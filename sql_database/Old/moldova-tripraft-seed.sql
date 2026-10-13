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
-- TripRaft Moldova country seed
-- Generated: 2026-10-02
-- ID namespace: ISO 3166-1 numeric 498
-- Administrative basis: current first-level/second-tier territorial units used by selected hubs; the October 2026 reorganization proposal is not treated as implemented.
-- Place basis: Moldova Travel official tourism portal, Moldova official statistics/government sources, municipal/heritage institutions, and official winery/operator identities.
-- Unsupported provider/live metadata remains NULL; new places use partial verification.
-- ============================================================================

BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (498,'Moldova','2026-10-02');

INSERT INTO states (id,country_id,state_name,created_at) VALUES
(498001,498,'Chișinău Municipality','2026-10-02'),
(498002,498,'Orhei District','2026-10-02'),
(498003,498,'Ialoveni District','2026-10-02'),
(498004,498,'Soroca District','2026-10-02'),
(498005,498,'Gagauzia Autonomous Territorial Unit','2026-10-02'),
(498006,498,'Cahul District','2026-10-02'),
(498007,498,'Hîncești District','2026-10-02'),
(498008,498,'Bălți Municipality','2026-10-02'),
(498009,498,'Ștefan Vodă District','2026-10-02'),
(498010,498,'Anenii Noi District','2026-10-02'),
(498011,498,'Strășeni District','2026-10-02');

INSERT OR IGNORE INTO tags (tag_name) VALUES
('Art'),
('Culture'),
('Family'),
('Fortress'),
('Heritage'),
('Landmark'),
('Museum'),
('Nature'),
('Park'),
('Religious'),
('Waterfront');

INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES
(4980001,498001,'Chișinău','2026-10-02',1),
(4980002,498001,'Cricova','2026-10-02',2),
(4980003,498002,'Butuceni','2026-10-02',1),
(4980004,498002,'Orhei','2026-10-02',1),
(4980005,498003,'Mileștii Mici','2026-10-02',2),
(4980006,498004,'Soroca','2026-10-02',1),
(4980007,498005,'Comrat','2026-10-02',1),
(4980008,498005,'Beșalma','2026-10-02',2),
(4980009,498006,'Cahul','2026-10-02',1),
(4980010,498007,'Hîncești','2026-10-02',1),
(4980011,498008,'Bălți','2026-10-02',1),
(4980012,498009,'Purcari','2026-10-02',2),
(4980013,498010,'Bulboaca','2026-10-02',2),
(4980014,498011,'Căpriana','2026-10-02',2);

INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES
(498000001,4980001,'Nativity Cathedral Chișinău','Nativity Cathedral Chișinău','Chișinău Municipality','2026-10-02','religious site','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000002,4980001,'Triumphal Arch Chișinău','Triumphal Arch Chișinău','Chișinău Municipality','2026-10-02','landmark','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000003,4980001,'Ștefan cel Mare Central Park','Ștefan cel Mare Central Park','Chișinău Municipality','2026-10-02','nature site','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000004,4980001,'Valea Morilor Park','Valea Morilor Park','Chișinău Municipality','2026-10-02','nature site','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000005,4980001,'National Museum of History of Moldova','National Museum of History of Moldova','Chișinău Municipality','2026-10-02','museum','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000006,4980001,'National Museum of Ethnography and Natural History','National Museum of Ethnography and Natural History','Chișinău Municipality','2026-10-02','museum','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000007,4980001,'National Art Museum of Moldova','National Art Museum of Moldova','Chișinău Municipality','2026-10-02','museum','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000008,4980001,'Cathedral Park Chișinău','Cathedral Park Chișinău','Chișinău Municipality','2026-10-02','religious site','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000009,4980001,'Chișinău Central Market','Chișinău Central Market','Chișinău Municipality','2026-10-02','historic urban area','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000010,4980001,'Chișinău City Hall','Chișinău City Hall','Chișinău Municipality','2026-10-02','landmark','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000011,4980001,'Organ Hall Chișinău','Organ Hall Chișinău','Chișinău Municipality','2026-10-02','landmark','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000012,4980001,'Maria Bieșu National Opera and Ballet Theatre','Maria Bieșu National Opera and Ballet Theatre','Chișinău Municipality','2026-10-02','landmark','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000013,4980001,'Alexander Pushkin House Museum Chișinău','Alexander Pushkin House Museum Chișinău','Chișinău Municipality','2026-10-02','museum','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000014,4980001,'Dendrarium Park Chișinău','Dendrarium Park Chișinău','Chișinău Municipality','2026-10-02','nature site','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000015,4980001,'Eternity Memorial Complex','Eternity Memorial Complex','Chișinău Municipality','2026-10-02','landmark','Moldova Travel official tourism portal / Chișinău cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000016,4980002,'Cricova Winery Underground Galleries','Cricova Winery Underground Galleries','Chișinău Municipality','2026-10-02','landmark','Moldova Travel official tourism portal / Cricova official operator','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000017,4980003,'Orheiul Vechi Cultural-Natural Reserve','Orheiul Vechi Cultural-Natural Reserve','Orhei District','2026-10-02','nature site','Moldova Travel official tourism portal / Orheiul Vechi Reserve','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000018,4980003,'Assumption Cave Monastery Orheiul Vechi','Assumption Cave Monastery Orheiul Vechi','Orhei District','2026-10-02','religious site','Moldova Travel official tourism portal / Orheiul Vechi Reserve','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000019,4980003,'Nativity of the Mother of God Church Butuceni','Nativity of the Mother of God Church Butuceni','Orhei District','2026-10-02','religious site','Moldova Travel official tourism portal / Orheiul Vechi Reserve','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000020,4980003,'Butuceni Village Cultural Landscape','Butuceni Village Cultural Landscape','Orhei District','2026-10-02','landmark','Moldova Travel official tourism portal / Orheiul Vechi Reserve','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000021,4980004,'Orhei History and Ethnography Museum','Orhei History and Ethnography Museum','Orhei District','2026-10-02','museum','Moldova Travel official tourism portal / Orhei cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000022,4980004,'Saint Dumitru Church Orhei','Saint Dumitru Church Orhei','Orhei District','2026-10-02','religious site','Moldova Travel official tourism portal / Orhei cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000023,4980004,'Vasile Lupu Monument Orhei','Vasile Lupu Monument Orhei','Orhei District','2026-10-02','landmark','Moldova Travel official tourism portal / Orhei cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000024,4980004,'Orhei City Park','Orhei City Park','Orhei District','2026-10-02','nature site','Moldova Travel official tourism portal / Orhei cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000025,4980004,'Château Vartely','Château Vartely','Orhei District','2026-10-02','landmark','Moldova Travel official tourism portal / Orhei cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000026,4980005,'Mileștii Mici Winery','Mileștii Mici Winery','Ialoveni District','2026-10-02','landmark','Moldova Travel official tourism portal / Mileștii Mici official operator','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000027,4980006,'Soroca Fortress','Soroca Fortress','Soroca District','2026-10-02','castle or fortress','Moldova Travel official tourism portal / Soroca cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000028,4980006,'Candle of Gratitude Monument','Candle of Gratitude Monument','Soroca District','2026-10-02','landmark','Moldova Travel official tourism portal / Soroca cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000029,4980006,'Soroca Roma Hill','Soroca Roma Hill','Soroca District','2026-10-02','landmark','Moldova Travel official tourism portal / Soroca cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000030,4980006,'Soroca History and Ethnography Museum','Soroca History and Ethnography Museum','Soroca District','2026-10-02','museum','Moldova Travel official tourism portal / Soroca cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000031,4980006,'Assumption Cathedral Soroca','Assumption Cathedral Soroca','Soroca District','2026-10-02','religious site','Moldova Travel official tourism portal / Soroca cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000032,4980007,'Comrat Regional History Museum','Comrat Regional History Museum','Gagauzia Autonomous Territorial Unit','2026-10-02','museum','Moldova Travel official tourism portal / Gagauzia official portal','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000033,4980007,'Cathedral of Saint John the Baptist Comrat','Cathedral of Saint John the Baptist Comrat','Gagauzia Autonomous Territorial Unit','2026-10-02','religious site','Moldova Travel official tourism portal / Gagauzia official portal','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000034,4980007,'Gagauz National Theatre','Gagauz National Theatre','Gagauzia Autonomous Territorial Unit','2026-10-02','landmark','Moldova Travel official tourism portal / Gagauzia official portal','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000035,4980007,'Comrat Central Square','Comrat Central Square','Gagauzia Autonomous Territorial Unit','2026-10-02','historic urban area','Moldova Travel official tourism portal / Gagauzia official portal','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000036,4980007,'Monument to the Gagauz People','Monument to the Gagauz People','Gagauzia Autonomous Territorial Unit','2026-10-02','landmark','Moldova Travel official tourism portal / Gagauzia official portal','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000037,4980008,'National Gagauz History and Ethnographic Museum','National Gagauz History and Ethnographic Museum','Gagauzia Autonomous Territorial Unit','2026-10-02','museum','Gagauzia official portal / Moldova Travel','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000038,4980008,'Beșalma Windmill','Beșalma Windmill','Gagauzia Autonomous Territorial Unit','2026-10-02','landmark','Gagauzia official portal / Moldova Travel','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000039,4980009,'Cahul History Museum','Cahul History Museum','Cahul District','2026-10-02','museum','Moldova Travel official tourism portal / Cahul cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000040,4980009,'Cathedral of Archangel Michael Cahul','Cathedral of Archangel Michael Cahul','Cahul District','2026-10-02','religious site','Moldova Travel official tourism portal / Cahul cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000041,4980009,'Ioan Vodă cel Cumplit Park','Ioan Vodă cel Cumplit Park','Cahul District','2026-10-02','nature site','Moldova Travel official tourism portal / Cahul cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000042,4980010,'Manuc Bey Mansion','Manuc Bey Mansion','Hîncești District','2026-10-02','landmark','Moldova Travel official tourism portal / Hîncești cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000043,4980010,'Hîncești History and Ethnography Museum','Hîncești History and Ethnography Museum','Hîncești District','2026-10-02','museum','Moldova Travel official tourism portal / Hîncești cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000044,4980010,'Hîncești Municipal Park','Hîncești Municipal Park','Hîncești District','2026-10-02','nature site','Moldova Travel official tourism portal / Hîncești cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000045,4980011,'Saint Constantine and Elena Cathedral Bălți','Saint Constantine and Elena Cathedral Bălți','Bălți Municipality','2026-10-02','religious site','Moldova Travel official tourism portal / Bălți cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000046,4980011,'Vasile Alecsandri National Theatre Bălți','Vasile Alecsandri National Theatre Bălți','Bălți Municipality','2026-10-02','landmark','Moldova Travel official tourism portal / Bălți cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000047,4980011,'Bălți History and Ethnography Museum','Bălți History and Ethnography Museum','Bălți Municipality','2026-10-02','museum','Moldova Travel official tourism portal / Bălți cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000048,4980011,'Central Park Bălți','Central Park Bălți','Bălți Municipality','2026-10-02','nature site','Moldova Travel official tourism portal / Bălți cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000049,4980011,'Saint Nicholas Church Bălți','Saint Nicholas Church Bălți','Bălți Municipality','2026-10-02','religious site','Moldova Travel official tourism portal / Bălți cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000050,4980012,'Purcari Winery','Purcari Winery','Ștefan Vodă District','2026-10-02','landmark','Moldova Travel official tourism portal / Purcari official operator','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000051,4980013,'Castel Mimi','Castel Mimi','Anenii Noi District','2026-10-02','landmark','Moldova Travel official tourism portal / Castel Mimi official operator','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(498000052,4980014,'Căpriana Monastery','Căpriana Monastery','Strășeni District','2026-10-02','religious site','Moldova Travel official tourism portal / Căpriana Monastery heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02');

INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES
(498000001,498000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000002,498000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000003,498000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000004,498000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000005,498000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000006,498000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000007,498000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000008,498000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000009,498000009,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000010,498000010,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000011,498000011,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000012,498000012,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000013,498000013,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000014,498000014,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000015,498000015,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000016,498000016,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000017,498000017,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000018,498000018,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000019,498000019,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000020,498000020,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000021,498000021,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000022,498000022,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000023,498000023,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000024,498000024,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000025,498000025,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000026,498000026,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000027,498000027,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000028,498000028,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000029,498000029,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000030,498000030,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000031,498000031,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000032,498000032,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000033,498000033,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000034,498000034,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000035,498000035,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000036,498000036,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000037,498000037,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000038,498000038,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000039,498000039,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000040,498000040,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000041,498000041,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000042,498000042,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000043,498000043,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000044,498000044,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000045,498000045,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000046,498000046,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000047,498000047,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000048,498000048,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000049,498000049,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000050,498000050,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000051,498000051,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(498000052,498000052,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.');

INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES
(498000001,498000001,'Nativity Cathedral Chișinău','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000002,498000002,'Triumphal Arch Chișinău','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000003,498000003,'Ștefan cel Mare Central Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000004,498000004,'Valea Morilor Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000005,498000005,'National Museum of History of Moldova','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000006,498000006,'National Museum of Ethnography and Natural History','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000007,498000007,'National Art Museum of Moldova','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000008,498000008,'Cathedral Park Chișinău','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000009,498000009,'Chișinău Central Market','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000010,498000010,'Chișinău City Hall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000011,498000011,'Organ Hall Chișinău','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000012,498000012,'Maria Bieșu National Opera and Ballet Theatre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000013,498000013,'Alexander Pushkin House Museum Chișinău','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000014,498000014,'Dendrarium Park Chișinău','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000015,498000015,'Eternity Memorial Complex','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000016,498000016,'Cricova Winery Underground Galleries','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000017,498000017,'Orheiul Vechi Cultural-Natural Reserve','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000018,498000018,'Assumption Cave Monastery Orheiul Vechi','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000019,498000019,'Nativity of the Mother of God Church Butuceni','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000020,498000020,'Butuceni Village Cultural Landscape','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000021,498000021,'Orhei History and Ethnography Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000022,498000022,'Saint Dumitru Church Orhei','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000023,498000023,'Vasile Lupu Monument Orhei','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000024,498000024,'Orhei City Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000025,498000025,'Château Vartely','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000026,498000026,'Mileștii Mici Winery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000027,498000027,'Soroca Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000028,498000028,'Candle of Gratitude Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000029,498000029,'Soroca Roma Hill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000030,498000030,'Soroca History and Ethnography Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000031,498000031,'Assumption Cathedral Soroca','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000032,498000032,'Comrat Regional History Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000033,498000033,'Cathedral of Saint John the Baptist Comrat','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000034,498000034,'Gagauz National Theatre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000035,498000035,'Comrat Central Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000036,498000036,'Monument to the Gagauz People','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000037,498000037,'National Gagauz History and Ethnographic Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000038,498000038,'Beșalma Windmill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000039,498000039,'Cahul History Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000040,498000040,'Cathedral of Archangel Michael Cahul','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000041,498000041,'Ioan Vodă cel Cumplit Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000042,498000042,'Manuc Bey Mansion','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000043,498000043,'Hîncești History and Ethnography Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000044,498000044,'Hîncești Municipal Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000045,498000045,'Saint Constantine and Elena Cathedral Bălți','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000046,498000046,'Vasile Alecsandri National Theatre Bălți','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000047,498000047,'Bălți History and Ethnography Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000048,498000048,'Central Park Bălți','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000049,498000049,'Saint Nicholas Church Bălți','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000050,498000050,'Purcari Winery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000051,498000051,'Castel Mimi','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(498000052,498000052,'Căpriana Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

INSERT INTO place_tags (place_id,tag_id) SELECT 498000001,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000001,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000002,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000003,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000003,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000004,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000004,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000005,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000006,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000007,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000008,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000008,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000009,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000009,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000010,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000011,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000012,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000013,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000014,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000014,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000015,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000016,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000017,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000018,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000018,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000019,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000019,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000020,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000021,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000022,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000022,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000023,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000024,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000024,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000025,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000026,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000027,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000027,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000028,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000029,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000030,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000031,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000031,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000032,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000033,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000033,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000034,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000035,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000035,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000036,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000037,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000038,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000039,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000040,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000040,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000041,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000041,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000042,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000043,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000044,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000044,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000045,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000045,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000046,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000047,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000048,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000048,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000049,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000049,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000050,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000051,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000052,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 498000052,id FROM tags WHERE tag_name='Religious';

COMMIT;
