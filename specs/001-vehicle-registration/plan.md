# Implementation Plan: Feature 001 — Vehicle Registration

**Branch**: No Git branch exists. setup-plan.ps1 returned the feature-context label
`001-vehicle-registration` from .specify/feature.json.

**Date**: 2026-11-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-vehicle-registration/spec.md`.

**Status**: Feature 001 scope and B-001/B-002 design decisions approved for implementation;
task ordering is being reconciled before the first complete story. Design-level constitution
checks pass; runtime proof remains pending. External G-CLERK, G-PINS and G-SQL gates in
[tasks.md](tasks.md) apply only to the work and acceptance evidence that need them.

## Summary

Deliver a small vehicle registration/read workflow for AUTH-01, AUTH-02, the first FLT-01 slice
and DEV-008. An authorized dispatcher creates a truck and sees it after refresh; a read-only
dispatcher cannot create; another carrier cannot see or address the truck. Use a React SPA,
typed FastAPI services and SQLAlchemy repositories with Alembic migrations against SQL Server.

Database work is the **unchanged 17-table foundation plus one explicitly authorized table**:
the kit's proposed integration.idempotency_keys. [Data model](data-model.md) gives all exact
contracts: 18 domain tables, 166 columns and 42 FKs. The addition's 12 columns and 3 FKs require
only existing core.tenants and iam.memberships; no further domain dependencies or column changes.
Alembic bookkeeping and reviewed security objects remain infrastructure over this subset.

### Resolved Review Decisions

| ID | User direction | Revised disposition |
| --- | --- | --- |
| B-001 | Plan a narrow addition using the kit's integration.idempotency_keys. | RESOLVED: adopt that exact table, plus tenant RLS/grants. A typed vehicle reference and hash-verified retry payload reproduce the original 201 body/Location; truck/audit/receipt commit together. |
| B-002 | Use UTF-16 code units for NVARCHAR field limits. | RESOLVED: FR-004, browser/API/OpenAPI/database validation and unit/integration/Selenium boundary criteria now use 30/80 code units after the same trim. Supplementary characters count as two; no truncation. |

### Remaining Decisions and Evidence Gates

| ID | Remaining item | Before / disposition |
| --- | --- | --- |
| G-001 | Clerk ADR-004; actual driver/TLS/RLS, SQL application-lock permissions and recovery behavior; compatible dependency/image pins. | Design review and scoped Gate 0 proof before the feature implementation is accepted. These are unexecuted evidence gates, not unresolved B-001/B-002. |
| R-007 | A future finite receipt retention/deletion policy and production lifecycle approval. | Not needed for this no-purge slice: expires_at uses 9999-12-31T23:59:59.999 UTC and receipts are retained. Product/security must approve any later finite window or cleanup with FR-008 changes; the kit's proposed 30 days is not silently adopted. |
| R-008 | Future editable/deletable vehicles or a larger POST response. | Outside Feature 001. Preserve immutable reference/creator/creation-time and v1 response reconstruction, or review immutable response storage before introducing those changes. |

All 22 acceptance groups remain required, expanded where necessary for replay races, atomicity
and supplementary Unicode. No required scenario is skipped or replaced by a duplicate-only test.

## Technical Context

**Language/Version**: Python 3.12 baseline; strict TypeScript; Node.js 24 LTS proposed for the
web build. Pin compatible package patches and container digests after the Gate 0 spike.

**Primary Dependencies**: React, Vite, Tailwind; FastAPI, Pydantic v2, SQLAlchemy 2.x, Alembic;
pyodbc with Microsoft ODBC Driver 18 as first driver candidate; Clerk React/Python SDKs subject
to ADR-004 approval. Use an OpenAPI-generated/validated typed web client and tenant-scoped query
state. No AI SDK, model/provider call or operational AI tool is introduced by this feature.

**Storage**: SQL Server 2022 Developer on Linux amd64 for development/CI; 17-table foundation
plus integration.idempotency_keys, UTC DATETIME2(3), UNIQUEIDENTIFIER, ROWVERSION, BINARY(32)
and existing DECIMAL definitions.
Production SQL hosting remains provisional. No Redis/file/process replay store substitutes for SQL.

**Testing**: pytest unit and FastAPI/SQL Server integration; Vitest + React Testing Library;
pytest + Selenium WebDriver/Chrome through the built SPA. Required root commands test-unit,
test-integration, test-selenium and aggregate test; required PR checks unit/integration/selenium.
See [test-plan.md](test-plan.md) for every file, fixture, case, command and check mapping.

**Target Platform**: Windows PowerShell or WSL2 developers, Docker Desktop Linux x86-64;
GitHub Actions Linux x86-64. App dependencies and Chrome run in pinned Linux containers.
A supported remote amd64 environment is required for ARM hosts.

**Project Type**: Web application monorepo, FastAPI modular monolith, feature-focused SPA.

**Performance Goals**: Inherit root spec's proposed p95 <500 ms for ordinary indexed reads at
pilot load, excluding third-party identity calls. Bounded pages (50 default/100 max), bounded
pool and external timeouts. Capture actual latency/query plans before claims; no benchmark exists.

**Constraints**: Verified server membership/capability on every read/create/replay, tenant-safe
FKs/RLS defense in depth, no schema changes at request/startup, runtime/migration/seed privilege
separation, accessible states and no cached tenant leakage. Scope excludes edit/delete/import,
trailers, dispatch, GPS, finance, documents and Copilot. No publishing/deployment is authorized.

**Scale/Scope**: Initial carrier profile is 10–150 power units, from root spec. Test data uses
two synthetic carriers, separate read/create/read-only/multi-carrier identities and independent
unit numbers. Three P1 journeys; 12 feature requirements; 5 unit, 10 integration, 7 browser cases.

## Constitution Check

The prior review found a scope conflict and ambiguous string semantics. The user now explicitly
authorizes the sole table addition and UTF-16 interpretation. Post-revision design checks pass;
this is not an execution/acceptance pass or authorization to begin implementation.

| Principle / gate | Prior finding | Revised design evaluation and evidence |
| --- | --- | --- |
| I. Tenant isolation | Required across auth, lists, details, create, retry and caches. | PASS at design level: verified RequestContext, scoped repositories, tenant FKs/RLS, actor-scoped receipts and fresh replay authorization. UT-01/05, IT-03–05/07/09 and SB-02/03/05/06; runtime proof pending. |
| II. SQL Server/migrations | Original scope was 17 foundation tables. | PASS: user-authorized exact eighteenth table, closed dependencies, no changed existing columns. Alembic 0003 adds table/RLS/grants; actual SQL checks required. UTF-16 contract resolved. |
| III. Read-only AI | AI is outside Feature 001. | PASS: no model tools, arbitrary SQL or AI writes; future Copilot remains constrained. |
| IV. DEV-008 | Tests and command/CI scaffold must ship with feature code. | PASS for design: all 22 groups mapped, including durable retry and UTF-16 vectors. All suites and CI results remain unexecuted. |
| V. Operational integrity | FR-008 previously had no approved durable store. | PASS at design level: one transaction for asset/vehicle/audit/receipt; payload-bound replay after restart, concurrent-key locking and fail-closed integrity checks. IT-01/06–08/10. |
| Canonical scope and review | No general CRUD or unrelated module expansion. | PASS: read/create only; one explicit foundation exception, no migration execution or production change. |
| Evidence honesty | No app, Alembic history or CI presently exists. | PASS: static evidence distinguished from pending runtime/CI proof. |

## Project Structure

### Documentation (this feature)

```text
specs/001-vehicle-registration/
├── spec.md
├── checklists/requirements.md
├── plan.md
├── research.md
├── data-model.md
├── test-plan.md
├── quickstart.md
└── contracts/
    ├── README.md
    └── openapi.json
```

The spec/checklist and [tasks.md](tasks.md) incorporate both user-directed decisions. The
active feature pointer remains independent of a Git branch.

### Source Code (repository root)

The following is proposed structure, not existing source:

```text
apps/
├── web/
│   └── src/
│       ├── app/                    tenant selection, identity session, cache lifetime
│       ├── features/vehicles/      list, registration, detail, accessible states
│       └── lib/                    typed API client and transport
└── api/
    ├── app/
    │   ├── core/                   identity/context, SQL sessions, errors, config, telemetry
    │   └── modules/
    │       ├── tenants/            bounded membership/bootstrap query boundary
    │       └── fleet/              schemas, routes, service, repository, foundation models
    ├── alembic/                    reviewed foundation/security revisions only
    └── tests/
        ├── unit/
        └── integration/
packages/api-contracts/             client generated/validated against approved OpenAPI
tests/
├── fixtures/                       synthetic tenants and signed identity boundary
└── selenium/
tools/run_tests.py                  host-side cross-platform Compose test orchestration
Makefile                           same root targets locally and in CI
compose.yaml                       local app and explicit bootstrap/migrate/seed jobs
compose.test.yaml                  isolated suites/identity boundary/Chrome
.vscode/                           tasks invoking the same root commands
.github/workflows/ci.yml            unit, integration, selenium and supporting quality gates
```

**Structure Decision**: Keep thin routes, typed services and tenant-bound repositories in the
selected FastAPI monolith. React uses one shared typed client; no direct browser SQL access.
Do not scaffold empty modules, a second frontend framework or a placeholder worker. Broader
Gate 0 worker/queue, AI streaming, staging publication and rollback exercises remain separate
approved scope; Feature 001 does not certify completion of the entire project Gate 0.

## Complexity Tracking

| Approved scope exception / design constraint | Why needed | Boundary |
| --- | --- | --- |
| One table beyond the original foundation | FR-008 needs durable actor-scoped key/hash/result linkage. | User-authorized integration.idempotency_keys only; original 17 contracts and global foundation flags unchanged. |
| Reference-based original response | Existing response_reference is NVARCHAR(150), not a response blob. | Hash-verified canonical input plus immutable vehicle identity/time reconstruct v1; no audit overload, response column or hidden later-module dependency. |

## Phase 0 — Research Result

[research.md](research.md) records technology, SQL driver/pool/TLS, RLS bootstrap, identity
revocation, permission naming, CI identity fixtures and Windows/Selenium decisions with primary
documentation references. Unknowns are classified as concrete proposed choices or explicit
review/evidence gates; none is hidden behind an unexplained placeholder.

The database-kit verifier passed. Metadata/references are internally consistent and dependency
closed. The approved table addition resolves the storage design, not SQL execution or driver/auth
compatibility. Static reference verification still reports the unchanged 17-table baseline.

## Phase 1 — Review Design

### Request and UI Flow

1. Typed identity adapter acquires a current token. FastAPI verifies credentials and active
   provider session, then uses the bounded bootstrap query to resolve current membership and
   exact fleet.vehicle.read/create capabilities. No client role/tenant field grants access.
2. GET /me lists only the verified user's authorized memberships. Selecting a carrier is a
   claim carried in X-Tenant-Id; server verification precedes tenant DB session creation.
3. Vehicles lists/searches only that carrier's records; detail IDs are resolved in the same
   scope. Unknown and foreign IDs have identical non-disclosing 404 semantics.
4. Create input contains only unit/make/model/year/ownership. The service supplies tenant,
   current membership actor, TRACTOR reference and carrier currency. A transaction-owned SQL
   lock serializes each tenant/member/key; hash mismatch yields 409. First success commits
   asset, vehicle, audit and retry receipt together. Authorized same-key/payload replay returns
   the original 201/body/Location, including after restart, with no additional business write.
   Different-key unit conflicts roll back the entire attempt. See the exact
   [durable replay protocol](data-model.md#transaction-and-provenance).
   UI/API use the same post-trim UTF-16 limits and preserve invalid input for correction.
5. Render success only after commit, then refetch current scoped records. Refresh must recover
   persisted state. Read-only users have no enabled create action, and direct create is still
   rejected server-side. Switch/logout clears cache, form/key/result state and ignores late
   responses; history navigation revalidates the scope.
6. Trace request/correlation IDs, latency, safe error codes, denied capabilities and create/conflict
   counts. Audit stores verified creator and minimal IDs; logs never contain tokens, credentials,
   full request payloads or raw provider/SQL errors.

See [contracts/README.md](contracts/README.md) for UI states, authorization order and replay
semantics, and [contracts/openapi.json](contracts/openapi.json) for typed request/response schemas.

### Database and Security Delivery

The migration set contains the five foundation schemas/17 tables plus integration.idempotency_keys
in the integration schema. Proposed Alembic revisions keep 0001 foundation and 0002 security
separate from 0003_vehicle_registration_idempotency (new table, RLS coverage and runtime grants).
Create all tables before actor/self-referential FKs; preserve every existing constraint/index.
Seed governed references separately from synthetic dev/test identities. Never apply the full target
or reference SQL as a second application migration mechanism.

Use restricted runtime, bootstrap-execute, migration and test/setup roles. Runtime has only
needed reference reads and tenant-scoped asset/vehicle reads/inserts plus audit inserts.
Add only SELECT/INSERT on the retry table and runtime-role transaction-lock access. RLS expands
from nine/45 to ten tenant tables/50 predicates after actual pool validation; global identity/tenant
catalogs remain behind the bounded bootstrap. Review the explicit security-definer principal
exception and forbid caller impersonation/DDL. Bind native UUID tenant context, clear on every
pool path and invalidate failed resets. Details and exact contract are in [data-model.md](data-model.md).

No destructive production migration or live deployment is proposed. Fresh application migration,
0001→head and populated 0002→0003 upgrades, schema drift and separate 17-table reference rehearsal
are required. The application migration inventory must separately verify the eighteenth table. Future release
backout needs compatible images/schema and approved recovery; do not blindly downgrade populated
tables. Runtime readiness fails if expected migrations/security are absent.

### Tests and CI

All source paths, fixture ownership and case-level commands/checks are mapped in
[test-plan.md](test-plan.md). Implement the unit, SQL Server integration and Selenium tests
alongside the first working vehicle slice. A passing test inventory must cover every specified
acceptance case, not merely collect one test per suite.

Backend owns permission/validation/SQL/assertion cases; frontend owns component/cache/accessibility
cases; browser journeys are jointly owned by feature engineering; delivery engineering owns the
shared runner, migrations/readiness, isolation, reports and CI exit propagation. Product/Engineering
review this revised design and eventual acceptance results; the two original decisions are resolved.

Required checks unit/integration/selenium invoke their matching root Make target. Linux x86-64
images/driver/browser match local use. Additional gates cover lint/types, OpenAPI drift,
secret/dependency/image scans and built-app health. Missing services, failed setup, no tests or
skipped required scenarios fail checks; demonstrate a controlled failure then restored success.
Provider/network doubles are allowed only at explicit external boundaries, never as authorization
or persistence replacements.

### Windows Workflow

[quickstart.md](quickstart.md) distinguishes current static commands from future scaffold commands.
Native PowerShell invokes make with PYTHON=python; WSL uses make and python3. The host-side
Python runner issues Docker argument lists and owns per-run disposable resources; no Bash syntax
or Docker socket mounting is required. Browser container traffic uses web:8080, not localhost.
An unavailable engine or misconfigured identity is a failed prerequisite, not a green check.

## Proposed Delivery Order After Review

1. Verify the approved B-001 retry-table and B-002 UTF-16 decisions against this package and
   maintain the [executable task list](tasks.md); do not reopen those decisions as implementation gates.
2. Start independent scaffold, model, Unicode-vector and unit-test work while the Clerk
   decision, dependency/image pins and isolated SQL Server access are established. Complete the
   shared permission, protected-route and scoped-replay guards before US1 tests or completion.
3. Demonstrate scoped SQL driver/TLS/type round trips, identity/session verification, bounded
   bootstrap/RLS and pool cleanup in isolated environments. Lock tested versions/digests and
   record ADR-004 outcomes. Scaffold the explicit migration jobs and all three DEV-008
   runners/checks; prove missing setup and deliberately bad assertions fail. No production keys
   or deployment.
4. Implement the reviewed vehicle slice through real UI/API/service/SQL/provenance with its mapped
   tests. Preserve schema ceiling unless a separately approved decision changes it.
5. Run fresh/upgrade/drift, all three root suites and quality gates on the same implementation
   commit. Review evidence, accessibility and product acceptance. Publish/deploy only under a
   separate explicit authorization; this plan creates no release workflow or credentials.

## Evidence and Handoff

**Executed**: setup-plan.ps1; python database/tools/verify_kit.py (exit 0); metadata dependency
projection; read-only Python/Docker/Git environment probes. Static target inventory is 174 tables,
1,839 columns and 653 FKs; approved foundation inventory is 17 tables, 154 columns and 39 FKs.
The reference seed contains 28 inserts and RLS example 45 predicates.

**Not executed**: SQL Server reference rehearsal, Docker builds, Alembic migrations, Clerk smoke,
the required pytest/Vitest/SQL integration/Selenium suites, CI or deployment. A few validation
modules, unit-test files and local configuration files now exist, but the runnable application
scaffold, locked dependencies and test runners do not. Docker config access was denied and the
engine pipe was absent in the recorded probe; no broader machine state is inferred.

**Revised scope**: the unchanged static reference inventory above is not the application's new
scope. Feature 001 adds exactly 12 columns/3 FKs for a total of 18 tables/166 columns/42 FKs,
and five RLS predicates for 50. The global metadata/reference foundation remains unchanged.

**Revision validation**: static kit verifier exit 0; planning checks confirm the 18-table dependency
closure, exact column types/defaults, unchanged original 17 contracts, all 22 test-case mappings,
4 OpenAPI operations/44 resolved references, local links/anchors and formatting. These are
planning/static checks, not executed unit, SQL integration or Selenium tests.

**Next review**: approve the revised schema/replay/Unicode design and remaining evidence gates.
Stop here: no $speckit-implement, task generation, executable tests, migrations or deployment.
