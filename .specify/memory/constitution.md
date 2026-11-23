<!--
Sync Impact Report
Version change: unratified template -> 1.0.0 (initial FleetOps adoption)
Modified principles:
- Principle slot 1 -> I. Server-Enforced Tenant Isolation
- Principle slot 2 -> II. SQL Server Authority and Controlled Migrations
- Principle slot 3 -> III. Read-Only, Grounded AI
- Principle slot 4 -> IV. Tests Delivered with Application Code (DEV-008)
- Principle slot 5 -> V. Operational Integrity and Honest Data
Added sections: Technology and Delivery Constraints; Development Workflow and Quality Gates;
project-specific Governance.
Removed sections: none; replaced template examples and placeholders.
Deferred placeholders and implementation intents: none.
Dependent templates and commands: unchanged; consume this constitution at runtime.
Review follow-up: remove this temporary Sync Impact Report before committing the constitution.
-->

# FleetOps Constitution

## Core Principles

### I. Server-Enforced Tenant Isolation

Authority: AUTH-01–03, MOB-01, DOC-01, AI-02–04 and AI-07; ADR-004 and ADR-008.

- Every tenant-owned read, write, import, export, API response, background operation and AI tool
  invocation MUST enforce verified tenant scope and the relevant permissions on the server.
  FastAPI MUST verify identity, resolve an active internal user and tenant membership, and pass
  a verified request context through services and tenant-bound repositories.
- Identity-provider authentication MUST NOT confer business permissions by itself. Client tenant
  IDs, roles, route visibility and prompt text MUST NOT grant access. Invalid, expired or revoked
  credentials and disabled users, tenants or memberships MUST be denied.
- Resource IDs and related records MUST be validated within the authorized tenant before access.
  Finance, driver PII, precise locations, documents and conversation history MUST receive
  least-privilege protection. Drivers MUST access only their permitted assignments. Source links,
  downloads and cached mutation replays MUST recheck current authorization.
- Tenant-owned tables MUST carry tenant scope. Relationships MUST use tenant-scoped composite
  foreign keys or demonstrably equivalent constraints. SQL Server row-level security, if adopted
  after validation, MUST supplement application authorization and handle pooled connection state.
- Frontend query keys MUST include tenant context; tenant switching and logout MUST clear scoped
  caches. Denials MUST follow the documented 401/403/404 policy without disclosing protected data.
- Automated cases MUST cover valid/invalid/expired credentials, revoked users, role denial,
  cross-tenant lists and direct IDs, writes, imports/exports, documents and AI access as each
  surface ships. Zero unauthorized cross-tenant disclosures is a mandatory release gate.

Rationale: identity proves who a caller is; verified membership and resource scope establish
which operational data that caller may use.

### II. SQL Server Authority and Controlled Migrations

Authority: spec.md §§8–10, DEV-002–006; ADR-003 and ADR-008.

- Microsoft SQL Server MUST remain the authoritative datastore. Schema changes MUST use versioned
  Alembic migrations targeting SQL Server. Browser code and AI models MUST NOT access SQL directly.
  Production request paths MUST NOT invoke `create_all()` or perform ad hoc schema changes.
- Before schema work, engineers MUST read `docs/database/database-architecture.md`,
  `docs/database/business-rules.md`, `docs/database/migration-roadmap.md` and
  `database/metadata/model.json`. The physical model is a proposed reference target: migrations
  MUST implement only the approved, dependency-closed feature subset. The full reference DDL
  MUST NOT be executed as an application migration; synthetic seeds MUST NOT enter production.
- Migrations MUST preserve tenant-safe relationships, uniqueness, checks and required indexes.
  Money MUST use Python `Decimal` and SQL `DECIMAL`; timestamps MUST preserve UTC semantics and
  distinguish source occurrence from receipt. SQL-specific types and concurrency behavior MUST
  be exercised on actual SQL Server, not inferred from SQLite or another database.
- Gate 0 MUST validate the SQL driver in the selected Linux API image, including SQLAlchemy and
  Alembic compatibility, TLS, Unicode/decimal/time round trips, pooling and migration permissions.
  CI MUST run SQL Server integration and migration checks on Linux x86-64, including fresh and
  prior-schema upgrades, schema drift, tenant constraints and relevant concurrent transactions.
- Migrations MUST run as an explicit, controlled job with a separate migration principal and
  protection against concurrent migration runs. API and worker runtime identities MUST remain
  least-privileged; service startup MUST NOT automatically migrate the database.
- Changes MUST document deployment order and rollback or compensation. Expand/transition/contract
  changes MUST preserve rollout compatibility. Destructive production changes require explicit
  authorization, verified backup/PITR and rehearsed recovery. Migration failure MUST stop release;
  rollback MUST NOT blindly downgrade or overwrite newly written data.

Rationale: reproducible migrations and actual SQL Server evidence protect tenant constraints,
transactional correctness and recoverability.

### III. Read-Only, Grounded AI

Authority: AI-01–07; ADR-006 and ADR-010.

- The P0 Copilot MUST remain read-only for business records. The Python backend MUST own model
  calls and tool execution; `@ai-sdk/react` MUST act as UI transport. Model/provider selection
  MUST use configuration behind a typed provider interface.
- The tool allowlist MUST contain only the approved typed query tools: `getFleetSummary`,
  `getAvailableVehicles`, `getDelayedTrips`, `getTripStatus`, `getVehicleLocation`,
  `getMaintenanceDue`, `getDriverAssignments` and `getTripFinancialSummary`. Each invocation MUST
  call an authorized backend query service with verified tenant and capability context, bounded
  inputs and bounded results. An authorized chat session MUST NOT bypass per-tool checks.
- Models MUST NOT receive arbitrary SQL, text-to-SQL, shell/code execution, unrestricted network
  or URL-fetch tools, or business mutation tools. Assignment, cancellation, payment, permission
  changes and compliance determinations MUST NOT be model actions. Unsupported actions MUST be
  refused accurately and MAY direct the user to an authorized application workflow.
- Fleet facts MUST derive from permitted records. Responses MUST expose authorized source record
  references, relevant timestamps, query scope and financial completeness through a tested
  structured channel. Source access MUST be reauthorized. Missing or stale evidence MUST be
  disclosed; invented records, amounts, locations and model-generated-only citations are invalid.
- Notes, uploaded documents and provider text MUST be treated as hostile data, never instruction
  authority. Provider credentials MUST remain server-side. Tenant/user usage caps, bounded tool
  calls, token/time/cost limits, minimal redacted telemetry and conversation retention/deletion
  controls MUST be enforced. AI-07 chat history and usage recording MUST NOT enable business writes.
- SDK/provider versions and the streaming protocol MUST be pinned after a FastAPI compatibility
  test. Automated coverage MUST include grounded, empty, stale and contradictory answers,
  forbidden mutations with unchanged business rows, financial permission denial, cross-tenant
  context and source access, prompt injection, tool/provider failure and streaming disconnects.
  Zero unauthorized disclosures is a mandatory AI release gate.

Rationale: Copilot summarizes authorized operational evidence; it cannot become a separate
authorization path or an autonomous operational actor.

### IV. Tests Delivered with Application Code (DEV-008)

Authority: DEV-008, spec.md §§7, 10 and 13; [test generation instructions](../../spec-kit/feature-test-generation.md).

- Every system-code change MUST generate or update executable tests alongside the application
  code in the same feature change. Plans MUST map each changed acceptance behavior to its
  requirement ID, test file/name, fixture, user action and observable outcome.
- The first vehicle workflow (FLT-01 with AUTH-01–02) at Gate 0 MUST scaffold and pass all three
  suites locally and in pull-request CI, including fixtures, pinned dependencies, runners,
  root commands and CI jobs. Test descriptions, placeholders and database reference rehearsals
  MUST NOT substitute for executable application tests.
- Unit tests MUST exercise real business, validation, authorization and component behavior:
  pytest in `apps/api/tests/unit/`, and Vitest with React Testing Library under `apps/web/src/`.
- Integration tests MUST use pytest in `apps/api/tests/integration/`, production FastAPI entry
  points and an isolated actual SQL Server database upgraded by application Alembic revisions.
  They MUST exercise token verification, membership, services and repositories and assert both
  HTTP results and committed effects. Event-driven features MUST exercise the real worker
  consumer entry point. Application assertions MUST use runtime credentials; setup uses migration
  credentials.
- Browser tests MUST use pytest and Selenium WebDriver in `tests/selenium/` against the built
  React UI, running API and separately seeded SQL Server test environment. Headless Chrome is
  the default. Each test MUST use an isolated browser session, condition-based waits and cleanup
  even on failure, and verify user feedback and persisted results after refresh.
- Later features MUST extend each affected suite and browser journey. Backend-only changes MUST
  identify the existing Selenium regression covering their visible effect, or record the absence
  of a browser-visible effect once in the feature plan. All three PR checks MUST still run.
- Synthetic fixtures MUST isolate tenants, identities, databases, storage and queues per run.
  External dependencies MAY use controlled boundary doubles, but production token verification
  and business authorization MUST remain active in end-to-end tests. Production data, credentials
  and private driver information MUST NOT appear in fixtures, screenshots or reports.

Rationale: executable acceptance evidence shipped with each feature prevents security, database
and browser behavior from becoming deferred work.

### V. Operational Integrity and Honest Data

Authority: DISP-01–02, TRIP-01–03, GPS-01–02, MOB-02, DOC-01, MNT-02, FIN-01–03 and RPT-01.

- Dispatch MUST check asset status, equipment compatibility and overlapping reservations inside
  a SQL Server transaction. Blocked/out-of-service assets MUST NOT be assigned. Concurrent
  incompatible assignments MUST yield one commit and a conflict; failed reassignment MUST
  preserve the original assignment.
- Trips MUST use explicit, auditable state transitions and current authorization. Delivery,
  POD availability/verification, expense reconciliation, closure and invoice readiness MUST
  remain distinct. Document eligibility MUST bind the exact authorized tenant/document/version
  to its scan and approved verification result.
- Imports, webhooks, telemetry, offline events and dispatch mutations MUST use durable
  idempotency keys scoped to tenant, operation and actor/source, bound to the request payload.
  Identical authorized retries MUST replay the original result without repeating business effects;
  changed payloads MUST conflict. Business effects, deduplication and required outbox records MUST
  commit atomically; consumers MUST deduplicate.
- GPS MUST retain source and ingestion times. Older observations MUST NOT replace newer
  latest-known positions; stale positions MUST be labeled with last-seen time, never as live.
- Financial reports MUST disclose currency, units, mileage basis and completeness. Missing cost
  MUST NOT become zero; zero/unknown miles MUST produce an unavailable rate. Direct contribution
  MUST NOT be labeled net profit without approved allocations. UI, export and AI summaries MUST
  use consistent calculations for the same revision; adjustments MUST retain an audit trail.
- Files MUST remain private with validated type/size, scan or quarantine handling and authorized,
  expiry-controlled access. Secrets and unnecessary PII, financial or precise-location data MUST
  be excluded from logs, prompts and diagnostics. FleetOps MUST NOT claim certified ELD status,
  conclusive HOS validation or guaranteed regulatory compliance.

Rationale: trustworthy operational facts and explicit uncertainty take priority over convenient
screens or confident AI answers.

## Technology and Delivery Constraints

- The stack MUST remain React, strict TypeScript, Vite and Tailwind; a Python/FastAPI modular
  monolith with Pydantic, SQLAlchemy and Alembic; and SQL Server. Web/API contracts MUST be typed
  and generated or validated against OpenAPI. Modules MUST communicate through typed interfaces.
- Clerk remains preferred pending ADR-004 validation and approval. Azure SQL and Azure Container
  Apps remain proposed hosts; AI provider/model, queue and storage providers remain open.
  Implementations MUST record spike evidence and approved ADR decisions before treating these
  choices as final. Selected database, authentication, hosting or product scope MUST NOT change
  silently.
- Development MUST use VS Code and reproducible Docker Compose. Before scaffolding or deployment
  changes, engineers MUST read `docs/development-and-delivery.md`. Images MUST use pinned
  dependencies, non-root application runtimes, health checks and private service networking.
  SQL MUST NOT be publicly exposed; environments MUST NOT share production secrets or data.
- Integrations MUST use a dedicated durable worker/queue, bounded timeouts/retries, provenance
  and observable failure/recovery states. In-process request background tasks MUST NOT be treated
  as a durable queue. Database transactions MUST NOT remain open around model/network calls.
- GitHub Actions MUST enforce tests, scans and container checks; only authorized trusted releases
  may publish to GHCR. Deployment MUST promote identical tested digests through staging and
  approved production, with explicit migration, smoke and rollback evidence. Pushes, deployments,
  production configuration changes and destructive migrations require explicit authorization.

## Development Workflow and Quality Gates

1. Before significant changes, read `spec.md`, `docs/architecture-notes.md`, `AGENTS.md` and the
   nearest feature README/ADR. Identify requirement IDs, permissions, edge cases, architecture
   gates and test mappings. Unresolved accounting, settlement, HOS or qualification policy MUST
   be recorded for stakeholder decision, not invented.
2. Implement the smallest complete vertical slice through UI, API, service, database migration,
   observability and tests. Include accessible keyboard/focus behavior, loading/empty/error and
   conflict states, tenant-cache cleanup, time zones, GPS freshness and financial completeness
   where relevant. Update affected contracts, acceptance references and deployment/backout notes.
3. At Gate 0, generate `make test-unit`, `make test-integration`, `make test-selenium` and aggregate
   `make test` at the repository root, with equivalent VS Code tasks. Required PR checks MUST be
   named `unit`, `integration` and `selenium` and invoke their matching root commands. Local and
   CI runs MUST share pinned dependencies, browser/driver pairing and documented Compose setup.
4. Integration and browser jobs MUST wait for readiness with a timeout, apply migrations, seed
   isolated synthetic data and always clean up their run resources. Setup failure, missing SQL
   Server/browser, zero collected tests and skipped required scenarios MUST fail checks. Scaffold
   verification MUST demonstrate a deliberately failing assertion exits nonzero, then restore
   it and record a passing run. Reference database rehearsals MUST remain separate.
5. Coverage MUST apply the `AGENTS.md` test matrix: authorization and tenant probes; invalid input;
   state/dispatch conflicts; duplicate/out-of-order events; decimal and incomplete-data cases;
   document/offline conflicts; AI grounding/injection/outage; and accessible UI states as relevant.
   PR evidence MUST link accepted behaviors to executable cases and results from the implementation
   commit, including suite counts, failures/skips, commit SHA, JUnit reports and sanitized browser
   failure screenshots/diagnostics.
6. All three test checks and applicable lint/type, OpenAPI drift, SQL Server migration, security,
   image and build/smoke gates MUST pass before merge or promotion. Product acceptance and manual
   pilot UAT remain required. Handoffs MUST state actual commands, outcomes, limitations and any
   unexecuted checks with reasons; unavailable infrastructure MUST NOT be reported as a pass.

## Governance

This constitution applies throughout FleetOps and operationalizes the existing authority hierarchy:
[spec.md](../../spec.md) governs product behavior and acceptance;
[architecture notes](../../docs/architecture-notes.md) govern technical design and decision status;
[AGENTS.md](../../AGENTS.md) governs implementation and agent behavior. Supplemental agent files,
plans and tasks MUST remain consistent with these authorities and this constitution. Conflicts
MUST be surfaced and resolved through the relevant spec/ADR decision before conflicting work
proceeds; this document does not silently override canonical requirements.

Amendments MUST state the proposed rule, rationale, affected requirements/ADRs, security and
compatibility impact, and necessary migration/test changes. Product and Engineering review and
approval MUST precede adoption. Cross-document conflicts MUST be resolved in the corresponding
authoritative documents. Local exceptions MUST NOT waive tenant isolation, read-only P0 AI or
required verification; changing an invariant requires an explicit approved spec/ADR and
constitution amendment, including a new security review for future AI write capabilities.

Constitution versions MUST follow semantic versioning: MAJOR for incompatible principle removal
or redefinition, MINOR for new principles/sections or materially expanded guidance, PATCH for
non-semantic clarification. Ratification records initial adoption; the last-amended date MUST
be updated whenever this constitution is amended. Dates MUST use ISO YYYY-MM-DD.

Every feature plan and PR review MUST check these principles, identify the affected acceptance
cases and attach actual verification evidence. Completion MUST NOT be claimed while required
checks or approvals remain unmet. This workspace is currently a planning/database reference kit;
the application, root test commands and CI suites described here are Gate 0 deliverables, not
existing implementation or evidence of successful execution.

**Version**: 1.0.0 | **Ratified**: 2026-11-23 | **Last Amended**: 2026-11-23
