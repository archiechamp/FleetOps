"""Real FastAPI, demo membership and SQL path with a deterministic model boundary."""

import json
from uuid import UUID, uuid4

from fastapi.testclient import TestClient
from pydantic import SecretStr

from app.core.demo_auth import _memberships
from app.main import create_app
from app.modules.ai import routes
from app.modules.ai.database_answer import answer_from_database
from app.modules.ai.facts import gather_facts
from app.modules.ai.provider import ProviderQuotaExceeded


class FakeProvider:
    def __init__(self) -> None:
        self.calls = []

    async def answer(self, question, history, facts) -> str:
        self.calls.append((question, history, facts))
        return "The saved demo carrier has fleet records."


def _enable_fake_model(monkeypatch) -> None:
    monkeypatch.setattr(routes, "get_settings", lambda: type("Settings", (), {
        "openai_api_key": SecretStr("test-only-key")})())


def _login(client: TestClient, username: str) -> str:
    response = client.post("/api/v1/demo/login", json={
        "username": username},
        headers={"X-Demo-Request": "fleetops-ui"})
    assert response.status_code == 200
    return client.get("/api/v1/me").json()["carriers"][0]["id"]


def _request(conversation_id: str, text: str) -> dict:
    return {"id": conversation_id, "messages": [{"id": str(uuid4()),
             "role": "user", "parts": [{"type": "text", "text": text}]}]}


def _events(response) -> list[dict]:
    return [json.loads(line[6:]) for line in response.text.splitlines()
            if line.startswith("data: {")]


def test_grounded_stream_history_feedback_and_member_isolation(monkeypatch) -> None:
    fake = FakeProvider()
    monkeypatch.setattr(routes, "get_provider", lambda: fake)
    _enable_fake_model(monkeypatch)
    conversation_id = str(uuid4())
    app = create_app()
    with TestClient(app) as creator:
        tenant = _login(creator, "demo_creator")
        headers = {"X-Tenant-Id": tenant, "X-Demo-Request": "fleetops-ui"}
        try:
            response = creator.post("/api/v1/ai/chat", headers=headers,
                                    json=_request(conversation_id, "Which trucks need service?"))
            assert response.status_code == 200
            assert response.headers["x-vercel-ai-ui-message-stream"] == "v1"
            events = _events(response)
            assert events[0]["type"] == "start"
            sources = next(item["data"] for item in events if item["type"] == "data-sources")
            assert sources["records"]
            assert all(item["view"] in ("Overview", "Fleet", "Dispatch", "Maintenance")
                       for item in sources["records"])
            assert fake.calls and any(fact["tool"] == "getMaintenanceDue"
                                      for fact in fake.calls[0][2]["facts"])
            assert "file_bytes" not in json.dumps(fake.calls[0][2])
            history = creator.get(f"/api/v1/ai/conversations/{conversation_id}", headers=headers)
            assert history.status_code == 200
            assert len(history.json()["messages"]) == 2
            answer_id = events[0]["messageId"]
            assert creator.post("/api/v1/ai/feedback", headers=headers,
                                json={"message_id": answer_id, "helpful": True}).status_code == 200
            with TestClient(app) as reader:
                _login(reader, "demo_reader")
                assert reader.get(f"/api/v1/ai/conversations/{conversation_id}",
                                  headers={"X-Tenant-Id": tenant}).status_code == 404
        finally:
            assert creator.delete(f"/api/v1/ai/conversations/{conversation_id}",
                                  headers=headers).status_code == 200


def test_reader_cost_question_and_forbidden_mutation_use_no_model(monkeypatch) -> None:
    fake = FakeProvider()
    monkeypatch.setattr(routes, "get_provider", lambda: fake)
    _enable_fake_model(monkeypatch)
    app = create_app()
    with TestClient(app) as reader:
        tenant = _login(reader, "demo_reader")
        headers = {"X-Tenant-Id": tenant, "X-Demo-Request": "fleetops-ui"}
        ids = [str(uuid4()), str(uuid4()), str(uuid4())]
        try:
            cost = reader.post("/api/v1/ai/chat", headers=headers,
                               json=_request(ids[0], "What costs are recorded?"))
            assert cost.status_code == 200
            assert "do not have permission" in cost.text
            mutation = reader.post("/api/v1/ai/chat", headers=headers,
                                   json=_request(ids[1], "Assign truck DEMO-101"))
            assert mutation.status_code == 200
            assert "cannot change" in mutation.text
            assert fake.calls == []
            mileage = reader.post("/api/v1/ai/chat", headers=headers,
                                  json=_request(ids[2], "Which trucks have service due mileage?"))
            assert mileage.status_code == 200
            assert len(fake.calls) == 1
            assert not any(fact["tool"] == "getTripFinancialSummary"
                           for fact in fake.calls[0][2]["facts"])
        finally:
            for conversation_id in ids:
                assert reader.delete(f"/api/v1/ai/conversations/{conversation_id}",
                                     headers=headers).status_code == 200


def test_exhausted_provider_returns_grounded_database_answer(monkeypatch) -> None:
    class ExhaustedProvider:
        async def answer(self, question, history, facts):
            raise ProviderQuotaExceeded("AI provider credit is exhausted")

    monkeypatch.setattr(routes, "get_provider", lambda: ExhaustedProvider())
    monkeypatch.setattr(routes, "get_settings", lambda: type("Settings", (), {
        "openai_api_key": SecretStr("test-only-key")})())
    conversation_id = str(uuid4())
    app = create_app()
    with TestClient(app) as creator:
        tenant = _login(creator, "demo_creator")
        headers = {"X-Tenant-Id": tenant, "X-Demo-Request": "fleetops-ui"}
        try:
            response = creator.post("/api/v1/ai/chat", headers=headers,
                                    json=_request(conversation_id, "Where was DEMO-101 last seen?"))
            assert response.status_code == 200
            assert "AI provider credit is exhausted" in response.text
            assert "verified database records" in response.text
            events = _events(response)
            sources = next(item["data"] for item in events if item["type"] == "data-sources")
            assert any(row["view"] == "GPS" for row in sources["records"])
            history = creator.get(f"/api/v1/ai/conversations/{conversation_id}", headers=headers)
            assert history.status_code == 200
            assert "verified database records" in history.text
        finally:
            assert creator.delete(f"/api/v1/ai/conversations/{conversation_id}",
                                  headers=headers).status_code == 200


def test_named_asset_and_trip_questions_resolve_from_tenant_tables() -> None:
    member = _memberships("demo_creator", UUID("11111111-1111-4111-8111-111111111111"))[0]
    assets = next(fact["assets"] for fact in gather_facts(member, "fleet")["facts"]
                  if fact["tool"] == "getAvailableVehicles")
    assert assets
    asset = assets[0]
    question = f"Tell me something about {asset['unit_number']}"
    bundle = gather_facts(member, question)
    answer = answer_from_database(question, bundle, "AI provider credit is exhausted.")
    assert f"{asset['unit_number']}: {asset['asset_type']}, status {asset['status']}" in answer
    assert any(source["kind"] == "asset" and source["id"] == str(asset["id"])
               for source in bundle["sources"])
    assert not any(source["kind"] == "carrier" for source in bundle["sources"])

    assignments = next(fact["assignment_windows"] for fact in gather_facts(member, "trip")["facts"]
                       if fact["tool"] == "getAvailableVehicles")
    assert assignments
    trip = assignments[0]
    trip_question = f"Tell me something about {trip['trip_reference']}"
    trip_bundle = gather_facts(member, trip_question)
    trip_answer = answer_from_database(trip_question, trip_bundle, "AI provider credit is exhausted.")
    assert f"{trip['trip_reference']}: truck {trip['truck_unit']}" in trip_answer
    assert any(source["kind"] == "assignment" and source["id"] == str(trip["id"])
               for source in trip_bundle["sources"])
    assert not any(source["label"] == "1" for source in trip_bundle["sources"])
