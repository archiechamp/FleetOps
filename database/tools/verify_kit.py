"""Validate the reference kit on disk with the Python standard library.

The DDL comparison reads the kit's generated layout. It does not execute SQL.
Run verify-foundation.sql on SQL Server for engine-specific behavior.
"""
import csv
import json
import re
import sys
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree

ROOT = Path(__file__).resolve().parents[2]
DB = ROOT / "database"
SQL = DB / "sql"
DOCS = ROOT / "docs" / "database"
OWNED = {"T", "A", "H"}


def require(condition, detail):
    if not condition:
        raise ValueError(detail)


def bracket(name):
    return ".".join(f"[{part}]" for part in name.split("."))


def key(columns):
    return "(" + ", ".join(map(bracket, columns)) + ")"


def compare_items(expected, actual, label):
    missing = Counter(expected) - Counter(actual)
    extra = Counter(actual) - Counter(expected)
    require(not missing and not extra, f"{label}: missing {list(missing)[:3]}, extra {list(extra)[:3]}")


def validate_model(tables):
    for name, table in tables.items():
        columns = {col["name"]: col for col in table["columns"]}
        require(len(columns) == len(table["columns"]), f"{name}: duplicate column")
        require([c["name"] for c in columns.values() if c["pk"]] == [table["pk"]], f"{name}: PK")
        for group in table["unique_keys"] + [idx["columns"] for idx in table["indexes"]]:
            require(set(group) <= columns.keys(), f"{name}: unknown key column {group}")
        if table["scope"] in OWNED:
            require(not columns["tenant_id"]["nullable"], f"{name}: nullable tenant")
            require(any(f["columns"] == ["tenant_id"] and f["target"] == "core.tenants"
                        for f in table["foreign_keys"]), f"{name}: missing tenant reference")
        for fk in table["foreign_keys"]:
            parent = tables[fk["target"]]
            local, remote = fk["columns"], fk["target_columns"]
            target = {c["name"]: c["type"] for c in parent["columns"]}
            require(remote in [[parent["pk"]]] + parent["unique_keys"], f"{name}: FK target key {remote}")
            require([columns[c]["type"] for c in local] == [target[c] for c in remote], f"{name}: FK type {local}")
            if parent["scope"] in OWNED:
                require(("tenant_id", "tenant_id") in zip(local, remote), f"{name}: tenant pairing {local}")
            if table["foundation"]:
                require(parent["foundation"], f"{name}: non-foundation dependency {parent['table']}")
            if table["phase"] in {"P0", "P0B"}:
                require(parent["phase"] in {"P0", "P0B"}, f"{name}: later-phase dependency {parent['table']}")


def validate_ddl(path, tables):
    source = path.read_text()
    blocks = re.findall(r"CREATE TABLE \[(\w+)\]\.\[(\w+)\] \(\n(.*?)\n\);", source, re.S)
    compare_items(tables.keys(), [f"{s}.{t}" for s, t, _ in blocks], path.name)
    relationships = []
    indexes = []
    for schema, table_name, body in blocks:
        name = f"{schema}.{table_name}"
        table = tables[name]
        stem = f"{schema}_{table_name}"
        definitions = []
        for c in table["columns"]:
            line = f"{bracket(c['name'])} {c['type']}"
            if c["identity"]:
                line += " IDENTITY(1,1)"
            line += " NULL" if c["nullable"] else " NOT NULL"
            if c["default"] is not None:
                line += f" CONSTRAINT [DF_{stem}_{c['name']}] DEFAULT ({c['default']})"
            definitions.append(line)
        definitions.append(f"CONSTRAINT [PK_{stem}] PRIMARY KEY {key([table['pk']])}")
        for i, cols in enumerate(table["unique_keys"], 1):
            definitions.append(f"CONSTRAINT [UQ_{stem}_{i}] UNIQUE {key(cols)}")
        for i, check in enumerate(table["checks"], 1):
            definitions.append(f"CONSTRAINT [CK_{stem}_{i}] CHECK ({check})")
        actual = [line.strip().rstrip(",") for line in body.splitlines()]
        require(definitions == actual, f"{path.name}: column or constraint drift at {name}")
        for i, fk in enumerate(table["foreign_keys"], 1):
            relationships.append(f"ALTER TABLE {bracket(name)} ADD CONSTRAINT [FK_{stem}_{i}] "
                                 f"FOREIGN KEY {key(fk['columns'])} REFERENCES "
                                 f"{bracket(fk['target'])} {key(fk['target_columns'])};")
        for i, idx in enumerate(table["indexes"], 1):
            unique = "UNIQUE " if idx["unique"] else ""
            predicate = f" WHERE {idx['filter']}" if idx["filter"] else ""
            indexes.append(f"CREATE {unique}INDEX [IX_{stem}_{i}] ON {bracket(name)} "
                           f"{key(idx['columns'])}{predicate};")
    compare_items(relationships, re.findall(r"^ALTER TABLE .+$", source, re.M), f"{path.name} FKs")
    compare_items(indexes, re.findall(r"^CREATE (?:UNIQUE )?INDEX .+$", source, re.M), f"{path.name} indexes")


def validate_reference_files(tables):
    expected = []
    with (DB / "metadata/columns.csv").open(newline="") as handle:
        reader = csv.DictReader(handle)
        fields = reader.fieldnames
        for table in tables.values():
            for col in table["columns"]:
                values = {**table, **col}
                expected.append({field: "" if values[field] is None else str(values[field]) for field in fields})
        require(list(reader) == expected, "CSV and model disagree")
    dictionary = (DOCS / "data-dictionary.md").read_text()
    for name, block in sections(dictionary, tables):
        names = re.findall(r"^\| `(\w+)` \|", block, re.M)
        require(names == [c["name"] for c in tables[name]["columns"]], f"{name}: dictionary")
    atlas = DOCS / "erd"
    for schema in {name.split(".")[0] for name in tables}:
        local = [t for t in tables.values() if t["table"].startswith(schema + ".")]
        dot = (atlas / (schema + ".dot")).read_text()
        edges = re.findall(r'^"([^"]+)" -> "([^"]+)"', dot, re.M)
        compare_items([(t["table"], fk["target"]) for t in local for fk in t["foreign_keys"]],
                      edges, f"{schema}: diagram edges")
        for t in local:
            node = next(line for line in dot.splitlines() if line.startswith(f'"{t["table"]}" [label='))
            names = re.findall(r'<TR><TD ALIGN="LEFT">(\w+)</TD>', node)
            require(names == [c["name"] for c in t["columns"]], f"{t['table']}: diagram columns")
        ElementTree.parse(atlas / (schema + ".svg"))
    ElementTree.parse(atlas / "foundation-overview.svg")


def sections(markdown, tables):
    parts = re.split(r"^## `([\w.]+)`\n", markdown, flags=re.M)
    compare_items(tables.keys(), parts[1::2], "dictionary sections")
    return zip(parts[1::2], parts[2::2])


def validate_foundation(tables):
    policy = (SQL / "003-optional-foundation-rls.sql").read_text()
    predicates = re.findall(r"(FILTER|BLOCK) PREDICATE iam.fn_tenant_access\(tenant_id\) ON "
                            r"([\w.]+)(?: (AFTER INSERT|AFTER UPDATE|BEFORE UPDATE|BEFORE DELETE))?", policy)
    expected = [(kind, name, event) for name, t in tables.items() if t["scope"] in OWNED
                for kind, event in [("FILTER", ""), ("BLOCK", "AFTER INSERT"), ("BLOCK", "AFTER UPDATE"),
                                    ("BLOCK", "BEFORE UPDATE"), ("BLOCK", "BEFORE DELETE")]]
    compare_items(expected, predicates, "RLS coverage")
    seed = (SQL / "002-synthetic-seed.sql").read_text()
    inserts = re.findall(r"INSERT INTO ([\w.]+) \(([^)]+)\) VALUES ", seed)
    require(len(inserts) == len(re.findall(r"\bINSERT INTO\b", seed)), "unrecognized fixture layout")
    for name, col_list in inserts:
        names = set(re.findall(r"\[(\w+)\]", col_list))
        cols = tables[name]["columns"]
        required = {c["name"] for c in cols if not c["nullable"] and c["default"] is None
                    and not c["identity"] and c["type"] != "ROWVERSION"}
        require(required <= names <= {c["name"] for c in cols}, f"{name}: fixture column coverage")
    return len(inserts), len(predicates)


def main():
    model = json.loads((DB / "metadata/model.json").read_text())
    tables = {t["table"]: t for t in model["tables"]}
    require(len(tables) == len(model["tables"]), "duplicate table name")
    foundation = {n: t for n, t in tables.items() if t["foundation"]}
    validate_model(tables)
    validate_ddl(SQL / "target-schema-reference.sql", tables)
    validate_ddl(SQL / "001-foundation-reference.sql", foundation)
    validate_reference_files(tables)
    seeds, predicates = validate_foundation(foundation)
    print(f"Target: {len(tables)} tables, {sum(len(t['columns']) for t in tables.values())} columns, "
          f"{sum(len(t['foreign_keys']) for t in tables.values())} foreign keys")
    print(f"Foundation: {len(foundation)} tables, {seeds} fixture inserts, {predicates} policy predicates")
    print("Static checks passed. SQL Server execution is a separate gate.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, StopIteration) as exc:
        sys.exit(f"Validation failed: {exc}")
