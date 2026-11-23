# FleetOps local demo

This is a **local operations demo** of FleetOps. It covers the vehicle slice plus bounded demonstrations of FLT-01/02, DISP-01, GPS-02, MNT-01/02, registration/insurance document metadata, operating costs, and RPT-01. The two carriers, accounts and starting records are fictional. It runs only on the local workstation with a separate `fleetops_demo_001` SQL Server Developer database and a named Docker volume. The web port binds to `127.0.0.1:18080`; SQL Server has no host port.

## Start

From PowerShell in the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/start_demo.ps1
```

The first run generates ignored `.env.demo` with random local credentials. Open <http://localhost:18080>. Sign in as `demo_creator` or `demo_reader` using the `FLEETOPS_DEMO_PASSWORD` value in `.env.demo`. Keep that file private. The demo password and session secret are never baked into images. Re-running the start script preserves registered trucks in the named SQL volume. It also runs the bounded Alembic migration and idempotent fictional seed jobs before starting the API.

## Show

1. Sign in as `demo_creator` and select **Northstar Freight (Demo)**. Open the seeded `DEMO-101` truck.
2. Register a new truck with a fresh unit number, make, model, model year and ownership type. Open it, then refresh to show it persisted.
3. Try the same unit number again. The API reports a conflict without a second truck.
4. Switch to **Lakeside Logistics (Demo)**. Its seeded `DEMO-202` appears; Northstar's new truck does not.
5. Sign out and sign in as `demo_reader`. The reader can inspect trucks but has no registration action. Direct API creation is also denied.

## New demo views

- **Overview / Fleet:** current counts and status graphs, truck/trailer inventory, ownership, terminal, odometer and status. A creator can register trucks and trailers.
- **Dispatch:** reserve a truck and optional trailer against a unique demo trip reference and UTC-backed time window. The API checks current status and overlap inside a SQL transaction using per-asset locks; same-reference retries return the prior assignment. This demo has no driver, load, HOS or equipment-compatibility workflow.
- **GPS:** view the last observed position, source, received time and freshness. Creator-entered observations only update latest-known position when newer. There is no provider ingestion, location history or live map.
- **Maintenance:** set service due date/mileage and odometer; record a note when restricting or releasing equipment. Restriction and assignment share the same asset lock. This is not an inspection or compliance certification.
- **Documents:** creator-only PDF/PNG/JPEG upload and authenticated download for registration and insurance records, limited to 1 MB. This local SQL file store is illustrative; it has no malware scan, quarantine, review workflow, signed object link or production retention controls. Do not upload real driver/customer data.
- **Costs / Reports:** creator-only USD expenses and date-filtered cost graph/CSV; fleet counts have a status filter and CSV. Totals use recorded expenses only. Cost coverage is unknown, and cost per mile is unavailable because period mileage is not recorded. Do not treat totals as net profit.
- **Ask Copilot:** read-only AI chat about the selected carrier's fleet, equipment assignments, last-known GPS, maintenance, and (for finance-permitted creators) recorded costs. Open the right panel with **Ask Copilot**. Answers stream through the pinned AI SDK UI protocol and carry separately generated source record chips with query timestamps. The backend queries the live demo SQL database through fixed read functions and sends only bounded, authorized facts to the configured model. The model cannot run SQL or mutate records. The chat stores member-scoped messages for seven days, permits deletion and answer feedback, and caps each member at 25 requests per UTC day.

To enable model answers, set `OPENAI_API_KEY` in the PowerShell environment before running `tools/start_demo.ps1`; optionally set `FLEETOPS_AI_MODEL` (default `gpt-5.4-mini`). The key is passed only to the API container at runtime and is never baked into either image. The AI provider account needs available credit and outbound HTTPS. If the provider is unavailable, the chat shows an error; it never fabricates a model answer. Direct action requests and reader requests for costs receive server-enforced refusals without a model call. Uploaded document contents, driver PII and SQL credentials are not sent to the model. Only use fictional demo data here.

The new records live in a `demo` SQL schema added by Alembic revisions `0004_demo_operations` and `0005_demo_ai_chat`, alongside the existing tenant-scoped asset tables. They are a disposable prototype of these workflows, not substitutes for the production tables and services in `database/metadata/model.json`. The API still resolves active SQL membership for each request; financial reads have a separate creator permission. All records remain carrier-scoped by API predicates and SQL row-level security.

**Migration/backout:** the migrations are additive and preserve the named demo volume. They have no automatic downgrade because assignment, cost, document and chat records may exist. To back out the UI, use the previous image while retaining the schema; a production schema plan is a separate feature review.

The UI uses a local demo sign-in with a signed, HTTP-only session cookie. The backend resolves active SQL membership and `fleet.vehicle.read/create` capability on each protected request. This is **not Clerk** or a production authentication option. The API refuses to enable these routes outside `FLEETOPS_ENV=demo`. Do not expose port 18080 beyond loopback, reuse the local credentials, or use the Developer Edition database for production.

## Operate

```powershell
docker compose --env-file .env.demo -f compose.demo.yaml ps
docker compose --env-file .env.demo -f compose.demo.yaml logs --tail 80 api web
docker compose --env-file .env.demo -f compose.demo.yaml down
```

Routine `down` preserves the demo database. Deleting the named volume would delete registered trucks; this guide does not include a reset command.

## Scope and remaining work

The demo still does not implement real loads/trips, driver assignment, trip economics or telematics ingestion. Copilot is a local beta over these demo records, not the full AI-01–07 production feature: provider streaming, complete tool coverage, production identity, full adversarial evaluation, and production retention/consent controls remain open. Clerk approval and integration, the full DEV-008 unit/integration/Selenium suite, CI checks, production document storage and release hardening remain later work. Docker startup and selected HTTP smoke journeys were verified on 2026-11-23; no complete acceptance suite is claimed.
