# FleetOps — Product and System Specification

**Document:** `spec.md`  
**Version:** 1.5  
**Date:** 2026-11-22  
**Status:** Implementation baseline / customer-validation pending  
**Owner:** Product + Engineering  
**Companion:** [`docs/architecture-notes.md`](docs/architecture-notes.md)

> This specification starts a new repository; it does **not** assert that any feature, provider integration, regulatory compliance, or deployment has been completed.

## 1. Executive summary

FleetOps is a role-based trucking **fleet operations and trip economics platform** for initial U.S. dry-van truckload carriers with approximately **10–150 power units**. It connects fleet assets and drivers to commercial loads, dispatch assignments, trip execution, delivery evidence, direct expenses, and profitability. An embedded **FleetOps AI Copilot** enables authorized users to ask natural-language questions about their records. At MVP, Copilot is **read-only**.

**Core operational loop:** Create load → validate availability → assign truck/driver/trailer → execute stops → monitor exceptions → capture proof of delivery → reconcile direct costs → report contribution.  
**Differentiator to validate:** a coherent workflow and reliable trip/vehicle economics for small and midsize carriers, rather than another generic GPS or ELD dashboard.

### 1.1 Primary assumptions

- Initial customer: U.S. interstate, for-hire, dry-van truckload carrier. Subsequent LTL, reefer, flatbed, and non-U.S. requirements are out of MVP scope.
- Initial product is company-centric but data architecture is multi-tenant from day one.
- Telematics/ELD comes from authorized third-party providers; FleetOps is **not** a certified ELD.
- Dollar amounts are USD; distance is miles; fuel is gallons. Timestamps are stored UTC and displayed in the applicable local time zone.
- First commercial release may use a responsive driver web experience; a separate driver mobile app is a release decision subject to field tests. Required *driver capabilities* remain in scope.

### 1.2 Selected technical constraints

| Concern | Choice | Status |
| --- | --- | --- |
| Web client | React.js, TypeScript, Vite, Tailwind CSS | Chosen |
| Backend/API | Python, FastAPI | Chosen implementation |
| Database | Microsoft SQL Server; Azure SQL Database proposed for production | SQL Server chosen; host provisional |
| Identity | Clerk preferred over Supabase Auth | Pending spike/approval |
| AI chat UI | Vercel AI SDK (`@ai-sdk/react`) | Chosen |
| AI model | Anthropic Claude **or** OpenAI | Provider/model TBD |
| Deployment | Docker + Docker Compose + GitHub Actions + GHCR | Required; Azure Container Apps proposed; Vercel optional frontend |
| Development | VS Code + Git + GitHub | Required; Dev Containers optional |
| Jobs | Durable queue/worker service | Provider TBD |
| File storage | Private object storage + signed access | Provider TBD |

## 2. Validation plan and business goals

### 2.1 Problem hypotheses

- **H1:** Dispatchers spend excessive time reconciling load, driver, and vehicle status across disconnected tools.
- **H2:** Finance and owners cannot reliably measure trip contribution without manual expense reconciliation.
- **H3:** Service defects, qualification expirations, and stale GPS data generate late or unclear operational responses.
- **H4:** Read-only AI questions let managers retrieve verifiable, authorized answers faster than navigation alone.

### 2.2 Validation experiments / go-no-go

1. Interview **15–20** qualified owners, dispatchers, finance, maintenance, and safety staff; document current workflows, paid tools, most recent costly incidents, and procurement authority. *Proposed gate:* ≥70% report at least one recurring high-value pain point.
2. Test an interactive prototype with **5–8** operational users; complete load assignment, delayed trip investigation, maintenance identification, profitability review, and AI query tasks. *Proposed gate:* ≥80% task success without moderator intervention.
3. Run a controlled pilot with **2–3 carriers**; compare baseline dispatch times, on-time POD capture, expense coverage, and answer correctness. Do not extrapolate pilot outcomes to the market.
4. Validate price using concrete paid-pilot offers; *proposed gate:* three genuine paid or equivalent purchasing commitments before full commercial expansion.

These thresholds are planning hypotheses, not market facts.

### 2.3 Measurable pilot targets

| KPI | Proposed pilot threshold | Measurement |
| --- | --- | --- |
| Onboarded assets | ≥90% of in-scope trucks | valid imported / expected |
| Load workflow adoption | ≥80% of pilot loads | FleetOps-managed / in-scope |
| Dispatch assignment time | ≥25% faster than baseline | median elapsed time |
| Proof of delivery | ≥90% received within 24h | timely POD / delivered loads |
| Direct cost completeness | ≥90% of completed pilot trips | trips meeting specified cost checklist |
| AI supported-query accuracy | ≥95% on curated golden set | correct / tested outputs |
| AI unauthorized disclosures | 0 in security test suite | security assertions |

## 3. Personas and permissions

| Role | Top jobs |
| --- | --- |
| Company admin / owner | Users, equipment, business performance, tenant settings |
| Operations manager | Overall status, asset availability, exceptions |
| Dispatcher | Loads, assignments, trip status, driver communication |
| Driver | See own trips, update progress, upload POD/defect evidence |
| Maintenance manager | Service schedules, repairs, release status |
| Safety / compliance officer | Qualification records, expirations, inspection records |
| Finance user | Rates, expenses, reconciliation, reporting |
| Platform support | Infrastructure diagnostics; no unrestricted customer access |

**Policy:** permissions are resolved in FastAPI from authenticated user **plus active tenant membership**. Frontend hiding is not enforcement. Tenant records, driver PII, and financial figures require least-privilege controls. Multi-company users must select an authorized company; tenant IDs supplied by clients are never sufficient proof of access.

## 4. Scope and roadmap

### P0 — MVP: end-to-end operational loop

- Company/account setup, login, MFA for privileged users, membership and RBAC.
- Import/create customers, trucks, trailers, and drivers.
- Load creation with ordered stops, pickup/delivery time windows, equipment needs, and revenue lines. Each pilot trip carries one commercial load and may have several delivery stops.
- Dispatch board, assignment validation, conflict handling.
- Trip lifecycle, events/timeline, delay/breakdown exceptions.
- One verified telematics integration, latest-known vehicle map with location freshness.
- Driver mobile-friendly assigned-trip view, status update, POD upload, simple offline submission queue.
- Basic maintenance schedules and vehicle out-of-service controls.
- Manual trip expenses, direct trip contribution, data-completeness labels.
- KPI dashboard, CSV export, audit history, activity alerts.
- **AI Copilot beta:** limited, read-only, tool-grounded, source-linked chat on permitted records.

### P1 — operational expansion

Maintenance work orders and inspection workflows; fuel-card imports and reconciliation; read-only HOS/ELD integration; qualification expiry workflows; invoice preparation/export; IFTA-supporting records; additional telematics; advanced reporting.

### P2 — later / conditional

Optimized dispatch suggestions, predictive maintenance, ETA forecasting, customer portal, automated summaries, complex settlements, multi-terminal needs, self-service SaaS billing. Any AI **write** actions require a new security review and explicit approval controls.

### Explicit exclusions

Proprietary GPS/ELD hardware, certified ELD functionality, guaranteed FMCSA/IFTA compliance, freight marketplace, payroll/general-ledger replacement, autonomous dispatch, AI payment approval, and unsupervised modification of fleet records.

## 5. Information architecture and UX

**Main web navigation:** Overview / Dispatch / Loads & Trips / Fleet (trucks, trailers, drivers) / Maintenance / Fuel & Expenses / Finance / Reports / Compliance (stage-gated) / Settings. AI Copilot opens as a dismissible contextual right panel and does not obscure dispatch-critical controls by default.

**Key pages:**

| Page | Essential components and interactions |
| --- | --- |
| Overview | KPI cards, exception list, upcoming pickups/deliveries, last-known map, freshness indicators |
| Dispatch board | Unassigned loads, assigned trips, time windows, filters, conflict explanations, accessible assignment dialog |
| Load details | Customer, revenue lines, ordered stops, requirements, documents, linked trip, change history |
| Trip details | Timeline, assignments, GPS, stop statuses, exceptions, POD, expense coverage |
| Vehicle details | Unit/VIN/status, driver, latest location and age, maintenance, documents, cost overview |
| Driver view | Authorized personal assignments, stop directions, status updates, upload/sync state |
| Expenses/finance | Trip revenue, direct costs, data completeness, transparent CPM/RPM/operating ratio definitions |
| Copilot | Suggested questions, streamed answer, source record links, freshness notes, feedback, error states |

**UX rules:** status uses text + icon, never color alone; all date-times show timezone; never call a stale position “live”; each KPI drills to a supported list; forms have validation/errors; keyboard navigation and accessible focus; show loading/empty/offline/sync conflict states.

## 6. Domain requirements and acceptance criteria

Use IDs when creating stories and tests. `MUST` is P0 unless identified otherwise.

### 6.1 Identity and tenants

**AUTH-01** — Provider-backed sign-in/session handling and verified backend identity. Use Clerk for the proposed architecture spike; final provider selection follows ADR-004. **AC:** revoked/expired/invalid tokens cannot call protected APIs; MFA can be enforced for company administrators.

**AUTH-02** — Membership and role-based permissions, verified on every relevant API. **AC:** tenant A cannot read/write tenant B; dispatcher cannot access finance-only endpoints; driver sees only own assigned trip information.

**AUTH-03** — Company onboarding and CSV imports. **AC:** preview shows row errors/duplicates; validation errors are actionable; retry/import is deduplicated; imported counts are auditable.

### 6.2 Assets and drivers

**FLT-01** — Trucks: unit number, VIN, make/model/year, plate/jurisdiction, odometer, ownership type, status, registration/insurance metadata. **AC:** per-tenant unit number uniqueness; VIN validity policy documented; inactive/out-of-service assets not silently assigned.

**FLT-02** — Trailers: asset identity, category, condition, status, registration, assignment and service history. **AC:** conflicting assignment blocked unless expressly permitted.

**DRV-01** — Driver profiles: active status, contact, employment type, CDL/qualification metadata and expiration, supported availability. **AC:** sensitive fields hidden based on role; expired qualifications surface a warning or hard block per applicable legal and operational policy.

**DRV-02** — Distinguish “available to dispatch” from “HOS eligibility verified.” **AC:** absent/stale HOS data displays *not verified*, not compliant.

### 6.3 Loads, trips and dispatch

**LOAD-01** — Customer-linked load with load number, freight type/weight, equipment requirements, revenue lines, ordered pickup/delivery/multi-stops, appointments/time zones, references, attachments. **AC:** required fields validated; draft persists; unique per-tenant load number.

**DISP-01** — Authorized dispatcher assigns driver, truck, optional trailer. **AC:** active statuses, vehicle safety status, overlap and equipment compatibility checked inside transaction; concurrent attempts cannot create conflicting active assignments.

**DISP-02** — Dispatch board filters/searches by date, driver, equipment, load and exception. **AC:** a keyboard-operable assignment path exists; validation details displayed before confirmation.

**TRIP-01** — Default trip progression: `DRAFT → PLANNED → ASSIGNED → EN_ROUTE_TO_PICKUP → AT_PICKUP → IN_TRANSIT → DELIVERED → CLOSED`; `CANCELLED` allowed by controlled transition rules. **AC:** invalid transitions rejected; event history records actor, source and timestamp.

**TRIP-02** — Operational exceptions (late stop, breakdown, unavailable driver, missing POD) have severity, owner, status and resolution. **AC:** exceptions can be assigned and resolved independently of trip state.

**TRIP-03** — Completing delivery does not automatically finalize costs or issue an invoice. **AC:** delivery, trip closure, expense reconciliation and invoice readiness are separate recorded states.

### 6.4 Telematics and driver workflows

**GPS-01** — Ingest GPS updates from one provider. **AC:** provider vehicle identity is mapped, timestamps and source retained, duplicate events ignored, out-of-order points cannot replace a newer last-known position.

**GPS-02** — Last-known map and location history. **AC:** marker opens authorized asset/trip; stale/offline is visible; position timestamp displayed; history restricted by role/retention.

**MOB-01** — Driver sees assigned trips, stops, instructions and dispatcher contact. **AC:** unrelated loads are inaccessible even by direct URL.

**MOB-02** — Driver submits supported arrival/departure/delay/delivery events with client-generated event IDs. **AC:** offline submissions reconcile without duplicate status transitions; rejected conflicts show correction workflow.

**DOC-01** — Secure POD upload and association to a trip. **AC:** validated file type/size, malware scanning or quarantine policy, private access, proper source/actor/timestamp, authorized download only.

### 6.5 Maintenance, expenses and financials

**MNT-01** — Time/odometer-based service schedule and overdue alerts. **AC:** service deadlines displayed per truck; schedule changes audited.

**MNT-02** — Authorized out-of-service flag blocks prohibited dispatch. **AC:** only appropriate release workflow can restore dispatch availability; repairs/inspection records are retained.

**COST-01** — Manual trip expenses with category, amount, currency, transaction date, attribution, receipt, and status. **AC:** negative/zero values validated per type; duplicate import/event controls; modifications audited.

**FIN-01** — Revenue lines and `direct_trip_contribution = sum(revenue_lines) - sum(direct_trip_expenses)`. **AC:** estimates/incomplete/reconciled labels shown; shared fleet overhead excluded unless allocation rule explicitly implemented.

**FIN-02** — `CPM = included_costs / applicable_miles`, `RPM = recognized_revenue / applicable_miles`; denominators explicitly labeled (loaded vs total miles). **AC:** zero denominators return “not available,” not division errors; currency/units disclosed.

**FIN-03** — Invoice readiness and expense finalization are independent from delivered state. **AC:** user sees missing POD/expense components before finalization; unauthorized user cannot edit finalized figures without approved adjustment flow.

**RPT-01** — Fleet overview and authorized filtered CSV reports. **AC:** consistent time-zone/currency definitions, permissions on export, active filter state shown, incomplete data noted.

### 6.6 AI FleetOps Copilot — P0 beta

**AI-01** — Embedded `@ai-sdk/react` chat with prompt suggestions and contextual entry points on vehicle, trip, maintenance and permitted finance screens. **AC:** loading, interruption, failure, source attribution and feedback supported.

**AI-02** — **Read-only** tool allowlist: `getFleetSummary`, `getAvailableVehicles`, `getDelayedTrips`, `getTripStatus`, `getVehicleLocation`, `getMaintenanceDue`, `getDriverAssignments`, `getTripFinancialSummary`. **AC:** all tools call authorized backend domain services; no arbitrary SQL, URL fetch, or mutation tool exposed to model.

**AI-03** — Grounded answers with citations to accessible records, source timestamps, scope, financial completeness. **AC:** no invented truck IDs, locations, trips or amounts; no record access granted by prompt text.

**AI-04** — Context binding. **AC:** "How is this truck performing?" on a vehicle page references the server-validated active vehicle context; chat cannot substitute a cross-tenant vehicle ID.

**AI-05** — Refuse unsupported actions accurately. **AC:** “Assign Truck 42” directs user to dispatch screen, not an autonomous write; no approval/payment/compliance certification.

**AI-06** — Prompt injection and abuse resistance. **AC:** untrusted load notes/docs are never promoted to instructions; unauthorized prompts fail safe; tenant/user rate and cost controls exist.

**AI-07** — Chat history per tenant/user with configured retention, deletion controls and privacy notices. **AC:** conversations cannot leak to other users/tenants; user feedback attaches to exact response ID.

## 7. Representative end-to-end acceptance scenarios

1. **Create and assign:** Given a valid draft load and available equipment, the dispatcher plans a trip for the load, then assigns a truck and driver. Only the committed assignment appears on the driver’s trip list.
2. **Concurrent dispatch:** Two dispatchers try to assign same truck for overlapping windows; exactly one assignment commits and the other receives `409 CONFLICT` with explanation.
3. **Out of service:** Vehicle has an unresolved dispatch-prohibiting maintenance condition; server rejects assignment regardless of UI state.
4. **Late delivery:** Arrival estimate crosses configured threshold; operational exception appears and is traceable to a trip.
5. **Offline driver:** A queued arrival submission retries; only one event is stored; conflict is surfaced if the trip moved on in the meantime.
6. **Stale location:** Last location outside configured freshness threshold; UI and Copilot disclose last-seen timestamp, not “current location.”
7. **Incomplete expenses:** Trip delivered with missing mandatory expense categories; contribution marked provisional; finalization disallowed until policy conditions met.
8. **Cross-tenant:** User from tenant A tries list/detail/export, attachment URL, and AI tool access for tenant B; all denied without record disclosure.
9. **AI grounded question:** “Which trucks need service?” returns only authorized, matching maintenance records with source links; if none, responds with a verified empty result.
10. **AI prohibited action:** “Cancel load 102” produces no change to a load, trip or other business record and invokes no external action. Chat history and redacted usage telemetry follow AI-07.

### 7.1 Pilot acceptance fixtures

Use synthetic records. Run these cases through the named user entry points when their milestone is implemented. Each row defines an observable pass condition.

| Case and requirements | Initial condition and action | Required observation |
| --- | --- | --- |
| Plan and assign • LOAD-01, DISP-01, MOB-01 | A dispatcher plans a trip from a saved load with ordered stops. Assignment fails because its tractor is restricted. After an authorized release, dispatch assigns it and retries the same submission. | The planned trip remains available after rejection. One committed assignment and one assignment event appear after retry. The assigned driver sees the ordered stops. |
| Reassign • DISP-01, MOB-02 | Driver A queues a stop update offline. Dispatch replaces A with B for that trip before A reconnects. | A receives a denial on resync. B sees the current assignment. No stop or trip state changes from the denied submission. |
| Execute stops • LOAD-01, TRIP-01, MOB-02 | A trip has a pickup and two required delivery stops. The driver completes the first delivery and submits the same event twice. | Only that stop is completed once. The trip remains in transit until all required deliveries are confirmed. Delivery and POD status are shown separately. |
| Collect evidence • DOC-01, TRIP-03, FIN-03 | The driver registers a POD for a delivery. Its file is awaiting scan, then fails validation. A replacement passes the approved verification flow. | The first version never satisfies the POD requirement. The replacement is traceable to the delivery. Readiness is reevaluated under approved policy and expense reconciliation retains its own status. |
| Reconcile and report • FIN-01–03, RPT-01, AI-03 | A single trip has two allocated revenue lines (USD 900 and 300), two complete direct costs (USD 100 and 200), 400 loaded miles and 500 total miles. Compare the finance screen, filtered CSV and permitted Copilot summary for the same revision. | Each reports USD 900 direct contribution. Where total miles are selected, CPM is USD 0.60 and RPM is USD 2.40. With an unknown required cost, completeness becomes provisional. With missing miles, the affected per-mile metric is unavailable. |

## 8. API and data contracts (normative intent)

All protected APIs live under `/api/v1`, accept a verified user session, and resolve active tenant membership server-side. OpenAPI is source of truth for HTTP contracts; typed frontend clients must be generated or validated against it.

| Method / endpoint | Scope |
| --- | --- |
| `GET /api/v1/me` | current user, tenant memberships, effective permissions |
| `GET/POST /api/v1/vehicles` | company-scoped asset list/create |
| `GET/POST /api/v1/drivers` | company-scoped driver list/create |
| `GET/POST /api/v1/loads` | list/create commercial loads |
| `GET /api/v1/loads/{id}` | load, stops and authorized financial fields |
| `POST /api/v1/trips` | dispatcher plans a trip from one tenant-owned load and its ordered stops, returns trip ID and version for assignment, retries reuse the original trip |
| `POST /api/v1/trips/{id}/assignments` | validated, idempotent equipment/driver assignment |
| `POST /api/v1/trips/{id}/events` | controlled lifecycle/event append |
| `GET /api/v1/vehicles/{id}/positions` | authorized GPS history |
| `POST /api/v1/trips/{id}/documents` | register uploaded private document |
| `GET/POST /api/v1/expenses` | expenses according to role |
| `GET /api/v1/reports/trip-contribution` | finance-authorized report |
| `POST /api/v1/ai/chat` | authorized chat with streaming transport |

**API conventions:** typed validation errors (`400/422`), `401` unauthenticated, `403` forbidden, `404` unknown/non-disclosable resource, `409` conflicts, `429` rate limit; cursor pagination; sort/filter allowlists; idempotency keys for consequential POSTs; request IDs; optimistic version control on conflicting writes; UTC ISO timestamps, decimal strings for money, units and currency present where needed.

## 9. Data integrity and operational rules

- SQL Server is authoritative; AI outputs, maps and cached dashboards are derived views.
- Use tenant-owned records and tenant-scoped foreign key constraints. Asset IDs, driver IDs, load IDs, and trip IDs must never be resolved without tenant validation.
- Finance uses `DECIMAL`, never binary floats; explicit rounding, adjustment and reconciliation policy.
- Location points retain `source_observed_at` and `received_at`; late arrivals do not overwrite newer latest-known records.
- Deduplicate imports, webhook events, mobile submissions and telematics events using durable source/event keys.
- Preserve immutable audit records for permissions, rates, assignments, safety status and financial finalization.
- Files live in private storage with expiry-controlled download access, validation and scanning/quarantine policy.
- HOS presence or driver availability never equals verified legal ability to drive; compliance features support recordkeeping only.

## 10. Nonfunctional requirements and test gates

| Dimension | Proposed MVP target / gate |
| --- | --- |
| Security | zero cross-tenant leaks in automated matrix; least privilege enforced server-side |
| API latency | p95 under 500ms for ordinary indexed reads at pilot load, excluding third-party calls |
| Availability | pilot target 99.5% excluding agreed maintenance; instrument before promising SLA |
| Location | provider-specific freshness thresholds; stale data visibly labeled |
| AI latency | target median first answer within 5s for simple supported queries, dependent on provider |
| AI accuracy | curated golden query set ≥95% correct; zero unauthorized disclosures |
| Resilience | durable retries and dead-letter path for external events; restore drills |
| Accessibility | target WCAG 2.2 AA for supported web workflows |
| Observability | structured logs, trace IDs, metrics, alerting, non-sensitive audit trails |
| Mobile reliability | offline submission queue, idempotent sync, visible conflict handling |
| Migration | forward migration with documented rollback/compensation plan; no ad-hoc prod schema edits |

**Automated acceptance (DEV-008).** Generate unit tests, FastAPI integration tests on SQL Server, and Selenium WebDriver browser tests alongside the code. Use the [feature and test generation instructions](spec-kit/feature-test-generation.md) for commands, fixtures and CI evidence. Include auth/tenant, API contract, AI evaluation, event replay and performance cases as their features ship. Pilot operators perform manual UAT.

## 11. Milestones and exit criteria

**Gate 0 — architecture spike:** scaffold from VS Code; run Docker Compose with React, FastAPI and SQL Server; verify Clerk-authenticated CRUD, container driver/TLS, AI SDK-compatible streaming, health checks, migration and GitHub Actions CI. Build and publish immutable images to GHCR, deploy the same images to an approved staging container host and rehearse rollback. Record evidence and ADRs before feature expansion. See `docs/development-and-delivery.md`.

**Gate 1 — foundations:** company, memberships, users, assets, drivers, imports, role-aware navigation; cross-tenant tests passing.

**Gate 2 — operational loop:** loads, stops, dispatch, trip events, one GPS provider, driver updates, POD, basic maintenance and alerts.

**Gate 3 — financials and AI beta:** direct cost/revenue reporting, reconciliation labels; grounded read-only Copilot; evaluation, injection, cost/latency, security tests.

**Gate 4 — controlled pilot:** end-to-end UAT; operational monitoring/backup/incident runbook; source freshness/cost-completeness checks; approved known limitations; customer trial outcomes.

## 12. Open decisions / do not silently assume

1. Internal single-carrier product first or commercial multi-company SaaS launch?
2. Full native driver app vs responsive web pilot? Which offline requirements are contractual?
3. Which telematics provider has a verified API, consent, pricing, and update rate?
4. Clerk vs Supabase Auth final selection and organization model?
5. Azure SQL edition/region, container host, network strategy, and supported Python driver in the Linux API image?
6. AI provider/model, data processing terms, retention and model budget?
7. Exact trip direct-cost categories, accounting method, invoice readiness rules, shared-cost allocations?
8. Required state/insurance/qualification compliance policies and legal sign-off?
9. Storage, queue/worker and notification providers?
10. What historical migrations are needed and what level of SaaS self-service is required?

## 13. Definition of ready / done

**Ready:** user role, business goal, UI state, dependencies, API contract, tenant/permission scope, validations, edge cases and testable criteria documented.  
**Done:** reviewed code; data migrations and OpenAPI updated; DEV-008 tests are committed with the feature and all three required CI checks pass; permission, accessibility, empty/error states implemented; audit/metrics added; QA and product acceptance complete; deployment/backout notes recorded. If tests were not executed, explicitly state which and why.

## 14. Engineering delivery requirements (P0)

| ID | Requirement / acceptance condition |
| --- | --- |
| DEV-001 | Fresh clone can be opened in VS Code and started with documented Docker Compose commands using local-only configuration. No production credentials needed. |
| DEV-002 | Web, API and worker build reproducible Linux container images from lockfiles; SQL Server-backed integration tests run on Linux x86-64. |
| DEV-003 | GitHub pull requests enforce lint, types, tests, migrations, tenant isolation, container builds and vulnerability/secret checks. |
| DEV-004 | Trusted releases publish immutable image digests to GHCR; staging and production promote the identical tested digests. |
| DEV-005 | Deployment requires an approved container host, environment separation, explicit migration step, health/smoke checks, production approval and documented rollback. |
| DEV-006 | API and worker run as non-root; SQL is not publicly exposed; secrets are injected at runtime; backup and restore are demonstrated before pilot. |
| DEV-007 | VS Code tasks, debugging instructions and extension recommendations are maintained alongside the code. |
| DEV-008 | Generate code and executable tests in the same feature change. The first vehicle workflow must pass unit, real SQL Server integration and Selenium browser suites locally and in pull-request CI. Later features extend coverage for each changed behavior and user journey. |

Delivery design and scaffolding sequence: [`docs/development-and-delivery.md`](docs/development-and-delivery.md). The app and pipeline do not exist yet.

## 15. Reference links (verify current versions)

- https://docs.docker.com/compose/
- https://docs.github.com/en/actions
- https://learn.microsoft.com/en-us/azure/container-apps/overview
- https://ai-sdk.dev/docs/ai-sdk-ui/stream-protocol
- https://clerk.com/articles/how-to-add-authentication-to-a-python-backend
- https://learn.microsoft.com/en-us/sql/connect/python/mssql-python/sqlalchemy-integration
- https://www.fmcsa.dot.gov/hours-service/elds/general-information-about-eld-rule

**End — spec.md v1.5**
