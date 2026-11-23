"""Loopback-only demo identity; Clerk remains the production identity decision."""

import base64
import hashlib
import hmac
import time
from dataclasses import dataclass
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Cookie, Depends, Header, HTTPException, Response
from pydantic import BaseModel
from sqlalchemy import text

from app.core.config import get_settings
from app.core.demo_db import get_demo_engine

router = APIRouter(tags=["demo identity"])
_COOKIE = "fleetops_demo_session"
_SUBJECTS = {"demo_creator", "demo_reader"}
_NAMES = {
    "11111111-1111-4111-8111-111111111111": "Northstar Freight (Demo)",
    "22222222-2222-4222-8222-222222222222": "Lakeside Logistics (Demo)",
}


class Login(BaseModel):
    username: str


@dataclass(frozen=True)
class DemoMember:
    subject: str
    tenant_id: UUID
    user_id: UUID
    membership_id: UUID
    permissions: frozenset[str]


def _signed_session(subject: str) -> str:
    expires = int(time.time()) + 8 * 3600
    payload = f"{subject}:{expires}".encode("ascii")
    signature = hmac.new(
        get_settings().demo_session_secret.encode("utf-8"), payload, hashlib.sha256
    ).digest()
    return base64.urlsafe_b64encode(payload + b"." + signature).decode("ascii")


def _subject(token: str | None) -> str:
    if not token:
        raise HTTPException(401, "Sign in to continue")
    try:
        decoded = base64.urlsafe_b64decode(token.encode("ascii"))
        payload, separator, signature = decoded[:-33], decoded[-33:-32], decoded[-32:]
        if separator != b".":
            raise ValueError("Invalid session")
        expected = hmac.new(
            get_settings().demo_session_secret.encode("utf-8"), payload, hashlib.sha256
        ).digest()
        subject, expires = payload.decode("ascii").rsplit(":", 1)
        if (not hmac.compare_digest(signature, expected) or subject not in _SUBJECTS
                or int(expires) <= time.time()):
            raise ValueError("Invalid session")
        return subject
    except (ValueError, UnicodeError, base64.binascii.Error):
        raise HTTPException(401, "Sign in to continue") from None


def _memberships(subject: str, selected: UUID | None = None) -> list[DemoMember]:
    with get_demo_engine().connect() as connection:
        rows = connection.execute(text("""
            EXEC iam.get_verified_memberships
                @auth_provider=:provider, @external_subject=:subject,
                @selected_tenant=:tenant
        """), {"provider": "demo", "subject": subject,
                "tenant": str(selected) if selected else None}).mappings().all()
    grouped: dict[str, tuple[UUID, UUID, set[str]]] = {}
    for row in rows:
        tenant_id = UUID(str(row["tenant_id"]))
        key = str(tenant_id)
        if key not in grouped:
            grouped[key] = (UUID(str(row["user_id"])), UUID(str(row["membership_id"])), set())
        grouped[key][2].add(row["permission_code"])
    return [DemoMember(subject, UUID(key), user_id, member_id, frozenset(permissions))
            for key, (user_id, member_id, permissions) in sorted(grouped.items())]


def current_subject(fleetops_demo_session: str | None = Cookie(default=None)) -> str:
    return _subject(fleetops_demo_session)


def selected_member(
    subject: str = Depends(current_subject),
    x_tenant_id: Annotated[UUID | None, Header()] = None,
) -> DemoMember:
    if x_tenant_id is None:
        raise HTTPException(403, "Select a carrier")
    members = _memberships(subject, x_tenant_id)
    if not members:
        raise HTTPException(403, "Carrier access denied")
    return members[0]


def require_demo_request(x_demo_request: str | None = Header(default=None)) -> None:
    if x_demo_request != "fleetops-ui":
        raise HTTPException(403, "Invalid demo request")


@router.post("/demo/login")
def login(body: Login, response: Response, _: None = Depends(require_demo_request)) -> dict[str, str]:
    if body.username not in _SUBJECTS:
        raise HTTPException(401, "Unknown demo account")
    response.set_cookie(_COOKIE, _signed_session(body.username), max_age=8 * 3600,
                        httponly=True, samesite="strict", path="/api")
    return {"username": body.username}


@router.post("/demo/logout")
def logout(response: Response, _: None = Depends(require_demo_request)) -> dict[str, str]:
    response.delete_cookie(_COOKIE, path="/api")
    return {"status": "signed_out"}


@router.get("/me")
def me(subject: str = Depends(current_subject)) -> dict:
    members = _memberships(subject)
    if not members:
        raise HTTPException(403, "No active carrier membership")
    return {"username": subject, "carriers": [
        {"id": str(member.tenant_id), "name": _NAMES.get(str(member.tenant_id), "Demo carrier"),
         "permissions": sorted(member.permissions)} for member in members
    ]}
