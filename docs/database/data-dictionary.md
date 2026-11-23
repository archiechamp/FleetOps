# FleetOps column-level data dictionary v1.1

Proposed target: 174 tables, 1839 columns. Foundation subset is explicitly marked. See `../../database/metadata/model.json` for machine-readable metadata. P0B = P0 AI beta; G = global restricted, R = reference, T = tenant mutable, A = tenant append-only UUID, H = tenant high-volume append-only BIGINT.

All foreign keys are NO ACTION. Nullable composite foreign keys use SQL Server MATCH SIMPLE; application must enforce mandatory context and other business rules. A default of — means caller supplies the value or SQL Server generates identity/rowversion.

## `core.tenants`
Tenants · P0 · scope `G` · foundation: yes.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `name` | `NVARCHAR(200)` | NO | `—` | — | Confidential operations |
| `legal_name` | `NVARCHAR(200)` | YES | `—` | — | Confidential operations |
| `slug` | `VARCHAR(100)` | NO | `—` | — | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `'ACTIVE'` | — | Confidential operations |
| `dot_number` | `VARCHAR(20)` | YES | `—` | — | Confidential operations |
| `mc_number` | `VARCHAR(20)` | YES | `—` | — | Confidential operations |
| `timezone` | `NVARCHAR(64)` | NO | `—` | — | Confidential operations |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `core.tenant_settings`
Tenant settings · P0 · scope `T` · foundation: yes.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `setting_key` | `VARCHAR(100)` | NO | `—` | — | Confidential operations |
| `setting_value` | `NVARCHAR(MAX)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `core.terminals`
Terminals · P0 · scope `T` · foundation: yes.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `code` | `VARCHAR(30)` | NO | `—` | — | Confidential operations |
| `name` | `NVARCHAR(150)` | NO | `—` | — | Confidential operations |
| `address` | `NVARCHAR(500)` | YES | `—` | — | Restricted |
| `timezone` | `NVARCHAR(64)` | NO | `—` | — | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `core.departments`
Departments · P1 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); core.terminals(tenant_id,id) via (tenant_id,terminal_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `terminal_id` | `UNIQUEIDENTIFIER` | YES | `—` | core.terminals(tenant_id,id) via (tenant_id,terminal_id) | Confidential operations |
| `name` | `NVARCHAR(150)` | NO | `—` | — | Confidential operations |
| `code` | `VARCHAR(30)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `core.business_entities`
Business entities · P1 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `legal_name` | `NVARCHAR(200)` | NO | `—` | — | Confidential operations |
| `registration_number` | `NVARCHAR(100)` | YES | `—` | — | Confidential operations |
| `tax_reference` | `NVARCHAR(100)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `core.number_sequences`
Number sequences · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `entity_type` | `VARCHAR(50)` | NO | `—` | — | Confidential operations |
| `prefix` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `next_number` | `BIGINT` | NO | `1` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.countries`
Countries · P0 · scope `R` · foundation: yes.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `CHAR(2)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.jurisdictions`
Jurisdictions · P0 · scope `R` · foundation: yes.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `country_id` | `SMALLINT` | NO | `—` | ref.countries(id) via (country_id) | Internal reference |
| `code` | `VARCHAR(10)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.currencies`
Currencies · P0 · scope `R` · foundation: yes.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `code` | `CHAR(3)` | NO | `—` | PK;  | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.units_of_measure`
Units of measure · P0 · scope `R` · foundation: no.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `VARCHAR(20)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `dimension` | `VARCHAR(20)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.asset_types`
Asset types · P0 · scope `R` · foundation: yes.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `VARCHAR(30)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.trailer_types`
Trailer types · P0 · scope `R` · foundation: no.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `VARCHAR(30)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.fuel_types`
Fuel types · P0 · scope `R` · foundation: yes.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `VARCHAR(30)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.expense_categories`
Expense categories · P0 · scope `R` · foundation: no.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `VARCHAR(30)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.revenue_categories`
Revenue categories · P0 · scope `R` · foundation: no.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `VARCHAR(30)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.maintenance_types`
Maintenance types · P0 · scope `R` · foundation: no.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `VARCHAR(30)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.document_types`
Document types · P0 · scope `R` · foundation: no.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `VARCHAR(30)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.exception_types`
Exception types · P0 · scope `R` · foundation: no.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `VARCHAR(30)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ref.contact_types`
Contact types · P0 · scope `R` · foundation: no.
Classification: Internal reference. Retention: Versioned reference lifecycle. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `SMALLINT` | NO | `IDENTITY(1,1)` | PK;  | Internal reference |
| `code` | `VARCHAR(30)` | NO | `—` | — | Internal reference |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Internal reference |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Internal reference |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `iam.users`
Users · P0 · scope `G` · foundation: yes.
Classification: Restricted identity. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted identity |
| `auth_provider` | `VARCHAR(30)` | NO | `—` | — | Restricted identity |
| `external_subject` | `NVARCHAR(200)` | NO | `—` | — | Restricted |
| `email` | `NVARCHAR(254)` | YES | `—` | — | Restricted |
| `display_name` | `NVARCHAR(150)` | NO | `—` | — | Restricted identity |
| `status` | `VARCHAR(20)` | NO | `'ACTIVE'` | — | Restricted identity |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted identity |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `iam.memberships`
Memberships · P0 · scope `T` · foundation: yes.
Classification: Restricted identity. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted identity |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |
| `user_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.users(id) via (user_id) | Restricted identity |
| `status` | `VARCHAR(20)` | NO | `'ACTIVE'` | — | Restricted identity |
| `joined_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted identity |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted identity |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `iam.roles`
Roles · P0 · scope `T` · foundation: yes.
Classification: Restricted identity. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted identity |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |
| `code` | `VARCHAR(50)` | NO | `—` | — | Restricted identity |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Restricted identity |
| `description` | `NVARCHAR(500)` | YES | `—` | — | Restricted identity |
| `system_role` | `BIT` | NO | `0` | — | Restricted identity |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted identity |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted identity |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `iam.permissions`
Permissions · P0 · scope `G` · foundation: yes.
Classification: Restricted identity. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted identity |
| `code` | `VARCHAR(100)` | NO | `—` | — | Restricted identity |
| `resource` | `VARCHAR(50)` | NO | `—` | — | Restricted identity |
| `action` | `VARCHAR(50)` | NO | `—` | — | Restricted identity |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted identity |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `iam.membership_roles`
Membership roles · P0 · scope `T` · foundation: yes.
Classification: Restricted identity. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted identity |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,membership_id); iam.roles(tenant_id,id) via (tenant_id,role_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |
| `membership_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,membership_id) | Restricted identity |
| `role_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.roles(tenant_id,id) via (tenant_id,role_id) | Restricted identity |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted identity |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted identity |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `iam.role_permissions`
Role permissions · P0 · scope `T` · foundation: yes.
Classification: Restricted identity. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted identity |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.roles(tenant_id,id) via (tenant_id,role_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |
| `role_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.roles(tenant_id,id) via (tenant_id,role_id) | Restricted identity |
| `permission_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.permissions(id) via (permission_id) | Restricted identity |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted identity |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted identity |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `iam.user_preferences`
User preferences · P0 · scope `T` · foundation: no.
Classification: Restricted identity. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted identity |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,membership_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |
| `membership_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,membership_id) | Restricted identity |
| `timezone` | `NVARCHAR(64)` | NO | `—` | — | Restricted identity |
| `language` | `VARCHAR(10)` | NO | `—` | — | Restricted identity |
| `theme` | `VARCHAR(20)` | NO | `—` | — | Restricted identity |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted identity |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted identity |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `iam.invitations`
Invitations · P0 · scope `T` · foundation: no.
Classification: Restricted identity. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted identity |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.roles(tenant_id,id) via (tenant_id,invited_role_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |
| `email` | `NVARCHAR(254)` | NO | `—` | — | Restricted |
| `invited_role_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.roles(tenant_id,id) via (tenant_id,invited_role_id) | Restricted identity |
| `expires_at` | `DATETIME2(3)` | NO | `—` | — | Restricted identity |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted identity |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted identity |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted identity |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `iam.terminal_access`
Terminal access · P1 · scope `T` · foundation: no.
Classification: Restricted identity. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted identity |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,membership_id); core.terminals(tenant_id,id) via (tenant_id,terminal_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |
| `membership_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,membership_id) | Restricted identity |
| `terminal_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.terminals(tenant_id,id) via (tenant_id,terminal_id) | Restricted identity |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted identity |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted identity |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted identity |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted identity |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fleet.assets`
Assets · P0 · scope `T` · foundation: yes.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); core.terminals(tenant_id,id) via (tenant_id,terminal_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `unit_number` | `NVARCHAR(30)` | NO | `—` | — | Confidential operations |
| `asset_type_id` | `SMALLINT` | NO | `—` | ref.asset_types(id) via (asset_type_id) | Confidential operations |
| `vin` | `VARCHAR(17)` | YES | `—` | — | Confidential operations |
| `make` | `NVARCHAR(80)` | NO | `—` | — | Confidential operations |
| `model` | `NVARCHAR(80)` | NO | `—` | — | Confidential operations |
| `model_year` | `SMALLINT` | NO | `—` | — | Confidential operations |
| `ownership_type` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `status` | `VARCHAR(25)` | NO | `'AVAILABLE'` | — | Confidential operations |
| `terminal_id` | `UNIQUEIDENTIFIER` | YES | `—` | core.terminals(tenant_id,id) via (tenant_id,terminal_id) | Confidential operations |
| `in_service_date` | `DATE` | YES | `—` | — | Confidential operations |
| `acquisition_cost` | `DECIMAL(19,4)` | YES | `—` | — | Confidential operations |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential operations |
| `notes` | `NVARCHAR(2000)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fleet.vehicles`
Vehicles · P0 · scope `T` · foundation: yes.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `plate_number` | `NVARCHAR(30)` | YES | `—` | — | Confidential operations |
| `plate_jurisdiction_id` | `SMALLINT` | YES | `—` | ref.jurisdictions(id) via (plate_jurisdiction_id) | Confidential operations |
| `fuel_type_id` | `SMALLINT` | YES | `—` | ref.fuel_types(id) via (fuel_type_id) | Confidential operations |
| `fuel_capacity` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `gross_vehicle_weight` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `engine_serial` | `NVARCHAR(100)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fleet.trailers`
Trailers · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `trailer_type_id` | `SMALLINT` | NO | `—` | ref.trailer_types(id) via (trailer_type_id) | Confidential operations |
| `length_feet` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `max_payload` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `plate_number` | `NVARCHAR(30)` | YES | `—` | — | Confidential operations |
| `plate_jurisdiction_id` | `SMALLINT` | YES | `—` | ref.jurisdictions(id) via (plate_jurisdiction_id) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fleet.asset_status_history`
Asset status history · P0 · scope `A` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `previous_status` | `VARCHAR(25)` | YES | `—` | — | Confidential operations |
| `new_status` | `VARCHAR(25)` | NO | `—` | — | Confidential operations |
| `reason` | `NVARCHAR(500)` | YES | `—` | — | Confidential operations |
| `changed_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `actor_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.users(id) via (actor_id) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fleet.odometer_readings`
Odometer readings · P0 · scope `A` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `reading` | `DECIMAL(14,3)` | NO | `—` | — | Confidential operations |
| `unit_id` | `SMALLINT` | NO | `—` | ref.units_of_measure(id) via (unit_id) | Confidential operations |
| `recorded_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `source` | `VARCHAR(30)` | NO | `—` | — | Confidential operations |
| `source_reference` | `NVARCHAR(150)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fleet.engine_hour_readings`
Engine hour readings · P1 · scope `A` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `engine_hours` | `DECIMAL(14,3)` | NO | `—` | — | Confidential operations |
| `recorded_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `source` | `VARCHAR(30)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fleet.asset_availability`
Asset availability · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `start_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `end_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `availability_type` | `VARCHAR(25)` | NO | `—` | — | Confidential operations |
| `reason` | `NVARCHAR(500)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fleet.ownership_agreements`
Ownership agreements · P1 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); mnt.vendors(tenant_id,id) via (tenant_id,vendor_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `ownership_type` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `vendor_id` | `UNIQUEIDENTIFIER` | YES | `—` | mnt.vendors(tenant_id,id) via (tenant_id,vendor_id) | Confidential operations |
| `start_date` | `DATE` | NO | `—` | — | Confidential operations |
| `end_date` | `DATE` | YES | `—` | — | Confidential operations |
| `payment_amount` | `DECIMAL(19,4)` | YES | `—` | — | Confidential operations |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fleet.asset_meter_adjustments`
Asset meter adjustments · P1 · scope `A` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `meter_type` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `previous_reading` | `DECIMAL(14,3)` | NO | `—` | — | Confidential operations |
| `corrected_reading` | `DECIMAL(14,3)` | NO | `—` | — | Confidential operations |
| `reason` | `NVARCHAR(500)` | NO | `—` | — | Confidential operations |
| `actor_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.users(id) via (actor_id) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `hr.drivers`
Drivers · P0 · scope `T` · foundation: no.
Classification: Restricted driver PII. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted driver PII |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,membership_id); core.terminals(tenant_id,id) via (tenant_id,terminal_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |
| `membership_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,membership_id) | Restricted driver PII |
| `driver_number` | `NVARCHAR(30)` | NO | `—` | — | Restricted driver PII |
| `first_name` | `NVARCHAR(100)` | NO | `—` | — | Restricted driver PII |
| `last_name` | `NVARCHAR(100)` | NO | `—` | — | Restricted driver PII |
| `phone` | `NVARCHAR(30)` | YES | `—` | — | Restricted |
| `email` | `NVARCHAR(254)` | YES | `—` | — | Restricted |
| `employment_type` | `VARCHAR(25)` | NO | `—` | — | Restricted driver PII |
| `terminal_id` | `UNIQUEIDENTIFIER` | YES | `—` | core.terminals(tenant_id,id) via (tenant_id,terminal_id) | Restricted driver PII |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted driver PII |
| `hire_date` | `DATE` | YES | `—` | — | Restricted driver PII |
| `timezone` | `NVARCHAR(64)` | NO | `—` | — | Restricted driver PII |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted driver PII |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted driver PII |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `hr.driver_licenses`
Driver licenses · P0 · scope `T` · foundation: no.
Classification: Restricted driver PII. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted driver PII |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted driver PII |
| `license_number` | `NVARCHAR(100)` | NO | `—` | — | Restricted |
| `jurisdiction_id` | `SMALLINT` | NO | `—` | ref.jurisdictions(id) via (jurisdiction_id) | Restricted driver PII |
| `class` | `VARCHAR(10)` | NO | `—` | — | Restricted driver PII |
| `issued_date` | `DATE` | YES | `—` | — | Restricted driver PII |
| `expiry_date` | `DATE` | NO | `—` | — | Restricted driver PII |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted driver PII |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted driver PII |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `hr.driver_endorsements`
Driver endorsements · P1 · scope `T` · foundation: no.
Classification: Restricted driver PII. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted driver PII |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.driver_licenses(tenant_id,id) via (tenant_id,driver_license_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |
| `driver_license_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.driver_licenses(tenant_id,id) via (tenant_id,driver_license_id) | Restricted driver PII |
| `endorsement_code` | `VARCHAR(20)` | NO | `—` | — | Restricted driver PII |
| `expiry_date` | `DATE` | YES | `—` | — | Restricted driver PII |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted driver PII |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted driver PII |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `hr.driver_qualifications`
Driver qualifications · P0 · scope `T` · foundation: no.
Classification: Restricted driver PII. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted driver PII |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted driver PII |
| `qualification_type` | `VARCHAR(50)` | NO | `—` | — | Restricted driver PII |
| `verified_at` | `DATETIME2(3)` | YES | `—` | — | Restricted driver PII |
| `expires_at` | `DATETIME2(3)` | YES | `—` | — | Restricted driver PII |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted driver PII |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted driver PII |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted driver PII |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `hr.driver_availability`
Driver availability · P0 · scope `T` · foundation: no.
Classification: Restricted driver PII. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted driver PII |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted driver PII |
| `start_at` | `DATETIME2(3)` | NO | `—` | — | Restricted driver PII |
| `end_at` | `DATETIME2(3)` | NO | `—` | — | Restricted driver PII |
| `availability_status` | `VARCHAR(25)` | NO | `—` | — | Restricted driver PII |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted driver PII |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted driver PII |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `hr.driver_time_off`
Driver time off · P1 · scope `T` · foundation: no.
Classification: Restricted driver PII. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted driver PII |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted driver PII |
| `start_date` | `DATE` | NO | `—` | — | Restricted driver PII |
| `end_date` | `DATE` | NO | `—` | — | Restricted driver PII |
| `approval_status` | `VARCHAR(20)` | NO | `—` | — | Restricted driver PII |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted driver PII |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted driver PII |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `hr.driver_emergency_contacts`
Driver emergency contacts · P1 · scope `T` · foundation: no.
Classification: Restricted driver PII. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted driver PII |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted driver PII |
| `name` | `NVARCHAR(150)` | NO | `—` | — | Restricted driver PII |
| `relationship` | `NVARCHAR(50)` | NO | `—` | — | Restricted driver PII |
| `phone` | `NVARCHAR(30)` | NO | `—` | — | Restricted |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted driver PII |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted driver PII |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `hr.driver_compensation_profiles`
Driver compensation profiles · P1 · scope `T` · foundation: no.
Classification: Restricted driver PII. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted driver PII |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted driver PII |
| `compensation_type` | `VARCHAR(30)` | NO | `—` | — | Restricted driver PII |
| `rate` | `DECIMAL(19,4)` | NO | `—` | — | Restricted driver PII |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Restricted driver PII |
| `effective_from` | `DATETIME2(3)` | NO | `—` | — | Restricted driver PII |
| `effective_to` | `DATETIME2(3)` | YES | `—` | — | Restricted driver PII |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted driver PII |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted driver PII |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted driver PII |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `hr.driver_status_history`
Driver status history · P0 · scope `A` · foundation: no.
Classification: Restricted driver PII. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted driver PII |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted driver PII |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted driver PII |
| `previous_status` | `VARCHAR(20)` | YES | `—` | — | Restricted driver PII |
| `new_status` | `VARCHAR(20)` | NO | `—` | — | Restricted driver PII |
| `changed_at` | `DATETIME2(3)` | NO | `—` | — | Restricted driver PII |
| `actor_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.users(id) via (actor_id) | Restricted driver PII |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted driver PII |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `crm.customers`
Customers · P0 · scope `T` · foundation: no.
Classification: Confidential customer. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential customer |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |
| `customer_code` | `NVARCHAR(30)` | NO | `—` | — | Confidential customer |
| `legal_name` | `NVARCHAR(200)` | NO | `—` | — | Confidential customer |
| `display_name` | `NVARCHAR(200)` | NO | `—` | — | Confidential customer |
| `customer_type` | `VARCHAR(30)` | NO | `—` | — | Confidential customer |
| `payment_terms_days` | `SMALLINT` | YES | `—` | — | Confidential customer |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential customer |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential customer |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential customer |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `crm.customer_contacts`
Customer contacts · P0 · scope `T` · foundation: no.
Classification: Confidential customer. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential customer |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); crm.customers(tenant_id,id) via (tenant_id,customer_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |
| `customer_id` | `UNIQUEIDENTIFIER` | NO | `—` | crm.customers(tenant_id,id) via (tenant_id,customer_id) | Confidential customer |
| `name` | `NVARCHAR(150)` | NO | `—` | — | Confidential customer |
| `email` | `NVARCHAR(254)` | YES | `—` | — | Restricted |
| `phone` | `NVARCHAR(30)` | YES | `—` | — | Restricted |
| `contact_type_id` | `SMALLINT` | NO | `—` | ref.contact_types(id) via (contact_type_id) | Confidential customer |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential customer |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential customer |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `crm.locations`
Locations · P0 · scope `T` · foundation: no.
Classification: Confidential customer. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential customer |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); crm.customers(tenant_id,id) via (tenant_id,customer_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |
| `customer_id` | `UNIQUEIDENTIFIER` | YES | `—` | crm.customers(tenant_id,id) via (tenant_id,customer_id) | Confidential customer |
| `location_name` | `NVARCHAR(150)` | NO | `—` | — | Confidential customer |
| `address` | `NVARCHAR(500)` | NO | `—` | — | Restricted |
| `latitude` | `DECIMAL(9,6)` | YES | `—` | — | Restricted |
| `longitude` | `DECIMAL(9,6)` | YES | `—` | — | Restricted |
| `timezone` | `NVARCHAR(64)` | NO | `—` | — | Confidential customer |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential customer |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential customer |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `crm.customer_contracts`
Customer contracts · P1 · scope `T` · foundation: no.
Classification: Confidential customer. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential customer |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); crm.customers(tenant_id,id) via (tenant_id,customer_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |
| `customer_id` | `UNIQUEIDENTIFIER` | NO | `—` | crm.customers(tenant_id,id) via (tenant_id,customer_id) | Confidential customer |
| `start_date` | `DATE` | NO | `—` | — | Confidential customer |
| `end_date` | `DATE` | YES | `—` | — | Confidential customer |
| `terms` | `NVARCHAR(MAX)` | NO | `—` | — | Confidential customer |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential customer |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential customer |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential customer |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `crm.customer_rate_agreements`
Customer rate agreements · P1 · scope `T` · foundation: no.
Classification: Confidential customer. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential customer |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); crm.customer_contracts(tenant_id,id) via (tenant_id,contract_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |
| `contract_id` | `UNIQUEIDENTIFIER` | NO | `—` | crm.customer_contracts(tenant_id,id) via (tenant_id,contract_id) | Confidential customer |
| `equipment_type_id` | `SMALLINT` | NO | `—` | ref.asset_types(id) via (equipment_type_id) | Confidential customer |
| `rate_type` | `VARCHAR(30)` | NO | `—` | — | Confidential customer |
| `amount` | `DECIMAL(19,4)` | NO | `—` | — | Confidential customer |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential customer |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential customer |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential customer |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `crm.customer_notes`
Customer notes · P0 · scope `T` · foundation: no.
Classification: Confidential customer. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential customer |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); crm.customers(tenant_id,id) via (tenant_id,customer_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |
| `customer_id` | `UNIQUEIDENTIFIER` | NO | `—` | crm.customers(tenant_id,id) via (tenant_id,customer_id) | Confidential customer |
| `note` | `NVARCHAR(2000)` | NO | `—` | — | Confidential customer |
| `author_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.users(id) via (author_id) | Confidential customer |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential customer |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential customer |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential customer |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential customer |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.loads`
Loads · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); crm.customers(tenant_id,id) via (tenant_id,customer_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `load_number` | `NVARCHAR(40)` | NO | `—` | — | Confidential operations |
| `customer_id` | `UNIQUEIDENTIFIER` | NO | `—` | crm.customers(tenant_id,id) via (tenant_id,customer_id) | Confidential operations |
| `customer_reference` | `NVARCHAR(100)` | YES | `—` | — | Confidential operations |
| `commodity` | `NVARCHAR(255)` | YES | `—` | — | Confidential operations |
| `weight_lbs` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `equipment_type_id` | `SMALLINT` | YES | `—` | ref.asset_types(id) via (equipment_type_id) | Confidential operations |
| `commercial_status` | `VARCHAR(25)` | NO | `'DRAFT'` | — | Confidential operations |
| `special_instructions` | `NVARCHAR(MAX)` | YES | `—` | — | Confidential operations |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.load_stops`
Load stops · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.loads(tenant_id,id) via (tenant_id,load_id); crm.locations(tenant_id,id) via (tenant_id,location_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `load_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.loads(tenant_id,id) via (tenant_id,load_id) | Confidential operations |
| `sequence_number` | `INT` | NO | `—` | — | Confidential operations |
| `stop_type` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `location_id` | `UNIQUEIDENTIFIER` | NO | `—` | crm.locations(tenant_id,id) via (tenant_id,location_id) | Confidential operations |
| `address_snapshot` | `NVARCHAR(500)` | NO | `—` | — | Confidential operations |
| `timezone` | `NVARCHAR(64)` | NO | `—` | — | Confidential operations |
| `appointment_start` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `appointment_end` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.load_status_history`
Load status history · P0 · scope `A` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.loads(tenant_id,id) via (tenant_id,load_id) | Confidential operations |
| `load_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.loads(tenant_id,id) via (tenant_id,load_id) | Confidential operations |
| `previous_status` | `VARCHAR(25)` | YES | `—` | — | Confidential operations |
| `new_status` | `VARCHAR(25)` | NO | `—` | — | Confidential operations |
| `changed_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `actor_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.users(id) via (actor_id) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.trips`
Trips · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,dispatcher_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `trip_number` | `NVARCHAR(40)` | NO | `—` | — | Confidential operations |
| `status` | `VARCHAR(25)` | NO | `'DRAFT'` | — | Confidential operations |
| `planned_start_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `planned_end_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `actual_start_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `actual_end_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `dispatcher_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,dispatcher_id) | Confidential operations |
| `closed_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `cancellation_reason` | `NVARCHAR(500)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.trip_loads`
Trip loads · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); ops.loads(tenant_id,id) via (tenant_id,load_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `load_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.loads(tenant_id,id) via (tenant_id,load_id) | Confidential operations |
| `sequence_number` | `INT` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.trip_stops`
Trip stops · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); ops.load_stops(tenant_id,id) via (tenant_id,load_stop_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `load_stop_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.load_stops(tenant_id,id) via (tenant_id,load_stop_id) | Confidential operations |
| `sequence_number` | `INT` | NO | `—` | — | Confidential operations |
| `arrival_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `departure_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.trip_assignments`
Trip assignments · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); fleet.vehicles(tenant_id,id) via (tenant_id,vehicle_id); fleet.trailers(tenant_id,id) via (tenant_id,trailer_id); iam.memberships(tenant_id,id) via (tenant_id,assigned_by); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Confidential operations |
| `vehicle_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.vehicles(tenant_id,id) via (tenant_id,vehicle_id) | Confidential operations |
| `trailer_id` | `UNIQUEIDENTIFIER` | YES | `—` | fleet.trailers(tenant_id,id) via (tenant_id,trailer_id) | Confidential operations |
| `assigned_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `effective_from` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `effective_to` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `assigned_by` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,assigned_by) | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `release_reason` | `NVARCHAR(500)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.equipment_reservations`
Equipment reservations · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); ops.trip_assignments(tenant_id,id) via (tenant_id,assignment_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `assignment_id` | `UNIQUEIDENTIFIER` | YES | `—` | ops.trip_assignments(tenant_id,id) via (tenant_id,assignment_id) | Confidential operations |
| `start_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `end_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.driver_reservations`
Driver reservations · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); ops.trip_assignments(tenant_id,id) via (tenant_id,assignment_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Confidential operations |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `assignment_id` | `UNIQUEIDENTIFIER` | YES | `—` | ops.trip_assignments(tenant_id,id) via (tenant_id,assignment_id) | Confidential operations |
| `start_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `end_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.trip_events`
Trip events · P0 · scope `A` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `event_type` | `VARCHAR(40)` | NO | `—` | — | Confidential operations |
| `occurred_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `received_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `source` | `VARCHAR(30)` | NO | `—` | — | Confidential operations |
| `event_reference` | `NVARCHAR(150)` | NO | `—` | — | Confidential operations |
| `payload` | `NVARCHAR(MAX)` | YES | `—` | — | Restricted |
| `actor_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.users(id) via (actor_id) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.trip_exceptions`
Trip exceptions · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); iam.memberships(tenant_id,id) via (tenant_id,owner_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `exception_type_id` | `SMALLINT` | NO | `—` | ref.exception_types(id) via (exception_type_id) | Confidential operations |
| `severity` | `VARCHAR(15)` | NO | `—` | — | Confidential operations |
| `description` | `NVARCHAR(2000)` | NO | `—` | — | Confidential operations |
| `owner_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,owner_id) | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `resolved_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.trip_distances`
Trip distances · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `loaded_miles` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `empty_miles` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `source` | `VARCHAR(30)` | NO | `—` | — | Confidential operations |
| `measurement_status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `measured_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.trip_status_history`
Trip status history · P0 · scope `A` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential operations |
| `previous_status` | `VARCHAR(25)` | YES | `—` | — | Confidential operations |
| `new_status` | `VARCHAR(25)` | NO | `—` | — | Confidential operations |
| `changed_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `actor_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.users(id) via (actor_id) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.delivery_confirmations`
Delivery confirmations · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trip_stops(tenant_id,id) via (tenant_id,trip_stop_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `trip_stop_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trip_stops(tenant_id,id) via (tenant_id,trip_stop_id) | Confidential operations |
| `receiver_name` | `NVARCHAR(150)` | YES | `—` | — | Confidential operations |
| `delivered_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `verification_status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ops.trip_exception_events`
Trip exception events · P0 · scope `A` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trip_exceptions(tenant_id,id) via (tenant_id,exception_id) | Confidential operations |
| `exception_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trip_exceptions(tenant_id,id) via (tenant_id,exception_id) | Confidential operations |
| `event_type` | `VARCHAR(30)` | NO | `—` | — | Confidential operations |
| `note` | `NVARCHAR(1000)` | YES | `—` | — | Confidential operations |
| `occurred_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `actor_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.users(id) via (actor_id) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.providers`
Providers · P0 · scope `G` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `provider_code` | `VARCHAR(50)` | NO | `—` | — | Restricted integration |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Restricted integration |
| `integration_type` | `VARCHAR(30)` | NO | `—` | — | Restricted integration |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted integration |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.connections`
Connections · P0 · scope `T` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |
| `provider_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.providers(id) via (provider_id) | Restricted integration |
| `secret_reference` | `NVARCHAR(250)` | NO | `—` | — | Restricted |
| `connection_status` | `VARCHAR(20)` | NO | `—` | — | Restricted integration |
| `external_account_id` | `NVARCHAR(150)` | YES | `—` | — | Restricted integration |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted integration |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted integration |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.external_mappings`
External mappings · P0 · scope `T` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); integration.connections(tenant_id,id) via (tenant_id,connection_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |
| `connection_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.connections(tenant_id,id) via (tenant_id,connection_id) | Restricted integration |
| `entity_type` | `VARCHAR(50)` | NO | `—` | — | Restricted integration |
| `internal_id` | `UNIQUEIDENTIFIER` | NO | `—` | — | Restricted integration |
| `external_id` | `NVARCHAR(150)` | NO | `—` | — | Restricted integration |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted integration |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted integration |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.sync_jobs`
Sync jobs · P0 · scope `T` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); integration.connections(tenant_id,id) via (tenant_id,connection_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |
| `connection_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.connections(tenant_id,id) via (tenant_id,connection_id) | Restricted integration |
| `job_type` | `VARCHAR(30)` | NO | `—` | — | Restricted integration |
| `started_at` | `DATETIME2(3)` | YES | `—` | — | Restricted integration |
| `completed_at` | `DATETIME2(3)` | YES | `—` | — | Restricted integration |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted integration |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted integration |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted integration |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.sync_checkpoints`
Sync checkpoints · P0 · scope `T` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); integration.connections(tenant_id,id) via (tenant_id,connection_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |
| `connection_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.connections(tenant_id,id) via (tenant_id,connection_id) | Restricted integration |
| `resource_type` | `VARCHAR(50)` | NO | `—` | — | Restricted integration |
| `cursor_value` | `NVARCHAR(2000)` | YES | `—` | — | Restricted integration |
| `last_sync_at` | `DATETIME2(3)` | YES | `—` | — | Restricted integration |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted integration |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted integration |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.webhook_events`
Webhook events · P0 · scope `T` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); integration.connections(tenant_id,id) via (tenant_id,connection_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |
| `connection_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.connections(tenant_id,id) via (tenant_id,connection_id) | Restricted integration |
| `external_event_id` | `NVARCHAR(150)` | NO | `—` | — | Restricted integration |
| `event_type` | `VARCHAR(50)` | NO | `—` | — | Restricted integration |
| `received_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted integration |
| `payload` | `NVARCHAR(MAX)` | YES | `—` | — | Restricted |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted integration |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted integration |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.processing_failures`
Processing failures · P0 · scope `T` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); integration.sync_jobs(tenant_id,id) via (tenant_id,sync_job_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |
| `sync_job_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.sync_jobs(tenant_id,id) via (tenant_id,sync_job_id) | Restricted integration |
| `error_code` | `VARCHAR(50)` | NO | `—` | — | Restricted integration |
| `error_message` | `NVARCHAR(1000)` | NO | `—` | — | Restricted integration |
| `retry_count` | `INT` | NO | `0` | — | Restricted integration |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted integration |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted integration |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.import_batches`
Import batches · P0 · scope `T` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |
| `import_type` | `VARCHAR(30)` | NO | `—` | — | Restricted integration |
| `filename` | `NVARCHAR(255)` | NO | `—` | — | Restricted integration |
| `imported_by` | `UNIQUEIDENTIFIER` | NO | `—` | iam.users(id) via (imported_by) | Restricted integration |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted integration |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted integration |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted integration |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.import_errors`
Import errors · P0 · scope `A` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); integration.import_batches(tenant_id,id) via (tenant_id,batch_id) | Restricted integration |
| `batch_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.import_batches(tenant_id,id) via (tenant_id,batch_id) | Restricted integration |
| `row_number` | `INT` | NO | `—` | — | Restricted integration |
| `error_code` | `VARCHAR(50)` | NO | `—` | — | Restricted integration |
| `error_description` | `NVARCHAR(1000)` | NO | `—` | — | Restricted integration |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.outbox_events`
Outbox events · P0 · scope `T` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |
| `event_type` | `VARCHAR(50)` | NO | `—` | — | Restricted integration |
| `aggregate_id` | `UNIQUEIDENTIFIER` | NO | `—` | — | Restricted integration |
| `payload` | `NVARCHAR(MAX)` | NO | `—` | — | Restricted |
| `publication_status` | `VARCHAR(20)` | NO | `—` | — | Restricted integration |
| `published_at` | `DATETIME2(3)` | YES | `—` | — | Restricted integration |
| `attempt_count` | `INT` | NO | `0` | — | Restricted integration |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted integration |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted integration |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `integration.idempotency_keys`
Idempotency keys · P0 · scope `T` · foundation: no.
Classification: Restricted integration. Retention: 30-day transient payload proposal; business evidence retained. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted integration |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |
| `operation_scope` | `VARCHAR(80)` | NO | `—` | — | Restricted integration |
| `request_key` | `NVARCHAR(150)` | NO | `—` | — | Restricted integration |
| `request_hash` | `BINARY(32)` | NO | `—` | — | Restricted integration |
| `response_reference` | `NVARCHAR(150)` | YES | `—` | — | Restricted integration |
| `expires_at` | `DATETIME2(3)` | NO | `—` | — | Restricted integration |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted integration |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted integration |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted integration |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted integration |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `gps.devices`
Devices · P0 · scope `T` · foundation: no.
Classification: Restricted location. Retention: 90-day raw telemetry proposal; required records preserved. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); integration.connections(tenant_id,id) via (tenant_id,connection_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted location |
| `connection_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.connections(tenant_id,id) via (tenant_id,connection_id) | Restricted location |
| `external_device_id` | `NVARCHAR(150)` | NO | `—` | — | Restricted location |
| `serial_number` | `NVARCHAR(100)` | YES | `—` | — | Restricted location |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `gps.device_assignments`
Device assignments · P0 · scope `T` · foundation: no.
Classification: Restricted location. Retention: 90-day raw telemetry proposal; required records preserved. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); gps.devices(tenant_id,id) via (tenant_id,device_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted location |
| `device_id` | `UNIQUEIDENTIFIER` | NO | `—` | gps.devices(tenant_id,id) via (tenant_id,device_id) | Restricted location |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted location |
| `effective_from` | `DATETIME2(3)` | NO | `—` | — | Restricted location |
| `effective_to` | `DATETIME2(3)` | YES | `—` | — | Restricted location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `gps.vehicle_positions`
Vehicle positions · P0 · scope `H` · foundation: no.
Classification: Restricted location. Retention: 90-day raw telemetry proposal; required records preserved. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `BIGINT` | NO | `IDENTITY(1,1)` | PK;  | Restricted location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); gps.devices(tenant_id,id) via (tenant_id,device_id) | Restricted location |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted location |
| `device_id` | `UNIQUEIDENTIFIER` | NO | `—` | gps.devices(tenant_id,id) via (tenant_id,device_id) | Restricted location |
| `latitude` | `DECIMAL(9,6)` | NO | `—` | — | Restricted |
| `longitude` | `DECIMAL(9,6)` | NO | `—` | — | Restricted |
| `speed_mph` | `DECIMAL(14,3)` | YES | `—` | — | Restricted location |
| `heading_degrees` | `DECIMAL(5,2)` | YES | `—` | — | Restricted location |
| `ignition_on` | `BIT` | YES | `—` | — | Restricted location |
| `odometer_miles` | `DECIMAL(14,3)` | YES | `—` | — | Restricted location |
| `recorded_at` | `DATETIME2(3)` | NO | `—` | — | Restricted location |
| `received_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `provider_event_id` | `NVARCHAR(150)` | NO | `—` | — | Restricted location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `gps.latest_vehicle_positions`
Latest vehicle positions · P0 · scope `T` · foundation: no.
Classification: Restricted location. Retention: 90-day raw telemetry proposal; required records preserved. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by); gps.vehicle_positions(tenant_id,asset_id,id) via (tenant_id,asset_id,position_id) | Restricted location |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id); gps.vehicle_positions(tenant_id,asset_id,id) via (tenant_id,asset_id,position_id) | Restricted location |
| `position_id` | `BIGINT` | NO | `—` | gps.vehicle_positions(tenant_id,asset_id,id) via (tenant_id,asset_id,position_id) | Restricted location |
| `recorded_at` | `DATETIME2(3)` | NO | `—` | — | Restricted location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `gps.telemetry_events`
Telemetry events · P1 · scope `H` · foundation: no.
Classification: Restricted location. Retention: 90-day raw telemetry proposal; required records preserved. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `BIGINT` | NO | `IDENTITY(1,1)` | PK;  | Restricted location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted location |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted location |
| `event_type` | `VARCHAR(50)` | NO | `—` | — | Restricted location |
| `event_value` | `NVARCHAR(MAX)` | NO | `—` | — | Restricted location |
| `recorded_at` | `DATETIME2(3)` | NO | `—` | — | Restricted location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `gps.geofences`
Geofences · P1 · scope `T` · foundation: no.
Classification: Restricted location. Retention: 90-day raw telemetry proposal; required records preserved. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted location |
| `name` | `NVARCHAR(150)` | NO | `—` | — | Restricted location |
| `boundary` | `GEOGRAPHY` | NO | `—` | — | Restricted location |
| `geofence_type` | `VARCHAR(30)` | NO | `—` | — | Restricted location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `gps.geofence_events`
Geofence events · P1 · scope `H` · foundation: no.
Classification: Restricted location. Retention: 90-day raw telemetry proposal; required records preserved. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `BIGINT` | NO | `IDENTITY(1,1)` | PK;  | Restricted location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); gps.geofences(tenant_id,id) via (tenant_id,geofence_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted location |
| `geofence_id` | `UNIQUEIDENTIFIER` | NO | `—` | gps.geofences(tenant_id,id) via (tenant_id,geofence_id) | Restricted location |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted location |
| `event_type` | `VARCHAR(30)` | NO | `—` | — | Restricted location |
| `occurred_at` | `DATETIME2(3)` | NO | `—` | — | Restricted location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `gps.vehicle_fault_codes`
Vehicle fault codes · P1 · scope `T` · foundation: no.
Classification: Restricted location. Retention: 90-day raw telemetry proposal; required records preserved. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted location |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted location |
| `fault_code` | `VARCHAR(50)` | NO | `—` | — | Restricted location |
| `severity` | `VARCHAR(20)` | NO | `—` | — | Restricted location |
| `detected_at` | `DATETIME2(3)` | NO | `—` | — | Restricted location |
| `resolved_at` | `DATETIME2(3)` | YES | `—` | — | Restricted location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `gps.idle_sessions`
Idle sessions · P1 · scope `A` · foundation: no.
Classification: Restricted location. Retention: 90-day raw telemetry proposal; required records preserved. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted location |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted location |
| `started_at` | `DATETIME2(3)` | NO | `—` | — | Restricted location |
| `ended_at` | `DATETIME2(3)` | NO | `—` | — | Restricted location |
| `duration_seconds` | `INT` | NO | `—` | — | Restricted location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.service_types`
Service types · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `service_code` | `VARCHAR(30)` | NO | `—` | — | Confidential operations |
| `name` | `NVARCHAR(100)` | NO | `—` | — | Confidential operations |
| `description` | `NVARCHAR(500)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.maintenance_schedules`
Maintenance schedules · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); mnt.service_types(tenant_id,id) via (tenant_id,service_type_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `service_type_id` | `UNIQUEIDENTIFIER` | NO | `—` | mnt.service_types(tenant_id,id) via (tenant_id,service_type_id) | Confidential operations |
| `interval_days` | `INT` | YES | `—` | — | Confidential operations |
| `interval_miles` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `interval_hours` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `enabled` | `BIT` | NO | `1` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.scheduled_services`
Scheduled services · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); mnt.maintenance_schedules(tenant_id,id) via (tenant_id,schedule_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `schedule_id` | `UNIQUEIDENTIFIER` | NO | `—` | mnt.maintenance_schedules(tenant_id,id) via (tenant_id,schedule_id) | Confidential operations |
| `due_date` | `DATE` | YES | `—` | — | Confidential operations |
| `due_odometer` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `due_engine_hours` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.service_records`
Service records · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); mnt.service_types(tenant_id,id) via (tenant_id,service_type_id); mnt.vendors(tenant_id,id) via (tenant_id,vendor_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `service_type_id` | `UNIQUEIDENTIFIER` | NO | `—` | mnt.service_types(tenant_id,id) via (tenant_id,service_type_id) | Confidential operations |
| `vendor_id` | `UNIQUEIDENTIFIER` | YES | `—` | mnt.vendors(tenant_id,id) via (tenant_id,vendor_id) | Confidential operations |
| `service_date` | `DATE` | NO | `—` | — | Confidential operations |
| `odometer` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `description` | `NVARCHAR(2000)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.maintenance_restrictions`
Maintenance restrictions · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,release_approved_by); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `reason` | `NVARCHAR(500)` | NO | `—` | — | Confidential operations |
| `imposed_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `released_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `release_approved_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,release_approved_by) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.vendors`
Vendors · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `vendor_code` | `NVARCHAR(30)` | NO | `—` | — | Confidential operations |
| `name` | `NVARCHAR(200)` | NO | `—` | — | Confidential operations |
| `email` | `NVARCHAR(254)` | YES | `—` | — | Restricted |
| `phone` | `NVARCHAR(30)` | YES | `—` | — | Restricted |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.work_orders`
Work orders · P1 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); mnt.vendors(tenant_id,id) via (tenant_id,vendor_id); iam.memberships(tenant_id,id) via (tenant_id,approved_by); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `work_order_number` | `NVARCHAR(40)` | NO | `—` | — | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `vendor_id` | `UNIQUEIDENTIFIER` | YES | `—` | mnt.vendors(tenant_id,id) via (tenant_id,vendor_id) | Confidential operations |
| `maintenance_type_id` | `SMALLINT` | NO | `—` | ref.maintenance_types(id) via (maintenance_type_id) | Confidential operations |
| `title` | `NVARCHAR(200)` | NO | `—` | — | Confidential operations |
| `description` | `NVARCHAR(MAX)` | YES | `—` | — | Confidential operations |
| `priority` | `VARCHAR(15)` | NO | `—` | — | Confidential operations |
| `status` | `VARCHAR(25)` | NO | `—` | — | Confidential operations |
| `odometer_miles` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `opened_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `scheduled_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `completed_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `approved_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,approved_by) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.work_order_items`
Work order items · P1 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); mnt.work_orders(tenant_id,id) via (tenant_id,work_order_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `work_order_id` | `UNIQUEIDENTIFIER` | NO | `—` | mnt.work_orders(tenant_id,id) via (tenant_id,work_order_id) | Confidential operations |
| `description` | `NVARCHAR(500)` | NO | `—` | — | Confidential operations |
| `labor_hours` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `quantity` | `DECIMAL(14,3)` | NO | `—` | — | Confidential operations |
| `unit_cost` | `DECIMAL(19,4)` | NO | `—` | — | Confidential operations |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.defects`
Defects · P1 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); compliance.inspections(tenant_id,id) via (tenant_id,inspection_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `inspection_id` | `UNIQUEIDENTIFIER` | YES | `—` | compliance.inspections(tenant_id,id) via (tenant_id,inspection_id) | Confidential operations |
| `description` | `NVARCHAR(2000)` | NO | `—` | — | Confidential operations |
| `severity` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.parts`
Parts · P2 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `part_number` | `NVARCHAR(50)` | NO | `—` | — | Confidential operations |
| `description` | `NVARCHAR(500)` | NO | `—` | — | Confidential operations |
| `unit_cost` | `DECIMAL(19,4)` | YES | `—` | — | Confidential operations |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.parts_inventory`
Parts inventory · P2 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); mnt.parts(tenant_id,id) via (tenant_id,part_id); core.terminals(tenant_id,id) via (tenant_id,terminal_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `part_id` | `UNIQUEIDENTIFIER` | NO | `—` | mnt.parts(tenant_id,id) via (tenant_id,part_id) | Confidential operations |
| `terminal_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.terminals(tenant_id,id) via (tenant_id,terminal_id) | Confidential operations |
| `quantity_on_hand` | `DECIMAL(14,3)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.tire_records`
Tire records · P2 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `tire_position` | `VARCHAR(30)` | NO | `—` | — | Confidential operations |
| `serial_number` | `NVARCHAR(100)` | NO | `—` | — | Confidential operations |
| `installed_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `removed_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `mnt.downtime_events`
Downtime events · P1 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential operations |
| `started_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `ended_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `reason` | `NVARCHAR(500)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fuel.fuel_transactions`
Fuel transactions · P0 · scope `T` · foundation: no.
Classification: Confidential finance/location. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance/location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); integration.connections(tenant_id,id) via (tenant_id,connection_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |
| `asset_id` | `UNIQUEIDENTIFIER` | YES | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential finance/location |
| `driver_id` | `UNIQUEIDENTIFIER` | YES | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Confidential finance/location |
| `fuel_type_id` | `SMALLINT` | NO | `—` | ref.fuel_types(id) via (fuel_type_id) | Confidential finance/location |
| `transaction_at` | `DATETIME2(3)` | NO | `—` | — | Confidential finance/location |
| `quantity_gallons` | `DECIMAL(14,3)` | NO | `—` | — | Confidential finance/location |
| `price_per_gallon` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance/location |
| `total_amount` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance/location |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential finance/location |
| `odometer_miles` | `DECIMAL(14,3)` | YES | `—` | — | Confidential finance/location |
| `jurisdiction_id` | `SMALLINT` | YES | `—` | ref.jurisdictions(id) via (jurisdiction_id) | Confidential finance/location |
| `merchant_name` | `NVARCHAR(200)` | YES | `—` | — | Confidential finance/location |
| `connection_id` | `UNIQUEIDENTIFIER` | YES | `—` | integration.connections(tenant_id,id) via (tenant_id,connection_id) | Confidential finance/location |
| `external_transaction_id` | `NVARCHAR(150)` | YES | `—` | — | Confidential finance/location |
| `source_system` | `VARCHAR(50)` | NO | `—` | — | Confidential finance/location |
| `reconciliation_status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance/location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance/location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance/location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fuel.fuel_transaction_matches`
Fuel transaction matches · P0 · scope `T` · foundation: no.
Classification: Confidential finance/location. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance/location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fuel.fuel_transactions(tenant_id,id) via (tenant_id,fuel_transaction_id); fin.expenses(tenant_id,id) via (tenant_id,expense_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |
| `fuel_transaction_id` | `UNIQUEIDENTIFIER` | NO | `—` | fuel.fuel_transactions(tenant_id,id) via (tenant_id,fuel_transaction_id) | Confidential finance/location |
| `expense_id` | `UNIQUEIDENTIFIER` | NO | `—` | fin.expenses(tenant_id,id) via (tenant_id,expense_id) | Confidential finance/location |
| `match_status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance/location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance/location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance/location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fuel.fuel_cards`
Fuel cards · P1 · scope `T` · foundation: no.
Classification: Confidential finance/location. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance/location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); integration.connections(tenant_id,id) via (tenant_id,connection_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |
| `connection_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.connections(tenant_id,id) via (tenant_id,connection_id) | Confidential finance/location |
| `masked_card_number` | `VARCHAR(20)` | NO | `—` | — | Confidential finance/location |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance/location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance/location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance/location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fuel.fuel_card_assignments`
Fuel card assignments · P1 · scope `T` · foundation: no.
Classification: Confidential finance/location. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance/location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fuel.fuel_cards(tenant_id,id) via (tenant_id,fuel_card_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |
| `fuel_card_id` | `UNIQUEIDENTIFIER` | NO | `—` | fuel.fuel_cards(tenant_id,id) via (tenant_id,fuel_card_id) | Confidential finance/location |
| `asset_id` | `UNIQUEIDENTIFIER` | YES | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential finance/location |
| `driver_id` | `UNIQUEIDENTIFIER` | YES | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Confidential finance/location |
| `effective_from` | `DATETIME2(3)` | NO | `—` | — | Confidential finance/location |
| `effective_to` | `DATETIME2(3)` | YES | `—` | — | Confidential finance/location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance/location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance/location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fuel.fuel_import_batches`
Fuel import batches · P1 · scope `T` · foundation: no.
Classification: Confidential finance/location. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance/location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); integration.connections(tenant_id,id) via (tenant_id,connection_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |
| `connection_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.connections(tenant_id,id) via (tenant_id,connection_id) | Confidential finance/location |
| `external_batch_id` | `NVARCHAR(150)` | NO | `—` | — | Confidential finance/location |
| `imported_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance/location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance/location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance/location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fuel.fuel_efficiency_records`
Fuel efficiency records · P1 · scope `T` · foundation: no.
Classification: Confidential finance/location. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance/location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential finance/location |
| `period_start` | `DATE` | NO | `—` | — | Confidential finance/location |
| `period_end` | `DATE` | NO | `—` | — | Confidential finance/location |
| `miles` | `DECIMAL(14,3)` | NO | `—` | — | Confidential finance/location |
| `gallons` | `DECIMAL(14,3)` | NO | `—` | — | Confidential finance/location |
| `source` | `VARCHAR(30)` | NO | `—` | — | Confidential finance/location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance/location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance/location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fuel.fuel_exceptions`
Fuel exceptions · P1 · scope `T` · foundation: no.
Classification: Confidential finance/location. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance/location |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fuel.fuel_transactions(tenant_id,id) via (tenant_id,fuel_transaction_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |
| `fuel_transaction_id` | `UNIQUEIDENTIFIER` | NO | `—` | fuel.fuel_transactions(tenant_id,id) via (tenant_id,fuel_transaction_id) | Confidential finance/location |
| `exception_type` | `VARCHAR(30)` | NO | `—` | — | Confidential finance/location |
| `severity` | `VARCHAR(20)` | NO | `—` | — | Confidential finance/location |
| `resolution_status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance/location |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance/location |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance/location |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance/location |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance/location |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.revenue_items`
Revenue items · P0 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.loads(tenant_id,id) via (tenant_id,load_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `load_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.loads(tenant_id,id) via (tenant_id,load_id) | Confidential finance |
| `revenue_category_id` | `SMALLINT` | NO | `—` | ref.revenue_categories(id) via (revenue_category_id) | Confidential finance |
| `amount` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential finance |
| `recognition_status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance |
| `recognized_at` | `DATETIME2(3)` | YES | `—` | — | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.expenses`
Expenses · P0 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); mnt.vendors(tenant_id,id) via (tenant_id,vendor_id); iam.memberships(tenant_id,id) via (tenant_id,approved_by); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `expense_category_id` | `SMALLINT` | NO | `—` | ref.expense_categories(id) via (expense_category_id) | Confidential finance |
| `vendor_id` | `UNIQUEIDENTIFIER` | YES | `—` | mnt.vendors(tenant_id,id) via (tenant_id,vendor_id) | Confidential finance |
| `description` | `NVARCHAR(500)` | NO | `—` | — | Confidential finance |
| `expense_date` | `DATE` | NO | `—` | — | Confidential finance |
| `amount` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential finance |
| `source_type` | `VARCHAR(30)` | NO | `—` | — | Confidential finance |
| `source_reference` | `NVARCHAR(150)` | YES | `—` | — | Confidential finance |
| `reconciliation_status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance |
| `approval_status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance |
| `approved_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,approved_by) | Confidential finance |
| `approved_at` | `DATETIME2(3)` | YES | `—` | — | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.expense_allocations`
Expense allocations · P0 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fin.expenses(tenant_id,id) via (tenant_id,expense_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `expense_id` | `UNIQUEIDENTIFIER` | NO | `—` | fin.expenses(tenant_id,id) via (tenant_id,expense_id) | Confidential finance |
| `trip_id` | `UNIQUEIDENTIFIER` | YES | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential finance |
| `asset_id` | `UNIQUEIDENTIFIER` | YES | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Confidential finance |
| `allocated_amount` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance |
| `allocation_basis` | `VARCHAR(50)` | NO | `—` | — | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.revenue_allocations`
Revenue allocations · P0 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fin.revenue_items(tenant_id,id) via (tenant_id,revenue_item_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `revenue_item_id` | `UNIQUEIDENTIFIER` | NO | `—` | fin.revenue_items(tenant_id,id) via (tenant_id,revenue_item_id) | Confidential finance |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential finance |
| `allocated_amount` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance |
| `allocation_basis` | `VARCHAR(50)` | NO | `—` | — | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.trip_financial_closures`
Trip financial closures · P0 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); iam.memberships(tenant_id,id) via (tenant_id,finalized_by); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential finance |
| `closure_status` | `VARCHAR(25)` | NO | `—` | — | Confidential finance |
| `finalized_at` | `DATETIME2(3)` | YES | `—` | — | Confidential finance |
| `finalized_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,finalized_by) | Confidential finance |
| `calculation_version` | `VARCHAR(30)` | NO | `—` | — | Confidential finance |
| `revision_number` | `INT` | NO | `—` | — | Confidential finance |
| `revenue_total` | `DECIMAL(19,4)` | YES | `—` | — | Confidential finance |
| `direct_cost_total` | `DECIMAL(19,4)` | YES | `—` | — | Confidential finance |
| `snapshot` | `NVARCHAR(MAX)` | YES | `—` | — | Confidential finance |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.cost_allocation_rules`
Cost allocation rules · P1 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `expense_category_id` | `SMALLINT` | NO | `—` | ref.expense_categories(id) via (expense_category_id) | Confidential finance |
| `allocation_method` | `VARCHAR(50)` | NO | `—` | — | Confidential finance |
| `effective_from` | `DATETIME2(3)` | NO | `—` | — | Confidential finance |
| `effective_to` | `DATETIME2(3)` | YES | `—` | — | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.invoices`
Invoices · P1 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); crm.customers(tenant_id,id) via (tenant_id,customer_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `customer_id` | `UNIQUEIDENTIFIER` | NO | `—` | crm.customers(tenant_id,id) via (tenant_id,customer_id) | Confidential finance |
| `invoice_number` | `NVARCHAR(40)` | NO | `—` | — | Confidential finance |
| `invoice_date` | `DATE` | NO | `—` | — | Confidential finance |
| `due_date` | `DATE` | NO | `—` | — | Confidential finance |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.invoice_items`
Invoice items · P1 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fin.invoices(tenant_id,id) via (tenant_id,invoice_id); fin.revenue_items(tenant_id,id) via (tenant_id,revenue_item_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `invoice_id` | `UNIQUEIDENTIFIER` | NO | `—` | fin.invoices(tenant_id,id) via (tenant_id,invoice_id) | Confidential finance |
| `revenue_item_id` | `UNIQUEIDENTIFIER` | YES | `—` | fin.revenue_items(tenant_id,id) via (tenant_id,revenue_item_id) | Confidential finance |
| `description` | `NVARCHAR(500)` | NO | `—` | — | Confidential finance |
| `quantity` | `DECIMAL(14,3)` | NO | `—` | — | Confidential finance |
| `unit_price` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.payments`
Payments · P1 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); crm.customers(tenant_id,id) via (tenant_id,customer_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `customer_id` | `UNIQUEIDENTIFIER` | NO | `—` | crm.customers(tenant_id,id) via (tenant_id,customer_id) | Confidential finance |
| `payment_reference` | `NVARCHAR(100)` | NO | `—` | — | Confidential finance |
| `amount` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential finance |
| `received_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.payment_allocations`
Payment allocations · P1 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fin.payments(tenant_id,id) via (tenant_id,payment_id); fin.invoices(tenant_id,id) via (tenant_id,invoice_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `payment_id` | `UNIQUEIDENTIFIER` | NO | `—` | fin.payments(tenant_id,id) via (tenant_id,payment_id) | Confidential finance |
| `invoice_id` | `UNIQUEIDENTIFIER` | NO | `—` | fin.invoices(tenant_id,id) via (tenant_id,invoice_id) | Confidential finance |
| `allocated_amount` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.driver_settlements`
Driver settlements · P1 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Confidential finance |
| `period_start` | `DATE` | NO | `—` | — | Confidential finance |
| `period_end` | `DATE` | NO | `—` | — | Confidential finance |
| `settlement_status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.driver_settlement_items`
Driver settlement items · P1 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fin.driver_settlements(tenant_id,id) via (tenant_id,settlement_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `settlement_id` | `UNIQUEIDENTIFIER` | NO | `—` | fin.driver_settlements(tenant_id,id) via (tenant_id,settlement_id) | Confidential finance |
| `trip_id` | `UNIQUEIDENTIFIER` | YES | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Confidential finance |
| `category` | `VARCHAR(30)` | NO | `—` | — | Confidential finance |
| `amount` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.financial_periods`
Financial periods · P1 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `period_start` | `DATE` | NO | `—` | — | Confidential finance |
| `period_end` | `DATE` | NO | `—` | — | Confidential finance |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.financial_adjustments`
Financial adjustments · P1 · scope `A` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fin.expenses(tenant_id,id) via (tenant_id,expense_id); fin.revenue_items(tenant_id,id) via (tenant_id,revenue_item_id); iam.memberships(tenant_id,id) via (tenant_id,approved_by) | Confidential finance |
| `expense_id` | `UNIQUEIDENTIFIER` | YES | `—` | fin.expenses(tenant_id,id) via (tenant_id,expense_id) | Confidential finance |
| `revenue_item_id` | `UNIQUEIDENTIFIER` | YES | `—` | fin.revenue_items(tenant_id,id) via (tenant_id,revenue_item_id) | Confidential finance |
| `adjustment_amount` | `DECIMAL(19,4)` | NO | `—` | — | Confidential finance |
| `reason` | `NVARCHAR(500)` | NO | `—` | — | Confidential finance |
| `approved_by` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,approved_by) | Confidential finance |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.service_expense_links`
Service expense links · P0 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); mnt.service_records(tenant_id,id) via (tenant_id,service_record_id); fin.expenses(tenant_id,id) via (tenant_id,expense_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `service_record_id` | `UNIQUEIDENTIFIER` | NO | `—` | mnt.service_records(tenant_id,id) via (tenant_id,service_record_id) | Confidential finance |
| `expense_id` | `UNIQUEIDENTIFIER` | NO | `—` | fin.expenses(tenant_id,id) via (tenant_id,expense_id) | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `fin.work_order_expense_links`
Work order expense links · P1 · scope `T` · foundation: no.
Classification: Confidential finance. Retention: Applicable accounting, tax and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential finance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); mnt.work_orders(tenant_id,id) via (tenant_id,work_order_id); fin.expenses(tenant_id,id) via (tenant_id,expense_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |
| `work_order_id` | `UNIQUEIDENTIFIER` | NO | `—` | mnt.work_orders(tenant_id,id) via (tenant_id,work_order_id) | Confidential finance |
| `expense_id` | `UNIQUEIDENTIFIER` | NO | `—` | fin.expenses(tenant_id,id) via (tenant_id,expense_id) | Confidential finance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential finance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential finance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential finance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential finance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.compliance_requirements`
Compliance requirements · P0 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `requirement_code` | `VARCHAR(50)` | NO | `—` | — | Restricted compliance |
| `name` | `NVARCHAR(150)` | NO | `—` | — | Restricted compliance |
| `applicability` | `VARCHAR(30)` | NO | `—` | — | Restricted compliance |
| `renewal_interval_days` | `INT` | YES | `—` | — | Restricted compliance |
| `enabled` | `BIT` | NO | `1` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.driver_compliance_records`
Driver compliance records · P0 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); compliance.compliance_requirements(tenant_id,id) via (tenant_id,requirement_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted compliance |
| `requirement_id` | `UNIQUEIDENTIFIER` | NO | `—` | compliance.compliance_requirements(tenant_id,id) via (tenant_id,requirement_id) | Restricted compliance |
| `document_id` | `UNIQUEIDENTIFIER` | YES | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted compliance |
| `verified_at` | `DATETIME2(3)` | YES | `—` | — | Restricted compliance |
| `expires_at` | `DATETIME2(3)` | YES | `—` | — | Restricted compliance |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.asset_compliance_records`
Asset compliance records · P0 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); compliance.compliance_requirements(tenant_id,id) via (tenant_id,requirement_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted compliance |
| `requirement_id` | `UNIQUEIDENTIFIER` | NO | `—` | compliance.compliance_requirements(tenant_id,id) via (tenant_id,requirement_id) | Restricted compliance |
| `document_id` | `UNIQUEIDENTIFIER` | YES | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted compliance |
| `verified_at` | `DATETIME2(3)` | YES | `—` | — | Restricted compliance |
| `expires_at` | `DATETIME2(3)` | YES | `—` | — | Restricted compliance |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.inspection_templates`
Inspection templates · P1 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `inspection_type` | `VARCHAR(30)` | NO | `—` | — | Restricted compliance |
| `version` | `INT` | NO | `—` | — | Restricted compliance |
| `effective_from` | `DATETIME2(3)` | NO | `—` | — | Restricted compliance |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.inspection_template_items`
Inspection template items · P1 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); compliance.inspection_templates(tenant_id,id) via (tenant_id,template_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `template_id` | `UNIQUEIDENTIFIER` | NO | `—` | compliance.inspection_templates(tenant_id,id) via (tenant_id,template_id) | Restricted compliance |
| `component` | `NVARCHAR(100)` | NO | `—` | — | Restricted compliance |
| `question` | `NVARCHAR(500)` | NO | `—` | — | Restricted compliance |
| `sequence_number` | `INT` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.inspections`
Inspections · P1 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); compliance.inspection_templates(tenant_id,id) via (tenant_id,template_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted compliance |
| `driver_id` | `UNIQUEIDENTIFIER` | YES | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted compliance |
| `template_id` | `UNIQUEIDENTIFIER` | NO | `—` | compliance.inspection_templates(tenant_id,id) via (tenant_id,template_id) | Restricted compliance |
| `inspection_at` | `DATETIME2(3)` | NO | `—` | — | Restricted compliance |
| `result` | `VARCHAR(20)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.inspection_items`
Inspection items · P1 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); compliance.inspections(tenant_id,id) via (tenant_id,inspection_id); compliance.inspection_template_items(tenant_id,id) via (tenant_id,template_item_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `inspection_id` | `UNIQUEIDENTIFIER` | NO | `—` | compliance.inspections(tenant_id,id) via (tenant_id,inspection_id) | Restricted compliance |
| `template_item_id` | `UNIQUEIDENTIFIER` | NO | `—` | compliance.inspection_template_items(tenant_id,id) via (tenant_id,template_item_id) | Restricted compliance |
| `result` | `VARCHAR(20)` | NO | `—` | — | Restricted compliance |
| `notes` | `NVARCHAR(1000)` | YES | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.repair_certifications`
Repair certifications · P1 · scope `A` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); mnt.defects(tenant_id,id) via (tenant_id,defect_id); mnt.work_orders(tenant_id,id) via (tenant_id,work_order_id); iam.memberships(tenant_id,id) via (tenant_id,certified_by) | Restricted compliance |
| `defect_id` | `UNIQUEIDENTIFIER` | NO | `—` | mnt.defects(tenant_id,id) via (tenant_id,defect_id) | Restricted compliance |
| `work_order_id` | `UNIQUEIDENTIFIER` | YES | `—` | mnt.work_orders(tenant_id,id) via (tenant_id,work_order_id) | Restricted compliance |
| `certified_by` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,certified_by) | Restricted compliance |
| `certified_at` | `DATETIME2(3)` | NO | `—` | — | Restricted compliance |
| `attestation` | `NVARCHAR(1000)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.hos_records`
Hos records · P1 · scope `A` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); integration.connections(tenant_id,id) via (tenant_id,connection_id) | Restricted compliance |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted compliance |
| `connection_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.connections(tenant_id,id) via (tenant_id,connection_id) | Restricted compliance |
| `duty_status` | `VARCHAR(30)` | NO | `—` | — | Restricted compliance |
| `started_at` | `DATETIME2(3)` | NO | `—` | — | Restricted compliance |
| `ended_at` | `DATETIME2(3)` | YES | `—` | — | Restricted compliance |
| `external_event_id` | `NVARCHAR(150)` | NO | `—` | — | Restricted compliance |
| `source` | `VARCHAR(30)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.hos_balance_snapshots`
Hos balance snapshots · P1 · scope `A` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); integration.connections(tenant_id,id) via (tenant_id,connection_id) | Restricted compliance |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted compliance |
| `connection_id` | `UNIQUEIDENTIFIER` | NO | `—` | integration.connections(tenant_id,id) via (tenant_id,connection_id) | Restricted compliance |
| `drive_remaining` | `INT` | YES | `—` | — | Restricted compliance |
| `duty_remaining` | `INT` | YES | `—` | — | Restricted compliance |
| `cycle_remaining` | `INT` | YES | `—` | — | Restricted compliance |
| `recorded_at` | `DATETIME2(3)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.safety_incidents`
Safety incidents · P1 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `asset_id` | `UNIQUEIDENTIFIER` | YES | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted compliance |
| `driver_id` | `UNIQUEIDENTIFIER` | YES | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted compliance |
| `incident_type` | `VARCHAR(40)` | NO | `—` | — | Restricted compliance |
| `occurred_at` | `DATETIME2(3)` | NO | `—` | — | Restricted compliance |
| `severity` | `VARCHAR(20)` | NO | `—` | — | Restricted compliance |
| `description` | `NVARCHAR(2000)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.jurisdiction_distance_records`
Jurisdiction distance records · P1 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted compliance |
| `trip_id` | `UNIQUEIDENTIFIER` | YES | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Restricted compliance |
| `jurisdiction_id` | `SMALLINT` | NO | `—` | ref.jurisdictions(id) via (jurisdiction_id) | Restricted compliance |
| `distance` | `DECIMAL(14,3)` | NO | `—` | — | Restricted compliance |
| `source` | `VARCHAR(30)` | NO | `—` | — | Restricted compliance |
| `recorded_at` | `DATETIME2(3)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.ifta_reporting_periods`
Ifta reporting periods · P1 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `year` | `SMALLINT` | NO | `—` | — | Restricted compliance |
| `quarter` | `SMALLINT` | NO | `—` | — | Restricted compliance |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `compliance.ifta_report_lines`
Ifta report lines · P1 · scope `T` · foundation: no.
Classification: Restricted compliance. Retention: Applicable statutory and contractual retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted compliance |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); compliance.ifta_reporting_periods(tenant_id,id) via (tenant_id,period_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |
| `period_id` | `UNIQUEIDENTIFIER` | NO | `—` | compliance.ifta_reporting_periods(tenant_id,id) via (tenant_id,period_id) | Restricted compliance |
| `jurisdiction_id` | `SMALLINT` | NO | `—` | ref.jurisdictions(id) via (jurisdiction_id) | Restricted compliance |
| `total_miles` | `DECIMAL(14,3)` | NO | `—` | — | Restricted compliance |
| `qualifying_gallons` | `DECIMAL(14,3)` | NO | `—` | — | Restricted compliance |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted compliance |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted compliance |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted compliance |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted compliance |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.documents`
Documents · P0 · scope `T` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |
| `document_type_id` | `SMALLINT` | NO | `—` | ref.document_types(id) via (document_type_id) | Restricted documents |
| `title` | `NVARCHAR(200)` | NO | `—` | — | Restricted documents |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted documents |
| `issued_at` | `DATETIME2(3)` | YES | `—` | — | Restricted documents |
| `expires_at` | `DATETIME2(3)` | YES | `—` | — | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted documents |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted documents |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.document_versions`
Document versions · P0 · scope `T` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted documents |
| `version_number` | `INT` | NO | `—` | — | Restricted documents |
| `object_key` | `NVARCHAR(500)` | NO | `—` | — | Restricted |
| `content_type` | `VARCHAR(100)` | NO | `—` | — | Restricted documents |
| `checksum` | `BINARY(32)` | NO | `—` | — | Restricted documents |
| `file_size` | `BIGINT` | NO | `—` | — | Restricted documents |
| `scan_status` | `VARCHAR(20)` | NO | `—` | — | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted documents |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted documents |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.asset_documents`
Asset documents · P0 · scope `T` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fleet.assets(tenant_id,id) via (tenant_id,asset_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | `—` | fleet.assets(tenant_id,id) via (tenant_id,asset_id) | Restricted documents |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted documents |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted documents |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.driver_documents`
Driver documents · P0 · scope `T` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); hr.drivers(tenant_id,id) via (tenant_id,driver_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |
| `driver_id` | `UNIQUEIDENTIFIER` | NO | `—` | hr.drivers(tenant_id,id) via (tenant_id,driver_id) | Restricted documents |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted documents |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted documents |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.load_documents`
Load documents · P0 · scope `T` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.loads(tenant_id,id) via (tenant_id,load_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |
| `load_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.loads(tenant_id,id) via (tenant_id,load_id) | Restricted documents |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted documents |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted documents |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.trip_documents`
Trip documents · P0 · scope `T` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.trips(tenant_id,id) via (tenant_id,trip_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |
| `trip_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.trips(tenant_id,id) via (tenant_id,trip_id) | Restricted documents |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted documents |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted documents |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.delivery_documents`
Delivery documents · P0 · scope `T` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ops.delivery_confirmations(tenant_id,id) via (tenant_id,delivery_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by); docs.document_versions(tenant_id,document_id,version_number) via (tenant_id,document_id,version_number) | Restricted documents |
| `delivery_id` | `UNIQUEIDENTIFIER` | NO | `—` | ops.delivery_confirmations(tenant_id,id) via (tenant_id,delivery_id) | Restricted documents |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id); docs.document_versions(tenant_id,document_id,version_number) via (tenant_id,document_id,version_number) | Restricted documents |
| `version_number` | `INT` | NO | `—` | docs.document_versions(tenant_id,document_id,version_number) via (tenant_id,document_id,version_number) | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted documents |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted documents |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.inspection_documents`
Inspection documents · P1 · scope `T` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); compliance.inspections(tenant_id,id) via (tenant_id,inspection_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |
| `inspection_id` | `UNIQUEIDENTIFIER` | NO | `—` | compliance.inspections(tenant_id,id) via (tenant_id,inspection_id) | Restricted documents |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted documents |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted documents |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.expense_documents`
Expense documents · P0 · scope `T` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); fin.expenses(tenant_id,id) via (tenant_id,expense_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |
| `expense_id` | `UNIQUEIDENTIFIER` | NO | `—` | fin.expenses(tenant_id,id) via (tenant_id,expense_id) | Restricted documents |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted documents |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted documents |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.work_order_documents`
Work order documents · P1 · scope `T` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); mnt.work_orders(tenant_id,id) via (tenant_id,work_order_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |
| `work_order_id` | `UNIQUEIDENTIFIER` | NO | `—` | mnt.work_orders(tenant_id,id) via (tenant_id,work_order_id) | Restricted documents |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted documents |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted documents |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `docs.document_verifications`
Document verifications · P0 · scope `A` · foundation: no.
Classification: Restricted documents. Retention: Inherit linked record and legal-hold retention. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted documents |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,verified_by); docs.document_versions(tenant_id,document_id,version_number) via (tenant_id,document_id,version_number) | Restricted documents |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id); docs.document_versions(tenant_id,document_id,version_number) via (tenant_id,document_id,version_number) | Restricted documents |
| `version_number` | `INT` | NO | `—` | docs.document_versions(tenant_id,document_id,version_number) via (tenant_id,document_id,version_number) | Restricted documents |
| `verified_by` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,verified_by) | Restricted documents |
| `verified_at` | `DATETIME2(3)` | NO | `—` | — | Restricted documents |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted documents |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted documents |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `notify.alert_rules`
Alert rules · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `rule_type` | `VARCHAR(50)` | NO | `—` | — | Confidential operations |
| `severity` | `VARCHAR(15)` | NO | `—` | — | Confidential operations |
| `threshold` | `DECIMAL(14,3)` | YES | `—` | — | Confidential operations |
| `enabled` | `BIT` | NO | `1` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `notify.alerts`
Alerts · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); notify.alert_rules(tenant_id,id) via (tenant_id,rule_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `rule_id` | `UNIQUEIDENTIFIER` | YES | `—` | notify.alert_rules(tenant_id,id) via (tenant_id,rule_id) | Confidential operations |
| `source_domain` | `VARCHAR(50)` | NO | `—` | — | Confidential operations |
| `source_reference` | `NVARCHAR(150)` | NO | `—` | — | Confidential operations |
| `severity` | `VARCHAR(15)` | NO | `—` | — | Confidential operations |
| `title` | `NVARCHAR(200)` | NO | `—` | — | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `resolved_at` | `DATETIME2(3)` | YES | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `notify.alert_assignments`
Alert assignments · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); notify.alerts(tenant_id,id) via (tenant_id,alert_id); iam.memberships(tenant_id,id) via (tenant_id,membership_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `alert_id` | `UNIQUEIDENTIFIER` | NO | `—` | notify.alerts(tenant_id,id) via (tenant_id,alert_id) | Confidential operations |
| `membership_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,membership_id) | Confidential operations |
| `assigned_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `notify.alert_acknowledgments`
Alert acknowledgments · P0 · scope `A` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); notify.alerts(tenant_id,id) via (tenant_id,alert_id); iam.memberships(tenant_id,id) via (tenant_id,membership_id) | Confidential operations |
| `alert_id` | `UNIQUEIDENTIFIER` | NO | `—` | notify.alerts(tenant_id,id) via (tenant_id,alert_id) | Confidential operations |
| `membership_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,membership_id) | Confidential operations |
| `acknowledged_at` | `DATETIME2(3)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `notify.notifications`
Notifications · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,recipient_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `recipient_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,recipient_id) | Confidential operations |
| `channel` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `message` | `NVARCHAR(2000)` | NO | `—` | — | Confidential operations |
| `delivery_status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `notify.notification_preferences`
Notification preferences · P0 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,membership_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `membership_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,membership_id) | Confidential operations |
| `event_type` | `VARCHAR(50)` | NO | `—` | — | Confidential operations |
| `channel` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `enabled` | `BIT` | NO | `1` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `notify.notification_delivery_attempts`
Notification delivery attempts · P0 · scope `A` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); notify.notifications(tenant_id,id) via (tenant_id,notification_id) | Confidential operations |
| `notification_id` | `UNIQUEIDENTIFIER` | NO | `—` | notify.notifications(tenant_id,id) via (tenant_id,notification_id) | Confidential operations |
| `provider_reference` | `NVARCHAR(150)` | YES | `—` | — | Confidential operations |
| `attempt_number` | `INT` | NO | `—` | — | Confidential operations |
| `status` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `attempted_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `notify.notification_templates`
Notification templates · P1 · scope `T` · foundation: no.
Classification: Confidential operations. Retention: Business lifecycle + approved archival / legal-hold period. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Confidential operations |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |
| `template_code` | `VARCHAR(50)` | NO | `—` | — | Confidential operations |
| `channel` | `VARCHAR(20)` | NO | `—` | — | Confidential operations |
| `subject` | `NVARCHAR(200)` | YES | `—` | — | Confidential operations |
| `template_body` | `NVARCHAR(MAX)` | NO | `—` | — | Confidential operations |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Confidential operations |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Confidential operations |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Confidential operations |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Confidential operations |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.conversations`
Conversations · P0B · scope `T` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,membership_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted AI content |
| `membership_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,membership_id) | Restricted AI content |
| `title` | `NVARCHAR(200)` | YES | `—` | — | Restricted AI content |
| `context_type` | `VARCHAR(50)` | YES | `—` | — | Restricted AI content |
| `context_reference` | `UNIQUEIDENTIFIER` | YES | `—` | — | Restricted AI content |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted AI content |
| `last_activity_at` | `DATETIME2(3)` | NO | `—` | — | Restricted AI content |
| `archived_at` | `DATETIME2(3)` | YES | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted AI content |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted AI content |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.messages`
Messages · P0B · scope `T` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ai.conversations(tenant_id,id) via (tenant_id,conversation_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted AI content |
| `conversation_id` | `UNIQUEIDENTIFIER` | NO | `—` | ai.conversations(tenant_id,id) via (tenant_id,conversation_id) | Restricted AI content |
| `role` | `VARCHAR(20)` | NO | `—` | — | Restricted AI content |
| `content` | `NVARCHAR(MAX)` | NO | `—` | — | Restricted |
| `sequence_number` | `INT` | NO | `—` | — | Restricted AI content |
| `model_identifier` | `NVARCHAR(100)` | YES | `—` | — | Restricted AI content |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted AI content |
| `completed_at` | `DATETIME2(3)` | YES | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted AI content |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted AI content |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.model_configurations`
Model configurations · P0B · scope `G` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `provider` | `VARCHAR(30)` | NO | `—` | — | Restricted AI content |
| `model_identifier` | `NVARCHAR(100)` | NO | `—` | — | Restricted AI content |
| `enabled` | `BIT` | NO | `1` | — | Restricted AI content |
| `temperature` | `DECIMAL(14,3)` | YES | `—` | — | Restricted AI content |
| `token_limit` | `INT` | NO | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.tool_definitions`
Tool definitions · P0B · scope `G` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `tool_code` | `VARCHAR(80)` | NO | `—` | — | Restricted AI content |
| `description` | `NVARCHAR(500)` | NO | `—` | — | Restricted AI content |
| `required_permission_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.permissions(id) via (required_permission_id) | Restricted AI content |
| `enabled` | `BIT` | NO | `1` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.tool_invocations`
Tool invocations · P0B · scope `A` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ai.messages(tenant_id,id) via (tenant_id,message_id) | Restricted AI content |
| `message_id` | `UNIQUEIDENTIFIER` | NO | `—` | ai.messages(tenant_id,id) via (tenant_id,message_id) | Restricted AI content |
| `tool_id` | `UNIQUEIDENTIFIER` | NO | `—` | ai.tool_definitions(id) via (tool_id) | Restricted AI content |
| `request_metadata` | `NVARCHAR(MAX)` | YES | `—` | — | Restricted AI content |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted AI content |
| `duration_ms` | `INT` | YES | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.response_sources`
Response sources · P0B · scope `A` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ai.messages(tenant_id,id) via (tenant_id,message_id); ai.tool_invocations(tenant_id,id) via (tenant_id,tool_invocation_id) | Restricted AI content |
| `message_id` | `UNIQUEIDENTIFIER` | NO | `—` | ai.messages(tenant_id,id) via (tenant_id,message_id) | Restricted AI content |
| `tool_invocation_id` | `UNIQUEIDENTIFIER` | NO | `—` | ai.tool_invocations(tenant_id,id) via (tenant_id,tool_invocation_id) | Restricted AI content |
| `resource_type` | `VARCHAR(50)` | NO | `—` | — | Restricted AI content |
| `resource_id` | `NVARCHAR(100)` | NO | `—` | — | Restricted AI content |
| `source_timestamp` | `DATETIME2(3)` | YES | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.response_feedback`
Response feedback · P0B · scope `T` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ai.messages(tenant_id,id) via (tenant_id,message_id); iam.memberships(tenant_id,id) via (tenant_id,membership_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted AI content |
| `message_id` | `UNIQUEIDENTIFIER` | NO | `—` | ai.messages(tenant_id,id) via (tenant_id,message_id) | Restricted AI content |
| `membership_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,membership_id) | Restricted AI content |
| `rating` | `SMALLINT` | NO | `—` | — | Restricted AI content |
| `feedback_category` | `VARCHAR(50)` | YES | `—` | — | Restricted AI content |
| `comments` | `NVARCHAR(1000)` | YES | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted AI content |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted AI content |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.usage_records`
Usage records · P0B · scope `A` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); ai.messages(tenant_id,id) via (tenant_id,message_id) | Restricted AI content |
| `message_id` | `UNIQUEIDENTIFIER` | YES | `—` | ai.messages(tenant_id,id) via (tenant_id,message_id) | Restricted AI content |
| `model_identifier` | `NVARCHAR(100)` | NO | `—` | — | Restricted AI content |
| `input_tokens` | `INT` | NO | `—` | — | Restricted AI content |
| `output_tokens` | `INT` | NO | `—` | — | Restricted AI content |
| `estimated_cost` | `DECIMAL(19,4)` | YES | `—` | — | Restricted AI content |
| `currency_code` | `CHAR(3)` | NO | `—` | ref.currencies(code) via (currency_code) | Restricted AI content |
| `latency_ms` | `INT` | NO | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.tenant_ai_settings`
Tenant ai settings · P0B · scope `T` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted AI content |
| `enabled` | `BIT` | NO | `1` | — | Restricted AI content |
| `usage_limit` | `INT` | NO | `—` | — | Restricted AI content |
| `retention_days` | `INT` | NO | `—` | — | Restricted AI content |
| `model_configuration_id` | `UNIQUEIDENTIFIER` | NO | `—` | ai.model_configurations(id) via (model_configuration_id) | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted AI content |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted AI content |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.prompt_templates`
Prompt templates · P1 · scope `G` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `template_code` | `VARCHAR(50)` | NO | `—` | — | Restricted AI content |
| `version` | `INT` | NO | `—` | — | Restricted AI content |
| `template_content` | `NVARCHAR(MAX)` | NO | `—` | — | Restricted AI content |
| `status` | `VARCHAR(20)` | NO | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.evaluation_cases`
Evaluation cases · P0B · scope `G` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `question` | `NVARCHAR(1000)` | NO | `—` | — | Restricted AI content |
| `expected_behavior` | `NVARCHAR(2000)` | NO | `—` | — | Restricted AI content |
| `evaluation_category` | `VARCHAR(50)` | NO | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.evaluation_runs`
Evaluation runs · P0B · scope `G` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `case_id` | `UNIQUEIDENTIFIER` | NO | `—` | ai.evaluation_cases(id) via (case_id) | Restricted AI content |
| `model_identifier` | `NVARCHAR(100)` | NO | `—` | — | Restricted AI content |
| `evaluated_at` | `DATETIME2(3)` | NO | `—` | — | Restricted AI content |
| `result` | `VARCHAR(20)` | NO | `—` | — | Restricted AI content |
| `evaluation_version` | `VARCHAR(30)` | NO | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `ai.knowledge_documents`
Knowledge documents · P2 · scope `T` · foundation: no.
Classification: Restricted AI content. Retention: 90-day chat / 12-month usage proposal; legal holds override. Audit: audit significant lifecycle and permission changes; never log raw restricted payloads.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | PK;  | Restricted AI content |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); docs.documents(tenant_id,id) via (tenant_id,document_id); iam.memberships(tenant_id,id) via (tenant_id,created_by); iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted AI content |
| `document_id` | `UNIQUEIDENTIFIER` | NO | `—` | docs.documents(tenant_id,id) via (tenant_id,document_id) | Restricted AI content |
| `indexing_status` | `VARCHAR(20)` | NO | `—` | — | Restricted AI content |
| `access_scope` | `VARCHAR(30)` | NO | `—` | — | Restricted AI content |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted AI content |
| `row_version` | `ROWVERSION` | NO | `engine-generated` | — | Restricted AI content |
| `created_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,created_by) | Restricted AI content |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | `—` | iam.memberships(tenant_id,id) via (tenant_id,updated_by) | Restricted AI content |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `audit.audit_events`
Audit events · P0 · scope `H` · foundation: yes.
Classification: Restricted audit. Retention: 1–3 years proposal; legal holds override. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `BIGINT` | NO | `IDENTITY(1,1)` | PK;  | Restricted audit |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id) | Restricted audit |
| `actor_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.users(id) via (actor_id) | Restricted audit |
| `actor_type` | `VARCHAR(20)` | NO | `—` | — | Restricted audit |
| `action` | `VARCHAR(50)` | NO | `—` | — | Restricted audit |
| `entity_type` | `VARCHAR(100)` | NO | `—` | — | Restricted audit |
| `entity_id` | `NVARCHAR(100)` | YES | `—` | — | Restricted audit |
| `old_values` | `NVARCHAR(MAX)` | YES | `—` | — | Restricted |
| `new_values` | `NVARCHAR(MAX)` | YES | `—` | — | Restricted |
| `correlation_id` | `UNIQUEIDENTIFIER` | NO | `—` | — | Restricted audit |
| `occurred_at` | `DATETIME2(3)` | NO | `—` | — | Restricted audit |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted audit |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `audit.security_events`
Security events · P0 · scope `H` · foundation: no.
Classification: Restricted audit. Retention: 1–3 years proposal; legal holds override. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `BIGINT` | NO | `IDENTITY(1,1)` | PK;  | Restricted audit |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id) | Restricted audit |
| `user_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.users(id) via (user_id) | Restricted audit |
| `event_type` | `VARCHAR(50)` | NO | `—` | — | Restricted audit |
| `result` | `VARCHAR(20)` | NO | `—` | — | Restricted audit |
| `correlation_id` | `UNIQUEIDENTIFIER` | NO | `—` | — | Restricted audit |
| `occurred_at` | `DATETIME2(3)` | NO | `—` | — | Restricted audit |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted audit |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `audit.data_access_events`
Data access events · P1 · scope `H` · foundation: no.
Classification: Restricted audit. Retention: 1–3 years proposal; legal holds override. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `BIGINT` | NO | `IDENTITY(1,1)` | PK;  | Restricted audit |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id) | Restricted audit |
| `actor_id` | `UNIQUEIDENTIFIER` | YES | `—` | iam.users(id) via (actor_id) | Restricted audit |
| `resource_type` | `VARCHAR(50)` | NO | `—` | — | Restricted audit |
| `resource_id` | `NVARCHAR(100)` | NO | `—` | — | Restricted audit |
| `access_reason` | `NVARCHAR(200)` | NO | `—` | — | Restricted audit |
| `occurred_at` | `DATETIME2(3)` | NO | `—` | — | Restricted audit |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted audit |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `audit.export_events`
Export events · P0 · scope `H` · foundation: no.
Classification: Restricted audit. Retention: 1–3 years proposal; legal holds override. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `BIGINT` | NO | `IDENTITY(1,1)` | PK;  | Restricted audit |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id) | Restricted audit |
| `user_id` | `UNIQUEIDENTIFIER` | NO | `—` | iam.users(id) via (user_id) | Restricted audit |
| `report_type` | `VARCHAR(50)` | NO | `—` | — | Restricted audit |
| `filter_metadata` | `NVARCHAR(MAX)` | YES | `—` | — | Restricted audit |
| `exported_at` | `DATETIME2(3)` | NO | `—` | — | Restricted audit |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted audit |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

## `audit.approval_events`
Approval events · P0 · scope `H` · foundation: no.
Classification: Restricted audit. Retention: 1–3 years proposal; legal holds override. Audit: append-only; controlled retention.

| Column | SQL Server type | NULL | Default / generation | Key / FK | Classification |
|---|---|---|---|---|---|
| `id` | `BIGINT` | NO | `IDENTITY(1,1)` | PK;  | Restricted audit |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | `—` | core.tenants(id) via (tenant_id); iam.memberships(tenant_id,id) via (tenant_id,approved_by) | Restricted audit |
| `entity_type` | `VARCHAR(50)` | NO | `—` | — | Restricted audit |
| `entity_id` | `NVARCHAR(100)` | NO | `—` | — | Restricted audit |
| `decision` | `VARCHAR(20)` | NO | `—` | — | Restricted audit |
| `approved_by` | `UNIQUEIDENTIFIER` | NO | `—` | iam.memberships(tenant_id,id) via (tenant_id,approved_by) | Restricted audit |
| `occurred_at` | `DATETIME2(3)` | NO | `—` | — | Restricted audit |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | Restricted audit |

See [constraints and indexes](constraints-and-indexes.md) for table-specific keys, checks and indexes.

