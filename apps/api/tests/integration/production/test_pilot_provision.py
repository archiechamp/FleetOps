"""Controlled pilot onboarding stays reader-only and is idempotent on isolated SQL."""

import os
from uuid import UUID, uuid4

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

from tools import provision_pilot

pytestmark = pytest.mark.integration


def test_pilot_reader_provision_is_idempotent(monkeypatch) -> None:
    if (os.environ.get("FLEETOPS_ENV"), os.environ.get("FLEETOPS_DATABASE_NAME"),
            os.environ.get("FLEETOPS_TEST_MIGRATION_BRANCH")) != (
            "test", "fleetops_test_001", "production"):
        raise RuntimeError("Pilot onboarding test requires isolated production-branch SQL")
    url = URL.create(
        "mssql+pyodbc", username="sa", password=os.environ["FLEETOPS_TEST_SA_PASSWORD"],
        host=os.environ["FLEETOPS_SQL_SERVER"], database="fleetops_test_001",
        query={"driver": "ODBC Driver 18 for SQL Server", "Encrypt": "yes",
               "TrustServerCertificate": "yes"},
    )
    monkeypatch.setattr(provision_pilot, "migration_target", lambda: (url, "production@head"))
    monkeypatch.setenv("FLEETOPS_ENV", "production")
    subject = f"user_{uuid4().hex}"
    slug = f"pilot-test-{uuid4().hex[:16]}"
    monkeypatch.setenv("FLEETOPS_PILOT_CLERK_USER_ID", subject)
    monkeypatch.setenv("FLEETOPS_PILOT_TENANT_NAME", "Pilot test carrier")
    monkeypatch.setenv("FLEETOPS_PILOT_TENANT_SLUG", slug)
    monkeypatch.setenv("FLEETOPS_PILOT_TIMEZONE", "America/Chicago")
    first = provision_pilot.provision()
    assert provision_pilot.provision() == first
    engine = create_engine(url)
    try:
        with engine.connect() as connection:
            rows = connection.execute(text("""
                EXEC iam.get_verified_memberships
                    @auth_provider='clerk', @external_subject=:subject,
                    @selected_tenant=:tenant
            """), {"subject": subject, "tenant": first[0]}).mappings().all()
        assert len(rows) == 1
        assert rows[0]["permission_code"] == "fleet.vehicle.read"
        assert str(UUID(str(rows[0]["membership_id"]))) == first[1]
    finally:
        engine.dispose()
