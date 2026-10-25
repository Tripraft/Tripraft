#!/bin/sh
# Purpose: Initializes the empty canonical catalog and starts the server/worker after separate schema deployment.
set -eu
python init_travel_db.py
exec "$@"
