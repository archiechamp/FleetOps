import hashlib
import json
from pathlib import Path
from uuid import UUID

from app.modules.fleet.idempotency import (
    RECEIPT_EXPIRY_UTC,
    canonical_registration_json,
    parse_submission_key,
    parse_vehicle_reference,
    registration_digest,
    registration_operation_scope,
    vehicle_reference,
)
from app.modules.fleet.schemas import VehicleCreate

VECTORS = json.loads(
    (Path(__file__).resolve().parents[4] / "tests/fixtures/vehicle_registration_vectors.json").read_text(
        encoding="utf-8"
    )
)


def test_canonical_registration_digest():
    for case in VECTORS["hash_cases"]:
        vehicle = VehicleCreate.model_validate(case["payload"])
        assert canonical_registration_json(vehicle) == case["canonical_json"]
        digest = registration_digest(vehicle)
        assert digest == hashlib.sha256(case["canonical_json"].encode("utf-8")).digest()
        assert digest.hex() == case["sha256_hex"]
        assert len(digest) == 32

    payload = VECTORS["hash_cases"][0]["payload"]
    original = VehicleCreate.model_validate(payload)
    assert registration_digest(original) == registration_digest(
        VehicleCreate.model_validate_json(json.dumps(payload, indent=2, ensure_ascii=False))
    )
    assert registration_digest(original) == registration_digest(
        VehicleCreate.model_validate({**payload, "unit_number": "TRK-001"})
    )
    assert registration_digest(original) != registration_digest(
        VehicleCreate.model_validate({**payload, "unit_number": "trk-001"})
    )
    assert registration_digest(original) != registration_digest(
        VehicleCreate.model_validate({**payload, "model": "Road 2"})
    )
    for changed in (
        {"make": "Other"},
        {"model_year": 2026},
        {"ownership_type": "LEASED"},
    ):
        assert registration_digest(original) != registration_digest(
            VehicleCreate.model_validate({**payload, **changed})
        )
    member_id = UUID("D6A7E493-5958-48E3-942D-6E3FB6489438")
    vehicle_id = UUID("DC2E5B3F-300B-47BE-9896-77D1BE320C87")
    assert registration_operation_scope(member_id) == "vehicle.register:v1:d6a7e493-5958-48e3-942d-6e3fb6489438"
    assert vehicle_reference(vehicle_id) == "fleet.vehicles:dc2e5b3f-300b-47be-9896-77d1be320c87"
    assert parse_submission_key(str(vehicle_id).upper()) == vehicle_id
    assert parse_vehicle_reference(vehicle_reference(vehicle_id)) == vehicle_id
    assert RECEIPT_EXPIRY_UTC.isoformat() == "9999-12-31T23:59:59.999000+00:00"
    for invalid_key in ["", "not-a-uuid", "fleet.vehicles:" + str(vehicle_id)]:
        try:
            parse_submission_key(invalid_key)
        except ValueError:
            pass
        else:
            raise AssertionError(f"Accepted invalid submission key {invalid_key!r}")
    for invalid_reference in ["fleet.assets:" + str(vehicle_id), "fleet.vehicles:" + str(vehicle_id).upper()]:
        try:
            parse_vehicle_reference(invalid_reference)
        except ValueError:
            pass
        else:
            raise AssertionError(f"Accepted invalid reference {invalid_reference}")
