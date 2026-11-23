"""Clerk session verification followed by internal SQL membership authorization."""

from dataclasses import dataclass
from typing import Annotated
from uuid import UUID

from clerk_backend_api import AuthenticateRequestOptions, Clerk, authenticate_request
from clerk_backend_api.models import ClerkErrors, SDKError
from clerk_backend_api.models.session import Status
from fastapi import Depends, Header, HTTPException, Request
from sqlalchemy import text

from app.core.config import get_settings
from app.core.production_db import get_production_engine


@dataclass(frozen=True)
class ClerkMember:
    subject: str
    tenant_id: UUID
    user_id: UUID
    membership_id: UUID
    permissions: frozenset[str]


def _active_session(subject: str, session_id: str, secret_key: str) -> bool:
    """Check current Clerk state so a revoked JWT cannot outlive its session."""
    try:
        with Clerk(bearer_auth=secret_key, timeout_ms=3000) as clerk:
            session = clerk.sessions.get(session_id=session_id, timeout_ms=3000)
    except (ClerkErrors, SDKError):
        raise HTTPException(503, "Identity service is unavailable") from None
    return session.status == Status.ACTIVE and session.user_id == subject


def verified_subject(request: Request) -> str:
    settings = get_settings()
    if (settings.env != "production" or
            not settings.clerk_secret_key or
            not settings.clerk_issuer or not settings.clerk_authorized_party):
        raise HTTPException(503, "Identity service is not configured")
    state = authenticate_request(request, AuthenticateRequestOptions(
        secret_key=settings.clerk_secret_key.get_secret_value() if settings.clerk_secret_key else None,
        jwt_key=settings.clerk_jwt_key.get_secret_value() if settings.clerk_jwt_key else None,
        authorized_parties=[settings.clerk_authorized_party],
        accepts_token=["session_token"],
    ))
    if (not state.is_signed_in or not state.payload or
            state.payload.get("iss") != settings.clerk_issuer or
            not state.payload.get("sub") or not state.payload.get("sid")):
        raise HTTPException(401, "Sign in to continue", headers={"WWW-Authenticate": "Bearer"})
    subject = str(state.payload["sub"])
    if not _active_session(subject, str(state.payload["sid"]),
                           settings.clerk_secret_key.get_secret_value()):
        raise HTTPException(401, "Sign in to continue", headers={"WWW-Authenticate": "Bearer"})
    return subject


def verified_memberships(subject: str, selected: UUID | None = None) -> list[ClerkMember]:
    with get_production_engine().connect() as connection:
        rows = connection.execute(text("""
            EXEC iam.get_verified_memberships
                @auth_provider=:provider, @external_subject=:subject,
                @selected_tenant=:tenant
        """), {"provider": "clerk", "subject": subject,
                "tenant": str(selected) if selected else None}).mappings().all()
    grouped: dict[UUID, tuple[UUID, UUID, set[str]]] = {}
    for row in rows:
        tenant_id = UUID(str(row["tenant_id"]))
        if tenant_id not in grouped:
            grouped[tenant_id] = (UUID(str(row["user_id"])),
                                  UUID(str(row["membership_id"])), set())
        grouped[tenant_id][2].add(row["permission_code"])
    return [ClerkMember(subject, tenant_id, user_id, member_id, frozenset(permissions))
            for tenant_id, (user_id, member_id, permissions) in grouped.items()]


def selected_clerk_member(
    subject: Annotated[str, Depends(verified_subject)],
    x_tenant_id: Annotated[UUID | None, Header()] = None,
) -> ClerkMember:
    if x_tenant_id is None:
        raise HTTPException(403, "Select a carrier")
    members = verified_memberships(subject, x_tenant_id)
    if not members:
        raise HTTPException(403, "Carrier access denied")
    return members[0]
