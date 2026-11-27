"""One-shot, reviewed Clerk reader onboarding on an approved production SQL target."""

import os
import re
from uuid import UUID, uuid4
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import create_engine, text

from app.core.migration_config import migration_target

EXPECTED_REVISIONS = {"0005_production_readiness_grant", "0006_staging_operations"}


def inputs() -> tuple[str, str, str, str]:
    subject = os.environ.get("FLEETOPS_PILOT_CLERK_USER_ID", "")
    name = os.environ.get("FLEETOPS_PILOT_TENANT_NAME", "").strip()
    slug = os.environ.get("FLEETOPS_PILOT_TENANT_SLUG", "").strip()
    timezone = os.environ.get("FLEETOPS_PILOT_TIMEZONE", "")
    if not re.fullmatch(r"user_[A-Za-z0-9]{8,100}", subject):
        raise RuntimeError("A verified Clerk user ID is required")
    if not 1 <= len(name) <= 200 or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", slug):
        raise RuntimeError("Valid pilot carrier name and slug are required")
    if len(slug) > 100:
        raise RuntimeError("Pilot carrier slug is too long")
    try:
        ZoneInfo(timezone)
    except (ZoneInfoNotFoundError, ValueError):
        raise RuntimeError("A valid IANA pilot time zone is required") from None
    return subject, name, slug, timezone


def provision() -> tuple[str, str]:
    subject, name, slug, timezone = inputs()
    url, head = migration_target()
    if os.environ.get("FLEETOPS_ENV") != "production" or head != "production@head":
        raise RuntimeError("Pilot onboarding requires an approved production migration target")
    engine = create_engine(url)
    try:
        with engine.begin() as connection:
            revision = connection.execute(text("SELECT version_num FROM dbo.alembic_version")).scalar_one()
            if revision not in EXPECTED_REVISIONS:
                raise RuntimeError("Production schema is not at the approved revision")
            connection.execute(text("""
                IF NOT EXISTS (SELECT 1 FROM ref.currencies WHERE code='USD')
                    INSERT INTO ref.currencies (code, name) VALUES ('USD', 'US Dollar')
                IF NOT EXISTS (SELECT 1 FROM iam.permissions WHERE code='fleet.vehicle.read')
                    INSERT INTO iam.permissions (id, code, resource, action)
                    VALUES (:permission, 'fleet.vehicle.read', 'fleet.vehicle', 'read')
            """), {"permission": str(uuid4())})
            tenant = connection.execute(text("""
                SELECT id, name, timezone, status FROM core.tenants WHERE slug=:slug
            """), {"slug": slug}).mappings().first()
            if tenant is None:
                tenant_id = str(uuid4())
                connection.execute(text("""
                    INSERT INTO core.tenants (id, name, slug, timezone, currency_code)
                    VALUES (:id, :name, :slug, :timezone, 'USD')
                """), {"id": tenant_id, "name": name, "slug": slug, "timezone": timezone})
            else:
                if (tenant["name"], tenant["timezone"], tenant["status"]) != (name, timezone, "ACTIVE"):
                    raise RuntimeError("Existing carrier differs from the approved pilot input")
                tenant_id = str(UUID(str(tenant["id"])))
            connection.execute(text("""
                DECLARE @selected UNIQUEIDENTIFIER = CONVERT(UNIQUEIDENTIFIER, :tenant);
                EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@selected
            """), {"tenant": tenant_id})
            user = connection.execute(text("""
                SELECT id, status FROM iam.users
                WHERE auth_provider='clerk' AND external_subject=:subject
            """), {"subject": subject}).mappings().first()
            if user is None:
                user_id = str(uuid4())
                connection.execute(text("""
                    INSERT INTO iam.users (id, auth_provider, external_subject, display_name)
                    VALUES (:id, 'clerk', :subject, :name)
                """), {"id": user_id, "subject": subject, "name": "Pilot reader"})
            else:
                if user["status"] != "ACTIVE":
                    raise RuntimeError("Clerk-linked FleetOps user is not active")
                user_id = str(UUID(str(user["id"])))
            member = connection.execute(text("""
                SELECT id, status FROM iam.memberships WHERE tenant_id=:tenant AND user_id=:user
            """), {"tenant": tenant_id, "user": user_id}).mappings().first()
            if member is None:
                member_id = str(uuid4())
                connection.execute(text("""
                    INSERT INTO iam.memberships (id, tenant_id, user_id)
                    VALUES (:id, :tenant, :user)
                """), {"id": member_id, "tenant": tenant_id, "user": user_id})
            else:
                if member["status"] != "ACTIVE":
                    raise RuntimeError("Pilot membership exists but is not active")
                member_id = str(UUID(str(member["id"])))
            role = connection.execute(text("""
                SELECT id FROM iam.roles WHERE tenant_id=:tenant AND code='PILOT_READER'
            """), {"tenant": tenant_id}).mappings().first()
            if role is None:
                role_id = str(uuid4())
                connection.execute(text("""
                    INSERT INTO iam.roles (id, tenant_id, code, name)
                    VALUES (:id, :tenant, 'PILOT_READER', 'Pilot reader')
                """), {"id": role_id, "tenant": tenant_id})
            else:
                role_id = str(UUID(str(role["id"])))
            permission = connection.execute(text("""
                SELECT id FROM iam.permissions WHERE code='fleet.vehicle.read'
            """)).scalar_one()
            connection.execute(text("""
                IF NOT EXISTS (SELECT 1 FROM iam.role_permissions
                               WHERE tenant_id=:tenant AND role_id=:role AND permission_id=:permission)
                    INSERT INTO iam.role_permissions
                        (id, tenant_id, role_id, permission_id)
                    VALUES (:id, :tenant, :role, :permission)
            """), {"id": str(uuid4()), "tenant": tenant_id,
                   "role": role_id, "permission": str(permission)})
            connection.execute(text("""
                IF NOT EXISTS (SELECT 1 FROM iam.membership_roles
                               WHERE tenant_id=:tenant AND membership_id=:member AND role_id=:role)
                    INSERT INTO iam.membership_roles
                        (id, tenant_id, membership_id, role_id)
                    VALUES (:id, :tenant, :member, :role)
            """), {"id": str(uuid4()), "tenant": tenant_id,
                   "member": member_id, "role": role_id})
        return tenant_id, member_id
    finally:
        engine.dispose()


if __name__ == "__main__":
    tenant_id, membership_id = provision()
    print(f"Pilot reader linked: tenant={tenant_id} membership={membership_id}")
