"""Bounded, tenant-scoped facts for the fictional hosted staging workspace."""

import re
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import text

from app.core.clerk_auth import ClerkMember
from app.core.db import tenant_connection
from app.core.production_db import get_production_engine

DOMAIN = re.compile(r"\b(?:gps|location|last seen|where|trip|dispatch|assignments?|maintenance|service|repair|due|costs?|expenses?|fuel|tolls?|documents?|insurance|registration|reports?|available)\b", re.IGNORECASE)
UNSUPPORTED = re.compile(r"\b(?:driver|hos|eld|compliance|profit|revenue|cpm|invoice|payment)\b", re.IGNORECASE)
UNIT_REFERENCE = re.compile(r"\b[A-Za-z][A-Za-z0-9-]*-\d+\b")


def _reference_params(question: str) -> tuple[set[str], dict[str, str | None]]:
    references = {value.casefold() for value in UNIT_REFERENCE.findall(question)}
    selected = sorted(references)[:3]
    return references, {f"ref{index}": selected[index] if index < len(selected) else None
                        for index in range(3)}


def requested_domain(question: str) -> str | None:
    if UNSUPPORTED.search(question):
        return "unsupported"
    if not DOMAIN.search(question):
        return None
    for name, pattern in (
        ("documents", r"\b(?:documents?|insurance|registration)\b"),
        ("costs", r"\b(?:costs?|expenses?|fuel|tolls?)\b"),
        ("reports", r"\breports?\b"),
        ("maintenance", r"\b(?:maintenance|service|repair|due)\b"),
        ("dispatch", r"\b(?:trip|dispatch|assignments?|available)\b"),
        ("gps", r"\b(?:gps|location|last seen|where)\b"),
    ):
        if re.search(pattern, question, re.IGNORECASE):
            return name
    return None


def _time(value: datetime | None) -> str | None:
    return value.replace(tzinfo=UTC).isoformat().replace("+00:00", "Z") if value else None


def gather_pilot_facts(member: ClerkMember, question: str, domain: str) -> dict[str, Any]:
    tenant = str(member.tenant_id)
    now = datetime.now(UTC).isoformat().replace("+00:00", "Z")
    requested_refs, ref_params = _reference_params(question)
    parameters = {"tenant": tenant, **ref_params}
    permission = "pilot.documents.read" if domain == "documents" else (
        "pilot.finance.read" if domain == "costs" else "fleet.vehicle.read")
    with tenant_connection(get_production_engine(), member.tenant_id) as connection:
        grants = connection.execute(text("""
            EXEC iam.get_verified_memberships @auth_provider='clerk',
                @external_subject=:subject, @selected_tenant=:tenant
        """), {"subject": member.subject, "tenant": tenant}).mappings().all()
        if not any(row["permission_code"] == permission
                   and UUID(str(row["membership_id"])) == member.membership_id for row in grants):
            raise HTTPException(403, "AI Fleet access denied")
        sources: list[dict[str, Any]] = []
        if domain in {"gps", "maintenance", "reports"}:
            rows = connection.execute(text("""
                SELECT TOP (40) a.id, a.unit_number, a.status, t.code AS asset_type,
                    s.odometer_miles, s.service_due_date, s.service_due_miles, s.service_note,
                    s.gps_latitude, s.gps_longitude, s.gps_source,
                    s.gps_observed_at, s.gps_received_at, s.updated_at
                FROM fleet.assets a JOIN ref.asset_types t ON t.id=a.asset_type_id
                LEFT JOIN pilot.asset_state s ON s.tenant_id=a.tenant_id AND s.asset_id=a.id
                WHERE a.tenant_id=:tenant AND t.code IN ('TRACTOR','TRAILER')
                  AND (:ref0 IS NULL OR LOWER(a.unit_number) IN (:ref0,:ref1,:ref2))
                ORDER BY a.unit_number
            """), parameters).mappings().all()
            relevant = rows
            if domain == "gps":
                relevant = [row for row in relevant if row["asset_type"] == "TRACTOR"]
            view = {"gps": "GPS", "maintenance": "Maintenance", "reports": "Reports"}[domain]
            sources = [{"kind": "asset", "id": str(row["id"]), "label": row["unit_number"],
                        "view": view, "updated_at": _time(row["updated_at"])} for row in relevant]
            if domain == "gps":
                lines = []
                for row in relevant:
                    observed = _time(row["gps_observed_at"])
                    if observed:
                        age = (datetime.now(UTC) - row["gps_observed_at"].replace(tzinfo=UTC)).total_seconds()
                        fresh = "stale" if age > 3600 else "recent"
                        lines.append(f"{row['unit_number']}: {fresh} last-known position {row['gps_latitude']}, {row['gps_longitude']}; observed {observed}; received {_time(row['gps_received_at'])}; source {row['gps_source']}.")
                    else:
                        lines.append(f"{row['unit_number']}: no verified position recorded.")
                answer = " ".join(lines) or ("No matching truck position was found for this carrier."
                                             if requested_refs else "No truck position records were found for this carrier.")
            elif domain == "maintenance":
                lines = [f"{row['unit_number']}: status {row['status']}; odometer {row['odometer_miles'] if row['odometer_miles'] is not None else 'unknown'} miles; service due date {row['service_due_date'] or 'unknown'}; service due mileage {row['service_due_miles'] if row['service_due_miles'] is not None else 'unknown'} miles; note {row['service_note'] or 'none'}." for row in relevant]
                answer = " ".join(lines) or ("No matching equipment was found for this carrier."
                                             if requested_refs else "No maintenance records were found for this carrier.")
            else:
                counts: dict[str, int] = {}
                for row in relevant:
                    key = f"{row['asset_type']} {row['status']}"
                    counts[key] = counts.get(key, 0) + 1
                answer = "Fleet report for the first 40 matching equipment records: " + (", ".join(f"{value} {key}" for key, value in counts.items()) or "no matching equipment") + ". Cost completeness and mileage basis are unknown."
        elif domain == "dispatch":
            rows = connection.execute(text("""
                SELECT TOP (40) x.id, x.trip_reference, truck.unit_number AS truck_unit,
                    trailer.unit_number AS trailer_unit, x.starts_at, x.ends_at, x.created_at
                FROM pilot.assignments x
                JOIN fleet.assets truck ON truck.tenant_id=x.tenant_id AND truck.id=x.truck_asset_id
                LEFT JOIN fleet.assets trailer ON trailer.tenant_id=x.tenant_id AND trailer.id=x.trailer_asset_id
                WHERE x.tenant_id=:tenant
                  AND (:ref0 IS NULL OR LOWER(x.trip_reference) IN (:ref0,:ref1,:ref2)
                       OR LOWER(truck.unit_number) IN (:ref0,:ref1,:ref2)
                       OR LOWER(trailer.unit_number) IN (:ref0,:ref1,:ref2))
                ORDER BY x.starts_at DESC
            """), parameters).mappings().all()
            relevant = rows
            sources = [{"kind": "assignment", "id": str(row["id"]), "label": row["trip_reference"],
                        "view": "Dispatch", "updated_at": _time(row["created_at"])} for row in relevant]
            answer = " ".join(f"{row['trip_reference']}: {row['truck_unit']}"
                              f"{(' + ' + row['trailer_unit']) if row['trailer_unit'] else ''}, "
                              f"{_time(row['starts_at'])} to {_time(row['ends_at'])}." for row in relevant)
            answer = answer or ("No matching dispatch assignment was found for this carrier."
                                if requested_refs else "No dispatch assignments are recorded for this carrier.")
            if "available" in question.lower():
                equipment = connection.execute(text("""
                    SELECT TOP (40) a.id, a.unit_number, a.status, t.code AS asset_type
                    FROM fleet.assets a JOIN ref.asset_types t ON t.id=a.asset_type_id
                    WHERE a.tenant_id=:tenant AND t.code IN ('TRACTOR','TRAILER')
                    ORDER BY a.unit_number
                """), {"tenant": tenant}).mappings().all()
                assigned = connection.execute(text("""
                    SELECT truck_asset_id, trailer_asset_id FROM pilot.assignments
                    WHERE tenant_id=:tenant AND starts_at <= SYSUTCDATETIME()
                      AND ends_at > SYSUTCDATETIME()
                """), {"tenant": tenant}).mappings().all()
                busy = {str(value) for row in assigned for value in row.values() if value is not None}
                available = [row for row in equipment if row["status"] == "AVAILABLE"
                             and str(row["id"]) not in busy]
                answer += " Available and unassigned now (first 40 equipment records): " + (
                    ", ".join(f"{row['unit_number']} ({row['asset_type']})" for row in available)
                    or "none") + ". Future trip windows require a separate overlap check."
                sources.extend({"kind": "asset", "id": str(row["id"]),
                                "label": row["unit_number"], "view": "Dispatch",
                                "updated_at": None} for row in equipment)
        elif domain == "documents":
            rows = connection.execute(text("""
                SELECT TOP (40) d.id, a.unit_number, d.kind, d.expires_on, d.uploaded_at
                FROM pilot.documents d JOIN fleet.assets a ON a.tenant_id=d.tenant_id AND a.id=d.asset_id
                WHERE d.tenant_id=:tenant
                  AND (:ref0 IS NULL OR LOWER(a.unit_number) IN (:ref0,:ref1,:ref2))
                ORDER BY d.uploaded_at DESC
            """), parameters).mappings().all()
            sources = [{"kind": "document", "id": str(row["id"]), "label": f"{row['unit_number']} {row['kind']}",
                        "view": "Documents", "updated_at": _time(row["uploaded_at"])} for row in rows]
            answer = " ".join(f"{row['unit_number']} {row['kind']}: expires {row['expires_on'] or 'unknown'}." for row in rows)
            answer = answer or "No registration or insurance records are available for this carrier."
            answer += " I cannot determine regulatory compliance from these records."
        else:
            rows = connection.execute(text("""
                SELECT TOP (40) c.id, a.unit_number, c.trip_reference, c.category,
                    c.amount_usd, c.occurred_on, c.created_at
                FROM pilot.costs c JOIN fleet.assets a ON a.tenant_id=c.tenant_id AND a.id=c.asset_id
                WHERE c.tenant_id=:tenant
                  AND (:ref0 IS NULL OR LOWER(a.unit_number) IN (:ref0,:ref1,:ref2)
                       OR LOWER(c.trip_reference) IN (:ref0,:ref1,:ref2))
                ORDER BY c.occurred_on DESC, c.id
            """), parameters).mappings().all()
            sources = [{"kind": "cost", "id": str(row["id"]), "label": f"{row['unit_number']} {row['category']}",
                        "view": "Costs", "updated_at": _time(row["created_at"])} for row in rows]
            total = sum((row["amount_usd"] for row in rows), Decimal("0.00"))
            answer = f"In the latest {len(rows)} matching recorded USD cost entries (limit 40): ${total:.2f}. "
            answer += " ".join(f"{row['unit_number']} {row['category']} ${row['amount_usd']:.2f} on {row['occurred_on']}." for row in rows)
            answer += " Coverage and mileage basis are unknown; this is not net profit."
    return {"queried_at": now, "scope": {"tenant_id": tenant}, "sources": sources,
            "facts": [{"tool": f"get{domain.title()}Facts", "answer": answer}], "answer": answer}
