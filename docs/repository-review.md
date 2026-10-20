# Published repository review

Reviewed on 2026-10-20 against GitHub `main`, starting from `e6e1f15c39f5bc3f85ea3eaa00dff051c4d52f68`. The [complete inventory](files.md) lists the resulting published files and their purposes. This review excludes unrelated pending work in the development checkout.

## What belongs in the repository

| Area | Needed for | Decision |
|---|---|---|
| `apps/web/`, `apps/admin/` | Running and testing the two frontend applications. | Retain source, configuration, regression tests and referenced public assets. |
| `services/api/` | API startup, domain behavior, application migrations and backend tests. | Retain the existing project/package boundaries; no move is needed. |
| `services/api/schema/` | Creating/understanding reference catalogs. | Retain maintained SQL and label older schema references in the service guide. |
| `services/api/migrations/versions/` | Applying established database history. | Retain all 20 revision IDs, including no-op historical revisions. |
| Partner agreement JSON and DOCX | Rendering versioned agreement text and serving the protected original attachment. | Retain both; this DOCX is distinct from the four removed root originals. |
| `packages/` | Shared contracts/client/UI and workspace configuration. | Retain generated client declarations and their reproducible generation workflow. |
| `infra/` and `.github/` | Local topology, validation, CI/deploy integration and ownership. | Retain both canonical workflow definitions and synchronized discovery copies. |
| Root launcher/manifests/lockfile | Reproducible setup and coordinated workspace tasks. | Retain. |
| Active `docs/` setup/API/architecture guides | Helping developers configure and maintain the code. | Retain and update catalog references for a checkout without bundled data. |
| `docs/plans/` | Design proposals and implementation sequencing. | Optional reading; retain as proposals, not claims of implemented features. |
| `docs/reports/` | Dated verification and historical audit evidence. | Optional for runtime; retain because removal was not requested. |

Empty Python package initializers are import boundaries. Generated OpenAPI/client files and the lockfile have specific consumers and should not receive invalid inline comments. File-purpose guides cover these formats instead.

## Requested removals

The following 216 tracked files are removed from the current published tree using index-only removal; their local worktree copies are preserved:

| Removed area | Files | Reason |
|---|---:|---|
| `data/` | 210 | Catalog databases, extracted geography listings, demo inputs and runtime journals are local inputs/artifacts. |
| `wikidata/` | 2 | Local Wikidata processing helper and notes. |
| Four root PDF/Word originals | 4 | Original planning/source documents are kept locally rather than distributed with source. |

The four originals are:

- `TripRaft_Enterprise_Platform_Master_Blueprint.pdf`
- `TripRaft_Places_Search_Live_Tour_Packages_Complete_UPDATED_2026 (1).docx`
- `TripRaft_Professional_Tour_Operator_Partner_Agreement_2026 (1).docx`
- `TripRaft_Unified_Marketplace_Reseller_Complete_Implementation_2026.docx`

Ignore rules prevent accidentally re-adding these inputs and SQLite journals. Earlier commits still contain the removed files; this is a normal cleanup commit, not a history rewrite. The API package-review test now builds synthetic content in memory, and the repository structure check no longer requires `data/seeds/`.

Fresh clones contain schemas, not catalog records. Follow [local catalog setup](../services/README.md#local-catalog-setup) to initialize the empty maintained schema and configure separately supplied populated catalogs. Existing runtime paths under `data/` remain valid local paths; they do not imply that data is distributed by Git.

## Optional material worth reviewing later

`docs/reports/` accounts for roughly 68.6 MB in this revision. Its largest files are historical SQL-seed audit CSV exports. The audit ZIP overlaps 30 of 31 expanded files exactly; `photos.csv` differs, so the archive is not an exact duplicate of the expanded directory. These reports are not required to start the applications, but may be useful as audit evidence. Keep or relocate them through a separate explicit cleanup decision.

No tracked `node_modules/`, virtual environment, uploaded media directory or Python bytecode was found. The tracked SQLite WAL/SHM files were inside the removed `data/` tree. Local environment values and unpublished service/schema changes were not included in this update.

## Validation scope

Checks for this publication use a copy containing only the final published files, excluding preserved local `data/` and `wikidata/`. Structure/infrastructure checks and backend regressions verify that those directories are no longer test prerequisites. The service guide separately verifies all 263 pre-existing service file entries and the single 20-revision migration chain. These checks do not exercise a live deployment or provision external catalogs.

Results: all 470 backend tests and 21 infrastructure tests passed in the source-only copy. Backend Ruff checks, Python 3.11 syntax checks for 245 files, import/path checks and static Compose/workflow validation passed. All 1,424 local Markdown links resolve against published paths. The backend suite reports existing dependency deprecation warnings. Frontend source is unchanged by this update.
