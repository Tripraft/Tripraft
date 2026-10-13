-- ============================================================================
-- TripRaft canonical seed schema v2 — CREATE TABLE + indexes
-- Faithful to the REAL repo DB schema (real_db_copy.db, inspected 2026-09-30,
-- re-verified 2026-10-07). Country-agnostic: works for every country/place.
--
-- Usage (fresh scratch DB for seed validation):
--   sqlite3 fresh.db < tripraft-canonical-schema.sql
--   sqlite3 fresh.db < <country>-seed.sql
--
-- Design notes:
-- * Section 1 reproduces the real schema exactly (columns, types, UNIQUEs,
--   FKs, AUTOINCREMENT, defaults).
-- * Section 2 ("PROPOSED EXTENSIONS") adds every column/table we might want
--   but that does NOT exist in the prod repo DB yet. It runs as real ALTERs
--   so you get a full superset DB to decide against — keep what earns its
--   place, delete the rest. WARNING: seed files using Section 2 columns will
--   NOT import into the current prod DB until this migration runs there.
-- * QA rules from the pipeline (checks C-R) are enforced as VALIDATION
--   QUERIES in section 3 below, not as DDL. CREATE TABLE IF NOT EXISTS is a
--   no-op against an existing DB, so DDL constraints can never "fail fast"
--   on the real target — the queries can.
-- * Seed files may use explicit IDs (AUTOINCREMENT tolerates them).
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ----------------------------------------------------------------------------
-- Section 1: tables + indexes (faithful to real DB)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS countries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS states (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_id INTEGER NOT NULL REFERENCES countries(id),
    state_name TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(country_id, state_name)
);

CREATE TABLE IF NOT EXISTS cities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES states(id),
    city_name TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(state_id, city_name)
);

CREATE TABLE IF NOT EXISTS places (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    city_id INTEGER NOT NULL REFERENCES cities(id),
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
    rating_tourist_priority INTEGER,
    rating_traveler_experience INTEGER,
    latitude REAL,
    longitude REAL,
    address TEXT,
    official_website TEXT,
    rank_score REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS opening_hours (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id INTEGER NOT NULL REFERENCES places(id),
    monday TEXT,
    tuesday TEXT,
    wednesday TEXT,
    thursday TEXT,
    friday TEXT,
    saturday TEXT,
    sunday TEXT,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS photos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id INTEGER NOT NULL REFERENCES places(id),
    source_file TEXT,
    thumbnail_url TEXT,
    thumbnail_width INTEGER,
    thumbnail_height INTEGER,
    photo_title TEXT,
    photo_author TEXT,
    license TEXT,
    license_url TEXT,
    source_url TEXT,
    credit TEXT,
    usage_terms TEXT,
    description TEXT
);

CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tag_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS place_tags (
    place_id INTEGER NOT NULL REFERENCES places(id),
    tag_id INTEGER NOT NULL REFERENCES tags(id),
    PRIMARY KEY (place_id, tag_id)
);

CREATE TABLE IF NOT EXISTS restaurants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    city_id INTEGER NOT NULL REFERENCES cities(id),
    restaurant_name TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS airports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    city_id INTEGER NOT NULL REFERENCES cities(id),
    airport_name TEXT,
    latitude REAL,
    longitude REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Provenance / verification notes live HERE, not on places.
-- source is constrained: 'api' | 'cli' | 'bulk'.
CREATE TABLE IF NOT EXISTS ingestion_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL
        CHECK(entity_type IN ('place','country','state','city','photo','tag','opening_hours')),
    entity_id INTEGER,
    action TEXT NOT NULL CHECK(action IN ('insert','update','delete')),
    source TEXT NOT NULL CHECK(source IN ('api','cli','bulk')),
    data_hash TEXT,
    errors TEXT,
    ingested_by TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

-- Full-text search over places (FTS5). Shadow tables (places_fts_data/_idx/_docsize/_config)
-- are auto-created by SQLite; never seed them directly. Rebuild after bulk import with:
--   INSERT INTO places_fts(places_fts) VALUES('rebuild');
CREATE VIRTUAL TABLE IF NOT EXISTS places_fts USING fts5(
    place_name,
    name_english,
    city_name,
    state_name,
    country_name,
    content='',
    tokenize='unicode61 remove_diacritics 2'
);

-- Indexes (faithful to real DB)
CREATE INDEX IF NOT EXISTS idx_states_country    ON states(country_id);
CREATE INDEX IF NOT EXISTS idx_cities_state      ON cities(state_id);
CREATE INDEX IF NOT EXISTS idx_cities_state_id   ON cities(state_id);
CREATE INDEX IF NOT EXISTS idx_places_city       ON places(city_id);
CREATE INDEX IF NOT EXISTS idx_places_name       ON places(place_name);
CREATE INDEX IF NOT EXISTS idx_places_city_rank  ON places(city_id, rank_score DESC);
CREATE INDEX IF NOT EXISTS idx_places_cost       ON places(cost);
CREATE INDEX IF NOT EXISTS idx_places_rating     ON places(rating_tourist_priority);
CREATE INDEX IF NOT EXISTS idx_restaurants_city  ON restaurants(city_id);
CREATE INDEX IF NOT EXISTS idx_airports_city     ON airports(city_id);
CREATE INDEX IF NOT EXISTS idx_opening_hours_place ON opening_hours(place_id);
CREATE INDEX IF NOT EXISTS idx_photos_place     ON photos(place_id);
CREATE INDEX IF NOT EXISTS idx_place_tags_place ON place_tags(place_id);
CREATE INDEX IF NOT EXISTS idx_place_tags_tag   ON place_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_countries_name_lower ON countries(country_name COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_states_name_lower    ON states(state_name COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_cities_name_lower    ON cities(city_name COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_places_name_lower    ON places(place_name COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_ingestion_log_entity  ON ingestion_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_ingestion_log_created ON ingestion_log(created_at);
CREATE INDEX IF NOT EXISTS idx_ingestion_log_action  ON ingestion_log(action);

-- ----------------------------------------------------------------------------
-- Section 2: PROPOSED EXTENSIONS (NOT in the prod repo DB — decide later)
-- ----------------------------------------------------------------------------
-- Everything below is a genuine proposal: it runs, so you can build the
-- superset DB and evaluate each column against real seed data. Keep what
-- earns its place; delete the rest. Until this migration runs on prod,
-- seed files must NOT reference these columns (they will fail to import).
--
-- SQLite cannot ADD CONSTRAINT via ALTER TABLE, so intended CHECK/UNIQUE
-- rules are documented in comments and enforced by the QA queries in
-- section 3 (Q1/Q2 cover the one-row-per-place rules).

-- QA F: reserved for future provider integration. Keep NULL until then —
-- the pipeline's no-provider-data rule still applies.
ALTER TABLE places ADD COLUMN google_place_id TEXT;

-- Discovery / filtering attributes (restaurant-ish data currently has no home;
-- the real restaurants table is id/city_id/name/lat/lng only).
ALTER TABLE places ADD COLUMN category TEXT;    -- e.g. 'temple','museum','restaurant'
ALTER TABLE places ADD COLUMN cuisine TEXT;     -- e.g. 'gujarati','south-indian'
ALTER TABLE places ADD COLUMN price_band TEXT;  -- intended: 'budget'|'mid'|'luxury'
ALTER TABLE places ADD COLUMN veg_flag TEXT;    -- intended: 'veg'|'non-veg'|'veg-options'

-- QA L: provenance per row. Intended rule: must be non-blank when the
-- column is in use (enforced by QA query, not DDL).
ALTER TABLE places ADD COLUMN source TEXT;
ALTER TABLE places ADD COLUMN updated_at TEXT;

-- QA G: verification workflow. Intended: CHECK IN ('verified','partial'),
-- DEFAULT 'partial'. (SQLite ADD COLUMN cannot add the CHECK; enforce via QA.)
ALTER TABLE places ADD COLUMN verification_status TEXT;
ALTER TABLE places ADD COLUMN verification_notes TEXT;
ALTER TABLE places ADD COLUMN verified_at TEXT;

-- Photos: richer attribution than the real table carries.
ALTER TABLE photos ADD COLUMN photo_url TEXT;
ALTER TABLE photos ADD COLUMN photo_license TEXT;
ALTER TABLE photos ADD COLUMN photo_source_url TEXT;
ALTER TABLE photos ADD COLUMN photo_status TEXT;

-- QA O: festivals. The real DB has no festivals table; the pipeline
-- intentionally omits weak festival rows rather than padding them.
-- Month is approximate by design — never invent exact dates.
CREATE TABLE IF NOT EXISTS festivals (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id      INTEGER REFERENCES places(id),
    city_id       INTEGER REFERENCES cities(id),
    festival_name TEXT NOT NULL,
    month_label   TEXT,
    notes         TEXT,
    source        TEXT,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (place_id IS NOT NULL OR city_id IS NOT NULL)
);

-- ----------------------------------------------------------------------------
-- Section 3: QA validation queries (run after importing a seed file;
-- every query below must return ZERO rows for the seed to pass)
--
-- Mapping to pipeline QA checks:
--   QA J (one opening-hours row per place)  -> Q1
--   QA K (one photo row per place)           -> Q2
--   QA N (no-photo rows: URLs must be NULL)  -> Q3
--   Pipeline hard rules (coords, names)      -> Q4-Q7
--   Referential integrity                   -> Q8-Q10
--   Coverage sanity                         -> Q11-Q12
--   Proposed-column checks (only meaningful after the Section 2
--   migration; skip them against the current prod DB):
--     QA F (google_place_id stays NULL)      -> Q14
--     QA G (verification_status in range)    -> Q15
--     QA L (source non-blank, where used)    -> Q16
--     QA O (festival rows well-formed)       -> Q17
-- ----------------------------------------------------------------------------

-- Q1: places with more than one opening_hours row (QA J)
-- SELECT place_id, COUNT(*) AS c FROM opening_hours GROUP BY place_id HAVING c > 1;

-- Q2: places with more than one photos row (QA K)
-- SELECT place_id, COUNT(*) AS c FROM photos GROUP BY place_id HAVING c > 1;

-- Q3: no-photo rows carrying URLs (QA N)
-- SELECT id, place_id FROM photos
--  WHERE usage_terms = 'no-photo-available'
--    AND (thumbnail_url IS NOT NULL OR source_url IS NOT NULL);

-- Q4: places missing coordinates (pipeline hard rule: coords within ~1km)
-- SELECT id, place_name FROM places WHERE latitude IS NULL OR longitude IS NULL;

-- Q5: places with blank names
-- SELECT id FROM places WHERE place_name IS NULL OR TRIM(place_name) = '';

-- Q6: cities missing coordinates
-- SELECT id, city_name FROM cities WHERE latitude IS NULL OR longitude IS NULL;

-- Q7: duplicate place names inside one city (real DB has no UNIQUE here; flag it)
-- SELECT city_id, LOWER(TRIM(place_name)) AS n, COUNT(*) AS c
--  FROM places GROUP BY city_id, n HAVING c > 1;

-- Q8: orphan places (city_id not in cities)
-- SELECT p.id FROM places p LEFT JOIN cities c ON c.id = p.city_id WHERE c.id IS NULL;

-- Q9: orphan cities (state_id not in states)
-- SELECT c.id FROM cities c LEFT JOIN states s ON s.id = c.state_id WHERE s.id IS NULL;

-- Q10: orphan states (country_id not in countries)
-- SELECT s.id FROM states s LEFT JOIN countries co ON co.id = s.country_id WHERE co.id IS NULL;

-- Q11: cities with zero places (coverage gap)
-- SELECT c.id, c.city_name FROM cities c
--  LEFT JOIN places p ON p.city_id = c.id WHERE p.id IS NULL;

-- Q12: places with zero tags
-- SELECT p.id, p.place_name FROM places p
--  LEFT JOIN place_tags pt ON pt.place_id = p.id WHERE pt.place_id IS NULL;

-- Q13: ingestion_log rows carrying errors (verification failures to triage)
-- SELECT id, entity_type, entity_id, errors FROM ingestion_log
--  WHERE errors IS NOT NULL AND TRIM(errors) <> '';

-- --- Proposed-column checks: run only on DBs built WITH the Section 2
-- --- migration. Skip against the current prod DB (columns don't exist there).

-- Q14: google_place_id must stay NULL until provider integration (QA F)
-- SELECT id FROM places WHERE google_place_id IS NOT NULL;

-- Q15: verification_status outside the allowed range (QA G)
-- SELECT id, verification_status FROM places
--  WHERE verification_status IS NOT NULL
--    AND verification_status NOT IN ('verified','partial');

-- Q16: source column in use but blank (QA L)
-- SELECT id FROM places
--  WHERE source IS NOT NULL AND TRIM(source) = '';

-- Q17: festival rows with neither place nor city, or blank names (QA O)
-- SELECT id FROM festivals
--  WHERE (place_id IS NULL AND city_id IS NULL)
--     OR festival_name IS NULL OR TRIM(festival_name) = '';
