# Marketplace catalog boundary

Recorded 18 October 2026. Status: engineering boundary recorded; canonical release selection remains open.

## Decision

Keep current SQLite source files and reader routing intact during the commerce foundation. Add no catalog inventory, booking state or operational money columns to `places`. A new package-to-place reference will carry a catalog namespace plus source entity ID and release fingerprint/provenance. Do not merge rows or redirect readers based solely on equal numeric IDs or row counts.

The canonical schema initializer remains a schema authority; an empty initialized database is not evidence of populated discovery coverage. Selecting and distributing a populated canonical release is a separate reviewed data change.

## Current evidence

| Source | Role and finding |
| --- | --- |
| `data/catalog/tripraft-canonical.db` | Default generic travel source in `Config.TRAVEL_DATABASE_PATH`; initialized schema, zero places |
| `data/catalog/tripraft_places.db` | Planner source in `Config.GROUP_PLANNER_CATALOG_PATH`; 191 countries, 6,478 cities and 30,339 places |
| `data/catalog/travel_data_complete.db` | Preserved older catalog; 16,830 places and five foreign-key violations in the inspected copy |
| `script/data/catalog/tripraft_places.enriched.db` | Enrichment working catalog; 30,339 places in initial inspection; keep separate from published planner file |
| `script/data/catalog/tripraft_places.enriched.db.backup-20261014-142422-445649.db` | Historical snapshot with 190 countries and 22,925 places, matching the blueprint's reported counts |
| `script/data/catalog/tripraft_places.table_enriched_v2.db` | Active enrichment database; changed during initial inventory; its verified online snapshot contains 30,339 places |
| `script/data/catalog/tripraft_places.table_enriched_v2.db.checkpoints.sqlite3` | Enrichment progress state; preserve with database snapshots |
| `data/runtime/dev/tripraft.db` | Native launcher's operational data candidate; active WAL requires online backup to include committed rows |

These are observed local files and static reader defaults, not proof of a deployed production configuration. Inventory does not import application configuration or read `.env` files. Existing environment/container overrides must be checked when the corresponding deployment is selected.

## Consequences

The current Group Planner remains on its configured catalog. Marketplace development can use an explicit catalog adapter and namespace without rewriting existing place IDs. Generic discovery may still be empty under its current default; the phase-zero checkpoint reports that condition rather than replacing data automatically.

A populated local planner database is untracked in this checkout. A reproducible fresh clone therefore needs an approved data-release distribution process, schema compatibility checks and a version/hash manifest. Do not commit private operational databases or active enrichment checkpoints as a substitute.

## Release-selection gate

Compare schemas, place identity mappings, provenance/verification fields, licensed media, geography coverage, foreign keys and known unresolved fields. Explain conflicts and preserve enrichment history. Resolve legacy foreign-key violations before migrating that source into a consolidated release. Publish a release manifest and test all reader paths against a disposable copy before changing defaults. Runtime tests and row counts do not certify content accuracy or license rights.

Database snapshots and detailed manifests are private under `.tripraft/phase0/2026-10-18/`. The reusable [inventory tool](../../infra/tools/catalog_inventory.py) and [backup/restore tool](../../infra/tools/backup_sqlite.py) are versioned source.
