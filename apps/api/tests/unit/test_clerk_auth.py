"""Production identity and carrier authorization boundaries (AUTH-01/02, FLT-01)."""

from time import time
from types import SimpleNamespace
from uuid import UUID

import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi import HTTPException
from fastapi.testclient import TestClient
from starlette.requests import Request

from app.core import clerk_auth
from app.core.config import Settings
from app.main import create_app

TENANT = UUID("11111111-1111-4111-8111-111111111111")
OTHER = UUID("22222222-2222-4222-8222-222222222222")


def _settings() -> Settings:
    return Settings(
        env="production", clerk_secret_key="test-secret",
        clerk_issuer="https://clerk.example.test",
        clerk_authorized_party="https://staging.example.test",
    )


def test_invalid_clerk_session_is_denied(monkeypatch) -> None:
    monkeypatch.setattr("app.main.get_settings", _settings)
    monkeypatch.setattr(clerk_auth, "get_settings", _settings)
    monkeypatch.setattr(clerk_auth, "authenticate_request", lambda request, options: SimpleNamespace(
        is_signed_in=False, payload=None,
    ))
    response = TestClient(create_app()).get("/api/v1/me")
    assert response.status_code == 401


def test_missing_clerk_configuration_fails_closed(monkeypatch) -> None:
    monkeypatch.setattr("app.main.get_settings", _settings)
    monkeypatch.setattr(clerk_auth, "get_settings", lambda: Settings(env="production"))
    response = TestClient(create_app()).get("/api/v1/me")
    assert response.status_code == 503


def test_clerk_token_cannot_select_another_carrier(monkeypatch) -> None:
    monkeypatch.setattr("app.main.get_settings", _settings)
    monkeypatch.setattr(clerk_auth, "verified_memberships", lambda subject, selected=None: [] if selected == OTHER else [
        clerk_auth.ClerkMember(subject, TENANT, TENANT, TENANT, frozenset({"fleet.vehicle.read"}))
    ])
    client = TestClient(create_app())
    client.app.dependency_overrides[clerk_auth.verified_subject] = lambda: "user_123"
    response = client.get("/api/v1/vehicles", headers={"X-Tenant-Id": str(OTHER)})
    assert response.status_code == 403


def test_read_permission_is_required_for_vehicle_list(monkeypatch) -> None:
    monkeypatch.setattr("app.main.get_settings", _settings)
    client = TestClient(create_app())
    client.app.dependency_overrides[clerk_auth.verified_subject] = lambda: "user_123"
    monkeypatch.setattr(clerk_auth, "verified_memberships", lambda subject, selected=None: [
        clerk_auth.ClerkMember(subject, TENANT, TENANT, TENANT, frozenset())
    ])
    response = client.get("/api/v1/vehicles", headers={"X-Tenant-Id": str(TENANT)})
    assert response.status_code == 403


def test_selected_carrier_is_required() -> None:
    try:
        clerk_auth.selected_clerk_member("user_123", None)
    except HTTPException as error:
        assert error.status_code == 403
    else:
        raise AssertionError("Missing carrier was accepted")


@pytest.mark.parametrize("claim,expected", [
    ("valid", 200),
    ("expired", 401),
    ("wrong_issuer", 401),
    ("wrong_origin", 401),
    ("wrong_signature", 401),
])
def test_signed_session_verification_with_public_key(monkeypatch, claim: str, expected: int) -> None:
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    public_key = private_key.public_key().public_bytes(
        serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo
    ).decode("ascii")
    settings = Settings(
        env="production", clerk_secret_key="test-secret", clerk_jwt_key=public_key,
        clerk_issuer="https://clerk.example.test",
        clerk_authorized_party="https://staging.example.test",
    )
    monkeypatch.setattr(clerk_auth, "get_settings", lambda: settings)
    monkeypatch.setattr(clerk_auth, "_active_session", lambda subject, sid, secret: True)
    now = int(time())
    payload = {
        "iss": "https://clerk.example.test", "sub": "user_123", "sid": "session_123",
        "azp": "https://staging.example.test", "iat": now - 120, "exp": now + 60,
    }
    if claim == "expired":
        payload["exp"] = now - 60
    elif claim == "wrong_issuer":
        payload["iss"] = "https://another-clerk.example.test"
    elif claim == "wrong_origin":
        payload["azp"] = "https://untrusted.example.test"
    signing_key = (rsa.generate_private_key(public_exponent=65537, key_size=2048)
                   if claim == "wrong_signature" else private_key)
    token = jwt.encode(payload, signing_key, algorithm="RS256")
    request = Request({"type": "http", "method": "GET", "path": "/api/v1/me",
                       "headers": [(b"authorization", f"Bearer {token}".encode("ascii"))]})
    if expected == 200:
        assert clerk_auth.verified_subject(request) == "user_123"
    else:
        with pytest.raises(HTTPException) as error:
            clerk_auth.verified_subject(request)
        assert error.value.status_code == expected


def test_revoked_clerk_session_is_denied(monkeypatch) -> None:
    settings = _settings()
    monkeypatch.setattr(clerk_auth, "get_settings", lambda: settings)
    monkeypatch.setattr(clerk_auth, "authenticate_request", lambda request, options: SimpleNamespace(
        is_signed_in=True, payload={"iss": settings.clerk_issuer, "sub": "user_123", "sid": "sess_123"},
    ))
    monkeypatch.setattr(clerk_auth, "_active_session", lambda subject, sid, secret: False)
    request = Request({"type": "http", "method": "GET", "path": "/api/v1/me", "headers": []})
    with pytest.raises(HTTPException) as error:
        clerk_auth.verified_subject(request)
    assert error.value.status_code == 401
