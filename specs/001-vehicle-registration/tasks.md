# Tasks: Feature 001 — Vehicle Registration

**Input**: [plan.md](plan.md), [spec.md](spec.md), [data-model.md](data-model.md), [test-plan.md](test-plan.md), [research.md](research.md), [quickstart.md](quickstart.md), and [contracts/](contracts/README.md).

**Scope**: AUTH-01, AUTH-02, the registration/read slice of FLT-01, and DEV-008. Three P1 stories; all 22 required acceptance groups (UT-01–05, IT-01–10, SB-01–07). Build the unchanged 17-table foundation plus the single approved `integration.idempotency_keys` table. `tasks.md` tracks implementation progress; no runtime evidence is assumed.

**Format**: `[P]` means the task can proceed in parallel with other marked tasks in that phase after its prerequisites. `[US1]`–`[US3]` identify story tasks. Each task names its output file. Tests precede story implementation; missing/failed/skipped cases cannot count as acceptance.

## External Gates

| Gate | Prerequisite | Tasks that need it |
| --- | --- | --- |
| G-CLERK | ADR-004 approval and scoped Clerk development proof established by T002. | Clerk-dependent package selection T004; production identity and shared authorization T037–T038/T045–T046/T047; membership selection T082; real provider smoke T088. Authenticated end-to-end acceptance needs the approved adapter. |
| G-PINS | Compatible locked Python/npm packages, image digests, browser/driver pair and Action SHAs established by T003–T005. | Container builds and CI T008–T012, production identity T037, browser fixture T043, reliable execution of UT/IT/SB cases, and final verification T084/T086–T089. T003–T005 can begin before the gate they establish. |
| G-SQL | External access to a running supported SQL Server 2022 Linux amd64 with working driver/TLS and isolated migration/bootstrap credentials; T003 and T084 record compatibility proof. | Migration/driver/permission validation T032–T038/T045–T047, SQL/browser fixtures T041/T043, IT-01–10, SB-01–07, and final SQL/CI evidence T084–T090. Migration source can be drafted before SQL is available. |

T001 verifies recorded decisions; it does not seek new B-001/B-002 approval. Work that establishes
an external gate may start immediately. Gate-dependent code may be drafted, but its runtime
acceptance cannot be signed off until the gate is proven. Independent scaffold, model, vector and
unit-test work does not wait for unrelated gates.

## Format: `[ID] [P?] [Story?] Description`

- `[P]`: different output files and no dependency on unfinished work beyond the phase prerequisites.
- `[Story]`: required only for story phases; setup, foundation and final tasks have no story label.
- All paths are repository-relative unless they refer to this feature's existing design artifacts.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish reproducible React/FastAPI/SQL Server development and the DEV-008 command contract. No application scaffold exists yet.

**Entry**: Verify the recorded plan decisions in T001. T002–T005 begin the Clerk, dependency/image and SQL compatibility work; the resulting gates apply to dependent runtime proof, not to drafting independent files.

- [X] T001 Verify the reviewed Feature 001 scope, approved eighteenth retry table, retained receipts and UTF-16 contract against `specs/001-vehicle-registration/plan.md`; record any unresolved gate before implementation.
- [ ] T002 Establish G-CLERK: confirm ADR-004 provider approval and prove Clerk Python SDK session status, subject/session binding, revocation and outage behavior with a scoped development instance; record evidence in `docs/architecture-notes.md`.
- [X] T003 Establish the Python/SQL part of G-PINS and G-SQL: select and pin compatible Python 3.12 packages, pyodbc/ODBC 18 and test tooling in `apps/api/pyproject.toml` and `apps/api/requirements.lock`; record SQL driver/TLS compatibility evidence before closing G-SQL.
- [ ] T004 Establish the web part of G-PINS: pin React/TypeScript/Vite/Tailwind, Vitest, generated OpenAPI client tooling and Node 24 in `apps/web/package.json` and `apps/web/package-lock.json`; finalize Clerk client selection after G-CLERK.
- [ ] T005 Establish the image/CI part of G-PINS: pin SQL Server 2022, API/web build images, Selenium Chrome/driver pair and GitHub Action SHAs in `compose.yaml`, `compose.test.yaml` and `.github/workflows/ci.yml` after image checks.
- [X] T006 Scaffold strict React SPA, accessible styling, app entry and test configuration in `apps/web/tsconfig.json`, `apps/web/vite.config.ts`, `apps/web/src/main.tsx` and `apps/web/vitest.config.ts`.
- [ ] T007 Scaffold typed FastAPI application, configuration, health endpoints, pytest/Ruff settings and Alembic environment in `apps/api/app/main.py`, `apps/api/app/core/config.py`, `apps/api/alembic/env.py` and `apps/api/pyproject.toml`.
- [ ] T008 Create private SQL, API and built-web Compose services plus explicit bootstrap/migrate/seed jobs, non-root application Dockerfiles and health checks in `compose.yaml`, `apps/api/Dockerfile` and `apps/web/Dockerfile`. (gate: G-PINS, G-SQL)
- [ ] T009 Add isolated test Compose services for identity boundary, SQL, API, built web, Selenium and test runners in `compose.test.yaml`; do not expose SQL or mount Docker socket. (gate: G-PINS, G-SQL)
- [X] T010 Create or verify `.env.example`, `.gitignore`, `apps/api/.dockerignore`, `apps/web/.dockerignore` and `.vscode/tasks.json` for secret-safe Windows PowerShell/WSL commands and matching test targets.
- [ ] T011 Implement `make test-unit`, `make test-integration`, `make test-selenium`, aggregate `make test` and cross-platform isolated Compose orchestration in `Makefile` and `tools/run_tests.py`; fail on setup errors, missing services, zero tests or required skips.
- [ ] T012 Configure PR checks named `unit`, `integration` and `selenium`, each invoking its exact root Make target, plus lint/type, OpenAPI drift, image/build smoke and security scans in `.github/workflows/ci.yml`; collect JUnit and sanitized browser diagnostics. (gate: G-PINS)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish exact SQL schema, tenant security, verified identity and isolated fixtures before the three user stories.

**Checkpoint**: Fresh and upgraded SQL databases contain the approved 18-table subset, runtime grants/RLS work, and the real token-verification/business-permission path is available. `G-CLERK`, `G-PINS` and `G-SQL` must be satisfied for the corresponding evidence tasks.

- [X] T013 Create schema-qualified SQLAlchemy model registry and naming conventions matching `data-model.md` in `apps/api/app/db/base.py`.
- [X] T014 [P] Implement the exact core.tenants SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#core-tenants`: `core.tenants.id`, `core.tenants.name`, `core.tenants.legal_name`, `core.tenants.slug`, `core.tenants.status`, `core.tenants.dot_number`, `core.tenants.mc_number`, `core.tenants.timezone`, `core.tenants.currency_code`, `core.tenants.created_at`, `core.tenants.updated_at`, `core.tenants.row_version` in `apps/api/app/db/models/core_tenants.py`.
- [X] T015 [P] Implement the exact core.tenant_settings SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#core-tenant_settings`: `core.tenant_settings.id`, `core.tenant_settings.tenant_id`, `core.tenant_settings.setting_key`, `core.tenant_settings.setting_value`, `core.tenant_settings.created_at`, `core.tenant_settings.updated_at`, `core.tenant_settings.row_version`, `core.tenant_settings.created_by`, `core.tenant_settings.updated_by` in `apps/api/app/db/models/core_tenant_settings.py`.
- [X] T016 [P] Implement the exact core.terminals SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#core-terminals`: `core.terminals.id`, `core.terminals.tenant_id`, `core.terminals.code`, `core.terminals.name`, `core.terminals.address`, `core.terminals.timezone`, `core.terminals.status`, `core.terminals.created_at`, `core.terminals.updated_at`, `core.terminals.row_version`, `core.terminals.created_by`, `core.terminals.updated_by` in `apps/api/app/db/models/core_terminals.py`.
- [X] T017 [P] Implement the exact ref.countries SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#ref-countries`: `ref.countries.id`, `ref.countries.code`, `ref.countries.name`, `ref.countries.created_at` in `apps/api/app/db/models/ref_countries.py`.
- [X] T018 [P] Implement the exact ref.jurisdictions SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#ref-jurisdictions`: `ref.jurisdictions.id`, `ref.jurisdictions.country_id`, `ref.jurisdictions.code`, `ref.jurisdictions.name`, `ref.jurisdictions.created_at` in `apps/api/app/db/models/ref_jurisdictions.py`.
- [X] T019 [P] Implement the exact ref.currencies SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#ref-currencies`: `ref.currencies.code`, `ref.currencies.name`, `ref.currencies.created_at` in `apps/api/app/db/models/ref_currencies.py`.
- [X] T020 [P] Implement the exact ref.asset_types SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#ref-asset_types`: `ref.asset_types.id`, `ref.asset_types.code`, `ref.asset_types.name`, `ref.asset_types.created_at` in `apps/api/app/db/models/ref_asset_types.py`.
- [X] T021 [P] Implement the exact ref.fuel_types SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#ref-fuel_types`: `ref.fuel_types.id`, `ref.fuel_types.code`, `ref.fuel_types.name`, `ref.fuel_types.created_at` in `apps/api/app/db/models/ref_fuel_types.py`.
- [X] T022 [P] Implement the exact iam.users SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#iam-users`: `iam.users.id`, `iam.users.auth_provider`, `iam.users.external_subject`, `iam.users.email`, `iam.users.display_name`, `iam.users.status`, `iam.users.created_at`, `iam.users.updated_at`, `iam.users.row_version` in `apps/api/app/db/models/iam_users.py`.
- [X] T023 [P] Implement the exact iam.memberships SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#iam-memberships`: `iam.memberships.id`, `iam.memberships.tenant_id`, `iam.memberships.user_id`, `iam.memberships.status`, `iam.memberships.joined_at`, `iam.memberships.created_at`, `iam.memberships.updated_at`, `iam.memberships.row_version`, `iam.memberships.created_by`, `iam.memberships.updated_by` in `apps/api/app/db/models/iam_memberships.py`.
- [X] T024 [P] Implement the exact iam.roles SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#iam-roles`: `iam.roles.id`, `iam.roles.tenant_id`, `iam.roles.code`, `iam.roles.name`, `iam.roles.description`, `iam.roles.system_role`, `iam.roles.created_at`, `iam.roles.updated_at`, `iam.roles.row_version`, `iam.roles.created_by`, `iam.roles.updated_by` in `apps/api/app/db/models/iam_roles.py`.
- [X] T025 [P] Implement the exact iam.permissions SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#iam-permissions`: `iam.permissions.id`, `iam.permissions.code`, `iam.permissions.resource`, `iam.permissions.action`, `iam.permissions.created_at`, `iam.permissions.updated_at`, `iam.permissions.row_version` in `apps/api/app/db/models/iam_permissions.py`.
- [X] T026 [P] Implement the exact iam.membership_roles SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#iam-membership_roles`: `iam.membership_roles.id`, `iam.membership_roles.tenant_id`, `iam.membership_roles.membership_id`, `iam.membership_roles.role_id`, `iam.membership_roles.created_at`, `iam.membership_roles.updated_at`, `iam.membership_roles.row_version`, `iam.membership_roles.created_by`, `iam.membership_roles.updated_by` in `apps/api/app/db/models/iam_membership_roles.py`.
- [X] T027 [P] Implement the exact iam.role_permissions SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#iam-role_permissions`: `iam.role_permissions.id`, `iam.role_permissions.tenant_id`, `iam.role_permissions.role_id`, `iam.role_permissions.permission_id`, `iam.role_permissions.created_at`, `iam.role_permissions.updated_at`, `iam.role_permissions.row_version`, `iam.role_permissions.created_by`, `iam.role_permissions.updated_by` in `apps/api/app/db/models/iam_role_permissions.py`.
- [X] T028 [P] Implement the exact fleet.assets SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#fleet-assets`: `fleet.assets.id`, `fleet.assets.tenant_id`, `fleet.assets.unit_number`, `fleet.assets.asset_type_id`, `fleet.assets.vin`, `fleet.assets.make`, `fleet.assets.model`, `fleet.assets.model_year`, `fleet.assets.ownership_type`, `fleet.assets.status`, `fleet.assets.terminal_id`, `fleet.assets.in_service_date`, `fleet.assets.acquisition_cost`, `fleet.assets.currency_code`, `fleet.assets.notes`, `fleet.assets.created_at`, `fleet.assets.updated_at`, `fleet.assets.row_version`, `fleet.assets.created_by`, `fleet.assets.updated_by` in `apps/api/app/db/models/fleet_assets.py`.
- [X] T029 [P] Implement the exact fleet.vehicles SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#fleet-vehicles`: `fleet.vehicles.id`, `fleet.vehicles.tenant_id`, `fleet.vehicles.asset_id`, `fleet.vehicles.plate_number`, `fleet.vehicles.plate_jurisdiction_id`, `fleet.vehicles.fuel_type_id`, `fleet.vehicles.fuel_capacity`, `fleet.vehicles.gross_vehicle_weight`, `fleet.vehicles.engine_serial`, `fleet.vehicles.created_at`, `fleet.vehicles.updated_at`, `fleet.vehicles.row_version`, `fleet.vehicles.created_by`, `fleet.vehicles.updated_by` in `apps/api/app/db/models/fleet_vehicles.py`.
- [X] T030 [P] Implement the exact integration.idempotency_keys SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#integration-idempotency_keys`: `integration.idempotency_keys.id`, `integration.idempotency_keys.tenant_id`, `integration.idempotency_keys.operation_scope`, `integration.idempotency_keys.request_key`, `integration.idempotency_keys.request_hash`, `integration.idempotency_keys.response_reference`, `integration.idempotency_keys.expires_at`, `integration.idempotency_keys.created_at`, `integration.idempotency_keys.updated_at`, `integration.idempotency_keys.row_version`, `integration.idempotency_keys.created_by`, `integration.idempotency_keys.updated_by` in `apps/api/app/db/models/integration_idempotency_keys.py`.
- [X] T031 [P] Implement the exact audit.audit_events SQLAlchemy model, PK/UQ/CHECK/FK/default/index and all constrained fields from `data-model.md#audit-audit_events`: `audit.audit_events.id`, `audit.audit_events.tenant_id`, `audit.audit_events.actor_id`, `audit.audit_events.actor_type`, `audit.audit_events.action`, `audit.audit_events.entity_type`, `audit.audit_events.entity_id`, `audit.audit_events.old_values`, `audit.audit_events.new_values`, `audit.audit_events.correlation_id`, `audit.audit_events.occurred_at`, `audit.audit_events.created_at` in `apps/api/app/db/models/audit_audit_events.py`.
- [X] T032 Implement `0001_foundation` with only the 17 foundation tables, exact 154 columns/39 FKs, cyclic/self FKs after table creation and no reference-DDL execution in `apps/api/alembic/versions/0001_foundation.py`. (gate: G-SQL)
- [ ] T033 Implement reviewed bounded identity bootstrap, nine-table RLS/filter/block coverage, 45 predicates and least-privilege runtime/bootstrap/migration grants in `apps/api/alembic/versions/0002_foundation_security.py`. (gate: G-SQL)
- [X] T034 Implement `0003_vehicle_registration_idempotency` with only the integration schema and proposed 12-column/3-FK `integration.idempotency_keys`, its PK/two UQs, five RLS predicates and SELECT/INSERT-only runtime grant in `apps/api/alembic/versions/0003_vehicle_registration_idempotency.py`; require 18 tables/166 columns/42 FKs and no populated downgrade. (gate: G-SQL)
- [ ] T035 Seed governed USD/US/jurisdiction/TRACTOR/fuel references and `fleet.vehicle.read/create` capability codes through controlled setup in `apps/api/app/db/reference_seed.py`; isolate fictional tenant/user fixture seeding in `tests/fixtures/seed_fleet.py`. (gate: G-SQL)
- [ ] T036 Implement TLS-verified pyodbc/SQLAlchemy connections, native UUID tenant context, checkout/checkin/error reset and failed-reset invalidation in `apps/api/app/core/db.py`; disable pyodbc's separate pooling before connections. (gate: G-PINS, G-SQL)
- [ ] T037 Implement production token signature/issuer/authorized-party/time verification plus current provider-session check with bounded timeout and outage handling in `apps/api/app/core/identity.py`; do not cache a positive session status. (gate: G-CLERK, G-PINS)
- [ ] T038 Implement fixed verified-subject membership/capability bootstrap and immutable RequestContext in `apps/api/app/modules/tenants/bootstrap.py` and `apps/api/app/core/request_context.py`; resolve fresh active membership for protected operations. (gate: G-CLERK, G-SQL)
- [ ] T039 Implement shared sanitized 401/403/404/409/422/503 envelopes, request IDs and redacted telemetry in `apps/api/app/core/errors.py` and `apps/api/app/core/telemetry.py`.
- [ ] T040 Create run-scoped signed identity/JWKS fixture and provider-status boundary while keeping production verifier active in `tests/fixtures/identity_boundary.py`; reject synthetic configuration at production startup.
- [ ] T041 Create `carrier_pair`, dispatchers, payload, `real_application`, inspection-role and revocation fixtures with isolated SQL state in `apps/api/tests/integration/conftest.py`; application actions use runtime credentials. (gate: G-SQL)
- [X] T042 Create or verify shared UC-01–09 UTF-16, normalization, surrogate and hash vectors for Python/TypeScript/SQL/Selenium in `tests/fixtures/vehicle_registration_vectors.json`.
- [ ] T043 Create independent RemoteWebDriver and test identity/browser fixtures with condition waits and `quit()` finalizers in `tests/selenium/conftest.py`; browser resolves `http://web:8080`. (gate: G-PINS, G-SQL)
- [ ] T044 Generate/validate the typed web client from `specs/001-vehicle-registration/contracts/openapi.json`, preserving `x-utf16-*`, trim and well-formedness annotations, in `packages/api-contracts/` and `apps/web/src/lib/apiClient.ts`.
- [ ] T045 Implement current read/create capability decisions and a fresh membership recheck callable for use after the SQL key-lock wait and before create/replay results in `apps/api/app/modules/fleet/permissions.py`; a DISPATCHER label grants nothing. (gate: G-CLERK, G-SQL)
- [ ] T046 Implement protected-route dependency factories for provider 401, membership/create 403 and provider-status outage 503 in `apps/api/app/core/request_context.py` and `apps/api/app/modules/fleet/route_dependencies.py`; US1 routes must consume them for direct POST and replay. (gate: G-CLERK)
- [ ] T047 Implement a scoped retry-lookup and response-authorization guard for `data-model.md#integration-idempotency_keys` `integration.idempotency_keys.tenant_id`, operation and membership in `apps/api/app/modules/fleet/replay_authorization.py`; reject foreign/missing references before the original response can be disclosed. (gate: G-CLERK, G-SQL)

---

## Phase 3: User Story 1 — Register and Find a Truck After Refresh (P1, MVP)

**Goal**: An active Carrier A dispatcher registers a truck, sees it after refresh and receives a durable original result on a valid retry.

**Independent test**: In its own seeded database and browser session, A creates a fresh unit, refreshes/searches and sees exactly one matching record; same-key replay after process replacement returns the original result. This phase owns FR-004/005/007–010 and the first FLT-01 slice. Its tests require the foundational permission, route-dependency and scoped-replay guards T045–T047, plus the retry-table migration T034.

**Tests first**: US1 tests may be authored while gates are being established, but they cannot be marked passing or make the story complete until T034 and T045–T047 are complete. Observe expected failures before remaining story implementation; SQL integration/Selenium execution requires `G-SQL` and pinned images.

### Tests

- [X] T048 [P] [US1] Implement UT-02 in `apps/api/tests/unit/test_vehicle_validation.py::test_registration_field_boundaries`, `test_unit_number_normalization` and `apps/api/tests/unit/test_vehicle_idempotency.py::test_canonical_registration_digest`; use shared UC-01–09/hash vectors to assert strict field/year/ownership checks, BMP/supplementary/combining boundaries, trim and surrogate rejection, stable canonical hashes, changed-value/case conflicts, 32-byte digest and scoped key/reference grammar.
- [ ] T049 [P] [US1] Implement UT-03 executable cases at `apps/web/src/features/vehicles/__tests__/VehicleRegistrationForm.test.tsx` — missing/over-limit fields; `apps/web/src/features/vehicles/__tests__/vehicleValidation.test.ts` — shared UTF-16 vectors using user keyboard, request spy, UC-01–09; assert Missing/blank/over-limit/malformed input has linked accessible error, retains typed value and sends no POST. Exact-limit supplementary values count as 30/80 units and submit unchanged. Shared normalization agrees with API..
- [ ] T050 [US1] Implement IT-01 executable cases at `apps/api/tests/integration/fleet/test_vehicle_registration.py::test_register_and_read_persisted_vehicle` using carrier_pair, A creator, registration_payload, real_application, inspect_db; assert 201 create, then independent GET/list; same ID/details, one A asset/vehicle pair, one audit and one scoped complete receipt with verified actor/UTC time; zero B changes.. (gate: G-SQL, G-PINS)
- [ ] T051 [US1] Implement IT-02 executable cases at `apps/api/tests/integration/fleet/test_vehicle_registration.py::test_duplicate_unit_is_scoped_to_tenant` using carrier_pair, A creator, two keys; assert First fresh create 201, distinct-key normalized duplicate 409, no second row; both seeded TRK-001 resolve to their own distinct records. Cover case/whitespace and collation vectors.. (gate: G-SQL, G-PINS)
- [ ] T052 [P] [US1] Implement IT-06 executable cases at `apps/api/tests/integration/fleet/test_vehicle_concurrency.py::test_concurrent_duplicate_registration_commits_once` using concurrency_barrier, A creator, fresh unit, inspect_db; assert Independent connections and keys race: one 201, one 409, exactly one complete pair, success audit and receipt; losing key leaves no receipt. Repeat enough times to expose race, with per-attempt isolated units.. (gate: G-SQL, G-PINS)
- [ ] T053 [P] [US1] Implement IT-07 executable cases at `apps/api/tests/integration/fleet/test_vehicle_idempotency.py::test_registration_replays_after_restart`; `test_key_payload_and_actor_scope`; `test_concurrent_key_replays_once`; `test_receipt_retention_and_missing_reference` using lost_response_restart, concurrency_barrier, second authorized actor/carrier, inspect_db; assert Original 201/body/Location after restart; one asset/vehicle/audit/receipt. Same-key race yields identical successes; changed-valid-payload race yields one success/one 409. Current auth on every replay; actor/tenant scope cannot leak original. Fixed canonical hash, sentinel expiry, aged receipt still replayable, missing/corrupt reference fails 503 without create.. (gate: G-SQL, G-PINS)
- [ ] T054 [US1] Implement IT-08 executable cases at `apps/api/tests/integration/fleet/test_vehicle_atomicity.py::test_invalid_registration_has_no_effect`; `test_partial_registration_rolls_back`; `test_precommit_process_loss`; `apps/api/tests/integration/fleet/test_vehicle_registration.py::test_utf16_boundary_round_trip` using UC-01–09, raw malformed JSON strings, fault_boundary, inspect_db; assert 422/zero rows for invalid fields or UTF-16 overflow. Valid BMP/supplementary/mixed boundaries return/read/replay unchanged; DATALENGTH/2 is exact. Failure after each of four inserts or precommit process loss leaves zero rows; same-key retry can then succeed once. Lock failure cannot commit anything.. (gate: G-SQL, G-PINS)
- [ ] T055 [P] [US1] Implement IT-10 executable cases at `apps/api/tests/integration/database/test_foundation_migrations.py::test_fresh_and_previous_revision_upgrade`; `test_foundation_contract_and_runtime_grants`; `test_vehicle_provenance`; `test_idempotency_schema_and_grants`; `test_nvarchar_rejects_overflow` using fresh DB, 0001/0002 baselines, populated 0002 fixture, runtime/seed/migrate roles; assert Exact 18-domain-table/166-column/42-FK contract; five additional retry predicates (50 total); defaults/UQs/FKs/BINARY(32)/NVARCHAR(150)/expiry/nullability and no extra checks/indexes. Verify runtime key locks and SELECT/INSERT only; update/delete/DDL denied. UTC/UUID/ROWVERSION/DECIMAL/Unicode round trips; direct SQL UTF-16 overflow fails with ANSI_WARNINGS ON, no truncated row. Immutable creation provenance; replay adds no event/receipt.. (gate: G-SQL, G-PINS)
- [ ] T056 [P] [US1] Implement SB-01 executable cases at `tests/selenium/test_vehicle_registration.py::test_dispatcher_registers_vehicle` using browser, A creator, registration_payload; assert Sign in, open Vehicles, register valid truck, wait for success, refresh/search and open result; exactly one truck and all submitted details match.. (gate: G-SQL, G-PINS)
- [ ] T057 [US1] Implement SB-04 executable cases at `tests/selenium/test_vehicle_registration.py::test_keyboard_validation_duplicate_and_correction`; `test_utf16_boundary_validation_and_refresh` using browser, A creator, duplicate/fresh units, UC-01–07/09; assert Keyboard missing/duplicate/correction journey, then actual form entry at BMP, supplementary and mixed 30/80 limits and one-unit-over. Overflow remains visible, accessible error/no POST or save; correction succeeds and exact text survives refresh/detail. Exercise make and model independently.. (gate: G-SQL, G-PINS)
- [ ] T058 [P] [US1] Implement SB-07 executable cases at `tests/selenium/test_vehicle_states.py::test_empty_loading_and_unavailable_states` using browser, own_empty_fleet, fault_boundary; assert Empty own fleet differs from no matches and outage; delayed list/save stays pending; unavailable request has retry/error state and no false success.. (gate: G-SQL, G-PINS)

### Implementation

- [X] T059 [US1] Implement exact post-trim UTF-16 validation, well-formed Unicode, strict year/ownership and normalized response schemas for `data-model.md#fleet-assets` `fleet.assets.unit_number`, `fleet.assets.make`, `fleet.assets.model`, `fleet.assets.model_year`, `fleet.assets.ownership_type` in `apps/api/app/modules/fleet/schemas.py`.
- [X] T060 [P] [US1] Implement matching browser UTF-16/trim/well-formedness validation, editable overflow errors and shared UC-01–09 vectors for `data-model.md#fleet-assets` `fleet.assets.unit_number`, `fleet.assets.make`, `fleet.assets.model` in `apps/web/src/features/vehicles/vehicleValidation.ts`.
- [ ] T061 [US1] Implement canonical v1 payload serialization/SHA-256, actor-scoped operation string, UUID key, typed vehicle reference and nonexpiring receipt sentinel for `data-model.md#integration-idempotency_keys` `integration.idempotency_keys.operation_scope`, `integration.idempotency_keys.request_key`, `integration.idempotency_keys.request_hash`, `integration.idempotency_keys.response_reference`, `integration.idempotency_keys.expires_at`, `integration.idempotency_keys.created_by`, `integration.idempotency_keys.updated_by` in `apps/api/app/modules/fleet/idempotency.py`.
- [ ] T062 [US1] Implement tenant-bound asset/vehicle and receipt reads/inserts, case-insensitive exact-unit filter, deterministic pagination, actor/reference verification and immutable created_at projection in `apps/api/app/modules/fleet/repository.py`.
- [ ] T063 [US1] Implement bounded SQL transaction-owned per-tenant/member/key lock and atomic asset/vehicle/audit/receipt insert with known unique-conflict rollback, safe lock failure, restart replay, hash mismatch 409 and corrupted-reference 503 in `apps/api/app/modules/fleet/service.py`; invoke the foundational fresh-capability and scoped-replay guards after lock acquisition and before any result disclosure.
- [ ] T064 [US1] Implement `GET /api/v1/vehicles`, `GET /api/v1/vehicles/{vehicle_id}` and `POST /api/v1/vehicles` with thin FastAPI routes, the foundational protected-route dependencies, strict body/headers, 201/Location and stable original result in `apps/api/app/modules/fleet/routes.py`.
- [ ] T065 [US1] Implement accessible Vehicles list/search/detail and registration form with pending/empty/error/conflict/success states, semantic labels and keyboard focus in `apps/web/src/features/vehicles/VehiclesPage.tsx`, `apps/web/src/features/vehicles/VehicleRegistrationForm.tsx` and `apps/web/src/features/vehicles/VehicleDetailPage.tsx`.
- [ ] T066 [US1] Use one UUID submission key per validated attempt, preserve it and unchanged payload after uncertain responses, refresh tenant-scoped list after commit and show the creation time with an explicit display zone in `apps/web/src/features/vehicles/useVehicleRegistration.ts`.
- [ ] T067 [US1] Normalize and diff FastAPI-exported OpenAPI against `specs/001-vehicle-registration/contracts/openapi.json`, including UTF-16 extensions and replay status/error contract, in `apps/api/tests/integration/contracts/test_vehicle_openapi.py`. (gate: G-SQL)

---

## Phase 4: User Story 2 — Browse Without Registration Permission (P1)

**Goal**: Read-only dispatchers browse their own trucks but cannot register, even by direct URL/API; revoked access blocks new writes and replay.

**Independent test**: Seed a truck in A or B for a read-only member, verify browsing, direct route/API denial, and zero new rows after revocation. This uses its own fixtures and does not depend on the US1 browser test's data.

**Tests first**: Add the cases before the story's permission and UI changes; run them through the production auth path.

### Tests

- [ ] T068 [P] [US2] Implement UT-01 executable cases at `apps/api/tests/unit/test_vehicle_permissions.py::test_vehicle_create_requires_create_permission` using dispatchers, immutable request-context values; assert Exercise the production permission decision: only active read/create membership in the selected carrier permits create; read-only, revoked/inactive and role-name-only contexts deny..
- [ ] T069 [US2] Implement UT-04 executable cases at `apps/web/src/features/vehicles/__tests__/VehicleRegistrationForm.test.tsx` and `VehiclesPage.test.tsx` — permission/request states using dispatchers, controlled response/error promises; assert No enabled action for reader; loading, empty, forbidden, duplicate, unavailable are distinguishable; pending/failed save never appears successful..
- [ ] T070 [P] [US2] Implement IT-03 executable cases at `apps/api/tests/integration/fleet/test_vehicle_authorization.py::test_read_only_member_cannot_create_vehicle` using B reader, A reader, registration_payload; assert Own read succeeds, direct create 403, no inserted asset/vehicle/audit/receipt rows; forged role metadata has no effect.. (gate: G-SQL, G-PINS)
- [ ] T071 [P] [US2] Implement IT-04 executable cases at `apps/api/tests/integration/auth/test_request_identity.py::test_invalid_or_revoked_identity_is_denied`; `test_membership_and_retry_reauthorization` using identity_boundary, dispatchers, revoked_access; assert Missing/bad/expired/revoked credentials 401; inactive/revoked membership or absent verified tenant 403. New create and replay after permission loss both deny without fleet changes. Provider status outage is safe 503, not successful auth.. (gate: G-SQL, G-PINS, G-CLERK)
- [ ] T072 [P] [US2] Implement SB-02 executable cases at `tests/selenium/test_vehicle_permissions.py::test_read_only_dispatcher_cannot_register` using browser, A reader or B reader, own seeded truck; assert Own truck readable; no enabled registration action; direct /vehicles/new is forbidden and exposes no usable form; refresh/inspection finds no new truck. IT-03 covers direct HTTP bypass.. (gate: G-SQL, G-PINS)
- [ ] T073 [US2] Implement SB-05 executable cases at `tests/selenium/test_vehicle_permissions.py::test_permission_revoked_during_registration` using browser, A creator, revoked_access, inspect_db; assert Open valid form, remove create grant, submit; access error, no success and no persisted change.. (gate: G-SQL, G-PINS)

### Implementation

- [ ] T074 [US2] Hide the enabled registration action from read-only users, block direct `/vehicles/new` navigation with a nonusable form, and retain own read access in `apps/web/src/features/vehicles/VehicleRegistrationRoute.tsx` and `apps/web/src/features/vehicles/VehiclesPage.tsx`.
- [ ] T075 [US2] Surface revoked-access errors without success and retain correctable form values when permission changes mid-entry in `apps/web/src/features/vehicles/VehicleRegistrationForm.tsx`.

---

## Phase 5: User Story 3 — Keep Each Carrier's Trucks Private (P1)

**Goal**: All list/search/detail/create paths and browser caches are scoped to current verified carrier membership.

**Independent test**: Seed both A and B with distinct `TRK-001` records plus an A-only truck, then sign in as B. B sees its own truck, never sees A's unique truck or details, and carrier switching/logout clears old content. Fixtures do not rely on any prior story test.

### Tests

- [ ] T076 [P] [US3] Implement UT-05 executable cases at `apps/web/src/app/__tests__/TenantScope.test.tsx` — stale response cannot cross tenant or sign-out using scoped_web_state; assert Clear queries/draft/result on switch/logout, cancel pending request, then resolve an old list/save response; no old data reaches the new UI..
- [ ] T077 [P] [US3] Implement IT-05 executable cases at `apps/api/tests/integration/fleet/test_vehicle_authorization.py::test_cross_tenant_list_detail_and_creation_are_denied` using A-only truck, B reader, A creator; assert B list/search/count exclude A; B requesting A ID and unknown ID gets same safe 404; unauthorized carrier context 403; ownership body contradicting verified context 422; no cross-carrier rows.. (gate: G-SQL, G-PINS)
- [ ] T078 [P] [US3] Implement IT-09 executable cases at `apps/api/tests/integration/security/test_tenant_pool.py::test_pool_reuse_is_tenant_safe`; `test_failed_reset_discards_connection`; `test_tenant_safe_asset_fk`; `test_tenant_safe_retry_actor_fk` using one-slot runtime pool, A/B/no context, malformed text context, inspect_db; assert A→B→none→A yields scoped rows; missing/text tenant context gives no rows; wrong-tenant subtype/receipt actor FKs are rejected; retry-table reads/inserts also obey RLS; failed reset connection cannot be reused. API requests without context are 403.. (gate: G-SQL, G-PINS)
- [ ] T079 [P] [US3] Implement SB-03 executable cases at `tests/selenium/test_vehicle_tenant_isolation.py::test_other_carrier_cannot_see_created_vehicle` using browser, B reader, independently seeded A-only truck, carrier_pair; assert B finds its own TRK-001; A-only search empty; A detail address shows ordinary non-disclosing not-found; no A details appear.. (gate: G-SQL, G-PINS)
- [ ] T080 [US3] Implement SB-06 executable cases at `tests/selenium/test_vehicle_tenant_isolation.py::test_tenant_switch_and_signout_clear_vehicle_state` using browser, A/B member, A creator, B reader, scoped_web_state; assert Switch A→B, refresh/back; sign out A and sign in B in same browser; all prior A list/search/detail/save data absent, late responses ignored.. (gate: G-SQL, G-PINS)

### Implementation

- [ ] T081 [US3] Enforce verified X-Tenant-Id and tenant-scoped IDs in every list/search/detail/create repository call, return identical unknown/foreign 404 responses and reject spoofed body ownership in `apps/api/app/modules/fleet/routes.py` and `apps/api/app/modules/fleet/repository.py`.
- [ ] T082 [US3] Implement verified `GET /api/v1/me` membership discovery and selected-carrier state using the bounded bootstrap in `apps/api/app/modules/tenants/routes.py` and `apps/web/src/app/TenantScope.tsx`. (gate: G-CLERK)
- [ ] T083 [US3] Scope query keys to user+tenant, clear list/detail/form/key/result state on switch/logout, cancel and ignore late responses and revalidate history/pageshow in `apps/web/src/app/TenantScope.tsx` and `apps/web/src/lib/apiClient.ts`.

---

## Phase 6: Polish & Cross-Cutting Verification

**Purpose**: Run the agreed local/CI gates, preserve evidence, and document migration/backout and operator setup. Completion requires all three stories and their tests.

- [ ] T084 Run the SQL Server driver/TLS/UUID/DATETIME2/ROWVERSION/DECIMAL/Unicode and native-context proof on Linux amd64, including retry lock permissions and connection reset, and record results in `specs/001-vehicle-registration/quickstart.md`. (gate: G-PINS, G-SQL)
- [ ] T085 Run fresh base→0003, 0001→0003 and populated 0002→0003 Alembic upgrades plus schema/drift/grant/RLS checks on actual SQL Server; keep 17-table reference rehearsal on a separate disposable database and record evidence in `specs/001-vehicle-registration/quickstart.md`. (gate: G-SQL)
- [ ] T086 Run `make test-unit`, `make test-integration`, `make test-selenium` and `make test` locally, including PowerShell `make PYTHON=python` and WSL guidance; capture reports, case counts and failures in `specs/001-vehicle-registration/quickstart.md`. (gate: G-PINS, G-SQL)
- [ ] T087 Verify CI `unit`, `integration` and `selenium` jobs run the same root targets, deliberately fail one scaffold assertion then restore it, and record exact commit SHA, JUnit counts/skips and links in `specs/001-vehicle-registration/test-plan.md`. (gate: G-PINS, G-SQL)
- [ ] T088 Run a real trusted Clerk development sign-in/revocation/outage smoke and record the ADR-004 approval evidence and limitations in `docs/architecture-notes.md`. (gate: G-CLERK)
- [ ] T089 Check accessibility, keyboard focus, explicit time zone, sanitized errors/logs, service latency and browser screenshot redaction against all three story journeys; record findings in `specs/001-vehicle-registration/quickstart.md`. (gate: G-PINS, G-SQL)
- [ ] T090 Document explicit 0001→0002→0003 migration order, readiness, nonexpiring receipt retention, populated-database forward fix/rollback limits and Windows setup in `specs/001-vehicle-registration/quickstart.md` and `docs/database/migration-roadmap.md`. (gate: G-SQL)
- [ ] T091 Reconcile generated API schemas, feature acceptance references and actual changed-case evidence with `specs/001-vehicle-registration/contracts/openapi.json`, `specs/001-vehicle-registration/spec.md` and `specs/001-vehicle-registration/test-plan.md`.

## Dependencies & Execution Order

### Phase Dependencies

1. **Setup (T001–T012)**: T001 verifies the recorded review decisions and any remaining gate. T002–T005 establish the relevant external gates; T006–T012 scaffold the shared command, container and CI surface.
2. **Foundation (T013–T047)**: Independent model, vector and error work can begin after its own scaffold prerequisites; it does not wait for unrelated gates. T014–T031 depend on T013. T032 depends on the 17 foundation model contracts; T033 follows T032; T034 follows T033 and the existing `core.tenants`/`iam.memberships` targets. T035 follows migrations; T036 needs the SQL driver and RLS design; T037 needs G-CLERK; T038 follows T033/T037. T040–T043 establish isolated fixtures; T044 follows client tooling pins. T045 follows T038 and defines the fresh post-lock capability check; T046 follows T037–T039 and defines route dependencies; T047 follows T030/T034/T038/T045 and defines scoped retry-result authorization. These three shared guards and T034 must be complete before US1 tests or implementation claim completion.
3. **US1 (T048–T067)**: Depends on T034 and T045–T047, as well as the relevant scaffold/fixtures. Write T048–T058 tests first. Implement T059/T060 validation, T061 replay identity, T062 repository, T063 transaction service consuming T045/T047, T064 routes consuming T046, T065/T066 UI and T067 contract drift. SQL/browser assertions require G-SQL and G-PINS.
4. **US2 (T068–T075)**: Depends on shared foundational authorization and US1 read/create surfaces for the complete journey. Test fixtures are independent of US1 test data. Write T068–T073 first; T074–T075 finish the read-only and revoked-access UI.
5. **US3 (T076–T083)**: Depends on shared foundational tenant/replay scope and US1 list/detail/create surfaces for the complete journey. Test fixtures are independent of US1 test data. Write T076–T080 first; tenant probing and browser cache tasks complete the story. G-CLERK applies to T082.
6. **Verification (T084–T091)**: Depends on all three stories. Record actual local/CI outcomes and reviewed backout constraints; a task is not complete because a static kit check passed.

### Story Completion Order

- **US1** is the MVP: registration, persisted refresh/read, UTF-16 validation and durable replay. Finish its independent test before calling the feature usable.
- **US2** and **US3** both use the shared US1 API/UI surfaces but have independent A/B/reader/revoked fixtures; they may be developed in parallel after the foundation/US1 interfaces settle. All three P1 stories are required for Feature 001 acceptance.
- Tenant isolation, current capability checks, post-lock reauthorization and scoped retry-result checks are foundational on every US1 route. US2/US3 add their explicit denial, probing and cache scenarios.

### Parallel Opportunities

- **Foundation**: T014–T031 define separate table model modules; T040 identity fixtures and T042 Unicode vectors can proceed while SQL migrations are developed after their shared scaffold exists.
- **US1**: T048 (API unit), T049 (web unit), T052–T053 (concurrency/replay), T055 (migration contract) and T058 (browser states) use distinct test files. T059 API validation and T060 browser validation use separate implementation files.
- **US2**: T068 (permission unit), T070 (fleet authorization integration), T071 (identity integration) and T072 (browser permission) use distinct test files. T073 shares the browser permission file with T072 and is sequenced.
- **US3**: T076 (web cache unit), T077 (fleet authorization integration), T078 (pool security integration) and T079 (browser tenant isolation) use distinct test files. T080 shares T079's file and is sequenced.

## Implementation Strategy

1. Use the recorded T001 scope verification and start independent scaffold/model work while T002–T005 establish Clerk, pins and SQL evidence. Do not claim a gate passed until evidence is recorded.
2. Build the shared scaffold, 17-table base migration, security revision and single retry-table revision. Validate exact schema and RLS/grants on real SQL Server.
3. Develop US1 as the first full vertical slice; run its unit, SQL integration and browser journey with independent fixtures.
4. Add US2 denial/revocation and US3 carrier isolation/cache behavior, each with its assigned tests.
5. Run the same `make test-unit`, `make test-integration`, `make test-selenium` and `make test` targets locally and in PR CI; keep the 17-table reference rehearsal separate from the 18-table application migration suite.
6. Stop at review with recorded evidence and remaining risks. Publishing/deployment needs separate authorization.

## Case Coverage Index

| Story | Unit | SQL Server integration | Selenium | Total |
| --- | --- | --- | --- | ---: |
| US1 | UT-02, UT-03 | IT-01, IT-02, IT-06, IT-07, IT-08, IT-10 | SB-01, SB-04, SB-07 | 11 |
| US2 | UT-01, UT-04 | IT-03, IT-04 | SB-02, SB-05 | 6 |
| US3 | UT-05 | IT-05, IT-09 | SB-03, SB-06 | 5 |
| **Total** | **5** | **10** | **7** | **22** |

Every constrained model field has an explicit `data-model.md#<entity>` and `Entity.field`
citation in its implementing model task T014–T031. Service validation and retry fields are
cited again in T059–T061 and T047. The canonical definitions remain in
[data-model.md](data-model.md); task prose does not replace the SQL contract.
