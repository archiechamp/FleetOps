"""Production read-only AI history subset; separate from fictional demo tables."""

from alembic import op

revision = "0004_production_ai"
down_revision = "0003_vehicle_retry"
branch_labels = ("production",)
depends_on = None


def upgrade() -> None:
    op.execute("CREATE SCHEMA ai")
    op.execute("""
        CREATE TABLE ai.conversations (
            id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            tenant_id UNIQUEIDENTIFIER NOT NULL,
            membership_id UNIQUEIDENTIFIER NOT NULL,
            created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
            updated_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT UQ_ai_conversation_owner UNIQUE (tenant_id, membership_id, id),
            CONSTRAINT FK_ai_conversation_member FOREIGN KEY (tenant_id, membership_id)
                REFERENCES iam.memberships (tenant_id, id)
        )
    """)
    op.execute("""
        CREATE TABLE ai.messages (
            id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            tenant_id UNIQUEIDENTIFIER NOT NULL,
            membership_id UNIQUEIDENTIFIER NOT NULL,
            conversation_id UNIQUEIDENTIFIER NOT NULL,
            role VARCHAR(10) NOT NULL,
            content NVARCHAR(4000) NOT NULL,
            sources_json NVARCHAR(MAX) NULL,
            feedback TINYINT NULL,
            created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_ai_message_conversation FOREIGN KEY
                (tenant_id, membership_id, conversation_id)
                REFERENCES ai.conversations (tenant_id, membership_id, id),
            CONSTRAINT CK_ai_message_role CHECK (role IN ('user','assistant')),
            CONSTRAINT CK_ai_message_feedback CHECK (feedback IN (0,1)),
            CONSTRAINT CK_ai_message_sources CHECK
                (sources_json IS NULL OR ISJSON(sources_json)=1)
        )
    """)
    op.execute("""
        CREATE INDEX IX_ai_messages_usage
        ON ai.messages (tenant_id, membership_id, role, created_at)
    """)
    op.execute("""
        CREATE INDEX IX_ai_messages_thread
        ON ai.messages (tenant_id, membership_id, conversation_id, created_at)
    """)
    predicates = []
    for table in ("ai.conversations", "ai.messages"):
        predicates.extend((
            f"ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON {table}",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} AFTER INSERT",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} AFTER UPDATE",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} BEFORE UPDATE",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} BEFORE DELETE",
        ))
    op.execute("ALTER SECURITY POLICY iam.foundation_tenant_policy " + ", ".join(predicates))
    for table in ("ai.conversations", "ai.messages"):
        op.execute(f"GRANT SELECT, INSERT, UPDATE, DELETE ON {table} TO fleetops_runtime")
    op.execute("GRANT SELECT ON core.tenants TO fleetops_runtime")


def downgrade() -> None:
    raise RuntimeError("AI history requires a reviewed forward fix")
