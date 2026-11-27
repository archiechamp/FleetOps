# Fictional staging operations release

This release targets only Azure SQL `fleetops-staging-db` and the existing `FleetOps Staging (Fictional Demo)` carrier. It does not import the local demo database or customer records. The guarded inventory seed has already added two tractors (`DEMO-101`, `DEMO-102`) and two trailers (`TRL-301`, `TRL-302`). The new operations seed adds fictional service and last-known GPS data, one assignment, one registration PDF, and two USD costs.

## Release order

1. Confirm the approved fictional carrier UUID and four deterministic inventory assets. Record the current SQL revision and verify a recovery point.
2. Merge the reviewed changes after the `unit`, `integration`, `selenium`, and `images` checks pass. Run **Publish FleetOps images** on `main`; record the immutable API and web digests from its manifest.
3. Run a controlled one-shot Alembic migration job from the new API image, using the dedicated migration SQL credential and verified TLS. Execute `alembic -x target=production@head upgrade production@head`; verify `dbo.alembic_version = 0006_staging_operations`. Do not migrate on API startup.
4. Update the serving Azure API to that API digest and verify `/health/ready`. Keep SQL, Clerk, and OpenAI secrets in Azure secret references and SQL public network access disabled.
5. Run the operations seed once as a manual Container Apps job from the same API digest with the dedicated migration credential. Set `FLEETOPS_ENV=production`, `FLEETOPS_DATABASE_NAME=fleetops-staging-db`, `FLEETOPS_MIGRATION_APPROVED_TARGET=fleetops-staging-db`, `FLEETOPS_STAGING_FICTIONAL_SEED=approved`, and `FLEETOPS_STAGING_DEMO_TENANT_ID` to the reviewed fictional tenant UUID. Supply the SQL server, migration user/password secret reference, verified TLS settings, and `PYTHONPATH=/workspace/apps/api`. From `/workspace/apps/api` run `python -m tools.seed_staging_fictional_operations`. Check for a successful execution and `assets=4`; do not start a second execution while checking status.
6. Promote the web image digest to Railway `web`, preserve its Azure API HTTPS upstream and Clerk authorized party, and verify the Railway HTTPS domain.

The operations seed refuses another database, schema revision, carrier, or asset set. Its deterministic IDs permit a controlled retry without overwriting existing operations rows. The older inventory seed accepts schema revision `0005` or `0006`, but is unnecessary when all four approved assets already exist.

## Live verification

Sign in as the pilot user. Confirm the fictional carrier and shared Overview, Fleet, Dispatch, GPS, Maintenance, Documents, Costs, and Reports views. Check the two trucks, two trailers, assignment, service due state, observation timestamps and freshness labels, private registration download, recorded USD costs, and unknown completeness and mileage basis. Ask AI Fleet about inventory, trip, GPS, service, document, and costs; inspect the answer sources and timestamps. Verify an unrelated Clerk user and cross-tenant IDs cannot read data. Record HTTP statuses, SQL revision, image digests, UTC time, and screenshots without credentials.

This is a fictional staging demonstration. It has no live GPS feed, driver or HOS validation, revenue ledger, or complete trip cost basis. A last-known position is an observation; recorded costs are not net profit.

## Backout

Redeploy the previous API and web digests only after checking compatibility with the additive `0006` schema. The migration has no automatic downgrade. A bad seed requires a reviewed tenant-scoped corrective transaction or Azure SQL point-in-time restore; do not delete the carrier, Clerk membership, or shared reference data as an informal cleanup.
