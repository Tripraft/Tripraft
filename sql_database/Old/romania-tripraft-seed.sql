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
-- TripRaft Romania country seed
-- Generated: 2026-10-02
-- ID namespace: ISO 3166-1 numeric 642
-- Administrative basis: selected real first-level counties plus Bucharest Municipality, matching each hub.
-- Place basis: official municipal/museum/heritage institutions, Romania cultural authorities, and UNESCO World Heritage Centre for listed properties.
-- Unsupported provider/live metadata remains NULL; new places use partial verification.
-- ============================================================================

BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (642,'Romania','2026-10-02');

INSERT INTO states (id,country_id,state_name,created_at) VALUES
(642001,642,'Bucharest Municipality','2026-10-02'),
(642002,642,'Brașov County','2026-10-02'),
(642003,642,'Sibiu County','2026-10-02'),
(642004,642,'Mureș County','2026-10-02'),
(642005,642,'Cluj County','2026-10-02'),
(642006,642,'Prahova County','2026-10-02'),
(642007,642,'Suceava County','2026-10-02'),
(642008,642,'Tulcea County','2026-10-02'),
(642009,642,'Gorj County','2026-10-02'),
(642010,642,'Alba County','2026-10-02'),
(642011,642,'Maramureș County','2026-10-02');

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
(6420001,642001,'Bucharest','2026-10-02',1),
(6420002,642002,'Brașov','2026-10-02',1),
(6420003,642002,'Bran','2026-10-02',2),
(6420004,642003,'Sibiu','2026-10-02',1),
(6420005,642004,'Sighișoara','2026-10-02',1),
(6420006,642005,'Cluj-Napoca','2026-10-02',1),
(6420007,642006,'Sinaia','2026-10-02',1),
(6420008,642007,'Suceava','2026-10-02',1),
(6420009,642007,'Gura Humorului','2026-10-02',2),
(6420010,642007,'Sucevița','2026-10-02',2),
(6420011,642007,'Vatra Moldoviței','2026-10-02',2),
(6420012,642008,'Tulcea','2026-10-02',1),
(6420013,642009,'Târgu Jiu','2026-10-02',1),
(6420014,642010,'Alba Iulia','2026-10-02',1),
(6420015,642011,'Sighetu Marmației','2026-10-02',1),
(6420016,642011,'Săpânța','2026-10-02',2);

INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES
(642000001,6420001,'Palace of the Parliament','Palace of the Parliament','Bucharest Municipality','2026-10-02','landmark','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000002,6420001,'Romanian Athenaeum','Romanian Athenaeum','Bucharest Municipality','2026-10-02','archaeological site','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000003,6420001,'National Museum of Art of Romania','National Museum of Art of Romania','Bucharest Municipality','2026-10-02','museum','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000004,6420001,'National Museum of Romanian History','National Museum of Romanian History','Bucharest Municipality','2026-10-02','museum','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000005,6420001,'Dimitrie Gusti National Village Museum','Dimitrie Gusti National Village Museum','Bucharest Municipality','2026-10-02','museum','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000006,6420001,'Cișmigiu Gardens','Cișmigiu Gardens','Bucharest Municipality','2026-10-02','nature site','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000007,6420001,'King Michael I Park','King Michael I Park','Bucharest Municipality','2026-10-02','nature site','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000008,6420001,'Stavropoleos Monastery','Stavropoleos Monastery','Bucharest Municipality','2026-10-02','religious site','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000009,6420001,'Lipscani Old Town','Lipscani Old Town','Bucharest Municipality','2026-10-02','historic urban area','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000010,6420001,'CEC Palace','CEC Palace','Bucharest Municipality','2026-10-02','landmark','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000011,6420001,'Revolution Square','Revolution Square','Bucharest Municipality','2026-10-02','historic urban area','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000012,6420001,'National Museum of the Romanian Peasant','National Museum of the Romanian Peasant','Bucharest Municipality','2026-10-02','museum','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000013,6420001,'Grigore Antipa National Museum of Natural History','Grigore Antipa National Museum of Natural History','Bucharest Municipality','2026-10-02','museum','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000014,6420001,'Cotroceni National Museum','Cotroceni National Museum','Bucharest Municipality','2026-10-02','museum','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000015,6420001,'Carol I Park','Carol I Park','Bucharest Municipality','2026-10-02','nature site','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000016,6420001,'Arch of Triumph Bucharest','Arch of Triumph Bucharest','Bucharest Municipality','2026-10-02','landmark','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000017,6420001,'Romanian National Opera','Romanian National Opera','Bucharest Municipality','2026-10-02','archaeological site','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000018,6420001,'Romanian Patriarchal Cathedral','Romanian Patriarchal Cathedral','Bucharest Municipality','2026-10-02','religious site','Official Bucharest cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000019,6420002,'Council Square Brașov','Council Square Brașov','Brașov County','2026-10-02','historic urban area','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000020,6420002,'Black Church','Black Church','Brașov County','2026-10-02','religious site','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000021,6420002,'Council House Brașov','Council House Brașov','Brașov County','2026-10-02','landmark','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000022,6420002,'Rope Street','Rope Street','Brașov County','2026-10-02','historic urban area','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000023,6420002,'Catherine’s Gate','Catherine’s Gate','Brașov County','2026-10-02','historic urban area','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000024,6420002,'Șchei Gate','Șchei Gate','Brașov County','2026-10-02','historic urban area','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000025,6420002,'First Romanian School Museum','First Romanian School Museum','Brașov County','2026-10-02','museum','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000026,6420002,'Saint Nicholas Church Șcheii Brașovului','Saint Nicholas Church Șcheii Brașovului','Brașov County','2026-10-02','religious site','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000027,6420002,'Tâmpa Mountain','Tâmpa Mountain','Brașov County','2026-10-02','nature site','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000028,6420002,'White Tower Brașov','White Tower Brașov','Brașov County','2026-10-02','castle or fortress','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000029,6420002,'Black Tower Brașov','Black Tower Brașov','Brașov County','2026-10-02','castle or fortress','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000030,6420002,'Weavers’ Bastion','Weavers’ Bastion','Brașov County','2026-10-02','castle or fortress','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000031,6420002,'Saint Bartholomew Church Brașov','Saint Bartholomew Church Brașov','Brașov County','2026-10-02','religious site','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000032,6420002,'Nicolae Titulescu Park','Nicolae Titulescu Park','Brașov County','2026-10-02','nature site','Brașov official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000033,6420003,'Bran Castle','Bran Castle','Brașov County','2026-10-02','castle or fortress','Bran Castle official institution / Brașov County tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000034,6420003,'Bran Village Museum','Bran Village Museum','Brașov County','2026-10-02','museum','Bran Castle official institution / Brașov County tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000035,6420004,'Grand Square Sibiu','Grand Square Sibiu','Sibiu County','2026-10-02','historic urban area','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000036,6420004,'Small Square Sibiu','Small Square Sibiu','Sibiu County','2026-10-02','historic urban area','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000037,6420004,'Bridge of Lies','Bridge of Lies','Sibiu County','2026-10-02','landmark','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000038,6420004,'Council Tower of Sibiu','Council Tower of Sibiu','Sibiu County','2026-10-02','castle or fortress','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000039,6420004,'Brukenthal National Museum','Brukenthal National Museum','Sibiu County','2026-10-02','museum','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000040,6420004,'Sibiu Lutheran Cathedral','Sibiu Lutheran Cathedral','Sibiu County','2026-10-02','religious site','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000041,6420004,'Holy Trinity Orthodox Cathedral Sibiu','Holy Trinity Orthodox Cathedral Sibiu','Sibiu County','2026-10-02','religious site','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000042,6420004,'ASTRA Museum of Traditional Folk Civilization','ASTRA Museum of Traditional Folk Civilization','Sibiu County','2026-10-02','museum','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000043,6420004,'Passage of the Stairs','Passage of the Stairs','Sibiu County','2026-10-02','landmark','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000044,6420004,'Altemberger House History Museum','Altemberger House History Museum','Sibiu County','2026-10-02','museum','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000045,6420004,'Potters’ Tower Sibiu','Potters’ Tower Sibiu','Sibiu County','2026-10-02','castle or fortress','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000046,6420004,'Carpenters’ Tower Sibiu','Carpenters’ Tower Sibiu','Sibiu County','2026-10-02','castle or fortress','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000047,6420004,'Pharmacy History Museum Sibiu','Pharmacy History Museum Sibiu','Sibiu County','2026-10-02','museum','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000048,6420004,'Sibiu Lower Town','Sibiu Lower Town','Sibiu County','2026-10-02','landmark','Sibiu official tourism and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000049,6420005,'Historic Centre of Sighișoara','Historic Centre of Sighișoara','Mureș County','2026-10-02','historic urban area','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000050,6420005,'Sighișoara Clock Tower','Sighișoara Clock Tower','Mureș County','2026-10-02','castle or fortress','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000051,6420005,'Church on the Hill Sighișoara','Church on the Hill Sighișoara','Mureș County','2026-10-02','religious site','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000052,6420005,'Covered Stairway Sighișoara','Covered Stairway Sighișoara','Mureș County','2026-10-02','landmark','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000053,6420005,'Citadel Square Sighișoara','Citadel Square Sighișoara','Mureș County','2026-10-02','castle or fortress','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000054,6420005,'Church of the Dominican Monastery Sighișoara','Church of the Dominican Monastery Sighișoara','Mureș County','2026-10-02','religious site','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000055,6420005,'Tailors’ Tower Sighișoara','Tailors’ Tower Sighișoara','Mureș County','2026-10-02','castle or fortress','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000056,6420005,'Shoemakers’ Tower Sighișoara','Shoemakers’ Tower Sighișoara','Mureș County','2026-10-02','castle or fortress','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000057,6420005,'Ropemakers’ Tower Sighișoara','Ropemakers’ Tower Sighișoara','Mureș County','2026-10-02','castle or fortress','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000058,6420005,'Tinsmiths’ Tower Sighișoara','Tinsmiths’ Tower Sighișoara','Mureș County','2026-10-02','castle or fortress','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000059,6420005,'Vlad Dracul House','Vlad Dracul House','Mureș County','2026-10-02','landmark','Sighișoara municipal heritage sources / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000060,6420006,'Saint Michael’s Church Cluj-Napoca','Saint Michael’s Church Cluj-Napoca','Cluj County','2026-10-02','religious site','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000061,6420006,'Unirii Square Cluj-Napoca','Unirii Square Cluj-Napoca','Cluj County','2026-10-02','historic urban area','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000062,6420006,'Matthias Corvinus Monument','Matthias Corvinus Monument','Cluj County','2026-10-02','landmark','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000063,6420006,'National Museum of Transylvanian History','National Museum of Transylvanian History','Cluj County','2026-10-02','museum','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000064,6420006,'Cluj-Napoca Art Museum','Cluj-Napoca Art Museum','Cluj County','2026-10-02','museum','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000065,6420006,'Ethnographic Museum of Transylvania','Ethnographic Museum of Transylvania','Cluj County','2026-10-02','museum','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000066,6420006,'Alexandru Borza Botanical Garden','Alexandru Borza Botanical Garden','Cluj County','2026-10-02','nature site','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000067,6420006,'Central Park Simion Bărnuțiu','Central Park Simion Bărnuțiu','Cluj County','2026-10-02','nature site','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000068,6420006,'Cetățuia Park Cluj-Napoca','Cetățuia Park Cluj-Napoca','Cluj County','2026-10-02','nature site','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000069,6420006,'Tailors’ Bastion Cluj-Napoca','Tailors’ Bastion Cluj-Napoca','Cluj County','2026-10-02','castle or fortress','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000070,6420006,'Reformed Church on Kogălniceanu Street','Reformed Church on Kogălniceanu Street','Cluj County','2026-10-02','religious site','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000071,6420006,'Dormition of the Theotokos Cathedral Cluj-Napoca','Dormition of the Theotokos Cathedral Cluj-Napoca','Cluj County','2026-10-02','religious site','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000072,6420006,'Museum Square Cluj-Napoca','Museum Square Cluj-Napoca','Cluj County','2026-10-02','museum','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000073,6420006,'Pharmacy History Collection Cluj','Pharmacy History Collection Cluj','Cluj County','2026-10-02','landmark','Cluj-Napoca official cultural institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000074,6420007,'Peleș Castle','Peleș Castle','Prahova County','2026-10-02','castle or fortress','Peleș National Museum / Sinaia official tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000075,6420007,'Pelișor Castle','Pelișor Castle','Prahova County','2026-10-02','castle or fortress','Peleș National Museum / Sinaia official tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000076,6420007,'Sinaia Monastery','Sinaia Monastery','Prahova County','2026-10-02','religious site','Peleș National Museum / Sinaia official tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000077,6420007,'Dimitrie Ghica Park','Dimitrie Ghica Park','Prahova County','2026-10-02','nature site','Peleș National Museum / Sinaia official tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000078,6420007,'Sinaia Casino','Sinaia Casino','Prahova County','2026-10-02','landmark','Peleș National Museum / Sinaia official tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000079,6420007,'George Enescu Memorial House','George Enescu Memorial House','Prahova County','2026-10-02','museum','Peleș National Museum / Sinaia official tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000080,6420007,'Bucegi Natural Park','Bucegi Natural Park','Prahova County','2026-10-02','nature site','Peleș National Museum / Sinaia official tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000081,6420007,'Sinaia Gondola','Sinaia Gondola','Prahova County','2026-10-02','landmark','Peleș National Museum / Sinaia official tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000082,6420008,'Suceava Fortress','Suceava Fortress','Suceava County','2026-10-02','castle or fortress','Suceava official museums and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000083,6420008,'Bucovina Village Museum','Bucovina Village Museum','Suceava County','2026-10-02','museum','Suceava official museums and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000084,6420008,'Museum of History Suceava','Museum of History Suceava','Suceava County','2026-10-02','museum','Suceava official museums and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000085,6420008,'Monastery of Saint John the New of Suceava','Monastery of Saint John the New of Suceava','Suceava County','2026-10-02','religious site','Suceava official museums and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000086,6420008,'Zamca Monastery','Zamca Monastery','Suceava County','2026-10-02','religious site','Suceava official museums and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000087,6420008,'Mirăuți Church','Mirăuți Church','Suceava County','2026-10-02','religious site','Suceava official museums and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000088,6420008,'Suceava Planetarium','Suceava Planetarium','Suceava County','2026-10-02','landmark','Suceava official museums and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000089,6420008,'Hanul Domnesc Ethnographic Museum','Hanul Domnesc Ethnographic Museum','Suceava County','2026-10-02','museum','Suceava official museums and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000090,6420009,'Voroneț Monastery','Voroneț Monastery','Suceava County','2026-10-02','religious site','UNESCO World Heritage Centre / official monastery and county heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000091,6420009,'Humor Monastery','Humor Monastery','Suceava County','2026-10-02','religious site','UNESCO World Heritage Centre / official monastery and county heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000092,6420010,'Sucevița Monastery','Sucevița Monastery','Suceava County','2026-10-02','religious site','UNESCO World Heritage Centre / Sucevița Monastery official heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000093,6420011,'Moldovița Monastery','Moldovița Monastery','Suceava County','2026-10-02','religious site','UNESCO World Heritage Centre / Moldovița Monastery official heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000094,6420012,'Danube Delta Eco-Tourism Museum Centre','Danube Delta Eco-Tourism Museum Centre','Tulcea County','2026-10-02','museum','Danube Delta Biosphere Reserve Authority / Tulcea official museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000095,6420012,'Danube Delta Biosphere Reserve','Danube Delta Biosphere Reserve','Tulcea County','2026-10-02','nature site','Danube Delta Biosphere Reserve Authority / Tulcea official museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000096,6420012,'Tulcea Art Museum','Tulcea Art Museum','Tulcea County','2026-10-02','museum','Danube Delta Biosphere Reserve Authority / Tulcea official museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000097,6420012,'Tulcea History and Archaeology Museum','Tulcea History and Archaeology Museum','Tulcea County','2026-10-02','museum','Danube Delta Biosphere Reserve Authority / Tulcea official museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000098,6420012,'Azzizie Mosque Tulcea','Azzizie Mosque Tulcea','Tulcea County','2026-10-02','religious site','Danube Delta Biosphere Reserve Authority / Tulcea official museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000099,6420012,'Independence Monument Tulcea','Independence Monument Tulcea','Tulcea County','2026-10-02','landmark','Danube Delta Biosphere Reserve Authority / Tulcea official museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000100,6420013,'Endless Column','Endless Column','Gorj County','2026-10-02','landmark','Brâncuși cultural institutions / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000101,6420013,'Gate of the Kiss','Gate of the Kiss','Gorj County','2026-10-02','historic urban area','Brâncuși cultural institutions / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000102,6420013,'Table of Silence','Table of Silence','Gorj County','2026-10-02','landmark','Brâncuși cultural institutions / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000103,6420013,'Constantin Brâncuși Memorial House','Constantin Brâncuși Memorial House','Gorj County','2026-10-02','museum','Brâncuși cultural institutions / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000104,6420013,'Târgu Jiu Art Museum','Târgu Jiu Art Museum','Gorj County','2026-10-02','museum','Brâncuși cultural institutions / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000105,6420013,'Central Park Târgu Jiu','Central Park Târgu Jiu','Gorj County','2026-10-02','nature site','Brâncuși cultural institutions / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000106,6420014,'Alba Carolina Citadel','Alba Carolina Citadel','Alba County','2026-10-02','castle or fortress','Alba Iulia municipal heritage institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000107,6420014,'Union Hall Alba Iulia','Union Hall Alba Iulia','Alba County','2026-10-02','landmark','Alba Iulia municipal heritage institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000108,6420014,'National Museum of the Union','National Museum of the Union','Alba County','2026-10-02','museum','Alba Iulia municipal heritage institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000109,6420014,'Saint Michael’s Cathedral Alba Iulia','Saint Michael’s Cathedral Alba Iulia','Alba County','2026-10-02','religious site','Alba Iulia municipal heritage institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000110,6420014,'Coronation Cathedral Alba Iulia','Coronation Cathedral Alba Iulia','Alba County','2026-10-02','religious site','Alba Iulia municipal heritage institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000111,6420014,'Third Gate of Alba Carolina','Third Gate of Alba Carolina','Alba County','2026-10-02','historic urban area','Alba Iulia municipal heritage institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000112,6420014,'Batthyaneum Library','Batthyaneum Library','Alba County','2026-10-02','landmark','Alba Iulia municipal heritage institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000113,6420014,'Roman Castrum Apulum','Roman Castrum Apulum','Alba County','2026-10-02','archaeological site','Alba Iulia municipal heritage institutions / Romanian Ministry of Culture','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000114,6420015,'Memorial of the Victims of Communism and of the Resistance','Memorial of the Victims of Communism and of the Resistance','Maramureș County','2026-10-02','landmark','Maramureș official museum and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000115,6420015,'Maramureș Village Museum','Maramureș Village Museum','Maramureș County','2026-10-02','museum','Maramureș official museum and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000116,6420015,'Maramureș Ethnographic Museum','Maramureș Ethnographic Museum','Maramureș County','2026-10-02','museum','Maramureș official museum and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000117,6420015,'Elie Wiesel Memorial House','Elie Wiesel Memorial House','Maramureș County','2026-10-02','museum','Maramureș official museum and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000118,6420015,'Sighetu Marmației Reformed Church','Sighetu Marmației Reformed Church','Maramureș County','2026-10-02','religious site','Maramureș official museum and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000119,6420015,'Saint Charles Borromeo Roman Catholic Church Sighet','Saint Charles Borromeo Roman Catholic Church Sighet','Maramureș County','2026-10-02','religious site','Maramureș official museum and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000120,6420015,'Central Park Sighetu Marmației','Central Park Sighetu Marmației','Maramureș County','2026-10-02','nature site','Maramureș official museum and cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000121,6420016,'Merry Cemetery','Merry Cemetery','Maramureș County','2026-10-02','landmark','Maramureș cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(642000122,6420016,'Săpânța-Peri Monastery','Săpânța-Peri Monastery','Maramureș County','2026-10-02','religious site','Maramureș cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02');

INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES
(642000001,642000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000002,642000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000003,642000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000004,642000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000005,642000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000006,642000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000007,642000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000008,642000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000009,642000009,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000010,642000010,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000011,642000011,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000012,642000012,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000013,642000013,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000014,642000014,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000015,642000015,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000016,642000016,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000017,642000017,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000018,642000018,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000019,642000019,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000020,642000020,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000021,642000021,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000022,642000022,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000023,642000023,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000024,642000024,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000025,642000025,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000026,642000026,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000027,642000027,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000028,642000028,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000029,642000029,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000030,642000030,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000031,642000031,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000032,642000032,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000033,642000033,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000034,642000034,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000035,642000035,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000036,642000036,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000037,642000037,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000038,642000038,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000039,642000039,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000040,642000040,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000041,642000041,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000042,642000042,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000043,642000043,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000044,642000044,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000045,642000045,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000046,642000046,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000047,642000047,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000048,642000048,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000049,642000049,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000050,642000050,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000051,642000051,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000052,642000052,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000053,642000053,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000054,642000054,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000055,642000055,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000056,642000056,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000057,642000057,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000058,642000058,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000059,642000059,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000060,642000060,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000061,642000061,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000062,642000062,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000063,642000063,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000064,642000064,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000065,642000065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000066,642000066,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000067,642000067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000068,642000068,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000069,642000069,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000070,642000070,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000071,642000071,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000072,642000072,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000073,642000073,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000074,642000074,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000075,642000075,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000076,642000076,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000077,642000077,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000078,642000078,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000079,642000079,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000080,642000080,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000081,642000081,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000082,642000082,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000083,642000083,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000084,642000084,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000085,642000085,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000086,642000086,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000087,642000087,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000088,642000088,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000089,642000089,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000090,642000090,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000091,642000091,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000092,642000092,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000093,642000093,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000094,642000094,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000095,642000095,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000096,642000096,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000097,642000097,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000098,642000098,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000099,642000099,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000100,642000100,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000101,642000101,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000102,642000102,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000103,642000103,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000104,642000104,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000105,642000105,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000106,642000106,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000107,642000107,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000108,642000108,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000109,642000109,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000110,642000110,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000111,642000111,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000112,642000112,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000113,642000113,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000114,642000114,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000115,642000115,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000116,642000116,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000117,642000117,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000118,642000118,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000119,642000119,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000120,642000120,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000121,642000121,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(642000122,642000122,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.');

INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES
(642000001,642000001,'Palace of the Parliament','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000002,642000002,'Romanian Athenaeum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000003,642000003,'National Museum of Art of Romania','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000004,642000004,'National Museum of Romanian History','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000005,642000005,'Dimitrie Gusti National Village Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000006,642000006,'Cișmigiu Gardens','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000007,642000007,'King Michael I Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000008,642000008,'Stavropoleos Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000009,642000009,'Lipscani Old Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000010,642000010,'CEC Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000011,642000011,'Revolution Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000012,642000012,'National Museum of the Romanian Peasant','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000013,642000013,'Grigore Antipa National Museum of Natural History','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000014,642000014,'Cotroceni National Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000015,642000015,'Carol I Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000016,642000016,'Arch of Triumph Bucharest','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000017,642000017,'Romanian National Opera','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000018,642000018,'Romanian Patriarchal Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000019,642000019,'Council Square Brașov','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000020,642000020,'Black Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000021,642000021,'Council House Brașov','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000022,642000022,'Rope Street','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000023,642000023,'Catherine’s Gate','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000024,642000024,'Șchei Gate','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000025,642000025,'First Romanian School Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000026,642000026,'Saint Nicholas Church Șcheii Brașovului','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000027,642000027,'Tâmpa Mountain','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000028,642000028,'White Tower Brașov','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000029,642000029,'Black Tower Brașov','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000030,642000030,'Weavers’ Bastion','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000031,642000031,'Saint Bartholomew Church Brașov','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000032,642000032,'Nicolae Titulescu Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000033,642000033,'Bran Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000034,642000034,'Bran Village Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000035,642000035,'Grand Square Sibiu','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000036,642000036,'Small Square Sibiu','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000037,642000037,'Bridge of Lies','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000038,642000038,'Council Tower of Sibiu','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000039,642000039,'Brukenthal National Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000040,642000040,'Sibiu Lutheran Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000041,642000041,'Holy Trinity Orthodox Cathedral Sibiu','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000042,642000042,'ASTRA Museum of Traditional Folk Civilization','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000043,642000043,'Passage of the Stairs','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000044,642000044,'Altemberger House History Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000045,642000045,'Potters’ Tower Sibiu','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000046,642000046,'Carpenters’ Tower Sibiu','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000047,642000047,'Pharmacy History Museum Sibiu','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000048,642000048,'Sibiu Lower Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000049,642000049,'Historic Centre of Sighișoara','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000050,642000050,'Sighișoara Clock Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000051,642000051,'Church on the Hill Sighișoara','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000052,642000052,'Covered Stairway Sighișoara','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000053,642000053,'Citadel Square Sighișoara','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000054,642000054,'Church of the Dominican Monastery Sighișoara','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000055,642000055,'Tailors’ Tower Sighișoara','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000056,642000056,'Shoemakers’ Tower Sighișoara','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000057,642000057,'Ropemakers’ Tower Sighișoara','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000058,642000058,'Tinsmiths’ Tower Sighișoara','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000059,642000059,'Vlad Dracul House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000060,642000060,'Saint Michael’s Church Cluj-Napoca','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000061,642000061,'Unirii Square Cluj-Napoca','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000062,642000062,'Matthias Corvinus Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000063,642000063,'National Museum of Transylvanian History','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000064,642000064,'Cluj-Napoca Art Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000065,642000065,'Ethnographic Museum of Transylvania','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000066,642000066,'Alexandru Borza Botanical Garden','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000067,642000067,'Central Park Simion Bărnuțiu','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000068,642000068,'Cetățuia Park Cluj-Napoca','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000069,642000069,'Tailors’ Bastion Cluj-Napoca','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000070,642000070,'Reformed Church on Kogălniceanu Street','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000071,642000071,'Dormition of the Theotokos Cathedral Cluj-Napoca','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000072,642000072,'Museum Square Cluj-Napoca','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000073,642000073,'Pharmacy History Collection Cluj','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000074,642000074,'Peleș Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000075,642000075,'Pelișor Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000076,642000076,'Sinaia Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000077,642000077,'Dimitrie Ghica Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000078,642000078,'Sinaia Casino','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000079,642000079,'George Enescu Memorial House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000080,642000080,'Bucegi Natural Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000081,642000081,'Sinaia Gondola','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000082,642000082,'Suceava Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000083,642000083,'Bucovina Village Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000084,642000084,'Museum of History Suceava','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000085,642000085,'Monastery of Saint John the New of Suceava','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000086,642000086,'Zamca Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000087,642000087,'Mirăuți Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000088,642000088,'Suceava Planetarium','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000089,642000089,'Hanul Domnesc Ethnographic Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000090,642000090,'Voroneț Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000091,642000091,'Humor Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000092,642000092,'Sucevița Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000093,642000093,'Moldovița Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000094,642000094,'Danube Delta Eco-Tourism Museum Centre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000095,642000095,'Danube Delta Biosphere Reserve','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000096,642000096,'Tulcea Art Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000097,642000097,'Tulcea History and Archaeology Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000098,642000098,'Azzizie Mosque Tulcea','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000099,642000099,'Independence Monument Tulcea','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000100,642000100,'Endless Column','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000101,642000101,'Gate of the Kiss','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000102,642000102,'Table of Silence','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000103,642000103,'Constantin Brâncuși Memorial House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000104,642000104,'Târgu Jiu Art Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000105,642000105,'Central Park Târgu Jiu','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000106,642000106,'Alba Carolina Citadel','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000107,642000107,'Union Hall Alba Iulia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000108,642000108,'National Museum of the Union','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000109,642000109,'Saint Michael’s Cathedral Alba Iulia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000110,642000110,'Coronation Cathedral Alba Iulia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000111,642000111,'Third Gate of Alba Carolina','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000112,642000112,'Batthyaneum Library','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000113,642000113,'Roman Castrum Apulum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000114,642000114,'Memorial of the Victims of Communism and of the Resistance','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000115,642000115,'Maramureș Village Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000116,642000116,'Maramureș Ethnographic Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000117,642000117,'Elie Wiesel Memorial House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000118,642000118,'Sighetu Marmației Reformed Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000119,642000119,'Saint Charles Borromeo Roman Catholic Church Sighet','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000120,642000120,'Central Park Sighetu Marmației','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000121,642000121,'Merry Cemetery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(642000122,642000122,'Săpânța-Peri Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

INSERT INTO place_tags (place_id,tag_id) SELECT 642000001,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000002,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000002,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000003,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000004,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000005,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000006,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000006,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000007,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000007,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000008,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000008,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000009,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000009,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000010,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000011,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000011,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000012,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000013,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000014,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000015,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000015,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000016,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000017,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000017,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000018,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000018,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000019,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000019,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000020,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000020,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000021,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000022,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000022,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000023,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000023,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000024,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000024,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000025,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000026,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000026,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000027,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000028,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000028,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000029,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000029,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000030,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000030,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000031,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000031,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000032,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000032,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000033,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000033,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000034,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000035,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000035,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000036,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000036,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000037,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000038,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000038,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000039,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000040,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000040,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000041,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000041,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000042,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000043,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000044,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000045,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000045,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000046,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000046,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000047,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000048,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000049,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000049,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000050,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000050,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000051,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000051,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000052,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000053,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000053,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000054,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000054,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000055,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000055,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000056,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000056,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000057,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000057,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000058,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000058,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000059,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000060,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000060,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000061,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000061,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000062,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000063,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000064,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000065,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000066,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000066,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000067,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000067,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000068,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000068,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000069,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000069,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000070,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000070,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000071,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000071,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000072,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000073,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000074,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000074,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000075,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000075,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000076,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000076,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000077,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000077,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000078,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000079,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000080,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000080,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000081,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000082,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000082,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000083,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000084,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000085,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000085,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000086,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000086,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000087,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000087,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000088,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000089,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000090,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000090,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000091,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000091,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000092,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000092,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000093,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000093,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000094,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000095,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000096,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000097,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000098,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000098,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000099,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000100,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000101,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000101,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000102,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000103,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000104,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000105,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000105,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000106,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000106,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000107,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000108,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000109,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000109,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000110,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000110,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000111,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000111,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000112,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000113,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000113,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000114,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000115,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000116,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000117,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000118,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000118,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000119,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000119,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000120,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000120,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000121,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000122,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 642000122,id FROM tags WHERE tag_name='Religious';

COMMIT;
