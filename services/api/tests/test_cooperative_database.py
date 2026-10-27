# Purpose: Regression tests for cooperative database, including success and failure behavior.
"""PostgreSQL waits must yield to other requests in gevent server workers."""
import pytest
from gevent import joinall, sleep, spawn
from gevent.socket import socketpair
from psycopg2 import OperationalError, extensions

from app.core.db.cooperative import configure_psycopg_wait, gevent_wait


@pytest.fixture
def restore_callback():
    original = extensions.get_wait_callback()
    extensions.set_wait_callback(None)
    yield
    extensions.set_wait_callback(original)


def test_configure_only_patched_servers_and_preserve_existing_callbacks(monkeypatch, restore_callback):
    monkeypatch.setattr('gevent.monkey.is_module_patched', lambda name: False)
    assert configure_psycopg_wait() is False
    assert extensions.get_wait_callback() is None
    monkeypatch.setattr('gevent.monkey.is_module_patched', lambda name: True)
    assert configure_psycopg_wait() is True
    assert extensions.get_wait_callback() is gevent_wait
    assert configure_psycopg_wait() is True
    custom = lambda connection: None
    extensions.set_wait_callback(custom)
    assert configure_psycopg_wait() is False
    assert extensions.get_wait_callback() is custom


def test_postgres_engine_installs_callback_before_opening_connections(monkeypatch, restore_callback):
    from app.core.db import connection
    monkeypatch.setattr('gevent.monkey.is_module_patched', lambda name: True)
    engine = object()

    def create(url, **options):
        assert extensions.get_wait_callback() is gevent_wait
        return engine

    monkeypatch.setattr(connection, 'create_engine', create)
    assert connection._create_pg_engine('postgresql://localhost/isolated') is engine


def test_database_read_wait_allows_another_request_to_run():
    reader, writer = socketpair()
    events = []

    class Connection:
        ready = False

        def poll(self):
            return extensions.POLL_OK if self.ready else extensions.POLL_READ

        def fileno(self):
            return reader.fileno()

    connection = Connection()

    def database_read():
        gevent_wait(connection, timeout=1)
        events.append('database finished')

    def other_request():
        events.append('other request served')
        sleep(0.01)
        connection.ready = True
        writer.send(b'x')

    try:
        tasks = [spawn(database_read), spawn(other_request)]
        joinall(tasks, timeout=2, raise_error=True)
        assert all(task.ready() for task in tasks)
        assert events == ['other request served', 'database finished']
    finally:
        reader.close()
        writer.close()


def test_write_wait_and_invalid_poll_states(monkeypatch):
    states = iter([extensions.POLL_WRITE, extensions.POLL_OK])
    calls = []
    monkeypatch.setattr('gevent.socket.wait_write', lambda fd, timeout: calls.append((fd, timeout)))

    class Connection:
        def poll(self):
            return next(states)

        def fileno(self):
            return 12

    gevent_wait(Connection(), timeout=3)
    assert calls == [(12, 3)]
    states = iter([999])
    with pytest.raises(OperationalError, match='Unexpected PostgreSQL poll state'):
        gevent_wait(Connection())
