USE [fleetops_test_001];
GO
SET NOCOUNT ON;
SELECT version_num FROM dbo.alembic_version;
SELECT COUNT(*) AS foundation_tables FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN ('core', 'ref', 'iam', 'fleet', 'audit');
SELECT COUNT(*) AS foundation_columns FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN ('core', 'ref', 'iam', 'fleet', 'audit');
SELECT COUNT(*) AS foundation_fks FROM sys.foreign_keys f
JOIN sys.tables t ON t.object_id = f.parent_object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN ('core', 'ref', 'iam', 'fleet', 'audit');
SELECT OBJECT_ID(N'integration.idempotency_keys', N'U') AS retry_table_object_id;
SELECT COUNT(*) AS policy_predicates FROM sys.security_predicates;
SELECT COUNT(*) AS domain_tables FROM sys.tables WHERE name <> 'alembic_version';
SELECT COUNT(*) AS domain_columns FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id
WHERE t.name <> 'alembic_version';
SELECT COUNT(*) AS domain_fks FROM sys.foreign_keys;
GO
