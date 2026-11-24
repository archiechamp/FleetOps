"""Clerk-protected, read-only AI Fleet chat on production fleet records."""

import json
import re
from datetime import UTC, datetime
from typing import Annotated, Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.core.clerk_auth import ClerkMember, selected_clerk_member
from app.core.config import get_settings
from app.core.db import tenant_connection
from app.core.production_db import get_production_engine
from app.modules.ai.production_facts import gather_production_facts
from app.modules.ai.provider import ProviderQuotaExceeded, ProviderUnavailable, get_provider

router = APIRouter(prefix="/ai", tags=["read-only AI Fleet"])
_LIMIT = 25
_MUTATION = re.compile(r"^\s*(?:please\s+)?(?:assign|cancel|delete|remove|pay|change|update|edit|release|mark|dispatch|create|register)\b", re.IGNORECASE)
_UNAVAILABLE = re.compile(r"\b(?:gps|location|last seen|where|trip|dispatch|driver|maintenance|service|repair|due|cost|expense|fuel|toll|profit|revenue|cpm|document|insurance)\b", re.IGNORECASE)
_CREDENTIAL = re.compile(r"sk-[A-Za-z0-9_-]{16,}|\b(?:api[_ -]?key|password|secret)\s*[:=]\s*\S+", re.IGNORECASE)


class ChatRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: UUID
    messages: list[dict[str, Any]] = Field(min_length=1, max_length=25)
    trigger: str | None = Field(default=None, max_length=32)


class FeedbackRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    message_id: UUID
    helpful: bool


def _question(body: ChatRequest) -> str:
    latest = body.messages[-1]
    parts = latest.get("parts")
    if latest.get("role") != "user" or not isinstance(parts, list) or not 1 <= len(parts) <= 4:
        raise HTTPException(422, "Send one text question")
    if any(not isinstance(part, dict) or part.get("type") != "text" for part in parts):
        raise HTTPException(422, "Only text questions are supported")
    question = " ".join(str(part.get("text", "")) for part in parts).strip()
    if not 1 <= len(question) <= 1000 or _CREDENTIAL.search(question):
        raise HTTPException(422, "Question is invalid or contains a credential")
    return question


def _fresh_permission(connection, member: ClerkMember) -> None:
    rows = connection.execute(text("""
        EXEC iam.get_verified_memberships @auth_provider='clerk',
            @external_subject=:subject, @selected_tenant=:tenant
    """), {"subject": member.subject, "tenant": str(member.tenant_id)}).mappings().all()
    if not any(row["permission_code"] == "fleet.vehicle.read"
               and UUID(str(row["membership_id"])) == member.membership_id for row in rows):
        raise HTTPException(403, "AI Fleet access denied")


def _owned(connection, member: ClerkMember, conversation_id: UUID) -> bool:
    return connection.execute(text("""
        SELECT 1 FROM ai.conversations
        WHERE id=:id AND tenant_id=:tenant AND membership_id=:member
    """), {"id": str(conversation_id), "tenant": str(member.tenant_id),
           "member": str(member.membership_id)}).first() is not None


def _prepare(member: ClerkMember, conversation_id: UUID, question: str) -> list[dict[str, str]]:
    tenant, owner = str(member.tenant_id), str(member.membership_id)
    with tenant_connection(get_production_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            _fresh_permission(connection, member)
            lock = connection.execute(text("""
                DECLARE @result INT;
                EXEC @result = sys.sp_getapplock @Resource=:resource,
                    @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=5000;
                SELECT @result
            """), {"resource": f"ai-usage:{tenant}:{owner}"}).scalar_one()
            if lock < 0:
                raise HTTPException(503, "AI Fleet is busy; retry")
            count = connection.execute(text("""
                SELECT COUNT(*) FROM ai.messages
                WHERE tenant_id=:tenant AND membership_id=:member AND role='user'
                  AND created_at >= CONVERT(date, SYSUTCDATETIME())
            """), {"tenant": tenant, "member": owner}).scalar_one()
            if count >= _LIMIT:
                raise HTTPException(429, "Daily AI Fleet limit reached")
            if not _owned(connection, member, conversation_id):
                try:
                    connection.execute(text("""
                        INSERT INTO ai.conversations (id, tenant_id, membership_id)
                        VALUES (:id, :tenant, :member)
                    """), {"id": str(conversation_id), "tenant": tenant, "member": owner})
                except IntegrityError:
                    raise HTTPException(404, "Conversation not found") from None
            rows = connection.execute(text("""
                SELECT TOP (8) role, content FROM ai.messages
                WHERE tenant_id=:tenant AND membership_id=:member
                  AND conversation_id=:conversation
                ORDER BY created_at DESC, id DESC
            """), {"tenant": tenant, "member": owner,
                   "conversation": str(conversation_id)}).mappings().all()
            history = [{"role": row["role"], "text": row["content"]}
                       for row in reversed(rows)]
            connection.execute(text("""
                INSERT INTO ai.messages
                    (id, tenant_id, membership_id, conversation_id, role, content)
                VALUES (:id, :tenant, :member, :conversation, 'user', :content)
            """), {"id": str(uuid4()), "tenant": tenant, "member": owner,
                   "conversation": str(conversation_id), "content": question})
            connection.execute(text("""
                UPDATE ai.conversations SET updated_at=SYSUTCDATETIME()
                WHERE id=:id AND tenant_id=:tenant AND membership_id=:member
            """), {"id": str(conversation_id), "tenant": tenant, "member": owner})
    return history


def _save(member: ClerkMember, conversation_id: UUID, message_id: UUID,
          answer: str, sources: list[dict], queried_at: str) -> None:
    with tenant_connection(get_production_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            _fresh_permission(connection, member)
            if not _owned(connection, member, conversation_id):
                raise HTTPException(404, "Conversation not found")
            connection.execute(text("""
                INSERT INTO ai.messages
                    (id, tenant_id, membership_id, conversation_id, role, content, sources_json)
                VALUES (:id, :tenant, :member, :conversation, 'assistant', :content, :sources)
            """), {"id": str(message_id), "tenant": str(member.tenant_id),
                   "member": str(member.membership_id), "conversation": str(conversation_id),
                   "content": answer,
                   "sources": json.dumps({"records": sources, "queried_at": queried_at})})


def _fleet_fallback(bundle: dict, reason: str) -> str:
    fleet = bundle["facts"][0]
    counts = fleet["equipment_counts"]
    count_text = ", ".join(f"{row['asset_count']} {row['asset_type']} {row['status']}"
                           for row in counts) or "no recorded equipment"
    assets = fleet["assets"]
    lines = [f"{reason} {fleet['carrier']['name']} has {count_text}."]
    if bundle.get("requested_units") and not bundle["named_asset_found"]:
        lines.append("No verified fleet asset matched the requested unit number.")
    elif assets:
        lines.append("Returned assets: " + ", ".join(
            f"{row['unit_number']} ({row['asset_type']}, {row['status']})" for row in assets[:10]) + ".")
    if fleet["truncated"]:
        lines.append("Only the first 40 assets were checked; ask with an exact unit number.")
    lines.append("This is recorded fleet status, not dispatch availability.")
    return " ".join(lines)


def _event(part: dict[str, Any]) -> str:
    return f"data: {json.dumps(part, ensure_ascii=False)}\n\n"


@router.get("/status")
def status(member: Annotated[ClerkMember, Depends(selected_clerk_member)]) -> dict[str, Any]:
    if "fleet.vehicle.read" not in member.permissions:
        raise HTTPException(403, "AI Fleet access denied")
    settings = get_settings()
    return {"configured": settings.openai_api_key is not None,
            "provider": settings.ai_provider, "model": settings.ai_model,
            "daily_limit": _LIMIT, "retention_days": None,
            "scope": "fleet inventory only"}


@router.post("/chat")
async def chat(body: ChatRequest,
               member: Annotated[ClerkMember, Depends(selected_clerk_member)]) -> StreamingResponse:
    question = _question(body)
    history = await run_in_threadpool(_prepare, member, body.id, question)
    now = datetime.now(UTC).isoformat().replace("+00:00", "Z")
    if _MUTATION.search(question):
        answer = "AI Fleet is read-only and cannot change carrier records. Use an authorized operations screen."
        bundle = {"sources": [], "queried_at": now}
    elif _UNAVAILABLE.search(question):
        answer = "That information is not connected to the production FleetOps data model yet. I cannot verify it from this carrier's records."
        bundle = {"sources": [], "queried_at": now}
    else:
        bundle = await run_in_threadpool(gather_production_facts, member, question)
        if bundle.get("requested_units") and not bundle["named_asset_found"]:
            answer = _fleet_fallback(bundle, "Verified database check:")
        elif get_settings().openai_api_key is None:
            answer = _fleet_fallback(bundle, "AI provider is not configured. Verified database summary:")
        else:
            try:
                answer = await get_provider().answer(question, history, bundle)
            except ProviderQuotaExceeded:
                answer = _fleet_fallback(bundle, "AI provider credit is exhausted. Verified database summary:")
            except ProviderUnavailable:
                answer = _fleet_fallback(bundle, "AI provider is unavailable. Verified database summary:")
    answer_id = uuid4()
    await run_in_threadpool(_save, member, body.id, answer_id, answer,
                            bundle["sources"], bundle["queried_at"])
    text_id = str(uuid4())

    async def stream():
        yield _event({"type": "start", "messageId": str(answer_id)})
        yield _event({"type": "data-sources", "data": {
            "records": bundle["sources"], "queried_at": bundle["queried_at"]}})
        yield _event({"type": "text-start", "id": text_id})
        for index in range(0, len(answer), 120):
            yield _event({"type": "text-delta", "id": text_id,
                          "delta": answer[index:index + 120]})
        yield _event({"type": "text-end", "id": text_id})
        yield _event({"type": "finish"})
        yield "data: [DONE]\n\n"

    return StreamingResponse(stream(), media_type="text/event-stream", headers={
        "x-vercel-ai-ui-message-stream": "v1", "Cache-Control": "private, no-store",
        "X-Accel-Buffering": "no", "X-Content-Type-Options": "nosniff",
    })


@router.get("/conversations")
def conversations(member: Annotated[ClerkMember, Depends(selected_clerk_member)]) -> list[dict]:
    if "fleet.vehicle.read" not in member.permissions:
        raise HTTPException(403, "AI Fleet access denied")
    with tenant_connection(get_production_engine(), member.tenant_id) as connection:
        rows = connection.execute(text("""
            SELECT TOP (20) c.id, c.updated_at,
              (SELECT TOP (1) LEFT(m.content, 80) FROM ai.messages m
               WHERE m.tenant_id=c.tenant_id AND m.membership_id=c.membership_id
                 AND m.conversation_id=c.id AND m.role='user'
               ORDER BY m.created_at, m.id) AS title
            FROM ai.conversations c
            WHERE c.tenant_id=:tenant AND c.membership_id=:member
            ORDER BY c.updated_at DESC, c.id DESC
        """), {"tenant": str(member.tenant_id),
               "member": str(member.membership_id)}).mappings().all()
    return [{"id": str(row["id"]), "title": row["title"],
             "updated_at": row["updated_at"].replace(tzinfo=UTC).isoformat()} for row in rows]


@router.get("/conversations/{conversation_id}")
def conversation(conversation_id: UUID,
                 member: Annotated[ClerkMember, Depends(selected_clerk_member)]) -> dict:
    if "fleet.vehicle.read" not in member.permissions:
        raise HTTPException(403, "AI Fleet access denied")
    with tenant_connection(get_production_engine(), member.tenant_id) as connection:
        if not _owned(connection, member, conversation_id):
            raise HTTPException(404, "Conversation not found")
        rows = connection.execute(text("""
            SELECT TOP (50) id, role, content, sources_json FROM ai.messages
            WHERE tenant_id=:tenant AND membership_id=:member
              AND conversation_id=:conversation
            ORDER BY created_at, id
        """), {"tenant": str(member.tenant_id), "member": str(member.membership_id),
               "conversation": str(conversation_id)}).mappings().all()
    messages = []
    for row in rows:
        parts: list[dict] = [{"type": "text", "text": row["content"]}]
        if row["sources_json"]:
            parts.insert(0, {"type": "data-sources", "data": json.loads(row["sources_json"])})
        messages.append({"id": str(row["id"]), "role": row["role"], "parts": parts})
    return {"messages": messages}


@router.delete("/conversations/{conversation_id}")
def delete_conversation(conversation_id: UUID,
                        member: Annotated[ClerkMember, Depends(selected_clerk_member)]) -> dict[str, str]:
    with tenant_connection(get_production_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            _fresh_permission(connection, member)
            if not _owned(connection, member, conversation_id):
                raise HTTPException(404, "Conversation not found")
            params = {"tenant": str(member.tenant_id), "member": str(member.membership_id),
                      "conversation": str(conversation_id)}
            connection.execute(text("""
                DELETE FROM ai.messages WHERE tenant_id=:tenant AND membership_id=:member
                  AND conversation_id=:conversation
            """), params)
            connection.execute(text("""
                DELETE FROM ai.conversations WHERE tenant_id=:tenant AND membership_id=:member
                  AND id=:conversation
            """), params)
    return {"status": "deleted"}


@router.post("/feedback")
def feedback(body: FeedbackRequest,
             member: Annotated[ClerkMember, Depends(selected_clerk_member)]) -> dict[str, str]:
    with tenant_connection(get_production_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            _fresh_permission(connection, member)
            result = connection.execute(text("""
                UPDATE ai.messages SET feedback=:helpful
                WHERE id=:id AND tenant_id=:tenant AND membership_id=:member
                  AND role='assistant'
            """), {"id": str(body.message_id), "tenant": str(member.tenant_id),
                   "member": str(member.membership_id), "helpful": int(body.helpful)})
            if result.rowcount != 1:
                raise HTTPException(404, "Answer not found")
    return {"status": "saved"}
