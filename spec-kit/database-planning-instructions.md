# GitHub Spec Kit database planning instructions

Use inside the existing FleetOps repo in VS Code + Claude Code. This kit supplements root spec.md, AGENTS.md, architecture and delivery notes; it does not replace feature specifications or the constitution. Commands may vary by installed Spec Kit integration; inspect locally and use the generated skills/commands. Do not reinitialize a working Spec Kit repository just to add these files.

## Constitution amendment (review before adoption)

Run `/speckit-constitution` (or installed equivalent): incorporate docs/database/database-architecture.md, business-rules.md and migration-roadmap.md. Enforce schema-qualified SQLAlchemy models, Alembic-only schema changes, tenant composite FKs + backend RBAC, validated RLS, Decimal, UTC, rowversion, audit, transactional reservations, idempotent imports, no arbitrary AI SQL, actual SQL Server tests in Docker and CI. Keep unresolved choices in ADRs. Do not grant model or web client database access.

Generate unit, integration and Selenium suites alongside application code under [DEV-008](feature-test-generation.md). Include test ownership and executable CI commands in the feature plan.

## Feature 001 planning prompt

Run `/speckit-plan` for the approved project foundation feature:

> Read root spec.md, AGENTS.md, docs/architecture-notes.md, docs/development-and-delivery.md and the entire database architecture kit. Treat database/metadata/model.json as the proposed physical contract. Generate specs/<active-feature>/data-model.md from the 17 foundation tables and their exact keys/types/constraints; check dependencies and report conflicts. Implement only these foundation objects through reviewed SQLAlchemy and Alembic after plan approval. Verify SQL Server Docker x86-64 environment and driver, UTC/UUID/ROWVERSION/DECIMAL handling, stable identity bootstrap and RLS strategy, protected session context and scoped grants. Use the 001 SQL script as reference, not a second schema mechanism. Seed two fictional tenants in a disposable DB only. First run `python3 database/tools/verify_kit.py` and record the result. Rehearse the reference on a separate disposable database using `database/sql/verify-foundation.sql`; compare its intended constraints with the actual migration without applying both to one database. Generate API contracts for vehicle CRUD and tenant membership, plus tests for missing context, cross-tenant read/write, role permissions, duplicate unit number, stale version and SQL Server migration. Generate the Feature 001 unit, SQL Server integration and Selenium vehicle-registration and tenant-isolation cases from the DEV-008 instructions. Wire them to the three root test commands and required PR jobs. Define CI fresh/upgrade and schema drift gates, no production deployment. Document actual commands and results; do not claim tests passed without executing them.

## Subsequent feature cycle

Specify feature outcomes and exclusions, clarify ambiguity, plan table subset and dependency closure, update feature data-model.md and approved global metadata through reviewed PR, generate tasks, analyze consistency, implement/test, verify convergence with spec/plan/tasks. Trace PRD ID → DBR rule → table/constraint/service → test → CI evidence. Add only approved tables; any schema alteration must update dictionary, ERD and constraints metadata. Confirm status vocabulary, nullable semantics, precision, security and retention with each phase. Use the reference target SQL for inspection, not mass deployment. Add reporting views only once grain, definitions and permission requirements are approved.

### Task template

- Requirement / feature ID and DBR IDs
- Tables/columns, constraints, index and FK dependencies
- Migration revision and compatibility plan
- Repository/service authorization and transaction behavior
- Requirement → test file and case → fixture/action → expected result at each affected layer, including SQL Server integration and Selenium UI journeys
- Security/retention review and rollback or forward-fix plan
- Evidence (command output, CI link) and status
