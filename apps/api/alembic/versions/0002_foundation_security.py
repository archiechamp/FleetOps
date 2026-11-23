"""Restricted identity bootstrap, 45 foundation RLS predicates and scoped grants."""
from alembic import op

revision = "0002_foundation_security"
down_revision = "0001_foundation"
branch_labels = None
depends_on = None

FUNCTION_SQL = "CREATE FUNCTION iam.fn_tenant_access(@tenant_id UNIQUEIDENTIFIER)\nRETURNS TABLE WITH SCHEMABINDING AS RETURN\nSELECT 1 AS allowed\nWHERE USER_NAME() = N'fleetops_bootstrap_executor' OR (SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'tenant_id'), 'BaseType') = N'uniqueidentifier'\n  AND SESSION_CONTEXT(N'tenant_id') = CONVERT(SQL_VARIANT, @tenant_id))"
POLICY_SQL = 'CREATE SECURITY POLICY iam.foundation_tenant_policy\nADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON core.tenant_settings,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.tenant_settings AFTER INSERT,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.tenant_settings AFTER UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.tenant_settings BEFORE UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.tenant_settings BEFORE DELETE,\nADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON core.terminals,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.terminals AFTER INSERT,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.terminals AFTER UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.terminals BEFORE UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.terminals BEFORE DELETE,\nADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON iam.memberships,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.memberships AFTER INSERT,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.memberships AFTER UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.memberships BEFORE UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.memberships BEFORE DELETE,\nADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON iam.roles,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.roles AFTER INSERT,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.roles AFTER UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.roles BEFORE UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.roles BEFORE DELETE,\nADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON iam.membership_roles,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.membership_roles AFTER INSERT,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.membership_roles AFTER UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.membership_roles BEFORE UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.membership_roles BEFORE DELETE,\nADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON iam.role_permissions,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.role_permissions AFTER INSERT,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.role_permissions AFTER UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.role_permissions BEFORE UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.role_permissions BEFORE DELETE,\nADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.assets,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.assets AFTER INSERT,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.assets AFTER UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.assets BEFORE UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.assets BEFORE DELETE,\nADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.vehicles,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.vehicles AFTER INSERT,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.vehicles AFTER UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.vehicles BEFORE UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.vehicles BEFORE DELETE,\nADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON audit.audit_events,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON audit.audit_events AFTER INSERT,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON audit.audit_events AFTER UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON audit.audit_events BEFORE UPDATE,\nADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON audit.audit_events BEFORE DELETE\nWITH (STATE=ON)'


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
