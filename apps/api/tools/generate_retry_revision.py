"""Emit only the approved retry table from the target reference into Alembic."""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
source = (ROOT / "database/sql/target-schema-reference.sql").read_text(encoding="utf-8")
metadata = json.loads((ROOT / "database/metadata/model.json").read_text(encoding="utf-8"))
table = next(table for table in metadata["tables"] if table["table"] == "integration.idempotency_keys")
assert len(table["columns"]) == 12 and len(table["foreign_keys"]) == 3
match = re.search(r"(?ms)^CREATE TABLE \[integration\]\.\[idempotency_keys\] \(.*?^\);", source)
assert match is not None
create_table = match.group().rstrip(";")
foreign_keys = re.findall(
    r"(?m)^ALTER TABLE \[integration\]\.\[idempotency_keys\] ADD CONSTRAINT .*?;", source
)
assert len(foreign_keys) == 3
predicates = (
    "ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON integration.idempotency_keys",
    "ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON integration.idempotency_keys AFTER INSERT",
    "ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON integration.idempotency_keys AFTER UPDATE",
    "ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON integration.idempotency_keys BEFORE UPDATE",
    "ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON integration.idempotency_keys BEFORE DELETE",
)
output = ROOT / "apps/api/alembic/versions/0003_vehicle_registration_idempotency.py"
output.write_text(
    '''"""The sole approved retry table and its five tenant predicates."""
from alembic import op

revision = "0003_vehicle_retry"
down_revision = "0002_foundation_security"
branch_labels = None
depends_on = None

CREATE_TABLE = ''' + repr(create_table) + '''
FOREIGN_KEYS = ''' + repr(tuple(item.rstrip(";") for item in foreign_keys)) + '''
PREDICATES = ''' + repr(predicates) + '''


def upgrade() -> None:
    op.execute("CREATE SCHEMA [integration]")
    op.execute(CREATE_TABLE)
    for statement in FOREIGN_KEYS:
        op.execute(statement)
    op.execute("ALTER SECURITY POLICY iam.foundation_tenant_policy " + ", ".join(PREDICATES))
    op.execute("GRANT SELECT, INSERT ON integration.idempotency_keys TO [fleetops_runtime]")


def downgrade() -> None:
    raise RuntimeError("Retained retry receipts require a reviewed forward fix")
''',
    encoding="utf-8",
)
print("Wrote 0003_vehicle_registration_idempotency.py: 12 columns, 3 FKs, 5 predicates")
