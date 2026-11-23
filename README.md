# FleetOps

## Local operations demo

Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/start_demo.ps1` from the repository root, then open <http://localhost:18080>. The landing page leads to a passwordless local demo account picker and lets you carry an example question into the AI Copilot. See [docs/demo.md](docs/demo.md) for fleet and dispatch workflows, reports, Copilot, and shutdown. The script creates ignored SQL and session secrets; no provider key is included in this repository.

**Version:** 1.5  
**Prepared:** 2026-11-22  
**Status:** Planning baseline with a runnable local operations demo; validate before production implementation

This repository contains the FleetOps specifications and a runnable local demo for fleet inventory, dispatch availability, last-known GPS, maintenance, documents, recorded costs, reports, and a read-only AI Copilot. The broader operations platform is still planned. Copilot model answers require a separately supplied OpenAI API key with available credit.

## Start here

- When generating system code, use the [feature and test generation instructions](spec-kit/feature-test-generation.md). Gate 0 delivers the first unit, integration and Selenium suites together with the vehicle workflow.
- Read the [release notes](CHANGELOG.md) for changes and remaining gates.
- For product review, start with the five pilot fixtures in §7.1 of [the specification](spec.md). Each defines a user action and an observable result.
- For engineering, run `python3 database/tools/verify_kit.py` at the extracted kit root. The [validation record](docs/database/VALIDATION.md) gives the SQL Server command and the [migration roadmap](docs/database/migration-roadmap.md) maps requirements to delivery groups.

## Files and precedence

| File | Purpose |
| --- | --- |
| [`spec.md`](spec.md) | Product scope, personas, domain workflows, functional/nonfunctional requirements, AI Copilot, acceptance criteria, delivery gates |
| [`docs/architecture-notes.md`](docs/architecture-notes.md) | Target architecture, data and API design, security model, AI orchestration, infrastructure and delivery decisions |
| [`docs/development-and-delivery.md`](docs/development-and-delivery.md) | Docker, VS Code, GitHub, CI/CD, release and rollback specification |
| [`AGENTS.md`](AGENTS.md) | Canonical, cross-agent coding instructions and definition of done |
| [`CLAUDE.md`](CLAUDE.md) | Claude-specific startup and working instructions, referencing `AGENTS.md` |
| [`.cursorrules`](.cursorrules) | Requested legacy Cursor instructions, referencing canonical rules |
| [`.cursor/rules/fleetops.mdc`](.cursor/rules/fleetops.mdc) | Modern Cursor project rule; `.cursorrules` included for compatibility |

**Authority:** `spec.md` defines product scope and acceptance criteria; `docs/architecture-notes.md` defines approved/provisional technical design; `AGENTS.md` defines engineering behavior. If documents conflict, raise the conflict and record a decision instead of silently implementing an assumption.

## Approved stack and open choices

- **Web:** React.js + TypeScript + Vite + Tailwind CSS.
- **Backend:** Python + FastAPI; REST APIs, business rules, authorization, AI tools.
- **Database:** Microsoft SQL Server. Azure SQL Database is the proposed managed production host, not yet contractually chosen.
- **Auth:** Clerk is the selected *working recommendation*; final decision remains Clerk vs Supabase Auth.
- **AI:** Vercel AI SDK (`@ai-sdk/react`) for streaming chat; Python backend integrates with **one** selected OpenAI or Anthropic Claude model through its server SDK. The exact model/provider remains open.
- **Deploy:** Docker images for web, API and worker; Docker Compose locally; GitHub Actions CI/CD with GHCR; Azure Container Apps recommended for production, pending approval. Vercel optional for frontend only. Asynchronous ingestion requires a durable worker/queue.
- **Driver mobile:** Required for full MVP operational workflow; native framework and release packaging not selected. Prototype responsive/mobile web first, and validate whether a separate app is required.

## Before implementation

1. Validate the product assumptions and target customer workflows in `spec.md`.
2. Run the mandatory **architecture spike** in `docs/architecture-notes.md`: Clerk token verification; Azure SQL/SQL Server connectivity from the final Python container, including driver packaging and TLS; AI SDK streaming with a FastAPI endpoint; one end-to-end CRUD test.
3. Scaffold in VS Code following `docs/development-and-delivery.md`; establish Docker Compose, GitHub repository and CI before feature work.
4. Record architecture decision outcomes and lock dependencies only after the spike.
5. Slice the MVP into vertical stories: company/role setup → assets/drivers → loads/dispatch → trips/POD → costs/financials → AI read-only beta.
6. Do not advertise regulatory certification or autonomous dispatch.

## Sources to recheck at implementation time

- Docker Compose: https://docs.docker.com/compose/
- GitHub container registry: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- Azure Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/overview
- AI SDK UI streaming protocol: https://ai-sdk.dev/docs/ai-sdk-ui/stream-protocol
- AI SDK `useChat`: https://ai-sdk.dev/docs/reference/ai-sdk-ui/use-chat
- Clerk Python backend authentication: https://clerk.com/articles/how-to-add-authentication-to-a-python-backend
- Microsoft SQLAlchemy driver integration: https://learn.microsoft.com/en-us/sql/connect/python/mssql-python/sqlalchemy-integration
- Cursor rules: https://docs.cursor.com/context/rules-for-ai

> Dependencies, limits, and SDK APIs change. Confirm version compatibility during the spike; nothing here claims a deployment has been tested.

## Database design companion v1.1
Read [database architecture](docs/database/database-architecture.md), [data dictionary](docs/database/data-dictionary.md), [physical ERD](docs/database/entity-relationship.md), and [Spec Kit database planning instructions](spec-kit/database-planning-instructions.md). The proposed full model is not an approved migration; Feature 001 is scoped to its 17-table foundation subset. The ZIP includes reference SQL, synthetic fixtures and a disposable-database rehearsal. See [validation limits](docs/database/VALIDATION.md).
