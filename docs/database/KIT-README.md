# FleetOps Database Design Kit v1.1

Companion to FleetOps Spec & Architecture Kit v1.5. Proposed target physical model for SQL Server, FastAPI/SQLAlchemy/Alembic, Docker, GitHub Actions, VS Code and Spec Kit. 174 base tables, 1,839 columns, 653 FK relationships across 17 base-table schemas plus reporting view schema. 17 foundation tables; P0, P0B (AI beta), P1 and P2 are deliberately separated.

## Read order

1. [Database architecture](database-architecture.md)
2. [Data dictionary](data-dictionary.md) and [table constraints/indexes](constraints-and-indexes.md)
3. [Physical ERD atlas](entity-relationship.md) (SVG diagrams plus DOT sources)
4. [Business rules](business-rules.md), [migration roadmap](migration-roadmap.md), [retention](data-retention-policy.md), [reporting contracts](reporting-contracts.md)
5. [Spec Kit planning instructions](../../spec-kit/database-planning-instructions.md)

## Reference files and execution

The table contract lives in `database/metadata/model.json`. Its flat column export, physical dictionary, constraints, domain diagrams and reference DDL describe the same proposed model. Use [the validation record](VALIDATION.md) to reproduce the static checks and run the SQL Server foundation rehearsal in an empty disposable database. Begin implementation with the 17-table subset and the [Feature 001 planning instructions](../../spec-kit/database-planning-instructions.md). Each later feature brings its own approved Alembic revision and service-level tests.
