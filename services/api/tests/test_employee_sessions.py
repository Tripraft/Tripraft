"""Employee sessions preserve PostgreSQL timezone offsets and SQLite naive UTC."""
from datetime import datetime, timedelta, timezone

import pytest

from app.employees import policy


@pytest.mark.parametrize('offset', [None, -7, 0, 5.5])
def test_session_expiry_compares_instants_not_wall_clock(monkeypatch, offset):
    current = datetime(2026, 10, 20, 22, 0, tzinfo=timezone.utc)
    monkeypatch.setattr(policy, 'now', lambda: current)
    future, past = current + timedelta(minutes=30), current - timedelta(minutes=1)
    if offset is None:
        future, past = future.replace(tzinfo=None), past.replace(tzinfo=None)
    else:
        zone = timezone(timedelta(hours=offset))
        future, past = future.astimezone(zone), past.astimezone(zone)
    assert policy.session_expired(future) is False
    assert policy.session_expired(past) is True
