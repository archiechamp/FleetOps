# FleetOps staging deployment runbook

**Status, 2026-11-24:** Prepared locally; no Railway service, Azure SQL Database, funded model account, or live URL has been verified. This is a controlled staging procedure for the read-only fleet and AI slice. The local demo image must remain loopback-only.

## 1. External prerequisites

1. Approve an Azure SQL Database budget, region, backup policy, and a network path from Railway. Azure SQL denies public connections by default. If using its public endpoint with an IP allowlist, Railway's static outbound IP feature currently requires a Pro plan. Enable static egress on the API and one-shot migration service, then allowlist their actual addresses. Do not enable the broad Azure-services firewall exception. A private endpoint requires a separately designed connection from Railway to the Azure virtual network.
2. Create a Clerk staging instance or use the existing Development instance only for staging. Obtain its publishable key, server secret key, exact issuer, and a real pilot user ID. Keep the secret in Railway's server-side variables. Set authorized party to the eventual **exact** HTTPS web origin. A production release should use a separate Clerk production instance and its own keys.
3. Create a funded OpenAI API project and restricted API key with a spending limit. Store `OPENAI_API_KEY` only on the API service. Without it, AI Fleet returns a clearly labeled verified database summary, not a model-generated answer.
4. Connect Railway and GitHub to this deployment agent or perform the account-side steps in their dashboards. GitHub being linked to Railway does not give this agent account access.

## 2. Database setup

Create a blank Azure SQL Database and separate contained SQL users for **migration** and **runtime**. Migration needs enough schema and security-policy privileges for Alembic. Runtime must be a member of `fleetops_runtime` and `fleetops_bootstrap` after the controlled migration; the latter only grants execution of the verified membership procedure. Do not grant runtime `db_owner`. Keep both passwords in Railway variables, never in Git or a browser public config.

Run the API image once as a migration job, with `FLEETOPS_ENV=production`, `FLEETOPS_DATABASE_NAME` set to the new database, `FLEETOPS_MIGRATION_APPROVED_TARGET` set to that same name, `FLEETOPS_SQL_SERVER` set to the Azure SQL hostname, dedicated `FLEETOPS_SQL_MIGRATION_USER` and `FLEETOPS_SQL_MIGRATION_PASSWORD`, and verified SQL TLS. Command:

```text
alembic -x target=production@head upgrade production@head
```

Check `dbo.alembic_version` equals `0005_production_readiness_grant`. Migrations are a one-shot job, never an API startup command. Verify backup or point-in-time recovery before the job.

## 3. Pilot membership

After verifying the Clerk user ID in Clerk, run the API image as a one-shot onboarding job with the same approved migration connection plus `FLEETOPS_PILOT_CLERK_USER_ID`, `FLEETOPS_PILOT_TENANT_NAME`, `FLEETOPS_PILOT_TENANT_SLUG`, and `FLEETOPS_PILOT_TIMEZONE` (IANA format). Command:

```text
python tools/provision_pilot.py
```

This creates or reuses one active carrier, one Clerk-linked user, and a **fleet-reader-only** membership. It creates no synthetic equipment or customer data. Run it only after reviewing the carrier name, slug, timezone, Clerk user ID, and target database. Verify a second Clerk user without membership receives `403`.

## 4. Railway services

Create two private-source services in **FleetOps Staging**, both from the reviewed FleetOps repository and exact release commit or approved GHCR image digest:

| Service | Dockerfile | Ingress | Runtime configuration |
| --- | --- | --- | --- |
| `api` | `apps/api/Dockerfile` | Private network only, port 8000 | `FLEETOPS_ENV=production`, SQL runtime connection, Clerk server settings, `OPENAI_API_KEY`, model |
| `web` | `apps/web/Dockerfile.staging` | Railway-generated HTTPS domain, port 8080 | `FLEETOPS_WEB_MODE=production`, `FLEETOPS_CLERK_PUBLISHABLE_KEY`, `FLEETOPS_API_UPSTREAM=api.railway.internal:8000` |

For GitHub-source builds, set each service's `RAILWAY_DOCKERFILE_PATH` to its Dockerfile above and keep the build context at the repository root. Set API `PORT=8000` and web `PORT=8080` if Railway needs explicit port selection. Configure `/health/ready` for API health and `/` for web health. Only the web receives a public domain. The web proxy forwards `/api/*` and `/health/*` to the private API.

API variables: `FLEETOPS_ENV`, `FLEETOPS_DATABASE_NAME`, `FLEETOPS_SQL_SERVER`, `FLEETOPS_SQL_RUNTIME_USER`, `FLEETOPS_SQL_RUNTIME_PASSWORD`, `FLEETOPS_SQL_ENCRYPT=yes`, `FLEETOPS_SQL_TRUST_SERVER_CERTIFICATE=no`, `FLEETOPS_CLERK_ISSUER`, `FLEETOPS_CLERK_AUTHORIZED_PARTY`, `FLEETOPS_CLERK_SECRET_KEY`, optional `FLEETOPS_CLERK_JWT_KEY`, `FLEETOPS_AI_MODEL`, and `OPENAI_API_KEY`. Do not put a secret in any `VITE_` variable or the web service.

## 5. Release verification

The exact commit must pass `unit`, `integration`, and `selenium` checks. Then build, scan, and publish immutable web/API image digests to GHCR from a trusted reviewed commit; staging should deploy those digests. This release pipeline and a real Clerk Selenium journey still need their first GitHub run. Do not infer success from local tests.

After deployment, record the web HTTPS URL, image digests, SQL revision, and smoke results. Check `/health/ready`, Clerk login, own carrier fleet read, wrong-carrier `403`, AI Fleet source links, unsupported-data wording, provider response and quota fallback, conversation ownership, and browser sign-out. The current production slice is **read-only fleet inventory and AI Fleet inventory Q&A**. Dispatch, GPS, maintenance, costs, files, a durable worker, and seven-day chat purging are not yet live features.

## References

- Railway custom Dockerfile path: https://docs.railway.com/builds/dockerfiles
- Railway private networking: https://docs.railway.com/networking/private-networking
- Railway static outbound IPs: https://docs.railway.com/networking/static-outbound-ips
- Azure SQL network controls: https://learn.microsoft.com/azure/azure-sql/database/network-access-controls-overview
- Clerk production instances: https://clerk.com/docs/guides/development/deployment/production
