"""Demo vehicle slice. All business reads and writes use verified carrier membership."""

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Response
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.core.db import tenant_connection
from app.core.demo_auth import DemoMember, require_demo_request, selected_member
from app.core.demo_db import get_demo_engine
from app.modules.fleet.idempotency import (
    RECEIPT_EXPIRY_UTC,
    parse_submission_key,
    parse_vehicle_reference,
    registration_digest,
    registration_operation_scope,
    vehicle_reference,
)
from app.modules.fleet.schemas import Vehicle, VehicleCreate

router = APIRouter(prefix="/vehicles", tags=["vehicles"])

_PROJECTION = """
    SELECT v.id, a.tenant_id, a.unit_number, a.make, a.model,
           a.model_year, a.ownership_type, a.created_at
    FROM fleet.vehicles AS v
    JOIN fleet.assets AS a ON a.tenant_id = v.tenant_id AND a.id = v.asset_id
"""


def _require(member: DemoMember, permission: str) -> None:
    if permission not in member.permissions:
        raise HTTPException(403, "Vehicle access denied")


def _vehicle(row) -> Vehicle:
    return Vehicle.model_validate(dict(row))


@router.get("", response_model=list[Vehicle])
def list_vehicles(
    member: Annotated[DemoMember, Depends(selected_member)],
    unit_number: Annotated[str | None, Query(max_length=30)] = None,
) -> list[Vehicle]:
    _require(member, "fleet.vehicle.read")
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        rows = connection.execute(text(_PROJECTION + """
            WHERE a.tenant_id = :tenant
              AND (:unit IS NULL OR a.unit_number = :unit)
            ORDER BY a.unit_number, v.id
            OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
        """), {"tenant": str(member.tenant_id), "unit": unit_number}).mappings().all()
    return [_vehicle(row) for row in rows]


@router.get("/{vehicle_id}", response_model=Vehicle)
def get_vehicle(
    vehicle_id: UUID, member: Annotated[DemoMember, Depends(selected_member)]
) -> Vehicle:
    _require(member, "fleet.vehicle.read")
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        row = connection.execute(text(_PROJECTION + """
            WHERE a.tenant_id = :tenant AND v.id = :vehicle
        """), {"tenant": str(member.tenant_id), "vehicle": str(vehicle_id)}).mappings().first()
    if row is None:
        raise HTTPException(404, "Vehicle not found")
    return _vehicle(row)


@router.post("", response_model=Vehicle, status_code=201)
def create_vehicle(
    payload: VehicleCreate,
    response: Response,
    member: Annotated[DemoMember, Depends(selected_member)],
    _: Annotated[None, Depends(require_demo_request)],
    idempotency_key: Annotated[str | None, Header()] = None,
) -> Vehicle:
    _require(member, "fleet.vehicle.create")
    if idempotency_key is None:
        raise HTTPException(422, "Idempotency-Key is required")
    try:
        key = parse_submission_key(idempotency_key)
    except ValueError:
        raise HTTPException(422, "Idempotency-Key must be a UUID") from None
    digest = registration_digest(payload)
    scope = registration_operation_scope(member.membership_id)
    vehicle_id = uuid4()
    asset_id = uuid4()
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        connection.commit()  # End the context-setting statement before the business transaction.
        try:
            with connection.begin():
                lock_result = connection.execute(text("""
                    DECLARE @result INT;
                    EXEC @result = sys.sp_getapplock
                        @Resource=:resource, @LockMode='Exclusive',
                        @LockOwner='Transaction', @LockTimeout=5000;
                    SELECT @result
                """), {"resource": f"vehicle:{member.tenant_id}:{member.membership_id}:{key}"}).scalar_one()
                if lock_result < 0:
                    raise HTTPException(503, "Registration is busy; retry with the same key")
                # Recheck after the lock: permission may have been revoked while waiting.
                fresh = connection.execute(text("""
                    EXEC iam.get_verified_memberships @auth_provider='demo',
                        @external_subject=:subject, @selected_tenant=:tenant
                """), {"subject": member.subject, "tenant": str(member.tenant_id)}).mappings().all()
                if not any(row["permission_code"] == "fleet.vehicle.create"
                           and UUID(str(row["membership_id"])) == member.membership_id
                           for row in fresh):
                    raise HTTPException(403, "Vehicle access denied")
                receipt = connection.execute(text("""
                    SELECT request_hash, response_reference
                    FROM integration.idempotency_keys
                    WHERE tenant_id=:tenant AND operation_scope=:scope AND request_key=:key
                """), {"tenant": str(member.tenant_id), "scope": scope,
                       "key": str(key)}).mappings().first()
                if receipt:
                    if bytes(receipt["request_hash"]) != digest:
                        raise HTTPException(409, "Retry key was used for another registration")
                    try:
                        old_id = parse_vehicle_reference(receipt["response_reference"])
                    except (ValueError, TypeError):
                        raise HTTPException(503, "Saved registration needs review") from None
                    row = connection.execute(text(_PROJECTION + """
                        WHERE a.tenant_id=:tenant AND v.id=:vehicle
                    """), {"tenant": str(member.tenant_id), "vehicle": str(old_id)}).mappings().first()
                    if row is None:
                        raise HTTPException(503, "Saved registration needs review")
                    result = _vehicle(row)
                else:
                    asset_type = connection.execute(text("""
                        SELECT id FROM ref.asset_types WHERE code='TRACTOR'
                    """)).scalar_one()
                    connection.execute(text("""
                        INSERT INTO fleet.assets
                          (id, tenant_id, unit_number, asset_type_id, make, model,
                           model_year, ownership_type, currency_code, created_by, updated_by)
                        VALUES (:id, :tenant, :unit, :type, :make, :model,
                                :year, :ownership, 'USD', :member, :member)
                    """), {"id": str(asset_id), "tenant": str(member.tenant_id),
                           "unit": payload.unit_number, "type": asset_type,
                           "make": payload.make, "model": payload.model,
                           "year": payload.model_year, "ownership": payload.ownership_type,
                           "member": str(member.membership_id)})
                    connection.execute(text("""
                        INSERT INTO fleet.vehicles (id, tenant_id, asset_id, created_by, updated_by)
                        VALUES (:id, :tenant, :asset, :member, :member)
                    """), {"id": str(vehicle_id), "tenant": str(member.tenant_id),
                           "asset": str(asset_id), "member": str(member.membership_id)})
                    connection.execute(text("""
                        INSERT INTO audit.audit_events
                          (tenant_id, actor_id, actor_type, action, entity_type, entity_id,
                           new_values, correlation_id, occurred_at)
                        VALUES (:tenant, :actor, 'USER', 'vehicle.register',
                                'fleet.vehicles', :vehicle, '{}', :correlation, :occurred)
                    """), {"tenant": str(member.tenant_id), "actor": str(member.user_id),
                           "vehicle": str(vehicle_id), "correlation": str(uuid4()),
                           "occurred": datetime.now(UTC).replace(tzinfo=None)})
                    connection.execute(text("""
                        INSERT INTO integration.idempotency_keys
                          (tenant_id, operation_scope, request_key, request_hash,
                           response_reference, expires_at, created_by, updated_by)
                        VALUES (:tenant, :scope, :key, :hash, :reference, :expiry,
                                :member, :member)
                    """), {"tenant": str(member.tenant_id), "scope": scope,
                           "key": str(key), "hash": digest,
                           "reference": vehicle_reference(vehicle_id),
                           "expiry": RECEIPT_EXPIRY_UTC.replace(tzinfo=None),
                           "member": str(member.membership_id)})
                    row = connection.execute(text(_PROJECTION + """
                        WHERE a.tenant_id=:tenant AND v.id=:vehicle
                    """), {"tenant": str(member.tenant_id),
                           "vehicle": str(vehicle_id)}).mappings().one()
                    result = _vehicle(row)
        except IntegrityError as error:
            if "UQ_fleet_assets_2" in str(error.orig):
                raise HTTPException(409, "Unit number already exists in this carrier") from None
            raise HTTPException(503, "Registration could not be saved") from None
    response.headers["Location"] = f"/api/v1/vehicles/{result.id}"
    return result
