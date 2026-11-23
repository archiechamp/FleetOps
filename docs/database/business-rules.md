# Database integrity rules and verification matrix

Static SQL checks are necessary, not sufficient. All tests below are required when their feature is implemented; none have been run on a live SQL Server as part of this documentation delivery.

| ID | Invariant | Enforcement | Required test |
|---|---|---|---|
| DBR-001 | tenant-owned records refer to real tenant | NOT NULL and FK | unknown tenant insert fails |
| DBR-002 | no cross-tenant relationships/reads/writes | composite FK + verified membership + RLS + grants | A references B rejected; A/B/no-context pool tests |
| DBR-003 | unique unit number per tenant | UQ | duplicate A fails; same number B allowed |
| DBR-004 | unique driver number per tenant | UQ | duplicate within tenant fails |
| DBR-005 | unique load number per tenant | UQ, locked sequence allocation | concurrent creation unique |
| DBR-006 | unique trip number per tenant | UQ, locked sequence allocation | concurrent creation unique |
| DBR-007 | no incompatible overlapping truck/trailer reservations | locked asset transaction, half-open interval | two different connections race; only one succeeds |
| DBR-008 | no incompatible overlapping driver reservations | same locked driver protocol | two connections race; one succeeds |
| DBR-009 | prohibit unsafe or unavailable dispatch | maintenance restrictions + shared locking protocol | restriction races with assignment safely |
| DBR-010 | end >= start; reservation end > start | CHECK, required fields by workflow | reversed intervals rejected |
| DBR-011 | duplicate events/imports do not duplicate actions | unique source key + idempotency transaction | retries/out-of-order and payload mismatch |
| DBR-012 | allocation cannot exceed source amount, currency matches | lock source and validate cumulative amount/sign | concurrent allocations, credit adjustments, mixed currency |
| DBR-013 | corrections traceable | append-only adjustment and audit | historical record changes leave evidence |
| DBR-014 | final financial snapshot immutable except authorized revision | scoped grants + service transitions | edit rejected; new revision succeeds |
| DBR-015 | documents private and tenant-authorized | typed links, object storage ACL and service | wrong tenant or failed scan cannot download |
| DBR-016 | valid latitude/longitude | CHECK + service validity | out-of-range and missing coordinate tests |
| DBR-017 | latest GPS never regresses | conditional deterministic projection update, one row per asset | older update / timestamp tie tests |
| DBR-018 | AI chat ownership and data scope | tenant+membership, per-tool authorization | A/B chats, finance denial, revoked membership, prompt injection |
| DBR-019 | archive preserves required links | NO ACTION FK, business lifecycle rules | physical delete parent rejected |
| DBR-020 | lost updates detected | ROWVERSION and conditional UPDATE | stale token fails with conflict |
| DBR-021 | subtype matches asset type and assignment resolves actual asset | service transaction | tractor as trailer rejected |
| DBR-022 | trip-stop references belong to a load attached to trip | service validates trip_loads | unrelated load stop rejected |
| DBR-023 | delivered, POD-approved, reconciled, invoicable are distinct | separate state transitions | missing POD/cost stays incomplete |
| DBR-024 | position device assigned to asset at recorded time | device assignment interval service | misattributed device rejected |
| DBR-025 | append-only records protected | grants + controlled retention principal | runtime update/delete denied |
| DBR-026 | same financial source not counted twice | canonical expense + source-link validation | same fuel/service expense imported twice |
| DBR-027 | membership role belongs to same tenant | FK + permission service | wrong-tenant role rejected |
| DBR-028 | inspection item belongs to version used by inspection | service check + transactional certification | wrong version rejected |
| DBR-029 | no misleading unknown or stale values | projections return source timestamp/completeness | missing costs unknown; stale GPS labeled |
| DBR-030 | AI cannot mutate business data | allowlisted typed read tools, separate persistence | attempted dispatch via chat rejected |
| DBR-031 | POD review applies to specific bytes | composite version FKs on delivery link and verification, immutable version content, policy-aware read | version 1 approved, version 2 selected and pending → delivery shows pending; replacing bytes requires a new version |
| DBR-032 | A retry cannot disclose an earlier result after reassignment or revocation | current membership and resource authorization on replay, durable actor-scoped key | A queues a stop event, B replaces A, A resubmits → denial, zero additional events |

## Assignment transaction protocol

Verify membership, permission, active driver, subtype and resource references. Begin transaction. Lock all requested stable resource identifiers in consistent order, including release or reassignment operations. Recheck current asset restrictions, driver availability, reservations and trip state after acquiring locks. Reject overlap if existing.start < requested.end AND existing.end > requested.start for blocking status. Insert reservations and assignments, update derived statuses, append audit and outbox, commit. Deadlocks/timeouts yield retryable controlled failures; no partial assignment. Maintenance restrictions must use the same locks. A filtered unique index cannot replace this protocol.

## Financial and event semantics

Use Python Decimal and SQL DECIMAL with documented rounding per currency; store source invoice/expense amount once, allow signed credits under separate approval policy. Split revenue and cost sums before joining; use explicit coverage/mileage basis. No unsupported net profit or HOS conclusion. Provider keys must be stable within documented scope; generate stable source IDs if provider lacks them and validate collision behavior; never guess. Reject same idempotency key with different request hash.
