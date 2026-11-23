# Migration roadmap and deployment gates

This is a proposed sequence, not Alembic revision IDs. Only implement objects required by the currently approved Spec Kit feature. Build dependency-closed revisions; no empty stubs for unrelated modules. All changes through reviewed Alembic migrations; generated reference SQL is not a second migration mechanism.

| Group | Features / scope | Tables or objects | Exit gate |
|---|---|---|---|
| G00 | 001 foundation | 17 tables marked foundation in model.json, reference seed; optional RLS proof | Docker SQL connectivity, fresh upgrade, two-tenant test, CRUD, pool reuse, CI |
| G01 | 002–003 auth/onboarding | remaining core/iam/ref P0 | roles/permissions, numbering and import test |
| G02 | 004–006 assets/drivers/customers | fleet/hr/crm P0 | subtype and tenant FK, qualification visibility |
| G03 | 007–009 load/dispatch/trips | approved ops P0 subset, audit, durable idempotency and outbox, dispatch-prohibiting restriction source | state, retry, maintenance/assignment race and concurrent reservation tests |
| G04 | 010–011 docs/mobile | delivery, POD versions and review, mobile reuse of G03 idempotency | versioned POD, retry and offline tests |
| G05 | 012–013 GPS/maintenance | selected integration/gps/mnt P0, including maintenance scheduling | out-of-order GPS, restriction lock tests |
| G06 | 014–015 fuel/finance | fuel/fin P0, expense document links | allocation lock & currency tests |
| G07 | 016–019 dashboard, notifications, AI | notify/ai P0/P0B; reporting contracts | authorized KPI, stale/missing, AI eval and usage controls |
| G08 | 020–021 compliance/invoicing | remaining P0 compliance records, P1 as approved | required record and retention review |
| G09 | future | P2 inventory, knowledge documents, analytics | approved future feature |

These groups may move dependency tables earlier; e.g. expense-document links depend on finance and compliance documents depend on docs. Resolve by computing FK dependency closure from metadata and splitting revisions, not disabling constraints. Foundation seed is development only. Production references seeded with idempotent controlled migration; no synthetic users in production.

## Migration implementation and CI

1. Use SQLAlchemy declarative metadata with schema-aware naming and Alembic `include_schemas=True`; validate MSSQL dialect, ODBC driver and type compilation. `GO` is sqlcmd batch syntax, not an API statement, and must not be passed to SQLAlchemy. Port SQL functions/policies using explicit batch execution. Use UTC defaults and server-generated rowversion correctly.
2. Run SQL Server Docker with persistent local volume; CI uses disposable supported x86-64 container and pinned image digest. Managed production database outside app containers. Keep queue/worker and API migrations separate. Never use production `create_all()`.
3. In GitHub Actions validate fresh migration, previous release upgrade, required reference seeds, schema drift, real SQL Server constraints and grants, RLS pool reuse, concurrency, numeric precision and rollback/recovery procedure. SQLite is insufficient. Pin dependencies; use separate staging/production credentials and approval.
4. Production uses a single controlled migration job with least-privilege migration credential, backup/PITR verification and exclusive deployment lock. API/worker readiness checks schema compatibility; they do not run migrations at startup. Prefer expand/contract across releases, backfill in bounded batches, and deploy compatible image digests from GHCR. Roll back application image only when schema is compatible; destructive schema changes require explicit restore or forward-fix plan. Never assume downgrade is safe.

## Existing proof-of-delivery data

For any installation derived from the earlier target, add the two version columns as nullable in an expansion migration. Resolve the exact uploaded revision from immutable receipt/checksum or historical audit evidence. Leave ambiguous links pending review. Never infer approval from a document’s latest version. Dual-write exact versions, reconcile unresolved rows and validate the composite FKs before requiring values. Preserve historical signed-off evidence through any backout. The 17-table foundation contains neither affected table.

## Reference rehearsal

Run the [foundation verification procedure](VALIDATION.md) against a fresh disposable SQL Server database. The 174-table target is a design reference. Production and staging use reviewed Alembic revisions. Record fresh upgrade, upgrade from the previous release and application/worker pool reuse separately when the implementation exists.

## Requirements to implementation evidence

| Product requirement | First relevant group | Durable records and invariant | Evidence at the feature gate |
|---|---|---|---|
| AUTH-02, FLT-01 | G00 | Membership, role permissions, tenant-bound asset and vehicle keys | Through the API, tenant A may create a vehicle, B has fixture read-only access. A repeated unit number within A fails. Test revocation and pool reuse. |
| LOAD-01, DISP-01, MNT-02 | G03 | Trip, load, stops, asset/driver reservations, maintenance restriction, idempotency record and outbox | Two sessions contend for a resource. One commits. Failed reassignment preserves prior reservations. Restriction writers acquire the same resource locks. |
| MOB-02, TRIP-01, DOC-01 | G03–G04 | Assigned membership, stop event, delivery confirmation, delivery document and verification version | An offline duplicate produces one event. Reassigned driver loses access. The first of two required deliveries leaves the trip in transit. An earlier approval cannot satisfy a replacement POD. |
| GPS-01–02 | G05 | Device assignment effective at observation time, raw position and latest projection for the same tenant and asset | Replay a duplicate and an older event. Latest observation remains stable. A stale reading surfaces the actual last observation time. |
| COST-01, FIN-01–03, RPT-01 | G06–G07 | Separate allocation streams, source currency, trip distance and closure revision | Reconcile the fixed USD amounts in the reporting contract against UI and CSV. Record absent categories and missing miles explicitly. |
| AI-02–07 | G07 | Membership-owned conversation, typed read tool, source timestamp and response provenance | A permitted financial summary reproduces that same revision. A revoked member cannot replay its source. A dispatch request through chat leaves assignment records untouched. |

The proposed P0 metadata includes some tables shared with future workflows. Table phase identifies the earliest candidate dependency. The product specification controls when fuel-card imports, invoicing and other user-facing capabilities ship.
