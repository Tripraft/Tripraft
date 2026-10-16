"""FX is a read-only display aid with validated, dated provider observations."""
from unittest.mock import Mock

import pytest
import requests

from app.expenses.services import exchange_rates as fx


@pytest.fixture(autouse=True)
def provider(monkeypatch):
    fx._cache.clear()
    response = Mock(status_code=200)
    response.json.return_value = [
        {'iso_code': 'USD', 'name': 'US Dollar'},
        {'iso_code': 'INR', 'name': 'Indian Rupee'},
        {'iso_code': 'AED', 'name': 'UAE Dirham'},
    ]
    get = Mock(return_value=response)
    monkeypatch.setattr(fx.requests, 'get', get)
    yield get
    fx._cache.clear()


def rate_response(**updates):
    result = Mock(status_code=200)
    result.json.return_value = {'base': 'USD', 'quote': 'INR', 'rate': 96, 'date': '2026-10-15', **updates}
    return result


def test_public_currency_list_and_pair_are_read_only_cached_and_dated(app, provider):
    client = app.test_client()
    data = client.get('/api/v1/currencies').get_json()['data']
    assert [row['code'] for row in data['currencies']] == ['AED', 'INR', 'USD']
    provider.return_value = rate_response()
    path = '/api/v1/exchange-rates?base=usd&quote=inr'
    result = client.get(path).get_json()['data']
    assert (result['base'], result['quote'], result['rate'], result['date']) == ('USD', 'INR', 96, '2026-10-15')
    assert result['source'] == 'Frankfurter' and not result['stale']
    assert client.get(path + '&refresh=1').get_json()['data'] == result
    assert provider.call_count == 2
    provider.assert_called_with('https://api.frankfurter.dev/v2/rate/usd/inr', timeout=(3, 6), allow_redirects=False)
    assert client.post(path).status_code in (403, 405)


@pytest.mark.parametrize('query', ['base=../url&quote=INR', 'base=USD&quote=ZZZ', 'base=&quote=INR'])
def test_invalid_or_unsupported_codes_never_become_provider_paths(app, provider, query):
    response = app.test_client().get('/api/v1/exchange-rates?' + query)
    assert response.status_code == 400
    assert all('/rate/' not in call.args[0] for call in provider.call_args_list)


@pytest.mark.parametrize('updates', [{'rate': 0}, {'rate': -1}, {'rate': float('nan')}, {'rate': True}, {'quote': 'EUR'}, {'date': 'not-a-date'}, {'date': '2999-01-01'}])
def test_bad_provider_observations_are_not_used(provider, updates):
    fx.currencies()
    provider.return_value = rate_response(**updates)
    with pytest.raises(fx.RateUnavailable):
        fx.latest_rate('USD', 'INR')


def test_outage_uses_explicit_bounded_stale_fallback_and_recovers(provider, monkeypatch):
    clock = [time_now := fx.time.time()]
    monkeypatch.setattr(fx.time, 'time', lambda: clock[0])
    fx.currencies()
    provider.return_value = rate_response()
    first = fx.latest_rate('USD', 'INR')
    clock[0] = time_now + 901
    provider.side_effect = requests.Timeout()
    fallback = fx.latest_rate('USD', 'INR')
    assert fallback['stale'] and fallback['fetched_at'] == first['fetched_at']
    calls = provider.call_count
    assert fx.latest_rate('USD', 'INR', refresh=True)['stale']
    assert provider.call_count == calls
    clock[0] += 61
    provider.side_effect = None
    provider.return_value = rate_response(rate=97)
    assert fx.latest_rate('USD', 'INR')['rate'] == 97
    clock[0] += 8 * 86400
    provider.side_effect = requests.Timeout()
    with pytest.raises(fx.RateUnavailable):
        fx.latest_rate('USD', 'INR')


def test_initial_outage_is_503_and_identity_needs_no_pair_lookup(app, provider):
    fx.currencies()
    provider.side_effect = requests.Timeout()
    client = app.test_client()
    assert client.get('/api/v1/exchange-rates?base=USD&quote=USD').get_json()['data']['rate'] == 1
    assert client.get('/api/v1/exchange-rates?base=USD&quote=INR').status_code == 503
