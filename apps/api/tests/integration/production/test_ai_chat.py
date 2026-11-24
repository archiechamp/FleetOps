"""SQL Server-backed production AI and tenant isolation (synthetic test DB only)."""

import os
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.engine import URL

from app.core import clerk_auth
from app.core.config import Settings
from app.core.db import make_sql_engine, tenant_connection
from app.main import create_app
from app.modules.ai import production_facts, production_routes

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
        assert connection.execute(text("SELECT version_num FROM alembic_version")).scalar_one() == "0005_production_readiness_grant"
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
    from uuid import UUID

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
