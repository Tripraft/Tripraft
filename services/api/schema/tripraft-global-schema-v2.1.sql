-- Purpose: Defines the maintained empty canonical discovery schema for native and container startup.
-- TripRaft Global Travel Database — Enhanced SQLite Schema v2.1
-- SCHEMA ONLY: no user, country, place, airport or fabricated records.
-- Backward compatible with legacy Afghanistan seed INSERT column lists.
-- Intended for fresh databases; NOT a drop-in ALTER migration for existing DBs.
-- Requires SQLite with FTS5 and JSON1 support. Test on an isolated copy first.
-- Development validation is not production certification.
-- Date generated: 2026-10-07

-- ============================================================================
-- TripRaft PRODUCTION schema — one file for all countries and all data.
-- Covers: geography hierarchy, places, hours, photos, tags, festivals,
--         airports, verification tracking, change log, batch registry,
--         AI search (full-text search, embeddings, demand log).
--
-- Usage:
--   sqlite3 tripraft.db < tripraft-production-schema.sql
-- Then import per-country seed files. CHECK / UNIQUE constraints below
-- enforce the QA rules at the database level: bad rows fail fast instead
-- of silently corrupting the dataset.
--
-- NOTE (SQLite): PRAGMA foreign_keys is per-connection. Every application
-- connection MUST run `PRAGMA foreign_keys = ON;` after opening the DB.
-- ============================================================================

PRAGMA foreign_keys = ON;

-- --------------------------------------------------------------------------
-- Core geography
-- --------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS countries (
    id           INTEGER PRIMARY KEY,
    country_name TEXT NOT NULL,
    created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now')),
    iso2 TEXT UNIQUE CHECK (iso2 IS NULL OR (length(iso2)=2 AND iso2=upper(iso2))),
    iso3 TEXT UNIQUE CHECK (iso3 IS NULL OR (length(iso3)=3 AND iso3=upper(iso3))),
    iso_numeric TEXT UNIQUE, currency_code TEXT, calling_code TEXT,
    capital TEXT, region TEXT, updated_at TEXT, retired_at TEXT,
    UNIQUE (country_name)
);

CREATE TABLE IF NOT EXISTS states (
    id          INTEGER PRIMARY KEY,
    country_id  INTEGER NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
    state_name  TEXT NOT NULL,
    created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now')),
    iso3166_2 TEXT UNIQUE, division_type TEXT, updated_at TEXT, retired_at TEXT,
    UNIQUE (country_id, state_name), UNIQUE(id, country_id)
);

CREATE TABLE IF NOT EXISTS cities (
    id         INTEGER PRIMARY KEY,
    state_id   INTEGER NOT NULL REFERENCES states(id) ON DELETE CASCADE,
    city_name  TEXT NOT NULL,
    latitude   REAL CHECK (latitude  IS NULL OR (latitude  BETWEEN -90 AND  90)),
    longitude  REAL CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now')),
    tier       TEXT,
    locality_type TEXT, timezone TEXT, updated_at TEXT, retired_at TEXT,
    UNIQUE (state_id, city_name), UNIQUE(id, state_id)
);

CREATE TABLE IF NOT EXISTS tags (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    tag_name TEXT NOT NULL UNIQUE
);

-- --------------------------------------------------------------------------
-- Places (column order matches the canonical seed generator)
-- --------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS places (
    id                         INTEGER PRIMARY KEY,
    city_id                    INTEGER NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
    place_name                 TEXT NOT NULL,
    name_english               TEXT,
    ai_summary                 TEXT,
    suggested_duration         TEXT,
    best_time_to_visit         TEXT,
    place_tip                  TEXT,
    advanced_booking           TEXT,
    state_name                 TEXT,   -- denormalized; QA M checks it matches states
    sunrise_view               TEXT,
    sunset_view                TEXT,
    sunrise_time               TEXT,
    sunset_time                TEXT,
    cost                       TEXT,
    rating_tourist_priority    TEXT,
    rating_traveler_experience TEXT,
    latitude                   REAL CHECK (latitude  IS NULL OR (latitude  BETWEEN -90 AND  90)),
    longitude                  REAL CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
    address                    TEXT,
    official_website           TEXT,
    rank_score                 REAL,
    created_at                 TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now')),
    google_place_id            TEXT,   -- QA F: must stay NULL (no provider data)
    category                   TEXT,
    cuisine                    TEXT,
    price_band                 TEXT,
    veg_flag                   TEXT,
    source                     TEXT NOT NULL,  -- QA L: non-blank required
    updated_at                 TEXT,
    verification_status        TEXT NOT NULL DEFAULT 'partial'
        CHECK (verification_status IN ('verified','partial','unverified','conflicting','needs_review')),   -- QA G (5 allowed statuses: verified, partial, unverified, conflicting, needs_review)
    verification_notes         TEXT,
    verified_at                TEXT,
    wikidata_id TEXT, osm_id TEXT, locality_type TEXT,
    access_status TEXT CHECK (access_status IS NULL OR access_status IN
      ('unknown','open','restricted','seasonal','temporarily_closed','permanently_closed')),
    deleted_at TEXT,
    UNIQUE (city_id, place_name),
    CHECK (TRIM(source) <> '')
);

-- QA J (LEGACY ONLY): at most one legacy opening-hours row per place.
-- CANONICAL WRITE MODEL: place_hours_intervals, with opening_hour_exceptions for date-specific exceptions.
-- Legacy opening_hours remains for existing seed compatibility; do not dual-write new data.
CREATE TABLE IF NOT EXISTS opening_hours (
    id         INTEGER PRIMARY KEY,
    place_id   INTEGER NOT NULL UNIQUE REFERENCES places(id) ON DELETE CASCADE,
    monday     TEXT,
    tuesday    TEXT,
    wednesday  TEXT,
    thursday   TEXT,
    friday     TEXT,
    saturday   TEXT,
    sunday     TEXT,
    notes      TEXT
);

-- QA K: multiple photos per place are allowed; at most ONE may be primary.
-- Enforced by partial unique index ux_photos_primary.
-- Legacy seeds may insert one placeholder row; subsequent real photos can coexist.
-- QA N: legacy no-match rows use usage_terms='no-photo-available' with all URLs NULL.
CREATE TABLE IF NOT EXISTS photos (
    id               INTEGER PRIMARY KEY,
    place_id         INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    photo_title      TEXT,
    usage_terms      TEXT,
    thumbnail_url    TEXT,
    photo_url        TEXT,
    photo_author     TEXT,
    photo_license    TEXT,
    photo_source_url TEXT,
    photo_status     TEXT NOT NULL DEFAULT 'no_match'
        CHECK (photo_status IN ('verified','no_match','needs_review')),
    is_primary INTEGER NOT NULL DEFAULT 0 CHECK(is_primary IN (0,1)),
    sort_order INTEGER NOT NULL DEFAULT 0, commons_file_name TEXT,
    image_width INTEGER CHECK(image_width IS NULL OR image_width > 0),
    image_height INTEGER CHECK(image_height IS NULL OR image_height > 0),
    CHECK(photo_status <> 'verified' OR (photo_url IS NOT NULL AND photo_source_url IS NOT NULL AND photo_license IS NOT NULL))
);

CREATE TABLE IF NOT EXISTS place_tags (
    place_id INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    tag_id   INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (place_id, tag_id)
);

CREATE TABLE IF NOT EXISTS festivals (
    id            INTEGER PRIMARY KEY,
    place_id      INTEGER REFERENCES places(id) ON DELETE CASCADE,
    city_id       INTEGER REFERENCES cities(id) ON DELETE CASCADE,
    festival_name TEXT NOT NULL,
    month_label   TEXT,      -- approximate month only; never invented dates
    notes         TEXT,
    source        TEXT,
    created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now')),
    CHECK (place_id IS NOT NULL OR city_id IS NOT NULL)
);

-- --------------------------------------------------------------------------
-- Airports (empty by default — no fabricated rows or codes)
-- --------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS airports (
    id                 INTEGER PRIMARY KEY,
    country_id         INTEGER NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
    state_id           INTEGER REFERENCES states(id),
    city_id            INTEGER REFERENCES cities(id),
    official_name      TEXT NOT NULL,
    alternate_name     TEXT,
    internal_code      TEXT UNIQUE,
    iata_code          TEXT UNIQUE CHECK (iata_code IS NULL OR (length(iata_code)=3 AND iata_code = upper(iata_code))),
    icao_code          TEXT UNIQUE CHECK (icao_code IS NULL OR (length(icao_code)=4 AND icao_code = upper(icao_code))),
    local_airport_code TEXT,
    latitude           REAL CHECK (latitude  IS NULL OR (latitude  BETWEEN -90 AND  90)),
    longitude          REAL CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
    elevation_m        REAL,
    timezone           TEXT,    -- IANA, e.g. America/Los_Angeles
    official_website   TEXT,
    airport_type       TEXT,
    operational_status TEXT,
    last_verified_at   TEXT,
    deleted_at TEXT,
    FOREIGN KEY(state_id, country_id) REFERENCES states(id,country_id)
);

-- --------------------------------------------------------------------------
-- Project tracking: codes, sources, verifications, changes, batches
-- --------------------------------------------------------------------------

-- Global internal-code registry. Reserve BEFORE use: PROPOSE -> CHECK -> RESERVE -> INSERT.
CREATE TABLE IF NOT EXISTS entity_codes (
    internal_code       TEXT PRIMARY KEY,   -- e.g. CTRY-US, PLACE-US-WA-SEA-000001
    entity_type         TEXT NOT NULL CHECK (entity_type IN ('COUNTRY','STATE','CITY','PLACE','AIRPORT')),
    entity_table        TEXT NOT NULL,
    entity_id           INTEGER NOT NULL,
    country_iso2        TEXT,
    parent_internal_code TEXT REFERENCES entity_codes(internal_code),
    allocation_status   TEXT NOT NULL DEFAULT 'RESERVED'
        CHECK (allocation_status IN ('RESERVED','ACTIVE','RETIRED')),
    source_filename     TEXT,
    notes               TEXT,
    UNIQUE (entity_table, entity_id)
);

CREATE TABLE IF NOT EXISTS entity_aliases (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    internal_code TEXT NOT NULL REFERENCES entity_codes(internal_code) ON DELETE CASCADE,
    alias_name    TEXT NOT NULL,
    language_code TEXT,
    source_url    TEXT,
    UNIQUE (internal_code, alias_name, language_code)
);

-- Every distinct source URL gets one row; verifications reference it.
CREATE TABLE IF NOT EXISTS data_sources (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    url            TEXT NOT NULL UNIQUE,
    source_title   TEXT,
    publisher      TEXT,
    authority_tier INTEGER CHECK (authority_tier BETWEEN 1 AND 3),  -- 1=official 2=institutional 3=supporting
    published_at   TEXT,
    accessed_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now'))
);

-- Per-field verification evidence. A NULL that remains must have a row here
-- explaining why (NULL is intentional and auditable, never forgotten).
CREATE TABLE IF NOT EXISTS field_verifications (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_id            TEXT,
    entity_type         TEXT,
    entity_id           INTEGER,
    entity_internal_code TEXT,
    source_table        TEXT NOT NULL,
    column_name         TEXT NOT NULL,
    accepted_value      TEXT,
    source_id           INTEGER REFERENCES data_sources(id),
    verification_status TEXT NOT NULL
        CHECK (verification_status IN ('verified','partial','unverified','conflicting','needs_review')),
    verified_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now')),
    notes               TEXT
);

CREATE TABLE IF NOT EXISTS data_change_log (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_id    TEXT,
    table_name  TEXT NOT NULL,
    record_id   INTEGER,
    column_name TEXT,
    old_value   TEXT,
    new_value   TEXT,
    change_type TEXT NOT NULL
        CHECK (change_type IN ('NULL_FILLED','CORRECTED','STANDARDIZED','DUPLICATE_RESOLVED','CODE_ASSIGNED','PHOTO_ADDED','HOURS_UPDATED')),
    source_id   INTEGER REFERENCES data_sources(id),
    changed_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now')),
    notes       TEXT
);

CREATE TABLE IF NOT EXISTS batch_registry (
    batch_id                        TEXT PRIMARY KEY,
    country_id                      INTEGER REFERENCES countries(id),
    source_filename                 TEXT NOT NULL,
    output_filename                 TEXT,
    input_sha256                    TEXT,
    processing_status               TEXT NOT NULL DEFAULT 'PENDING'
        CHECK (processing_status IN ('PENDING','PROCESSING','PASS','FAIL','NEEDS_REVIEW')),
    places_total                    INTEGER,
    places_with_verified_summary    INTEGER,
    verified_photo_count            INTEGER,
    started_at                      TEXT,
    completed_at                    TEXT,
    notes                           TEXT
);

CREATE TABLE IF NOT EXISTS unresolved_fields (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_id     TEXT,
    source_table TEXT NOT NULL,
    record_id    INTEGER NOT NULL,
    column_name  TEXT NOT NULL,
    reason_code  TEXT NOT NULL,   -- e.g. NO_OFFICIAL_SOURCE, CONFLICTING_SOURCES, NO_COMMONS_IMAGE
    details      TEXT,
    UNIQUE (batch_id, source_table, record_id, column_name)
);

CREATE TABLE IF NOT EXISTS photo_attributions (
    photo_id         INTEGER PRIMARY KEY REFERENCES photos(id) ON DELETE CASCADE,
    commons_file_page TEXT,
    license_url      TEXT,
    attribution_text TEXT,
    verified_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now')),
    notes            TEXT
);

CREATE TABLE IF NOT EXISTS opening_hour_exceptions (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id   INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    date_from  TEXT,
    date_to    TEXT,
    weekday    TEXT,
    hours_text TEXT,
    source_id  INTEGER REFERENCES data_sources(id),
    verified_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now'))
);

-- LEGACY READ/IMPORT COMPATIBILITY ONLY. New prices MUST be written to
-- ticket_price_revisions; never dual-write or union these tables without explicit migration.
CREATE TABLE IF NOT EXISTS ticket_prices (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id       INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    visitor_type   TEXT,
    amount         REAL,
    currency_code  TEXT,
    price_text     TEXT,
    effective_from TEXT,
    source_id      INTEGER REFERENCES data_sources(id),
    verified_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now'))
);

-- --------------------------------------------------------------------------
-- Indexes
-- --------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_states_country    ON states(country_id);
CREATE INDEX IF NOT EXISTS idx_cities_state      ON cities(state_id);
CREATE INDEX IF NOT EXISTS idx_places_city       ON places(city_id);
CREATE INDEX IF NOT EXISTS idx_places_status     ON places(verification_status);
CREATE INDEX IF NOT EXISTS idx_hours_place       ON opening_hours(place_id);
CREATE INDEX IF NOT EXISTS idx_photos_place      ON photos(place_id);
CREATE INDEX IF NOT EXISTS idx_photos_status     ON photos(photo_status);
CREATE INDEX IF NOT EXISTS idx_pt_place          ON place_tags(place_id);
CREATE INDEX IF NOT EXISTS idx_pt_tag            ON place_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_fest_place        ON festivals(place_id);
CREATE INDEX IF NOT EXISTS idx_fest_city         ON festivals(city_id);
CREATE INDEX IF NOT EXISTS idx_airports_country  ON airports(country_id);
CREATE INDEX IF NOT EXISTS idx_airports_city     ON airports(city_id);
CREATE INDEX IF NOT EXISTS idx_verif_entity      ON field_verifications(source_table, entity_id, column_name);
CREATE INDEX IF NOT EXISTS idx_verif_batch       ON field_verifications(batch_id);
CREATE INDEX IF NOT EXISTS idx_changelog_table   ON data_change_log(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_changelog_batch   ON data_change_log(batch_id);
CREATE INDEX IF NOT EXISTS idx_unresolved_batch  ON unresolved_fields(batch_id, source_table);
CREATE INDEX IF NOT EXISTS idx_codes_type        ON entity_codes(entity_type);

-- --------------------------------------------------------------------------
-- AI search: full-text search, semantic embeddings, demand learning
-- --------------------------------------------------------------------------

-- FTS5 index over the text users search. Query with:
--   SELECT p.* FROM place_search_fts f JOIN places p ON p.id = f.rowid
--   WHERE place_search_fts MATCH 'quiet beach*';
-- Kept in sync with places by the triggers below.
CREATE VIRTUAL TABLE IF NOT EXISTS place_search_fts USING fts5(
    place_name, name_english, ai_summary, place_tip, category,
    content='places', content_rowid='id', tokenize='porter'
);

CREATE TRIGGER IF NOT EXISTS trg_places_fts_insert AFTER INSERT ON places BEGIN
    INSERT INTO place_search_fts(rowid, place_name, name_english, ai_summary, place_tip, category)
    VALUES (new.id, new.place_name, new.name_english, new.ai_summary, new.place_tip, new.category);
END;

CREATE TRIGGER IF NOT EXISTS trg_places_fts_delete AFTER DELETE ON places BEGIN
    INSERT INTO place_search_fts(place_search_fts, rowid, place_name, name_english, ai_summary, place_tip, category)
    VALUES ('delete', old.id, old.place_name, old.name_english, old.ai_summary, old.place_tip, old.category);
END;

CREATE TRIGGER IF NOT EXISTS trg_places_fts_update AFTER UPDATE ON places BEGIN
    INSERT INTO place_search_fts(place_search_fts, rowid, place_name, name_english, ai_summary, place_tip, category)
    VALUES ('delete', old.id, old.place_name, old.name_english, old.ai_summary, old.place_tip, old.category);
    INSERT INTO place_search_fts(rowid, place_name, name_english, ai_summary, place_tip, category)
    VALUES (new.id, new.place_name, new.name_english, new.ai_summary, new.place_tip, new.category);
END;

-- Backfill the FTS index for rows imported before the triggers existed.
-- Run once after bulk imports:
--   INSERT INTO place_search_fts(rowid, place_name, name_english, ai_summary, place_tip, category)
--   SELECT id, place_name, name_english, ai_summary, place_tip, category FROM places
--   WHERE id NOT IN (SELECT rowid FROM place_search_fts);

-- Semantic vectors for "romantic sunset spots"-style queries. Embedding bytes
-- are float32 little-endian; use sqlite-vec or pgvector at query time.
-- Populated by the embedding pipeline, never by hand.
CREATE TABLE IF NOT EXISTS place_embeddings (
    place_id   INTEGER PRIMARY KEY REFERENCES places(id) ON DELETE CASCADE,
    embedding  BLOB NOT NULL,
    dims       INTEGER NOT NULL CHECK(dims > 0),
    model      TEXT NOT NULL,   -- e.g. text-embedding-3-small
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now'))
);

-- Every user search, logged. This is how the system learns demand:
-- what people ask for, where, and what they click.
CREATE TABLE IF NOT EXISTS search_log (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    query_text       TEXT NOT NULL,
    filters_json     TEXT CHECK(filters_json IS NULL OR json_valid(filters_json)),   -- e.g. {"country":"Afghanistan","category":"Museum"}
    result_count     INTEGER,
    clicked_place_id INTEGER REFERENCES places(id) ON DELETE SET NULL,
    session_id       TEXT,
    expires_at TEXT,
    created_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now'))
);

CREATE INDEX IF NOT EXISTS idx_searchlog_created ON search_log(created_at);
CREATE INDEX IF NOT EXISTS idx_searchlog_query   ON search_log(query_text);

-- Demand at a glance: most-asked queries and their click-through.
CREATE VIEW IF NOT EXISTS v_top_search_queries AS
SELECT query_text,
       COUNT(*) AS searches,
       SUM(CASE WHEN clicked_place_id IS NOT NULL THEN 1 ELSE 0 END) AS clicks
FROM search_log
GROUP BY query_text
ORDER BY searches DESC;


-- ============================================================================
-- V2.1 normalized operational extensions. Legacy tables/columns remain compatible
-- with the original country seed format. New country datasets should use these.
-- ============================================================================
CREATE UNIQUE INDEX IF NOT EXISTS ux_photos_primary ON photos(place_id) WHERE is_primary = 1;
CREATE INDEX IF NOT EXISTS idx_photos_place_sort ON photos(place_id,sort_order);
CREATE UNIQUE INDEX IF NOT EXISTS ux_places_wikidata ON places(wikidata_id) WHERE wikidata_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_places_geographic ON places(latitude,longitude);
CREATE INDEX IF NOT EXISTS idx_cities_geographic ON cities(latitude,longitude);
CREATE INDEX IF NOT EXISTS idx_airports_geographic ON airports(latitude,longitude);
CREATE INDEX IF NOT EXISTS idx_airports_state ON airports(state_id);
CREATE INDEX IF NOT EXISTS idx_codes_country ON entity_codes(country_iso2,entity_type);
CREATE INDEX IF NOT EXISTS idx_sources_publisher ON data_sources(publisher);
CREATE INDEX IF NOT EXISTS idx_prices_place_effective ON ticket_prices(place_id,effective_from);
CREATE INDEX IF NOT EXISTS idx_searchlog_expiration ON search_log(expires_at);

-- Close loophole: an airport's city must belong to its state when both supplied;
-- the supplied state must belong to its declared country.
CREATE TRIGGER IF NOT EXISTS trg_airports_city_guard_insert BEFORE INSERT ON airports
WHEN NEW.city_id IS NOT NULL
BEGIN
 SELECT RAISE(ABORT,'airport city/state/country mismatch') WHERE
  NOT EXISTS (
    SELECT 1 FROM cities ci JOIN states st ON ci.state_id=st.id
    WHERE ci.id=NEW.city_id AND st.country_id=NEW.country_id
    AND (NEW.state_id IS NULL OR st.id=NEW.state_id)
  );
END;
CREATE TRIGGER IF NOT EXISTS trg_airports_city_guard_update BEFORE UPDATE OF city_id,state_id,country_id ON airports
WHEN NEW.city_id IS NOT NULL
BEGIN
 SELECT RAISE(ABORT,'airport city/state/country mismatch') WHERE
  NOT EXISTS (
    SELECT 1 FROM cities ci JOIN states st ON ci.state_id=st.id
    WHERE ci.id=NEW.city_id AND st.country_id=NEW.country_id
    AND (NEW.state_id IS NULL OR st.id=NEW.state_id)
  );
END;

-- Hard deletes of top-level geography are dangerous in production.
-- This schema retains old CASCADE behavior for seed compatibility; application
-- roles MUST restrict DELETE, prefer retired_at/deleted_at and tested migrations.

-- CANONICAL HOURS: use this table for all new recurring opening-hour writes.
-- Old opening_hours rows are legacy-only, not a parallel source of truth.
-- A migration must reconcile legacy rows before retiring legacy reads.
CREATE TABLE IF NOT EXISTS place_hours_intervals (
 id INTEGER PRIMARY KEY,
 place_id INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
 weekday INTEGER NOT NULL CHECK(weekday BETWEEN 0 AND 6),
 opens_local TEXT NOT NULL CHECK(opens_local GLOB '[0-2][0-9]:[0-5][0-9]'),
 closes_local TEXT NOT NULL CHECK(closes_local GLOB '[0-2][0-9]:[0-5][0-9]'),
 spans_midnight INTEGER NOT NULL DEFAULT 0 CHECK(spans_midnight IN (0,1)),
 valid_from TEXT, valid_through TEXT,
 source_id INTEGER REFERENCES data_sources(id), verified_at TEXT,
 CHECK(opens_local <= '23:59' AND closes_local <= '23:59'),
 CHECK(valid_from IS NULL OR valid_through IS NULL OR valid_from <= valid_through),
 UNIQUE(place_id,weekday,opens_local,closes_local,valid_from)
);
CREATE INDEX IF NOT EXISTS idx_hours_intervals_lookup ON place_hours_intervals(place_id,weekday);

CREATE TABLE IF NOT EXISTS place_access_events (
 id INTEGER PRIMARY KEY,
 place_id INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
 status TEXT NOT NULL CHECK(status IN ('restricted','temporarily_closed','permanently_closed','open','seasonal')),
 starts_at TEXT, ends_at TEXT,
 notes TEXT, source_id INTEGER REFERENCES data_sources(id),
 verified_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
 CHECK(starts_at IS NULL OR ends_at IS NULL OR starts_at<=ends_at)
);
CREATE INDEX IF NOT EXISTS idx_access_events_place ON place_access_events(place_id,starts_at);

CREATE TABLE IF NOT EXISTS provider_references (
 id INTEGER PRIMARY KEY,
 entity_type TEXT NOT NULL CHECK(entity_type IN ('COUNTRY','STATE','CITY','PLACE','AIRPORT')),
 entity_internal_code TEXT NOT NULL REFERENCES entity_codes(internal_code),
 provider TEXT NOT NULL, provider_entity_id TEXT NOT NULL,
 license_notes TEXT, last_verified_at TEXT,
 UNIQUE(provider,provider_entity_id), UNIQUE(entity_internal_code,provider)
);

-- CANONICAL PRICES: all new and updated admission prices belong here.
-- Old ticket_prices rows are legacy-only; migrate before retiring legacy reads.
CREATE TABLE IF NOT EXISTS ticket_price_revisions (
 id INTEGER PRIMARY KEY,
 place_id INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
 visitor_type TEXT NOT NULL,
 amount_minor INTEGER CHECK(amount_minor IS NULL OR amount_minor>=0),
 currency_code TEXT CHECK(currency_code IS NULL OR (length(currency_code)=3 AND currency_code=upper(currency_code))),
 original_text TEXT,
 effective_from TEXT, effective_to TEXT,
 source_id INTEGER REFERENCES data_sources(id), verified_at TEXT,
 CHECK(effective_from IS NULL OR effective_to IS NULL OR effective_from <= effective_to),
 CHECK(amount_minor IS NOT NULL OR original_text IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS idx_price_revisions_place ON ticket_price_revisions(place_id,visitor_type,effective_from);

CREATE TABLE IF NOT EXISTS verification_evidence (
 id INTEGER PRIMARY KEY,
 field_verification_id INTEGER NOT NULL REFERENCES field_verifications(id) ON DELETE CASCADE,
 source_id INTEGER NOT NULL REFERENCES data_sources(id),
 evidence_excerpt TEXT, field_value TEXT,
 observed_at TEXT, effective_at TEXT,
 UNIQUE(field_verification_id,source_id)
);

CREATE TABLE IF NOT EXISTS code_reservation_events (
 id INTEGER PRIMARY KEY,
 internal_code TEXT NOT NULL REFERENCES entity_codes(internal_code),
 prior_status TEXT, next_status TEXT NOT NULL,
 batch_id TEXT REFERENCES batch_registry(batch_id),
 changed_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
 notes TEXT
);
CREATE INDEX IF NOT EXISTS idx_code_events_code ON code_reservation_events(internal_code,changed_at);

CREATE TABLE IF NOT EXISTS batch_artifacts (
 id INTEGER PRIMARY KEY,
 batch_id TEXT NOT NULL REFERENCES batch_registry(batch_id),
 artifact_type TEXT NOT NULL, artifact_filename TEXT NOT NULL,
 sha256 TEXT, created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
 UNIQUE(batch_id,artifact_type,artifact_filename)
);

CREATE TABLE IF NOT EXISTS place_ratings_provenance (
 id INTEGER PRIMARY KEY,
 place_id INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
 rating_type TEXT NOT NULL CHECK(rating_type IN ('tourist_priority','traveler_experience','rank_score')),
 rating REAL NOT NULL,
 scale_min REAL, scale_max REAL,
 algorithm_version TEXT, provider TEXT, review_count INTEGER CHECK(review_count IS NULL OR review_count>=0),
 source_id INTEGER REFERENCES data_sources(id), calculated_at TEXT,
 CHECK(scale_min IS NULL OR scale_max IS NULL OR scale_min < scale_max)
);
CREATE INDEX IF NOT EXISTS idx_ratings_place ON place_ratings_provenance(place_id,rating_type);

-- FTS works for supported languages but English porter stemming is not a
-- universal multilingual strategy. Language-specific search is an app concern.
-- Vector BLOBs are storage only, not ANN search; use sqlite-vec or external
-- vector infrastructure in the application runtime.
-- Each connection must turn on foreign_keys. Recommended production pragmas:
--   PRAGMA journal_mode=WAL; PRAGMA busy_timeout=5000;
-- Set retention/privacy policies in the app for search_log; do not collect
-- session identifiers without lawful purpose, retention and access controls.

-- ============================================================================
-- QA SPEC v2.1 (authoritative for automated validation)
-- QA G: places.verification_status MUST be one of the FIVE values:
--       verified, partial, unverified, conflicting, needs_review.
-- QA J: opening_hours is legacy only. At most one legacy row per place.
--       Canonical recurring schedules live in place_hours_intervals.
-- QA K: photos permits multiple rows per place; at most one is_primary=1.
--       ux_photos_primary enforces this. Zero primary rows is allowed.
-- QA N: legacy no_match photo placeholders may have null URLs; a verified
--       photo must have a photo URL, source URL, and license.
-- QA P: ticket_prices is legacy only; ticket_price_revisions is canonical.
-- IMPORTANT: New writers MUST use canonical tables only. No automatic
-- synchronization triggers are installed to prevent ambiguous dual writes.
-- ============================================================================
