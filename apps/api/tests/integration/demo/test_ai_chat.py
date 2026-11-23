"""Real FastAPI, demo membership and SQL path with a deterministic model boundary."""

import json
import os
from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import create_app
from app.modules.ai import routes


class FakeProvider:
    def __init__(self) -> None:
        self.calls = []

    async def answer(self, question, history, facts) -> str:
        self.calls.append((question, history, facts))
        return "The saved demo carrier has fleet records."


def _login(client: TestClient, username: str) -> str:
    response = client.post("/api/v1/demo/login", json={
        "username": username, "password": os.environ["FLEETOPS_DEMO_PASSWORD"]},
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
