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
