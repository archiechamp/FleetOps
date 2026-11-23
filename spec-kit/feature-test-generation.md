# Generate tests with each FleetOps feature

Implements **DEV-008**. Generate executable test files, fixtures, runner commands and CI jobs in the same change as the feature they exercise. Start all three suites with the first vehicle workflow at Gate 0. Later changes extend the suites whose behavior they affect. The three PR checks continue to run together, including for changes confined to the backend.

## Instruction for Spec Kit or a coding agent

> Implement the approved FleetOps feature and its automated tests together. Read the requirement IDs and acceptance fixtures in spec.md. In the feature plan, map each changed behavior to a test file, test name, fixture, user action and observable outcome. Generate unit tests for business and component logic, integration tests through FastAPI and the migrated SQL Server database, and Selenium WebDriver tests for affected browser workflows. Use the production entry points and authorization path. Generate the local and GitHub Actions commands below with the first slice. Run the applicable cases and record their actual results in the feature handoff.

During **planning**, include the mappings in the feature's existing plan or task list. During **implementation**, commit the test sources and runner configuration with the feature. During **review**, link each accepted behavior to its executable case and CI result. For a backend-only change, identify the existing Selenium regression covering its visible effect. If there is no browser-visible effect, record that once in the feature plan and keep the existing browser suite running.

## Generated repository contract

These commands and paths are deliverables of Gate 0. Run them from the generated repository root.

| Root command | Implementation to generate | What a pass demonstrates |
|---|---|---|
| `make test-unit` | Run pytest in `apps/api/tests/unit/` and Vitest with React Testing Library for changed components under `apps/web/src/`. | Domain functions, validation, permission decisions and component states have deterministic outcomes. Inject clocks and external dependencies where needed. |
| `make test-integration` | Run pytest in `apps/api/tests/integration/` against an isolated SQL Server database upgraded by the application's Alembic revisions. | Requests pass through FastAPI, authentication, membership checks, services, repositories and SQL Server. Assert HTTP results and committed database effects. Exercise workers through their real consumer entry point for event-driven features. |
| `make test-selenium` | Run pytest with Selenium WebDriver in `tests/selenium/` against the built React UI, running API and a separately seeded SQL Server test environment. Use headless Chrome by default. | A user completes an actual task through the browser, receives the expected feedback and can see the correct persisted result after refresh. |
| `make test` | Run all three targets, propagate failures and preserve a separate report per suite. Provide equivalent VS Code tasks wired to these commands. | A fresh checkout can reproduce the three required PR checks with the documented Docker Compose prerequisites. |

Use the same pinned dependencies and browser/driver pairing locally and in CI. Scope temporary databases, identities, storage and worker queues to each run. Use runtime credentials for application assertions and migration credentials for setup. Control third-party identity, telematics, storage and model dependencies through test tenants, local services or boundary doubles as appropriate. Keep production FastAPI token verification and business authorization active during end-to-end tests. Give each Selenium test an isolated browser session and close it even on failure. Wait for an observable condition such as a saved row or a visible conflict. Prefer accessible names and stable resource identifiers when locating elements.

## Feature 001 · vehicle registration

The foundation seed includes two carriers with the same truck number, `TRK-001`. Carrier A's dispatcher has vehicle read/create permissions. Carrier B's dispatcher has read permission. Use a separate new unit number per test so retries and parallel jobs remain independent.

| Layer and example case | Action | Expected result |
|---|---|---|
| Unit · `test_vehicle_create_requires_create_permission` | Exercise the real permission decision with read-only and read/create grants. | Read-only is denied, and read/create permits the action in an active membership. |
| React unit · vehicle form | Submit a form with a required unit number missing. | The field is identified accessibly and no create request is sent. |
| Integration · `test_duplicate_unit_is_scoped_to_tenant` | Submit a valid vehicle through the API as A. Submit a second create in A with the same number and a distinct request key. Read each tenant's seeded `TRK-001`. | The first create persists one asset and vehicle, the duplicate returns the documented conflict, and each read resolves to its own tenant's asset ID. |
| Integration · `test_read_only_member_cannot_create_vehicle` | Submit a valid create as B and inspect resulting state. Repeat a protected read with an expired test identity. | The first call returns 403 with zero inserted rows. The expired identity returns 401. |
| Selenium · `test_dispatcher_registers_vehicle` | Sign in as A, open Vehicles, create a uniquely numbered truck and refresh the list. | The number appears exactly once and its details match the submitted vehicle. |
| Selenium · `test_other_carrier_cannot_see_created_vehicle` | Open a fresh browser as B and find the seeded `TRK-001`. Search for an A-only unit supplied by this test's setup. | B can see its own truck and the search returns the empty state for the A-only unit. This case runs independently of the registration test. |

## Extend coverage as workflows ship

| Requirements | Unit assertion | Integration assertion | Selenium assertion |
|---|---|---|---|
| DISP-01, MNT-02 | Back-to-back reservations are allowed; overlapping intervals conflict. | Two independent SQL connections contend for the same truck. Exactly one assignment commits. Failed reassignment preserves the existing reservation. | The losing dispatcher sees the conflict; refresh shows the winning assignment. |
| MOB-02, TRIP-01, DOC-01 | Completing the first of two required deliveries leaves the trip in transit. | Replay the same offline event. One event persists. Approval for POD v1 cannot satisfy a selected v2. | The driver sees sync confirmation; the delivery view shows v2 as pending until that version passes review. |
| GPS-01–02 | An older observation cannot replace a newer one; include a timestamp tie case. | Send duplicate and out-of-order records through the consumer. The latest projection retains the correct observation. | An authorized user sees the recorded last-seen time and stale label for an overdue position. |
| FIN-01–03, RPT-01 | For USD 1,200 revenue, USD 300 costs and 500 total miles, assert contribution 900, CPM 0.60 and RPM 2.40 using decimal arithmetic. | Compare the report response and CSV for the same tenant, trip, currency and revision. Unknown costs remain provisional and zero miles yield an unavailable rate. | The finance user sees the same figures and mileage basis, and the provisional label for the incomplete fixture. |
| AI-02–07 | The tool allowlist contains only approved reads. | Drive the real tool dispatcher using a deterministic provider double. Verify source authorization and that a requested mutation leaves business rows unchanged. | A permitted answer opens its cited record. An unsupported dispatch request shows the refusal and leaves the assignment unchanged after refresh. |

## Pull-request evidence and failure behavior

Generate required GitHub Actions checks named `unit`, `integration` and `selenium`. Each invokes its matching root command. Integration and browser jobs start isolated Compose stacks, wait for service readiness with a timeout, apply migrations and seed synthetic data. Within Compose, give the browser a web-service URL reachable from its container. Tear down that run's resources in an always-run cleanup step.

Capture suite names, executed case counts, failures, skips, commit SHA and JUnit XML. On browser failure, attach a screenshot of the synthetic workflow and sanitized diagnostics. Treat setup failure, missing SQL Server/browser, zero collected tests and skipped required scenarios as failed checks. Include one deliberately failing assertion during scaffold verification, confirm its job exits nonzero, then restore the assertion and record the green run. Keep the database reference rehearsal on its own fresh database, separate from the application migration suite.
