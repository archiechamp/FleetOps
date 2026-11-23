-- From the kit root, using SQLCMD against an empty, disposable user database.
-- Requires the sqlcmd variable ALLOW_SYNTHETIC=YES and privileges to create the test objects.
:ON ERROR EXIT
IF DB_ID() <= 4 OR EXISTS (SELECT 1 FROM sys.tables WHERE is_ms_shipped = 0)
    THROW 50020, 'Select an empty disposable user database', 1;
IF N'$(ALLOW_SYNTHETIC)' <> N'YES' THROW 50021, 'Explicit synthetic-data opt-in required', 1;
GO
:r database/sql/001-foundation-reference.sql
-- A synthetic second country exercises the country-qualified jurisdiction lookup.
BEGIN TRANSACTION;
INSERT ref.countries (code, name) VALUES ('ZZ', N'Synthetic test country');
INSERT ref.jurisdictions (country_id, code, name)
SELECT id, 'AZ', N'Synthetic test jurisdiction' FROM ref.countries WHERE code = 'ZZ';
COMMIT TRANSACTION;
GO
:r database/sql/002-synthetic-seed.sql
:r database/sql/002-synthetic-seed.sql
-- Check the exact reference population after the second application.
-- ZZ and ZZ/AZ are the two additional lookups introduced above.
IF EXISTS (
    SELECT 1 FROM (VALUES
        ((SELECT COUNT(*) FROM ref.currencies), 1),
        ((SELECT COUNT(*) FROM ref.countries), 2),
        ((SELECT COUNT(*) FROM ref.jurisdictions), 2),
        ((SELECT COUNT(*) FROM ref.asset_types), 1),
        ((SELECT COUNT(*) FROM ref.fuel_types), 1),
        ((SELECT COUNT(*) FROM core.tenants), 2),
        ((SELECT COUNT(*) FROM core.tenant_settings), 2),
        ((SELECT COUNT(*) FROM core.terminals), 2),
        ((SELECT COUNT(*) FROM iam.users), 2),
        ((SELECT COUNT(*) FROM iam.memberships), 2),
        ((SELECT COUNT(*) FROM iam.roles), 2),
        ((SELECT COUNT(*) FROM iam.permissions), 2),
        ((SELECT COUNT(*) FROM iam.membership_roles), 2),
        ((SELECT COUNT(*) FROM iam.role_permissions), 3),
        ((SELECT COUNT(*) FROM fleet.assets), 2),
        ((SELECT COUNT(*) FROM fleet.vehicles), 2),
        ((SELECT COUNT(*) FROM audit.audit_events), 0)
    ) AS population(actual, expected_count)
    WHERE actual <> expected_count
) THROW 50022, 'Unexpected foundation population after seed replay', 1;
GO
:r database/sql/004-foundation-smoke.sql
:r database/sql/003-optional-foundation-rls.sql
CREATE USER fleetops_smoke WITHOUT LOGIN;
GRANT SELECT ON OBJECT::fleet.assets TO fleetops_smoke;
GRANT SELECT, INSERT, UPDATE ON OBJECT::core.terminals TO fleetops_smoke;
EXECUTE AS USER = N'fleetops_smoke';
GO
:r database/sql/005-rls-smoke.sql
REVERT;
DROP USER fleetops_smoke;
PRINT 'Foundation verification completed';
GO
