"""Least-privilege production SQL connection; no demo credentials or trust bypass."""

from functools import lru_cache

from sqlalchemy.engine import URL, Engine

from app.core.config import get_settings
from app.core.db import make_sql_engine


@lru_cache
def get_production_engine() -> Engine:
    settings = get_settings()
    if settings.env != "production":
        raise RuntimeError("Production SQL access requires production mode")
    if not settings.sql_runtime_user or not settings.sql_runtime_password:
        raise RuntimeError("Production SQL runtime credentials are required")
    if not settings.sql_encrypt or settings.sql_trust_server_certificate:
        raise RuntimeError("Production SQL requires verified TLS")
    return make_sql_engine(URL.create(
        "mssql+pyodbc",
        username=settings.sql_runtime_user,
        password=settings.sql_runtime_password.get_secret_value(),
        host=settings.sql_server,
        database=settings.database_name,
        query={
            "driver": "ODBC Driver 18 for SQL Server",
            "Encrypt": "yes",
            "TrustServerCertificate": "no",
            "LongAsMax": "Yes",
        },
    ))
