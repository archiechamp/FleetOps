"""Guarded SQL Server migration target selection."""

import os

from sqlalchemy.engine import URL


def migration_target() -> tuple[URL, str]:
    environment = os.environ.get("FLEETOPS_ENV")
    database = os.environ.get("FLEETOPS_DATABASE_NAME", "")
    server = os.environ.get("FLEETOPS_SQL_SERVER", "sqlserver")
    if (environment, database) in {
        ("test", "fleetops_test_001"), ("demo", "fleetops_demo_001")
    }:
        password = os.environ.get("FLEETOPS_TEST_SA_PASSWORD")
        if not password:
            raise RuntimeError("Isolated SQL test password is required")
        return URL.create(
            "mssql+pyodbc", username="sa", password=password, host=server,
            database=database, query={
                "driver": "ODBC Driver 18 for SQL Server",
                "Encrypt": "yes", "TrustServerCertificate": "yes",
            },
        ), ("production@head" if environment == "test" and
             os.environ.get("FLEETOPS_TEST_MIGRATION_BRANCH") == "production" else "demo@head")
    if environment != "production" or not database or database in {
        "fleetops_test_001", "fleetops_demo_001"
    }:
        raise RuntimeError("Migration target is not an approved isolated or production database")
    if os.environ.get("FLEETOPS_MIGRATION_APPROVED_TARGET") != database:
        raise RuntimeError("Production migration target must be explicitly approved")
    if (os.environ.get("FLEETOPS_SQL_ENCRYPT", "yes").lower() not in {"yes", "true"}
            or os.environ.get("FLEETOPS_SQL_TRUST_SERVER_CERTIFICATE", "no").lower()
            not in {"no", "false"}):
        raise RuntimeError("Production migrations require verified SQL TLS")
    username = os.environ.get("FLEETOPS_SQL_MIGRATION_USER")
    password = os.environ.get("FLEETOPS_SQL_MIGRATION_PASSWORD")
    if not username or not password or username.lower() == "sa":
        raise RuntimeError("Dedicated SQL migration credentials are required")
    return URL.create(
        "mssql+pyodbc", username=username, password=password, host=server,
        database=database, query={
            "driver": "ODBC Driver 18 for SQL Server",
            "Encrypt": "yes", "TrustServerCertificate": "no",
        },
    ), "production@head"
