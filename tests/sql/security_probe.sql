USE [fleetops_test_001];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
IF USER_ID(N'fleetops_runtime_probe') IS NULL CREATE USER [fleetops_runtime_probe] WITHOUT LOGIN;
IF IS_ROLEMEMBER(N'fleetops_runtime',N'fleetops_runtime_probe') <> 1
    ALTER ROLE [fleetops_runtime] ADD MEMBER [fleetops_runtime_probe];
IF USER_ID(N'fleetops_bootstrap_probe') IS NULL CREATE USER [fleetops_bootstrap_probe] WITHOUT LOGIN;
IF IS_ROLEMEMBER(N'fleetops_bootstrap',N'fleetops_bootstrap_probe') <> 1
    ALTER ROLE [fleetops_bootstrap] ADD MEMBER [fleetops_bootstrap_probe];

DECLARE @tenant UNIQUEIDENTIFIER = '11111111-1111-4111-8111-111111111111';
DECLARE @user UNIQUEIDENTIFIER = '22222222-2222-4222-8222-222222222222';
DECLARE @membership UNIQUEIDENTIFIER = '33333333-3333-4333-8333-333333333333';
BEGIN TRANSACTION;
INSERT ref.currencies(code,name) VALUES ('USD',N'US Dollar');
INSERT ref.asset_types(code,name) VALUES ('TRACTOR',N'Tractor');
INSERT core.tenants(id,name,slug,timezone,currency_code)
VALUES (@tenant,N'Probe Carrier','probe-carrier','America/Chicago','USD');
INSERT iam.users(id,auth_provider,external_subject,display_name)
VALUES (@user,'TEST_FIXTURE',N'probe-subject',N'Probe User');
EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@tenant;
INSERT iam.memberships(id,tenant_id,user_id) VALUES (@membership,@tenant,@user);
INSERT iam.roles(id,tenant_id,code,name)
VALUES ('77777777-7777-4777-8777-777777777777',@tenant,'CREATOR',N'Creator');
INSERT iam.permissions(id,code,resource,action)
VALUES ('88888888-8888-4888-8888-888888888888','fleet.vehicle.read','fleet.vehicle','read');
INSERT iam.membership_roles(tenant_id,membership_id,role_id)
VALUES (@tenant,@membership,'77777777-7777-4777-8777-777777777777');
INSERT iam.role_permissions(tenant_id,role_id,permission_id)
VALUES (@tenant,'77777777-7777-4777-8777-777777777777','88888888-8888-4888-8888-888888888888');
INSERT fleet.assets(id,tenant_id,unit_number,asset_type_id,make,model,model_year,ownership_type,currency_code,created_by,updated_by)
VALUES ('44444444-4444-4444-8444-444444444444',@tenant,N'PROBE-1',
        (SELECT id FROM ref.asset_types WHERE code='TRACTOR'),N'Probe',N'Unit',2025,'OWNED','USD',@membership,@membership);
EXEC sys.sp_set_session_context @key=N'tenant_id', @value=NULL;

DECLARE @bootstrap TABLE (user_id UNIQUEIDENTIFIER, membership_id UNIQUEIDENTIFIER,
                          tenant_id UNIQUEIDENTIFIER, permission_code VARCHAR(100));
EXECUTE AS USER = 'fleetops_bootstrap_probe';
INSERT @bootstrap EXEC iam.get_verified_memberships 'TEST_FIXTURE',N'probe-subject',@tenant;
REVERT;
IF (SELECT COUNT(*) FROM @bootstrap WHERE user_id=@user AND membership_id=@membership
      AND tenant_id=@tenant AND permission_code='fleet.vehicle.read') <> 1
    THROW 51004, 'Bounded bootstrap did not return the verified membership capability', 1;

EXECUTE AS USER = 'fleetops_runtime_probe';
DECLARE @count INT;
SELECT @count=COUNT(*) FROM fleet.assets;
IF @count <> 0 THROW 51000, 'RLS exposed a row without tenant context', 1;
IF HAS_PERMS_BY_NAME('integration.idempotency_keys','OBJECT','SELECT') <> 1
    OR HAS_PERMS_BY_NAME('integration.idempotency_keys','OBJECT','INSERT') <> 1
    OR HAS_PERMS_BY_NAME('integration.idempotency_keys','OBJECT','UPDATE') <> 0
    OR HAS_PERMS_BY_NAME('integration.idempotency_keys','OBJECT','DELETE') <> 0
    OR HAS_PERMS_BY_NAME('integration.idempotency_keys','OBJECT','ALTER') <> 0
    THROW 51001, 'Retry ledger runtime grants are incorrect', 1;
EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@tenant;
SELECT @count=COUNT(*) FROM fleet.assets;
IF @count <> 1 THROW 51002, 'Native tenant context did not reveal own row', 1;
INSERT integration.idempotency_keys(tenant_id,operation_scope,request_key,request_hash,response_reference,expires_at,created_by,updated_by)
VALUES (@tenant,'vehicle.register:v1:33333333-3333-4333-8333-333333333333',
        N'55555555-5555-4555-8555-555555555555',0x0000000000000000000000000000000000000000000000000000000000000000,
        N'fleet.vehicles:66666666-6666-4666-8666-666666666666','9999-12-31T23:59:59.999',@membership,@membership);
EXEC sys.sp_set_session_context @key=N'tenant_id', @value=NULL;
SELECT @count=COUNT(*) FROM integration.idempotency_keys;
IF @count <> 0 THROW 51003, 'RLS exposed a retry receipt without context', 1;
REVERT;
ROLLBACK TRANSACTION;
PRINT 'Bootstrap, runtime grants, native tenant RLS, and retry ledger probe passed';
GO
