# Purpose: Let psycopg2 release the gevent hub while PostgreSQL is reading or writing.
"""Let psycopg2 release the gevent hub while PostgreSQL is reading or writing."""


def gevent_wait(connection, timeout=None):
    """Follow libpq's poll states using gevent's cooperative socket waiters."""
    from gevent.socket import wait_read, wait_write
    from psycopg2 import OperationalError, extensions

    while True:
        state = connection.poll()
        if state == extensions.POLL_OK:
            return
        if state == extensions.POLL_READ:
            wait_read(connection.fileno(), timeout=timeout)
        elif state == extensions.POLL_WRITE:
            wait_write(connection.fileno(), timeout=timeout)
        else:
            raise OperationalError(f'Unexpected PostgreSQL poll state: {state}')


def configure_psycopg_wait():
    """Enable only in patched server workers; preserve CLI and custom callbacks."""
    from gevent.monkey import is_module_patched
    if not is_module_patched('socket'):
        return False
    from psycopg2 import extensions
    if extensions.get_wait_callback() is None:
        extensions.set_wait_callback(gevent_wait)
    return extensions.get_wait_callback() is gevent_wait
