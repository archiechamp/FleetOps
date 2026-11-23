"""Local demo operations only; not the production domain schema."""

from alembic import op

revision = "0004_demo_operations"
down_revision = "0003_vehicle_retry"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE SCHEMA demo")
    op.execute("""
        CREATE TABLE demo.asset_state (
            tenant_id UNIQUEIDENTIFIER NOT NULL,
            asset_id UNIQUEIDENTIFIER NOT NULL,
            odometer_miles DECIMAL(12,1) NULL,
            service_due_date DATE NULL,
            service_due_miles DECIMAL(12,1) NULL,
            service_note NVARCHAR(300) NULL,
            gps_latitude DECIMAL(9,6) NULL,
            gps_longitude DECIMAL(9,6) NULL,
            gps_source NVARCHAR(80) NULL,
            gps_observed_at DATETIME2(3) NULL,
            gps_received_at DATETIME2(3) NULL,
            updated_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT PK_demo_asset_state PRIMARY KEY (tenant_id, asset_id),
            CONSTRAINT FK_demo_asset_state_asset FOREIGN KEY (tenant_id, asset_id)
                REFERENCES fleet.assets (tenant_id, id),
            CONSTRAINT CK_demo_asset_state_odometer CHECK
                (odometer_miles >= 0 AND service_due_miles >= 0),
            CONSTRAINT CK_demo_asset_state_gps CHECK
                ((gps_latitude IS NULL AND gps_longitude IS NULL AND gps_observed_at IS NULL)
                 OR (gps_latitude BETWEEN -90 AND 90 AND gps_longitude BETWEEN -180 AND 180
                     AND gps_observed_at IS NOT NULL))
        )
    """)
    op.execute("""
        CREATE TABLE demo.assignments (
            id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            tenant_id UNIQUEIDENTIFIER NOT NULL,
            truck_asset_id UNIQUEIDENTIFIER NOT NULL,
            trailer_asset_id UNIQUEIDENTIFIER NULL,
            trip_reference NVARCHAR(40) NOT NULL,
            starts_at DATETIME2(3) NOT NULL,
            ends_at DATETIME2(3) NOT NULL,
            created_by UNIQUEIDENTIFIER NOT NULL,
            created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_demo_assignment_truck FOREIGN KEY (tenant_id, truck_asset_id)
                REFERENCES fleet.assets (tenant_id, id),
            CONSTRAINT FK_demo_assignment_trailer FOREIGN KEY (tenant_id, trailer_asset_id)
                REFERENCES fleet.assets (tenant_id, id),
            CONSTRAINT FK_demo_assignment_member FOREIGN KEY (tenant_id, created_by)
                REFERENCES iam.memberships (tenant_id, id),
            CONSTRAINT CK_demo_assignment_period CHECK (ends_at > starts_at),
            CONSTRAINT UQ_demo_assignment_trip UNIQUE (tenant_id, trip_reference)
        )
    """)
    op.execute("CREATE INDEX IX_demo_assignments_truck ON demo.assignments (tenant_id, truck_asset_id, starts_at, ends_at)")
    op.execute("CREATE INDEX IX_demo_assignments_trailer ON demo.assignments (tenant_id, trailer_asset_id, starts_at, ends_at)")
    op.execute("""
        CREATE TABLE demo.documents (
            id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            tenant_id UNIQUEIDENTIFIER NOT NULL,
            asset_id UNIQUEIDENTIFIER NOT NULL,
            kind VARCHAR(20) NOT NULL,
            expires_on DATE NULL,
            file_name NVARCHAR(160) NOT NULL,
            content_type VARCHAR(50) NOT NULL,
            file_bytes VARBINARY(MAX) NOT NULL,
            uploaded_by UNIQUEIDENTIFIER NOT NULL,
            uploaded_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_demo_document_asset FOREIGN KEY (tenant_id, asset_id)
                REFERENCES fleet.assets (tenant_id, id),
            CONSTRAINT FK_demo_document_member FOREIGN KEY (tenant_id, uploaded_by)
                REFERENCES iam.memberships (tenant_id, id),
            CONSTRAINT CK_demo_document_kind CHECK (kind IN ('REGISTRATION','INSURANCE')),
            CONSTRAINT CK_demo_document_size CHECK (DATALENGTH(file_bytes) BETWEEN 1 AND 1048576)
        )
    """)
    op.execute("CREATE INDEX IX_demo_documents_asset ON demo.documents (tenant_id, asset_id, kind)")
    op.execute("""
        CREATE TABLE demo.costs (
            id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
            tenant_id UNIQUEIDENTIFIER NOT NULL,
            asset_id UNIQUEIDENTIFIER NOT NULL,
            trip_reference NVARCHAR(40) NULL,
            category VARCHAR(30) NOT NULL,
            amount_usd DECIMAL(19,2) NOT NULL,
            occurred_on DATE NOT NULL,
            created_by UNIQUEIDENTIFIER NOT NULL,
            created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_demo_cost_asset FOREIGN KEY (tenant_id, asset_id)
                REFERENCES fleet.assets (tenant_id, id),
            CONSTRAINT FK_demo_cost_member FOREIGN KEY (tenant_id, created_by)
                REFERENCES iam.memberships (tenant_id, id),
            CONSTRAINT CK_demo_cost_amount CHECK (amount_usd > 0),
            CONSTRAINT CK_demo_cost_category CHECK
                (category IN ('FUEL','MAINTENANCE','TOLLS','OTHER'))
        )
    """)
    op.execute("CREATE INDEX IX_demo_costs_asset ON demo.costs (tenant_id, asset_id, occurred_on)")
    tables = ("demo.asset_state", "demo.assignments", "demo.documents", "demo.costs")
    predicates = []
    for table in tables:
        predicates.extend((
            f"ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON {table}",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} AFTER INSERT",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} AFTER UPDATE",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} BEFORE UPDATE",
            f"ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON {table} BEFORE DELETE",
        ))
        op.execute(f"GRANT SELECT, INSERT, UPDATE ON {table} TO fleetops_runtime")
    op.execute("ALTER SECURITY POLICY iam.foundation_tenant_policy " + ", ".join(predicates))
    op.execute("GRANT UPDATE ON fleet.assets TO fleetops_runtime")
    op.execute("GRANT SELECT ON core.terminals TO fleetops_runtime")
    op.execute("""
        ALTER PROCEDURE iam.get_verified_memberships
        @auth_provider VARCHAR(25), @external_subject NVARCHAR(200),
        @selected_tenant UNIQUEIDENTIFIER = NULL
        WITH EXECUTE AS 'fleetops_bootstrap_executor'
        AS BEGIN
            SET NOCOUNT ON;
            SELECT u.id AS user_id, m.id AS membership_id, m.tenant_id,
                   p.code AS permission_code
            FROM iam.users u
            JOIN iam.memberships m ON m.user_id = u.id
            JOIN core.tenants t ON t.id = m.tenant_id
            JOIN iam.membership_roles mr ON mr.tenant_id = m.tenant_id AND mr.membership_id = m.id
            JOIN iam.roles r ON r.tenant_id = mr.tenant_id AND r.id = mr.role_id
            JOIN iam.role_permissions rp ON rp.tenant_id = r.tenant_id AND rp.role_id = r.id
            JOIN iam.permissions p ON p.id = rp.permission_id
            WHERE u.auth_provider = @auth_provider AND u.external_subject = @external_subject
              AND u.status = 'ACTIVE' AND m.status = 'ACTIVE' AND t.status = 'ACTIVE'
              AND (@selected_tenant IS NULL OR m.tenant_id = @selected_tenant)
              AND p.code IN ('fleet.vehicle.read','fleet.vehicle.create',
                             'demo.finance.read','demo.finance.create');
        END
    """)


def downgrade() -> None:
    raise RuntimeError("Demo records require a reviewed forward fix")
