# Folder and database organization

Organized the workspace after the user confirmed moving reference/planning files
while preserving active code and databases. The original root is cleaner; no
file contents or database records were deleted, imported or merged.

## Relocations

The companion [move manifest](file-organization-2026-10-19.json) records original
and new paths, sizes and SHA-256 hashes for all 31 relocated files:

- Five original Word/PDF planning documents moved from the root to
  `docs/plans/source-documents/`. Four were already tracked in Git and remain
  versioned as identical-content renames. The beta setup original was untracked
  and remains local and ignored.
- The old roadmap moved from `extra/` to ignored `docs/plans/local-archive/`.
- The extracted blueprint text and 23 PNG page images moved into ignored
  `docs/extra/blueprint-review/`. The Python document-processing libraries stayed
  under their existing `extra/blueprint-review/tools/` path.
- The unconfigured root `tripraft.db` moved intact to ignored
  `data/archive/root-tripraft-2026-10-19.db`. Its integrity check passed and no
  SQLite sidecars were present. It is an empty travel-schema file, not the active
  application database.

Six SQLite WAL/shared-memory files were removed from Git tracking with
`git rm --cached`; every file remains on disk. Runtime `.db` files were already
ignored. New explicit rules cover runtime data, database archives and SQLite
journals. No Git history was rewritten.

## Paths preserved

The configured development database remains `data/runtime/dev/tripraft.db`.
General travel readers keep `data/catalog/tripraft-canonical.db`; it currently has
no country/state/city/place records. The populated planner catalog remains
`data/catalog/tripraft_places.db`, with 30,339 places at inspection.

Local enrichment datasets, their backups/checkpoints, import inputs, code
archives, dependency environments and source paths were preserved. The deployed
partner agreement under `services/api/app/partners/agreements/` is a runtime input
and was not relocated. Docker ignore rules explicitly retain it while excluding
planning sources and local document extracts.

Updated the root README, architecture/catalog notes, folder/database guide and
data/planning/archive indexes. Historical reports retain their original paths as
records of past operations; the move manifest maps the relocated files.

## Verification

Every move was constrained to resolved paths inside `C:\Tripraft` and verified by
SHA-256. The native launcher's read-only setup check and repository structure and
infrastructure validators passed. Active catalog and archived database checks
were read-only. No new application logic was introduced, and no services were
stopped or restarted for this organization pass.
