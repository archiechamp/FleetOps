# Feature 001 Data Model — Foundation and Approved Retry Addition

**Date**: 2026-11-23
**Status**: Revised review draft; B-001/B-002 resolved by the user's 2026-11-23 planning direction.
**Source**: [model.json](../../database/metadata/model.json), the 17 foundation=true tables
plus the explicitly authorized existing proposal integration.idempotency_keys.
**Scope**: 18 domain tables, 166 columns, 42 foreign keys. The original 17 tables are unchanged;
the sole addition has 12 columns and 3 FKs, all targeting the existing foundation.
Alembic's version table is separate migration bookkeeping. No application migration is executed.

The inventory below preserves the metadata column order, SQL types, nullability, defaults,
identity generation, primary/unique keys, checks, foreign keys and secondary indexes. Constraint
names follow the reference DDL convention. All foreign-key targets are within this subset.
No cascading delete/update action is introduced. Exact types are physical design, not a claim
that migrations have run. [Research](research.md) records the resolved decisions and evidence gates.

## Entities and Relationships

| Entity | Role in this feature | Scope | Columns | Foreign keys |
| --- | --- | --- | --- | --- |
| `core.tenants` | Carrier identity, active status, timezone and default currency | G | 12 | 1 |
| `core.tenant_settings` | Existing foundation configuration; no registration retry payloads | T | 9 | 3 |
| `core.terminals` | Existing carrier locations; optional asset reference remains null on creation | T | 12 | 3 |
| `ref.countries` | Governed country catalog | R | 4 | 0 |
| `ref.jurisdictions` | Country-qualified jurisdiction catalog | R | 5 | 1 |
| `ref.currencies` | Governed currency catalog; USD for this U.S. slice | R | 3 | 0 |
| `ref.asset_types` | Resolve TRACTOR by code | R | 4 | 0 |
| `ref.fuel_types` | Existing governed catalog; optional vehicle fuel remains null | R | 4 | 0 |
| `iam.users` | External identity mapping and active/disabled user status | G | 9 | 0 |
| `iam.memberships` | Active carrier membership and creator provenance | T | 10 | 4 |
| `iam.roles` | Carrier-specific roles; role names never confer capabilities | T | 11 | 3 |
| `iam.permissions` | fleet.vehicle.read and fleet.vehicle.create capability catalog | G | 7 | 0 |
| `iam.membership_roles` | Carrier-safe role assignment | T | 9 | 5 |
| `iam.role_permissions` | Effective role capabilities in the carrier | T | 9 | 5 |
| `fleet.assets` | Truck identifying fields and lifecycle status | T | 20 | 6 |
| `fleet.vehicles` | One truck subtype per carrier/asset; vehicle ID is the API resource ID | T | 14 | 6 |
| `audit.audit_events` | Append-only registration provenance; not a replay store | H | 12 | 2 |
| `integration.idempotency_keys` | Approved durable registration key/hash/result reference | T | 12 | 3 |

Scopes: G = globally restricted identity/configuration; R = governed reference;
T = mutable tenant-owned; H = append-only high-volume tenant-owned.
Scope G on core.tenants does not grant callers visibility into other carriers.

## Validation and Service Rules

- FR-004 maps unit_number/make/model/model_year/ownership_type to fleet.assets. The server derives
  tenant_id, membership actor fields, asset_type_id from TRACTOR, and currency_code from the verified
  carrier (USD in this slice). No client status, price, identity, tenant or audit fields are accepted.
- Unit numbers trim outer whitespace, preserve display case and compare case-insensitively.
  Proposed new-database collation is Latin1_General_100_CI_AS_SC, selected explicitly at bootstrap;
  never alter an existing database's collation as setup. Database uniqueness and parameterized
  equality search must use that same collation. Test accents, trailing/interior spaces and case;
  no application-only lowercase lookup is sufficient for concurrent uniqueness.
- FR-004 now defines unit_number as 1–30 UTF-16 code units and make/model as 1–80 each,
  after the identical outer-whitespace trim defined in [the contract](contracts/README.md#unicode-and-length-contract).
  A supplementary character consumes two units. Preserve valid Unicode; reject unpaired
  surrogates and over-capacity input with 422; never truncate or widen the columns.
  Browser counting and API validation must match SQL NVARCHAR capacity, not code-point/grapheme
  counts. Verify DATALENGTH(value)/2, not LEN(value), against the boundary vectors.
- Validation uses strict integer model years 1900–2100; booleans, fractions and numeric strings
  are rejected. Ownership labels map exactly to OWNED/LEASED/CONTRACTED.
- Unspecified nullable fields remain null, not fabricated VIN, plate, acquisition cost or fuel.
  The existing AVAILABLE default is retained as a lifecycle storage value; this feature neither
  exposes dispatch eligibility nor assigns equipment.
- SQL defaults generate IDs/timestamps/rowversion. Service writes current membership into both
  asset/vehicle created_by and updated_by, maintains updated_at on any future approved update,
  and reads generated values before committing the response. SQL DATETIME2 values represent UTC;
  API serialization attaches UTC Z, not the Windows workstation timezone.
- The asset ID and vehicle ID are distinct. Join on both tenant_id and asset_id; never use an
  audit entity pointer as ownership proof. Monetary/measurement fields retain their declared
  DECIMAL types, even though this feature leaves them null.

## Transaction and Provenance

FR-007/008, DBR-003/011/032: one SQL Server transaction commits fleet.assets, fleet.vehicles,
one audit.audit_events row and one integration.idempotency_keys row, or none. No durable
pending reservation, separate retry-store commit, background completion or in-memory substitute.

### Durable Submission Identity and Original Result

- Derive tenant_id and membership from current verified authorization, never body claims.
  operation_scope is the ASCII string `vehicle.register:v1:<lowercase membership UUID>`
  (56 characters, within VARCHAR(80)). request_key is the parsed Idempotency-Key UUID serialized
  as 36 lowercase hyphenated characters, within NVARCHAR(150).
- Normalize/validate the five submitted fields under the shared Unicode contract. Compute SHA-256
  over UTF-8 bytes of the compact JSON array
  `[1,unit_number,make,model,model_year,ownership_type]`: fixed order, no whitespace between
  tokens, unescaped valid Unicode (normal JSON escaping for quotes/backslashes/control characters),
  integer year and uppercase ownership enum. Store the 32 digest bytes in BINARY(32), not hex.
  No case folding or Unicode normalization enters this hash. Equivalent JSON formatting, UUID
  casing and trimmed outer whitespace do not change identity; changed display case or any other
  normalized field does. Invalid input is 422 before lookup; a valid changed payload is 409.
- Use the existing unique key (tenant_id, operation_scope, request_key). Membership is part of
  operation_scope and both created_by/updated_by are set to that verified membership on insert.
  This gives tenant + operation + actor + key scope without adding an actor column or changing
  the kit's key definitions.
- Store `fleet.vehicles:<lowercase vehicle UUID>` (51 UTF-16 units) in response_reference.
  It is a typed internal record reference, not a URL, serialized response or authorization proof.
  No FK is invented for this polymorphic column: the transaction and scoped lookup enforce the
  link. Read the referenced vehicle with tenant_id and created_by matching the current context.
- The original v1 response is deliberately reconstructible: its five identifying fields come
  from the hash-verified canonical retry payload; id comes from the reference; tenant_id from
  verified scope; created_at from the vehicle's immutable SQL-generated creation timestamp.
  First success uses the same projection and timestamp formatted as UTC with exactly three
  fractional digits and Z. Replay returns the same 201 JSON values and Location, not a new
  timestamp or a GET of possibly changed identifying fields. Per-request tracing headers may
  differ. No full payload/response snapshot is stored in audit or the retry table.
- Preserve vehicle ID, tenant, creator and created_at for the lifetime of the replay record.
  Feature 001 grants no updates/deletes. A future edit/delete/response-expansion feature must
  preserve this v1 reconstruction or separately review immutable response storage before
  changing those invariants. A missing/malformed reference, mismatched creator or unavailable
  result is a sanitized SERVICE_UNAVAILABLE (503), with an integrity alert and no new create.
- FR-008 has no agreed expiry window. For this feature set expires_at explicitly to
  `9999-12-31T23:59:59.999` UTC: retained, non-expiring registration receipts. No purge job,
  key reuse or runtime update/delete is planned. The metadata's “30-day transient payload
  proposal” is not an approved expiry policy and is not applied to these compact receipts.
  Finite retention/deletion needs a later product/security decision and an explicit FR-008
  compatibility change; it is not a blocker to this no-purge design.

### Transaction Protocol and Failure Outcomes

1. Verify token/provider session and active membership with read/create capabilities. Do provider
   network checks before starting a transaction. Validate input and derive scope/key/hash.
2. Begin a runtime SQL transaction with a clean, native-UUID tenant context. Serialize this key
   across API processes using a transaction-owned SQL application lock: resource
   `vehicle.register.v1:<tenant UUID>:<membership UUID>:<request UUID>` (130 ASCII characters),
   Exclusive mode, DbPrincipal = the shared runtime database role, LockOwner = Transaction and
   LockTimeout = 5000 ms. Every registration writer uses this exact canonical protocol.
   Lock release follows commit/rollback, not process-local state. Negative return codes,
   timeout, cancellation or deadlock explicitly roll back and return safe 503; never treat them
   as acquired or loop indefinitely. A subsequent request retries the unchanged key/payload.
3. After acquiring the lock, recheck current internal membership/capabilities before result access,
   and query the exact tenant/operation/key under normal committed reads (no NOLOCK or stale
   transaction snapshot). If present, compare hash first: mismatch returns IDEMPOTENCY_CONFLICT
   (409) without changing any row. If equal, authorize the referenced record, reconstruct the
   original result as above, finish the read transaction and return it. No insert or audit occurs.
4. If absent, insert the asset, vehicle and success audit; obtain SQL-generated IDs and the
   vehicle creation time. Insert the complete retry row with nonnull response_reference, hash,
   scope, expiry sentinel and verified actor fields. Keep the reference column nullable in the
   physical model, but never commit a null reference for this operation. No update grant needed.
5. Commit once, then send 201 and Location. Any failure after any insert or before commit rolls
   back all four rows. A crash before commit leaves none; a crash/lost connection after commit
   leaves all four and an authorized restart retry replays. Ambiguous commit outcome is never
   “repaired” by creating with a new key.
6. The original tenant/unit unique constraint remains final protection for different-key races:
   one complete registration succeeds and the losing transaction rolls back its audit/retry rows
   before returning VEHICLE_UNIT_CONFLICT (409). The retry UQ remains a second safety net. An
   unexpected retry-UQ violation must roll back and resolve via a fresh authorized locked lookup,
   never blindly rerun inserts or return an unrelated unit conflict.

The SQL lock only coordinates concurrent work; the committed table is the restart-proof ledger.
This plan uses a bounded transaction-owned lock per the documented
[SQL application-lock contract](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-getapplock-transact-sql).
IT-07 must prove this protocol under separate connections/processes with runtime privileges.

The audit actor_id references iam.users, not iam.memberships. Use the verified internal user ID;
record action vehicle.registered, entity_type fleet.vehicles, the vehicle ID and request correlation
ID. A small new_values JSON contains membership and asset/vehicle IDs, not credentials, complete
request payloads or response snapshots. Runtime may insert but never update/delete audit rows.

## Migration and Bootstrap Order

1. After review, create only the five used schemas (core, ref, iam, fleet, audit) and all 17
   tables with their exact PK/UQ/check/default/index definitions through Alembic.
2. Add foreign keys after all tables exist: membership actor links include self/cyclic references,
   so a table-by-table naive insertion order is insufficient. Keep dependencies enabled.
3. Seed governed USD/US/jurisdiction/TRACTOR/fuel catalogs and capability codes using stable natural
   keys; synthetic carriers/users are development/test setup only. Explicitly distinguish
   provider identity bootstrap from fixture identities (TEST_FIXTURE subjects are not logins).
4. Review and migrate narrowly scoped identity-bootstrap procedures, RLS predicate/policy and
   grants over the original foundation. Add only the integration schema and idempotency_keys
   contract below in a separate revision, after its core.tenants/iam.memberships FK targets and
   existing RLS function/runtime role are available. No other integration or G03 table is pulled in.
5. Fresh tests apply revisions to an empty application database. Reference rehearsal uses a
   different fresh database with verify-foundation.sql. Never apply reference DDL and Alembic to
   the same database. Compare migration results to this inventory and original metadata.
6. Proposed revisions: 0001_foundation (original 17 tables/constraints);
   0002_foundation_security (bootstrap/RLS/grants); 0003_vehicle_registration_idempotency
   (integration schema, sole added table with exact constraints, five RLS predicates and
   scoped grants). Head contains 18 tables/166 columns/42 FKs, excluding Alembic bookkeeping.
   Test base→head, 0001→head and populated 0002→0003; no prior released app is claimed.
   Existing trucks remain unchanged; do not invent retry keys/results for historical rows.
7. Backout is a reviewed local-only disposable-database exercise. Production rollout would need
   backup/PITR, schema/image compatibility and an approved recovery/forward-fix plan. A failed
   security migration keeps readiness false. No request/startup migrations or blind data loss.
   Reverting 0003 is allowed only in a disposable empty test DB: revoke added grants/remove its
   policy predicates before dropping the table/schema. In a populated environment retain the
   ledger and compatible v1 replay code; dropping it loses guarantees. Production recovery or
   roll-forward is separately reviewed. Readiness requires 0003 and all new security objects.

## Authorization, RLS and Grants

Use a restricted bootstrap connection that can execute only a fixed identity/membership query
procedure. Its parameters are provider/subject from verified credentials and an optional selected
tenant; it returns only that user's active memberships and capabilities. It has no general table
read or write grant. To break the RLS/bootstrap cycle, a reviewed security-definer execution
principal without login may read membership rows inside that bounded procedure. The predicate
must explicitly account for this principal; EXECUTE AS or module signing alone must not be
assumed to bypass RLS. Runtime cannot impersonate it or alter the procedure/predicate.

The separate runtime principal reads authorized assets/vehicles and needed reference values,
inserts assets/vehicles/audit rows, and has SELECT/INSERT only on integration.idempotency_keys.
It is a member of the shared runtime role used for transaction-owned application locks; it does
not gain dbo, general integration-schema access, or UPDATE/DELETE on retry/audit/fleet rows.
It cannot alter schemas/policies. Current carrier/user data comes from the bounded bootstrap result. Seed and
migration credentials never serve application requests. Test-inspection credentials are separate
and never injected into the web/API runtime.

The nine tenant-owned foundation tables receive filter/block predicates after the pool spike:
core.tenant_settings, core.terminals, iam.memberships, iam.roles, iam.membership_roles,
iam.role_permissions, fleet.assets, fleet.vehicles, audit.audit_events. Keep the reference's 45
predicates and add five on integration.idempotency_keys: FILTER plus BLOCK AFTER INSERT,
AFTER UPDATE, BEFORE UPDATE and BEFORE DELETE. The application set has ten tenant tables and
50 predicates; test missing/wrong context for the new ledger as well as fleet. Global iam.users/core.tenants/iam.permissions
need explicit privilege boundaries; they are not protected by this tenant policy.

Set tenant context using a native SQL UNIQUEIDENTIFIER parameter; no context denies rows.
Clear context before binding and on checkout/check-in/error; rollback first where necessary,
clear with a verified statement and invalidate the connection on failed reset. Do not set
read_only=1 on reusable pooled connections. Disable pyodbc's separate pooling before connection
creation so SQLAlchemy owns lifecycle. Test A→B→none→A, revoked membership, failed cleanup and
runtime-principal constraints. RLS and context are defense in depth, not proof against a compromised
application principal or replacement for service checks.

## Exact Application Schema Contract

### core.tenants

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `name` | `NVARCHAR(200)` | NO | — | — | — |
| `legal_name` | `NVARCHAR(200)` | YES | — | — | — |
| `slug` | `VARCHAR(100)` | NO | — | — | — |
| `status` | `VARCHAR(20)` | NO | `'ACTIVE'` | — | — |
| `dot_number` | `VARCHAR(20)` | YES | — | — | — |
| `mc_number` | `VARCHAR(20)` | YES | — | — | — |
| `timezone` | `NVARCHAR(64)` | NO | — | — | — |
| `currency_code` | `CHAR(3)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |

- `PK_core_tenants`: PRIMARY KEY (`id`).
- `UQ_core_tenants_1`: UNIQUE (`slug`).
- `CK_core_tenants_1`: CHECK (`status IN ('ACTIVE','SUSPENDED','INACTIVE')`).
- `FK_core_tenants_1`: (`currency_code`) → `ref.currencies` (`code`); NO ACTION.
- `IX_core_tenants_1`: INDEX (`currency_code`).

### core.tenant_settings

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `setting_key` | `VARCHAR(100)` | NO | — | — | — |
| `setting_value` | `NVARCHAR(MAX)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |
| `created_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |

- `PK_core_tenant_settings`: PRIMARY KEY (`id`).
- `UQ_core_tenant_settings_1`: UNIQUE (`tenant_id`, `id`).
- `UQ_core_tenant_settings_2`: UNIQUE (`tenant_id`, `setting_key`).
- `CK_core_tenant_settings_1`: CHECK (`ISJSON(setting_value) = 1`).
- `FK_core_tenant_settings_1`: (`tenant_id`) → `core.tenants` (`id`); NO ACTION.
- `FK_core_tenant_settings_2`: (`tenant_id`, `created_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `FK_core_tenant_settings_3`: (`tenant_id`, `updated_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.

### core.terminals

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `code` | `VARCHAR(30)` | NO | — | — | — |
| `name` | `NVARCHAR(150)` | NO | — | — | — |
| `address` | `NVARCHAR(500)` | YES | — | — | — |
| `timezone` | `NVARCHAR(64)` | NO | — | — | — |
| `status` | `VARCHAR(20)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |
| `created_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |

- `PK_core_terminals`: PRIMARY KEY (`id`).
- `UQ_core_terminals_1`: UNIQUE (`tenant_id`, `id`).
- `UQ_core_terminals_2`: UNIQUE (`tenant_id`, `code`).
- `FK_core_terminals_1`: (`tenant_id`) → `core.tenants` (`id`); NO ACTION.
- `FK_core_terminals_2`: (`tenant_id`, `created_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `FK_core_terminals_3`: (`tenant_id`, `updated_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.

### ref.countries

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `SMALLINT` | NO | — | IDENTITY(1,1) | YES |
| `code` | `CHAR(2)` | NO | — | — | — |
| `name` | `NVARCHAR(100)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |

- `PK_ref_countries`: PRIMARY KEY (`id`).
- `UQ_ref_countries_1`: UNIQUE (`code`).

### ref.jurisdictions

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `SMALLINT` | NO | — | IDENTITY(1,1) | YES |
| `country_id` | `SMALLINT` | NO | — | — | — |
| `code` | `VARCHAR(10)` | NO | — | — | — |
| `name` | `NVARCHAR(100)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |

- `PK_ref_jurisdictions`: PRIMARY KEY (`id`).
- `UQ_ref_jurisdictions_1`: UNIQUE (`country_id`, `code`).
- `FK_ref_jurisdictions_1`: (`country_id`) → `ref.countries` (`id`); NO ACTION.

### ref.currencies

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `code` | `CHAR(3)` | NO | — | — | YES |
| `name` | `NVARCHAR(100)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |

- `PK_ref_currencies`: PRIMARY KEY (`code`).

### ref.asset_types

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `SMALLINT` | NO | — | IDENTITY(1,1) | YES |
| `code` | `VARCHAR(30)` | NO | — | — | — |
| `name` | `NVARCHAR(100)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |

- `PK_ref_asset_types`: PRIMARY KEY (`id`).
- `UQ_ref_asset_types_1`: UNIQUE (`code`).

### ref.fuel_types

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `SMALLINT` | NO | — | IDENTITY(1,1) | YES |
| `code` | `VARCHAR(30)` | NO | — | — | — |
| `name` | `NVARCHAR(100)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |

- `PK_ref_fuel_types`: PRIMARY KEY (`id`).
- `UQ_ref_fuel_types_1`: UNIQUE (`code`).

### iam.users

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `auth_provider` | `VARCHAR(30)` | NO | — | — | — |
| `external_subject` | `NVARCHAR(200)` | NO | — | — | — |
| `email` | `NVARCHAR(254)` | YES | — | — | — |
| `display_name` | `NVARCHAR(150)` | NO | — | — | — |
| `status` | `VARCHAR(20)` | NO | `'ACTIVE'` | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |

- `PK_iam_users`: PRIMARY KEY (`id`).
- `UQ_iam_users_1`: UNIQUE (`auth_provider`, `external_subject`).
- `CK_iam_users_1`: CHECK (`status IN ('ACTIVE','DISABLED','INVITED')`).

### iam.memberships

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `user_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `status` | `VARCHAR(20)` | NO | `'ACTIVE'` | — | — |
| `joined_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |
| `created_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |

- `PK_iam_memberships`: PRIMARY KEY (`id`).
- `UQ_iam_memberships_1`: UNIQUE (`tenant_id`, `id`).
- `UQ_iam_memberships_2`: UNIQUE (`tenant_id`, `user_id`).
- `CK_iam_memberships_1`: CHECK (`status IN ('ACTIVE','SUSPENDED','INVITED','REVOKED')`).
- `FK_iam_memberships_1`: (`tenant_id`) → `core.tenants` (`id`); NO ACTION.
- `FK_iam_memberships_2`: (`user_id`) → `iam.users` (`id`); NO ACTION.
- `FK_iam_memberships_3`: (`tenant_id`, `created_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `FK_iam_memberships_4`: (`tenant_id`, `updated_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.

### iam.roles

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `code` | `VARCHAR(50)` | NO | — | — | — |
| `name` | `NVARCHAR(100)` | NO | — | — | — |
| `description` | `NVARCHAR(500)` | YES | — | — | — |
| `system_role` | `BIT` | NO | `0` | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |
| `created_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |

- `PK_iam_roles`: PRIMARY KEY (`id`).
- `UQ_iam_roles_1`: UNIQUE (`tenant_id`, `id`).
- `UQ_iam_roles_2`: UNIQUE (`tenant_id`, `code`).
- `FK_iam_roles_1`: (`tenant_id`) → `core.tenants` (`id`); NO ACTION.
- `FK_iam_roles_2`: (`tenant_id`, `created_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `FK_iam_roles_3`: (`tenant_id`, `updated_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.

### iam.permissions

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `code` | `VARCHAR(100)` | NO | — | — | — |
| `resource` | `VARCHAR(50)` | NO | — | — | — |
| `action` | `VARCHAR(50)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |

- `PK_iam_permissions`: PRIMARY KEY (`id`).
- `UQ_iam_permissions_1`: UNIQUE (`code`).

### iam.membership_roles

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `membership_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `role_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |
| `created_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |

- `PK_iam_membership_roles`: PRIMARY KEY (`id`).
- `UQ_iam_membership_roles_1`: UNIQUE (`tenant_id`, `id`).
- `UQ_iam_membership_roles_2`: UNIQUE (`tenant_id`, `membership_id`, `role_id`).
- `FK_iam_membership_roles_1`: (`tenant_id`) → `core.tenants` (`id`); NO ACTION.
- `FK_iam_membership_roles_2`: (`tenant_id`, `membership_id`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `FK_iam_membership_roles_3`: (`tenant_id`, `role_id`) → `iam.roles` (`tenant_id`, `id`); NO ACTION.
- `FK_iam_membership_roles_4`: (`tenant_id`, `created_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `FK_iam_membership_roles_5`: (`tenant_id`, `updated_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `IX_iam_membership_roles_1`: INDEX (`tenant_id`, `role_id`).

### iam.role_permissions

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `role_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `permission_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |
| `created_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |

- `PK_iam_role_permissions`: PRIMARY KEY (`id`).
- `UQ_iam_role_permissions_1`: UNIQUE (`tenant_id`, `id`).
- `UQ_iam_role_permissions_2`: UNIQUE (`tenant_id`, `role_id`, `permission_id`).
- `FK_iam_role_permissions_1`: (`tenant_id`) → `core.tenants` (`id`); NO ACTION.
- `FK_iam_role_permissions_2`: (`tenant_id`, `role_id`) → `iam.roles` (`tenant_id`, `id`); NO ACTION.
- `FK_iam_role_permissions_3`: (`permission_id`) → `iam.permissions` (`id`); NO ACTION.
- `FK_iam_role_permissions_4`: (`tenant_id`, `created_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `FK_iam_role_permissions_5`: (`tenant_id`, `updated_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `IX_iam_role_permissions_1`: INDEX (`tenant_id`, `permission_id`).

### fleet.assets

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `unit_number` | `NVARCHAR(30)` | NO | — | — | — |
| `asset_type_id` | `SMALLINT` | NO | — | — | — |
| `vin` | `VARCHAR(17)` | YES | — | — | — |
| `make` | `NVARCHAR(80)` | NO | — | — | — |
| `model` | `NVARCHAR(80)` | NO | — | — | — |
| `model_year` | `SMALLINT` | NO | — | — | — |
| `ownership_type` | `VARCHAR(20)` | NO | — | — | — |
| `status` | `VARCHAR(25)` | NO | `'AVAILABLE'` | — | — |
| `terminal_id` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `in_service_date` | `DATE` | YES | — | — | — |
| `acquisition_cost` | `DECIMAL(19,4)` | YES | — | — | — |
| `currency_code` | `CHAR(3)` | NO | — | — | — |
| `notes` | `NVARCHAR(2000)` | YES | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |
| `created_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |

- `PK_fleet_assets`: PRIMARY KEY (`id`).
- `UQ_fleet_assets_1`: UNIQUE (`tenant_id`, `id`).
- `UQ_fleet_assets_2`: UNIQUE (`tenant_id`, `unit_number`).
- `CK_fleet_assets_1`: CHECK (`status IN ('AVAILABLE','ASSIGNED','IN_TRANSIT','MAINTENANCE','OUT_OF_SERVICE','INACTIVE')`).
- `CK_fleet_assets_2`: CHECK (`ownership_type IN ('OWNED','LEASED','CONTRACTED')`).
- `CK_fleet_assets_3`: CHECK (`model_year BETWEEN 1900 AND 2100`).
- `CK_fleet_assets_4`: CHECK (`vin IS NULL OR LEN(vin)=17`).
- `FK_fleet_assets_1`: (`tenant_id`) → `core.tenants` (`id`); NO ACTION.
- `FK_fleet_assets_2`: (`asset_type_id`) → `ref.asset_types` (`id`); NO ACTION.
- `FK_fleet_assets_3`: (`tenant_id`, `terminal_id`) → `core.terminals` (`tenant_id`, `id`); NO ACTION.
- `FK_fleet_assets_4`: (`currency_code`) → `ref.currencies` (`code`); NO ACTION.
- `FK_fleet_assets_5`: (`tenant_id`, `created_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `FK_fleet_assets_6`: (`tenant_id`, `updated_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `IX_fleet_assets_1`: UNIQUE INDEX (`tenant_id`, `vin`) WHERE `vin IS NOT NULL`.
- `IX_fleet_assets_2`: INDEX (`tenant_id`, `asset_type_id`).
- `IX_fleet_assets_3`: INDEX (`tenant_id`, `terminal_id`).
- `IX_fleet_assets_4`: INDEX (`tenant_id`, `currency_code`).
- `IX_fleet_assets_5`: INDEX (`tenant_id`, `status`, `terminal_id`).

### fleet.vehicles

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `asset_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `plate_number` | `NVARCHAR(30)` | YES | — | — | — |
| `plate_jurisdiction_id` | `SMALLINT` | YES | — | — | — |
| `fuel_type_id` | `SMALLINT` | YES | — | — | — |
| `fuel_capacity` | `DECIMAL(14,3)` | YES | — | — | — |
| `gross_vehicle_weight` | `DECIMAL(14,3)` | YES | — | — | — |
| `engine_serial` | `NVARCHAR(100)` | YES | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |
| `created_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |

- `PK_fleet_vehicles`: PRIMARY KEY (`id`).
- `UQ_fleet_vehicles_1`: UNIQUE (`tenant_id`, `id`).
- `UQ_fleet_vehicles_2`: UNIQUE (`tenant_id`, `asset_id`).
- `CK_fleet_vehicles_1`: CHECK (`fuel_capacity >= 0`).
- `CK_fleet_vehicles_2`: CHECK (`gross_vehicle_weight >= 0`).
- `FK_fleet_vehicles_1`: (`tenant_id`) → `core.tenants` (`id`); NO ACTION.
- `FK_fleet_vehicles_2`: (`tenant_id`, `asset_id`) → `fleet.assets` (`tenant_id`, `id`); NO ACTION.
- `FK_fleet_vehicles_3`: (`plate_jurisdiction_id`) → `ref.jurisdictions` (`id`); NO ACTION.
- `FK_fleet_vehicles_4`: (`fuel_type_id`) → `ref.fuel_types` (`id`); NO ACTION.
- `FK_fleet_vehicles_5`: (`tenant_id`, `created_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `FK_fleet_vehicles_6`: (`tenant_id`, `updated_by`) → `iam.memberships` (`tenant_id`, `id`); NO ACTION.
- `IX_fleet_vehicles_1`: INDEX (`tenant_id`, `plate_jurisdiction_id`).
- `IX_fleet_vehicles_2`: INDEX (`tenant_id`, `fuel_type_id`).

### audit.audit_events

| Column | SQL type | Nullable | Default | Identity | Primary key |
| --- | --- | --- | --- | --- | --- |
| `id` | `BIGINT` | NO | — | IDENTITY(1,1) | YES |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `actor_id` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `actor_type` | `VARCHAR(20)` | NO | — | — | — |
| `action` | `VARCHAR(50)` | NO | — | — | — |
| `entity_type` | `VARCHAR(100)` | NO | — | — | — |
| `entity_id` | `NVARCHAR(100)` | YES | — | — | — |
| `old_values` | `NVARCHAR(MAX)` | YES | — | — | — |
| `new_values` | `NVARCHAR(MAX)` | YES | — | — | — |
| `correlation_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `occurred_at` | `DATETIME2(3)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |

- `PK_audit_audit_events`: PRIMARY KEY (`id`).
- `UQ_audit_audit_events_1`: UNIQUE (`tenant_id`, `id`).
- `CK_audit_audit_events_1`: CHECK (`ISJSON(old_values) = 1`).
- `CK_audit_audit_events_2`: CHECK (`ISJSON(new_values) = 1`).
- `FK_audit_audit_events_1`: (`tenant_id`) → `core.tenants` (`id`); NO ACTION.
- `FK_audit_audit_events_2`: (`actor_id`) → `iam.users` (`id`); NO ACTION.
- `IX_audit_audit_events_1`: INDEX (`tenant_id`, `actor_id`).
- `IX_audit_audit_events_2`: INDEX (`tenant_id`, `entity_type`, `entity_id`, `occurred_at`).

### integration.idempotency_keys

**Approved delta only**: existing target proposal, still foundation=false in the unchanged
global metadata. Feature 001's reviewed set is foundation=true OR this exact table name.
No other columns, tables, checks, secondary indexes, cascades or reference seeds are added.

| Column | SQL Server type | Nullable | Default | Identity | PK |
| --- | --- | --- | --- | --- | --- |
| `id` | `UNIQUEIDENTIFIER` | NO | `NEWSEQUENTIALID()` | — | YES |
| `tenant_id` | `UNIQUEIDENTIFIER` | NO | — | — | — |
| `operation_scope` | `VARCHAR(80)` | NO | — | — | — |
| `request_key` | `NVARCHAR(150)` | NO | — | — | — |
| `request_hash` | `BINARY(32)` | NO | — | — | — |
| `response_reference` | `NVARCHAR(150)` | YES | — | — | — |
| `expires_at` | `DATETIME2(3)` | NO | — | — | — |
| `created_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `updated_at` | `DATETIME2(3)` | NO | `SYSUTCDATETIME()` | — | — |
| `row_version` | `ROWVERSION` | NO | — | — | — |
| `created_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |
| `updated_by` | `UNIQUEIDENTIFIER` | YES | — | — | — |

- `PK_integration_idempotency_keys`: PRIMARY KEY (`id`).
- `UQ_integration_idempotency_keys_1`: UNIQUE (`tenant_id, id`).
- `UQ_integration_idempotency_keys_2`: UNIQUE (`tenant_id, operation_scope, request_key`).
- `FK_integration_idempotency_keys_1`: (`tenant_id`) → `core.tenants` (`id`), nonnull.
- `FK_integration_idempotency_keys_2`: (`tenant_id, created_by`) → `iam.memberships` (`tenant_id, id`), nullable.
- `FK_integration_idempotency_keys_3`: (`tenant_id, updated_by`) → `iam.memberships` (`tenant_id, id`), nullable.
- No CHECK constraints or additional indexes in the proposed model; PK/UQs provide their indexes.
- All FKs use NO ACTION for delete/update. Referenced tenant PK and membership composite UQ
  already exist in the 17-table foundation; its transitive dependencies are closed.
- SQL types/defaults/nullability remain exactly as proposed. Feature-specific scope grammar,
  nonnull completed reference, actor values and expiry sentinel are enforced by the service
  and acceptance tests, not unapproved physical-model edits.
