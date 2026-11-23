"""Copilot input and provider boundary cases without a live model."""

import asyncio
import json
from uuid import uuid4

import httpx
import pytest
from fastapi import HTTPException
from pydantic import SecretStr

from app.modules.ai import provider
from app.modules.ai.database_answer import answer_from_database, matches_reference
from app.modules.ai.routes import _MUTATION_PATTERN, ChatRequest, _question


def _body(text: str) -> ChatRequest:
    return ChatRequest(id=uuid4(), messages=[{"role": "user", "parts": [
        {"type": "text", "text": text}]}])


def test_rejects_credentials_and_nontext_parts() -> None:
    with pytest.raises(HTTPException) as credential:
        _question(_body("api_key=sk-example-secret-value-123456789"))
    assert credential.value.status_code == 422
    body = ChatRequest(id=uuid4(), messages=[{"role": "user", "parts": [
        {"type": "file", "url": "https://example.invalid"}]}])
    with pytest.raises(HTTPException) as attachment:
        _question(body)
    assert attachment.value.status_code == 422


def test_mutation_requests_are_not_sent_to_the_model() -> None:
    assert _MUTATION_PATTERN.search("Assign truck DEMO-101")
    assert _MUTATION_PATTERN.search("Please cancel trip 12")
    assert not _MUTATION_PATTERN.search("Which truck was assigned yesterday?")


def test_openai_request_disables_provider_storage_and_tools(monkeypatch) -> None:
    captured = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured.update(json.loads(request.content))
        return httpx.Response(200, json={"status": "completed", "output": [
            {"type": "message", "content": [{"type": "output_text", "text": "Two trucks."}]}]})

    original = httpx.AsyncClient
    monkeypatch.setattr(provider.httpx, "AsyncClient",
                        lambda **kwargs: original(transport=httpx.MockTransport(handler), **kwargs))
    monkeypatch.setattr(provider, "get_settings", lambda: type("Settings", (), {
        "openai_api_key": SecretStr("test-only-key"), "ai_model": "test-model"})())
    answer = asyncio.run(provider.OpenAIProvider().answer("How many trucks?", [],
                                                          {"facts": [{"count": 2}]}))
    assert answer == "Two trucks."
    assert captured["store"] is False
    assert captured["max_output_tokens"] == 450
    assert "tools" not in captured


def test_provider_unavailable_is_sanitized(monkeypatch) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        del request
        return httpx.Response(403, json={"error": {"message": "private provider detail"}})

    original = httpx.AsyncClient
    monkeypatch.setattr(provider.httpx, "AsyncClient",
                        lambda **kwargs: original(transport=httpx.MockTransport(handler), **kwargs))
    monkeypatch.setattr(provider, "get_settings", lambda: type("Settings", (), {
        "openai_api_key": SecretStr("test-only-key"), "ai_model": "test-model"})())
    with pytest.raises(provider.ProviderUnavailable) as error:
        asyncio.run(provider.OpenAIProvider().answer("Fleet?", [], {"facts": []}))
    assert "private provider detail" not in str(error.value)


def test_exhausted_provider_credit_is_reported_without_retry(monkeypatch) -> None:
    requests = []

    def handler(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        return httpx.Response(429, json={"error": {
            "code": "credit_balance_exhausted", "type": "insufficient_quota"}})

    original = httpx.AsyncClient
    monkeypatch.setattr(provider.httpx, "AsyncClient",
                        lambda **kwargs: original(transport=httpx.MockTransport(handler), **kwargs))
    monkeypatch.setattr(provider, "get_settings", lambda: type("Settings", (), {
        "openai_api_key": SecretStr("test-only-key"), "ai_model": "test-model"})())
    with pytest.raises(provider.ProviderQuotaExceeded):
        asyncio.run(provider.OpenAIProvider().answer("Fleet?", [], {"facts": []}))
    assert len(requests) == 1


def test_database_answer_labels_stale_gps_and_uses_recorded_source() -> None:
    bundle = {"facts": [{"tool": "getVehicleLocation", "truncated": False,
                         "vehicles": [{"unit_number": "DEMO-101", "gps_latitude": "40.1",
                                       "gps_longitude": "-75.2", "gps_source": "demo",
                                       "gps_observed_at": "2020-01-01T00:00:00Z"}]}]}
    answer = answer_from_database("Where was DEMO-101 last seen?", bundle,
                                  "AI provider credit is exhausted.")
    assert "verified database records" in answer
    assert "DEMO-101: stale position 40.1, -75.2" in answer
    assert "live" not in answer


def test_database_answer_matches_saved_trip_and_does_not_invent_other_trips() -> None:
    bundle = {"facts": [{"tool": "getAvailableVehicles", "truncated": False,
                         "assets": [], "assignment_windows": [{
                             "trip_reference": "Trip Demo 1", "truck_unit": "DEMO-101",
                             "trailer_unit": None, "starts_at": "2026-11-24T01:00:00Z",
                             "ends_at": "2026-11-24T02:00:00Z"}]}]}
    answer = answer_from_database("Tell me about Trip Demo 1", bundle, "AI unavailable.")
    assert "Trip Demo 1: truck DEMO-101" in answer
    missing = answer_from_database("Tell me about Trip Unknown", bundle, "AI unavailable.")
    assert "No matching trip assignment" in missing
    assert "DEMO-101" not in missing


def test_database_answer_finance_discloses_incomplete_basis() -> None:
    bundle = {"facts": [{"tool": "getTripFinancialSummary", "currency": "USD",
                         "recorded_costs_by_category": [{"category": "FUEL", "entry_count": 2,
                                                         "amount_usd": "150.25"}]}]}
    answer = answer_from_database("What were our costs?", bundle, "AI unavailable.")
    assert "USD 150.25" in answer
    assert "Cost completeness is unknown" in answer
    assert "profit are unavailable" in answer


def test_unit_number_match_is_exact_and_generic_vehicle_answer_is_specific() -> None:
    assert matches_reference("Tell me about UnitNumber-1", "UnitNumber-1")
    assert not matches_reference("Tell me about UnitNumber-10", "UnitNumber-1")
    assert not matches_reference("Tell me about UnitNumber-1", "1")
    bundle = {"facts": [
        {"tool": "getFleetSummary", "carrier": {"name": "Test Carrier"},
         "equipment_counts": []},
        {"tool": "getAvailableVehicles", "truncated": False,
         "assets": [{"id": "a1", "unit_number": "UnitNumber-1",
                     "asset_type": "TRACTOR", "status": "AVAILABLE"}],
         "assignment_windows": []},
    ]}
    answer = answer_from_database("Tell me something about UnitNumber-1", bundle,
                                  "AI provider credit is exhausted.")
    assert "UnitNumber-1: TRACTOR, status AVAILABLE" in answer
    assert "equipment counts" not in answer
