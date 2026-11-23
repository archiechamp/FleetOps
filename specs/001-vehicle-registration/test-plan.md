# Feature 001 — Test Plan and DEV-008 Traceability

**Date**: 2026-11-23
**Status**: Review draft. All paths/commands below are planned scaffold deliverables.
**Scope**: UT-01–05, IT-01–10 and SB-01–07 from [spec.md](spec.md).
**Acceptance gate**: B-001/B-002 are resolved in the revised plan. Generate every expanded case
alongside implementation; no required case may be skipped, xfailed or reported green without execution.

## Shared Runners and Required Checks

| Code | Root command on Linux/WSL | Native PowerShell equivalent | Required PR check | Runner and output |
| --- | --- | --- | --- | --- |
| U | `make test-unit` | `make PYTHON=python test-unit` | `unit` | pytest in apps/api/tests/unit and Vitest/React Testing Library in apps/web/src; separate JUnit files and combined nonzero failure propagation |
| I | `make test-integration` | `make PYTHON=python test-integration` | `integration` | pytest in apps/api/tests/integration against real migrated SQL Server; JUnit and migration/schema evidence |
| S | `make test-selenium` | `make PYTHON=python test-selenium` | `selenium` | pytest + Selenium in tests/selenium against built web/API/SQL Server; JUnit, sanitized screenshots and diagnostics on failure |
| All | `make test` | `make PYTHON=python test` | All three separate checks | Run U/I/S, preserve each suite report and return nonzero if any fails |

The Makefile delegates to planned `tools/run_tests.py` with suite unit/integration/selenium/all.
Use PYTHON=python3 by default and permit the explicit Windows override. The runner uses argument
lists, pathlib and the Docker CLI on the host; no Bash helpers, shell string interpolation,
Docker socket mounts or host SQL/Chrome dependency. VS Code tasks call these same root commands.

## Fixtures

| Fixture | Definition and isolation |
| --- | --- |
| run_context | Unique lowercase Compose project, per-suite database/volume/network and run ID. Synthetic records only. Each test gets a unit number no longer than the reviewed limit. |
| carrier_pair | A and B with different carrier/asset/vehicle UUIDs but each with TRK-001. Both own records must remain distinguishable. Match the reference fixture intent; UUID constants are not assumed to equal asset/vehicle IDs. |
| dispatchers | A creator: read/create. B reader: read only. A reader: read only. Separate A/B member: read in both and create only where explicitly granted. Separate inactive/revoked variants. Every test gets its own identity/membership records or reset isolated DB. |
| registration_payload | Fictional make/model, integer year, ownership enum, fresh unit and UUID key. Shared tests/fixtures/vehicle_registration_vectors.json carries UC-01–09 from the Unicode contract; use isolated units/DB state so length cases cannot become duplicate cases. |
| identity_boundary | Run-scoped signing key/JWKS, expected issuer/authorized party/session/subject and controlled active/revoked provider status. Real token verifier and membership authorization execute; signing material never enters reports or source. |
| real_application | Real FastAPI route/dependency/service/repository path, runtime SQL role, committed transactions and bounded HTTP client. No overrides of authorization or repositories. |
| inspect_db | Separate test-assertion identity can inspect isolated A/B state. It is never the application identity. Setup/teardown roles own migrations and fixtures; ordinary assertions first verify application behavior through runtime credentials. |
| revoked_access | Controlled fixture connection changes membership status or role grant between form open and submission. Provider boundary independently revokes a session for 401 tests. No public administrative test endpoint. |
| concurrency_barrier | Independent authenticated requests and SQL connections; parameterize distinct keys/same unit and identical keys/same or changed payload. Synchronize at controlled transaction boundaries without serializing the test; exercise separate API processes sharing SQL. |
| lost_response_restart | Commit via real API, capture response only in the test observer while dropping it to the caller, preserve SQL state, replace the API process and retry key/payload. Compare original 201/body/Location and exact four-row counts, with no process-memory reuse. |
| fault_boundary | Controlled failure after each asset/vehicle/audit/receipt insert and immediately before commit, plus precommit process termination and lock timeout/cancellation. Use internal test seams/infrastructure, never production fault routes. HTTP delay/outage stays at the transport boundary. |
| browser | Fresh RemoteWebDriver session per test, headless Chrome, default and keyboard-focused coverage. Always quit in finally. Explicit waits target rendered state or persisted result, never fixed sleeps. |
| scoped_web_state | Deferred HTTP responses and old-session results to exercise logout/tenant-switch invalidation. In unit tests use boundary request doubles; Selenium still reaches the actual application. |
| own_empty_fleet | Separate per-test carrier/member or cleared test fixture with no trucks, plus independent no-match search. Seed A-only trucks within the case requiring them. |

All integration/Selenium setup is committed before application requests begin. Clean each suite's
exact project resources in an always-run finalizer; never delete a shared developer database.
Test datasets for U/I/S are independent. Runtime cannot update/delete audit rows; inspection must
prove one success audit and one completed retry receipt per committed create, none for rollback,
and no new event/receipt for replay. Runtime cannot update/delete receipts; setup alone may age
a synthetic receipt's created_at beyond 30 days to prove that age does not expire it.

## Unit Cases

| Case | Proposed file and executable case | Fixtures | Action / observable assertions | Command / CI | Scope gate |
| --- | --- | --- | --- | --- | --- |
| UT-01 | `apps/api/tests/unit/test_vehicle_permissions.py::test_vehicle_create_requires_create_permission` | dispatchers, immutable request-context values | Exercise the production permission decision: only active read/create membership in the selected carrier permits create; read-only, revoked/inactive and role-name-only contexts deny. | U / unit | Ready after review |
| UT-02 | `apps/api/tests/unit/test_vehicle_validation.py::test_registration_field_boundaries`; `test_unit_number_normalization`; `apps/api/tests/unit/test_vehicle_idempotency.py::test_canonical_registration_digest` | registration_payload, shared UC-01–09, canonical hash vectors | Strict field/year/ownership checks; BMP/supplementary/combining boundaries, exact trim and surrogate rejection. Stable hash for normalized input/JSON formatting; changed normalized values or display case change hash; 32-byte digest and scoped key/reference grammar. | U / unit | Ready after review |
| UT-03 | `apps/web/src/features/vehicles/__tests__/VehicleRegistrationForm.test.tsx` — missing/over-limit fields; `apps/web/src/features/vehicles/__tests__/vehicleValidation.test.ts` — shared UTF-16 vectors | user keyboard, request spy, UC-01–09 | Missing/blank/over-limit/malformed input has linked accessible error, retains typed value and sends no POST. Exact-limit supplementary values count as 30/80 units and submit unchanged. Shared normalization agrees with API. | U / unit | Ready after review |
| UT-04 | `apps/web/src/features/vehicles/__tests__/VehicleRegistrationForm.test.tsx` and `VehiclesPage.test.tsx` — permission/request states | dispatchers, controlled response/error promises | No enabled action for reader; loading, empty, forbidden, duplicate, unavailable are distinguishable; pending/failed save never appears successful. | U / unit | Ready after review |
| UT-05 | `apps/web/src/app/__tests__/TenantScope.test.tsx` — stale response cannot cross tenant or sign-out | scoped_web_state | Clear queries/draft/result on switch/logout, cancel pending request, then resolve an old list/save response; no old data reaches the new UI. | U / unit | Ready after review |

## FastAPI / SQL Server Integration Cases

| Case | Proposed file and executable case | Fixtures | Action / observable assertions | Command / CI | Scope gate |
| --- | --- | --- | --- | --- | --- |
| IT-01 | `apps/api/tests/integration/fleet/test_vehicle_registration.py::test_register_and_read_persisted_vehicle` | carrier_pair, A creator, registration_payload, real_application, inspect_db | 201 create, then independent GET/list; same ID/details, one A asset/vehicle pair, one audit and one scoped complete receipt with verified actor/UTC time; zero B changes. | I / integration | Ready after review |
| IT-02 | `apps/api/tests/integration/fleet/test_vehicle_registration.py::test_duplicate_unit_is_scoped_to_tenant` | carrier_pair, A creator, two keys | First fresh create 201, distinct-key normalized duplicate 409, no second row; both seeded TRK-001 resolve to their own distinct records. Cover case/whitespace and collation vectors. | I / integration | Ready after review |
| IT-03 | `apps/api/tests/integration/fleet/test_vehicle_authorization.py::test_read_only_member_cannot_create_vehicle` | B reader, A reader, registration_payload | Own read succeeds, direct create 403, no inserted asset/vehicle/audit/receipt rows; forged role metadata has no effect. | I / integration | Ready after review |
| IT-04 | `apps/api/tests/integration/auth/test_request_identity.py::test_invalid_or_revoked_identity_is_denied`; `test_membership_and_retry_reauthorization` | identity_boundary, dispatchers, revoked_access | Missing/bad/expired/revoked credentials 401; inactive/revoked membership or absent verified tenant 403. New create and replay after permission loss both deny without fleet changes. Provider status outage is safe 503, not successful auth. | I / integration | Ready after review |
| IT-05 | `apps/api/tests/integration/fleet/test_vehicle_authorization.py::test_cross_tenant_list_detail_and_creation_are_denied` | A-only truck, B reader, A creator | B list/search/count exclude A; B requesting A ID and unknown ID gets same safe 404; unauthorized carrier context 403; ownership body contradicting verified context 422; no cross-carrier rows. | I / integration | Ready after review |
| IT-06 | `apps/api/tests/integration/fleet/test_vehicle_concurrency.py::test_concurrent_duplicate_registration_commits_once` | concurrency_barrier, A creator, fresh unit, inspect_db | Independent connections and keys race: one 201, one 409, exactly one complete pair, success audit and receipt; losing key leaves no receipt. Repeat enough times to expose race, with per-attempt isolated units. | I / integration | Ready after review |
| IT-07 | `apps/api/tests/integration/fleet/test_vehicle_idempotency.py::test_registration_replays_after_restart`; `test_key_payload_and_actor_scope`; `test_concurrent_key_replays_once`; `test_receipt_retention_and_missing_reference` | lost_response_restart, concurrency_barrier, second authorized actor/carrier, inspect_db | Original 201/body/Location after restart; one asset/vehicle/audit/receipt. Same-key race yields identical successes; changed-valid-payload race yields one success/one 409. Current auth on every replay; actor/tenant scope cannot leak original. Fixed canonical hash, sentinel expiry, aged receipt still replayable, missing/corrupt reference fails 503 without create. | I / integration | Ready after review |
| IT-08 | `apps/api/tests/integration/fleet/test_vehicle_atomicity.py::test_invalid_registration_has_no_effect`; `test_partial_registration_rolls_back`; `test_precommit_process_loss`; `apps/api/tests/integration/fleet/test_vehicle_registration.py::test_utf16_boundary_round_trip` | UC-01–09, raw malformed JSON strings, fault_boundary, inspect_db | 422/zero rows for invalid fields or UTF-16 overflow. Valid BMP/supplementary/mixed boundaries return/read/replay unchanged; DATALENGTH/2 is exact. Failure after each of four inserts or precommit process loss leaves zero rows; same-key retry can then succeed once. Lock failure cannot commit anything. | I / integration | Ready after review |
| IT-09 | `apps/api/tests/integration/security/test_tenant_pool.py::test_pool_reuse_is_tenant_safe`; `test_failed_reset_discards_connection`; `test_tenant_safe_asset_fk`; `test_tenant_safe_retry_actor_fk` | one-slot runtime pool, A/B/no context, malformed text context, inspect_db | A→B→none→A yields scoped rows; missing/text tenant context gives no rows; wrong-tenant subtype/receipt actor FKs are rejected; retry-table reads/inserts also obey RLS; failed reset connection cannot be reused. API requests without context are 403. | I / integration | RLS/bootstrap spike required |
| IT-10 | `apps/api/tests/integration/database/test_foundation_migrations.py::test_fresh_and_previous_revision_upgrade`; `test_foundation_contract_and_runtime_grants`; `test_vehicle_provenance`; `test_idempotency_schema_and_grants`; `test_nvarchar_rejects_overflow` | fresh DB, 0001/0002 baselines, populated 0002 fixture, runtime/seed/migrate roles | Exact 18-domain-table/166-column/42-FK contract; five additional retry predicates (50 total); defaults/UQs/FKs/BINARY(32)/NVARCHAR(150)/expiry/nullability and no extra checks/indexes. Verify runtime key locks and SELECT/INSERT only; update/delete/DDL denied. UTC/UUID/ROWVERSION/DECIMAL/Unicode round trips; direct SQL UTF-16 overflow fails with ANSI_WARNINGS ON, no truncated row. Immutable creation provenance; replay adds no event/receipt. | I / integration | Ready after review |

IT-10 tests empty→0003, 0001→0003 and populated 0002→0003 when revisions are created; no previous
application release exists yet. Verify that 0003 leaves existing truck data and all 17 contracts
unchanged and does not backfill invented receipts. The reference SQL rehearsal stays on a different
empty database and still verifies only the original 17-table baseline; report it separately. ROWVERSION stale-update behavior is a controlled database assertion, not authorization
to add public update/delete routes. The final API test environment must match the Linux driver image.

## Selenium Cases

| Case | Proposed file and executable case | Fixtures | Action / observable assertions | Command / CI | Scope gate |
| --- | --- | --- | --- | --- | --- |
| SB-01 | `tests/selenium/test_vehicle_registration.py::test_dispatcher_registers_vehicle` | browser, A creator, registration_payload | Sign in, open Vehicles, register valid truck, wait for success, refresh/search and open result; exactly one truck and all submitted details match. | S / selenium | Ready after review |
| SB-02 | `tests/selenium/test_vehicle_permissions.py::test_read_only_dispatcher_cannot_register` | browser, A reader or B reader, own seeded truck | Own truck readable; no enabled registration action; direct /vehicles/new is forbidden and exposes no usable form; refresh/inspection finds no new truck. IT-03 covers direct HTTP bypass. | S / selenium | Ready after review |
| SB-03 | `tests/selenium/test_vehicle_tenant_isolation.py::test_other_carrier_cannot_see_created_vehicle` | browser, B reader, independently seeded A-only truck, carrier_pair | B finds its own TRK-001; A-only search empty; A detail address shows ordinary non-disclosing not-found; no A details appear. | S / selenium | Ready after review |
| SB-04 | `tests/selenium/test_vehicle_registration.py::test_keyboard_validation_duplicate_and_correction`; `test_utf16_boundary_validation_and_refresh` | browser, A creator, duplicate/fresh units, UC-01–07/09 | Keyboard missing/duplicate/correction journey, then actual form entry at BMP, supplementary and mixed 30/80 limits and one-unit-over. Overflow remains visible, accessible error/no POST or save; correction succeeds and exact text survives refresh/detail. Exercise make and model independently. | S / selenium | Ready after review |
| SB-05 | `tests/selenium/test_vehicle_permissions.py::test_permission_revoked_during_registration` | browser, A creator, revoked_access, inspect_db | Open valid form, remove create grant, submit; access error, no success and no persisted change. | S / selenium | Ready after review |
| SB-06 | `tests/selenium/test_vehicle_tenant_isolation.py::test_tenant_switch_and_signout_clear_vehicle_state` | browser, A/B member, A creator, B reader, scoped_web_state | Switch A→B, refresh/back; sign out A and sign in B in same browser; all prior A list/search/detail/save data absent, late responses ignored. | S / selenium | Ready after review |
| SB-07 | `tests/selenium/test_vehicle_states.py::test_empty_loading_and_unavailable_states` | browser, own_empty_fleet, fault_boundary | Empty own fleet differs from no matches and outage; delayed list/save stays pending; unavailable request has retry/error state and no false success. | S / selenium | Ready after review |

## CI Orchestration and Evidence

- Required named checks unit/integration/selenium each use the matching root command and fail
  independently. Backend-only changes still run all three. Runs use Linux x86-64 and pinned
  browser/driver pairing; no arm64 SQL test substitution.
- Host runner builds the required pinned images, creates a unique Compose project, waits for
  SQL/API/web/browser readiness with a timeout, bootstraps isolated credentials, runs Alembic,
  seeds two synthetic carriers and starts actual test processes. Web serves a production build;
  Selenium uses http://web:8080, API uses sqlserver DNS, and browser control uses
  http://selenium:4444. Only local interactive web access binds to loopback.
- The runner records its exact owned project/database/resources before any teardown. Finalizers
  preserve logs/JUnit before deleting only test-owned resources, including on setup failure.
  No cleanup targets a developer persistent stack or assumes all Compose volumes are disposable.
- Default workflow permissions contents: read; untrusted PRs receive no provider/production
  secrets or registry publishing credentials. Check OpenAPI drift, lint/type, secret/dependency
  scanning, image/build smoke as additional gates from the delivery specification.
- Collect JUnit per backend-unit, web-unit, integration and Selenium suite, plus counts,
  failures/skips, commit SHA, revision, image identifiers, driver/browser versions and run link.
  Screenshots/HTML/console diagnostics contain only synthetic data and redact tokens.
- A missing service, failed migration, no collected cases, skipped/xfail required cases or
  mismatched report/exit status fails the check. All expanded retry and Unicode cases are required;
  OpenAPI extension drift and shared-vector divergence fail the applicable checks.
  A controlled deliberately failing assertion proves exit propagation;
  restore it before the recorded passing run.
- Core Gate 0 tests include driver/TLS/pool/migration and real Clerk smoke after provider setup.
  Full Gate 0 worker/AI-streaming/staging rollout remains separate approved work; Feature 001
  must not claim those broader gates passed.
