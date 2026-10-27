# Purpose: Keep development filesystem scans off the gevent request loop without changing reload or database behavior.
"""Development source watching must not block requests while scanning files."""
import os


def prepare_native_reload(config):
    """Select a cooperative stat reloader only for patched development servers."""
    if config.FLASK_ENV == 'production' or not (getattr(config, 'DEBUG', False) or os.getenv('TRIPRAFT_DEV_RELOAD') == '1'):
        return {}
    from gevent.monkey import is_module_patched
    if not is_module_patched('socket'):
        return {}
    from werkzeug._reloader import StatReloaderLoop, reloader_loops

    class CooperativeStatReloader(StatReloaderLoop):
        name = 'cooperative stat'

        def run_step(self):
            from gevent import get_hub
            # Werkzeug's threading.Thread is monkey-patched to a greenlet.
            # Filesystem stat calls aren't cooperative. Use a real worker thread
            # for the scan and propagate reload/error signals to the main loop.
            return get_hub().threadpool.apply(super().run_step)

    reloader_loops['tripraft-gevent-stat'] = CooperativeStatReloader
    return {'reloader_type': 'tripraft-gevent-stat'}
