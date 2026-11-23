import os
from uuid import UUID

import pytest
from sqlalchemy.engine import URL

from app.core import db as db_module
from app.core.db import make_sql_engine, tenant_connection

pytestmark = pytest.mark.integration


@pytest.fixture
def engine():
    if os.environ.get("FLEETOPS_ENV") != "test":
        raise RuntimeError("Tenant pool tests require the isolated test environment")
    url = URL.create(
        "mssql+pyodbc",
        username="sa",
        password=os.environ["FLEETOPS_TEST_SA_PASSWORD"],
        host=os.environ["FLEETOPS_SQL_SERVER"],
        database=os.environ["FLEETOPS_DATABASE_NAME"],
        query={
            "driver": "ODBC Driver 18 for SQL Server",
            "Encrypt": "yes",
            "TrustServerCertificate": "yes",
        },
    )
    test_engine = make_sql_engine(url, pool_size=1)
    try:
        yield test_engine
    finally:
        test_engine.dispose()


def test_pool_reuse_is_tenant_safe(engine) -> None:
    tenant_a = UUID("11111111-1111-4111-8111-111111111111")
    tenant_b = UUID("22222222-2222-4222-8222-222222222222")
    for tenant in (tenant_a, tenant_b, tenant_a):
        with tenant_connection(engine, tenant) as connection:
            row = connection.exec_driver_sql(
                "SELECT CONVERT(VARCHAR(36), SESSION_CONTEXT(N'tenant_id')), "
                "SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'tenant_id'), 'BaseType')"
            ).one()
            assert row == (str(tenant), "uniqueidentifier")
        with engine.connect() as connection:
            assert connection.exec_driver_sql(
                "SELECT CASE WHEN SESSION_CONTEXT(N'tenant_id') IS NULL THEN 1 ELSE 0 END"
            ).scalar_one() == 1
    with pytest.raises(TypeError), tenant_connection(engine, "forged-tenant"):
        pass


def test_failed_reset_discards_connection(engine, monkeypatch) -> None:
    clear_context = db_module._clear_dbapi_context

    def fail_reset(_connection) -> None:
        raise RuntimeError("Injected context reset failure")

    with engine.connect() as connection:
        original_dbapi = connection.connection.dbapi_connection
        monkeypatch.setattr(db_module, "_clear_dbapi_context", fail_reset)
    monkeypatch.setattr(db_module, "_clear_dbapi_context", clear_context)
    with engine.connect() as connection:
        assert connection.connection.dbapi_connection is not original_dbapi
        assert connection.exec_driver_sql(
            "SELECT CASE WHEN SESSION_CONTEXT(N'tenant_id') IS NULL THEN 1 ELSE 0 END"
        ).scalar_one() == 1
