# Table-by-table SQL Server constraints and indexes

Names correspond to generated DDL. All references use NO ACTION; tenant-owned parent relationships include tenant_id. SQL CHECK predicates permit UNKNOWN for nullable operands unless explicitly required. See business-rules.md for transactional rules and state constraints that are not expressible as row checks.

## `core.tenants`
- `PK_core_tenants`: PRIMARY KEY (id)
- `UQ_core_tenants_1`: UNIQUE (slug)
- `FK_core_tenants_1`: (currency_code) → `ref.currencies` (code)
- `CK_core_tenants_1`: CHECK (`status IN ('ACTIVE','SUSPENDED','INACTIVE')`)
- `IX_core_tenants_1`: INDEX (currency_code)

## `core.tenant_settings`
- `PK_core_tenant_settings`: PRIMARY KEY (id)
- `UQ_core_tenant_settings_1`: UNIQUE (tenant_id, id)
- `UQ_core_tenant_settings_2`: UNIQUE (tenant_id, setting_key)
- `FK_core_tenant_settings_1`: (tenant_id) → `core.tenants` (id)
- `FK_core_tenant_settings_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_core_tenant_settings_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_core_tenant_settings_1`: CHECK (`ISJSON(setting_value) = 1`)

## `core.terminals`
- `PK_core_terminals`: PRIMARY KEY (id)
- `UQ_core_terminals_1`: UNIQUE (tenant_id, id)
- `UQ_core_terminals_2`: UNIQUE (tenant_id, code)
- `FK_core_terminals_1`: (tenant_id) → `core.tenants` (id)
- `FK_core_terminals_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_core_terminals_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `core.departments`
- `PK_core_departments`: PRIMARY KEY (id)
- `UQ_core_departments_1`: UNIQUE (tenant_id, id)
- `UQ_core_departments_2`: UNIQUE (tenant_id, code)
- `FK_core_departments_1`: (tenant_id) → `core.tenants` (id)
- `FK_core_departments_2`: (tenant_id, terminal_id) → `core.terminals` (tenant_id, id)
- `FK_core_departments_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_core_departments_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_core_departments_1`: INDEX (tenant_id, terminal_id)

## `core.business_entities`
- `PK_core_business_entities`: PRIMARY KEY (id)
- `UQ_core_business_entities_1`: UNIQUE (tenant_id, id)
- `FK_core_business_entities_1`: (tenant_id) → `core.tenants` (id)
- `FK_core_business_entities_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_core_business_entities_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `core.number_sequences`
- `PK_core_number_sequences`: PRIMARY KEY (id)
- `UQ_core_number_sequences_1`: UNIQUE (tenant_id, id)
- `UQ_core_number_sequences_2`: UNIQUE (tenant_id, entity_type)
- `FK_core_number_sequences_1`: (tenant_id) → `core.tenants` (id)
- `FK_core_number_sequences_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_core_number_sequences_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_core_number_sequences_1`: CHECK (`next_number > 0`)

## `ref.countries`
- `PK_ref_countries`: PRIMARY KEY (id)
- `UQ_ref_countries_1`: UNIQUE (code)

## `ref.jurisdictions`
- `PK_ref_jurisdictions`: PRIMARY KEY (id)
- `UQ_ref_jurisdictions_1`: UNIQUE (country_id, code)
- `FK_ref_jurisdictions_1`: (country_id) → `ref.countries` (id)

## `ref.currencies`
- `PK_ref_currencies`: PRIMARY KEY (code)

## `ref.units_of_measure`
- `PK_ref_units_of_measure`: PRIMARY KEY (id)
- `UQ_ref_units_of_measure_1`: UNIQUE (code)

## `ref.asset_types`
- `PK_ref_asset_types`: PRIMARY KEY (id)
- `UQ_ref_asset_types_1`: UNIQUE (code)

## `ref.trailer_types`
- `PK_ref_trailer_types`: PRIMARY KEY (id)
- `UQ_ref_trailer_types_1`: UNIQUE (code)

## `ref.fuel_types`
- `PK_ref_fuel_types`: PRIMARY KEY (id)
- `UQ_ref_fuel_types_1`: UNIQUE (code)

## `ref.expense_categories`
- `PK_ref_expense_categories`: PRIMARY KEY (id)
- `UQ_ref_expense_categories_1`: UNIQUE (code)

## `ref.revenue_categories`
- `PK_ref_revenue_categories`: PRIMARY KEY (id)
- `UQ_ref_revenue_categories_1`: UNIQUE (code)

## `ref.maintenance_types`
- `PK_ref_maintenance_types`: PRIMARY KEY (id)
- `UQ_ref_maintenance_types_1`: UNIQUE (code)

## `ref.document_types`
- `PK_ref_document_types`: PRIMARY KEY (id)
- `UQ_ref_document_types_1`: UNIQUE (code)

## `ref.exception_types`
- `PK_ref_exception_types`: PRIMARY KEY (id)
- `UQ_ref_exception_types_1`: UNIQUE (code)

## `ref.contact_types`
- `PK_ref_contact_types`: PRIMARY KEY (id)
- `UQ_ref_contact_types_1`: UNIQUE (code)

## `iam.users`
- `PK_iam_users`: PRIMARY KEY (id)
- `UQ_iam_users_1`: UNIQUE (auth_provider, external_subject)
- `CK_iam_users_1`: CHECK (`status IN ('ACTIVE','DISABLED','INVITED')`)

## `iam.memberships`
- `PK_iam_memberships`: PRIMARY KEY (id)
- `UQ_iam_memberships_1`: UNIQUE (tenant_id, id)
- `UQ_iam_memberships_2`: UNIQUE (tenant_id, user_id)
- `FK_iam_memberships_1`: (tenant_id) → `core.tenants` (id)
- `FK_iam_memberships_2`: (user_id) → `iam.users` (id)
- `FK_iam_memberships_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_iam_memberships_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_iam_memberships_1`: CHECK (`status IN ('ACTIVE','SUSPENDED','INVITED','REVOKED')`)

## `iam.roles`
- `PK_iam_roles`: PRIMARY KEY (id)
- `UQ_iam_roles_1`: UNIQUE (tenant_id, id)
- `UQ_iam_roles_2`: UNIQUE (tenant_id, code)
- `FK_iam_roles_1`: (tenant_id) → `core.tenants` (id)
- `FK_iam_roles_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_iam_roles_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `iam.permissions`
- `PK_iam_permissions`: PRIMARY KEY (id)
- `UQ_iam_permissions_1`: UNIQUE (code)

## `iam.membership_roles`
- `PK_iam_membership_roles`: PRIMARY KEY (id)
- `UQ_iam_membership_roles_1`: UNIQUE (tenant_id, id)
- `UQ_iam_membership_roles_2`: UNIQUE (tenant_id, membership_id, role_id)
- `FK_iam_membership_roles_1`: (tenant_id) → `core.tenants` (id)
- `FK_iam_membership_roles_2`: (tenant_id, membership_id) → `iam.memberships` (tenant_id, id)
- `FK_iam_membership_roles_3`: (tenant_id, role_id) → `iam.roles` (tenant_id, id)
- `FK_iam_membership_roles_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_iam_membership_roles_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_iam_membership_roles_1`: INDEX (tenant_id, role_id)

## `iam.role_permissions`
- `PK_iam_role_permissions`: PRIMARY KEY (id)
- `UQ_iam_role_permissions_1`: UNIQUE (tenant_id, id)
- `UQ_iam_role_permissions_2`: UNIQUE (tenant_id, role_id, permission_id)
- `FK_iam_role_permissions_1`: (tenant_id) → `core.tenants` (id)
- `FK_iam_role_permissions_2`: (tenant_id, role_id) → `iam.roles` (tenant_id, id)
- `FK_iam_role_permissions_3`: (permission_id) → `iam.permissions` (id)
- `FK_iam_role_permissions_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_iam_role_permissions_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_iam_role_permissions_1`: INDEX (tenant_id, permission_id)

## `iam.user_preferences`
- `PK_iam_user_preferences`: PRIMARY KEY (id)
- `UQ_iam_user_preferences_1`: UNIQUE (tenant_id, id)
- `UQ_iam_user_preferences_2`: UNIQUE (tenant_id, membership_id)
- `FK_iam_user_preferences_1`: (tenant_id) → `core.tenants` (id)
- `FK_iam_user_preferences_2`: (tenant_id, membership_id) → `iam.memberships` (tenant_id, id)
- `FK_iam_user_preferences_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_iam_user_preferences_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `iam.invitations`
- `PK_iam_invitations`: PRIMARY KEY (id)
- `UQ_iam_invitations_1`: UNIQUE (tenant_id, id)
- `FK_iam_invitations_1`: (tenant_id) → `core.tenants` (id)
- `FK_iam_invitations_2`: (tenant_id, invited_role_id) → `iam.roles` (tenant_id, id)
- `FK_iam_invitations_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_iam_invitations_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_iam_invitations_1`: INDEX (tenant_id, invited_role_id)

## `iam.terminal_access`
- `PK_iam_terminal_access`: PRIMARY KEY (id)
- `UQ_iam_terminal_access_1`: UNIQUE (tenant_id, id)
- `UQ_iam_terminal_access_2`: UNIQUE (tenant_id, membership_id, terminal_id)
- `FK_iam_terminal_access_1`: (tenant_id) → `core.tenants` (id)
- `FK_iam_terminal_access_2`: (tenant_id, membership_id) → `iam.memberships` (tenant_id, id)
- `FK_iam_terminal_access_3`: (tenant_id, terminal_id) → `core.terminals` (tenant_id, id)
- `FK_iam_terminal_access_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_iam_terminal_access_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_iam_terminal_access_1`: INDEX (tenant_id, terminal_id)

## `fleet.assets`
- `PK_fleet_assets`: PRIMARY KEY (id)
- `UQ_fleet_assets_1`: UNIQUE (tenant_id, id)
- `UQ_fleet_assets_2`: UNIQUE (tenant_id, unit_number)
- `FK_fleet_assets_1`: (tenant_id) → `core.tenants` (id)
- `FK_fleet_assets_2`: (asset_type_id) → `ref.asset_types` (id)
- `FK_fleet_assets_3`: (tenant_id, terminal_id) → `core.terminals` (tenant_id, id)
- `FK_fleet_assets_4`: (currency_code) → `ref.currencies` (code)
- `FK_fleet_assets_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fleet_assets_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fleet_assets_1`: CHECK (`status IN ('AVAILABLE','ASSIGNED','IN_TRANSIT','MAINTENANCE','OUT_OF_SERVICE','INACTIVE')`)
- `CK_fleet_assets_2`: CHECK (`ownership_type IN ('OWNED','LEASED','CONTRACTED')`)
- `CK_fleet_assets_3`: CHECK (`model_year BETWEEN 1900 AND 2100`)
- `CK_fleet_assets_4`: CHECK (`vin IS NULL OR LEN(vin)=17`)
- `IX_fleet_assets_1`: UNIQUE INDEX (tenant_id, vin) WHERE `vin IS NOT NULL`
- `IX_fleet_assets_2`: INDEX (tenant_id, asset_type_id)
- `IX_fleet_assets_3`: INDEX (tenant_id, terminal_id)
- `IX_fleet_assets_4`: INDEX (tenant_id, currency_code)
- `IX_fleet_assets_5`: INDEX (tenant_id, status, terminal_id)

## `fleet.vehicles`
- `PK_fleet_vehicles`: PRIMARY KEY (id)
- `UQ_fleet_vehicles_1`: UNIQUE (tenant_id, id)
- `UQ_fleet_vehicles_2`: UNIQUE (tenant_id, asset_id)
- `FK_fleet_vehicles_1`: (tenant_id) → `core.tenants` (id)
- `FK_fleet_vehicles_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fleet_vehicles_3`: (plate_jurisdiction_id) → `ref.jurisdictions` (id)
- `FK_fleet_vehicles_4`: (fuel_type_id) → `ref.fuel_types` (id)
- `FK_fleet_vehicles_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fleet_vehicles_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fleet_vehicles_1`: CHECK (`fuel_capacity >= 0`)
- `CK_fleet_vehicles_2`: CHECK (`gross_vehicle_weight >= 0`)
- `IX_fleet_vehicles_1`: INDEX (tenant_id, plate_jurisdiction_id)
- `IX_fleet_vehicles_2`: INDEX (tenant_id, fuel_type_id)

## `fleet.trailers`
- `PK_fleet_trailers`: PRIMARY KEY (id)
- `UQ_fleet_trailers_1`: UNIQUE (tenant_id, id)
- `UQ_fleet_trailers_2`: UNIQUE (tenant_id, asset_id)
- `FK_fleet_trailers_1`: (tenant_id) → `core.tenants` (id)
- `FK_fleet_trailers_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fleet_trailers_3`: (trailer_type_id) → `ref.trailer_types` (id)
- `FK_fleet_trailers_4`: (plate_jurisdiction_id) → `ref.jurisdictions` (id)
- `FK_fleet_trailers_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fleet_trailers_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fleet_trailers_1`: INDEX (tenant_id, trailer_type_id)
- `IX_fleet_trailers_2`: INDEX (tenant_id, plate_jurisdiction_id)

## `fleet.asset_status_history`
- `PK_fleet_asset_status_history`: PRIMARY KEY (id)
- `UQ_fleet_asset_status_history_1`: UNIQUE (tenant_id, id)
- `FK_fleet_asset_status_history_1`: (tenant_id) → `core.tenants` (id)
- `FK_fleet_asset_status_history_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fleet_asset_status_history_3`: (actor_id) → `iam.users` (id)
- `IX_fleet_asset_status_history_1`: INDEX (tenant_id, asset_id)
- `IX_fleet_asset_status_history_2`: INDEX (tenant_id, actor_id)

## `fleet.odometer_readings`
- `PK_fleet_odometer_readings`: PRIMARY KEY (id)
- `UQ_fleet_odometer_readings_1`: UNIQUE (tenant_id, id)
- `FK_fleet_odometer_readings_1`: (tenant_id) → `core.tenants` (id)
- `FK_fleet_odometer_readings_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fleet_odometer_readings_3`: (unit_id) → `ref.units_of_measure` (id)
- `CK_fleet_odometer_readings_1`: CHECK (`reading >= 0`)
- `IX_fleet_odometer_readings_1`: INDEX (tenant_id, asset_id)
- `IX_fleet_odometer_readings_2`: INDEX (tenant_id, unit_id)

## `fleet.engine_hour_readings`
- `PK_fleet_engine_hour_readings`: PRIMARY KEY (id)
- `UQ_fleet_engine_hour_readings_1`: UNIQUE (tenant_id, id)
- `FK_fleet_engine_hour_readings_1`: (tenant_id) → `core.tenants` (id)
- `FK_fleet_engine_hour_readings_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `CK_fleet_engine_hour_readings_1`: CHECK (`engine_hours >= 0`)
- `IX_fleet_engine_hour_readings_1`: INDEX (tenant_id, asset_id)

## `fleet.asset_availability`
- `PK_fleet_asset_availability`: PRIMARY KEY (id)
- `UQ_fleet_asset_availability_1`: UNIQUE (tenant_id, id)
- `FK_fleet_asset_availability_1`: (tenant_id) → `core.tenants` (id)
- `FK_fleet_asset_availability_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fleet_asset_availability_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fleet_asset_availability_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fleet_asset_availability_1`: CHECK (`end_at >= start_at`)
- `IX_fleet_asset_availability_1`: INDEX (tenant_id, asset_id)

## `fleet.ownership_agreements`
- `PK_fleet_ownership_agreements`: PRIMARY KEY (id)
- `UQ_fleet_ownership_agreements_1`: UNIQUE (tenant_id, id)
- `FK_fleet_ownership_agreements_1`: (tenant_id) → `core.tenants` (id)
- `FK_fleet_ownership_agreements_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fleet_ownership_agreements_3`: (tenant_id, vendor_id) → `mnt.vendors` (tenant_id, id)
- `FK_fleet_ownership_agreements_4`: (currency_code) → `ref.currencies` (code)
- `FK_fleet_ownership_agreements_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fleet_ownership_agreements_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fleet_ownership_agreements_1`: CHECK (`end_date >= start_date`)
- `IX_fleet_ownership_agreements_1`: INDEX (tenant_id, asset_id)
- `IX_fleet_ownership_agreements_2`: INDEX (tenant_id, vendor_id)
- `IX_fleet_ownership_agreements_3`: INDEX (tenant_id, currency_code)

## `fleet.asset_meter_adjustments`
- `PK_fleet_asset_meter_adjustments`: PRIMARY KEY (id)
- `UQ_fleet_asset_meter_adjustments_1`: UNIQUE (tenant_id, id)
- `FK_fleet_asset_meter_adjustments_1`: (tenant_id) → `core.tenants` (id)
- `FK_fleet_asset_meter_adjustments_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fleet_asset_meter_adjustments_3`: (actor_id) → `iam.users` (id)
- `IX_fleet_asset_meter_adjustments_1`: INDEX (tenant_id, asset_id)
- `IX_fleet_asset_meter_adjustments_2`: INDEX (tenant_id, actor_id)

## `hr.drivers`
- `PK_hr_drivers`: PRIMARY KEY (id)
- `UQ_hr_drivers_1`: UNIQUE (tenant_id, id)
- `UQ_hr_drivers_2`: UNIQUE (tenant_id, driver_number)
- `FK_hr_drivers_1`: (tenant_id) → `core.tenants` (id)
- `FK_hr_drivers_2`: (tenant_id, membership_id) → `iam.memberships` (tenant_id, id)
- `FK_hr_drivers_3`: (tenant_id, terminal_id) → `core.terminals` (tenant_id, id)
- `FK_hr_drivers_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_hr_drivers_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_hr_drivers_1`: CHECK (`status IN ('ACTIVE','SUSPENDED','INACTIVE')`)
- `CK_hr_drivers_2`: CHECK (`employment_type IN ('COMPANY','CONTRACTOR','OWNER_OPERATOR')`)
- `IX_hr_drivers_1`: INDEX (tenant_id, membership_id)
- `IX_hr_drivers_2`: INDEX (tenant_id, terminal_id)
- `IX_hr_drivers_3`: INDEX (tenant_id, status, driver_number)

## `hr.driver_licenses`
- `PK_hr_driver_licenses`: PRIMARY KEY (id)
- `UQ_hr_driver_licenses_1`: UNIQUE (tenant_id, id)
- `FK_hr_driver_licenses_1`: (tenant_id) → `core.tenants` (id)
- `FK_hr_driver_licenses_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_hr_driver_licenses_3`: (jurisdiction_id) → `ref.jurisdictions` (id)
- `FK_hr_driver_licenses_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_hr_driver_licenses_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_hr_driver_licenses_1`: CHECK (`expiry_date >= issued_date`)
- `IX_hr_driver_licenses_1`: INDEX (tenant_id, driver_id)
- `IX_hr_driver_licenses_2`: INDEX (tenant_id, jurisdiction_id)

## `hr.driver_endorsements`
- `PK_hr_driver_endorsements`: PRIMARY KEY (id)
- `UQ_hr_driver_endorsements_1`: UNIQUE (tenant_id, id)
- `UQ_hr_driver_endorsements_2`: UNIQUE (tenant_id, driver_license_id, endorsement_code)
- `FK_hr_driver_endorsements_1`: (tenant_id) → `core.tenants` (id)
- `FK_hr_driver_endorsements_2`: (tenant_id, driver_license_id) → `hr.driver_licenses` (tenant_id, id)
- `FK_hr_driver_endorsements_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_hr_driver_endorsements_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `hr.driver_qualifications`
- `PK_hr_driver_qualifications`: PRIMARY KEY (id)
- `UQ_hr_driver_qualifications_1`: UNIQUE (tenant_id, id)
- `FK_hr_driver_qualifications_1`: (tenant_id) → `core.tenants` (id)
- `FK_hr_driver_qualifications_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_hr_driver_qualifications_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_hr_driver_qualifications_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_hr_driver_qualifications_1`: INDEX (tenant_id, driver_id)

## `hr.driver_availability`
- `PK_hr_driver_availability`: PRIMARY KEY (id)
- `UQ_hr_driver_availability_1`: UNIQUE (tenant_id, id)
- `FK_hr_driver_availability_1`: (tenant_id) → `core.tenants` (id)
- `FK_hr_driver_availability_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_hr_driver_availability_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_hr_driver_availability_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_hr_driver_availability_1`: CHECK (`end_at >= start_at`)
- `IX_hr_driver_availability_1`: INDEX (tenant_id, driver_id)

## `hr.driver_time_off`
- `PK_hr_driver_time_off`: PRIMARY KEY (id)
- `UQ_hr_driver_time_off_1`: UNIQUE (tenant_id, id)
- `FK_hr_driver_time_off_1`: (tenant_id) → `core.tenants` (id)
- `FK_hr_driver_time_off_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_hr_driver_time_off_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_hr_driver_time_off_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_hr_driver_time_off_1`: CHECK (`end_date >= start_date`)
- `IX_hr_driver_time_off_1`: INDEX (tenant_id, driver_id)

## `hr.driver_emergency_contacts`
- `PK_hr_driver_emergency_contacts`: PRIMARY KEY (id)
- `UQ_hr_driver_emergency_contacts_1`: UNIQUE (tenant_id, id)
- `FK_hr_driver_emergency_contacts_1`: (tenant_id) → `core.tenants` (id)
- `FK_hr_driver_emergency_contacts_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_hr_driver_emergency_contacts_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_hr_driver_emergency_contacts_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_hr_driver_emergency_contacts_1`: INDEX (tenant_id, driver_id)

## `hr.driver_compensation_profiles`
- `PK_hr_driver_compensation_profiles`: PRIMARY KEY (id)
- `UQ_hr_driver_compensation_profiles_1`: UNIQUE (tenant_id, id)
- `FK_hr_driver_compensation_profiles_1`: (tenant_id) → `core.tenants` (id)
- `FK_hr_driver_compensation_profiles_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_hr_driver_compensation_profiles_3`: (currency_code) → `ref.currencies` (code)
- `FK_hr_driver_compensation_profiles_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_hr_driver_compensation_profiles_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_hr_driver_compensation_profiles_1`: CHECK (`effective_to >= effective_from`)
- `IX_hr_driver_compensation_profiles_1`: INDEX (tenant_id, driver_id)
- `IX_hr_driver_compensation_profiles_2`: INDEX (tenant_id, currency_code)

## `hr.driver_status_history`
- `PK_hr_driver_status_history`: PRIMARY KEY (id)
- `UQ_hr_driver_status_history_1`: UNIQUE (tenant_id, id)
- `FK_hr_driver_status_history_1`: (tenant_id) → `core.tenants` (id)
- `FK_hr_driver_status_history_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_hr_driver_status_history_3`: (actor_id) → `iam.users` (id)
- `IX_hr_driver_status_history_1`: INDEX (tenant_id, driver_id)
- `IX_hr_driver_status_history_2`: INDEX (tenant_id, actor_id)

## `crm.customers`
- `PK_crm_customers`: PRIMARY KEY (id)
- `UQ_crm_customers_1`: UNIQUE (tenant_id, id)
- `UQ_crm_customers_2`: UNIQUE (tenant_id, customer_code)
- `FK_crm_customers_1`: (tenant_id) → `core.tenants` (id)
- `FK_crm_customers_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_crm_customers_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_crm_customers_1`: CHECK (`payment_terms_days >= 0`)

## `crm.customer_contacts`
- `PK_crm_customer_contacts`: PRIMARY KEY (id)
- `UQ_crm_customer_contacts_1`: UNIQUE (tenant_id, id)
- `FK_crm_customer_contacts_1`: (tenant_id) → `core.tenants` (id)
- `FK_crm_customer_contacts_2`: (tenant_id, customer_id) → `crm.customers` (tenant_id, id)
- `FK_crm_customer_contacts_3`: (contact_type_id) → `ref.contact_types` (id)
- `FK_crm_customer_contacts_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_crm_customer_contacts_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_crm_customer_contacts_1`: INDEX (tenant_id, customer_id)
- `IX_crm_customer_contacts_2`: INDEX (tenant_id, contact_type_id)

## `crm.locations`
- `PK_crm_locations`: PRIMARY KEY (id)
- `UQ_crm_locations_1`: UNIQUE (tenant_id, id)
- `FK_crm_locations_1`: (tenant_id) → `core.tenants` (id)
- `FK_crm_locations_2`: (tenant_id, customer_id) → `crm.customers` (tenant_id, id)
- `FK_crm_locations_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_crm_locations_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_crm_locations_1`: CHECK (`latitude BETWEEN -90 AND 90`)
- `CK_crm_locations_2`: CHECK (`longitude BETWEEN -180 AND 180`)
- `CK_crm_locations_3`: CHECK (`(latitude IS NULL AND longitude IS NULL) OR (latitude IS NOT NULL AND longitude IS NOT NULL)`)
- `IX_crm_locations_1`: INDEX (tenant_id, customer_id)

## `crm.customer_contracts`
- `PK_crm_customer_contracts`: PRIMARY KEY (id)
- `UQ_crm_customer_contracts_1`: UNIQUE (tenant_id, id)
- `FK_crm_customer_contracts_1`: (tenant_id) → `core.tenants` (id)
- `FK_crm_customer_contracts_2`: (tenant_id, customer_id) → `crm.customers` (tenant_id, id)
- `FK_crm_customer_contracts_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_crm_customer_contracts_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_crm_customer_contracts_1`: CHECK (`end_date >= start_date`)
- `IX_crm_customer_contracts_1`: INDEX (tenant_id, customer_id)

## `crm.customer_rate_agreements`
- `PK_crm_customer_rate_agreements`: PRIMARY KEY (id)
- `UQ_crm_customer_rate_agreements_1`: UNIQUE (tenant_id, id)
- `FK_crm_customer_rate_agreements_1`: (tenant_id) → `core.tenants` (id)
- `FK_crm_customer_rate_agreements_2`: (tenant_id, contract_id) → `crm.customer_contracts` (tenant_id, id)
- `FK_crm_customer_rate_agreements_3`: (equipment_type_id) → `ref.asset_types` (id)
- `FK_crm_customer_rate_agreements_4`: (currency_code) → `ref.currencies` (code)
- `FK_crm_customer_rate_agreements_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_crm_customer_rate_agreements_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_crm_customer_rate_agreements_1`: INDEX (tenant_id, contract_id)
- `IX_crm_customer_rate_agreements_2`: INDEX (tenant_id, equipment_type_id)
- `IX_crm_customer_rate_agreements_3`: INDEX (tenant_id, currency_code)

## `crm.customer_notes`
- `PK_crm_customer_notes`: PRIMARY KEY (id)
- `UQ_crm_customer_notes_1`: UNIQUE (tenant_id, id)
- `FK_crm_customer_notes_1`: (tenant_id) → `core.tenants` (id)
- `FK_crm_customer_notes_2`: (tenant_id, customer_id) → `crm.customers` (tenant_id, id)
- `FK_crm_customer_notes_3`: (author_id) → `iam.users` (id)
- `FK_crm_customer_notes_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_crm_customer_notes_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_crm_customer_notes_1`: INDEX (tenant_id, customer_id)
- `IX_crm_customer_notes_2`: INDEX (tenant_id, author_id)

## `ops.loads`
- `PK_ops_loads`: PRIMARY KEY (id)
- `UQ_ops_loads_1`: UNIQUE (tenant_id, id)
- `UQ_ops_loads_2`: UNIQUE (tenant_id, load_number)
- `FK_ops_loads_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_loads_2`: (tenant_id, customer_id) → `crm.customers` (tenant_id, id)
- `FK_ops_loads_3`: (equipment_type_id) → `ref.asset_types` (id)
- `FK_ops_loads_4`: (currency_code) → `ref.currencies` (code)
- `FK_ops_loads_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_loads_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ops_loads_1`: CHECK (`weight_lbs >= 0`)
- `CK_ops_loads_2`: CHECK (`commercial_status IN ('DRAFT','BOOKED','CANCELLED','FULFILLED')`)
- `IX_ops_loads_1`: INDEX (tenant_id, customer_id)
- `IX_ops_loads_2`: INDEX (tenant_id, equipment_type_id)
- `IX_ops_loads_3`: INDEX (tenant_id, currency_code)
- `IX_ops_loads_4`: INDEX (tenant_id, commercial_status, created_at)

## `ops.load_stops`
- `PK_ops_load_stops`: PRIMARY KEY (id)
- `UQ_ops_load_stops_1`: UNIQUE (tenant_id, id)
- `UQ_ops_load_stops_2`: UNIQUE (tenant_id, load_id, sequence_number)
- `FK_ops_load_stops_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_load_stops_2`: (tenant_id, load_id) → `ops.loads` (tenant_id, id)
- `FK_ops_load_stops_3`: (tenant_id, location_id) → `crm.locations` (tenant_id, id)
- `FK_ops_load_stops_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_load_stops_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ops_load_stops_1`: CHECK (`sequence_number > 0`)
- `CK_ops_load_stops_2`: CHECK (`appointment_end >= appointment_start`)
- `CK_ops_load_stops_3`: CHECK (`stop_type IN ('PICKUP','DELIVERY','INTERMEDIATE')`)
- `IX_ops_load_stops_1`: INDEX (tenant_id, location_id)

## `ops.load_status_history`
- `PK_ops_load_status_history`: PRIMARY KEY (id)
- `UQ_ops_load_status_history_1`: UNIQUE (tenant_id, id)
- `FK_ops_load_status_history_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_load_status_history_2`: (tenant_id, load_id) → `ops.loads` (tenant_id, id)
- `FK_ops_load_status_history_3`: (actor_id) → `iam.users` (id)
- `IX_ops_load_status_history_1`: INDEX (tenant_id, load_id)
- `IX_ops_load_status_history_2`: INDEX (tenant_id, actor_id)

## `ops.trips`
- `PK_ops_trips`: PRIMARY KEY (id)
- `UQ_ops_trips_1`: UNIQUE (tenant_id, id)
- `UQ_ops_trips_2`: UNIQUE (tenant_id, trip_number)
- `FK_ops_trips_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_trips_2`: (tenant_id, dispatcher_id) → `iam.memberships` (tenant_id, id)
- `FK_ops_trips_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_trips_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ops_trips_1`: CHECK (`actual_end_at >= actual_start_at`)
- `CK_ops_trips_2`: CHECK (`planned_end_at >= planned_start_at`)
- `CK_ops_trips_3`: CHECK (`status IN ('DRAFT','PLANNED','ASSIGNED','EN_ROUTE_TO_PICKUP','AT_PICKUP','IN_TRANSIT','DELIVERED','CLOSED','CANCELLED')`)
- `IX_ops_trips_1`: INDEX (tenant_id, dispatcher_id)
- `IX_ops_trips_2`: INDEX (tenant_id, status, planned_start_at)

## `ops.trip_loads`
- `PK_ops_trip_loads`: PRIMARY KEY (id)
- `UQ_ops_trip_loads_1`: UNIQUE (tenant_id, id)
- `UQ_ops_trip_loads_2`: UNIQUE (tenant_id, trip_id, load_id)
- `UQ_ops_trip_loads_3`: UNIQUE (tenant_id, trip_id, sequence_number)
- `FK_ops_trip_loads_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_trip_loads_2`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_ops_trip_loads_3`: (tenant_id, load_id) → `ops.loads` (tenant_id, id)
- `FK_ops_trip_loads_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_trip_loads_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ops_trip_loads_1`: CHECK (`sequence_number > 0`)
- `IX_ops_trip_loads_1`: INDEX (tenant_id, load_id)

## `ops.trip_stops`
- `PK_ops_trip_stops`: PRIMARY KEY (id)
- `UQ_ops_trip_stops_1`: UNIQUE (tenant_id, id)
- `UQ_ops_trip_stops_2`: UNIQUE (tenant_id, trip_id, sequence_number)
- `FK_ops_trip_stops_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_trip_stops_2`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_ops_trip_stops_3`: (tenant_id, load_stop_id) → `ops.load_stops` (tenant_id, id)
- `FK_ops_trip_stops_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_trip_stops_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ops_trip_stops_1`: CHECK (`sequence_number > 0`)
- `CK_ops_trip_stops_2`: CHECK (`departure_at >= arrival_at`)
- `IX_ops_trip_stops_1`: INDEX (tenant_id, load_stop_id)

## `ops.trip_assignments`
- `PK_ops_trip_assignments`: PRIMARY KEY (id)
- `UQ_ops_trip_assignments_1`: UNIQUE (tenant_id, id)
- `FK_ops_trip_assignments_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_trip_assignments_2`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_ops_trip_assignments_3`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_ops_trip_assignments_4`: (tenant_id, vehicle_id) → `fleet.vehicles` (tenant_id, id)
- `FK_ops_trip_assignments_5`: (tenant_id, trailer_id) → `fleet.trailers` (tenant_id, id)
- `FK_ops_trip_assignments_6`: (tenant_id, assigned_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_trip_assignments_7`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_trip_assignments_8`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ops_trip_assignments_1`: CHECK (`effective_to >= effective_from`)
- `CK_ops_trip_assignments_2`: CHECK (`status IN ('ACTIVE','RELEASED','CANCELLED')`)
- `IX_ops_trip_assignments_1`: INDEX (tenant_id, trip_id)
- `IX_ops_trip_assignments_2`: INDEX (tenant_id, driver_id)
- `IX_ops_trip_assignments_3`: INDEX (tenant_id, vehicle_id)
- `IX_ops_trip_assignments_4`: INDEX (tenant_id, trailer_id)
- `IX_ops_trip_assignments_5`: INDEX (tenant_id, assigned_by)

## `ops.equipment_reservations`
- `PK_ops_equipment_reservations`: PRIMARY KEY (id)
- `UQ_ops_equipment_reservations_1`: UNIQUE (tenant_id, id)
- `FK_ops_equipment_reservations_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_equipment_reservations_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_ops_equipment_reservations_3`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_ops_equipment_reservations_4`: (tenant_id, assignment_id) → `ops.trip_assignments` (tenant_id, id)
- `FK_ops_equipment_reservations_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_equipment_reservations_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ops_equipment_reservations_1`: CHECK (`end_at > start_at`)
- `CK_ops_equipment_reservations_2`: CHECK (`status IN ('HELD','CONFIRMED','RELEASED','CANCELLED')`)
- `IX_ops_equipment_reservations_1`: INDEX (tenant_id, asset_id)
- `IX_ops_equipment_reservations_2`: INDEX (tenant_id, trip_id)
- `IX_ops_equipment_reservations_3`: INDEX (tenant_id, assignment_id)
- `IX_ops_equipment_reservations_4`: INDEX (tenant_id, asset_id, status, start_at, end_at)

## `ops.driver_reservations`
- `PK_ops_driver_reservations`: PRIMARY KEY (id)
- `UQ_ops_driver_reservations_1`: UNIQUE (tenant_id, id)
- `FK_ops_driver_reservations_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_driver_reservations_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_ops_driver_reservations_3`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_ops_driver_reservations_4`: (tenant_id, assignment_id) → `ops.trip_assignments` (tenant_id, id)
- `FK_ops_driver_reservations_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_driver_reservations_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ops_driver_reservations_1`: CHECK (`end_at > start_at`)
- `CK_ops_driver_reservations_2`: CHECK (`status IN ('HELD','CONFIRMED','RELEASED','CANCELLED')`)
- `IX_ops_driver_reservations_1`: INDEX (tenant_id, driver_id)
- `IX_ops_driver_reservations_2`: INDEX (tenant_id, trip_id)
- `IX_ops_driver_reservations_3`: INDEX (tenant_id, assignment_id)
- `IX_ops_driver_reservations_4`: INDEX (tenant_id, driver_id, status, start_at, end_at)

## `ops.trip_events`
- `PK_ops_trip_events`: PRIMARY KEY (id)
- `UQ_ops_trip_events_1`: UNIQUE (tenant_id, id)
- `UQ_ops_trip_events_2`: UNIQUE (tenant_id, trip_id, source, event_reference)
- `FK_ops_trip_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_trip_events_2`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_ops_trip_events_3`: (actor_id) → `iam.users` (id)
- `CK_ops_trip_events_1`: CHECK (`ISJSON(payload) = 1`)
- `IX_ops_trip_events_1`: INDEX (tenant_id, actor_id)

## `ops.trip_exceptions`
- `PK_ops_trip_exceptions`: PRIMARY KEY (id)
- `UQ_ops_trip_exceptions_1`: UNIQUE (tenant_id, id)
- `FK_ops_trip_exceptions_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_trip_exceptions_2`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_ops_trip_exceptions_3`: (exception_type_id) → `ref.exception_types` (id)
- `FK_ops_trip_exceptions_4`: (tenant_id, owner_id) → `iam.memberships` (tenant_id, id)
- `FK_ops_trip_exceptions_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_trip_exceptions_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_ops_trip_exceptions_1`: INDEX (tenant_id, trip_id)
- `IX_ops_trip_exceptions_2`: INDEX (tenant_id, exception_type_id)
- `IX_ops_trip_exceptions_3`: INDEX (tenant_id, owner_id)

## `ops.trip_distances`
- `PK_ops_trip_distances`: PRIMARY KEY (id)
- `UQ_ops_trip_distances_1`: UNIQUE (tenant_id, id)
- `UQ_ops_trip_distances_2`: UNIQUE (tenant_id, trip_id)
- `FK_ops_trip_distances_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_trip_distances_2`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_ops_trip_distances_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_trip_distances_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ops_trip_distances_1`: CHECK (`loaded_miles >= 0`)
- `CK_ops_trip_distances_2`: CHECK (`empty_miles >= 0`)

## `ops.trip_status_history`
- `PK_ops_trip_status_history`: PRIMARY KEY (id)
- `UQ_ops_trip_status_history_1`: UNIQUE (tenant_id, id)
- `FK_ops_trip_status_history_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_trip_status_history_2`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_ops_trip_status_history_3`: (actor_id) → `iam.users` (id)
- `IX_ops_trip_status_history_1`: INDEX (tenant_id, trip_id)
- `IX_ops_trip_status_history_2`: INDEX (tenant_id, actor_id)

## `ops.delivery_confirmations`
- `PK_ops_delivery_confirmations`: PRIMARY KEY (id)
- `UQ_ops_delivery_confirmations_1`: UNIQUE (tenant_id, id)
- `UQ_ops_delivery_confirmations_2`: UNIQUE (tenant_id, trip_stop_id)
- `FK_ops_delivery_confirmations_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_delivery_confirmations_2`: (tenant_id, trip_stop_id) → `ops.trip_stops` (tenant_id, id)
- `FK_ops_delivery_confirmations_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ops_delivery_confirmations_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `ops.trip_exception_events`
- `PK_ops_trip_exception_events`: PRIMARY KEY (id)
- `UQ_ops_trip_exception_events_1`: UNIQUE (tenant_id, id)
- `FK_ops_trip_exception_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_ops_trip_exception_events_2`: (tenant_id, exception_id) → `ops.trip_exceptions` (tenant_id, id)
- `FK_ops_trip_exception_events_3`: (actor_id) → `iam.users` (id)
- `IX_ops_trip_exception_events_1`: INDEX (tenant_id, exception_id)
- `IX_ops_trip_exception_events_2`: INDEX (tenant_id, actor_id)

## `integration.providers`
- `PK_integration_providers`: PRIMARY KEY (id)
- `UQ_integration_providers_1`: UNIQUE (provider_code)

## `integration.connections`
- `PK_integration_connections`: PRIMARY KEY (id)
- `UQ_integration_connections_1`: UNIQUE (tenant_id, id)
- `FK_integration_connections_1`: (tenant_id) → `core.tenants` (id)
- `FK_integration_connections_2`: (provider_id) → `integration.providers` (id)
- `FK_integration_connections_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_integration_connections_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_integration_connections_1`: INDEX (tenant_id, provider_id)

## `integration.external_mappings`
- `PK_integration_external_mappings`: PRIMARY KEY (id)
- `UQ_integration_external_mappings_1`: UNIQUE (tenant_id, id)
- `UQ_integration_external_mappings_2`: UNIQUE (tenant_id, connection_id, entity_type, external_id)
- `UQ_integration_external_mappings_3`: UNIQUE (tenant_id, connection_id, entity_type, internal_id)
- `FK_integration_external_mappings_1`: (tenant_id) → `core.tenants` (id)
- `FK_integration_external_mappings_2`: (tenant_id, connection_id) → `integration.connections` (tenant_id, id)
- `FK_integration_external_mappings_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_integration_external_mappings_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `integration.sync_jobs`
- `PK_integration_sync_jobs`: PRIMARY KEY (id)
- `UQ_integration_sync_jobs_1`: UNIQUE (tenant_id, id)
- `FK_integration_sync_jobs_1`: (tenant_id) → `core.tenants` (id)
- `FK_integration_sync_jobs_2`: (tenant_id, connection_id) → `integration.connections` (tenant_id, id)
- `FK_integration_sync_jobs_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_integration_sync_jobs_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_integration_sync_jobs_1`: INDEX (tenant_id, connection_id)

## `integration.sync_checkpoints`
- `PK_integration_sync_checkpoints`: PRIMARY KEY (id)
- `UQ_integration_sync_checkpoints_1`: UNIQUE (tenant_id, id)
- `UQ_integration_sync_checkpoints_2`: UNIQUE (tenant_id, connection_id, resource_type)
- `FK_integration_sync_checkpoints_1`: (tenant_id) → `core.tenants` (id)
- `FK_integration_sync_checkpoints_2`: (tenant_id, connection_id) → `integration.connections` (tenant_id, id)
- `FK_integration_sync_checkpoints_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_integration_sync_checkpoints_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `integration.webhook_events`
- `PK_integration_webhook_events`: PRIMARY KEY (id)
- `UQ_integration_webhook_events_1`: UNIQUE (tenant_id, id)
- `UQ_integration_webhook_events_2`: UNIQUE (tenant_id, connection_id, external_event_id)
- `FK_integration_webhook_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_integration_webhook_events_2`: (tenant_id, connection_id) → `integration.connections` (tenant_id, id)
- `FK_integration_webhook_events_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_integration_webhook_events_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_integration_webhook_events_1`: CHECK (`ISJSON(payload) = 1`)

## `integration.processing_failures`
- `PK_integration_processing_failures`: PRIMARY KEY (id)
- `UQ_integration_processing_failures_1`: UNIQUE (tenant_id, id)
- `FK_integration_processing_failures_1`: (tenant_id) → `core.tenants` (id)
- `FK_integration_processing_failures_2`: (tenant_id, sync_job_id) → `integration.sync_jobs` (tenant_id, id)
- `FK_integration_processing_failures_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_integration_processing_failures_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_integration_processing_failures_1`: CHECK (`retry_count >= 0`)
- `IX_integration_processing_failures_1`: INDEX (tenant_id, sync_job_id)

## `integration.import_batches`
- `PK_integration_import_batches`: PRIMARY KEY (id)
- `UQ_integration_import_batches_1`: UNIQUE (tenant_id, id)
- `FK_integration_import_batches_1`: (tenant_id) → `core.tenants` (id)
- `FK_integration_import_batches_2`: (imported_by) → `iam.users` (id)
- `FK_integration_import_batches_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_integration_import_batches_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_integration_import_batches_1`: INDEX (tenant_id, imported_by)

## `integration.import_errors`
- `PK_integration_import_errors`: PRIMARY KEY (id)
- `UQ_integration_import_errors_1`: UNIQUE (tenant_id, id)
- `FK_integration_import_errors_1`: (tenant_id) → `core.tenants` (id)
- `FK_integration_import_errors_2`: (tenant_id, batch_id) → `integration.import_batches` (tenant_id, id)
- `CK_integration_import_errors_1`: CHECK (`row_number > 0`)
- `IX_integration_import_errors_1`: INDEX (tenant_id, batch_id)

## `integration.outbox_events`
- `PK_integration_outbox_events`: PRIMARY KEY (id)
- `UQ_integration_outbox_events_1`: UNIQUE (tenant_id, id)
- `FK_integration_outbox_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_integration_outbox_events_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_integration_outbox_events_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_integration_outbox_events_1`: CHECK (`ISJSON(payload) = 1`)
- `CK_integration_outbox_events_2`: CHECK (`attempt_count >= 0`)
- `IX_integration_outbox_events_1`: INDEX (tenant_id, publication_status, created_at)

## `integration.idempotency_keys`
- `PK_integration_idempotency_keys`: PRIMARY KEY (id)
- `UQ_integration_idempotency_keys_1`: UNIQUE (tenant_id, id)
- `UQ_integration_idempotency_keys_2`: UNIQUE (tenant_id, operation_scope, request_key)
- `FK_integration_idempotency_keys_1`: (tenant_id) → `core.tenants` (id)
- `FK_integration_idempotency_keys_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_integration_idempotency_keys_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `gps.devices`
- `PK_gps_devices`: PRIMARY KEY (id)
- `UQ_gps_devices_1`: UNIQUE (tenant_id, id)
- `UQ_gps_devices_2`: UNIQUE (tenant_id, connection_id, external_device_id)
- `FK_gps_devices_1`: (tenant_id) → `core.tenants` (id)
- `FK_gps_devices_2`: (tenant_id, connection_id) → `integration.connections` (tenant_id, id)
- `FK_gps_devices_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_gps_devices_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `gps.device_assignments`
- `PK_gps_device_assignments`: PRIMARY KEY (id)
- `UQ_gps_device_assignments_1`: UNIQUE (tenant_id, id)
- `FK_gps_device_assignments_1`: (tenant_id) → `core.tenants` (id)
- `FK_gps_device_assignments_2`: (tenant_id, device_id) → `gps.devices` (tenant_id, id)
- `FK_gps_device_assignments_3`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_gps_device_assignments_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_gps_device_assignments_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_gps_device_assignments_1`: CHECK (`effective_to >= effective_from`)
- `IX_gps_device_assignments_1`: INDEX (tenant_id, device_id)
- `IX_gps_device_assignments_2`: INDEX (tenant_id, asset_id)

## `gps.vehicle_positions`
- `PK_gps_vehicle_positions`: PRIMARY KEY (id)
- `UQ_gps_vehicle_positions_1`: UNIQUE (tenant_id, id)
- `UQ_gps_vehicle_positions_2`: UNIQUE (tenant_id, device_id, provider_event_id)
- `UQ_gps_vehicle_positions_3`: UNIQUE (tenant_id, asset_id, id)
- `FK_gps_vehicle_positions_1`: (tenant_id) → `core.tenants` (id)
- `FK_gps_vehicle_positions_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_gps_vehicle_positions_3`: (tenant_id, device_id) → `gps.devices` (tenant_id, id)
- `CK_gps_vehicle_positions_1`: CHECK (`speed_mph >= 0`)
- `CK_gps_vehicle_positions_2`: CHECK (`odometer_miles >= 0`)
- `CK_gps_vehicle_positions_3`: CHECK (`latitude BETWEEN -90 AND 90`)
- `CK_gps_vehicle_positions_4`: CHECK (`longitude BETWEEN -180 AND 180`)
- `CK_gps_vehicle_positions_5`: CHECK (`heading_degrees >= 0 AND heading_degrees < 360`)
- `IX_gps_vehicle_positions_1`: INDEX (tenant_id, asset_id)
- `IX_gps_vehicle_positions_2`: INDEX (tenant_id, asset_id, recorded_at)

## `gps.latest_vehicle_positions`
- `PK_gps_latest_vehicle_positions`: PRIMARY KEY (id)
- `UQ_gps_latest_vehicle_positions_1`: UNIQUE (tenant_id, id)
- `UQ_gps_latest_vehicle_positions_2`: UNIQUE (tenant_id, asset_id)
- `FK_gps_latest_vehicle_positions_1`: (tenant_id) → `core.tenants` (id)
- `FK_gps_latest_vehicle_positions_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_gps_latest_vehicle_positions_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_gps_latest_vehicle_positions_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `FK_gps_latest_vehicle_positions_5`: (tenant_id, asset_id, position_id) → `gps.vehicle_positions` (tenant_id, asset_id, id)
- `IX_gps_latest_vehicle_positions_1`: INDEX (tenant_id, position_id)

## `gps.telemetry_events`
- `PK_gps_telemetry_events`: PRIMARY KEY (id)
- `UQ_gps_telemetry_events_1`: UNIQUE (tenant_id, id)
- `FK_gps_telemetry_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_gps_telemetry_events_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `CK_gps_telemetry_events_1`: CHECK (`ISJSON(event_value) = 1`)
- `IX_gps_telemetry_events_1`: INDEX (tenant_id, asset_id)

## `gps.geofences`
- `PK_gps_geofences`: PRIMARY KEY (id)
- `UQ_gps_geofences_1`: UNIQUE (tenant_id, id)
- `FK_gps_geofences_1`: (tenant_id) → `core.tenants` (id)
- `FK_gps_geofences_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_gps_geofences_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `gps.geofence_events`
- `PK_gps_geofence_events`: PRIMARY KEY (id)
- `UQ_gps_geofence_events_1`: UNIQUE (tenant_id, id)
- `FK_gps_geofence_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_gps_geofence_events_2`: (tenant_id, geofence_id) → `gps.geofences` (tenant_id, id)
- `FK_gps_geofence_events_3`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `IX_gps_geofence_events_1`: INDEX (tenant_id, geofence_id)
- `IX_gps_geofence_events_2`: INDEX (tenant_id, asset_id)

## `gps.vehicle_fault_codes`
- `PK_gps_vehicle_fault_codes`: PRIMARY KEY (id)
- `UQ_gps_vehicle_fault_codes_1`: UNIQUE (tenant_id, id)
- `FK_gps_vehicle_fault_codes_1`: (tenant_id) → `core.tenants` (id)
- `FK_gps_vehicle_fault_codes_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_gps_vehicle_fault_codes_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_gps_vehicle_fault_codes_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_gps_vehicle_fault_codes_1`: INDEX (tenant_id, asset_id)

## `gps.idle_sessions`
- `PK_gps_idle_sessions`: PRIMARY KEY (id)
- `UQ_gps_idle_sessions_1`: UNIQUE (tenant_id, id)
- `FK_gps_idle_sessions_1`: (tenant_id) → `core.tenants` (id)
- `FK_gps_idle_sessions_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `CK_gps_idle_sessions_1`: CHECK (`duration_seconds >= 0`)
- `CK_gps_idle_sessions_2`: CHECK (`ended_at >= started_at`)
- `IX_gps_idle_sessions_1`: INDEX (tenant_id, asset_id)

## `mnt.service_types`
- `PK_mnt_service_types`: PRIMARY KEY (id)
- `UQ_mnt_service_types_1`: UNIQUE (tenant_id, id)
- `UQ_mnt_service_types_2`: UNIQUE (tenant_id, service_code)
- `FK_mnt_service_types_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_service_types_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_service_types_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `mnt.maintenance_schedules`
- `PK_mnt_maintenance_schedules`: PRIMARY KEY (id)
- `UQ_mnt_maintenance_schedules_1`: UNIQUE (tenant_id, id)
- `FK_mnt_maintenance_schedules_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_maintenance_schedules_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_mnt_maintenance_schedules_3`: (tenant_id, service_type_id) → `mnt.service_types` (tenant_id, id)
- `FK_mnt_maintenance_schedules_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_maintenance_schedules_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_mnt_maintenance_schedules_1`: CHECK (`interval_days > 0`)
- `CK_mnt_maintenance_schedules_2`: CHECK (`interval_miles > 0`)
- `CK_mnt_maintenance_schedules_3`: CHECK (`interval_hours > 0`)
- `CK_mnt_maintenance_schedules_4`: CHECK (`interval_days IS NOT NULL OR interval_miles IS NOT NULL OR interval_hours IS NOT NULL`)
- `IX_mnt_maintenance_schedules_1`: INDEX (tenant_id, asset_id)
- `IX_mnt_maintenance_schedules_2`: INDEX (tenant_id, service_type_id)

## `mnt.scheduled_services`
- `PK_mnt_scheduled_services`: PRIMARY KEY (id)
- `UQ_mnt_scheduled_services_1`: UNIQUE (tenant_id, id)
- `FK_mnt_scheduled_services_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_scheduled_services_2`: (tenant_id, schedule_id) → `mnt.maintenance_schedules` (tenant_id, id)
- `FK_mnt_scheduled_services_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_scheduled_services_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_mnt_scheduled_services_1`: CHECK (`due_date IS NOT NULL OR due_odometer IS NOT NULL OR due_engine_hours IS NOT NULL`)
- `IX_mnt_scheduled_services_1`: INDEX (tenant_id, schedule_id)
- `IX_mnt_scheduled_services_2`: INDEX (tenant_id, status, due_date)

## `mnt.service_records`
- `PK_mnt_service_records`: PRIMARY KEY (id)
- `UQ_mnt_service_records_1`: UNIQUE (tenant_id, id)
- `FK_mnt_service_records_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_service_records_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_mnt_service_records_3`: (tenant_id, service_type_id) → `mnt.service_types` (tenant_id, id)
- `FK_mnt_service_records_4`: (tenant_id, vendor_id) → `mnt.vendors` (tenant_id, id)
- `FK_mnt_service_records_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_service_records_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_mnt_service_records_1`: INDEX (tenant_id, asset_id)
- `IX_mnt_service_records_2`: INDEX (tenant_id, service_type_id)
- `IX_mnt_service_records_3`: INDEX (tenant_id, vendor_id)

## `mnt.maintenance_restrictions`
- `PK_mnt_maintenance_restrictions`: PRIMARY KEY (id)
- `UQ_mnt_maintenance_restrictions_1`: UNIQUE (tenant_id, id)
- `FK_mnt_maintenance_restrictions_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_maintenance_restrictions_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_mnt_maintenance_restrictions_3`: (tenant_id, release_approved_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_maintenance_restrictions_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_maintenance_restrictions_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_mnt_maintenance_restrictions_1`: CHECK (`released_at >= imposed_at`)
- `CK_mnt_maintenance_restrictions_2`: CHECK (`released_at IS NULL OR release_approved_by IS NOT NULL`)
- `IX_mnt_maintenance_restrictions_1`: INDEX (tenant_id, asset_id)
- `IX_mnt_maintenance_restrictions_2`: INDEX (tenant_id, release_approved_by)

## `mnt.vendors`
- `PK_mnt_vendors`: PRIMARY KEY (id)
- `UQ_mnt_vendors_1`: UNIQUE (tenant_id, id)
- `UQ_mnt_vendors_2`: UNIQUE (tenant_id, vendor_code)
- `FK_mnt_vendors_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_vendors_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_vendors_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `mnt.work_orders`
- `PK_mnt_work_orders`: PRIMARY KEY (id)
- `UQ_mnt_work_orders_1`: UNIQUE (tenant_id, id)
- `UQ_mnt_work_orders_2`: UNIQUE (tenant_id, work_order_number)
- `FK_mnt_work_orders_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_work_orders_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_mnt_work_orders_3`: (tenant_id, vendor_id) → `mnt.vendors` (tenant_id, id)
- `FK_mnt_work_orders_4`: (maintenance_type_id) → `ref.maintenance_types` (id)
- `FK_mnt_work_orders_5`: (tenant_id, approved_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_work_orders_6`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_work_orders_7`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_mnt_work_orders_1`: CHECK (`odometer_miles >= 0`)
- `IX_mnt_work_orders_1`: INDEX (tenant_id, asset_id)
- `IX_mnt_work_orders_2`: INDEX (tenant_id, vendor_id)
- `IX_mnt_work_orders_3`: INDEX (tenant_id, maintenance_type_id)
- `IX_mnt_work_orders_4`: INDEX (tenant_id, approved_by)

## `mnt.work_order_items`
- `PK_mnt_work_order_items`: PRIMARY KEY (id)
- `UQ_mnt_work_order_items_1`: UNIQUE (tenant_id, id)
- `FK_mnt_work_order_items_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_work_order_items_2`: (tenant_id, work_order_id) → `mnt.work_orders` (tenant_id, id)
- `FK_mnt_work_order_items_3`: (currency_code) → `ref.currencies` (code)
- `FK_mnt_work_order_items_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_work_order_items_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_mnt_work_order_items_1`: INDEX (tenant_id, work_order_id)
- `IX_mnt_work_order_items_2`: INDEX (tenant_id, currency_code)

## `mnt.defects`
- `PK_mnt_defects`: PRIMARY KEY (id)
- `UQ_mnt_defects_1`: UNIQUE (tenant_id, id)
- `FK_mnt_defects_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_defects_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_mnt_defects_3`: (tenant_id, inspection_id) → `compliance.inspections` (tenant_id, id)
- `FK_mnt_defects_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_defects_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_mnt_defects_1`: INDEX (tenant_id, asset_id)
- `IX_mnt_defects_2`: INDEX (tenant_id, inspection_id)

## `mnt.parts`
- `PK_mnt_parts`: PRIMARY KEY (id)
- `UQ_mnt_parts_1`: UNIQUE (tenant_id, id)
- `UQ_mnt_parts_2`: UNIQUE (tenant_id, part_number)
- `FK_mnt_parts_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_parts_2`: (currency_code) → `ref.currencies` (code)
- `FK_mnt_parts_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_parts_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_mnt_parts_1`: INDEX (tenant_id, currency_code)

## `mnt.parts_inventory`
- `PK_mnt_parts_inventory`: PRIMARY KEY (id)
- `UQ_mnt_parts_inventory_1`: UNIQUE (tenant_id, id)
- `UQ_mnt_parts_inventory_2`: UNIQUE (tenant_id, part_id, terminal_id)
- `FK_mnt_parts_inventory_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_parts_inventory_2`: (tenant_id, part_id) → `mnt.parts` (tenant_id, id)
- `FK_mnt_parts_inventory_3`: (tenant_id, terminal_id) → `core.terminals` (tenant_id, id)
- `FK_mnt_parts_inventory_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_parts_inventory_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_mnt_parts_inventory_1`: CHECK (`quantity_on_hand >= 0`)
- `IX_mnt_parts_inventory_1`: INDEX (tenant_id, terminal_id)

## `mnt.tire_records`
- `PK_mnt_tire_records`: PRIMARY KEY (id)
- `UQ_mnt_tire_records_1`: UNIQUE (tenant_id, id)
- `FK_mnt_tire_records_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_tire_records_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_mnt_tire_records_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_tire_records_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_mnt_tire_records_1`: CHECK (`removed_at >= installed_at`)
- `IX_mnt_tire_records_1`: INDEX (tenant_id, asset_id)

## `mnt.downtime_events`
- `PK_mnt_downtime_events`: PRIMARY KEY (id)
- `UQ_mnt_downtime_events_1`: UNIQUE (tenant_id, id)
- `FK_mnt_downtime_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_mnt_downtime_events_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_mnt_downtime_events_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_mnt_downtime_events_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_mnt_downtime_events_1`: CHECK (`ended_at >= started_at`)
- `IX_mnt_downtime_events_1`: INDEX (tenant_id, asset_id)

## `fuel.fuel_transactions`
- `PK_fuel_fuel_transactions`: PRIMARY KEY (id)
- `UQ_fuel_fuel_transactions_1`: UNIQUE (tenant_id, id)
- `FK_fuel_fuel_transactions_1`: (tenant_id) → `core.tenants` (id)
- `FK_fuel_fuel_transactions_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fuel_fuel_transactions_3`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_fuel_fuel_transactions_4`: (fuel_type_id) → `ref.fuel_types` (id)
- `FK_fuel_fuel_transactions_5`: (currency_code) → `ref.currencies` (code)
- `FK_fuel_fuel_transactions_6`: (jurisdiction_id) → `ref.jurisdictions` (id)
- `FK_fuel_fuel_transactions_7`: (tenant_id, connection_id) → `integration.connections` (tenant_id, id)
- `FK_fuel_fuel_transactions_8`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fuel_fuel_transactions_9`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fuel_fuel_transactions_1`: CHECK (`quantity_gallons >= 0`)
- `CK_fuel_fuel_transactions_2`: CHECK (`odometer_miles >= 0`)
- `IX_fuel_fuel_transactions_1`: UNIQUE INDEX (tenant_id, connection_id, external_transaction_id) WHERE `connection_id IS NOT NULL AND external_transaction_id IS NOT NULL`
- `IX_fuel_fuel_transactions_2`: INDEX (tenant_id, asset_id)
- `IX_fuel_fuel_transactions_3`: INDEX (tenant_id, driver_id)
- `IX_fuel_fuel_transactions_4`: INDEX (tenant_id, fuel_type_id)
- `IX_fuel_fuel_transactions_5`: INDEX (tenant_id, currency_code)
- `IX_fuel_fuel_transactions_6`: INDEX (tenant_id, jurisdiction_id)
- `IX_fuel_fuel_transactions_7`: INDEX (tenant_id, asset_id, transaction_at)

## `fuel.fuel_transaction_matches`
- `PK_fuel_fuel_transaction_matches`: PRIMARY KEY (id)
- `UQ_fuel_fuel_transaction_matches_1`: UNIQUE (tenant_id, id)
- `UQ_fuel_fuel_transaction_matches_2`: UNIQUE (tenant_id, fuel_transaction_id, expense_id)
- `FK_fuel_fuel_transaction_matches_1`: (tenant_id) → `core.tenants` (id)
- `FK_fuel_fuel_transaction_matches_2`: (tenant_id, fuel_transaction_id) → `fuel.fuel_transactions` (tenant_id, id)
- `FK_fuel_fuel_transaction_matches_3`: (tenant_id, expense_id) → `fin.expenses` (tenant_id, id)
- `FK_fuel_fuel_transaction_matches_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fuel_fuel_transaction_matches_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fuel_fuel_transaction_matches_1`: INDEX (tenant_id, expense_id)

## `fuel.fuel_cards`
- `PK_fuel_fuel_cards`: PRIMARY KEY (id)
- `UQ_fuel_fuel_cards_1`: UNIQUE (tenant_id, id)
- `FK_fuel_fuel_cards_1`: (tenant_id) → `core.tenants` (id)
- `FK_fuel_fuel_cards_2`: (tenant_id, connection_id) → `integration.connections` (tenant_id, id)
- `FK_fuel_fuel_cards_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fuel_fuel_cards_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fuel_fuel_cards_1`: INDEX (tenant_id, connection_id)

## `fuel.fuel_card_assignments`
- `PK_fuel_fuel_card_assignments`: PRIMARY KEY (id)
- `UQ_fuel_fuel_card_assignments_1`: UNIQUE (tenant_id, id)
- `FK_fuel_fuel_card_assignments_1`: (tenant_id) → `core.tenants` (id)
- `FK_fuel_fuel_card_assignments_2`: (tenant_id, fuel_card_id) → `fuel.fuel_cards` (tenant_id, id)
- `FK_fuel_fuel_card_assignments_3`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fuel_fuel_card_assignments_4`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_fuel_fuel_card_assignments_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fuel_fuel_card_assignments_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fuel_fuel_card_assignments_1`: CHECK (`effective_to >= effective_from`)
- `IX_fuel_fuel_card_assignments_1`: INDEX (tenant_id, fuel_card_id)
- `IX_fuel_fuel_card_assignments_2`: INDEX (tenant_id, asset_id)
- `IX_fuel_fuel_card_assignments_3`: INDEX (tenant_id, driver_id)

## `fuel.fuel_import_batches`
- `PK_fuel_fuel_import_batches`: PRIMARY KEY (id)
- `UQ_fuel_fuel_import_batches_1`: UNIQUE (tenant_id, id)
- `UQ_fuel_fuel_import_batches_2`: UNIQUE (tenant_id, connection_id, external_batch_id)
- `FK_fuel_fuel_import_batches_1`: (tenant_id) → `core.tenants` (id)
- `FK_fuel_fuel_import_batches_2`: (tenant_id, connection_id) → `integration.connections` (tenant_id, id)
- `FK_fuel_fuel_import_batches_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fuel_fuel_import_batches_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `fuel.fuel_efficiency_records`
- `PK_fuel_fuel_efficiency_records`: PRIMARY KEY (id)
- `UQ_fuel_fuel_efficiency_records_1`: UNIQUE (tenant_id, id)
- `UQ_fuel_fuel_efficiency_records_2`: UNIQUE (tenant_id, asset_id, period_start, period_end, source)
- `FK_fuel_fuel_efficiency_records_1`: (tenant_id) → `core.tenants` (id)
- `FK_fuel_fuel_efficiency_records_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fuel_fuel_efficiency_records_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fuel_fuel_efficiency_records_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fuel_fuel_efficiency_records_1`: CHECK (`miles >= 0`)
- `CK_fuel_fuel_efficiency_records_2`: CHECK (`gallons >= 0`)
- `CK_fuel_fuel_efficiency_records_3`: CHECK (`period_end >= period_start`)

## `fuel.fuel_exceptions`
- `PK_fuel_fuel_exceptions`: PRIMARY KEY (id)
- `UQ_fuel_fuel_exceptions_1`: UNIQUE (tenant_id, id)
- `FK_fuel_fuel_exceptions_1`: (tenant_id) → `core.tenants` (id)
- `FK_fuel_fuel_exceptions_2`: (tenant_id, fuel_transaction_id) → `fuel.fuel_transactions` (tenant_id, id)
- `FK_fuel_fuel_exceptions_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fuel_fuel_exceptions_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fuel_fuel_exceptions_1`: INDEX (tenant_id, fuel_transaction_id)

## `fin.revenue_items`
- `PK_fin_revenue_items`: PRIMARY KEY (id)
- `UQ_fin_revenue_items_1`: UNIQUE (tenant_id, id)
- `FK_fin_revenue_items_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_revenue_items_2`: (tenant_id, load_id) → `ops.loads` (tenant_id, id)
- `FK_fin_revenue_items_3`: (revenue_category_id) → `ref.revenue_categories` (id)
- `FK_fin_revenue_items_4`: (currency_code) → `ref.currencies` (code)
- `FK_fin_revenue_items_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_revenue_items_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fin_revenue_items_1`: INDEX (tenant_id, load_id)
- `IX_fin_revenue_items_2`: INDEX (tenant_id, revenue_category_id)
- `IX_fin_revenue_items_3`: INDEX (tenant_id, currency_code)

## `fin.expenses`
- `PK_fin_expenses`: PRIMARY KEY (id)
- `UQ_fin_expenses_1`: UNIQUE (tenant_id, id)
- `FK_fin_expenses_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_expenses_2`: (expense_category_id) → `ref.expense_categories` (id)
- `FK_fin_expenses_3`: (tenant_id, vendor_id) → `mnt.vendors` (tenant_id, id)
- `FK_fin_expenses_4`: (currency_code) → `ref.currencies` (code)
- `FK_fin_expenses_5`: (tenant_id, approved_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_expenses_6`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_expenses_7`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fin_expenses_1`: INDEX (tenant_id, expense_category_id)
- `IX_fin_expenses_2`: INDEX (tenant_id, vendor_id)
- `IX_fin_expenses_3`: INDEX (tenant_id, currency_code)
- `IX_fin_expenses_4`: INDEX (tenant_id, approved_by)
- `IX_fin_expenses_5`: INDEX (tenant_id, expense_date, expense_category_id)

## `fin.expense_allocations`
- `PK_fin_expense_allocations`: PRIMARY KEY (id)
- `UQ_fin_expense_allocations_1`: UNIQUE (tenant_id, id)
- `FK_fin_expense_allocations_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_expense_allocations_2`: (tenant_id, expense_id) → `fin.expenses` (tenant_id, id)
- `FK_fin_expense_allocations_3`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_fin_expense_allocations_4`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_fin_expense_allocations_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_expense_allocations_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fin_expense_allocations_1`: CHECK (`trip_id IS NOT NULL OR asset_id IS NOT NULL`)
- `IX_fin_expense_allocations_1`: INDEX (tenant_id, expense_id)
- `IX_fin_expense_allocations_2`: INDEX (tenant_id, trip_id)
- `IX_fin_expense_allocations_3`: INDEX (tenant_id, asset_id)

## `fin.revenue_allocations`
- `PK_fin_revenue_allocations`: PRIMARY KEY (id)
- `UQ_fin_revenue_allocations_1`: UNIQUE (tenant_id, id)
- `FK_fin_revenue_allocations_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_revenue_allocations_2`: (tenant_id, revenue_item_id) → `fin.revenue_items` (tenant_id, id)
- `FK_fin_revenue_allocations_3`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_fin_revenue_allocations_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_revenue_allocations_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fin_revenue_allocations_1`: INDEX (tenant_id, revenue_item_id)
- `IX_fin_revenue_allocations_2`: INDEX (tenant_id, trip_id)

## `fin.trip_financial_closures`
- `PK_fin_trip_financial_closures`: PRIMARY KEY (id)
- `UQ_fin_trip_financial_closures_1`: UNIQUE (tenant_id, id)
- `UQ_fin_trip_financial_closures_2`: UNIQUE (tenant_id, trip_id, revision_number)
- `FK_fin_trip_financial_closures_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_trip_financial_closures_2`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_fin_trip_financial_closures_3`: (tenant_id, finalized_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_trip_financial_closures_4`: (currency_code) → `ref.currencies` (code)
- `FK_fin_trip_financial_closures_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_trip_financial_closures_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fin_trip_financial_closures_1`: CHECK (`revision_number > 0`)
- `CK_fin_trip_financial_closures_2`: CHECK (`ISJSON(snapshot) = 1`)
- `CK_fin_trip_financial_closures_3`: CHECK (`closure_status IN ('ESTIMATED','PARTIAL','FINALIZED','SUPERSEDED')`)
- `CK_fin_trip_financial_closures_4`: CHECK (`closure_status <> 'FINALIZED' OR (finalized_at IS NOT NULL AND finalized_by IS NOT NULL AND revenue_total IS NOT NULL AND direct_cost_total IS NOT NULL AND snapshot IS NOT NULL)`)
- `IX_fin_trip_financial_closures_1`: INDEX (tenant_id, finalized_by)
- `IX_fin_trip_financial_closures_2`: INDEX (tenant_id, currency_code)

## `fin.cost_allocation_rules`
- `PK_fin_cost_allocation_rules`: PRIMARY KEY (id)
- `UQ_fin_cost_allocation_rules_1`: UNIQUE (tenant_id, id)
- `FK_fin_cost_allocation_rules_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_cost_allocation_rules_2`: (expense_category_id) → `ref.expense_categories` (id)
- `FK_fin_cost_allocation_rules_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_cost_allocation_rules_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fin_cost_allocation_rules_1`: CHECK (`effective_to >= effective_from`)
- `IX_fin_cost_allocation_rules_1`: INDEX (tenant_id, expense_category_id)

## `fin.invoices`
- `PK_fin_invoices`: PRIMARY KEY (id)
- `UQ_fin_invoices_1`: UNIQUE (tenant_id, id)
- `UQ_fin_invoices_2`: UNIQUE (tenant_id, invoice_number)
- `FK_fin_invoices_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_invoices_2`: (tenant_id, customer_id) → `crm.customers` (tenant_id, id)
- `FK_fin_invoices_3`: (currency_code) → `ref.currencies` (code)
- `FK_fin_invoices_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_invoices_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fin_invoices_1`: CHECK (`due_date >= invoice_date`)
- `IX_fin_invoices_1`: INDEX (tenant_id, customer_id)
- `IX_fin_invoices_2`: INDEX (tenant_id, currency_code)

## `fin.invoice_items`
- `PK_fin_invoice_items`: PRIMARY KEY (id)
- `UQ_fin_invoice_items_1`: UNIQUE (tenant_id, id)
- `FK_fin_invoice_items_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_invoice_items_2`: (tenant_id, invoice_id) → `fin.invoices` (tenant_id, id)
- `FK_fin_invoice_items_3`: (tenant_id, revenue_item_id) → `fin.revenue_items` (tenant_id, id)
- `FK_fin_invoice_items_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_invoice_items_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fin_invoice_items_1`: INDEX (tenant_id, invoice_id)
- `IX_fin_invoice_items_2`: INDEX (tenant_id, revenue_item_id)

## `fin.payments`
- `PK_fin_payments`: PRIMARY KEY (id)
- `UQ_fin_payments_1`: UNIQUE (tenant_id, id)
- `UQ_fin_payments_2`: UNIQUE (tenant_id, payment_reference)
- `FK_fin_payments_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_payments_2`: (tenant_id, customer_id) → `crm.customers` (tenant_id, id)
- `FK_fin_payments_3`: (currency_code) → `ref.currencies` (code)
- `FK_fin_payments_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_payments_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fin_payments_1`: INDEX (tenant_id, customer_id)
- `IX_fin_payments_2`: INDEX (tenant_id, currency_code)

## `fin.payment_allocations`
- `PK_fin_payment_allocations`: PRIMARY KEY (id)
- `UQ_fin_payment_allocations_1`: UNIQUE (tenant_id, id)
- `FK_fin_payment_allocations_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_payment_allocations_2`: (tenant_id, payment_id) → `fin.payments` (tenant_id, id)
- `FK_fin_payment_allocations_3`: (tenant_id, invoice_id) → `fin.invoices` (tenant_id, id)
- `FK_fin_payment_allocations_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_payment_allocations_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fin_payment_allocations_1`: INDEX (tenant_id, payment_id)
- `IX_fin_payment_allocations_2`: INDEX (tenant_id, invoice_id)

## `fin.driver_settlements`
- `PK_fin_driver_settlements`: PRIMARY KEY (id)
- `UQ_fin_driver_settlements_1`: UNIQUE (tenant_id, id)
- `FK_fin_driver_settlements_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_driver_settlements_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_fin_driver_settlements_3`: (currency_code) → `ref.currencies` (code)
- `FK_fin_driver_settlements_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_driver_settlements_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fin_driver_settlements_1`: CHECK (`period_end >= period_start`)
- `IX_fin_driver_settlements_1`: INDEX (tenant_id, driver_id)
- `IX_fin_driver_settlements_2`: INDEX (tenant_id, currency_code)

## `fin.driver_settlement_items`
- `PK_fin_driver_settlement_items`: PRIMARY KEY (id)
- `UQ_fin_driver_settlement_items_1`: UNIQUE (tenant_id, id)
- `FK_fin_driver_settlement_items_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_driver_settlement_items_2`: (tenant_id, settlement_id) → `fin.driver_settlements` (tenant_id, id)
- `FK_fin_driver_settlement_items_3`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_fin_driver_settlement_items_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_driver_settlement_items_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fin_driver_settlement_items_1`: INDEX (tenant_id, settlement_id)
- `IX_fin_driver_settlement_items_2`: INDEX (tenant_id, trip_id)

## `fin.financial_periods`
- `PK_fin_financial_periods`: PRIMARY KEY (id)
- `UQ_fin_financial_periods_1`: UNIQUE (tenant_id, id)
- `UQ_fin_financial_periods_2`: UNIQUE (tenant_id, period_start, period_end)
- `FK_fin_financial_periods_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_financial_periods_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_financial_periods_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_fin_financial_periods_1`: CHECK (`period_end >= period_start`)

## `fin.financial_adjustments`
- `PK_fin_financial_adjustments`: PRIMARY KEY (id)
- `UQ_fin_financial_adjustments_1`: UNIQUE (tenant_id, id)
- `FK_fin_financial_adjustments_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_financial_adjustments_2`: (tenant_id, expense_id) → `fin.expenses` (tenant_id, id)
- `FK_fin_financial_adjustments_3`: (tenant_id, revenue_item_id) → `fin.revenue_items` (tenant_id, id)
- `FK_fin_financial_adjustments_4`: (tenant_id, approved_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_financial_adjustments_5`: (currency_code) → `ref.currencies` (code)
- `CK_fin_financial_adjustments_1`: CHECK (`(expense_id IS NOT NULL AND revenue_item_id IS NULL) OR (expense_id IS NULL AND revenue_item_id IS NOT NULL)`)
- `IX_fin_financial_adjustments_1`: INDEX (tenant_id, expense_id)
- `IX_fin_financial_adjustments_2`: INDEX (tenant_id, revenue_item_id)
- `IX_fin_financial_adjustments_3`: INDEX (tenant_id, approved_by)
- `IX_fin_financial_adjustments_4`: INDEX (tenant_id, currency_code)

## `fin.service_expense_links`
- `PK_fin_service_expense_links`: PRIMARY KEY (id)
- `UQ_fin_service_expense_links_1`: UNIQUE (tenant_id, id)
- `UQ_fin_service_expense_links_2`: UNIQUE (tenant_id, service_record_id, expense_id)
- `FK_fin_service_expense_links_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_service_expense_links_2`: (tenant_id, service_record_id) → `mnt.service_records` (tenant_id, id)
- `FK_fin_service_expense_links_3`: (tenant_id, expense_id) → `fin.expenses` (tenant_id, id)
- `FK_fin_service_expense_links_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_service_expense_links_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fin_service_expense_links_1`: INDEX (tenant_id, expense_id)

## `fin.work_order_expense_links`
- `PK_fin_work_order_expense_links`: PRIMARY KEY (id)
- `UQ_fin_work_order_expense_links_1`: UNIQUE (tenant_id, id)
- `UQ_fin_work_order_expense_links_2`: UNIQUE (tenant_id, work_order_id, expense_id)
- `FK_fin_work_order_expense_links_1`: (tenant_id) → `core.tenants` (id)
- `FK_fin_work_order_expense_links_2`: (tenant_id, work_order_id) → `mnt.work_orders` (tenant_id, id)
- `FK_fin_work_order_expense_links_3`: (tenant_id, expense_id) → `fin.expenses` (tenant_id, id)
- `FK_fin_work_order_expense_links_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_fin_work_order_expense_links_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_fin_work_order_expense_links_1`: INDEX (tenant_id, expense_id)

## `compliance.compliance_requirements`
- `PK_compliance_compliance_requirements`: PRIMARY KEY (id)
- `UQ_compliance_compliance_requirements_1`: UNIQUE (tenant_id, id)
- `UQ_compliance_compliance_requirements_2`: UNIQUE (tenant_id, requirement_code)
- `FK_compliance_compliance_requirements_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_compliance_requirements_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_compliance_requirements_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `compliance.driver_compliance_records`
- `PK_compliance_driver_compliance_records`: PRIMARY KEY (id)
- `UQ_compliance_driver_compliance_records_1`: UNIQUE (tenant_id, id)
- `FK_compliance_driver_compliance_records_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_driver_compliance_records_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_compliance_driver_compliance_records_3`: (tenant_id, requirement_id) → `compliance.compliance_requirements` (tenant_id, id)
- `FK_compliance_driver_compliance_records_4`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_compliance_driver_compliance_records_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_driver_compliance_records_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_compliance_driver_compliance_records_1`: INDEX (tenant_id, driver_id)
- `IX_compliance_driver_compliance_records_2`: INDEX (tenant_id, requirement_id)
- `IX_compliance_driver_compliance_records_3`: INDEX (tenant_id, document_id)

## `compliance.asset_compliance_records`
- `PK_compliance_asset_compliance_records`: PRIMARY KEY (id)
- `UQ_compliance_asset_compliance_records_1`: UNIQUE (tenant_id, id)
- `FK_compliance_asset_compliance_records_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_asset_compliance_records_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_compliance_asset_compliance_records_3`: (tenant_id, requirement_id) → `compliance.compliance_requirements` (tenant_id, id)
- `FK_compliance_asset_compliance_records_4`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_compliance_asset_compliance_records_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_asset_compliance_records_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_compliance_asset_compliance_records_1`: INDEX (tenant_id, asset_id)
- `IX_compliance_asset_compliance_records_2`: INDEX (tenant_id, requirement_id)
- `IX_compliance_asset_compliance_records_3`: INDEX (tenant_id, document_id)

## `compliance.inspection_templates`
- `PK_compliance_inspection_templates`: PRIMARY KEY (id)
- `UQ_compliance_inspection_templates_1`: UNIQUE (tenant_id, id)
- `UQ_compliance_inspection_templates_2`: UNIQUE (tenant_id, inspection_type, version)
- `FK_compliance_inspection_templates_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_inspection_templates_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_inspection_templates_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_compliance_inspection_templates_1`: CHECK (`version > 0`)

## `compliance.inspection_template_items`
- `PK_compliance_inspection_template_items`: PRIMARY KEY (id)
- `UQ_compliance_inspection_template_items_1`: UNIQUE (tenant_id, id)
- `UQ_compliance_inspection_template_items_2`: UNIQUE (tenant_id, template_id, sequence_number)
- `FK_compliance_inspection_template_items_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_inspection_template_items_2`: (tenant_id, template_id) → `compliance.inspection_templates` (tenant_id, id)
- `FK_compliance_inspection_template_items_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_inspection_template_items_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_compliance_inspection_template_items_1`: CHECK (`sequence_number > 0`)

## `compliance.inspections`
- `PK_compliance_inspections`: PRIMARY KEY (id)
- `UQ_compliance_inspections_1`: UNIQUE (tenant_id, id)
- `FK_compliance_inspections_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_inspections_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_compliance_inspections_3`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_compliance_inspections_4`: (tenant_id, template_id) → `compliance.inspection_templates` (tenant_id, id)
- `FK_compliance_inspections_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_inspections_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_compliance_inspections_1`: INDEX (tenant_id, asset_id)
- `IX_compliance_inspections_2`: INDEX (tenant_id, driver_id)
- `IX_compliance_inspections_3`: INDEX (tenant_id, template_id)

## `compliance.inspection_items`
- `PK_compliance_inspection_items`: PRIMARY KEY (id)
- `UQ_compliance_inspection_items_1`: UNIQUE (tenant_id, id)
- `UQ_compliance_inspection_items_2`: UNIQUE (tenant_id, inspection_id, template_item_id)
- `FK_compliance_inspection_items_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_inspection_items_2`: (tenant_id, inspection_id) → `compliance.inspections` (tenant_id, id)
- `FK_compliance_inspection_items_3`: (tenant_id, template_item_id) → `compliance.inspection_template_items` (tenant_id, id)
- `FK_compliance_inspection_items_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_inspection_items_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_compliance_inspection_items_1`: INDEX (tenant_id, template_item_id)

## `compliance.repair_certifications`
- `PK_compliance_repair_certifications`: PRIMARY KEY (id)
- `UQ_compliance_repair_certifications_1`: UNIQUE (tenant_id, id)
- `FK_compliance_repair_certifications_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_repair_certifications_2`: (tenant_id, defect_id) → `mnt.defects` (tenant_id, id)
- `FK_compliance_repair_certifications_3`: (tenant_id, work_order_id) → `mnt.work_orders` (tenant_id, id)
- `FK_compliance_repair_certifications_4`: (tenant_id, certified_by) → `iam.memberships` (tenant_id, id)
- `IX_compliance_repair_certifications_1`: INDEX (tenant_id, defect_id)
- `IX_compliance_repair_certifications_2`: INDEX (tenant_id, work_order_id)
- `IX_compliance_repair_certifications_3`: INDEX (tenant_id, certified_by)

## `compliance.hos_records`
- `PK_compliance_hos_records`: PRIMARY KEY (id)
- `UQ_compliance_hos_records_1`: UNIQUE (tenant_id, id)
- `UQ_compliance_hos_records_2`: UNIQUE (tenant_id, connection_id, external_event_id)
- `FK_compliance_hos_records_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_hos_records_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_compliance_hos_records_3`: (tenant_id, connection_id) → `integration.connections` (tenant_id, id)
- `CK_compliance_hos_records_1`: CHECK (`ended_at >= started_at`)
- `IX_compliance_hos_records_1`: INDEX (tenant_id, driver_id)

## `compliance.hos_balance_snapshots`
- `PK_compliance_hos_balance_snapshots`: PRIMARY KEY (id)
- `UQ_compliance_hos_balance_snapshots_1`: UNIQUE (tenant_id, id)
- `FK_compliance_hos_balance_snapshots_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_hos_balance_snapshots_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_compliance_hos_balance_snapshots_3`: (tenant_id, connection_id) → `integration.connections` (tenant_id, id)
- `CK_compliance_hos_balance_snapshots_1`: CHECK (`drive_remaining >= 0`)
- `CK_compliance_hos_balance_snapshots_2`: CHECK (`duty_remaining >= 0`)
- `CK_compliance_hos_balance_snapshots_3`: CHECK (`cycle_remaining >= 0`)
- `IX_compliance_hos_balance_snapshots_1`: INDEX (tenant_id, driver_id)
- `IX_compliance_hos_balance_snapshots_2`: INDEX (tenant_id, connection_id)

## `compliance.safety_incidents`
- `PK_compliance_safety_incidents`: PRIMARY KEY (id)
- `UQ_compliance_safety_incidents_1`: UNIQUE (tenant_id, id)
- `FK_compliance_safety_incidents_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_safety_incidents_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_compliance_safety_incidents_3`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_compliance_safety_incidents_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_safety_incidents_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_compliance_safety_incidents_1`: INDEX (tenant_id, asset_id)
- `IX_compliance_safety_incidents_2`: INDEX (tenant_id, driver_id)

## `compliance.jurisdiction_distance_records`
- `PK_compliance_jurisdiction_distance_records`: PRIMARY KEY (id)
- `UQ_compliance_jurisdiction_distance_records_1`: UNIQUE (tenant_id, id)
- `FK_compliance_jurisdiction_distance_records_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_jurisdiction_distance_records_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_compliance_jurisdiction_distance_records_3`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_compliance_jurisdiction_distance_records_4`: (jurisdiction_id) → `ref.jurisdictions` (id)
- `FK_compliance_jurisdiction_distance_records_5`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_jurisdiction_distance_records_6`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_compliance_jurisdiction_distance_records_1`: CHECK (`distance >= 0`)
- `IX_compliance_jurisdiction_distance_records_1`: INDEX (tenant_id, asset_id)
- `IX_compliance_jurisdiction_distance_records_2`: INDEX (tenant_id, trip_id)
- `IX_compliance_jurisdiction_distance_records_3`: INDEX (tenant_id, jurisdiction_id)

## `compliance.ifta_reporting_periods`
- `PK_compliance_ifta_reporting_periods`: PRIMARY KEY (id)
- `UQ_compliance_ifta_reporting_periods_1`: UNIQUE (tenant_id, id)
- `UQ_compliance_ifta_reporting_periods_2`: UNIQUE (tenant_id, year, quarter)
- `FK_compliance_ifta_reporting_periods_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_ifta_reporting_periods_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_ifta_reporting_periods_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_compliance_ifta_reporting_periods_1`: CHECK (`quarter BETWEEN 1 AND 4`)

## `compliance.ifta_report_lines`
- `PK_compliance_ifta_report_lines`: PRIMARY KEY (id)
- `UQ_compliance_ifta_report_lines_1`: UNIQUE (tenant_id, id)
- `UQ_compliance_ifta_report_lines_2`: UNIQUE (tenant_id, period_id, jurisdiction_id)
- `FK_compliance_ifta_report_lines_1`: (tenant_id) → `core.tenants` (id)
- `FK_compliance_ifta_report_lines_2`: (tenant_id, period_id) → `compliance.ifta_reporting_periods` (tenant_id, id)
- `FK_compliance_ifta_report_lines_3`: (jurisdiction_id) → `ref.jurisdictions` (id)
- `FK_compliance_ifta_report_lines_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_compliance_ifta_report_lines_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_compliance_ifta_report_lines_1`: CHECK (`total_miles >= 0`)
- `CK_compliance_ifta_report_lines_2`: CHECK (`qualifying_gallons >= 0`)
- `IX_compliance_ifta_report_lines_1`: INDEX (tenant_id, jurisdiction_id)

## `docs.documents`
- `PK_docs_documents`: PRIMARY KEY (id)
- `UQ_docs_documents_1`: UNIQUE (tenant_id, id)
- `FK_docs_documents_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_documents_2`: (document_type_id) → `ref.document_types` (id)
- `FK_docs_documents_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_documents_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_docs_documents_1`: INDEX (tenant_id, document_type_id)
- `IX_docs_documents_2`: INDEX (tenant_id, document_type_id, expires_at)

## `docs.document_versions`
- `PK_docs_document_versions`: PRIMARY KEY (id)
- `UQ_docs_document_versions_1`: UNIQUE (tenant_id, id)
- `UQ_docs_document_versions_2`: UNIQUE (tenant_id, document_id, version_number)
- `UQ_docs_document_versions_3`: UNIQUE (tenant_id, object_key)
- `FK_docs_document_versions_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_document_versions_2`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_docs_document_versions_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_document_versions_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_docs_document_versions_1`: CHECK (`version_number > 0`)
- `CK_docs_document_versions_2`: CHECK (`file_size >= 0`)

## `docs.asset_documents`
- `PK_docs_asset_documents`: PRIMARY KEY (id)
- `UQ_docs_asset_documents_1`: UNIQUE (tenant_id, id)
- `UQ_docs_asset_documents_2`: UNIQUE (tenant_id, asset_id, document_id)
- `FK_docs_asset_documents_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_asset_documents_2`: (tenant_id, asset_id) → `fleet.assets` (tenant_id, id)
- `FK_docs_asset_documents_3`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_docs_asset_documents_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_asset_documents_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_docs_asset_documents_1`: INDEX (tenant_id, document_id)

## `docs.driver_documents`
- `PK_docs_driver_documents`: PRIMARY KEY (id)
- `UQ_docs_driver_documents_1`: UNIQUE (tenant_id, id)
- `UQ_docs_driver_documents_2`: UNIQUE (tenant_id, driver_id, document_id)
- `FK_docs_driver_documents_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_driver_documents_2`: (tenant_id, driver_id) → `hr.drivers` (tenant_id, id)
- `FK_docs_driver_documents_3`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_docs_driver_documents_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_driver_documents_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_docs_driver_documents_1`: INDEX (tenant_id, document_id)

## `docs.load_documents`
- `PK_docs_load_documents`: PRIMARY KEY (id)
- `UQ_docs_load_documents_1`: UNIQUE (tenant_id, id)
- `UQ_docs_load_documents_2`: UNIQUE (tenant_id, load_id, document_id)
- `FK_docs_load_documents_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_load_documents_2`: (tenant_id, load_id) → `ops.loads` (tenant_id, id)
- `FK_docs_load_documents_3`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_docs_load_documents_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_load_documents_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_docs_load_documents_1`: INDEX (tenant_id, document_id)

## `docs.trip_documents`
- `PK_docs_trip_documents`: PRIMARY KEY (id)
- `UQ_docs_trip_documents_1`: UNIQUE (tenant_id, id)
- `UQ_docs_trip_documents_2`: UNIQUE (tenant_id, trip_id, document_id)
- `FK_docs_trip_documents_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_trip_documents_2`: (tenant_id, trip_id) → `ops.trips` (tenant_id, id)
- `FK_docs_trip_documents_3`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_docs_trip_documents_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_trip_documents_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_docs_trip_documents_1`: INDEX (tenant_id, document_id)

## `docs.delivery_documents`
- `PK_docs_delivery_documents`: PRIMARY KEY (id)
- `UQ_docs_delivery_documents_1`: UNIQUE (tenant_id, id)
- `UQ_docs_delivery_documents_2`: UNIQUE (tenant_id, delivery_id, document_id)
- `FK_docs_delivery_documents_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_delivery_documents_2`: (tenant_id, delivery_id) → `ops.delivery_confirmations` (tenant_id, id)
- `FK_docs_delivery_documents_3`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_docs_delivery_documents_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_delivery_documents_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_delivery_documents_6`: (tenant_id, document_id, version_number) → `docs.document_versions` (tenant_id, document_id, version_number)
- `IX_docs_delivery_documents_1`: INDEX (tenant_id, document_id, version_number)

## `docs.inspection_documents`
- `PK_docs_inspection_documents`: PRIMARY KEY (id)
- `UQ_docs_inspection_documents_1`: UNIQUE (tenant_id, id)
- `UQ_docs_inspection_documents_2`: UNIQUE (tenant_id, inspection_id, document_id)
- `FK_docs_inspection_documents_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_inspection_documents_2`: (tenant_id, inspection_id) → `compliance.inspections` (tenant_id, id)
- `FK_docs_inspection_documents_3`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_docs_inspection_documents_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_inspection_documents_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_docs_inspection_documents_1`: INDEX (tenant_id, document_id)

## `docs.expense_documents`
- `PK_docs_expense_documents`: PRIMARY KEY (id)
- `UQ_docs_expense_documents_1`: UNIQUE (tenant_id, id)
- `UQ_docs_expense_documents_2`: UNIQUE (tenant_id, expense_id, document_id)
- `FK_docs_expense_documents_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_expense_documents_2`: (tenant_id, expense_id) → `fin.expenses` (tenant_id, id)
- `FK_docs_expense_documents_3`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_docs_expense_documents_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_expense_documents_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_docs_expense_documents_1`: INDEX (tenant_id, document_id)

## `docs.work_order_documents`
- `PK_docs_work_order_documents`: PRIMARY KEY (id)
- `UQ_docs_work_order_documents_1`: UNIQUE (tenant_id, id)
- `UQ_docs_work_order_documents_2`: UNIQUE (tenant_id, work_order_id, document_id)
- `FK_docs_work_order_documents_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_work_order_documents_2`: (tenant_id, work_order_id) → `mnt.work_orders` (tenant_id, id)
- `FK_docs_work_order_documents_3`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_docs_work_order_documents_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_work_order_documents_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_docs_work_order_documents_1`: INDEX (tenant_id, document_id)

## `docs.document_verifications`
- `PK_docs_document_verifications`: PRIMARY KEY (id)
- `UQ_docs_document_verifications_1`: UNIQUE (tenant_id, id)
- `FK_docs_document_verifications_1`: (tenant_id) → `core.tenants` (id)
- `FK_docs_document_verifications_2`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_docs_document_verifications_3`: (tenant_id, verified_by) → `iam.memberships` (tenant_id, id)
- `FK_docs_document_verifications_4`: (tenant_id, document_id, version_number) → `docs.document_versions` (tenant_id, document_id, version_number)
- `IX_docs_document_verifications_1`: INDEX (tenant_id, document_id, version_number)
- `IX_docs_document_verifications_2`: INDEX (tenant_id, verified_by)

## `notify.alert_rules`
- `PK_notify_alert_rules`: PRIMARY KEY (id)
- `UQ_notify_alert_rules_1`: UNIQUE (tenant_id, id)
- `FK_notify_alert_rules_1`: (tenant_id) → `core.tenants` (id)
- `FK_notify_alert_rules_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_notify_alert_rules_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `notify.alerts`
- `PK_notify_alerts`: PRIMARY KEY (id)
- `UQ_notify_alerts_1`: UNIQUE (tenant_id, id)
- `FK_notify_alerts_1`: (tenant_id) → `core.tenants` (id)
- `FK_notify_alerts_2`: (tenant_id, rule_id) → `notify.alert_rules` (tenant_id, id)
- `FK_notify_alerts_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_notify_alerts_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_notify_alerts_1`: INDEX (tenant_id, rule_id)
- `IX_notify_alerts_2`: INDEX (tenant_id, status, severity, created_at)

## `notify.alert_assignments`
- `PK_notify_alert_assignments`: PRIMARY KEY (id)
- `UQ_notify_alert_assignments_1`: UNIQUE (tenant_id, id)
- `UQ_notify_alert_assignments_2`: UNIQUE (tenant_id, alert_id, membership_id)
- `FK_notify_alert_assignments_1`: (tenant_id) → `core.tenants` (id)
- `FK_notify_alert_assignments_2`: (tenant_id, alert_id) → `notify.alerts` (tenant_id, id)
- `FK_notify_alert_assignments_3`: (tenant_id, membership_id) → `iam.memberships` (tenant_id, id)
- `FK_notify_alert_assignments_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_notify_alert_assignments_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_notify_alert_assignments_1`: INDEX (tenant_id, membership_id)

## `notify.alert_acknowledgments`
- `PK_notify_alert_acknowledgments`: PRIMARY KEY (id)
- `UQ_notify_alert_acknowledgments_1`: UNIQUE (tenant_id, id)
- `UQ_notify_alert_acknowledgments_2`: UNIQUE (tenant_id, alert_id, membership_id)
- `FK_notify_alert_acknowledgments_1`: (tenant_id) → `core.tenants` (id)
- `FK_notify_alert_acknowledgments_2`: (tenant_id, alert_id) → `notify.alerts` (tenant_id, id)
- `FK_notify_alert_acknowledgments_3`: (tenant_id, membership_id) → `iam.memberships` (tenant_id, id)
- `IX_notify_alert_acknowledgments_1`: INDEX (tenant_id, membership_id)

## `notify.notifications`
- `PK_notify_notifications`: PRIMARY KEY (id)
- `UQ_notify_notifications_1`: UNIQUE (tenant_id, id)
- `FK_notify_notifications_1`: (tenant_id) → `core.tenants` (id)
- `FK_notify_notifications_2`: (tenant_id, recipient_id) → `iam.memberships` (tenant_id, id)
- `FK_notify_notifications_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_notify_notifications_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_notify_notifications_1`: INDEX (tenant_id, recipient_id)

## `notify.notification_preferences`
- `PK_notify_notification_preferences`: PRIMARY KEY (id)
- `UQ_notify_notification_preferences_1`: UNIQUE (tenant_id, id)
- `UQ_notify_notification_preferences_2`: UNIQUE (tenant_id, membership_id, event_type, channel)
- `FK_notify_notification_preferences_1`: (tenant_id) → `core.tenants` (id)
- `FK_notify_notification_preferences_2`: (tenant_id, membership_id) → `iam.memberships` (tenant_id, id)
- `FK_notify_notification_preferences_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_notify_notification_preferences_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `notify.notification_delivery_attempts`
- `PK_notify_notification_delivery_attempts`: PRIMARY KEY (id)
- `UQ_notify_notification_delivery_attempts_1`: UNIQUE (tenant_id, id)
- `UQ_notify_notification_delivery_attempts_2`: UNIQUE (tenant_id, notification_id, attempt_number)
- `FK_notify_notification_delivery_attempts_1`: (tenant_id) → `core.tenants` (id)
- `FK_notify_notification_delivery_attempts_2`: (tenant_id, notification_id) → `notify.notifications` (tenant_id, id)
- `CK_notify_notification_delivery_attempts_1`: CHECK (`attempt_number > 0`)

## `notify.notification_templates`
- `PK_notify_notification_templates`: PRIMARY KEY (id)
- `UQ_notify_notification_templates_1`: UNIQUE (tenant_id, id)
- `UQ_notify_notification_templates_2`: UNIQUE (tenant_id, template_code, channel)
- `FK_notify_notification_templates_1`: (tenant_id) → `core.tenants` (id)
- `FK_notify_notification_templates_2`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_notify_notification_templates_3`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `ai.conversations`
- `PK_ai_conversations`: PRIMARY KEY (id)
- `UQ_ai_conversations_1`: UNIQUE (tenant_id, id)
- `FK_ai_conversations_1`: (tenant_id) → `core.tenants` (id)
- `FK_ai_conversations_2`: (tenant_id, membership_id) → `iam.memberships` (tenant_id, id)
- `FK_ai_conversations_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ai_conversations_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `IX_ai_conversations_1`: INDEX (tenant_id, membership_id)

## `ai.messages`
- `PK_ai_messages`: PRIMARY KEY (id)
- `UQ_ai_messages_1`: UNIQUE (tenant_id, id)
- `UQ_ai_messages_2`: UNIQUE (tenant_id, conversation_id, sequence_number)
- `FK_ai_messages_1`: (tenant_id) → `core.tenants` (id)
- `FK_ai_messages_2`: (tenant_id, conversation_id) → `ai.conversations` (tenant_id, id)
- `FK_ai_messages_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ai_messages_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ai_messages_1`: CHECK (`sequence_number > 0`)
- `CK_ai_messages_2`: CHECK (`role IN ('USER','ASSISTANT','SYSTEM','TOOL')`)

## `ai.model_configurations`
- `PK_ai_model_configurations`: PRIMARY KEY (id)
- `UQ_ai_model_configurations_1`: UNIQUE (provider, model_identifier)
- `CK_ai_model_configurations_1`: CHECK (`token_limit > 0`)
- `CK_ai_model_configurations_2`: CHECK (`temperature BETWEEN 0 AND 2`)

## `ai.tool_definitions`
- `PK_ai_tool_definitions`: PRIMARY KEY (id)
- `UQ_ai_tool_definitions_1`: UNIQUE (tool_code)
- `FK_ai_tool_definitions_1`: (required_permission_id) → `iam.permissions` (id)
- `IX_ai_tool_definitions_1`: INDEX (required_permission_id)

## `ai.tool_invocations`
- `PK_ai_tool_invocations`: PRIMARY KEY (id)
- `UQ_ai_tool_invocations_1`: UNIQUE (tenant_id, id)
- `FK_ai_tool_invocations_1`: (tenant_id) → `core.tenants` (id)
- `FK_ai_tool_invocations_2`: (tenant_id, message_id) → `ai.messages` (tenant_id, id)
- `FK_ai_tool_invocations_3`: (tool_id) → `ai.tool_definitions` (id)
- `CK_ai_tool_invocations_1`: CHECK (`ISJSON(request_metadata) = 1`)
- `CK_ai_tool_invocations_2`: CHECK (`duration_ms >= 0`)
- `IX_ai_tool_invocations_1`: INDEX (tenant_id, message_id)
- `IX_ai_tool_invocations_2`: INDEX (tenant_id, tool_id)

## `ai.response_sources`
- `PK_ai_response_sources`: PRIMARY KEY (id)
- `UQ_ai_response_sources_1`: UNIQUE (tenant_id, id)
- `FK_ai_response_sources_1`: (tenant_id) → `core.tenants` (id)
- `FK_ai_response_sources_2`: (tenant_id, message_id) → `ai.messages` (tenant_id, id)
- `FK_ai_response_sources_3`: (tenant_id, tool_invocation_id) → `ai.tool_invocations` (tenant_id, id)
- `IX_ai_response_sources_1`: INDEX (tenant_id, message_id)
- `IX_ai_response_sources_2`: INDEX (tenant_id, tool_invocation_id)

## `ai.response_feedback`
- `PK_ai_response_feedback`: PRIMARY KEY (id)
- `UQ_ai_response_feedback_1`: UNIQUE (tenant_id, id)
- `UQ_ai_response_feedback_2`: UNIQUE (tenant_id, message_id, membership_id)
- `FK_ai_response_feedback_1`: (tenant_id) → `core.tenants` (id)
- `FK_ai_response_feedback_2`: (tenant_id, message_id) → `ai.messages` (tenant_id, id)
- `FK_ai_response_feedback_3`: (tenant_id, membership_id) → `iam.memberships` (tenant_id, id)
- `FK_ai_response_feedback_4`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ai_response_feedback_5`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ai_response_feedback_1`: CHECK (`rating IN (-1,1)`)
- `IX_ai_response_feedback_1`: INDEX (tenant_id, membership_id)

## `ai.usage_records`
- `PK_ai_usage_records`: PRIMARY KEY (id)
- `UQ_ai_usage_records_1`: UNIQUE (tenant_id, id)
- `FK_ai_usage_records_1`: (tenant_id) → `core.tenants` (id)
- `FK_ai_usage_records_2`: (tenant_id, message_id) → `ai.messages` (tenant_id, id)
- `FK_ai_usage_records_3`: (currency_code) → `ref.currencies` (code)
- `CK_ai_usage_records_1`: CHECK (`input_tokens >= 0`)
- `CK_ai_usage_records_2`: CHECK (`output_tokens >= 0`)
- `CK_ai_usage_records_3`: CHECK (`latency_ms >= 0`)
- `IX_ai_usage_records_1`: INDEX (tenant_id, message_id)
- `IX_ai_usage_records_2`: INDEX (tenant_id, currency_code)

## `ai.tenant_ai_settings`
- `PK_ai_tenant_ai_settings`: PRIMARY KEY (id)
- `UQ_ai_tenant_ai_settings_1`: UNIQUE (tenant_id, id)
- `UQ_ai_tenant_ai_settings_2`: UNIQUE (tenant_id)
- `FK_ai_tenant_ai_settings_1`: (tenant_id) → `core.tenants` (id)
- `FK_ai_tenant_ai_settings_2`: (model_configuration_id) → `ai.model_configurations` (id)
- `FK_ai_tenant_ai_settings_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ai_tenant_ai_settings_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)
- `CK_ai_tenant_ai_settings_1`: CHECK (`usage_limit >= 0`)
- `CK_ai_tenant_ai_settings_2`: CHECK (`retention_days BETWEEN 1 AND 3650`)
- `IX_ai_tenant_ai_settings_1`: INDEX (tenant_id, model_configuration_id)

## `ai.prompt_templates`
- `PK_ai_prompt_templates`: PRIMARY KEY (id)
- `UQ_ai_prompt_templates_1`: UNIQUE (template_code, version)
- `CK_ai_prompt_templates_1`: CHECK (`version > 0`)

## `ai.evaluation_cases`
- `PK_ai_evaluation_cases`: PRIMARY KEY (id)

## `ai.evaluation_runs`
- `PK_ai_evaluation_runs`: PRIMARY KEY (id)
- `FK_ai_evaluation_runs_1`: (case_id) → `ai.evaluation_cases` (id)
- `IX_ai_evaluation_runs_1`: INDEX (case_id)

## `ai.knowledge_documents`
- `PK_ai_knowledge_documents`: PRIMARY KEY (id)
- `UQ_ai_knowledge_documents_1`: UNIQUE (tenant_id, id)
- `UQ_ai_knowledge_documents_2`: UNIQUE (tenant_id, document_id)
- `FK_ai_knowledge_documents_1`: (tenant_id) → `core.tenants` (id)
- `FK_ai_knowledge_documents_2`: (tenant_id, document_id) → `docs.documents` (tenant_id, id)
- `FK_ai_knowledge_documents_3`: (tenant_id, created_by) → `iam.memberships` (tenant_id, id)
- `FK_ai_knowledge_documents_4`: (tenant_id, updated_by) → `iam.memberships` (tenant_id, id)

## `audit.audit_events`
- `PK_audit_audit_events`: PRIMARY KEY (id)
- `UQ_audit_audit_events_1`: UNIQUE (tenant_id, id)
- `FK_audit_audit_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_audit_audit_events_2`: (actor_id) → `iam.users` (id)
- `CK_audit_audit_events_1`: CHECK (`ISJSON(old_values) = 1`)
- `CK_audit_audit_events_2`: CHECK (`ISJSON(new_values) = 1`)
- `IX_audit_audit_events_1`: INDEX (tenant_id, actor_id)
- `IX_audit_audit_events_2`: INDEX (tenant_id, entity_type, entity_id, occurred_at)

## `audit.security_events`
- `PK_audit_security_events`: PRIMARY KEY (id)
- `UQ_audit_security_events_1`: UNIQUE (tenant_id, id)
- `FK_audit_security_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_audit_security_events_2`: (user_id) → `iam.users` (id)
- `IX_audit_security_events_1`: INDEX (tenant_id, user_id)

## `audit.data_access_events`
- `PK_audit_data_access_events`: PRIMARY KEY (id)
- `UQ_audit_data_access_events_1`: UNIQUE (tenant_id, id)
- `FK_audit_data_access_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_audit_data_access_events_2`: (actor_id) → `iam.users` (id)
- `IX_audit_data_access_events_1`: INDEX (tenant_id, actor_id)

## `audit.export_events`
- `PK_audit_export_events`: PRIMARY KEY (id)
- `UQ_audit_export_events_1`: UNIQUE (tenant_id, id)
- `FK_audit_export_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_audit_export_events_2`: (user_id) → `iam.users` (id)
- `CK_audit_export_events_1`: CHECK (`ISJSON(filter_metadata) = 1`)
- `IX_audit_export_events_1`: INDEX (tenant_id, user_id)

## `audit.approval_events`
- `PK_audit_approval_events`: PRIMARY KEY (id)
- `UQ_audit_approval_events_1`: UNIQUE (tenant_id, id)
- `FK_audit_approval_events_1`: (tenant_id) → `core.tenants` (id)
- `FK_audit_approval_events_2`: (tenant_id, approved_by) → `iam.memberships` (tenant_id, id)
- `IX_audit_approval_events_1`: INDEX (tenant_id, approved_by)

