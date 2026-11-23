-- FleetOps v1.1 generated SQL Server reference. Empty database only.
-- Run in explicitly selected dev database; do not use as a production migration.
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
GO
BEGIN TRANSACTION;
IF SCHEMA_ID(N'audit') IS NULL EXEC(N'CREATE SCHEMA [audit]');
IF SCHEMA_ID(N'core') IS NULL EXEC(N'CREATE SCHEMA [core]');
IF SCHEMA_ID(N'fleet') IS NULL EXEC(N'CREATE SCHEMA [fleet]');
IF SCHEMA_ID(N'iam') IS NULL EXEC(N'CREATE SCHEMA [iam]');
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

CREATE TABLE [ref].[asset_types] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_asset_types_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_asset_types] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_asset_types_1] UNIQUE ([code])
);

CREATE TABLE [ref].[fuel_types] (
    [id] SMALLINT IDENTITY(1,1) NOT NULL,
    [code] VARCHAR(30) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(3) NOT NULL CONSTRAINT [DF_ref_fuel_types_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ref_fuel_types] PRIMARY KEY ([id]),
    CONSTRAINT [UQ_ref_fuel_types_1] UNIQUE ([code])
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
ALTER TABLE [core].[tenants] ADD CONSTRAINT [FK_core_tenants_1] FOREIGN KEY ([currency_code]) REFERENCES [ref].[currencies] ([code]);
CREATE INDEX [IX_core_tenants_1] ON [core].[tenants] ([currency_code]);
ALTER TABLE [core].[tenant_settings] ADD CONSTRAINT [FK_core_tenant_settings_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [core].[tenant_settings] ADD CONSTRAINT [FK_core_tenant_settings_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[tenant_settings] ADD CONSTRAINT [FK_core_tenant_settings_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[terminals] ADD CONSTRAINT [FK_core_terminals_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [core].[terminals] ADD CONSTRAINT [FK_core_terminals_2] FOREIGN KEY ([tenant_id], [created_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
ALTER TABLE [core].[terminals] ADD CONSTRAINT [FK_core_terminals_3] FOREIGN KEY ([tenant_id], [updated_by]) REFERENCES [iam].[memberships] ([tenant_id], [id]);
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
ALTER TABLE [audit].[audit_events] ADD CONSTRAINT [FK_audit_audit_events_1] FOREIGN KEY ([tenant_id]) REFERENCES [core].[tenants] ([id]);
ALTER TABLE [audit].[audit_events] ADD CONSTRAINT [FK_audit_audit_events_2] FOREIGN KEY ([actor_id]) REFERENCES [iam].[users] ([id]);
CREATE INDEX [IX_audit_audit_events_1] ON [audit].[audit_events] ([tenant_id], [actor_id]);
CREATE INDEX [IX_audit_audit_events_2] ON [audit].[audit_events] ([tenant_id], [entity_type], [entity_id], [occurred_at]);
COMMIT TRANSACTION;
GO
