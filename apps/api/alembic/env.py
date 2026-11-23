import os

import pyodbc
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.pool import NullPool

import app.db.models  # noqa: F401 - registers the approved model subset
from alembic import context
from app.db.base import Base

config = context.config
target_metadata = Base.metadata


def run_migrations_online() -> None:
    environment = os.environ.get("FLEETOPS_ENV")
    database = os.environ.get("FLEETOPS_DATABASE_NAME")
    if (environment, database) not in {
        ("test", "fleetops_test_001"), ("demo", "fleetops_demo_001")
    }:
        raise RuntimeError("Migration target must be the isolated test or demo database")
    pyodbc.pooling = False
    url = URL.create(
        "mssql+pyodbc",
        username="sa",
        password=os.environ["FLEETOPS_TEST_SA_PASSWORD"],
        host=os.environ.get("FLEETOPS_SQL_SERVER", "sqlserver"),
        database=database,
        query={
            "driver": "ODBC Driver 18 for SQL Server",
            "Encrypt": "yes",
            "TrustServerCertificate": "yes",
        },
    )
    engine = create_engine(url, poolclass=NullPool)
    with engine.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata, include_schemas=True)
        with context.begin_transaction():
            context.run_migrations()
    engine.dispose()


if context.is_offline_mode():
    raise RuntimeError("Offline SQL generation is not approved for Feature 001")
run_migrations_online()
