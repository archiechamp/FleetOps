"""Isolated demo SQL connection. Never use the demo principal outside demo mode."""

from functools import lru_cache

from sqlalchemy.engine import URL, Engine

from app.core.config import get_settings
from app.core.db import make_sql_engine


@lru_cache
def get_demo_engine() -> Engine:
    settings = get_settings()
    if settings.env != "demo" or settings.database_name != "fleetops_demo_001":
        raise RuntimeError("Demo SQL access is restricted to fleetops_demo_001")
    return make_sql_engine(URL.create(
        "mssql+pyodbc",
        username="fleetops_demo_runtime",
        password=settings.demo_runtime_password,
        host=settings.sql_server,
        database=settings.database_name,
        query={
            "driver": "ODBC Driver 18 for SQL Server",
            "Encrypt": "yes",
            "TrustServerCertificate": "yes",
        },
    ))


class _EngineProxy:
    def connect(self):
        return get_demo_engine().connect()


engine = _EngineProxy()
