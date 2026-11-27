# Fictional staging fleet inventory

This document covers the earlier inventory seed. For the next hosted feature release and its `0006` migration, use [Fictional staging operations release](staging-fictional-operations.md). The inventory seed now accepts either `0005_production_readiness_grant` or `0006_staging_operations`; the statements below about unavailable hosted features describe the earlier inventory-only release.

This procedure populates **only** the existing Azure SQL database
`fleetops-staging-db`. It does not copy the local demo database, seed a
production carrier, or enable dispatch, GPS, maintenance, or costs in the
hosted pilot. The result is two clearly fictional tractor records and two
fictional trailer records for the
already-onboarded Clerk pilot carrier.

## Preconditions

1. Confirm the approved staging tenant UUID and record its current name.
   Confirm that it has no real or unrelated assets.
2. Confirm Azure SQL is at `0005_production_readiness_grant` or `0006_staging_operations` and that the
   migration job can reach the private SQL endpoint with verified TLS.
3. Build and scan the API image containing
   `tools/seed_staging_fictional_fleet.py`. Use its immutable digest.
4. Run a **manual one-shot Container Apps job** in the staging Container Apps
   environment. Use the dedicated migration SQL credential; do not add that
   credential to the web service or the normal API runtime.

Set `FLEETOPS_ENV=production`, `FLEETOPS_DATABASE_NAME=fleetops-staging-db`,
`FLEETOPS_MIGRATION_APPROVED_TARGET=fleetops-staging-db`,
`FLEETOPS_STAGING_DEMO_TENANT_ID` to the reviewed tenant UUID, and
`FLEETOPS_STAGING_FICTIONAL_SEED=approved`. Supply the existing SQL server,
migration user and password secret reference, and verified SQL TLS settings.
Run `python -m tools.seed_staging_fictional_fleet` from `/workspace/apps/api`.

The tool refuses another database, an unexpected schema revision, an inactive
or non-staging carrier, and a carrier containing unrelated assets. Its
deterministic asset IDs allow a safe retry. It prints only the carrier ID and
fictional vehicle count. Re-running the guarded seed after the updated image
is deployed adds only the two deterministic trailer assets to the previously
seeded tractors.

## Verification

After the job succeeds, a signed-in pilot reader should see carrier
`FleetOps Staging (Fictional Demo)`, trucks `DEMO-101` and `DEMO-102`, and
trailers `TRL-301` and `TRL-302`. The hosted Overview and Fleet tabs use
`GET /api/v1/assets` and show only recorded status counts. Service due,
dispatch, GPS, documents, and costs remain unavailable in hosted staging.
Check that the Azure API returns only these authorized carrier assets and
that an unrelated Clerk account receives 403. Ask AI Fleet to summarize the
fleet and verify its answer cites the fictional records.

## Backout

Keep the recorded original carrier name. If the staging seed must be removed,
review the exact tenant and deterministic IDs, then delete the two
`fleet.vehicles` rows followed by their four `fleet.assets` rows in one controlled
transaction and restore the original carrier name. Do not delete the carrier,
Clerk user, membership, or global reference data. Capture the SQL job result
and recheck the signed-in empty state.
