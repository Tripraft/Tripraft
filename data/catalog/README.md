# Canonical travel database

`tripraft-canonical.db` is the project's travel-data source of truth. Its schema
is created empty from the supplied
[`tripraft-global-schema-v2.1.sql`](../../services/api/schema/tripraft-global-schema-v2.1.sql).
This is the authoritative schema for both native startup and Docker builds.
It includes all 31 logical tables, indexes, five triggers, the search-demand view,
and the FTS5 search index. No country seed files or sample records are imported.

A populated catalog can contain imported travel records. Geography is updated
from the three supplied country, state, and city files in `sql_database/` using
[`import_geography.py`](../../sql_database/import_geography.py). See the
[import instructions and audit details](../../sql_database/README.md). Use
`python services/api/init_travel_db.py --check` to validate a populated catalog;
`--require-empty` below is only for a newly initialized catalog.

From the repository root, using Python with the API dependencies installed:

```sh
python services/api/init_travel_db.py --require-empty
python services/api/init_travel_db.py --check --require-empty
```

Native startup and Docker also initialize this database when missing. Repeating
initialization also completes a valid, unmarked SQLite file with no schema objects
(including a zero-byte placeholder). Schema creation holds a write lock and rolls
back if any statement fails. Otherwise it validates and preserves an existing
database, including its data;
it never overwrites or silently migrates an incompatible database. The initializer
checks the complete schema, SQLite integrity, and foreign key consistency.

The SQL schema and both active reference catalog `.db` files are currently
versioned. SQLite journal/coordination files are ignored and are never deployment
assets. Operational databases under `data/runtime/` remain local and ignored.
Generic travel readers and ingestion use `TRAVEL_DATABASE_PATH`;
the ORM travel URL defaults to the same path. `TRAVEL_DATABASE_DIR` can relocate
the catalog. Any explicit `TRAVEL_DATA_URL` must identify the same source or its replica.

The Group Planner has a separate read-only reader configured with
`GROUP_PLANNER_CATALOG_PATH`, defaulting to `data/catalog/tripraft_places.db`.
That populated file is distinct from the initialized canonical database and is
included in the current repository and beta image. Preserve both sources and their IDs
during tour-package implementation. Existing discovery continues using its
configured readers; new agent packages use separate operational records. See the
[Places Search tour-package plan](../../docs/plans/places-search-tour-packages/README.md).

Older reports mention `travel_data_complete.db`; that file is not present at its
former catalog path in the inspected workspace and is not the default database.
User accounts, trips, and expenses continue to use their
separate application database and Alembic migrations.

The `place_search_fts` index uses external content from `places`. Schema triggers
keep it synchronized with inserts, updates, and deletes. SQLite's internal FTS
shadow tables contain structural metadata even while all logical tables are empty.
New recurring hours use `place_hours_intervals`; new prices use
`ticket_price_revisions`, as defined in the supplied schema.

For country enrichment, run `python wikidata/countries.py` from the root.
The [country importer](../../wikidata/countries.py) reads all existing country
IDs directly from this database and processes the full roster in one run.
It preserves IDs, refreshes available facts, backs up the catalog before applying,
and saves source snapshots and reports under `wikidata/data`. See the
[import commands and field mapping](../../wikidata/README.md).

The older `services/api/schema/tripraft-canonical-schema.sql` is retained only
as a reference. Existing databases with that older structure need an explicit
upgrade before startup will accept them; initialization never silently migrates
or erases existing records. The local empty catalog was rebuilt for v2.1 after
backing up its previous empty structure under `.tripraft/database-backups/`.
