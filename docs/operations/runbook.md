# Development and operations

## Install and run

Use Node 22, pnpm 10.34.6, and Python 3.11. `pnpm install --frozen-lockfile` installs
the JavaScript workspace. Create an isolated Python environment and install
`services/api/requirements.txt` and `services/api/requirements-dev.txt`.
The root `start.py` automates one-time setup and starts the whole project; see
[startup](../setup/startup.md). The optional backend-only PowerShell helper creates `.venv`.

For shared development, use `python start.py` with personal restricted credentials.
The separate [database release process](database-releases.md) applies shared
migrations after approved merges to `develop`. Employees use the same development
database for group/invitation tests; production is a separate target. For private
local schema experiments, `python start.py --isolated` automatically migrates a
checkout-owned PostgreSQL database.

For an explicitly owned local database, authorized developers can run
`alembic upgrade head` from `services/api`, then `python run.py`.
From the repository root, `pnpm dev` starts web (5173) and admin (5174); their
development proxies forward `/api` to localhost:5000. A local SQLite database is
used by default. Set `REDIS_URL` to a running instance, or empty it for development
without cache/worker support. Use `ADMIN_EMAILS` to configure server admin accounts.
Do not embed personal allowlists in frontend source.

For PostgreSQL and Redis:

```sh
docker compose -f infra/docker/docker-compose.yml up --build
docker compose -f infra/docker/docker-compose.yml --profile workers up --build
```

The API waits for healthy PostgreSQL and Redis, then starts Gunicorn against an
already migrated schema. Initial provisioning and subsequent migrations are
separate owner operations. One local Gunicorn worker supports Socket.IO; multiple workers require
deployment routing/sticky-session validation. Development secrets in Compose are
for local use. Configure real secrets and production settings before deployment.

## Verification and release

`pnpm verify` runs structure validation, syntax lint, Python 3.11 syntax checks,
strict TypeScript checks for entry points/shared packages/admin, tests, and builds.
`pnpm format:check` checks workspace configuration formatting. The JavaScript
modules have syntax lint and regression coverage; they are not fully typechecked.

Update canonical CI/deployment workflows under `infra/github/workflows`, then
`pnpm workflows:sync`. Follow [database releases](database-releases.md) to configure
the environment-scoped migration credentials, independent target pins and
production reviewer/branch protections before enabling `DATABASE_RELEASES_ENABLED`.
`develop` updates the common development schema. `main` stages a release;
production requires manual dispatch, exact-commit staging evidence, acceptance,
a backup reference and administrator environment approval. Staging/production
application hooks must deploy the requested SHA and readiness must report that
same SHA. The previous tag-based production hook and flag are superseded.

## Back up and restore

Back up PostgreSQL with `pg_dump` or the provider's snapshot tooling before schema
changes. With SQLite, stop writers and back up `data/runtime/tripraft.db` and
associated WAL data together. Preserve uploaded files separately. The travel
catalog is reference data, not the private expense/group database. Docker named
volumes contain persistent database and uploads; removing those volumes erases
data and is not part of routine shutdown.

Local archived files and earlier Smartlog checkpoints are preserved on the
development machine. They are not included in the published source tree. The
current file responsibilities are documented in [files.md](../files.md).
