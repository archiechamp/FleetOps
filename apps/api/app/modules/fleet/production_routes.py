"""Initial read-only production fleet slice."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text

from app.core.clerk_auth import (
    ClerkMember,
    selected_clerk_member,
    verified_memberships,
    verified_subject,
)
from app.core.db import tenant_connection
from app.core.production_db import get_production_engine
from app.modules.fleet.routes import _PROJECTION, _vehicle
from app.modules.fleet.schemas import Vehicle

router = APIRouter(tags=["production fleet"])


@router.get("/me")
def me(subject: Annotated[str, Depends(verified_subject)]) -> dict:
    members = verified_memberships(subject)
    if not members:
        raise HTTPException(403, "No active carrier membership")
    return {"carriers": [
        {"id": str(member.tenant_id), "permissions": sorted(member.permissions)}
        for member in members
    ]}


@router.get("/vehicles", response_model=list[Vehicle])
def list_vehicles(
    member: Annotated[ClerkMember, Depends(selected_clerk_member)],
    unit_number: Annotated[str | None, Query(max_length=30)] = None,
) -> list[Vehicle]:
    if "fleet.vehicle.read" not in member.permissions:
        raise HTTPException(403, "Vehicle access denied")
    with tenant_connection(get_production_engine(), member.tenant_id) as connection:
        rows = connection.execute(text(_PROJECTION + """
            WHERE a.tenant_id = :tenant
              AND (:unit IS NULL OR a.unit_number = :unit)
            ORDER BY a.unit_number, v.id
            OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
        """), {"tenant": str(member.tenant_id), "unit": unit_number}).mappings().all()
    return [_vehicle(row) for row in rows]
