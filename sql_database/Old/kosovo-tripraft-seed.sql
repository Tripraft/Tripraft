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
-- TripRaft Kosovo country seed
-- Generated: 2026-10-02
-- ID namespace: project-local user-assigned numeric 983 (not an official ISO 3166-1 numeric code; ISO reserves 900-999 for user assignment)
-- Administrative basis: municipalities are used as the real basic administrative units; seven statistical regions are non-administrative and therefore are not used as states.
-- Place basis: municipal tourism/heritage sources (notably Visit Prizren and Peja Tourism), Kosovo municipal/government sources, Kosovo.travel as a secondary destination source, and UNESCO for the medieval monuments.
-- Unsupported provider/live metadata remains NULL; new places use partial verification.
-- ============================================================================

BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (983,'Kosovo','2026-10-02');

INSERT INTO states (id,country_id,state_name,created_at) VALUES
(983001,983,'Municipality of Prishtina','2026-10-02'),
(983002,983,'Municipality of Prizren','2026-10-02'),
(983003,983,'Municipality of Peja','2026-10-02'),
(983004,983,'Municipality of Gjakova','2026-10-02'),
(983005,983,'Municipality of Deçan','2026-10-02'),
(983006,983,'Municipality of South Mitrovica','2026-10-02'),
(983007,983,'Municipality of Ferizaj','2026-10-02'),
(983008,983,'Municipality of Shtërpcë','2026-10-02'),
(983009,983,'Municipality of Gjilan','2026-10-02'),
(983010,983,'Municipality of Gračanica','2026-10-02'),
(983011,983,'Municipality of Novo Brdo','2026-10-02');

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
(9830001,983001,'Prishtina','2026-10-02',1),
(9830002,983002,'Prizren','2026-10-02',1),
(9830003,983003,'Peja','2026-10-02',1),
(9830004,983004,'Gjakova','2026-10-02',1),
(9830005,983005,'Deçan','2026-10-02',2),
(9830006,983006,'Mitrovica','2026-10-02',1),
(9830007,983007,'Ferizaj','2026-10-02',1),
(9830008,983008,'Shtërpcë','2026-10-02',2),
(9830009,983009,'Gjilan','2026-10-02',1),
(9830010,983010,'Gračanica','2026-10-02',2),
(9830011,983011,'Novo Brdo','2026-10-02',2);

INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES
(983000001,9830001,'NEWBORN Monument','NEWBORN Monument','Municipality of Prishtina','2026-10-02','landmark','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000002,9830001,'National Library of Kosovo','National Library of Kosovo','Municipality of Prishtina','2026-10-02','landmark','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000003,9830001,'Cathedral of Saint Mother Teresa','Cathedral of Saint Mother Teresa','Municipality of Prishtina','2026-10-02','religious site','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000004,9830001,'Imperial Mosque Prishtina','Imperial Mosque Prishtina','Municipality of Prishtina','2026-10-02','religious site','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000005,9830001,'Clock Tower Prishtina','Clock Tower Prishtina','Municipality of Prishtina','2026-10-02','castle or fortress','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000006,9830001,'Ethnological Museum Emin Gjiku','Ethnological Museum Emin Gjiku','Municipality of Prishtina','2026-10-02','museum','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000007,9830001,'Kosovo Museum','Kosovo Museum','Municipality of Prishtina','2026-10-02','museum','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000008,9830001,'Skanderbeg Square Prishtina','Skanderbeg Square Prishtina','Municipality of Prishtina','2026-10-02','historic urban area','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000009,9830001,'Mother Teresa Square Prishtina','Mother Teresa Square Prishtina','Municipality of Prishtina','2026-10-02','historic urban area','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000010,9830001,'Gërmia Park','Gërmia Park','Municipality of Prishtina','2026-10-02','nature site','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000011,9830001,'National Gallery of Kosovo','National Gallery of Kosovo','Municipality of Prishtina','2026-10-02','museum','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000012,9830001,'Heroinat Memorial','Heroinat Memorial','Municipality of Prishtina','2026-10-02','landmark','Prishtina municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000013,9830002,'Prizren Fortress','Prizren Fortress','Municipality of Prizren','2026-10-02','castle or fortress','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000014,9830002,'Sinan Pasha Mosque','Sinan Pasha Mosque','Municipality of Prizren','2026-10-02','religious site','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000015,9830002,'Shadervan Square','Shadervan Square','Municipality of Prizren','2026-10-02','historic urban area','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000016,9830002,'Stone Bridge Prizren','Stone Bridge Prizren','Municipality of Prizren','2026-10-02','landmark','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000017,9830002,'Church of Our Lady of Ljeviš','Church of Our Lady of Ljeviš','Municipality of Prizren','2026-10-02','religious site','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000018,9830002,'Church of the Holy Saviour Prizren','Church of the Holy Saviour Prizren','Municipality of Prizren','2026-10-02','religious site','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000019,9830002,'Cathedral of Our Lady of Perpetual Succour Prizren','Cathedral of Our Lady of Perpetual Succour Prizren','Municipality of Prizren','2026-10-02','religious site','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000020,9830002,'League of Prizren Complex','League of Prizren Complex','Municipality of Prizren','2026-10-02','landmark','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000021,9830002,'Gazi Mehmet Pasha Hamam','Gazi Mehmet Pasha Hamam','Municipality of Prizren','2026-10-02','landmark','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000022,9830002,'Suzi Çelebi Bridge','Suzi Çelebi Bridge','Municipality of Prizren','2026-10-02','landmark','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000023,9830002,'Beledija Building','Beledija Building','Municipality of Prizren','2026-10-02','landmark','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000024,9830002,'Prizren Archaeological Museum','Prizren Archaeological Museum','Municipality of Prizren','2026-10-02','museum','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000025,9830002,'Saint George Orthodox Cathedral Prizren','Saint George Orthodox Cathedral Prizren','Municipality of Prizren','2026-10-02','religious site','Visit Prizren municipal tourism portal / Kosovo cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000026,9830003,'Rugova Gorge','Rugova Gorge','Municipality of Peja','2026-10-02','nature site','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000027,9830003,'Rugova Mountains','Rugova Mountains','Municipality of Peja','2026-10-02','nature site','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000028,9830003,'Rugova Lakes','Rugova Lakes','Municipality of Peja','2026-10-02','nature site','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000029,9830003,'White Drin Waterfall','White Drin Waterfall','Municipality of Peja','2026-10-02','nature site','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000030,9830003,'Karagaq Park','Karagaq Park','Municipality of Peja','2026-10-02','nature site','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000031,9830003,'Museum of Peja','Museum of Peja','Municipality of Peja','2026-10-02','museum','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000032,9830003,'Patriarchate of Peć Monastery','Patriarchate of Peć Monastery','Municipality of Peja','2026-10-02','religious site','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000033,9830003,'Peja Old Bazaar','Peja Old Bazaar','Municipality of Peja','2026-10-02','historic urban area','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000034,9830003,'Bajrakli Mosque Peja','Bajrakli Mosque Peja','Municipality of Peja','2026-10-02','religious site','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000035,9830003,'Haxhi Bey Hamam','Haxhi Bey Hamam','Municipality of Peja','2026-10-02','landmark','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000036,9830003,'Saint Catherine Church Peja','Saint Catherine Church Peja','Municipality of Peja','2026-10-02','religious site','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000037,9830003,'Austro-Hungarian Cemetery Peja','Austro-Hungarian Cemetery Peja','Municipality of Peja','2026-10-02','landmark','Peja Tourism municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000038,9830004,'Gjakova Grand Bazaar','Gjakova Grand Bazaar','Municipality of Gjakova','2026-10-02','historic urban area','Gjakova municipal cultural heritage sources / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000039,9830004,'Hadum Mosque','Hadum Mosque','Municipality of Gjakova','2026-10-02','religious site','Gjakova municipal cultural heritage sources / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000040,9830004,'Gjakova Ethnographic Museum','Gjakova Ethnographic Museum','Municipality of Gjakova','2026-10-02','museum','Gjakova municipal cultural heritage sources / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000041,9830004,'Clock Tower Gjakova','Clock Tower Gjakova','Municipality of Gjakova','2026-10-02','castle or fortress','Gjakova municipal cultural heritage sources / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000042,9830004,'Shejh Emin Tekke','Shejh Emin Tekke','Municipality of Gjakova','2026-10-02','religious site','Gjakova municipal cultural heritage sources / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000043,9830004,'Saint Peter and Paul Catholic Church Gjakova','Saint Peter and Paul Catholic Church Gjakova','Municipality of Gjakova','2026-10-02','religious site','Gjakova municipal cultural heritage sources / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000044,9830004,'Tabhane Bridge Gjakova','Tabhane Bridge Gjakova','Municipality of Gjakova','2026-10-02','landmark','Gjakova municipal cultural heritage sources / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000045,9830004,'Abdullah Pasha Dreni Kulla','Abdullah Pasha Dreni Kulla','Municipality of Gjakova','2026-10-02','landmark','Gjakova municipal cultural heritage sources / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000046,9830005,'Visoki Dečani Monastery','Visoki Dečani Monastery','Municipality of Deçan','2026-10-02','religious site','UNESCO World Heritage Centre / Deçan municipal heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000047,9830005,'Deçan Gorge','Deçan Gorge','Municipality of Deçan','2026-10-02','nature site','UNESCO World Heritage Centre / Deçan municipal heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000048,9830006,'Ibar Bridge Mitrovica','Ibar Bridge Mitrovica','Municipality of South Mitrovica','2026-10-02','landmark','Mitrovica municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000049,9830006,'Miners’ Monument Mitrovica','Miners’ Monument Mitrovica','Municipality of South Mitrovica','2026-10-02','landmark','Mitrovica municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000050,9830006,'Mitrovica City Museum','Mitrovica City Museum','Municipality of South Mitrovica','2026-10-02','museum','Mitrovica municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000051,9830006,'Isa Boletini Memorial Complex','Isa Boletini Memorial Complex','Municipality of South Mitrovica','2026-10-02','landmark','Mitrovica municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000052,9830007,'Ferizaj Mosque and Orthodox Church Ensemble','Ferizaj Mosque and Orthodox Church Ensemble','Municipality of Ferizaj','2026-10-02','religious site','Ferizaj municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000053,9830007,'Ferizaj City Museum','Ferizaj City Museum','Municipality of Ferizaj','2026-10-02','museum','Ferizaj municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000054,9830007,'Ferizaj City Square','Ferizaj City Square','Municipality of Ferizaj','2026-10-02','historic urban area','Ferizaj municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000055,9830007,'Saint Uroš Cathedral Ferizaj','Saint Uroš Cathedral Ferizaj','Municipality of Ferizaj','2026-10-02','religious site','Ferizaj municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000056,9830008,'Brezovica Ski Centre','Brezovica Ski Centre','Municipality of Shtërpcë','2026-10-02','landmark','Kosovo.travel secondary destination source / Sharri National Park sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000057,9830008,'Sharri National Park','Sharri National Park','Municipality of Shtërpcë','2026-10-02','nature site','Kosovo.travel secondary destination source / Sharri National Park sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000058,9830008,'Livadica Lake','Livadica Lake','Municipality of Shtërpcë','2026-10-02','nature site','Kosovo.travel secondary destination source / Sharri National Park sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000059,9830009,'Gjilan City Museum','Gjilan City Museum','Municipality of Gjilan','2026-10-02','museum','Gjilan municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000060,9830009,'Gjilan City Theatre','Gjilan City Theatre','Municipality of Gjilan','2026-10-02','landmark','Gjilan municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000061,9830009,'Saint Nicholas Church Gjilan','Saint Nicholas Church Gjilan','Municipality of Gjilan','2026-10-02','religious site','Gjilan municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000062,9830009,'Central Mosque Gjilan','Central Mosque Gjilan','Municipality of Gjilan','2026-10-02','religious site','Gjilan municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000063,9830009,'Gjilan City Park','Gjilan City Park','Municipality of Gjilan','2026-10-02','nature site','Gjilan municipal cultural institutions / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000064,9830010,'Gračanica Monastery','Gračanica Monastery','Municipality of Gračanica','2026-10-02','religious site','UNESCO World Heritage Centre / Gračanica municipal heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000065,9830010,'Ulpiana Archaeological Site','Ulpiana Archaeological Site','Municipality of Gračanica','2026-10-02','archaeological site','UNESCO World Heritage Centre / Gračanica municipal heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000066,9830011,'Novo Brdo Fortress','Novo Brdo Fortress','Municipality of Novo Brdo','2026-10-02','castle or fortress','Kosovo cultural heritage sources / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(983000067,9830011,'Novo Brdo Medieval Mining Town Archaeological Site','Novo Brdo Medieval Mining Town Archaeological Site','Municipality of Novo Brdo','2026-10-02','archaeological site','Kosovo cultural heritage sources / Kosovo.travel secondary destination source','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02');

INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES
(983000001,983000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000002,983000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000003,983000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000004,983000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000005,983000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000006,983000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000007,983000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000008,983000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000009,983000009,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000010,983000010,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000011,983000011,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000012,983000012,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000013,983000013,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000014,983000014,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000015,983000015,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000016,983000016,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000017,983000017,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000018,983000018,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000019,983000019,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000020,983000020,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000021,983000021,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000022,983000022,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000023,983000023,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000024,983000024,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000025,983000025,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000026,983000026,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000027,983000027,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000028,983000028,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000029,983000029,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000030,983000030,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000031,983000031,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000032,983000032,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000033,983000033,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000034,983000034,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000035,983000035,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000036,983000036,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000037,983000037,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000038,983000038,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000039,983000039,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000040,983000040,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000041,983000041,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000042,983000042,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000043,983000043,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000044,983000044,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000045,983000045,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000046,983000046,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000047,983000047,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000048,983000048,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000049,983000049,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000050,983000050,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000051,983000051,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000052,983000052,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000053,983000053,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000054,983000054,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000055,983000055,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000056,983000056,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000057,983000057,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000058,983000058,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000059,983000059,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000060,983000060,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000061,983000061,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000062,983000062,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000063,983000063,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000064,983000064,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000065,983000065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000066,983000066,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(983000067,983000067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.');

INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES
(983000001,983000001,'NEWBORN Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000002,983000002,'National Library of Kosovo','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000003,983000003,'Cathedral of Saint Mother Teresa','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000004,983000004,'Imperial Mosque Prishtina','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000005,983000005,'Clock Tower Prishtina','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000006,983000006,'Ethnological Museum Emin Gjiku','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000007,983000007,'Kosovo Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000008,983000008,'Skanderbeg Square Prishtina','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000009,983000009,'Mother Teresa Square Prishtina','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000010,983000010,'Gërmia Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000011,983000011,'National Gallery of Kosovo','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000012,983000012,'Heroinat Memorial','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000013,983000013,'Prizren Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000014,983000014,'Sinan Pasha Mosque','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000015,983000015,'Shadervan Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000016,983000016,'Stone Bridge Prizren','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000017,983000017,'Church of Our Lady of Ljeviš','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000018,983000018,'Church of the Holy Saviour Prizren','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000019,983000019,'Cathedral of Our Lady of Perpetual Succour Prizren','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000020,983000020,'League of Prizren Complex','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000021,983000021,'Gazi Mehmet Pasha Hamam','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000022,983000022,'Suzi Çelebi Bridge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000023,983000023,'Beledija Building','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000024,983000024,'Prizren Archaeological Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000025,983000025,'Saint George Orthodox Cathedral Prizren','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000026,983000026,'Rugova Gorge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000027,983000027,'Rugova Mountains','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000028,983000028,'Rugova Lakes','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000029,983000029,'White Drin Waterfall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000030,983000030,'Karagaq Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000031,983000031,'Museum of Peja','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000032,983000032,'Patriarchate of Peć Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000033,983000033,'Peja Old Bazaar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000034,983000034,'Bajrakli Mosque Peja','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000035,983000035,'Haxhi Bey Hamam','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000036,983000036,'Saint Catherine Church Peja','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000037,983000037,'Austro-Hungarian Cemetery Peja','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000038,983000038,'Gjakova Grand Bazaar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000039,983000039,'Hadum Mosque','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000040,983000040,'Gjakova Ethnographic Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000041,983000041,'Clock Tower Gjakova','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000042,983000042,'Shejh Emin Tekke','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000043,983000043,'Saint Peter and Paul Catholic Church Gjakova','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000044,983000044,'Tabhane Bridge Gjakova','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000045,983000045,'Abdullah Pasha Dreni Kulla','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000046,983000046,'Visoki Dečani Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000047,983000047,'Deçan Gorge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000048,983000048,'Ibar Bridge Mitrovica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000049,983000049,'Miners’ Monument Mitrovica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000050,983000050,'Mitrovica City Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000051,983000051,'Isa Boletini Memorial Complex','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000052,983000052,'Ferizaj Mosque and Orthodox Church Ensemble','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000053,983000053,'Ferizaj City Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000054,983000054,'Ferizaj City Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000055,983000055,'Saint Uroš Cathedral Ferizaj','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000056,983000056,'Brezovica Ski Centre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000057,983000057,'Sharri National Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000058,983000058,'Livadica Lake','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000059,983000059,'Gjilan City Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000060,983000060,'Gjilan City Theatre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000061,983000061,'Saint Nicholas Church Gjilan','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000062,983000062,'Central Mosque Gjilan','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000063,983000063,'Gjilan City Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000064,983000064,'Gračanica Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000065,983000065,'Ulpiana Archaeological Site','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000066,983000066,'Novo Brdo Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(983000067,983000067,'Novo Brdo Medieval Mining Town Archaeological Site','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

INSERT INTO place_tags (place_id,tag_id) SELECT 983000001,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000002,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000003,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000003,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000004,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000004,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000005,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000005,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000006,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000007,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000008,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000008,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000009,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000009,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000010,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000010,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000011,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000012,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000013,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000013,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000014,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000014,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000015,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000015,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000016,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000017,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000017,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000018,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000018,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000019,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000019,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000020,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000021,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000022,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000023,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000024,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000025,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000025,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000026,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000027,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000028,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000029,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000030,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000030,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000031,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000032,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000032,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000033,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000033,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000034,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000034,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000035,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000036,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000036,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000037,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000038,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000038,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000039,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000039,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000040,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000041,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000041,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000042,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000042,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000043,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000043,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000044,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000045,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000046,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000046,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000047,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000048,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000049,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000050,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000051,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000052,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000052,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000053,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000054,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000054,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000055,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000055,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000056,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000057,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000057,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000058,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000059,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000060,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000061,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000061,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000062,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000062,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000063,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000063,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000064,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000064,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000065,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000065,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000066,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000066,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000067,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 983000067,id FROM tags WHERE tag_name='Heritage';

COMMIT;
