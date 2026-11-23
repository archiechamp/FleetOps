from fastapi.testclient import TestClient

from app.main import create_app


def test_live_endpoint() -> None:
    response = TestClient(create_app()).get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "live"}


def test_readiness_fails_closed_until_database_is_available() -> None:
    response = TestClient(create_app()).get("/health/ready")
    assert response.status_code == 503
