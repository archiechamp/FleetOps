from datetime import UTC, datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, StrictInt, StrictStr, field_serializer, field_validator

TRIM_CHARACTERS = "".join(
    chr(code_point)
    for code_point in [
        *range(0x0009, 0x000E),
        0x0020,
        0x00A0,
        0x1680,
        *range(0x2000, 0x200B),
        0x2028,
        0x2029,
        0x202F,
        0x205F,
        0x3000,
        0xFEFF,
    ]
)


def normalize_vehicle_text(value: str, maximum_units: int) -> str:
    try:
        value.encode("utf-16-le", errors="strict")
    except UnicodeEncodeError as error:
        raise ValueError("Must contain well-formed Unicode") from error
    normalized = value.strip(TRIM_CHARACTERS)
    code_units = len(normalized.encode("utf-16-le")) // 2
    if not 1 <= code_units <= maximum_units:
        raise ValueError(f"Must contain 1–{maximum_units} UTF-16 code units after trimming")
    return normalized


class VehicleCreate(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

    unit_number: StrictStr
    make: StrictStr
    model: StrictStr
    model_year: StrictInt
    ownership_type: Literal["OWNED", "LEASED", "CONTRACTED"]

    @field_validator("unit_number")
    @classmethod
    def validate_unit_number(cls, value: str) -> str:
        return normalize_vehicle_text(value, 30)

    @field_validator("make", "model")
    @classmethod
    def validate_make_or_model(cls, value: str) -> str:
        return normalize_vehicle_text(value, 80)

    @field_validator("model_year")
    @classmethod
    def validate_model_year(cls, value: int) -> int:
        if not 1900 <= value <= 2100:
            raise ValueError("Must be between 1900 and 2100")
        return value


class Vehicle(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: UUID
    tenant_id: UUID
    unit_number: StrictStr
    make: StrictStr
    model: StrictStr
    model_year: StrictInt
    ownership_type: Literal["OWNED", "LEASED", "CONTRACTED"]
    created_at: datetime

    @field_validator("unit_number")
    @classmethod
    def validate_unit_number(cls, value: str) -> str:
        return normalize_vehicle_text(value, 30)

    @field_validator("make", "model")
    @classmethod
    def validate_make_or_model(cls, value: str) -> str:
        return normalize_vehicle_text(value, 80)

    @field_validator("model_year")
    @classmethod
    def validate_model_year(cls, value: int) -> int:
        if not 1900 <= value <= 2100:
            raise ValueError("Must be between 1900 and 2100")
        return value

    @field_serializer("created_at")
    def serialize_created_at(self, value: datetime) -> str:
        utc_value = value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)
        return utc_value.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
