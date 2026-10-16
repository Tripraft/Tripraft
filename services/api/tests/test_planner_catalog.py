"""Catalog hierarchy must never leak another destination or omit ungeocoded cards."""
import sqlite3

import pytest

from app.core.config import Config
from conftest import payload


@pytest.fixture
def catalog(tmp_path, monkeypatch):
    path = tmp_path / 'places.db'
    with sqlite3.connect(path) as conn:
        conn.executescript('''
            CREATE TABLE countries (id INTEGER PRIMARY KEY,country_name TEXT,retired_at TEXT);
            CREATE TABLE states (id INTEGER PRIMARY KEY,country_id INTEGER,state_name TEXT,retired_at TEXT);
            CREATE TABLE cities (id INTEGER PRIMARY KEY,state_id INTEGER,city_name TEXT,latitude REAL,longitude REAL,retired_at TEXT);
            CREATE TABLE places (id INTEGER PRIMARY KEY,city_id INTEGER,place_name TEXT,name_english TEXT,
                ai_summary TEXT,category TEXT,address TEXT,latitude REAL,longitude REAL,official_website TEXT,
                rating_tourist_priority TEXT,rank_score REAL,deleted_at TEXT);
            CREATE TABLE photos (id INTEGER PRIMARY KEY,place_id INTEGER,thumbnail_url TEXT,photo_url TEXT,is_primary INTEGER,sort_order INTEGER);
            INSERT INTO countries VALUES (1,'Country A',NULL),(2,'Country B',NULL);
            INSERT INTO states VALUES (11,1,'Alpha',NULL),(12,1,'Beta',NULL),(13,1,'No places yet',NULL),(21,2,'Alpha',NULL);
            INSERT INTO cities VALUES (111,11,'Springfield',1,2,NULL),(121,12,'Springfield',3,4,NULL),
                (211,21,'Springfield',5,6,NULL),(113,11,'Empty town',NULL,NULL,NULL),
                (112,11,'Retired',NULL,NULL,'2026-01-01');
            INSERT INTO places (id,city_id,place_name,category,latitude,longitude) VALUES
                (1001,111,'Ungeocoded Garden','garden',NULL,NULL),
                (1002,111,'Museum','museum',1,2),(1003,121,'Beta Cafe','restaurant',3,4),
                (1004,211,'Foreign Museum','museum',5,6),(1005,111,'Deleted',NULL,NULL,NULL),
                (1006,112,'Retired Place',NULL,NULL,NULL);
            UPDATE places SET deleted_at='2026-01-01' WHERE id=1005;
            INSERT INTO photos VALUES (1,1002,'https://example.test/secondary.jpg',NULL,0,0),
                (2,1002,'https://example.test/primary.jpg',NULL,1,1);
        ''')
    monkeypatch.setattr(Config, 'GROUP_PLANNER_CATALOG_PATH', path)
    return path


def test_destinations_only_return_catalog_geography_and_disambiguate_parents(app, catalog):
    client = app.test_client()
    base = '/api/v1/group-planner/catalog/destinations'
    choices = payload(client.get(base + '?q=Springfield&type=city'))
    assert len(choices) == 3
    assert {c['display_name'] for c in choices} == {
        'Springfield, Alpha, Country A', 'Springfield, Beta, Country A', 'Springfield, Alpha, Country B'}
    assert all(c['type'] == 'city' for c in choices)
    assert payload(client.get(base + '?q=Country&type=country'))[0]['type'] == 'country'
    assert client.get(base + '?q=Unknown').get_json()['data'] == []
    assert client.get(base + '?q=%25').get_json()['data'] == []
    assert client.get(base + '?type=place').status_code == 400


def test_country_state_and_city_cards_are_complete_scoped_and_paginated(app, catalog):
    client = app.test_client()
    base = '/api/v1/group-planner/catalog/places'
    country = payload(client.get(base + '?destination_type=country&destination_id=1&per_page=2'))
    assert country['total'] == 3 and country['total_pages'] == 2
    assert len(country['places']) == 2
    assert {s['name'] for s in country['states']} == {'Alpha', 'Beta', 'No places yet'}
    assert next(s for s in country['states'] if s['id'] == 13)['place_count'] == 0
    assert len(country['cities']) == 3
    page2 = payload(client.get(base + '?destination_type=country&destination_id=1&per_page=2&page=2'))
    all_cards = country['places'] + page2['places']
    assert {p['id'] for p in all_cards} == {1001, 1002, 1003}
    museum = next(p for p in all_cards if p['id'] == 1002)
    assert museum['photo_url'] == 'https://example.test/primary.jpg'
    assert next(p for p in all_cards if p['id'] == 1001)['latitude'] is None
    state = payload(client.get(base + '?destination_type=state&destination_id=11'))
    assert state['total'] == 2 and len(state['cities']) == 2
    assert next(c for c in state['cities'] if c['id'] == 113)['place_count'] == 0
    city = payload(client.get(base + '?destination_type=city&destination_id=121'))
    assert [p['id'] for p in city['places']] == [1003]
    filtered = payload(client.get(base + '?destination_type=country&destination_id=1&state_id=12&city_id=121'))
    assert [p['id'] for p in filtered['places']] == [1003]
    outside = payload(client.get(base + '?destination_type=country&destination_id=1&city_id=211'))
    assert outside['total'] == 0
    old_group = payload(client.get(base + '?destination=Springfield,Alpha,Country%20A'))
    assert old_group['total'] == 2
    assert payload(client.get(base + '?destination=Springfield'))['total'] == 0
    assert client.get(base + '?destination_type=city&destination_id=-1').status_code == 400
    assert client.get(base + '?destination_id=111').status_code == 400


def test_create_group_keeps_catalog_scope_and_rejects_unknown_ids(alice, catalog):
    client, _, _ = alice
    base = '/api/v1/group-planner/groups'
    response = client.post(base, json={'name': 'Country trip', 'destination': 'Country A',
                                     'destination_type': 'country', 'destination_id': 1})
    assert response.status_code == 201
    assert payload(response)['destination_id'] == '1'
    assert payload(response)['destination_type'] == 'country'
    invalid = client.post(base, json={'name': 'Unknown', 'destination_type': 'city', 'destination_id': 999})
    assert invalid.status_code == 400


def test_missing_catalog_reports_unavailable_without_creating_database(app, tmp_path, monkeypatch):
    missing = tmp_path / 'does-not-exist.db'
    monkeypatch.setattr(Config, 'GROUP_PLANNER_CATALOG_PATH', missing)
    response = app.test_client().get('/api/v1/group-planner/catalog/destinations?q=Unknown')
    assert response.status_code == 503
    assert not missing.exists()


def test_viewport_uses_selected_catalog_scope_and_reports_missing_coordinates(app, catalog):
    client = app.test_client()
    base = '/api/v1/group-planner/catalog/viewport'
    country = payload(client.get(base + '?destination_type=country&destination_id=1'))
    assert country['destination']['type'] == 'country'
    assert country['bounds'] == [[1.0, 2.0], [3.0, 4.0]]
    assert country['source'] == 'catalog'
    state = payload(client.get(base + '?destination_type=state&destination_id=11'))
    assert state['center'] == [1.0, 2.0] and state['bounds'] is None
    city = payload(client.get(base + '?destination_type=city&destination_id=121'))
    assert city['center'] == [3.0, 4.0] and city['destination']['type'] == 'city'
    missing = payload(client.get(base + '?destination_type=city&destination_id=113'))
    assert missing['status'] == 'location_unavailable' and missing['center'] is None
    ambiguous = payload(client.get(base + '?destination=Springfield'))
    assert ambiguous['status'] == 'unresolved'
    assert client.get(base + '?destination_type=country&destination_id=-1').status_code == 400


def test_viewport_filters_invalid_points_and_takes_shortest_arc_across_date_line():
    from app.places.services.planner_catalog_service import coordinate_viewport
    viewport = coordinate_viewport([(1, 179), (3, -179), (None, 0), (400, 50), ('NaN', 0)], 'country')
    assert viewport['bounds'] == [[1.0, 179.0], [3.0, 181.0]]
    assert viewport['coordinate_count'] == 2
    assert abs(viewport['center'][1]) == 180


def test_library_separates_restaurants_and_scopes_catalog_festivals(app, catalog):
    with sqlite3.connect(catalog) as conn:
        conn.executescript('''CREATE TABLE festivals (id INTEGER PRIMARY KEY, place_id INTEGER,
            city_id INTEGER, festival_name TEXT, month_label TEXT, notes TEXT);
            INSERT INTO festivals VALUES (1,1002,111,'Spring lanterns','April','City celebration'),
                (2,1004,211,'Foreign festival','June','Elsewhere');''')
    client = app.test_client()
    base = '/api/v1/group-planner/catalog/places?destination_type=country&destination_id=1'
    places = payload(client.get(base + '&section=places'))
    assert {p['id'] for p in places['places']} == {1001, 1002}
    food = payload(client.get(base + '&section=restaurants'))
    assert [p['id'] for p in food['places']] == [1003]
    festivals = payload(client.get(base + '&section=festivals'))
    assert [p['name'] for p in festivals['places']] == ['Spring lanterns']
    assert festivals['places'][0]['month_label'] == 'April'
    assert payload(client.get(base + '&section=festivals&city_id=211'))['total'] == 0
    assert client.get(base + '&section=unknown').status_code == 400
