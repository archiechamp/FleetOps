import pyodbc
from sqlalchemy import create_engine
from sqlalchemy.pool import NullPool

import app.db.models  # noqa: F401 - registers the approved model subset
from alembic import context
from app.core.migration_config import migration_target
from app.db.base import Base

config = context.config
target_metadata = Base.metadata


def run_migrations_online() -> None:
    url, expected_head = migration_target()
    requested_head = context.get_x_argument(as_dictionary=True).get("target")
    if requested_head != expected_head:
        raise RuntimeError(f"Migration requires -x target={expected_head}")
    pyodbc.pooling = False
    engine = create_engine(url, poolclass=NullPool)
    with engine.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata, include_schemas=True)
        with context.begin_transaction():
            context.run_migrations()
    engine.dispose()


if context.is_offline_mode():
    raise RuntimeError("Offline SQL generation is not approved for Feature 001")
run_migrations_online()
