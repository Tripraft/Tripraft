# Country enrichment

One standalone Python 3.10+ script processes **every country already in the database**
(currently 190) in one invocation. No packages, API keys, or manual country selection.

```powershell
python wikidata/countries.py
```

The default database is `data/catalog/tripraft-canonical.db`. The script resolves each
country's English Wikipedia article to its Wikidata entity, then downloads structured
facts using Wikimedia's public APIs. It refreshes available fields in `countries`:

| Column | Wikidata property | Stored format |
| --- | --- | --- |
| `iso2` | P297 | Two uppercase letters |
| `iso3` | P298 | Three uppercase letters |
| `iso_numeric` | P299 | Three digits, including leading zeros |
| `currency_code` | P38 → P498 | ISO 4217 currency code(s) |
| `calling_code` | P474 | Calling code(s), including `+` |
| `capital` | P36 | English capital name(s) |
| `region` | P30 | English continent name(s) |

`region` means continent, consistent with the existing country data. Multiple current
currencies, capitals, calling codes, or continents are stored in sorted order separated
by `; `. The report retains their individual source statements. Ambiguous ISO codes,
missing linked values, deprecated statements, ended claims, and future claims are
excluded. Currency entities without alphabetic ISO codes are reported separately;
the available ISO currency codes are still stored. Unavailable facts leave stored
values unchanged, including NULLs.
Kosovo's source codes are unofficial, and its ISO numeric code may be unavailable.
The Netherlands' ISO codes are read from its verified sovereign kingdom (P17);
its capital, currency, and continent still come from the Netherlands entity.
English Wikipedia titles provide names when English Wikidata labels are unavailable.

Existing country IDs, names, creation dates, and retirement dates are preserved.
Available source facts replace differing stored facts. Unavailable source values
leave stored values unchanged. `updated_at` changes only when a fact changes.
Retired records are skipped. There are no country inserts, deletes, schema migrations,
or changes to states, cities, or places. Before-and-after values appear in the report.
Use `--only-missing` to preserve populated fields and report differences instead.

Before applying changes, the script creates a SQLite backup (including committed WAL
data), checks the downloaded plan against the current country rows, and uses a
transaction. Country constraint failures roll back that country's changes and are
reported while other countries continue. Unexpected write failures roll back the
transaction. A process lock prevents simultaneous runs of this importer against the
same database. The canonical catalog's existing provenance tables receive a batch,
source records, change logs, and `partial` field verifications; a single Wikimedia
source is not independent verification. A database containing only your supplied
`countries` table is also supported, with provenance in the JSON files.

Downloads use batches of 25, timeouts, bounded retries, exponential backoff,
`Retry-After`, `maxlag`, gzip, and a 24-hour disk cache. Rerunning is safe and reuses
fresh downloads. Set a contact in `WIKIMEDIA_USER_AGENT` or `--user-agent` if desired.

```powershell
python wikidata/countries.py --dry-run
python wikidata/countries.py --only-missing
python wikidata/countries.py --cache-hours 0
python wikidata/countries.py --database C:\path\catalog.db
python -m unittest discover -s wikidata/tests -v
```

Each run writes `wikidata/data/runs/<batch>/report.json`, `sources.json`, and, when
updating, `before.db`. `wikidata/data/latest.json` points to the latest completed
report. JSON files are written atomically. The source snapshot retains the raw
Wikidata statements, qualifiers, references, and linked entity data. Exit codes:
0 = completed (unavailable fields may remain); 1 = source, validation, write failure,
or conflicts requiring review; 130 = interrupted. Dry runs do not update database
records but still save downloads, reports, and a process lock file.

Source data is [Wikidata CC0](https://www.wikidata.org/wiki/Wikidata:Data_access).
API access follows [MediaWiki etiquette](https://www.mediawiki.org/wiki/API:Etiquette).
This imports structured country facts; the Wikimedia project links pasted in the
request are a navigation footer rather than a country dataset.

The previous Wikidata scripts and generated files were moved out of this folder to
`.tripraft/wikidata-legacy-20261009/`, preserving their backups and history.
