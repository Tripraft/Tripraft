# Remaining-details import

Imported the available data from all 197 SQL files in `sql_database/Old` into
`data/catalog/tripraft-canonical.db`, retaining the supplied v2.1 schema.
Existing geography/place IDs were preserved. New IDs are random six-digit integers.

| Data | Records |
| --- | ---: |
| Countries/territories | 190 |
| States/regions | 1,739 |
| Cities/destination bases | 3,380 |
| Places, including restaurants | 22,925 |
| Legacy weekly hours snapshots | 22,880 |
| Photo records, including no-match placeholders | 21,550 |
| Photo attribution records | 1,279 |
| Tags | 1,034 |
| Place/tag relationships | 45,335 |
| Linked festival records | 673 |
| Import sources | 198 |
| SQL source batches | 197 |
| Preserved legacy evidence/metadata records | 11,906 |
| Review flags | 1,341 |

Source details include English names, summaries, tips, durations, booking guidance,
coordinates, addresses, websites, costs, ratings, categories, cuisine, price bands,
vegetarian flags, source notes, verification claims, hours, photos, tags, and festivals.
NULL/blank source values were retained as unknown. No missing facts, photos, airport
records, embeddings, operational schedules, or normalized price amounts were invented.

The 20 pending Indonesian places were assigned to two state-specific destination-base
entries named `Yogyakarta & Borobudur`, using the state labels on the source place rows.
The original combined city record and its coordinates are preserved in evidence metadata.

The schema has no separate restaurants table. The 569 legacy restaurant rows were
mapped to restaurant-category places; 45 needed new place rows and the rest matched
already-imported names. Legacy weekly hours remain in `opening_hours` without
dual-writing canonical interval schedules. Historical metadata/audit columns that
have no v2.1 column are preserved in `field_verifications` as source JSON.

295 numeric tag IDs referenced by the seeds were resolved using the preserved
`data/catalog/travel_data_complete.db` tag dictionary. Only referenced labels were
used from that database; the reference database was not modified.

## Records requiring review

- 17 festivals have no usable city/place parent and are preserved as source evidence,
  rather than inserted with an invented location.
- 23 places use unsupported legacy status labels (`renamed`/`merged`); their original
  values are retained and the canonical status is `needs_review`.
- 1,301 photo records have a legacy matched/incomplete/unverified asset state and
  remain `needs_review`. The other 20,249 records are no-match placeholders.

## Validation

The live database matches the validated preview. Schema, SQLite integrity, foreign
keys, complete FTS5 integrity, preserved IDs, six-digit ID uniqueness, and denormalized
place/state relationships passed. Seed verification claims were imported without
independent web verification. Input SQL hashes and per-file import batches are stored
in the database. A backup was taken before applying the transaction.

The [machine-readable report](report.json) lists every review flag.
