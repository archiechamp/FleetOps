"""Copilot input and provider boundary cases without a live model."""

import asyncio
import json
from uuid import uuid4

import httpx
import pytest
from fastapi import HTTPException
from pydantic import SecretStr

from app.modules.ai import provider
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
