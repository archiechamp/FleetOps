"""Generate self-contained SQLAlchemy Core model modules from the approved kit subset."""

import json
from pathlib import Path
from pprint import pformat

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "database/metadata/model.json"
OUTPUT = ROOT / "apps/api/app/db/models"
metadata = json.loads(SOURCE.read_text(encoding="utf-8"))
tables = [
    table for table in metadata["tables"]
    if table["foundation"] or table["table"] == "integration.idempotency_keys"
]
assert len(tables) == 18
modules = []
for table in tables:
    module = table["table"].replace(".", "_")
    modules.append(module)
    spec = {
        "table": table["table"],
        "pk": table["pk"],
        "columns": [
            {key: column[key] for key in ("name", "type", "nullable", "default", "identity")}
            for column in table["columns"]
        ],
        "foreign_keys": table["foreign_keys"],
        "unique_keys": table["unique_keys"],
        "checks": table["checks"],
        "indexes": table["indexes"],
    }
    (OUTPUT / f"{module}.py").write_text(
        '"""Approved Feature 001 SQL Server table contract."""\n'
        "from app.db.models.definition import create_table\n\n"
        f"SPEC = {pformat(spec, width=1000, sort_dicts=False)}\n"
        "table = create_table(SPEC)\n",
        encoding="utf-8",
    )
(OUTPUT / "__init__.py").write_text(
    '"""Load the exact Feature 001 table subset."""\n'
    "from importlib import import_module\n\n"
    f"MODULES = {tuple(modules)!r}\n"
    "for module in MODULES:\n"
    "    import_module(f\"{__name__}.{module}\")\n",
    encoding="utf-8",
)
print(f"Generated {len(tables)} model modules")
