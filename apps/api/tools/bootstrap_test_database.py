"""Create only the isolated fleetops_test_001 SQL Server integration database."""

import os

import pyodbc


def main() -> None:
    if (os.environ.get("FLEETOPS_ENV"), os.environ.get("FLEETOPS_DATABASE_NAME")) != (
            "test", "fleetops_test_001"):
        raise RuntimeError("Test bootstrap requires the isolated test database")
    password = os.environ["FLEETOPS_TEST_SA_PASSWORD"]
    connection = pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={os.environ.get('FLEETOPS_SQL_SERVER', 'sqlserver')};"
        f"UID=sa;PWD={password};DATABASE=master;"
        "Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=5",
        autocommit=True, timeout=5,
    )
    try:
        connection.cursor().execute("""
            IF DB_ID(N'fleetops_test_001') IS NULL
                EXEC(N'CREATE DATABASE [fleetops_test_001] COLLATE Latin1_General_100_CI_AS_SC')
        """)
    finally:
        connection.close()


if __name__ == "__main__":
    main()
