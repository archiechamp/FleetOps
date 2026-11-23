-- Isolated development database, after seed and before RLS.
SET XACT_ABORT OFF;
DECLARE @a UNIQUEIDENTIFIER = '07550486-be04-5574-92e6-057343eb615a';
DECLARE @b UNIQUEIDENTIFIER = 'f4b4a94a-df48-56df-8ccf-18315312182a';
DECLARE @asset_a UNIQUEIDENTIFIER = '4498de1c-dae9-54be-9efa-a2f4b9c7a321';
DECLARE @asset_b UNIQUEIDENTIFIER = 'fbd71305-9474-5885-a751-b15cc80c578f';

IF (SELECT COUNT(*) FROM fleet.assets WHERE unit_number = N'TRK-001' AND tenant_id IN (@a, @b)) <> 2
    THROW 50001, 'Expected one TRK-001 per fixture tenant', 1;
IF (SELECT COUNT(*) FROM fleet.vehicles v
    JOIN ref.jurisdictions j ON j.id = v.plate_jurisdiction_id
    JOIN ref.countries c ON c.id = j.country_id
    WHERE v.tenant_id IN (@a, @b) AND j.code = 'AZ' AND c.code = 'US') <> 2
    THROW 50002, 'Fixture vehicles require the US jurisdiction', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT fleet.vehicles (tenant_id, asset_id) VALUES (@a, @asset_b);
    THROW 50003, 'Expected the tenant and asset foreign key to reject the link', 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 547 OR CHARINDEX('FK_fleet_vehicles_2', ERROR_MESSAGE()) = 0 THROW;
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT fleet.assets (tenant_id, unit_number, asset_type_id, make, model, model_year, ownership_type, currency_code)
    SELECT tenant_id, unit_number, asset_type_id, make, model, model_year, ownership_type, currency_code
    FROM fleet.assets WHERE tenant_id = @a AND id = @asset_a;
    THROW 50004, 'Expected duplicate unit number rejection', 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() NOT IN (2601, 2627) OR CHARINDEX('UQ_fleet_assets_2', ERROR_MESSAGE()) = 0 THROW;
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @original BINARY(8) = (SELECT row_version FROM fleet.assets WHERE tenant_id = @a AND id = @asset_a);
    UPDATE fleet.assets SET notes = N'Fixture first update' WHERE tenant_id = @a AND id = @asset_a AND row_version = @original;
    IF @@ROWCOUNT <> 1 THROW 50005, 'Expected one update at original version', 1;
    UPDATE fleet.assets SET notes = N'Fixture stale update' WHERE tenant_id = @a AND id = @asset_a AND row_version = @original;
    IF @@ROWCOUNT <> 0 THROW 50006, 'Stale version matched', 1;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
PRINT 'Foundation smoke passed';
GO
