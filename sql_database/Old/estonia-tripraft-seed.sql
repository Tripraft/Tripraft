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
-- TripRaft Estonia country seed
-- Generated: 2026-10-02
-- ISO 3166-1 numeric namespace: 233
-- Administrative basis: Estonia's 15 official counties.
-- Place basis: Visit Estonia official tourism portal; Visit Pärnu for Pärnu.
-- Unsupported provider/live metadata remains NULL; new places use partial verification.
-- ============================================================================

BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (233,'Estonia','2026-10-02');

INSERT INTO states (id,country_id,state_name,created_at) VALUES
(233001,233,'Harju County','2026-10-02'),
(233002,233,'Hiiu County','2026-10-02'),
(233003,233,'Ida-Viru County','2026-10-02'),
(233004,233,'Jõgeva County','2026-10-02'),
(233005,233,'Järva County','2026-10-02'),
(233006,233,'Lääne County','2026-10-02'),
(233007,233,'Lääne-Viru County','2026-10-02'),
(233008,233,'Põlva County','2026-10-02'),
(233009,233,'Pärnu County','2026-10-02'),
(233010,233,'Rapla County','2026-10-02'),
(233011,233,'Saare County','2026-10-02'),
(233012,233,'Tartu County','2026-10-02'),
(233013,233,'Valga County','2026-10-02'),
(233014,233,'Viljandi County','2026-10-02'),
(233015,233,'Võru County','2026-10-02');

INSERT OR IGNORE INTO tags (tag_name) VALUES
('Activity'),
('Archaeology'),
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
('Promenade'),
('Religious'),
('Waterfront');

INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES
(2330001,233001,'Tallinn','2026-10-02',1),
(2330002,233012,'Tartu','2026-10-02',1),
(2330003,233009,'Pärnu','2026-10-02',1),
(2330004,233003,'Narva','2026-10-02',1),
(2330005,233011,'Saaremaa Rural Municipality','2026-10-02',1),
(2330006,233006,'Haapsalu','2026-10-02',2),
(2330007,233014,'Viljandi','2026-10-02',2),
(2330008,233007,'Rakvere','2026-10-02',2),
(2330009,233015,'Võru','2026-10-02',2),
(2330010,233013,'Otepää','2026-10-02',2),
(2330011,233005,'Paide','2026-10-02',2),
(2330012,233013,'Valga','2026-10-02',2),
(2330013,233002,'Hiiumaa Rural Municipality','2026-10-02',2);

INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES
(233000001,2330001,'Tallinn Old Town','Tallinn Old Town','Harju County','2026-10-02','historic district','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000002,2330001,'Tallinn Town Hall','Tallinn Town Hall','Harju County','2026-10-02','landmark','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000003,2330001,'Tallinn Town Hall Square','Tallinn Town Hall Square','Harju County','2026-10-02','square','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000004,2330001,'Town Hall Pharmacy','Town Hall Pharmacy','Harju County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000005,2330001,'St. Olaf''s Church Tower and Observation Platform','St. Olaf''s Church Tower and Observation Platform','Harju County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000006,2330001,'Niguliste Museum and Viewing Platform','Niguliste Museum and Viewing Platform','Harju County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000007,2330001,'Kiek in de Kök Fortifications Museum','Kiek in de Kök Fortifications Museum','Harju County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000008,2330001,'Tallinn City Life Museum','Tallinn City Life Museum','Harju County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000009,2330001,'Kumu Art Museum','Kumu Art Museum','Harju County','2026-10-02','art museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000010,2330001,'Kadriorg Palace','Kadriorg Palace','Harju County','2026-10-02','palace','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000011,2330001,'Estonian Maritime Museum at the Seaplane Harbour','Estonian Maritime Museum at the Seaplane Harbour','Harju County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000012,2330001,'Estonian Open Air Museum','Estonian Open Air Museum','Harju County','2026-10-02','open-air museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000013,2330001,'Telliskivi Creative City','Telliskivi Creative City','Harju County','2026-10-02','cultural district','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000014,2330001,'Noblessner','Noblessner','Harju County','2026-10-02','cultural district','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000015,2330001,'Rotermann Quarter','Rotermann Quarter','Harju County','2026-10-02','historic district','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000016,2330001,'Tallinn TV Tower','Tallinn TV Tower','Harju County','2026-10-02','observation tower','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000017,2330001,'Tallinn Botanic Garden','Tallinn Botanic Garden','Harju County','2026-10-02','garden','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000018,2330001,'Tallinn Song Festival Grounds','Tallinn Song Festival Grounds','Harju County','2026-10-02','cultural venue','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000019,2330002,'Estonian National Museum','Estonian National Museum','Tartu County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000020,2330002,'AHHAA Science Centre','AHHAA Science Centre','Tartu County','2026-10-02','science centre','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000021,2330002,'University of Tartu Museum','University of Tartu Museum','Tartu County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000022,2330002,'University of Tartu Botanical Garden','University of Tartu Botanical Garden','Tartu County','2026-10-02','garden','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000023,2330002,'University of Tartu Natural History Museum','University of Tartu Natural History Museum','Tartu County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000024,2330002,'University of Tartu Art Museum','University of Tartu Art Museum','Tartu County','2026-10-02','art museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000025,2330002,'Tartu Toy Museum','Tartu Toy Museum','Tartu County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000026,2330002,'Tartu Observatory','Tartu Observatory','Tartu County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000027,2330002,'19th-century Tartu Citizen''s Home Museum','19th-century Tartu Citizen''s Home Museum','Tartu County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000028,2330002,'Tartu Art Museum','Tartu Art Museum','Tartu County','2026-10-02','art museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000029,2330002,'Tartu Town Hall Square','Tartu Town Hall Square','Tartu County','2026-10-02','square','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000030,2330002,'Toomemäe Park','Toomemäe Park','Tartu County','2026-10-02','park','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000031,2330002,'Tartu Cathedral Ruins','Tartu Cathedral Ruins','Tartu County','2026-10-02','ruins','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000032,2330002,'St. John''s Church in Tartu','St. John''s Church in Tartu','Tartu County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000033,2330002,'Estonian Sports and Olympic Museum','Estonian Sports and Olympic Museum','Tartu County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000034,2330002,'Aparaaditehas Creative City','Aparaaditehas Creative City','Tartu County','2026-10-02','cultural district','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000035,2330002,'Supilinn','Supilinn','Tartu County','2026-10-02','historic district','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000036,2330002,'Karlova','Karlova','Tartu County','2026-10-02','historic district','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000037,2330003,'Pärnu Beach','Pärnu Beach','Pärnu County','2026-10-02','beach','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000038,2330003,'Pärnu Beach Promenade','Pärnu Beach Promenade','Pärnu County','2026-10-02','promenade','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000039,2330003,'Pärnu Coastal Meadow Hiking Trail','Pärnu Coastal Meadow Hiking Trail','Pärnu County','2026-10-02','nature trail','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000040,2330003,'Pärnu Beach Park','Pärnu Beach Park','Pärnu County','2026-10-02','park','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000041,2330003,'Pärnu Museum','Pärnu Museum','Pärnu County','2026-10-02','museum','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000042,2330003,'Red Tower','Red Tower','Pärnu County','2026-10-02','historic tower','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000043,2330003,'Tallinn Gate','Tallinn Gate','Pärnu County','2026-10-02','historic gate','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000044,2330003,'Museum of New Art','Museum of New Art','Pärnu County','2026-10-02','art museum','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000045,2330003,'Lydia Koidula Memorial Museum','Lydia Koidula Memorial Museum','Pärnu County','2026-10-02','museum','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000046,2330003,'Pernova Nature House','Pernova Nature House','Pärnu County','2026-10-02','nature centre','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000047,2330003,'Pärnu Jetty','Pärnu Jetty','Pärnu County','2026-10-02','waterfront','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000048,2330003,'Pärnu Moat (Vallikäär)','Pärnu Moat (Vallikäär)','Pärnu County','2026-10-02','park','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000049,2330003,'Vana-Pärnu Birdwatching Tower','Vana-Pärnu Birdwatching Tower','Pärnu County','2026-10-02','observation tower','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000050,2330003,'Pärnu Old Town','Pärnu Old Town','Pärnu County','2026-10-02','historic district','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000051,2330003,'St. Elizabeth''s Church','St. Elizabeth''s Church','Pärnu County','2026-10-02','religious site','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000052,2330003,'St. Catherine''s Church in Pärnu','St. Catherine''s Church in Pärnu','Pärnu County','2026-10-02','religious site','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000053,2330003,'Mary Magdalene Guild','Mary Magdalene Guild','Pärnu County','2026-10-02','craft centre','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000054,2330003,'Jaanson''s Track','Jaanson''s Track','Pärnu County','2026-10-02','promenade','Visit Pärnu official destination portal / Visit Estonia','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000055,2330004,'Narva Castle','Narva Castle','Ida-Viru County','2026-10-02','fortress','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000056,2330004,'Narva Museum','Narva Museum','Ida-Viru County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000057,2330004,'Narva River Promenade','Narva River Promenade','Ida-Viru County','2026-10-02','promenade','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000058,2330004,'Narva Bastions','Narva Bastions','Ida-Viru County','2026-10-02','fortifications','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000059,2330004,'Casemates of Bastion Victoria','Casemates of Bastion Victoria','Ida-Viru County','2026-10-02','historic site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000060,2330004,'Narva Town Hall','Narva Town Hall','Ida-Viru County','2026-10-02','landmark','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000061,2330004,'Kreenholm District and Kreenholm Textile Factory','Kreenholm District and Kreenholm Textile Factory','Ida-Viru County','2026-10-02','industrial heritage','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000062,2330004,'Alexander''s Cathedral','Alexander''s Cathedral','Ida-Viru County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000063,2330004,'Resurrection of Christ Orthodox Cathedral','Resurrection of Christ Orthodox Cathedral','Ida-Viru County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000064,2330004,'Dark Garden','Dark Garden','Ida-Viru County','2026-10-02','park','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000065,2330004,'Five-Kroon Viewing Platform','Five-Kroon Viewing Platform','Ida-Viru County','2026-10-02','viewpoint','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000066,2330004,'Old Narva''s New Life Virtual Exhibition','Old Narva''s New Life Virtual Exhibition','Ida-Viru County','2026-10-02','exhibition','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000067,2330004,'Narva Museum Art Gallery','Narva Museum Art Gallery','Ida-Viru County','2026-10-02','art museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000068,2330004,'Joaorg Recreation Area','Joaorg Recreation Area','Ida-Viru County','2026-10-02','recreation area','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000069,2330005,'Kuressaare Episcopal Castle','Kuressaare Episcopal Castle','Saare County','2026-10-02','fortress','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000070,2330005,'Saaremaa Museum','Saaremaa Museum','Saare County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000071,2330005,'Kuressaare Town Hall','Kuressaare Town Hall','Saare County','2026-10-02','landmark','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000072,2330005,'Thule Koda','Thule Koda','Saare County','2026-10-02','theme centre','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000073,2330005,'Kuressaare Health Park','Kuressaare Health Park','Saare County','2026-10-02','park','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000074,2330005,'Kaali Field of Meteorite Craters','Kaali Field of Meteorite Craters','Saare County','2026-10-02','natural site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000075,2330005,'Panga Cliff and Recreation Area','Panga Cliff and Recreation Area','Saare County','2026-10-02','natural site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000076,2330005,'Angla Windmill Mount','Angla Windmill Mount','Saare County','2026-10-02','heritage site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000077,2330005,'St. Catherine''s Church in Karja','St. Catherine''s Church in Karja','Saare County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000078,2330005,'Salme Viking Ship Site','Salme Viking Ship Site','Saare County','2026-10-02','archaeological site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000079,2330005,'Asva Viking Village Fortress','Asva Viking Village Fortress','Saare County','2026-10-02','theme park','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000080,2330005,'Saare KEK Museum','Saare KEK Museum','Saare County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000081,2330005,'Sõrve Lighthouse','Sõrve Lighthouse','Saare County','2026-10-02','lighthouse','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000082,2330005,'Vilsandi National Park','Vilsandi National Park','Saare County','2026-10-02','national park','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000083,2330005,'Mändjala Beach','Mändjala Beach','Saare County','2026-10-02','beach','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000084,2330005,'Koigi Bog Hiking Trail','Koigi Bog Hiking Trail','Saare County','2026-10-02','nature trail','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000085,2330005,'Kiipsaare Lighthouse','Kiipsaare Lighthouse','Saare County','2026-10-02','lighthouse','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000086,2330005,'Lõmala-Kaugatoma Heritage Trail','Lõmala-Kaugatoma Heritage Trail','Saare County','2026-10-02','heritage trail','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000087,2330006,'Haapsalu Castle','Haapsalu Castle','Lääne County','2026-10-02','fortress','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000088,2330006,'Museum of the Coastal Swedes','Museum of the Coastal Swedes','Lääne County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000089,2330006,'Ilon''s Wonderland','Ilon''s Wonderland','Lääne County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000090,2330006,'Haapsalu Railway and Communications Museum','Haapsalu Railway and Communications Museum','Lääne County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000091,2330006,'Haapsalu Town Hall Museum','Haapsalu Town Hall Museum','Lääne County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000092,2330006,'Africa Beach and Promenade','Africa Beach and Promenade','Lääne County','2026-10-02','promenade','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000093,2330006,'Paralepa Beach','Paralepa Beach','Lääne County','2026-10-02','beach','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000094,2330006,'Gulf Tagalaht Birdwatching Tower','Gulf Tagalaht Birdwatching Tower','Lääne County','2026-10-02','observation tower','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000095,2330006,'Okas Museum','Okas Museum','Lääne County','2026-10-02','art museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000096,2330006,'Haapsalu Kuursaal','Haapsalu Kuursaal','Lääne County','2026-10-02','historic building','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000097,2330006,'Haapsalu Cathedral','Haapsalu Cathedral','Lääne County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000098,2330006,'Haapsalu Old Town','Haapsalu Old Town','Lääne County','2026-10-02','historic district','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000099,2330007,'Ruins of Viljandi Order Castle','Ruins of Viljandi Order Castle','Viljandi County','2026-10-02','ruins','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000100,2330007,'Viljandi Suspension Bridge','Viljandi Suspension Bridge','Viljandi County','2026-10-02','landmark','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000101,2330007,'Viljandi Museum','Viljandi Museum','Viljandi County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000102,2330007,'Kondas Centre','Kondas Centre','Viljandi County','2026-10-02','art museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000103,2330007,'Viljandi Traditional Music Center','Viljandi Traditional Music Center','Viljandi County','2026-10-02','cultural venue','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000104,2330007,'St. John''s Church in Viljandi','St. John''s Church in Viljandi','Viljandi County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000105,2330007,'St. Paul''s Church in Viljandi','St. Paul''s Church in Viljandi','Viljandi County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000106,2330007,'Viljandi Old Water Tower','Viljandi Old Water Tower','Viljandi County','2026-10-02','historic tower','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000107,2330007,'Lake Viljandi Beach','Lake Viljandi Beach','Viljandi County','2026-10-02','beach','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000108,2330007,'Uueveski Recreation Area','Uueveski Recreation Area','Viljandi County','2026-10-02','recreation area','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000109,2330007,'Viljandi Trepimägi','Viljandi Trepimägi','Viljandi County','2026-10-02','landmark','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000110,2330007,'Viljandi Oak Tree and Swing','Viljandi Oak Tree and Swing','Viljandi County','2026-10-02','landmark','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000111,2330007,'Viljandi Strawberries','Viljandi Strawberries','Viljandi County','2026-10-02','public art','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000112,2330007,'Viljandi Old Town','Viljandi Old Town','Viljandi County','2026-10-02','historic district','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000113,2330008,'Rakvere Castle','Rakvere Castle','Lääne-Viru County','2026-10-02','fortress','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000114,2330008,'Tarvas Sculpture','Tarvas Sculpture','Lääne-Viru County','2026-10-02','public art','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000115,2330008,'Estonian Police Museum','Estonian Police Museum','Lääne-Viru County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000116,2330008,'Rakvere Town Citizen''s Home Museum','Rakvere Town Citizen''s Home Museum','Lääne-Viru County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000117,2330008,'Pikk Street in Rakvere','Pikk Street in Rakvere','Lääne-Viru County','2026-10-02','historic street','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000118,2330008,'Rakvere Central Square','Rakvere Central Square','Lääne-Viru County','2026-10-02','square','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000119,2330008,'Young Man on Bicycle Listening to Music','Young Man on Bicycle Listening to Music','Lääne-Viru County','2026-10-02','public art','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000120,2330009,'Võru County Museum','Võru County Museum','Võru County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000121,2330009,'Fr. R. Kreutzwald Memorial Museum','Fr. R. Kreutzwald Memorial Museum','Võru County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000122,2330009,'Catherine''s Church in Võru','Catherine''s Church in Võru','Võru County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000123,2330009,'Apostolic St. Catherine''s Church in Võru','Apostolic St. Catherine''s Church in Võru','Võru County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000124,2330009,'Tamula Lake Beach and Beach Promenade','Tamula Lake Beach and Beach Promenade','Võru County','2026-10-02','beach','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000125,2330009,'Roosisaare Bridge','Roosisaare Bridge','Võru County','2026-10-02','landmark','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000126,2330009,'Site of Tamula Ancient Settlement on Roosisaare','Site of Tamula Ancient Settlement on Roosisaare','Võru County','2026-10-02','archaeological site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000127,2330009,'Fr. R. Kreutzwald Monument and Park','Fr. R. Kreutzwald Monument and Park','Võru County','2026-10-02','park','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000128,2330009,'Catherine II Sculpture and Catherine Alley','Catherine II Sculpture and Catherine Alley','Võru County','2026-10-02','public art','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000129,2330009,'Võru Central Square','Võru Central Square','Võru County','2026-10-02','square','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000130,2330010,'Otepää Central Square','Otepää Central Square','Valga County','2026-10-02','square','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000131,2330010,'Otepää Hill Fort','Otepää Hill Fort','Valga County','2026-10-02','archaeological site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000132,2330010,'Tehvandi Sports Center','Tehvandi Sports Center','Valga County','2026-10-02','sports centre','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000133,2330010,'Viewing Platform at Tehvandi Ski Jumping Hill','Viewing Platform at Tehvandi Ski Jumping Hill','Valga County','2026-10-02','viewpoint','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000134,2330010,'Otepää Winter Sports Museum','Otepää Winter Sports Museum','Valga County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000135,2330010,'Lake Pühajärv','Lake Pühajärv','Valga County','2026-10-02','lake','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000136,2330010,'Pühajärve Beach','Pühajärve Beach','Valga County','2026-10-02','beach','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000137,2330010,'Otepää Nature Park','Otepää Nature Park','Valga County','2026-10-02','nature park','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000138,2330010,'Otepää Adventure Park','Otepää Adventure Park','Valga County','2026-10-02','adventure park','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000139,2330010,'Otepää Wakepark','Otepää Wakepark','Valga County','2026-10-02','water activity','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000140,2330010,'Väike-Munamäe Ski Resort (Munakas)','Väike-Munamäe Ski Resort (Munakas)','Valga County','2026-10-02','ski resort','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000141,2330010,'Kuutsemäe Holiday Centre','Kuutsemäe Holiday Centre','Valga County','2026-10-02','ski resort','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000142,2330010,'Kääriku Sports Centre','Kääriku Sports Centre','Valga County','2026-10-02','sports centre','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000143,2330010,'Kääriku Hiking Trails','Kääriku Hiking Trails','Valga County','2026-10-02','nature trail','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000144,2330010,'Harimägi Observation Tower','Harimägi Observation Tower','Valga County','2026-10-02','observation tower','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000145,2330011,'Paide Castle Tower and Ruins of the Order Castle','Paide Castle Tower and Ruins of the Order Castle','Järva County','2026-10-02','fortress','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000146,2330011,'Wittenstein Activity Museum','Wittenstein Activity Museum','Järva County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000147,2330011,'Arvo Pärt Music Garden','Arvo Pärt Music Garden','Järva County','2026-10-02','garden','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000148,2330011,'Paide Winter Road Hiking Trail','Paide Winter Road Hiking Trail','Järva County','2026-10-02','hiking trail','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000149,2330012,'Valga Town Hall','Valga Town Hall','Valga County','2026-10-02','landmark','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000150,2330012,'Valga-Valka Central Square','Valga-Valka Central Square','Valga County','2026-10-02','square','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000151,2330012,'Valga-Valka Border Swing','Valga-Valka Border Swing','Valga County','2026-10-02','landmark','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000152,2330012,'St. John''s Church in Valga','St. John''s Church in Valga','Valga County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000153,2330012,'Roman Catholic Church of the Holy Spirit','Roman Catholic Church of the Holy Spirit','Valga County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000154,2330012,'Issidor Cathedral','Issidor Cathedral','Valga County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000155,2330012,'Valga Museum','Valga Museum','Valga County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000156,2330012,'Valga War Museum','Valga War Museum','Valga County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000157,2330012,'Pedeli River Nature Trail','Pedeli River Nature Trail','Valga County','2026-10-02','nature trail','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000158,2330012,'Valga Railway Station','Valga Railway Station','Valga County','2026-10-02','historic building','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000159,2330012,'Valga-Valka Open-Air Stage','Valga-Valka Open-Air Stage','Valga County','2026-10-02','cultural venue','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000160,2330013,'Kõpu Lighthouse','Kõpu Lighthouse','Hiiu County','2026-10-02','lighthouse','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000161,2330013,'Ristna Lighthouse','Ristna Lighthouse','Hiiu County','2026-10-02','lighthouse','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000162,2330013,'Tahkuna Lighthouse','Tahkuna Lighthouse','Hiiu County','2026-10-02','lighthouse','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000163,2330013,'Windtower Experience Centre','Windtower Experience Centre','Hiiu County','2026-10-02','experience centre','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000164,2330013,'Sääretirp','Sääretirp','Hiiu County','2026-10-02','natural site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000165,2330013,'Lavender Farm in Hiiumaa','Lavender Farm in Hiiumaa','Hiiu County','2026-10-02','farm attraction','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000166,2330013,'Hill of Crosses in Hiiumaa','Hill of Crosses in Hiiumaa','Hiiu County','2026-10-02','heritage site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000167,2330013,'Tihu Study Trail','Tihu Study Trail','Hiiu County','2026-10-02','nature trail','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000168,2330013,'Long House of Hiiumaa Museum','Long House of Hiiumaa Museum','Hiiu County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000169,2330013,'Kärdla Beach','Kärdla Beach','Hiiu County','2026-10-02','beach','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000170,2330013,'Tõrvanina Beach and Camping Area','Tõrvanina Beach and Camping Area','Hiiu County','2026-10-02','beach','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000171,2330013,'Orjaku Birdwatching Tower','Orjaku Birdwatching Tower','Hiiu County','2026-10-02','observation tower','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000172,2330013,'Orjaku Study Trail','Orjaku Study Trail','Hiiu County','2026-10-02','nature trail','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000173,2330013,'Kassari Chapel','Kassari Chapel','Hiiu County','2026-10-02','religious site','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000174,2330013,'Mihkli Farm Museum','Mihkli Farm Museum','Hiiu County','2026-10-02','museum','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(233000175,2330013,'Suuremõisa Castle','Suuremõisa Castle','Hiiu County','2026-10-02','manor','Visit Estonia official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02');

INSERT INTO opening_hours (id,place_id,notes)
SELECT id,id,'Exact hours require official/operator/provider refresh; daily values intentionally NULL.' FROM places WHERE id BETWEEN 233000001 AND 233000175;

INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status)
SELECT id,id,place_name,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match' FROM places WHERE id BETWEEN 233000001 AND 233000175;

WITH m(place_id,tag_name) AS (VALUES
(233000001,'Heritage'),
(233000002,'Landmark'),
(233000003,'Landmark'),
(233000004,'Museum'),
(233000005,'Religious'),
(233000006,'Museum'),
(233000007,'Museum'),
(233000008,'Museum'),
(233000009,'Art'),
(233000010,'Heritage'),
(233000011,'Museum'),
(233000012,'Museum'),
(233000013,'Culture'),
(233000014,'Culture'),
(233000015,'Heritage'),
(233000016,'Landmark'),
(233000017,'Nature'),
(233000018,'Culture'),
(233000019,'Museum'),
(233000020,'Family'),
(233000021,'Museum'),
(233000022,'Nature'),
(233000023,'Museum'),
(233000024,'Art'),
(233000025,'Museum'),
(233000026,'Museum'),
(233000027,'Museum'),
(233000028,'Art'),
(233000029,'Landmark'),
(233000030,'Park'),
(233000031,'Heritage'),
(233000032,'Religious'),
(233000033,'Museum'),
(233000034,'Culture'),
(233000035,'Heritage'),
(233000036,'Heritage'),
(233000037,'Beach'),
(233000038,'Promenade'),
(233000039,'Nature'),
(233000040,'Park'),
(233000041,'Museum'),
(233000042,'Heritage'),
(233000043,'Heritage'),
(233000044,'Art'),
(233000045,'Museum'),
(233000046,'Nature'),
(233000047,'Waterfront'),
(233000048,'Park'),
(233000049,'Nature'),
(233000050,'Heritage'),
(233000051,'Religious'),
(233000052,'Religious'),
(233000053,'Culture'),
(233000054,'Promenade'),
(233000055,'Fortress'),
(233000056,'Museum'),
(233000057,'Promenade'),
(233000058,'Fortress'),
(233000059,'Heritage'),
(233000060,'Landmark'),
(233000061,'Heritage'),
(233000062,'Religious'),
(233000063,'Religious'),
(233000064,'Park'),
(233000065,'Landmark'),
(233000066,'Museum'),
(233000067,'Art'),
(233000068,'Park'),
(233000069,'Fortress'),
(233000070,'Museum'),
(233000071,'Landmark'),
(233000072,'Family'),
(233000073,'Park'),
(233000074,'Nature'),
(233000075,'Nature'),
(233000076,'Heritage'),
(233000077,'Religious'),
(233000078,'Archaeology'),
(233000079,'Family'),
(233000080,'Museum'),
(233000081,'Lighthouse'),
(233000082,'Nature'),
(233000083,'Beach'),
(233000084,'Nature'),
(233000085,'Lighthouse'),
(233000086,'Heritage'),
(233000087,'Fortress'),
(233000088,'Museum'),
(233000089,'Family'),
(233000090,'Museum'),
(233000091,'Museum'),
(233000092,'Promenade'),
(233000093,'Beach'),
(233000094,'Nature'),
(233000095,'Art'),
(233000096,'Heritage'),
(233000097,'Religious'),
(233000098,'Heritage'),
(233000099,'Heritage'),
(233000100,'Landmark'),
(233000101,'Museum'),
(233000102,'Art'),
(233000103,'Culture'),
(233000104,'Religious'),
(233000105,'Religious'),
(233000106,'Heritage'),
(233000107,'Beach'),
(233000108,'Park'),
(233000109,'Landmark'),
(233000110,'Landmark'),
(233000111,'Art'),
(233000112,'Heritage'),
(233000113,'Fortress'),
(233000114,'Art'),
(233000115,'Museum'),
(233000116,'Museum'),
(233000117,'Heritage'),
(233000118,'Landmark'),
(233000119,'Art'),
(233000120,'Museum'),
(233000121,'Museum'),
(233000122,'Religious'),
(233000123,'Religious'),
(233000124,'Beach'),
(233000125,'Landmark'),
(233000126,'Archaeology'),
(233000127,'Park'),
(233000128,'Art'),
(233000129,'Landmark'),
(233000130,'Landmark'),
(233000131,'Archaeology'),
(233000132,'Activity'),
(233000133,'Landmark'),
(233000134,'Museum'),
(233000135,'Nature'),
(233000136,'Beach'),
(233000137,'Nature'),
(233000138,'Activity'),
(233000139,'Activity'),
(233000140,'Activity'),
(233000141,'Activity'),
(233000142,'Activity'),
(233000143,'Nature'),
(233000144,'Nature'),
(233000145,'Fortress'),
(233000146,'Museum'),
(233000147,'Culture'),
(233000148,'Nature'),
(233000149,'Landmark'),
(233000150,'Landmark'),
(233000151,'Landmark'),
(233000152,'Religious'),
(233000153,'Religious'),
(233000154,'Religious'),
(233000155,'Museum'),
(233000156,'Museum'),
(233000157,'Nature'),
(233000158,'Heritage'),
(233000159,'Culture'),
(233000160,'Lighthouse'),
(233000161,'Lighthouse'),
(233000162,'Lighthouse'),
(233000163,'Family'),
(233000164,'Nature'),
(233000165,'Nature'),
(233000166,'Heritage'),
(233000167,'Nature'),
(233000168,'Museum'),
(233000169,'Beach'),
(233000170,'Beach'),
(233000171,'Nature'),
(233000172,'Nature'),
(233000173,'Religious'),
(233000174,'Museum'),
(233000175,'Heritage')
)
INSERT INTO place_tags (place_id,tag_id)
SELECT m.place_id,t.id FROM m JOIN tags t ON t.tag_name=m.tag_name;

COMMIT;
