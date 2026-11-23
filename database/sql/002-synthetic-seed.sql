-- SYNTHETIC ONLY. Run on an isolated local DB before enabling RLS. Never run on production.
-- Requires explicit operator opt-in using the sqlcmd variable ALLOW_SYNTHETIC=YES.
SET XACT_ABORT ON;
IF N'$(ALLOW_SYNTHETIC)' <> N'YES' THROW 50000, 'Synthetic seed not enabled', 1;
BEGIN TRANSACTION;
IF NOT EXISTS (SELECT 1 FROM ref.currencies WHERE [code] = N'USD')
    INSERT INTO ref.currencies ([code], [name]) VALUES (N'USD', N'US Dollar');
IF NOT EXISTS (SELECT 1 FROM ref.countries WHERE [code] = N'US')
    INSERT INTO ref.countries ([code], [name]) VALUES (N'US', N'United States');
DECLARE @us SMALLINT = (SELECT id FROM ref.countries WHERE code = N'US');
IF NOT EXISTS (SELECT 1 FROM ref.jurisdictions WHERE country_id = @us AND code = N'AZ')
    INSERT INTO ref.jurisdictions ([country_id], [code], [name]) VALUES (@us, N'AZ', N'Arizona');
IF NOT EXISTS (SELECT 1 FROM ref.asset_types WHERE [code] = N'TRACTOR')
    INSERT INTO ref.asset_types ([code], [name]) VALUES (N'TRACTOR', N'Tractor');
IF NOT EXISTS (SELECT 1 FROM ref.fuel_types WHERE [code] = N'DIESEL')
    INSERT INTO ref.fuel_types ([code], [name]) VALUES (N'DIESEL', N'Diesel');
IF NOT EXISTS (SELECT 1 FROM iam.permissions WHERE [id] = N'f11f5433-a442-5149-b573-3053d7416484')
    INSERT INTO iam.permissions ([id], [code], [resource], [action]) VALUES (N'f11f5433-a442-5149-b573-3053d7416484', N'fleet.vehicle.read', N'fleet.vehicle', N'read');
IF NOT EXISTS (SELECT 1 FROM iam.permissions WHERE [id] = N'6a4cad1b-8971-50e0-a213-29501a939c54')
    INSERT INTO iam.permissions ([id], [code], [resource], [action]) VALUES (N'6a4cad1b-8971-50e0-a213-29501a939c54', N'fleet.vehicle.create', N'fleet.vehicle', N'create');
IF NOT EXISTS (SELECT 1 FROM core.tenants WHERE [id] = N'07550486-be04-5574-92e6-057343eb615a')
    INSERT INTO core.tenants ([id], [name], [slug], [status], [timezone], [currency_code]) VALUES (N'07550486-be04-5574-92e6-057343eb615a', N'Synthetic Carrier A', N'synthetic-carrier-a', N'ACTIVE', N'America/Phoenix', N'USD');
IF NOT EXISTS (SELECT 1 FROM core.tenants WHERE [id] = N'f4b4a94a-df48-56df-8ccf-18315312182a')
    INSERT INTO core.tenants ([id], [name], [slug], [status], [timezone], [currency_code]) VALUES (N'f4b4a94a-df48-56df-8ccf-18315312182a', N'Synthetic Carrier B', N'synthetic-carrier-b', N'ACTIVE', N'America/Phoenix', N'USD');
IF NOT EXISTS (SELECT 1 FROM iam.users WHERE [id] = N'cc7aba77-bd3c-5dde-acca-e47d981c7f89')
    INSERT INTO iam.users ([id], [auth_provider], [external_subject], [email], [display_name], [status]) VALUES (N'cc7aba77-bd3c-5dde-acca-e47d981c7f89', N'TEST_FIXTURE', N'fixture-user-a', N'fleet-a@example.invalid', N'Synthetic Dispatcher A', N'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM iam.users WHERE [id] = N'd3baa832-94c3-5dd5-a2da-ea3464909af5')
    INSERT INTO iam.users ([id], [auth_provider], [external_subject], [email], [display_name], [status]) VALUES (N'd3baa832-94c3-5dd5-a2da-ea3464909af5', N'TEST_FIXTURE', N'fixture-user-b', N'fleet-b@example.invalid', N'Synthetic Dispatcher B', N'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM iam.memberships WHERE [id] = N'852959ac-0d80-5b30-b618-9fe17f707a27')
    INSERT INTO iam.memberships ([id], [tenant_id], [user_id], [status]) VALUES (N'852959ac-0d80-5b30-b618-9fe17f707a27', N'07550486-be04-5574-92e6-057343eb615a', N'cc7aba77-bd3c-5dde-acca-e47d981c7f89', N'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM iam.memberships WHERE [id] = N'f92544eb-2f08-519f-b4d1-a2c0a74046b8')
    INSERT INTO iam.memberships ([id], [tenant_id], [user_id], [status]) VALUES (N'f92544eb-2f08-519f-b4d1-a2c0a74046b8', N'f4b4a94a-df48-56df-8ccf-18315312182a', N'd3baa832-94c3-5dd5-a2da-ea3464909af5', N'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM iam.roles WHERE [id] = N'654db1c3-306c-5888-bf96-efc21f2fe139')
    INSERT INTO iam.roles ([id], [tenant_id], [code], [name], [system_role]) VALUES (N'654db1c3-306c-5888-bf96-efc21f2fe139', N'07550486-be04-5574-92e6-057343eb615a', N'DISPATCHER', N'Dispatcher', 1);
IF NOT EXISTS (SELECT 1 FROM iam.roles WHERE [id] = N'3cd6a348-4f0a-5522-a5ca-4a7959feee06')
    INSERT INTO iam.roles ([id], [tenant_id], [code], [name], [system_role]) VALUES (N'3cd6a348-4f0a-5522-a5ca-4a7959feee06', N'f4b4a94a-df48-56df-8ccf-18315312182a', N'DISPATCHER', N'Dispatcher', 1);
IF NOT EXISTS (SELECT 1 FROM iam.membership_roles WHERE [id] = N'ea293d9d-03a6-5dc6-8296-d0897b4f2789')
    INSERT INTO iam.membership_roles ([id], [tenant_id], [membership_id], [role_id]) VALUES (N'ea293d9d-03a6-5dc6-8296-d0897b4f2789', N'07550486-be04-5574-92e6-057343eb615a', N'852959ac-0d80-5b30-b618-9fe17f707a27', N'654db1c3-306c-5888-bf96-efc21f2fe139');
IF NOT EXISTS (SELECT 1 FROM iam.membership_roles WHERE [id] = N'a0c8aeaf-c5f6-5d13-a683-d0086d3f45f7')
    INSERT INTO iam.membership_roles ([id], [tenant_id], [membership_id], [role_id]) VALUES (N'a0c8aeaf-c5f6-5d13-a683-d0086d3f45f7', N'f4b4a94a-df48-56df-8ccf-18315312182a', N'f92544eb-2f08-519f-b4d1-a2c0a74046b8', N'3cd6a348-4f0a-5522-a5ca-4a7959feee06');
IF NOT EXISTS (SELECT 1 FROM iam.role_permissions WHERE [id] = N'48e60bb5-084d-525d-b7a2-711614235340')
    INSERT INTO iam.role_permissions ([id], [tenant_id], [role_id], [permission_id]) VALUES (N'48e60bb5-084d-525d-b7a2-711614235340', N'07550486-be04-5574-92e6-057343eb615a', N'654db1c3-306c-5888-bf96-efc21f2fe139', N'f11f5433-a442-5149-b573-3053d7416484');
IF NOT EXISTS (SELECT 1 FROM iam.role_permissions WHERE [id] = N'b4d9f1fc-935d-5d37-a169-122246e1bee5')
    INSERT INTO iam.role_permissions ([id], [tenant_id], [role_id], [permission_id]) VALUES (N'b4d9f1fc-935d-5d37-a169-122246e1bee5', N'07550486-be04-5574-92e6-057343eb615a', N'654db1c3-306c-5888-bf96-efc21f2fe139', N'6a4cad1b-8971-50e0-a213-29501a939c54');
IF NOT EXISTS (SELECT 1 FROM iam.role_permissions WHERE [id] = N'0350c2fc-0126-5000-ace3-3658d604d544')
    INSERT INTO iam.role_permissions ([id], [tenant_id], [role_id], [permission_id]) VALUES (N'0350c2fc-0126-5000-ace3-3658d604d544', N'f4b4a94a-df48-56df-8ccf-18315312182a', N'3cd6a348-4f0a-5522-a5ca-4a7959feee06', N'f11f5433-a442-5149-b573-3053d7416484');
IF NOT EXISTS (SELECT 1 FROM core.terminals WHERE [id] = N'082d6501-789a-5c35-b819-9d73544dde99')
    INSERT INTO core.terminals ([id], [tenant_id], [code], [name], [timezone], [status]) VALUES (N'082d6501-789a-5c35-b819-9d73544dde99', N'07550486-be04-5574-92e6-057343eb615a', N'YARD-01', N'Synthetic Yard A', N'America/Phoenix', N'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM core.terminals WHERE [id] = N'7b3101ad-233f-566f-b7c7-79f458c2ac98')
    INSERT INTO core.terminals ([id], [tenant_id], [code], [name], [timezone], [status]) VALUES (N'7b3101ad-233f-566f-b7c7-79f458c2ac98', N'f4b4a94a-df48-56df-8ccf-18315312182a', N'YARD-01', N'Synthetic Yard B', N'America/Phoenix', N'ACTIVE');
IF NOT EXISTS (SELECT 1 FROM core.tenant_settings WHERE [id] = N'055c0bfc-b0c7-50ad-b067-38962ae74d3d')
    INSERT INTO core.tenant_settings ([id], [tenant_id], [setting_key], [setting_value]) VALUES (N'055c0bfc-b0c7-50ad-b067-38962ae74d3d', N'07550486-be04-5574-92e6-057343eb615a', N'demo_mode', N'{"enabled":true}');
IF NOT EXISTS (SELECT 1 FROM core.tenant_settings WHERE [id] = N'497a480e-5369-5bf4-9d1c-3462861bc6e7')
    INSERT INTO core.tenant_settings ([id], [tenant_id], [setting_key], [setting_value]) VALUES (N'497a480e-5369-5bf4-9d1c-3462861bc6e7', N'f4b4a94a-df48-56df-8ccf-18315312182a', N'demo_mode', N'{"enabled":true}');
IF NOT EXISTS (SELECT 1 FROM fleet.assets WHERE [id] = N'4498de1c-dae9-54be-9efa-a2f4b9c7a321')
    INSERT INTO fleet.assets ([id], [tenant_id], [unit_number], [asset_type_id], [make], [model], [model_year], [ownership_type], [terminal_id], [status], [currency_code]) VALUES (N'4498de1c-dae9-54be-9efa-a2f4b9c7a321', N'07550486-be04-5574-92e6-057343eb615a', N'TRK-001', (SELECT id FROM ref.asset_types WHERE code = 'TRACTOR'), N'Fictional', N'Demo Tractor', 2025, N'OWNED', N'082d6501-789a-5c35-b819-9d73544dde99', N'AVAILABLE', N'USD');
IF NOT EXISTS (SELECT 1 FROM fleet.assets WHERE [id] = N'fbd71305-9474-5885-a751-b15cc80c578f')
    INSERT INTO fleet.assets ([id], [tenant_id], [unit_number], [asset_type_id], [make], [model], [model_year], [ownership_type], [terminal_id], [status], [currency_code]) VALUES (N'fbd71305-9474-5885-a751-b15cc80c578f', N'f4b4a94a-df48-56df-8ccf-18315312182a', N'TRK-001', (SELECT id FROM ref.asset_types WHERE code = 'TRACTOR'), N'Fictional', N'Demo Tractor', 2025, N'OWNED', N'7b3101ad-233f-566f-b7c7-79f458c2ac98', N'AVAILABLE', N'USD');
IF NOT EXISTS (SELECT 1 FROM fleet.vehicles WHERE [id] = N'476af555-8b0a-55f1-853b-3a06994aacad')
    INSERT INTO fleet.vehicles ([id], [tenant_id], [asset_id], [plate_jurisdiction_id], [fuel_type_id]) VALUES (N'476af555-8b0a-55f1-853b-3a06994aacad', N'07550486-be04-5574-92e6-057343eb615a', N'4498de1c-dae9-54be-9efa-a2f4b9c7a321', (SELECT id FROM ref.jurisdictions WHERE country_id = @us AND code = N'AZ'), (SELECT id FROM ref.fuel_types WHERE code = 'DIESEL'));
IF NOT EXISTS (SELECT 1 FROM fleet.vehicles WHERE [id] = N'3d881360-1b33-558b-be6c-937aac8eb406')
    INSERT INTO fleet.vehicles ([id], [tenant_id], [asset_id], [plate_jurisdiction_id], [fuel_type_id]) VALUES (N'3d881360-1b33-558b-be6c-937aac8eb406', N'f4b4a94a-df48-56df-8ccf-18315312182a', N'fbd71305-9474-5885-a751-b15cc80c578f', (SELECT id FROM ref.jurisdictions WHERE country_id = @us AND code = N'AZ'), (SELECT id FROM ref.fuel_types WHERE code = 'DIESEL'));
COMMIT TRANSACTION;
GO
