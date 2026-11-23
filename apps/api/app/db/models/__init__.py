"""Load the exact Feature 001 table subset."""
from importlib import import_module

MODULES = ('core_tenants', 'core_tenant_settings', 'core_terminals', 'ref_countries', 'ref_jurisdictions', 'ref_currencies', 'ref_asset_types', 'ref_fuel_types', 'iam_users', 'iam_memberships', 'iam_roles', 'iam_permissions', 'iam_membership_roles', 'iam_role_permissions', 'fleet_assets', 'fleet_vehicles', 'integration_idempotency_keys', 'audit_audit_events')
for module in MODULES:
    import_module(f"{__name__}.{module}")
