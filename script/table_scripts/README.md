# TripRaft per-table enrichment — repaired, no-duplicate edition

**This edition is designed for an already completed `tripraft_enrich.py` run.** It creates a new SQLite copy and by default **skips `places.py`, `photos.py`, and `photo_attributions.py`** to avoid repeating Wikimedia place/photo research. Existing non-empty research facts are never overwritten, including when using `--force`. The original enriched DB is not modified.

## Run on Windows PowerShell

1. Extract this ZIP to `C:\Tripraft\script\` (result should be `C:\Tripraft\script\table_scripts\core.py`). Close any previous failed worker before starting.
2. From PowerShell:

```powershell
cd C:\Tripraft\script\table_scripts
python run_all.py list
python run_all.py start --all --contact rdcoding1842@gmail.com --db "C:\Tripraft\script\data\catalog\tripraft_places.enriched.db" --output "C:\Tripraft\script\data\catalog\tripraft_places.table_enriched.db"
python run_all.py status --output "C:\Tripraft\script\data\catalog\tripraft_places.table_enriched.db"
```

The default stages are countries, states, cities, tags, place_tags, place_hours_intervals, ticket_price_revisions, festivals, opening_hour_exceptions, and place_access_events. Explicit `--only` overrides this default; `--only places` researches *only missing columns for already identified Wikidata QIDs*, never retries unmatched places. `photos.py` remains an optional manual stage, not the default.

3. Watch the log in a second terminal:

```powershell
Get-Content "C:\Tripraft\script\data\catalog\tripraft_places.table_enriched.db.tables.worker.log" -Tail 30 -Wait
```

4. Stop safely and resume:

```powershell
python run_all.py stop --output "C:\Tripraft\script\data\catalog\tripraft_places.table_enriched.db"
python run_all.py start --all --contact rdcoding1842@gmail.com --db "C:\Tripraft\script\data\catalog\tripraft_places.enriched.db" --output "C:\Tripraft\script\data\catalog\tripraft_places.table_enriched.db"
```

**Existing output warning:** The pipeline reuses an existing `.table_enriched.db` and does not import new data from the input on later runs. If a previous failed attempt already created the output copy from an incomplete input, back it up and start with a *new output filename*, e.g. `tripraft_places.table_enriched_v2.db`. Never delete an active worker's database.

## Coverage

Run `python coverage.py --output "C:\Tripraft\script\data\catalog\tripraft_places.table_enriched.db"` and examine the populated vs verified fields. Not all hours, prices, festivals, and subjective fields are obtainable from the available free sources. No 80–90% guarantee.

---

# TripRaft: separate enrichment script per table

Python 3.10+, standard library only. **Not a guarantee of 80–90% verified fields**. Scripts only store evidence-supported facts, preserve existing IDs and related rows, and report missing/conflicting fields. Official web sites, hours, admissions, special events and subjective scores may be unavailable. This is a first modular research system, not a full human-quality website agent.

## Starting location

Extract this ZIP to `C:\Tripraft\script\table_scripts`. The scripts automatically search upwards for `data\catalog\tripraft_places.db`, so it works from `C:\Tripraft\script` too. You can always set `--db "C:\Tripraft\data\catalog\tripraft_places.db"` explicitly.

A **working copy** `data\catalog\tripraft_places.table_enriched.db` is automatically created once. **Never run it concurrently against the older enrichment worker's output** or intentionally target the same SQLite file from two workers. To preserve your prior worker's findings, finish/pause that worker first, then use its **enriched DB as `--db`** and set a new `--output` path (example below). This software does not mutate the original DB unless you explicitly use `--in-place`.

## Quick start (PowerShell)

```powershell
cd C:\Tripraft\script\table_scripts
python countries.py --country Algeria --contact rdcoding1842@gmail.com
python states.py --country Algeria --contact rdcoding1842@gmail.com
python cities.py --country Algeria --contact rdcoding1842@gmail.com
python places.py --country Algeria --contact rdcoding1842@gmail.com --limit 10
python photos.py --country Algeria --contact rdcoding1842@gmail.com --limit 10
python photo_attributions.py --country Algeria
python tags.py --country Algeria
python place_tags.py --country Algeria
python coverage.py --output ..\..\data\catalog\tripraft_places.table_enriched.db
```

You can also run the **sequential country pipeline** (individual table scripts called one at a time):

```powershell
python run_all.py run --country Algeria --contact rdcoding1842@gmail.com --limit 5
python run_all.py start --all --contact rdcoding1842@gmail.com
python run_all.py status
python run_all.py stop
python run_all.py resume --all --contact rdcoding1842@gmail.com
python run_all.py run --country Albania --only places,photos --contact rdcoding1842@gmail.com
```

`start` runs a background process on **your Windows computer**, independent of the terminal. Keep the PC awake and online. Each completed entity has an individual checkpoint in `<output>.checkpoints.sqlite3`. The `<output>.events.jsonl` log and `<output>.progress.json` are updated as work continues. Stop waits for the current item to finish, then resume skips completed items. `--force` revisits *every* item, including previous `no_match` cases (useful after improving match rules, but increases traffic and duplicates unresolved audit rows across batches).

**Monitor:**

```powershell
while ($true) { Clear-Host; python run_all.py status; Start-Sleep 10 }
Get-Content "C:\Tripraft\data\catalog\tripraft_places.table_enriched.db.tables.worker.log" -Tail 40 -Wait
```

## Research stages

| Script | New verified/partial factual data | Source(s) | Limitations |
| --- | --- | --- | --- |
| `countries.py` | ISO2, ISO3, numeric ISO, calling codes, capital, currency | Wikidata | Must unambiguously match country; existing values are not overwritten |
| `states.py` | ISO3166-2 (where exact country and item match) | Wikidata | Administrative changes / missing codes remain unresolved |
| `cities.py` | Coordinates for disambiguated cities | Wikidata | No bulk Nominatim geocoding; time zones are not inferred |
| `places.py` | Wikidata ID, English name, coordinates, CC0 short description, P6375 address, P856 URL candidate | Wikidata | Website candidate is `partial`, **not live confirmed**; no invented durations/tickets/scores |
| `photos.py` | Multiple Commons URLs, thumbnails, license, author and source page | Wikidata P18 / Commons category | Category images **need visual review**; max 10 per place in this release |
| `photo_attributions.py` | Missing attribution records for existing source-and-license-backed Commons photos | Existing data | Fills only supported metadata; cannot independently verify identity |
| `tags.py` | Controlled category tags | Existing category values | Derived, not independent facts |
| `place_tags.py` | Relationships from valid place categories to available tags | Existing category values | Derived, not independent facts |
| `place_hours_intervals.py` | Simple weekly hours from **existing** OSM IDs only | OpenStreetMap API v0.6 | No bulk OSM searches, no complex schedules or holiday assumptions |
| `ticket_price_revisions.py` | Only price observations already backed by recorded verified official evidence | Stored provenance | No new live price scraping; likely low yield |
| `festivals.py` | Audit source/month problems | Existing records | Does **not** invent or create festivals |
| `opening_hour_exceptions.py` | Audit of exceptions | Existing records | No invented holiday closures |
| `place_access_events.py` | Audit of dated status changes | Existing records | No invented open/closed status |
| `airports.py` | Deliberately excluded (audit only) | — | Existing rows preserved |

Every other source/audit/application/legacy table has an individual script named after the table. These report their true role and row count; they **do not** fabricate records. `opening_hours.py` and `ticket_prices.py` are legacy read-only. `place_search_fts.py` is trigger-managed, and SQLite FTS internal shadow tables have no standalone writers.

`coverage.py` reads the 307-field policy CSV and reports *raw populated field-cells* per table, clearly separate from verification events. With the original DB, researchable/derivable field-cells in `places` are only about **42% populated**, whereas countries are about 89%, states 79%, and cities 82%. These percentages are **not verification rates**, and conditional fields do not apply universally. It is **not realistic** to promise 80–90% verified place fields just by using Wikidata/Commons.

## Safety, licensing and operational notes

- Wikimedia APIs have enforced rate limits; provide a contact email, cache results, respect 429/503 `Retry-After`, do not run parallel API workers. A network cannot be made immune to timeouts. [Wikimedia API rate limits](https://www.mediawiki.org/wiki/Wikimedia_APIs/Rate_limits).
- The free OpenStreetMap element API is used **only** for a preexisting `osm_id` in your database (7 existing IDs at the time of packaging); this does not bulk search or geocode. Cite `© OpenStreetMap contributors` and comply with [OSM copyright](https://www.openstreetmap.org/copyright) and [OSM API guidelines](https://wiki.openstreetmap.org/wiki/Api06).
- Wikimedia Commons photo licenses may require visible attribution, share-alike terms, and special handling; images in Commons categories are not necessarily of the requested attraction.
- Each script runs separately. The **controller runs sequentially**, which avoids conflicting concurrent writers. The controller's background process is not remote cloud hosting.
- No third-party dependencies. The script does **not** use paid AI or paid provider APIs. Verified decisions require real trustworthy evidence; failures are logged, not guessed.
- This environment cannot validate a full 25k-place run against live Wikimedia endpoints. Run `offline_tests.py --db "..."` for local data logic and a small online sample to assess live match quality and API reliability.

## Explicit future improvements for 80–90% target

For a high verification coverage target, add licensed structured geographic data, country tourism authority/official attraction **source-specific adapters** for live hours/prices/access, advanced multilingual alias/disambiguation matching, and review of partial records. Collecting *every* field for every venue is not meaningful (many not applicable or generated only from real app usage). Keep missing values NULL with reason and evidence instead of guessing.
