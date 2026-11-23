"""Exact SQL Server Core table definitions for the approved Feature 001 subset."""

import re

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    Column,
    ForeignKeyConstraint,
    Identity,
    Index,
    PrimaryKeyConstraint,
    SmallInteger,
    Table,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects import mssql

from app.db.base import Base


def sql_type(declaration: str):
    fixed = {
        "UNIQUEIDENTIFIER": mssql.UNIQUEIDENTIFIER,
        "DATETIME2(3)": lambda: mssql.DATETIME2(precision=3),
        "ROWVERSION": mssql.TIMESTAMP,
        "SMALLINT": SmallInteger,
        "BIGINT": BigInteger,
        "BIT": mssql.BIT,
        "DATE": mssql.DATE,
    }
    if declaration in fixed:
        return fixed[declaration]()
    match = re.fullmatch(r"(N?VARCHAR|CHAR|BINARY)\((MAX|\d+)\)", declaration)
    if match:
        kind, length = match.groups()
        return {
            "NVARCHAR": mssql.NVARCHAR,
            "VARCHAR": mssql.VARCHAR,
            "CHAR": mssql.CHAR,
            "BINARY": mssql.BINARY,
        }[kind](None if length == "MAX" else int(length))
    match = re.fullmatch(r"DECIMAL\((\d+),(\d+)\)", declaration)
    if match:
        return mssql.DECIMAL(int(match[1]), int(match[2]))
    raise ValueError(f"Unsupported SQL type: {declaration}")


def create_table(spec: dict) -> Table:
    schema, name = spec["table"].split(".")
    prefix = f"{schema}_{name}"
    columns = []
    for entry in spec["columns"]:
        args = [Identity(start=1, increment=1)] if entry["identity"] else []
        default = entry["default"]
        columns.append(
            Column(
                entry["name"],
                sql_type(entry["type"]),
                *args,
                nullable=entry["nullable"],
                server_default=text(default) if default is not None else None,
            )
        )
    constraints = [PrimaryKeyConstraint(spec["pk"], name=f"PK_{prefix}")]
    constraints.extend(
        UniqueConstraint(*key, name=f"UQ_{prefix}_{index}")
        for index, key in enumerate(spec["unique_keys"], 1)
    )
    constraints.extend(
        CheckConstraint(expression, name=f"CK_{prefix}_{index}")
        for index, expression in enumerate(spec["checks"], 1)
    )
    constraints.extend(
        ForeignKeyConstraint(
            foreign_key["columns"],
            [f"{foreign_key['target']}.{column}" for column in foreign_key["target_columns"]],
            name=f"FK_{prefix}_{index}",
            use_alter=True,
        )
        for index, foreign_key in enumerate(spec["foreign_keys"], 1)
    )
    table = Table(name, Base.metadata, *columns, *constraints, schema=schema)
    for index, entry in enumerate(spec["indexes"], 1):
        Index(
            f"IX_{prefix}_{index}",
            *(table.c[column] for column in entry["columns"]),
            unique=entry["unique"],
            mssql_where=text(entry["filter"]) if entry["filter"] else None,
        )
    return table
