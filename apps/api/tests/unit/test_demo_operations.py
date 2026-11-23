"""Validation that protects the local demo's write boundary."""

from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.modules.demo_operations.routes import AssignmentCreate, CostCreate, PositionCreate


def test_position_requires_zoned_nonfuture_observation() -> None:
    with pytest.raises(ValidationError):
        PositionCreate(latitude=41, longitude=-87, source="test",
                       observed_at=datetime(2026, 1, 1))
    with pytest.raises(ValidationError):
        PositionCreate(latitude=41, longitude=-87, source="test",
                       observed_at=datetime.now(UTC) + timedelta(minutes=1))
    with pytest.raises(ValidationError):
        PositionCreate(latitude=91, longitude=-87, source="test",
                       observed_at=datetime.now(UTC) - timedelta(minutes=1))


def test_assignment_requires_zoned_window_values() -> None:
    with pytest.raises(ValidationError):
        AssignmentCreate(trip_reference="T-1", truck_asset_id=uuid4(),
                         starts_at=datetime(2026, 1, 1), ends_at=datetime(2026, 1, 2))


def test_cost_uses_decimal_and_rejects_invalid_amounts() -> None:
    valid = CostCreate(asset_id=uuid4(), category="FUEL", amount_usd=Decimal("25.75"),
                       occurred_on="2026-11-23")
    assert valid.amount_usd == Decimal("25.75")
    for amount in (Decimal(0), Decimal("1.001")):
        with pytest.raises(ValidationError):
            CostCreate(asset_id=uuid4(), category="FUEL", amount_usd=amount,
                       occurred_on="2026-11-23")
