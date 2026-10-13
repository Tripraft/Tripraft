#!/bin/sh
# Purpose: Initializes the empty canonical catalog, applies API migrations and starts the server/worker.
set -eu
python init_travel_db.py
if [ "${1:-}" = "gunicorn" ]; then
    alembic upgrade head
fi
exec "$@"
