# Start TripRaft on Windows

Follow [Windows team development](windows-team-dev.md) for setup, personal
development credentials, startup, shutdown and troubleshooting.

The native launcher checks restricted development credentials before starting.
Shared startup can request a fixed owner-approved development migration without
owner credentials after one-time database setup. Source reload does not migrate.
Team group tests use the common development database and separate release process
in the [database release guide](../operations/database-releases.md). Existing local
settings and catalog data are preserved. Use the separate reviewed operations
runbook for maintenance; do not use Docker startup for shared team development.
