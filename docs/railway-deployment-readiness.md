# Railway deployment readiness

**Status:** Not ready for a public FleetOps application deployment.  
**Reviewed:** 2026-11-24  
**Scope:** First live pilot using Railway as the primary application host and a separately managed SQL Server-compatible database.

This is a deployment gate record, not a claim that Azure SQL, Clerk, or GitHub Actions have been provisioned. Railway has an empty staging project. The local demo remains bound to loopback and must not be made public by changing the port binding or copying `compose.demo.yaml` into Railway.

## Selected topology for the first live pilot

```text
Public HTTPS -> Railway web (React static build / reverse proxy)
             -> Railway API (FastAPI, authenticated)
             -> Railway worker (durable queue consumer)
             -> managed Azure SQL Database (SQL Server dialect, TLS)
             -> private object storage and configured AI provider
```

Railway is the primary **application** host proposed for the first pilot. The database remains Microsoft SQL Server-compatible; the selected managed service, network path, region, cost and backup policy require approval. GitHub Actions and GHCR remain the required release authority and image registry. The deployment should promote tested image digests, not rebuild different images per environment.

## Readiness findings

| Gate | Current evidence | Required before public deployment |
| --- | --- | --- |
| Identity and access | Clerk was approved for the pilot. A FleetOps Clerk Development instance exists. Its public JWKS is reachable. A separate production API path verifies token signature, issuer and authorized origin, checks current Clerk session status, then checks internal membership for read-only fleet access; synthetic signed-token unit tests pass. No real test identity or end-to-end verification exists yet. | Configure the Development instance for staging; verify real tokens, expiry/revocation and cross-carrier denial against SQL Server, then complete role coverage and onboarding. |
| Production API | Production mode exposes protected `/me`, read-only `/vehicles`, and a fleet-inventory-only AI chat with SQL-backed history, per-user daily cap and source records. Readiness checks revision `0005_production_readiness_grant`. These paths passed local synthetic SQL tests. | Verify on Azure SQL using a real Clerk session and least-privilege runtime identity; complete other business domains before claiming full product scope. |
| Database and migrations | Separate demo and production Alembic branches exist. Production requires an explicit approved database target and verified TLS. The production branch applied to isolated local SQL Server; pilot reader onboarding passed an idempotency test. | Provision a managed Azure SQL database, separate migration/runtime identities and restricted network path; then run the one-shot migration and real pilot onboarding. |
| Durable work | The present Compose demo has no worker or queue. | Select and implement a durable queue and dedicated worker for ingestion and long tasks. |
| Files | Demo documents are stored in local SQL rows with no production malware/quarantine or private object-store lifecycle. | Implement private object storage, authorized short-lived access, scanning/quarantine policy and retention. |
| Web serving | A separate non-root Caddy staging image serves the React build and runtime public config and proxies `/api` and `/health` privately. Local proxy smoke passed. The loopback demo still uses Vite preview. | Verify HTTPS, Clerk auth, AI streaming, SPA fallback and health on Railway. |
| CI and release | Root `make` targets and three GitHub Actions checks are prepared locally. They have not run on GitHub. Two local demo Selenium cases passed after selector repair. | Run all three jobs on the pushed commit; add production Clerk browser coverage, security scans, trusted GHCR publication, digest promotion and rollback evidence. |
| External access | The user confirmed GitHub is linked to Railway and showed a `FleetOps Staging` project with no services on 2026-11-24. A FleetOps Clerk Development instance exists. Its publishable key is configured in ignored local web settings and the Clerk-enabled web build passes; no backend secret, test user or SQL membership is configured. Azure SQL is not set up. This agent has no Railway account-control connection. | Connect the remaining services and supply configuration through each service's secret store. Do not paste credentials into chat or commit them. |

On 2026-11-24, local web lint, typecheck, 63 Vitest cases and build passed; API unit suite passed 40 cases; six production SQL integration cases passed on an isolated SQL Server test database; two demo Selenium cases passed against the loopback demo. GitHub CI, real Clerk, Azure SQL, provider-backed AI and Railway HTTPS verification have not run. The staging code is not a deployed service.

## User-provided prerequisites

1. **Railway:** The empty `FleetOps Staging` project has been created and GitHub linked. Before deploying services, choose a plan appropriate to always-on API and worker resources and choose the region with the database region in mind. Give the agent a supported Railway connection if account-side setup is desired.
2. **Azure:** Create a subscription and approve an Azure SQL Database budget, region, backup/restore target, and secure connectivity design. If using Azure SQL's public endpoint with an IP allowlist, Railway static outbound IPs currently require Pro; do not enable the broad "Allow Azure services" firewall rule as a shortcut. Private connectivity may require a different host/network design.
3. **Identity:** The FleetOps Clerk Development instance has been created. Its `pk_test_...` publishable key is in ignored local web configuration, and the Clerk-enabled build passes; the screen will not load carrier data until a production-mode API and SQL membership are available. In **Developer → API keys → Show JWT public key**, obtain the optional PEM public key for `FLEETOPS_CLERK_JWT_KEY`; this verifies signatures locally. The API still requires `FLEETOPS_CLERK_SECRET_KEY` in a server-only secret store to check whether each session remains active, so revoked sessions fail immediately. Set `FLEETOPS_CLERK_ISSUER` to the exact Clerk instance issuer and, after a staging web URL exists, `FLEETOPS_CLERK_AUTHORIZED_PARTY` to its exact HTTPS origin. Do not put any server secret in a `VITE_` variable or chat. Create a test user and matching internal SQL membership; Clerk authentication alone does not grant carrier access. Later create a separate production Clerk instance. The local demo account picker is not an internet authentication mechanism.
4. **GitHub:** Make the repository available to the deployment connection and enable protected environments/required CI checks where the plan permits. GHCR must allow the runtime to pull private images by digest.
5. **AI:** Provide a funded provider account and restricted API key through the API secret store. Define a spending cap and verify the deterministic database fallback when the provider is unavailable.
6. **Domain and pilot policy:** Decide whether to use Railway's HTTPS domain initially or a custom domain, who may access the pilot, whether only fictional or authorized customer data is allowed, and the incident/support contact.

## Implementation order after prerequisites

1. Complete the Gate 0 auth, SQL Server connectivity/TLS, production API, worker and production web-serving slices with their unit, integration and Selenium tests.
2. Add the three required CI jobs. Build and scan pinned images; publish only reviewed commits to GHCR and record immutable digests.
3. Provision separate staging services and database. Configure secrets and network restrictions. Run Alembic as a controlled, one-shot job using a migration identity.
4. Deploy the tested web/API/worker image digests to staging. Verify health, authenticated fleet CRUD, cross-carrier denial, dispatch conflict, AI source grounding and outage behavior, and database backup/restore.
5. Approve the production environment, promote the same digests and run post-deploy smoke tests. Record rollback-compatible image digests and schema revision.

## Stop conditions

Do not publish the current demo container, use SQL Server Developer Edition for production, change the selected database to a different engine for hosting convenience, print secrets into logs, or mark deployment successful based solely on a public landing page. If identity, SQL connectivity, queue durability, CI, backup, or authorization checks fail, stop promotion and report the failing gate.
