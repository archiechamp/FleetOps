"""Bounded, fictional local demo workflows. Production modules use the approved target model."""

import base64
import binascii
from datetime import UTC, date, datetime
from decimal import Decimal
from typing import Annotated, Literal
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel, ConfigDict, Field, field_validator
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.core.db import tenant_connection
from app.core.demo_auth import DemoMember, require_demo_request, selected_member
from app.core.demo_db import get_demo_engine

router = APIRouter(prefix="/demo", tags=["local demo operations"])


def _require(member: DemoMember, permission: str) -> None:
    if permission not in member.permissions:
        raise HTTPException(403, "Access denied")


def _fresh_permission(connection, member: DemoMember, permission: str) -> None:
    rows = connection.execute(text("""
        EXEC iam.get_verified_memberships @auth_provider='demo',
            @external_subject=:subject, @selected_tenant=:tenant
    """), {"subject": member.subject, "tenant": str(member.tenant_id)}).mappings().all()
    if not any(row["permission_code"] == permission
               and UUID(str(row["membership_id"])) == member.membership_id for row in rows):
        raise HTTPException(403, "Access denied")


def _lock(connection, tenant: UUID, asset_ids: list[UUID]) -> None:
    for asset_id in sorted(set(asset_ids), key=str):
        result = connection.execute(text("""
            DECLARE @result INT;
            EXEC @result = sys.sp_getapplock @Resource=:resource,
                @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=5000;
            SELECT @result
        """), {"resource": f"demo-asset:{tenant}:{asset_id}"}).scalar_one()
        if result < 0:
            raise HTTPException(503, "Equipment is busy; retry")


def _asset(connection, tenant: UUID, asset_id: UUID):
    return connection.execute(text("""
        SELECT a.id, a.status, t.code AS asset_type
        FROM fleet.assets a JOIN ref.asset_types t ON t.id=a.asset_type_id
        WHERE a.tenant_id=:tenant AND a.id=:asset
    """), {"tenant": str(tenant), "asset": str(asset_id)}).mappings().first()


def _audit(connection, member: DemoMember, action: str, entity: str, entity_id: UUID) -> None:
    connection.execute(text("""
        INSERT INTO audit.audit_events
          (tenant_id, actor_id, actor_type, action, entity_type, entity_id,
           new_values, correlation_id, occurred_at)
        VALUES (:tenant, :actor, 'USER', :action, :entity, :id, '{}', :correlation, SYSUTCDATETIME())
    """), {"tenant": str(member.tenant_id), "actor": str(member.user_id),
           "action": action, "entity": entity, "id": str(entity_id),
           "correlation": str(uuid4())})


class TrailerCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    unit_number: str = Field(min_length=1, max_length=30)
    make: str = Field(min_length=1, max_length=80)
    model: str = Field(min_length=1, max_length=80)
    model_year: int = Field(ge=1900, le=2100)
    ownership_type: Literal["OWNED", "LEASED", "CONTRACTED"]

    @field_validator("unit_number", "make", "model")
    @classmethod
    def trim_required(cls, value: str) -> str:
        trimmed = value.strip()
        if not trimmed:
            raise ValueError("Value is required")
        return trimmed


class AssetUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    odometer_miles: Decimal | None = Field(default=None, ge=0, max_digits=12, decimal_places=1)
    service_due_date: date | None = None
    service_due_miles: Decimal | None = Field(default=None, ge=0, max_digits=12, decimal_places=1)
    service_note: str | None = Field(default=None, max_length=300)
    status: Literal["AVAILABLE", "MAINTENANCE", "OUT_OF_SERVICE", "INACTIVE"] | None = None


class PositionCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    latitude: Decimal = Field(ge=-90, le=90, max_digits=9, decimal_places=6)
    longitude: Decimal = Field(ge=-180, le=180, max_digits=9, decimal_places=6)
    observed_at: datetime
    source: str = Field(min_length=1, max_length=80)

    @field_validator("observed_at")
    @classmethod
    def require_utc(cls, value: datetime) -> datetime:
        if value.tzinfo is None:
            raise ValueError("Timestamp must include a time zone")
        if value.astimezone(UTC) > datetime.now(UTC):
            raise ValueError("Future observations are not accepted")
        return value.astimezone(UTC)


class AssignmentCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    trip_reference: str = Field(min_length=1, max_length=40)
    truck_asset_id: UUID
    trailer_asset_id: UUID | None = None
    starts_at: datetime
    ends_at: datetime

    @field_validator("trip_reference")
    @classmethod
    def trim_trip(cls, value: str) -> str:
        trimmed = value.strip()
        if not trimmed:
            raise ValueError("Trip reference is required")
        return trimmed

    @field_validator("starts_at", "ends_at")
    @classmethod
    def require_zone(cls, value: datetime) -> datetime:
        if value.tzinfo is None:
            raise ValueError("Time zone required")
        return value.astimezone(UTC)


class DocumentCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    asset_id: UUID
    kind: Literal["REGISTRATION", "INSURANCE"]
    expires_on: date | None = None
    file_name: str = Field(min_length=1, max_length=160)
    content_type: Literal["application/pdf", "image/png", "image/jpeg"]
    content_base64: str


class CostCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    asset_id: UUID
    trip_reference: str | None = Field(default=None, max_length=40)
    category: Literal["FUEL", "MAINTENANCE", "TOLLS", "OTHER"]
    amount_usd: Decimal = Field(gt=0, max_digits=19, decimal_places=2)
    occurred_on: date


@router.get("/assets")
def assets(member: Annotated[DemoMember, Depends(selected_member)]) -> list[dict]:
    _require(member, "fleet.vehicle.read")
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        rows = connection.execute(text("""
            SELECT a.id, a.unit_number, t.code AS asset_type, a.make, a.model,
                   a.model_year, a.ownership_type, a.status, term.name AS terminal,
                   s.odometer_miles, s.service_due_date, s.service_due_miles,
                   s.service_note, s.gps_latitude, s.gps_longitude,
                   s.gps_source, s.gps_observed_at, s.gps_received_at
            FROM fleet.assets a JOIN ref.asset_types t ON t.id=a.asset_type_id
            LEFT JOIN core.terminals term ON term.tenant_id=a.tenant_id AND term.id=a.terminal_id
            LEFT JOIN demo.asset_state s ON s.tenant_id=a.tenant_id AND s.asset_id=a.id
            WHERE a.tenant_id=:tenant AND t.code IN ('TRACTOR','TRAILER')
            ORDER BY a.unit_number OFFSET 0 ROWS FETCH NEXT 200 ROWS ONLY
        """), {"tenant": str(member.tenant_id)}).mappings().all()
    return [dict(row) for row in rows]


@router.post("/trailers", status_code=201)
def create_trailer(body: TrailerCreate,
                   member: Annotated[DemoMember, Depends(selected_member)],
                   _: Annotated[None, Depends(require_demo_request)]) -> dict:
    _require(member, "fleet.vehicle.create")
    asset_id = uuid4()
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        try:
            with connection.begin():
                _fresh_permission(connection, member, "fleet.vehicle.create")
                connection.execute(text("""
                    INSERT INTO fleet.assets
                      (id, tenant_id, unit_number, asset_type_id, make, model,
                       model_year, ownership_type, currency_code, created_by, updated_by)
                    SELECT :id, :tenant, :unit, t.id, :make, :model, :year,
                           :ownership, 'USD', :member, :member
                    FROM ref.asset_types t WHERE t.code='TRAILER'
                """), {"id": str(asset_id), "tenant": str(member.tenant_id),
                       "unit": body.unit_number.strip(), "make": body.make.strip(),
                       "model": body.model.strip(), "year": body.model_year,
                       "ownership": body.ownership_type, "member": str(member.membership_id)})
                _audit(connection, member, "trailer.register", "fleet.assets", asset_id)
        except IntegrityError:
            raise HTTPException(409, "Unit number already exists") from None
    return {"id": asset_id}


@router.patch("/assets/{asset_id}")
def update_asset(asset_id: UUID, body: AssetUpdate,
                 member: Annotated[DemoMember, Depends(selected_member)],
                 _: Annotated[None, Depends(require_demo_request)]) -> dict:
    _require(member, "fleet.vehicle.create")
    if not body.model_fields_set:
        raise HTTPException(422, "Provide a field to update")
    if body.status == "AVAILABLE" and not (body.service_note or "").strip():
        raise HTTPException(422, "A release note is required")
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            _lock(connection, member.tenant_id, [asset_id])
            _fresh_permission(connection, member, "fleet.vehicle.create")
            asset = _asset(connection, member.tenant_id, asset_id)
            if asset is None:
                raise HTTPException(404, "Equipment not found")
            if body.status and body.status != asset["status"]:
                active = connection.execute(text("""
                    SELECT 1 FROM demo.assignments WHERE tenant_id=:tenant
                      AND (truck_asset_id=:asset OR trailer_asset_id=:asset)
                      AND ends_at > SYSUTCDATETIME()
                """), {"tenant": str(member.tenant_id), "asset": str(asset_id)}).first()
                if active and body.status != "AVAILABLE":
                    raise HTTPException(409, "Equipment has an active assignment")
                connection.execute(text("""
                    UPDATE fleet.assets SET status=:status, updated_at=SYSUTCDATETIME(),
                        updated_by=:member WHERE tenant_id=:tenant AND id=:asset
                """), {"status": body.status, "member": str(member.membership_id),
                       "tenant": str(member.tenant_id), "asset": str(asset_id)})
            connection.execute(text("""
                IF NOT EXISTS (SELECT 1 FROM demo.asset_state WHERE tenant_id=:tenant AND asset_id=:asset)
                    INSERT INTO demo.asset_state (tenant_id, asset_id) VALUES (:tenant, :asset)
            """), {"tenant": str(member.tenant_id), "asset": str(asset_id)})
            values = body.model_dump(exclude_unset=True, exclude={"status"})
            if values:
                allowed = ("odometer_miles", "service_due_date", "service_due_miles", "service_note")
                assignments = ", ".join(f"{name}=:{name}" for name in allowed if name in values)
                connection.execute(text(f"""
                    UPDATE demo.asset_state SET {assignments}, updated_at=SYSUTCDATETIME()
                    WHERE tenant_id=:tenant AND asset_id=:asset
                """), {**values, "tenant": str(member.tenant_id), "asset": str(asset_id)})
            _audit(connection, member, "asset.update", "fleet.assets", asset_id)
    return {"id": asset_id, "status": body.status or asset["status"]}


@router.post("/assets/{asset_id}/position", status_code=201)
def record_position(asset_id: UUID, body: PositionCreate,
                    member: Annotated[DemoMember, Depends(selected_member)],
                    _: Annotated[None, Depends(require_demo_request)]) -> dict:
    _require(member, "fleet.vehicle.create")
    observed = body.observed_at.replace(tzinfo=None)
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            _lock(connection, member.tenant_id, [asset_id])
            _fresh_permission(connection, member, "fleet.vehicle.create")
            asset = _asset(connection, member.tenant_id, asset_id)
            if asset is None or asset["asset_type"] != "TRACTOR":
                raise HTTPException(404, "Truck not found")
            connection.execute(text("""
                IF NOT EXISTS (SELECT 1 FROM demo.asset_state WHERE tenant_id=:tenant AND asset_id=:asset)
                    INSERT INTO demo.asset_state (tenant_id, asset_id) VALUES (:tenant, :asset)
            """), {"tenant": str(member.tenant_id), "asset": str(asset_id)})
            changed = connection.execute(text("""
                UPDATE demo.asset_state SET gps_latitude=:lat, gps_longitude=:lon,
                    gps_source=:source, gps_observed_at=:observed,
                    gps_received_at=SYSUTCDATETIME(), updated_at=SYSUTCDATETIME()
                WHERE tenant_id=:tenant AND asset_id=:asset
                  AND (gps_observed_at IS NULL OR gps_observed_at < :observed)
            """), {"lat": body.latitude, "lon": body.longitude,
                   "source": body.source, "observed": observed,
                   "tenant": str(member.tenant_id), "asset": str(asset_id)}).rowcount
            if changed:
                _audit(connection, member, "gps.demo_position", "fleet.assets", asset_id)
    return {"updated": bool(changed)}


@router.get("/assignments")
def assignments(member: Annotated[DemoMember, Depends(selected_member)]) -> list[dict]:
    _require(member, "fleet.vehicle.read")
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        rows = connection.execute(text("""
            SELECT x.id, x.trip_reference, x.truck_asset_id, x.trailer_asset_id,
                   truck.unit_number AS truck_unit, trailer.unit_number AS trailer_unit,
                   x.starts_at, x.ends_at, x.created_at
            FROM demo.assignments x
            JOIN fleet.assets truck ON truck.tenant_id=x.tenant_id AND truck.id=x.truck_asset_id
            LEFT JOIN fleet.assets trailer ON trailer.tenant_id=x.tenant_id AND trailer.id=x.trailer_asset_id
            WHERE x.tenant_id=:tenant ORDER BY x.starts_at DESC
            OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
        """), {"tenant": str(member.tenant_id)}).mappings().all()
    return [dict(row) for row in rows]


@router.post("/assignments", status_code=201)
def create_assignment(body: AssignmentCreate,
                      member: Annotated[DemoMember, Depends(selected_member)],
                      _: Annotated[None, Depends(require_demo_request)]) -> dict:
    _require(member, "fleet.vehicle.create")
    if body.ends_at <= body.starts_at:
        raise HTTPException(422, "End must follow start")
    if body.trailer_asset_id == body.truck_asset_id:
        raise HTTPException(422, "Truck and trailer must differ")
    new_id = uuid4()
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            ids = [body.truck_asset_id] + ([body.trailer_asset_id] if body.trailer_asset_id else [])
            _lock(connection, member.tenant_id, ids)
            _fresh_permission(connection, member, "fleet.vehicle.create")
            old = connection.execute(text("""
                SELECT id, truck_asset_id, trailer_asset_id, starts_at, ends_at
                FROM demo.assignments WHERE tenant_id=:tenant AND trip_reference=:trip
            """), {"tenant": str(member.tenant_id), "trip": body.trip_reference}).mappings().first()
            start = body.starts_at.replace(tzinfo=None)
            end = body.ends_at.replace(tzinfo=None)
            if old:
                if (UUID(str(old["truck_asset_id"])) == body.truck_asset_id
                        and (UUID(str(old["trailer_asset_id"])) if old["trailer_asset_id"] else None) == body.trailer_asset_id
                        and old["starts_at"] == start and old["ends_at"] == end):
                    return {"id": old["id"], "replayed": True}
                raise HTTPException(409, "Trip reference already used")
            for asset_id, expected in ((body.truck_asset_id, "TRACTOR"),
                                       (body.trailer_asset_id, "TRAILER")):
                if asset_id is None:
                    continue
                asset = _asset(connection, member.tenant_id, asset_id)
                if asset is None or asset["asset_type"] != expected:
                    raise HTTPException(404, "Equipment not found")
                if asset["status"] != "AVAILABLE":
                    raise HTTPException(409, "Equipment is not available")
                conflict = connection.execute(text("""
                    SELECT 1 FROM demo.assignments
                    WHERE tenant_id=:tenant AND (truck_asset_id=:asset OR trailer_asset_id=:asset)
                      AND starts_at < :ends AND ends_at > :starts
                """), {"tenant": str(member.tenant_id), "asset": str(asset_id),
                       "starts": start, "ends": end}).first()
                if conflict:
                    raise HTTPException(409, "Equipment is already assigned in this window")
            try:
                connection.execute(text("""
                    INSERT INTO demo.assignments (id, tenant_id, truck_asset_id, trailer_asset_id,
                        trip_reference, starts_at, ends_at, created_by)
                    VALUES (:id, :tenant, :truck, :trailer, :trip, :starts, :ends, :member)
                """), {"id": str(new_id), "tenant": str(member.tenant_id),
                       "truck": str(body.truck_asset_id),
                       "trailer": str(body.trailer_asset_id) if body.trailer_asset_id else None,
                       "trip": body.trip_reference, "starts": start, "ends": end,
                       "member": str(member.membership_id)})
            except IntegrityError:
                raise HTTPException(409, "Trip reference already used") from None
            _audit(connection, member, "dispatch.demo_assign", "demo.assignments", new_id)
    return {"id": new_id, "replayed": False}


@router.get("/documents")
def documents(member: Annotated[DemoMember, Depends(selected_member)]) -> list[dict]:
    _require(member, "fleet.vehicle.create")
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        rows = connection.execute(text("""
            SELECT d.id, d.asset_id, a.unit_number, d.kind, d.expires_on,
                   d.file_name, d.content_type, d.uploaded_at
            FROM demo.documents d JOIN fleet.assets a
              ON a.tenant_id=d.tenant_id AND a.id=d.asset_id
            WHERE d.tenant_id=:tenant ORDER BY d.uploaded_at DESC
            OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
        """), {"tenant": str(member.tenant_id)}).mappings().all()
    return [dict(row) for row in rows]


@router.post("/documents", status_code=201)
def upload_document(body: DocumentCreate,
                    member: Annotated[DemoMember, Depends(selected_member)],
                    _: Annotated[None, Depends(require_demo_request)]) -> dict:
    _require(member, "fleet.vehicle.create")
    try:
        raw = base64.b64decode(body.content_base64, validate=True)
    except (ValueError, binascii.Error):
        raise HTTPException(422, "Invalid file encoding") from None
    if not 1 <= len(raw) <= 1024 * 1024:
        raise HTTPException(422, "File must be 1 byte to 1 MB")
    signatures = {"application/pdf": b"%PDF-", "image/png": b"\x89PNG\r\n\x1a\n",
                  "image/jpeg": b"\xff\xd8\xff"}
    if not raw.startswith(signatures[body.content_type]):
        raise HTTPException(422, "File content does not match its type")
    document_id = uuid4()
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            _fresh_permission(connection, member, "fleet.vehicle.create")
            if _asset(connection, member.tenant_id, body.asset_id) is None:
                raise HTTPException(404, "Equipment not found")
            connection.execute(text("""
                INSERT INTO demo.documents (id, tenant_id, asset_id, kind, expires_on,
                    file_name, content_type, file_bytes, uploaded_by)
                VALUES (:id, :tenant, :asset, :kind, :expires, :name, :type, :data, :member)
            """), {"id": str(document_id), "tenant": str(member.tenant_id),
                   "asset": str(body.asset_id), "kind": body.kind,
                   "expires": body.expires_on, "name": body.file_name,
                   "type": body.content_type, "data": raw,
                   "member": str(member.membership_id)})
            _audit(connection, member, "document.upload", "demo.documents", document_id)
    return {"id": document_id}


@router.get("/documents/{document_id}/file")
def download_document(document_id: UUID,
                      member: Annotated[DemoMember, Depends(selected_member)]) -> Response:
    _require(member, "fleet.vehicle.create")
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        row = connection.execute(text("""
            SELECT content_type, file_bytes FROM demo.documents
            WHERE tenant_id=:tenant AND id=:id
        """), {"tenant": str(member.tenant_id), "id": str(document_id)}).mappings().first()
    if row is None:
        raise HTTPException(404, "Document not found")
    return Response(content=bytes(row["file_bytes"]), media_type=row["content_type"],
                    headers={"Cache-Control": "private, no-store", "X-Content-Type-Options": "nosniff"})


@router.get("/costs")
def costs(member: Annotated[DemoMember, Depends(selected_member)]) -> list[dict]:
    _require(member, "demo.finance.read")
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        rows = connection.execute(text("""
            SELECT c.id, c.asset_id, a.unit_number, c.trip_reference, c.category,
                   c.amount_usd, c.occurred_on, c.created_at
            FROM demo.costs c JOIN fleet.assets a
              ON a.tenant_id=c.tenant_id AND a.id=c.asset_id
            WHERE c.tenant_id=:tenant ORDER BY c.occurred_on DESC, c.id
            OFFSET 0 ROWS FETCH NEXT 200 ROWS ONLY
        """), {"tenant": str(member.tenant_id)}).mappings().all()
    return [{**dict(row), "amount_usd": str(row["amount_usd"])} for row in rows]


@router.post("/costs", status_code=201)
def create_cost(body: CostCreate,
                member: Annotated[DemoMember, Depends(selected_member)],
                _: Annotated[None, Depends(require_demo_request)]) -> dict:
    _require(member, "demo.finance.create")
    cost_id = uuid4()
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()
        with connection.begin():
            _fresh_permission(connection, member, "demo.finance.create")
            if _asset(connection, member.tenant_id, body.asset_id) is None:
                raise HTTPException(404, "Equipment not found")
            if body.trip_reference and not connection.execute(text("""
                SELECT 1 FROM demo.assignments WHERE tenant_id=:tenant AND trip_reference=:trip
            """), {"tenant": str(member.tenant_id), "trip": body.trip_reference}).first():
                raise HTTPException(422, "Trip reference not found")
            connection.execute(text("""
                INSERT INTO demo.costs (id, tenant_id, asset_id, trip_reference,
                    category, amount_usd, occurred_on, created_by)
                VALUES (:id, :tenant, :asset, :trip, :category, :amount, :date, :member)
            """), {"id": str(cost_id), "tenant": str(member.tenant_id),
                   "asset": str(body.asset_id), "trip": body.trip_reference,
                   "category": body.category, "amount": body.amount_usd,
                   "date": body.occurred_on, "member": str(member.membership_id)})
            _audit(connection, member, "cost.demo_add", "demo.costs", cost_id)
    return {"id": cost_id}
