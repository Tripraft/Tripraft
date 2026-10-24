# Start TripRaft on Windows

Follow [Windows team development](windows-team-dev.md) for setup, personal
development credentials, startup, shutdown and troubleshooting.

The native launcher checks restricted development credentials before starting.
Setup, startup and source reload never apply database migrations. Existing local
settings and catalog data are preserved. Use the separate reviewed operations
runbook for maintenance; do not use Docker startup for shared team development.
