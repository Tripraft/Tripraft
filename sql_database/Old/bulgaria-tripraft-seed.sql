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
-- TripRaft Bulgaria country seed
-- Generated: 2026-10-02
-- ID namespace: ISO 3166-1 numeric 100
-- Administrative basis: selected real first-level provinces (oblasts) corresponding to traveler hubs.
-- Place basis: Bulgaria Ministry of Tourism plus official municipal tourism portals (Sofia, Plovdiv, Varna, Nessebar, Kazanlak) and UNESCO where applicable.
-- Unsupported provider/live metadata remains NULL; new places use partial verification.
-- ============================================================================

BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (100,'Bulgaria','2026-10-02');

INSERT INTO states (id,country_id,state_name,created_at) VALUES
(100001,100,'Sofia City Province','2026-10-02'),
(100002,100,'Plovdiv Province','2026-10-02'),
(100003,100,'Veliko Tarnovo Province','2026-10-02'),
(100004,100,'Varna Province','2026-10-02'),
(100005,100,'Burgas Province','2026-10-02'),
(100006,100,'Kyustendil Province','2026-10-02'),
(100007,100,'Blagoevgrad Province','2026-10-02'),
(100008,100,'Sofia Province','2026-10-02'),
(100009,100,'Stara Zagora Province','2026-10-02'),
(100010,100,'Vidin Province','2026-10-02'),
(100011,100,'Ruse Province','2026-10-02');

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
(1000001,100001,'Sofia','2026-10-02',1),
(1000002,100002,'Plovdiv','2026-10-02',1),
(1000003,100003,'Veliko Tarnovo','2026-10-02',1),
(1000004,100004,'Varna','2026-10-02',1),
(1000005,100005,'Nessebar','2026-10-02',1),
(1000006,100005,'Sozopol','2026-10-02',1),
(1000007,100006,'Rila','2026-10-02',1),
(1000008,100007,'Bansko','2026-10-02',1),
(1000009,100008,'Koprivshtitsa','2026-10-02',1),
(1000010,100009,'Kazanlak','2026-10-02',1),
(1000011,100010,'Belogradchik','2026-10-02',1),
(1000012,100011,'Ruse','2026-10-02',1);

INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES
(100000001,1000001,'Alexander Nevsky Cathedral','Alexander Nevsky Cathedral','Sofia City Province','2026-10-02','religious site','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000002,1000001,'Saint Sofia Church','Saint Sofia Church','Sofia City Province','2026-10-02','religious site','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000003,1000001,'Rotunda of St George','Rotunda of St George','Sofia City Province','2026-10-02','landmark','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000004,1000001,'Boyana Church','Boyana Church','Sofia City Province','2026-10-02','religious site','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000005,1000001,'National Archaeological Museum','National Archaeological Museum','Sofia City Province','2026-10-02','museum','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000006,1000001,'National History Museum','National History Museum','Sofia City Province','2026-10-02','museum','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000007,1000001,'National Art Gallery','National Art Gallery','Sofia City Province','2026-10-02','museum','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000008,1000001,'National Gallery Square 500','National Gallery Square 500','Sofia City Province','2026-10-02','museum','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000009,1000001,'Sofia History Museum','Sofia History Museum','Sofia City Province','2026-10-02','museum','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000010,1000001,'Banya Bashi Mosque','Banya Bashi Mosque','Sofia City Province','2026-10-02','religious site','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000011,1000001,'Sofia Synagogue','Sofia Synagogue','Sofia City Province','2026-10-02','religious site','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000012,1000001,'Serdica Archaeological Complex','Serdica Archaeological Complex','Sofia City Province','2026-10-02','archaeological site','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000013,1000001,'Ivan Vazov National Theatre','Ivan Vazov National Theatre','Sofia City Province','2026-10-02','landmark','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000014,1000001,'National Palace of Culture','National Palace of Culture','Sofia City Province','2026-10-02','landmark','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000015,1000001,'Borisova Gradina','Borisova Gradina','Sofia City Province','2026-10-02','landmark','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000016,1000001,'Vitosha Boulevard','Vitosha Boulevard','Sofia City Province','2026-10-02','landmark','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000017,1000001,'South Park','South Park','Sofia City Province','2026-10-02','nature site','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000018,1000001,'Monument to the Unknown Warrior','Monument to the Unknown Warrior','Sofia City Province','2026-10-02','landmark','Visit Sofia official tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000019,1000002,'Ancient Theatre of Philippopolis','Ancient Theatre of Philippopolis','Plovdiv Province','2026-10-02','archaeological site','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000020,1000002,'Roman Stadium of Philippopolis','Roman Stadium of Philippopolis','Plovdiv Province','2026-10-02','archaeological site','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000021,1000002,'Plovdiv Old Town','Plovdiv Old Town','Plovdiv Province','2026-10-02','historic urban area','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000022,1000002,'Nebet Tepe','Nebet Tepe','Plovdiv Province','2026-10-02','landmark','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000023,1000002,'Bishop’s Basilica of Philippopolis','Bishop’s Basilica of Philippopolis','Plovdiv Province','2026-10-02','religious site','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000024,1000002,'Small Basilica of Philippopolis','Small Basilica of Philippopolis','Plovdiv Province','2026-10-02','religious site','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000025,1000002,'Roman Forum and Odeon of Philippopolis','Roman Forum and Odeon of Philippopolis','Plovdiv Province','2026-10-02','archaeological site','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000026,1000002,'Regional Ethnographic Museum Plovdiv','Regional Ethnographic Museum Plovdiv','Plovdiv Province','2026-10-02','museum','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000027,1000002,'Regional Archaeological Museum Plovdiv','Regional Archaeological Museum Plovdiv','Plovdiv Province','2026-10-02','museum','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000028,1000002,'Dzhumaya Mosque','Dzhumaya Mosque','Plovdiv Province','2026-10-02','religious site','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000029,1000002,'Church of Saints Constantine and Helena','Church of Saints Constantine and Helena','Plovdiv Province','2026-10-02','religious site','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000030,1000002,'Kapana Creative District','Kapana Creative District','Plovdiv Province','2026-10-02','historic urban area','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000031,1000002,'Tsar Simeon Garden','Tsar Simeon Garden','Plovdiv Province','2026-10-02','nature site','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000032,1000002,'Singing Fountains','Singing Fountains','Plovdiv Province','2026-10-02','landmark','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000033,1000002,'Balabanov House','Balabanov House','Plovdiv Province','2026-10-02','landmark','Visit Plovdiv official municipal tourism portal / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000034,1000003,'Tsarevets Fortress','Tsarevets Fortress','Veliko Tarnovo Province','2026-10-02','castle or fortress','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000035,1000003,'Trapezitsa Fortress','Trapezitsa Fortress','Veliko Tarnovo Province','2026-10-02','castle or fortress','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000036,1000003,'Samovodska Charshiya','Samovodska Charshiya','Veliko Tarnovo Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000037,1000003,'Gurko Street','Gurko Street','Veliko Tarnovo Province','2026-10-02','historic urban area','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000038,1000003,'Veliko Tarnovo Archaeological Museum','Veliko Tarnovo Archaeological Museum','Veliko Tarnovo Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000039,1000003,'Museum of Revival and Constituent Assembly','Museum of Revival and Constituent Assembly','Veliko Tarnovo Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000040,1000003,'Sarafkina House','Sarafkina House','Veliko Tarnovo Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000041,1000003,'Holy Forty Martyrs Church','Holy Forty Martyrs Church','Veliko Tarnovo Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000042,1000003,'Church of St Demetrius of Thessaloniki','Church of St Demetrius of Thessaloniki','Veliko Tarnovo Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000043,1000003,'Asenevtsi Monument','Asenevtsi Monument','Veliko Tarnovo Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000044,1000003,'St Peter and Paul Church','St Peter and Paul Church','Veliko Tarnovo Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000045,1000003,'Vladishki Bridge','Vladishki Bridge','Veliko Tarnovo Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Veliko Tarnovo heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000046,1000004,'Varna Archaeological Museum','Varna Archaeological Museum','Varna Province','2026-10-02','museum','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000047,1000004,'Roman Thermae of Varna','Roman Thermae of Varna','Varna Province','2026-10-02','archaeological site','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000048,1000004,'Small Roman Thermae of Varna','Small Roman Thermae of Varna','Varna Province','2026-10-02','archaeological site','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000049,1000004,'Sea Garden','Sea Garden','Varna Province','2026-10-02','nature site','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000050,1000004,'Dormition of the Mother of God Cathedral','Dormition of the Mother of God Cathedral','Varna Province','2026-10-02','religious site','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000051,1000004,'Varna Aquarium','Varna Aquarium','Varna Province','2026-10-02','landmark','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000052,1000004,'Varna Dolphinarium','Varna Dolphinarium','Varna Province','2026-10-02','landmark','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000053,1000004,'Naval Museum Varna','Naval Museum Varna','Varna Province','2026-10-02','museum','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000054,1000004,'Ethnographic Museum Varna','Ethnographic Museum Varna','Varna Province','2026-10-02','museum','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000055,1000004,'Museum of the History of Medicine Varna','Museum of the History of Medicine Varna','Varna Province','2026-10-02','museum','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000056,1000004,'Euxinograd Palace','Euxinograd Palace','Varna Province','2026-10-02','landmark','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000057,1000004,'Aladzha Monastery','Aladzha Monastery','Varna Province','2026-10-02','religious site','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000058,1000004,'Pobiti Kamani Stone Forest','Pobiti Kamani Stone Forest','Varna Province','2026-10-02','nature site','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000059,1000004,'Asparuhov Park','Asparuhov Park','Varna Province','2026-10-02','nature site','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000060,1000004,'Varna City Art Gallery','Varna City Art Gallery','Varna Province','2026-10-02','museum','Visit Varna official tourism website of Varna Municipality','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000061,1000005,'Ancient City of Nessebar','Ancient City of Nessebar','Burgas Province','2026-10-02','archaeological site','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000062,1000005,'Church of Saint Sophia Nessebar','Church of Saint Sophia Nessebar','Burgas Province','2026-10-02','religious site','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000063,1000005,'Church of Christ Pantocrator','Church of Christ Pantocrator','Burgas Province','2026-10-02','religious site','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000064,1000005,'Church of Saint Stephen Nessebar','Church of Saint Stephen Nessebar','Burgas Province','2026-10-02','religious site','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000065,1000005,'Church of Saint John the Baptist Nessebar','Church of Saint John the Baptist Nessebar','Burgas Province','2026-10-02','religious site','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000066,1000005,'Church of Saint Paraskeva Nessebar','Church of Saint Paraskeva Nessebar','Burgas Province','2026-10-02','religious site','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000067,1000005,'Church of the Holy Archangels Michael and Gabriel','Church of the Holy Archangels Michael and Gabriel','Burgas Province','2026-10-02','religious site','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000068,1000005,'Church of Saint John Aliturgetos','Church of Saint John Aliturgetos','Burgas Province','2026-10-02','religious site','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000069,1000005,'Nessebar Archaeological Museum','Nessebar Archaeological Museum','Burgas Province','2026-10-02','museum','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000070,1000005,'Nessebar Old Windmill','Nessebar Old Windmill','Burgas Province','2026-10-02','landmark','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000071,1000005,'Byzantine Baths of Nessebar','Byzantine Baths of Nessebar','Burgas Province','2026-10-02','landmark','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000072,1000005,'Nessebar Fortification Walls','Nessebar Fortification Walls','Burgas Province','2026-10-02','historic urban area','VisitNessebar official tourism website of Nessebar Municipality / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000073,1000006,'Sozopol Old Town Architectural Reserve','Sozopol Old Town Architectural Reserve','Burgas Province','2026-10-02','nature site','Bulgaria Ministry of Tourism / Sozopol heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000074,1000006,'Sozopol Archaeological Museum','Sozopol Archaeological Museum','Burgas Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Sozopol heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000075,1000006,'Southern Fortress Wall and Tower','Southern Fortress Wall and Tower','Burgas Province','2026-10-02','castle or fortress','Bulgaria Ministry of Tourism / Sozopol heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000076,1000006,'Church of Saints Cyril and Methodius Sozopol','Church of Saints Cyril and Methodius Sozopol','Burgas Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / Sozopol heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000077,1000006,'Church of the Holy Mother of God Sozopol','Church of the Holy Mother of God Sozopol','Burgas Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / Sozopol heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000078,1000006,'Sozopol Ethnographic Museum','Sozopol Ethnographic Museum','Burgas Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Sozopol heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000079,1000006,'Sozopol Art Gallery','Sozopol Art Gallery','Burgas Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Sozopol heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000080,1000006,'Harmani Beach','Harmani Beach','Burgas Province','2026-10-02','nature site','Bulgaria Ministry of Tourism / Sozopol heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000081,1000006,'Central Beach Sozopol','Central Beach Sozopol','Burgas Province','2026-10-02','nature site','Bulgaria Ministry of Tourism / Sozopol heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000082,1000006,'Saint Ivan Island','Saint Ivan Island','Burgas Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Sozopol heritage institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000083,1000007,'Rila Monastery','Rila Monastery','Kyustendil Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000084,1000007,'Hrelyo’s Tower','Hrelyo’s Tower','Kyustendil Province','2026-10-02','castle or fortress','Bulgaria Ministry of Tourism / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000085,1000007,'Rila Monastery Museum','Rila Monastery Museum','Kyustendil Province','2026-10-02','museum','Bulgaria Ministry of Tourism / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000086,1000007,'Nativity of the Virgin Church at Rila Monastery','Nativity of the Virgin Church at Rila Monastery','Kyustendil Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000087,1000007,'Cave of Saint Ivan of Rila','Cave of Saint Ivan of Rila','Kyustendil Province','2026-10-02','nature site','Bulgaria Ministry of Tourism / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000088,1000007,'Hermitage of Saint Luke near Rila Monastery','Hermitage of Saint Luke near Rila Monastery','Kyustendil Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000089,1000008,'Holy Trinity Church Bansko','Holy Trinity Church Bansko','Blagoevgrad Province','2026-10-02','religious site','Bansko Municipality tourism / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000090,1000008,'Velyanova House','Velyanova House','Blagoevgrad Province','2026-10-02','landmark','Bansko Municipality tourism / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000091,1000008,'Nikola Vaptsarov Memorial House','Nikola Vaptsarov Memorial House','Blagoevgrad Province','2026-10-02','museum','Bansko Municipality tourism / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000092,1000008,'Neofit Rilski House Museum','Neofit Rilski House Museum','Blagoevgrad Province','2026-10-02','museum','Bansko Municipality tourism / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000093,1000008,'Radonova House Historical and Ethnographic Museum','Radonova House Historical and Ethnographic Museum','Blagoevgrad Province','2026-10-02','museum','Bansko Municipality tourism / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000094,1000008,'Bansko Icon Exhibition','Bansko Icon Exhibition','Blagoevgrad Province','2026-10-02','landmark','Bansko Municipality tourism / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000095,1000008,'Bansko Gondola','Bansko Gondola','Blagoevgrad Province','2026-10-02','landmark','Bansko Municipality tourism / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000096,1000008,'Vihren Hut','Vihren Hut','Blagoevgrad Province','2026-10-02','landmark','Bansko Municipality tourism / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000097,1000008,'Baykusheva Mura','Baykusheva Mura','Blagoevgrad Province','2026-10-02','nature site','Bansko Municipality tourism / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000098,1000008,'Banderishka Polyana','Banderishka Polyana','Blagoevgrad Province','2026-10-02','landmark','Bansko Municipality tourism / Bulgaria Ministry of Tourism','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000099,1000009,'Oslekov House Museum','Oslekov House Museum','Sofia Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Koprivshtitsa museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000100,1000009,'Lyuben Karavelov Memorial House','Lyuben Karavelov Memorial House','Sofia Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Koprivshtitsa museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000101,1000009,'Dimcho Debelyanov House Museum','Dimcho Debelyanov House Museum','Sofia Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Koprivshtitsa museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000102,1000009,'Todor Kableshkov Memorial House','Todor Kableshkov Memorial House','Sofia Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Koprivshtitsa museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000103,1000009,'Georgi Benkovski Memorial House','Georgi Benkovski Memorial House','Sofia Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Koprivshtitsa museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000104,1000009,'Dormition of the Mother of God Church Koprivshtitsa','Dormition of the Mother of God Church Koprivshtitsa','Sofia Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / Koprivshtitsa museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000105,1000009,'Saint Nicholas Church Koprivshtitsa','Saint Nicholas Church Koprivshtitsa','Sofia Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / Koprivshtitsa museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000106,1000009,'April 20 Square','April 20 Square','Sofia Province','2026-10-02','historic urban area','Bulgaria Ministry of Tourism / Koprivshtitsa museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000107,1000009,'First Rifle Monument','First Rifle Monument','Sofia Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Koprivshtitsa museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000108,1000009,'Kalachev Bridge','Kalachev Bridge','Sofia Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Koprivshtitsa museum institutions','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000109,1000010,'Thracian Tomb of Kazanlak','Thracian Tomb of Kazanlak','Stara Zagora Province','2026-10-02','archaeological site','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000110,1000010,'Museum of Roses','Museum of Roses','Stara Zagora Province','2026-10-02','museum','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000111,1000010,'Iskra History Museum','Iskra History Museum','Stara Zagora Province','2026-10-02','museum','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000112,1000010,'Kazanlak Art Gallery','Kazanlak Art Gallery','Stara Zagora Province','2026-10-02','museum','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000113,1000010,'Kulata Ethnographic Complex','Kulata Ethnographic Complex','Stara Zagora Province','2026-10-02','museum','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000114,1000010,'Golyama Kosmatka Thracian Tomb','Golyama Kosmatka Thracian Tomb','Stara Zagora Province','2026-10-02','archaeological site','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000115,1000010,'Shushmanets Thracian Tomb','Shushmanets Thracian Tomb','Stara Zagora Province','2026-10-02','archaeological site','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000116,1000010,'Helvetia Thracian Tomb','Helvetia Thracian Tomb','Stara Zagora Province','2026-10-02','archaeological site','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000117,1000010,'Griffins Thracian Tomb','Griffins Thracian Tomb','Stara Zagora Province','2026-10-02','archaeological site','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000118,1000010,'Shipka Monument','Shipka Monument','Stara Zagora Province','2026-10-02','landmark','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000119,1000010,'Shipka Memorial Church','Shipka Memorial Church','Stara Zagora Province','2026-10-02','religious site','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000120,1000010,'Buzludzha Monument','Buzludzha Monument','Stara Zagora Province','2026-10-02','landmark','Visit Kazanlak municipal tourism portal / UNESCO World Heritage Centre','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000121,1000011,'Belogradchik Rocks','Belogradchik Rocks','Vidin Province','2026-10-02','nature site','Bulgaria Ministry of Tourism / Belogradchik historical museum','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000122,1000011,'Belogradchik Fortress','Belogradchik Fortress','Vidin Province','2026-10-02','castle or fortress','Bulgaria Ministry of Tourism / Belogradchik historical museum','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000123,1000011,'Belogradchik History Museum','Belogradchik History Museum','Vidin Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Belogradchik historical museum','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000124,1000011,'Belogradchik Astronomical Observatory','Belogradchik Astronomical Observatory','Vidin Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Belogradchik historical museum','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000125,1000011,'Magura Cave','Magura Cave','Vidin Province','2026-10-02','nature site','Bulgaria Ministry of Tourism / Belogradchik historical museum','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000126,1000012,'Freedom Square Ruse','Freedom Square Ruse','Ruse Province','2026-10-02','historic urban area','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000127,1000012,'Monument of Liberty Ruse','Monument of Liberty Ruse','Ruse Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000128,1000012,'Dohodno Zdanie','Dohodno Zdanie','Ruse Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000129,1000012,'Ruse Regional Historical Museum','Ruse Regional Historical Museum','Ruse Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000130,1000012,'Sexaginta Prista Roman Fortress','Sexaginta Prista Roman Fortress','Ruse Province','2026-10-02','castle or fortress','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000131,1000012,'Pantheon of National Revival Heroes','Pantheon of National Revival Heroes','Ruse Province','2026-10-02','landmark','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000132,1000012,'Holy Trinity Cathedral Ruse','Holy Trinity Cathedral Ruse','Ruse Province','2026-10-02','religious site','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000133,1000012,'Ruse Art Gallery','Ruse Art Gallery','Ruse Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000134,1000012,'Eco Museum and Aquarium Ruse','Eco Museum and Aquarium Ruse','Ruse Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000135,1000012,'Zahari Stoyanov House Museum','Zahari Stoyanov House Museum','Ruse Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000136,1000012,'Baba Tonka Museum','Baba Tonka Museum','Ruse Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02'),
(100000137,1000012,'National Transport Museum Ruse','National Transport Museum Ruse','Ruse Province','2026-10-02','museum','Bulgaria Ministry of Tourism / Ruse Regional Museum of History','2026-10-02','partial','Identity/source basis checked at tourism/heritage level; live/provider metadata not fetched.','2026-10-02');

INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES
(100000001,100000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000002,100000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000003,100000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000004,100000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000005,100000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000006,100000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000007,100000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000008,100000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000009,100000009,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000010,100000010,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000011,100000011,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000012,100000012,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000013,100000013,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000014,100000014,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000015,100000015,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000016,100000016,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000017,100000017,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000018,100000018,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000019,100000019,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000020,100000020,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000021,100000021,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000022,100000022,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000023,100000023,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000024,100000024,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000025,100000025,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000026,100000026,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000027,100000027,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000028,100000028,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000029,100000029,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000030,100000030,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000031,100000031,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000032,100000032,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000033,100000033,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000034,100000034,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000035,100000035,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000036,100000036,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000037,100000037,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000038,100000038,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000039,100000039,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000040,100000040,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000041,100000041,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000042,100000042,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000043,100000043,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000044,100000044,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000045,100000045,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000046,100000046,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000047,100000047,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000048,100000048,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000049,100000049,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000050,100000050,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000051,100000051,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000052,100000052,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000053,100000053,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000054,100000054,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000055,100000055,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000056,100000056,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000057,100000057,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000058,100000058,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000059,100000059,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000060,100000060,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000061,100000061,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000062,100000062,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000063,100000063,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000064,100000064,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000065,100000065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000066,100000066,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000067,100000067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000068,100000068,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000069,100000069,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000070,100000070,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000071,100000071,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000072,100000072,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000073,100000073,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000074,100000074,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000075,100000075,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000076,100000076,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000077,100000077,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000078,100000078,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000079,100000079,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000080,100000080,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000081,100000081,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000082,100000082,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000083,100000083,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000084,100000084,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000085,100000085,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000086,100000086,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000087,100000087,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000088,100000088,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000089,100000089,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000090,100000090,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000091,100000091,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000092,100000092,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000093,100000093,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000094,100000094,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000095,100000095,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000096,100000096,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000097,100000097,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000098,100000098,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000099,100000099,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000100,100000100,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000101,100000101,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000102,100000102,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000103,100000103,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000104,100000104,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000105,100000105,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000106,100000106,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000107,100000107,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000108,100000108,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000109,100000109,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000110,100000110,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000111,100000111,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000112,100000112,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000113,100000113,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000114,100000114,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000115,100000115,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000116,100000116,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000117,100000117,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000118,100000118,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000119,100000119,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000120,100000120,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000121,100000121,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000122,100000122,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000123,100000123,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000124,100000124,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000125,100000125,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000126,100000126,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000127,100000127,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000128,100000128,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000129,100000129,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000130,100000130,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000131,100000131,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000132,100000132,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000133,100000133,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000134,100000134,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000135,100000135,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000136,100000136,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.'),
(100000137,100000137,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact weekly hours require official/operator/provider refresh; not guessed in this seed.');

INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES
(100000001,100000001,'Alexander Nevsky Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000002,100000002,'Saint Sofia Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000003,100000003,'Rotunda of St George','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000004,100000004,'Boyana Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000005,100000005,'National Archaeological Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000006,100000006,'National History Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000007,100000007,'National Art Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000008,100000008,'National Gallery Square 500','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000009,100000009,'Sofia History Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000010,100000010,'Banya Bashi Mosque','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000011,100000011,'Sofia Synagogue','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000012,100000012,'Serdica Archaeological Complex','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000013,100000013,'Ivan Vazov National Theatre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000014,100000014,'National Palace of Culture','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000015,100000015,'Borisova Gradina','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000016,100000016,'Vitosha Boulevard','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000017,100000017,'South Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000018,100000018,'Monument to the Unknown Warrior','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000019,100000019,'Ancient Theatre of Philippopolis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000020,100000020,'Roman Stadium of Philippopolis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000021,100000021,'Plovdiv Old Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000022,100000022,'Nebet Tepe','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000023,100000023,'Bishop’s Basilica of Philippopolis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000024,100000024,'Small Basilica of Philippopolis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000025,100000025,'Roman Forum and Odeon of Philippopolis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000026,100000026,'Regional Ethnographic Museum Plovdiv','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000027,100000027,'Regional Archaeological Museum Plovdiv','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000028,100000028,'Dzhumaya Mosque','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000029,100000029,'Church of Saints Constantine and Helena','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000030,100000030,'Kapana Creative District','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000031,100000031,'Tsar Simeon Garden','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000032,100000032,'Singing Fountains','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000033,100000033,'Balabanov House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000034,100000034,'Tsarevets Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000035,100000035,'Trapezitsa Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000036,100000036,'Samovodska Charshiya','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000037,100000037,'Gurko Street','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000038,100000038,'Veliko Tarnovo Archaeological Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000039,100000039,'Museum of Revival and Constituent Assembly','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000040,100000040,'Sarafkina House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000041,100000041,'Holy Forty Martyrs Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000042,100000042,'Church of St Demetrius of Thessaloniki','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000043,100000043,'Asenevtsi Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000044,100000044,'St Peter and Paul Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000045,100000045,'Vladishki Bridge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000046,100000046,'Varna Archaeological Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000047,100000047,'Roman Thermae of Varna','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000048,100000048,'Small Roman Thermae of Varna','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000049,100000049,'Sea Garden','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000050,100000050,'Dormition of the Mother of God Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000051,100000051,'Varna Aquarium','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000052,100000052,'Varna Dolphinarium','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000053,100000053,'Naval Museum Varna','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000054,100000054,'Ethnographic Museum Varna','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000055,100000055,'Museum of the History of Medicine Varna','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000056,100000056,'Euxinograd Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000057,100000057,'Aladzha Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000058,100000058,'Pobiti Kamani Stone Forest','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000059,100000059,'Asparuhov Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000060,100000060,'Varna City Art Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000061,100000061,'Ancient City of Nessebar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000062,100000062,'Church of Saint Sophia Nessebar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000063,100000063,'Church of Christ Pantocrator','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000064,100000064,'Church of Saint Stephen Nessebar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000065,100000065,'Church of Saint John the Baptist Nessebar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000066,100000066,'Church of Saint Paraskeva Nessebar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000067,100000067,'Church of the Holy Archangels Michael and Gabriel','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000068,100000068,'Church of Saint John Aliturgetos','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000069,100000069,'Nessebar Archaeological Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000070,100000070,'Nessebar Old Windmill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000071,100000071,'Byzantine Baths of Nessebar','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000072,100000072,'Nessebar Fortification Walls','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000073,100000073,'Sozopol Old Town Architectural Reserve','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000074,100000074,'Sozopol Archaeological Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000075,100000075,'Southern Fortress Wall and Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000076,100000076,'Church of Saints Cyril and Methodius Sozopol','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000077,100000077,'Church of the Holy Mother of God Sozopol','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000078,100000078,'Sozopol Ethnographic Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000079,100000079,'Sozopol Art Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000080,100000080,'Harmani Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000081,100000081,'Central Beach Sozopol','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000082,100000082,'Saint Ivan Island','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000083,100000083,'Rila Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000084,100000084,'Hrelyo’s Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000085,100000085,'Rila Monastery Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000086,100000086,'Nativity of the Virgin Church at Rila Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000087,100000087,'Cave of Saint Ivan of Rila','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000088,100000088,'Hermitage of Saint Luke near Rila Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000089,100000089,'Holy Trinity Church Bansko','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000090,100000090,'Velyanova House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000091,100000091,'Nikola Vaptsarov Memorial House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000092,100000092,'Neofit Rilski House Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000093,100000093,'Radonova House Historical and Ethnographic Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000094,100000094,'Bansko Icon Exhibition','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000095,100000095,'Bansko Gondola','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000096,100000096,'Vihren Hut','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000097,100000097,'Baykusheva Mura','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000098,100000098,'Banderishka Polyana','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000099,100000099,'Oslekov House Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000100,100000100,'Lyuben Karavelov Memorial House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000101,100000101,'Dimcho Debelyanov House Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000102,100000102,'Todor Kableshkov Memorial House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000103,100000103,'Georgi Benkovski Memorial House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000104,100000104,'Dormition of the Mother of God Church Koprivshtitsa','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000105,100000105,'Saint Nicholas Church Koprivshtitsa','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000106,100000106,'April 20 Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000107,100000107,'First Rifle Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000108,100000108,'Kalachev Bridge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000109,100000109,'Thracian Tomb of Kazanlak','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000110,100000110,'Museum of Roses','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000111,100000111,'Iskra History Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000112,100000112,'Kazanlak Art Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000113,100000113,'Kulata Ethnographic Complex','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000114,100000114,'Golyama Kosmatka Thracian Tomb','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000115,100000115,'Shushmanets Thracian Tomb','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000116,100000116,'Helvetia Thracian Tomb','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000117,100000117,'Griffins Thracian Tomb','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000118,100000118,'Shipka Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000119,100000119,'Shipka Memorial Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000120,100000120,'Buzludzha Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000121,100000121,'Belogradchik Rocks','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000122,100000122,'Belogradchik Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000123,100000123,'Belogradchik History Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000124,100000124,'Belogradchik Astronomical Observatory','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000125,100000125,'Magura Cave','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000126,100000126,'Freedom Square Ruse','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000127,100000127,'Monument of Liberty Ruse','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000128,100000128,'Dohodno Zdanie','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000129,100000129,'Ruse Regional Historical Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000130,100000130,'Sexaginta Prista Roman Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000131,100000131,'Pantheon of National Revival Heroes','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000132,100000132,'Holy Trinity Cathedral Ruse','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000133,100000133,'Ruse Art Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000134,100000134,'Eco Museum and Aquarium Ruse','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000135,100000135,'Zahari Stoyanov House Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000136,100000136,'Baba Tonka Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(100000137,100000137,'National Transport Museum Ruse','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

INSERT INTO place_tags (place_id,tag_id) SELECT 100000001,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000001,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000002,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000002,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000003,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000004,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000004,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000005,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000006,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000007,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000008,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000009,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000010,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000010,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000011,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000011,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000012,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000012,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000013,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000014,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000015,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000016,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000017,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000017,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000018,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000019,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000019,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000020,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000020,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000021,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000021,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000022,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000023,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000023,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000024,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000024,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000025,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000025,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000026,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000027,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000028,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000028,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000029,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000029,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000030,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000030,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000031,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000031,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000032,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000033,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000034,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000034,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000035,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000035,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000036,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000037,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000037,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000038,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000039,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000040,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000041,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000041,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000042,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000042,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000043,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000044,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000044,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000045,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000046,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000047,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000047,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000048,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000048,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000049,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000049,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000050,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000050,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000051,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000052,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000053,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000054,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000055,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000056,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000057,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000057,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000058,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000058,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000059,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000059,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000060,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000061,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000061,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000062,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000062,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000063,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000063,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000064,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000064,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000065,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000065,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000066,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000066,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000067,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000067,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000068,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000068,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000069,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000070,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000071,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000072,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000072,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000073,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000074,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000075,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000075,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000076,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000076,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000077,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000077,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000078,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000079,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000080,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000081,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000082,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000083,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000083,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000084,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000084,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000085,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000086,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000086,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000087,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000088,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000088,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000089,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000089,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000090,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000091,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000092,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000093,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000094,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000095,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000096,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000097,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000098,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000099,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000100,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000101,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000102,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000103,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000104,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000104,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000105,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000105,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000106,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000106,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000107,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000108,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000109,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000109,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000110,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000111,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000112,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000113,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000114,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000114,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000115,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000115,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000116,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000116,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000117,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000117,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000118,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000119,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000119,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000120,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000121,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000122,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000122,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000123,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000124,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000125,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000126,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000126,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000127,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000128,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000129,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000130,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000130,id FROM tags WHERE tag_name='Fortress';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000131,id FROM tags WHERE tag_name='Landmark';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000132,id FROM tags WHERE tag_name='Culture';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000132,id FROM tags WHERE tag_name='Religious';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000133,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000134,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000135,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000136,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 100000137,id FROM tags WHERE tag_name='Museum';

COMMIT;
