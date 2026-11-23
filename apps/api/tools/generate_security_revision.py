"""Generate the reviewed foundation predicate list as standalone Alembic DDL."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
source = (ROOT / "database/sql/003-optional-foundation-rls.sql").read_text(encoding="utf-8")
function = re.search(r"(?ms)^CREATE FUNCTION iam\.fn_tenant_access.*?^GO", source)
policy = re.search(r"(?ms)^CREATE SECURITY POLICY iam\.foundation_tenant_policy.*?WITH \(STATE=ON\);", source)
assert function is not None and policy is not None
function_sql = function.group().rsplit("GO", 1)[0].strip().rstrip(";")
function_sql = function_sql.replace(
    "WHERE SQL_VARIANT_PROPERTY",
    "WHERE USER_NAME() = N'fleetops_bootstrap_executor' OR (SQL_VARIANT_PROPERTY",
    1,
)
function_sql += ")"
policy_sql = policy.group().rstrip(";")
assert policy_sql.count("PREDICATE") == 45

output = ROOT / "apps/api/alembic/versions/0002_foundation_security.py"
output.write_text(
    '''"""Restricted identity bootstrap, 45 foundation RLS predicates and scoped grants."""
from alembic import op

revision = "0002_foundation_security"
down_revision = "0001_foundation"
branch_labels = None
depends_on = None

FUNCTION_SQL = ''' + repr(function_sql) + '''
POLICY_SQL = ''' + repr(policy_sql) + '''


def upgrade() -> None:
    op.execute("CREATE USER [fleetops_bootstrap_executor] WITHOUT LOGIN")
    op.execute("CREATE ROLE [fleetops_bootstrap]")
    op.execute("CREATE ROLE [fleetops_runtime]")
    op.execute("CREATE ROLE [fleetops_seed]")
    for table in (
        "iam.users", "iam.memberships", "iam.membership_roles", "iam.roles",
        "iam.role_permissions", "iam.permissions", "core.tenants",
    ):
        op.execute(f"GRANT SELECT ON {table} TO [fleetops_bootstrap_executor]")
    op.execute(FUNCTION_SQL)
    op.execute(POLICY_SQL)
    op.execute("""CREATE PROCEDURE iam.get_verified_memberships
        @auth_provider VARCHAR(25),
        @external_subject NVARCHAR(200),
        @selected_tenant UNIQUEIDENTIFIER = NULL
        WITH EXECUTE AS 'fleetops_bootstrap_executor'
        AS BEGIN
            SET NOCOUNT ON;
            SELECT u.id AS user_id, m.id AS membership_id, m.tenant_id,
                   p.code AS permission_code
            FROM iam.users AS u
            JOIN iam.memberships AS m ON m.user_id = u.id
            JOIN core.tenants AS t ON t.id = m.tenant_id
            JOIN iam.membership_roles AS mr
              ON mr.tenant_id = m.tenant_id AND mr.membership_id = m.id
            JOIN iam.roles AS r ON r.tenant_id = mr.tenant_id AND r.id = mr.role_id
            JOIN iam.role_permissions AS rp
              ON rp.tenant_id = r.tenant_id AND rp.role_id = r.id
            JOIN iam.permissions AS p ON p.id = rp.permission_id
            WHERE u.auth_provider = @auth_provider
              AND u.external_subject = @external_subject
              AND u.status = 'ACTIVE' AND m.status = 'ACTIVE'
              AND t.status = 'ACTIVE'
              AND (@selected_tenant IS NULL OR m.tenant_id = @selected_tenant)
              AND p.code IN ('fleet.vehicle.read', 'fleet.vehicle.create');
        END""")
    op.execute("GRANT EXECUTE ON iam.get_verified_memberships TO [fleetops_bootstrap]")
    for table in ("fleet.assets", "fleet.vehicles", "ref.asset_types"):
        op.execute(f"GRANT SELECT ON {table} TO [fleetops_runtime]")
    for table in ("fleet.assets", "fleet.vehicles", "audit.audit_events"):
        op.execute(f"GRANT INSERT ON {table} TO [fleetops_runtime]")


def downgrade() -> None:
    raise RuntimeError("Security downgrade requires a reviewed forward fix")
''',
    encoding="utf-8",
)
print("Wrote 0002_foundation_security.py with 45 predicates")
