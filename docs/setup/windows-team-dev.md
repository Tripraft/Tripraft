# Windows developer setup (3?4 engineers)

Use the existing `start.py` launcher for the React traveler app, Flask API and
React admin app. Run all commands from your own feature checkout in PowerShell.
Setup and startup do not initialize catalogs, seed data, apply migrations or invite staff.
Saving Python source reloads Flask without running migrations.

The companion migration-consistency proposal restores the required revision chain.
Startup verifies the configured database; only the designated schema owner applies
reviewed migrations separately.

## 1. Install once

Install Git for Windows, Python **3.11** (with the `py` launcher), and Node.js
**22 or newer**, including npm. Open a new PowerShell window and check:

```powershell
git --version
py -3.11 --version
node --version
npm --version
```

Use your own clone or a CTO-provided feature worktree; do not develop in `main`,
`develop`, the CTO's current checkout, or the Employee Portal worktree. Example
for a new engineer with repository access and a clean clone:

```powershell
git clone <CTO-provided-repository-URL> TripRaft
cd TripRaft
git switch -c feature/yourname-first-task
py -3.11 start.py --setup
```

`--setup` installs the repository-pinned pnpm (`10.34.6`), locked JavaScript
dependencies and a Python `.venv`. It creates `services/api/.env` with random
local secrets only if that file is absent. It preserves existing configuration
and databases. No global pnpm, second launcher, Docker or PowerShell activation
is needed. Later starts reuse dependencies unless manifests change.

If you already have a checkout with work in progress, keep it. Ask the CTO for
a separate checkout containing these startup changes; do not reset, clean,
rebase, delete databases, or remove another worktree to follow this guide.

## 2. Obtain your personal development credentials

Before running the apps, the CTO must approve the exact **development** project
and privately issue a distinct restricted PostgreSQL login to each engineer.
Do not reuse the CTO's `.env`, `.env.supabase`, project password, `postgres`,
`service_role`, Supabase dashboard credentials, or production connection details.
Do not place any database URL or secret in a frontend `VITE_*` variable.

Open `services/api/.env` in an editor. Paste the complete CTO-issued URL and set:

```dotenv
DATABASE_URL=CTO_ISSUED_PERSONAL_DEV_URL_WITH_SSLMODE
TRIPRAFT_DEV_DB_ROLE=tripraft_dev_yourname
TRIPRAFT_DEV_DB_HOST=CTO_APPROVED_DEV_HOST
DB_POOL_SIZE=2
DB_MAX_OVERFLOW=1
TRAVEL_POOL_SIZE=1
TRAVEL_MAX_OVERFLOW=0
```

The placeholders above are not usable credentials. Keep the generated
`SECRET_KEY` and `JWT_SECRET_KEY`. Keep Redis empty unless an approved dev Redis
service is needed. The supplied URL must use TLS (`sslmode=require` or certificate
verification). Use the exact session-pooler host and login issued by the CTO
when direct IPv6 connectivity is unavailable. A pooler username can be
`tripraft_dev_yourname.PROJECT_REF`; `TRIPRAFT_DEV_DB_ROLE` is the database role
without the project suffix. Password characters must be URL-encoded by the issuer.
Do not paste secrets into shell history, issues, screenshots, chat or commits.

Check the credentials without starting apps:

```powershell
py -3.11 start.py --check-database
```

This only reads PostgreSQL privilege metadata in a read-only transaction. It
requires the configured role and host to match, and rejects elevated roles,
privileged memberships, database/schema/object ownership, schema creation,
dangerous table grants and writes to migration bookkeeping. It checks a separate
PostgreSQL `TRAVEL_DATA_URL` too. Existing local SQLite catalog paths are allowed;
they are not automatically created or modified by the launcher.

The check is a guardrail, not proof that an endpoint is development or that a
password is unique. The CTO must confirm those facts and review effective grants,
RLS policies, callable security-definer functions and revocation procedures.
Use only approved synthetic development data. Application writes are shared:
prefix test accounts/trips with your name and coordinate cleanup with the team.
Do not run database-writing test suites against the shared development URL.

The small pools above allow up to four application/catalog connections per API
process, or about 16 across four running engineers, excluding temporary startup
checks and other clients. The CTO should confirm the project's total budget.

Frontend defaults already proxy `/api` to local Flask. If overriding public
settings, copy `apps/web/.env.example` to `apps/web/.env.local` and
`apps/admin/.env.example` to `apps/admin/.env.local` only if absent. Traveler
`VITE_API_BASE_URL=/api`; admin `VITE_API_BASE_URL=` (empty). Keep secrets in the
backend `.env` only. Restart after changing any `.env`.

## 3. Update and start each day

Run these commands from the checkout you use to start TripRaft. First save or
commit your work and stop its launcher with Ctrl+C (or `py -3.11 start.py --stop`).
Then update your employee feature branch:

```powershell
git status --short --branch
git fetch origin
git merge origin/develop
git log -1 --oneline
py -3.11 start.py
```

Resolve any merge conflicts before starting. `git pull` on a feature branch only
updates that branch from its configured upstream; it does not automatically merge
`develop`. Updating the separate team preview also does not update your active
checkout. Keep your personal `.env` in this checkout.

If you work directly on `develop`, use `git pull --ff-only origin develop`
after fetching instead of the merge above. A failed fast-forward needs history
review; preserve local work.

After the launcher is ready, open http://127.0.0.1:5173 and press Ctrl+Shift+R.
This URL serves your local checkout. An already open hosted URL or another
checkout's server can show a different version. Restarting after a pull also
reloads dependency and environment changes.

To verify tools before starting:

```powershell
py -3.11 start.py --check
py -3.11 start.py
```

`--check` checks local tools and dependency setup; it does not connect to the DB.
Startup checks the personal database role, starts Flask and both Vite servers,
waits for HTTP readiness and opens the traveler app. Keep that terminal open.

| App | URL |
| --- | --- |
| Traveler React app | http://127.0.0.1:5173 |
| Admin React app | http://127.0.0.1:5174 |
| Flask API liveness | http://127.0.0.1:5000/api/health/live |

React/CSS edits update through Vite. Python edits reload Flask. Starting again
reuses a healthy session belonging to this checkout. Occupied ports belonging
to another checkout or application produce an error; startup never kills them.
Only one checkout can use these default ports at a time on one computer.

To check startup and then stop the services created for the check:

```powershell
py -3.11 start.py --smoke --no-browser
```

A smoke check reuses an already healthy owned session without stopping it.
It verifies HTTP readiness, not every feature or authorization flow. Opening the
admin app does not grant staff access. Ask the CTO for an approved test identity;
this setup does not create accounts, invitations or permissions and does not
start or load the Employee Portal worktree.

## 4. Stop

Press **Ctrl+C** in the launcher terminal and wait for shutdown. Closing the
launcher window on Windows also ends its owned child processes. If a previous
session needs cleanup, run from the same checkout:

```powershell
py -3.11 start.py --stop
```

This stops only recorded processes whose creation identity still matches.
It never scans ports to kill other applications, resets data, or stops the
Employee Portal. Local settings, databases and logs remain on disk.

## 5. Troubleshooting

| Symptom | What to do |
| --- | --- |
| Python 3.11 or Node missing | Install the required runtime, reopen PowerShell, and repeat the version checks. `py -3.11` avoids a newer default Python. |
| Existing `.venv` uses another Python | Preserve it and use a fresh feature checkout. Do not delete another engineer's environment. |
| Install failed / dependencies changed | Read the terminal error, check network access and run `py -3.11 start.py --setup` again. Do not delete the lockfile. |
| Missing/unsafe DB role or host | Obtain your personal development credentials from the CTO. Do not substitute an owner password or bypass the check. |
| DB timeout, TLS or password error | Confirm VPN/network, exact endpoint, URL encoding, TLS and personal login with the CTO. Connection details are withheld from preflight errors. |
| Schema revision/drift error | Startup requests only fixed owner-approved development migrations. If unavailable, the owner installs `infra/sql/development/enable_approved_startup_migrations.sql` once in the testing project's SQL Editor. See [database releases](../operations/database-releases.md). Do not stamp, reset or seed. |
| Port 5000, 5173 or 5174 busy | Stop your previous session in its own checkout. To identify a listener, use `Get-NetTCPConnection -LocalPort 5000,5173,5174 -State Listen`. Ask its owner before stopping anything. |
| Admin login denied | The frontend can run without staff authorization. Request approved test access from the CTO; do not change `ADMIN_EMAILS` to grant yourself access. |
| API unavailable / proxy 503 | Read `.tripraft/logs/api.log`, `web.log` and `admin.log`. Wait for reload or restart your launcher. Refresh before retrying writes. Redact secrets before sharing logs. |
| Updated Add Expense UI missing after a pull | Fetch and merge `origin/develop` into the checkout serving port 5173 using the steps above, restart, then hard refresh. Run `git merge-base --is-ancestor origin/develop HEAD`; exit code 0 confirms the fetched team history is included. Share `git status --short --branch` and `git log -1 --oneline` if it still differs. |
| Catalog-backed pages empty | Obtain a compatible approved catalog snapshot/path from the CTO. No catalog download, initialization or seed import happens at startup. |
| Redis, email, AI or external API unavailable | These are optional integrations with separate approved dev credentials. Do not reuse production keys. |
| `--docker` or `--migrate-native` rejected | Intentional. Shared engineer startup uses restricted personal native credentials. The container entrypoint no longer migrates; provisioning and schema releases happen separately. |

For development checks without virtualenv activation:

```powershell
$env:Path = "$PWD\.venv\Scripts;$PWD\.tripraft\tools\pnpm\node_modules\.bin;$env:Path"
pnpm verify
```

Run tests only with their isolated temporary database fixtures. Never set test
configuration to the shared development database. Schema changes need a separate
CTO-reviewed migration and scheduled shared schema update before dependent code
is used by the team.

## CTO approval before onboarding

- Confirm the shared project is development only and contains approved test data.
- Issue/review 3?4 individual restricted logins with only required application DML,
  sequence usage and schema introspection; read access to `alembic_version`;
  catalog read access as needed; no ownership, DDL, administrative memberships,
  RLS bypass or migration writes. Review RLS and security-definer functions.
- Confirm backups, connection limits, credential delivery/rotation/revocation,
  catalog distribution, optional integrations and an authorized admin test account.
- Have the designated schema owner apply reviewed migrations outside engineer
  startup. Review these worktree changes before distributing or merging them.

No invitations, Supabase grants or permission changes are performed by this guide.

References: [Supabase connection options](https://supabase.com/docs/guides/database/connecting-to-postgres),
[Postgres roles](https://supabase.com/docs/guides/database/postgres/roles), and
[PostgreSQL privilege inquiry functions](https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-ACCESS-TABLE).
