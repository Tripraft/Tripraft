# Purpose: Verifies canonical catalog creation, preservation, and shared database configuration.
import sqlite3
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from init_travel_db import SCHEMA, initialize_database, validate_database


def test_creates_complete_empty_catalog(tmp_path):
    database = tmp_path / 'catalog.db'
    assert initialize_database(database)
    counts = validate_database(database, require_empty=True)
    assert set(counts) == {
        'countries', 'states', 'cities', 'places', 'opening_hours', 'photos',
        'tags', 'place_tags', 'airports', 'festivals', 'entity_codes',
        'entity_aliases', 'data_sources', 'field_verifications', 'data_change_log',
        'batch_registry', 'unresolved_fields', 'photo_attributions',
        'opening_hour_exceptions', 'ticket_prices', 'place_search_fts',
        'place_embeddings', 'search_log', 'place_hours_intervals',
        'place_access_events', 'provider_references', 'ticket_price_revisions',
        'verification_evidence', 'code_reservation_events', 'batch_artifacts',
        'place_ratings_provenance',
    }
    assert not any(counts.values())
    with sqlite3.connect(database) as connection:
        place_columns = {row[1] for row in connection.execute('PRAGMA table_info(places)')}
        photo_columns = {row[1] for row in connection.execute('PRAGMA table_info(photos)')}
        assert {'google_place_id', 'category', 'cuisine', 'price_band', 'veg_flag',
                'source', 'updated_at', 'verification_status', 'verification_notes',
                'verified_at'} <= place_columns
        assert {'photo_url', 'photo_license', 'photo_source_url', 'photo_status'} <= photo_columns
        assert connection.execute('SELECT * FROM v_top_search_queries').fetchall() == []


def test_uses_supplied_global_schema():
    assert SCHEMA == Path(__file__).resolve().parents[1] / 'schema/tripraft-global-schema-v2.1.sql'


def test_full_text_search_tracks_place_changes(tmp_path):
    database = tmp_path / 'catalog.db'
    initialize_database(database)
    with sqlite3.connect(database) as connection:
        connection.execute('PRAGMA foreign_keys = ON')
        connection.execute("INSERT INTO countries(id, country_name) VALUES(1, 'Test country')")
        connection.execute("INSERT INTO states(id, country_id, state_name) VALUES(1, 1, 'Test state')")
        connection.execute("INSERT INTO cities(id, state_id, city_name) VALUES(1, 1, 'Test city')")
        connection.execute("INSERT INTO places(id, city_id, place_name, source) VALUES(1, 1, 'Beach', 'test')")
        assert connection.execute("SELECT rowid FROM place_search_fts WHERE place_search_fts MATCH 'beach'").fetchall() == [(1,)]
        connection.execute("UPDATE places SET place_name = 'Museum' WHERE id = 1")
        assert connection.execute("SELECT rowid FROM place_search_fts WHERE place_search_fts MATCH 'beach'").fetchall() == []
        assert connection.execute("SELECT rowid FROM place_search_fts WHERE place_search_fts MATCH 'museum'").fetchall() == [(1,)]
        connection.execute('DELETE FROM places WHERE id = 1')
        assert connection.execute("SELECT rowid FROM place_search_fts WHERE place_search_fts MATCH 'museum'").fetchall() == []


def test_repeat_initialization_preserves_existing_data(tmp_path):
    database = tmp_path / 'catalog.db'
    initialize_database(database)
    with sqlite3.connect(database) as connection:
        connection.execute("INSERT INTO countries(country_name) VALUES ('Test country')")
    before = database.read_bytes()
    assert not initialize_database(database)
    assert database.read_bytes() == before
    with pytest.raises(ValueError, match='contains data'):
        validate_database(database, require_empty=True)


def test_incompatible_database_is_never_modified(tmp_path):
    database = tmp_path / 'catalog.db'
    with sqlite3.connect(database) as connection:
        connection.execute('CREATE TABLE legacy(id INTEGER)')
    before = database.read_bytes()
    with pytest.raises(ValueError, match='schema differs'):
        initialize_database(database)
    assert database.read_bytes() == before


@pytest.mark.parametrize('sqlite_header', [False, True])
def test_initializes_existing_schema_less_catalog(tmp_path, sqlite_header):
    database = tmp_path / 'catalog.db'
    database.touch()
    if sqlite_header:
        with sqlite3.connect(database) as connection:
            connection.execute('VACUUM')
    assert initialize_database(database)
    assert not any(validate_database(database, require_empty=True).values())
    assert not initialize_database(database)


def test_failed_schema_less_initialization_rolls_back(tmp_path):
    database = tmp_path / 'catalog.db'
    with sqlite3.connect(database) as connection:
        connection.execute('VACUUM')
    schema = tmp_path / 'broken.sql'
    schema.write_text('CREATE TABLE example(id INTEGER);\nINVALID SQL;\n', encoding='utf-8')
    with pytest.raises(sqlite3.Error):
        initialize_database(database, schema)
    with sqlite3.connect(database) as connection:
        assert connection.execute('SELECT * FROM sqlite_master').fetchall() == []


def test_schema_less_initialization_supports_multiple_statements_on_one_line(tmp_path):
    database = tmp_path / 'catalog.db'
    database.touch()
    schema = tmp_path / 'schema.sql'
    schema.write_text("CREATE TABLE a(id INTEGER); CREATE TABLE b(value TEXT DEFAULT ';');", encoding='utf-8')
    assert initialize_database(database, schema)
    assert validate_database(database, schema, require_empty=True) == {'a': 0, 'b': 0}


def test_preserves_schema_less_database_with_application_metadata(tmp_path):
    database = tmp_path / 'catalog.db'
    with sqlite3.connect(database) as connection:
        connection.execute('PRAGMA user_version = 7')
    before = database.read_bytes()
    with pytest.raises(ValueError, match='schema differs'):
        initialize_database(database)
    assert database.read_bytes() == before


def test_invalid_schema_leaves_no_partial_database(tmp_path):
    schema = tmp_path / 'broken.sql'
    schema.write_text('CREATE TABLE countries(id INTEGER); INVALID SQL;', encoding='utf-8')
    database = tmp_path / 'catalog.db'
    with pytest.raises(sqlite3.Error):
        initialize_database(database, schema)
    assert not database.exists()
    assert not list(tmp_path.glob('.catalog-*.db'))


def test_shared_connections_honor_path_and_enforce_foreign_keys(tmp_path, monkeypatch):
    from app.core.config import Config
    from app.core.db.travel_db import TravelDatabase
    database = tmp_path / 'catalog.db'
    initialize_database(database)
    monkeypatch.setattr(Config, 'TRAVEL_DATABASE_PATH', database)
    manager = TravelDatabase()
    assert manager.db_path == database
    with manager.get_connection() as connection:
        assert connection.execute('PRAGMA foreign_keys').fetchone()[0] == 1
    connection = manager._raw_connection(read_only=True)
    try:
        assert connection.execute('PRAGMA foreign_keys').fetchone()[0] == 1
        assert connection.execute('PRAGMA query_only').fetchone()[0] == 1
    finally:
        connection.close()
    with pytest.raises(sqlite3.IntegrityError):
        with manager.get_connection_rw() as connection:
            connection.execute("INSERT INTO states(country_id, state_name) VALUES(999, 'Orphan')")
    assert validate_database(database, require_empty=True)['states'] == 0
