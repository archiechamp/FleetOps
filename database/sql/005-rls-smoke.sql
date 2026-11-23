-- Run with the limited object grants in verify-foundation.sql, after 003.
SET XACT_ABORT OFF;
DECLARE @a UNIQUEIDENTIFIER = '07550486-be04-5574-92e6-057343eb615a';
DECLARE @b UNIQUEIDENTIFIER = 'f4b4a94a-df48-56df-8ccf-18315312182a';
IF USER_NAME() = N'dbo' OR IS_ROLEMEMBER(N'db_owner') = 1
    THROW 50010, 'Use the limited smoke principal', 1;
EXEC sys.sp_set_session_context @key=N'tenant_id', @value=NULL;
IF EXISTS (SELECT 1 FROM fleet.assets) THROW 50011, 'Unexpected result for empty context', 1;
DECLARE @text_key NVARCHAR(36) = CONVERT(NVARCHAR(36), @a);
EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@text_key;
IF EXISTS (SELECT 1 FROM fleet.assets) THROW 50012, 'Text context must fail closed', 1;

EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@a;
IF (SELECT COUNT(*) FROM fleet.assets WHERE tenant_id = @a AND unit_number = N'TRK-001') <> 1
   OR EXISTS (SELECT 1 FROM fleet.assets WHERE tenant_id <> @a)
    THROW 50013, 'Unexpected assets for tenant A', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT core.terminals (tenant_id, code, name, timezone, status)
    VALUES (@a, 'SMOKE-OWN', N'Synthetic', N'UTC', 'ACTIVE');
    IF @@ROWCOUNT <> 1 THROW 50014, 'Valid tenant write failed', 1;
    UPDATE core.terminals SET name = N'Smoke' WHERE tenant_id = @b AND code = 'YARD-01';
    IF @@ROWCOUNT <> 0 THROW 50015, 'Hidden terminal was updated', 1;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT core.terminals (tenant_id, code, name, timezone, status)
    VALUES (@b, 'SMOKE-FOREIGN', N'Synthetic', N'UTC', 'ACTIVE');
    THROW 50016, 'Expected an RLS block on insert', 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 33504 THROW;
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT core.terminals (tenant_id, code, name, timezone, status)
    VALUES (@a, 'SMOKE-MOVE', N'Synthetic', N'UTC', 'ACTIVE');
    UPDATE core.terminals SET tenant_id = @b WHERE tenant_id = @a AND code = 'SMOKE-MOVE';
    THROW 50017, 'Expected an RLS block on tenant change', 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 33504 THROW;
END CATCH;

EXEC sys.sp_set_session_context @key=N'tenant_id', @value=NULL;
EXEC sys.sp_set_session_context @key=N'tenant_id', @value=@b;
IF (SELECT COUNT(*) FROM fleet.assets WHERE tenant_id = @b AND unit_number = N'TRK-001') <> 1
   OR EXISTS (SELECT 1 FROM fleet.assets WHERE tenant_id <> @b)
    THROW 50018, 'Unexpected assets for tenant B', 1;
EXEC sys.sp_set_session_context @key=N'tenant_id', @value=NULL;
IF EXISTS (SELECT 1 FROM fleet.assets) THROW 50019, 'Rows remained visible after context clearance', 1;
PRINT 'RLS read and write smoke passed';
GO
