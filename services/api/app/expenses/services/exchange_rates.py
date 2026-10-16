"""Public daily reference data; never reads or mutates a financial ledger."""
import math
import re
import time
from collections import OrderedDict
from datetime import date, datetime, timezone
from threading import RLock

import requests

_cache = OrderedDict()
_lock = RLock()
_PROVIDER = 'https://api.frankfurter.dev/v2'
_MAX_STALE = 7 * 86400


class RateUnavailable(Exception):
    pass


def _cached(key, ttl, load, refresh=False):
    # Bounded worker-local cache also works in development without Redis.
    # Keep a last-known observation for a short, explicitly labelled fallback.
    with _lock:
        now = time.time()
        previous = _cache.get(key)
        if previous and now < previous[2]:
            if previous[1] and now - previous[0] <= _MAX_STALE:
                return {**previous[1], 'stale': True}
            raise RateUnavailable('Currency data is temporarily unavailable. Please try again.')
        if previous and previous[1] and now - previous[0] < (60 if refresh else ttl):
            _cache.move_to_end(key)
            return {**previous[1], 'stale': False}
        try:
            data = load()
        except (requests.RequestException, ValueError, TypeError, KeyError) as exc:
            _cache[key] = (previous[0], previous[1], now + 60) if previous else (now, None, now + 60)
            while len(_cache) > 512:
                _cache.popitem(last=False)
            if previous and previous[1] and now - previous[0] <= _MAX_STALE:
                return {**previous[1], 'stale': True}
            raise RateUnavailable('Currency data is temporarily unavailable. Please try again.') from exc
        result = {**data, 'source': 'Frankfurter', 'fetched_at': datetime.now(timezone.utc).isoformat()}
        _cache[key] = (now, result, 0)
        _cache.move_to_end(key)
        while len(_cache) > 512:
            _cache.popitem(last=False)
        return {**result, 'stale': False}


def _get(path):
    response = requests.get(_PROVIDER + path, timeout=(3, 6), allow_redirects=False)
    if response.status_code != 200:
        raise ValueError('Provider returned an unavailable resource')
    return response.json()


def currency_code(value):
    code = str(value or '').upper()
    if not re.fullmatch(r'[A-Z]{3}', code):
        raise ValueError('Use a three-letter currency code.')
    return code


def currencies():
    def load():
        rows = _get('/currencies')
        if not isinstance(rows, list) or not rows:
            raise ValueError('Invalid currency list')
        values = []
        for row in rows:
            code = currency_code(row['iso_code'])
            name = row['name']
            if not isinstance(name, str) or not name.strip():
                raise ValueError('Invalid currency name')
            values.append({'code': code, 'name': name[:160]})
        return {'currencies': sorted(values, key=lambda item: item['code'])}
    return _cached('currencies', 86400, load)


def latest_rate(base, quote, refresh=False):
    base, quote = currency_code(base), currency_code(quote)
    listing = currencies()
    supported = {row['code'] for row in listing['currencies']}
    if base not in supported or quote not in supported:
        raise ValueError('This currency is not currently supported by Frankfurter.')
    if base == quote:
        return {'base': base, 'quote': quote, 'rate': 1, 'date': None,
                'source': 'Identity', 'stale': False, 'fetched_at': None}

    def load():
        row = _get(f'/rate/{base.lower()}/{quote.lower()}')
        rate = row['rate']
        if isinstance(rate, bool) or not isinstance(rate, (float, int)) or not math.isfinite(rate) or rate <= 0:
            raise ValueError('Invalid exchange rate')
        observed = date.fromisoformat(row['date'])
        if observed > datetime.now(timezone.utc).date():
            raise ValueError('Invalid rate date')
        if currency_code(row['base']) != base or currency_code(row['quote']) != quote:
            raise ValueError('Wrong exchange pair')
        return {'base': base, 'quote': quote, 'rate': rate, 'date': observed.isoformat()}
    return _cached(f'{base}:{quote}', 900, load, refresh)
