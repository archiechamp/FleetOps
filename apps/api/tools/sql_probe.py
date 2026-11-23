"""Probe only the isolated local test SQL Server; never mutate schema."""

import os

import pyodbc


def main() -> None:
    if os.environ.get("FLEETOPS_ENV") != "test":
        raise RuntimeError("SQL probe requires the isolated test environment")
    password = os.environ["FLEETOPS_TEST_SA_PASSWORD"]
    server = os.environ.get("FLEETOPS_SQL_SERVER", "sqlserver")
    connection_string = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={server};DATABASE=master;UID=sa;PWD={password};"
        "Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=5"
    )
    with pyodbc.connect(connection_string, timeout=5, autocommit=True) as connection:
        cursor = connection.cursor()
        cursor.execute(
            "SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar(40)), "
            "encrypt_option FROM sys.dm_exec_connections WHERE session_id=@@SPID"
        )
        version, encrypted = cursor.fetchone()
        if encrypted != "TRUE" or not version.startswith("16."):
            raise RuntimeError("Unsupported or unencrypted SQL Server connection")
        cursor.execute("EXEC sys.sp_set_session_context @key=N'tenant_id', @value=NULL")
        cursor.execute("SELECT CASE WHEN SESSION_CONTEXT(N'tenant_id') IS NULL THEN 1 ELSE 0 END")
        assert cursor.fetchone()[0] == 1
        print(f"ODBC 18 to SQL Server {version}: encrypted={encrypted}")


if __name__ == "__main__":
    main()
