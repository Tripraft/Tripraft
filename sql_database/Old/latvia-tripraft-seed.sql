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
-- TripRaft Latvia country seed
-- Generated: 2026-10-02
-- ISO 3166-1 numeric namespace: 428
-- Administrative basis: Latvia's official State city governments and municipalities under the Administrative Territories and Populated Areas Law.
-- Place basis: Latvia Travel official tourism portal plus official destination portals for selected hubs.
-- Unsupported provider/live metadata remains NULL; new places use partial verification.
-- ============================================================================

BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (428,'Latvia','2026-10-02');

INSERT INTO states (id,country_id,state_name,created_at) VALUES
(428001,428,'Rīga City Government','2026-10-02'),
(428002,428,'Jūrmala City Government','2026-10-02'),
(428003,428,'Liepāja City Government','2026-10-02'),
(428004,428,'Ventspils City Government','2026-10-02'),
(428005,428,'Daugavpils City Government','2026-10-02'),
(428006,428,'Rēzekne City Government','2026-10-02'),
(428007,428,'Jelgava City Government','2026-10-02'),
(428008,428,'Sigulda municipality','2026-10-02'),
(428009,428,'Cēsis municipality','2026-10-02'),
(428010,428,'Kuldīga municipality','2026-10-02'),
(428011,428,'Bauska municipality','2026-10-02'),
(428012,428,'Valmiera municipality','2026-10-02');

INSERT OR IGNORE INTO tags (tag_name) VALUES
('Activity'),
('Art'),
('Beach'),
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
(4280001,428001,'Rīga','2026-10-02',1),
(4280002,428002,'Jūrmala','2026-10-02',1),
(4280003,428003,'Liepāja','2026-10-02',1),
(4280004,428004,'Ventspils','2026-10-02',1),
(4280005,428005,'Daugavpils','2026-10-02',1),
(4280006,428006,'Rēzekne','2026-10-02',2),
(4280007,428007,'Jelgava','2026-10-02',2),
(4280008,428008,'Sigulda','2026-10-02',1),
(4280009,428009,'Cēsis','2026-10-02',1),
(4280010,428010,'Kuldīga','2026-10-02',2),
(4280011,428011,'Bauska','2026-10-02',2),
(4280012,428012,'Valmiera','2026-10-02',2);

INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES
(428000001,4280001,'Old Town Riga','Old Town Riga','Rīga City Government','2026-10-02','historic urban area','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000002,4280001,'Riga Castle','Riga Castle','Rīga City Government','2026-10-02','castle or fortress','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000003,4280001,'House of the Black Heads','House of the Black Heads','Rīga City Government','2026-10-02','landmark','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000004,4280001,'Riga Cathedral','Riga Cathedral','Rīga City Government','2026-10-02','religious site','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000005,4280001,'St Peter’s Church','St Peter’s Church','Rīga City Government','2026-10-02','religious site','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000006,4280001,'Three Brothers','Three Brothers','Rīga City Government','2026-10-02','landmark','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000007,4280001,'Swedish Gate','Swedish Gate','Rīga City Government','2026-10-02','landmark','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000008,4280001,'Powder Tower','Powder Tower','Rīga City Government','2026-10-02','landmark','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000009,4280001,'Freedom Monument','Freedom Monument','Rīga City Government','2026-10-02','landmark','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000010,4280001,'Latvian National Opera','Latvian National Opera','Rīga City Government','2026-10-02','cultural venue','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000011,4280001,'Riga Central Market','Riga Central Market','Rīga City Government','2026-10-02','landmark','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000012,4280001,'Latvian National Museum of Art','Latvian National Museum of Art','Rīga City Government','2026-10-02','museum','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000013,4280001,'Alberta Street Art Nouveau District','Alberta Street Art Nouveau District','Rīga City Government','2026-10-02','historic urban area','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000014,4280001,'Riga Motor Museum','Riga Motor Museum','Rīga City Government','2026-10-02','museum','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000015,4280001,'Latvian Ethnographic Open-Air Museum','Latvian Ethnographic Open-Air Museum','Rīga City Government','2026-10-02','museum','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000016,4280001,'National Library of Latvia','National Library of Latvia','Rīga City Government','2026-10-02','landmark','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000017,4280001,'Bastejkalna Park','Bastejkalna Park','Rīga City Government','2026-10-02','nature site','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000018,4280001,'Riga Ghetto and Latvian Holocaust Museum','Riga Ghetto and Latvian Holocaust Museum','Rīga City Government','2026-10-02','museum','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000019,4280002,'Majori Beach','Majori Beach','Jūrmala City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000020,4280002,'Jomas Street','Jomas Street','Jūrmala City Government','2026-10-02','historic urban area','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000021,4280002,'Dzintari Concert Hall','Dzintari Concert Hall','Jūrmala City Government','2026-10-02','cultural venue','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000022,4280002,'Jūrmala Open Air Museum','Jūrmala Open Air Museum','Jūrmala City Government','2026-10-02','museum','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000023,4280002,'Ragakāpa Nature Park','Ragakāpa Nature Park','Jūrmala City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000024,4280002,'Great Ķemeri Bog Boardwalk','Great Ķemeri Bog Boardwalk','Jūrmala City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000025,4280002,'Ķemeri National Park','Ķemeri National Park','Jūrmala City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000026,4280002,'Līvu Aquapark','Līvu Aquapark','Jūrmala City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000027,4280002,'Dzintari Forest Park','Dzintari Forest Park','Jūrmala City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000028,4280002,'Jūrmala City Museum','Jūrmala City Museum','Jūrmala City Government','2026-10-02','museum','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000029,4280002,'Ķemeri Water Tower','Ķemeri Water Tower','Jūrmala City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000030,4280002,'Dubulti Art Station','Dubulti Art Station','Jūrmala City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Visit Jūrmala','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000031,4280003,'Liepāja Beach','Liepāja Beach','Liepāja City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000032,4280003,'Liepāja Seaside Park','Liepāja Seaside Park','Liepāja City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000033,4280003,'Karosta','Karosta','Liepāja City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000034,4280003,'Karosta Prison','Karosta Prison','Liepāja City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000035,4280003,'St Nicholas Orthodox Naval Cathedral','St Nicholas Orthodox Naval Cathedral','Liepāja City Government','2026-10-02','religious site','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000036,4280003,'Northern Forts','Northern Forts','Liepāja City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000037,4280003,'North Pier','North Pier','Liepāja City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000038,4280003,'Great Amber Concert Hall','Great Amber Concert Hall','Liepāja City Government','2026-10-02','cultural venue','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000039,4280003,'Liepāja Museum','Liepāja Museum','Liepāja City Government','2026-10-02','museum','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000040,4280003,'Holy Trinity Cathedral','Holy Trinity Cathedral','Liepāja City Government','2026-10-02','religious site','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000041,4280003,'Peter’s Market','Peter’s Market','Liepāja City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000042,4280003,'Rose Square','Rose Square','Liepāja City Government','2026-10-02','historic urban area','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000043,4280003,'Liepāja Theatre','Liepāja Theatre','Liepāja City Government','2026-10-02','cultural venue','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000044,4280003,'Latvian Musicians’ Walk of Fame','Latvian Musicians’ Walk of Fame','Liepāja City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Liepāja official destination portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000045,4280004,'Ventspils Livonian Order Castle','Ventspils Livonian Order Castle','Ventspils City Government','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000046,4280004,'Seaside Open-Air Museum in Ventspils','Seaside Open-Air Museum in Ventspils','Ventspils City Government','2026-10-02','museum','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000047,4280004,'Ventspils Beach','Ventspils Beach','Ventspils City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000048,4280004,'Ostas Street Promenade','Ostas Street Promenade','Ventspils City Government','2026-10-02','historic urban area','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000049,4280004,'Adventure Park of Ventspils','Adventure Park of Ventspils','Ventspils City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000050,4280004,'Ventspils Water Amusement Park','Ventspils Water Amusement Park','Ventspils City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000051,4280004,'Science Centre VIZIUM','Science Centre VIZIUM','Ventspils City Government','2026-10-02','visitor attraction','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000052,4280004,'Ventspils Creative House Planetarium and Observatory','Ventspils Creative House Planetarium and Observatory','Ventspils City Government','2026-10-02','visitor attraction','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000053,4280004,'Ventspils South Pier','Ventspils South Pier','Ventspils City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000054,4280004,'Ventspils Children’s Town','Ventspils Children’s Town','Ventspils City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000055,4280004,'Reņķa Garden','Reņķa Garden','Ventspils City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000056,4280004,'Lemberga Hūte Ski Hill','Lemberga Hūte Ski Hill','Ventspils City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Ventspils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000057,4280005,'Daugavpils Fortress','Daugavpils Fortress','Daugavpils City Government','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000058,4280005,'Rothko Museum','Rothko Museum','Daugavpils City Government','2026-10-02','museum','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000059,4280005,'Church Hill','Church Hill','Daugavpils City Government','2026-10-02','religious site','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000060,4280005,'Latgale Zoo','Latgale Zoo','Daugavpils City Government','2026-10-02','visitor attraction','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000061,4280005,'Šmakovka Museum','Šmakovka Museum','Daugavpils City Government','2026-10-02','museum','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000062,4280005,'Unity House','Unity House','Daugavpils City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000063,4280005,'Dubrovina Park','Dubrovina Park','Daugavpils City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000064,4280005,'Daugavpils Lead Shot Factory','Daugavpils Lead Shot Factory','Daugavpils City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000065,4280005,'Daugavpils Regional and Art Museum','Daugavpils Regional and Art Museum','Daugavpils City Government','2026-10-02','museum','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000066,4280005,'Saints Boris and Gleb Cathedral','Saints Boris and Gleb Cathedral','Daugavpils City Government','2026-10-02','religious site','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000067,4280005,'Daugavpils Synagogue','Daugavpils Synagogue','Daugavpils City Government','2026-10-02','religious site','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000068,4280005,'Nikolai Gate of Daugavpils Fortress','Nikolai Gate of Daugavpils Fortress','Daugavpils City Government','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Visit Daugavpils','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000069,4280006,'Embassy of Latgale GORS','Embassy of Latgale GORS','Rēzekne City Government','2026-10-02','cultural venue','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000070,4280006,'Latgale Culture and History Museum','Latgale Culture and History Museum','Rēzekne City Government','2026-10-02','museum','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000071,4280006,'Rēzekne Castle Hill','Rēzekne Castle Hill','Rēzekne City Government','2026-10-02','castle or fortress','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000072,4280006,'Latgale Liberation Monument','Latgale Liberation Monument','Rēzekne City Government','2026-10-02','landmark','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000073,4280006,'Eastern Latvia Creative Services Centre Zeimuļs','Eastern Latvia Creative Services Centre Zeimuļs','Rēzekne City Government','2026-10-02','landmark','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000074,4280006,'Rēzekne Green Synagogue','Rēzekne Green Synagogue','Rēzekne City Government','2026-10-02','religious site','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000075,4280006,'Rēzekne House of Art','Rēzekne House of Art','Rēzekne City Government','2026-10-02','museum','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000076,4280006,'Rēzekne Cathedral of the Sacred Heart of Jesus','Rēzekne Cathedral of the Sacred Heart of Jesus','Rēzekne City Government','2026-10-02','religious site','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000077,4280006,'Olympic Centre Rēzekne','Olympic Centre Rēzekne','Rēzekne City Government','2026-10-02','landmark','Latvia Travel official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000078,4280007,'Jelgava Holy Trinity Church Tower','Jelgava Holy Trinity Church Tower','Jelgava City Government','2026-10-02','religious site','Latvia Travel official tourism portal / Jelgava Regional Tourism Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000079,4280007,'Jelgava Palace','Jelgava Palace','Jelgava City Government','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Jelgava Regional Tourism Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000080,4280007,'Vault of the Dukes of Courland','Vault of the Dukes of Courland','Jelgava City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Jelgava Regional Tourism Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000081,4280007,'Ģederts Eliass Jelgava History and Art Museum','Ģederts Eliass Jelgava History and Art Museum','Jelgava City Government','2026-10-02','museum','Latvia Travel official tourism portal / Jelgava Regional Tourism Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000082,4280007,'Ādolfs Alunāns Memorial Museum','Ādolfs Alunāns Memorial Museum','Jelgava City Government','2026-10-02','museum','Latvia Travel official tourism portal / Jelgava Regional Tourism Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000083,4280007,'Lielupe Floodplain Meadows','Lielupe Floodplain Meadows','Jelgava City Government','2026-10-02','nature site','Latvia Travel official tourism portal / Jelgava Regional Tourism Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000084,4280007,'Jelgava Old Town House','Jelgava Old Town House','Jelgava City Government','2026-10-02','historic urban area','Latvia Travel official tourism portal / Jelgava Regional Tourism Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000085,4280007,'Vecpilsētas Street Quarter','Vecpilsētas Street Quarter','Jelgava City Government','2026-10-02','historic urban area','Latvia Travel official tourism portal / Jelgava Regional Tourism Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000086,4280007,'Monument to Jānis Čakste','Monument to Jānis Čakste','Jelgava City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Jelgava Regional Tourism Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000087,4280007,'Pasta Island','Pasta Island','Jelgava City Government','2026-10-02','landmark','Latvia Travel official tourism portal / Jelgava Regional Tourism Centre','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000088,4280008,'Sigulda Medieval Castle','Sigulda Medieval Castle','Sigulda municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000089,4280008,'Sigulda New Castle and Castle Quarter','Sigulda New Castle and Castle Quarter','Sigulda municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000090,4280008,'Turaida Museum Reserve','Turaida Museum Reserve','Sigulda municipality','2026-10-02','museum','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000091,4280008,'Turaida Castle','Turaida Castle','Sigulda municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000092,4280008,'Gutman’s Cave','Gutman’s Cave','Sigulda municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000093,4280008,'Krimulda Manor','Krimulda Manor','Sigulda municipality','2026-10-02','landmark','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000094,4280008,'Cable Car over Gauja River','Cable Car over Gauja River','Sigulda municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000095,4280008,'Sigulda Bobsleigh and Luge Track','Sigulda Bobsleigh and Luge Track','Sigulda municipality','2026-10-02','visitor attraction','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000096,4280008,'Paradise Hill – Painter’s Hill','Paradise Hill – Painter’s Hill','Sigulda municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000097,4280008,'Gauja National Park','Gauja National Park','Sigulda municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000098,4280008,'Tarzāns Outdoor Adventure Park','Tarzāns Outdoor Adventure Park','Sigulda municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000099,4280008,'Aerodium','Aerodium','Sigulda municipality','2026-10-02','landmark','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000100,4280008,'Fischer Cross-Country Ski Centre','Fischer Cross-Country Ski Centre','Sigulda municipality','2026-10-02','visitor attraction','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000101,4280008,'Culture Centre Siguldas Devons','Culture Centre Siguldas Devons','Sigulda municipality','2026-10-02','cultural venue','Latvia Travel official tourism portal / Sigulda official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000102,4280009,'Cēsis Medieval Castle','Cēsis Medieval Castle','Cēsis municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Cēsis official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000103,4280009,'Cēsis New Castle','Cēsis New Castle','Cēsis municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Cēsis official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000104,4280009,'Cēsis Castle Park','Cēsis Castle Park','Cēsis municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Cēsis official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000105,4280009,'Cēsis Old Town','Cēsis Old Town','Cēsis municipality','2026-10-02','historic urban area','Latvia Travel official tourism portal / Cēsis official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000106,4280009,'St John’s Church in Cēsis','St John’s Church in Cēsis','Cēsis municipality','2026-10-02','religious site','Latvia Travel official tourism portal / Cēsis official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000107,4280009,'Cēsis History and Art Museum','Cēsis History and Art Museum','Cēsis municipality','2026-10-02','museum','Latvia Travel official tourism portal / Cēsis official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000108,4280009,'Cīrulīši Nature Trails','Cīrulīši Nature Trails','Cēsis municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Cēsis official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000109,4280009,'Āraiši Lake Castle Archaeological Park','Āraiši Lake Castle Archaeological Park','Cēsis municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Cēsis official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000110,4280009,'Rose Square in Cēsis','Rose Square in Cēsis','Cēsis municipality','2026-10-02','historic urban area','Latvia Travel official tourism portal / Cēsis official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000111,4280009,'Unity Square in Cēsis','Unity Square in Cēsis','Cēsis municipality','2026-10-02','historic urban area','Latvia Travel official tourism portal / Cēsis official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000112,4280010,'Historical Centre of Kuldīga','Historical Centre of Kuldīga','Kuldīga municipality','2026-10-02','historic urban area','Latvia Travel official tourism portal / Visit Kuldīga','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000113,4280010,'Venta Waterfall','Venta Waterfall','Kuldīga municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Kuldīga','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000114,4280010,'Kuldīga Old Brick Bridge','Kuldīga Old Brick Bridge','Kuldīga municipality','2026-10-02','landmark','Latvia Travel official tourism portal / Visit Kuldīga','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000115,4280010,'Kuldīga District Museum','Kuldīga District Museum','Kuldīga municipality','2026-10-02','museum','Latvia Travel official tourism portal / Visit Kuldīga','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000116,4280010,'Live Museum “The Story of Ancient Kuldīga”','Live Museum “The Story of Ancient Kuldīga”','Kuldīga municipality','2026-10-02','museum','Latvia Travel official tourism portal / Visit Kuldīga','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000117,4280010,'Alekšupīte Waterfall','Alekšupīte Waterfall','Kuldīga municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Kuldīga','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000118,4280010,'Kuldīga Town Garden','Kuldīga Town Garden','Kuldīga municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Kuldīga','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000119,4280010,'St Catherine’s Church in Kuldīga','St Catherine’s Church in Kuldīga','Kuldīga municipality','2026-10-02','religious site','Latvia Travel official tourism portal / Visit Kuldīga','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000120,4280010,'Liepāja Street Promenade','Liepāja Street Promenade','Kuldīga municipality','2026-10-02','historic urban area','Latvia Travel official tourism portal / Visit Kuldīga','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000121,4280010,'Mārtiņsala Bathing Area','Mārtiņsala Bathing Area','Kuldīga municipality','2026-10-02','landmark','Latvia Travel official tourism portal / Visit Kuldīga','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000122,4280011,'Bauska Castle','Bauska Castle','Bauska municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Bauska official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000123,4280011,'Bauska Museum','Bauska Museum','Bauska municipality','2026-10-02','museum','Latvia Travel official tourism portal / Bauska official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000124,4280011,'Bauska Town Hall','Bauska Town Hall','Bauska municipality','2026-10-02','landmark','Latvia Travel official tourism portal / Bauska official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000125,4280011,'Bauska Church of the Holy Spirit','Bauska Church of the Holy Spirit','Bauska municipality','2026-10-02','religious site','Latvia Travel official tourism portal / Bauska official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000126,4280011,'Rundāle Palace and Museum','Rundāle Palace and Museum','Bauska municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Bauska official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000127,4280011,'Rundāle Palace French Garden','Rundāle Palace French Garden','Bauska municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Bauska official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000128,4280011,'Mežotne Palace','Mežotne Palace','Bauska municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Bauska official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000129,4280011,'Bauska Nature Park','Bauska Nature Park','Bauska municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Bauska official tourism portal','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000130,4280012,'Valmiera St Simon’s Church','Valmiera St Simon’s Church','Valmiera municipality','2026-10-02','religious site','Latvia Travel official tourism portal / Visit Valmiera','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000131,4280012,'Valmiera Livonian Order Castle Ruins','Valmiera Livonian Order Castle Ruins','Valmiera municipality','2026-10-02','castle or fortress','Latvia Travel official tourism portal / Visit Valmiera','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000132,4280012,'Valmiera Museum','Valmiera Museum','Valmiera municipality','2026-10-02','museum','Latvia Travel official tourism portal / Visit Valmiera','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000133,4280012,'Park of Senses','Park of Senses','Valmiera municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Valmiera','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000134,4280012,'Valmiera Old Town','Valmiera Old Town','Valmiera municipality','2026-10-02','historic urban area','Latvia Travel official tourism portal / Visit Valmiera','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000135,4280012,'Gauja River Walking Trails in Valmiera','Gauja River Walking Trails in Valmiera','Valmiera municipality','2026-10-02','nature site','Latvia Travel official tourism portal / Visit Valmiera','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000136,4280012,'Valmiera Drama Theatre','Valmiera Drama Theatre','Valmiera municipality','2026-10-02','cultural venue','Latvia Travel official tourism portal / Visit Valmiera','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02'),
(428000137,4280012,'Valmiermuiža Brewery','Valmiermuiža Brewery','Valmiera municipality','2026-10-02','landmark','Latvia Travel official tourism portal / Visit Valmiera','2026-10-02','partial','Official tourism identity checked; live/provider metadata not fetched.','2026-10-02');

INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES
(428000001,428000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000002,428000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000003,428000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000004,428000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000005,428000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000006,428000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000007,428000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000008,428000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000009,428000009,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000010,428000010,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000011,428000011,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000012,428000012,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000013,428000013,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000014,428000014,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000015,428000015,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000016,428000016,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000017,428000017,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000018,428000018,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000019,428000019,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000020,428000020,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000021,428000021,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000022,428000022,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000023,428000023,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000024,428000024,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000025,428000025,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000026,428000026,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000027,428000027,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000028,428000028,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000029,428000029,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000030,428000030,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000031,428000031,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000032,428000032,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000033,428000033,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000034,428000034,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000035,428000035,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000036,428000036,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000037,428000037,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000038,428000038,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000039,428000039,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000040,428000040,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000041,428000041,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000042,428000042,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000043,428000043,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000044,428000044,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000045,428000045,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000046,428000046,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000047,428000047,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000048,428000048,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000049,428000049,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000050,428000050,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000051,428000051,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000052,428000052,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000053,428000053,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000054,428000054,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000055,428000055,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000056,428000056,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000057,428000057,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000058,428000058,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000059,428000059,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000060,428000060,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000061,428000061,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000062,428000062,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000063,428000063,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000064,428000064,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000065,428000065,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000066,428000066,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000067,428000067,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000068,428000068,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000069,428000069,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000070,428000070,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000071,428000071,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000072,428000072,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000073,428000073,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000074,428000074,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000075,428000075,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000076,428000076,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000077,428000077,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000078,428000078,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000079,428000079,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000080,428000080,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000081,428000081,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000082,428000082,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000083,428000083,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000084,428000084,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000085,428000085,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000086,428000086,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000087,428000087,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000088,428000088,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000089,428000089,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000090,428000090,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000091,428000091,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000092,428000092,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000093,428000093,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000094,428000094,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000095,428000095,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000096,428000096,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000097,428000097,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000098,428000098,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000099,428000099,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000100,428000100,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000101,428000101,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000102,428000102,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000103,428000103,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000104,428000104,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000105,428000105,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000106,428000106,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000107,428000107,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000108,428000108,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000109,428000109,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000110,428000110,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000111,428000111,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000112,428000112,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000113,428000113,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000114,428000114,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000115,428000115,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000116,428000116,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000117,428000117,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000118,428000118,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000119,428000119,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000120,428000120,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000121,428000121,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000122,428000122,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000123,428000123,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000124,428000124,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000125,428000125,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000126,428000126,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000127,428000127,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000128,428000128,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000129,428000129,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000130,428000130,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000131,428000131,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000132,428000132,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000133,428000133,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000134,428000134,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000135,428000135,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000136,428000136,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.'),
(428000137,428000137,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact hours require official/operator/provider refresh.');

INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES
(428000001,428000001,'Old Town Riga','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000002,428000002,'Riga Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000003,428000003,'House of the Black Heads','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000004,428000004,'Riga Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000005,428000005,'St Peter’s Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000006,428000006,'Three Brothers','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000007,428000007,'Swedish Gate','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000008,428000008,'Powder Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000009,428000009,'Freedom Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000010,428000010,'Latvian National Opera','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000011,428000011,'Riga Central Market','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000012,428000012,'Latvian National Museum of Art','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000013,428000013,'Alberta Street Art Nouveau District','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000014,428000014,'Riga Motor Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000015,428000015,'Latvian Ethnographic Open-Air Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000016,428000016,'National Library of Latvia','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000017,428000017,'Bastejkalna Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000018,428000018,'Riga Ghetto and Latvian Holocaust Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000019,428000019,'Majori Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000020,428000020,'Jomas Street','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000021,428000021,'Dzintari Concert Hall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000022,428000022,'Jūrmala Open Air Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000023,428000023,'Ragakāpa Nature Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000024,428000024,'Great Ķemeri Bog Boardwalk','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000025,428000025,'Ķemeri National Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000026,428000026,'Līvu Aquapark','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000027,428000027,'Dzintari Forest Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000028,428000028,'Jūrmala City Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000029,428000029,'Ķemeri Water Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000030,428000030,'Dubulti Art Station','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000031,428000031,'Liepāja Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000032,428000032,'Liepāja Seaside Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000033,428000033,'Karosta','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000034,428000034,'Karosta Prison','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000035,428000035,'St Nicholas Orthodox Naval Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000036,428000036,'Northern Forts','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000037,428000037,'North Pier','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000038,428000038,'Great Amber Concert Hall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000039,428000039,'Liepāja Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000040,428000040,'Holy Trinity Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000041,428000041,'Peter’s Market','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000042,428000042,'Rose Square','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000043,428000043,'Liepāja Theatre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000044,428000044,'Latvian Musicians’ Walk of Fame','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000045,428000045,'Ventspils Livonian Order Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000046,428000046,'Seaside Open-Air Museum in Ventspils','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000047,428000047,'Ventspils Beach','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000048,428000048,'Ostas Street Promenade','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000049,428000049,'Adventure Park of Ventspils','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000050,428000050,'Ventspils Water Amusement Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000051,428000051,'Science Centre VIZIUM','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000052,428000052,'Ventspils Creative House Planetarium and Observatory','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000053,428000053,'Ventspils South Pier','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000054,428000054,'Ventspils Children’s Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000055,428000055,'Reņķa Garden','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000056,428000056,'Lemberga Hūte Ski Hill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000057,428000057,'Daugavpils Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000058,428000058,'Rothko Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000059,428000059,'Church Hill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000060,428000060,'Latgale Zoo','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000061,428000061,'Šmakovka Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000062,428000062,'Unity House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000063,428000063,'Dubrovina Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000064,428000064,'Daugavpils Lead Shot Factory','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000065,428000065,'Daugavpils Regional and Art Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000066,428000066,'Saints Boris and Gleb Cathedral','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000067,428000067,'Daugavpils Synagogue','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000068,428000068,'Nikolai Gate of Daugavpils Fortress','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000069,428000069,'Embassy of Latgale GORS','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000070,428000070,'Latgale Culture and History Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000071,428000071,'Rēzekne Castle Hill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000072,428000072,'Latgale Liberation Monument','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000073,428000073,'Eastern Latvia Creative Services Centre Zeimuļs','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000074,428000074,'Rēzekne Green Synagogue','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000075,428000075,'Rēzekne House of Art','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000076,428000076,'Rēzekne Cathedral of the Sacred Heart of Jesus','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000077,428000077,'Olympic Centre Rēzekne','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000078,428000078,'Jelgava Holy Trinity Church Tower','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000079,428000079,'Jelgava Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000080,428000080,'Vault of the Dukes of Courland','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000081,428000081,'Ģederts Eliass Jelgava History and Art Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000082,428000082,'Ādolfs Alunāns Memorial Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000083,428000083,'Lielupe Floodplain Meadows','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000084,428000084,'Jelgava Old Town House','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000085,428000085,'Vecpilsētas Street Quarter','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000086,428000086,'Monument to Jānis Čakste','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000087,428000087,'Pasta Island','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000088,428000088,'Sigulda Medieval Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000089,428000089,'Sigulda New Castle and Castle Quarter','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000090,428000090,'Turaida Museum Reserve','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000091,428000091,'Turaida Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000092,428000092,'Gutman’s Cave','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000093,428000093,'Krimulda Manor','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000094,428000094,'Cable Car over Gauja River','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000095,428000095,'Sigulda Bobsleigh and Luge Track','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000096,428000096,'Paradise Hill – Painter’s Hill','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000097,428000097,'Gauja National Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000098,428000098,'Tarzāns Outdoor Adventure Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000099,428000099,'Aerodium','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000100,428000100,'Fischer Cross-Country Ski Centre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000101,428000101,'Culture Centre Siguldas Devons','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000102,428000102,'Cēsis Medieval Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000103,428000103,'Cēsis New Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000104,428000104,'Cēsis Castle Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000105,428000105,'Cēsis Old Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000106,428000106,'St John’s Church in Cēsis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000107,428000107,'Cēsis History and Art Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000108,428000108,'Cīrulīši Nature Trails','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000109,428000109,'Āraiši Lake Castle Archaeological Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000110,428000110,'Rose Square in Cēsis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000111,428000111,'Unity Square in Cēsis','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000112,428000112,'Historical Centre of Kuldīga','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000113,428000113,'Venta Waterfall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000114,428000114,'Kuldīga Old Brick Bridge','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000115,428000115,'Kuldīga District Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000116,428000116,'Live Museum “The Story of Ancient Kuldīga”','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000117,428000117,'Alekšupīte Waterfall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000118,428000118,'Kuldīga Town Garden','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000119,428000119,'St Catherine’s Church in Kuldīga','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000120,428000120,'Liepāja Street Promenade','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000121,428000121,'Mārtiņsala Bathing Area','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000122,428000122,'Bauska Castle','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000123,428000123,'Bauska Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000124,428000124,'Bauska Town Hall','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000125,428000125,'Bauska Church of the Holy Spirit','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000126,428000126,'Rundāle Palace and Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000127,428000127,'Rundāle Palace French Garden','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000128,428000128,'Mežotne Palace','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000129,428000129,'Bauska Nature Park','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000130,428000130,'Valmiera St Simon’s Church','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000131,428000131,'Valmiera Livonian Order Castle Ruins','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000132,428000132,'Valmiera Museum','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000133,428000133,'Park of Senses','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000134,428000134,'Valmiera Old Town','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000135,428000135,'Gauja River Walking Trails in Valmiera','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000136,428000136,'Valmiera Drama Theatre','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match'),
(428000137,428000137,'Valmiermuiža Brewery','no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

-- Every place gets at least one meaningful tag; mappings use tag names to avoid assuming tag IDs.

INSERT INTO place_tags (place_id,tag_id) SELECT 428000001,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000002,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000003,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000004,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000005,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000006,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000007,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000008,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000009,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000010,id FROM tags WHERE tag_name IN ('Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000011,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000012,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000013,id FROM tags WHERE tag_name IN ('Heritage','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000014,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000015,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000016,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000017,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000018,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000019,id FROM tags WHERE tag_name IN ('Nature','Beach');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000020,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000021,id FROM tags WHERE tag_name IN ('Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000022,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000023,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000024,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000025,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000026,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000027,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000028,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000029,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000030,id FROM tags WHERE tag_name IN ('Landmark','Heritage','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000031,id FROM tags WHERE tag_name IN ('Nature','Beach');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000032,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000033,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000034,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000035,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000036,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000037,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000038,id FROM tags WHERE tag_name IN ('Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000039,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000040,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000041,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000042,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000043,id FROM tags WHERE tag_name IN ('Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000044,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000045,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000046,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000047,id FROM tags WHERE tag_name IN ('Nature','Beach');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000048,id FROM tags WHERE tag_name IN ('Heritage','Culture','Waterfront');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000049,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000050,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000051,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000052,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000053,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000054,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000055,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000056,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000057,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000058,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000059,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000060,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000061,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000062,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000063,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000064,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000065,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000066,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000067,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000068,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000069,id FROM tags WHERE tag_name IN ('Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000070,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000071,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000072,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000073,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000074,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000075,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000076,id FROM tags WHERE tag_name IN ('Religious','Heritage','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000077,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000078,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000079,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000080,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000081,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000082,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000083,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000084,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000085,id FROM tags WHERE tag_name IN ('Heritage','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000086,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000087,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000088,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000089,id FROM tags WHERE tag_name IN ('Fortress','Heritage','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000090,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000091,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000092,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000093,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000094,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000095,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000096,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000097,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000098,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000099,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000100,id FROM tags WHERE tag_name IN ('Activity','Family');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000101,id FROM tags WHERE tag_name IN ('Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000102,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000103,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000104,id FROM tags WHERE tag_name IN ('Fortress','Heritage','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000105,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000106,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000107,id FROM tags WHERE tag_name IN ('Museum','Culture','Art');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000108,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000109,id FROM tags WHERE tag_name IN ('Fortress','Heritage','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000110,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000111,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000112,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000113,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000114,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000115,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000116,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000117,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000118,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000119,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000120,id FROM tags WHERE tag_name IN ('Heritage','Culture','Waterfront');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000121,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000122,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000123,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000124,id FROM tags WHERE tag_name IN ('Landmark','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000125,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000126,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000127,id FROM tags WHERE tag_name IN ('Fortress','Heritage','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000128,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000129,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000130,id FROM tags WHERE tag_name IN ('Religious','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000131,id FROM tags WHERE tag_name IN ('Fortress','Heritage');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000132,id FROM tags WHERE tag_name IN ('Museum','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000133,id FROM tags WHERE tag_name IN ('Nature','Park');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000134,id FROM tags WHERE tag_name IN ('Heritage','Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000135,id FROM tags WHERE tag_name IN ('Nature');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000136,id FROM tags WHERE tag_name IN ('Culture');
INSERT INTO place_tags (place_id,tag_id) SELECT 428000137,id FROM tags WHERE tag_name IN ('Landmark','Heritage');

COMMIT;
