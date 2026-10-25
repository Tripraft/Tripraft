# Database releases and employee development

Employees develop and test with restricted credentials. A separate release process
changes shared database schemas. Production releases need the release administrator's
approval after staging acceptance. Employee startup can request a fixed,
owner-approved development migration without receiving schema-owner credentials.

Open [the interactive checklist](database-release-checklist.html) in a browser for a
local planning aid. It does not connect to GitHub or a database, and checking a box
does not grant approval or deploy anything. GitHub records the actual approvals.

## Daily employee workflow

1. Pull the approved team branch and use the CTO-issued development `.env`.
2. Run `python start.py`. The credential check rejects elevated runtime roles.
3. Test profiles, login and CRUD using development test data. Creating, updating
   or deleting records does not change migration versions.
4. Open a PR for changes. Include a new Alembic migration only when the schema
   changes. Never edit an already deployed migration or make shared schema edits
   directly in the Supabase dashboard.
5. Startup automatically requests an approved development migration if needed.
   If it still reports pending migrations, send the sanitized revision list to
   the release administrator. The migration may need one-time function setup or
   approval/deployment. Do not change `alembic_version` manually.

Engineers may experiment with schemas in their own isolated databases. Their
personal login to the shared development database still has no schema privileges.
Application admin accounts do not receive database-owner privileges.

Employees can trigger approved development migrations through the workflow
without receiving direct `ALTER`/`DROP` rights. PostgreSQL does not provide a
general "run arbitrary migrations but never drop a table" privilege: altering
and dropping an object are ownership powers. PR/CODEOWNER review controls which
migration code the separate deployment identity executes. Do not grant employees
table ownership to bypass startup. Deleting individual permitted test records
through CRUD is different from dropping a table or database.

## Automatic migration on `python start.py`

The owner/CTO runs [the one-time development setup SQL](../../infra/sql/development/enable_approved_startup_migrations.sql)
in the **shared testing project's** Supabase SQL Editor. It creates a locked
`tripraft_dev_ops` schema and a security-definer function callable by existing
members of `tripraft_dev_runtime`. If personal logins do not inherit that role,
the owner must review their membership separately; no role membership is granted
by this script. Never install this development-only function in production.

After this one-time setup, employees just run `python start.py`. Startup verifies
the restricted login, reads the migration state and, when behind, requests the
checkout's target revision from that function. The database owner has explicitly
approved only the `b825c4202610` → `c62f718293a4` currency-column migration in its
fixed body. It cannot execute caller SQL, accept table names, drop tables, delete
rows or change an arbitrary version. The column and migration record change in
one transaction under the shared release lock. A second employee start is a safe
no-op. Startup then independently checks the resulting revision and the API checks
actual schema parity before accepting traffic.

Future migrations are normally reviewed and deployed automatically by the
central `develop` workflow before employees pull that code. The startup function
refuses unapproved target revisions; the owner can explicitly review and replace
its fixed body for additional approved operations. This avoids giving employees
general migration credentials. The one-time function installation itself requires
an owner session: restricted credentials cannot create their own privilege bridge.

## Shared groups and testing between employees

Use **one common development Supabase database** for the team, separate from the
production database. Each employee has a personal restricted database login and
a separate application test account, but their development URLs point to the
same development project/database. Their local API and frontend use those shared
test records. Invite two test users to the same group to exercise membership,
expenses, invitations and other interactions. The app's normal authorization
still applies: sharing a database does not expose every private group to everyone.

Once CI releases are enabled, approved `develop` changes automatically migrate
the common development database. Employees pull the matching code and run `python start.py`; no migration
owner password is distributed to their machines. Development does not need an
application hosting hook because the team runs the application locally. Separate
local Socket.IO servers do not broadcast events to each other automatically;
refresh/refetch reads the common records. To test live updates between machines,
use one shared hosted development API or a separately configured shared Redis
message queue and validate that setup. Database sharing alone does not provide
cross-process WebSocket delivery.

## What runs automatically

Canonical workflow: `infra/github/workflows/deploy.yml`; GitHub discovery copy:
`.github/workflows/deploy.yml`. After editing, run `pnpm workflows:sync`.

| Trigger | Environment | Release control |
| --- | --- | --- |
| Approved merge/push to `develop` | `development` | Protected branch review, full verification, disposable PostgreSQL tests |
| Approved merge/push to `main` | `staging` | Same checks, then migrations, exact-commit application deploy and readiness |
| Administrator runs **Deploy** from `main` | `production` | Successful staging run for the exact same SHA, acceptance confirmation, backup reference, environment reviewer approval |

`DATABASE_RELEASES_ENABLED` must be `true` before any release job runs. Leave it
unset/false while configuring the environments. The previous `DEPLOY_HOOKS_ENABLED`
flag and `v*` production tag trigger are replaced by this controlled workflow.

The workflow runs all workspace checks and PostgreSQL migration/permission tests
before accessing environment secrets. Migration execution is serialized across
releases and guarded by a database session advisory lock. The runner validates
the expected host, database and full login, applies pending upgrades, then verifies
both the migration revision and the real application schema. Unknown histories,
multiple code heads, schema drift and unavailable locks block the release.

Migration history must already exist. Initial empty database provisioning is an
explicit owner task using the reviewed existing setup tools. The release runner
does not initialize, reset, stamp, seed or downgrade an environment.

## One-time administrator setup in GitHub

Create **three separate database targets** for development, staging and production.
Do not point these environments at the same Supabase database. Existing test data
stays in development; migrations change the schema of each target without copying
test accounts into production. This change does not provision Supabase projects.

In repository **Settings → Environments**, configure `development`, `staging`,
and `production`. Use environment-scoped credentials, never repository-wide
production migration secrets.

| Setting in each environment | Type | Value |
| --- | --- | --- |
| `MIGRATION_DATABASE_URL` | Secret | Separate authorized migration login; TLS required |
| `MIGRATION_EXPECTED_HOST` | Variable | Exact target hostname |
| `MIGRATION_EXPECTED_USER` | Variable | Full URL login, including pooler project suffix when applicable |
| `MIGRATION_EXPECTED_DATABASE` | Variable | Exact database name, commonly `postgres` |
| `APPLICATION_DEPLOY_HOOK` | Secret | Staging/production: HTTPS hosting adapter accepting `POST {"sha":"<40-character commit>"}` |
| `APPLICATION_READINESS_URL` | Variable | Staging/production: HTTPS application `/api/health/ready` endpoint |

Use a direct database connection or a **session pooler**. Transaction pooling is
unsupported because the release lock must remain on one database session; port
6543 is rejected. Migration credentials must own or have authorized access to the
application objects being migrated. Do not reuse the migration login as the app
runtime login or distribute it in employee `.env` files.

The hosting adapter must deploy the requested commit and set `RELEASE_SHA` to that
full commit SHA in the running API. Readiness must return HTTP 200 with
`{"status":"healthy","release_sha":"<same SHA>", ...}`. The API now includes this
field. A healthy old deployment does not satisfy a new release. A generic hosting
hook that ignores the JSON SHA needs an adapter before enabling this workflow.
The readiness check confirms the API commit; the hosting adapter is responsible
for deploying matching frontend assets too.

Configure required reviewers for `production` to include only the designated
release administrators (initial owner: `@deeppatel1842` from CODEOWNERS), restrict
its deployment branch to `main`, and disable administrator bypass. The release
gate checks that reviewer and branch protections exist; GitHub enforces the
configured reviewers. Feature branches must never access production secrets.
The pre-approval gate uses `github.token` to read production environment metadata;
if repository policy denies that read, it fails closed for administrator review.

Protect `develop` and `main`: require PRs, passing CI and CODEOWNER approval;
restrict direct pushes and disallow bypass where supported. CODEOWNERS alone
does not enforce review. Protect both workflow locations, migration code and
release tools through that review policy. Configure development and staging
environment branch policies for `develop` and `main`, respectively.

The initial repository setup requires CODEOWNER approval and passing `verify` /
`employee-postgresql` checks for non-admin PRs on both branches. The repository
administrator retains GitHub's administrative branch authority for bootstrap;
the production environment's required approval cannot be bypassed. Additional
CTO/Admin GitHub identities must be explicitly added to the reviewer list before
they can approve production. Application role names alone grant no GitHub access.

Verify backup/restore access, required runtime grants, staging identities and the
hosting adapter. Then set repository variable `DATABASE_RELEASES_ENABLED=true`.
No workflow YAML can supply your database credentials, hosting integration or
human acceptance results; these settings must be configured before activation.

## Release an approved change

1. Review migration SQL and data impact in the PR. Test on a disposable database.
   Preserve existing rows; verify required runtime grants for newly added tables
   explicitly. Never grant all future tables automatically.
2. Merge to `develop`. Wait for **Deploy** to complete for development. Employees
   pull the matching approved code and retry startup.
3. Promote the selected code to `main`. Wait for its staging **Deploy** run to
   finish successfully. Record its run ID and exact commit SHA.
4. In staging test signup, login/logout, profile create/read/update, relevant
   table CRUD, validation, authorization and the changed features. Use the app's
   legitimate deletion flows and approved test identities. Automated tests and
   readiness do not establish exhaustive feature correctness.
5. Verify a production backup/snapshot and its recovery procedure. For a schema
   change incompatible with the running app, schedule maintenance or redesign
   it as compatible additive changes before continuing.
6. Open GitHub **Actions → Deploy → Run workflow**, choose `main`, enter the
   successful staging run ID and backup reference, and confirm acceptance.
   If `main` advanced, stage the new commit first; an older staging run is rejected.
7. The designated production reviewer inspects the commit, migration impact,
   staging acceptance and backup evidence, then approves the environment job.
8. Wait for migrations, application deployment and exact-commit readiness. Review
   the workflow summary and perform the production smoke checks.

To plan manually as an authorized release administrator, inject the environment's
four `MIGRATION_*` values through your secret manager, then run from the repo root:

```powershell
python infra/tools/deploy_database.py --environment development
```

You can use your existing `services/api/.env` instead of another configuration
file. Keep its working restricted `DATABASE_URL` unchanged, and add the four
`MIGRATION_*` settings from the table above **only on the administrator's machine**.
`MIGRATION_DATABASE_URL` must contain a distinct schema-owner login, not the
TripRaft CTO/Admin portal password or an employee CRUD login. Then plan with:

```powershell
python infra/tools/deploy_database.py --environment development --env-file services/api/.env
```

The new workflow does not require `.env.supabase`. The explicit file option only
supplies `MIGRATION_*` values; it never falls back to `DATABASE_URL`. Keep migration
settings blank in employee copies. Do not commit `.env` or paste credentials into
chat; publish migration credentials only as the intended GitHub environment secret.

This only reads migration metadata. `--apply` is the explicit owner action used
by the approved workflow. The command does not authenticate a TripRaft admin;
database privileges and access to release credentials enforce the authority.
The environment argument labels the operation; independent target pins and
correctly scoped GitHub environment secrets determine the actual database.

## Failure and recovery

If verification or approval fails, migration/deployment does not start. If a
migration fails, the application hook is not called. PostgreSQL transactional
migrations usually roll back their transaction; verify the actual revision and
schema before retrying, especially for future nontransactional migrations.

Migrations finish before the application hook runs. If application deployment or
readiness then fails, the database may already be upgraded. Do not automatically
downgrade or drop columns. Inspect the target, repair forward, or deploy a tested
compatible app version. Use expand-and-contract for changes that must coexist
with old app instances: add first, backfill and switch code, remove only in a
later approved release. The existing startup policy requires an exact schema
match on restart; this change does not add old-version compatibility or guarantee
zero-downtime deployment. Maintenance may be needed for coordinated releases.

After success, retain the GitHub run, commit SHA, review and backup reference.
The workflow prints revision descriptions and sanitized errors, never URLs or
driver SQL/parameters. Debug privately; do not paste `.env` contents into a PR.

## References

- [Supabase environment workflow](https://supabase.com/docs/guides/deployment/managing-environments)
- [GitHub environments and deployment protections](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments)
- [Alembic shared migration connections](https://alembic.sqlalchemy.org/en/latest/cookbook.html#sharing-a-connection-across-one-or-more-programmatic-migration-commands)
- [PostgreSQL advisory locks](https://www.postgresql.org/docs/current/explicit-locking.html#ADVISORY-LOCKS)
- [PostgreSQL ownership and privileges](https://www.postgresql.org/docs/17/ddl-priv.html)
