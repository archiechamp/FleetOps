"""Tenant and membership scoped local Copilot history and daily request cap."""

from alembic import op

revision = "0005_demo_ai_chat"
down_revision = "0004_demo_operations"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        CREATE TABLE demo.ai_conversations (
            id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            tenant_id UNIQUEIDENTIFIER NOT NULL,
            membership_id UNIQUEIDENTIFIER NOT NULL,
            created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
            updated_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT UQ_demo_ai_conversation_owner UNIQUE (tenant_id, membership_id, id),
            CONSTRAINT FK_demo_ai_conversation_member FOREIGN KEY (tenant_id, membership_id)
                REFERENCES iam.memberships (tenant_id, id)
        )
    """)
    op.execute("""
        CREATE TABLE demo.ai_messages (
            id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            tenant_id UNIQUEIDENTIFIER NOT NULL,
            membership_id UNIQUEIDENTIFIER NOT NULL,
            conversation_id UNIQUEIDENTIFIER NOT NULL,
            role VARCHAR(10) NOT NULL,
            content NVARCHAR(4000) NOT NULL,
            sources_json NVARCHAR(MAX) NULL,
            requires_finance BIT NOT NULL DEFAULT 0,
            feedback TINYINT NULL,
            created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_demo_ai_message_conversation
                FOREIGN KEY (tenant_id, membership_id, conversation_id)
                REFERENCES demo.ai_conversations (tenant_id, membership_id, id),
            CONSTRAINT CK_demo_ai_message_role CHECK (role IN ('user','assistant')),
            CONSTRAINT CK_demo_ai_message_feedback CHECK (feedback IN (0,1)),
            CONSTRAINT CK_demo_ai_message_sources CHECK
                (sources_json IS NULL OR ISJSON(sources_json)=1)
        )
    """)
    op.execute("CREATE INDEX IX_demo_ai_messages_thread ON demo.ai_messages (tenant_id, membership_id, conversation_id, created_at)")
    op.execute("""
        CREATE TABLE demo.ai_daily_usage (
            tenant_id UNIQUEIDENTIFIER NOT NULL,
            membership_id UNIQUEIDENTIFIER NOT NULL,
            usage_date DATE NOT NULL,
            request_count INT NOT NULL,
            CONSTRAINT PK_demo_ai_daily_usage PRIMARY KEY
                (tenant_id, membership_id, usage_date),
            CONSTRAINT FK_demo_ai_daily_member FOREIGN KEY (tenant_id, membership_id)
                REFERENCES iam.memberships (tenant_id, id),
            CONSTRAINT CK_demo_ai_daily_count CHECK (request_count BETWEEN 0 AND 25)
        )
    """)
    predicates = []
    for table in ("demo.ai_conversations", "demo.ai_messages", "demo.ai_daily_usage"):
        predicates.extend((
            f"ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON {table}",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} AFTER INSERT",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} AFTER UPDATE",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} BEFORE UPDATE",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} BEFORE DELETE",
        ))
    op.execute("ALTER SECURITY POLICY iam.foundation_tenant_policy " + ", ".join(predicates))
    for table in ("demo.ai_conversations", "demo.ai_messages"):
        op.execute(f"GRANT SELECT, INSERT, UPDATE, DELETE ON {table} TO fleetops_runtime")
    op.execute("GRANT SELECT, INSERT, UPDATE ON demo.ai_daily_usage TO fleetops_runtime")
    op.execute("GRANT SELECT ON core.tenants TO fleetops_runtime")


def downgrade() -> None:
    raise RuntimeError("Demo chat history requires a reviewed forward fix")
