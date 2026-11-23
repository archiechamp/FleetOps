-- OPTIONAL reference; run only after explicit Gate 0 review.
-- Runtime principal must not own policy/function or be db_owner. Migration/seed principal separate.
-- The app must authenticate and verify membership before opening a tenant session.
-- No session context = no rows. Do not use read_only=1 on pooled connections.
SET ANSI_NULLS, QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
GO
CREATE FUNCTION iam.fn_tenant_access(@tenant_id UNIQUEIDENTIFIER)
RETURNS TABLE WITH SCHEMABINDING AS RETURN
SELECT 1 AS allowed
WHERE SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'tenant_id'), 'BaseType') = N'uniqueidentifier'
  AND SESSION_CONTEXT(N'tenant_id') = CONVERT(SQL_VARIANT, @tenant_id);
GO
CREATE SECURITY POLICY iam.foundation_tenant_policy
ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON core.tenant_settings,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.tenant_settings AFTER INSERT,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.tenant_settings AFTER UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.tenant_settings BEFORE UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.tenant_settings BEFORE DELETE,
ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON core.terminals,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.terminals AFTER INSERT,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.terminals AFTER UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.terminals BEFORE UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON core.terminals BEFORE DELETE,
ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON iam.memberships,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.memberships AFTER INSERT,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.memberships AFTER UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.memberships BEFORE UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.memberships BEFORE DELETE,
ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON iam.roles,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.roles AFTER INSERT,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.roles AFTER UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.roles BEFORE UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.roles BEFORE DELETE,
ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON iam.membership_roles,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.membership_roles AFTER INSERT,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.membership_roles AFTER UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.membership_roles BEFORE UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.membership_roles BEFORE DELETE,
ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON iam.role_permissions,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.role_permissions AFTER INSERT,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.role_permissions AFTER UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.role_permissions BEFORE UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON iam.role_permissions BEFORE DELETE,
ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.assets,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.assets AFTER INSERT,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.assets AFTER UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.assets BEFORE UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.assets BEFORE DELETE,
ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.vehicles,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.vehicles AFTER INSERT,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.vehicles AFTER UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.vehicles BEFORE UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON fleet.vehicles BEFORE DELETE,
ADD FILTER PREDICATE iam.fn_tenant_access(tenant_id) ON audit.audit_events,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON audit.audit_events AFTER INSERT,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON audit.audit_events AFTER UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON audit.audit_events BEFORE UPDATE,
ADD BLOCK PREDICATE iam.fn_tenant_access(tenant_id) ON audit.audit_events BEFORE DELETE
WITH (STATE=ON);
COMMIT TRANSACTION;
GO
