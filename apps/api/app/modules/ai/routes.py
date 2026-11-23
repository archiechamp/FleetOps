"""Read-only local Copilot, backed by verified tenant-scoped SQL read models."""

import json
import re
from datetime import UTC, datetime
from typing import Annotated, Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from starlette.concurrency import run_in_threadpool

from app.core.config import get_settings
from app.core.db import tenant_connection
from app.core.demo_auth import DemoMember, require_demo_request, selected_member
from app.core.demo_db import get_demo_engine
from app.modules.ai.database_answer import answer_from_database
from app.modules.ai.facts import gather_facts
from app.modules.ai.provider import ProviderQuotaExceeded, ProviderUnavailable, get_provider

router = APIRouter(prefix="/ai", tags=["read-only Copilot"])
_LIMIT = 25
_RETENTION_DAYS = 7
_CREDENTIAL_PATTERN = re.compile(
    r"sk-[A-Za-z0-9_-]{16,}|\b(?:api[_ -]?key|password|secret)\s*[:=]\s*\S+",
    re.IGNORECASE,
)
_MUTATION_PATTERN = re.compile(
    r"^\s*(?:please\s+)?(?:assign|cancel|delete|remove|pay|change|update|edit|release|"
    r"mark|dispatch|create|register)\b",
    re.IGNORECASE,
)


class ChatRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: UUID
    messages: list[dict[str, Any]] = Field(min_length=1, max_length=25)


class FeedbackRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    message_id: UUID
    helpful: bool


def _question(body: ChatRequest) -> str:
    latest = body.messages[-1]
    if latest.get("role") != "user":
        raise HTTPException(422, "Last message must be from the user")
    parts = latest.get("parts")
    if not isinstance(parts, list) or not parts or len(parts) > 4:
        raise HTTPException(422, "Send one text question")
    if any(not isinstance(part, dict) or part.get("type") != "text" for part in parts):
        raise HTTPException(422, "Only text questions are supported")
    question = " ".join(str(part.get("text", "")) for part in parts).strip()
    if not 1 <= len(question) <= 1000:
        raise HTTPException(422, "Question must be 1–1000 characters")
    if _CREDENTIAL_PATTERN.search(question):
        raise HTTPException(422, "Remove credentials before asking Copilot")
    return question


def _fresh_permissions(connection, member: DemoMember) -> set[str]:
    rows = connection.execute(text("""
        EXEC iam.get_verified_memberships @auth_provider='demo',
            @external_subject=:subject, @selected_tenant=:tenant
    """), {"subject": member.subject, "tenant": str(member.tenant_id)}).mappings().all()
    return {row["permission_code"] for row in rows
            if UUID(str(row["membership_id"])) == member.membership_id}


def _owned_conversation(connection, member: DemoMember, conversation_id: UUID) -> bool:
    return connection.execute(text("""
        SELECT 1 FROM demo.ai_conversations
        WHERE id=:id AND tenant_id=:tenant AND membership_id=:member
    """), {"id": str(conversation_id), "tenant": str(member.tenant_id),
           "member": str(member.membership_id)}).first() is not None


def _prepare(member: DemoMember, conversation_id: UUID,
             question: str) -> list[dict[str, str]]:
    tenant = str(member.tenant_id)
    owner = str(member.membership_id)
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            permissions = _fresh_permissions(connection, member)
            if "fleet.vehicle.read" not in permissions:
                raise HTTPException(403, "Copilot access denied")
            lock = connection.execute(text("""
                DECLARE @result INT;
                EXEC @result = sys.sp_getapplock @Resource=:resource,
                    @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=5000;
                SELECT @result
            """), {"resource": f"demo-ai:{tenant}:{owner}"}).scalar_one()
            if lock < 0:
                raise HTTPException(503, "Copilot is busy; retry")
            connection.execute(text("""
                DELETE FROM demo.ai_messages WHERE tenant_id=:tenant AND membership_id=:member
                    AND created_at < DATEADD(day, -7, SYSUTCDATETIME())
            """), {"tenant": tenant, "member": owner})
            connection.execute(text("""
                DELETE FROM demo.ai_conversations WHERE tenant_id=:tenant AND membership_id=:member
                    AND updated_at < DATEADD(day, -7, SYSUTCDATETIME())
                    AND NOT EXISTS (SELECT 1 FROM demo.ai_messages m
                        WHERE m.tenant_id=:tenant AND m.membership_id=:member
                          AND m.conversation_id=demo.ai_conversations.id)
            """), {"tenant": tenant, "member": owner})
            exists = _owned_conversation(connection, member, conversation_id)
            if not exists:
                # An existing ID owned by another member must not be adopted.
                taken = connection.execute(text("""
                    SELECT 1 FROM demo.ai_conversations WHERE id=:id
                """), {"id": str(conversation_id)}).first()
                if taken:
                    raise HTTPException(404, "Conversation not found")
                try:
                    connection.execute(text("""
                        INSERT INTO demo.ai_conversations (id, tenant_id, membership_id)
                        VALUES (:id, :tenant, :member)
                    """), {"id": str(conversation_id), "tenant": tenant, "member": owner})
                except IntegrityError:
                    raise HTTPException(404, "Conversation not found") from None
            rows = connection.execute(text("""
                SELECT TOP (8) role, content FROM demo.ai_messages
                WHERE tenant_id=:tenant AND membership_id=:member
                  AND conversation_id=:conversation
                  AND (requires_finance=0 OR :finance=1)
                ORDER BY created_at DESC, id DESC
            """), {"tenant": tenant, "member": owner,
                   "conversation": str(conversation_id),
                   "finance": int("demo.finance.read" in permissions)}).mappings().all()
            history = [{"role": row["role"], "text": row["content"]}
                       for row in reversed(rows)]
            current = connection.execute(text("""
                SELECT request_count FROM demo.ai_daily_usage WITH (UPDLOCK, HOLDLOCK)
                WHERE tenant_id=:tenant AND membership_id=:member
                  AND usage_date=CONVERT(date, SYSUTCDATETIME())
            """), {"tenant": tenant, "member": owner}).scalar()
            if current is not None and current >= _LIMIT:
                raise HTTPException(429, "Daily Copilot limit reached")
            if current is None:
                connection.execute(text("""
                    INSERT INTO demo.ai_daily_usage
                      (tenant_id, membership_id, usage_date, request_count)
                    VALUES (:tenant, :member, CONVERT(date, SYSUTCDATETIME()), 1)
                """), {"tenant": tenant, "member": owner})
            else:
                connection.execute(text("""
                    UPDATE demo.ai_daily_usage SET request_count=request_count+1
                    WHERE tenant_id=:tenant AND membership_id=:member
                      AND usage_date=CONVERT(date, SYSUTCDATETIME())
                """), {"tenant": tenant, "member": owner})
            connection.execute(text("""
                INSERT INTO demo.ai_messages
                  (id, tenant_id, membership_id, conversation_id, role, content)
                VALUES (:id, :tenant, :member, :conversation, 'user', :content)
            """), {"id": str(uuid4()), "tenant": tenant, "member": owner,
                   "conversation": str(conversation_id), "content": question})
            connection.execute(text("""
                UPDATE demo.ai_conversations SET updated_at=SYSUTCDATETIME()
                WHERE id=:id AND tenant_id=:tenant AND membership_id=:member
            """), {"id": str(conversation_id), "tenant": tenant, "member": owner})
    return history


def _save_answer(member: DemoMember, conversation_id: UUID, answer_id: UUID,
                 answer: str, sources: list[dict], queried_at: str,
                 requires_finance: bool) -> None:
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            permissions = _fresh_permissions(connection, member)
            if "fleet.vehicle.read" not in permissions or (requires_finance
                    and "demo.finance.read" not in permissions):
                raise HTTPException(403, "Copilot access changed; ask again")
            if not _owned_conversation(connection, member, conversation_id):
                raise HTTPException(404, "Conversation not found")
            connection.execute(text("""
                INSERT INTO demo.ai_messages
                  (id, tenant_id, membership_id, conversation_id, role, content,
                   sources_json, requires_finance)
                VALUES (:id, :tenant, :member, :conversation, 'assistant', :content,
                        :sources, :finance)
            """), {"id": str(answer_id), "tenant": str(member.tenant_id),
                   "member": str(member.membership_id),
                   "conversation": str(conversation_id), "content": answer,
                   "sources": json.dumps({"records": sources, "queried_at": queried_at}),
                   "finance": int(requires_finance)})
            connection.execute(text("""
                UPDATE demo.ai_conversations SET updated_at=SYSUTCDATETIME()
                WHERE id=:id AND tenant_id=:tenant AND membership_id=:member
            """), {"id": str(conversation_id), "tenant": str(member.tenant_id),
                   "member": str(member.membership_id)})


def _event(part: dict[str, Any]) -> str:
    return f"data: {json.dumps(part, ensure_ascii=False)}\n\n"


@router.get("/status")
def status(member: Annotated[DemoMember, Depends(selected_member)]) -> dict[str, Any]:
    if "fleet.vehicle.read" not in member.permissions:
        raise HTTPException(403, "Copilot access denied")
    settings = get_settings()
    return {"configured": settings.openai_api_key is not None,
            "provider": settings.ai_provider, "model": settings.ai_model,
            "daily_limit": _LIMIT, "retention_days": _RETENTION_DAYS}


@router.post("/chat")
async def chat(body: ChatRequest,
               member: Annotated[DemoMember, Depends(selected_member)],
               _: Annotated[None, Depends(require_demo_request)]) -> StreamingResponse:
    question = _question(body)
    history = await run_in_threadpool(_prepare, member, body.id, question)
    if _MUTATION_PATTERN.search(question):
        answer = ("I can read this carrier's records, but I cannot change them. "
                  "Use the Fleet, Dispatch, Maintenance, Documents or Costs screen for an authorized action.")
        bundle = {"queried_at": datetime.now(UTC).isoformat().replace("+00:00", "Z"),
                  "sources": [], "facts": []}
    else:
        bundle = await run_in_threadpool(gather_facts, member, question)
        finance_denied = any(fact.get("tool") == "getTripFinancialSummary"
                             and fact.get("access") == "denied"
                             for fact in bundle["facts"])
        if finance_denied:
            answer = "I do not have permission to read this carrier's cost records."
        else:
            if get_settings().openai_api_key is None:
                answer = answer_from_database(question, bundle, "AI provider is not configured.")
            else:
                try:
                    answer = await get_provider().answer(question, history, bundle)
                except ProviderQuotaExceeded:
                    answer = answer_from_database(question, bundle, "AI provider credit is exhausted.")
                except ProviderUnavailable:
                    answer = answer_from_database(question, bundle, "AI provider is unavailable.")
    requires_finance = any(fact.get("tool") == "getTripFinancialSummary"
                           and fact.get("access") != "denied"
                           for fact in bundle["facts"])
    answer_id = uuid4()
    await run_in_threadpool(_save_answer, member, body.id, answer_id, answer,
                            bundle["sources"], bundle["queried_at"], requires_finance)
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
def conversations(member: Annotated[DemoMember, Depends(selected_member)]) -> list[dict]:
    if "fleet.vehicle.read" not in member.permissions:
        raise HTTPException(403, "Copilot access denied")
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        rows = connection.execute(text("""
            SELECT TOP (20) c.id, c.created_at, c.updated_at,
              (SELECT TOP (1) LEFT(m.content, 80) FROM demo.ai_messages m
               WHERE m.tenant_id=c.tenant_id AND m.membership_id=c.membership_id
                 AND m.conversation_id=c.id AND m.role='user'
               ORDER BY m.created_at, m.id) AS title
            FROM demo.ai_conversations c
            WHERE c.tenant_id=:tenant AND c.membership_id=:member
              AND c.updated_at >= DATEADD(day, -7, SYSUTCDATETIME())
            ORDER BY c.updated_at DESC
        """), {"tenant": str(member.tenant_id),
               "member": str(member.membership_id)}).mappings().all()
    return [dict(row) for row in rows]


@router.get("/conversations/{conversation_id}")
def conversation(conversation_id: UUID,
                 member: Annotated[DemoMember, Depends(selected_member)]) -> dict:
    if "fleet.vehicle.read" not in member.permissions:
        raise HTTPException(403, "Copilot access denied")
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        if not _owned_conversation(connection, member, conversation_id):
            raise HTTPException(404, "Conversation not found")
        rows = connection.execute(text("""
            SELECT TOP (100) id, role, content, sources_json, created_at
            FROM demo.ai_messages WHERE tenant_id=:tenant AND membership_id=:member
              AND conversation_id=:conversation
              AND created_at >= DATEADD(day, -7, SYSUTCDATETIME())
              AND (requires_finance=0 OR :finance=1)
            ORDER BY created_at, id
        """), {"tenant": str(member.tenant_id), "member": str(member.membership_id),
               "conversation": str(conversation_id),
               "finance": int("demo.finance.read" in member.permissions)}).mappings().all()
    messages = []
    for row in rows:
        parts = ([{"type": "data-sources", "data": json.loads(row["sources_json"])}]
                 if row["sources_json"] else [])
        parts.append({"type": "text", "text": row["content"]})
        messages.append({"id": str(row["id"]), "role": row["role"], "parts": parts})
    return {"id": str(conversation_id), "messages": messages}


@router.delete("/conversations/{conversation_id}")
def delete_conversation(conversation_id: UUID,
                        member: Annotated[DemoMember, Depends(selected_member)],
                        _: Annotated[None, Depends(require_demo_request)]) -> dict:
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            if not _owned_conversation(connection, member, conversation_id):
                raise HTTPException(404, "Conversation not found")
            connection.execute(text("""
                DELETE FROM demo.ai_messages WHERE tenant_id=:tenant
                  AND membership_id=:member AND conversation_id=:conversation
            """), {"tenant": str(member.tenant_id), "member": str(member.membership_id),
                   "conversation": str(conversation_id)})
            connection.execute(text("""
                DELETE FROM demo.ai_conversations WHERE id=:conversation
                  AND tenant_id=:tenant AND membership_id=:member
            """), {"conversation": str(conversation_id),
                   "tenant": str(member.tenant_id), "member": str(member.membership_id)})
    return {"deleted": True}


@router.post("/feedback")
def feedback(body: FeedbackRequest,
             member: Annotated[DemoMember, Depends(selected_member)],
             _: Annotated[None, Depends(require_demo_request)]) -> dict:
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            permissions = _fresh_permissions(connection, member)
            if "fleet.vehicle.read" not in permissions:
                raise HTTPException(403, "Copilot access denied")
            changed = connection.execute(text("""
                UPDATE demo.ai_messages SET feedback=:feedback
                WHERE id=:id AND tenant_id=:tenant AND membership_id=:member
                  AND role='assistant' AND (requires_finance=0 OR :finance=1)
            """), {"feedback": int(body.helpful), "id": str(body.message_id),
                   "tenant": str(member.tenant_id), "member": str(member.membership_id),
                   "finance": int("demo.finance.read" in permissions)}).rowcount
            if not changed:
                raise HTTPException(404, "Answer not found")
    return {"saved": True}
