"""Bootstrap and seed only the isolated, fictional FleetOps Docker demo."""

import os
import sys
from uuid import UUID, uuid5

import pyodbc
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from sqlalchemy.pool import NullPool

TENANTS = (
    (UUID("11111111-1111-4111-8111-111111111111"), "Northstar Freight (Demo)", "northstar-demo"),
    (UUID("22222222-2222-4222-8222-222222222222"), "Lakeside Logistics (Demo)", "lakeside-demo"),
)
USERS = ("demo_creator", "demo_reader")


def _engine(database: str):
    pyodbc.pooling = False
    return create_engine(URL.create(
        "mssql+pyodbc", username="sa", password=os.environ["FLEETOPS_TEST_SA_PASSWORD"],
        host=os.environ.get("FLEETOPS_SQL_SERVER", "sqlserver"), database=database,
        query={"driver": "ODBC Driver 18 for SQL Server", "Encrypt": "yes",
               "TrustServerCertificate": "yes"},
    ), poolclass=NullPool, isolation_level="AUTOCOMMIT" if database == "master" else None)


def _insert(connection, table: str, marker: str, values: dict) -> None:
    columns = ", ".join(f"[{name}]" for name in values)
    parameters = ", ".join(f":{name}" for name in values)
    connection.execute(text(f"""
        IF NOT EXISTS (SELECT 1 FROM {table} WHERE {marker})
        INSERT INTO {table} ({columns}) VALUES ({parameters})
    """), values)


def _id(label: str) -> str:
    return str(uuid5(UUID("7a2f672d-6209-4a7c-9940-637697223cde"), label))


def bootstrap() -> None:
    with _engine("master").connect() as connection:
        connection.execute(text("""
            IF DB_ID(N'fleetops_demo_001') IS NULL
                EXEC(N'CREATE DATABASE [fleetops_demo_001] COLLATE Latin1_General_100_CI_AS_SC')
        """))


def seed() -> None:
    password = os.environ["FLEETOPS_DEMO_RUNTIME_PASSWORD"]
    if len(password) < 12 or "'" in password:
        raise RuntimeError("Demo SQL password must be 12+ characters without apostrophes")
    with _engine("master").connect() as connection:
        exists = connection.execute(text("""
            SELECT 1 FROM sys.sql_logins WHERE name = 'fleetops_demo_runtime'
        """)).scalar()
        verb = "ALTER" if exists else "CREATE"
        connection.exec_driver_sql(
            f"{verb} LOGIN [fleetops_demo_runtime] WITH PASSWORD = '{password}'"
        )
    engine = _engine("fleetops_demo_001")
    with engine.begin() as connection:
        connection.execute(text("""
            IF USER_ID(N'fleetops_demo_runtime') IS NULL
                CREATE USER [fleetops_demo_runtime] FOR LOGIN [fleetops_demo_runtime]
        """))
        for role in ("fleetops_runtime", "fleetops_bootstrap"):
            connection.execute(text(f"""
                IF IS_ROLEMEMBER(N'{role}', N'fleetops_demo_runtime') <> 1
                    ALTER ROLE [{role}] ADD MEMBER [fleetops_demo_runtime]
            """))
        connection.execute(text("""
            GRANT SELECT ON dbo.alembic_version TO [fleetops_demo_runtime]
        """))
        _insert(connection, "ref.currencies", "code='USD'",
                {"code": "USD", "name": "US Dollar"})
        _insert(connection, "ref.asset_types", "code='TRACTOR'",
                {"code": "TRACTOR", "name": "Tractor"})
        _insert(connection, "ref.asset_types", "code='TRAILER'",
                {"code": "TRAILER", "name": "Trailer"})
        asset_type = connection.execute(text("""
            SELECT id FROM ref.asset_types WHERE code='TRACTOR'
        """)).scalar_one()
        for action in ("read", "create"):
            code = f"fleet.vehicle.{action}"
            _insert(connection, "iam.permissions", "code=:code", {
                "id": _id(f"permission:{code}"), "code": code,
                "resource": "fleet.vehicle", "action": action,
            })
        for action in ("read", "create"):
            code = f"demo.finance.{action}"
            _insert(connection, "iam.permissions", "code=:code", {
                "id": _id(f"permission:{code}"), "code": code,
                "resource": "demo.finance", "action": action,
            })
        for subject in USERS:
            _insert(connection, "iam.users",
                    "auth_provider='demo' AND external_subject=:external_subject", {
                        "id": _id(f"user:{subject}"), "auth_provider": "demo",
                        "external_subject": subject, "display_name": subject.replace("_", " ").title(),
                    })
        for tenant_id, name, slug in TENANTS:
            tenant = str(tenant_id)
            _insert(connection, "core.tenants", "id=:id", {
                "id": tenant, "name": name, "slug": slug,
                "timezone": "America/Chicago", "currency_code": "USD",
            })
            connection.execute(text("""
                DECLARE @selected UNIQUEIDENTIFIER = CONVERT(UNIQUEIDENTIFIER, :tenant);
                EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@selected
            """), {"tenant": tenant})
            for subject in USERS:
                _insert(connection, "iam.memberships", "id=:id", {
                    "id": _id(f"membership:{tenant}:{subject}"), "tenant_id": tenant,
                    "user_id": _id(f"user:{subject}"),
                })
            for role in ("creator", "reader"):
                _insert(connection, "iam.roles", "id=:id", {
                    "id": _id(f"role:{tenant}:{role}"), "tenant_id": tenant,
                    "code": role.upper(), "name": role.title(),
                })
                actions = ("read", "create") if role == "creator" else ("read",)
                for action in actions:
                    _insert(connection, "iam.role_permissions", "id=:id", {
                        "id": _id(f"grant:{tenant}:{role}:{action}"), "tenant_id": tenant,
                        "role_id": _id(f"role:{tenant}:{role}"),
                        "permission_id": _id(f"permission:fleet.vehicle.{action}"),
                    })
                if role == "creator":
                    for action in ("read", "create"):
                        _insert(connection, "iam.role_permissions", "id=:id", {
                            "id": _id(f"grant:{tenant}:{role}:finance:{action}"),
                            "tenant_id": tenant,
                            "role_id": _id(f"role:{tenant}:{role}"),
                            "permission_id": _id(f"permission:demo.finance.{action}"),
                        })
                _insert(connection, "iam.membership_roles", "id=:id", {
                    "id": _id(f"memberrole:{tenant}:{role}"), "tenant_id": tenant,
                    "membership_id": _id(f"membership:{tenant}:demo_{role}"),
                    "role_id": _id(f"role:{tenant}:{role}"),
                })
            unit = "DEMO-101" if slug == "northstar-demo" else "DEMO-202"
            asset = _id(f"asset:{tenant}")
            terminal_id = _id(f"terminal:{tenant}")
            _insert(connection, "core.terminals", "id=:id", {
                "id": terminal_id, "tenant_id": tenant,
                "code": "MAIN", "name": "Main terminal (Demo)",
                "timezone": "America/Chicago", "status": "ACTIVE",
            })
            _insert(connection, "fleet.assets", "id=:id", {
                "id": asset, "tenant_id": tenant, "unit_number": unit,
                "asset_type_id": asset_type, "make": "Freightliner",
                "model": "Cascadia", "model_year": 2024,
                "ownership_type": "OWNED", "currency_code": "USD",
                "terminal_id": terminal_id,
                "created_by": _id(f"membership:{tenant}:demo_creator"),
            })
            _insert(connection, "fleet.vehicles", "id=:id", {
                "id": _id(f"vehicle:{tenant}"), "tenant_id": tenant,
                "asset_id": asset,
                "created_by": _id(f"membership:{tenant}:demo_creator"),
            })
            _insert(connection, "demo.asset_state", "tenant_id=:tenant_id AND asset_id=:asset_id", {
                "tenant_id": tenant, "asset_id": asset,
                "odometer_miles": 128450, "service_due_miles": 130000,
                "service_due_date": "2026-12-15",
                "gps_latitude": 41.878113, "gps_longitude": -87.629799,
                "gps_source": "Fictional demo position",
                "gps_observed_at": "2026-11-22T12:00:00",
                "gps_received_at": "2026-11-22T12:02:00",
            })
            trailer_type = connection.execute(text("""
                SELECT id FROM ref.asset_types WHERE code='TRAILER'
            """)).scalar_one()
            _insert(connection, "fleet.assets", "id=:id", {
                "id": _id(f"trailer:{tenant}"), "tenant_id": tenant,
                "unit_number": "TRL-301" if slug == "northstar-demo" else "TRL-402",
                "asset_type_id": trailer_type, "make": "Great Dane", "model": "Dry van",
                "model_year": 2022, "ownership_type": "LEASED",
                "currency_code": "USD", "terminal_id": terminal_id,
                "created_by": _id(f"membership:{tenant}:demo_creator"),
            })
            _insert(connection, "demo.costs", "id=:id", {
                "id": _id(f"cost:{tenant}"), "tenant_id": tenant,
                "asset_id": asset, "category": "FUEL", "amount_usd": "325.50",
                "occurred_on": "2026-11-20",
                "created_by": _id(f"membership:{tenant}:demo_creator"),
            })
    print("Fictional demo carriers, users, permissions and vehicles are ready")


if __name__ == "__main__":
    if (os.environ.get("FLEETOPS_ENV"), os.environ.get("FLEETOPS_DATABASE_NAME")) != (
        "demo", "fleetops_demo_001"
    ):
        raise RuntimeError("Demo setup refuses non-demo targets")
    if sys.argv[1:] == ["bootstrap"]:
        bootstrap()
    elif sys.argv[1:] == ["seed"]:
        seed()
    else:
        raise SystemExit("Usage: python -m app.demo_setup bootstrap|seed")
