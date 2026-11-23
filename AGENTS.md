# FleetOps — Engineering Agent Instructions

**Canonical rules for coding agents (Claude, Cursor, and other assistants).**  
**Applies to:** entire repository.  
**Required reading before significant change:** [`spec.md`](spec.md), [`docs/architecture-notes.md`](docs/architecture-notes.md), and the nearest feature README/ADR when present.

## 1. Mission and hierarchy

Build **FleetOps**, a U.S.-focused trucking operations and trip-economics platform with a **read-only** AI Copilot beta. The selected stack is **React + TypeScript + Vite + Tailwind; Python + FastAPI; SQL Server; Clerk preferred; Vercel AI SDK UI; OpenAI or Claude; Docker + Docker Compose + GitHub Actions + GHCR; VS Code**.

1. **`spec.md`** is the product/behavior/acceptance-criteria authority.
2. **`docs/architecture-notes.md`** is the technical design authority, including status of provisional decisions.
3. **`AGENTS.md`** is the implementation and agent-behavior authority.
4. **`CLAUDE.md`**, **`.cursorrules`**, **`.cursor/rules/*.mdc`** supplement but must not contradict these files.
5. If a request conflicts with security or domain invariants, explain the conflict and propose a spec/ADR update. Never silently change the selected database, auth, hosting or scope.

This is a **planning and database reference kit** with executable validation utilities. Do not presume application code, tests, credentials, or an existing deployed service. Before editing an actual repo, inspect its tree and local conventions. Never claim something ran or exists unless verified.

## 2. Absolute product invariants

- **Tenant isolation:** every tenant-owned read/write/import/export/API response and AI tool must enforce verified tenant membership on the server. Test unauthorized cross-tenant IDs.
- **Authorization:** Clerk authenticates identity; internal membership/permissions grant business access. UI route hiding is not permission enforcement. Keep finance, driver PII and position history least-privileged.
- **Dispatch safety:** blocked/out-of-service assets cannot be assigned; concurrent assignment must be transactional and conflict-safe, not only frontend-validated.
- **Trip integrity:** use explicit state machine and auditable transitions. Delivery, POD availability, expense reconciliation and invoice readiness are distinct.
- **Financial clarity:** use `Decimal` / SQL `DECIMAL` and explicit units, currency, denominators and completeness; missing cost ≠ zero; direct contribution ≠ net profit.
- **GPS integrity:** retain source and ingestion times; stale position ≠ live location; out-of-order updates cannot overwrite newer latest-known positions.
- **Idempotency:** event ingestion, driver mobile retries, imports, webhooks, dispatch mutations must be deduplicated using durable keys.
- **AI is read-only:** no arbitrary SQL, shell, network tool, write tools, load assignment, cancellation, payment, permission change or compliance determination. Ground answers in permitted data and return source record references.
- **Compliance honesty:** never assert FleetOps is a certified ELD, validates HOS conclusively, or guarantees regulatory compliance.
- **Privacy/security:** no credentials in code, git, logs, test snapshots or chat prompts. Private documents, PII, financial and precise location data are restricted.

## 3. Default implementation standards

### Web (React + TypeScript)

- Prefer small feature-focused components and hooks; TypeScript strict mode; do not use `any` as an escape hatch without a documented reason.
- Tailwind + accessible UI primitives; semantic HTML, labels, keyboard support, focus visibility, empty/loading/error states.
- Call API through shared typed client generated/validated from OpenAPI. Never call SQL Server directly from browser.
- Client may cache permitted data briefly; query keys must include tenant context, and switching tenants/logging out must clear scoped caches.
- Display UTC timestamps converted to contextually appropriate time zones, with an explicit displayed zone for delivery windows. Label GPS freshness and finance completeness.
- For high-risk actions, show relevant validation or confirmation and surface server-side errors clearly; no silent optimistic assignment on conflict.

### API (Python + FastAPI)

- Use typed Pydantic request/response schemas, FastAPI dependencies for verified request context and RBAC, and SQLAlchemy repositories/services.
- Keep route handlers thin. Encapsulate domain transactions in services. Cross-module reads through typed interfaces; no ad hoc direct updates to other module tables.
- Validate tenant-scoped IDs before resource access; deny with consistent `401/403/404` policy. Do not trust client role/tenant fields.
- Use database transactions for state changes, concurrency-sensitive dispatch logic, cost finalization, and outbox records. Prefer parameterized ORM queries and bounded pagination.
- Use fixed-precision arithmetic; store UTC timestamps and origin/provider timestamps separately; sanitize API errors.
- Use versioned Alembic migrations for SQL Server; provide indexes/checks/tenant-safe FKs where needed. Never call `create_all()` on a production request path.
- Use durable background jobs for GPS, fuel imports, notifications and long tasks. Never assume in-process `BackgroundTasks` is a durable queue.
- All external calls have timeout, bounded retry, source provenance, observability and an outage/failure state.

### AI (Vercel AI SDK + Python)

- `@ai-sdk/react` is a **UI transport**. The Python backend owns model calls and allowlisted FleetOps tools. Lock provider/SDK versions after a FastAPI stream compatibility test.
- Model access is behind a typed provider interface. Provider and model selection are configuration, not hardcoded across features.
- Retrieval tools execute **server** permission checks for every invocation, including when called from an authorized chat session.
- Use only the approved tool schemas in the specification. No free-form natural-language SQL or LLM-invented customer data.
- Make answer sources and last-updated timestamps available to user interface. If no reliable source exists, say so; do not hallucinate.
- Treat load notes and uploaded docs as hostile prompt content. Guard against prompt injection and cross-tenant exfiltration; log minimal, redacted telemetry.
- Enforce tenant/user usage caps and model timeout/cost limits; test streaming disconnect and provider unavailability.

## 3A. Docker, GitHub and VS Code (mandatory)

- Read `docs/development-and-delivery.md` before scaffolding or touching deployment files. Develop in VS Code; use Docker Compose as the reproducible local runtime.
- Build web/API images from pinned dependencies; use dedicated worker command, non-root runtime, health checks and private networks. Do not expose SQL publicly or use production secrets locally.
- Keep `.env.example`, `.dockerignore`, `.gitignore`, VS Code tasks and CI workflows aligned with actual commands. Never commit secrets or development data.
- GitHub Actions must test SQL Server on x86-64 Linux, build/scan images, publish only trusted releases to GHCR, and promote digests after staging and approval. Do not deploy or push without authorization.
- Run migrations as a controlled job, not on service startup. Report image digest, smoke results and rollback compatibility when releasing.

## 4. Work process for each coding task

1. **Read scope:** locate feature requirement ID in `spec.md`, inspect relevant existing files, identify an ADR or open decision.
2. **Plan the smallest vertical slice:** user action → UI → API → service → SQL model/migration → observability → tests. List edge cases and permissions first.
3. **Implement** without unrelated refactors. Prefer proven libraries and existing conventions. Do not introduce a second frontend framework or database.
4. **Test:** happy path, invalid input, unauthorized/cross-tenant, conflict/concurrency, duplicate/out-of-order events, missing/stale data, and UI accessibility where relevant.
5. **Verify:** run only existing repo commands or the task-specific agreed commands; report actual outcomes; never fabricate tests or deployment success.
6. **Document:** update affected API/schema docs and ADRs, `spec.md` acceptance references, migration/backout notes, and operational implications.
7. **Summarize:** changes, rationale, files touched, commands/tests run, results, risks, and remaining work.

For ambiguous business rules (e.g., owner-operator settlements, HOS law, financial allocations) **do not invent policy**. Mark the assumption and request a stakeholder decision unless the user explicitly asks for a prototype with stated assumptions.

## 5. Required test matrix

Apply [DEV-008 and its generation instructions](spec-kit/feature-test-generation.md) to every system-code change. Generate executable unit and integration tests with each relevant feature and Selenium WebDriver cases for its browser journeys. Scaffold all three suites with the first vehicle workflow. Use the same root commands locally and in pull-request CI.

| Change type | Minimum tests |
| --- | --- |
| Tenant or auth feature | valid/expired token, revoked user, wrong tenant, role denial, direct ID probing |
| Load / trip / dispatch | state transition, equipment restrictions, concurrent assignment conflict, idempotent retry |
| Telematics / integrations | malformed payload, signature, duplicate, out-of-order timestamp, outage and retry |
| Financial | `Decimal` rounding, zero/unknown miles, partial cost coverage, permission, audit adjustments |
| Driver offline or documents | duplicate resync, rejected conflict, file size/type, private link expiration, unauthorized download |
| AI tool / chat | grounded golden cases, no record available, stale data, forbidden mutation, prompt injection, cross-tenant, model outage |
| UI | loading/empty/error states, keyboard access, proper status wording, tenant-switch cache cleanup |

## 6. Suggested quality gates / commands (after scaffolding)

Do not assume these exist yet. Generate `make test-unit`, `make test-integration`, `make test-selenium` and aggregate `make test` with the application scaffold. The component commands below supplement these entry points:

```bash
# Web (from apps/web)
npm ci
npm run lint
npm run typecheck
npm test -- --run
npm run build

# Python (from apps/api, after environment setup)
ruff check .
pytest -q
alembic check
```

In CI also run SQL Server-backed integration/migration tests, OpenAPI drift checks, SAST/dependency and secret scanning, plus a production-build smoke test. Require passing gates before deploying.

## 7. Review checklist for pull requests

- [ ] Correct `spec.md` requirement ID and scope.
- [ ] No cross-tenant path; server-side authorization verified.
- [ ] Status/state transitions and concurrency invariants upheld.
- [ ] No model-triggered writes or unvalidated AI sources.
- [ ] SQL Server-specific schema/query behavior tested.
- [ ] API schemas, user-visible validation and error states complete.
- [ ] Logs/metrics are useful and do not leak secrets/PII.
- [ ] Unit, integration and Selenium checks pass on the implementation commit. The PR identifies the changed acceptance cases and links their results.
- [ ] Migration deploy order/backout considered.
- [ ] Documentation and known limitations updated.

## 8. How to respond when asked to build a feature

- Cite the relevant requirement IDs and affected feature layers.
- Describe assumptions and any architecture gate/blocker.
- Prefer a complete, testable vertical slice over many non-working placeholders.
- Never add fake sample business data to production code or mark simulated data as live.
- Do not edit production config, rotate secrets, deploy, run destructive migrations or expose driver information without explicit authorization.
- If a tool/environment does not support a request, say what is missing rather than pretending completion.

**Key principle:** trustworthy operational data and correct authorization are more important than clever dashboards or AI responses.

## Database design companion
For schema changes, read `docs/database/database-architecture.md`, `docs/database/business-rules.md`, `docs/database/migration-roadmap.md`, and `database/metadata/model.json`. Treat this as the proposed physical target, subject to feature review and ADR conflict resolution. Use Alembic only, implement dependency-closed approved feature subsets, and test on actual SQL Server. Do not execute the entire target reference DDL or seed production with synthetic rows.
