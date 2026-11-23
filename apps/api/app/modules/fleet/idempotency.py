import hashlib
import json
from datetime import UTC, datetime
from uuid import UUID

from app.modules.fleet.schemas import VehicleCreate

RECEIPT_EXPIRY_UTC = datetime(9999, 12, 31, 23, 59, 59, 999000, tzinfo=UTC)


def canonical_registration_json(vehicle: VehicleCreate) -> str:
    return json.dumps(
        [
            1,
            vehicle.unit_number,
            vehicle.make,
            vehicle.model,
            vehicle.model_year,
            vehicle.ownership_type,
        ],
        ensure_ascii=False,
        separators=(",", ":"),
    )


def registration_digest(vehicle: VehicleCreate) -> bytes:
    return hashlib.sha256(canonical_registration_json(vehicle).encode("utf-8")).digest()


def registration_operation_scope(membership_id: UUID) -> str:
    return f"vehicle.register:v1:{membership_id!s}"


def vehicle_reference(vehicle_id: UUID) -> str:
    return f"fleet.vehicles:{vehicle_id!s}"


def parse_submission_key(value: str) -> UUID:
    try:
        return UUID(value)
    except (ValueError, AttributeError) as error:
        raise ValueError("Idempotency-Key must be a UUID") from error


def parse_vehicle_reference(value: str) -> UUID:
    prefix = "fleet.vehicles:"
    if not value.startswith(prefix):
        raise ValueError("Invalid vehicle receipt reference")
    vehicle_id = parse_submission_key(value[len(prefix) :])
    if vehicle_reference(vehicle_id) != value:
        raise ValueError("Invalid vehicle receipt reference")
    return vehicle_id
