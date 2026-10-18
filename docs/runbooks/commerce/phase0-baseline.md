# Marketplace phase zero inventory and recovery

Run from the repository root using the project's Python environment. These commands create local private reports/snapshots and do not import application settings or issue network payments. Snapshot paths must be new; reruns use a different output directory.

## Inventory

```powershell
.\.venv\Scripts\python.exe infra/tools/catalog_inventory.py `
  --json-output .tripraft/phase0/catalog-inventory.json `
  --markdown-output .tripraft/phase0/catalog-inventory.md
```

Default discovery is bounded to known catalog/runtime directories. Pass repeatable `--database <path>` arguments for verified deployment paths or completed snapshots. Missing paths are reported without creating empty databases. Immutable read-only inventory creates no SQLite sidecars; if a nonempty WAL/journal exists, inspect an online-backup snapshot instead. A changed file or sidecar invalidates the inspection's consistency claim.

Reports contain counts, schemas, fingerprints, structural key checks and static reader locations. They do not contain application rows or `.env` values. Keep the detailed runtime metadata private.

## Snapshot and restoration rehearsal

```powershell
.\.venv\Scripts\python.exe infra/tools/backup_sqlite.py `
  --source data/catalog/tripraft-canonical.db `
  --source data/catalog/tripraft_places.db `
  --source data/catalog/travel_data_complete.db `
  --source data/runtime/tripraft.db `
  --source data/runtime/dev/tripraft.db `
  --source tripraft.db `
  --output-dir .tripraft/phase0/new-baseline-snapshot
```

Select only paths that actually exist. For enrichment, include the working enriched catalog, active table-enrichment database and its checkpoint database as separate `--source` arguments. Preserve source snapshots, enrichment code and evidence as well; a database snapshot is not a complete disaster-recovery backup of uploads/secrets/external infrastructure.

The tool reads sources with SQLite's online backup API, including committed WAL content, and writes standalone backups under `databases/`. It restores each into `restore-check/` and verifies schema, counts, user version, structural integrity and per-table content digests. Source data is never restored in place. A snapshot file can preserve existing foreign-key violations; the manifest reports those separately from successful restoration. Verify and repair original data issues in a separately reviewed task.

Files must stay within the workspace; paths resolving outside it are rejected. Sources and existing output directories cannot be overwritten. Invalid/timeout/failed integrity results produce a nonzero exit and evidence in the manifest. Partial files remain for diagnosis; do not assume that their existence means they are a verified backup.

Record a manifest reference and snapshot time for each independently backed-up database. Separate catalog and checkpoint snapshots are not one cross-database transaction. If resuming an enrichment pipeline requires an exactly aligned pair, coordinate its writer, take an additional aligned snapshot and validate the pipeline's own restart contract before resuming from it.

## Verification baseline

Run the root structure, lint, typecheck, test and build checks separately to retain each result. Use the repository virtual environment first on PATH. If root tests fail during infrastructure tests, run `pnpm exec turbo run test` independently so application tests are not hidden by short-circuiting. Save stdout/stderr, command, exit code, version and duration under an ignored dated `.tripraft/phase0/` directory.

New phase-zero tool tests:

```powershell
.\.venv\Scripts\python.exe -m unittest `
  infra.tests.test_backup_sqlite infra.tests.test_catalog_inventory -v
```

Before a source checkpoint, confirm unrelated dirty files still match their preservation manifest. Stage explicit implementation/report paths, inspect the staged diff, and commit only that scope. Use the existing [Interactive Smartlog workflow](../../backend-checkpoints.md); keep its authentication URL/token out of tracked files.
