"""One-time fictional fleet inventory for an approved, empty staging carrier."""

import os
from uuid import UUID, uuid5

from sqlalchemy import create_engine, text

from app.core.migration_config import migration_target

EXPECTED_REVISION = "0005_production_readiness_grant"
STAGING_DATABASE = "fleetops-staging-db"
DEMO_NAME = "FleetOps Staging (Fictional Demo)"
NAMESPACE = UUID("7a2f672d-6209-4a7c-9940-637697223cde")
VEHICLES = (
    ("DEMO-101", "Freightliner", "Cascadia", 2024),
    ("DEMO-102", "Kenworth", "T680", 2023),
)


def _id(tenant: str, kind: str, unit: str) -> str:
    return str(uuid5(NAMESPACE, f"staging:{tenant}:{kind}:{unit}"))


def seed() -> tuple[str, int]:
    if os.environ.get("FLEETOPS_ENV") != "production":
        raise RuntimeError("Staging seed requires the production schema mode")
    if os.environ.get("FLEETOPS_STAGING_FICTIONAL_SEED") != "approved":
        raise RuntimeError("Explicit fictional staging seed approval is required")
    tenant = str(UUID(os.environ["FLEETOPS_STAGING_DEMO_TENANT_ID"]))
    url, head = migration_target()
    if url.database != STAGING_DATABASE or head != "production@head":
        raise RuntimeError("Fictional seed refuses a non-staging or unapproved migration target")

    engine = create_engine(url)
    try:
        with engine.begin() as connection:
            revision = connection.execute(text("SELECT version_num FROM dbo.alembic_version")).scalar_one()
            if revision != EXPECTED_REVISION:
                raise RuntimeError("Staging schema is not at the approved revision")
            connection.execute(text("""
                DECLARE @selected UNIQUEIDENTIFIER = CONVERT(UNIQUEIDENTIFIER, :tenant);
                EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@selected
            """), {"tenant": tenant})
            carrier = connection.execute(text("""
                SELECT name, status FROM core.tenants WHERE id = :tenant
            """), {"tenant": tenant}).mappings().one_or_none()
            if carrier is None or carrier["status"] != "ACTIVE":
                raise RuntimeError("The approved staging carrier is missing or inactive")
            if not any(word in carrier["name"].casefold() for word in ("staging", "pilot", "demo")):
                raise RuntimeError("Carrier name does not identify a staging or demo carrier")

            expected = {_id(tenant, "asset", unit): unit for unit, *_ in VEHICLES}
            existing = connection.execute(text("""
                SELECT id, unit_number FROM fleet.assets WHERE tenant_id = :tenant
            """), {"tenant": tenant}).mappings().all()
            if any(expected.get(str(row["id"])) != row["unit_number"] for row in existing):
                raise RuntimeError("Carrier has unrelated assets; fictional seed refused")

            connection.execute(text("""
                IF NOT EXISTS (SELECT 1 FROM ref.asset_types WHERE code = 'TRACTOR')
                    INSERT INTO ref.asset_types (code, name) VALUES ('TRACTOR', 'Tractor')
            """))
            asset_type_id = connection.execute(text("""
                SELECT id FROM ref.asset_types WHERE code = 'TRACTOR'
            """)).scalar_one()
            membership_id = connection.execute(text("""
                SELECT TOP (1) id FROM iam.memberships
                WHERE tenant_id = :tenant AND status = 'ACTIVE' ORDER BY id
            """), {"tenant": tenant}).scalar_one_or_none()
            if membership_id is None:
                raise RuntimeError("Staging carrier has no active member")
            connection.execute(text("""
                UPDATE core.tenants SET name = :name WHERE id = :tenant
            """), {"name": DEMO_NAME, "tenant": tenant})

            for unit, make, model, year in VEHICLES:
                asset_id = _id(tenant, "asset", unit)
                vehicle_id = _id(tenant, "vehicle", unit)
                connection.execute(text("""
                    IF NOT EXISTS (SELECT 1 FROM fleet.assets WHERE id = :asset_id)
                        INSERT INTO fleet.assets
                            (id, tenant_id, unit_number, asset_type_id, make, model,
                             model_year, ownership_type, currency_code, created_by)
                        VALUES
                            (:asset_id, :tenant, :unit, :asset_type_id, :make, :model,
                             :year, 'OWNED', 'USD', :created_by)
                """), {"asset_id": asset_id, "tenant": tenant, "unit": unit,
                       "asset_type_id": asset_type_id, "make": make, "model": model,
                       "year": year, "created_by": str(membership_id)})
                connection.execute(text("""
                    IF NOT EXISTS (SELECT 1 FROM fleet.vehicles WHERE id = :vehicle_id)
                        INSERT INTO fleet.vehicles (id, tenant_id, asset_id, created_by)
                        VALUES (:vehicle_id, :tenant, :asset_id, :created_by)
                """), {"vehicle_id": vehicle_id, "tenant": tenant,
                       "asset_id": asset_id, "created_by": str(membership_id)})
        return tenant, len(VEHICLES)
    finally:
        engine.dispose()


if __name__ == "__main__":
    tenant_id, count = seed()
    print(f"Fictional staging fleet ready: carrier={tenant_id} vehicles={count}")
