# Purpose: Tests password-safe database URL construction and useful SQLSTATE diagnostics with raw/encoded credential redaction; no Supabase connection is made.
"""Supabase setup must expose useful database errors without exposing secrets."""
import importlib.util
from pathlib import Path
from types import SimpleNamespace
from urllib.parse import quote

from sqlalchemy.engine import make_url

spec = importlib.util.spec_from_file_location(
    'setup_supabase', Path(__file__).resolve().parents[1] / 'tools/setup_supabase.py'
)
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


def test_database_password_survives_url_encoding():
    password = 'test@:/?#%$password'
    url = setup.database_url({
        'SUPABASE_DB_PASSWORD': password,
        'SUPABASE_DB_USER': 'postgres.example',
        'SUPABASE_DB_HOST': 'example.pooler.supabase.com',
    })
    assert make_url(url.render_as_string(hide_password=False)).password == password
    assert url.query['sslmode'] == 'require'


def test_schema_error_includes_sqlstate_and_redacts_credentials(tmp_path, monkeypatch):
    password = 'secret@password'
    monkeypatch.setattr(setup, 'API', tmp_path)
    (tmp_path / '.env.supabase').write_text(f"SUPABASE_DB_PASSWORD='{password}'\n")
    primary = f'column is_archived has invalid default {password} {quote(password, safe="")}'
    error = SimpleNamespace(orig=SimpleNamespace(
        pgcode='42804', diag=SimpleNamespace(message_primary=primary)
    ))
    message = setup.database_error_message(error)
    assert '[42804]' in message and 'is_archived' in message
    assert password not in message and quote(password, safe='') not in message


def test_connection_error_does_not_print_driver_exception():
    error = SimpleNamespace(orig=Exception('connection string with password'))
    message = setup.database_error_message(error)
    assert 'connection string with password' not in message
    assert 'credentials are hidden' in message
