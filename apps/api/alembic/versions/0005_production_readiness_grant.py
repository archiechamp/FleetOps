"""Allow the runtime health check to read only the migration version."""

from alembic import op

revision = "0005_production_readiness_grant"
down_revision = "0004_production_ai"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("GRANT SELECT ON dbo.alembic_version TO fleetops_runtime")


def downgrade() -> None:
    op.execute("REVOKE SELECT ON dbo.alembic_version FROM fleetops_runtime")
