import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import UUID

from pydantic import ValidationError

from app.modules.fleet.schemas import Vehicle, VehicleCreate, normalize_vehicle_text

VECTORS = json.loads(
    (Path(__file__).resolve().parents[4] / "tests/fixtures/vehicle_registration_vectors.json").read_text(
        encoding="utf-8"
    )
)
BASE_PAYLOAD = {
    "unit_number": "TRK-123",
    "make": "Acme",
    "model": "Road",
    "model_year": 2025,
    "ownership_type": "OWNED",
}


def test_registration_field_boundaries():
    for field in BASE_PAYLOAD:
        try:
            VehicleCreate.model_validate({key: value for key, value in BASE_PAYLOAD.items() if key != field})
        except ValidationError as error:
            assert any(issue["loc"] == (field,) for issue in error.errors())
        else:
            raise AssertionError(f"Missing {field} was accepted")

    for case in VECTORS["cases"]:
        value = "".join(part["text"] * part["repeat"] for part in case["parts"])
        for field in case["fields"]:
            payload = {**BASE_PAYLOAD, field: value}
            if case["valid"]:
                vehicle = VehicleCreate.model_validate(payload)
                normalized = getattr(vehicle, field)
                assert len(normalized.encode("utf-16-le")) // 2 == case["expected_units"]
                if "expected_normalized" in case:
                    assert normalized == case["expected_normalized"]
            else:
                try:
                    VehicleCreate.model_validate(payload)
                except ValidationError as error:
                    assert any(issue["loc"] == (field,) for issue in error.errors())
                else:
                    raise AssertionError(f"{case['id']} unexpectedly accepted for {field}")

    for field, values in {
        "unit_number": [None, 123],
        "make": [None, 123],
        "model": [None, 123],
        "model_year": [True, 1899, 2101, 2025.0, "2025", None],
        "ownership_type": ["Owned", "RENTED", "", None],
    }.items():
        for value in values:
            try:
                VehicleCreate.model_validate({**BASE_PAYLOAD, field: value})
            except ValidationError:
                pass
            else:
                raise AssertionError(f"{field} accepted {value!r}")
    for year in [1900, 2100]:
        assert VehicleCreate.model_validate({**BASE_PAYLOAD, "model_year": year}).model_year == year
    for ownership in ["OWNED", "LEASED", "CONTRACTED"]:
        assert VehicleCreate.model_validate({**BASE_PAYLOAD, "ownership_type": ownership}).ownership_type == ownership
    for extra_field in ["tenant_id", "asset_id", "status", "created_by"]:
        try:
            VehicleCreate.model_validate({**BASE_PAYLOAD, extra_field: "forged"})
        except ValidationError:
            pass
        else:
            raise AssertionError(f"Accepted forbidden {extra_field}")


def test_unit_number_normalization():
    assert normalize_vehicle_text(" \u00a0TrK-1\ufeff", 30) == "TrK-1"
    assert normalize_vehicle_text("\u0085A\u0085", 30) == "\u0085A\u0085"
    assert VehicleCreate.model_validate({**BASE_PAYLOAD, "unit_number": "  TrK-1 "}).unit_number == "TrK-1"
    for code_point in VECTORS["trim_code_points"]:
        whitespace = chr(int(code_point, 16))
        assert normalize_vehicle_text(f"{whitespace}A{whitespace}", 30) == "A"
    assert normalize_vehicle_text("e\u0301", 30) == "e\u0301"
    assert normalize_vehicle_text("é", 30) == "é"
    assert normalize_vehicle_text("e\u0301", 30) != normalize_vehicle_text("é", 30)


def test_vehicle_response_uses_utc_milliseconds():
    vehicle = Vehicle.model_validate(
        {
            **BASE_PAYLOAD,
            "id": UUID("dc2e5b3f-300b-47be-9896-77d1be320c87"),
            "tenant_id": UUID("d6a7e493-5958-48e3-942d-6e3fb6489438"),
            "created_at": datetime(2025, 1, 2, 3, 4, 5, 123456, tzinfo=timezone(timedelta(hours=2))),
        }
    )
    assert vehicle.model_dump(mode="json")["created_at"] == "2025-01-02T01:04:05.123Z"
