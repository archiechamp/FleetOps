IF DB_ID(N'fleetops_test_001') IS NULL
    EXEC(N'CREATE DATABASE [fleetops_test_001] COLLATE Latin1_General_100_CI_AS_SC');
GO
SELECT name, collation_name FROM sys.databases WHERE name = N'fleetops_test_001';
GO
