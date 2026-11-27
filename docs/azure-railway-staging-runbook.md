# FleetOps staging: Azure API and Railway web

This is the current staging topology. The older [Railway runbook](railway-staging-runbook.md) describes a two-service Railway option and is not the deployment procedure for this preview.

**Release status, 2026-11-25:** The last user-verified live slice used SQL revision `0005_production_readiness_grant` and served the fictional staging carrier with two trucks and two trailers. The Railway web URL was `https://web-production-1fdeae76.up.railway.app`; the Azure API URL was `https://fleetops-staging-api.wittysand-52e0f278.southeastasia.azurecontainerapps.io`. The expanded hosted workspace and `0006_staging_operations` are a tested local release candidate, **not yet verified live**. Follow [Fictional staging operations release](staging-fictional-operations.md) for its migration, seed, promotion, and smoke checks. The steps below document the original inventory-only setup.

## Verified infrastructure

- Azure resource group `rg-fleetops-staging` in Southeast Asia contains SQL server `fleetops-staging-sql-aim`, database `fleetops-staging-db`, and Container Apps environment `cae-fleetops-staging`.
- Azure SQL public network access is disabled. Its approved private endpoint resolves through the linked `privatelink.database.windows.net` zone to `10.42.1.4` in `vnet-fleetops-staging`. Keep the public endpoint disabled.
- Railway project `FleetOps Staging` has a deployed `web` service and the HTTPS URL above. Verify its active image digest for each release.
- Clerk has a Development instance. Use it only for a staging preview until a custom domain and production Clerk instance are available.
- The OpenAI account has prepaid credit. The API had an OpenAI secret reference and the AI panel showed a configured model; verify a real answer and budget limit for each release.

## Release gate

1. Review and merge the current PR only after the four checks (`unit`, `integration`, `selenium`, `images`) pass on its final commit. Record the merged SHA.
2. Run the manual image publication workflow on `main`, scoped to that SHA. Confirm its release-check verification, vulnerability scans, and immutable API/web image digests. Do not deploy unverified tags.
3. Make images readable to Azure Container Apps and Railway through an approved registry access method. Keep registry credentials in service secrets, never Git or chat.

## Database and API

1. Configure a one-time migration Container Apps job in `cae-fleetops-staging` from the exact API image digest. Use the Azure SQL server FQDN, database `fleetops-staging-db`, encrypted SQL transport with certificate validation, and a dedicated migration identity. Inject credentials through Azure secrets. Check the target guard before `alembic -x target=production@head upgrade production@head`. The migration must not run on API startup.
2. Verify `dbo.alembic_version` at `0005_production_readiness_grant`, the expected roles and procedure grants, and a recovery point. Create a separate least-privileged runtime SQL user. Do not give runtime `db_owner`.
3. Run the one-time pilot onboarding job with the verified Clerk user ID and reviewed carrier name, slug and IANA timezone. It must create only the membership, not synthetic equipment. Verify a different Clerk user without membership is denied.
4. Deploy the API image digest to an externally reachable Azure Container App in the same environment. Its SQL traffic stays on the private endpoint. Set `FLEETOPS_ENV=production`, SQL runtime settings, Clerk issuer/authorized party/server secret, and `OPENAI_API_KEY` as Azure secrets. Limit CORS to the final Railway web origin; keep the AI tools read-only. Configure `/health/ready`, ingress and logs.

## Railway web

1. Attach the reviewed GitHub repository source to the staged Railway `web` service. Use `apps/web/Dockerfile.staging` with repository root as build context and the reviewed release commit. Where an immutable GHCR web image is used instead, select the verified digest.
2. Change `FLEETOPS_API_UPSTREAM` from the former `api.railway.internal:8000` value to the Azure API HTTPS origin. Verify that the staging Caddyfile supports an HTTPS upstream and preserves the API route paths. Keep the Clerk publishable key in web configuration; server secret and OpenAI key belong only on the API.
3. Deploy the web service, generate a Railway HTTPS domain, and set Clerk's authorized party and API CORS to that exact origin. Re-deploy affected services after setting these values.

## Live checks and record

- Confirm the web URL and API readiness endpoint respond over HTTPS.
- Sign in as the pilot Clerk user. Verify a read-only inventory answer with source references, unknown-record wording, provider outage fallback, usage cap, and sign-out. Verify cross-tenant or non-member access is denied.
- Record the release SHA, image digests, migration revision, UTC check time, URLs, and rollback images. The inventory-only `0005` preview lacked hosted dispatch, GPS, costs, documents and full chat retention; validate each new `0006` feature through the linked operations release procedure before calling it live.

## References

- [Azure Container Apps networking](https://learn.microsoft.com/en-us/azure/container-apps/networking)
- [Azure Container Apps jobs](https://learn.microsoft.com/en-us/azure/container-apps/jobs)
- [Azure SQL private endpoints](https://learn.microsoft.com/en-us/azure/azure-sql/database/private-endpoint-overview)
- [Caddy HTTPS reverse proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)
- [Railway Dockerfiles](https://docs.railway.com/builds/dockerfiles)
