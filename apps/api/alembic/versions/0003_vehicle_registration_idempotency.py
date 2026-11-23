"""The sole approved retry table and its five tenant predicates."""
from alembic import op

revision = "0003_vehicle_retry"
down_revision = "0002_foundation_security"
branch_labels = None
depends_on = None

CREATE_TABLE = 'CREATE TABLE [integration].[idempotency_keys] (\n    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_idempotency_keys_id] DEFAULT (NEWSEQUENTIALID()),\n    [tenant_id] UNIQUEIDENTIFIER NOT NULL,\n    [operation_scope] VARCHAR(80) NOT NULL,\n    [request_key] NVARCHAR(150) NOT NULL,\n    [request_hash] BINARY(32) NOT NULL,\n    [response_reference] NVARCHAR(150) NULL,\n    [expires_at] DATETIME2(3) NOT NULL,\n    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_idempotency_keys_created_at] DEFAULT (SYSUTCDATETIME()),\n    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_idempotency_keys_updated_at] DEFAULT (SYSUTCDATETIME()),\n    [row_version] ROWVERSION NOT NULL,\n    [created_by] UNIQUEIDENTIFIER NULL,\n    [updated_by] UNIQUEIDENTIFIER NULL,\n    CONSTRAINT [PK_integration_idempotency_keys] PRIMARY KEY ([id]),\n    CONSTRAINT [UQ_integration_idempotency_keys_1] UNIQUE ([tenant_id], [id]),\n    CONSTRAINT [UQ_integration_idempotency_keys_2] UNIQUE ([tenant_id], [operation_scope], [request_key])\n)'
FOREIGN_KEYS = ('ALTER TABLE [integration].[idempotency_keys] ADD CONSTRAINT [FK_integration_idempotency_keys_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id])', 'ALTER TABLE [integration].[idempotency_keys] ADD CONSTRAINT [FK_integration_idempotency_keys_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id])', 'ALTER TABLE [integration].[idempotency_keys] ADD CONSTRAINT [FK_integration_idempotency_keys_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id])')
PREDICATES = ('ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON integration.idempotency_keys', 'ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON integration.idempotency_keys AFTER INSERT', 'ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON integration.idempotency_keys AFTER UPDATE', 'ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON integration.idempotency_keys BEFORE UPDATE', 'ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON integration.idempotency_keys BEFORE DELETE')


def upgrade() -> None:
    op.execute("CREATE SCHEMA [integration]")
    op.execute(CREATE_TABLE)
    for statement in FOREIGN_KEYS:
        op.execute(statement)
    op.execute("ALTER SECURITY POLICY iam.foundation_tenant_policy " + ", ".join(PREDICATES))
    op.execute("GRANT SELECT, INSERT ON integration.idempotency_keys TO [fleetops_runtime]")


def downgrade() -> None:
    raise RuntimeError("Retained retry receipts require a reviewed forward fix")
