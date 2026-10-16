"""Read-only Group Planner geography and cards from tripraft_places.db."""
import sqlite3
import math
from contextlib import contextmanager
from pathlib import Path

from app.core.config import Config


@contextmanager
def catalog_connection():
    path = Path(Config.GROUP_PLANNER_CATALOG_PATH).resolve()
    conn = sqlite3.connect(path.as_uri() + '?mode=ro', uri=True, timeout=10)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


GEOGRAPHY = """FROM cities ci JOIN states s ON s.id = ci.state_id
    JOIN countries co ON co.id = s.country_id"""
ACTIVE = 'ci.retired_at IS NULL AND s.retired_at IS NULL AND co.retired_at IS NULL'


def search_destinations(query='', kind='all', limit=10):
    pattern = '%' + query.replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_') + '%'
    results = []
    with catalog_connection() as conn:
        for item_type, table, name, extra, joins in (
            ('country', 'countries co', 'co.country_name', "co.country_name country, NULL state", ''),
            ('state', 'states s', 's.state_name', 'co.country_name country, s.state_name state',
             'JOIN countries co ON co.id=s.country_id'),
            ('city', 'cities ci', 'ci.city_name', 'co.country_name country, s.state_name state',
             'JOIN states s ON s.id=ci.state_id JOIN countries co ON co.id=s.country_id'),
        ):
            if kind not in ('all', item_type):
                continue
            alias = {'country': 'co', 'state': 's', 'city': 'ci'}[item_type]
            active = {'country': 'co.retired_at IS NULL',
                      'state': 's.retired_at IS NULL AND co.retired_at IS NULL',
                      'city': ACTIVE}[item_type]
            coords = 'ci.latitude lat, ci.longitude lng' if item_type == 'city' else 'NULL lat, NULL lng'
            rows = conn.execute(f"""SELECT {alias}.id, {name} name, {extra}, {coords}
                FROM {table} {joins} WHERE {active} AND {name} LIKE ? ESCAPE '\\' COLLATE NOCASE
                ORDER BY CASE WHEN lower({name})=lower(?) THEN 0 ELSE 1 END, {name}, {alias}.id
                LIMIT ?""", (pattern, query, limit)).fetchall()
            for row in rows:
                item = dict(row)
                parts = [item['name']]
                if item_type == 'city' and item['state'] != item['name']:
                    parts.append(item['state'])
                if item['country'] != item['name']:
                    parts.append(item['country'])
                item.update(type=item_type, display_name=', '.join(parts))
                results.append(item)
    return results


def resolve_destination(conn, kind=None, identity=None, name=''):
    """Resolve IDs exactly, and support the qualified names on older groups."""
    if kind and identity:
        table, column = {'country': ('countries', 'country_name'),
                         'state': ('states', 'state_name'), 'city': ('cities', 'city_name')}[kind]
        row = conn.execute(f'SELECT id, {column} name FROM {table} WHERE id=? AND retired_at IS NULL',
                           (identity,)).fetchone()
        return {**dict(row), 'type': kind} if row else None
    parts = [part.strip() for part in name.split(',') if part.strip()]
    if not parts:
        return None
    # Qualified old city/state labels retain their parent names for disambiguation.
    for candidate in ([kind] if kind else (['city', 'state'] if len(parts) > 1 else ['country', 'state', 'city'])):
        if candidate == 'country':
            sql = 'SELECT id, country_name name FROM countries WHERE lower(country_name)=lower(?) AND retired_at IS NULL'
            args = [parts[0]]
        elif candidate == 'state':
            sql = '''SELECT s.id, s.state_name name FROM states s JOIN countries co ON co.id=s.country_id
                WHERE lower(s.state_name)=lower(?) AND s.retired_at IS NULL AND co.retired_at IS NULL'''
            args = [parts[0]]
            if len(parts) > 1:
                sql += ' AND lower(co.country_name)=lower(?)'
                args.append(parts[-1])
        else:
            sql = f'SELECT ci.id, ci.city_name name {GEOGRAPHY} WHERE lower(ci.city_name)=lower(?) AND {ACTIVE}'
            args = [parts[0]]
            if len(parts) > 1:
                sql += ' AND lower(co.country_name)=lower(?)'
                args.append(parts[-1])
            if len(parts) > 2:
                sql += ' AND lower(s.state_name)=lower(?)'
                args.append(parts[-2])
        rows = conn.execute(sql + ' LIMIT 2', args).fetchall()
        if len(rows) == 1:
            return {**dict(rows[0]), 'type': candidate}
    return None


def get_place_cards(kind=None, identity=None, name='', state_id=None, city_id=None,
                    search='', category='', page=1, per_page=24, section='all'):
    with catalog_connection() as conn:
        scope = resolve_destination(conn, kind, identity, name)
        if not scope:
            return {'places': [], 'states': [], 'cities': [], 'total': 0, 'page': page,
                    'total_pages': 0, 'per_page': per_page, 'destination': None}
        scope_column = {'country': 'co.id', 'state': 's.id', 'city': 'ci.id'}[scope['type']]
        if section == 'festivals':
            return festival_cards(conn, scope, state_id, city_id, search, page, per_page)
        food = "lower(COALESCE(p.category,'')) IN ('restaurant','cafe','café','food','dining','bar')"
        section_filter = (' AND ' + food if section == 'restaurants' else
                          " AND NOT (" + food + ") AND lower(COALESCE(p.category,'')) NOT IN ('festival','event')"
                          if section == 'places' else '')
        base = f'''FROM places p JOIN cities ci ON ci.id=p.city_id
            JOIN states s ON s.id=ci.state_id JOIN countries co ON co.id=s.country_id
            WHERE {ACTIVE} AND p.deleted_at IS NULL AND {scope_column}=? {section_filter}'''
        args = [scope['id']]
        geography = f'''FROM states s JOIN countries co ON co.id=s.country_id
            LEFT JOIN cities ci ON ci.state_id=s.id AND ci.retired_at IS NULL
            LEFT JOIN places p ON p.city_id=ci.id AND p.deleted_at IS NULL {section_filter}
            WHERE s.retired_at IS NULL AND co.retired_at IS NULL AND {scope_column}=?'''
        states = [dict(r) for r in conn.execute(
            'SELECT s.id, s.state_name name, COUNT(p.id) place_count ' + geography +
            ' GROUP BY s.id ORDER BY s.state_name', args)]
        city_base, city_args = geography + ' AND ci.id IS NOT NULL', list(args)
        if state_id:
            city_base += ' AND s.id=?'
            city_args.append(state_id)
        cities = [dict(r) for r in conn.execute(
            'SELECT ci.id, ci.city_name name, s.id state_id, s.state_name state_name, COUNT(p.id) place_count ' +
            city_base + ' GROUP BY ci.id ORDER BY s.state_name, ci.city_name', city_args)]
        if state_id:
            base += ' AND s.id=?'
            args.append(state_id)
        if city_id:
            base += ' AND ci.id=?'
            args.append(city_id)
        if category:
            base += " AND COALESCE(p.category, 'other')=?"
            args.append(category)
        if search:
            base += " AND (p.place_name LIKE ? ESCAPE '\\' OR p.name_english LIKE ? ESCAPE '\\')"
            pattern = '%' + search.replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_') + '%'
            args.extend([pattern, pattern])
        total = conn.execute('SELECT COUNT(*) ' + base, args).fetchone()[0]
        columns = {row[1] for row in conn.execute('PRAGMA table_info(places)')}
        details = ', '.join('p.' + key if key in columns else 'NULL ' + key for key in (
            'suggested_duration', 'best_time_to_visit', 'place_tip', 'advanced_booking',
            'cost', 'cuisine', 'price_band', 'veg_flag', 'access_status'))
        rows = conn.execute('''SELECT ''' + details + ''', p.id, COALESCE(NULLIF(p.name_english,''),p.place_name) name,
            p.ai_summary description, p.category, p.address, p.latitude, p.longitude,
            p.official_website website, p.rating_tourist_priority rating,
            ci.id city_id, ci.city_name, s.id state_id, s.state_name, co.country_name,
            (SELECT COALESCE(NULLIF(ph.thumbnail_url,''), ph.photo_url) FROM photos ph
             WHERE ph.place_id=p.id AND (NULLIF(ph.thumbnail_url,'') IS NOT NULL OR NULLIF(ph.photo_url,'') IS NOT NULL)
             ORDER BY ph.is_primary DESC, ph.sort_order, ph.id LIMIT 1) photo_url
            ''' + base + ''' ORDER BY s.state_name, ci.city_name, p.rank_score DESC, p.place_name, p.id
            LIMIT ? OFFSET ?''', args + [per_page, (page - 1) * per_page]).fetchall()
        return {'places': [dict(r) for r in rows], 'states': states, 'cities': cities,
                'destination': scope, 'total': total, 'page': page, 'per_page': per_page,
                'total_pages': (total + per_page - 1) // per_page}


def festival_cards(conn, scope, state_id, city_id, search, page, per_page):
    """Festivals are catalog events, separate from attraction/restaurant cards."""
    exists = conn.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name='festivals'").fetchone()
    if not exists:
        return {'places': [], 'states': [], 'cities': [], 'destination': scope, 'total': 0,
                'page': page, 'per_page': per_page, 'total_pages': 0}
    column = {'country': 'co.id', 'state': 's.id', 'city': 'ci.id'}[scope['type']]
    geography = f'''FROM festivals f LEFT JOIN places p ON p.id=f.place_id AND p.deleted_at IS NULL
        JOIN cities ci ON ci.id=COALESCE(f.city_id,p.city_id)
        JOIN states s ON s.id=ci.state_id JOIN countries co ON co.id=s.country_id
        WHERE {ACTIVE} AND {column}=? AND (f.place_id IS NULL OR p.id IS NOT NULL)'''
    args = [scope['id']]
    states = [dict(row) for row in conn.execute(
        'SELECT s.id, s.state_name name, COUNT(f.id) place_count ' + geography +
        ' GROUP BY s.id ORDER BY s.state_name', args)]
    city_base, city_args = geography, list(args)
    if state_id:
        city_base += ' AND s.id=?'
        city_args.append(state_id)
    cities = [dict(row) for row in conn.execute(
        'SELECT ci.id, ci.city_name name, s.id state_id, s.state_name state_name, COUNT(f.id) place_count ' +
        city_base + ' GROUP BY ci.id ORDER BY s.state_name, ci.city_name', city_args)]
    for key, value in (('s.id', state_id), ('ci.id', city_id)):
        if value:
            geography += f' AND {key}=?'
            args.append(value)
    if search:
        geography += " AND f.festival_name LIKE ? ESCAPE '\\'"
        args.append('%' + search.replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_') + '%')
    total = conn.execute('SELECT COUNT(*) ' + geography, args).fetchone()[0]
    rows = conn.execute('''SELECT 'festival-' || f.id id, f.festival_name name,
        f.notes description, f.month_label, 'festival' category, p.address, p.latitude,
        p.longitude, p.official_website website, NULL rating, NULL photo_url,
        ci.id city_id, ci.city_name, s.id state_id, s.state_name, co.country_name
        ''' + geography + ' ORDER BY s.state_name, ci.city_name, f.festival_name, f.id LIMIT ? OFFSET ?',
        args + [per_page, (page - 1) * per_page]).fetchall()
    return {'places': [dict(row) for row in rows], 'states': states, 'cities': cities,
            'destination': scope, 'total': total, 'page': page, 'per_page': per_page,
            'total_pages': (total + per_page - 1) // per_page}


def coordinate_viewport(points, kind):
    """Catalog point extent, using the shortest longitude arc across the date line."""
    valid = []
    for lat, lng in points:
        try:
            lat, lng = float(lat), float(lng)
        except (TypeError, ValueError):
            continue
        if math.isfinite(lat) and math.isfinite(lng) and -90 <= lat <= 90 and -180 <= lng <= 180:
            valid.append((lat, lng))
    if not valid:
        return {'center': None, 'bounds': None, 'zoom': None, 'coordinate_count': 0}
    south, north = min(p[0] for p in valid), max(p[0] for p in valid)
    longitudes = sorted(set(p[1] % 360 for p in valid))
    if len(longitudes) == 1:
        west = east = longitudes[0]
    else:
        gap_index = max(range(len(longitudes)), key=lambda i:
                        (longitudes[(i + 1) % len(longitudes)] - longitudes[i]) % 360)
        west = longitudes[(gap_index + 1) % len(longitudes)]
        east = longitudes[gap_index]
        if east < west:
            east += 360
    if west >= 180:
        west -= 360
        east -= 360
    center_lng = (west + east) / 2
    if center_lng > 180:
        center_lng -= 360
    bounds = [[south, west], [north, east]] if north != south or west != east else None
    return {'center': [(south + north) / 2, center_lng], 'bounds': bounds,
            'zoom': {'country': 5, 'state': 7, 'city': 12}[kind],
            'coordinate_count': len(valid)}


def get_destination_viewport(kind=None, identity=None, name=''):
    """Position a selected catalog geography without calling an external geocoder."""
    with catalog_connection() as conn:
        scope = resolve_destination(conn, kind, identity, name)
        if not scope:
            return {'destination': None, 'source': 'catalog', 'status': 'unresolved',
                    'center': None, 'bounds': None, 'zoom': None, 'coordinate_count': 0}
        column = {'country': 'co.id', 'state': 's.id', 'city': 'ci.id'}[scope['type']]
        args = [scope['id']]
        cities = conn.execute(f'SELECT ci.latitude, ci.longitude {GEOGRAPHY} WHERE {ACTIVE} AND {column}=?', args).fetchall()
        places = conn.execute(f'''SELECT p.latitude, p.longitude FROM places p
            JOIN cities ci ON ci.id=p.city_id JOIN states s ON s.id=ci.state_id
            JOIN countries co ON co.id=s.country_id WHERE {ACTIVE}
            AND p.deleted_at IS NULL AND {column}=?''', args).fetchall()
        viewport = coordinate_viewport([tuple(row) for row in cities] + [tuple(row) for row in places], scope['type'])
        return {**viewport, 'destination': scope, 'source': 'catalog',
                'status': 'available' if viewport['center'] else 'location_unavailable'}
