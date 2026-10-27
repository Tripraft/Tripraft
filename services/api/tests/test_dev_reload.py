# Purpose: Guard against database changes during development and production reloads.
from types import SimpleNamespace
from unittest.mock import patch

import pytest

from app.core import dev_reload


@pytest.mark.parametrize('flag', ['1', '0'])
@pytest.mark.parametrize('environment', ['development', 'production', 'testing'])
def test_reload_never_runs_migrations(monkeypatch, flag, environment):
    monkeypatch.setenv('TRIPRAFT_DEV_RELOAD', flag)
    with patch('subprocess.run') as runner:
        dev_reload.prepare_native_reload(SimpleNamespace(FLASK_ENV=environment))
    runner.assert_not_called()


def test_reloader_scan_yields_and_preserves_reload_signal(monkeypatch):
    from gevent import joinall, sleep, spawn
    from gevent.monkey import get_original
    from werkzeug._reloader import StatReloaderLoop, reloader_loops
    monkeypatch.setenv('TRIPRAFT_DEV_RELOAD', '1')
    monkeypatch.setattr('gevent.monkey.is_module_patched', lambda name: True)
    options = dev_reload.prepare_native_reload(SimpleNamespace(FLASK_ENV='development'))
    native_sleep = get_original('time', 'sleep')
    events = []

    def scan(self):
        native_sleep(.08)
        events.append('scan done')

    monkeypatch.setattr(StatReloaderLoop, 'run_step', scan)
    loop = reloader_loops[options['reloader_type']]()
    tasks = [spawn(loop.run_step), spawn(lambda: (sleep(.01), events.append('request served')))]
    joinall(tasks, timeout=2, raise_error=True)
    assert all(task.ready() for task in tasks)
    assert events == ['request served', 'scan done']

    def reload(self):
        raise SystemExit(3)

    monkeypatch.setattr(StatReloaderLoop, 'run_step', reload)
    with pytest.raises(SystemExit) as raised:
        loop.run_step()
    assert raised.value.code == 3


def test_production_and_unpatched_processes_keep_standard_reloader(monkeypatch):
    monkeypatch.setenv('TRIPRAFT_DEV_RELOAD', '1')
    monkeypatch.setattr('gevent.monkey.is_module_patched', lambda name: False)
    assert dev_reload.prepare_native_reload(SimpleNamespace(FLASK_ENV='development')) == {}
    assert dev_reload.prepare_native_reload(SimpleNamespace(FLASK_ENV='production', DEBUG=True)) == {}
