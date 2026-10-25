# Purpose: Exercise the release runner against disposable databases and verify release identity in readiness.
import importlib.util
from pathlib import Path
from unittest import mock

from alembic import command
from alembic.config import Config
import pytest
from sqlalchemy import create_engine, inspect, text

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('release_runner', ROOT / 'infra/tools/deploy_database.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


def test_plan_then_upgrade_preserves_records_and_verifies_schema(tmp_path, monkeypatch):
    url = 'sqlite:///' + (tmp_path / 'release.db').as_posix()
    monkeypatch.setenv('DATABASE_URL', url)
    config = Config(str(ROOT / 'services/api/alembic.ini'))
    config.set_main_option('script_location', str(ROOT / 'services/api/migrations'))
    command.upgrade(config, 'b825c4202610')
    engine = create_engine(url)
    try:
        with engine.begin() as connection:
            connection.execute(text("INSERT INTO users(id,email,password_hash) VALUES ('00000000000000000000000000000001','preserved@example.test','unused')"))
        with engine.connect() as connection:
            runner.run_release(connection, config)
            assert connection.execute(text('SELECT version_num FROM alembic_version')).scalar_one() == 'b825c4202610'
            assert 'personal_display_currency' not in {column['name'] for column in inspect(connection).get_columns('users')}
            connection.rollback()
            runner.run_release(connection, config, apply=True)
            assert connection.execute(text('SELECT email,personal_display_currency FROM users')).one() == ('preserved@example.test', None)
            connection.rollback()
            runner.run_release(connection, config, apply=True)
            assert connection.execute(text('SELECT COUNT(*) FROM users')).scalar_one() == 1
    finally:
        engine.dispose()


def test_unknown_history_never_attempts_upgrade(tmp_path, monkeypatch):
    url = 'sqlite:///' + (tmp_path / 'unknown.db').as_posix()
    monkeypatch.setenv('DATABASE_URL', url)
    config = runner.migration_config()
    engine = create_engine(url)
    try:
        with engine.begin() as connection:
            connection.execute(text('CREATE TABLE alembic_version(version_num VARCHAR(32) PRIMARY KEY)'))
            connection.execute(text("INSERT INTO alembic_version VALUES ('future_unknown')"))
        with engine.connect() as connection, mock.patch.object(runner.command, 'upgrade') as upgrade:
            with pytest.raises(RuntimeError, match='Release blocked'):
                runner.run_release(connection, config, apply=True)
            upgrade.assert_not_called()
            assert connection.execute(text('SELECT version_num FROM alembic_version')).scalar_one() == 'future_unknown'
    finally:
        engine.dispose()


def test_readiness_reports_the_deployed_commit(monkeypatch):
    from flask import Flask
    from app.core import health
    app = Flask(__name__)
    app.register_blueprint(health.health_bp, url_prefix='/api/health')
    monkeypatch.setenv('RELEASE_SHA', 'a' * 40)
    with mock.patch.object(health, '_check_database', return_value={'status': 'healthy'}), \
            mock.patch.object(health, '_check_cache', return_value={'status': 'unavailable'}), \
            mock.patch.object(health, '_check_celery', return_value={'status': 'unavailable'}):
        response = app.test_client().get('/api/health/ready')
    assert response.status_code == 200
    assert response.json['release_sha'] == 'a' * 40
