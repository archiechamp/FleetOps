"""Bounded, authorized reads from the approved production fleet foundation."""

import re
from datetime import UTC, datetime
from typing import Any
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import text

from app.core.clerk_auth import ClerkMember
from app.core.db import tenant_connection
from app.core.production_db import get_production_engine
from app.modules.ai.database_answer import matches_reference

_UNIT_REFERENCE = re.compile(r"\b[A-Za-z0-9]+(?:-[A-Za-z0-9]+)+\b")


def gather_production_facts(member: ClerkMember, question: str) -> dict[str, Any]:
    tenant = str(member.tenant_id)
    queried_at = datetime.now(UTC).isoformat().replace("+00:00", "Z")
    with tenant_connection(get_production_engine(), member.tenant_id) as connection:
        grants = connection.execute(text("""
            EXEC iam.get_verified_memberships @auth_provider='clerk',
                @external_subject=:subject, @selected_tenant=:tenant
        """), {"subject": member.subject, "tenant": tenant}).mappings().all()
        if not any(row["permission_code"] == "fleet.vehicle.read"
                   and UUID(str(row["membership_id"])) == member.membership_id
                   for row in grants):
            raise HTTPException(403, "Fleet access denied")
        carrier = connection.execute(text("""
            SELECT id, name, timezone, currency_code, updated_at
            FROM core.tenants WHERE id=:tenant
        """), {"tenant": tenant}).mappings().first()
        if carrier is None:
            raise HTTPException(404, "Carrier not found")
        counts = connection.execute(text("""
            SELECT t.code AS asset_type, a.status, COUNT(*) AS asset_count
            FROM fleet.assets a JOIN ref.asset_types t ON t.id=a.asset_type_id
            WHERE a.tenant_id=:tenant AND t.code IN ('TRACTOR','TRAILER')
            GROUP BY t.code, a.status
        """), {"tenant": tenant}).mappings().all()
        assets = connection.execute(text("""
            SELECT TOP (40) a.id, a.unit_number, t.code AS asset_type,
                   a.make, a.model, a.model_year, a.ownership_type,
                   a.status, a.updated_at
            FROM fleet.assets a JOIN ref.asset_types t ON t.id=a.asset_type_id
            WHERE a.tenant_id=:tenant AND t.code IN ('TRACTOR','TRAILER')
            ORDER BY a.unit_number
        """), {"tenant": tenant}).mappings().all()
        references = list(dict.fromkeys(_UNIT_REFERENCE.findall(question)))[:5]
        matched = []
        for reference in references:
            rows = connection.execute(text("""
                SELECT TOP (2) a.id, a.unit_number, t.code AS asset_type,
                       a.make, a.model, a.model_year, a.ownership_type,
                       a.status, a.updated_at
                FROM fleet.assets a JOIN ref.asset_types t ON t.id=a.asset_type_id
                WHERE a.tenant_id=:tenant AND a.unit_number=:unit
                  AND t.code IN ('TRACTOR','TRAILER')
            """), {"tenant": tenant, "unit": reference}).mappings().all()
            matched.extend(row for row in rows if matches_reference(question, row["unit_number"]))
    named = matched or [row for row in assets if matches_reference(question, row["unit_number"])]
    visible = named if references else assets
    source_assets = named or (assets[:10] if not references and len(assets) <= 10 else [])
    sources = [{"kind": "carrier", "id": tenant, "label": carrier["name"],
                "view": "Overview", "updated_at": _time(carrier["updated_at"])}]
    sources.extend({"kind": "asset", "id": str(row["id"]),
                    "label": row["unit_number"], "view": "Fleet",
                    "updated_at": _time(row["updated_at"])} for row in source_assets)
    return {
        "queried_at": queried_at,
        "scope": {"tenant_id": tenant},
        "facts": [{
            "tool": "getFleetSummary",
            "carrier": {"id": tenant, "name": carrier["name"],
                        "timezone": carrier["timezone"], "currency_code": carrier["currency_code"]},
            "equipment_counts": [dict(row) for row in counts],
            "assets": [{"id": str(row["id"]), "unit_number": row["unit_number"],
                        "asset_type": row["asset_type"], "make": row["make"],
                        "model": row["model"], "model_year": row["model_year"],
                        "ownership_type": row["ownership_type"], "status": row["status"],
                        "updated_at": _time(row["updated_at"])} for row in visible],
            "truncated": len(assets) == 40 and not named,
            "note": "Current asset status only. Dispatch availability, maintenance, GPS and costs are not yet connected to the production data model.",
        }],
        "sources": sources,
        "named_asset_found": bool(named),
        "requested_units": references,
        "asset_count_returned": len(assets),
    }


def _time(value: datetime | None) -> str | None:
    if value is None:
        return None
    return value.replace(tzinfo=UTC).isoformat().replace("+00:00", "Z")
