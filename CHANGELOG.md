# FleetOps release notes

## v1.5 · tests generated with the application

DEV-008 adds three required suites to code generation and pull-request CI. The first vehicle workflow includes Python and React unit tests, FastAPI integration tests on a freshly migrated SQL Server database, and Selenium WebDriver journeys for registration and tenant isolation. The same requirement follows each feature through Spec Kit, Codex, Claude Code and Cursor. The [generation instructions](spec-kit/feature-test-generation.md) define commands, case names, fixtures and evidence. The database model remains at v1.1.

## v1.4 · review of the integrated kit

The 22 November 2026 revision updates the product and architecture kit from v1.3 and the database companion from v1.0 to v1.1. It retains the U.S. dry-van pilot, SQL Server foundation, React/FastAPI stack and read-only Copilot beta. Product-owner decisions about identity provider, hosting, driver packaging, finance policy and AI provider remain open.

| Finding in the earlier kit | Change | Review or reproduce |
|---|---|---|
| The workflow described assigning a load, but the API needed a trip ID and offered no planning command. | A dispatcher plans one commercial load and its ordered stops as a trip. A failed assignment preserves the plan; failed reassignment preserves the earlier reservation. Multi-stop completion and driver revocation have observable outcomes. | [Product scenarios and proposed API](spec.md), sections 7–8, and [transaction boundaries](docs/architecture-notes.md), section 7. |
| The delivery link and the reviewer’s decision referred to the parent document. The database could not identify which version supplied the approved bytes. | Both now carry a required version number and a composite FK to the exact tenant/document/version. Reporting matches the selected version to its scan and review. Earlier approvals stay attached to the evidence originally reviewed. | [Data dictionary](docs/database/data-dictionary.md), [documents diagram](docs/database/erd/docs.svg) and [existing-data transition](docs/database/migration-roadmap.md). |
| Dispatch and retry requirements preceded durable idempotency, outbox and restriction handling in the migration plan. | The dispatch feature brings those dependencies forward. Commands bind retry keys to actor/source and payload. The consumer handles a replay after acknowledgement loss. | [Roadmap and requirement mapping](docs/database/migration-roadmap.md) and [architecture](docs/architecture-notes.md), section 10. |
| Financial examples lacked one numerical result the UI, CSV and Copilot could all be tested against. | A two-revenue, two-cost fixture specifies direct contribution, loaded and total mileage rates, currency and incomplete-data behavior. | [Reporting contract](docs/database/reporting-contracts.md) and [pilot fixtures](spec.md), section 7.1. |
| The fixture matched a jurisdiction on code alone, although its key includes country. The RLS smoke covered reads only. | The seed now looks up US/AZ. The SQL Server rehearsal tests a same-code jurisdiction in another country, repeats the seed, checks the expected FK and uniqueness failures, and exercises read and write RLS with a limited principal. | [Verification procedure and results](docs/database/VALIDATION.md). |

## What is ready to use

Product and engineering can walk the five pilot fixtures with an operator, inspect the 17-table foundation, and reproduce the static checks locally. The target remains a phased physical proposal. SQL Server execution, the application workflows, reviewed Alembic migrations and deployment gates require implementation-environment evidence.
