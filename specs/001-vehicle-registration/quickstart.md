# Feature 001 — Windows Setup and Validation Guide

**Date**: 2026-11-23
**Runnable local demo:** [docs/demo.md](../../docs/demo.md) documents the isolated vehicle-registration Docker stack. The longer planned commands and gates below describe full Feature 001 acceptance and do not claim that production identity or DEV-008 suites are complete.
**Status**: Partial Feature 001 implementation. B-001/B-002 are resolved in
[research.md](research.md). A private SQL Server 2022 Developer test instance is running;
0001/0002/0003 migrations reached head. Clerk, full runtime principal provisioning,
application API/browser implementation and the complete test matrix remain open.
This guide defines the full feature's required command interface. The separate local demo Compose
stack, pinned images and migrations now exist; Make targets, production identity, and complete
application/test suites remain future deliverables. Do not treat the future sections as runnable.

## Checks Available Now

From PowerShell:

```powershell
Set-Location 'D:\AIM\FleetOps'
python --version
python .\database\tools\verify_kit.py
```

Observed in this planning session: Python 3.12.5; static verifier exit 0, foundation 17 tables,
28 fixture inserts and 45 RLS policy predicates. This is static reference validation, not a
live SQL Server result. The metadata projection also confirms 154 foundation columns/39 FKs.
The revised application set separately adds integration.idempotency_keys: 18 tables, 166 columns,
42 FKs and 50 RLS predicates. Do not expect the unchanged reference verifier to report this delta.

`py -3` did not find Python on this workstation, while `python` worked. Use the executable
that actually reports a supported version; do not rely on the Microsoft Store python3 alias.
The earlier planning probe saw a denied Docker config read and missing engine pipe. A later
out-of-sandbox check in the implementation session reached a Linux/amd64 engine; see the current
check table below. The reference SQL rehearsal remains unexecuted.

## Implementation Checks on 2026-11-23

| Check | Observed result | Remaining gate |
| --- | --- | --- |
| `python database/tools/verify_kit.py` | Exit 0; static reference inventory 174 target tables, 17 foundation tables and 45 foundation RLS predicates. This does not validate the Feature 001 Alembic database. | None for the static kit check; G-SQL for application migrations. |
| Direct execution of four functions in `apps/api/tests/unit/test_vehicle_validation.py` and `test_vehicle_idempotency.py` | Passed; includes shared Unicode/length, schema and canonical-hash assertions. This is not a pytest suite run. | G-PINS and pytest/runner scaffold for `make test-unit`. |
| Node 24 direct import of `vehicleValidation.ts` with the shared JSON fixture | 54 field/vector combinations passed. This is not a Vitest/component run. | G-PINS and web package/lockfile for Vitest/build. |
| Web scaffold config syntax and `tsconfig.json` parse | Passed. React/Vite imports and the production build were not exercised. | G-PINS and locked npm install. |
| `docker version` outside the restricted shell | Linux/amd64 Docker 29.4.2 engine responded. The restricted shell itself cannot read the Docker config/pipe. | G-PINS for approved images; G-SQL for a running isolated SQL Server. |
| Local Docker images/containers | No SQL Server image or container was present; unrelated Postgres and application containers are not Feature 001 evidence. | G-SQL. |
| `python -m pytest` | Could not start: `No module named pytest`. | G-PINS and Python test dependencies. |
| Root Make, SQL Server integration, Selenium and CI checks | Not run: Makefile/Compose/application migrations and required test services are absent; no local `make` command was found. | G-PINS, G-SQL and G-CLERK where the approved provider adapter is required. |

### New local results (same date)

| Check | Observed result | Limit |
| --- | --- | --- |
| Host `python -m pytest tests/unit -q` in `apps/api/.venv` | 7 passed, 1 Starlette/httpx deprecation warning. The new model-contract test compares all 18 approved tables, 166 columns and 42 FKs with `model.json`. | Unit scope only. |
| `npm test` in `apps/web` | 58 passed, including 2 keyboard form cases and 56 shared UTF-16 vector cases. | No API/browser journey. |
| `npm run build`, `npm run lint`, `npm run typecheck` | All passed with exact npm lockfile and Node 24. | Scaffold is not an authenticated workflow. |
| Private `fleetops001test` SQL Server Compose service | Pinned image digest `sha256:4525e3efac9f3e241cb003bb2ff2a82818b502f37e12049d788b1a9fa7e13b7f`; SQL Server 16.0.4325.4 Developer; encrypted SQLCMD connection; no host SQL port. | Local test-only certificate trust exception (`-C`). |
| ODBC 18 from Linux API test image | `ODBC 18 to SQL Server 16.0.4325.4: encrypted=TRUE`. | Local test-only `TrustServerCertificate=yes`; full type/tenant-context proof pending. |
| Alembic `0001_foundation` on `fleetops_test_001` | Revision applied; direct SQL counts: 17 foundation tables, 154 columns, 39 FKs. | Fresh and populated upgrade permutations remain untested. |
| Alembic 0002 then 0003 on the same isolated DB | Reached `0003_vehicle_retry` (short Alembic ID in the named retry migration file). Direct SQL: 18 domain tables, 166 columns, 42 FKs, 50 security predicates. Failed long-ID attempt rolled back to 0002 with no retry table; short ID then succeeded. | Migration-role provisioning and full IT-10 case remain open. |
| `alembic check` in Linux ODBC 18 image | `No new upgrade operations detected` after `include_schemas=True`. | Same populated test DB; fresh upgrade matrix pending. |
| Transactional SQL security probe | Bootstrap procedure returned one matching member capability. Runtime role had SELECT/INSERT but no UPDATE/DELETE/ALTER on retry table; no-context RLS hid asset/receipt; native tenant context revealed own asset. Probe fixture rows rolled back. | More role and cross-tenant cases remain open. |
| Containerized Python unit suite in pinned API test image | 7 passed, 1 Starlette/httpx deprecation warning. | Unit scope only. |
| Containerized SQL integration checks | 4 passed against the live SQL Server instance: two migration/schema checks and two one-slot tenant-pool checks. The first schema run caught a mistaken nonnullable assertion for `response_reference`; corrected to the approved nullable contract. The pool test exposed an ODBC `sql_variant` NULL mapping quirk, so reset verification now uses a SQL-side `IS NULL` predicate. | Partial IT-09/IT-10 only; all IT-01–10 acceptance groups remain open. |

The API image uses Python 3.12.16 by digest and Microsoft ODBC Driver 18 package
`18.7.1.1-1`. Python dependencies, including pytest 9.2.0, are pinned in
`apps/api/requirements.lock`; React 19.3.1, TypeScript 5.9.3 and Vite 8.3.8 are
locked by `apps/web/package-lock.json`. The TypeScript pin avoids a peer-version conflict
with the current OpenAPI/ESLint tools. The SQL test container uses a private network and an
ignored `.env.test`; no SQL port is published. TLS is encrypted, with an explicit
test-only self-signed certificate trust exception inside the isolated stack.

The 22 planned UT/IT/SB acceptance groups remain required. The isolated API/web unit
checks below cover only their implemented portions; no SQL integration or Selenium group has
a recorded passing result.

## Prerequisites After Plan Approval

- VS Code, Git, a supported Python 3.12 runtime, GNU Make and Docker Desktop with Linux containers.
  Python on the host orchestrates tests using the standard library; app dependencies remain
  in containers. Native Node, ODBC and Chrome installations are unnecessary for the Compose path.
- A supported Intel/AMD x86-64 Linux Docker engine. Windows users can use Docker Desktop with
  WSL2 integration. ARM developers need an isolated remote x86-64 environment with matching
  images; do not treat emulation as a supported SQL Server test result.
- Host must reach Docker without exposing the Docker API remotely. Start/select the Linux
  engine and resolve local Docker access/config permissions through normal workstation setup.
  Never solve this by granting an untrusted container the host Docker socket.
- Allocate enough Docker memory/disk for SQL Server, app, Chrome and test runners. Begin with an
  engineering budget of 8 GB Docker memory and adjust from measurement; this is a planning
  allowance, not a vendor support minimum.
- Real Clerk development setup and scoped synthetic members are needed for the trusted-provider
  smoke. Routine PR suites use the controlled identity boundary described in research.md.
- Exact supported dependency versions and image digests must be locked after Gate 0 proof.
  SQL Server Developer Edition is restricted to development/test; no production rollout is part
  of these instructions.

Reference prerequisites:
[Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/),
[SQL Server container support](https://learn.microsoft.com/en-us/sql/linux/install-upgrade/quickstart-install-docker?view=sql-server-linux-ver17).

## Windows Preflight

Native PowerShell with GNU Make on PATH:

```powershell
Set-Location 'D:\AIM\FleetOps'
Get-Command python, make, docker
python --version
make --version
docker version --format '{{.Server.Os}}/{{.Server.Arch}} {{.Server.Version}}'
docker compose version
```

The server result must identify Linux/amd64 (or the engine's equivalent x86-64 spelling).
A missing pipe, access denial or unavailable daemon is a prerequisite failure, not a passing
integration result. Do not start migrations when preflight fails.

Alternative: run Make in WSL with Docker Desktop integration enabled for that distribution.
Use WSL's own Python and GNU Make, and verify the same Linux engine there. From PowerShell:

```powershell
wsl --cd /mnt/d/AIM/FleetOps --exec python3 --version
wsl --cd /mnt/d/AIM/FleetOps --exec make --version
wsl --cd /mnt/d/AIM/FleetOps --exec docker compose version
```

The /mnt/d path matches this checkout; use the corresponding mounted checkout if moved.
Do not mix Windows-created virtual environments or node_modules with WSL; containers own
dependencies. [WSL command reference](https://learn.microsoft.com/windows/wsl/reference).

## Planned Local Configuration

The implementation must provide compose.yaml, compose.test.yaml, .env.example, .gitignore,
.dockerignore, Makefile, tools/run_tests.py and VS Code tasks consistent with this guide.
The following commands are usable only after those artifacts are implemented and reviewed:

```powershell
if (-not (Test-Path -LiteralPath '.env')) {
    Copy-Item -LiteralPath '.env.example' -Destination '.env'
}
docker compose config --quiet
docker compose build
docker compose up -d --wait sqlserver
docker compose run --rm bootstrap
docker compose run --rm migrate
docker compose run --rm seed
docker compose up -d --wait api web
docker compose ps
```

Before running, populate the ignored local configuration using local-only credentials; do not
print resolved Compose configuration. Required categories are database bootstrap/migration/runtime
identities, identity provider/test issuer configuration, and non-secret public frontend config.
The seed command must require explicit synthetic opt-in and a development database allowlist;
otherwise it fails closed. It creates only fictional local data and never accepts a production URL.

Service contract:

| Service | Required behavior |
| --- | --- |
| sqlserver | Pinned SQL Server 2022 Linux amd64 development image, private port, persistent named local volume, bounded health check. |
| bootstrap | One-shot local database/principal provisioning for explicitly allowed development/test database names; refuses system/production targets. Establish reviewed collation on a new DB only. |
| migrate | One-shot Alembic head upgrade using migration credentials; no migration at API startup. Applies 0001/0002 foundation and 0003_vehicle_registration_idempotency: 18 domain tables, migration bookkeeping and reviewed security objects. No other integration table. |
| seed | Idempotent synthetic two-carrier fixture setup using separate setup credentials after migrations; not reference DDL. |
| api | Non-root FastAPI application with runtime identity, live/ready checks and bounded SQL connectivity. Readiness requires the expected schema/security revision. |
| web | Non-root server for the built React SPA, loopback host port 8080, internal port 8080; /api proxy reaches api:8000. No database credentials in web config. |
| identity-fixture | Test-profile-only signed identity and provider-status boundary, ephemeral keys and isolated routing. Absent from release routing. |
| selenium | Test-profile-only pinned Chrome/driver container, internal port 4444; no shared sessions. |
| api-tests, web-unit, browser-tests | Pinned test images/runners for the named suites; credentials/scopes appropriate to each role. |

Interactive development URL: http://localhost:8080. Container-based Selenium uses
http://web:8080 and its driver URL http://selenium:4444; localhost inside Chrome is the Chrome
container. Internal Compose names must not be supplied as URLs to a host browser.
SQL ports are not published. Optional local SQL tooling must use an explicitly loopback-only
development profile.

Use encryption with trusted certificates for SQL. A documented self-signed certificate trust
exception, if required for an isolated local test profile, must remain explicit and rejected
by staging/production config; never silently disable TLS. Record the actual TLS mode in evidence.

## Planned Root Test Commands

Native PowerShell (explicitly select the verified working Python executable):

```powershell
make PYTHON=python test-unit
make PYTHON=python test-integration
make PYTHON=python test-selenium
make PYTHON=python test
```

WSL alternative from PowerShell:

```powershell
wsl --cd /mnt/d/AIM/FleetOps --exec make test-unit
wsl --cd /mnt/d/AIM/FleetOps --exec make test-integration
wsl --cd /mnt/d/AIM/FleetOps --exec make test-selenium
wsl --cd /mnt/d/AIM/FleetOps --exec make test
```

GitHub Actions Linux x86-64 checks unit/integration/selenium invoke the identical targets
without the Windows Python override. Make recipes call the same cross-platform runner, which
owns per-suite Compose projects, readiness waits, migrations, seed, execution, evidence and
cleanup. No manual deletion of application data is needed before tests. See
[test-plan.md](test-plan.md) for every case/file/fixture mapping.

Each individual suite must return nonzero on setup failure, zero collection, required skips,
assertion failure or unavailable dependencies. The aggregate preserves distinct reports and
returns nonzero if any suite fails. Every revised replay and Unicode case remains required.

Expected report locations after implementation:

- artifacts/tests/unit/backend.xml and web.xml
- artifacts/tests/integration/junit.xml and schema-report.json
- artifacts/tests/selenium/junit.xml and sanitized failure screenshots/diagnostics
- artifacts/tests/run-manifest.json with commit, revisions, image/browser/driver versions,
  per-suite counts/results and the run's owned resource identifiers

These are outputs to generate, not current files. Tests run against isolated stacks even while
a developer's persistent stack is running. Cleanup must validate exact run-owned project names
and keep resources until sanitized failure evidence is captured.

## Validation Journeys After Implementation

1. A's creator signs in, opens Vehicles and registers a fresh unit with make/model/year/ownership.
   After confirmation, refresh and search: exactly one matching truck and unchanged details.
2. A's reader and B's reader can each see their own seeded TRK-001, cannot use registration,
   and receive denial when directly navigating to registration. Integration requests also
   prove direct POST denial and zero saved records.
3. B searches an independently seeded A-only number: ordinary empty state. A's known detail
   address is indistinguishable from an unknown truck; neither exposes A's details.
4. Submit a missing unit by keyboard, correct it to a duplicate, then to a fresh unit.
   Exercise shared UTF-16 boundaries: 15 truck symbols (U+1F69A) fit a 30-unit number; adding A
   is 31 and must show an editable validation error without save. For make/model, 40 symbols
   fit 80; adding A fails. Mixed ASCII/supplementary limits also save/read/refresh unchanged.
5. Race different keys for one unit: one success, one conflict; exactly one asset/vehicle/audit/
   receipt set. Race the same key/payload: both receive the identical original result. Drop the
   committed response, replace the API process while preserving SQL and retry: original
   201/body/Location and creation time, no new row/event. Changed valid payload returns 409;
   revoked authorization denies replay. Faults before commit roll back all four writes.
   The integration suite also checks retained receipts beyond 30 days, no automatic expiry,
   same-key scope isolation, missing-reference failure and runtime SQL lock/grant behavior.
6. Revoke permission while a form is open: deny submission with no save. Switch carriers/log out:
   erase prior scoped state and ignore late responses.
7. Run each root suite and check its separate CI result on the same commit; capture actual
   commands/results. Passing manual journeys never substitutes for executable test evidence.

## Separate Foundation Rehearsal

The existing database/sql/verify-foundation.sql is for a fresh, empty disposable reference DB only.
An engineer must supply an authenticated SQLCMD/TLS environment and explicitly opt into synthetic
data per [database validation](../../docs/database/VALIDATION.md). The SQL script rejects system
databases and databases with user tables. Never point it at the Alembic application database.

Windows SQLCMD form, only after those prerequisites and independent target verification:

```powershell
if ([string]::IsNullOrWhiteSpace($env:FLEETOPS_SQL_SERVER)) { throw 'Set the isolated SQL Server address.' }
if ($env:FLEETOPS_REFERENCE_DATABASE -notmatch '^fleetops_ref_[A-Za-z0-9_]+$') { throw 'Use an approved fresh reference DB.' }
$env:ALLOW_SYNTHETIC = 'YES'
sqlcmd -b -S $env:FLEETOPS_SQL_SERVER -d $env:FLEETOPS_REFERENCE_DATABASE -i 'database/sql/verify-foundation.sql'
$referenceExit = $LASTEXITCODE
Remove-Item Env:\ALLOW_SYNTHETIC
if ($referenceExit -ne 0) { throw 'Reference verification failed.' }
```

Use the installation's authenticated TLS settings; no password is embedded in the command.
If SQL is reachable only on the Compose private network, run SQLCMD from a purpose-built
reference-verification container with that same separate target. A pass requires exit 0 plus
Foundation verification completed and a captured engine/client version. Neither this rehearsal
nor a static verifier pass counts as application integration/Selenium evidence.
This rehearsal remains a 17-table baseline. Only the isolated Alembic suite verifies the approved
eighteenth table, populated 0002→0003 upgrade and its new RLS/grants; never append target DDL here.

## Shutdown and Troubleshooting

```powershell
docker compose logs --tail 100 api
docker compose down
```

Inspect logs locally and sanitize before sharing. Routine shutdown preserves local volumes.
Do not use down -v on the persistent development project. Test runner cleanup may remove only
its recorded, disposable resources after evidence capture.

- Docker pipe/config failure: resolve engine/access prerequisites; do not suppress the error.
- Browser cannot reach app: use web:8080 inside the test network and localhost:8080 on the host.
- Fresh SQL credentials appear ignored: a persistent volume may retain prior initialization;
  inspect the selected dev environment and follow an approved reset procedure, not an automatic
  volume deletion.
- Required suite cannot start: report failure and missing prerequisite. No fallback SQLite,
  no fake passed case and no production endpoint substitution.
- Replay or Unicode case fails: review [plan.md](plan.md) and the shared vectors; do not delete
  receipts, widen columns, waive tests or silently truncate. Report the failing check.
