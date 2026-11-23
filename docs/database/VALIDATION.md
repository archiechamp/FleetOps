# Validation record · integrated kit v1.4

## Checks completed on the packaged design

| Check | Result |
|---|---|
| Full target and foundation reference DDL against the JSON model | 174 tables, 1,839 columns and 653 FKs in the target. The dependency-closed foundation has 17 tables, 154 columns and 39 FKs. Column type, order, nullability, defaults, identity, primary keys, unique keys, checks, foreign keys and secondary index definitions match the model in the supplied DDL layout. |
| Tenant and phase integrity | Tenant-owned parent references pair the local and parent tenant columns. Referenced columns and types match a parent key. Foundation references stay in the subset. P0/P0B references stay within those two phases. |
| Catalogs and diagrams | Flat CSV rows match the JSON column entries. Dictionary column lists and domain DOT nodes match the model. Parent/child edge counts match by table pair. The 17 domain SVGs and the foundation overview parse as XML. The documents diagram was regenerated with the revised keys. |
| Fixtures and RLS structure | The 28 seed inserts cover the required columns for their tables. The optional policy lists one read filter and four write predicates on each of nine tenant-owned foundation tables. |
| Acceptance fixtures | Both child FKs identify the exact POD version. Independent decimal arithmetic confirmed contribution and all four per-mile examples. The UI, CSV and Copilot comparisons are future acceptance tests. |
| Archive | Verified ZIP integrity, all 263 relative Markdown file links and six SQLCMD includes. Static validation passed after extraction and detected each of three induced errors in scratch copies: a changed column type, a missing RLS operation and a diagram edge pointing to the wrong parent. |

To repeat the model, DDL, fixture and atlas checks, run this command from the kit root with Python 3.9 or later. It uses the standard library.

```sh
python3 database/tools/verify_kit.py
```

## SQL Server rehearsal · pending engine execution

This revision was reviewed in an environment without SQL Server, a Docker engine or a configured SQL Server connection. No Alembic history or application exists in the kit. Live engine behavior, actual connection-pool reuse, application authorization, concurrency and query performance remain open verification items.

Use a fresh empty disposable SQL Server database, an authenticated local sqlcmd session with DDL and impersonation privileges, and the extracted kit as the working directory. This POSIX example reads the server and user database names from your environment. Use the normal authenticated TLS connection settings for your installation.

```sh
ALLOW_SYNTHETIC=YES sqlcmd -b \
  -S "${FLEETOPS_SQL_SERVER:?set the disposable SQL Server address}" \
  -d "${FLEETOPS_TEST_DATABASE:?set the empty test database name}" \
  -i database/sql/verify-foundation.sql
```

The driver exits on errors. It refuses system databases and databases containing user tables. It creates the foundation, adds a fixture jurisdiction with the same code in a different country, runs the seed twice, verifies the resulting counts across all 17 tables, and checks the country-qualified vehicle data. It exercises the composite asset FK, tenant-local unit uniqueness and stale row versions. It installs the optional RLS policy and impersonates a dedicated user with read access to assets and limited terminal writes. Cases cover native UUID tenant contexts A and B, missing and text contexts, an authorized insert, a filtered update, prohibited inserts and tenant changes, and context cleanup on the same session. The user has no login and is removed on success. Use a fresh test database after a failed rehearsal.

An engine pass requires a zero process exit status and the final message `Foundation verification completed`. Capture the server version, database compatibility level and client version with the result. Record driver/pool checkout, failed reset invalidation, RBAC, concurrent assignments, feature migrations and load tests separately when the application exists. Run the reference rehearsal and the Alembic upgrade on separate fresh databases.

The harness uses sqlcmd include files and session-scoped SQL Server security predicates. [sqlcmd commands](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-commands) · [Scripting variables](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-use-scripting-variables) · [Row-level security](https://learn.microsoft.com/sql/relational-databases/security/row-level-security)
