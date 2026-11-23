"""Allowlisted read models for the local Copilot. The model never receives SQL access."""

from datetime import UTC, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import text

from app.core.db import tenant_connection
from app.core.demo_auth import DemoMember
from app.core.demo_db import get_demo_engine
from app.modules.ai.database_answer import matches_reference


def _value(value: Any) -> Any:
    if isinstance(value, datetime):
        return value.replace(tzinfo=UTC).isoformat().replace("+00:00", "Z")
    if isinstance(value, Decimal):
        return str(value)
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    return str(value)


def _rows(connection, query: str, tenant: str) -> list[dict[str, Any]]:
    return [{key: _value(value) for key, value in row.items()}
            for row in connection.execute(text(query), {"tenant": tenant}).mappings().all()]


def _source(kind: str, record_id: Any, label: str, view: str,
            updated_at: str | None) -> dict[str, str | None]:
    return {"kind": kind, "id": str(record_id), "label": label,
            "view": view, "updated_at": updated_at}


def gather_facts(member: DemoMember, question: str) -> dict[str, Any]:
    """Select bounded, typed read tools; all use the verified tenant and permissions."""
    lower = question.casefold()
    words = lambda *items: any(item in lower for item in items)
    broad = words("overview", "everything", "summary", "fleetops")
    wants_dispatch = broad or words("fleet", "truck", "trailer", "vehicle",
                                    "dispatch", "assign", "trip", "available", "reserve")
    wants_gps = words("gps", "location", "position", "where", "last seen")
    wants_maintenance = broad or words("maintenance", "service", "repair", "due", "out of service")
    wants_finance = words("cost", "expense", "fuel", "toll", "finance", "spend",
                          "profit", "revenue", "cpm")
    now = datetime.now(UTC).isoformat().replace("+00:00", "Z")
    tenant = str(member.tenant_id)
    facts: list[dict[str, Any]] = []
    sources: list[dict[str, str | None]] = []
    cost_rows: list[dict[str, Any]] = []
    with tenant_connection(get_demo_engine(), member.tenant_id) as connection:
        grants = connection.execute(text("""
            EXEC iam.get_verified_memberships @auth_provider='demo',
                @external_subject=:subject, @selected_tenant=:tenant
        """), {"subject": member.subject, "tenant": tenant}).mappings().all()
        permissions = {row["permission_code"] for row in grants
                       if UUID(str(row["membership_id"])) == member.membership_id}
        if "fleet.vehicle.read" not in permissions:
            raise HTTPException(403, "Fleet access denied")
        # getFleetSummary: always included so broad carrier questions have a verified basis.
        carrier = _rows(connection, """
            SELECT id, name, timezone, currency_code, updated_at
            FROM core.tenants WHERE id=:tenant
        """, tenant)
        if not carrier:
            raise HTTPException(404, "Carrier not found")
        counts = _rows(connection, """
            SELECT t.code AS asset_type, a.status, COUNT(*) AS asset_count
            FROM fleet.assets a JOIN ref.asset_types t ON t.id=a.asset_type_id
            WHERE a.tenant_id=:tenant AND t.code IN ('TRACTOR','TRAILER')
            GROUP BY t.code, a.status
        """, tenant)
        facts.append({"tool": "getFleetSummary", "carrier": carrier[0],
                      "equipment_counts": counts, "queried_at": now})
        sources.append(_source("carrier", carrier[0]["id"], carrier[0]["name"],
                               "Overview", carrier[0]["updated_at"]))

        # Resolve named records from bounded, tenant-scoped SQL reads. A prompt such as
        # "tell me about DEMO-101" has no fleet keyword, but still names an asset.
        asset_rows = _rows(connection, """
            SELECT TOP (40) a.id, a.unit_number, t.code AS asset_type,
                   a.make, a.model, a.model_year, a.ownership_type,
                   term.name AS terminal, s.odometer_miles,
                   a.status, a.updated_at
            FROM fleet.assets a JOIN ref.asset_types t ON t.id=a.asset_type_id
            LEFT JOIN core.terminals term ON term.tenant_id=a.tenant_id
                AND term.id=a.terminal_id
            LEFT JOIN demo.asset_state s ON s.tenant_id=a.tenant_id
                AND s.asset_id=a.id
            WHERE a.tenant_id=:tenant AND t.code IN ('TRACTOR','TRAILER')
            ORDER BY a.unit_number
        """, tenant)
        assignment_rows = _rows(connection, """
            SELECT TOP (40) x.id, x.trip_reference, x.starts_at, x.ends_at,
                   truck.unit_number AS truck_unit, trailer.unit_number AS trailer_unit,
                   x.created_at
            FROM demo.assignments x
            JOIN fleet.assets truck ON truck.tenant_id=x.tenant_id
                AND truck.id=x.truck_asset_id
            LEFT JOIN fleet.assets trailer ON trailer.tenant_id=x.tenant_id
                AND trailer.id=x.trailer_asset_id
            WHERE x.tenant_id=:tenant
            ORDER BY x.starts_at DESC
        """, tenant)
        named_trips = [row for row in assignment_rows
                       if matches_reference(question, row["trip_reference"])]
        named_assets = ([] if named_trips else [row for row in asset_rows
                        if matches_reference(question, row["unit_number"])])
        wants_dispatch = wants_dispatch or bool(named_assets or named_trips)
        wants_gps = wants_gps or any(row["asset_type"] == "TRACTOR" for row in named_assets)
        wants_maintenance = wants_maintenance or bool(named_assets)

        if wants_dispatch:
            if "fleet.vehicle.read" not in permissions:
                raise HTTPException(403, "Dispatch access denied")
            facts.append({"tool": "getAvailableVehicles", "scope": "current asset status",
                          "assets": asset_rows, "assignment_windows": assignment_rows,
                          "note": "Future availability requires a requested interval and dispatch recheck; this demo has no driver or HOS validation.",
                          "truncated": len(asset_rows) == 40 or len(assignment_rows) == 40})
            sources.extend(_source("asset", row["id"], row["unit_number"],
                                   "Fleet", row["updated_at"]) for row in asset_rows)
            sources.extend(_source("assignment", row["id"], row["trip_reference"],
                                   "Dispatch", row["created_at"]) for row in assignment_rows)

        if wants_maintenance:
            if "fleet.vehicle.read" not in permissions:
                raise HTTPException(403, "Maintenance access denied")
            rows = _rows(connection, """
                SELECT TOP (40) a.id, a.unit_number, a.status, a.updated_at,
                       s.odometer_miles, s.service_due_date, s.service_due_miles
                FROM fleet.assets a JOIN demo.asset_state s
                  ON s.tenant_id=a.tenant_id AND s.asset_id=a.id
                WHERE a.tenant_id=:tenant
                  AND (s.service_due_date IS NOT NULL OR s.service_due_miles IS NOT NULL
                       OR a.status IN ('MAINTENANCE','OUT_OF_SERVICE'))
                ORDER BY a.unit_number
            """, tenant)
            facts.append({"tool": "getMaintenanceDue", "assets": rows,
                          "note": "Due dates and mileage are scheduling records, not compliance certification.",
                          "truncated": len(rows) == 40})
            sources.extend(_source("asset", row["id"], row["unit_number"],
                                   "Maintenance", row["updated_at"]) for row in rows)

        if wants_gps:
            if "fleet.vehicle.read" not in permissions:
                raise HTTPException(403, "Location access denied")
            rows = _rows(connection, """
                SELECT TOP (40) a.id, a.unit_number, s.gps_latitude,
                       s.gps_longitude, s.gps_source, s.gps_observed_at,
                       s.gps_received_at
                FROM fleet.assets a JOIN demo.asset_state s
                  ON s.tenant_id=a.tenant_id AND s.asset_id=a.id
                JOIN ref.asset_types t ON t.id=a.asset_type_id
                WHERE a.tenant_id=:tenant AND t.code='TRACTOR'
                ORDER BY a.unit_number
            """, tenant)
            facts.append({"tool": "getVehicleLocation", "vehicles": rows,
                          "note": "Last known position only; observations older than one hour are stale. No live provider is connected.",
                          "truncated": len(rows) == 40})
            sources.extend(_source("asset", row["id"], row["unit_number"],
                                   "GPS", row["gps_observed_at"]) for row in rows)

        if wants_finance:
            if "demo.finance.read" not in permissions:
                facts.append({"tool": "getTripFinancialSummary", "access": "denied"})
            else:
                rows = _rows(connection, """
                    SELECT TOP (40) c.id, c.asset_id, a.unit_number,
                           c.trip_reference, c.category, c.amount_usd,
                           c.occurred_on, c.created_at
                    FROM demo.costs c JOIN fleet.assets a
                      ON a.tenant_id=c.tenant_id AND a.id=c.asset_id
                    WHERE c.tenant_id=:tenant
                    ORDER BY c.occurred_on DESC, c.id
                """, tenant)
                cost_rows = rows
                summary = _rows(connection, """
                    SELECT c.category, COUNT(*) AS entry_count,
                           SUM(c.amount_usd) AS amount_usd
                    FROM demo.costs c WHERE c.tenant_id=:tenant
                    GROUP BY c.category
                """, tenant)
                facts.append({"tool": "getTripFinancialSummary", "currency": "USD",
                              "recorded_costs_by_category": summary,
                              "recent_cost_records": rows,
                              "data_completeness": "unknown",
                              "mileage_basis": "unavailable",
                              "revenue": "not recorded",
                              "note": "These are recorded costs only; no net profit or CPM can be calculated.",
                              "truncated": len(rows) == 40})
                sources.extend(_source("cost", row["id"],
                                       f'{row["category"]} · {row["unit_number"]}',
                                       "Costs", row["created_at"]) for row in rows)
    # Remove repeated source chips while keeping stable order and keeping the model context bounded.
    if named_assets or named_trips:
        asset_ids = {str(row["id"]) for row in named_assets}
        trip_ids = {str(row["id"]) for row in named_trips}
        cost_ids = {str(row["id"]) for row in cost_rows
                    if matches_reference(question, row["unit_number"])
                    or matches_reference(question, row["trip_reference"])}
        sources = [item for item in sources
                   if (item["kind"] == "asset" and item["id"] in asset_ids)
                   or (item["kind"] == "assignment" and item["id"] in trip_ids)
                   or (item["kind"] == "cost" and item["id"] in cost_ids)]
    unique = list({(item["kind"], item["id"], item["view"]): item
                   for item in sources}.values())
    return {"queried_at": now, "facts": facts, "sources": unique[:80],
            "scope": {"tenant_id": tenant}}
