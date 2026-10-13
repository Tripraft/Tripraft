-- ============================================================================
-- TripRaft Canonical Country Seed Schema
-- Version: 1.1
-- Updated: 2026-10-02
--
-- MANDATORY AGENT CONTRACT:
--   Read /Tripraft/AGENTS.md before starting, resuming, replacing, auditing,
--   or proposing country seed work.
--
-- Purpose:
--   Country-neutral canonical seed schema for TripRaft.
--   Every new country seed should be importable against this schema.
--
-- Compatibility policy:
--   v1.1 intentionally preserves the v1.0 application table/column layout.
--   The update strengthens operating rules, ID guidance and QA rather than
--   introducing breaking application-table changes.
--
-- Seed rules:
--   1. Inspect current registry + existing /Tripraft country files first.
--   2. Country/state/city/place IDs may be provisional until production merge.
--      Prefer the deterministic ISO-numeric namespace documented in AGENTS.md.
--   3. google_place_id MUST remain NULL unless provider-backed lookup exists.
--   4. Never invent coordinates, hours, prices, ratings, URLs, addresses,
--      sunrise/sunset times, or photo metadata.
--   5. verification_status for newly generated country seeds must be
--      'verified' or 'partial'.
--   6. Every place MUST have:
--        - exactly one matching opening_hours row
--        - exactly one matching photos row
--        - at least one matching place_tags row
--   7. Photos with no verified/licensed match use photo_status='no_match'
--      and usage_terms='no-photo-available'.
--   8. Every newly generated place should have a nonblank source.
--   9. places.state_name must match the linked state's state_name.
--  10. Do not force a fixed place count. Registry count = actual QA row count.
--  11. All country files must pass clean-import, duplicate, orphan, coverage,
--      verification and foreign-key QA before completion.
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- COUNTRY / STATE PARENT TABLES
-- `states` is the canonical first-level administrative parent table even when
-- the local name is region/province/county/canton/prefecture/etc.
-- Never invent administrative divisions merely to satisfy the schema.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS countries (
  id INTEGER PRIMARY KEY,
  country_name TEXT NOT NULL,
  created_at TEXT
);

CREATE TABLE IF NOT EXISTS states (
  id INTEGER PRIMARY KEY,
  country_id INTEGER NOT NULL,
  state_name TEXT NOT NULL,
  created_at TEXT,
  FOREIGN KEY (country_id) REFERENCES countries(id)
);

-- ---------------------------------------------------------------------------
-- CITIES
-- `tier` is optional prioritization metadata. Coordinates remain NULL unless
-- directly source/provider backed.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS cities (
  id INTEGER PRIMARY KEY,
  state_id INTEGER NOT NULL,
  city_name TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  created_at TEXT,
  tier INTEGER,
  FOREIGN KEY (state_id) REFERENCES states(id)
);

-- ---------------------------------------------------------------------------
-- PLACES
-- Unsupported provider-style enrichment stays NULL.
-- Editorial fields should be conservative and source-supported or left NULL.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS places (
  id INTEGER PRIMARY KEY,
  city_id INTEGER NOT NULL,
  place_name TEXT NOT NULL,
  name_english TEXT,
  ai_summary TEXT,
  suggested_duration TEXT,
  best_time_to_visit TEXT,
  place_tip TEXT,
  advanced_booking TEXT,
  state_name TEXT,
  sunrise_view INTEGER,
  sunset_view INTEGER,
  sunrise_time TEXT,
  sunset_time TEXT,
  cost TEXT,
  rating_tourist_priority REAL,
  rating_traveler_experience REAL,
  latitude REAL,
  longitude REAL,
  address TEXT,
  official_website TEXT,
  rank_score REAL,
  created_at TEXT,
  google_place_id TEXT,
  category TEXT,
  cuisine TEXT,
  price_band TEXT,
  veg_flag TEXT,
  source TEXT,
  updated_at TEXT,
  verification_status TEXT,
  verification_notes TEXT,
  verified_at TEXT,
  FOREIGN KEY (city_id) REFERENCES cities(id),
  CHECK (
    verification_status IS NULL
    OR verification_status IN ('verified', 'partial')
  )
);

-- ---------------------------------------------------------------------------
-- OPENING HOURS
-- Exactly one row per place in canonical country seed files.
-- Unknown hours are NULL with a note; never guess a weekly schedule.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS opening_hours (
  id INTEGER PRIMARY KEY,
  place_id INTEGER NOT NULL UNIQUE,
  monday TEXT,
  tuesday TEXT,
  wednesday TEXT,
  thursday TEXT,
  friday TEXT,
  saturday TEXT,
  sunday TEXT,
  notes TEXT,
  FOREIGN KEY (place_id) REFERENCES places(id)
);

-- ---------------------------------------------------------------------------
-- PHOTOS
-- Exactly one row per place in canonical country seed files.
-- If no verified/licensed image exists:
--   usage_terms='no-photo-available'
--   URLs/author/license/source_url = NULL
--   photo_status='no_match'
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS photos (
  id INTEGER PRIMARY KEY,
  place_id INTEGER NOT NULL UNIQUE,
  photo_title TEXT,
  usage_terms TEXT,
  thumbnail_url TEXT,
  photo_url TEXT,
  photo_author TEXT,
  photo_license TEXT,
  photo_source_url TEXT,
  photo_status TEXT,
  FOREIGN KEY (place_id) REFERENCES places(id)
);

-- ---------------------------------------------------------------------------
-- TAGS / PLACE TAGS
-- Every place requires >= 1 tag.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS tags (
  id INTEGER PRIMARY KEY,
  tag_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS place_tags (
  place_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  PRIMARY KEY (place_id, tag_id),
  FOREIGN KEY (place_id) REFERENCES places(id),
  FOREIGN KEY (tag_id) REFERENCES tags(id)
);

-- Preferred tag insertion pattern:
-- INSERT OR IGNORE INTO tags (tag_name) VALUES ('Heritage');
--
-- INSERT INTO place_tags (place_id, tag_id)
-- SELECT <place_id>, id
-- FROM tags
-- WHERE tag_name IN ('Heritage', 'Museum');

-- ---------------------------------------------------------------------------
-- FESTIVALS
-- Optional enrichment, but when present must use real supported identities.
-- Do not invent exact annual dates for variable/lunar events.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS festivals (
  id INTEGER PRIMARY KEY,
  state_id INTEGER,
  city_id INTEGER,
  place_id INTEGER,
  festival_name TEXT NOT NULL,
  timing_label TEXT,
  lunar_note TEXT,
  duration_label TEXT,
  description TEXT,
  source TEXT DEFAULT 'own',
  updated_at TEXT,
  FOREIGN KEY (state_id) REFERENCES states(id),
  FOREIGN KEY (city_id) REFERENCES cities(id),
  FOREIGN KEY (place_id) REFERENCES places(id)
);

-- ---------------------------------------------------------------------------
-- RECOMMENDED NON-BREAKING INDEXES
-- ---------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_countries_country_name
  ON countries(country_name);

CREATE INDEX IF NOT EXISTS idx_states_country_id
  ON states(country_id);

CREATE INDEX IF NOT EXISTS idx_states_state_name
  ON states(state_name);

CREATE INDEX IF NOT EXISTS idx_cities_state_id
  ON cities(state_id);

CREATE INDEX IF NOT EXISTS idx_cities_city_name
  ON cities(city_name);

CREATE INDEX IF NOT EXISTS idx_places_city_id
  ON places(city_id);

CREATE INDEX IF NOT EXISTS idx_places_place_name
  ON places(place_name);

CREATE INDEX IF NOT EXISTS idx_places_category
  ON places(category);

CREATE INDEX IF NOT EXISTS idx_places_verification_status
  ON places(verification_status);

CREATE INDEX IF NOT EXISTS idx_place_tags_place_id
  ON place_tags(place_id);

CREATE INDEX IF NOT EXISTS idx_festivals_state_city
  ON festivals(state_id, city_id);

-- ============================================================================
-- REQUIRED SEED INSERT ORDER
-- ============================================================================
-- 1. countries
-- 2. states
-- 3. tags
-- 4. cities
-- 5. places
-- 6. opening_hours
-- 7. photos
-- 8. place_tags
-- 9. festivals
--
-- ============================================================================
-- REQUIRED QA BEFORE A COUNTRY IS MARKED COMPLETE
-- Run against a CLEAN temporary SQLite database containing this schema + the
-- single country seed being validated. Expected result is 0 rows/count unless
-- a check explicitly reports counts.
-- ============================================================================

-- A. No orphan cities:
-- SELECT COUNT(*) AS orphan_cities
-- FROM cities c
-- LEFT JOIN states s ON s.id = c.state_id
-- WHERE s.id IS NULL;

-- B. No orphan places:
-- SELECT COUNT(*) AS orphan_places
-- FROM places p
-- LEFT JOIN cities c ON c.id = p.city_id
-- WHERE c.id IS NULL;

-- C. Every place has opening_hours:
-- SELECT COUNT(*) AS places_missing_hours
-- FROM places p
-- LEFT JOIN opening_hours h ON h.place_id = p.id
-- WHERE h.place_id IS NULL;

-- D. Every place has photos:
-- SELECT COUNT(*) AS places_missing_photos
-- FROM places p
-- LEFT JOIN photos ph ON ph.place_id = p.id
-- WHERE ph.place_id IS NULL;

-- E. Every place has at least one tag:
-- SELECT COUNT(*) AS places_missing_tags
-- FROM places p
-- LEFT JOIN place_tags pt ON pt.place_id = p.id
-- WHERE pt.place_id IS NULL;

-- F. google_place_id stays NULL unless provider-backed lookup is documented:
-- SELECT COUNT(*) AS nonnull_google_place_id
-- FROM places
-- WHERE google_place_id IS NOT NULL;

-- G. Only allowed verification values on new seed rows:
-- SELECT COUNT(*) AS invalid_verification_status
-- FROM places
-- WHERE verification_status IS NULL
--    OR verification_status NOT IN ('verified', 'partial');

-- H. No duplicate city names inside one state:
-- SELECT state_id, city_name, COUNT(*) AS duplicate_count
-- FROM cities
-- GROUP BY state_id, city_name
-- HAVING COUNT(*) > 1;

-- I. No duplicate place names inside one city:
-- SELECT city_id, place_name, COUNT(*) AS duplicate_count
-- FROM places
-- GROUP BY city_id, place_name
-- HAVING COUNT(*) > 1;

-- J. No duplicate opening-hours rows per place:
-- SELECT place_id, COUNT(*) AS duplicate_count
-- FROM opening_hours
-- GROUP BY place_id
-- HAVING COUNT(*) > 1;

-- K. No duplicate photo rows per place:
-- SELECT place_id, COUNT(*) AS duplicate_count
-- FROM photos
-- GROUP BY place_id
-- HAVING COUNT(*) > 1;

-- L. Every new place has a nonblank source:
-- SELECT COUNT(*) AS places_missing_source
-- FROM places
-- WHERE source IS NULL OR TRIM(source) = '';

-- M. places.state_name matches linked state name:
-- SELECT COUNT(*) AS state_name_mismatches
-- FROM places p
-- JOIN cities c ON c.id = p.city_id
-- JOIN states s ON s.id = c.state_id
-- WHERE p.state_name IS NULL OR p.state_name <> s.state_name;

-- N. Every no-match photo uses the canonical empty-photo representation:
-- SELECT COUNT(*) AS invalid_no_match_photos
-- FROM photos
-- WHERE photo_status = 'no_match'
--   AND (
--        usage_terms <> 'no-photo-available'
--        OR thumbnail_url IS NOT NULL
--        OR photo_url IS NOT NULL
--        OR photo_author IS NOT NULL
--        OR photo_license IS NOT NULL
--        OR photo_source_url IS NOT NULL
--   );

-- O. Coverage row counts (record in QA report; do not guess):
-- SELECT
--   (SELECT COUNT(*) FROM countries) AS country_rows,
--   (SELECT COUNT(*) FROM states) AS state_rows,
--   (SELECT COUNT(*) FROM cities) AS city_rows,
--   (SELECT COUNT(*) FROM places) AS place_rows,
--   (SELECT COUNT(*) FROM opening_hours) AS hours_rows,
--   (SELECT COUNT(*) FROM photos) AS photo_rows,
--   (SELECT COUNT(*) FROM place_tags) AS place_tag_rows,
--   (SELECT COUNT(DISTINCT place_id) FROM place_tags) AS tagged_place_rows,
--   (SELECT COUNT(*) FROM festivals) AS festival_rows;

-- P. Foreign-key integrity:
-- PRAGMA foreign_key_check;
-- Expected: zero rows.

-- Q. Full SQLite import must complete without error.

-- R. Registry update is mandatory only AFTER all checks pass:
--    - save <country-slug>-tripraft-seed-qa.md with OVERALL: PASS
--    - use actual place_rows as registry place count
--    - update both registry Markdown and CSV
--    - persist seed + QA in /Tripraft/
-- ============================================================================

-- ============================================================================
-- TripRaft Slovenia country seed
-- Generated: 2026-10-02
-- ISO 3166-1 numeric namespace: 705
-- Administrative basis: Slovenia's municipalities, the basic units of local self-government.
-- Place basis: I feel Slovenia official tourism portal plus official destination sources for selected hubs.
-- Unsupported provider/live metadata remains NULL; new places use partial verification.
-- ============================================================================

BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (705,'Slovenia','2026-10-02');

INSERT INTO states (id,country_id,state_name,created_at) VALUES
(705001,705,'City Municipality of Ljubljana','2026-10-02'),
(705002,705,'Municipality of Bled','2026-10-02'),
(705003,705,'Municipality of Bohinj','2026-10-02'),
(705004,705,'Municipality of Piran','2026-10-02'),
(705005,705,'City Municipality of Koper','2026-10-02'),
(705006,705,'City Municipality of Maribor','2026-10-02'),
(705007,705,'City Municipality of Ptuj','2026-10-02'),
(705008,705,'City Municipality of Celje','2026-10-02'),
(705009,705,'Municipality of Kranjska Gora','2026-10-02'),
(705010,705,'Municipality of Postojna','2026-10-02'),
(705011,705,'Municipality of Divača','2026-10-02'),
(705012,705,'Municipality of Bovec','2026-10-02');

INSERT OR IGNORE INTO tags (tag_name) VALUES
('Activity'),
('Art'),
('Culture'),
('Family'),
('Fortress'),
('Heritage'),
('Landmark'),
('Lighthouse'),
('Museum'),
('Nature'),
('Park'),
('Religious'),
('Waterfront');

INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES
(7050001,705001,'Ljubljana','2026-10-02',1),
(7050002,705002,'Bled','2026-10-02',1),
(7050003,705003,'Bohinj','2026-10-02',1),
(7050004,705004,'Piran','2026-10-02',1),
(7050005,705005,'Koper','2026-10-02',1),
(7050006,705006,'Maribor','2026-10-02',1),
(7050007,705007,'Ptuj','2026-10-02',1),
(7050008,705008,'Celje','2026-10-02',1),
(7050009,705009,'Kranjska Gora','2026-10-02',1),
(7050010,705010,'Postojna','2026-10-02',1),
(7050011,705011,'Divača','2026-10-02',2),
(7050012,705012,'Bovec','2026-10-02',1);

INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES
(705000001,7050001,'Ljubljana Castle','Ljubljana Castle','City Municipality of Ljubljana','2026-10-02','castle or fortress','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000002,7050001,'Dragon Bridge','Dragon Bridge','City Municipality of Ljubljana','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000003,7050001,'Triple Bridge','Triple Bridge','City Municipality of Ljubljana','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000004,7050001,'Prešeren Square','Prešeren Square','City Municipality of Ljubljana','2026-10-02','historic urban area','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000005,7050001,'Ljubljana Central Market','Ljubljana Central Market','City Municipality of Ljubljana','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000006,7050001,'National Gallery of Slovenia','National Gallery of Slovenia','City Municipality of Ljubljana','2026-10-02','museum','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000007,7050001,'Plečnik House','Plečnik House','City Municipality of Ljubljana','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000008,7050001,'National Museum of Slovenia','National Museum of Slovenia','City Municipality of Ljubljana','2026-10-02','museum','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000009,7050001,'Museum of Modern Art Ljubljana','Museum of Modern Art Ljubljana','City Municipality of Ljubljana','2026-10-02','museum','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000010,7050001,'Tivoli Park','Tivoli Park','City Municipality of Ljubljana','2026-10-02','nature site','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000011,7050001,'Metelkova Mesto','Metelkova Mesto','City Municipality of Ljubljana','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000012,7050001,'Ljubljana Cathedral','Ljubljana Cathedral','City Municipality of Ljubljana','2026-10-02','religious site','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000013,7050001,'Franciscan Church of the Annunciation','Franciscan Church of the Annunciation','City Municipality of Ljubljana','2026-10-02','religious site','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000014,7050001,'Congress Square','Congress Square','City Municipality of Ljubljana','2026-10-02','historic urban area','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000015,7050001,'National and University Library of Slovenia','National and University Library of Slovenia','City Municipality of Ljubljana','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000016,7050001,'Cobblers’ Bridge','Cobblers’ Bridge','City Municipality of Ljubljana','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ljubljana','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000017,7050002,'Lake Bled','Lake Bled','Municipality of Bled','2026-10-02','nature site','I feel Slovenia official tourism portal / Bled official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000018,7050002,'Bled Island','Bled Island','Municipality of Bled','2026-10-02','landmark','I feel Slovenia official tourism portal / Bled official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000019,7050002,'Church of the Mother of God on the Lake','Church of the Mother of God on the Lake','Municipality of Bled','2026-10-02','religious site','I feel Slovenia official tourism portal / Bled official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000020,7050002,'Bled Castle','Bled Castle','Municipality of Bled','2026-10-02','castle or fortress','I feel Slovenia official tourism portal / Bled official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000021,7050002,'Straža Bled','Straža Bled','Municipality of Bled','2026-10-02','landmark','I feel Slovenia official tourism portal / Bled official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000022,7050002,'Ojstrica Viewpoint','Ojstrica Viewpoint','Municipality of Bled','2026-10-02','landmark','I feel Slovenia official tourism portal / Bled official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000023,7050002,'Mala Osojnica Viewpoint','Mala Osojnica Viewpoint','Municipality of Bled','2026-10-02','landmark','I feel Slovenia official tourism portal / Bled official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000024,7050002,'St Martin’s Parish Church in Bled','St Martin’s Parish Church in Bled','Municipality of Bled','2026-10-02','religious site','I feel Slovenia official tourism portal / Bled official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000025,7050002,'Bled Lake Promenade','Bled Lake Promenade','Municipality of Bled','2026-10-02','nature site','I feel Slovenia official tourism portal / Bled official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000026,7050002,'Castle Bathing Area','Castle Bathing Area','Municipality of Bled','2026-10-02','castle or fortress','I feel Slovenia official tourism portal / Bled official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000027,7050003,'Lake Bohinj','Lake Bohinj','Municipality of Bohinj','2026-10-02','nature site','I feel Slovenia official tourism portal / Bohinj official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000028,7050003,'Savica Waterfall','Savica Waterfall','Municipality of Bohinj','2026-10-02','nature site','I feel Slovenia official tourism portal / Bohinj official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000029,7050003,'Vogel','Vogel','Municipality of Bohinj','2026-10-02','landmark','I feel Slovenia official tourism portal / Bohinj official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000030,7050003,'Church of St John the Baptist at Lake Bohinj','Church of St John the Baptist at Lake Bohinj','Municipality of Bohinj','2026-10-02','religious site','I feel Slovenia official tourism portal / Bohinj official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000031,7050003,'Mostnica Gorge','Mostnica Gorge','Municipality of Bohinj','2026-10-02','nature site','I feel Slovenia official tourism portal / Bohinj official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000032,7050003,'Alpine Dairy Museum','Alpine Dairy Museum','Municipality of Bohinj','2026-10-02','museum','I feel Slovenia official tourism portal / Bohinj official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000033,7050003,'Devil’s Bridge in Stara Fužina','Devil’s Bridge in Stara Fužina','Municipality of Bohinj','2026-10-02','landmark','I feel Slovenia official tourism portal / Bohinj official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000034,7050003,'Triglav National Park in Bohinj','Triglav National Park in Bohinj','Municipality of Bohinj','2026-10-02','nature site','I feel Slovenia official tourism portal / Bohinj official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000035,7050003,'Bohinj Eco Trail','Bohinj Eco Trail','Municipality of Bohinj','2026-10-02','nature site','I feel Slovenia official tourism portal / Bohinj official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000036,7050003,'Studor Hayracks','Studor Hayracks','Municipality of Bohinj','2026-10-02','landmark','I feel Slovenia official tourism portal / Bohinj official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000037,7050004,'Tartini Square','Tartini Square','Municipality of Piran','2026-10-02','historic urban area','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000038,7050004,'St George’s Cathedral in Piran','St George’s Cathedral in Piran','Municipality of Piran','2026-10-02','religious site','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000039,7050004,'Piran Town Walls','Piran Town Walls','Municipality of Piran','2026-10-02','landmark','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000040,7050004,'Venetian House in Piran','Venetian House in Piran','Municipality of Piran','2026-10-02','landmark','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000041,7050004,'Minorite Monastery of St Francis','Minorite Monastery of St Francis','Municipality of Piran','2026-10-02','religious site','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000042,7050004,'Sergej Mašera Maritime Museum','Sergej Mašera Maritime Museum','Municipality of Piran','2026-10-02','museum','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000043,7050004,'First of May Square','First of May Square','Municipality of Piran','2026-10-02','historic urban area','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000044,7050004,'Piran Aquarium','Piran Aquarium','Municipality of Piran','2026-10-02','landmark','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000045,7050004,'Punta Lighthouse','Punta Lighthouse','Municipality of Piran','2026-10-02','landmark','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000046,7050004,'Sečovlje Salina Nature Park','Sečovlje Salina Nature Park','Municipality of Piran','2026-10-02','nature site','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000047,7050004,'Strunjan Nature Park','Strunjan Nature Park','Municipality of Piran','2026-10-02','nature site','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000048,7050004,'Moon Bay','Moon Bay','Municipality of Piran','2026-10-02','landmark','I feel Slovenia official tourism portal / Portorož and Piran Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000049,7050005,'Tito Square','Tito Square','City Municipality of Koper','2026-10-02','historic urban area','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000050,7050005,'Koper Bell Tower','Koper Bell Tower','City Municipality of Koper','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000051,7050005,'Praetorian Palace','Praetorian Palace','City Municipality of Koper','2026-10-02','castle or fortress','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000052,7050005,'Koper Cathedral of the Assumption','Koper Cathedral of the Assumption','City Municipality of Koper','2026-10-02','religious site','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000053,7050005,'Muda Gate','Muda Gate','City Municipality of Koper','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000054,7050005,'Da Ponte Fountain','Da Ponte Fountain','City Municipality of Koper','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000055,7050005,'Koper Regional Museum','Koper Regional Museum','City Municipality of Koper','2026-10-02','museum','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000056,7050005,'Carpaccio Square','Carpaccio Square','City Municipality of Koper','2026-10-02','historic urban area','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000057,7050005,'Škocjanski Zatok Nature Reserve','Škocjanski Zatok Nature Reserve','City Municipality of Koper','2026-10-02','nature site','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000058,7050005,'Socerb Castle','Socerb Castle','City Municipality of Koper','2026-10-02','castle or fortress','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000059,7050005,'Holy Trinity Church in Hrastovlje','Holy Trinity Church in Hrastovlje','City Municipality of Koper','2026-10-02','religious site','I feel Slovenia official tourism portal / Visit Koper','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000060,7050006,'World’s Oldest Grapevine','World’s Oldest Grapevine','City Municipality of Maribor','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000061,7050006,'Lent in Maribor','Lent in Maribor','City Municipality of Maribor','2026-10-02','historic urban area','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000062,7050006,'Vinag Wine Cellar','Vinag Wine Cellar','City Municipality of Maribor','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000063,7050006,'Maribor Castle','Maribor Castle','City Municipality of Maribor','2026-10-02','castle or fortress','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000064,7050006,'Regional Museum Maribor','Regional Museum Maribor','City Municipality of Maribor','2026-10-02','museum','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000065,7050006,'Maribor Art Gallery','Maribor Art Gallery','City Municipality of Maribor','2026-10-02','museum','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000066,7050006,'Main Square in Maribor','Main Square in Maribor','City Municipality of Maribor','2026-10-02','historic urban area','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000067,7050006,'Plague Column in Maribor','Plague Column in Maribor','City Municipality of Maribor','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000068,7050006,'Maribor Cathedral','Maribor Cathedral','City Municipality of Maribor','2026-10-02','religious site','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000069,7050006,'Water Tower in Maribor','Water Tower in Maribor','City Municipality of Maribor','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000070,7050006,'Judgement Tower in Maribor','Judgement Tower in Maribor','City Municipality of Maribor','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000071,7050006,'Maribor Synagogue','Maribor Synagogue','City Municipality of Maribor','2026-10-02','religious site','I feel Slovenia official tourism portal / Visit Maribor','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000072,7050007,'Ptuj Castle','Ptuj Castle','City Municipality of Ptuj','2026-10-02','castle or fortress','I feel Slovenia official tourism portal / Visit Ptuj','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000073,7050007,'Ptuj Town Tower','Ptuj Town Tower','City Municipality of Ptuj','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ptuj','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000074,7050007,'Orpheus Monument','Orpheus Monument','City Municipality of Ptuj','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ptuj','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000075,7050007,'Minorite Monastery in Ptuj','Minorite Monastery in Ptuj','City Municipality of Ptuj','2026-10-02','religious site','I feel Slovenia official tourism portal / Visit Ptuj','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000076,7050007,'Dominican Monastery in Ptuj','Dominican Monastery in Ptuj','City Municipality of Ptuj','2026-10-02','religious site','I feel Slovenia official tourism portal / Visit Ptuj','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000077,7050007,'Ptuj Regional Museum','Ptuj Regional Museum','City Municipality of Ptuj','2026-10-02','museum','I feel Slovenia official tourism portal / Visit Ptuj','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000078,7050007,'Ptuj Wine Cellar','Ptuj Wine Cellar','City Municipality of Ptuj','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ptuj','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000079,7050007,'Mithras Shrines of Ptuj','Mithras Shrines of Ptuj','City Municipality of Ptuj','2026-10-02','religious site','I feel Slovenia official tourism portal / Visit Ptuj','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000080,7050007,'Ptuj Old Town','Ptuj Old Town','City Municipality of Ptuj','2026-10-02','historic urban area','I feel Slovenia official tourism portal / Visit Ptuj','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000081,7050007,'Kurent House','Kurent House','City Municipality of Ptuj','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Ptuj','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000082,7050008,'Old Castle of Celje','Old Castle of Celje','City Municipality of Celje','2026-10-02','castle or fortress','I feel Slovenia official tourism portal / Visit Celje','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000083,7050008,'Celje Old Town Centre','Celje Old Town Centre','City Municipality of Celje','2026-10-02','historic urban area','I feel Slovenia official tourism portal / Visit Celje','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000084,7050008,'Celeia – a Town Beneath Today’s Town','Celeia – a Town Beneath Today’s Town','City Municipality of Celje','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Celje','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000085,7050008,'Celje Regional Museum','Celje Regional Museum','City Municipality of Celje','2026-10-02','museum','I feel Slovenia official tourism portal / Visit Celje','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000086,7050008,'Town Forest Tree House','Town Forest Tree House','City Municipality of Celje','2026-10-02','nature site','I feel Slovenia official tourism portal / Visit Celje','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000087,7050008,'Šmartinsko Lake','Šmartinsko Lake','City Municipality of Celje','2026-10-02','nature site','I feel Slovenia official tourism portal / Visit Celje','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000088,7050008,'Celje Cathedral','Celje Cathedral','City Municipality of Celje','2026-10-02','religious site','I feel Slovenia official tourism portal / Visit Celje','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000089,7050008,'Prince’s Mansion','Prince’s Mansion','City Municipality of Celje','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Celje','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000090,7050008,'Herman’s Den Children’s Museum','Herman’s Den Children’s Museum','City Municipality of Celje','2026-10-02','museum','I feel Slovenia official tourism portal / Visit Celje','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000091,7050008,'Celjska Koča','Celjska Koča','City Municipality of Celje','2026-10-02','landmark','I feel Slovenia official tourism portal / Visit Celje','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000092,7050009,'Zelenci Nature Reserve','Zelenci Nature Reserve','Municipality of Kranjska Gora','2026-10-02','nature site','I feel Slovenia official tourism portal / Kranjska Gora official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000093,7050009,'Lake Jasna','Lake Jasna','Municipality of Kranjska Gora','2026-10-02','nature site','I feel Slovenia official tourism portal / Kranjska Gora official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000094,7050009,'Russian Chapel on Vršič','Russian Chapel on Vršič','Municipality of Kranjska Gora','2026-10-02','religious site','I feel Slovenia official tourism portal / Kranjska Gora official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000095,7050009,'Peričnik Waterfall','Peričnik Waterfall','Municipality of Kranjska Gora','2026-10-02','nature site','I feel Slovenia official tourism portal / Kranjska Gora official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000096,7050009,'Planica Nordic Centre','Planica Nordic Centre','Municipality of Kranjska Gora','2026-10-02','visitor attraction','I feel Slovenia official tourism portal / Kranjska Gora official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000097,7050009,'Vršič Pass','Vršič Pass','Municipality of Kranjska Gora','2026-10-02','landmark','I feel Slovenia official tourism portal / Kranjska Gora official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000098,7050009,'Martuljek Waterfalls','Martuljek Waterfalls','Municipality of Kranjska Gora','2026-10-02','nature site','I feel Slovenia official tourism portal / Kranjska Gora official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000099,7050009,'Slovenian Alpine Museum','Slovenian Alpine Museum','Municipality of Kranjska Gora','2026-10-02','museum','I feel Slovenia official tourism portal / Kranjska Gora official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000100,7050009,'Tamar Valley','Tamar Valley','Municipality of Kranjska Gora','2026-10-02','nature site','I feel Slovenia official tourism portal / Kranjska Gora official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000101,7050009,'Ajdovska Deklica','Ajdovska Deklica','Municipality of Kranjska Gora','2026-10-02','landmark','I feel Slovenia official tourism portal / Kranjska Gora official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000102,7050010,'Postojna Cave','Postojna Cave','Municipality of Postojna','2026-10-02','nature site','I feel Slovenia official tourism portal / Postojna Cave official destination','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000103,7050010,'Vivarium Proteus','Vivarium Proteus','Municipality of Postojna','2026-10-02','landmark','I feel Slovenia official tourism portal / Postojna Cave official destination','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000104,7050010,'Expo Postojna Cave Karst','Expo Postojna Cave Karst','Municipality of Postojna','2026-10-02','nature site','I feel Slovenia official tourism portal / Postojna Cave official destination','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000105,7050010,'Predjama Castle','Predjama Castle','Municipality of Postojna','2026-10-02','castle or fortress','I feel Slovenia official tourism portal / Postojna Cave official destination','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000106,7050010,'Pivka Cave','Pivka Cave','Municipality of Postojna','2026-10-02','nature site','I feel Slovenia official tourism portal / Postojna Cave official destination','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000107,7050010,'Black Cave near Postojna','Black Cave near Postojna','Municipality of Postojna','2026-10-02','nature site','I feel Slovenia official tourism portal / Postojna Cave official destination','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000108,7050010,'Notranjska Museum Postojna','Notranjska Museum Postojna','Municipality of Postojna','2026-10-02','museum','I feel Slovenia official tourism portal / Postojna Cave official destination','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000109,7050010,'Planina Cave','Planina Cave','Municipality of Postojna','2026-10-02','nature site','I feel Slovenia official tourism portal / Postojna Cave official destination','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000110,7050011,'Škocjan Caves','Škocjan Caves','Municipality of Divača','2026-10-02','nature site','I feel Slovenia official tourism portal / Škocjan Caves Park','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000111,7050011,'Škocjan Caves Park','Škocjan Caves Park','Municipality of Divača','2026-10-02','nature site','I feel Slovenia official tourism portal / Škocjan Caves Park','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000112,7050011,'Škocjan Education Trail','Škocjan Education Trail','Municipality of Divača','2026-10-02','nature site','I feel Slovenia official tourism portal / Škocjan Caves Park','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000113,7050011,'Divača Cave','Divača Cave','Municipality of Divača','2026-10-02','nature site','I feel Slovenia official tourism portal / Škocjan Caves Park','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000114,7050011,'Škratelj Homestead – Museum of Slovenian Film Actors','Škratelj Homestead – Museum of Slovenian Film Actors','Municipality of Divača','2026-10-02','museum','I feel Slovenia official tourism portal / Škocjan Caves Park','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000115,7050012,'Soča River','Soča River','Municipality of Bovec','2026-10-02','nature site','I feel Slovenia official tourism portal / Soča Valley official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000116,7050012,'Great Soča Gorge','Great Soča Gorge','Municipality of Bovec','2026-10-02','nature site','I feel Slovenia official tourism portal / Soča Valley official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000117,7050012,'Boka Waterfall','Boka Waterfall','Municipality of Bovec','2026-10-02','nature site','I feel Slovenia official tourism portal / Soča Valley official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000118,7050012,'Kluže Fortress','Kluže Fortress','Municipality of Bovec','2026-10-02','castle or fortress','I feel Slovenia official tourism portal / Soča Valley official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000119,7050012,'Virje Waterfall','Virje Waterfall','Municipality of Bovec','2026-10-02','nature site','I feel Slovenia official tourism portal / Soča Valley official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000120,7050012,'Mangart Saddle','Mangart Saddle','Municipality of Bovec','2026-10-02','landmark','I feel Slovenia official tourism portal / Soča Valley official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000121,7050012,'Trenta Valley','Trenta Valley','Municipality of Bovec','2026-10-02','nature site','I feel Slovenia official tourism portal / Soča Valley official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000122,7050012,'Source of the Soča River','Source of the Soča River','Municipality of Bovec','2026-10-02','nature site','I feel Slovenia official tourism portal / Soča Valley official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000123,7050012,'Juliana Alpine Botanical Garden','Juliana Alpine Botanical Garden','Municipality of Bovec','2026-10-02','nature site','I feel Slovenia official tourism portal / Soča Valley official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(705000124,7050012,'Lepena Valley','Lepena Valley','Municipality of Bovec','2026-10-02','nature site','I feel Slovenia official tourism portal / Soča Valley official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02');

INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES
(705000001,705000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000002,705000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000003,705000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000004,705000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000005,705000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000006,705000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000007,705000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000008,705000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000009,705000009,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000010,705000010,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000011,705000011,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000012,705000012,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000013,705000013,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000014,705000014,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000015,705000015,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000016,705000016,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000017,705000017,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000018,705000018,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000019,705000019,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000020,705000020,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000021,705000021,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000022,705000022,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000023,705000023,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000024,705000024,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000025,705000025,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000026,705000026,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000027,705000027,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000028,705000028,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000029,705000029,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000030,705000030,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000031,705000031,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000032,705000032,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000033,705000033,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000034,705000034,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000035,705000035,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000036,705000036,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000037,705000037,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000038,705000038,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000039,705000039,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000040,705000040,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000041,705000041,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000042,705000042,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000043,705000043,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000044,705000044,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000045,705000045,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000046,705000046,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000047,705000047,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000048,705000048,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000049,705000049,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000050,705000050,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000051,705000051,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000052,705000052,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000053,705000053,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000054,705000054,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000055,705000055,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000056,705000056,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000057,705000057,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000058,705000058,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000059,705000059,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000060,705000060,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000061,705000061,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000062,705000062,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000063,705000063,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000064,705000064,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000065,705000065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000066,705000066,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000067,705000067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000068,705000068,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000069,705000069,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000070,705000070,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000071,705000071,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000072,705000072,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000073,705000073,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000074,705000074,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000075,705000075,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000076,705000076,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000077,705000077,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000078,705000078,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000079,705000079,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000080,705000080,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000081,705000081,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000082,705000082,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000083,705000083,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000084,705000084,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000085,705000085,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000086,705000086,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000087,705000087,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000088,705000088,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000089,705000089,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000090,705000090,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000091,705000091,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000092,705000092,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000093,705000093,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000094,705000094,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000095,705000095,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000096,705000096,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000097,705000097,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000098,705000098,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000099,705000099,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000100,705000100,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000101,705000101,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000102,705000102,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000103,705000103,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000104,705000104,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000105,705000105,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000106,705000106,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000107,705000107,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000108,705000108,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000109,705000109,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000110,705000110,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000111,705000111,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000112,705000112,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000113,705000113,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000114,705000114,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000115,705000115,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000116,705000116,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000117,705000117,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000118,705000118,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000119,705000119,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000120,705000120,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000121,705000121,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000122,705000122,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000123,705000123,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(705000124,705000124,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.');

INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES
(705000001,705000001,'Ljubljana Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000002,705000002,'Dragon Bridge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000003,705000003,'Triple Bridge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000004,705000004,'Prešeren Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000005,705000005,'Ljubljana Central Market','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000006,705000006,'National Gallery of Slovenia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000007,705000007,'Plečnik House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000008,705000008,'National Museum of Slovenia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000009,705000009,'Museum of Modern Art Ljubljana','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000010,705000010,'Tivoli Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000011,705000011,'Metelkova Mesto','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000012,705000012,'Ljubljana Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000013,705000013,'Franciscan Church of the Annunciation','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000014,705000014,'Congress Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000015,705000015,'National and University Library of Slovenia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000016,705000016,'Cobblers’ Bridge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000017,705000017,'Lake Bled','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000018,705000018,'Bled Island','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000019,705000019,'Church of the Mother of God on the Lake','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000020,705000020,'Bled Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000021,705000021,'Straža Bled','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000022,705000022,'Ojstrica Viewpoint','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000023,705000023,'Mala Osojnica Viewpoint','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000024,705000024,'St Martin’s Parish Church in Bled','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000025,705000025,'Bled Lake Promenade','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000026,705000026,'Castle Bathing Area','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000027,705000027,'Lake Bohinj','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000028,705000028,'Savica Waterfall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000029,705000029,'Vogel','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000030,705000030,'Church of St John the Baptist at Lake Bohinj','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000031,705000031,'Mostnica Gorge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000032,705000032,'Alpine Dairy Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000033,705000033,'Devil’s Bridge in Stara Fužina','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000034,705000034,'Triglav National Park in Bohinj','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000035,705000035,'Bohinj Eco Trail','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000036,705000036,'Studor Hayracks','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000037,705000037,'Tartini Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000038,705000038,'St George’s Cathedral in Piran','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000039,705000039,'Piran Town Walls','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000040,705000040,'Venetian House in Piran','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000041,705000041,'Minorite Monastery of St Francis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000042,705000042,'Sergej Mašera Maritime Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000043,705000043,'First of May Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000044,705000044,'Piran Aquarium','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000045,705000045,'Punta Lighthouse','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000046,705000046,'Sečovlje Salina Nature Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000047,705000047,'Strunjan Nature Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000048,705000048,'Moon Bay','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000049,705000049,'Tito Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000050,705000050,'Koper Bell Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000051,705000051,'Praetorian Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000052,705000052,'Koper Cathedral of the Assumption','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000053,705000053,'Muda Gate','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000054,705000054,'Da Ponte Fountain','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000055,705000055,'Koper Regional Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000056,705000056,'Carpaccio Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000057,705000057,'Škocjanski Zatok Nature Reserve','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000058,705000058,'Socerb Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000059,705000059,'Holy Trinity Church in Hrastovlje','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000060,705000060,'World’s Oldest Grapevine','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000061,705000061,'Lent in Maribor','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000062,705000062,'Vinag Wine Cellar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000063,705000063,'Maribor Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000064,705000064,'Regional Museum Maribor','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000065,705000065,'Maribor Art Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000066,705000066,'Main Square in Maribor','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000067,705000067,'Plague Column in Maribor','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000068,705000068,'Maribor Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000069,705000069,'Water Tower in Maribor','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000070,705000070,'Judgement Tower in Maribor','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000071,705000071,'Maribor Synagogue','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000072,705000072,'Ptuj Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000073,705000073,'Ptuj Town Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000074,705000074,'Orpheus Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000075,705000075,'Minorite Monastery in Ptuj','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000076,705000076,'Dominican Monastery in Ptuj','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000077,705000077,'Ptuj Regional Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000078,705000078,'Ptuj Wine Cellar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000079,705000079,'Mithras Shrines of Ptuj','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000080,705000080,'Ptuj Old Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000081,705000081,'Kurent House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000082,705000082,'Old Castle of Celje','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000083,705000083,'Celje Old Town Centre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000084,705000084,'Celeia – a Town Beneath Today’s Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000085,705000085,'Celje Regional Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000086,705000086,'Town Forest Tree House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000087,705000087,'Šmartinsko Lake','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000088,705000088,'Celje Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000089,705000089,'Prince’s Mansion','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000090,705000090,'Herman’s Den Children’s Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000091,705000091,'Celjska Koča','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000092,705000092,'Zelenci Nature Reserve','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000093,705000093,'Lake Jasna','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000094,705000094,'Russian Chapel on Vršič','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000095,705000095,'Peričnik Waterfall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000096,705000096,'Planica Nordic Centre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000097,705000097,'Vršič Pass','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000098,705000098,'Martuljek Waterfalls','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000099,705000099,'Slovenian Alpine Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000100,705000100,'Tamar Valley','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000101,705000101,'Ajdovska Deklica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000102,705000102,'Postojna Cave','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000103,705000103,'Vivarium Proteus','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000104,705000104,'Expo Postojna Cave Karst','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000105,705000105,'Predjama Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000106,705000106,'Pivka Cave','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000107,705000107,'Black Cave near Postojna','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000108,705000108,'Notranjska Museum Postojna','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000109,705000109,'Planina Cave','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000110,705000110,'Škocjan Caves','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000111,705000111,'Škocjan Caves Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000112,705000112,'Škocjan Education Trail','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000113,705000113,'Divača Cave','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000114,705000114,'Škratelj Homestead – Museum of Slovenian Film Actors','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000115,705000115,'Soča River','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000116,705000116,'Great Soča Gorge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000117,705000117,'Boka Waterfall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000118,705000118,'Kluže Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000119,705000119,'Virje Waterfall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000120,705000120,'Mangart Saddle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000121,705000121,'Trenta Valley','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000122,705000122,'Source of the Soča River','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000123,705000123,'Juliana Alpine Botanical Garden','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(705000124,705000124,'Lepena Valley','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

-- Every place gets at least one meaningful tag; mappings use tag names to avoid assuming tag IDs.

INSERT INTO place_tags (place_id,tag_id) SELECT 705000001,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000002,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000003,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000004,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000005,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000006,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000007,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000008,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000009,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000010,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000011,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000012,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000013,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000014,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000015,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000016,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000017,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000018,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000019,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000020,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000021,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000022,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000023,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000024,id FROM tags WHERE tag_name IN ('Religious','Heritage','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000025,id FROM tags WHERE tag_name IN ('Nature','Waterfront');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000026,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000027,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000028,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000029,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000030,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000031,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000032,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000033,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000034,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000035,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000036,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000037,id FROM tags WHERE tag_name IN ('Heritage','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000038,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000039,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000040,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000041,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000042,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000043,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000044,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000045,id FROM tags WHERE tag_name IN ('Landmark','Heritage','Lighthouse');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000046,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000047,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000048,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000049,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000050,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000051,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000052,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000053,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000054,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000055,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000056,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000057,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000058,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000059,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000060,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000061,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000062,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000063,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000064,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000065,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000066,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000067,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000068,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000069,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000070,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000071,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000072,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000073,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000074,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000075,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000076,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000077,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000078,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000079,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000080,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000081,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000082,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000083,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000084,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000085,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000086,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000087,id FROM tags WHERE tag_name IN ('Nature','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000088,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000089,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000090,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000091,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000092,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000093,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000094,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000095,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000096,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000097,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000098,id FROM tags WHERE tag_name IN ('Nature','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000099,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000100,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000101,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000102,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000103,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000104,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000105,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000106,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000107,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000108,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000109,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000110,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000111,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000112,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000113,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000114,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000115,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000116,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000117,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000118,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000119,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000120,id FROM tags WHERE tag_name IN ('Landmark','Heritage','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000121,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000122,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000123,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 705000124,id FROM tags WHERE tag_name IN ('Nature');

COMMIT;
