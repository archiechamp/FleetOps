"""Deterministic, read-only answers from already authorized Copilot facts."""

import re
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any


def matches_reference(question: str, value: Any) -> bool:
    if not value:
        return False
    return re.search(r"(?<![\w-])" + re.escape(str(value)) + r"(?![\w-])",
                     question, re.IGNORECASE) is not None


def _time(value: str | None) -> str:
    return value or "unknown time"


def _fact(bundle: dict, tool: str) -> dict | None:
    return next((item for item in bundle["facts"] if item["tool"] == tool), None)


def answer_from_database(question: str, bundle: dict, reason: str) -> str:
    """Summarize bounded SQL results without guessing or implying a model answered."""
    intro = f"{reason} Showing verified database records for this carrier instead."
    lower = question.casefold()
    lines: list[str] = []
    dispatch = _fact(bundle, "getAvailableVehicles")
    location = _fact(bundle, "getVehicleLocation")
    maintenance = _fact(bundle, "getMaintenanceDue")
    finance = _fact(bundle, "getTripFinancialSummary")
    fleet = _fact(bundle, "getFleetSummary")
    named_assets = ([row for row in dispatch["assets"]
                     if matches_reference(question, row["unit_number"])] if dispatch else [])
    named_trips = ([row for row in dispatch["assignment_windows"]
                    if matches_reference(question, row["trip_reference"])] if dispatch else [])
    if named_trips:
        named_assets = []

    if location and any(word in lower for word in ("where", "gps", "location", "position", "last seen")):
        vehicles = location["vehicles"]
        matched = [row for row in vehicles if matches_reference(question, row["unit_number"])]
        if not matched:
            if any(token in lower for token in ("demo-", "truck ", "tractor ")):
                lines.append("No matching tractor was found in the returned location records.")
            else:
                matched = vehicles[:10]
        for row in matched:
            observed = row["gps_observed_at"]
            if row["gps_latitude"] is None or row["gps_longitude"] is None or not observed:
                lines.append(f"{row['unit_number']}: no recorded position.")
                continue
            try:
                age = datetime.now(UTC) - datetime.fromisoformat(observed)
                freshness = "stale" if age.total_seconds() > 3600 else "last known"
            except ValueError:
                freshness = "last known; freshness unknown"
            lines.append(f"{row['unit_number']}: {freshness} position "
                         f"{row['gps_latitude']}, {row['gps_longitude']}; "
                         f"observed {_time(observed)}; source {row['gps_source'] or 'unknown'}.")
        if location["truncated"]:
            lines.append("Location results are limited to 40 tractors.")
    elif finance and finance.get("access") != "denied" and any(
            word in lower for word in ("cost", "expense", "fuel", "toll", "finance", "spend", "profit", "revenue", "cpm")):
        summary = finance["recorded_costs_by_category"]
        records = finance.get("recent_cost_records", [])
        named_costs = [row for row in records if matches_reference(question, row["unit_number"])
                       or matches_reference(question, row["trip_reference"])]
        if named_assets or named_trips:
            if named_costs:
                total = sum((Decimal(str(row["amount_usd"])) for row in named_costs), Decimal(0))
                lines.append(f"Matching recent recorded expenses: USD {total:,.2f} across {len(named_costs)} entries.")
                lines.extend(f"{row['category']}: USD {Decimal(str(row['amount_usd'])):,.2f} "
                             f"for {row['unit_number']}" +
                             (f", trip {row['trip_reference']}" if row["trip_reference"] else "") + "."
                             for row in named_costs[:10])
            else:
                lines.append("No matching expense appears in the returned recent cost records; this does not mean the cost is zero.")
        else:
            total = sum((Decimal(str(row["amount_usd"])) for row in summary), Decimal(0))
            lines.append(f"Recorded expenses total USD {total:,.2f} across {sum(row['entry_count'] for row in summary)} entries.")
            for row in summary:
                lines.append(f"{row['category']}: USD {Decimal(str(row['amount_usd'])):,.2f} ({row['entry_count']} entries).")
        lines.append("Cost completeness is unknown. Period mileage and revenue are not recorded; cost per mile and profit are unavailable.")
        if finance.get("truncated"):
            lines.append("Recent cost records are limited to 40 entries.")
    elif dispatch and (named_trips or (not named_assets and any(
            word in lower for word in ("trip", "dispatch", "assign")))):
        assignments = dispatch["assignment_windows"]
        matched = named_trips
        if not matched:
            matched = assignments[:10] if "trip" not in lower else []
        for row in matched:
            lines.append(f"{row['trip_reference']}: truck {row['truck_unit']}" +
                         (f", trailer {row['trailer_unit']}" if row["trailer_unit"] else "") +
                         f"; assignment window {_time(row['starts_at'])} to {_time(row['ends_at'])} UTC.")
        if not matched:
            lines.append("No matching trip assignment was found in the returned records.")
        if dispatch["truncated"]:
            lines.append("Dispatch results are limited to 40 assets and 40 assignments.")
        lines.append("These are equipment assignments; this demo does not record a full trip status or delivery evidence.")
    elif maintenance and any(word in lower for word in ("maintenance", "service", "repair", "due")):
        rows = maintenance["assets"]
        matched = [row for row in rows if matches_reference(question, row["unit_number"])]
        if not matched:
            matched = rows[:10]
        for row in matched:
            lines.append(f"{row['unit_number']}: {row['status']}; service due date "
                         f"{row['service_due_date'] or 'not recorded'}, due mileage "
                         f"{row['service_due_miles'] or 'not recorded'} mi; odometer "
                         f"{row['odometer_miles'] or 'not recorded'} mi.")
        if not rows:
            lines.append("No maintenance schedule or out-of-service record was found.")
        if maintenance["truncated"]:
            lines.append("Maintenance results are limited to 40 assets.")
    elif named_assets:
        for row in named_assets:
            lines.append(f"{row['unit_number']}: {row['asset_type']}, status {row['status']}.")
            details = [str(value) for value in (row.get("model_year"), row.get("make"), row.get("model")) if value]
            if details:
                lines.append("Vehicle: " + " ".join(details) + ".")
            if row.get("ownership_type"):
                lines.append(f"Ownership: {row['ownership_type']}.")
            if row.get("terminal"):
                lines.append(f"Terminal: {row['terminal']}.")
            if row.get("odometer_miles") is not None:
                lines.append(f"Odometer: {row['odometer_miles']} mi.")
            if location:
                gps = next((item for item in location["vehicles"] if item["id"] == row["id"]), None)
                if gps:
                    observed = gps["gps_observed_at"]
                    if gps["gps_latitude"] is not None and gps["gps_longitude"] is not None and observed:
                        try:
                            stale = (datetime.now(UTC) - datetime.fromisoformat(observed)).total_seconds() > 3600
                            freshness = "stale" if stale else "last known"
                        except ValueError:
                            freshness = "last known; freshness unknown"
                        lines.append(f"Last position ({freshness}): {gps['gps_latitude']}, {gps['gps_longitude']}; observed {observed}.")
                    else:
                        lines.append("No recorded position.")
            if maintenance:
                service = next((item for item in maintenance["assets"] if item["id"] == row["id"]), None)
                if service:
                    lines.append(f"Service due date {service['service_due_date'] or 'not recorded'}; "
                                 f"due mileage {service['service_due_miles'] or 'not recorded'} mi; "
                                 f"odometer {service['odometer_miles'] or 'not recorded'} mi.")
            assignments = [item for item in dispatch["assignment_windows"]
                           if item["truck_unit"] == row["unit_number"]
                           or item["trailer_unit"] == row["unit_number"]]
            if assignments:
                lines.append("Recorded assignments: " + ", ".join(
                    item["trip_reference"] for item in assignments[:5]) + ".")
        if dispatch["truncated"]:
            lines.append("Fleet and assignment results are limited to 40 records each.")
    elif dispatch:
        rows = dispatch["assets"]
        lines.append("Recorded equipment: " + ", ".join(
            f"{row['unit_number']} ({row['status']})" for row in rows[:10]) + ".")
        lines.append("Availability for a requested time window requires a dispatch recheck.")
        if dispatch["truncated"]:
            lines.append("Fleet results are limited to 40 assets.")
    elif fleet:
        carrier = fleet["carrier"]
        lines.append(f"{carrier['name']} equipment counts: " + ", ".join(
            f"{row['asset_count']} {row['asset_type']} {row['status']}"
            for row in fleet["equipment_counts"]) + ".")

    if not lines:
        lines.append("No supported record was found for this question. Try fleet, dispatch, GPS, maintenance, or recorded costs.")
    return intro + "\n\n" + "\n".join(lines)
