# Start TripRaft on Windows

Follow [Windows team development](windows-team-dev.md) for setup, personal
development credentials, startup, shutdown and troubleshooting.

The native launcher checks restricted development credentials before starting.
Shared setup, startup and source reload never apply database migrations. Optional
`python start.py --isolated` auto-migrates only a private local PostgreSQL sandbox;
team group tests use the common development database and separate release process
in the [database release guide](../operations/database-releases.md). Existing local
settings and catalog data are preserved. Use the separate reviewed operations
runbook for maintenance; do not use Docker startup for shared team development.
