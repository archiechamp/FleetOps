"""Local demo account picker keeps signed-session validation."""

import base64

import pytest
from fastapi import HTTPException

from app.core import demo_auth


def test_demo_session_expires_and_tampering_is_rejected(monkeypatch) -> None:
    monkeypatch.setattr(demo_auth, "get_settings", lambda: type("Settings", (), {
        "demo_session_secret": "test-session-secret-with-at-least-32-characters"})())
    monkeypatch.setattr(demo_auth.time, "time", lambda: 1000)
    token = demo_auth._signed_session("demo_creator")
    assert demo_auth._subject(token) == "demo_creator"

    decoded = bytearray(base64.urlsafe_b64decode(token.encode("ascii")))
    decoded[-1] ^= 1
    with pytest.raises(HTTPException) as tampered:
        demo_auth._subject(base64.urlsafe_b64encode(decoded).decode("ascii"))
    assert tampered.value.status_code == 401

    monkeypatch.setattr(demo_auth.time, "time", lambda: 1000 + 8 * 3600)
    with pytest.raises(HTTPException) as expired:
        demo_auth._subject(token)
    assert expired.value.status_code == 401
