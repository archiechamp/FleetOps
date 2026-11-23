# FleetOps — Development and Delivery Specification

**Version:** 1.5 | **Date:** 2026-11-22 | **Status:** Required engineering baseline; hosting proposal pending approval

This document implements DEV-001–DEV-008 in `../spec.md` and ADR-005/011 in `architecture-notes.md`. It specifies the files and commands to build during Gate 0; it is not an executed scaffold or a deployable application.

## 1. Repository and development environment

Use a GitHub monorepo, initially private. VS Code is the primary IDE. Developers install Git, Docker Engine/Desktop with Compose v2, and VS Code. Recommend Docker/Container Tools, Python, Pylance, ESLint, Tailwind CSS IntelliSense and optionally Dev Containers and Claude Code. Pin Node LTS, Python supported minor, npm and lockfiles in the scaffold ADR; verify version compatibility rather than using floating `latest` dependencies. The host does not need SQL Server installed. Linux x86-64 is the supported SQL Server container target; ARM developers use a remote x86-64 development SQL Server or an isolated managed dev database, not an assumed supported emulator.

### Expected repository after Gate 0

```text
fleetops/
├── README.md
├── spec.md
├── AGENTS.md
├── CLAUDE.md
├── .cursorrules
├── .cursor/rules/fleetops.mdc
├── docs/
│   ├── architecture-notes.md
│   └── development-and-delivery.md
├── apps/
│   ├── web/                  # React + TypeScript + Vite + Tailwind
│   │   ├── src/
│   │   ├── package.json
│   │   ├── package-lock.json
│   │   ├── Dockerfile         # dev/build/runtime targets
│   │   └── .dockerignore
│   └── api/                  # FastAPI + SQLAlchemy + Alembic
│       ├── app/
│       ├── alembic/
│       ├── tests/
│       ├── pyproject.toml
│       ├── requirements.lock # or equivalent reproducible Python lock
│       ├── Dockerfile
│       └── .dockerignore
├── packages/api-contracts/   # generated web client types
├── infra/
│   ├── docker/               # reverse proxy and local database helpers
│   ├── deploy/               # staging/prod IaC and release scripts
│   └── runbooks/             # migration, backup, rollback, incident response
├── compose.yaml
├── compose.override.yaml     # optional local hot reload overrides
├── .env.example
├── .gitignore
├── .vscode/
│   ├── extensions.json
│   ├── tasks.json
│   └── launch.json
├── .devcontainer/            # optional; attach to designated dev service
└── .github/
    ├── pull_request_template.md
    └── workflows/
        ├── ci.yml
        ├── release.yml
        └── deploy.yml
```

## 2. Docker runtime design

| Service | Local Compose | Staging / production |
| --- | --- | --- |
| web | Vite dev server, hot reload, loopback port 5173 | Multi-stage Node build → non-root static server / reverse proxy |
| api | Uvicorn reload inside Python image, loopback port 8000 | Non-root FastAPI image, trusted proxy configuration, streaming enabled |
| worker | Separate process, same API image, durable task consumption | Dedicated container app/process with independent scaling |
| sqlserver | Official SQL Server Developer image, named volume | Managed Azure SQL recommended; licensed SQL Server alternative subject to approval |
| queue | Durable compatible broker; Redis proposed, choice must be validated | Managed broker with persistence, retry and dead-letter handling |
| migrate | One-shot Alembic job, explicit execution | Controlled deployment job with separate migration identity |
| object storage | Local compatible emulator or isolated dev bucket | Private managed object storage |

Use one Compose network or separate frontend/backend networks as appropriate; SQL and broker have no published ports by default. Optional local DB tooling binds only to loopback. The web dev proxy forwards `/api` to the internal API service; browser never resolves Compose DNS names. Production reverse proxy serves SPA fallback, `/api` forwarding, and AI streaming without buffering (or use an equivalent tested ingress/routing setup). Health checks use `/health/live` and `/health/ready` for API; readiness checks bounded DB connectivity without exposing internals. Worker health tracks heartbeat and queue progress, not merely process existence. Startup dependency order is not a substitute for retry/backoff or DB readiness. Liveness must not restart healthy processes solely because an external provider is unavailable.

Pin approved base images and SQL Server releases/digests, lock dependencies, use BuildKit caching where appropriate, and build multi-stage images. Keep credentials out of image layers, build args, and logs. Non-root runtime, minimal writable paths, resource limits, graceful SIGTERM, log to stdout/stderr, and vulnerability scans are required for application images. Do not force unsupported non-root changes to vendor images. Never use Developer Edition for production. Store local DB data in a named volume, and document that `docker compose down -v` destroys local state; do not use it as routine shutdown. Use real SQL Server for dialect, concurrency, constraints and migration tests; do not substitute SQLite to claim DB compatibility.

## 3. VS Code workflow and scaffold contract

Create in order: (1) repo and ignore rules; (2) Vite React TypeScript and Tailwind; (3) FastAPI settings, health endpoints, SQLAlchemy and Alembic; (4) containers and Compose; (5) tests and CI; (6) Clerk token validation and tenant-scoped vehicle CRUD; (7) minimum streaming chat spike; (8) stage deploy and rollback. Keep each slice reviewable. Do not generate every fleet module as empty placeholder code.

Once the files exist, the documented command interface should be:

```bash
# New developer: after cloning an actual repository and entering its root
code .
# Copy .env.example to .env using OS-appropriate command; set local values.
docker compose config --quiet
docker compose build
docker compose up -d sqlserver queue
# Follow documented DB bootstrap to create app DB and least-privilege roles.
docker compose run --rm migrate
docker compose up -d web api worker
docker compose ps
docker compose logs -f api
# when finished
docker compose down
```

Compose startup must wait for healthy DB/broker and handle bounded retries. The migration job must target only the selected local DB for these commands; production job uses separate credentials. The scaffold must document the exact bootstrap, storage emulator and test command variants after choosing concrete drivers and services. Recommended VS Code tasks: `Compose: Build`, `Compose: Up`, `Compose: Logs`, `Compose: Down`, `DB: Migrate (local)`, `Test: Web`, `Test: API`, `Test: Integration`. Configure Python debugpy attach on a loopback-only dev port and browser debugger for Vite; no debug listener in production. Dev Containers are optional and must use the same Compose services, not an unrelated second runtime. No blanket Docker socket mounting in untrusted workspaces.

## 4. Environment contract

| Variable/category | Exposure / guidance |
| --- | --- |
| `VITE_CLERK_PUBLISHABLE_KEY` or runtime public config | Browser-safe publishable key only; never inject secret keys into Vite builds |
| `CLERK_*` verification settings | API only; validated issuer/audience/authorized parties as applicable |
| `DATABASE_URL`, SQL bootstrap/migration credentials | API/worker or dedicated migration job; separate roles; local-only bootstrap admin |
| `OPENAI_API_KEY` / `ANTHROPIC_API_KEY`, model identifier | API only; selected provider; feature flag and usage cap |
| Queue and object storage config | Server only; private access and environment isolation |
| Provider signing keys and notification credentials | Server only; encrypted/rotatable |

Use relative `/api` requests and runtime-injected validated public configuration for environment-specific public settings to promote identical web image digests between staging and production; do not bake production Clerk keys or environment-dependent API URLs into a staging image. Public runtime configuration is non-secret and must be served without stale caching. All secrets are injected at runtime via local ignored `.env` or host secret store; GitHub environments may hold deployment settings. Never print Compose config with interpolated secrets into logs; use `--quiet` validation. Keep test/prod accounts, databases, storage and identity independent. Production SQL TLS verification is mandatory; local development trust exceptions are explicit, isolated, and never transferable to staging/prod.

## 5. GitHub repository and CI

Protect `main` with required checks and PR review where supported by repository plan. No force-push or direct unreviewed release changes. Use short feature branches and conventional or clear commit messages; PR references requirement IDs, migrations, screenshots if needed, and tests. Use CODEOWNERS for auth, billing, deployment and migration changes if staffing permits. GitHub Issues/Projects may track the PRD epics; repository docs remain authoritative.

`ci.yml` runs for PRs and main commits. Minimum jobs:

| Gate | Required verification |
| --- | --- |
| Web | npm ci, lint, TS typecheck, unit/component tests, production build |
| Python | locked dependency install, Ruff, type checking, pytest |
| SQL Server integration | pinned x86-64 SQL Server container, readiness, fresh upgrade and prior-schema upgrade, Alembic drift, CRUD, tenant isolation, concurrency, decimal/time semantics |
| API/UI | OpenAPI generated client drift, Selenium WebDriver critical user journeys, AI streaming protocol and disconnect, provider mocks |
| Security | dependency/SAST, secret detection, image CVE policy, prompt-injection/authorization tests |
| Containers | build web and API images, Compose validation, container startup/readiness smoke tests |

Use deterministic test fixtures and mocked identity/LLM/telematics for PR tests. Run limited real-provider integration tests only in trusted environment with scoped secrets and cost controls. Pin Actions by full commit SHA with maintainable version comments; default workflow permissions `contents: read`; do not use `pull_request_target` to execute untrusted code with secrets. Job timeouts and log redaction required. Upload short-retention test reports, never raw driver data. CI failure blocks promotion.

## 6. Release / deployment topology

GitHub Actions is the sole deployment authority. GHCR stores private web and API images (worker uses same API digest with distinct command). Use `ghcr.io/<owner>/fleetops-web` and `ghcr.io/<owner>/fleetops-api`, lowercased as required. Release workflow publishes only from trusted reviewed main commits or protected releases with explicit package write permission. Tag by commit SHA and optional release version, record resolved digest and provenance/SBOM, scan exact images. Never deploy mutable `latest`. Pull identity is read-only; host registry credential/identity access must be validated with GHCR. Do not reuse Actions write credentials at runtime.

Recommended production target: Azure Container Apps (web/API/worker, migration job), Azure SQL Database on private network, managed broker/storage and TLS ingress. This is a proposed cloud deployment target, not a provisioned resource. Alternative: a supported Linux Docker host with an explicitly designed reverse proxy, durable storage, backups, patching and monitored deployment strategy. Select host, region, networking, cost model and credentials in an ADR before enabling live deployments. Vercel optional for separately built SPA only; it is not the primary Docker image runtime. Keep Vercel AI SDK independent of hosting. If optional Vercel SPA is selected, record the artifact/deployment differences and disable competing automatic production deployment hooks.

### Pipeline sequence

1. PR: CI checks as above; no image publish or deployment from untrusted forks.
2. Reviewed main: run required CI for exact commit; build and publish GHCR images, generate release manifest with web/API digests, commit SHA, migration revision and test/scan references.
3. Staging: use approved manifest; provision/update infra separately; run one migration job with scoped credentials and check schema revision; deploy web/API/worker digests; wait for health and run authenticated smoke tests. Verify database, AI stream, and queue processing.
4. Production: require staging evidence and authorized GitHub environment approval; serialize deploys by environment; revalidate manifest, DB recovery readiness and schema compatibility; apply approved compatible migration then rollout identical digests; health/smoke checks before finalizing. Use workload identity/OIDC for cloud access where supported and narrow permissions. Otherwise use a scoped rotating deployment credential. Do not publish image digests with a different build per environment.
5. Record release manifest, deploying actor, environment, previous digests, migration revision, verification outcomes and rollback readiness. Alert responsible operators on failure.

### Migration and rollback policy

Use expand/contract migrations; old/new application versions must remain compatible during rollout and rollback. Back up or verify PITR before migration. Use a separate one-shot migration job, lock to prevent concurrent migrations, and stop release on failure. Never run schema changes automatically in every API replica. On failed smoke/health, stop promotion; restore prior known-good image digests/revisions if schema permits; verify health and resume processing safely. If incompatible schema change occurred, follow approved compensation/restore plan; do not blindly downgrade or restore over newly written data. Define RPO/RTO and rehearse backup restore and rollback in staging. Do not pretend a failed deployment succeeded or silently skip gates.

## 7. Gate 0 acceptance and evidence

Scaffold the three required PR jobs and root commands in the [generation instructions](../spec-kit/feature-test-generation.md) alongside the first real vehicle flow. Each suite has a separate result and blocks merge on failure.

- [ ] A fresh clone opened in VS Code with documented prerequisites runs Compose from scratch.
- [ ] SQL Server runs with persistent local volume; schema upgrade and CRUD pass on the final API image.
- [ ] Authenticated user can query their own tenant vehicle; cross-tenant and invalid token requests fail.
- [ ] Web and API containers have tested health checks, non-root runtime, and no embedded secrets.
- [ ] Approved AI provider streams through container ingress, shows grounded sources and correctly handles unavailable data.
- [ ] Unit, integration and Selenium jobs run executable tests from the implementation commit and publish separate results.
- [ ] The SQL integration job exercises the migrated application database, and the Selenium job drives a signed-in user through the built React application. Container builds pass.
- [ ] Trusted release pushes image digests to GHCR and publishes manifest.
- [ ] Staging deploy uses those digests; smoke tests, migration job, rollback and restore drill are recorded.
- [ ] Production host/security/approval decisions recorded before actual production deploy.

**Evidence required:** commit SHA, command outputs, CI run links, image digests, schema revision, staging smoke results and rollback record. None are claimed by this specification itself.

## 8. Official references (recheck version-specific APIs when implementing)

- Docker Compose: https://docs.docker.com/compose/
- VS Code Dev Containers: https://code.visualstudio.com/docs/devcontainers/containers
- Microsoft SQL Server containers: https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-docker-container-deployment
- GitHub Actions: https://docs.github.com/en/actions
- GHCR: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- Azure Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/overview
- Vercel AI SDK streaming: https://ai-sdk.dev/docs/ai-sdk-ui/stream-protocol
