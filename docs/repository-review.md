# Published repository review

Reviewed against GitHub `main` on 2026-10-20. The documentation cleanup starts from `aeb599bd399e7aa0f61cc376b56527c190e4b819`. [The documentation index](README.md) is the entry point; [the file inventory](files.md) lists the resulting published files. Unrelated pending application/database work is excluded.

## What stays published

| Area | Why it is needed |
|---|---|
| `apps/web/`, `apps/admin/` | Traveler and staff UI source, referenced assets, configuration and regressions. |
| `services/api/` | API implementation, application migrations, maintained/reference catalog SQL and backend tests. |
| Partner agreement JSON/DOCX | Versioned reader text and protected original attachment; distinct from removed root planning originals. |
| `packages/` | Shared client, generated API declarations, domain contracts, UI and tooling configuration. |
| `infra/`, `.github/` | Local topology, validation, maintenance tools and synchronized GitHub workflow discovery copies. |
| Root launcher/manifests/lockfile | Reproducible setup and coordinated workspace tasks. |
| `docs/setup/`, `architecture/`, `api/`, `guides/`, `operations/` | Current developer instructions organized by responsibility. |
| `docs/plans/` | Useful design proposals and acceptance gates, clearly distinguished from implemented behavior. |
| `docs/archive/` | Dated Markdown reports that explain changes and audit conclusions. |

The existing `services/api/app/` nesting is intentional: service project, then Python package. All 20 migration revisions and generated contracts remain intact. Strict JSON, generated declarations and binary assets are described in guides rather than given invalid inline comments.

## Documentation cleanup

The published docs previously mixed current guides with raw SQL extracts and machine-specific history. Current guides now have topic folders and an index; historical reports have a separate archive and dated-status notice. Links in the root README, infrastructure references and archived reports follow the new structure. The structure guard and documentation generator use the new guide paths.

Removed from current Git tracking: **35 files**, approximately **68.4 MB** of original worktree bytes:

- 29 historical SQL audit CSV exports and one overlapping ZIP bundle.
- Three detailed JSON audit/import/recovery dumps whose readable report summaries or Git history preserve their context.
- The local Smartlog checkpoint guide and its recovery report, which describe developer-specific branches, executables and machine recovery.

These are not application inputs or prerequisites for setup, builds or tests. Original copies are preserved locally; historical evidence remains accessible in earlier commits. The 30-of-31 exact file overlap between the old ZIP and expanded audit did not make the entire archive identical; all versions were preserved before untracking. The retained SQL audit report explains the findings without requiring raw exports in the current tree.

Current staff/agreement guides use generic configuration, correct the runtime agreement attachment description and distinguish implemented private package review from proposed public/commerce work. Historical reports keep their original conclusions under an explicit archive notice.

## Earlier source cleanup

The preceding publication removed 210 files under `data/`, two under `wikidata/` and four root planning PDF/Word originals while preserving local copies. Those exclusions remain. Catalog schema and migration source stay published; travel records must be supplied separately. See [local catalog setup](../services/README.md#local-catalog-setup).

Removal affects the current published tree; earlier Git history is unchanged. Real environment values, databases, uploads, dependencies and generated runtime artifacts remain outside the source inventory.

## Maintenance

Change the guide that owns the behavior and update its links and inventory entry. Keep plans marked as proposed until delivered. Preserve useful dated explanations in the archive; keep raw exports and machine-specific recovery state in ignored local storage.

Documentation checks validate links against the tracked publication, not preserved local files. Structure/import checks, static workflow/topology checks and infrastructure regressions cover the coordinated tooling path updates. No application behavior or deployment configuration is changed by this documentation cleanup.

Validation passed in a copy containing only the 665 published files: 1,432 local Markdown links, including 10 heading targets; 18 historical evidence links verified against their pinned Git revision; all 21 infrastructure tests; Python 3.11 syntax, structure/import and static Compose/workflow checks. SHA-256 checks verified the backup of all 77 original documentation files.
