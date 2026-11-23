from fastapi.testclient import TestClient
from sqlalchemy.exc import SQLAlchemyError

from app.core.config import Settings
from app.core.demo_db import engine
from app.main import create_app


def test_live_endpoint() -> None:
    response = TestClient(create_app()).get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "live"}


def test_readiness_fails_closed_until_database_is_available(monkeypatch) -> None:
    monkeypatch.setattr(
        "app.main.get_settings",
        lambda: Settings(
            env="demo",
            database_name="fleetops_demo_001",
            demo_session_secret="test-session-secret-with-at-least-32-characters",
            demo_runtime_password="test-database-password",
        ),
    )

    def unavailable_database():
        raise SQLAlchemyError("database unavailable")

    monkeypatch.setattr(engine, "connect", unavailable_database)
    response = TestClient(create_app()).get("/health/ready")
    assert response.status_code == 503


def test_production_mode_does_not_expose_demo_routes(monkeypatch) -> None:
    monkeypatch.setattr("app.main.get_settings", lambda: Settings(env="production"))
    client = TestClient(create_app())
    assert client.post(
        "/api/v1/demo/login",
        json={"username": "demo_creator"},
        headers={"X-Demo-Request": "fleetops-ui"},
    ).status_code == 404
    assert client.get("/health/ready").status_code == 503
