"""Optionally serve the built web app beside the API so browser cookies stay first party."""
from pathlib import Path

from flask import abort, request, send_from_directory
from werkzeug.security import safe_join


def register_frontend(app):
    """Return whether a verified frontend build was registered; never mask missing APIs."""
    configured = app.config.get('FRONTEND_DIST_DIR')
    if not configured:
        return False
    directory = Path(configured).resolve()
    if not (directory / 'index.html').is_file():
        raise RuntimeError('FRONTEND_DIST_DIR must contain a built index.html')

    @app.route('/', defaults={'path': ''}, endpoint='beta_frontend')
    @app.route('/<path:path>', endpoint='beta_frontend')
    def frontend(path):
        if path.split('/', 1)[0] in {'api', 'socket.io', 'health', 'static'}:
            abort(404)
        if any(part.startswith('.') for part in path.split('/') if part):
            abort(404)
        candidate = safe_join(str(directory), path)
        if candidate and Path(candidate).is_file():
            return send_from_directory(directory, path)
        # Missing assets must be 404s, not HTML that breaks module loading.
        if path.startswith('assets/') or '.' in Path(path).name:
            abort(404)
        response = send_from_directory(directory, 'index.html')
        response.headers['Cache-Control'] = 'no-cache'
        return response

    @app.after_request
    def frontend_policy(response):
        if request.endpoint == 'beta_frontend':
            # Scoped to SPA responses; the API keeps its existing policy.
            response.headers['Content-Security-Policy'] = (
                "default-src 'self'; script-src 'self'; "
                "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com; "
                "img-src 'self' data: blob: https:; "
                "font-src 'self' data: https://fonts.gstatic.com https://cdnjs.cloudflare.com; "
                "connect-src 'self' https://tiles.openfreemap.org https://*.tile.openstreetmap.org "
                "https://nominatim.openstreetmap.org https://app.ticketmaster.com; "
                "worker-src 'self' blob:; object-src 'none'; frame-ancestors 'none'; "
                "base-uri 'self'; form-action 'self'"
            )
        return response

    return True
