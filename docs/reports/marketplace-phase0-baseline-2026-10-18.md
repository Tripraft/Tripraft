# Marketplace phase zero engineering baseline

Recorded 18 October 2026. Local checkpoint: `unified-marketplace-phase-0`. Implementation started from the [unified marketplace plan](../plans/unified-marketplace-reseller/README.md).

The first implementation slice adds reusable catalog inventory and SQLite backup/restore tooling, captures the current verification baseline, preserves existing work and records the decisions needed before commerce. Workspace and supplier feature implementation follows in phase one/two; this checkpoint does not claim their delivery.

## Delivered

- [Catalog inventory CLI](../../infra/tools/catalog_inventory.py): bounded discovery, immutable read-only metadata, file/schema fingerprints, counts, ID/FK structure, static reader references, WAL deferral and changing-source detection. It imports no application configuration and exports no application rows.
- [SQLite recovery CLI](../../infra/tools/backup_sqlite.py): explicit source selection, online snapshots including committed WAL content, refusal to overwrite sources/output, isolated restoration, integrity checks and schema/count/content comparison.
- [Inventory regressions](../../infra/tests/test_catalog_inventory.py) and [backup/restore regressions](../../infra/tests/test_backup_sqlite.py): 25 tests pass, covering missing/invalid sources, unusual identifiers, WAL, private-value omission, changed restore contents, timeout and path protection.
- [Commercial decision register](../decisions/marketplace-phase0-decisions.md), [catalog boundary](../decisions/marketplace-catalog-boundary.md), [provider shortlist](../decisions/marketplace-provider-capabilities.md), and [reproducible runbook](../runbooks/commerce/phase0-baseline.md).
- Corrected catalog documentation to acknowledge the Group Planner's separate configured reader. Existing application defaults, source IDs and data were preserved.

## Preservation and recovery evidence

The starting branch was `tripraft_places_enrichment`, at commit `1e08d3d`. Four tracked files already had edits: `infra/tests/test_launcher.py`, `script/table_scripts/README.md`, `script/table_scripts/core.py` and `script/table_scripts/run_all.py`. Those files remain outside this checkpoint's staged implementation scope. Twelve selected working/reference files were copied and hash-verified under an ignored preservation directory before integration.

Two independently timed snapshot sets cover all ten databases discovered in the known catalog/runtime directories. Every snapshot was restored into a new private path and passed schema, row count, logical content and SQLite integrity comparison. The manifests retain backup/restore file hashes and existing foreign-key issue counts. Snapshot-set timestamps describe their start times, not simultaneous capture across databases.

| Source | Places in verified snapshot | Existing FK violations | Restore result |
| --- | ---: | ---: | --- |
| `data/catalog/tripraft-canonical.db` | 0 | 0 | Verified |
| `data/catalog/tripraft_places.db` | 30,339 | 0 | Verified |
| `data/catalog/travel_data_complete.db` | 16,830 | 5 | Verified with existing issues preserved |
| `data/runtime/tripraft.db` | Not a place catalog | 0 | Verified |
| `data/runtime/dev/tripraft.db` | Not a place catalog | 0 | Verified, including committed WAL |
| `tripraft.db` | 0 | 0 | Verified |
| `script/data/catalog/tripraft_places.enriched.db` | 30,339 | 0 | Verified |
| `script/data/catalog/tripraft_places.enriched.db.backup-20261014-142422-445649.db` | 22,925 | 0 | Verified |
| `script/data/catalog/tripraft_places.table_enriched_v2.db` | 30,339 | 0 | Verified after live-source inventory was unstable |
| `script/data/catalog/tripraft_places.table_enriched_v2.db.checkpoints.sqlite3` | Progress state | 0 | Verified |

The historical enrichment snapshot has 190 countries and 22,925 places, consistent with the blueprint's supplied catalog counts. The planner and current enriched snapshots have 191 countries and 30,339 places. Counts alone do not establish identical physical places, provenance or publication rights.

Detailed local evidence stays under `.tripraft/phase0/2026-10-18/`:

```text
preserved-work/                 selected original working/reference files
preserved-work-manifest.json    original/copy hash verification
database-snapshot/             six catalog/operational backups and restore copies
enrichment-snapshot/           four enrichment/progress backups and restore copies
snapshot-inventory.json        stable metadata from completed backup files
snapshot-inventory.md          readable snapshot inventory
verification/                  exact commands, versions, logs and exit codes
```

These private files are intentionally ignored by Git. They may contain operational data and are local recovery copies, not an off-machine backup policy. Independently captured enrichment/checkpoint databases require the pipeline's aligned resume validation before disaster recovery. Neither tool changes production routing or proves a deployed environment's effective configuration.

## Verification results

Structure checks, root lint, typechecking and both frontend production builds passed. The new tool tests and explicit Ruff checks passed. The aggregated root test command failed in existing launcher tests before it could reach workspace tests. The application workspaces were therefore tested independently: all 769 application tests passed. The machine-readable companion summary records the final outcomes.

| Check | Result |
| --- | --- |
| `pnpm structure:check` | Passed |
| `pnpm lint` | Passed, six tasks |
| `pnpm typecheck` | Passed, five tasks |
| `pnpm build` | Passed, both apps; existing chunk-size warnings |
| New inventory/recovery tests | 25 passed |
| Ruff on four new Python files | Passed |
| Root `pnpm test` | Failed: launcher tests had three assertion failures and one mock error |
| Independent API suite | 410 passed |
| Independent web suite | 39 suites and 356 tests passed |
| Independent admin suite | One suite and three tests passed |

The independent workspace test task completed successfully. Existing React `act` warnings and API deprecation/cache-permission warnings were retained in the local logs; the API run reported 532 warnings. These do not change the passing test outcomes or make the failing root launcher gate green.

The failing launcher cases are `test_running_pids_lifecycle`, `test_stop_existing_frees_pids_and_ports`, `test_stop_stale_services_terminates_only_saved_pids` and `test_startup_failure_cleans_only_the_created_child`. The first three expect old saved-PID behavior; the fourth mocks `Popen` while startup now invokes `subprocess.check_output` for port discovery. No launcher source or pre-existing user edits were changed in this checkpoint. Resolve these cases in a dedicated follow-up before calling the root verification gate green.

Captured runtime versions: Node 24.11.0, pnpm 10.34.6, Python 3.11.4, Flask 2.3.2, SQLAlchemy 2.0.45, Alembic 1.18.4, React 18.3.1, Vite 5.4.21, TypeScript 5.9.3, Turbo 2.11.7 and Jest 29.7.0. This identifies the local environment; it is not a dependency-upgrade recommendation. PostgreSQL commerce/concurrency validation belongs to the next implementation phase and was not established by this SQLite baseline.

## Remaining gates and next slice

The user confirmed on 18 October that incorporation/merchant country, receiving-bank country and supplier geography are undecided. Provider account approval, legal seller terms, charge currency, tax/invoice policy, pilot contracts and refund/support obligations remain open. The [decision register](../decisions/marketplace-phase0-decisions.md) records owners and dependencies. The complete phase-zero commercial exit gate is therefore open.

The next independent engineering slice is workspaces/membership/capabilities plus an isolated PostgreSQL test harness, preserving current users, trips, expenses and invitation IDs. Catalogue release selection still requires provenance/mapping/distribution review. Live gateway/provider selection and production tax configuration wait for their business inputs; the engineering foundation can use explicit fake-provider fixtures.
