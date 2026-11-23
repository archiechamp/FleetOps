# FleetOps database architecture | v1.1

Status: proposed physical target design, pending feature review and SQL Server execution. Product authority: FleetOps root `spec.md` v1.5; architecture and agent instructions remain authoritative. This document refines the earlier logical inventory; do not silently change approved scope. SQL Server 2022+ development baseline and compatible managed Azure SQL production are proposed, subject to Gate 0 verification.

## Domain and physical strategy

17 base-table schemas (`core`, `iam`, `ref`, `fleet`, `hr`, `crm`, `ops`, `gps`, `mnt`, `fuel`, `fin`, `compliance`, `docs`, `notify`, `ai`, `integration`, `audit`) plus eighteenth `reporting` schema for views. Single shared database; domain boundaries enforced in FastAPI services, not by giving each domain its own DB. `model.json` is the design snapshot, not an ORM runtime. Alembic history becomes physical deployment authority. Generated target DDL is reference only; do not apply en masse. All current artifacts use `snake_case`, schema-qualified names, no cascading deletes, UTC `DATETIME2(3)`, native `ROWVERSION`, and `DECIMAL` for measurements and money.

| Scope | Meaning | Key |
|---|---|---|
| G | global restricted identity/configuration | UUID |
| R | shared governed reference | smallint identity, except currency CHAR(3) |
| T | mutable tenant-owned | UUID + tenant_id |
| A | append-only tenant record | UUID + tenant_id |
| H | high-volume append-only tenant record | BIGINT identity + tenant_id |

Business UUID keys are globally unique; tenant-owned records also have UNIQUE(tenant_id,id). Composite FKs prevent wrong-tenant links. Currency is a natural code FK. Truck-specific assignment IDs refer to `fleet.vehicles.id`, trailer IDs to `fleet.trailers.id`, reservation IDs to `fleet.assets.id`; API must resolve subtype asset IDs explicitly, never assume they are equal. Driver identity links to a tenant membership instead of just a global user. Global `iam.users` represents verified identity; membership governs permissions. Platform administrator access is a separate privileged control plane with audited workflows; never grant global query permissions to a tenant administrator. Global roles are not assumed: each tenant has its own role records and seeds.

## Security design

- Every request verifies Clerk token issuer, audience/authorized parties as appropriate, signature, expiry and active membership through a bounded bootstrap service. No client-supplied tenant is trusted. DB access only through API/worker; never browser or model.
- Separate runtime, migration, seed/test and narrowly scoped identity/bootstrap principals. Bootstrap operations only return needed membership data; use reviewed stored procedures or equivalent bounded elevated access. No generic privileged query path. Runtime cannot alter schema/policy or update/delete append-only tables. Implement actual least-privilege grants with the approved feature; DDL alone does not establish them.
- Apply RLS filter/block policies after validating connection-pool behavior; the optional foundation script is illustrative and covers tenant tables, not global identity tables. No context = no rows; bind the verified tenant as a native SQL `UNIQUEIDENTIFIER` per checkout (use a parameter declared as that type before calling `sp_set_session_context`), clear in finally/return, invalidate on failures, and test pool reuse A→B→none. Do not set read_only context on reusable pooled sessions. `SESSION_CONTEXT` is not an authentication boundary against a compromised runtime principal; parameterized SQL and strict backend authorization remain mandatory.
- Cross-tenant relationships additionally blocked by composite FKs. Tenant-scoped reports include tenant_id and obey RLS and RBAC. Global catalog reads are separately governed. Actor identity FKs to global users are provenance, not proof of membership; service checks actor at time of event. Polymorphic audit/source references do not represent foreign-key guarantees; never use them to authorize data access.
- SQL Server encryption/TLS, private connectivity, secret references, least privilege, encrypted backups, redacted logs; never store model/API tokens or passwords in records. Clerk test subjects are fake and not log-in credentials.

## Operational consistency

Transactions coordinate assignments, reservations, current states and outbox. Use half-open intervals `[start,end)` and lock stable driver/asset rows in deterministic order, or use `sp_getapplock` transaction-owned locks with reviewed naming/timeout; all writers including maintenance restriction and reassignment must use same protocol. Snapshot queries alone cannot prevent races. Distinguish commercial loads, physical trips and operational exceptions. MVP single-load trip; future relays/multi-load require explicit allocation and stop consistency. Maintain sequence/current status projections transactionally; late provider events must not roll them back.

Normalize source costs and separate allocations. An expense allocated to a trip and asset in one row is one allocation, not two amounts; allocation sum is checked under source-row lock. Validate signed credits and matching currency; never sum across currencies. Final closure snapshot immutable under ordinary runtime operations; later corrections create a new revision and audit evidence. No complete accounting ledger is claimed.

GPS append-only records retain provider time and receipt time, deduplicate per device with provider event key, and update latest position only on newer (deterministically tie-broken) valid events. Source-device/asset interval must agree. Retention must remove or repoint latest projection before parent deletions, preserve statutory supporting records and legal holds, and be tested. High-volume data requires measured index and capacity planning.

Files: private object storage with quarantine, scan result, checksum, server-selected key and tenant-aware download authorization. SQL stores version metadata. For each delivery/document link, record the submitted version number. Record reviewer decisions against that same three-part key (tenant, document, version). A replacement creates a new version and a fresh scan/review history. Preserve the prior binding and reason in the audit trail when switching the submitted version. Keep object bytes and checksum immutable for a version; restrict scanner and reviewer updates to their respective fields or event records. AI: typed read-only domain tools; AI persistence uses a separate allowed write surface for chats/feedback/metrics only, never operational mutation. Treat prompts, notes, documents, and tool output as untrusted; authorize source links even when replaying prior chats. Conversation owner is membership; revoked access must not expose historical tool results. No vector DB required for P0.

## Physical decisions still requiring approved feature plans

- Confirm SQL Server edition/driver/TLS/ODBC and production host; test SQLAlchemy mapping for UUID, rowversion, geography, JSON and server defaults.
- Confirm reference/status vocabularies, jurisdiction applicability, identity bootstrap grants, retention, definition of operating mileage and expense completeness, plus source provider uniqueness semantics. The detailed target model contains structural SQL checks for critical codes; other status codes are service-governed until the relevant feature specifies them.
- Index keys are proposed (tenant-leading where applicable); benchmark real execution plans. No partitioning at foundation. Explicitly choose collation/case handling, string normalization and length restrictions in API. No arbitrary user-supplied query fragments.
- `updated_at` is maintained by services; `ROWVERSION` is generated by SQL Server and is not a clock. No universal soft delete: use inactive/status/archival transitions as specified; add legal deletion policies before production. Never automatically delete linked records.
- Target design adjusts earlier names to normalize currency, provider connections, membership actor IDs, delivery evidence, and source expense links. No duplicate cost amount lives in service records; canonical `fin.expenses` is the source. `reporting` view contracts are not executable KPI implementations yet.
