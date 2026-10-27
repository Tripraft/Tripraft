"""Request-local SQL timings without logging parameters or financial data."""
import hashlib
from time import perf_counter

from flask import g, has_request_context
from sqlalchemy import event


def track_query_timing(engine):
    """Attach once per engine; CLI and migration queries need no request state."""
    if event.contains(engine, 'before_cursor_execute', _before):
        return
    event.listen(engine, 'before_cursor_execute', _before)
    event.listen(engine, 'after_cursor_execute', _after)


def _before(connection, cursor, statement, parameters, context, executemany):
    if has_request_context():
        context._tripraft_started = perf_counter()


def _after(connection, cursor, statement, parameters, context, executemany):
    started = getattr(context, '_tripraft_started', None)
    if started is None or not has_request_context():
        return
    elapsed = (perf_counter() - started) * 1000
    g.db_query_count = getattr(g, 'db_query_count', 0) + 1
    g.db_time_ms = getattr(g, 'db_time_ms', 0.0) + elapsed
    if elapsed > getattr(g, 'db_slowest_ms', 0):
        g.db_slowest_ms = elapsed
        # Identify the statement in local profiling output without putting SQL,
        # bind values, credentials or response payloads in request logs.
        g.db_slowest_fingerprint = hashlib.sha256(statement.encode()).hexdigest()[:16]
