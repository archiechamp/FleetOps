# Fictional staging fleet inventory

This procedure populates **only** the existing Azure SQL database
`fleetops-staging-db`. It does not copy the local demo database, seed a
production carrier, or enable dispatch, GPS, maintenance, or costs in the
hosted pilot. The result is two clearly fictional tractor records for the
already-onboarded Clerk pilot carrier.

## Preconditions

1. Confirm the approved staging tenant UUID and record its current name.
   Confirm that it has no real or unrelated assets.
2. Confirm Azure SQL is at `0005_production_readiness_grant` and that the
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
fictional vehicle count.

## Verification

After the job succeeds, a signed-in pilot reader should see carrier
`FleetOps Staging (Fictional Demo)` and vehicles `DEMO-101` and `DEMO-102`.
Check that the Azure API returns only these authorized carrier vehicles and
that an unrelated Clerk account receives 403. Ask AI Fleet to summarize the
fleet and verify its answer cites the fictional records.

## Backout

Keep the recorded original carrier name. If the staging seed must be removed,
review the exact tenant and deterministic IDs, then delete the two
`fleet.vehicles` rows followed by their `fleet.assets` rows in one controlled
transaction and restore the original carrier name. Do not delete the carrier,
Clerk user, membership, or global reference data. Capture the SQL job result
and recheck the signed-in empty state.
