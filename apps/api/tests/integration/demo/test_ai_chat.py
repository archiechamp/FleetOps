"""Real FastAPI, demo membership and SQL path with a deterministic model boundary."""

import json
import os
from uuid import UUID, uuid4

from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import text
from sqlalchemy.engine import URL

from app.core.db import make_sql_engine, tenant_connection
from app.core.demo_auth import _memberships
from app.core.demo_db import get_demo_engine
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

    truck = next(row for row in assets if row["asset_type"] == "TRACTOR")
    assignment_id = str(uuid4())
    trip_reference = f"TEST-TRIP-{uuid4().hex[:12]}"
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            connection.execute(text("""
                INSERT INTO demo.assignments
                    (id, tenant_id, truck_asset_id, trip_reference,
                     starts_at, ends_at, created_by)
                VALUES (:id, :tenant, :truck, :trip,
                        '2030-01-01T00:00:00', '2030-01-02T00:00:00', :member)
            """), {"id": assignment_id, "tenant": str(member.tenant_id),
                   "truck": str(truck["id"]), "trip": trip_reference,
                   "member": str(member.membership_id)})
    try:
        assignments = next(fact["assignment_windows"]
                           for fact in gather_facts(member, "trip")["facts"]
                           if fact["tool"] == "getAvailableVehicles")
        trip = next(row for row in assignments if str(UUID(str(row["id"]))) == assignment_id)
        trip_question = f"Tell me something about {trip['trip_reference']}"
        trip_bundle = gather_facts(member, trip_question)
        trip_answer = answer_from_database(trip_question, trip_bundle,
                                           "AI provider credit is exhausted.")
        assert f"{trip['trip_reference']}: truck {trip['truck_unit']}" in trip_answer
        assert any(source["kind"] == "assignment" and source["id"] == str(trip["id"])
                   for source in trip_bundle["sources"])
        assert not any(source["label"] == "1" for source in trip_bundle["sources"])
    finally:
        admin_engine = make_sql_engine(URL.create(
            "mssql+pyodbc", username="sa", password=os.environ["FLEETOPS_TEST_SA_PASSWORD"],
            host=os.environ["FLEETOPS_SQL_SERVER"], database="fleetops_demo_001",
            query={"driver": "ODBC Driver 18 for SQL Server", "Encrypt": "yes",
                   "TrustServerCertificate": "yes"},
        ))
        try:
            with admin_engine.begin() as connection:
                connection.execute(text("""
                    DECLARE @selected UNIQUEIDENTIFIER = CONVERT(UNIQUEIDENTIFIER, :tenant);
                    EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@selected
                """), {"tenant": str(member.tenant_id)})
                connection.execute(text("""
                    DELETE FROM demo.assignments WHERE tenant_id=:tenant AND id=:id
                """), {"tenant": str(member.tenant_id), "id": assignment_id})
        finally:
            admin_engine.dispose()
