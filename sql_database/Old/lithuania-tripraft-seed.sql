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
-- TripRaft Lithuania country seed
-- Generated: 2026-10-02
-- ISO 3166-1 numeric namespace: 440
-- Administrative basis: Lithuania's counties, the higher territorial administrative units used by Statistics Lithuania.
-- Place basis: Lithuania Travel official tourism portal plus official destination portals for selected hubs.
-- Unsupported provider/live metadata remains NULL; new places use partial verification.
-- ============================================================================

BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (440,'Lithuania','2026-10-02');

INSERT INTO states (id,country_id,state_name,created_at) VALUES
(440001,440,'Vilnius County','2026-10-02'),
(440002,440,'Kaunas County','2026-10-02'),
(440003,440,'Klaipėda County','2026-10-02'),
(440004,440,'Alytus County','2026-10-02'),
(440005,440,'Šiauliai County','2026-10-02'),
(440006,440,'Utena County','2026-10-02');

INSERT OR IGNORE INTO tags (tag_name) VALUES
('Activity'),
('Art'),
('Beach'),
('Culture'),
('Family'),
('Fortress'),
('Heritage'),
('Landmark'),
('Lighthouse'),
('Museum'),
('Nature'),
('Park'),
('Religious');

INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES
(4400001,440001,'Vilnius','2026-10-02',1),
(4400002,440002,'Kaunas','2026-10-02',1),
(4400003,440003,'Klaipėda','2026-10-02',1),
(4400004,440001,'Trakai','2026-10-02',1),
(4400005,440004,'Druskininkai','2026-10-02',1),
(4400006,440003,'Neringa','2026-10-02',1),
(4400007,440003,'Palanga','2026-10-02',1),
(4400008,440005,'Šiauliai','2026-10-02',2),
(4400009,440006,'Anykščiai','2026-10-02',2),
(4400010,440001,'Kernavė','2026-10-02',2);

INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES
(440000001,4400001,'Vilnius Old Town','Vilnius Old Town','Vilnius County','2026-10-02','historic urban area','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000002,4400001,'Gediminas Castle Tower','Gediminas Castle Tower','Vilnius County','2026-10-02','castle or fortress','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000003,4400001,'Vilnius Cathedral','Vilnius Cathedral','Vilnius County','2026-10-02','religious site','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000004,4400001,'Palace of the Grand Dukes of Lithuania','Palace of the Grand Dukes of Lithuania','Vilnius County','2026-10-02','castle or fortress','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000005,4400001,'St Anne’s Church','St Anne’s Church','Vilnius County','2026-10-02','religious site','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000006,4400001,'Bernardine Garden','Bernardine Garden','Vilnius County','2026-10-02','nature site','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000007,4400001,'Užupis','Užupis','Vilnius County','2026-10-02','landmark','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000008,4400001,'Gate of Dawn','Gate of Dawn','Vilnius County','2026-10-02','landmark','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000009,4400001,'Museum of Occupations and Freedom Fights','Museum of Occupations and Freedom Fights','Vilnius County','2026-10-02','museum','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000010,4400001,'MO Museum','MO Museum','Vilnius County','2026-10-02','museum','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000011,4400001,'National Museum of Lithuania','National Museum of Lithuania','Vilnius County','2026-10-02','museum','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000012,4400001,'Three Crosses Monument','Three Crosses Monument','Vilnius County','2026-10-02','landmark','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000013,4400001,'Church of St Peter and St Paul','Church of St Peter and St Paul','Vilnius County','2026-10-02','religious site','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000014,4400001,'Literatų Street','Literatų Street','Vilnius County','2026-10-02','historic urban area','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000015,4400001,'Vilnius TV Tower','Vilnius TV Tower','Vilnius County','2026-10-02','landmark','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000016,4400001,'Energy and Technology Museum','Energy and Technology Museum','Vilnius County','2026-10-02','museum','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000017,4400001,'Presidential Palace of Lithuania','Presidential Palace of Lithuania','Vilnius County','2026-10-02','castle or fortress','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000018,4400001,'Pilies Street','Pilies Street','Vilnius County','2026-10-02','historic urban area','Lithuania Travel official tourism portal / Go Vilnius','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000019,4400002,'Kaunas Castle','Kaunas Castle','Kaunas County','2026-10-02','castle or fortress','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000020,4400002,'Pažaislis Monastery','Pažaislis Monastery','Kaunas County','2026-10-02','religious site','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000021,4400002,'M. K. Čiurlionis National Museum of Art','M. K. Čiurlionis National Museum of Art','Kaunas County','2026-10-02','museum','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000022,4400002,'Devils’ Museum','Devils’ Museum','Kaunas County','2026-10-02','museum','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000023,4400002,'Ninth Fort Museum','Ninth Fort Museum','Kaunas County','2026-10-02','castle or fortress','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000024,4400002,'Aleksotas Funicular','Aleksotas Funicular','Kaunas County','2026-10-02','visitor attraction','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000025,4400002,'Žaliakalnis Funicular','Žaliakalnis Funicular','Kaunas County','2026-10-02','visitor attraction','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000026,4400002,'Aleksotas Observation Deck','Aleksotas Observation Deck','Kaunas County','2026-10-02','landmark','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000027,4400002,'Yard Gallery','Yard Gallery','Kaunas County','2026-10-02','museum','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000028,4400002,'Laisvės Alėja','Laisvės Alėja','Kaunas County','2026-10-02','landmark','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000029,4400002,'Kaunas Town Hall','Kaunas Town Hall','Kaunas County','2026-10-02','landmark','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000030,4400002,'Kaunas Cathedral Basilica','Kaunas Cathedral Basilica','Kaunas County','2026-10-02','religious site','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000031,4400002,'House of Perkūnas','House of Perkūnas','Kaunas County','2026-10-02','landmark','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000032,4400002,'Historical Presidential Palace','Historical Presidential Palace','Kaunas County','2026-10-02','castle or fortress','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000033,4400002,'Sugihara House','Sugihara House','Kaunas County','2026-10-02','landmark','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000034,4400002,'Kaunas Modernist Architecture','Kaunas Modernist Architecture','Kaunas County','2026-10-02','landmark','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000035,4400002,'Christ’s Resurrection Basilica','Christ’s Resurrection Basilica','Kaunas County','2026-10-02','religious site','Lithuania Travel official tourism portal / Kaunas IN','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000036,4400003,'Klaipėda Old Town','Klaipėda Old Town','Klaipėda County','2026-10-02','historic urban area','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000037,4400003,'Theatre Square','Theatre Square','Klaipėda County','2026-10-02','historic urban area','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000038,4400003,'Klaipėda Drama Theatre','Klaipėda Drama Theatre','Klaipėda County','2026-10-02','cultural venue','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000039,4400003,'Klaipėda Castle Museum','Klaipėda Castle Museum','Klaipėda County','2026-10-02','castle or fortress','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000040,4400003,'Lithuanian Sea Museum','Lithuanian Sea Museum','Klaipėda County','2026-10-02','museum','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000041,4400003,'Dolphinarium of the Lithuanian Sea Museum','Dolphinarium of the Lithuanian Sea Museum','Klaipėda County','2026-10-02','museum','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000042,4400003,'Smiltynė Beach','Smiltynė Beach','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000043,4400003,'Klaipėda North Breakwater','Klaipėda North Breakwater','Klaipėda County','2026-10-02','landmark','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000044,4400003,'Meridianas Sailing Ship','Meridianas Sailing Ship','Klaipėda County','2026-10-02','landmark','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000045,4400003,'Klaipėda Sculpture Park','Klaipėda Sculpture Park','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000046,4400003,'Black Ghost Sculpture','Black Ghost Sculpture','Klaipėda County','2026-10-02','landmark','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000047,4400003,'Clock Museum','Clock Museum','Klaipėda County','2026-10-02','museum','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000048,4400003,'Museum 39/45','Museum 39/45','Klaipėda County','2026-10-02','museum','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000049,4400003,'Friedrich Passage','Friedrich Passage','Klaipėda County','2026-10-02','landmark','Lithuania Travel official tourism portal / Klaipėda Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000050,4400004,'Trakai Island Castle','Trakai Island Castle','Vilnius County','2026-10-02','castle or fortress','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000051,4400004,'Trakai Peninsula Castle','Trakai Peninsula Castle','Vilnius County','2026-10-02','castle or fortress','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000052,4400004,'Karaim Street','Karaim Street','Vilnius County','2026-10-02','historic urban area','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000053,4400004,'Trakai Kenesa','Trakai Kenesa','Vilnius County','2026-10-02','religious site','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000054,4400004,'Užutrakis Manor Estate','Užutrakis Manor Estate','Vilnius County','2026-10-02','landmark','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000055,4400004,'Varnikai Cognitive Walking Way','Varnikai Cognitive Walking Way','Vilnius County','2026-10-02','landmark','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000056,4400004,'Hill of Angels','Hill of Angels','Vilnius County','2026-10-02','nature site','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000057,4400004,'Trakai History Museum','Trakai History Museum','Vilnius County','2026-10-02','museum','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000058,4400004,'Church of the Visitation of the Blessed Virgin Mary','Church of the Visitation of the Blessed Virgin Mary','Vilnius County','2026-10-02','religious site','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000059,4400004,'Lake Galvė','Lake Galvė','Vilnius County','2026-10-02','nature site','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000060,4400004,'Trakai Old Post Office','Trakai Old Post Office','Vilnius County','2026-10-02','landmark','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000061,4400004,'Karaim Ethnographic Exhibition','Karaim Ethnographic Exhibition','Vilnius County','2026-10-02','museum','Lithuania Travel official tourism portal / Trakai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000062,4400005,'Snow Arena','Snow Arena','Alytus County','2026-10-02','visitor attraction','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000063,4400005,'Druskininkai Aqua Park','Druskininkai Aqua Park','Alytus County','2026-10-02','nature site','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000064,4400005,'M. K. Čiurlionis Memorial Museum','M. K. Čiurlionis Memorial Museum','Alytus County','2026-10-02','museum','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000065,4400005,'V. K. Jonynas Gallery','V. K. Jonynas Gallery','Alytus County','2026-10-02','museum','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000066,4400005,'Grūtas Park','Grūtas Park','Alytus County','2026-10-02','nature site','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000067,4400005,'Druskininkai Musical Fountain','Druskininkai Musical Fountain','Alytus County','2026-10-02','visitor attraction','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000068,4400005,'Lake Druskonis','Lake Druskonis','Alytus County','2026-10-02','nature site','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000069,4400005,'Druskininkai Cable Car','Druskininkai Cable Car','Alytus County','2026-10-02','visitor attraction','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000070,4400005,'ONE Adventure Park','ONE Adventure Park','Alytus County','2026-10-02','nature site','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000071,4400005,'Church of Saint Mary’s Scapular','Church of Saint Mary’s Scapular','Alytus County','2026-10-02','religious site','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000072,4400005,'Orthodox Church of the Icon of the Mother of God “Joy of All Who Sorrow”','Orthodox Church of the Icon of the Mother of God “Joy of All Who Sorrow”','Alytus County','2026-10-02','religious site','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000073,4400005,'Karolis Dineika Wellness Park','Karolis Dineika Wellness Park','Alytus County','2026-10-02','nature site','Lithuania Travel official tourism portal / Druskininkai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000074,4400006,'Curonian Spit National Park','Curonian Spit National Park','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000075,4400006,'Nida Lighthouse','Nida Lighthouse','Klaipėda County','2026-10-02','landmark','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000076,4400006,'Parnidis Dune','Parnidis Dune','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000077,4400006,'Thomas Mann Memorial Museum','Thomas Mann Memorial Museum','Klaipėda County','2026-10-02','museum','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000078,4400006,'Mizgiris Amber Museum','Mizgiris Amber Museum','Klaipėda County','2026-10-02','museum','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000079,4400006,'Nagliai Nature Reserve','Nagliai Nature Reserve','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000080,4400006,'Hill of Witches','Hill of Witches','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000081,4400006,'Juodkrantė Heron and Cormorant Colony','Juodkrantė Heron and Cormorant Colony','Klaipėda County','2026-10-02','landmark','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000082,4400006,'Nida Fisherman’s Ethnographic Homestead','Nida Fisherman’s Ethnographic Homestead','Klaipėda County','2026-10-02','landmark','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000083,4400006,'Curonian Spit National Park Visitor Centre','Curonian Spit National Park Visitor Centre','Klaipėda County','2026-10-02','museum','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000084,4400006,'Nida Beach','Nida Beach','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000085,4400006,'Grey Dunes','Grey Dunes','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Neringa Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000086,4400007,'Palanga Beach','Palanga Beach','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Palanga Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000087,4400007,'Palanga Pier','Palanga Pier','Klaipėda County','2026-10-02','landmark','Lithuania Travel official tourism portal / Palanga Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000088,4400007,'Palanga Amber Museum','Palanga Amber Museum','Klaipėda County','2026-10-02','museum','Lithuania Travel official tourism portal / Palanga Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000089,4400007,'Birutė Park','Birutė Park','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Palanga Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000090,4400007,'Birutė Hill','Birutė Hill','Klaipėda County','2026-10-02','nature site','Lithuania Travel official tourism portal / Palanga Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000091,4400007,'Jonas Basanavičius Street','Jonas Basanavičius Street','Klaipėda County','2026-10-02','historic urban area','Lithuania Travel official tourism portal / Palanga Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000092,4400007,'Church of the Assumption of the Virgin Mary','Church of the Assumption of the Virgin Mary','Klaipėda County','2026-10-02','religious site','Lithuania Travel official tourism portal / Palanga Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000093,4400007,'Palanga Kurhaus','Palanga Kurhaus','Klaipėda County','2026-10-02','landmark','Lithuania Travel official tourism portal / Palanga Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000094,4400007,'Antanas Mončys House Museum','Antanas Mončys House Museum','Klaipėda County','2026-10-02','museum','Lithuania Travel official tourism portal / Palanga Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000095,4400008,'Cathedral of Saints Peter and Paul in Šiauliai','Cathedral of Saints Peter and Paul in Šiauliai','Šiauliai County','2026-10-02','religious site','Lithuania Travel official tourism portal / Šiauliai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000096,4400008,'Chocolate Museum in Šiauliai','Chocolate Museum in Šiauliai','Šiauliai County','2026-10-02','museum','Lithuania Travel official tourism portal / Šiauliai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000097,4400008,'Bicycle Museum','Bicycle Museum','Šiauliai County','2026-10-02','museum','Lithuania Travel official tourism portal / Šiauliai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000098,4400008,'Photography Museum in Šiauliai','Photography Museum in Šiauliai','Šiauliai County','2026-10-02','museum','Lithuania Travel official tourism portal / Šiauliai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000099,4400008,'Chaim Frenkel Villa Museum','Chaim Frenkel Villa Museum','Šiauliai County','2026-10-02','museum','Lithuania Travel official tourism portal / Šiauliai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000100,4400008,'Sundial Square','Sundial Square','Šiauliai County','2026-10-02','historic urban area','Lithuania Travel official tourism portal / Šiauliai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000101,4400008,'Iron Fox Sculpture','Iron Fox Sculpture','Šiauliai County','2026-10-02','landmark','Lithuania Travel official tourism portal / Šiauliai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000102,4400008,'Lake Talkša','Lake Talkša','Šiauliai County','2026-10-02','nature site','Lithuania Travel official tourism portal / Šiauliai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000103,4400008,'Šiauliai History Museum','Šiauliai History Museum','Šiauliai County','2026-10-02','museum','Lithuania Travel official tourism portal / Šiauliai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000104,4400009,'Treetop Walking Path in Anykščiai Regional Park','Treetop Walking Path in Anykščiai Regional Park','Utena County','2026-10-02','nature site','Lithuania Travel official tourism portal / Anykščiai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000105,4400009,'Puntukas Stone','Puntukas Stone','Utena County','2026-10-02','landmark','Lithuania Travel official tourism portal / Anykščiai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000106,4400009,'Narrow Gauge Railway Museum','Narrow Gauge Railway Museum','Utena County','2026-10-02','museum','Lithuania Travel official tourism portal / Anykščiai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000107,4400009,'Horse Museum','Horse Museum','Utena County','2026-10-02','museum','Lithuania Travel official tourism portal / Anykščiai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000108,4400009,'Angel Museum','Angel Museum','Utena County','2026-10-02','museum','Lithuania Travel official tourism portal / Anykščiai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000109,4400009,'Church of St Matthew in Anykščiai','Church of St Matthew in Anykščiai','Utena County','2026-10-02','religious site','Lithuania Travel official tourism portal / Anykščiai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000110,4400009,'Anykščiai Regional Park','Anykščiai Regional Park','Utena County','2026-10-02','nature site','Lithuania Travel official tourism portal / Anykščiai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000111,4400009,'Kalita Hill','Kalita Hill','Utena County','2026-10-02','nature site','Lithuania Travel official tourism portal / Anykščiai Tourism','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000112,4400010,'Kernavė Archaeological Site','Kernavė Archaeological Site','Vilnius County','2026-10-02','landmark','Lithuania Travel official tourism portal / State Cultural Reserve of Kernavė','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000113,4400010,'Kernavė Archaeological Site Museum','Kernavė Archaeological Site Museum','Vilnius County','2026-10-02','museum','Lithuania Travel official tourism portal / State Cultural Reserve of Kernavė','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000114,4400010,'Aukuro Hillfort','Aukuro Hillfort','Vilnius County','2026-10-02','nature site','Lithuania Travel official tourism portal / State Cultural Reserve of Kernavė','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000115,4400010,'Mindaugas Throne Hillfort','Mindaugas Throne Hillfort','Vilnius County','2026-10-02','nature site','Lithuania Travel official tourism portal / State Cultural Reserve of Kernavė','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000116,4400010,'Lizdeika Hillfort','Lizdeika Hillfort','Vilnius County','2026-10-02','nature site','Lithuania Travel official tourism portal / State Cultural Reserve of Kernavė','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000117,4400010,'Castle Hillfort of Kernavė','Castle Hillfort of Kernavė','Vilnius County','2026-10-02','castle or fortress','Lithuania Travel official tourism portal / State Cultural Reserve of Kernavė','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000118,4400010,'Kriveikiškis Hillfort','Kriveikiškis Hillfort','Vilnius County','2026-10-02','nature site','Lithuania Travel official tourism portal / State Cultural Reserve of Kernavė','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(440000119,4400010,'Church of the Blessed Virgin Mary of the Scapular in Kernavė','Church of the Blessed Virgin Mary of the Scapular in Kernavė','Vilnius County','2026-10-02','religious site','Lithuania Travel official tourism portal / State Cultural Reserve of Kernavė','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02');

INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES
(440000001,440000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000002,440000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000003,440000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000004,440000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000005,440000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000006,440000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000007,440000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000008,440000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000009,440000009,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000010,440000010,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000011,440000011,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000012,440000012,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000013,440000013,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000014,440000014,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000015,440000015,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000016,440000016,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000017,440000017,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000018,440000018,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000019,440000019,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000020,440000020,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000021,440000021,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000022,440000022,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000023,440000023,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000024,440000024,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000025,440000025,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000026,440000026,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000027,440000027,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000028,440000028,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000029,440000029,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000030,440000030,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000031,440000031,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000032,440000032,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000033,440000033,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000034,440000034,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000035,440000035,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000036,440000036,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000037,440000037,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000038,440000038,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000039,440000039,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000040,440000040,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000041,440000041,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000042,440000042,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000043,440000043,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000044,440000044,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000045,440000045,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000046,440000046,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000047,440000047,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000048,440000048,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000049,440000049,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000050,440000050,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000051,440000051,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000052,440000052,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000053,440000053,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000054,440000054,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000055,440000055,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000056,440000056,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000057,440000057,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000058,440000058,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000059,440000059,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000060,440000060,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000061,440000061,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000062,440000062,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000063,440000063,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000064,440000064,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000065,440000065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000066,440000066,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000067,440000067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000068,440000068,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000069,440000069,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000070,440000070,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000071,440000071,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000072,440000072,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000073,440000073,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000074,440000074,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000075,440000075,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000076,440000076,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000077,440000077,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000078,440000078,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000079,440000079,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000080,440000080,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000081,440000081,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000082,440000082,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000083,440000083,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000084,440000084,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000085,440000085,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000086,440000086,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000087,440000087,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000088,440000088,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000089,440000089,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000090,440000090,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000091,440000091,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000092,440000092,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000093,440000093,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000094,440000094,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000095,440000095,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000096,440000096,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000097,440000097,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000098,440000098,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000099,440000099,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000100,440000100,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000101,440000101,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000102,440000102,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000103,440000103,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000104,440000104,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000105,440000105,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000106,440000106,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000107,440000107,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000108,440000108,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000109,440000109,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000110,440000110,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000111,440000111,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000112,440000112,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000113,440000113,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000114,440000114,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000115,440000115,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000116,440000116,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000117,440000117,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000118,440000118,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(440000119,440000119,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.');

INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES
(440000001,440000001,'Vilnius Old Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000002,440000002,'Gediminas Castle Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000003,440000003,'Vilnius Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000004,440000004,'Palace of the Grand Dukes of Lithuania','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000005,440000005,'St Anne’s Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000006,440000006,'Bernardine Garden','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000007,440000007,'Užupis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000008,440000008,'Gate of Dawn','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000009,440000009,'Museum of Occupations and Freedom Fights','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000010,440000010,'MO Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000011,440000011,'National Museum of Lithuania','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000012,440000012,'Three Crosses Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000013,440000013,'Church of St Peter and St Paul','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000014,440000014,'Literatų Street','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000015,440000015,'Vilnius TV Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000016,440000016,'Energy and Technology Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000017,440000017,'Presidential Palace of Lithuania','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000018,440000018,'Pilies Street','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000019,440000019,'Kaunas Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000020,440000020,'Pažaislis Monastery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000021,440000021,'M. K. Čiurlionis National Museum of Art','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000022,440000022,'Devils’ Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000023,440000023,'Ninth Fort Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000024,440000024,'Aleksotas Funicular','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000025,440000025,'Žaliakalnis Funicular','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000026,440000026,'Aleksotas Observation Deck','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000027,440000027,'Yard Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000028,440000028,'Laisvės Alėja','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000029,440000029,'Kaunas Town Hall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000030,440000030,'Kaunas Cathedral Basilica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000031,440000031,'House of Perkūnas','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000032,440000032,'Historical Presidential Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000033,440000033,'Sugihara House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000034,440000034,'Kaunas Modernist Architecture','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000035,440000035,'Christ’s Resurrection Basilica','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000036,440000036,'Klaipėda Old Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000037,440000037,'Theatre Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000038,440000038,'Klaipėda Drama Theatre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000039,440000039,'Klaipėda Castle Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000040,440000040,'Lithuanian Sea Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000041,440000041,'Dolphinarium of the Lithuanian Sea Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000042,440000042,'Smiltynė Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000043,440000043,'Klaipėda North Breakwater','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000044,440000044,'Meridianas Sailing Ship','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000045,440000045,'Klaipėda Sculpture Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000046,440000046,'Black Ghost Sculpture','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000047,440000047,'Clock Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000048,440000048,'Museum 39/45','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000049,440000049,'Friedrich Passage','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000050,440000050,'Trakai Island Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000051,440000051,'Trakai Peninsula Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000052,440000052,'Karaim Street','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000053,440000053,'Trakai Kenesa','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000054,440000054,'Užutrakis Manor Estate','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000055,440000055,'Varnikai Cognitive Walking Way','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000056,440000056,'Hill of Angels','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000057,440000057,'Trakai History Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000058,440000058,'Church of the Visitation of the Blessed Virgin Mary','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000059,440000059,'Lake Galvė','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000060,440000060,'Trakai Old Post Office','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000061,440000061,'Karaim Ethnographic Exhibition','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000062,440000062,'Snow Arena','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000063,440000063,'Druskininkai Aqua Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000064,440000064,'M. K. Čiurlionis Memorial Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000065,440000065,'V. K. Jonynas Gallery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000066,440000066,'Grūtas Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000067,440000067,'Druskininkai Musical Fountain','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000068,440000068,'Lake Druskonis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000069,440000069,'Druskininkai Cable Car','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000070,440000070,'ONE Adventure Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000071,440000071,'Church of Saint Mary’s Scapular','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000072,440000072,'Orthodox Church of the Icon of the Mother of God “Joy of All Who Sorrow”','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000073,440000073,'Karolis Dineika Wellness Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000074,440000074,'Curonian Spit National Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000075,440000075,'Nida Lighthouse','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000076,440000076,'Parnidis Dune','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000077,440000077,'Thomas Mann Memorial Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000078,440000078,'Mizgiris Amber Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000079,440000079,'Nagliai Nature Reserve','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000080,440000080,'Hill of Witches','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000081,440000081,'Juodkrantė Heron and Cormorant Colony','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000082,440000082,'Nida Fisherman’s Ethnographic Homestead','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000083,440000083,'Curonian Spit National Park Visitor Centre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000084,440000084,'Nida Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000085,440000085,'Grey Dunes','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000086,440000086,'Palanga Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000087,440000087,'Palanga Pier','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000088,440000088,'Palanga Amber Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000089,440000089,'Birutė Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000090,440000090,'Birutė Hill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000091,440000091,'Jonas Basanavičius Street','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000092,440000092,'Church of the Assumption of the Virgin Mary','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000093,440000093,'Palanga Kurhaus','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000094,440000094,'Antanas Mončys House Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000095,440000095,'Cathedral of Saints Peter and Paul in Šiauliai','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000096,440000096,'Chocolate Museum in Šiauliai','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000097,440000097,'Bicycle Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000098,440000098,'Photography Museum in Šiauliai','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000099,440000099,'Chaim Frenkel Villa Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000100,440000100,'Sundial Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000101,440000101,'Iron Fox Sculpture','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000102,440000102,'Lake Talkša','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000103,440000103,'Šiauliai History Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000104,440000104,'Treetop Walking Path in Anykščiai Regional Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000105,440000105,'Puntukas Stone','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000106,440000106,'Narrow Gauge Railway Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000107,440000107,'Horse Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000108,440000108,'Angel Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000109,440000109,'Church of St Matthew in Anykščiai','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000110,440000110,'Anykščiai Regional Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000111,440000111,'Kalita Hill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000112,440000112,'Kernavė Archaeological Site','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000113,440000113,'Kernavė Archaeological Site Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000114,440000114,'Aukuro Hillfort','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000115,440000115,'Mindaugas Throne Hillfort','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000116,440000116,'Lizdeika Hillfort','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000117,440000117,'Castle Hillfort of Kernavė','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000118,440000118,'Kriveikiškis Hillfort','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(440000119,440000119,'Church of the Blessed Virgin Mary of the Scapular in Kernavė','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

-- Every place gets at least one meaningful tag; mappings use tag names to avoid assuming tag IDs.

INSERT INTO place_tags (place_id,tag_id) SELECT 440000001,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000002,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000003,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000004,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000005,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000006,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000007,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000008,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000009,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000010,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000011,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000012,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000013,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000014,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000015,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000016,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000017,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000018,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000019,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000020,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000021,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000022,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000023,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000024,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000025,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000026,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000027,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000028,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000029,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000030,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000031,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000032,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000033,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000034,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000035,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000036,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000037,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000038,id FROM tags WHERE tag_name IN ('Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000039,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000040,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000041,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000042,id FROM tags WHERE tag_name IN ('Nature','Beach');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000043,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000044,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000045,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000046,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000047,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000048,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000049,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000050,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000051,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000052,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000053,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000054,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000055,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000056,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000057,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000058,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000059,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000060,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000061,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000062,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000063,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000064,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000065,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000066,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000067,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000068,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000069,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000070,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000071,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000072,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000073,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000074,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000075,id FROM tags WHERE tag_name IN ('Landmark','Heritage','Lighthouse');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000076,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000077,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000078,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000079,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000080,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000081,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000082,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000083,id FROM tags WHERE tag_name IN ('Museum','Culture','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000084,id FROM tags WHERE tag_name IN ('Nature','Beach');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000085,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000086,id FROM tags WHERE tag_name IN ('Nature','Beach');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000087,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000088,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000089,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000090,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000091,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000092,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000093,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000094,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000095,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000096,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000097,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000098,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000099,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000100,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000101,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000102,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000103,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000104,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000105,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000106,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000107,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000108,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000109,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000110,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000111,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000112,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000113,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000114,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000115,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000116,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000117,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000118,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 440000119,id FROM tags WHERE tag_name IN ('Religious','Heritage');

COMMIT;
