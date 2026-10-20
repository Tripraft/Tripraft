# Start TripRaft with one file

Install Node.js 22 or newer and Python 3.11 once. From the repository folder:

```sh
python start.py --setup
python start.py
```

`start.py` is the only launcher. The first command installs pinned pnpm locally,
installs the locked workspace dependencies, creates an isolated Python 3.11
`.venv`, installs API/test dependencies, and creates local settings with random
secrets. The second command starts API, web, and admin, waits for all three HTTP
endpoints, then opens the web app. Running without `--setup` on a new checkout
also performs setup automatically. Later starts reuse setup unless dependencies
change. On Windows, `py start.py` also works; no activation or execution-policy
changes are required.

The web app is http://127.0.0.1:5173, admin http://127.0.0.1:5174, and API
http://127.0.0.1:5000. The browser opens after all three services are ready.
Keep the launcher's terminal open and press Ctrl+C to stop its services.
Starting again reuses an existing healthy TripRaft session and opens the site;
it does not stop that session. If recovery is needed, startup replaces listeners
on the three development ports, checking process creation identities before
stopping them; use those ports for TripRaft only.
`python start.py --stop` also releases a previous run. Logs live in ignored `.tripraft/logs`.

Web and admin run Vite development servers: saving React, TypeScript or CSS
updates the open page through hot module replacement. Native API Python changes
restart the API automatically through the development reloader, preserving the
API's configured development debug behavior. After adding migrations or changing `.env`,
run `python start.py --stop`, then `python start.py` so startup checks run again. Docker API source changes
require rebuilding/restarting the container; the local React servers still update live.

## Data and integrations

Both startup modes initialize the empty canonical travel database from
`services/api/schema/tripraft-global-schema-v2.1.sql`. Native mode uses
`data/catalog/tripraft-canonical.db`; Docker uses its persistent catalog volume.
No seed files are imported. Existing canonical data is preserved and validated.
See [local catalog setup](../services/README.md#local-catalog-setup) for manual creation and checks.

Native mode generates `services/api/.env` only when absent, with its own development
database at `data/runtime/dev/tripraft.db`. It does not overwrite an existing `.env`
or migrate the older, unversioned `data/runtime/tripraft.db`. Sign up to create an
account in the development database. An existing configured database must already
have the correct Alembic migration history; never stamp or drop a legacy database
to suppress migration errors. Back up and migrate legacy data separately.

Native startup uses the same database URL as Flask. If migrations are pending on
an existing SQLite database, it first writes a consistent backup under ignored
`.tripraft/backups/`, then upgrades to the current revision. It preserves existing
traveler accounts and application data. PostgreSQL deployments retain their normal
external backup requirement.

Native mode disables Redis by default. Ordinary web/auth/trip/expense features run;
Redis-dependent workers and one-use financial AI confirmations require a real
`REDIS_URL`. AI providers, SMTP and external APIs also require their own configured
credentials. Set admin accounts through the server's `ADMIN_EMAILS` configuration.
Configure integrations in the ignored API `.env`, then restart the launcher.

Application review is in the separate staff console at `http://127.0.0.1:5174`.
Use its staff sign-in with an active, verified employee account enabled through
`ADMIN_EMAILS`; supplier accounts cannot enter it. See [staff review access](staff-console.md).

For PostgreSQL, Redis, and a worker, install/start Docker and use the same file:

```sh
python start.py --docker --setup
python start.py --docker
```

Docker mode runs the existing Compose topology with generated local secrets and
persistent volumes, plus the two local React servers. Stopping retains all volumes.
An already-running TripRaft Compose session is not adopted or stopped automatically.
Docker runtime execution was unavailable on the development machine; the topology
and launcher commands were checked statically. Native startup was exercised live.

## Checks and recovery

`python start.py --check` checks saved setup/prerequisites without changing files.
`python start.py --smoke --no-browser` starts all three native HTTP services,
verifies readiness, and stops them. Add `--docker` to test the Docker mode where
Docker is installed. Re-run `--setup` after changing dependency manifests.
If a native session is already healthy, `--smoke` checks and reuses it without
stopping its services. A failed child now reports its name, exit code and exact
log path in the launcher terminal.

For source verification after setup, prepend `.venv/Scripts` (Windows) or
`.venv/bin` (Unix) and `.tripraft/tools/pnpm/node_modules/.bin` to your PATH,
then run `pnpm verify`. The launcher itself uses absolute tool paths.

If startup fails, inspect `.tripraft/logs/api.log`, `web.log` or `admin.log`.
Installation errors are displayed in the launcher terminal. Missing runtimes or
occupied ports produce a direct error. Local `.env`, `.venv`, `.tripraft`, private
runtime data, uploads, dependencies, build output and `extra/` are excluded from
the published source.

## Schema edits during live development

The native development API runs the same backed-up migration command before initializing after a source reload. This requires the explicit launcher development-reload flag and is disabled for production. A second launcher waits briefly for a verified running service to recover from a reload before cleanup, rather than immediately treating its temporarily closed port as a failed session.

Web/admin development proxies return a clear JSON 503 during API downtime. Their frontend servers can stay reachable while the API reinitializes. The staff console has a connection retry; write actions are not automatically replayed. Refresh the application/receipt after recovery. Browser extension context errors are independent of these server/proxy errors.
