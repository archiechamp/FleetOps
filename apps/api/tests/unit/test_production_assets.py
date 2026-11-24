"""Hosted fleet overview reads only the verified carrier's assets (FLT-01/02)."""

from contextlib import contextmanager
from types import SimpleNamespace
from uuid import UUID

import pytest
from fastapi import HTTPException

from app.modules.fleet import production_routes

TENANT = UUID("a56c2a37-9aec-462f-8044-87ab76f9beef")


def test_assets_require_read_permission() -> None:
    member = SimpleNamespace(tenant_id=TENANT, permissions=frozenset())
    with pytest.raises(HTTPException) as error:
        production_routes.list_assets(member)
    assert error.value.status_code == 403


def test_assets_use_selected_verified_tenant(monkeypatch) -> None:
    member = SimpleNamespace(tenant_id=TENANT, permissions=frozenset({"fleet.vehicle.read"}))
    monkeypatch.setattr(production_routes, "get_production_engine", lambda: object())

    class Result:
        def mappings(self):
            return self

        def all(self):
            return [{"id": str(UUID("11111111-1111-4111-8111-111111111111")),
                     "unit_number": "DEMO-101", "asset_type": "TRACTOR",
                     "make": "Freightliner", "model": "Cascadia", "model_year": 2024,
                     "ownership_type": "OWNED", "status": "AVAILABLE"}]

    class Connection:
        def execute(self, statement, parameters):
            assert "WHERE a.tenant_id = :tenant" in str(statement)
            assert "FETCH NEXT 100 ROWS ONLY" in str(statement)
            assert parameters == {"tenant": str(TENANT)}
            return Result()

    @contextmanager
    def scoped_connection(engine, selected_tenant):
        assert selected_tenant == TENANT
        yield Connection()

    monkeypatch.setattr(production_routes, "tenant_connection", scoped_connection)
    rows = production_routes.list_assets(member)
    assert len(rows) == 1
    assert rows[0].unit_number == "DEMO-101"
    assert rows[0].asset_type == "TRACTOR"
