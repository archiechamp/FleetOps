# Feature 001 Research and Decisions

**Date**: 2026-11-23
**Status**: B-001/B-002 resolved and Feature 001 design approved for implementation by the
recorded user direction; Clerk ADR-004, dependency pins and runtime SQL evidence remain open.
**Inputs**: [feature spec](spec.md), [constitution](../../.specify/memory/constitution.md),
[root architecture](../../docs/architecture-notes.md), [database planning](../../spec-kit/database-planning-instructions.md)
and [DEV-008 instructions](../../spec-kit/feature-test-generation.md).

This records approved design decisions, not successful deployment or compatibility tests. The approved
exception is exactly one existing proposed table; the 17-table reference baseline stays intact.

## B-001 — Resolved: Narrow Durable Registration Receipt

**Decision**: Add only integration.idempotency_keys from the kit's existing target design.
The user explicitly authorized this addition to the 17-table foundation. The feature set becomes
18 tables, 166 columns and 42 FKs. All three added FKs target core.tenants/iam.memberships
already in the foundation. No new column or other integration/G03 table is necessary.
The roadmap permits moving dependency tables earlier; this feature records that narrow exception,
not a global promotion of foundation=false tables.

**Design**: The [exact schema and protocol](data-model.md#transaction-and-provenance) use the
existing tenant/operation/key UQ, with membership UUID encoded in versioned operation_scope,
a binary SHA-256 canonical-payload hash and a typed vehicle response_reference. One transaction
writes the complete truck, audit and receipt under a bounded transaction-owned SQL lock.
Same-key concurrent attempts serialize; distinct-key duplicate units still use the fleet UQ.

Original 201 body/Location can be recovered without a response blob: hash-verified retry values
supply the five original input fields; the scoped vehicle reference and immutable created_at
supply the original identity/time. Current permissions and record ownership are checked again,
even after restart. A valid changed payload conflicts; a missing result fails closed.
This response projection must remain stable for v1; a future expanded response or physical
deletion requires a compatibility review, not silent use of current mutable fields.

**Expiry decision for this slice**: Preserve FR-008's unbounded retry promise. Set the required
expires_at to SQL's maximum DATETIME2(3) instant and do not purge/reuse keys. The kit's 30-day
retention text is a proposal, not authority to discard registration receipts. A finite policy is
a later product/security decision before cleanup/production retention, with explicit spec impact.

**Alternatives considered**: Process memory is not restart-safe; Redis cannot atomically commit
with this SQL transaction. Audit JSON/settings are not request ledgers. A serialized full
response does not fit NVARCHAR(150); widening it or adding another response table is unnecessary
for this narrow deterministic v1 response. The chosen reference is never ownership proof.

## B-002 — Resolved: UTF-16 Code-Unit Limits

**Decision**: The user selects UTF-16 code units: unit_number 1–30, make/model 1–80 after a shared
explicit trim rule. Update FR-004, OpenAPI annotations, UI/API validation and all test layers.
Keep existing NVARCHAR(30/80) types and the proposed supplementary-character-aware collation;
do not truncate, normalize away differences, or reject valid supplementary characters.

**Rationale**: This matches SQL storage capacity, including supplementary characters using two
units. [Microsoft NVARCHAR semantics](https://learn.microsoft.com/en-us/sql/t-sql/data-types/nchar-and-nvarchar-transact-sql).
Browser string length counts code units; use the fixed ECMAScript whitespace set on both sides
rather than relying on different JavaScript/Python trimming defaults.
[ECMAScript string/trim definitions](https://tc39.es/ecma262/multipage/text-processing.html#sec-string.prototype.trim).
Generic JSON Schema maxLength is not the post-trim UTF-16 rule; custom validated contract metadata
and shared fixture vectors must bridge the generated client and Pydantic validator.
[JSON Schema string validation](https://json-schema.org/draft/2020-12/json-schema-validation#section-6.3).

**Alternatives considered**: Code-point or grapheme counts permit values that do not fit the
unchanged columns. Native input truncation hides invalid data. The reviewed contract instead
preserves entered input, displays accessible errors, rejects unpaired surrogates and checks exact
boundary round trips through SQL Server. See [Unicode contract](contracts/README.md#unicode-and-length-contract).

## R-001 — Technology Baseline and Version Locks

**Decision**: React + strict TypeScript + Vite + Tailwind; Python 3.12 baseline with FastAPI,
Pydantic v2, synchronous SQLAlchemy 2.x, Alembic and pyodbc + Microsoft ODBC Driver 18 as the
first driver candidate. Use Node.js 24 LTS as the proposed web build baseline. Use SQL Server
2022 Developer on Linux amd64 for isolated local/CI environments, consistent with the kit's 2022+
baseline. No Developer Edition production use is proposed.

Exact supported patch versions, npm/Python lockfiles, SQL image digest, browser image digest and
Action SHAs are implementation spike outputs required before merging a scaffold. Do not label
unresolved pins as latest or invent digest values. This plan does not select production hosting.

**Rationale**: Keep the selected stack and a single database/runtime architecture. Node 24 is
listed as LTS and satisfies current Vite minimums; dependency resolution must still prove the
selected package set. [Node releases](https://nodejs.org/en/about/previous-releases),
[Vite prerequisites](https://vite.dev/guide/).

**Alternatives considered**: mssql-python is a candidate if pyodbc packaging fails; it requires a
separate driver/SQLAlchemy/Alembic compatibility record. An asynchronous ODBC adapter adds a thread
bridge without helping this small slice. SQLite cannot establish SQL Server semantics.

## R-002 — SQL Driver, Connections and Migration Proof

**Decision**: Propose SQLAlchemy's mssql+pyodbc dialect, bounded pool and timeouts, TLS encryption
and certificate verification. Test UUID, DATETIME2 UTC, ROWVERSION bytes, Unicode and DECIMAL
round trips in the final Linux image. Disable pyodbc's internal pooling before connections are
created; explicitly manage tenant context lifecycle in the SQLAlchemy pool.
[SQLAlchemy MSSQL dialect](https://docs.sqlalchemy.org/en/20/dialects/mssql.html).

**Rationale**: Two pooling layers complicate tenant cleanup. Each checkout clears stale context,
binds only a verified native UNIQUEIDENTIFIER, and invalidates on reset failure. Normal rollback
alone is not proof of session-context cleanup. Clear with null and do not mark reusable context
read-only. [SQL Server session context](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-set-session-context-transact-sql).

**Alternatives considered**: Unverified client tenant fields, generic runtime admin credentials,
RLS without application scoping, or assumptions that EXECUTE AS automatically bypasses RLS are
rejected. Use a restricted identity bootstrap procedure with an explicitly reviewed RLS execution
principal exception; details are in [data-model.md](data-model.md).

**Evidence gate**: Real driver/container/migration tests remain pending. Use a dedicated migration
principal and a runtime role with read/create capability grants, no DDL or audit mutation grants.

## R-003 — Identity and Immediate Access Revocation

**Decision**: Retain Clerk as the proposed ADR-004 provider. Verify bearer credentials with the
official Python backend SDK, configured issuer, authorized parties, signature and temporal claims;
resolve internal identity, active carrier membership and effective permissions on every request.
The verified request context is the only source for ownership and actor attribution.
[Clerk Python integration](https://clerk.com/articles/how-to-add-authentication-to-a-python-backend).

**Rationale**: A valid short-lived JWT alone does not establish that its session remains active
at the time of a request. To meet immediate revoked-session acceptance without a new local
session table, the proposed identity adapter also retrieves current session status from the
provider and verifies the session/user binding. No positive session-status caching in this slice.
Use a bounded timeout/retry before any database transaction; revoked/expired is 401 and an
unavailable revocation check is 503 without data. Internal membership/capability revocation
is read fresh and denied with 403.
[Session token claims](https://clerk.com/docs/guides/sessions/session-tokens),
[backend session object](https://clerk.com/docs/reference/backend/types/backend-session).

**Alternatives considered**: Claiming immediate revocation from offline verification alone is
incorrect. A webhook-only revocation projection requires durable intake and delivery semantics
outside this slice. A provider-status cache introduces a revocation window not approved by the spec.

**Evidence gate**: Prove provider SDK session-status retrieval, subject/session binding, revoked
tokens, outage and limits with a real Clerk development instance before closing ADR-004. This
network check affects latency; the root read-latency target excludes external calls. No provider
key, live tenant or configured Clerk login is assumed present.

## R-004 — Test Identity Boundary

**Decision**: CI uses run-scoped signed test identities, JWKS/public keys and a controlled provider
session-status boundary. The real Python verifier, configured claim checks and database membership
authorization remain active; no FastAPI dependency override returns an already-authorized user.

A test-only identity service and frontend session adapter may provide a local sign-in flow and
signed tokens. The production API does not accept arbitrary subjects or test auth headers.
The test service is isolated to Compose tests, is absent from release routing, and uses ephemeral
keys. Production startup rejects synthetic identity configuration. A separate trusted Clerk
sign-in smoke remains required: local identity fixtures do not prove Clerk's hosted UI.

**Rationale**: Pull-request tests need deterministic auth without production credentials or
external availability. The same app entry points must still reject bad signatures, expiry,
issuer/party mismatch, revoked sessions and wrong memberships.

**Alternatives considered**: Bypassing verification, sharing a global authenticated browser session,
or reusing the fixture string TEST_FIXTURE as a usable Clerk login fail DEV-008.

## R-005 — Permissions, Normalization and Scope

**Decision**: Use the reference capability codes fleet.vehicle.read and fleet.vehicle.create.
Create requires both in the selected carrier; read requires read. Do not seed architecture's
illustrative fleet.read/fleet.write aliases or infer creation from a DISPATCHER label.
Propose an explicit Latin1_General_100_CI_AS_SC collation on each new disposable application
database and the same semantics for equality search and the unit-number unique constraint.
Outer whitespace is trimmed once; interior characters and accent distinctions remain significant.

**Rationale**: These choices match the concrete fixture/model and avoid application preflight-only
uniqueness. Confirm collation behavior under UT-02/IT-02/IT-06, including Unicode edge cases.
[Local dictionary](../../docs/database/data-dictionary.md) and
[reference constraints](../../docs/database/constraints-and-indexes.md) are authoritative inputs.

**Alternatives considered**: New normalized columns/indexes exceed the unchanged foundation
contract; broad CRUD scopes exceed this user's registration/read feature. Updates/deletes and
public If-Match mutation endpoints are deferred. Existing ROWVERSION behavior is still tested
as a database/driver characteristic in IT-10.

## R-006 — Windows, Selenium and CI

**Decision**: Use Docker Desktop's Linux engine on an Intel/AMD x86-64 workstation, PowerShell
commands with an explicit Python executable and GNU Make, or WSL2 with Docker integration and
GNU Make. Native Windows shell support lives in a Python-standard-library orchestration runner;
Make recipes contain no Bash-specific syntax. ARM hosts require a real remote amd64 test engine,
not an assumed SQL Server emulator.
[Docker Desktop Windows requirements](https://docs.docker.com/desktop/setup/install/windows-install/),
[SQL Server container platform support](https://learn.microsoft.com/en-us/sql/linux/install-upgrade/quickstart-install-docker?view=sql-server-linux-ver17).

**Rationale**: All application dependencies run inside the same pinned Linux images locally and
in CI. Only Python, Make and the Docker CLI are needed on the host. Selenium runs in its own
Chrome container and reaches the web service by its Compose service URL, not localhost.
Use explicit observable-condition waits and independent sessions.
[Selenium waits](https://www.selenium.dev/documentation/webdriver/waits/).

**Alternatives considered**: Different host-installed SQL/Chrome stacks undermine parity; mounting
the Docker socket into a generic tooling container grants unnecessary host control. The host
runner invokes Docker directly and isolates each suite by a unique Compose project.

## Observed Evidence on 2026-11-23

- setup-plan.ps1 resolved FEATURE_SPEC and IMPL_PLAN in specs/001-vehicle-registration and
  returned BRANCH=001-vehicle-registration. Git confirms there is no repository; this is a
  feature-context label, not an actual created branch.
- `python database/tools/verify_kit.py` exited 0: target 174 tables/1,839 columns/653 FKs;
  foundation 17 tables/28 fixture inserts/45 RLS policy predicates. Static validation passed.
- Metadata projection confirms 154 foundation columns and 39 foreign keys with dependency closure.
- `python --version` reports 3.12.5. `py -3 --version` reports no installed Python, so the
  Windows guide uses the working python executable and documents launcher fallback.
- Docker CLI/Compose are installed (Compose v5.1.3 reported). Docker server detection failed
  with denied access to the user's Docker config and a missing engine pipe. Engine availability
  is unverified from this session; no Docker/SQL/Clerk/application test was run.
- No secrets were read, containers started, migrations executed, branches created or releases
  published. Runtime proofs and exact dependency locks remain review/implementation gates.
