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
-- TripRaft Cyprus country seed
-- Generated: 2026-10-02
-- ID namespace: ISO 3166-1 numeric 196
-- Administrative basis: Republic of Cyprus administrative districts corresponding to selected hubs; this seed uses traveler sites in government-controlled areas.
-- Place basis: Visit Cyprus official Deputy Ministry of Tourism portal, Republic of Cyprus government district sources, official museums/heritage institutions, and UNESCO where applicable.
-- Unsupported provider/live metadata remains NULL; new places use partial verification.
-- ============================================================================

BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (196,'Cyprus','2026-10-02');

INSERT INTO states (id,country_id,state_name,created_at) VALUES
(196001,196,'Nicosia District','2026-10-02'),
(196002,196,'Limassol District','2026-10-02'),
(196003,196,'Larnaca District','2026-10-02'),
(196004,196,'Paphos District','2026-10-02'),
(196005,196,'Famagusta District','2026-10-02');

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
(1960001,196001,'Nicosia','2026-10-02',1),
(1960002,196001,'Kakopetria','2026-10-02',2),
(1960003,196002,'Limassol','2026-10-02',1),
(1960004,196002,'Episkopi','2026-10-02',2),
(1960005,196002,'Kolossi','2026-10-02',2),
(1960006,196002,'Omodos','2026-10-02',2),
(1960007,196002,'Pano Platres','2026-10-02',2),
(1960008,196003,'Larnaca','2026-10-02',1),
(1960009,196004,'Paphos','2026-10-02',1),
(1960010,196004,'Geroskipou','2026-10-02',2),
(1960011,196005,'Ayia Napa','2026-10-02',1),
(1960012,196005,'Protaras','2026-10-02',1);

INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES
(196000001,1960001,'Venetian Walls of Nicosia','Venetian Walls of Nicosia','Nicosia District','2026-10-02','historic urban area','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000002,1960001,'Famagusta Gate','Famagusta Gate','Nicosia District','2026-10-02','historic urban area','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000003,1960001,'Leventis Municipal Museum of Nicosia','Leventis Municipal Museum of Nicosia','Nicosia District','2026-10-02','museum','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000004,1960001,'Cyprus Museum','Cyprus Museum','Nicosia District','2026-10-02','museum','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000005,1960001,'Byzantine Museum Nicosia','Byzantine Museum Nicosia','Nicosia District','2026-10-02','museum','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000006,1960001,'Ledra Street','Ledra Street','Nicosia District','2026-10-02','historic urban area','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000007,1960001,'Shacolas Tower Museum and Observatory','Shacolas Tower Museum and Observatory','Nicosia District','2026-10-02','museum','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000008,1960001,'Saint John’s Cathedral Nicosia','Saint John’s Cathedral Nicosia','Nicosia District','2026-10-02','religious site','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000009,1960001,'Ömeriye Mosque','Ömeriye Mosque','Nicosia District','2026-10-02','religious site','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000010,1960001,'Hadjigeorgakis Kornesios Mansion','Hadjigeorgakis Kornesios Mansion','Nicosia District','2026-10-02','landmark','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000011,1960001,'A. G. Leventis Gallery','A. G. Leventis Gallery','Nicosia District','2026-10-02','museum','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000012,1960001,'Liberty Monument Nicosia','Liberty Monument Nicosia','Nicosia District','2026-10-02','landmark','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000013,1960001,'Faneromeni Church Nicosia','Faneromeni Church Nicosia','Nicosia District','2026-10-02','religious site','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000014,1960001,'Nicosia Municipal Arts Centre','Nicosia Municipal Arts Centre','Nicosia District','2026-10-02','landmark','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000015,1960001,'Athalassa National Forest Park','Athalassa National Forest Park','Nicosia District','2026-10-02','nature site','Visit Cyprus official tourism portal / Nicosia municipal and national cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000016,1960002,'Old Kakopetria','Old Kakopetria','Nicosia District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000017,1960002,'Church of Agios Nikolaos tis Stegis','Church of Agios Nikolaos tis Stegis','Nicosia District','2026-10-02','religious site','Visit Cyprus official tourism portal / Cyprus cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000018,1960002,'Kakopetria Watermill','Kakopetria Watermill','Nicosia District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus cultural heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000019,1960003,'Limassol Castle','Limassol Castle','Limassol District','2026-10-02','castle or fortress','Visit Cyprus official tourism portal / Limassol municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000020,1960003,'Cyprus Medieval Museum','Cyprus Medieval Museum','Limassol District','2026-10-02','museum','Visit Cyprus official tourism portal / Limassol municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000021,1960003,'Molos Promenade','Molos Promenade','Limassol District','2026-10-02','historic urban area','Visit Cyprus official tourism portal / Limassol municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000022,1960003,'Limassol Archaeological Museum','Limassol Archaeological Museum','Limassol District','2026-10-02','museum','Visit Cyprus official tourism portal / Limassol municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000023,1960003,'Limassol Municipal Gardens','Limassol Municipal Gardens','Limassol District','2026-10-02','nature site','Visit Cyprus official tourism portal / Limassol municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000024,1960003,'Agia Napa Cathedral Limassol','Agia Napa Cathedral Limassol','Limassol District','2026-10-02','religious site','Visit Cyprus official tourism portal / Limassol municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000025,1960003,'Anexartisias Street','Anexartisias Street','Limassol District','2026-10-02','historic urban area','Visit Cyprus official tourism portal / Limassol municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000026,1960003,'Limassol Old Port','Limassol Old Port','Limassol District','2026-10-02','landmark','Visit Cyprus official tourism portal / Limassol municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000027,1960003,'Limassol Municipal Art Gallery','Limassol Municipal Art Gallery','Limassol District','2026-10-02','museum','Visit Cyprus official tourism portal / Limassol municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000028,1960003,'Heroes Square Limassol','Heroes Square Limassol','Limassol District','2026-10-02','historic urban area','Visit Cyprus official tourism portal / Limassol municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000029,1960004,'Kourion Archaeological Site','Kourion Archaeological Site','Limassol District','2026-10-02','archaeological site','Visit Cyprus official tourism portal / Cyprus Department of Antiquities','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000030,1960004,'Sanctuary of Apollo Hylates','Sanctuary of Apollo Hylates','Limassol District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus Department of Antiquities','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000031,1960004,'Kourion Beach','Kourion Beach','Limassol District','2026-10-02','nature site','Visit Cyprus official tourism portal / Cyprus Department of Antiquities','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000032,1960005,'Kolossi Castle','Kolossi Castle','Limassol District','2026-10-02','castle or fortress','Visit Cyprus official tourism portal / Cyprus Department of Antiquities','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000033,1960006,'Holy Cross Monastery Omodos','Holy Cross Monastery Omodos','Limassol District','2026-10-02','religious site','Visit Cyprus official tourism portal / Omodos local heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000034,1960006,'Omodos Village Square','Omodos Village Square','Limassol District','2026-10-02','historic urban area','Visit Cyprus official tourism portal / Omodos local heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000035,1960006,'Linos Wine Press','Linos Wine Press','Limassol District','2026-10-02','landmark','Visit Cyprus official tourism portal / Omodos local heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000036,1960006,'Omodos Struggle Museum','Omodos Struggle Museum','Limassol District','2026-10-02','museum','Visit Cyprus official tourism portal / Omodos local heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000037,1960006,'Omodos Medieval Wine Press','Omodos Medieval Wine Press','Limassol District','2026-10-02','landmark','Visit Cyprus official tourism portal / Omodos local heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000038,1960007,'Caledonia Waterfall','Caledonia Waterfall','Limassol District','2026-10-02','nature site','Visit Cyprus official tourism portal / Troodos regional heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000039,1960007,'Millomeris Waterfall','Millomeris Waterfall','Limassol District','2026-10-02','nature site','Visit Cyprus official tourism portal / Troodos regional heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000040,1960007,'Platres Nature Trail','Platres Nature Trail','Limassol District','2026-10-02','nature site','Visit Cyprus official tourism portal / Troodos regional heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000041,1960007,'Pano Platres Village Centre','Pano Platres Village Centre','Limassol District','2026-10-02','landmark','Visit Cyprus official tourism portal / Troodos regional heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000042,1960007,'Troodos National Forest Park','Troodos National Forest Park','Limassol District','2026-10-02','nature site','Visit Cyprus official tourism portal / Troodos regional heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000043,1960008,'Church of Saint Lazarus Larnaca','Church of Saint Lazarus Larnaca','Larnaca District','2026-10-02','religious site','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000044,1960008,'Larnaca Salt Lake','Larnaca Salt Lake','Larnaca District','2026-10-02','nature site','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000045,1960008,'Hala Sultan Tekke','Hala Sultan Tekke','Larnaca District','2026-10-02','religious site','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000046,1960008,'Larnaca Medieval Castle','Larnaca Medieval Castle','Larnaca District','2026-10-02','castle or fortress','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000047,1960008,'Pierides Museum','Pierides Museum','Larnaca District','2026-10-02','museum','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000048,1960008,'Finikoudes Promenade','Finikoudes Promenade','Larnaca District','2026-10-02','historic urban area','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000049,1960008,'Kamares Aqueduct','Kamares Aqueduct','Larnaca District','2026-10-02','landmark','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000050,1960008,'Larnaca District Archaeological Museum','Larnaca District Archaeological Museum','Larnaca District','2026-10-02','museum','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000051,1960008,'Kition Archaeological Site','Kition Archaeological Site','Larnaca District','2026-10-02','archaeological site','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000052,1960008,'Mackenzie Beach','Mackenzie Beach','Larnaca District','2026-10-02','nature site','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000053,1960008,'Larnaca Municipal Art Gallery','Larnaca Municipal Art Gallery','Larnaca District','2026-10-02','museum','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000054,1960008,'Pattichio Park','Pattichio Park','Larnaca District','2026-10-02','nature site','Visit Cyprus official tourism portal / Larnaca municipal cultural institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000055,1960009,'Paphos Archaeological Park','Paphos Archaeological Park','Paphos District','2026-10-02','nature site','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000056,1960009,'Tombs of the Kings','Tombs of the Kings','Paphos District','2026-10-02','archaeological site','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000057,1960009,'Paphos Castle','Paphos Castle','Paphos District','2026-10-02','castle or fortress','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000058,1960009,'House of Dionysus Paphos','House of Dionysus Paphos','Paphos District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000059,1960009,'House of Theseus Paphos','House of Theseus Paphos','Paphos District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000060,1960009,'Paphos Odeon','Paphos Odeon','Paphos District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000061,1960009,'Panagia Chrysopolitissa Basilica','Panagia Chrysopolitissa Basilica','Paphos District','2026-10-02','religious site','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000062,1960009,'Saint Paul’s Pillar','Saint Paul’s Pillar','Paphos District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000063,1960009,'Agia Solomoni Catacomb','Agia Solomoni Catacomb','Paphos District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000064,1960009,'Paphos District Archaeological Museum','Paphos District Archaeological Museum','Paphos District','2026-10-02','museum','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000065,1960009,'Paphos Harbour','Paphos Harbour','Paphos District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000066,1960009,'Fabrika Hill','Fabrika Hill','Paphos District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000067,1960009,'Paphos Lighthouse','Paphos Lighthouse','Paphos District','2026-10-02','landmark','Visit Cyprus official tourism portal / Cyprus Department of Antiquities / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000068,1960010,'Agia Paraskevi Byzantine Church','Agia Paraskevi Byzantine Church','Paphos District','2026-10-02','religious site','Visit Cyprus official tourism portal / Geroskipou local heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000069,1960010,'Geroskipou Folk Art Museum','Geroskipou Folk Art Museum','Paphos District','2026-10-02','museum','Visit Cyprus official tourism portal / Geroskipou local heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000070,1960010,'Geroskipou Square','Geroskipou Square','Paphos District','2026-10-02','historic urban area','Visit Cyprus official tourism portal / Geroskipou local heritage sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000071,1960011,'Ayia Napa Monastery','Ayia Napa Monastery','Famagusta District','2026-10-02','religious site','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000072,1960011,'Ayia Napa Sculpture Park','Ayia Napa Sculpture Park','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000073,1960011,'Ayia Napa Sea Caves','Ayia Napa Sea Caves','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000074,1960011,'Thalassa Municipal Museum','Thalassa Municipal Museum','Famagusta District','2026-10-02','museum','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000075,1960011,'Makronissos Tombs','Makronissos Tombs','Famagusta District','2026-10-02','archaeological site','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000076,1960011,'Nissi Beach','Nissi Beach','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000077,1960011,'Makronissos Beach','Makronissos Beach','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000078,1960011,'Love Bridge Ayia Napa','Love Bridge Ayia Napa','Famagusta District','2026-10-02','landmark','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000079,1960011,'Park of Mediterranean Plants Cacti and Succulents','Park of Mediterranean Plants Cacti and Succulents','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000080,1960011,'Ayia Napa Harbour','Ayia Napa Harbour','Famagusta District','2026-10-02','landmark','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000081,1960011,'Museum of Underwater Sculpture Ayia Napa','Museum of Underwater Sculpture Ayia Napa','Famagusta District','2026-10-02','museum','Visit Cyprus official tourism portal / Ayia Napa municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000082,1960012,'Fig Tree Bay','Fig Tree Bay','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Paralimni-Deryneia municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000083,1960012,'Cape Greco National Forest Park','Cape Greco National Forest Park','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Paralimni-Deryneia municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000084,1960012,'Konnos Bay','Konnos Bay','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Paralimni-Deryneia municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000085,1960012,'Church of Profitis Elias Protaras','Church of Profitis Elias Protaras','Famagusta District','2026-10-02','religious site','Visit Cyprus official tourism portal / Paralimni-Deryneia municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000086,1960012,'Cyclops Cave','Cyclops Cave','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Paralimni-Deryneia municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000087,1960012,'Blue Lagoon Cape Greco','Blue Lagoon Cape Greco','Famagusta District','2026-10-02','landmark','Visit Cyprus official tourism portal / Paralimni-Deryneia municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000088,1960012,'Green Bay Protaras','Green Bay Protaras','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Paralimni-Deryneia municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(196000089,1960012,'Sunrise Beach Protaras','Sunrise Beach Protaras','Famagusta District','2026-10-02','nature site','Visit Cyprus official tourism portal / Paralimni-Deryneia municipal tourism sources','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02');

INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES
(196000001,196000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000002,196000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000003,196000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000004,196000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000005,196000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000006,196000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000007,196000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000008,196000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000009,196000009,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000010,196000010,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000011,196000011,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000012,196000012,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000013,196000013,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000014,196000014,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000015,196000015,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000016,196000016,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000017,196000017,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000018,196000018,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000019,196000019,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000020,196000020,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000021,196000021,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000022,196000022,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000023,196000023,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000024,196000024,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000025,196000025,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000026,196000026,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000027,196000027,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000028,196000028,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000029,196000029,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000030,196000030,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000031,196000031,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000032,196000032,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000033,196000033,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000034,196000034,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000035,196000035,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000036,196000036,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000037,196000037,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000038,196000038,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000039,196000039,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000040,196000040,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000041,196000041,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000042,196000042,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000043,196000043,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000044,196000044,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000045,196000045,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000046,196000046,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000047,196000047,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000048,196000048,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000049,196000049,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000050,196000050,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000051,196000051,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000052,196000052,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000053,196000053,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000054,196000054,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000055,196000055,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000056,196000056,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000057,196000057,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000058,196000058,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000059,196000059,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000060,196000060,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000061,196000061,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000062,196000062,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000063,196000063,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000064,196000064,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000065,196000065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000066,196000066,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000067,196000067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000068,196000068,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000069,196000069,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000070,196000070,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000071,196000071,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000072,196000072,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000073,196000073,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000074,196000074,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000075,196000075,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000076,196000076,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000077,196000077,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000078,196000078,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000079,196000079,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000080,196000080,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000081,196000081,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000082,196000082,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000083,196000083,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000084,196000084,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000085,196000085,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000086,196000086,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000087,196000087,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000088,196000088,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(196000089,196000089,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.');

INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES
(196000001,196000001,'Venetian Walls of Nicosia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000002,196000002,'Famagusta Gate','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000003,196000003,'Leventis Municipal Museum of Nicosia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000004,196000004,'Cyprus Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000005,196000005,'Byzantine Museum Nicosia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000006,196000006,'Ledra Street','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000007,196000007,'Shacolas Tower Museum and Observatory','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000008,196000008,'Saint John’s Cathedral Nicosia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000009,196000009,'Ömeriye Mosque','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000010,196000010,'Hadjigeorgakis Kornesios Mansion','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000011,196000011,'A. G. Leventis Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000012,196000012,'Liberty Monument Nicosia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000013,196000013,'Faneromeni Church Nicosia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000014,196000014,'Nicosia Municipal Arts Centre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000015,196000015,'Athalassa National Forest Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000016,196000016,'Old Kakopetria','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000017,196000017,'Church of Agios Nikolaos tis Stegis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000018,196000018,'Kakopetria Watermill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000019,196000019,'Limassol Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000020,196000020,'Cyprus Medieval Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000021,196000021,'Molos Promenade','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000022,196000022,'Limassol Archaeological Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000023,196000023,'Limassol Municipal Gardens','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000024,196000024,'Agia Napa Cathedral Limassol','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000025,196000025,'Anexartisias Street','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000026,196000026,'Limassol Old Port','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000027,196000027,'Limassol Municipal Art Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000028,196000028,'Heroes Square Limassol','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000029,196000029,'Kourion Archaeological Site','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000030,196000030,'Sanctuary of Apollo Hylates','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000031,196000031,'Kourion Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000032,196000032,'Kolossi Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000033,196000033,'Holy Cross Monastery Omodos','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000034,196000034,'Omodos Village Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000035,196000035,'Linos Wine Press','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000036,196000036,'Omodos Struggle Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000037,196000037,'Omodos Medieval Wine Press','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000038,196000038,'Caledonia Waterfall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000039,196000039,'Millomeris Waterfall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000040,196000040,'Platres Nature Trail','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000041,196000041,'Pano Platres Village Centre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000042,196000042,'Troodos National Forest Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000043,196000043,'Church of Saint Lazarus Larnaca','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000044,196000044,'Larnaca Salt Lake','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000045,196000045,'Hala Sultan Tekke','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000046,196000046,'Larnaca Medieval Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000047,196000047,'Pierides Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000048,196000048,'Finikoudes Promenade','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000049,196000049,'Kamares Aqueduct','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000050,196000050,'Larnaca District Archaeological Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000051,196000051,'Kition Archaeological Site','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000052,196000052,'Mackenzie Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000053,196000053,'Larnaca Municipal Art Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000054,196000054,'Pattichio Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000055,196000055,'Paphos Archaeological Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000056,196000056,'Tombs of the Kings','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000057,196000057,'Paphos Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000058,196000058,'House of Dionysus Paphos','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000059,196000059,'House of Theseus Paphos','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000060,196000060,'Paphos Odeon','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000061,196000061,'Panagia Chrysopolitissa Basilica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000062,196000062,'Saint Paul’s Pillar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000063,196000063,'Agia Solomoni Catacomb','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000064,196000064,'Paphos District Archaeological Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000065,196000065,'Paphos Harbour','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000066,196000066,'Fabrika Hill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000067,196000067,'Paphos Lighthouse','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000068,196000068,'Agia Paraskevi Byzantine Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000069,196000069,'Geroskipou Folk Art Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000070,196000070,'Geroskipou Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000071,196000071,'Ayia Napa Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000072,196000072,'Ayia Napa Sculpture Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000073,196000073,'Ayia Napa Sea Caves','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000074,196000074,'Thalassa Municipal Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000075,196000075,'Makronissos Tombs','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000076,196000076,'Nissi Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000077,196000077,'Makronissos Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000078,196000078,'Love Bridge Ayia Napa','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000079,196000079,'Park of Mediterranean Plants Cacti and Succulents','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000080,196000080,'Ayia Napa Harbour','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000081,196000081,'Museum of Underwater Sculpture Ayia Napa','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000082,196000082,'Fig Tree Bay','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000083,196000083,'Cape Greco National Forest Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000084,196000084,'Konnos Bay','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000085,196000085,'Church of Profitis Elias Protaras','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000086,196000086,'Cyclops Cave','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000087,196000087,'Blue Lagoon Cape Greco','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000088,196000088,'Green Bay Protaras','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(196000089,196000089,'Sunrise Beach Protaras','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

INSERT INTO place_tags (place_id,tag_id) SELECT 196000001,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000001,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000002,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000002,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000003,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000004,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000005,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000006,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000006,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000007,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000008,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000008,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000009,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000009,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000010,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000011,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000012,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000013,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000013,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000014,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000015,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000015,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000016,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000017,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000017,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000018,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000019,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000019,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000020,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000021,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000021,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000022,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000023,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000023,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000024,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000024,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000025,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000025,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000026,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000027,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000028,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000028,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000029,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000029,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000030,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000031,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000032,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000032,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000033,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000033,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000034,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000034,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000035,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000036,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000037,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000038,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000039,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000040,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000041,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000042,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000042,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000043,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000043,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000044,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000045,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000045,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000046,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000046,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000047,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000048,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000048,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000049,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000050,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000051,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000051,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000052,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000053,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000054,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000054,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000055,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000055,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000056,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000056,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000057,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000057,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000058,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000059,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000060,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000061,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000061,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000062,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000063,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000064,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000065,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000066,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000067,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000068,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000068,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000069,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000070,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000070,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000071,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000071,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000072,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000072,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000073,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000074,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000075,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000075,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000076,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000077,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000078,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000079,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000079,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000080,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000081,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000082,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000083,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000083,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000084,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000085,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000085,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000086,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000087,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000088,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 196000089,id FROM tags WHERE tag_name='Nature';

COMMIT;
