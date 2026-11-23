"""SQL Server connection lifecycle with fail-closed tenant context cleanup."""

from collections.abc import Iterator
from contextlib import contextmanager
from uuid import UUID

import pyodbc
from sqlalchemy import create_engine, event
from sqlalchemy.engine import URL, Connection, Engine
from sqlalchemy.exc import DisconnectionError
from sqlalchemy.pool import QueuePool

pyodbc.pooling = False

_CLEAR_CONTEXT = "EXEC sys.sp_set_session_context @key=N'tenant_id', @value=NULL"
_VERIFY_CLEAR = "SELECT CASE WHEN SESSION_CONTEXT(N'tenant_id') IS NULL THEN 1 ELSE 0 END"
_BIND_CONTEXT = (
    "DECLARE @tenant UNIQUEIDENTIFIER = CONVERT(UNIQUEIDENTIFIER, ?); "
    "EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@tenant"
)


def _clear_dbapi_context(dbapi_connection) -> None:
    cursor = dbapi_connection.cursor()
    try:
        cursor.execute(_CLEAR_CONTEXT)
        cursor.execute(_VERIFY_CLEAR)
        if cursor.fetchone()[0] != 1:
            raise RuntimeError("SQL tenant context could not be cleared")
    finally:
        cursor.close()


def make_sql_engine(url: URL, *, pool_size: int = 5) -> Engine:
    """Create a bounded pool; caller supplies a least-privilege SQL principal URL."""
    engine = create_engine(
        url,
        poolclass=QueuePool,
        pool_size=pool_size,
        max_overflow=0,
        pool_timeout=5,
        pool_pre_ping=True,
        connect_args={"timeout": 5},
    )

    @event.listens_for(engine, "checkout")
    def clear_on_checkout(dbapi_connection, connection_record, connection_proxy) -> None:
        del connection_proxy
        try:
            _clear_dbapi_context(dbapi_connection)
        except (pyodbc.Error, RuntimeError) as error:
            connection_record.invalidate(error)
            raise DisconnectionError("SQL tenant context reset failed") from error

    @event.listens_for(engine, "checkin")
    def clear_on_checkin(dbapi_connection, connection_record) -> None:
        if dbapi_connection is None:
            return
        try:
            _clear_dbapi_context(dbapi_connection)
        except (pyodbc.Error, RuntimeError) as error:
            connection_record.invalidate(error)

    return engine


@contextmanager
def tenant_connection(engine: Engine, tenant_id: UUID) -> Iterator[Connection]:
    if not isinstance(tenant_id, UUID):
        raise TypeError("Verified tenant context must be a UUID")
    with engine.connect() as connection:
        connection.exec_driver_sql(_BIND_CONTEXT, (str(tenant_id),))
        try:
            yield connection
        finally:
            connection.rollback()
