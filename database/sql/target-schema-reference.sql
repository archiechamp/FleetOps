-- FleetOps v1.1 generated SQL Server reference. Empty database only.
-- Run in explicitly selected dev database; do not use as a production migration.
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
GO
BEGIN TRANSACTION;
IF SCHEMA_ID(N'reporting') IS NULL EXEC(N'CREATE SCHEMA [reporting]');
IF SCHEMA_ID(N'ai') IS NULL EXEC(N'CREATE SCHEMA [ai]');
IF SCHEMA_ID(N'audit') IS NULL EXEC(N'CREATE SCHEMA [audit]');
IF SCHEMA_ID(N'compliance') IS NULL EXEC(N'CREATE SCHEMA [compliance]');
IF SCHEMA_ID(N'core') IS NULL EXEC(N'CREATE SCHEMA [core]');
IF SCHEMA_ID(N'crm') IS NULL EXEC(N'CREATE SCHEMA [crm]');
IF SCHEMA_ID(N'docs') IS NULL EXEC(N'CREATE SCHEMA [docs]');
IF SCHEMA_ID(N'fin') IS NULL EXEC(N'CREATE SCHEMA [fin]');
IF SCHEMA_ID(N'fleet') IS NULL EXEC(N'CREATE SCHEMA [fleet]');
IF SCHEMA_ID(N'fuel') IS NULL EXEC(N'CREATE SCHEMA [fuel]');
IF SCHEMA_ID(N'gps') IS NULL EXEC(N'CREATE SCHEMA [gps]');
IF SCHEMA_ID(N'hr') IS NULL EXEC(N'CREATE SCHEMA [hr]');
IF SCHEMA_ID(N'iam') IS NULL EXEC(N'CREATE SCHEMA [iam]');
IF SCHEMA_ID(N'integration') IS NULL EXEC(N'CREATE SCHEMA [integration]');
IF SCHEMA_ID(N'mnt') IS NULL EXEC(N'CREATE SCHEMA [mnt]');
IF SCHEMA_ID(N'notify') IS NULL EXEC(N'CREATE SCHEMA [notify]');
IF SCHEMA_ID(N'ops') IS NULL EXEC(N'CREATE SCHEMA [ops]');
IF SCHEMA_ID(N'ref') IS NULL EXEC(N'CREATE SCHEMA [ref]');

CREATE TABLE [core].[tenants] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_core_tenants_id] DEFAULT (NEWSEQUENTIALID()),
    [name] NVARCHAR(200) NOT NULL,
    [legal_name] NVARCHAR(200) NULL,
    [slug] VARCHAR(100) NOT NULL,
    [status] VARCHAR(20) NOT NULL CONSTRAINT [DF_core_tenants_status] DEFAULT ('ACTIVE'),
    [dot_number] VARCHAR(20) NULL,
    [mc_number] VARCHAR(20) NULL,
    [timezone] NVARCHAR(64) NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_tenants_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_tenants_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    CONSTRAINT [PK_core_tenants] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_core_tenants_1] UNIQUE ([slug]),
    CONSTRAINT [CK_core_tenants_1] CHECK (status IN ('ACTIVE','SUSPENDED','INACTIVE'))
);

CREATE TABLE [core].[tenant_settings] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_core_tenant_settings_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [setting_key] VARCHAR(100) NOT NULL,
    [setting_value] NVARCHAR(MAX) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_tenant_settings_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_tenant_settings_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_core_tenant_settings] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_core_tenant_settings_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_core_tenant_settings_2] UNIQUE ([tenant_id], [setting_key]),
    CONSTRAINT [CK_core_tenant_settings_1] CHECK (ISJSON(setting_value) = 1)
);

CREATE TABLE [core].[terminals] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_core_terminals_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    [address] NVARCHAR(500) NULL,
    [timezone] NVARCHAR(64) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_terminals_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_terminals_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_core_terminals] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_core_terminals_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_core_terminals_2] UNIQUE ([tenant_id], [code])
);

CREATE TABLE [core].[departments] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_core_departments_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [terminal_id] UNIQUEIDENTIFIER NULL,
    [name] NVARCHAR(150) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_departments_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_departments_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_core_departments] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_core_departments_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_core_departments_2] UNIQUE ([tenant_id], [code])
);

CREATE TABLE [core].[business_entities] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_core_business_entities_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [legal_name] NVARCHAR(200) NOT NULL,
    [registration_number] NVARCHAR(100) NULL,
    [tax_reference] NVARCHAR(100) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_business_entities_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_business_entities_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_core_business_entities] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_core_business_entities_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [core].[number_sequences] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_core_number_sequences_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [entity_type] VARCHAR(50) NOT NULL,
    [prefix] VARCHAR(20) NOT NULL,
    [next_number] BIGINT NOT NULL CONSTRAINT [DF_core_number_sequences_next_number] DEFAULT (1),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_number_sequences_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_core_number_sequences_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_core_number_sequences] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_core_number_sequences_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_core_number_sequences_2] UNIQUE ([tenant_id], [entity_type]),
    CONSTRAINT [CK_core_number_sequences_1] CHECK (next_number > 0)
);

CREATE TABLE [ref].[countries] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] CHAR(2) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_countries_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_countries] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_countries_1] UNIQUE ([code])
);

CREATE TABLE [ref].[jurisdictions] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [country_id] SMALLINT NOT NULL,
    [code] VARCHAR(10) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_jurisdictions_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_jurisdictions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_jurisdictions_1] UNIQUE ([country_id], [code])
);

CREATE TABLE [ref].[currencies] (
    [code] CHAR(3) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_currencies_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_currencies] PRIMARY KEY ([code])
);

CREATE TABLE [ref].[units_of_measure] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(20) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [dimension] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_units_of_measure_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_units_of_measure] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_units_of_measure_1] UNIQUE ([code])
);

CREATE TABLE [ref].[asset_types] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_asset_types_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_asset_types] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_asset_types_1] UNIQUE ([code])
);

CREATE TABLE [ref].[trailer_types] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_trailer_types_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_trailer_types] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_trailer_types_1] UNIQUE ([code])
);

CREATE TABLE [ref].[fuel_types] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_fuel_types_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_fuel_types] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_fuel_types_1] UNIQUE ([code])
);

CREATE TABLE [ref].[expense_categories] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_expense_categories_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_expense_categories] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_expense_categories_1] UNIQUE ([code])
);

CREATE TABLE [ref].[revenue_categories] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_revenue_categories_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_revenue_categories] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_revenue_categories_1] UNIQUE ([code])
);

CREATE TABLE [ref].[maintenance_types] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_maintenance_types_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_maintenance_types] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_maintenance_types_1] UNIQUE ([code])
);

CREATE TABLE [ref].[document_types] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_document_types_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_document_types] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_document_types_1] UNIQUE ([code])
);

CREATE TABLE [ref].[exception_types] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_exception_types_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_exception_types] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_exception_types_1] UNIQUE ([code])
);

CREATE TABLE [ref].[contact_types] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_contact_types_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_contact_types] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_contact_types_1] UNIQUE ([code])
);

CREATE TABLE [iam].[users] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_iam_users_id] DEFAULT (NEWSEQUENTIALID()),
    [auth_provider] VARCHAR(30) NOT NULL,
    [external_subject] NVARCHAR(200) NOT NULL,
    [email] NVARCHAR(254) NULL,
    [display_name] NVARCHAR(150) NOT NULL,
    [status] VARCHAR(20) NOT NULL CONSTRAINT [DF_iam_users_status] DEFAULT ('ACTIVE'),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_users_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_users_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    CONSTRAINT [PK_iam_users] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_iam_users_1] UNIQUE ([auth_provider], [external_subject]),
    CONSTRAINT [CK_iam_users_1] CHECK (status IN ('ACTIVE','DISABLED','INVITED'))
);

CREATE TABLE [iam].[memberships] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_iam_memberships_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [user_id] UNIQUEIDENTIFIER NOT NULL,
    [status] VARCHAR(20) NOT NULL CONSTRAINT [DF_iam_memberships_status] DEFAULT ('ACTIVE'),
    [joined_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_memberships_joined_at] DEFAULT (SYSUTCDATETIME()),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_memberships_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_memberships_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_iam_memberships] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_iam_memberships_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_iam_memberships_2] UNIQUE ([tenant_id], [user_id]),
    CONSTRAINT [CK_iam_memberships_1] CHECK (status IN ('ACTIVE','SUSPENDED','INVITED','REVOKED'))
);

CREATE TABLE [iam].[roles] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_iam_roles_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [code] VARCHAR(50) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(500) NULL,
    [system_role] BIT NOT NULL CONSTRAINT [DF_iam_roles_system_role] DEFAULT (0),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_roles_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_roles_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_iam_roles] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_iam_roles_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_iam_roles_2] UNIQUE ([tenant_id], [code])
);

CREATE TABLE [iam].[permissions] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_iam_permissions_id] DEFAULT (NEWSEQUENTIALID()),
    [code] VARCHAR(100) NOT NULL,
    [resource] VARCHAR(50) NOT NULL,
    [action] VARCHAR(50) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_permissions_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_permissions_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    CONSTRAINT [PK_iam_permissions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_iam_permissions_1] UNIQUE ([code])
);

CREATE TABLE [iam].[membership_roles] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_iam_membership_roles_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [membership_id] UNIQUEIDENTIFIER NOT NULL,
    [role_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_membership_roles_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_membership_roles_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_iam_membership_roles] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_iam_membership_roles_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_iam_membership_roles_2] UNIQUE ([tenant_id], [membership_id], [role_id])
);

CREATE TABLE [iam].[role_permissions] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_iam_role_permissions_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [role_id] UNIQUEIDENTIFIER NOT NULL,
    [permission_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_role_permissions_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_role_permissions_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_iam_role_permissions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_iam_role_permissions_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_iam_role_permissions_2] UNIQUE ([tenant_id], [role_id], [permission_id])
);

CREATE TABLE [iam].[user_preferences] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_iam_user_preferences_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [membership_id] UNIQUEIDENTIFIER NOT NULL,
    [timezone] NVARCHAR(64) NOT NULL,
    [language] VARCHAR(10) NOT NULL,
    [theme] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_user_preferences_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_user_preferences_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_iam_user_preferences] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_iam_user_preferences_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_iam_user_preferences_2] UNIQUE ([tenant_id], [membership_id])
);

CREATE TABLE [iam].[invitations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_iam_invitations_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [email] NVARCHAR(254) NOT NULL,
    [invited_role_id] UNIQUEIDENTIFIER NOT NULL,
    [expires_at] DATETIME2(3) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_invitations_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_invitations_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_iam_invitations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_iam_invitations_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [iam].[terminal_access] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_iam_terminal_access_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [membership_id] UNIQUEIDENTIFIER NOT NULL,
    [terminal_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_terminal_access_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_iam_terminal_access_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_iam_terminal_access] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_iam_terminal_access_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_iam_terminal_access_2] UNIQUE ([tenant_id], [membership_id], [terminal_id])
);

CREATE TABLE [fleet].[assets] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fleet_assets_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [unit_number] NVARCHAR(30) NOT NULL,
    [asset_type_id] SMALLINT NOT NULL,
    [vin] VARCHAR(17) NULL,
    [make] NVARCHAR(80) NOT NULL,
    [model] NVARCHAR(80) NOT NULL,
    [model_year] SMALLINT NOT NULL,
    [ownership_type] VARCHAR(20) NOT NULL,
    [status] VARCHAR(25) NOT NULL CONSTRAINT [DF_fleet_assets_status] DEFAULT ('AVAILABLE'),
    [terminal_id] UNIQUEIDENTIFIER NULL,
    [in_service_date] DATE NULL,
    [acquisition_cost] DECIMAL(19,4) NULL,
    [currency_code] CHAR(3) NOT NULL,
    [notes] NVARCHAR(2000) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_assets_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_assets_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fleet_assets] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fleet_assets_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fleet_assets_2] UNIQUE ([tenant_id], [unit_number]),
    CONSTRAINT [CK_fleet_assets_1] CHECK (status IN ('AVAILABLE','ASSIGNED','IN_TRANSIT','MAINTENANCE','OUT_OF_SERVICE','INACTIVE')),
    CONSTRAINT [CK_fleet_assets_2] CHECK (ownership_type IN ('OWNED','LEASED','CONTRACTED')),
    CONSTRAINT [CK_fleet_assets_3] CHECK (model_year BETWEEN 1900 AND 2100),
    CONSTRAINT [CK_fleet_assets_4] CHECK (vin IS NULL OR LEN(vin)=17)
);

CREATE TABLE [fleet].[vehicles] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fleet_vehicles_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [plate_number] NVARCHAR(30) NULL,
    [plate_jurisdiction_id] SMALLINT NULL,
    [fuel_type_id] SMALLINT NULL,
    [fuel_capacity] DECIMAL(14,3) NULL,
    [gross_vehicle_weight] DECIMAL(14,3) NULL,
    [engine_serial] NVARCHAR(100) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_vehicles_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_vehicles_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fleet_vehicles] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fleet_vehicles_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fleet_vehicles_2] UNIQUE ([tenant_id], [asset_id]),
    CONSTRAINT [CK_fleet_vehicles_1] CHECK (fuel_capacity >= 0),
    CONSTRAINT [CK_fleet_vehicles_2] CHECK (gross_vehicle_weight >= 0)
);

CREATE TABLE [fleet].[trailers] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fleet_trailers_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [trailer_type_id] SMALLINT NOT NULL,
    [length_feet] DECIMAL(14,3) NULL,
    [max_payload] DECIMAL(14,3) NULL,
    [plate_number] NVARCHAR(30) NULL,
    [plate_jurisdiction_id] SMALLINT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_trailers_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_trailers_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fleet_trailers] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fleet_trailers_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fleet_trailers_2] UNIQUE ([tenant_id], [asset_id])
);

CREATE TABLE [fleet].[asset_status_history] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fleet_asset_status_history_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [previous_status] VARCHAR(25) NULL,
    [new_status] VARCHAR(25) NOT NULL,
    [reason] NVARCHAR(500) NULL,
    [changed_at] DATETIME2(3) NOT NULL,
    [actor_id] UNIQUEIDENTIFIER NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_asset_status_history_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_fleet_asset_status_history] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fleet_asset_status_history_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [fleet].[odometer_readings] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fleet_odometer_readings_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [reading] DECIMAL(14,3) NOT NULL,
    [unit_id] SMALLINT NOT NULL,
    [recorded_at] DATETIME2(3) NOT NULL,
    [source] VARCHAR(30) NOT NULL,
    [source_reference] NVARCHAR(150) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_odometer_readings_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_fleet_odometer_readings] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fleet_odometer_readings_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_fleet_odometer_readings_1] CHECK (reading >= 0)
);

CREATE TABLE [fleet].[engine_hour_readings] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fleet_engine_hour_readings_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [engine_hours] DECIMAL(14,3) NOT NULL,
    [recorded_at] DATETIME2(3) NOT NULL,
    [source] VARCHAR(30) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_engine_hour_readings_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_fleet_engine_hour_readings] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fleet_engine_hour_readings_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_fleet_engine_hour_readings_1] CHECK (engine_hours >= 0)
);

CREATE TABLE [fleet].[asset_availability] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fleet_asset_availability_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [start_at] DATETIME2(3) NOT NULL,
    [end_at] DATETIME2(3) NOT NULL,
    [availability_type] VARCHAR(25) NOT NULL,
    [reason] NVARCHAR(500) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_asset_availability_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_asset_availability_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fleet_asset_availability] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fleet_asset_availability_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_fleet_asset_availability_1] CHECK (end_at >= start_at)
);

CREATE TABLE [fleet].[ownership_agreements] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fleet_ownership_agreements_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [ownership_type] VARCHAR(20) NOT NULL,
    [vendor_id] UNIQUEIDENTIFIER NULL,
    [start_date] DATE NOT NULL,
    [end_date] DATE NULL,
    [payment_amount] DECIMAL(19,4) NULL,
    [currency_code] CHAR(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_ownership_agreements_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_ownership_agreements_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fleet_ownership_agreements] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fleet_ownership_agreements_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_fleet_ownership_agreements_1] CHECK (end_date >= start_date)
);

CREATE TABLE [fleet].[asset_meter_adjustments] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fleet_asset_meter_adjustments_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [meter_type] VARCHAR(20) NOT NULL,
    [previous_reading] DECIMAL(14,3) NOT NULL,
    [corrected_reading] DECIMAL(14,3) NOT NULL,
    [reason] NVARCHAR(500) NOT NULL,
    [actor_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fleet_asset_meter_adjustments_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_fleet_asset_meter_adjustments] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fleet_asset_meter_adjustments_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [hr].[drivers] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_hr_drivers_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [membership_id] UNIQUEIDENTIFIER NULL,
    [driver_number] NVARCHAR(30) NOT NULL,
    [first_name] NVARCHAR(100) NOT NULL,
    [last_name] NVARCHAR(100) NOT NULL,
    [phone] NVARCHAR(30) NULL,
    [email] NVARCHAR(254) NULL,
    [employment_type] VARCHAR(25) NOT NULL,
    [terminal_id] UNIQUEIDENTIFIER NULL,
    [status] VARCHAR(20) NOT NULL,
    [hire_date] DATE NULL,
    [timezone] NVARCHAR(64) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_drivers_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_drivers_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_hr_drivers] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_hr_drivers_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_hr_drivers_2] UNIQUE ([tenant_id], [driver_number]),
    CONSTRAINT [CK_hr_drivers_1] CHECK (status IN ('ACTIVE','SUSPENDED','INACTIVE')),
    CONSTRAINT [CK_hr_drivers_2] CHECK (employment_type IN ('COMPANY','CONTRACTOR','OWNER_OPERATOR'))
);

CREATE TABLE [hr].[driver_licenses] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_hr_driver_licenses_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [license_number] NVARCHAR(100) NOT NULL,
    [jurisdiction_id] SMALLINT NOT NULL,
    [class] VARCHAR(10) NOT NULL,
    [issued_date] DATE NULL,
    [expiry_date] DATE NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_licenses_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_licenses_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_hr_driver_licenses] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_hr_driver_licenses_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_hr_driver_licenses_1] CHECK (expiry_date >= issued_date)
);

CREATE TABLE [hr].[driver_endorsements] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_hr_driver_endorsements_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_license_id] UNIQUEIDENTIFIER NOT NULL,
    [endorsement_code] VARCHAR(20) NOT NULL,
    [expiry_date] DATE NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_endorsements_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_endorsements_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_hr_driver_endorsements] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_hr_driver_endorsements_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_hr_driver_endorsements_2] UNIQUE ([tenant_id], [driver_license_id], [endorsement_code])
);

CREATE TABLE [hr].[driver_qualifications] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_hr_driver_qualifications_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [qualification_type] VARCHAR(50) NOT NULL,
    [verified_at] DATETIME2(3) NULL,
    [expires_at] DATETIME2(3) NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_qualifications_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_qualifications_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_hr_driver_qualifications] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_hr_driver_qualifications_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [hr].[driver_availability] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_hr_driver_availability_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [start_at] DATETIME2(3) NOT NULL,
    [end_at] DATETIME2(3) NOT NULL,
    [availability_status] VARCHAR(25) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_availability_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_availability_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_hr_driver_availability] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_hr_driver_availability_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_hr_driver_availability_1] CHECK (end_at >= start_at)
);

CREATE TABLE [hr].[driver_time_off] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_hr_driver_time_off_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [start_date] DATE NOT NULL,
    [end_date] DATE NOT NULL,
    [approval_status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_time_off_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_time_off_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_hr_driver_time_off] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_hr_driver_time_off_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_hr_driver_time_off_1] CHECK (end_date >= start_date)
);

CREATE TABLE [hr].[driver_emergency_contacts] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_hr_driver_emergency_contacts_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    [relationship] NVARCHAR(50) NOT NULL,
    [phone] NVARCHAR(30) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_emergency_contacts_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_emergency_contacts_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_hr_driver_emergency_contacts] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_hr_driver_emergency_contacts_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [hr].[driver_compensation_profiles] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_hr_driver_compensation_profiles_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [compensation_type] VARCHAR(30) NOT NULL,
    [rate] DECIMAL(19,4) NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [effective_from] DATETIME2(3) NOT NULL,
    [effective_to] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_compensation_profiles_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_compensation_profiles_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_hr_driver_compensation_profiles] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_hr_driver_compensation_profiles_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_hr_driver_compensation_profiles_1] CHECK (effective_to >= effective_from)
);

CREATE TABLE [hr].[driver_status_history] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_hr_driver_status_history_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [previous_status] VARCHAR(20) NULL,
    [new_status] VARCHAR(20) NOT NULL,
    [changed_at] DATETIME2(3) NOT NULL,
    [actor_id] UNIQUEIDENTIFIER NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_hr_driver_status_history_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_hr_driver_status_history] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_hr_driver_status_history_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [crm].[customers] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_crm_customers_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [customer_code] NVARCHAR(30) NOT NULL,
    [legal_name] NVARCHAR(200) NOT NULL,
    [display_name] NVARCHAR(200) NOT NULL,
    [customer_type] VARCHAR(30) NOT NULL,
    [payment_terms_days] SMALLINT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_customers_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_customers_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_crm_customers] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_crm_customers_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_crm_customers_2] UNIQUE ([tenant_id], [customer_code]),
    CONSTRAINT [CK_crm_customers_1] CHECK (payment_terms_days >= 0)
);

CREATE TABLE [crm].[customer_contacts] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_crm_customer_contacts_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [customer_id] UNIQUEIDENTIFIER NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    [email] NVARCHAR(254) NULL,
    [phone] NVARCHAR(30) NULL,
    [contact_type_id] SMALLINT NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_customer_contacts_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_customer_contacts_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_crm_customer_contacts] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_crm_customer_contacts_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [crm].[locations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_crm_locations_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [customer_id] UNIQUEIDENTIFIER NULL,
    [location_name] NVARCHAR(150) NOT NULL,
    [address] NVARCHAR(500) NOT NULL,
    [latitude] DECIMAL(9,6) NULL,
    [longitude] DECIMAL(9,6) NULL,
    [timezone] NVARCHAR(64) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_locations_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_locations_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_crm_locations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_crm_locations_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_crm_locations_1] CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT [CK_crm_locations_2] CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT [CK_crm_locations_3] CHECK ((latitude IS NULL AND longitude IS NULL) OR (latitude IS NOT NULL AND longitude IS NOT NULL))
);

CREATE TABLE [crm].[customer_contracts] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_crm_customer_contracts_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [customer_id] UNIQUEIDENTIFIER NOT NULL,
    [start_date] DATE NOT NULL,
    [end_date] DATE NULL,
    [terms] NVARCHAR(MAX) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_customer_contracts_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_customer_contracts_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_crm_customer_contracts] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_crm_customer_contracts_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_crm_customer_contracts_1] CHECK (end_date >= start_date)
);

CREATE TABLE [crm].[customer_rate_agreements] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_crm_customer_rate_agreements_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [contract_id] UNIQUEIDENTIFIER NOT NULL,
    [equipment_type_id] SMALLINT NOT NULL,
    [rate_type] VARCHAR(30) NOT NULL,
    [amount] DECIMAL(19,4) NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_customer_rate_agreements_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_customer_rate_agreements_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_crm_customer_rate_agreements] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_crm_customer_rate_agreements_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [crm].[customer_notes] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_crm_customer_notes_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [customer_id] UNIQUEIDENTIFIER NOT NULL,
    [note] NVARCHAR(2000) NOT NULL,
    [author_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_customer_notes_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_crm_customer_notes_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_crm_customer_notes] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_crm_customer_notes_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [ops].[loads] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_loads_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [load_number] NVARCHAR(40) NOT NULL,
    [customer_id] UNIQUEIDENTIFIER NOT NULL,
    [customer_reference] NVARCHAR(100) NULL,
    [commodity] NVARCHAR(255) NULL,
    [weight_lbs] DECIMAL(14,3) NULL,
    [equipment_type_id] SMALLINT NULL,
    [commercial_status] VARCHAR(25) NOT NULL CONSTRAINT [DF_ops_loads_commercial_status] DEFAULT ('DRAFT'),
    [special_instructions] NVARCHAR(MAX) NULL,
    [currency_code] CHAR(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_loads_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_loads_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_loads] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_loads_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ops_loads_2] UNIQUE ([tenant_id], [load_number]),
    CONSTRAINT [CK_ops_loads_1] CHECK (weight_lbs >= 0),
    CONSTRAINT [CK_ops_loads_2] CHECK (commercial_status IN ('DRAFT','BOOKED','CANCELLED','FULFILLED'))
);

CREATE TABLE [ops].[load_stops] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_load_stops_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [load_id] UNIQUEIDENTIFIER NOT NULL,
    [sequence_number] INT NOT NULL,
    [stop_type] VARCHAR(20) NOT NULL,
    [location_id] UNIQUEIDENTIFIER NOT NULL,
    [address_snapshot] NVARCHAR(500) NOT NULL,
    [timezone] NVARCHAR(64) NOT NULL,
    [appointment_start] DATETIME2(3) NULL,
    [appointment_end] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_load_stops_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_load_stops_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_load_stops] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_load_stops_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ops_load_stops_2] UNIQUE ([tenant_id], [load_id], [sequence_number]),
    CONSTRAINT [CK_ops_load_stops_1] CHECK (sequence_number > 0),
    CONSTRAINT [CK_ops_load_stops_2] CHECK (appointment_end >= appointment_start),
    CONSTRAINT [CK_ops_load_stops_3] CHECK (stop_type IN ('PICKUP','DELIVERY','INTERMEDIATE'))
);

CREATE TABLE [ops].[load_status_history] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_load_status_history_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [load_id] UNIQUEIDENTIFIER NOT NULL,
    [previous_status] VARCHAR(25) NULL,
    [new_status] VARCHAR(25) NOT NULL,
    [changed_at] DATETIME2(3) NOT NULL,
    [actor_id] UNIQUEIDENTIFIER NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_load_status_history_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ops_load_status_history] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_load_status_history_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [ops].[trips] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_trips_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_number] NVARCHAR(40) NOT NULL,
    [status] VARCHAR(25) NOT NULL CONSTRAINT [DF_ops_trips_status] DEFAULT ('DRAFT'),
    [planned_start_at] DATETIME2(3) NULL,
    [planned_end_at] DATETIME2(3) NULL,
    [actual_start_at] DATETIME2(3) NULL,
    [actual_end_at] DATETIME2(3) NULL,
    [dispatcher_id] UNIQUEIDENTIFIER NULL,
    [closed_at] DATETIME2(3) NULL,
    [cancellation_reason] NVARCHAR(500) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trips_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trips_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_trips] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_trips_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ops_trips_2] UNIQUE ([tenant_id], [trip_number]),
    CONSTRAINT [CK_ops_trips_1] CHECK (actual_end_at >= actual_start_at),
    CONSTRAINT [CK_ops_trips_2] CHECK (planned_end_at >= planned_start_at),
    CONSTRAINT [CK_ops_trips_3] CHECK (status IN ('DRAFT','PLANNED','ASSIGNED','EN_ROUTE_TO_PICKUP','AT_PICKUP','IN_TRANSIT','DELIVERED','CLOSED','CANCELLED'))
);

CREATE TABLE [ops].[trip_loads] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_trip_loads_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [load_id] UNIQUEIDENTIFIER NOT NULL,
    [sequence_number] INT NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_loads_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_loads_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_trip_loads] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_trip_loads_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ops_trip_loads_2] UNIQUE ([tenant_id], [trip_id], [load_id]),
    CONSTRAINT [UQ_ops_trip_loads_3] UNIQUE ([tenant_id], [trip_id], [sequence_number]),
    CONSTRAINT [CK_ops_trip_loads_1] CHECK (sequence_number > 0)
);

CREATE TABLE [ops].[trip_stops] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_trip_stops_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [load_stop_id] UNIQUEIDENTIFIER NOT NULL,
    [sequence_number] INT NOT NULL,
    [arrival_at] DATETIME2(3) NULL,
    [departure_at] DATETIME2(3) NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_stops_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_stops_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_trip_stops] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_trip_stops_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ops_trip_stops_2] UNIQUE ([tenant_id], [trip_id], [sequence_number]),
    CONSTRAINT [CK_ops_trip_stops_1] CHECK (sequence_number > 0),
    CONSTRAINT [CK_ops_trip_stops_2] CHECK (departure_at >= arrival_at)
);

CREATE TABLE [ops].[trip_assignments] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_trip_assignments_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [vehicle_id] UNIQUEIDENTIFIER NOT NULL,
    [trailer_id] UNIQUEIDENTIFIER NULL,
    [assigned_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_assignments_assigned_at] DEFAULT (SYSUTCDATETIME()),
    [effective_from] DATETIME2(3) NOT NULL,
    [effective_to] DATETIME2(3) NULL,
    [assigned_by] UNIQUEIDENTIFIER NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [release_reason] NVARCHAR(500) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_assignments_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_assignments_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_trip_assignments] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_trip_assignments_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_ops_trip_assignments_1] CHECK (effective_to >= effective_from),
    CONSTRAINT [CK_ops_trip_assignments_2] CHECK (status IN ('ACTIVE','RELEASED','CANCELLED'))
);

CREATE TABLE [ops].[equipment_reservations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_equipment_reservations_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [assignment_id] UNIQUEIDENTIFIER NULL,
    [start_at] DATETIME2(3) NOT NULL,
    [end_at] DATETIME2(3) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_equipment_reservations_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_equipment_reservations_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_equipment_reservations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_equipment_reservations_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_ops_equipment_reservations_1] CHECK (end_at > start_at),
    CONSTRAINT [CK_ops_equipment_reservations_2] CHECK (status IN ('HELD','CONFIRMED','RELEASED','CANCELLED'))
);

CREATE TABLE [ops].[driver_reservations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_driver_reservations_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [assignment_id] UNIQUEIDENTIFIER NULL,
    [start_at] DATETIME2(3) NOT NULL,
    [end_at] DATETIME2(3) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_driver_reservations_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_driver_reservations_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_driver_reservations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_driver_reservations_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_ops_driver_reservations_1] CHECK (end_at > start_at),
    CONSTRAINT [CK_ops_driver_reservations_2] CHECK (status IN ('HELD','CONFIRMED','RELEASED','CANCELLED'))
);

CREATE TABLE [ops].[trip_events] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_trip_events_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [event_type] VARCHAR(40) NOT NULL,
    [occurred_at] DATETIME2(3) NOT NULL,
    [received_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_events_received_at] DEFAULT (SYSUTCDATETIME()),
    [source] VARCHAR(30) NOT NULL,
    [event_reference] NVARCHAR(150) NOT NULL,
    [payload] NVARCHAR(MAX) NULL,
    [actor_id] UNIQUEIDENTIFIER NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_events_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ops_trip_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_trip_events_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ops_trip_events_2] UNIQUE ([tenant_id], [trip_id], [source], [event_reference]),
    CONSTRAINT [CK_ops_trip_events_1] CHECK (ISJSON(payload) = 1)
);

CREATE TABLE [ops].[trip_exceptions] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_trip_exceptions_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [exception_type_id] SMALLINT NOT NULL,
    [severity] VARCHAR(15) NOT NULL,
    [description] NVARCHAR(2000) NOT NULL,
    [owner_id] UNIQUEIDENTIFIER NULL,
    [status] VARCHAR(20) NOT NULL,
    [resolved_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_exceptions_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_exceptions_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_trip_exceptions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_trip_exceptions_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [ops].[trip_distances] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_trip_distances_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [loaded_miles] DECIMAL(14,3) NULL,
    [empty_miles] DECIMAL(14,3) NULL,
    [source] VARCHAR(30) NOT NULL,
    [measurement_status] VARCHAR(20) NOT NULL,
    [measured_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_distances_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_distances_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_trip_distances] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_trip_distances_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ops_trip_distances_2] UNIQUE ([tenant_id], [trip_id]),
    CONSTRAINT [CK_ops_trip_distances_1] CHECK (loaded_miles >= 0),
    CONSTRAINT [CK_ops_trip_distances_2] CHECK (empty_miles >= 0)
);

CREATE TABLE [ops].[trip_status_history] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_trip_status_history_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [previous_status] VARCHAR(25) NULL,
    [new_status] VARCHAR(25) NOT NULL,
    [changed_at] DATETIME2(3) NOT NULL,
    [actor_id] UNIQUEIDENTIFIER NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_status_history_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ops_trip_status_history] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_trip_status_history_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [ops].[delivery_confirmations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_delivery_confirmations_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_stop_id] UNIQUEIDENTIFIER NOT NULL,
    [receiver_name] NVARCHAR(150) NULL,
    [delivered_at] DATETIME2(3) NOT NULL,
    [verification_status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_delivery_confirmations_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_delivery_confirmations_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ops_delivery_confirmations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_delivery_confirmations_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ops_delivery_confirmations_2] UNIQUE ([tenant_id], [trip_stop_id])
);

CREATE TABLE [ops].[trip_exception_events] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ops_trip_exception_events_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [exception_id] UNIQUEIDENTIFIER NOT NULL,
    [event_type] VARCHAR(30) NOT NULL,
    [note] NVARCHAR(1000) NULL,
    [occurred_at] DATETIME2(3) NOT NULL,
    [actor_id] UNIQUEIDENTIFIER NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ops_trip_exception_events_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ops_trip_exception_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ops_trip_exception_events_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [integration].[providers] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_providers_id] DEFAULT (NEWSEQUENTIALID()),
    [provider_code] VARCHAR(50) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [integration_type] VARCHAR(30) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_providers_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_providers_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    CONSTRAINT [PK_integration_providers] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_providers_1] UNIQUE ([provider_code])
);

CREATE TABLE [integration].[connections] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_connections_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [provider_id] UNIQUEIDENTIFIER NOT NULL,
    [secret_reference] NVARCHAR(250) NOT NULL,
    [connection_status] VARCHAR(20) NOT NULL,
    [external_account_id] NVARCHAR(150) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_connections_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_connections_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_integration_connections] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_connections_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [integration].[external_mappings] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_external_mappings_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [connection_id] UNIQUEIDENTIFIER NOT NULL,
    [entity_type] VARCHAR(50) NOT NULL,
    [internal_id] UNIQUEIDENTIFIER NOT NULL,
    [external_id] NVARCHAR(150) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_external_mappings_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_external_mappings_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_integration_external_mappings] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_external_mappings_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_integration_external_mappings_2] UNIQUE ([tenant_id], [connection_id], [entity_type], [external_id]),
    CONSTRAINT [UQ_integration_external_mappings_3] UNIQUE ([tenant_id], [connection_id], [entity_type], [internal_id])
);

CREATE TABLE [integration].[sync_jobs] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_sync_jobs_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [connection_id] UNIQUEIDENTIFIER NOT NULL,
    [job_type] VARCHAR(30) NOT NULL,
    [started_at] DATETIME2(3) NULL,
    [completed_at] DATETIME2(3) NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_sync_jobs_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_sync_jobs_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_integration_sync_jobs] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_sync_jobs_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [integration].[sync_checkpoints] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_sync_checkpoints_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [connection_id] UNIQUEIDENTIFIER NOT NULL,
    [resource_type] VARCHAR(50) NOT NULL,
    [cursor_value] NVARCHAR(2000) NULL,
    [last_sync_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_sync_checkpoints_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_sync_checkpoints_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_integration_sync_checkpoints] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_sync_checkpoints_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_integration_sync_checkpoints_2] UNIQUE ([tenant_id], [connection_id], [resource_type])
);

CREATE TABLE [integration].[webhook_events] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_webhook_events_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [connection_id] UNIQUEIDENTIFIER NOT NULL,
    [external_event_id] NVARCHAR(150) NOT NULL,
    [event_type] VARCHAR(50) NOT NULL,
    [received_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_webhook_events_received_at] DEFAULT (SYSUTCDATETIME()),
    [status] VARCHAR(20) NOT NULL,
    [payload] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_webhook_events_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_webhook_events_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_integration_webhook_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_webhook_events_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_integration_webhook_events_2] UNIQUE ([tenant_id], [connection_id], [external_event_id]),
    CONSTRAINT [CK_integration_webhook_events_1] CHECK (ISJSON(payload) = 1)
);

CREATE TABLE [integration].[processing_failures] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_processing_failures_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [sync_job_id] UNIQUEIDENTIFIER NOT NULL,
    [error_code] VARCHAR(50) NOT NULL,
    [error_message] NVARCHAR(1000) NOT NULL,
    [retry_count] INT NOT NULL CONSTRAINT [DF_integration_processing_failures_retry_count] DEFAULT (0),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_processing_failures_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_processing_failures_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_integration_processing_failures] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_processing_failures_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_integration_processing_failures_1] CHECK (retry_count >= 0)
);

CREATE TABLE [integration].[import_batches] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_import_batches_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [import_type] VARCHAR(30) NOT NULL,
    [filename] NVARCHAR(255) NOT NULL,
    [imported_by] UNIQUEIDENTIFIER NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_import_batches_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_import_batches_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_integration_import_batches] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_import_batches_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [integration].[import_errors] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_import_errors_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [batch_id] UNIQUEIDENTIFIER NOT NULL,
    [row_number] INT NOT NULL,
    [error_code] VARCHAR(50) NOT NULL,
    [error_description] NVARCHAR(1000) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_import_errors_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_integration_import_errors] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_import_errors_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_integration_import_errors_1] CHECK (row_number > 0)
);

CREATE TABLE [integration].[outbox_events] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_outbox_events_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [event_type] VARCHAR(50) NOT NULL,
    [aggregate_id] UNIQUEIDENTIFIER NOT NULL,
    [payload] NVARCHAR(MAX) NOT NULL,
    [publication_status] VARCHAR(20) NOT NULL,
    [published_at] DATETIME2(3) NULL,
    [attempt_count] INT NOT NULL CONSTRAINT [DF_integration_outbox_events_attempt_count] DEFAULT (0),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_outbox_events_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_outbox_events_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_integration_outbox_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_outbox_events_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_integration_outbox_events_1] CHECK (ISJSON(payload) = 1),
    CONSTRAINT [CK_integration_outbox_events_2] CHECK (attempt_count >= 0)
);

CREATE TABLE [integration].[idempotency_keys] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_integration_idempotency_keys_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [operation_scope] VARCHAR(80) NOT NULL,
    [request_key] NVARCHAR(150) NOT NULL,
    [request_hash] BINARY(32) NOT NULL,
    [response_reference] NVARCHAR(150) NULL,
    [expires_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_idempotency_keys_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_integration_idempotency_keys_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_integration_idempotency_keys] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_integration_idempotency_keys_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_integration_idempotency_keys_2] UNIQUE ([tenant_id], [operation_scope], [request_key])
);

CREATE TABLE [gps].[devices] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_gps_devices_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [connection_id] UNIQUEIDENTIFIER NOT NULL,
    [external_device_id] NVARCHAR(150) NOT NULL,
    [serial_number] NVARCHAR(100) NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_devices_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_devices_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_gps_devices] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_gps_devices_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_gps_devices_2] UNIQUE ([tenant_id], [connection_id], [external_device_id])
);

CREATE TABLE [gps].[device_assignments] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_gps_device_assignments_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [device_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [effective_from] DATETIME2(3) NOT NULL,
    [effective_to] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_device_assignments_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_device_assignments_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_gps_device_assignments] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_gps_device_assignments_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_gps_device_assignments_1] CHECK (effective_to >= effective_from)
);

CREATE TABLE [gps].[vehicle_positions] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [device_id] UNIQUEIDENTIFIER NOT NULL,
    [latitude] DECIMAL(9,6) NOT NULL,
    [longitude] DECIMAL(9,6) NOT NULL,
    [speed_mph] DECIMAL(14,3) NULL,
    [heading_degrees] DECIMAL(5,2) NULL,
    [ignition_on] BIT NULL,
    [odometer_miles] DECIMAL(14,3) NULL,
    [recorded_at] DATETIME2(3) NOT NULL,
    [received_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_vehicle_positions_received_at] DEFAULT (SYSUTCDATETIME()),
    [provider_event_id] NVARCHAR(150) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_vehicle_positions_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_gps_vehicle_positions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_gps_vehicle_positions_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_gps_vehicle_positions_2] UNIQUE ([tenant_id], [device_id], [provider_event_id]),
    CONSTRAINT [UQ_gps_vehicle_positions_3] UNIQUE ([tenant_id], [asset_id], [id]),
    CONSTRAINT [CK_gps_vehicle_positions_1] CHECK (speed_mph >= 0),
    CONSTRAINT [CK_gps_vehicle_positions_2] CHECK (odometer_miles >= 0),
    CONSTRAINT [CK_gps_vehicle_positions_3] CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT [CK_gps_vehicle_positions_4] CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT [CK_gps_vehicle_positions_5] CHECK (heading_degrees >= 0 AND heading_degrees < 360)
);

CREATE TABLE [gps].[latest_vehicle_positions] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_gps_latest_vehicle_positions_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [position_id] BIGINT NOT NULL,
    [recorded_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_latest_vehicle_positions_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_latest_vehicle_positions_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_gps_latest_vehicle_positions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_gps_latest_vehicle_positions_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_gps_latest_vehicle_positions_2] UNIQUE ([tenant_id], [asset_id])
);

CREATE TABLE [gps].[telemetry_events] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [event_type] VARCHAR(50) NOT NULL,
    [event_value] NVARCHAR(MAX) NOT NULL,
    [recorded_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_telemetry_events_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_gps_telemetry_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_gps_telemetry_events_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_gps_telemetry_events_1] CHECK (ISJSON(event_value) = 1)
);

CREATE TABLE [gps].[geofences] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_gps_geofences_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    [boundary] GEOGRAPHY NOT NULL,
    [geofence_type] VARCHAR(30) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_geofences_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_geofences_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_gps_geofences] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_gps_geofences_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [gps].[geofence_events] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [geofence_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [event_type] VARCHAR(30) NOT NULL,
    [occurred_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_geofence_events_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_gps_geofence_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_gps_geofence_events_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [gps].[vehicle_fault_codes] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_gps_vehicle_fault_codes_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [fault_code] VARCHAR(50) NOT NULL,
    [severity] VARCHAR(20) NOT NULL,
    [detected_at] DATETIME2(3) NOT NULL,
    [resolved_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_vehicle_fault_codes_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_vehicle_fault_codes_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_gps_vehicle_fault_codes] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_gps_vehicle_fault_codes_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [gps].[idle_sessions] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_gps_idle_sessions_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [started_at] DATETIME2(3) NOT NULL,
    [ended_at] DATETIME2(3) NOT NULL,
    [duration_seconds] INT NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_gps_idle_sessions_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_gps_idle_sessions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_gps_idle_sessions_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_gps_idle_sessions_1] CHECK (duration_seconds >= 0),
    CONSTRAINT [CK_gps_idle_sessions_2] CHECK (ended_at >= started_at)
);

CREATE TABLE [mnt].[service_types] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_service_types_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [service_code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(500) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_service_types_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_service_types_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_service_types] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_service_types_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_mnt_service_types_2] UNIQUE ([tenant_id], [service_code])
);

CREATE TABLE [mnt].[maintenance_schedules] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_maintenance_schedules_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [service_type_id] UNIQUEIDENTIFIER NOT NULL,
    [interval_days] INT NULL,
    [interval_miles] DECIMAL(14,3) NULL,
    [interval_hours] DECIMAL(14,3) NULL,
    [enabled] BIT NOT NULL CONSTRAINT [DF_mnt_maintenance_schedules_enabled] DEFAULT (1),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_maintenance_schedules_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_maintenance_schedules_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_maintenance_schedules] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_maintenance_schedules_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_mnt_maintenance_schedules_1] CHECK (interval_days > 0),
    CONSTRAINT [CK_mnt_maintenance_schedules_2] CHECK (interval_miles > 0),
    CONSTRAINT [CK_mnt_maintenance_schedules_3] CHECK (interval_hours > 0),
    CONSTRAINT [CK_mnt_maintenance_schedules_4] CHECK (interval_days IS NOT NULL OR interval_miles IS NOT NULL OR interval_hours IS NOT NULL)
);

CREATE TABLE [mnt].[scheduled_services] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_scheduled_services_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [schedule_id] UNIQUEIDENTIFIER NOT NULL,
    [due_date] DATE NULL,
    [due_odometer] DECIMAL(14,3) NULL,
    [due_engine_hours] DECIMAL(14,3) NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_scheduled_services_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_scheduled_services_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_scheduled_services] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_scheduled_services_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_mnt_scheduled_services_1] CHECK (due_date IS NOT NULL OR due_odometer IS NOT NULL OR due_engine_hours IS NOT NULL)
);

CREATE TABLE [mnt].[service_records] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_service_records_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [service_type_id] UNIQUEIDENTIFIER NOT NULL,
    [vendor_id] UNIQUEIDENTIFIER NULL,
    [service_date] DATE NOT NULL,
    [odometer] DECIMAL(14,3) NULL,
    [description] NVARCHAR(2000) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_service_records_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_service_records_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_service_records] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_service_records_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [mnt].[maintenance_restrictions] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_maintenance_restrictions_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [reason] NVARCHAR(500) NOT NULL,
    [imposed_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_maintenance_restrictions_imposed_at] DEFAULT (SYSUTCDATETIME()),
    [released_at] DATETIME2(3) NULL,
    [release_approved_by] UNIQUEIDENTIFIER NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_maintenance_restrictions_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_maintenance_restrictions_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_maintenance_restrictions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_maintenance_restrictions_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_mnt_maintenance_restrictions_1] CHECK (released_at >= imposed_at),
    CONSTRAINT [CK_mnt_maintenance_restrictions_2] CHECK (released_at IS NULL OR release_approved_by IS NOT NULL)
);

CREATE TABLE [mnt].[vendors] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_vendors_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [vendor_code] NVARCHAR(30) NOT NULL,
    [name] NVARCHAR(200) NOT NULL,
    [email] NVARCHAR(254) NULL,
    [phone] NVARCHAR(30) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_vendors_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_vendors_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_vendors] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_vendors_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_mnt_vendors_2] UNIQUE ([tenant_id], [vendor_code])
);

CREATE TABLE [mnt].[work_orders] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_work_orders_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [work_order_number] NVARCHAR(40) NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [vendor_id] UNIQUEIDENTIFIER NULL,
    [maintenance_type_id] SMALLINT NOT NULL,
    [title] NVARCHAR(200) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [priority] VARCHAR(15) NOT NULL,
    [status] VARCHAR(25) NOT NULL,
    [odometer_miles] DECIMAL(14,3) NULL,
    [opened_at] DATETIME2(3) NOT NULL,
    [scheduled_at] DATETIME2(3) NULL,
    [completed_at] DATETIME2(3) NULL,
    [approved_by] UNIQUEIDENTIFIER NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_work_orders_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_work_orders_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_work_orders] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_work_orders_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_mnt_work_orders_2] UNIQUE ([tenant_id], [work_order_number]),
    CONSTRAINT [CK_mnt_work_orders_1] CHECK (odometer_miles >= 0)
);

CREATE TABLE [mnt].[work_order_items] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_work_order_items_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [work_order_id] UNIQUEIDENTIFIER NOT NULL,
    [description] NVARCHAR(500) NOT NULL,
    [labor_hours] DECIMAL(14,3) NULL,
    [quantity] DECIMAL(14,3) NOT NULL,
    [unit_cost] DECIMAL(19,4) NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_work_order_items_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_work_order_items_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_work_order_items] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_work_order_items_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [mnt].[defects] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_defects_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [inspection_id] UNIQUEIDENTIFIER NULL,
    [description] NVARCHAR(2000) NOT NULL,
    [severity] VARCHAR(20) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_defects_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_defects_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_defects] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_defects_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [mnt].[parts] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_parts_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [part_number] NVARCHAR(50) NOT NULL,
    [description] NVARCHAR(500) NOT NULL,
    [unit_cost] DECIMAL(19,4) NULL,
    [currency_code] CHAR(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_parts_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_parts_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_parts] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_parts_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_mnt_parts_2] UNIQUE ([tenant_id], [part_number])
);

CREATE TABLE [mnt].[parts_inventory] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_parts_inventory_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [part_id] UNIQUEIDENTIFIER NOT NULL,
    [terminal_id] UNIQUEIDENTIFIER NOT NULL,
    [quantity_on_hand] DECIMAL(14,3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_parts_inventory_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_parts_inventory_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_parts_inventory] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_parts_inventory_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_mnt_parts_inventory_2] UNIQUE ([tenant_id], [part_id], [terminal_id]),
    CONSTRAINT [CK_mnt_parts_inventory_1] CHECK (quantity_on_hand >= 0)
);

CREATE TABLE [mnt].[tire_records] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_tire_records_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [tire_position] VARCHAR(30) NOT NULL,
    [serial_number] NVARCHAR(100) NOT NULL,
    [installed_at] DATETIME2(3) NOT NULL,
    [removed_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_tire_records_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_tire_records_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_tire_records] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_tire_records_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_mnt_tire_records_1] CHECK (removed_at >= installed_at)
);

CREATE TABLE [mnt].[downtime_events] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_mnt_downtime_events_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [started_at] DATETIME2(3) NOT NULL,
    [ended_at] DATETIME2(3) NULL,
    [reason] NVARCHAR(500) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_downtime_events_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_mnt_downtime_events_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_mnt_downtime_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_mnt_downtime_events_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_mnt_downtime_events_1] CHECK (ended_at >= started_at)
);

CREATE TABLE [fuel].[fuel_transactions] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fuel_fuel_transactions_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NULL,
    [driver_id] UNIQUEIDENTIFIER NULL,
    [fuel_type_id] SMALLINT NOT NULL,
    [transaction_at] DATETIME2(3) NOT NULL,
    [quantity_gallons] DECIMAL(14,3) NOT NULL,
    [price_per_gallon] DECIMAL(19,4) NOT NULL,
    [total_amount] DECIMAL(19,4) NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [odometer_miles] DECIMAL(14,3) NULL,
    [jurisdiction_id] SMALLINT NULL,
    [merchant_name] NVARCHAR(200) NULL,
    [connection_id] UNIQUEIDENTIFIER NULL,
    [external_transaction_id] NVARCHAR(150) NULL,
    [source_system] VARCHAR(50) NOT NULL,
    [reconciliation_status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_transactions_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_transactions_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fuel_fuel_transactions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fuel_fuel_transactions_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_fuel_fuel_transactions_1] CHECK (quantity_gallons >= 0),
    CONSTRAINT [CK_fuel_fuel_transactions_2] CHECK (odometer_miles >= 0)
);

CREATE TABLE [fuel].[fuel_transaction_matches] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fuel_fuel_transaction_matches_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [fuel_transaction_id] UNIQUEIDENTIFIER NOT NULL,
    [expense_id] UNIQUEIDENTIFIER NOT NULL,
    [match_status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_transaction_matches_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_transaction_matches_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fuel_fuel_transaction_matches] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fuel_fuel_transaction_matches_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fuel_fuel_transaction_matches_2] UNIQUE ([tenant_id], [fuel_transaction_id], [expense_id])
);

CREATE TABLE [fuel].[fuel_cards] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fuel_fuel_cards_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [connection_id] UNIQUEIDENTIFIER NOT NULL,
    [masked_card_number] VARCHAR(20) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_cards_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_cards_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fuel_fuel_cards] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fuel_fuel_cards_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [fuel].[fuel_card_assignments] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fuel_fuel_card_assignments_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [fuel_card_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NULL,
    [driver_id] UNIQUEIDENTIFIER NULL,
    [effective_from] DATETIME2(3) NOT NULL,
    [effective_to] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_card_assignments_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_card_assignments_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fuel_fuel_card_assignments] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fuel_fuel_card_assignments_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_fuel_fuel_card_assignments_1] CHECK (effective_to >= effective_from)
);

CREATE TABLE [fuel].[fuel_import_batches] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fuel_fuel_import_batches_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [connection_id] UNIQUEIDENTIFIER NOT NULL,
    [external_batch_id] NVARCHAR(150) NOT NULL,
    [imported_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_import_batches_imported_at] DEFAULT (SYSUTCDATETIME()),
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_import_batches_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_import_batches_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fuel_fuel_import_batches] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fuel_fuel_import_batches_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fuel_fuel_import_batches_2] UNIQUE ([tenant_id], [connection_id], [external_batch_id])
);

CREATE TABLE [fuel].[fuel_efficiency_records] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fuel_fuel_efficiency_records_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [period_start] DATE NOT NULL,
    [period_end] DATE NOT NULL,
    [miles] DECIMAL(14,3) NOT NULL,
    [gallons] DECIMAL(14,3) NOT NULL,
    [source] VARCHAR(30) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_efficiency_records_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_efficiency_records_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fuel_fuel_efficiency_records] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fuel_fuel_efficiency_records_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fuel_fuel_efficiency_records_2] UNIQUE ([tenant_id], [asset_id], [period_start], [period_end], [source]),
    CONSTRAINT [CK_fuel_fuel_efficiency_records_1] CHECK (miles >= 0),
    CONSTRAINT [CK_fuel_fuel_efficiency_records_2] CHECK (gallons >= 0),
    CONSTRAINT [CK_fuel_fuel_efficiency_records_3] CHECK (period_end >= period_start)
);

CREATE TABLE [fuel].[fuel_exceptions] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fuel_fuel_exceptions_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [fuel_transaction_id] UNIQUEIDENTIFIER NOT NULL,
    [exception_type] VARCHAR(30) NOT NULL,
    [severity] VARCHAR(20) NOT NULL,
    [resolution_status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_exceptions_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fuel_fuel_exceptions_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fuel_fuel_exceptions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fuel_fuel_exceptions_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [fin].[revenue_items] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_revenue_items_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [load_id] UNIQUEIDENTIFIER NOT NULL,
    [revenue_category_id] SMALLINT NOT NULL,
    [amount] DECIMAL(19,4) NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [recognition_status] VARCHAR(20) NOT NULL,
    [recognized_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_revenue_items_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_revenue_items_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_revenue_items] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_revenue_items_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [fin].[expenses] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_expenses_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [expense_category_id] SMALLINT NOT NULL,
    [vendor_id] UNIQUEIDENTIFIER NULL,
    [description] NVARCHAR(500) NOT NULL,
    [expense_date] DATE NOT NULL,
    [amount] DECIMAL(19,4) NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [source_type] VARCHAR(30) NOT NULL,
    [source_reference] NVARCHAR(150) NULL,
    [reconciliation_status] VARCHAR(20) NOT NULL,
    [approval_status] VARCHAR(20) NOT NULL,
    [approved_by] UNIQUEIDENTIFIER NULL,
    [approved_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_expenses_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_expenses_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_expenses] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_expenses_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [fin].[expense_allocations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_expense_allocations_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [expense_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NULL,
    [asset_id] UNIQUEIDENTIFIER NULL,
    [allocated_amount] DECIMAL(19,4) NOT NULL,
    [allocation_basis] VARCHAR(50) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_expense_allocations_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_expense_allocations_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_expense_allocations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_expense_allocations_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_fin_expense_allocations_1] CHECK (trip_id IS NOT NULL OR asset_id IS NOT NULL)
);

CREATE TABLE [fin].[revenue_allocations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_revenue_allocations_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [revenue_item_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [allocated_amount] DECIMAL(19,4) NOT NULL,
    [allocation_basis] VARCHAR(50) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_revenue_allocations_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_revenue_allocations_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_revenue_allocations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_revenue_allocations_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [fin].[trip_financial_closures] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_trip_financial_closures_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [closure_status] VARCHAR(25) NOT NULL,
    [finalized_at] DATETIME2(3) NULL,
    [finalized_by] UNIQUEIDENTIFIER NULL,
    [calculation_version] VARCHAR(30) NOT NULL,
    [revision_number] INT NOT NULL,
    [revenue_total] DECIMAL(19,4) NULL,
    [direct_cost_total] DECIMAL(19,4) NULL,
    [snapshot] NVARCHAR(MAX) NULL,
    [currency_code] CHAR(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_trip_financial_closures_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_trip_financial_closures_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_trip_financial_closures] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_trip_financial_closures_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fin_trip_financial_closures_2] UNIQUE ([tenant_id], [trip_id], [revision_number]),
    CONSTRAINT [CK_fin_trip_financial_closures_1] CHECK (revision_number > 0),
    CONSTRAINT [CK_fin_trip_financial_closures_2] CHECK (ISJSON(snapshot) = 1),
    CONSTRAINT [CK_fin_trip_financial_closures_3] CHECK (closure_status IN ('ESTIMATED','PARTIAL','FINALIZED','SUPERSEDED')),
    CONSTRAINT [CK_fin_trip_financial_closures_4] CHECK (closure_status <> 'FINALIZED' OR (finalized_at IS NOT NULL AND finalized_by IS NOT NULL AND revenue_total IS NOT NULL AND direct_cost_total IS NOT NULL AND snapshot IS NOT NULL))
);

CREATE TABLE [fin].[cost_allocation_rules] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_cost_allocation_rules_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [expense_category_id] SMALLINT NOT NULL,
    [allocation_method] VARCHAR(50) NOT NULL,
    [effective_from] DATETIME2(3) NOT NULL,
    [effective_to] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_cost_allocation_rules_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_cost_allocation_rules_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_cost_allocation_rules] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_cost_allocation_rules_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_fin_cost_allocation_rules_1] CHECK (effective_to >= effective_from)
);

CREATE TABLE [fin].[invoices] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_invoices_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [customer_id] UNIQUEIDENTIFIER NOT NULL,
    [invoice_number] NVARCHAR(40) NOT NULL,
    [invoice_date] DATE NOT NULL,
    [due_date] DATE NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_invoices_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_invoices_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_invoices] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_invoices_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fin_invoices_2] UNIQUE ([tenant_id], [invoice_number]),
    CONSTRAINT [CK_fin_invoices_1] CHECK (due_date >= invoice_date)
);

CREATE TABLE [fin].[invoice_items] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_invoice_items_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [invoice_id] UNIQUEIDENTIFIER NOT NULL,
    [revenue_item_id] UNIQUEIDENTIFIER NULL,
    [description] NVARCHAR(500) NOT NULL,
    [quantity] DECIMAL(14,3) NOT NULL,
    [unit_price] DECIMAL(19,4) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_invoice_items_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_invoice_items_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_invoice_items] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_invoice_items_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [fin].[payments] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_payments_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [customer_id] UNIQUEIDENTIFIER NOT NULL,
    [payment_reference] NVARCHAR(100) NOT NULL,
    [amount] DECIMAL(19,4) NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [received_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_payments_received_at] DEFAULT (SYSUTCDATETIME()),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_payments_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_payments_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_payments] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_payments_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fin_payments_2] UNIQUE ([tenant_id], [payment_reference])
);

CREATE TABLE [fin].[payment_allocations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_payment_allocations_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [payment_id] UNIQUEIDENTIFIER NOT NULL,
    [invoice_id] UNIQUEIDENTIFIER NOT NULL,
    [allocated_amount] DECIMAL(19,4) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_payment_allocations_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_payment_allocations_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_payment_allocations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_payment_allocations_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [fin].[driver_settlements] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_driver_settlements_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [period_start] DATE NOT NULL,
    [period_end] DATE NOT NULL,
    [settlement_status] VARCHAR(20) NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_driver_settlements_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_driver_settlements_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_driver_settlements] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_driver_settlements_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_fin_driver_settlements_1] CHECK (period_end >= period_start)
);

CREATE TABLE [fin].[driver_settlement_items] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_driver_settlement_items_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [settlement_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NULL,
    [category] VARCHAR(30) NOT NULL,
    [amount] DECIMAL(19,4) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_driver_settlement_items_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_driver_settlement_items_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_driver_settlement_items] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_driver_settlement_items_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [fin].[financial_periods] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_financial_periods_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [period_start] DATE NOT NULL,
    [period_end] DATE NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_financial_periods_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_financial_periods_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_financial_periods] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_financial_periods_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fin_financial_periods_2] UNIQUE ([tenant_id], [period_start], [period_end]),
    CONSTRAINT [CK_fin_financial_periods_1] CHECK (period_end >= period_start)
);

CREATE TABLE [fin].[financial_adjustments] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_financial_adjustments_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [expense_id] UNIQUEIDENTIFIER NULL,
    [revenue_item_id] UNIQUEIDENTIFIER NULL,
    [adjustment_amount] DECIMAL(19,4) NOT NULL,
    [reason] NVARCHAR(500) NOT NULL,
    [approved_by] UNIQUEIDENTIFIER NOT NULL,
    [currency_code] CHAR(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_financial_adjustments_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_fin_financial_adjustments] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_financial_adjustments_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_fin_financial_adjustments_1] CHECK ((expense_id IS NOT NULL AND revenue_item_id IS NULL) OR (expense_id IS NULL AND revenue_item_id IS NOT NULL))
);

CREATE TABLE [fin].[service_expense_links] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_service_expense_links_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [service_record_id] UNIQUEIDENTIFIER NOT NULL,
    [expense_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_service_expense_links_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_service_expense_links_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_service_expense_links] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_service_expense_links_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fin_service_expense_links_2] UNIQUE ([tenant_id], [service_record_id], [expense_id])
);

CREATE TABLE [fin].[work_order_expense_links] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_fin_work_order_expense_links_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [work_order_id] UNIQUEIDENTIFIER NOT NULL,
    [expense_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_work_order_expense_links_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_fin_work_order_expense_links_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_fin_work_order_expense_links] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_fin_work_order_expense_links_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_fin_work_order_expense_links_2] UNIQUE ([tenant_id], [work_order_id], [expense_id])
);

CREATE TABLE [compliance].[compliance_requirements] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_compliance_requirements_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [requirement_code] VARCHAR(50) NOT NULL,
    [name] NVARCHAR(150) NOT NULL,
    [applicability] VARCHAR(30) NOT NULL,
    [renewal_interval_days] INT NULL,
    [enabled] BIT NOT NULL CONSTRAINT [DF_compliance_compliance_requirements_enabled] DEFAULT (1),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_compliance_requirements_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_compliance_requirements_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_compliance_requirements] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_compliance_requirements_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_compliance_compliance_requirements_2] UNIQUE ([tenant_id], [requirement_code])
);

CREATE TABLE [compliance].[driver_compliance_records] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_driver_compliance_records_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [requirement_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NULL,
    [verified_at] DATETIME2(3) NULL,
    [expires_at] DATETIME2(3) NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_driver_compliance_records_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_driver_compliance_records_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_driver_compliance_records] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_driver_compliance_records_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [compliance].[asset_compliance_records] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_asset_compliance_records_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [requirement_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NULL,
    [verified_at] DATETIME2(3) NULL,
    [expires_at] DATETIME2(3) NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_asset_compliance_records_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_asset_compliance_records_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_asset_compliance_records] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_asset_compliance_records_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [compliance].[inspection_templates] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_inspection_templates_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [inspection_type] VARCHAR(30) NOT NULL,
    [version] INT NOT NULL,
    [effective_from] DATETIME2(3) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_inspection_templates_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_inspection_templates_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_inspection_templates] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_inspection_templates_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_compliance_inspection_templates_2] UNIQUE ([tenant_id], [inspection_type], [version]),
    CONSTRAINT [CK_compliance_inspection_templates_1] CHECK (version > 0)
);

CREATE TABLE [compliance].[inspection_template_items] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_inspection_template_items_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [template_id] UNIQUEIDENTIFIER NOT NULL,
    [component] NVARCHAR(100) NOT NULL,
    [question] NVARCHAR(500) NOT NULL,
    [sequence_number] INT NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_inspection_template_items_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_inspection_template_items_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_inspection_template_items] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_inspection_template_items_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_compliance_inspection_template_items_2] UNIQUE ([tenant_id], [template_id], [sequence_number]),
    CONSTRAINT [CK_compliance_inspection_template_items_1] CHECK (sequence_number > 0)
);

CREATE TABLE [compliance].[inspections] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_inspections_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NULL,
    [template_id] UNIQUEIDENTIFIER NOT NULL,
    [inspection_at] DATETIME2(3) NOT NULL,
    [result] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_inspections_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_inspections_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_inspections] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_inspections_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [compliance].[inspection_items] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_inspection_items_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [inspection_id] UNIQUEIDENTIFIER NOT NULL,
    [template_item_id] UNIQUEIDENTIFIER NOT NULL,
    [result] VARCHAR(20) NOT NULL,
    [notes] NVARCHAR(1000) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_inspection_items_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_inspection_items_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_inspection_items] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_inspection_items_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_compliance_inspection_items_2] UNIQUE ([tenant_id], [inspection_id], [template_item_id])
);

CREATE TABLE [compliance].[repair_certifications] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_repair_certifications_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [defect_id] UNIQUEIDENTIFIER NOT NULL,
    [work_order_id] UNIQUEIDENTIFIER NULL,
    [certified_by] UNIQUEIDENTIFIER NOT NULL,
    [certified_at] DATETIME2(3) NOT NULL,
    [attestation] NVARCHAR(1000) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_repair_certifications_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_compliance_repair_certifications] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_repair_certifications_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [compliance].[hos_records] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_hos_records_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [connection_id] UNIQUEIDENTIFIER NOT NULL,
    [duty_status] VARCHAR(30) NOT NULL,
    [started_at] DATETIME2(3) NOT NULL,
    [ended_at] DATETIME2(3) NULL,
    [external_event_id] NVARCHAR(150) NOT NULL,
    [source] VARCHAR(30) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_hos_records_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_compliance_hos_records] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_hos_records_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_compliance_hos_records_2] UNIQUE ([tenant_id], [connection_id], [external_event_id]),
    CONSTRAINT [CK_compliance_hos_records_1] CHECK (ended_at >= started_at)
);

CREATE TABLE [compliance].[hos_balance_snapshots] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_hos_balance_snapshots_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [connection_id] UNIQUEIDENTIFIER NOT NULL,
    [drive_remaining] INT NULL,
    [duty_remaining] INT NULL,
    [cycle_remaining] INT NULL,
    [recorded_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_hos_balance_snapshots_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_compliance_hos_balance_snapshots] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_hos_balance_snapshots_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_compliance_hos_balance_snapshots_1] CHECK (drive_remaining >= 0),
    CONSTRAINT [CK_compliance_hos_balance_snapshots_2] CHECK (duty_remaining >= 0),
    CONSTRAINT [CK_compliance_hos_balance_snapshots_3] CHECK (cycle_remaining >= 0)
);

CREATE TABLE [compliance].[safety_incidents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_safety_incidents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NULL,
    [driver_id] UNIQUEIDENTIFIER NULL,
    [incident_type] VARCHAR(40) NOT NULL,
    [occurred_at] DATETIME2(3) NOT NULL,
    [severity] VARCHAR(20) NOT NULL,
    [description] NVARCHAR(2000) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_safety_incidents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_safety_incidents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_safety_incidents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_safety_incidents_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [compliance].[jurisdiction_distance_records] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_jurisdiction_distance_records_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NULL,
    [jurisdiction_id] SMALLINT NOT NULL,
    [distance] DECIMAL(14,3) NOT NULL,
    [source] VARCHAR(30) NOT NULL,
    [recorded_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_jurisdiction_distance_records_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_jurisdiction_distance_records_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_jurisdiction_distance_records] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_jurisdiction_distance_records_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_compliance_jurisdiction_distance_records_1] CHECK (distance >= 0)
);

CREATE TABLE [compliance].[ifta_reporting_periods] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_ifta_reporting_periods_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [year] SMALLINT NOT NULL,
    [quarter] SMALLINT NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_ifta_reporting_periods_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_ifta_reporting_periods_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_ifta_reporting_periods] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_ifta_reporting_periods_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_compliance_ifta_reporting_periods_2] UNIQUE ([tenant_id], [year], [quarter]),
    CONSTRAINT [CK_compliance_ifta_reporting_periods_1] CHECK (quarter BETWEEN 1 AND 4)
);

CREATE TABLE [compliance].[ifta_report_lines] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_compliance_ifta_report_lines_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [period_id] UNIQUEIDENTIFIER NOT NULL,
    [jurisdiction_id] SMALLINT NOT NULL,
    [total_miles] DECIMAL(14,3) NOT NULL,
    [qualifying_gallons] DECIMAL(14,3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_ifta_report_lines_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_compliance_ifta_report_lines_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_compliance_ifta_report_lines] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_compliance_ifta_report_lines_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_compliance_ifta_report_lines_2] UNIQUE ([tenant_id], [period_id], [jurisdiction_id]),
    CONSTRAINT [CK_compliance_ifta_report_lines_1] CHECK (total_miles >= 0),
    CONSTRAINT [CK_compliance_ifta_report_lines_2] CHECK (qualifying_gallons >= 0)
);

CREATE TABLE [docs].[documents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_documents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [document_type_id] SMALLINT NOT NULL,
    [title] NVARCHAR(200) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [issued_at] DATETIME2(3) NULL,
    [expires_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_documents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_documents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_docs_documents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_documents_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [docs].[document_versions] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_document_versions_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [version_number] INT NOT NULL,
    [object_key] NVARCHAR(500) NOT NULL,
    [content_type] VARCHAR(100) NOT NULL,
    [checksum] BINARY(32) NOT NULL,
    [file_size] BIGINT NOT NULL,
    [scan_status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_document_versions_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_document_versions_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_docs_document_versions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_document_versions_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_docs_document_versions_2] UNIQUE ([tenant_id], [document_id], [version_number]),
    CONSTRAINT [UQ_docs_document_versions_3] UNIQUE ([tenant_id], [object_key]),
    CONSTRAINT [CK_docs_document_versions_1] CHECK (version_number > 0),
    CONSTRAINT [CK_docs_document_versions_2] CHECK (file_size >= 0)
);

CREATE TABLE [docs].[asset_documents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_asset_documents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [asset_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_asset_documents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_asset_documents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_docs_asset_documents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_asset_documents_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_docs_asset_documents_2] UNIQUE ([tenant_id], [asset_id], [document_id])
);

CREATE TABLE [docs].[driver_documents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_driver_documents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [driver_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_driver_documents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_driver_documents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_docs_driver_documents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_driver_documents_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_docs_driver_documents_2] UNIQUE ([tenant_id], [driver_id], [document_id])
);

CREATE TABLE [docs].[load_documents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_load_documents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [load_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_load_documents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_load_documents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_docs_load_documents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_load_documents_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_docs_load_documents_2] UNIQUE ([tenant_id], [load_id], [document_id])
);

CREATE TABLE [docs].[trip_documents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_trip_documents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [trip_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_trip_documents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_trip_documents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_docs_trip_documents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_trip_documents_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_docs_trip_documents_2] UNIQUE ([tenant_id], [trip_id], [document_id])
);

CREATE TABLE [docs].[delivery_documents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_delivery_documents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [delivery_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [version_number] INT NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_delivery_documents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_delivery_documents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_docs_delivery_documents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_delivery_documents_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_docs_delivery_documents_2] UNIQUE ([tenant_id], [delivery_id], [document_id])
);

CREATE TABLE [docs].[inspection_documents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_inspection_documents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [inspection_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_inspection_documents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_inspection_documents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_docs_inspection_documents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_inspection_documents_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_docs_inspection_documents_2] UNIQUE ([tenant_id], [inspection_id], [document_id])
);

CREATE TABLE [docs].[expense_documents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_expense_documents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [expense_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_expense_documents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_expense_documents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_docs_expense_documents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_expense_documents_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_docs_expense_documents_2] UNIQUE ([tenant_id], [expense_id], [document_id])
);

CREATE TABLE [docs].[work_order_documents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_work_order_documents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [work_order_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_work_order_documents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_work_order_documents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_docs_work_order_documents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_work_order_documents_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_docs_work_order_documents_2] UNIQUE ([tenant_id], [work_order_id], [document_id])
);

CREATE TABLE [docs].[document_verifications] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_docs_document_verifications_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [version_number] INT NOT NULL,
    [verified_by] UNIQUEIDENTIFIER NOT NULL,
    [verified_at] DATETIME2(3) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_docs_document_verifications_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_docs_document_verifications] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_docs_document_verifications_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [notify].[alert_rules] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_notify_alert_rules_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [rule_type] VARCHAR(50) NOT NULL,
    [severity] VARCHAR(15) NOT NULL,
    [threshold] DECIMAL(14,3) NULL,
    [enabled] BIT NOT NULL CONSTRAINT [DF_notify_alert_rules_enabled] DEFAULT (1),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_alert_rules_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_alert_rules_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_notify_alert_rules] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_notify_alert_rules_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [notify].[alerts] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_notify_alerts_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [rule_id] UNIQUEIDENTIFIER NULL,
    [source_domain] VARCHAR(50) NOT NULL,
    [source_reference] NVARCHAR(150) NOT NULL,
    [severity] VARCHAR(15) NOT NULL,
    [title] NVARCHAR(200) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [resolved_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_alerts_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_alerts_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_notify_alerts] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_notify_alerts_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [notify].[alert_assignments] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_notify_alert_assignments_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [alert_id] UNIQUEIDENTIFIER NOT NULL,
    [membership_id] UNIQUEIDENTIFIER NOT NULL,
    [assigned_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_alert_assignments_assigned_at] DEFAULT (SYSUTCDATETIME()),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_alert_assignments_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_alert_assignments_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_notify_alert_assignments] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_notify_alert_assignments_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_notify_alert_assignments_2] UNIQUE ([tenant_id], [alert_id], [membership_id])
);

CREATE TABLE [notify].[alert_acknowledgments] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_notify_alert_acknowledgments_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [alert_id] UNIQUEIDENTIFIER NOT NULL,
    [membership_id] UNIQUEIDENTIFIER NOT NULL,
    [acknowledged_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_alert_acknowledgments_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_notify_alert_acknowledgments] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_notify_alert_acknowledgments_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_notify_alert_acknowledgments_2] UNIQUE ([tenant_id], [alert_id], [membership_id])
);

CREATE TABLE [notify].[notifications] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_notify_notifications_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [recipient_id] UNIQUEIDENTIFIER NOT NULL,
    [channel] VARCHAR(20) NOT NULL,
    [message] NVARCHAR(2000) NOT NULL,
    [delivery_status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_notifications_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_notifications_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_notify_notifications] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_notify_notifications_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [notify].[notification_preferences] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_notify_notification_preferences_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [membership_id] UNIQUEIDENTIFIER NOT NULL,
    [event_type] VARCHAR(50) NOT NULL,
    [channel] VARCHAR(20) NOT NULL,
    [enabled] BIT NOT NULL CONSTRAINT [DF_notify_notification_preferences_enabled] DEFAULT (1),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_notification_preferences_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_notification_preferences_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_notify_notification_preferences] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_notify_notification_preferences_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_notify_notification_preferences_2] UNIQUE ([tenant_id], [membership_id], [event_type], [channel])
);

CREATE TABLE [notify].[notification_delivery_attempts] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_notify_notification_delivery_attempts_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [notification_id] UNIQUEIDENTIFIER NOT NULL,
    [provider_reference] NVARCHAR(150) NULL,
    [attempt_number] INT NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [attempted_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_notification_delivery_attempts_attempted_at] DEFAULT (SYSUTCDATETIME()),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_notification_delivery_attempts_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_notify_notification_delivery_attempts] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_notify_notification_delivery_attempts_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_notify_notification_delivery_attempts_2] UNIQUE ([tenant_id], [notification_id], [attempt_number]),
    CONSTRAINT [CK_notify_notification_delivery_attempts_1] CHECK (attempt_number > 0)
);

CREATE TABLE [notify].[notification_templates] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_notify_notification_templates_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [template_code] VARCHAR(50) NOT NULL,
    [channel] VARCHAR(20) NOT NULL,
    [subject] NVARCHAR(200) NULL,
    [template_body] NVARCHAR(MAX) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_notification_templates_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_notify_notification_templates_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_notify_notification_templates] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_notify_notification_templates_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_notify_notification_templates_2] UNIQUE ([tenant_id], [template_code], [channel])
);

CREATE TABLE [ai].[conversations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_conversations_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [membership_id] UNIQUEIDENTIFIER NOT NULL,
    [title] NVARCHAR(200) NULL,
    [context_type] VARCHAR(50) NULL,
    [context_reference] UNIQUEIDENTIFIER NULL,
    [status] VARCHAR(20) NOT NULL,
    [last_activity_at] DATETIME2(3) NOT NULL,
    [archived_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_conversations_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_conversations_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ai_conversations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_conversations_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [ai].[messages] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_messages_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [conversation_id] UNIQUEIDENTIFIER NOT NULL,
    [role] VARCHAR(20) NOT NULL,
    [content] NVARCHAR(MAX) NOT NULL,
    [sequence_number] INT NOT NULL,
    [model_identifier] NVARCHAR(100) NULL,
    [status] VARCHAR(20) NOT NULL,
    [completed_at] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_messages_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_messages_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ai_messages] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_messages_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ai_messages_2] UNIQUE ([tenant_id], [conversation_id], [sequence_number]),
    CONSTRAINT [CK_ai_messages_1] CHECK (sequence_number > 0),
    CONSTRAINT [CK_ai_messages_2] CHECK (role IN ('USER','ASSISTANT','SYSTEM','TOOL'))
);

CREATE TABLE [ai].[model_configurations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_model_configurations_id] DEFAULT (NEWSEQUENTIALID()),
    [provider] VARCHAR(30) NOT NULL,
    [model_identifier] NVARCHAR(100) NOT NULL,
    [enabled] BIT NOT NULL CONSTRAINT [DF_ai_model_configurations_enabled] DEFAULT (1),
    [temperature] DECIMAL(14,3) NULL,
    [token_limit] INT NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_model_configurations_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_model_configurations_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    CONSTRAINT [PK_ai_model_configurations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_model_configurations_1] UNIQUE ([provider], [model_identifier]),
    CONSTRAINT [CK_ai_model_configurations_1] CHECK (token_limit > 0),
    CONSTRAINT [CK_ai_model_configurations_2] CHECK (temperature BETWEEN 0 AND 2)
);

CREATE TABLE [ai].[tool_definitions] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_tool_definitions_id] DEFAULT (NEWSEQUENTIALID()),
    [tool_code] VARCHAR(80) NOT NULL,
    [description] NVARCHAR(500) NOT NULL,
    [required_permission_id] UNIQUEIDENTIFIER NOT NULL,
    [enabled] BIT NOT NULL CONSTRAINT [DF_ai_tool_definitions_enabled] DEFAULT (1),
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_tool_definitions_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_tool_definitions_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    CONSTRAINT [PK_ai_tool_definitions] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_tool_definitions_1] UNIQUE ([tool_code])
);

CREATE TABLE [ai].[tool_invocations] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_tool_invocations_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [message_id] UNIQUEIDENTIFIER NOT NULL,
    [tool_id] UNIQUEIDENTIFIER NOT NULL,
    [request_metadata] NVARCHAR(MAX) NULL,
    [status] VARCHAR(20) NOT NULL,
    [duration_ms] INT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_tool_invocations_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ai_tool_invocations] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_tool_invocations_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_ai_tool_invocations_1] CHECK (ISJSON(request_metadata) = 1),
    CONSTRAINT [CK_ai_tool_invocations_2] CHECK (duration_ms >= 0)
);

CREATE TABLE [ai].[response_sources] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_response_sources_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [message_id] UNIQUEIDENTIFIER NOT NULL,
    [tool_invocation_id] UNIQUEIDENTIFIER NOT NULL,
    [resource_type] VARCHAR(50) NOT NULL,
    [resource_id] NVARCHAR(100) NOT NULL,
    [source_timestamp] DATETIME2(3) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_response_sources_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ai_response_sources] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_response_sources_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [ai].[response_feedback] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_response_feedback_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [message_id] UNIQUEIDENTIFIER NOT NULL,
    [membership_id] UNIQUEIDENTIFIER NOT NULL,
    [rating] SMALLINT NOT NULL,
    [feedback_category] VARCHAR(50) NULL,
    [comments] NVARCHAR(1000) NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_response_feedback_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_response_feedback_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ai_response_feedback] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_response_feedback_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ai_response_feedback_2] UNIQUE ([tenant_id], [message_id], [membership_id]),
    CONSTRAINT [CK_ai_response_feedback_1] CHECK (rating IN (-1,1))
);

CREATE TABLE [ai].[usage_records] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_usage_records_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [message_id] UNIQUEIDENTIFIER NULL,
    [model_identifier] NVARCHAR(100) NOT NULL,
    [input_tokens] INT NOT NULL,
    [output_tokens] INT NOT NULL,
    [estimated_cost] DECIMAL(19,4) NULL,
    [currency_code] CHAR(3) NOT NULL,
    [latency_ms] INT NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_usage_records_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ai_usage_records] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_usage_records_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_ai_usage_records_1] CHECK (input_tokens >= 0),
    CONSTRAINT [CK_ai_usage_records_2] CHECK (output_tokens >= 0),
    CONSTRAINT [CK_ai_usage_records_3] CHECK (latency_ms >= 0)
);

CREATE TABLE [ai].[tenant_ai_settings] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_tenant_ai_settings_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [enabled] BIT NOT NULL CONSTRAINT [DF_ai_tenant_ai_settings_enabled] DEFAULT (1),
    [usage_limit] INT NOT NULL,
    [retention_days] INT NOT NULL,
    [model_configuration_id] UNIQUEIDENTIFIER NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_tenant_ai_settings_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_tenant_ai_settings_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ai_tenant_ai_settings] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_tenant_ai_settings_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ai_tenant_ai_settings_2] UNIQUE ([tenant_id]),
    CONSTRAINT [CK_ai_tenant_ai_settings_1] CHECK (usage_limit >= 0),
    CONSTRAINT [CK_ai_tenant_ai_settings_2] CHECK (retention_days BETWEEN 1 AND 3650)
);

CREATE TABLE [ai].[prompt_templates] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_prompt_templates_id] DEFAULT (NEWSEQUENTIALID()),
    [template_code] VARCHAR(50) NOT NULL,
    [version] INT NOT NULL,
    [template_content] NVARCHAR(MAX) NOT NULL,
    [status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_prompt_templates_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_prompt_templates_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    CONSTRAINT [PK_ai_prompt_templates] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_prompt_templates_1] UNIQUE ([template_code], [version]),
    CONSTRAINT [CK_ai_prompt_templates_1] CHECK (version > 0)
);

CREATE TABLE [ai].[evaluation_cases] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_evaluation_cases_id] DEFAULT (NEWSEQUENTIALID()),
    [question] NVARCHAR(1000) NOT NULL,
    [expected_behavior] NVARCHAR(2000) NOT NULL,
    [evaluation_category] VARCHAR(50) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_evaluation_cases_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_evaluation_cases_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    CONSTRAINT [PK_ai_evaluation_cases] PRIMARY KEY ([id])
);

CREATE TABLE [ai].[evaluation_runs] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_evaluation_runs_id] DEFAULT (NEWSEQUENTIALID()),
    [case_id] UNIQUEIDENTIFIER NOT NULL,
    [model_identifier] NVARCHAR(100) NOT NULL,
    [evaluated_at] DATETIME2(3) NOT NULL,
    [result] VARCHAR(20) NOT NULL,
    [evaluation_version] VARCHAR(30) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_evaluation_runs_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_evaluation_runs_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    CONSTRAINT [PK_ai_evaluation_runs] PRIMARY KEY ([id])
);

CREATE TABLE [ai].[knowledge_documents] (
    [id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ai_knowledge_documents_id] DEFAULT (NEWSEQUENTIALID()),
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [document_id] UNIQUEIDENTIFIER NOT NULL,
    [indexing_status] VARCHAR(20) NOT NULL,
    [access_scope] VARCHAR(30) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_knowledge_documents_created_at] DEFAULT (SYSUTCDATETIME()),
    [updated_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ai_knowledge_documents_updated_at] DEFAULT (SYSUTCDATETIME()),
    [row_version] ROWVERSION NOT NULL,
    [created_by] UNIQUEIDENTIFIER NULL,
    [updated_by] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_ai_knowledge_documents] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ai_knowledge_documents_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [UQ_ai_knowledge_documents_2] UNIQUE ([tenant_id], [document_id])
);

CREATE TABLE [audit].[audit_events] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [actor_id] UNIQUEIDENTIFIER NULL,
    [actor_type] VARCHAR(20) NOT NULL,
    [action] VARCHAR(50) NOT NULL,
    [entity_type] VARCHAR(100) NOT NULL,
    [entity_id] NVARCHAR(100) NULL,
    [old_values] NVARCHAR(MAX) NULL,
    [new_values] NVARCHAR(MAX) NULL,
    [correlation_id] UNIQUEIDENTIFIER NOT NULL,
    [occurred_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_audit_audit_events_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_audit_audit_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_audit_audit_events_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_audit_audit_events_1] CHECK (ISJSON(old_values) = 1),
    CONSTRAINT [CK_audit_audit_events_2] CHECK (ISJSON(new_values) = 1)
);

CREATE TABLE [audit].[security_events] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [user_id] UNIQUEIDENTIFIER NULL,
    [event_type] VARCHAR(50) NOT NULL,
    [result] VARCHAR(20) NOT NULL,
    [correlation_id] UNIQUEIDENTIFIER NOT NULL,
    [occurred_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_audit_security_events_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_audit_security_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_audit_security_events_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [audit].[data_access_events] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [actor_id] UNIQUEIDENTIFIER NULL,
    [resource_type] VARCHAR(50) NOT NULL,
    [resource_id] NVARCHAR(100) NOT NULL,
    [access_reason] NVARCHAR(200) NOT NULL,
    [occurred_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_audit_data_access_events_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_audit_data_access_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_audit_data_access_events_1] UNIQUE ([tenant_id], [id])
);

CREATE TABLE [audit].[export_events] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [user_id] UNIQUEIDENTIFIER NOT NULL,
    [report_type] VARCHAR(50) NOT NULL,
    [filter_metadata] NVARCHAR(MAX) NULL,
    [exported_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_audit_export_events_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_audit_export_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_audit_export_events_1] UNIQUE ([tenant_id], [id]),
    CONSTRAINT [CK_audit_export_events_1] CHECK (ISJSON(filter_metadata) = 1)
);

CREATE TABLE [audit].[approval_events] (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [tenant_id] UNIQUEIDENTIFIER NOT NULL,
    [entity_type] VARCHAR(50) NOT NULL,
    [entity_id] NVARCHAR(100) NOT NULL,
    [decision] VARCHAR(20) NOT NULL,
    [approved_by] UNIQUEIDENTIFIER NOT NULL,
    [occurred_at] DATETIME2(3) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_audit_approval_events_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_audit_approval_events] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_audit_approval_events_1] UNIQUE ([tenant_id], [id])
);
ALTER TABLE [core].[tenants] ADD CONSTRAINT [FK_core_tenants_1] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
CREATE INDEX [IX_core_tenants_1] ON [core].[tenants] ([currency_code]);
ALTER TABLE [core].[tenant_settings] ADD CONSTRAINT [FK_core_tenant_settings_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [core].[tenant_settings] ADD CONSTRAINT [FK_core_tenant_settings_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[tenant_settings] ADD CONSTRAINT [FK_core_tenant_settings_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[terminals] ADD CONSTRAINT [FK_core_terminals_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [core].[terminals] ADD CONSTRAINT [FK_core_terminals_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[terminals] ADD CONSTRAINT [FK_core_terminals_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[departments] ADD CONSTRAINT [FK_core_departments_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [core].[departments] ADD CONSTRAINT [FK_core_departments_2] FOREIGN KEY ([tenant_id], [terminal_id]) REFERENCES [core].[terminals] ([tenant_id], [id]);
ALTER TABLE [core].[departments] ADD CONSTRAINT [FK_core_departments_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[departments] ADD CONSTRAINT [FK_core_departments_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_core_departments_1] ON [core].[departments] ([tenant_id], [terminal_id]);
ALTER TABLE [core].[business_entities] ADD CONSTRAINT [FK_core_business_entities_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [core].[business_entities] ADD CONSTRAINT [FK_core_business_entities_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[business_entities] ADD CONSTRAINT [FK_core_business_entities_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[number_sequences] ADD CONSTRAINT [FK_core_number_sequences_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [core].[number_sequences] ADD CONSTRAINT [FK_core_number_sequences_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[number_sequences] ADD CONSTRAINT [FK_core_number_sequences_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ref].[jurisdictions] ADD CONSTRAINT [FK_ref_jurisdictions_1] FOREIGN KEY ([country_id]) REFERENCES [ref].[countries] ([id]);
ALTER TABLE [iam].[memberships] ADD CONSTRAINT [FK_iam_memberships_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [iam].[memberships] ADD CONSTRAINT [FK_iam_memberships_2] FOREIGN KEY ([user_id]) REFERENCES [iam].[users] ([id]);
ALTER TABLE [iam].[memberships] ADD CONSTRAINT [FK_iam_memberships_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[memberships] ADD CONSTRAINT [FK_iam_memberships_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[roles] ADD CONSTRAINT [FK_iam_roles_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [iam].[roles] ADD CONSTRAINT [FK_iam_roles_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[roles] ADD CONSTRAINT [FK_iam_roles_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[membership_roles] ADD CONSTRAINT [FK_iam_membership_roles_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [iam].[membership_roles] ADD CONSTRAINT [FK_iam_membership_roles_2] FOREIGN KEY ([tenant_id], [membership_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[membership_roles] ADD CONSTRAINT [FK_iam_membership_roles_3] FOREIGN KEY ([tenant_id], [role_id]) REFERENCES [iam].[roles] ([tenant_id], [id]);
ALTER TABLE [iam].[membership_roles] ADD CONSTRAINT [FK_iam_membership_roles_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[membership_roles] ADD CONSTRAINT [FK_iam_membership_roles_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_iam_membership_roles_1] ON [iam].[membership_roles] ([tenant_id], [role_id]);
ALTER TABLE [iam].[role_permissions] ADD CONSTRAINT [FK_iam_role_permissions_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [iam].[role_permissions] ADD CONSTRAINT [FK_iam_role_permissions_2] FOREIGN KEY ([tenant_id], [role_id]) REFERENCES [iam].[roles] ([tenant_id], [id]);
ALTER TABLE [iam].[role_permissions] ADD CONSTRAINT [FK_iam_role_permissions_3] FOREIGN KEY ([permission_id]) REFERENCES [iam].[permissions] ([id]);
ALTER TABLE [iam].[role_permissions] ADD CONSTRAINT [FK_iam_role_permissions_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[role_permissions] ADD CONSTRAINT [FK_iam_role_permissions_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_iam_role_permissions_1] ON [iam].[role_permissions] ([tenant_id], [permission_id]);
ALTER TABLE [iam].[user_preferences] ADD CONSTRAINT [FK_iam_user_preferences_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [iam].[user_preferences] ADD CONSTRAINT [FK_iam_user_preferences_2] FOREIGN KEY ([tenant_id], [membership_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[user_preferences] ADD CONSTRAINT [FK_iam_user_preferences_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[user_preferences] ADD CONSTRAINT [FK_iam_user_preferences_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[invitations] ADD CONSTRAINT [FK_iam_invitations_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [iam].[invitations] ADD CONSTRAINT [FK_iam_invitations_2] FOREIGN KEY ([tenant_id], [invited_role_id]) REFERENCES [iam].[roles] ([tenant_id], [id]);
ALTER TABLE [iam].[invitations] ADD CONSTRAINT [FK_iam_invitations_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[invitations] ADD CONSTRAINT [FK_iam_invitations_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_iam_invitations_1] ON [iam].[invitations] ([tenant_id], [invited_role_id]);
ALTER TABLE [iam].[terminal_access] ADD CONSTRAINT [FK_iam_terminal_access_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [iam].[terminal_access] ADD CONSTRAINT [FK_iam_terminal_access_2] FOREIGN KEY ([tenant_id], [membership_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[terminal_access] ADD CONSTRAINT [FK_iam_terminal_access_3] FOREIGN KEY ([tenant_id], [terminal_id]) REFERENCES [core].[terminals] ([tenant_id], [id]);
ALTER TABLE [iam].[terminal_access] ADD CONSTRAINT [FK_iam_terminal_access_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [iam].[terminal_access] ADD CONSTRAINT [FK_iam_terminal_access_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_iam_terminal_access_1] ON [iam].[terminal_access] ([tenant_id], [terminal_id]);
ALTER TABLE [fleet].[assets] ADD CONSTRAINT [FK_fleet_assets_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fleet].[assets] ADD CONSTRAINT [FK_fleet_assets_2] FOREIGN KEY ([asset_type_id]) REFERENCES [ref].[asset_types] ([id]);
ALTER TABLE [fleet].[assets] ADD CONSTRAINT [FK_fleet_assets_3] FOREIGN KEY ([tenant_id], [terminal_id]) REFERENCES [core].[terminals] ([tenant_id], [id]);
ALTER TABLE [fleet].[assets] ADD CONSTRAINT [FK_fleet_assets_4] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [fleet].[assets] ADD CONSTRAINT [FK_fleet_assets_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fleet].[assets] ADD CONSTRAINT [FK_fleet_assets_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE UNIQUE INDEX [IX_fleet_assets_1] ON [fleet].[assets] ([tenant_id], [vin]) WHERE vin IS NOT NULL;
CREATE INDEX [IX_fleet_assets_2] ON [fleet].[assets] ([tenant_id], [asset_type_id]);
CREATE INDEX [IX_fleet_assets_3] ON [fleet].[assets] ([tenant_id], [terminal_id]);
CREATE INDEX [IX_fleet_assets_4] ON [fleet].[assets] ([tenant_id], [currency_code]);
CREATE INDEX [IX_fleet_assets_5] ON [fleet].[assets] ([tenant_id], [status], [terminal_id]);
ALTER TABLE [fleet].[vehicles] ADD CONSTRAINT [FK_fleet_vehicles_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fleet].[vehicles] ADD CONSTRAINT [FK_fleet_vehicles_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fleet].[vehicles] ADD CONSTRAINT [FK_fleet_vehicles_3] FOREIGN KEY ([plate_jurisdiction_id]) REFERENCES [ref].[jurisdictions] ([id]);
ALTER TABLE [fleet].[vehicles] ADD CONSTRAINT [FK_fleet_vehicles_4] FOREIGN KEY ([fuel_type_id]) REFERENCES [ref].[fuel_types] ([id]);
ALTER TABLE [fleet].[vehicles] ADD CONSTRAINT [FK_fleet_vehicles_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fleet].[vehicles] ADD CONSTRAINT [FK_fleet_vehicles_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fleet_vehicles_1] ON [fleet].[vehicles] ([tenant_id], [plate_jurisdiction_id]);
CREATE INDEX [IX_fleet_vehicles_2] ON [fleet].[vehicles] ([tenant_id], [fuel_type_id]);
ALTER TABLE [fleet].[trailers] ADD CONSTRAINT [FK_fleet_trailers_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fleet].[trailers] ADD CONSTRAINT [FK_fleet_trailers_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fleet].[trailers] ADD CONSTRAINT [FK_fleet_trailers_3] FOREIGN KEY ([trailer_type_id]) REFERENCES [ref].[trailer_types] ([id]);
ALTER TABLE [fleet].[trailers] ADD CONSTRAINT [FK_fleet_trailers_4] FOREIGN KEY ([plate_jurisdiction_id]) REFERENCES [ref].[jurisdictions] ([id]);
ALTER TABLE [fleet].[trailers] ADD CONSTRAINT [FK_fleet_trailers_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fleet].[trailers] ADD CONSTRAINT [FK_fleet_trailers_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fleet_trailers_1] ON [fleet].[trailers] ([tenant_id], [trailer_type_id]);
CREATE INDEX [IX_fleet_trailers_2] ON [fleet].[trailers] ([tenant_id], [plate_jurisdiction_id]);
ALTER TABLE [fleet].[asset_status_history] ADD CONSTRAINT [FK_fleet_asset_status_history_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fleet].[asset_status_history] ADD CONSTRAINT [FK_fleet_asset_status_history_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fleet].[asset_status_history] ADD CONSTRAINT [FK_fleet_asset_status_history_3] FOREIGN KEY ([actor_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_fleet_asset_status_history_1] ON [fleet].[asset_status_history] ([tenant_id], [asset_id]);
CREATE INDEX [IX_fleet_asset_status_history_2] ON [fleet].[asset_status_history] ([tenant_id], [actor_id]);
ALTER TABLE [fleet].[odometer_readings] ADD CONSTRAINT [FK_fleet_odometer_readings_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fleet].[odometer_readings] ADD CONSTRAINT [FK_fleet_odometer_readings_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fleet].[odometer_readings] ADD CONSTRAINT [FK_fleet_odometer_readings_3] FOREIGN KEY ([unit_id]) REFERENCES [ref].[units_of_measure] ([id]);
CREATE INDEX [IX_fleet_odometer_readings_1] ON [fleet].[odometer_readings] ([tenant_id], [asset_id]);
CREATE INDEX [IX_fleet_odometer_readings_2] ON [fleet].[odometer_readings] ([tenant_id], [unit_id]);
ALTER TABLE [fleet].[engine_hour_readings] ADD CONSTRAINT [FK_fleet_engine_hour_readings_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fleet].[engine_hour_readings] ADD CONSTRAINT [FK_fleet_engine_hour_readings_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
CREATE INDEX [IX_fleet_engine_hour_readings_1] ON [fleet].[engine_hour_readings] ([tenant_id], [asset_id]);
ALTER TABLE [fleet].[asset_availability] ADD CONSTRAINT [FK_fleet_asset_availability_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fleet].[asset_availability] ADD CONSTRAINT [FK_fleet_asset_availability_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fleet].[asset_availability] ADD CONSTRAINT [FK_fleet_asset_availability_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fleet].[asset_availability] ADD CONSTRAINT [FK_fleet_asset_availability_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fleet_asset_availability_1] ON [fleet].[asset_availability] ([tenant_id], [asset_id]);
ALTER TABLE [fleet].[ownership_agreements] ADD CONSTRAINT [FK_fleet_ownership_agreements_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fleet].[ownership_agreements] ADD CONSTRAINT [FK_fleet_ownership_agreements_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fleet].[ownership_agreements] ADD CONSTRAINT [FK_fleet_ownership_agreements_3] FOREIGN KEY ([tenant_id], [vendor_id]) REFERENCES [mnt].[vendors] ([tenant_id], [id]);
ALTER TABLE [fleet].[ownership_agreements] ADD CONSTRAINT [FK_fleet_ownership_agreements_4] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [fleet].[ownership_agreements] ADD CONSTRAINT [FK_fleet_ownership_agreements_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fleet].[ownership_agreements] ADD CONSTRAINT [FK_fleet_ownership_agreements_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fleet_ownership_agreements_1] ON [fleet].[ownership_agreements] ([tenant_id], [asset_id]);
CREATE INDEX [IX_fleet_ownership_agreements_2] ON [fleet].[ownership_agreements] ([tenant_id], [vendor_id]);
CREATE INDEX [IX_fleet_ownership_agreements_3] ON [fleet].[ownership_agreements] ([tenant_id], [currency_code]);
ALTER TABLE [fleet].[asset_meter_adjustments] ADD CONSTRAINT [FK_fleet_asset_meter_adjustments_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fleet].[asset_meter_adjustments] ADD CONSTRAINT [FK_fleet_asset_meter_adjustments_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fleet].[asset_meter_adjustments] ADD CONSTRAINT [FK_fleet_asset_meter_adjustments_3] FOREIGN KEY ([actor_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_fleet_asset_meter_adjustments_1] ON [fleet].[asset_meter_adjustments] ([tenant_id], [asset_id]);
CREATE INDEX [IX_fleet_asset_meter_adjustments_2] ON [fleet].[asset_meter_adjustments] ([tenant_id], [actor_id]);
ALTER TABLE [hr].[drivers] ADD CONSTRAINT [FK_hr_drivers_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [hr].[drivers] ADD CONSTRAINT [FK_hr_drivers_2] FOREIGN KEY ([tenant_id], [membership_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [hr].[drivers] ADD CONSTRAINT [FK_hr_drivers_3] FOREIGN KEY ([tenant_id], [terminal_id]) REFERENCES [core].[terminals] ([tenant_id], [id]);
ALTER TABLE [hr].[drivers] ADD CONSTRAINT [FK_hr_drivers_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [hr].[drivers] ADD CONSTRAINT [FK_hr_drivers_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_hr_drivers_1] ON [hr].[drivers] ([tenant_id], [membership_id]);
CREATE INDEX [IX_hr_drivers_2] ON [hr].[drivers] ([tenant_id], [terminal_id]);
CREATE INDEX [IX_hr_drivers_3] ON [hr].[drivers] ([tenant_id], [status], [driver_number]);
ALTER TABLE [hr].[driver_licenses] ADD CONSTRAINT [FK_hr_driver_licenses_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [hr].[driver_licenses] ADD CONSTRAINT [FK_hr_driver_licenses_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_licenses] ADD CONSTRAINT [FK_hr_driver_licenses_3] FOREIGN KEY ([jurisdiction_id]) REFERENCES [ref].[jurisdictions] ([id]);
ALTER TABLE [hr].[driver_licenses] ADD CONSTRAINT [FK_hr_driver_licenses_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_licenses] ADD CONSTRAINT [FK_hr_driver_licenses_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_hr_driver_licenses_1] ON [hr].[driver_licenses] ([tenant_id], [driver_id]);
CREATE INDEX [IX_hr_driver_licenses_2] ON [hr].[driver_licenses] ([tenant_id], [jurisdiction_id]);
ALTER TABLE [hr].[driver_endorsements] ADD CONSTRAINT [FK_hr_driver_endorsements_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [hr].[driver_endorsements] ADD CONSTRAINT [FK_hr_driver_endorsements_2] FOREIGN KEY ([tenant_id], [driver_license_id]) REFERENCES [hr].[driver_licenses] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_endorsements] ADD CONSTRAINT [FK_hr_driver_endorsements_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_endorsements] ADD CONSTRAINT [FK_hr_driver_endorsements_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_qualifications] ADD CONSTRAINT [FK_hr_driver_qualifications_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [hr].[driver_qualifications] ADD CONSTRAINT [FK_hr_driver_qualifications_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_qualifications] ADD CONSTRAINT [FK_hr_driver_qualifications_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_qualifications] ADD CONSTRAINT [FK_hr_driver_qualifications_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_hr_driver_qualifications_1] ON [hr].[driver_qualifications] ([tenant_id], [driver_id]);
ALTER TABLE [hr].[driver_availability] ADD CONSTRAINT [FK_hr_driver_availability_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [hr].[driver_availability] ADD CONSTRAINT [FK_hr_driver_availability_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_availability] ADD CONSTRAINT [FK_hr_driver_availability_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_availability] ADD CONSTRAINT [FK_hr_driver_availability_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_hr_driver_availability_1] ON [hr].[driver_availability] ([tenant_id], [driver_id]);
ALTER TABLE [hr].[driver_time_off] ADD CONSTRAINT [FK_hr_driver_time_off_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [hr].[driver_time_off] ADD CONSTRAINT [FK_hr_driver_time_off_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_time_off] ADD CONSTRAINT [FK_hr_driver_time_off_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_time_off] ADD CONSTRAINT [FK_hr_driver_time_off_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_hr_driver_time_off_1] ON [hr].[driver_time_off] ([tenant_id], [driver_id]);
ALTER TABLE [hr].[driver_emergency_contacts] ADD CONSTRAINT [FK_hr_driver_emergency_contacts_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [hr].[driver_emergency_contacts] ADD CONSTRAINT [FK_hr_driver_emergency_contacts_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_emergency_contacts] ADD CONSTRAINT [FK_hr_driver_emergency_contacts_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_emergency_contacts] ADD CONSTRAINT [FK_hr_driver_emergency_contacts_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_hr_driver_emergency_contacts_1] ON [hr].[driver_emergency_contacts] ([tenant_id], [driver_id]);
ALTER TABLE [hr].[driver_compensation_profiles] ADD CONSTRAINT [FK_hr_driver_compensation_profiles_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [hr].[driver_compensation_profiles] ADD CONSTRAINT [FK_hr_driver_compensation_profiles_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_compensation_profiles] ADD CONSTRAINT [FK_hr_driver_compensation_profiles_3] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [hr].[driver_compensation_profiles] ADD CONSTRAINT [FK_hr_driver_compensation_profiles_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_compensation_profiles] ADD CONSTRAINT [FK_hr_driver_compensation_profiles_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_hr_driver_compensation_profiles_1] ON [hr].[driver_compensation_profiles] ([tenant_id], [driver_id]);
CREATE INDEX [IX_hr_driver_compensation_profiles_2] ON [hr].[driver_compensation_profiles] ([tenant_id], [currency_code]);
ALTER TABLE [hr].[driver_status_history] ADD CONSTRAINT [FK_hr_driver_status_history_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [hr].[driver_status_history] ADD CONSTRAINT [FK_hr_driver_status_history_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [hr].[driver_status_history] ADD CONSTRAINT [FK_hr_driver_status_history_3] FOREIGN KEY ([actor_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_hr_driver_status_history_1] ON [hr].[driver_status_history] ([tenant_id], [driver_id]);
CREATE INDEX [IX_hr_driver_status_history_2] ON [hr].[driver_status_history] ([tenant_id], [actor_id]);
ALTER TABLE [crm].[customers] ADD CONSTRAINT [FK_crm_customers_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [crm].[customers] ADD CONSTRAINT [FK_crm_customers_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [crm].[customers] ADD CONSTRAINT [FK_crm_customers_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [crm].[customer_contacts] ADD CONSTRAINT [FK_crm_customer_contacts_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [crm].[customer_contacts] ADD CONSTRAINT [FK_crm_customer_contacts_2] FOREIGN KEY ([tenant_id], [customer_id]) REFERENCES [crm].[customers] ([tenant_id], [id]);
ALTER TABLE [crm].[customer_contacts] ADD CONSTRAINT [FK_crm_customer_contacts_3] FOREIGN KEY ([contact_type_id]) REFERENCES [ref].[contact_types] ([id]);
ALTER TABLE [crm].[customer_contacts] ADD CONSTRAINT [FK_crm_customer_contacts_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [crm].[customer_contacts] ADD CONSTRAINT [FK_crm_customer_contacts_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_crm_customer_contacts_1] ON [crm].[customer_contacts] ([tenant_id], [customer_id]);
CREATE INDEX [IX_crm_customer_contacts_2] ON [crm].[customer_contacts] ([tenant_id], [contact_type_id]);
ALTER TABLE [crm].[locations] ADD CONSTRAINT [FK_crm_locations_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [crm].[locations] ADD CONSTRAINT [FK_crm_locations_2] FOREIGN KEY ([tenant_id], [customer_id]) REFERENCES [crm].[customers] ([tenant_id], [id]);
ALTER TABLE [crm].[locations] ADD CONSTRAINT [FK_crm_locations_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [crm].[locations] ADD CONSTRAINT [FK_crm_locations_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_crm_locations_1] ON [crm].[locations] ([tenant_id], [customer_id]);
ALTER TABLE [crm].[customer_contracts] ADD CONSTRAINT [FK_crm_customer_contracts_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [crm].[customer_contracts] ADD CONSTRAINT [FK_crm_customer_contracts_2] FOREIGN KEY ([tenant_id], [customer_id]) REFERENCES [crm].[customers] ([tenant_id], [id]);
ALTER TABLE [crm].[customer_contracts] ADD CONSTRAINT [FK_crm_customer_contracts_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [crm].[customer_contracts] ADD CONSTRAINT [FK_crm_customer_contracts_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_crm_customer_contracts_1] ON [crm].[customer_contracts] ([tenant_id], [customer_id]);
ALTER TABLE [crm].[customer_rate_agreements] ADD CONSTRAINT [FK_crm_customer_rate_agreements_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [crm].[customer_rate_agreements] ADD CONSTRAINT [FK_crm_customer_rate_agreements_2] FOREIGN KEY ([tenant_id], [contract_id]) REFERENCES [crm].[customer_contracts] ([tenant_id], [id]);
ALTER TABLE [crm].[customer_rate_agreements] ADD CONSTRAINT [FK_crm_customer_rate_agreements_3] FOREIGN KEY ([equipment_type_id]) REFERENCES [ref].[asset_types] ([id]);
ALTER TABLE [crm].[customer_rate_agreements] ADD CONSTRAINT [FK_crm_customer_rate_agreements_4] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [crm].[customer_rate_agreements] ADD CONSTRAINT [FK_crm_customer_rate_agreements_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [crm].[customer_rate_agreements] ADD CONSTRAINT [FK_crm_customer_rate_agreements_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_crm_customer_rate_agreements_1] ON [crm].[customer_rate_agreements] ([tenant_id], [contract_id]);
CREATE INDEX [IX_crm_customer_rate_agreements_2] ON [crm].[customer_rate_agreements] ([tenant_id], [equipment_type_id]);
CREATE INDEX [IX_crm_customer_rate_agreements_3] ON [crm].[customer_rate_agreements] ([tenant_id], [currency_code]);
ALTER TABLE [crm].[customer_notes] ADD CONSTRAINT [FK_crm_customer_notes_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [crm].[customer_notes] ADD CONSTRAINT [FK_crm_customer_notes_2] FOREIGN KEY ([tenant_id], [customer_id]) REFERENCES [crm].[customers] ([tenant_id], [id]);
ALTER TABLE [crm].[customer_notes] ADD CONSTRAINT [FK_crm_customer_notes_3] FOREIGN KEY ([author_id]) REFERENCES [iam].[users] ([id]);
ALTER TABLE [crm].[customer_notes] ADD CONSTRAINT [FK_crm_customer_notes_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [crm].[customer_notes] ADD CONSTRAINT [FK_crm_customer_notes_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_crm_customer_notes_1] ON [crm].[customer_notes] ([tenant_id], [customer_id]);
CREATE INDEX [IX_crm_customer_notes_2] ON [crm].[customer_notes] ([tenant_id], [author_id]);
ALTER TABLE [ops].[loads] ADD CONSTRAINT [FK_ops_loads_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[loads] ADD CONSTRAINT [FK_ops_loads_2] FOREIGN KEY ([tenant_id], [customer_id]) REFERENCES [crm].[customers] ([tenant_id], [id]);
ALTER TABLE [ops].[loads] ADD CONSTRAINT [FK_ops_loads_3] FOREIGN KEY ([equipment_type_id]) REFERENCES [ref].[asset_types] ([id]);
ALTER TABLE [ops].[loads] ADD CONSTRAINT [FK_ops_loads_4] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [ops].[loads] ADD CONSTRAINT [FK_ops_loads_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[loads] ADD CONSTRAINT [FK_ops_loads_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ops_loads_1] ON [ops].[loads] ([tenant_id], [customer_id]);
CREATE INDEX [IX_ops_loads_2] ON [ops].[loads] ([tenant_id], [equipment_type_id]);
CREATE INDEX [IX_ops_loads_3] ON [ops].[loads] ([tenant_id], [currency_code]);
CREATE INDEX [IX_ops_loads_4] ON [ops].[loads] ([tenant_id], [commercial_status], [created_at]);
ALTER TABLE [ops].[load_stops] ADD CONSTRAINT [FK_ops_load_stops_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[load_stops] ADD CONSTRAINT [FK_ops_load_stops_2] FOREIGN KEY ([tenant_id], [load_id]) REFERENCES [ops].[loads] ([tenant_id], [id]);
ALTER TABLE [ops].[load_stops] ADD CONSTRAINT [FK_ops_load_stops_3] FOREIGN KEY ([tenant_id], [location_id]) REFERENCES [crm].[locations] ([tenant_id], [id]);
ALTER TABLE [ops].[load_stops] ADD CONSTRAINT [FK_ops_load_stops_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[load_stops] ADD CONSTRAINT [FK_ops_load_stops_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ops_load_stops_1] ON [ops].[load_stops] ([tenant_id], [location_id]);
ALTER TABLE [ops].[load_status_history] ADD CONSTRAINT [FK_ops_load_status_history_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[load_status_history] ADD CONSTRAINT [FK_ops_load_status_history_2] FOREIGN KEY ([tenant_id], [load_id]) REFERENCES [ops].[loads] ([tenant_id], [id]);
ALTER TABLE [ops].[load_status_history] ADD CONSTRAINT [FK_ops_load_status_history_3] FOREIGN KEY ([actor_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_ops_load_status_history_1] ON [ops].[load_status_history] ([tenant_id], [load_id]);
CREATE INDEX [IX_ops_load_status_history_2] ON [ops].[load_status_history] ([tenant_id], [actor_id]);
ALTER TABLE [ops].[trips] ADD CONSTRAINT [FK_ops_trips_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[trips] ADD CONSTRAINT [FK_ops_trips_2] FOREIGN KEY ([tenant_id], [dispatcher_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trips] ADD CONSTRAINT [FK_ops_trips_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trips] ADD CONSTRAINT [FK_ops_trips_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ops_trips_1] ON [ops].[trips] ([tenant_id], [dispatcher_id]);
CREATE INDEX [IX_ops_trips_2] ON [ops].[trips] ([tenant_id], [status], [planned_start_at]);
ALTER TABLE [ops].[trip_loads] ADD CONSTRAINT [FK_ops_trip_loads_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[trip_loads] ADD CONSTRAINT [FK_ops_trip_loads_2] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_loads] ADD CONSTRAINT [FK_ops_trip_loads_3] FOREIGN KEY ([tenant_id], [load_id]) REFERENCES [ops].[loads] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_loads] ADD CONSTRAINT [FK_ops_trip_loads_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_loads] ADD CONSTRAINT [FK_ops_trip_loads_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ops_trip_loads_1] ON [ops].[trip_loads] ([tenant_id], [load_id]);
ALTER TABLE [ops].[trip_stops] ADD CONSTRAINT [FK_ops_trip_stops_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[trip_stops] ADD CONSTRAINT [FK_ops_trip_stops_2] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_stops] ADD CONSTRAINT [FK_ops_trip_stops_3] FOREIGN KEY ([tenant_id], [load_stop_id]) REFERENCES [ops].[load_stops] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_stops] ADD CONSTRAINT [FK_ops_trip_stops_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_stops] ADD CONSTRAINT [FK_ops_trip_stops_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ops_trip_stops_1] ON [ops].[trip_stops] ([tenant_id], [load_stop_id]);
ALTER TABLE [ops].[trip_assignments] ADD CONSTRAINT [FK_ops_trip_assignments_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[trip_assignments] ADD CONSTRAINT [FK_ops_trip_assignments_2] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_assignments] ADD CONSTRAINT [FK_ops_trip_assignments_3] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_assignments] ADD CONSTRAINT [FK_ops_trip_assignments_4] FOREIGN KEY ([tenant_id], [vehicle_id]) REFERENCES [fleet].[vehicles] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_assignments] ADD CONSTRAINT [FK_ops_trip_assignments_5] FOREIGN KEY ([tenant_id], [trailer_id]) REFERENCES [fleet].[trailers] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_assignments] ADD CONSTRAINT [FK_ops_trip_assignments_6] FOREIGN KEY ([tenant_id], [assigned_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_assignments] ADD CONSTRAINT [FK_ops_trip_assignments_7] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_assignments] ADD CONSTRAINT [FK_ops_trip_assignments_8] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ops_trip_assignments_1] ON [ops].[trip_assignments] ([tenant_id], [trip_id]);
CREATE INDEX [IX_ops_trip_assignments_2] ON [ops].[trip_assignments] ([tenant_id], [driver_id]);
CREATE INDEX [IX_ops_trip_assignments_3] ON [ops].[trip_assignments] ([tenant_id], [vehicle_id]);
CREATE INDEX [IX_ops_trip_assignments_4] ON [ops].[trip_assignments] ([tenant_id], [trailer_id]);
CREATE INDEX [IX_ops_trip_assignments_5] ON [ops].[trip_assignments] ([tenant_id], [assigned_by]);
ALTER TABLE [ops].[equipment_reservations] ADD CONSTRAINT [FK_ops_equipment_reservations_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[equipment_reservations] ADD CONSTRAINT [FK_ops_equipment_reservations_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [ops].[equipment_reservations] ADD CONSTRAINT [FK_ops_equipment_reservations_3] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [ops].[equipment_reservations] ADD CONSTRAINT [FK_ops_equipment_reservations_4] FOREIGN KEY ([tenant_id], [assignment_id]) REFERENCES [ops].[trip_assignments] ([tenant_id], [id]);
ALTER TABLE [ops].[equipment_reservations] ADD CONSTRAINT [FK_ops_equipment_reservations_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[equipment_reservations] ADD CONSTRAINT [FK_ops_equipment_reservations_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ops_equipment_reservations_1] ON [ops].[equipment_reservations] ([tenant_id], [asset_id]);
CREATE INDEX [IX_ops_equipment_reservations_2] ON [ops].[equipment_reservations] ([tenant_id], [trip_id]);
CREATE INDEX [IX_ops_equipment_reservations_3] ON [ops].[equipment_reservations] ([tenant_id], [assignment_id]);
CREATE INDEX [IX_ops_equipment_reservations_4] ON [ops].[equipment_reservations] ([tenant_id], [asset_id], [status], [start_at], [end_at]);
ALTER TABLE [ops].[driver_reservations] ADD CONSTRAINT [FK_ops_driver_reservations_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[driver_reservations] ADD CONSTRAINT [FK_ops_driver_reservations_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [ops].[driver_reservations] ADD CONSTRAINT [FK_ops_driver_reservations_3] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [ops].[driver_reservations] ADD CONSTRAINT [FK_ops_driver_reservations_4] FOREIGN KEY ([tenant_id], [assignment_id]) REFERENCES [ops].[trip_assignments] ([tenant_id], [id]);
ALTER TABLE [ops].[driver_reservations] ADD CONSTRAINT [FK_ops_driver_reservations_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[driver_reservations] ADD CONSTRAINT [FK_ops_driver_reservations_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ops_driver_reservations_1] ON [ops].[driver_reservations] ([tenant_id], [driver_id]);
CREATE INDEX [IX_ops_driver_reservations_2] ON [ops].[driver_reservations] ([tenant_id], [trip_id]);
CREATE INDEX [IX_ops_driver_reservations_3] ON [ops].[driver_reservations] ([tenant_id], [assignment_id]);
CREATE INDEX [IX_ops_driver_reservations_4] ON [ops].[driver_reservations] ([tenant_id], [driver_id], [status], [start_at], [end_at]);
ALTER TABLE [ops].[trip_events] ADD CONSTRAINT [FK_ops_trip_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[trip_events] ADD CONSTRAINT [FK_ops_trip_events_2] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_events] ADD CONSTRAINT [FK_ops_trip_events_3] FOREIGN KEY ([actor_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_ops_trip_events_1] ON [ops].[trip_events] ([tenant_id], [actor_id]);
ALTER TABLE [ops].[trip_exceptions] ADD CONSTRAINT [FK_ops_trip_exceptions_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[trip_exceptions] ADD CONSTRAINT [FK_ops_trip_exceptions_2] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_exceptions] ADD CONSTRAINT [FK_ops_trip_exceptions_3] FOREIGN KEY ([exception_type_id]) REFERENCES [ref].[exception_types] ([id]);
ALTER TABLE [ops].[trip_exceptions] ADD CONSTRAINT [FK_ops_trip_exceptions_4] FOREIGN KEY ([tenant_id], [owner_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_exceptions] ADD CONSTRAINT [FK_ops_trip_exceptions_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_exceptions] ADD CONSTRAINT [FK_ops_trip_exceptions_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ops_trip_exceptions_1] ON [ops].[trip_exceptions] ([tenant_id], [trip_id]);
CREATE INDEX [IX_ops_trip_exceptions_2] ON [ops].[trip_exceptions] ([tenant_id], [exception_type_id]);
CREATE INDEX [IX_ops_trip_exceptions_3] ON [ops].[trip_exceptions] ([tenant_id], [owner_id]);
ALTER TABLE [ops].[trip_distances] ADD CONSTRAINT [FK_ops_trip_distances_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[trip_distances] ADD CONSTRAINT [FK_ops_trip_distances_2] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_distances] ADD CONSTRAINT [FK_ops_trip_distances_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_distances] ADD CONSTRAINT [FK_ops_trip_distances_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_status_history] ADD CONSTRAINT [FK_ops_trip_status_history_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[trip_status_history] ADD CONSTRAINT [FK_ops_trip_status_history_2] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_status_history] ADD CONSTRAINT [FK_ops_trip_status_history_3] FOREIGN KEY ([actor_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_ops_trip_status_history_1] ON [ops].[trip_status_history] ([tenant_id], [trip_id]);
CREATE INDEX [IX_ops_trip_status_history_2] ON [ops].[trip_status_history] ([tenant_id], [actor_id]);
ALTER TABLE [ops].[delivery_confirmations] ADD CONSTRAINT [FK_ops_delivery_confirmations_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[delivery_confirmations] ADD CONSTRAINT [FK_ops_delivery_confirmations_2] FOREIGN KEY ([tenant_id], [trip_stop_id]) REFERENCES [ops].[trip_stops] ([tenant_id], [id]);
ALTER TABLE [ops].[delivery_confirmations] ADD CONSTRAINT [FK_ops_delivery_confirmations_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[delivery_confirmations] ADD CONSTRAINT [FK_ops_delivery_confirmations_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_exception_events] ADD CONSTRAINT [FK_ops_trip_exception_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ops].[trip_exception_events] ADD CONSTRAINT [FK_ops_trip_exception_events_2] FOREIGN KEY ([tenant_id], [exception_id]) REFERENCES [ops].[trip_exceptions] ([tenant_id], [id]);
ALTER TABLE [ops].[trip_exception_events] ADD CONSTRAINT [FK_ops_trip_exception_events_3] FOREIGN KEY ([actor_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_ops_trip_exception_events_1] ON [ops].[trip_exception_events] ([tenant_id], [exception_id]);
CREATE INDEX [IX_ops_trip_exception_events_2] ON [ops].[trip_exception_events] ([tenant_id], [actor_id]);
ALTER TABLE [integration].[connections] ADD CONSTRAINT [FK_integration_connections_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [integration].[connections] ADD CONSTRAINT [FK_integration_connections_2] FOREIGN KEY ([provider_id]) REFERENCES [integration].[providers] ([id]);
ALTER TABLE [integration].[connections] ADD CONSTRAINT [FK_integration_connections_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[connections] ADD CONSTRAINT [FK_integration_connections_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_integration_connections_1] ON [integration].[connections] ([tenant_id], [provider_id]);
ALTER TABLE [integration].[external_mappings] ADD CONSTRAINT [FK_integration_external_mappings_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [integration].[external_mappings] ADD CONSTRAINT [FK_integration_external_mappings_2] FOREIGN KEY ([tenant_id], [connection_id]) REFERENCES [integration].[connections] ([tenant_id], [id]);
ALTER TABLE [integration].[external_mappings] ADD CONSTRAINT [FK_integration_external_mappings_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[external_mappings] ADD CONSTRAINT [FK_integration_external_mappings_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[sync_jobs] ADD CONSTRAINT [FK_integration_sync_jobs_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [integration].[sync_jobs] ADD CONSTRAINT [FK_integration_sync_jobs_2] FOREIGN KEY ([tenant_id], [connection_id]) REFERENCES [integration].[connections] ([tenant_id], [id]);
ALTER TABLE [integration].[sync_jobs] ADD CONSTRAINT [FK_integration_sync_jobs_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[sync_jobs] ADD CONSTRAINT [FK_integration_sync_jobs_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_integration_sync_jobs_1] ON [integration].[sync_jobs] ([tenant_id], [connection_id]);
ALTER TABLE [integration].[sync_checkpoints] ADD CONSTRAINT [FK_integration_sync_checkpoints_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [integration].[sync_checkpoints] ADD CONSTRAINT [FK_integration_sync_checkpoints_2] FOREIGN KEY ([tenant_id], [connection_id]) REFERENCES [integration].[connections] ([tenant_id], [id]);
ALTER TABLE [integration].[sync_checkpoints] ADD CONSTRAINT [FK_integration_sync_checkpoints_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[sync_checkpoints] ADD CONSTRAINT [FK_integration_sync_checkpoints_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[webhook_events] ADD CONSTRAINT [FK_integration_webhook_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [integration].[webhook_events] ADD CONSTRAINT [FK_integration_webhook_events_2] FOREIGN KEY ([tenant_id], [connection_id]) REFERENCES [integration].[connections] ([tenant_id], [id]);
ALTER TABLE [integration].[webhook_events] ADD CONSTRAINT [FK_integration_webhook_events_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[webhook_events] ADD CONSTRAINT [FK_integration_webhook_events_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[processing_failures] ADD CONSTRAINT [FK_integration_processing_failures_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [integration].[processing_failures] ADD CONSTRAINT [FK_integration_processing_failures_2] FOREIGN KEY ([tenant_id], [sync_job_id]) REFERENCES [integration].[sync_jobs] ([tenant_id], [id]);
ALTER TABLE [integration].[processing_failures] ADD CONSTRAINT [FK_integration_processing_failures_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[processing_failures] ADD CONSTRAINT [FK_integration_processing_failures_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_integration_processing_failures_1] ON [integration].[processing_failures] ([tenant_id], [sync_job_id]);
ALTER TABLE [integration].[import_batches] ADD CONSTRAINT [FK_integration_import_batches_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [integration].[import_batches] ADD CONSTRAINT [FK_integration_import_batches_2] FOREIGN KEY ([imported_by]) REFERENCES [iam].[users] ([id]);
ALTER TABLE [integration].[import_batches] ADD CONSTRAINT [FK_integration_import_batches_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[import_batches] ADD CONSTRAINT [FK_integration_import_batches_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_integration_import_batches_1] ON [integration].[import_batches] ([tenant_id], [imported_by]);
ALTER TABLE [integration].[import_errors] ADD CONSTRAINT [FK_integration_import_errors_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [integration].[import_errors] ADD CONSTRAINT [FK_integration_import_errors_2] FOREIGN KEY ([tenant_id], [batch_id]) REFERENCES [integration].[import_batches] ([tenant_id], [id]);
CREATE INDEX [IX_integration_import_errors_1] ON [integration].[import_errors] ([tenant_id], [batch_id]);
ALTER TABLE [integration].[outbox_events] ADD CONSTRAINT [FK_integration_outbox_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [integration].[outbox_events] ADD CONSTRAINT [FK_integration_outbox_events_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[outbox_events] ADD CONSTRAINT [FK_integration_outbox_events_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_integration_outbox_events_1] ON [integration].[outbox_events] ([tenant_id], [publication_status], [created_at]);
ALTER TABLE [integration].[idempotency_keys] ADD CONSTRAINT [FK_integration_idempotency_keys_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [integration].[idempotency_keys] ADD CONSTRAINT [FK_integration_idempotency_keys_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [integration].[idempotency_keys] ADD CONSTRAINT [FK_integration_idempotency_keys_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [gps].[devices] ADD CONSTRAINT [FK_gps_devices_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [gps].[devices] ADD CONSTRAINT [FK_gps_devices_2] FOREIGN KEY ([tenant_id], [connection_id]) REFERENCES [integration].[connections] ([tenant_id], [id]);
ALTER TABLE [gps].[devices] ADD CONSTRAINT [FK_gps_devices_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [gps].[devices] ADD CONSTRAINT [FK_gps_devices_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [gps].[device_assignments] ADD CONSTRAINT [FK_gps_device_assignments_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [gps].[device_assignments] ADD CONSTRAINT [FK_gps_device_assignments_2] FOREIGN KEY ([tenant_id], [device_id]) REFERENCES [gps].[devices] ([tenant_id], [id]);
ALTER TABLE [gps].[device_assignments] ADD CONSTRAINT [FK_gps_device_assignments_3] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [gps].[device_assignments] ADD CONSTRAINT [FK_gps_device_assignments_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [gps].[device_assignments] ADD CONSTRAINT [FK_gps_device_assignments_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_gps_device_assignments_1] ON [gps].[device_assignments] ([tenant_id], [device_id]);
CREATE INDEX [IX_gps_device_assignments_2] ON [gps].[device_assignments] ([tenant_id], [asset_id]);
ALTER TABLE [gps].[vehicle_positions] ADD CONSTRAINT [FK_gps_vehicle_positions_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [gps].[vehicle_positions] ADD CONSTRAINT [FK_gps_vehicle_positions_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [gps].[vehicle_positions] ADD CONSTRAINT [FK_gps_vehicle_positions_3] FOREIGN KEY ([tenant_id], [device_id]) REFERENCES [gps].[devices] ([tenant_id], [id]);
CREATE INDEX [IX_gps_vehicle_positions_1] ON [gps].[vehicle_positions] ([tenant_id], [asset_id]);
CREATE INDEX [IX_gps_vehicle_positions_2] ON [gps].[vehicle_positions] ([tenant_id], [asset_id], [recorded_at]);
ALTER TABLE [gps].[latest_vehicle_positions] ADD CONSTRAINT [FK_gps_latest_vehicle_positions_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [gps].[latest_vehicle_positions] ADD CONSTRAINT [FK_gps_latest_vehicle_positions_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [gps].[latest_vehicle_positions] ADD CONSTRAINT [FK_gps_latest_vehicle_positions_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [gps].[latest_vehicle_positions] ADD CONSTRAINT [FK_gps_latest_vehicle_positions_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [gps].[latest_vehicle_positions] ADD CONSTRAINT [FK_gps_latest_vehicle_positions_5] FOREIGN KEY ([tenant_id], [asset_id], [position_id]) REFERENCES [gps].[vehicle_positions] ([tenant_id], [asset_id], [id]);
CREATE INDEX [IX_gps_latest_vehicle_positions_1] ON [gps].[latest_vehicle_positions] ([tenant_id], [position_id]);
ALTER TABLE [gps].[telemetry_events] ADD CONSTRAINT [FK_gps_telemetry_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [gps].[telemetry_events] ADD CONSTRAINT [FK_gps_telemetry_events_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
CREATE INDEX [IX_gps_telemetry_events_1] ON [gps].[telemetry_events] ([tenant_id], [asset_id]);
ALTER TABLE [gps].[geofences] ADD CONSTRAINT [FK_gps_geofences_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [gps].[geofences] ADD CONSTRAINT [FK_gps_geofences_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [gps].[geofences] ADD CONSTRAINT [FK_gps_geofences_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [gps].[geofence_events] ADD CONSTRAINT [FK_gps_geofence_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [gps].[geofence_events] ADD CONSTRAINT [FK_gps_geofence_events_2] FOREIGN KEY ([tenant_id], [geofence_id]) REFERENCES [gps].[geofences] ([tenant_id], [id]);
ALTER TABLE [gps].[geofence_events] ADD CONSTRAINT [FK_gps_geofence_events_3] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
CREATE INDEX [IX_gps_geofence_events_1] ON [gps].[geofence_events] ([tenant_id], [geofence_id]);
CREATE INDEX [IX_gps_geofence_events_2] ON [gps].[geofence_events] ([tenant_id], [asset_id]);
ALTER TABLE [gps].[vehicle_fault_codes] ADD CONSTRAINT [FK_gps_vehicle_fault_codes_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [gps].[vehicle_fault_codes] ADD CONSTRAINT [FK_gps_vehicle_fault_codes_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [gps].[vehicle_fault_codes] ADD CONSTRAINT [FK_gps_vehicle_fault_codes_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [gps].[vehicle_fault_codes] ADD CONSTRAINT [FK_gps_vehicle_fault_codes_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_gps_vehicle_fault_codes_1] ON [gps].[vehicle_fault_codes] ([tenant_id], [asset_id]);
ALTER TABLE [gps].[idle_sessions] ADD CONSTRAINT [FK_gps_idle_sessions_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [gps].[idle_sessions] ADD CONSTRAINT [FK_gps_idle_sessions_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
CREATE INDEX [IX_gps_idle_sessions_1] ON [gps].[idle_sessions] ([tenant_id], [asset_id]);
ALTER TABLE [mnt].[service_types] ADD CONSTRAINT [FK_mnt_service_types_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[service_types] ADD CONSTRAINT [FK_mnt_service_types_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[service_types] ADD CONSTRAINT [FK_mnt_service_types_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[maintenance_schedules] ADD CONSTRAINT [FK_mnt_maintenance_schedules_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[maintenance_schedules] ADD CONSTRAINT [FK_mnt_maintenance_schedules_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [mnt].[maintenance_schedules] ADD CONSTRAINT [FK_mnt_maintenance_schedules_3] FOREIGN KEY ([tenant_id], [service_type_id]) REFERENCES [mnt].[service_types] ([tenant_id], [id]);
ALTER TABLE [mnt].[maintenance_schedules] ADD CONSTRAINT [FK_mnt_maintenance_schedules_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[maintenance_schedules] ADD CONSTRAINT [FK_mnt_maintenance_schedules_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_maintenance_schedules_1] ON [mnt].[maintenance_schedules] ([tenant_id], [asset_id]);
CREATE INDEX [IX_mnt_maintenance_schedules_2] ON [mnt].[maintenance_schedules] ([tenant_id], [service_type_id]);
ALTER TABLE [mnt].[scheduled_services] ADD CONSTRAINT [FK_mnt_scheduled_services_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[scheduled_services] ADD CONSTRAINT [FK_mnt_scheduled_services_2] FOREIGN KEY ([tenant_id], [schedule_id]) REFERENCES [mnt].[maintenance_schedules] ([tenant_id], [id]);
ALTER TABLE [mnt].[scheduled_services] ADD CONSTRAINT [FK_mnt_scheduled_services_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[scheduled_services] ADD CONSTRAINT [FK_mnt_scheduled_services_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_scheduled_services_1] ON [mnt].[scheduled_services] ([tenant_id], [schedule_id]);
CREATE INDEX [IX_mnt_scheduled_services_2] ON [mnt].[scheduled_services] ([tenant_id], [status], [due_date]);
ALTER TABLE [mnt].[service_records] ADD CONSTRAINT [FK_mnt_service_records_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[service_records] ADD CONSTRAINT [FK_mnt_service_records_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [mnt].[service_records] ADD CONSTRAINT [FK_mnt_service_records_3] FOREIGN KEY ([tenant_id], [service_type_id]) REFERENCES [mnt].[service_types] ([tenant_id], [id]);
ALTER TABLE [mnt].[service_records] ADD CONSTRAINT [FK_mnt_service_records_4] FOREIGN KEY ([tenant_id], [vendor_id]) REFERENCES [mnt].[vendors] ([tenant_id], [id]);
ALTER TABLE [mnt].[service_records] ADD CONSTRAINT [FK_mnt_service_records_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[service_records] ADD CONSTRAINT [FK_mnt_service_records_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_service_records_1] ON [mnt].[service_records] ([tenant_id], [asset_id]);
CREATE INDEX [IX_mnt_service_records_2] ON [mnt].[service_records] ([tenant_id], [service_type_id]);
CREATE INDEX [IX_mnt_service_records_3] ON [mnt].[service_records] ([tenant_id], [vendor_id]);
ALTER TABLE [mnt].[maintenance_restrictions] ADD CONSTRAINT [FK_mnt_maintenance_restrictions_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[maintenance_restrictions] ADD CONSTRAINT [FK_mnt_maintenance_restrictions_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [mnt].[maintenance_restrictions] ADD CONSTRAINT [FK_mnt_maintenance_restrictions_3] FOREIGN KEY ([tenant_id], [release_approved_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[maintenance_restrictions] ADD CONSTRAINT [FK_mnt_maintenance_restrictions_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[maintenance_restrictions] ADD CONSTRAINT [FK_mnt_maintenance_restrictions_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_maintenance_restrictions_1] ON [mnt].[maintenance_restrictions] ([tenant_id], [asset_id]);
CREATE INDEX [IX_mnt_maintenance_restrictions_2] ON [mnt].[maintenance_restrictions] ([tenant_id], [release_approved_by]);
ALTER TABLE [mnt].[vendors] ADD CONSTRAINT [FK_mnt_vendors_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[vendors] ADD CONSTRAINT [FK_mnt_vendors_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[vendors] ADD CONSTRAINT [FK_mnt_vendors_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[work_orders] ADD CONSTRAINT [FK_mnt_work_orders_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[work_orders] ADD CONSTRAINT [FK_mnt_work_orders_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [mnt].[work_orders] ADD CONSTRAINT [FK_mnt_work_orders_3] FOREIGN KEY ([tenant_id], [vendor_id]) REFERENCES [mnt].[vendors] ([tenant_id], [id]);
ALTER TABLE [mnt].[work_orders] ADD CONSTRAINT [FK_mnt_work_orders_4] FOREIGN KEY ([maintenance_type_id]) REFERENCES [ref].[maintenance_types] ([id]);
ALTER TABLE [mnt].[work_orders] ADD CONSTRAINT [FK_mnt_work_orders_5] FOREIGN KEY ([tenant_id], [approved_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[work_orders] ADD CONSTRAINT [FK_mnt_work_orders_6] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[work_orders] ADD CONSTRAINT [FK_mnt_work_orders_7] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_work_orders_1] ON [mnt].[work_orders] ([tenant_id], [asset_id]);
CREATE INDEX [IX_mnt_work_orders_2] ON [mnt].[work_orders] ([tenant_id], [vendor_id]);
CREATE INDEX [IX_mnt_work_orders_3] ON [mnt].[work_orders] ([tenant_id], [maintenance_type_id]);
CREATE INDEX [IX_mnt_work_orders_4] ON [mnt].[work_orders] ([tenant_id], [approved_by]);
ALTER TABLE [mnt].[work_order_items] ADD CONSTRAINT [FK_mnt_work_order_items_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[work_order_items] ADD CONSTRAINT [FK_mnt_work_order_items_2] FOREIGN KEY ([tenant_id], [work_order_id]) REFERENCES [mnt].[work_orders] ([tenant_id], [id]);
ALTER TABLE [mnt].[work_order_items] ADD CONSTRAINT [FK_mnt_work_order_items_3] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [mnt].[work_order_items] ADD CONSTRAINT [FK_mnt_work_order_items_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[work_order_items] ADD CONSTRAINT [FK_mnt_work_order_items_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_work_order_items_1] ON [mnt].[work_order_items] ([tenant_id], [work_order_id]);
CREATE INDEX [IX_mnt_work_order_items_2] ON [mnt].[work_order_items] ([tenant_id], [currency_code]);
ALTER TABLE [mnt].[defects] ADD CONSTRAINT [FK_mnt_defects_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[defects] ADD CONSTRAINT [FK_mnt_defects_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [mnt].[defects] ADD CONSTRAINT [FK_mnt_defects_3] FOREIGN KEY ([tenant_id], [inspection_id]) REFERENCES [compliance].[inspections] ([tenant_id], [id]);
ALTER TABLE [mnt].[defects] ADD CONSTRAINT [FK_mnt_defects_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[defects] ADD CONSTRAINT [FK_mnt_defects_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_defects_1] ON [mnt].[defects] ([tenant_id], [asset_id]);
CREATE INDEX [IX_mnt_defects_2] ON [mnt].[defects] ([tenant_id], [inspection_id]);
ALTER TABLE [mnt].[parts] ADD CONSTRAINT [FK_mnt_parts_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[parts] ADD CONSTRAINT [FK_mnt_parts_2] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [mnt].[parts] ADD CONSTRAINT [FK_mnt_parts_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[parts] ADD CONSTRAINT [FK_mnt_parts_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_parts_1] ON [mnt].[parts] ([tenant_id], [currency_code]);
ALTER TABLE [mnt].[parts_inventory] ADD CONSTRAINT [FK_mnt_parts_inventory_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[parts_inventory] ADD CONSTRAINT [FK_mnt_parts_inventory_2] FOREIGN KEY ([tenant_id], [part_id]) REFERENCES [mnt].[parts] ([tenant_id], [id]);
ALTER TABLE [mnt].[parts_inventory] ADD CONSTRAINT [FK_mnt_parts_inventory_3] FOREIGN KEY ([tenant_id], [terminal_id]) REFERENCES [core].[terminals] ([tenant_id], [id]);
ALTER TABLE [mnt].[parts_inventory] ADD CONSTRAINT [FK_mnt_parts_inventory_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[parts_inventory] ADD CONSTRAINT [FK_mnt_parts_inventory_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_parts_inventory_1] ON [mnt].[parts_inventory] ([tenant_id], [terminal_id]);
ALTER TABLE [mnt].[tire_records] ADD CONSTRAINT [FK_mnt_tire_records_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[tire_records] ADD CONSTRAINT [FK_mnt_tire_records_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [mnt].[tire_records] ADD CONSTRAINT [FK_mnt_tire_records_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[tire_records] ADD CONSTRAINT [FK_mnt_tire_records_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_tire_records_1] ON [mnt].[tire_records] ([tenant_id], [asset_id]);
ALTER TABLE [mnt].[downtime_events] ADD CONSTRAINT [FK_mnt_downtime_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [mnt].[downtime_events] ADD CONSTRAINT [FK_mnt_downtime_events_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [mnt].[downtime_events] ADD CONSTRAINT [FK_mnt_downtime_events_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [mnt].[downtime_events] ADD CONSTRAINT [FK_mnt_downtime_events_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_mnt_downtime_events_1] ON [mnt].[downtime_events] ([tenant_id], [asset_id]);
ALTER TABLE [fuel].[fuel_transactions] ADD CONSTRAINT [FK_fuel_fuel_transactions_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fuel].[fuel_transactions] ADD CONSTRAINT [FK_fuel_fuel_transactions_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_transactions] ADD CONSTRAINT [FK_fuel_fuel_transactions_3] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_transactions] ADD CONSTRAINT [FK_fuel_fuel_transactions_4] FOREIGN KEY ([fuel_type_id]) REFERENCES [ref].[fuel_types] ([id]);
ALTER TABLE [fuel].[fuel_transactions] ADD CONSTRAINT [FK_fuel_fuel_transactions_5] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [fuel].[fuel_transactions] ADD CONSTRAINT [FK_fuel_fuel_transactions_6] FOREIGN KEY ([jurisdiction_id]) REFERENCES [ref].[jurisdictions] ([id]);
ALTER TABLE [fuel].[fuel_transactions] ADD CONSTRAINT [FK_fuel_fuel_transactions_7] FOREIGN KEY ([tenant_id], [connection_id]) REFERENCES [integration].[connections] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_transactions] ADD CONSTRAINT [FK_fuel_fuel_transactions_8] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_transactions] ADD CONSTRAINT [FK_fuel_fuel_transactions_9] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE UNIQUE INDEX [IX_fuel_fuel_transactions_1] ON [fuel].[fuel_transactions] ([tenant_id], [connection_id], [external_transaction_id]) WHERE connection_id IS NOT NULL AND external_transaction_id IS NOT NULL;
CREATE INDEX [IX_fuel_fuel_transactions_2] ON [fuel].[fuel_transactions] ([tenant_id], [asset_id]);
CREATE INDEX [IX_fuel_fuel_transactions_3] ON [fuel].[fuel_transactions] ([tenant_id], [driver_id]);
CREATE INDEX [IX_fuel_fuel_transactions_4] ON [fuel].[fuel_transactions] ([tenant_id], [fuel_type_id]);
CREATE INDEX [IX_fuel_fuel_transactions_5] ON [fuel].[fuel_transactions] ([tenant_id], [currency_code]);
CREATE INDEX [IX_fuel_fuel_transactions_6] ON [fuel].[fuel_transactions] ([tenant_id], [jurisdiction_id]);
CREATE INDEX [IX_fuel_fuel_transactions_7] ON [fuel].[fuel_transactions] ([tenant_id], [asset_id], [transaction_at]);
ALTER TABLE [fuel].[fuel_transaction_matches] ADD CONSTRAINT [FK_fuel_fuel_transaction_matches_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fuel].[fuel_transaction_matches] ADD CONSTRAINT [FK_fuel_fuel_transaction_matches_2] FOREIGN KEY ([tenant_id], [fuel_transaction_id]) REFERENCES [fuel].[fuel_transactions] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_transaction_matches] ADD CONSTRAINT [FK_fuel_fuel_transaction_matches_3] FOREIGN KEY ([tenant_id], [expense_id]) REFERENCES [fin].[expenses] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_transaction_matches] ADD CONSTRAINT [FK_fuel_fuel_transaction_matches_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_transaction_matches] ADD CONSTRAINT [FK_fuel_fuel_transaction_matches_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fuel_fuel_transaction_matches_1] ON [fuel].[fuel_transaction_matches] ([tenant_id], [expense_id]);
ALTER TABLE [fuel].[fuel_cards] ADD CONSTRAINT [FK_fuel_fuel_cards_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fuel].[fuel_cards] ADD CONSTRAINT [FK_fuel_fuel_cards_2] FOREIGN KEY ([tenant_id], [connection_id]) REFERENCES [integration].[connections] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_cards] ADD CONSTRAINT [FK_fuel_fuel_cards_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_cards] ADD CONSTRAINT [FK_fuel_fuel_cards_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fuel_fuel_cards_1] ON [fuel].[fuel_cards] ([tenant_id], [connection_id]);
ALTER TABLE [fuel].[fuel_card_assignments] ADD CONSTRAINT [FK_fuel_fuel_card_assignments_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fuel].[fuel_card_assignments] ADD CONSTRAINT [FK_fuel_fuel_card_assignments_2] FOREIGN KEY ([tenant_id], [fuel_card_id]) REFERENCES [fuel].[fuel_cards] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_card_assignments] ADD CONSTRAINT [FK_fuel_fuel_card_assignments_3] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_card_assignments] ADD CONSTRAINT [FK_fuel_fuel_card_assignments_4] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_card_assignments] ADD CONSTRAINT [FK_fuel_fuel_card_assignments_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_card_assignments] ADD CONSTRAINT [FK_fuel_fuel_card_assignments_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fuel_fuel_card_assignments_1] ON [fuel].[fuel_card_assignments] ([tenant_id], [fuel_card_id]);
CREATE INDEX [IX_fuel_fuel_card_assignments_2] ON [fuel].[fuel_card_assignments] ([tenant_id], [asset_id]);
CREATE INDEX [IX_fuel_fuel_card_assignments_3] ON [fuel].[fuel_card_assignments] ([tenant_id], [driver_id]);
ALTER TABLE [fuel].[fuel_import_batches] ADD CONSTRAINT [FK_fuel_fuel_import_batches_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fuel].[fuel_import_batches] ADD CONSTRAINT [FK_fuel_fuel_import_batches_2] FOREIGN KEY ([tenant_id], [connection_id]) REFERENCES [integration].[connections] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_import_batches] ADD CONSTRAINT [FK_fuel_fuel_import_batches_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_import_batches] ADD CONSTRAINT [FK_fuel_fuel_import_batches_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_efficiency_records] ADD CONSTRAINT [FK_fuel_fuel_efficiency_records_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fuel].[fuel_efficiency_records] ADD CONSTRAINT [FK_fuel_fuel_efficiency_records_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_efficiency_records] ADD CONSTRAINT [FK_fuel_fuel_efficiency_records_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_efficiency_records] ADD CONSTRAINT [FK_fuel_fuel_efficiency_records_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_exceptions] ADD CONSTRAINT [FK_fuel_fuel_exceptions_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fuel].[fuel_exceptions] ADD CONSTRAINT [FK_fuel_fuel_exceptions_2] FOREIGN KEY ([tenant_id], [fuel_transaction_id]) REFERENCES [fuel].[fuel_transactions] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_exceptions] ADD CONSTRAINT [FK_fuel_fuel_exceptions_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fuel].[fuel_exceptions] ADD CONSTRAINT [FK_fuel_fuel_exceptions_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fuel_fuel_exceptions_1] ON [fuel].[fuel_exceptions] ([tenant_id], [fuel_transaction_id]);
ALTER TABLE [fin].[revenue_items] ADD CONSTRAINT [FK_fin_revenue_items_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[revenue_items] ADD CONSTRAINT [FK_fin_revenue_items_2] FOREIGN KEY ([tenant_id], [load_id]) REFERENCES [ops].[loads] ([tenant_id], [id]);
ALTER TABLE [fin].[revenue_items] ADD CONSTRAINT [FK_fin_revenue_items_3] FOREIGN KEY ([revenue_category_id]) REFERENCES [ref].[revenue_categories] ([id]);
ALTER TABLE [fin].[revenue_items] ADD CONSTRAINT [FK_fin_revenue_items_4] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [fin].[revenue_items] ADD CONSTRAINT [FK_fin_revenue_items_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[revenue_items] ADD CONSTRAINT [FK_fin_revenue_items_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_revenue_items_1] ON [fin].[revenue_items] ([tenant_id], [load_id]);
CREATE INDEX [IX_fin_revenue_items_2] ON [fin].[revenue_items] ([tenant_id], [revenue_category_id]);
CREATE INDEX [IX_fin_revenue_items_3] ON [fin].[revenue_items] ([tenant_id], [currency_code]);
ALTER TABLE [fin].[expenses] ADD CONSTRAINT [FK_fin_expenses_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[expenses] ADD CONSTRAINT [FK_fin_expenses_2] FOREIGN KEY ([expense_category_id]) REFERENCES [ref].[expense_categories] ([id]);
ALTER TABLE [fin].[expenses] ADD CONSTRAINT [FK_fin_expenses_3] FOREIGN KEY ([tenant_id], [vendor_id]) REFERENCES [mnt].[vendors] ([tenant_id], [id]);
ALTER TABLE [fin].[expenses] ADD CONSTRAINT [FK_fin_expenses_4] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [fin].[expenses] ADD CONSTRAINT [FK_fin_expenses_5] FOREIGN KEY ([tenant_id], [approved_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[expenses] ADD CONSTRAINT [FK_fin_expenses_6] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[expenses] ADD CONSTRAINT [FK_fin_expenses_7] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_expenses_1] ON [fin].[expenses] ([tenant_id], [expense_category_id]);
CREATE INDEX [IX_fin_expenses_2] ON [fin].[expenses] ([tenant_id], [vendor_id]);
CREATE INDEX [IX_fin_expenses_3] ON [fin].[expenses] ([tenant_id], [currency_code]);
CREATE INDEX [IX_fin_expenses_4] ON [fin].[expenses] ([tenant_id], [approved_by]);
CREATE INDEX [IX_fin_expenses_5] ON [fin].[expenses] ([tenant_id], [expense_date], [expense_category_id]);
ALTER TABLE [fin].[expense_allocations] ADD CONSTRAINT [FK_fin_expense_allocations_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[expense_allocations] ADD CONSTRAINT [FK_fin_expense_allocations_2] FOREIGN KEY ([tenant_id], [expense_id]) REFERENCES [fin].[expenses] ([tenant_id], [id]);
ALTER TABLE [fin].[expense_allocations] ADD CONSTRAINT [FK_fin_expense_allocations_3] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [fin].[expense_allocations] ADD CONSTRAINT [FK_fin_expense_allocations_4] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [fin].[expense_allocations] ADD CONSTRAINT [FK_fin_expense_allocations_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[expense_allocations] ADD CONSTRAINT [FK_fin_expense_allocations_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_expense_allocations_1] ON [fin].[expense_allocations] ([tenant_id], [expense_id]);
CREATE INDEX [IX_fin_expense_allocations_2] ON [fin].[expense_allocations] ([tenant_id], [trip_id]);
CREATE INDEX [IX_fin_expense_allocations_3] ON [fin].[expense_allocations] ([tenant_id], [asset_id]);
ALTER TABLE [fin].[revenue_allocations] ADD CONSTRAINT [FK_fin_revenue_allocations_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[revenue_allocations] ADD CONSTRAINT [FK_fin_revenue_allocations_2] FOREIGN KEY ([tenant_id], [revenue_item_id]) REFERENCES [fin].[revenue_items] ([tenant_id], [id]);
ALTER TABLE [fin].[revenue_allocations] ADD CONSTRAINT [FK_fin_revenue_allocations_3] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [fin].[revenue_allocations] ADD CONSTRAINT [FK_fin_revenue_allocations_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[revenue_allocations] ADD CONSTRAINT [FK_fin_revenue_allocations_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_revenue_allocations_1] ON [fin].[revenue_allocations] ([tenant_id], [revenue_item_id]);
CREATE INDEX [IX_fin_revenue_allocations_2] ON [fin].[revenue_allocations] ([tenant_id], [trip_id]);
ALTER TABLE [fin].[trip_financial_closures] ADD CONSTRAINT [FK_fin_trip_financial_closures_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[trip_financial_closures] ADD CONSTRAINT [FK_fin_trip_financial_closures_2] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [fin].[trip_financial_closures] ADD CONSTRAINT [FK_fin_trip_financial_closures_3] FOREIGN KEY ([tenant_id], [finalized_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[trip_financial_closures] ADD CONSTRAINT [FK_fin_trip_financial_closures_4] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [fin].[trip_financial_closures] ADD CONSTRAINT [FK_fin_trip_financial_closures_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[trip_financial_closures] ADD CONSTRAINT [FK_fin_trip_financial_closures_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_trip_financial_closures_1] ON [fin].[trip_financial_closures] ([tenant_id], [finalized_by]);
CREATE INDEX [IX_fin_trip_financial_closures_2] ON [fin].[trip_financial_closures] ([tenant_id], [currency_code]);
ALTER TABLE [fin].[cost_allocation_rules] ADD CONSTRAINT [FK_fin_cost_allocation_rules_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[cost_allocation_rules] ADD CONSTRAINT [FK_fin_cost_allocation_rules_2] FOREIGN KEY ([expense_category_id]) REFERENCES [ref].[expense_categories] ([id]);
ALTER TABLE [fin].[cost_allocation_rules] ADD CONSTRAINT [FK_fin_cost_allocation_rules_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[cost_allocation_rules] ADD CONSTRAINT [FK_fin_cost_allocation_rules_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_cost_allocation_rules_1] ON [fin].[cost_allocation_rules] ([tenant_id], [expense_category_id]);
ALTER TABLE [fin].[invoices] ADD CONSTRAINT [FK_fin_invoices_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[invoices] ADD CONSTRAINT [FK_fin_invoices_2] FOREIGN KEY ([tenant_id], [customer_id]) REFERENCES [crm].[customers] ([tenant_id], [id]);
ALTER TABLE [fin].[invoices] ADD CONSTRAINT [FK_fin_invoices_3] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [fin].[invoices] ADD CONSTRAINT [FK_fin_invoices_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[invoices] ADD CONSTRAINT [FK_fin_invoices_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_invoices_1] ON [fin].[invoices] ([tenant_id], [customer_id]);
CREATE INDEX [IX_fin_invoices_2] ON [fin].[invoices] ([tenant_id], [currency_code]);
ALTER TABLE [fin].[invoice_items] ADD CONSTRAINT [FK_fin_invoice_items_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[invoice_items] ADD CONSTRAINT [FK_fin_invoice_items_2] FOREIGN KEY ([tenant_id], [invoice_id]) REFERENCES [fin].[invoices] ([tenant_id], [id]);
ALTER TABLE [fin].[invoice_items] ADD CONSTRAINT [FK_fin_invoice_items_3] FOREIGN KEY ([tenant_id], [revenue_item_id]) REFERENCES [fin].[revenue_items] ([tenant_id], [id]);
ALTER TABLE [fin].[invoice_items] ADD CONSTRAINT [FK_fin_invoice_items_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[invoice_items] ADD CONSTRAINT [FK_fin_invoice_items_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_invoice_items_1] ON [fin].[invoice_items] ([tenant_id], [invoice_id]);
CREATE INDEX [IX_fin_invoice_items_2] ON [fin].[invoice_items] ([tenant_id], [revenue_item_id]);
ALTER TABLE [fin].[payments] ADD CONSTRAINT [FK_fin_payments_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[payments] ADD CONSTRAINT [FK_fin_payments_2] FOREIGN KEY ([tenant_id], [customer_id]) REFERENCES [crm].[customers] ([tenant_id], [id]);
ALTER TABLE [fin].[payments] ADD CONSTRAINT [FK_fin_payments_3] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [fin].[payments] ADD CONSTRAINT [FK_fin_payments_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[payments] ADD CONSTRAINT [FK_fin_payments_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_payments_1] ON [fin].[payments] ([tenant_id], [customer_id]);
CREATE INDEX [IX_fin_payments_2] ON [fin].[payments] ([tenant_id], [currency_code]);
ALTER TABLE [fin].[payment_allocations] ADD CONSTRAINT [FK_fin_payment_allocations_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[payment_allocations] ADD CONSTRAINT [FK_fin_payment_allocations_2] FOREIGN KEY ([tenant_id], [payment_id]) REFERENCES [fin].[payments] ([tenant_id], [id]);
ALTER TABLE [fin].[payment_allocations] ADD CONSTRAINT [FK_fin_payment_allocations_3] FOREIGN KEY ([tenant_id], [invoice_id]) REFERENCES [fin].[invoices] ([tenant_id], [id]);
ALTER TABLE [fin].[payment_allocations] ADD CONSTRAINT [FK_fin_payment_allocations_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[payment_allocations] ADD CONSTRAINT [FK_fin_payment_allocations_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_payment_allocations_1] ON [fin].[payment_allocations] ([tenant_id], [payment_id]);
CREATE INDEX [IX_fin_payment_allocations_2] ON [fin].[payment_allocations] ([tenant_id], [invoice_id]);
ALTER TABLE [fin].[driver_settlements] ADD CONSTRAINT [FK_fin_driver_settlements_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[driver_settlements] ADD CONSTRAINT [FK_fin_driver_settlements_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [fin].[driver_settlements] ADD CONSTRAINT [FK_fin_driver_settlements_3] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
ALTER TABLE [fin].[driver_settlements] ADD CONSTRAINT [FK_fin_driver_settlements_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[driver_settlements] ADD CONSTRAINT [FK_fin_driver_settlements_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_driver_settlements_1] ON [fin].[driver_settlements] ([tenant_id], [driver_id]);
CREATE INDEX [IX_fin_driver_settlements_2] ON [fin].[driver_settlements] ([tenant_id], [currency_code]);
ALTER TABLE [fin].[driver_settlement_items] ADD CONSTRAINT [FK_fin_driver_settlement_items_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[driver_settlement_items] ADD CONSTRAINT [FK_fin_driver_settlement_items_2] FOREIGN KEY ([tenant_id], [settlement_id]) REFERENCES [fin].[driver_settlements] ([tenant_id], [id]);
ALTER TABLE [fin].[driver_settlement_items] ADD CONSTRAINT [FK_fin_driver_settlement_items_3] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [fin].[driver_settlement_items] ADD CONSTRAINT [FK_fin_driver_settlement_items_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[driver_settlement_items] ADD CONSTRAINT [FK_fin_driver_settlement_items_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_driver_settlement_items_1] ON [fin].[driver_settlement_items] ([tenant_id], [settlement_id]);
CREATE INDEX [IX_fin_driver_settlement_items_2] ON [fin].[driver_settlement_items] ([tenant_id], [trip_id]);
ALTER TABLE [fin].[financial_periods] ADD CONSTRAINT [FK_fin_financial_periods_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[financial_periods] ADD CONSTRAINT [FK_fin_financial_periods_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[financial_periods] ADD CONSTRAINT [FK_fin_financial_periods_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[financial_adjustments] ADD CONSTRAINT [FK_fin_financial_adjustments_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[financial_adjustments] ADD CONSTRAINT [FK_fin_financial_adjustments_2] FOREIGN KEY ([tenant_id], [expense_id]) REFERENCES [fin].[expenses] ([tenant_id], [id]);
ALTER TABLE [fin].[financial_adjustments] ADD CONSTRAINT [FK_fin_financial_adjustments_3] FOREIGN KEY ([tenant_id], [revenue_item_id]) REFERENCES [fin].[revenue_items] ([tenant_id], [id]);
ALTER TABLE [fin].[financial_adjustments] ADD CONSTRAINT [FK_fin_financial_adjustments_4] FOREIGN KEY ([tenant_id], [approved_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[financial_adjustments] ADD CONSTRAINT [FK_fin_financial_adjustments_5] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
CREATE INDEX [IX_fin_financial_adjustments_1] ON [fin].[financial_adjustments] ([tenant_id], [expense_id]);
CREATE INDEX [IX_fin_financial_adjustments_2] ON [fin].[financial_adjustments] ([tenant_id], [revenue_item_id]);
CREATE INDEX [IX_fin_financial_adjustments_3] ON [fin].[financial_adjustments] ([tenant_id], [approved_by]);
CREATE INDEX [IX_fin_financial_adjustments_4] ON [fin].[financial_adjustments] ([tenant_id], [currency_code]);
ALTER TABLE [fin].[service_expense_links] ADD CONSTRAINT [FK_fin_service_expense_links_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[service_expense_links] ADD CONSTRAINT [FK_fin_service_expense_links_2] FOREIGN KEY ([tenant_id], [service_record_id]) REFERENCES [mnt].[service_records] ([tenant_id], [id]);
ALTER TABLE [fin].[service_expense_links] ADD CONSTRAINT [FK_fin_service_expense_links_3] FOREIGN KEY ([tenant_id], [expense_id]) REFERENCES [fin].[expenses] ([tenant_id], [id]);
ALTER TABLE [fin].[service_expense_links] ADD CONSTRAINT [FK_fin_service_expense_links_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[service_expense_links] ADD CONSTRAINT [FK_fin_service_expense_links_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_service_expense_links_1] ON [fin].[service_expense_links] ([tenant_id], [expense_id]);
ALTER TABLE [fin].[work_order_expense_links] ADD CONSTRAINT [FK_fin_work_order_expense_links_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [fin].[work_order_expense_links] ADD CONSTRAINT [FK_fin_work_order_expense_links_2] FOREIGN KEY ([tenant_id], [work_order_id]) REFERENCES [mnt].[work_orders] ([tenant_id], [id]);
ALTER TABLE [fin].[work_order_expense_links] ADD CONSTRAINT [FK_fin_work_order_expense_links_3] FOREIGN KEY ([tenant_id], [expense_id]) REFERENCES [fin].[expenses] ([tenant_id], [id]);
ALTER TABLE [fin].[work_order_expense_links] ADD CONSTRAINT [FK_fin_work_order_expense_links_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [fin].[work_order_expense_links] ADD CONSTRAINT [FK_fin_work_order_expense_links_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_fin_work_order_expense_links_1] ON [fin].[work_order_expense_links] ([tenant_id], [expense_id]);
ALTER TABLE [compliance].[compliance_requirements] ADD CONSTRAINT [FK_compliance_compliance_requirements_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[compliance_requirements] ADD CONSTRAINT [FK_compliance_compliance_requirements_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[compliance_requirements] ADD CONSTRAINT [FK_compliance_compliance_requirements_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[driver_compliance_records] ADD CONSTRAINT [FK_compliance_driver_compliance_records_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[driver_compliance_records] ADD CONSTRAINT [FK_compliance_driver_compliance_records_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [compliance].[driver_compliance_records] ADD CONSTRAINT [FK_compliance_driver_compliance_records_3] FOREIGN KEY ([tenant_id], [requirement_id]) REFERENCES [compliance].[compliance_requirements] ([tenant_id], [id]);
ALTER TABLE [compliance].[driver_compliance_records] ADD CONSTRAINT [FK_compliance_driver_compliance_records_4] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [compliance].[driver_compliance_records] ADD CONSTRAINT [FK_compliance_driver_compliance_records_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[driver_compliance_records] ADD CONSTRAINT [FK_compliance_driver_compliance_records_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_compliance_driver_compliance_records_1] ON [compliance].[driver_compliance_records] ([tenant_id], [driver_id]);
CREATE INDEX [IX_compliance_driver_compliance_records_2] ON [compliance].[driver_compliance_records] ([tenant_id], [requirement_id]);
CREATE INDEX [IX_compliance_driver_compliance_records_3] ON [compliance].[driver_compliance_records] ([tenant_id], [document_id]);
ALTER TABLE [compliance].[asset_compliance_records] ADD CONSTRAINT [FK_compliance_asset_compliance_records_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[asset_compliance_records] ADD CONSTRAINT [FK_compliance_asset_compliance_records_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [compliance].[asset_compliance_records] ADD CONSTRAINT [FK_compliance_asset_compliance_records_3] FOREIGN KEY ([tenant_id], [requirement_id]) REFERENCES [compliance].[compliance_requirements] ([tenant_id], [id]);
ALTER TABLE [compliance].[asset_compliance_records] ADD CONSTRAINT [FK_compliance_asset_compliance_records_4] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [compliance].[asset_compliance_records] ADD CONSTRAINT [FK_compliance_asset_compliance_records_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[asset_compliance_records] ADD CONSTRAINT [FK_compliance_asset_compliance_records_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_compliance_asset_compliance_records_1] ON [compliance].[asset_compliance_records] ([tenant_id], [asset_id]);
CREATE INDEX [IX_compliance_asset_compliance_records_2] ON [compliance].[asset_compliance_records] ([tenant_id], [requirement_id]);
CREATE INDEX [IX_compliance_asset_compliance_records_3] ON [compliance].[asset_compliance_records] ([tenant_id], [document_id]);
ALTER TABLE [compliance].[inspection_templates] ADD CONSTRAINT [FK_compliance_inspection_templates_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[inspection_templates] ADD CONSTRAINT [FK_compliance_inspection_templates_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspection_templates] ADD CONSTRAINT [FK_compliance_inspection_templates_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspection_template_items] ADD CONSTRAINT [FK_compliance_inspection_template_items_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[inspection_template_items] ADD CONSTRAINT [FK_compliance_inspection_template_items_2] FOREIGN KEY ([tenant_id], [template_id]) REFERENCES [compliance].[inspection_templates] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspection_template_items] ADD CONSTRAINT [FK_compliance_inspection_template_items_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspection_template_items] ADD CONSTRAINT [FK_compliance_inspection_template_items_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspections] ADD CONSTRAINT [FK_compliance_inspections_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[inspections] ADD CONSTRAINT [FK_compliance_inspections_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspections] ADD CONSTRAINT [FK_compliance_inspections_3] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspections] ADD CONSTRAINT [FK_compliance_inspections_4] FOREIGN KEY ([tenant_id], [template_id]) REFERENCES [compliance].[inspection_templates] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspections] ADD CONSTRAINT [FK_compliance_inspections_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspections] ADD CONSTRAINT [FK_compliance_inspections_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_compliance_inspections_1] ON [compliance].[inspections] ([tenant_id], [asset_id]);
CREATE INDEX [IX_compliance_inspections_2] ON [compliance].[inspections] ([tenant_id], [driver_id]);
CREATE INDEX [IX_compliance_inspections_3] ON [compliance].[inspections] ([tenant_id], [template_id]);
ALTER TABLE [compliance].[inspection_items] ADD CONSTRAINT [FK_compliance_inspection_items_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[inspection_items] ADD CONSTRAINT [FK_compliance_inspection_items_2] FOREIGN KEY ([tenant_id], [inspection_id]) REFERENCES [compliance].[inspections] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspection_items] ADD CONSTRAINT [FK_compliance_inspection_items_3] FOREIGN KEY ([tenant_id], [template_item_id]) REFERENCES [compliance].[inspection_template_items] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspection_items] ADD CONSTRAINT [FK_compliance_inspection_items_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[inspection_items] ADD CONSTRAINT [FK_compliance_inspection_items_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_compliance_inspection_items_1] ON [compliance].[inspection_items] ([tenant_id], [template_item_id]);
ALTER TABLE [compliance].[repair_certifications] ADD CONSTRAINT [FK_compliance_repair_certifications_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[repair_certifications] ADD CONSTRAINT [FK_compliance_repair_certifications_2] FOREIGN KEY ([tenant_id], [defect_id]) REFERENCES [mnt].[defects] ([tenant_id], [id]);
ALTER TABLE [compliance].[repair_certifications] ADD CONSTRAINT [FK_compliance_repair_certifications_3] FOREIGN KEY ([tenant_id], [work_order_id]) REFERENCES [mnt].[work_orders] ([tenant_id], [id]);
ALTER TABLE [compliance].[repair_certifications] ADD CONSTRAINT [FK_compliance_repair_certifications_4] FOREIGN KEY ([tenant_id], [certified_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_compliance_repair_certifications_1] ON [compliance].[repair_certifications] ([tenant_id], [defect_id]);
CREATE INDEX [IX_compliance_repair_certifications_2] ON [compliance].[repair_certifications] ([tenant_id], [work_order_id]);
CREATE INDEX [IX_compliance_repair_certifications_3] ON [compliance].[repair_certifications] ([tenant_id], [certified_by]);
ALTER TABLE [compliance].[hos_records] ADD CONSTRAINT [FK_compliance_hos_records_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[hos_records] ADD CONSTRAINT [FK_compliance_hos_records_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [compliance].[hos_records] ADD CONSTRAINT [FK_compliance_hos_records_3] FOREIGN KEY ([tenant_id], [connection_id]) REFERENCES [integration].[connections] ([tenant_id], [id]);
CREATE INDEX [IX_compliance_hos_records_1] ON [compliance].[hos_records] ([tenant_id], [driver_id]);
ALTER TABLE [compliance].[hos_balance_snapshots] ADD CONSTRAINT [FK_compliance_hos_balance_snapshots_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[hos_balance_snapshots] ADD CONSTRAINT [FK_compliance_hos_balance_snapshots_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [compliance].[hos_balance_snapshots] ADD CONSTRAINT [FK_compliance_hos_balance_snapshots_3] FOREIGN KEY ([tenant_id], [connection_id]) REFERENCES [integration].[connections] ([tenant_id], [id]);
CREATE INDEX [IX_compliance_hos_balance_snapshots_1] ON [compliance].[hos_balance_snapshots] ([tenant_id], [driver_id]);
CREATE INDEX [IX_compliance_hos_balance_snapshots_2] ON [compliance].[hos_balance_snapshots] ([tenant_id], [connection_id]);
ALTER TABLE [compliance].[safety_incidents] ADD CONSTRAINT [FK_compliance_safety_incidents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[safety_incidents] ADD CONSTRAINT [FK_compliance_safety_incidents_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [compliance].[safety_incidents] ADD CONSTRAINT [FK_compliance_safety_incidents_3] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [compliance].[safety_incidents] ADD CONSTRAINT [FK_compliance_safety_incidents_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[safety_incidents] ADD CONSTRAINT [FK_compliance_safety_incidents_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_compliance_safety_incidents_1] ON [compliance].[safety_incidents] ([tenant_id], [asset_id]);
CREATE INDEX [IX_compliance_safety_incidents_2] ON [compliance].[safety_incidents] ([tenant_id], [driver_id]);
ALTER TABLE [compliance].[jurisdiction_distance_records] ADD CONSTRAINT [FK_compliance_jurisdiction_distance_records_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[jurisdiction_distance_records] ADD CONSTRAINT [FK_compliance_jurisdiction_distance_records_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [compliance].[jurisdiction_distance_records] ADD CONSTRAINT [FK_compliance_jurisdiction_distance_records_3] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [compliance].[jurisdiction_distance_records] ADD CONSTRAINT [FK_compliance_jurisdiction_distance_records_4] FOREIGN KEY ([jurisdiction_id]) REFERENCES [ref].[jurisdictions] ([id]);
ALTER TABLE [compliance].[jurisdiction_distance_records] ADD CONSTRAINT [FK_compliance_jurisdiction_distance_records_5] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[jurisdiction_distance_records] ADD CONSTRAINT [FK_compliance_jurisdiction_distance_records_6] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_compliance_jurisdiction_distance_records_1] ON [compliance].[jurisdiction_distance_records] ([tenant_id], [asset_id]);
CREATE INDEX [IX_compliance_jurisdiction_distance_records_2] ON [compliance].[jurisdiction_distance_records] ([tenant_id], [trip_id]);
CREATE INDEX [IX_compliance_jurisdiction_distance_records_3] ON [compliance].[jurisdiction_distance_records] ([tenant_id], [jurisdiction_id]);
ALTER TABLE [compliance].[ifta_reporting_periods] ADD CONSTRAINT [FK_compliance_ifta_reporting_periods_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[ifta_reporting_periods] ADD CONSTRAINT [FK_compliance_ifta_reporting_periods_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[ifta_reporting_periods] ADD CONSTRAINT [FK_compliance_ifta_reporting_periods_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[ifta_report_lines] ADD CONSTRAINT [FK_compliance_ifta_report_lines_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [compliance].[ifta_report_lines] ADD CONSTRAINT [FK_compliance_ifta_report_lines_2] FOREIGN KEY ([tenant_id], [period_id]) REFERENCES [compliance].[ifta_reporting_periods] ([tenant_id], [id]);
ALTER TABLE [compliance].[ifta_report_lines] ADD CONSTRAINT [FK_compliance_ifta_report_lines_3] FOREIGN KEY ([jurisdiction_id]) REFERENCES [ref].[jurisdictions] ([id]);
ALTER TABLE [compliance].[ifta_report_lines] ADD CONSTRAINT [FK_compliance_ifta_report_lines_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [compliance].[ifta_report_lines] ADD CONSTRAINT [FK_compliance_ifta_report_lines_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_compliance_ifta_report_lines_1] ON [compliance].[ifta_report_lines] ([tenant_id], [jurisdiction_id]);
ALTER TABLE [docs].[documents] ADD CONSTRAINT [FK_docs_documents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[documents] ADD CONSTRAINT [FK_docs_documents_2] FOREIGN KEY ([document_type_id]) REFERENCES [ref].[document_types] ([id]);
ALTER TABLE [docs].[documents] ADD CONSTRAINT [FK_docs_documents_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[documents] ADD CONSTRAINT [FK_docs_documents_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_docs_documents_1] ON [docs].[documents] ([tenant_id], [document_type_id]);
CREATE INDEX [IX_docs_documents_2] ON [docs].[documents] ([tenant_id], [document_type_id], [expires_at]);
ALTER TABLE [docs].[document_versions] ADD CONSTRAINT [FK_docs_document_versions_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[document_versions] ADD CONSTRAINT [FK_docs_document_versions_2] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [docs].[document_versions] ADD CONSTRAINT [FK_docs_document_versions_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[document_versions] ADD CONSTRAINT [FK_docs_document_versions_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[asset_documents] ADD CONSTRAINT [FK_docs_asset_documents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[asset_documents] ADD CONSTRAINT [FK_docs_asset_documents_2] FOREIGN KEY ([tenant_id], [asset_id]) REFERENCES [fleet].[assets] ([tenant_id], [id]);
ALTER TABLE [docs].[asset_documents] ADD CONSTRAINT [FK_docs_asset_documents_3] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [docs].[asset_documents] ADD CONSTRAINT [FK_docs_asset_documents_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[asset_documents] ADD CONSTRAINT [FK_docs_asset_documents_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_docs_asset_documents_1] ON [docs].[asset_documents] ([tenant_id], [document_id]);
ALTER TABLE [docs].[driver_documents] ADD CONSTRAINT [FK_docs_driver_documents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[driver_documents] ADD CONSTRAINT [FK_docs_driver_documents_2] FOREIGN KEY ([tenant_id], [driver_id]) REFERENCES [hr].[drivers] ([tenant_id], [id]);
ALTER TABLE [docs].[driver_documents] ADD CONSTRAINT [FK_docs_driver_documents_3] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [docs].[driver_documents] ADD CONSTRAINT [FK_docs_driver_documents_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[driver_documents] ADD CONSTRAINT [FK_docs_driver_documents_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_docs_driver_documents_1] ON [docs].[driver_documents] ([tenant_id], [document_id]);
ALTER TABLE [docs].[load_documents] ADD CONSTRAINT [FK_docs_load_documents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[load_documents] ADD CONSTRAINT [FK_docs_load_documents_2] FOREIGN KEY ([tenant_id], [load_id]) REFERENCES [ops].[loads] ([tenant_id], [id]);
ALTER TABLE [docs].[load_documents] ADD CONSTRAINT [FK_docs_load_documents_3] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [docs].[load_documents] ADD CONSTRAINT [FK_docs_load_documents_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[load_documents] ADD CONSTRAINT [FK_docs_load_documents_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_docs_load_documents_1] ON [docs].[load_documents] ([tenant_id], [document_id]);
ALTER TABLE [docs].[trip_documents] ADD CONSTRAINT [FK_docs_trip_documents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[trip_documents] ADD CONSTRAINT [FK_docs_trip_documents_2] FOREIGN KEY ([tenant_id], [trip_id]) REFERENCES [ops].[trips] ([tenant_id], [id]);
ALTER TABLE [docs].[trip_documents] ADD CONSTRAINT [FK_docs_trip_documents_3] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [docs].[trip_documents] ADD CONSTRAINT [FK_docs_trip_documents_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[trip_documents] ADD CONSTRAINT [FK_docs_trip_documents_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_docs_trip_documents_1] ON [docs].[trip_documents] ([tenant_id], [document_id]);
ALTER TABLE [docs].[delivery_documents] ADD CONSTRAINT [FK_docs_delivery_documents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[delivery_documents] ADD CONSTRAINT [FK_docs_delivery_documents_2] FOREIGN KEY ([tenant_id], [delivery_id]) REFERENCES [ops].[delivery_confirmations] ([tenant_id], [id]);
ALTER TABLE [docs].[delivery_documents] ADD CONSTRAINT [FK_docs_delivery_documents_3] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [docs].[delivery_documents] ADD CONSTRAINT [FK_docs_delivery_documents_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[delivery_documents] ADD CONSTRAINT [FK_docs_delivery_documents_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[delivery_documents] ADD CONSTRAINT [FK_docs_delivery_documents_6] FOREIGN KEY ([tenant_id], [document_id], [version_number]) REFERENCES [docs].[document_versions] ([tenant_id], [document_id], [version_number]);
CREATE INDEX [IX_docs_delivery_documents_1] ON [docs].[delivery_documents] ([tenant_id], [document_id], [version_number]);
ALTER TABLE [docs].[inspection_documents] ADD CONSTRAINT [FK_docs_inspection_documents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[inspection_documents] ADD CONSTRAINT [FK_docs_inspection_documents_2] FOREIGN KEY ([tenant_id], [inspection_id]) REFERENCES [compliance].[inspections] ([tenant_id], [id]);
ALTER TABLE [docs].[inspection_documents] ADD CONSTRAINT [FK_docs_inspection_documents_3] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [docs].[inspection_documents] ADD CONSTRAINT [FK_docs_inspection_documents_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[inspection_documents] ADD CONSTRAINT [FK_docs_inspection_documents_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_docs_inspection_documents_1] ON [docs].[inspection_documents] ([tenant_id], [document_id]);
ALTER TABLE [docs].[expense_documents] ADD CONSTRAINT [FK_docs_expense_documents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[expense_documents] ADD CONSTRAINT [FK_docs_expense_documents_2] FOREIGN KEY ([tenant_id], [expense_id]) REFERENCES [fin].[expenses] ([tenant_id], [id]);
ALTER TABLE [docs].[expense_documents] ADD CONSTRAINT [FK_docs_expense_documents_3] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [docs].[expense_documents] ADD CONSTRAINT [FK_docs_expense_documents_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[expense_documents] ADD CONSTRAINT [FK_docs_expense_documents_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_docs_expense_documents_1] ON [docs].[expense_documents] ([tenant_id], [document_id]);
ALTER TABLE [docs].[work_order_documents] ADD CONSTRAINT [FK_docs_work_order_documents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[work_order_documents] ADD CONSTRAINT [FK_docs_work_order_documents_2] FOREIGN KEY ([tenant_id], [work_order_id]) REFERENCES [mnt].[work_orders] ([tenant_id], [id]);
ALTER TABLE [docs].[work_order_documents] ADD CONSTRAINT [FK_docs_work_order_documents_3] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [docs].[work_order_documents] ADD CONSTRAINT [FK_docs_work_order_documents_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[work_order_documents] ADD CONSTRAINT [FK_docs_work_order_documents_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_docs_work_order_documents_1] ON [docs].[work_order_documents] ([tenant_id], [document_id]);
ALTER TABLE [docs].[document_verifications] ADD CONSTRAINT [FK_docs_document_verifications_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [docs].[document_verifications] ADD CONSTRAINT [FK_docs_document_verifications_2] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [docs].[document_verifications] ADD CONSTRAINT [FK_docs_document_verifications_3] FOREIGN KEY ([tenant_id], [verified_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [docs].[document_verifications] ADD CONSTRAINT [FK_docs_document_verifications_4] FOREIGN KEY ([tenant_id], [document_id], [version_number]) REFERENCES [docs].[document_versions] ([tenant_id], [document_id], [version_number]);
CREATE INDEX [IX_docs_document_verifications_1] ON [docs].[document_verifications] ([tenant_id], [document_id], [version_number]);
CREATE INDEX [IX_docs_document_verifications_2] ON [docs].[document_verifications] ([tenant_id], [verified_by]);
ALTER TABLE [notify].[alert_rules] ADD CONSTRAINT [FK_notify_alert_rules_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [notify].[alert_rules] ADD CONSTRAINT [FK_notify_alert_rules_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[alert_rules] ADD CONSTRAINT [FK_notify_alert_rules_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[alerts] ADD CONSTRAINT [FK_notify_alerts_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [notify].[alerts] ADD CONSTRAINT [FK_notify_alerts_2] FOREIGN KEY ([tenant_id], [rule_id]) REFERENCES [notify].[alert_rules] ([tenant_id], [id]);
ALTER TABLE [notify].[alerts] ADD CONSTRAINT [FK_notify_alerts_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[alerts] ADD CONSTRAINT [FK_notify_alerts_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_notify_alerts_1] ON [notify].[alerts] ([tenant_id], [rule_id]);
CREATE INDEX [IX_notify_alerts_2] ON [notify].[alerts] ([tenant_id], [status], [severity], [created_at]);
ALTER TABLE [notify].[alert_assignments] ADD CONSTRAINT [FK_notify_alert_assignments_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [notify].[alert_assignments] ADD CONSTRAINT [FK_notify_alert_assignments_2] FOREIGN KEY ([tenant_id], [alert_id]) REFERENCES [notify].[alerts] ([tenant_id], [id]);
ALTER TABLE [notify].[alert_assignments] ADD CONSTRAINT [FK_notify_alert_assignments_3] FOREIGN KEY ([tenant_id], [membership_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[alert_assignments] ADD CONSTRAINT [FK_notify_alert_assignments_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[alert_assignments] ADD CONSTRAINT [FK_notify_alert_assignments_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_notify_alert_assignments_1] ON [notify].[alert_assignments] ([tenant_id], [membership_id]);
ALTER TABLE [notify].[alert_acknowledgments] ADD CONSTRAINT [FK_notify_alert_acknowledgments_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [notify].[alert_acknowledgments] ADD CONSTRAINT [FK_notify_alert_acknowledgments_2] FOREIGN KEY ([tenant_id], [alert_id]) REFERENCES [notify].[alerts] ([tenant_id], [id]);
ALTER TABLE [notify].[alert_acknowledgments] ADD CONSTRAINT [FK_notify_alert_acknowledgments_3] FOREIGN KEY ([tenant_id], [membership_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_notify_alert_acknowledgments_1] ON [notify].[alert_acknowledgments] ([tenant_id], [membership_id]);
ALTER TABLE [notify].[notifications] ADD CONSTRAINT [FK_notify_notifications_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [notify].[notifications] ADD CONSTRAINT [FK_notify_notifications_2] FOREIGN KEY ([tenant_id], [recipient_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[notifications] ADD CONSTRAINT [FK_notify_notifications_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[notifications] ADD CONSTRAINT [FK_notify_notifications_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_notify_notifications_1] ON [notify].[notifications] ([tenant_id], [recipient_id]);
ALTER TABLE [notify].[notification_preferences] ADD CONSTRAINT [FK_notify_notification_preferences_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [notify].[notification_preferences] ADD CONSTRAINT [FK_notify_notification_preferences_2] FOREIGN KEY ([tenant_id], [membership_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[notification_preferences] ADD CONSTRAINT [FK_notify_notification_preferences_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[notification_preferences] ADD CONSTRAINT [FK_notify_notification_preferences_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[notification_delivery_attempts] ADD CONSTRAINT [FK_notify_notification_delivery_attempts_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [notify].[notification_delivery_attempts] ADD CONSTRAINT [FK_notify_notification_delivery_attempts_2] FOREIGN KEY ([tenant_id], [notification_id]) REFERENCES [notify].[notifications] ([tenant_id], [id]);
ALTER TABLE [notify].[notification_templates] ADD CONSTRAINT [FK_notify_notification_templates_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [notify].[notification_templates] ADD CONSTRAINT [FK_notify_notification_templates_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [notify].[notification_templates] ADD CONSTRAINT [FK_notify_notification_templates_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ai].[conversations] ADD CONSTRAINT [FK_ai_conversations_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ai].[conversations] ADD CONSTRAINT [FK_ai_conversations_2] FOREIGN KEY ([tenant_id], [membership_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ai].[conversations] ADD CONSTRAINT [FK_ai_conversations_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ai].[conversations] ADD CONSTRAINT [FK_ai_conversations_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ai_conversations_1] ON [ai].[conversations] ([tenant_id], [membership_id]);
ALTER TABLE [ai].[messages] ADD CONSTRAINT [FK_ai_messages_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ai].[messages] ADD CONSTRAINT [FK_ai_messages_2] FOREIGN KEY ([tenant_id], [conversation_id]) REFERENCES [ai].[conversations] ([tenant_id], [id]);
ALTER TABLE [ai].[messages] ADD CONSTRAINT [FK_ai_messages_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ai].[messages] ADD CONSTRAINT [FK_ai_messages_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ai].[tool_definitions] ADD CONSTRAINT [FK_ai_tool_definitions_1] FOREIGN KEY ([required_permission_id]) REFERENCES [iam].[permissions] ([id]);
CREATE INDEX [IX_ai_tool_definitions_1] ON [ai].[tool_definitions] ([required_permission_id]);
ALTER TABLE [ai].[tool_invocations] ADD CONSTRAINT [FK_ai_tool_invocations_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ai].[tool_invocations] ADD CONSTRAINT [FK_ai_tool_invocations_2] FOREIGN KEY ([tenant_id], [message_id]) REFERENCES [ai].[messages] ([tenant_id], [id]);
ALTER TABLE [ai].[tool_invocations] ADD CONSTRAINT [FK_ai_tool_invocations_3] FOREIGN KEY ([tool_id]) REFERENCES [ai].[tool_definitions] ([id]);
CREATE INDEX [IX_ai_tool_invocations_1] ON [ai].[tool_invocations] ([tenant_id], [message_id]);
CREATE INDEX [IX_ai_tool_invocations_2] ON [ai].[tool_invocations] ([tenant_id], [tool_id]);
ALTER TABLE [ai].[response_sources] ADD CONSTRAINT [FK_ai_response_sources_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ai].[response_sources] ADD CONSTRAINT [FK_ai_response_sources_2] FOREIGN KEY ([tenant_id], [message_id]) REFERENCES [ai].[messages] ([tenant_id], [id]);
ALTER TABLE [ai].[response_sources] ADD CONSTRAINT [FK_ai_response_sources_3] FOREIGN KEY ([tenant_id], [tool_invocation_id]) REFERENCES [ai].[tool_invocations] ([tenant_id], [id]);
CREATE INDEX [IX_ai_response_sources_1] ON [ai].[response_sources] ([tenant_id], [message_id]);
CREATE INDEX [IX_ai_response_sources_2] ON [ai].[response_sources] ([tenant_id], [tool_invocation_id]);
ALTER TABLE [ai].[response_feedback] ADD CONSTRAINT [FK_ai_response_feedback_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ai].[response_feedback] ADD CONSTRAINT [FK_ai_response_feedback_2] FOREIGN KEY ([tenant_id], [message_id]) REFERENCES [ai].[messages] ([tenant_id], [id]);
ALTER TABLE [ai].[response_feedback] ADD CONSTRAINT [FK_ai_response_feedback_3] FOREIGN KEY ([tenant_id], [membership_id]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ai].[response_feedback] ADD CONSTRAINT [FK_ai_response_feedback_4] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ai].[response_feedback] ADD CONSTRAINT [FK_ai_response_feedback_5] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ai_response_feedback_1] ON [ai].[response_feedback] ([tenant_id], [membership_id]);
ALTER TABLE [ai].[usage_records] ADD CONSTRAINT [FK_ai_usage_records_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ai].[usage_records] ADD CONSTRAINT [FK_ai_usage_records_2] FOREIGN KEY ([tenant_id], [message_id]) REFERENCES [ai].[messages] ([tenant_id], [id]);
ALTER TABLE [ai].[usage_records] ADD CONSTRAINT [FK_ai_usage_records_3] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
CREATE INDEX [IX_ai_usage_records_1] ON [ai].[usage_records] ([tenant_id], [message_id]);
CREATE INDEX [IX_ai_usage_records_2] ON [ai].[usage_records] ([tenant_id], [currency_code]);
ALTER TABLE [ai].[tenant_ai_settings] ADD CONSTRAINT [FK_ai_tenant_ai_settings_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ai].[tenant_ai_settings] ADD CONSTRAINT [FK_ai_tenant_ai_settings_2] FOREIGN KEY ([model_configuration_id]) REFERENCES [ai].[model_configurations] ([id]);
ALTER TABLE [ai].[tenant_ai_settings] ADD CONSTRAINT [FK_ai_tenant_ai_settings_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ai].[tenant_ai_settings] ADD CONSTRAINT [FK_ai_tenant_ai_settings_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_ai_tenant_ai_settings_1] ON [ai].[tenant_ai_settings] ([tenant_id], [model_configuration_id]);
ALTER TABLE [ai].[evaluation_runs] ADD CONSTRAINT [FK_ai_evaluation_runs_1] FOREIGN KEY ([case_id]) REFERENCES [ai].[evaluation_cases] ([id]);
CREATE INDEX [IX_ai_evaluation_runs_1] ON [ai].[evaluation_runs] ([case_id]);
ALTER TABLE [ai].[knowledge_documents] ADD CONSTRAINT [FK_ai_knowledge_documents_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [ai].[knowledge_documents] ADD CONSTRAINT [FK_ai_knowledge_documents_2] FOREIGN KEY ([tenant_id], [document_id]) REFERENCES [docs].[documents] ([tenant_id], [id]);
ALTER TABLE [ai].[knowledge_documents] ADD CONSTRAINT [FK_ai_knowledge_documents_3] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [ai].[knowledge_documents] ADD CONSTRAINT [FK_ai_knowledge_documents_4] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [audit].[audit_events] ADD CONSTRAINT [FK_audit_audit_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [audit].[audit_events] ADD CONSTRAINT [FK_audit_audit_events_2] FOREIGN KEY ([actor_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_audit_audit_events_1] ON [audit].[audit_events] ([tenant_id], [actor_id]);
CREATE INDEX [IX_audit_audit_events_2] ON [audit].[audit_events] ([tenant_id], [entity_type], [entity_id], [occurred_at]);
ALTER TABLE [audit].[security_events] ADD CONSTRAINT [FK_audit_security_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [audit].[security_events] ADD CONSTRAINT [FK_audit_security_events_2] FOREIGN KEY ([user_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_audit_security_events_1] ON [audit].[security_events] ([tenant_id], [user_id]);
ALTER TABLE [audit].[data_access_events] ADD CONSTRAINT [FK_audit_data_access_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [audit].[data_access_events] ADD CONSTRAINT [FK_audit_data_access_events_2] FOREIGN KEY ([actor_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_audit_data_access_events_1] ON [audit].[data_access_events] ([tenant_id], [actor_id]);
ALTER TABLE [audit].[export_events] ADD CONSTRAINT [FK_audit_export_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [audit].[export_events] ADD CONSTRAINT [FK_audit_export_events_2] FOREIGN KEY ([user_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_audit_export_events_1] ON [audit].[export_events] ([tenant_id], [user_id]);
ALTER TABLE [audit].[approval_events] ADD CONSTRAINT [FK_audit_approval_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [audit].[approval_events] ADD CONSTRAINT [FK_audit_approval_events_2] FOREIGN KEY ([tenant_id], [approved_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
CREATE INDEX [IX_audit_approval_events_1] ON [audit].[approval_events] ([tenant_id], [approved_by]);
COMMIT TRANSACTION;
GO
