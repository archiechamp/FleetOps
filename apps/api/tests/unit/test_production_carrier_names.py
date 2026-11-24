"""Carrier labels are resolved from verified tenant membership on the server."""

from contextlib import contextmanager
from types import SimpleNamespace
from uuid import UUID

import pytest
from fastapi import HTTPException

from app.modules.fleet import production_routes


def test_me_returns_names_only_for_verified_memberships(monkeypatch) -> None:
    tenant = UUID("a56c2a37-9aec-462f-8044-87ab76f9beef")
    member = SimpleNamespace(tenant_id=tenant, permissions=frozenset({"fleet.vehicle.read"}))
    monkeypatch.setattr(production_routes, "verified_memberships", lambda subject: [member])
    monkeypatch.setattr(production_routes, "get_production_engine", lambda: object())

    class Result:
        def scalar_one_or_none(self):
            return "FleetOps Staging (Fictional Demo)"

    class Connection:
        def execute(self, statement, parameters):
            assert "core.tenants" in str(statement)
            assert parameters == {"tenant": str(tenant)}
            return Result()

    @contextmanager
    def scoped_connection(engine, selected_tenant):
        assert selected_tenant == tenant
        yield Connection()

    monkeypatch.setattr(production_routes, "tenant_connection", scoped_connection)
    assert production_routes.me("user_verified") == {"carriers": [{
        "id": str(tenant), "name": "FleetOps Staging (Fictional Demo)",
        "permissions": ["fleet.vehicle.read"],
    }]}


def test_me_rejects_subject_without_membership(monkeypatch) -> None:
    monkeypatch.setattr(production_routes, "verified_memberships", lambda subject: [])
    with pytest.raises(HTTPException) as error:
        production_routes.me("user_without_membership")
    assert error.value.status_code == 403
