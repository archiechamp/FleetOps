"""One-shot, repeatable fictional operations for the approved staging carrier."""

import os
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid5

from sqlalchemy import create_engine, text

from app.core.migration_config import migration_target
from tools.seed_staging_fictional_fleet import NAMESPACE, STAGING_DATABASE, _id

EXPECTED_REVISION = "0006_staging_operations"


def _record_id(tenant: str, kind: str) -> str:
    return str(uuid5(NAMESPACE, f"staging:{tenant}:{kind}"))


def _fictional_pdf() -> bytes:
    """Make a valid, tiny PDF without pulling private documents into staging."""
    stream = b"BT /F1 14 Tf 40 740 Td (FICTIONAL STAGING REGISTRATION) Tj ET\n"
    objects = (
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Length " + str(len(stream)).encode() + b" >>\nstream\n" + stream + b"endstream",
    )
    document = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for index, value in enumerate(objects, 1):
        offsets.append(len(document))
        document.extend(f"{index} 0 obj\n".encode() + value + b"\nendobj\n")
    start_xref = len(document)
    document.extend(f"xref\n0 {len(offsets)}\n0000000000 65535 f \n".encode())
    for offset in offsets[1:]:
        document.extend(f"{offset:010d} 00000 n \n".encode())
    document.extend(f"trailer\n<< /Size {len(offsets)} /Root 1 0 R >>\nstartxref\n{start_xref}\n%%EOF\n".encode())
    return bytes(document)


def seed() -> tuple[str, int]:
    if os.environ.get("FLEETOPS_ENV") != "production":
        raise RuntimeError("Fictional operations require the production schema mode")
    if os.environ.get("FLEETOPS_STAGING_FICTIONAL_SEED") != "approved":
        raise RuntimeError("Explicit fictional staging seed approval is required")
    tenant = str(UUID(os.environ["FLEETOPS_STAGING_DEMO_TENANT_ID"]))
    url, head = migration_target()
    if url.database != STAGING_DATABASE or head != "production@head":
        raise RuntimeError("Fictional operations refuse a non-staging target")
    engine = create_engine(url)
    try:
        with engine.begin() as connection:
            revision = connection.execute(text("SELECT version_num FROM dbo.alembic_version")).scalar_one()
            if revision != EXPECTED_REVISION:
                raise RuntimeError("Staging schema is not at the approved revision")
            connection.execute(text("""
                DECLARE @selected UNIQUEIDENTIFIER = CONVERT(UNIQUEIDENTIFIER, :tenant);
                EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@selected
            """), {"tenant": tenant})
            carrier = connection.execute(text("""
                SELECT name, status FROM core.tenants WHERE id=:tenant
            """), {"tenant": tenant}).mappings().one_or_none()
            if carrier is None or carrier["status"] != "ACTIVE" or "fictional" not in carrier["name"].casefold():
                raise RuntimeError("Approved fictional staging carrier is missing")
            expected = {_id(tenant, "asset", unit) for unit in ("DEMO-101", "DEMO-102", "TRL-301", "TRL-302")}
            assets = connection.execute(text("""
                SELECT id, unit_number FROM fleet.assets WHERE tenant_id=:tenant
            """), {"tenant": tenant}).mappings().all()
            if {str(row["id"]) for row in assets} != expected:
                raise RuntimeError("Carrier assets differ from the approved fictional seed")
            members = connection.execute(text("""
                SELECT m.id FROM iam.memberships m
                JOIN iam.membership_roles mr ON mr.tenant_id=m.tenant_id AND mr.membership_id=m.id
                JOIN iam.roles r ON r.tenant_id=mr.tenant_id AND r.id=mr.role_id
                WHERE m.tenant_id=:tenant AND m.status='ACTIVE' AND r.code='PILOT_READER'
            """), {"tenant": tenant}).scalars().all()
            if len(members) != 1:
                raise RuntimeError("Exactly one approved fictional pilot member is required")
            membership = members[0]
            role = connection.execute(text("""
                SELECT id FROM iam.roles WHERE tenant_id=:tenant AND code='PILOT_READER'
            """), {"tenant": tenant}).scalar_one()
            for code, resource, action in (
                ("pilot.documents.read", "pilot.documents", "read"),
                ("pilot.finance.read", "pilot.finance", "read"),
                ("fleet.vehicle.create", "fleet.vehicle", "create"),
                ("pilot.documents.write", "pilot.documents", "write"),
                ("pilot.finance.write", "pilot.finance", "write"),
            ):
                permission = _record_id(tenant, f"permission:{code}")
                connection.execute(text("""
                    IF NOT EXISTS (SELECT 1 FROM iam.permissions WHERE code=:code)
                        INSERT INTO iam.permissions (id, code, resource, action)
                        VALUES (:id, :code, :resource, :action)
                """), {"id": permission, "code": code, "resource": resource, "action": action})
                permission = str(connection.execute(text("""
                    SELECT id FROM iam.permissions WHERE code=:code
                """), {"code": code}).scalar_one())
                grant_role = role
                if action in {"create", "write"}:
                    creator_role = _record_id(tenant, "role:pilot-creator")
                    connection.execute(text("""
                        IF NOT EXISTS (SELECT 1 FROM iam.roles WHERE tenant_id=:tenant AND code='PILOT_CREATOR')
                            INSERT INTO iam.roles (id, tenant_id, code, name)
                            VALUES (:id, :tenant, 'PILOT_CREATOR', 'Fictional staging creator')
                    """), {"id": creator_role, "tenant": tenant})
                    grant_role = connection.execute(text("""
                        SELECT id FROM iam.roles WHERE tenant_id=:tenant AND code='PILOT_CREATOR'
                    """), {"tenant": tenant}).scalar_one()
                    connection.execute(text("""
                        IF NOT EXISTS (SELECT 1 FROM iam.membership_roles
                                       WHERE tenant_id=:tenant AND membership_id=:member AND role_id=:role)
                            INSERT INTO iam.membership_roles (id, tenant_id, membership_id, role_id)
                            VALUES (:id, :tenant, :member, :role)
                    """), {"id": _record_id(tenant, "member-role:pilot-creator"),
                           "tenant": tenant, "member": str(membership), "role": str(grant_role)})
                connection.execute(text("""
                    IF NOT EXISTS (SELECT 1 FROM iam.role_permissions
                                   WHERE tenant_id=:tenant AND role_id=:role AND permission_id=:permission)
                        INSERT INTO iam.role_permissions (id, tenant_id, role_id, permission_id)
                        VALUES (:id, :tenant, :role, :permission)
                """), {"id": _record_id(tenant, f"grant:{code}"), "tenant": tenant,
                       "role": str(grant_role), "permission": permission})
            now = datetime.now(UTC).replace(tzinfo=None)
            state = (
                ("DEMO-101", Decimal("128450.0"), Decimal("130000.0"),
                 (now + timedelta(days=14)).date(), 41.878113, -87.629799, now - timedelta(hours=3)),
                ("DEMO-102", Decimal("149500.0"), Decimal("149000.0"),
                 (now - timedelta(days=2)).date(), 41.882702, -87.623301, now - timedelta(minutes=20)),
                ("TRL-301", None, None, None, None, None, None),
                ("TRL-302", None, None, None, None, None, None),
            )
            for unit, odometer, due_miles, due_date, lat, lon, observed in state:
                connection.execute(text("""
                    IF NOT EXISTS (SELECT 1 FROM pilot.asset_state WHERE tenant_id=:tenant AND asset_id=:asset)
                        INSERT INTO pilot.asset_state
                          (tenant_id, asset_id, odometer_miles, service_due_miles, service_due_date,
                           gps_latitude, gps_longitude, gps_source, gps_observed_at, gps_received_at)
                        VALUES (:tenant, :asset, :odometer, :due_miles, :due_date,
                                :lat, :lon, :source, :observed, :received)
                """), {"tenant": tenant, "asset": _id(tenant, "asset", unit),
                       "odometer": odometer, "due_miles": due_miles, "due_date": due_date,
                       "lat": lat, "lon": lon,
                       "source": "Fictional staging observation" if observed else None,
                       "observed": observed, "received": observed + timedelta(minutes=2) if observed else None})
            trip = "DEMO-TRIP-1"
            connection.execute(text("""
                IF NOT EXISTS (SELECT 1 FROM pilot.assignments WHERE tenant_id=:tenant AND trip_reference=:trip)
                    INSERT INTO pilot.assignments
                      (id, tenant_id, truck_asset_id, trailer_asset_id, trip_reference,
                       starts_at, ends_at, created_by)
                    VALUES (:id, :tenant, :truck, :trailer, :trip, :starts, :ends, :member)
            """), {"id": _record_id(tenant, "assignment:1"), "tenant": tenant,
                   "truck": _id(tenant, "asset", "DEMO-101"),
                   "trailer": _id(tenant, "asset", "TRL-301"), "trip": trip,
                   "starts": now - timedelta(hours=1), "ends": now + timedelta(hours=8),
                   "member": str(membership)})
            pdf = _fictional_pdf()
            connection.execute(text("""
                IF NOT EXISTS (SELECT 1 FROM pilot.documents WHERE id=:id)
                    INSERT INTO pilot.documents
                      (id, tenant_id, asset_id, kind, expires_on, file_name,
                       content_type, file_bytes, uploaded_by)
                    VALUES (:id, :tenant, :asset, 'REGISTRATION', :expires,
                            'fictional-registration.pdf', 'application/pdf', :data, :member)
            """), {"id": _record_id(tenant, "document:registration"), "tenant": tenant,
                   "asset": _id(tenant, "asset", "DEMO-101"),
                   "expires": (now + timedelta(days=90)).date(), "data": pdf,
                   "member": str(membership)})
            for unit, category, amount, trip_ref in (
                ("DEMO-101", "FUEL", Decimal("325.50"), trip),
                ("DEMO-102", "MAINTENANCE", Decimal("75.00"), None),
            ):
                connection.execute(text("""
                    IF NOT EXISTS (SELECT 1 FROM pilot.costs WHERE id=:id)
                        INSERT INTO pilot.costs
                          (id, tenant_id, asset_id, trip_reference, category,
                           amount_usd, occurred_on, created_by)
                        VALUES (:id, :tenant, :asset, :trip, :category, :amount, :date, :member)
                """), {"id": _record_id(tenant, f"cost:{unit}:{category}"),
                       "tenant": tenant, "asset": _id(tenant, "asset", unit),
                       "trip": trip_ref, "category": category, "amount": amount,
                       "date": (now - timedelta(days=1)).date(), "member": str(membership)})
        return tenant, len(state)
    finally:
        engine.dispose()


if __name__ == "__main__":
    tenant_id, count = seed()
    print(f"Fictional staging operations ready: carrier={tenant_id} assets={count}")
