"""One-time development helper: copy the approved 17-table DDL into Alembic.

This reads only the foundation reference and emits a standalone migration. It does
not connect to a database or execute reference scripts.
"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "database/sql/001-foundation-reference.sql"
MODEL = ROOT / "database/metadata/model.json"
OUTPUT = ROOT / "apps/api/alembic/versions/0001_foundation.py"

source = SOURCE.read_text(encoding="utf-8")
metadata = json.loads(MODEL.read_text(encoding="utf-8"))
foundation = {table["table"] for table in metadata["tables"] if table["foundation"]}

tables = re.findall(r"(?ms)^CREATE TABLE \[([^]]+)\]\.\[([^]]+)\] \(.*?^\);", source)
assert {f"{schema}.{table}" for schema, table in tables} == foundation

statements = []
for match in re.finditer(r"(?ms)^CREATE TABLE \[[^]]+\]\.\[[^]]+\] \(.*?^\);", source):
    statements.append(match.group().rstrip(";"))
for line in source.splitlines():
    if line.startswith(("ALTER TABLE ", "CREATE INDEX ", "CREATE UNIQUE INDEX ")):
        statements.append(line.rstrip(";"))
assert len([statement for statement in statements if statement.startswith("ALTER TABLE")]) == 39
assert len(statements) == 17 + 39 + sum(len(table["indexes"]) for table in metadata["tables"] if table["foundation"])

header = '''"""Approved 17-table foundation, copied as individual Alembic DDL statements.

Revision ID: 0001_foundation
Revises:
"""
from alembic import op

revision = "0001_foundation"
down_revision = None
branch_labels = None
depends_on = None

SCHEMAS = ("audit", "core", "fleet", "iam", "ref")
STATEMENTS = (
'''
body = "".join(f"    {statement!r},\n" for statement in statements)
footer = ''' )


def upgrade() -> None:
    for schema in SCHEMAS:
        op.execute(f"CREATE SCHEMA [{schema}]")
    for statement in STATEMENTS:
        op.execute(statement)


def downgrade() -> None:
    raise RuntimeError("Populated foundation downgrade is not approved; use a reviewed forward fix")
'''
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text(header + body + footer, encoding="utf-8")
print(f"Wrote {OUTPUT.name}: {len(tables)} tables, 39 FKs, {len(statements) - 56} indexes")
