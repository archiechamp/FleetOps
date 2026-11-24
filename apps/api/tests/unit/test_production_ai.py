"""Read-only production AI behavior for AI-02/03/05/06 and AUTH-02."""

from uuid import UUID

from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.core import clerk_auth
from app.core.config import Settings
from app.main import create_app
from app.modules.ai import production_routes

TENANT = UUID("11111111-1111-4111-8111-111111111111")


def _client(monkeypatch) -> TestClient:
    monkeypatch.setattr("app.main.get_settings", lambda: Settings(env="production"))
    client = TestClient(create_app())
    client.app.dependency_overrides[clerk_auth.selected_clerk_member] = lambda: clerk_auth.ClerkMember(
        "user_123", TENANT, TENANT, TENANT, frozenset({"fleet.vehicle.read"})
    )
    monkeypatch.setattr(production_routes, "_prepare", lambda member, conversation, question: [])
    monkeypatch.setattr(production_routes, "_save", lambda *args: None)
    return client


def _body(question: str) -> dict:
    return {"id": "33333333-3333-4333-8333-333333333333",
            "messages": [{"role": "user", "parts": [{"type": "text", "text": question}]}]}


def test_mutation_refusal_does_not_query_fleet_or_model(monkeypatch) -> None:
    client = _client(monkeypatch)
    monkeypatch.setattr(production_routes, "gather_production_facts",
                        lambda *args: (_ for _ in ()).throw(AssertionError("unexpected SQL read")))
    response = client.post("/api/v1/ai/chat", json=_body("Assign truck 12"))
    assert response.status_code == 200
    assert "read-only" in response.text
    assert "[DONE]" in response.text


def test_unsupported_domain_answer_is_explicit(monkeypatch) -> None:
    client = _client(monkeypatch)
    monkeypatch.setattr(production_routes, "gather_production_facts",
                        lambda *args: (_ for _ in ()).throw(AssertionError("unexpected SQL read")))
    response = client.post("/api/v1/ai/chat", json=_body("Where was truck 12 last seen?"))
    assert response.status_code == 200
    assert "not connected" in response.text
    assert "12 last seen" not in response.text


def test_database_fallback_uses_authorized_facts_and_sources(monkeypatch) -> None:
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)
    client = _client(monkeypatch)
    monkeypatch.setattr(production_routes, "get_settings", lambda: Settings(env="production"))
    monkeypatch.setattr(production_routes, "gather_production_facts", lambda member, question: {
        "queried_at": "2026-11-24T00:00:00Z",
        "sources": [{"kind": "asset", "id": "44444444-4444-4444-8444-444444444444",
                     "label": "TRK-001", "view": "Fleet", "updated_at": None}],
        "facts": [{"tool": "getFleetSummary", "carrier": {"name": "Test carrier"},
                   "equipment_counts": [{"asset_count": 1, "asset_type": "TRACTOR",
                                         "status": "AVAILABLE"}],
                   "assets": [{"unit_number": "TRK-001", "asset_type": "TRACTOR",
                               "status": "AVAILABLE"}], "truncated": False}],
    })
    response = client.post("/api/v1/ai/chat", json=_body("Summarize the fleet"))
    assert response.status_code == 200
    assert "TRK-001" in response.text
    assert "Verified database summary" in response.text
    assert "data-sources" in response.text


def test_bad_question_and_wrong_carrier_are_denied(monkeypatch) -> None:
    client = _client(monkeypatch)
    assert client.post("/api/v1/ai/chat", json=_body("password=guess")).status_code == 422
    client.app.dependency_overrides[clerk_auth.selected_clerk_member] = lambda: (_ for _ in ()).throw(
        HTTPException(403, "Carrier access denied"))
    assert client.post("/api/v1/ai/chat", json=_body("Summarize fleet")).status_code == 403
