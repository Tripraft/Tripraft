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
-- TripRaft Slovakia country seed
-- Generated: 2026-10-02
-- ISO 3166-1 numeric namespace: 703
-- Administrative basis: Slovakia's eight administrative/self-governing regions.
-- Place basis: Slovakia.travel official tourism portal plus official city/destination tourism sources.
-- Unsupported provider/live metadata remains NULL; new places use partial verification.
-- ============================================================================

BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (703,'Slovakia','2026-10-02');

INSERT INTO states (id,country_id,state_name,created_at) VALUES
(703001,703,'Bratislava Region','2026-10-02'),
(703002,703,'Trnava Region','2026-10-02'),
(703003,703,'Trenčín Region','2026-10-02'),
(703004,703,'Nitra Region','2026-10-02'),
(703005,703,'Žilina Region','2026-10-02'),
(703006,703,'Banská Bystrica Region','2026-10-02'),
(703007,703,'Prešov Region','2026-10-02'),
(703008,703,'Košice Region','2026-10-02');

INSERT OR IGNORE INTO tags (tag_name) VALUES
('Activity'),
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
(7030001,703001,'Bratislava','2026-10-02',1),
(7030002,703002,'Trnava','2026-10-02',1),
(7030003,703003,'Trenčín','2026-10-02',1),
(7030004,703004,'Nitra','2026-10-02',1),
(7030005,703005,'Žilina','2026-10-02',1),
(7030006,703003,'Bojnice','2026-10-02',1),
(7030007,703006,'Banská Bystrica','2026-10-02',1),
(7030008,703006,'Banská Štiavnica','2026-10-02',1),
(7030009,703007,'Prešov','2026-10-02',1),
(7030010,703007,'Vysoké Tatry','2026-10-02',1),
(7030011,703007,'Levoča','2026-10-02',2),
(7030012,703008,'Košice','2026-10-02',1);

INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES
(703000001,7030001,'Bratislava Castle','Bratislava Castle','Bratislava Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000002,7030001,'Bratislava Old Town','Bratislava Old Town','Bratislava Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000003,7030001,'Main Square in Bratislava','Main Square in Bratislava','Bratislava Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000004,7030001,'Old Town Hall in Bratislava','Old Town Hall in Bratislava','Bratislava Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000005,7030001,'St Martin’s Cathedral','St Martin’s Cathedral','Bratislava Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000006,7030001,'Michael’s Gate','Michael’s Gate','Bratislava Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000007,7030001,'Blue Church','Blue Church','Bratislava Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000008,7030001,'Primate’s Palace','Primate’s Palace','Bratislava Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000009,7030001,'Slovak National Theatre Historical Building','Slovak National Theatre Historical Building','Bratislava Region','2026-10-02','cultural venue','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000010,7030001,'UFO Observation Deck','UFO Observation Deck','Bratislava Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000011,7030001,'Slavín Memorial','Slavín Memorial','Bratislava Region','2026-10-02','museum','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000012,7030001,'Devín Castle','Devín Castle','Bratislava Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000013,7030001,'Grassalkovich Palace','Grassalkovich Palace','Bratislava Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000014,7030001,'Hviezdoslav Square','Hviezdoslav Square','Bratislava Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000015,7030001,'Danube River Promenade','Danube River Promenade','Bratislava Region','2026-10-02','nature site','Slovakia.travel official tourism portal / Bratislava Tourist Board','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000016,7030002,'Trnava Town Tower','Trnava Town Tower','Trnava Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Región Tirnavia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000017,7030002,'Trnava City Walls','Trnava City Walls','Trnava Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Región Tirnavia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000018,7030002,'Cathedral of St John the Baptist in Trnava','Cathedral of St John the Baptist in Trnava','Trnava Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Región Tirnavia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000019,7030002,'Basilica of St Nicholas in Trnava','Basilica of St Nicholas in Trnava','Trnava Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Región Tirnavia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000020,7030002,'Trinity Square in Trnava','Trinity Square in Trnava','Trnava Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Región Tirnavia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000021,7030002,'Holy Trinity Column in Trnava','Holy Trinity Column in Trnava','Trnava Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Región Tirnavia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000022,7030002,'Synagogue Status Quo Ante in Trnava','Synagogue Status Quo Ante in Trnava','Trnava Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Región Tirnavia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000023,7030002,'West Slovak Museum','West Slovak Museum','Trnava Region','2026-10-02','museum','Slovakia.travel official tourism portal / Región Tirnavia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000024,7030002,'Ján Koniarek Gallery','Ján Koniarek Gallery','Trnava Region','2026-10-02','museum','Slovakia.travel official tourism portal / Región Tirnavia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000025,7030002,'University Buildings of Trnava','University Buildings of Trnava','Trnava Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Región Tirnavia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000026,7030003,'Trenčín Castle','Trenčín Castle','Trenčín Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Visit Trenčín','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000027,7030003,'Roman Inscription of Trenčín','Roman Inscription of Trenčín','Trenčín Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Trenčín','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000028,7030003,'Mierové Square','Mierové Square','Trenčín Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Visit Trenčín','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000029,7030003,'Trenčín Town Tower','Trenčín Town Tower','Trenčín Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Trenčín','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000030,7030003,'Trenčín Synagogue','Trenčín Synagogue','Trenčín Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Visit Trenčín','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000031,7030003,'Piarist Church of St Francis Xavier','Piarist Church of St Francis Xavier','Trenčín Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Visit Trenčín','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000032,7030003,'Parish Stairway in Trenčín','Parish Stairway in Trenčín','Trenčín Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Trenčín','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000033,7030003,'Brezina Forest Park','Brezina Forest Park','Trenčín Region','2026-10-02','nature site','Slovakia.travel official tourism portal / Visit Trenčín','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000034,7030004,'Nitra Castle','Nitra Castle','Nitra Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / TIC Nitra','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000035,7030004,'Cathedral of St Emmeram','Cathedral of St Emmeram','Nitra Region','2026-10-02','religious site','Slovakia.travel official tourism portal / TIC Nitra','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000036,7030004,'Diocesan Museum in Nitra','Diocesan Museum in Nitra','Nitra Region','2026-10-02','museum','Slovakia.travel official tourism portal / TIC Nitra','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000037,7030004,'Pribina Square','Pribina Square','Nitra Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / TIC Nitra','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000038,7030004,'Zobor Monastery','Zobor Monastery','Nitra Region','2026-10-02','religious site','Slovakia.travel official tourism portal / TIC Nitra','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000039,7030004,'Nitra Calvary','Nitra Calvary','Nitra Region','2026-10-02','religious site','Slovakia.travel official tourism portal / TIC Nitra','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000040,7030004,'Slovak Agricultural Museum','Slovak Agricultural Museum','Nitra Region','2026-10-02','museum','Slovakia.travel official tourism portal / TIC Nitra','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000041,7030004,'Nitra City Park','Nitra City Park','Nitra Region','2026-10-02','nature site','Slovakia.travel official tourism portal / TIC Nitra','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000042,7030004,'Nitra Synagogue','Nitra Synagogue','Nitra Region','2026-10-02','religious site','Slovakia.travel official tourism portal / TIC Nitra','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000043,7030004,'Ponitrianske Museum','Ponitrianske Museum','Nitra Region','2026-10-02','museum','Slovakia.travel official tourism portal / TIC Nitra','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000044,7030005,'Mariánske Square','Mariánske Square','Žilina Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Žilina Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000045,7030005,'Holy Trinity Cathedral in Žilina','Holy Trinity Cathedral in Žilina','Žilina Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Žilina Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000046,7030005,'Burian Tower','Burian Tower','Žilina Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Žilina Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000047,7030005,'Rosenfeld Palace','Rosenfeld Palace','Žilina Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Žilina Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000048,7030005,'Považie Art Gallery','Považie Art Gallery','Žilina Region','2026-10-02','museum','Slovakia.travel official tourism portal / Žilina Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000049,7030005,'Budatín Castle','Budatín Castle','Žilina Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Žilina Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000050,7030005,'Budatín Park','Budatín Park','Žilina Region','2026-10-02','nature site','Slovakia.travel official tourism portal / Žilina Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000051,7030005,'Church of St Stephen the King','Church of St Stephen the King','Žilina Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Žilina Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000052,7030005,'Stanica Žilina-Záriečie','Stanica Žilina-Záriečie','Žilina Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Žilina Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000053,7030006,'Bojnice Castle','Bojnice Castle','Trenčín Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Bojnice Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000054,7030006,'Bojnice Zoo','Bojnice Zoo','Trenčín Region','2026-10-02','visitor attraction','Slovakia.travel official tourism portal / Bojnice Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000055,7030006,'Museum of Prehistoric Slovakia','Museum of Prehistoric Slovakia','Trenčín Region','2026-10-02','museum','Slovakia.travel official tourism portal / Bojnice Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000056,7030006,'Prepoštská Cave','Prepoštská Cave','Trenčín Region','2026-10-02','nature site','Slovakia.travel official tourism portal / Bojnice Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000057,7030006,'Čajka in the Clouds Observation Tower','Čajka in the Clouds Observation Tower','Trenčín Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Bojnice Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000058,7030006,'Bojnice Spa','Bojnice Spa','Trenčín Region','2026-10-02','visitor attraction','Slovakia.travel official tourism portal / Bojnice Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000059,7030007,'SNP Square in Banská Bystrica','SNP Square in Banská Bystrica','Banská Bystrica Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Visit Banská Bystrica','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000060,7030007,'Clock Tower of Banská Bystrica','Clock Tower of Banská Bystrica','Banská Bystrica Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Banská Bystrica','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000061,7030007,'Thurzo House','Thurzo House','Banská Bystrica Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Banská Bystrica','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000062,7030007,'Museum of Central Slovakia','Museum of Central Slovakia','Banská Bystrica Region','2026-10-02','museum','Slovakia.travel official tourism portal / Visit Banská Bystrica','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000063,7030007,'Banská Bystrica Town Castle','Banská Bystrica Town Castle','Banská Bystrica Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Visit Banská Bystrica','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000064,7030007,'Church of the Assumption of the Virgin Mary in Banská Bystrica','Church of the Assumption of the Virgin Mary in Banská Bystrica','Banská Bystrica Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Visit Banská Bystrica','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000065,7030007,'Church of the Holy Cross in Banská Bystrica','Church of the Holy Cross in Banská Bystrica','Banská Bystrica Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Visit Banská Bystrica','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000066,7030007,'Matej’s House','Matej’s House','Banská Bystrica Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Banská Bystrica','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000067,7030007,'Museum of the Slovak National Uprising','Museum of the Slovak National Uprising','Banská Bystrica Region','2026-10-02','museum','Slovakia.travel official tourism portal / Visit Banská Bystrica','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000068,7030008,'Old Castle in Banská Štiavnica','Old Castle in Banská Štiavnica','Banská Bystrica Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Banská Štiavnica Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000069,7030008,'New Castle in Banská Štiavnica','New Castle in Banská Štiavnica','Banská Bystrica Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Banská Štiavnica Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000070,7030008,'Trinity Square in Banská Štiavnica','Trinity Square in Banská Štiavnica','Banská Bystrica Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Banská Štiavnica Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000071,7030008,'Holy Trinity Column in Banská Štiavnica','Holy Trinity Column in Banská Štiavnica','Banská Bystrica Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Banská Štiavnica Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000072,7030008,'Church of St Catherine in Banská Štiavnica','Church of St Catherine in Banská Štiavnica','Banská Bystrica Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Banská Štiavnica Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000073,7030008,'Banská Štiavnica Town Hall','Banská Štiavnica Town Hall','Banská Bystrica Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Banská Štiavnica Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000074,7030008,'Kammerhof Mining Museum','Kammerhof Mining Museum','Banská Bystrica Region','2026-10-02','museum','Slovakia.travel official tourism portal / Banská Štiavnica Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000075,7030008,'Open-Air Mining Museum','Open-Air Mining Museum','Banská Bystrica Region','2026-10-02','museum','Slovakia.travel official tourism portal / Banská Štiavnica Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000076,7030008,'Banská Štiavnica Calvary','Banská Štiavnica Calvary','Banská Bystrica Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Banská Štiavnica Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000077,7030008,'Mining Academy Botanical Garden','Mining Academy Botanical Garden','Banská Bystrica Region','2026-10-02','nature site','Slovakia.travel official tourism portal / Banská Štiavnica Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000078,7030009,'Co-Cathedral of St Nicholas in Prešov','Co-Cathedral of St Nicholas in Prešov','Prešov Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Prešov Tourist Information Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000079,7030009,'Greek Catholic Cathedral of St John the Baptist','Greek Catholic Cathedral of St John the Baptist','Prešov Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Prešov Tourist Information Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000080,7030009,'Rákóczi Palace','Rákóczi Palace','Prešov Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Prešov Tourist Information Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000081,7030009,'Neptune Fountain in Prešov','Neptune Fountain in Prešov','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Prešov Tourist Information Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000082,7030009,'Prešov Town Hall','Prešov Town Hall','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Prešov Tourist Information Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000083,7030009,'Hlavná Street in Prešov','Hlavná Street in Prešov','Prešov Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Prešov Tourist Information Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000084,7030009,'Klobušický Palace','Klobušický Palace','Prešov Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Prešov Tourist Information Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000085,7030009,'Orthodox Cathedral of St Alexander Nevsky','Orthodox Cathedral of St Alexander Nevsky','Prešov Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Prešov Tourist Information Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000086,7030009,'Prešov Calvary','Prešov Calvary','Prešov Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Prešov Tourist Information Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000087,7030009,'Wine Museum in Prešov','Wine Museum in Prešov','Prešov Region','2026-10-02','museum','Slovakia.travel official tourism portal / Prešov Tourist Information Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000088,7030010,'Starý Smokovec','Starý Smokovec','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / High Tatras tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000089,7030010,'Hrebienok','Hrebienok','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / High Tatras tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000090,7030010,'Tatranská Lomnica','Tatranská Lomnica','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / High Tatras tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000091,7030010,'Lomnický štít','Lomnický štít','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / High Tatras tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000092,7030010,'Skalnaté pleso','Skalnaté pleso','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / High Tatras tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000093,7030010,'Belianska Cave','Belianska Cave','Prešov Region','2026-10-02','nature site','Slovakia.travel official tourism portal / High Tatras tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000094,7030010,'TANAP Museum','TANAP Museum','Prešov Region','2026-10-02','museum','Slovakia.travel official tourism portal / High Tatras tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000095,7030010,'Rainer’s Hut','Rainer’s Hut','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / High Tatras tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000096,7030010,'Cold Creek Waterfalls','Cold Creek Waterfalls','Prešov Region','2026-10-02','nature site','Slovakia.travel official tourism portal / High Tatras tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000097,7030010,'Tatranská Kotlina','Tatranská Kotlina','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / High Tatras tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000098,7030011,'Basilica of St James in Levoča','Basilica of St James in Levoča','Prešov Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Levoča Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000099,7030011,'Altar of Master Paul in Levoča','Altar of Master Paul in Levoča','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Levoča Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000100,7030011,'Levoča Town Hall','Levoča Town Hall','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Levoča Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000101,7030011,'Spiš Museum in Levoča','Spiš Museum in Levoča','Prešov Region','2026-10-02','museum','Slovakia.travel official tourism portal / Levoča Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000102,7030011,'Cage of Shame','Cage of Shame','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Levoča Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000103,7030011,'Master Paul’s House','Master Paul’s House','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Levoča Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000104,7030011,'Levoča Town Walls','Levoča Town Walls','Prešov Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Levoča Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000105,7030011,'Mariánska hora Basilica','Mariánska hora Basilica','Prešov Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Levoča Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000106,7030012,'St Elisabeth Cathedral','St Elisabeth Cathedral','Košice Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000107,7030012,'Urban Tower','Urban Tower','Košice Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000108,7030012,'St Michael Chapel in Košice','St Michael Chapel in Košice','Košice Region','2026-10-02','religious site','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000109,7030012,'Hlavná Street in Košice','Hlavná Street in Košice','Košice Region','2026-10-02','historic urban area','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000110,7030012,'Singing Fountain in Košice','Singing Fountain in Košice','Košice Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000111,7030012,'State Theatre Košice','State Theatre Košice','Košice Region','2026-10-02','cultural venue','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000112,7030012,'East Slovak Museum','East Slovak Museum','Košice Region','2026-10-02','museum','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000113,7030012,'Lower Gate of Košice','Lower Gate of Košice','Košice Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000114,7030012,'Mikluš Prison','Mikluš Prison','Košice Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000115,7030012,'Jakab Palace','Jakab Palace','Košice Region','2026-10-02','castle or fortress','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000116,7030012,'Marathon Runner Statue','Marathon Runner Statue','Košice Region','2026-10-02','landmark','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(703000117,7030012,'Košice Botanical Garden','Košice Botanical Garden','Košice Region','2026-10-02','nature site','Slovakia.travel official tourism portal / Visit Košice','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02');

INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES
(703000001,703000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000002,703000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000003,703000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000004,703000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000005,703000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000006,703000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000007,703000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000008,703000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000009,703000009,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000010,703000010,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000011,703000011,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000012,703000012,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000013,703000013,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000014,703000014,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000015,703000015,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000016,703000016,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000017,703000017,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000018,703000018,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000019,703000019,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000020,703000020,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000021,703000021,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000022,703000022,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000023,703000023,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000024,703000024,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000025,703000025,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000026,703000026,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000027,703000027,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000028,703000028,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000029,703000029,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000030,703000030,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000031,703000031,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000032,703000032,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000033,703000033,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000034,703000034,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000035,703000035,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000036,703000036,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000037,703000037,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000038,703000038,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000039,703000039,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000040,703000040,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000041,703000041,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000042,703000042,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000043,703000043,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000044,703000044,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000045,703000045,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000046,703000046,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000047,703000047,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000048,703000048,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000049,703000049,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000050,703000050,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000051,703000051,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000052,703000052,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000053,703000053,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000054,703000054,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000055,703000055,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000056,703000056,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000057,703000057,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000058,703000058,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000059,703000059,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000060,703000060,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000061,703000061,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000062,703000062,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000063,703000063,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000064,703000064,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000065,703000065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000066,703000066,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000067,703000067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000068,703000068,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000069,703000069,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000070,703000070,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000071,703000071,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000072,703000072,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000073,703000073,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000074,703000074,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000075,703000075,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000076,703000076,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000077,703000077,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000078,703000078,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000079,703000079,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000080,703000080,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000081,703000081,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000082,703000082,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000083,703000083,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000084,703000084,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000085,703000085,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000086,703000086,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000087,703000087,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000088,703000088,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000089,703000089,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000090,703000090,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000091,703000091,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000092,703000092,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000093,703000093,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000094,703000094,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000095,703000095,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000096,703000096,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000097,703000097,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000098,703000098,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000099,703000099,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000100,703000100,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000101,703000101,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000102,703000102,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000103,703000103,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000104,703000104,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000105,703000105,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000106,703000106,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000107,703000107,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000108,703000108,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000109,703000109,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000110,703000110,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000111,703000111,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000112,703000112,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000113,703000113,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000114,703000114,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000115,703000115,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000116,703000116,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(703000117,703000117,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.');

INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES
(703000001,703000001,'Bratislava Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000002,703000002,'Bratislava Old Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000003,703000003,'Main Square in Bratislava','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000004,703000004,'Old Town Hall in Bratislava','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000005,703000005,'St Martin’s Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000006,703000006,'Michael’s Gate','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000007,703000007,'Blue Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000008,703000008,'Primate’s Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000009,703000009,'Slovak National Theatre Historical Building','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000010,703000010,'UFO Observation Deck','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000011,703000011,'Slavín Memorial','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000012,703000012,'Devín Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000013,703000013,'Grassalkovich Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000014,703000014,'Hviezdoslav Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000015,703000015,'Danube River Promenade','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000016,703000016,'Trnava Town Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000017,703000017,'Trnava City Walls','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000018,703000018,'Cathedral of St John the Baptist in Trnava','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000019,703000019,'Basilica of St Nicholas in Trnava','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000020,703000020,'Trinity Square in Trnava','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000021,703000021,'Holy Trinity Column in Trnava','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000022,703000022,'Synagogue Status Quo Ante in Trnava','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000023,703000023,'West Slovak Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000024,703000024,'Ján Koniarek Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000025,703000025,'University Buildings of Trnava','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000026,703000026,'Trenčín Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000027,703000027,'Roman Inscription of Trenčín','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000028,703000028,'Mierové Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000029,703000029,'Trenčín Town Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000030,703000030,'Trenčín Synagogue','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000031,703000031,'Piarist Church of St Francis Xavier','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000032,703000032,'Parish Stairway in Trenčín','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000033,703000033,'Brezina Forest Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000034,703000034,'Nitra Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000035,703000035,'Cathedral of St Emmeram','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000036,703000036,'Diocesan Museum in Nitra','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000037,703000037,'Pribina Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000038,703000038,'Zobor Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000039,703000039,'Nitra Calvary','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000040,703000040,'Slovak Agricultural Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000041,703000041,'Nitra City Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000042,703000042,'Nitra Synagogue','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000043,703000043,'Ponitrianske Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000044,703000044,'Mariánske Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000045,703000045,'Holy Trinity Cathedral in Žilina','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000046,703000046,'Burian Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000047,703000047,'Rosenfeld Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000048,703000048,'Považie Art Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000049,703000049,'Budatín Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000050,703000050,'Budatín Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000051,703000051,'Church of St Stephen the King','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000052,703000052,'Stanica Žilina-Záriečie','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000053,703000053,'Bojnice Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000054,703000054,'Bojnice Zoo','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000055,703000055,'Museum of Prehistoric Slovakia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000056,703000056,'Prepoštská Cave','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000057,703000057,'Čajka in the Clouds Observation Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000058,703000058,'Bojnice Spa','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000059,703000059,'SNP Square in Banská Bystrica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000060,703000060,'Clock Tower of Banská Bystrica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000061,703000061,'Thurzo House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000062,703000062,'Museum of Central Slovakia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000063,703000063,'Banská Bystrica Town Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000064,703000064,'Church of the Assumption of the Virgin Mary in Banská Bystrica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000065,703000065,'Church of the Holy Cross in Banská Bystrica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000066,703000066,'Matej’s House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000067,703000067,'Museum of the Slovak National Uprising','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000068,703000068,'Old Castle in Banská Štiavnica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000069,703000069,'New Castle in Banská Štiavnica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000070,703000070,'Trinity Square in Banská Štiavnica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000071,703000071,'Holy Trinity Column in Banská Štiavnica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000072,703000072,'Church of St Catherine in Banská Štiavnica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000073,703000073,'Banská Štiavnica Town Hall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000074,703000074,'Kammerhof Mining Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000075,703000075,'Open-Air Mining Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000076,703000076,'Banská Štiavnica Calvary','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000077,703000077,'Mining Academy Botanical Garden','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000078,703000078,'Co-Cathedral of St Nicholas in Prešov','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000079,703000079,'Greek Catholic Cathedral of St John the Baptist','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000080,703000080,'Rákóczi Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000081,703000081,'Neptune Fountain in Prešov','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000082,703000082,'Prešov Town Hall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000083,703000083,'Hlavná Street in Prešov','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000084,703000084,'Klobušický Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000085,703000085,'Orthodox Cathedral of St Alexander Nevsky','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000086,703000086,'Prešov Calvary','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000087,703000087,'Wine Museum in Prešov','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000088,703000088,'Starý Smokovec','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000089,703000089,'Hrebienok','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000090,703000090,'Tatranská Lomnica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000091,703000091,'Lomnický štít','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000092,703000092,'Skalnaté pleso','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000093,703000093,'Belianska Cave','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000094,703000094,'TANAP Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000095,703000095,'Rainer’s Hut','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000096,703000096,'Cold Creek Waterfalls','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000097,703000097,'Tatranská Kotlina','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000098,703000098,'Basilica of St James in Levoča','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000099,703000099,'Altar of Master Paul in Levoča','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000100,703000100,'Levoča Town Hall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000101,703000101,'Spiš Museum in Levoča','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000102,703000102,'Cage of Shame','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000103,703000103,'Master Paul’s House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000104,703000104,'Levoča Town Walls','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000105,703000105,'Mariánska hora Basilica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000106,703000106,'St Elisabeth Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000107,703000107,'Urban Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000108,703000108,'St Michael Chapel in Košice','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000109,703000109,'Hlavná Street in Košice','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000110,703000110,'Singing Fountain in Košice','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000111,703000111,'State Theatre Košice','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000112,703000112,'East Slovak Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000113,703000113,'Lower Gate of Košice','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000114,703000114,'Mikluš Prison','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000115,703000115,'Jakab Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000116,703000116,'Marathon Runner Statue','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(703000117,703000117,'Košice Botanical Garden','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

-- Every place gets at least one meaningful tag; mappings use tag names to avoid assuming tag IDs.

INSERT INTO place_tags (place_id,tag_id) SELECT 703000001,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000002,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000003,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000004,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000005,id FROM tags WHERE tag_name IN ('Religious','Heritage','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000006,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000007,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000008,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000009,id FROM tags WHERE tag_name IN ('Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000010,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000011,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000012,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000013,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000014,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000015,id FROM tags WHERE tag_name IN ('Nature','Waterfront');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000016,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000017,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000018,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000019,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000020,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000021,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000022,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000023,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000024,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000025,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000026,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000027,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000028,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000029,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000030,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000031,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000032,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000033,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000034,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000035,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000036,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000037,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000038,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000039,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000040,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000041,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000042,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000043,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000044,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000045,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000046,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000047,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000048,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000049,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000050,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000051,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000052,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000053,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000054,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000055,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000056,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000057,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000058,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000059,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000060,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000061,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000062,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000063,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000064,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000065,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000066,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000067,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000068,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000069,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000070,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000071,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000072,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000073,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000074,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000075,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000076,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000077,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000078,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000079,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000080,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000081,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000082,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000083,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000084,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000085,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000086,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000087,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000088,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000089,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000090,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000091,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000092,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000093,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000094,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000095,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000096,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000097,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000098,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000099,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000100,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000101,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000102,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000103,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000104,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000105,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000106,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000107,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000108,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000109,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000110,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000111,id FROM tags WHERE tag_name IN ('Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000112,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000113,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000114,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000115,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000116,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 703000117,id FROM tags WHERE tag_name IN ('Nature','Park');

COMMIT;
