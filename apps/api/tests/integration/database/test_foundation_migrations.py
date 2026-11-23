"""Live SQL Server schema checks for the approved Feature 001 migration subset."""

import os

import pyodbc
import pytest

pytestmark = pytest.mark.integration


@pytest.fixture(scope="module")
def database():
    if os.environ.get("FLEETOPS_ENV") != "test":
        raise RuntimeError("Integration tests require the isolated test environment")
    connection_string = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={os.environ['FLEETOPS_SQL_SERVER']};"
        f"DATABASE={os.environ['FLEETOPS_DATABASE_NAME']};"
        f"UID=sa;PWD={os.environ['FLEETOPS_TEST_SA_PASSWORD']};"
        "Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=5"
    )
    connection = pyodbc.connect(connection_string, timeout=5)
    try:
        yield connection
    finally:
        connection.close()


def scalar(database, query: str):
    return database.cursor().execute(query).fetchone()[0]


def test_foundation_contract_and_runtime_grants(database) -> None:
    assert scalar(database, "SELECT version_num FROM dbo.alembic_version") == "0003_vehicle_retry"
    assert scalar(database, "SELECT COUNT(*) FROM sys.tables WHERE name <> 'alembic_version'") == 18
    assert scalar(
        database,
        "SELECT COUNT(*) FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id "
        "WHERE t.name <> 'alembic_version'",
    ) == 166
    assert scalar(database, "SELECT COUNT(*) FROM sys.foreign_keys") == 42
    assert scalar(database, "SELECT COUNT(*) FROM sys.security_predicates") == 50
    assert scalar(
        database,
        "SELECT COUNT(*) FROM sys.security_predicates "
        "WHERE target_object_id=OBJECT_ID(N'integration.idempotency_keys')",
    ) == 5
    assert scalar(
        database,
        "SELECT COUNT(*) FROM sys.database_permissions p "
        "JOIN sys.database_principals r ON r.principal_id=p.grantee_principal_id "
        "WHERE r.name='fleetops_runtime' "
        "AND p.major_id=OBJECT_ID(N'integration.idempotency_keys') "
        "AND p.permission_name IN ('SELECT','INSERT') AND p.state='G'",
    ) == 2


def test_idempotency_schema_and_grants(database) -> None:
    rows = database.cursor().execute(
        "SELECT c.name, ty.name, c.max_length, c.is_nullable "
        "FROM sys.columns c JOIN sys.types ty ON ty.user_type_id=c.user_type_id "
        "WHERE c.object_id=OBJECT_ID(N'integration.idempotency_keys')"
    ).fetchall()
    columns = {row[0]: (row[1], row[2], row[3]) for row in rows}
    assert len(columns) == 12
    assert columns["request_hash"] == ("binary", 32, False)
    assert columns["request_key"] == ("nvarchar", 300, False)
    assert columns["response_reference"] == ("nvarchar", 300, True)
    assert columns["expires_at"][0] == "datetime2"
    assert columns["expires_at"][2] is False
    assert scalar(
        database,
        "SELECT COUNT(*) FROM sys.key_constraints WHERE parent_object_id="
        "OBJECT_ID(N'integration.idempotency_keys') AND type='UQ'",
    ) == 2
