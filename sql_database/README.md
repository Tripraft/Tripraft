# Geography import

These source files update the active catalog at `data/catalog/tripraft-canonical.db`:

- `countries_table.sql`: 190 countries and territories.
- `states table.sql`: 1,739 states and subdivisions.
- `tripraft-cities-all-3380-audit.csv`: 3,380 cities and destination bases.

From the repository root:

```sh
python sql_database/import_geography.py
python sql_database/import_geography.py --apply
```

The first command previews the complete import and rolls back. `--apply` first
backs up the existing database under `.tripraft/database-backups/`, then commits
the import in one transaction. The existing canonical database must already exist
and match `tripraft-global-schema-v2.1.sql`.

Existing IDs and parent identities are checked before updates. Country and state
creation and retirement dates are preserved, following the SQL files. City fields
use the CSV values, with blank fields stored as NULL. All 28 CSV columns, including
original values, source links, methods, and notes, are retained as JSON in
`field_verifications` with `column_name='source_record'`. Country and state source
records are retained there too; generated country lifecycle dates are excluded
from source evidence. Importing a source does not independently verify its claims.

The CSV has 795 cities without coordinates. Their missing latitude and longitude
are also recorded in `unresolved_fields`. Other catalog contents are preserved.
Checks cover every imported row, complete audit records, unchanged unrelated tables,
the canonical schema, SQLite integrity, foreign keys, and FTS integrity.

Results and source SHA-256 hashes are saved in `geography-import-report.json`;
preview results are saved in `geography-import-preview.json`. Repeating the same
import preserves existing evidence records and logs only changed field values.
