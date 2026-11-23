import json
from pathlib import Path

from sqlalchemy import CheckConstraint, ForeignKeyConstraint, UniqueConstraint
from sqlalchemy.dialects import mssql

import app.db.models  # noqa: F401
from app.db.base import Base

MODEL = json.loads(
    (Path(__file__).resolve().parents[4] / "database/metadata/model.json").read_text(encoding="utf-8")
)
EXPECTED = {
    entry["table"]: entry
    for entry in MODEL["tables"]
    if entry["foundation"] or entry["table"] == "integration.idempotency_keys"
}


def test_approved_sqlalchemy_subset_matches_reference_metadata() -> None:
    assert set(Base.metadata.tables) == set(EXPECTED)
    assert sum(len(table.columns) for table in Base.metadata.tables.values()) == 166
    assert sum(len(table.foreign_key_constraints) for table in Base.metadata.tables.values()) == 42

    dialect = mssql.dialect()
    for qualified_name, reference in EXPECTED.items():
        table = Base.metadata.tables[qualified_name]
        prefix = qualified_name.replace(".", "_")
        assert list(table.columns.keys()) == [column["name"] for column in reference["columns"]]
        assert [column.name for column in table.primary_key.columns] == [reference["pk"]]
        assert table.primary_key.name == f"PK_{prefix}"
        for column_reference in reference["columns"]:
            column = table.c[column_reference["name"]]
            actual_type = str(column.type.compile(dialect=dialect)).upper()
            if column_reference["type"] == "ROWVERSION":
                assert actual_type in {"TIMESTAMP", "ROWVERSION"}
            else:
                assert actual_type.replace(" ", "") == column_reference["type"]
            assert column.nullable == column_reference["nullable"]
            actual_default = (
                str(column.server_default.arg)
                if column.server_default is not None and column.identity is None else None
            )
            assert actual_default == column_reference["default"]
            assert (column.identity is not None) == column_reference["identity"]
        uniques = sorted(
            (constraint.name, tuple(column.name for column in constraint.columns))
            for constraint in table.constraints if isinstance(constraint, UniqueConstraint)
        )
        assert uniques == sorted(
            (f"UQ_{prefix}_{number}", tuple(columns))
            for number, columns in enumerate(reference["unique_keys"], 1)
        )
        checks = sorted(
            (constraint.name, str(constraint.sqltext))
            for constraint in table.constraints if isinstance(constraint, CheckConstraint)
        )
        assert checks == sorted(
            (f"CK_{prefix}_{number}", expression)
            for number, expression in enumerate(reference["checks"], 1)
        )
        foreign_keys = sorted(
            (constraint.name, tuple(column.name for column in constraint.columns),
             tuple(element.target_fullname for element in constraint.elements))
            for constraint in table.constraints if isinstance(constraint, ForeignKeyConstraint)
        )
        assert foreign_keys == sorted(
            (f"FK_{prefix}_{number}", tuple(foreign_key["columns"]),
             tuple(f"{foreign_key['target']}.{name}" for name in foreign_key["target_columns"]))
            for number, foreign_key in enumerate(reference["foreign_keys"], 1)
        )
        indexes = sorted(
            (index.name, tuple(column.name for column in index.columns), index.unique,
             str(index.dialect_options["mssql"].get("where")) if index.dialect_options["mssql"].get("where") is not None else None)
            for index in table.indexes
        )
        assert indexes == sorted(
            (f"IX_{prefix}_{number}", tuple(item["columns"]), item["unique"], item["filter"])
            for number, item in enumerate(reference["indexes"], 1)
        )
