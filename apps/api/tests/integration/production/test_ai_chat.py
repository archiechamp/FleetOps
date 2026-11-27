"""SQL Server-backed production AI and tenant isolation (synthetic test DB only)."""

import base64
import os
from uuid import UUID, uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.engine import URL

from app.core import clerk_auth
from app.core.config import Settings
from app.core.db import make_sql_engine, tenant_connection
from app.main import create_app
from app.modules import pilot_operations_routes
from app.modules.ai import pilot_facts, production_facts, production_routes

pytestmark = pytest.mark.integration


@pytest.fixture(scope="module")
def sql_fixture():
    if (os.environ.get("FLEETOPS_ENV"), os.environ.get("FLEETOPS_DATABASE_NAME"),
            os.environ.get("FLEETOPS_TEST_MIGRATION_BRANCH")) != (
            "test", "fleetops_test_001", "production"):
        raise RuntimeError("Production AI integration requires the isolated production-branch test DB")
    engine = make_sql_engine(URL.create(
        "mssql+pyodbc", username="sa", password=os.environ["FLEETOPS_TEST_SA_PASSWORD"],
        host=os.environ["FLEETOPS_SQL_SERVER"], database="fleetops_test_001",
        query={"driver": "ODBC Driver 18 for SQL Server", "Encrypt": "yes",
               "TrustServerCertificate": "yes"},
    ))
    tenant_a, tenant_b = str(uuid4()), str(uuid4())
    user_id, member_id, role_id, asset_a, asset_b = (str(uuid4()) for _ in range(5))
    subject = f"user_test_{uuid4().hex}"
    with engine.begin() as connection:
        assert connection.execute(text("SELECT version_num FROM alembic_version")).scalar_one() == "0006_staging_operations"
        assert connection.execute(text("SELECT COUNT(*) FROM sys.security_predicates WHERE target_object_id=OBJECT_ID(N'ai.messages')")).scalar_one() == 5
        connection.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM ref.currencies WHERE code='USD')
                INSERT INTO ref.currencies (code, name) VALUES ('USD', 'US Dollar')
            IF NOT EXISTS (SELECT 1 FROM ref.asset_types WHERE code='TRACTOR')
                INSERT INTO ref.asset_types (code, name) VALUES ('TRACTOR', 'Tractor')
            IF NOT EXISTS (SELECT 1 FROM iam.permissions WHERE code='fleet.vehicle.read')
                INSERT INTO iam.permissions (id, code, resource, action)
                VALUES (:permission, 'fleet.vehicle.read', 'fleet.vehicle', 'read')
        """), {"permission": str(uuid4())})
        type_id = connection.execute(text("SELECT id FROM ref.asset_types WHERE code='TRACTOR'")).scalar_one()
        permission_id = connection.execute(text("SELECT id FROM iam.permissions WHERE code='fleet.vehicle.read'")).scalar_one()
        connection.execute(text("""
            INSERT INTO iam.users (id, auth_provider, external_subject, display_name)
            VALUES (:id, 'clerk', :subject, 'Integration user')
        """), {"id": user_id, "subject": subject})
        for tenant, label, asset, unit in (
            (tenant_a, "Carrier A", asset_a, "TEST-A"),
            (tenant_b, "Carrier B", asset_b, "TEST-B"),
        ):
            connection.execute(text("""
                INSERT INTO core.tenants (id, name, slug, timezone, currency_code)
                VALUES (:id, :name, :slug, 'America/Chicago', 'USD')
            """), {"id": tenant, "name": label,
                   "slug": f"test-{uuid4().hex[:20]}"})
            connection.execute(text("""
                DECLARE @selected UNIQUEIDENTIFIER = CONVERT(UNIQUEIDENTIFIER, :tenant);
                EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@selected
            """), {"tenant": tenant})
            if tenant == tenant_a:
                connection.execute(text("""
                    INSERT INTO iam.memberships (id, tenant_id, user_id)
                    VALUES (:id, :tenant, :user)
                """), {"id": member_id, "tenant": tenant, "user": user_id})
                connection.execute(text("""
                    INSERT INTO iam.roles (id, tenant_id, code, name)
                    VALUES (:id, :tenant, 'READER', 'Reader')
                """), {"id": role_id, "tenant": tenant})
                connection.execute(text("""
                    INSERT INTO iam.role_permissions (id, tenant_id, role_id, permission_id)
                    VALUES (:id, :tenant, :role, :permission)
                """), {"id": str(uuid4()), "tenant": tenant,
                       "role": role_id, "permission": permission_id})
                connection.execute(text("""
                    INSERT INTO iam.membership_roles (id, tenant_id, membership_id, role_id)
                    VALUES (:id, :tenant, :member, :role)
                """), {"id": str(uuid4()), "tenant": tenant,
                       "member": member_id, "role": role_id})
            connection.execute(text("""
                INSERT INTO fleet.assets
                    (id, tenant_id, unit_number, asset_type_id, make, model,
                     model_year, ownership_type, currency_code)
                VALUES (:id, :tenant, :unit, :type, 'Test', 'Tractor', 2024, 'OWNED', 'USD')
            """), {"id": asset, "tenant": tenant, "unit": unit,
                   "type": type_id})
    try:
        yield engine, subject, tenant_a, tenant_b, member_id
    finally:
        engine.dispose()


@pytest.fixture
def client(sql_fixture, monkeypatch):
    engine, subject, *_ = sql_fixture
    monkeypatch.setattr("app.main.get_settings", lambda: Settings(env="production"))
    monkeypatch.setattr(clerk_auth, "get_production_engine", lambda: engine)
    monkeypatch.setattr(production_routes, "get_production_engine", lambda: engine)
    monkeypatch.setattr(production_facts, "get_production_engine", lambda: engine)
    monkeypatch.setattr(pilot_facts, "get_production_engine", lambda: engine)
    test_client = TestClient(create_app())
    test_client.app.dependency_overrides[clerk_auth.verified_subject] = lambda: subject
    return test_client


def _body(question: str) -> dict:
    return {"id": str(uuid4()), "messages": [{"role": "user", "parts": [
        {"type": "text", "text": question}]}]}


def test_ai_reads_only_selected_carrier(client, sql_fixture) -> None:
    _, _, tenant_a, tenant_b, _ = sql_fixture
    response = client.post("/api/v1/ai/chat", json=_body("Summarize fleet inventory"),
                           headers={"X-Tenant-Id": tenant_a})
    assert response.status_code == 200
    assert "TEST-A" in response.text
    assert "TEST-B" not in response.text
    assert "data-sources" in response.text
    assert client.post("/api/v1/ai/chat", json=_body("Summarize fleet inventory"),
                       headers={"X-Tenant-Id": tenant_b}).status_code == 403


def test_named_asset_cannot_resolve_other_carrier_unit(client, sql_fixture) -> None:
    _, _, tenant_a, _, _ = sql_fixture
    response = client.post("/api/v1/ai/chat", json=_body("Tell me about TEST-B"),
                           headers={"X-Tenant-Id": tenant_a})
    assert response.status_code == 200
    assert "No verified fleet asset matched" in response.text
    assert "TEST-B (" not in response.text


def test_ai_mutation_prompt_does_not_change_asset(client, sql_fixture) -> None:
    engine, _, tenant_a, _, _ = sql_fixture
    response = client.post("/api/v1/ai/chat", json=_body("Delete TEST-A"),
                           headers={"X-Tenant-Id": tenant_a})
    assert response.status_code == 200
    assert "read-only" in response.text
    with engine.connect() as connection:
        connection.execute(text("""
            DECLARE @selected UNIQUEIDENTIFIER = CONVERT(UNIQUEIDENTIFIER, :tenant);
            EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@selected
        """), {"tenant": tenant_a})
        count = connection.execute(text("""
            SELECT COUNT(*) FROM fleet.assets WHERE tenant_id=:tenant AND unit_number='TEST-A'
        """), {"tenant": tenant_a}).scalar_one()
    assert count == 1


def test_conversation_is_owner_scoped_and_deletable(client, sql_fixture) -> None:
    _, _, tenant_a, tenant_b, _ = sql_fixture
    headers = {"X-Tenant-Id": tenant_a}
    listed = client.get("/api/v1/ai/conversations", headers=headers)
    assert listed.status_code == 200
    conversation_id = listed.json()[0]["id"]
    detail = client.get(f"/api/v1/ai/conversations/{conversation_id}", headers=headers)
    assert detail.status_code == 200
    assert any(message["role"] == "assistant" for message in detail.json()["messages"])
    assert client.get(f"/api/v1/ai/conversations/{conversation_id}",
                      headers={"X-Tenant-Id": tenant_b}).status_code == 403
    assert client.delete(f"/api/v1/ai/conversations/{conversation_id}", headers=headers).status_code == 200
    assert client.get(f"/api/v1/ai/conversations/{conversation_id}", headers=headers).status_code == 404


def test_daily_limit_is_backed_by_sql(client, sql_fixture) -> None:
    engine, _, tenant_a, _, member_id = sql_fixture

    with tenant_connection(engine, UUID(tenant_a)) as connection:
        connection.commit()
        with connection.begin():
            conversation_id = str(uuid4())
            connection.execute(text("""
                INSERT INTO ai.conversations (id, tenant_id, membership_id)
                VALUES (:id, :tenant, :member)
            """), {"id": conversation_id, "tenant": tenant_a, "member": member_id})
            current = connection.execute(text("""
                SELECT COUNT(*) FROM ai.messages
                WHERE tenant_id=:tenant AND membership_id=:member AND role='user'
                  AND created_at >= CONVERT(date, SYSUTCDATETIME())
            """), {"tenant": tenant_a, "member": member_id}).scalar_one()
            for _ in range(max(0, 25 - current)):
                connection.execute(text("""
                    INSERT INTO ai.messages
                        (id, tenant_id, membership_id, conversation_id, role, content)
                    VALUES (:id, :tenant, :member, :conversation, 'user', 'test usage')
                """), {"id": str(uuid4()), "tenant": tenant_a,
                       "member": member_id, "conversation": conversation_id})
    response = client.post("/api/v1/ai/chat", json=_body("Summarize fleet inventory"),
                           headers={"X-Tenant-Id": tenant_a})
    assert response.status_code == 429


def test_fictional_pilot_operations_enforce_membership_and_dispatch_conflicts(
    client, sql_fixture, monkeypatch,
) -> None:
    """Exercise the hosted pilot schema with real SQL locks and tenant RLS."""
    from datetime import UTC, datetime, timedelta

    engine, _, tenant_a, tenant_b, _ = sql_fixture
    monkeypatch.setattr(pilot_operations_routes, "get_settings", lambda: Settings(
        env="production", database_name="fleetops-staging-db"))
    monkeypatch.setattr(pilot_operations_routes, "get_production_engine", lambda: engine)
    with tenant_connection(engine, UUID(tenant_a)) as connection:
        connection.commit()
        with connection.begin():
            for code, resource, action in (
                ("fleet.vehicle.create", "fleet.vehicle", "create"),
                ("pilot.documents.read", "pilot.documents", "read"),
                ("pilot.documents.write", "pilot.documents", "write"),
                ("pilot.finance.read", "pilot.finance", "read"),
                ("pilot.finance.write", "pilot.finance", "write"),
            ):
                connection.execute(text("""
                    IF NOT EXISTS (SELECT 1 FROM iam.permissions WHERE code=:code)
                        INSERT INTO iam.permissions (id, code, resource, action)
                        VALUES (:id, :code, :resource, :action)
                """), {"id": str(uuid4()), "code": code, "resource": resource,
                       "action": action})
                connection.execute(text("""
                    INSERT INTO iam.role_permissions (id, tenant_id, role_id, permission_id)
                    SELECT :id, :tenant, r.id, p.id FROM iam.roles r
                    CROSS JOIN iam.permissions p
                    WHERE r.tenant_id=:tenant AND r.code='READER' AND p.code=:code
                      AND NOT EXISTS (SELECT 1 FROM iam.role_permissions rp
                        WHERE rp.tenant_id=:tenant AND rp.role_id=r.id AND rp.permission_id=p.id)
                """), {"id": str(uuid4()), "tenant": tenant_a, "code": code})
            connection.execute(text("""
                IF NOT EXISTS (SELECT 1 FROM ref.asset_types WHERE code='TRAILER')
                    INSERT INTO ref.asset_types (code, name) VALUES ('TRAILER', 'Trailer')
            """))
    headers = {"X-Tenant-Id": tenant_a}
    assert client.get("/api/v1/pilot/assets", headers={"X-Tenant-Id": tenant_b}).status_code == 403
    assets = client.get("/api/v1/pilot/assets", headers=headers)
    assert assets.status_code == 200
    assert "TEST-A" in str(assets.json()) and "TEST-B" not in str(assets.json())
    truck = next(row for row in assets.json() if row["unit_number"] == "TEST-A")
    trailer = client.post("/api/v1/pilot/trailers", headers=headers, json={
        "unit_number": f"TEST-T-{uuid4().hex[:8]}", "make": "Test",
        "model": "Dry van", "model_year": 2024, "ownership_type": "LEASED",
    })
    assert trailer.status_code == 201
    start = datetime.now(UTC) + timedelta(days=1)
    assignment = {"trip_reference": f"TEST-TRIP-{uuid4().hex[:8]}",
                  "truck_asset_id": truck["id"], "trailer_asset_id": trailer.json()["id"],
                  "starts_at": start.isoformat(),
                  "ends_at": (start + timedelta(hours=2)).isoformat()}
    first = client.post("/api/v1/pilot/assignments", headers=headers, json=assignment)
    assert first.status_code == 201 and first.json()["replayed"] is False
    replay = client.post("/api/v1/pilot/assignments", headers=headers, json=assignment)
    assert replay.status_code == 201 and replay.json()["replayed"] is True
    assert client.post("/api/v1/pilot/assignments", headers=headers, json={
        **assignment, "trip_reference": f"TEST-TRIP-{uuid4().hex[:8]}",
    }).status_code == 409
    position = {"latitude": 41.8, "longitude": -87.6,
                "source": "Synthetic test", "observed_at": datetime.now(UTC).isoformat()}
    assert client.post(f"/api/v1/pilot/assets/{truck['id']}/position",
                       headers=headers, json=position).json()["updated"] is True
    older = {**position, "latitude": 40.0,
             "observed_at": (datetime.now(UTC) - timedelta(days=1)).isoformat()}
    assert client.post(f"/api/v1/pilot/assets/{truck['id']}/position",
                       headers=headers, json=older).json()["updated"] is False
    assert client.patch(f"/api/v1/pilot/assets/{truck['id']}", headers=headers,
                        json={"status": "MAINTENANCE"}).status_code == 409
    assert client.get("/api/v1/pilot/assets", headers=headers).json()[0]["gps_latitude"] == 41.8

    document = {"asset_id": truck["id"], "kind": "REGISTRATION",
                "file_name": "synthetic.pdf", "content_type": "application/pdf",
                "content_base64": base64.b64encode(b"%PDF-1.4\nfictional test").decode()}
    bad_file = client.post("/api/v1/pilot/documents", headers=headers,
                           json={**document, "content_base64": base64.b64encode(b"not a PDF").decode()})
    assert bad_file.status_code == 422
    created = client.post("/api/v1/pilot/documents", headers=headers, json=document)
    assert created.status_code == 201
    document_id = created.json()["id"]
    assert client.get(f"/api/v1/pilot/documents/{document_id}/file", headers=headers).content.startswith(b"%PDF-")
    assert client.get(f"/api/v1/pilot/documents/{document_id}/file",
                      headers={"X-Tenant-Id": tenant_b}).status_code == 403

    cost = {"asset_id": truck["id"], "category": "FUEL", "amount_usd": "12.34",
            "occurred_on": datetime.now(UTC).date().isoformat()}
    assert client.post("/api/v1/pilot/costs", headers=headers, json=cost).status_code == 201
    assert client.post("/api/v1/pilot/costs", headers=headers,
                       json={**cost, "amount_usd": "0.001"}).status_code == 422
    report = client.get("/api/v1/pilot/reports", headers=headers)
    assert report.status_code == 200
    assert report.json()["cost_completeness"] == "unknown"
    assert report.json()["mileage_basis"] == "unknown"
    assert "12.34" in report.json()["recorded_cost_total"]

    member = clerk_auth.verified_memberships(sql_fixture[1], UUID(tenant_a))[0]
    gps = pilot_facts.gather_pilot_facts(member, "Where was TEST-A last seen?", "gps")
    assert "TEST-A" in gps["answer"] and "TEST-B" not in gps["answer"]
    assert any(source["label"] == "TEST-A" for source in gps["sources"])
    assert "Synthetic test" in gps["answer"]
    costs = pilot_facts.gather_pilot_facts(member, "What costs are recorded for TEST-A?", "costs")
    assert "12.34" in costs["answer"] and "TEST-B" not in costs["answer"]
    documents = pilot_facts.gather_pilot_facts(member, "Show documents for TEST-A", "documents")
    assert "TEST-A" in documents["answer"] and "TEST-B" not in documents["answer"]
    assert "fictional test" not in str(documents)


def test_pilot_routes_hidden_outside_approved_staging(client, sql_fixture) -> None:
    _, _, tenant_a, _, _ = sql_fixture
    assert client.get("/api/v1/pilot/assets", headers={"X-Tenant-Id": tenant_a}).status_code == 404
