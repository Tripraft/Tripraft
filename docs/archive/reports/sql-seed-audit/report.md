# SQL seed audit — 7 October 2026

> Historical report. Results, local accounts, file counts and open findings describe the original checkpoint. For current setup and contracts, use the [documentation index](../../../README.md). Raw CSV/JSON/ZIP exports referenced here are preserved locally and in earlier Git history; they are not current repository inputs.

**Read-only analysis:** all 197 source files were read as text. No seed SQL was executed and no project database was opened by the audit. SHA-256 hashes of project database files and journals matched before and after analysis.

The files cover **190 country/territory labels** and declare **23,501 place rows**. There are **22,881 distinct (country/territory, place ID) pairs**. The remaining **620 rows** repeat IDs in Thailand's cumulative phases. These are source counts, not imported or independently verified physical-place counts.

Only **180** distinct names have a `countries` INSERT. Ten destination labels are inferred from filenames and file headers because their country rows are absent: France, Indonesia, Italy, Japan, Singapore, Spain, Switzerland, Thailand, United Arab Emirates, United Kingdom.

## Counting and NULL methodology

- Multi-row VALUES inserts count each tuple. INSERT ... SELECT and CTE-derived associations are interpreted in Python against declarations in the same file. Later source UPDATE statements are reflected in field completeness. No seed SQL is executed.
- Invalid uncommented prose is recorded as a syntax blocker. A following INSERT is recovered for counting so valid declared data is not lost from the audit.
- Counts include attempted declarations, including repeated INSERT OR IGNORE rows. They do not claim an import would succeed or that every conditional insert would run against an existing dataset.
- Explicit NULL means the INSERT literally supplies NULL (or a scalar lookup resolves to no row). Omitted means the INSERT does not list that column. Final NULL includes omitted nullable columns, unless a later UPDATE fills them. Omitted timestamp/default/autoincrement columns are counted as defaulted/generated, not NULL.
- Empty/whitespace-only strings are counted separately from SQL NULL. Zero and false are populated values. Quoted numeric IDs are compared using SQLite numeric affinity; 321001 and the text literal '321001' identify the same INTEGER key.
- Distinct IDs within a country are useful for source counting. IDs are not safe global deduplication keys: the audit finds collisions between different countries.
- Tag IDs synthesized for source SELECT lookups are analysis-only and marked `_synthetic_id`. They do not prescribe real AUTOINCREMENT IDs. Numeric references to pre-existing tags need separate reconciliation.
- Names and source claims are reported as supplied. No websites, geographic accuracy, licenses, or verification claims were independently checked.

## Records by table

| Table | Declared/derived rows | Explicit IDs: distinct within country |
|---|---:|---:|
| airports | 0 | 0 |
| cities | 3,449 | 3,379 |
| countries | 200 | 180 |
| festivals | 774 | 690 |
| ingestion_log | 2,471 | 0 |
| opening_hours | 23,501 | 22,881 |
| photos | 22,171 | 18,776 |
| place_tags | 47,258 | — |
| places | 23,501 | 22,881 |
| places_fts | 0 | 0 |
| restaurants | 569 | 569 |
| states | 1,619 | 1,609 |
| tags | 3,832 | 136 |
| tripraft_city_meta | 213 | 0 |
| tripraft_place_external_ids | 2,426 | 0 |
| tripraft_place_meta | 5,326 | 0 |
| tripraft_restaurant_external_ids | 569 | 0 |
| tripraft_restaurant_meta | 569 | 0 |
| tripraft_state_meta | 34 | 0 |

Additional `tripraft_*` rows are supplemental metadata, not additional attractions. Restaurant rows are counted separately; they should not simply be added to the place count because names may overlap with places.

## Import blockers and data quality

- **All 197 files insert `cities.tier`, which is absent from the canonical schema.** None is ready for an unchanged import.
- Festival inserts in 27 files use a different festival layout, including `state_id`, `timing_label`, `duration_label`, `lunar_note`, `description`, and `updated_at`. India also uses `approx_month`. These columns are absent from the canonical festival table.
- India includes 17 ALTER statements. Sixteen add columns already present in the canonical database, causing duplicate-column failures; the remaining one adds `cities.tier`.
- India contains 13 uncommented prose prefixes. Their exact source lines appear in `statement_issues.csv`.
- Six supplemental `tripraft_*` tables are outside the canonical schema. Their source declarations and data are preserved in the audit exports.
- Ten destinations lack country inserts. Several also omit state/province inserts, so an empty canonical database cannot satisfy those foreign keys.

| Table | IDs used by multiple countries/territories |
|---|---:|
| cities | 50 |
| countries | 1 |
| opening_hours | 994 |
| photos | 133 |
| places | 994 |
| states | 9 |

For example, country ID **31** is assigned to both **India and Azerbaijan**. There are **994 conflicting place IDs** between countries. `cross_country_id_collisions.csv` gives every affected ID, country, filename and name. These are conflicts, not duplicate physical places.

| Relationship | Source rows with parent absent in same country | Distinct missing references |
|---|---:|---:|
| cities.state_id | 333 | 156 |

The reference check uses all files for the same destination. It does not allow an ID in another country to mask an absent parent. Missing references may be intentional reliance on a legacy database, but they remain blockers for this empty database.

| Data-quality finding | Source rows/findings |
|---|---:|
| blank_name | 1 |
| festival_missing_place_and_city | 17 |
| ingestion_check_constraint | 270 |
| ingestion_errors | 2,471 |
| rating_outside_API_range | 408 |
| verification_status_outside_QA | 41 |

`data_quality_issues.csv` records each finding with source line. Zero findings are not evidence that names, coordinates or sources are factually correct.

## Place information completeness

Denominator: **23,501 declared place rows**, including cumulative Thailand repeats. Later source updates have been applied only in the Python analysis. Blank strings remain separate.

| Field | Final NULL | Blank strings | NULL % | Explicit NULL in INSERT | Omitted in INSERT |
|---|---:|---:|---:|---:|---:|
| id | 0 | 0 | 0.00% | 0 | 0 |
| city_id | 0 | 0 | 0.00% | 0 | 0 |
| place_name | 0 | 0 | 0.00% | 0 | 0 |
| name_english | 359 | 0 | 1.53% | 359 | 2,539 |
| ai_summary | 10,213 | 0 | 43.46% | 5,535 | 4,678 |
| suggested_duration | 11,476 | 0 | 48.83% | 6,798 | 4,678 |
| best_time_to_visit | 11,450 | 3,074 | 48.72% | 6,772 | 4,678 |
| place_tip | 10,398 | 2,495 | 44.24% | 5,720 | 4,678 |
| advanced_booking | 12,588 | 9,452 | 53.56% | 7,910 | 4,678 |
| state_name | 0 | 1 | 0.00% | 0 | 2,898 |
| sunrise_view | 14,367 | 0 | 61.13% | 9,689 | 4,678 |
| sunset_view | 14,367 | 0 | 61.13% | 9,689 | 4,678 |
| sunrise_time | 15,755 | 6,654 | 67.04% | 11,077 | 4,678 |
| sunset_time | 15,729 | 6,530 | 66.93% | 11,051 | 4,678 |
| cost | 15,465 | 3,074 | 65.81% | 10,787 | 4,678 |
| rating_tourist_priority | 14,779 | 0 | 62.89% | 10,101 | 4,678 |
| rating_traveler_experience | 14,778 | 0 | 62.88% | 10,100 | 4,678 |
| latitude | 19,567 | 0 | 83.26% | 14,889 | 4,678 |
| longitude | 19,567 | 0 | 83.26% | 14,889 | 4,678 |
| address | 11,364 | 0 | 48.36% | 6,686 | 4,678 |
| official_website | 16,379 | 3,292 | 69.69% | 11,701 | 4,678 |
| rank_score | 14,601 | 0 | 62.13% | 9,923 | 4,678 |
| created_at | 0 | 0 | 0.00% | 0 | 5,554 |
| google_place_id | 23,501 | 0 | 100.00% | 16,397 | 7,104 |
| category | 2,426 | 0 | 10.32% | 0 | 2,426 |
| cuisine | 22,623 | 0 | 96.26% | 15,519 | 7,104 |
| price_band | 16,793 | 0 | 71.46% | 9,689 | 7,104 |
| veg_flag | 16,793 | 0 | 71.46% | 9,689 | 7,104 |
| source | 2,426 | 0 | 10.32% | 0 | 5,324 |
| updated_at | 2,717 | 0 | 11.56% | 0 | 5,615 |
| verification_status | 2,426 | 0 | 10.32% | 0 | 5,324 |
| verification_notes | 2,426 | 0 | 10.32% | 0 | 5,324 |
| verified_at | 2,426 | 0 | 10.32% | 0 | 5,324 |

`google_place_id` is deliberately NULL under the supplied provider-data policy. Fields absent from places may also have information in supplemental metadata, particularly India; normalization would be needed to transfer it.

## Hours, photos and tags

Coverage denominator: **22,881 distinct within-country place IDs**. A related row counts as present if any source version provides it; a placeholder photo is not an image.

| Coverage | Places |
|---|---:|
| opening hours missing rows | 0 |
| photos missing rows | 1,330 |
| place tags missing rows | 183 |
| with image url | 1,272 |
| without image url | 21,609 |
| with any weekday hours | 4,160 |
| with all seven weekday hours | 4,071 |
| without any weekday hours | 18,721 |

Photo placeholder rows marked `no-photo-available`: **17,992**.

Image rows missing author or license: **0**. Image rows missing a source URL: **1**. These counts check presence only, not the license’s validity or actual permission to use an image.

There are **899 distinct supplied tag names** across all files. **6,897 hardcoded tag links lack an explicit same-file tag-ID declaration**. They may rely on generated or legacy tag IDs; this is a reconciliation requirement, not proof they would all be orphans after an import.

| Supplied place verification status | Declared rows |
|---|---:|
| partial | 16,849 |
| verified | 4,185 |
| renamed | 20 |
| unverified | 18 |
| merged | 3 |
| <NULL> | 2,426 |

Verification labels are source claims. `renamed`, `unverified`, and `merged` are outside the supplied QA query’s allowed `verified`/`partial` values.

| Supplied photo status | Rows |
|---|---:|
| no_match | 20,863 |
| matched | 183 |
| excluded_mismatch | 29 |
| <NULL> | 1,096 |

## Counts for every country or territory

| Country / territory | Files | Country row? | State IDs | City IDs | Place rows | Distinct place IDs | Places NULL coords | Photos with image URL |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| Afghanistan | 1 | Yes | 34 | 14 | 44 | 44 | 44 | 0 |
| Albania | 1 | Yes | 7 | 13 | 117 | 117 | 117 | 0 |
| Algeria | 1 | Yes | 8 | 12 | 32 | 32 | 32 | 0 |
| Andorra | 1 | Yes | 7 | 7 | 43 | 43 | 43 | 0 |
| Angola | 1 | Yes | 15 | 21 | 48 | 48 | 48 | 0 |
| Antigua and Barbuda | 1 | Yes | 5 | 5 | 8 | 8 | 8 | 0 |
| Argentina | 1 | Yes | 13 | 19 | 52 | 52 | 52 | 0 |
| Armenia | 1 | Yes | 10 | 16 | 119 | 119 | 119 | 0 |
| Australia | 1 | Yes | 8 | 27 | 151 | 151 | 151 | 0 |
| Austria | 1 | Yes | 9 | 79 | 475 | 475 | 475 | 0 |
| Azerbaijan | 1 | Yes | 15 | 17 | 135 | 135 | 135 | 0 |
| Bahamas | 1 | Yes | 3 | 3 | 12 | 12 | 12 | 0 |
| Bahrain | 1 | Yes | 4 | 11 | 41 | 41 | 41 | 0 |
| Barbados | 1 | Yes | 11 | 9 | 13 | 13 | 13 | 0 |
| Belarus | 1 | Yes | 7 | 8 | 48 | 48 | 48 | 0 |
| Belgium | 1 | Yes | 9 | 12 | 216 | 216 | 216 | 0 |
| Belize | 1 | Yes | 6 | 11 | 15 | 15 | 15 | 0 |
| Benin | 1 | Yes | 9 | 11 | 34 | 34 | 34 | 0 |
| Bhutan | 1 | Yes | 20 | 21 | 88 | 88 | 88 | 0 |
| Bolivia | 1 | Yes | 6 | 14 | 38 | 38 | 38 | 0 |
| Botswana | 1 | Yes | 14 | 14 | 25 | 25 | 25 | 0 |
| Brazil | 1 | Yes | 13 | 17 | 52 | 52 | 52 | 0 |
| Brunei | 1 | Yes | 4 | 8 | 59 | 59 | 59 | 0 |
| Bulgaria | 1 | Yes | 11 | 12 | 137 | 137 | 137 | 0 |
| Burkina Faso | 1 | Yes | 17 | 27 | 29 | 29 | 29 | 0 |
| Burundi | 1 | Yes | 5 | 8 | 10 | 10 | 10 | 0 |
| Cabo Verde | 1 | Yes | 3 | 3 | 3 | 3 | 3 | 0 |
| Cambodia | 1 | Yes | 12 | 12 | 110 | 110 | 110 | 0 |
| Cameroon | 1 | Yes | 2 | 3 | 3 | 3 | 3 | 0 |
| Canada | 1 | Yes | 13 | 22 | 39 | 39 | 39 | 0 |
| Central African Republic | 1 | Yes | 3 | 3 | 3 | 3 | 3 | 0 |
| Chad | 1 | Yes | 2 | 3 | 3 | 3 | 3 | 0 |
| Chile | 1 | Yes | 10 | 16 | 44 | 44 | 44 | 0 |
| China | 1 | Yes | 31 | 223 | 359 | 359 | 359 | 0 |
| Colombia | 1 | Yes | 14 | 16 | 48 | 48 | 48 | 0 |
| Comoros | 1 | Yes | 3 | 3 | 3 | 3 | 3 | 0 |
| Costa Rica | 1 | Yes | 7 | 16 | 19 | 19 | 19 | 0 |
| Croatia | 1 | Yes | 7 | 12 | 216 | 216 | 216 | 0 |
| Cuba | 1 | Yes | 16 | 11 | 13 | 13 | 13 | 0 |
| Cyprus | 1 | Yes | 5 | 12 | 89 | 89 | 89 | 0 |
| Czechia | 1 | Yes | 8 | 12 | 216 | 216 | 216 | 0 |
| Côte d’Ivoire | 1 | Yes | 2 | 3 | 3 | 3 | 3 | 0 |
| Democratic Republic of the Congo | 1 | Yes | 3 | 3 | 3 | 3 | 3 | 0 |
| Denmark | 1 | Yes | 5 | 12 | 216 | 216 | 216 | 0 |
| Djibouti | 1 | Yes | 3 | 3 | 3 | 3 | 3 | 0 |
| Dominica | 1 | Yes | 5 | 8 | 15 | 15 | 15 | 0 |
| Dominican Republic | 1 | Yes | 7 | 11 | 26 | 26 | 26 | 0 |
| Ecuador | 1 | Yes | 11 | 16 | 73 | 73 | 73 | 0 |
| Egypt | 1 | Yes | 3 | 3 | 3 | 3 | 3 | 0 |
| El Salvador | 1 | Yes | 9 | 15 | 23 | 23 | 23 | 0 |
| Equatorial Guinea | 1 | Yes | 2 | 3 | 3 | 3 | 3 | 0 |
| Eritrea | 1 | Yes | 2 | 2 | 2 | 2 | 2 | 0 |
| Estonia | 1 | Yes | 15 | 13 | 175 | 175 | 175 | 0 |
| Eswatini | 1 | Yes | 1 | 2 | 3 | 3 | 3 | 0 |
| Ethiopia | 1 | Yes | 3 | 3 | 3 | 3 | 3 | 0 |
| Fiji | 1 | Yes | 4 | 12 | 65 | 65 | 65 | 0 |
| Finland | 1 | Yes | 10 | 12 | 216 | 216 | 216 | 0 |
| France | 1 | No | 0 | 18 | 360 | 360 | 360 | 0 |
| Gabon | 1 | Yes | 2 | 3 | 3 | 3 | 3 | 0 |
| Gambia | 1 | Yes | 2 | 3 | 3 | 3 | 3 | 0 |
| Georgia | 1 | Yes | 10 | 25 | 145 | 145 | 145 | 0 |
| Germany | 1 | Yes | 16 | 100 | 880 | 880 | 880 | 0 |
| Ghana | 1 | Yes | 3 | 4 | 4 | 4 | 4 | 0 |
| Greece | 1 | Yes | 13 | 107 | 687 | 687 | 687 | 0 |
| Grenada | 1 | Yes | 5 | 12 | 22 | 22 | 22 | 0 |
| Guatemala | 1 | Yes | 12 | 20 | 36 | 36 | 36 | 0 |
| Guinea | 1 | Yes | 2 | 2 | 2 | 2 | 2 | 0 |
| Guinea-Bissau | 1 | Yes | 1 | 1 | 3 | 3 | 3 | 0 |
| Guyana | 1 | Yes | 9 | 13 | 33 | 33 | 33 | 0 |
| Hong Kong | 1 | Yes | 18 | 25 | 57 | 57 | 57 | 0 |
| Hungary | 1 | Yes | 10 | 12 | 216 | 216 | 216 | 0 |
| Iceland | 1 | Yes | 8 | 9 | 48 | 48 | 48 | 0 |
| India | 1 | Yes | 11 | 224 | 5,577 | 5,577 | 3,080 | 1,213 |
| Indonesia | 1 | No | 0 | 10 | 200 | 200 | 0 | 0 |
| Iran | 1 | Yes | 15 | 32 | 162 | 162 | 162 | 0 |
| Iraq | 1 | Yes | 19 | 22 | 63 | 63 | 63 | 0 |
| Ireland | 1 | Yes | 12 | 12 | 216 | 216 | 216 | 0 |
| Israel | 1 | Yes | 6 | 23 | 90 | 90 | 90 | 0 |
| Italy | 1 | No | 0 | 18 | 360 | 360 | 360 | 0 |
| Japan | 1 | No | 0 | 20 | 400 | 400 | 400 | 0 |
| Jordan | 1 | Yes | 12 | 25 | 97 | 97 | 97 | 0 |
| Kazakhstan | 1 | Yes | 20 | 42 | 174 | 174 | 174 | 0 |
| Kenya | 1 | Yes | 5 | 5 | 5 | 5 | 5 | 0 |
| Kiribati | 1 | Yes | 3 | 7 | 21 | 21 | 21 | 0 |
| Kosovo | 1 | Yes | 11 | 11 | 67 | 67 | 67 | 0 |
| Kuwait | 1 | Yes | 6 | 10 | 28 | 28 | 28 | 0 |
| Kyrgyzstan | 1 | Yes | 9 | 23 | 77 | 77 | 77 | 0 |
| Laos | 1 | Yes | 8 | 10 | 90 | 90 | 90 | 0 |
| Latvia | 1 | Yes | 12 | 12 | 137 | 137 | 137 | 0 |
| Lebanon | 1 | Yes | 8 | 21 | 74 | 74 | 74 | 0 |
| Lesotho | 1 | Yes | 2 | 3 | 3 | 3 | 3 | 0 |
| Liberia | 1 | Yes | 5 | 5 | 5 | 5 | 5 | 0 |
| Libya | 1 | Yes | 5 | 5 | 5 | 5 | 5 | 0 |
| Liechtenstein | 1 | Yes | 7 | 9 | 30 | 30 | 30 | 0 |
| Lithuania | 1 | Yes | 6 | 10 | 119 | 119 | 119 | 0 |
| Luxembourg | 1 | Yes | 8 | 9 | 44 | 44 | 44 | 0 |
| Macao | 1 | Yes | 1 | 3 | 47 | 47 | 47 | 0 |
| Madagascar | 1 | Yes | 4 | 6 | 6 | 6 | 6 | 0 |
| Malawi | 1 | Yes | 3 | 9 | 9 | 9 | 9 | 0 |
| Malaysia | 1 | Yes | 11 | 12 | 120 | 120 | 120 | 0 |
| Maldives | 1 | Yes | 21 | 24 | 52 | 52 | 52 | 0 |
| Mali | 1 | Yes | 8 | 9 | 56 | 56 | 56 | 0 |
| Malta | 1 | Yes | 6 | 20 | 56 | 56 | 56 | 0 |
| Marshall Islands | 1 | Yes | 9 | 9 | 31 | 31 | 31 | 0 |
| Mauritania | 1 | Yes | 6 | 9 | 37 | 37 | 37 | 0 |
| Mauritius | 1 | Yes | 10 | 11 | 41 | 41 | 41 | 0 |
| Micronesia | 1 | Yes | 4 | 5 | 29 | 29 | 29 | 0 |
| Moldova | 1 | Yes | 11 | 14 | 52 | 52 | 52 | 0 |
| Monaco | 1 | Yes | 6 | 6 | 33 | 33 | 33 | 0 |
| Mongolia | 1 | Yes | 22 | 40 | 118 | 118 | 118 | 0 |
| Montenegro | 1 | Yes | 11 | 12 | 108 | 108 | 108 | 0 |
| Morocco | 1 | Yes | 7 | 12 | 99 | 99 | 99 | 0 |
| Mozambique | 1 | Yes | 8 | 18 | 89 | 89 | 89 | 0 |
| Myanmar | 1 | Yes | 15 | 33 | 96 | 96 | 96 | 0 |
| Namibia | 1 | Yes | 9 | 13 | 32 | 32 | 32 | 0 |
| Nauru | 1 | Yes | 4 | 4 | 14 | 14 | 14 | 0 |
| Nepal | 1 | Yes | 7 | 26 | 131 | 131 | 131 | 0 |
| Netherlands | 1 | Yes | 12 | 79 | 387 | 387 | 387 | 0 |
| New Zealand | 1 | Yes | 15 | 34 | 116 | 116 | 116 | 0 |
| Niger | 1 | Yes | 6 | 9 | 22 | 22 | 22 | 0 |
| Nigeria | 1 | Yes | 14 | 15 | 20 | 20 | 20 | 0 |
| North Korea | 1 | Yes | 13 | 13 | 45 | 45 | 45 | 0 |
| North Macedonia | 1 | Yes | 12 | 12 | 92 | 92 | 92 | 0 |
| Norway | 1 | Yes | 12 | 12 | 216 | 216 | 216 | 0 |
| Oman | 1 | Yes | 11 | 29 | 77 | 77 | 77 | 0 |
| Palau | 1 | Yes | 9 | 9 | 36 | 36 | 36 | 0 |
| Palestine | 1 | Yes | 16 | 13 | 42 | 42 | 42 | 0 |
| Panama | 1 | Yes | 9 | 12 | 24 | 24 | 24 | 0 |
| Papua New Guinea | 1 | Yes | 12 | 15 | 25 | 25 | 25 | 0 |
| Paraguay | 1 | Yes | 9 | 13 | 55 | 55 | 55 | 0 |
| Peru | 1 | Yes | 16 | 47 | 157 | 157 | 157 | 0 |
| Philippines | 1 | Yes | 18 | 32 | 105 | 105 | 105 | 0 |
| Poland | 1 | Yes | 11 | 12 | 216 | 216 | 216 | 0 |
| Portugal | 1 | Yes | 20 | 117 | 645 | 645 | 645 | 0 |
| Qatar | 1 | Yes | 8 | 13 | 50 | 50 | 50 | 0 |
| Republic of the Congo | 1 | Yes | 3 | 3 | 3 | 3 | 3 | 0 |
| Romania | 1 | Yes | 11 | 16 | 122 | 122 | 122 | 0 |
| Russia | 1 | Yes | 14 | 19 | 77 | 77 | 77 | 0 |
| Rwanda | 1 | Yes | 5 | 11 | 13 | 13 | 13 | 0 |
| Saint Kitts and Nevis | 1 | Yes | 7 | 8 | 23 | 23 | 23 | 0 |
| Saint Lucia | 1 | Yes | 3 | 4 | 19 | 19 | 19 | 0 |
| Saint Vincent and the Grenadines | 1 | Yes | 3 | 9 | 21 | 21 | 21 | 0 |
| Samoa | 1 | Yes | 7 | 9 | 20 | 20 | 20 | 0 |
| San Marino | 1 | Yes | 7 | 8 | 23 | 23 | 23 | 0 |
| Saudi Arabia | 1 | Yes | 13 | 38 | 119 | 119 | 119 | 0 |
| Senegal | 1 | Yes | 9 | 12 | 16 | 16 | 16 | 0 |
| Serbia | 1 | Yes | 10 | 15 | 105 | 105 | 105 | 0 |
| Seychelles | 1 | Yes | 6 | 6 | 13 | 13 | 13 | 0 |
| Sierra Leone | 1 | Yes | 4 | 11 | 20 | 20 | 20 | 0 |
| Singapore | 1 | No | 0 | 1 | 200 | 200 | 0 | 0 |
| Slovakia | 1 | Yes | 8 | 12 | 117 | 117 | 117 | 0 |
| Slovenia | 1 | Yes | 12 | 12 | 124 | 124 | 124 | 0 |
| Solomon Islands | 1 | Yes | 6 | 11 | 19 | 19 | 19 | 0 |
| Somalia | 1 | Yes | 1 | 1 | 15 | 15 | 15 | 0 |
| South Africa | 1 | Yes | 9 | 26 | 36 | 36 | 36 | 0 |
| South Korea | 1 | Yes | 10 | 13 | 216 | 216 | 216 | 0 |
| South Sudan | 1 | Yes | 4 | 4 | 5 | 5 | 5 | 0 |
| Spain | 1 | No | 0 | 18 | 360 | 360 | 360 | 0 |
| Sri Lanka | 1 | Yes | 9 | 24 | 156 | 156 | 156 | 0 |
| Sudan | 1 | Yes | 4 | 15 | 15 | 15 | 15 | 0 |
| Suriname | 1 | Yes | 10 | 21 | 47 | 47 | 47 | 0 |
| Sweden | 1 | Yes | 9 | 12 | 216 | 216 | 216 | 0 |
| Switzerland | 1 | No | 0 | 14 | 280 | 280 | 280 | 0 |
| Syria | 1 | Yes | 14 | 17 | 17 | 17 | 17 | 0 |
| São Tomé and Príncipe | 1 | Yes | 7 | 8 | 28 | 28 | 28 | 0 |
| Taiwan | 1 | Yes | 12 | 12 | 120 | 120 | 120 | 0 |
| Tajikistan | 1 | Yes | 5 | 21 | 82 | 82 | 82 | 0 |
| Tanzania | 1 | Yes | 7 | 7 | 8 | 8 | 8 | 0 |
| Thailand | 8 | No | 0 | 10 | 820 | 200 | 0 | 0 |
| Timor-Leste | 1 | Yes | 14 | 31 | 71 | 71 | 71 | 0 |
| Togo | 1 | Yes | 4 | 5 | 5 | 5 | 5 | 0 |
| Tonga | 1 | Yes | 4 | 6 | 20 | 20 | 20 | 0 |
| Trinidad and Tobago | 1 | Yes | 6 | 16 | 28 | 28 | 28 | 0 |
| Tunisia | 1 | Yes | 8 | 10 | 10 | 10 | 10 | 0 |
| Turkey | 1 | Yes | 30 | 61 | 510 | 510 | 510 | 0 |
| Turkmenistan | 1 | Yes | 6 | 13 | 58 | 58 | 58 | 0 |
| Tuvalu | 1 | Yes | 8 | 11 | 20 | 20 | 20 | 0 |
| Uganda | 1 | Yes | 10 | 10 | 11 | 11 | 11 | 0 |
| Ukraine | 1 | Yes | 8 | 8 | 30 | 30 | 30 | 0 |
| United Arab Emirates | 1 | No | 0 | 15 | 217 | 217 | 0 | 59 |
| United Kingdom | 1 | No | 0 | 18 | 360 | 360 | 360 | 0 |
| Uruguay | 1 | Yes | 10 | 14 | 66 | 66 | 66 | 0 |
| Uzbekistan | 1 | Yes | 12 | 14 | 110 | 110 | 110 | 0 |
| Vanuatu | 1 | Yes | 6 | 32 | 57 | 57 | 57 | 0 |
| Vatican City | 1 | Yes | 1 | 1 | 22 | 22 | 22 | 0 |
| Venezuela | 1 | Yes | 11 | 18 | 90 | 90 | 90 | 0 |
| Vietnam | 1 | Yes | 11 | 12 | 120 | 120 | 120 | 0 |
| Yemen | 1 | Yes | 22 | 29 | 31 | 31 | 31 | 0 |
| Zambia | 1 | Yes | 5 | 10 | 10 | 10 | 10 | 0 |
| Zimbabwe | 1 | Yes | 6 | 10 | 10 | 10 | 10 | 0 |

## Field completeness for all remaining tables

These rows include both canonical and source-only columns. A `No` in the canonical column indicates information that needs schema mapping before import.

| Table | Field | Rows | Final NULL | Blank | Defaulted/generated | Canonical? |
|---|---|---:|---:|---:|---:|---|
| countries | id | 200 | 0 | 0 | 0 | Yes |
| countries | country_name | 200 | 0 | 0 | 0 | Yes |
| countries | created_at | 200 | 0 | 0 | 21 | Yes |
| states | id | 1,619 | 0 | 0 | 0 | Yes |
| states | country_id | 1,619 | 0 | 0 | 0 | Yes |
| states | state_name | 1,619 | 0 | 0 | 0 | Yes |
| states | latitude | 1,619 | 1,598 | 0 | 0 | Yes |
| states | longitude | 1,619 | 1,598 | 0 | 0 | Yes |
| states | created_at | 1,619 | 0 | 0 | 21 | Yes |
| tags | id | 3,832 | 0 | 0 | 0 | Yes |
| tags | tag_name | 3,832 | 0 | 0 | 0 | Yes |
| cities | id | 3,449 | 0 | 0 | 0 | Yes |
| cities | state_id | 3,449 | 0 | 0 | 0 | Yes |
| cities | city_name | 3,449 | 0 | 0 | 0 | Yes |
| cities | latitude | 3,449 | 3,014 | 0 | 0 | Yes |
| cities | longitude | 3,449 | 3,014 | 0 | 0 | Yes |
| cities | created_at | 3,449 | 0 | 0 | 98 | Yes |
| cities | tier | 3,449 | 460 | 0 | 0 | No |
| opening_hours | id | 23,501 | 0 | 0 | 0 | Yes |
| opening_hours | place_id | 23,501 | 0 | 0 | 0 | Yes |
| opening_hours | monday | 23,501 | 16,344 | 2,429 | 0 | Yes |
| opening_hours | tuesday | 23,501 | 16,298 | 2,429 | 0 | Yes |
| opening_hours | wednesday | 23,501 | 16,302 | 2,429 | 0 | Yes |
| opening_hours | thursday | 23,501 | 16,296 | 2,429 | 0 | Yes |
| opening_hours | friday | 23,501 | 16,297 | 2,429 | 0 | Yes |
| opening_hours | saturday | 23,501 | 16,296 | 2,429 | 0 | Yes |
| opening_hours | sunday | 23,501 | 16,307 | 2,429 | 0 | Yes |
| opening_hours | notes | 23,501 | 699 | 2,536 | 0 | Yes |
| photos | id | 22,171 | 0 | 0 | 2,775 | Yes |
| photos | place_id | 22,171 | 0 | 0 | 0 | Yes |
| photos | source_file | 22,171 | 21,084 | 0 | 0 | Yes |
| photos | thumbnail_url | 22,171 | 20,899 | 0 | 0 | Yes |
| photos | thumbnail_width | 22,171 | 21,344 | 0 | 0 | Yes |
| photos | thumbnail_height | 22,171 | 21,344 | 0 | 0 | Yes |
| photos | photo_title | 22,171 | 5,379 | 0 | 0 | Yes |
| photos | photo_author | 22,171 | 20,892 | 0 | 0 | Yes |
| photos | license | 22,171 | 21,075 | 0 | 0 | Yes |
| photos | license_url | 22,171 | 21,307 | 14 | 0 | Yes |
| photos | source_url | 22,171 | 21,079 | 0 | 0 | Yes |
| photos | credit | 22,171 | 21,075 | 19 | 0 | Yes |
| photos | usage_terms | 22,171 | 2,903 | 3 | 0 | Yes |
| photos | description | 22,171 | 21,504 | 1 | 0 | Yes |
| photos | photo_url | 22,171 | 21,988 | 0 | 0 | Yes |
| photos | photo_license | 22,171 | 21,988 | 0 | 0 | Yes |
| photos | photo_source_url | 22,171 | 21,988 | 0 | 0 | Yes |
| photos | photo_status | 22,171 | 1,096 | 0 | 0 | Yes |
| place_tags | place_id | 47,258 | 0 | 0 | 0 | Yes |
| place_tags | tag_id | 47,258 | 0 | 0 | 0 | Yes |
| festivals | id | 774 | 0 | 0 | 0 | Yes |
| festivals | place_id | 774 | 668 | 0 | 0 | Yes |
| festivals | city_id | 774 | 17 | 0 | 0 | Yes |
| festivals | festival_name | 774 | 0 | 0 | 0 | Yes |
| festivals | month_label | 774 | 774 | 0 | 0 | Yes |
| festivals | notes | 774 | 774 | 0 | 0 | Yes |
| festivals | source | 774 | 399 | 0 | 0 | Yes |
| festivals | created_at | 774 | 0 | 0 | 774 | Yes |
| festivals | state_id | 774 | 11 | 0 | 0 | No |
| festivals | timing_label | 774 | 461 | 0 | 0 | No |
| festivals | lunar_note | 774 | 461 | 0 | 0 | No |
| festivals | duration_label | 774 | 461 | 0 | 0 | No |
| festivals | description | 774 | 69 | 0 | 0 | No |
| festivals | updated_at | 774 | 399 | 0 | 0 | No |
| festivals | approx_month | 774 | 413 | 0 | 0 | No |
| tripraft_state_meta | state_id | 34 | 0 | 0 | 0 | No |
| tripraft_state_meta | country_name | 34 | 0 | 0 | 0 | No |
| tripraft_state_meta | country_code | 34 | 0 | 0 | 0 | No |
| tripraft_state_meta | state_name | 34 | 0 | 0 | 0 | No |
| tripraft_state_meta | state_code | 34 | 0 | 0 | 0 | No |
| tripraft_state_meta | state_key | 34 | 0 | 0 | 0 | No |
| tripraft_state_meta | state_hash | 34 | 0 | 0 | 0 | No |
| tripraft_city_meta | city_id | 213 | 0 | 0 | 0 | No |
| tripraft_city_meta | country_name | 213 | 0 | 0 | 0 | No |
| tripraft_city_meta | country_code | 213 | 0 | 0 | 0 | No |
| tripraft_city_meta | state_name | 213 | 0 | 0 | 0 | No |
| tripraft_city_meta | state_code | 213 | 0 | 0 | 0 | No |
| tripraft_city_meta | city_key | 213 | 0 | 0 | 0 | No |
| tripraft_city_meta | city_hash | 213 | 0 | 0 | 0 | No |
| tripraft_place_meta | place_id | 5,326 | 0 | 0 | 0 | No |
| tripraft_place_meta | country_name | 5,326 | 0 | 0 | 0 | No |
| tripraft_place_meta | country_code | 5,326 | 0 | 0 | 0 | No |
| tripraft_place_meta | state_name | 5,326 | 0 | 0 | 0 | No |
| tripraft_place_meta | state_code | 5,326 | 0 | 0 | 0 | No |
| tripraft_place_meta | city_key | 5,326 | 0 | 0 | 0 | No |
| tripraft_place_meta | search_key | 5,326 | 0 | 0 | 0 | No |
| tripraft_place_meta | stable_key | 5,326 | 0 | 0 | 0 | No |
| tripraft_place_meta | stable_hash | 5,326 | 0 | 0 | 0 | No |
| ingestion_log | id | 2,471 | 0 | 0 | 2,471 | Yes |
| ingestion_log | entity_type | 2,471 | 0 | 0 | 0 | Yes |
| ingestion_log | entity_id | 2,471 | 0 | 0 | 0 | Yes |
| ingestion_log | action | 2,471 | 0 | 0 | 0 | Yes |
| ingestion_log | source | 2,471 | 0 | 0 | 0 | Yes |
| ingestion_log | data_hash | 2,471 | 2,471 | 0 | 0 | Yes |
| ingestion_log | errors | 2,471 | 0 | 0 | 0 | Yes |
| ingestion_log | ingested_by | 2,471 | 0 | 0 | 0 | Yes |
| ingestion_log | created_at | 2,471 | 0 | 0 | 2,471 | Yes |
| restaurants | id | 569 | 0 | 0 | 0 | Yes |
| restaurants | city_id | 569 | 0 | 0 | 0 | Yes |
| restaurants | restaurant_name | 569 | 0 | 0 | 0 | Yes |
| restaurants | latitude | 569 | 45 | 0 | 0 | Yes |
| restaurants | longitude | 569 | 45 | 0 | 0 | Yes |
| restaurants | created_at | 569 | 0 | 0 | 569 | Yes |
| tripraft_place_external_ids | place_id | 2,426 | 0 | 0 | 0 | No |
| tripraft_place_external_ids | google_place_id | 2,426 | 2,426 | 0 | 0 | No |
| tripraft_restaurant_meta | restaurant_id | 569 | 0 | 0 | 0 | No |
| tripraft_restaurant_meta | country_name | 569 | 0 | 0 | 0 | No |
| tripraft_restaurant_meta | country_code | 569 | 0 | 0 | 0 | No |
| tripraft_restaurant_meta | state_name | 569 | 0 | 0 | 0 | No |
| tripraft_restaurant_meta | state_code | 569 | 0 | 0 | 0 | No |
| tripraft_restaurant_meta | city_key | 569 | 0 | 0 | 0 | No |
| tripraft_restaurant_meta | search_key | 569 | 0 | 0 | 0 | No |
| tripraft_restaurant_meta | stable_key | 569 | 0 | 0 | 0 | No |
| tripraft_restaurant_meta | stable_hash | 569 | 0 | 0 | 0 | No |
| tripraft_restaurant_external_ids | restaurant_id | 569 | 0 | 0 | 0 | No |
| tripraft_restaurant_external_ids | google_place_id | 569 | 569 | 0 | 0 | No |

## Files supplied with this report

- [country_summary.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/country_summary.csv): all 190 destinations, related-row counts and key missing-field counts.
- [file_inventory.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/file_inventory.csv): all 197 files, hashes and row counts.
- [field_completeness.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/field_completeness.csv): every field, explicit NULL, omitted values, blanks, defaults and final completeness.
- [place_missing_information.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/place_missing_information.csv): each place declaration, complete values, lists of NULL/blank/omitted fields, and related-row coverage.
- [cross_country_id_collisions.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/cross_country_id_collisions.csv) and [repeated_ids_within_country.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/repeated_ids_within_country.csv): every collision and repeated ID, including source variants.
- [duplicate_place_names.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/duplicate_place_names.csv): same city/name under different place IDs.
- [missing_parent_references.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/missing_parent_references.csv): missing countries, states, cities and places needed by foreign keys.
- [tag_ids_requiring_reconciliation.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/tag_ids_requiring_reconciliation.csv): hardcoded tag references not defined explicitly in the same file.
- [schema_mismatches.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/schema_mismatches.csv), [statement_issues.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/statement_issues.csv) and [data_quality_issues.csv](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/data_quality_issues.csv): schema, syntax and QA findings.
- One CSV for each source table preserves its declared rows and values, including supplemental metadata. CSV blank cells can mean SQL NULL or an empty string; use the completeness and place-detail exports to distinguish them.
- [summary.json](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/reports/sql-seed-audit/summary.json): structured totals and database hashes.

**Database status:** all project database/journal hashes remain unchanged. The canonical database remains empty.
