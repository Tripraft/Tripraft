# Purpose: Ensures only explicit native development reload runs the backed-up migration command before API initialization.
from types import SimpleNamespace
from unittest.mock import Mock

import pytest

from app.core import dev_reload


@pytest.mark.parametrize(('flag', 'environment', 'runs'), [
    ('1', 'development', True), ('0', 'development', False),
    ('1', 'production', False), ('1', 'testing', False),
])
def test_native_reload_migration_is_explicit_and_not_production(monkeypatch, flag, environment, runs):
    monkeypatch.setenv('TRIPRAFT_DEV_RELOAD', flag)
    runner = Mock()
    monkeypatch.setattr(dev_reload.subprocess, 'run', runner)
    dev_reload.prepare_native_reload(SimpleNamespace(FLASK_ENV=environment))
    if runs:
        command, = runner.call_args.args
        assert command[0] == dev_reload.sys.executable and command[-1] == '--migrate-native'
        assert command[1].endswith('start.py')
        assert runner.call_args.kwargs['check'] is True
        assert runner.call_args.kwargs['timeout'] == 60
        assert runner.call_args.kwargs['cwd'].name == 'api'
    else:
        runner.assert_not_called()
