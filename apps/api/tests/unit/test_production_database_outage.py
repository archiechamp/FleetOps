"""A resumed Azure SQL connection failure is a sanitized retryable response."""

from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError

from app.core import clerk_auth
from app.core.config import Settings
from app.main import create_app
from app.modules.fleet import production_routes


def test_carrier_read_database_outage_returns_sanitized_503(monkeypatch) -> None:
    monkeypatch.setattr("app.main.get_settings", lambda: Settings(env="production"))
    app = create_app()
    app.dependency_overrides[clerk_auth.verified_subject] = lambda: "user_verified"

    def unavailable(subject: str):
        raise OperationalError("SELECT secret from table", {}, Exception("password must not leak"))

    monkeypatch.setattr(production_routes, "verified_memberships", unavailable)
    response = TestClient(app).get("/api/v1/me")
    assert response.status_code == 503
    assert response.json() == {"detail": "Fleet service is temporarily unavailable"}
    assert "password" not in response.text
