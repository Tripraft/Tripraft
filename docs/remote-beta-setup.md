# TripRaft remote beta setup

Open [the interactive checklist](interactive/remote-beta-setup.html) in a browser.
It records manual progress and generates a configuration reference. It does not
collect keys, make network calls, deploy services or certify cloud acceptance.

The source Word document was reviewed on October 19, 2026. The implementation
uses its same-origin recommendation: one Docker Render service hosts the built
React app, Flask API and Socket.IO endpoint. This avoids separate-host cookie and
CSRF issues. Supabase stores operational data; Upstash supplies Redis; the existing
SQLite travel catalogs are baked into the image. Gmail HTTPS delivery replaces
SMTP when `EMAIL_PROVIDER=gmail`; local SMTP remains the default. Resend remains
an optional alternative. See [Gmail sender setup](gmail-beta-email.md).

## Requirements and credential locations

| Requirement | Where to obtain it | Where to enter it |
| --- | --- | --- |
| GitHub access | Individual repo access and `gh auth login` | Local GitHub CLI; connect repo in Render |
| Shared PostgreSQL | Supabase Connect, Session pooler, exact URI with `sslmode=require` | Render service Environment `DATABASE_URL` |
| Redis TLS | Upstash Redis `rediss://` connection URL | Render `REDIS_URL` |
| Gmail OAuth client | Google Cloud OAuth client for the sender | Render `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET` |
| Gmail offline sender grant | Authorize Gmail sending using your own OAuth client | Render `GMAIL_REFRESH_TOKEN` |
| Sender address | Same Gmail address authorized by the grant | Render `FROM_EMAIL` |
| Staff address | Your own staff email | Render `ADMIN_EMAILS` |
| Public beta origin | Assigned Render HTTPS URL | Render `FRONTEND_URL` and `CORS_ORIGINS` |
| Random application secrets | Generated independently by Blueprint | Render `SECRET_KEY`, `JWT_SECRET_KEY` |
| Optional event API | Ticketmaster developer account | Render `TICKETMASTER_API_KEY` |

No Supabase anon/service-role key is needed for this database connection. No map
API key is needed for OpenFreeMap. No Render API key is needed for dashboard
deployment. Never put database credentials, Redis passwords or mail keys in
`VITE_` variables. Leave `services/api/.env` for development.

For optional private bulk import, from the project root run:

```powershell
.venv\Scripts\python.exe infra\remote-beta\configure_beta.py --init
.venv\Scripts\python.exe infra\remote-beta\configure_beta.py --connections
```

The first command exclusively creates ignored `infra/remote-beta/.env.beta` and
never overwrites it. Secret prompts are hidden. The second validates settings and
performs only PostgreSQL `SELECT 1` and Redis `PING`. It does not migrate a database
or send email. Import that file in Render Environment; keep it private.

## Publication and deployment

Review the task files and publish them to `develop` before creating the service.
The workspace initially had only runtime SQLite sidecar changes and the untracked
source Word document. Do not include local runtime databases or unrelated changes.
Local `main` matched the saved `origin/main` ref; remote freshness was not established
by that comparison. Never force-push to reconcile history.

In Render choose New, Blueprint, connect the private repository and select
`infra/remote-beta/render.yaml` from `develop`. Supply the prompted values. The
Blueprint explicitly requests the Free plan and waits for passing CI on later
deploys. Startup validates environment settings, validates the canonical catalog,
runs `alembic upgrade head` against the specified beta database and starts one
Gunicorn worker. Start with an empty dedicated staging database; do not attach a
production database without a backup and migration review.

If the assigned public URL changes, update both origin variables and redeploy.
The web build uses `/api`; no per-user local Vite proxy is involved in the hosted app.
Direct `/invitation/<id>` and `/invitations/<id>` routes serve the SPA. Missing API
and asset paths remain 404s. CSP permits the app's existing map/font sources on SPA
responses without changing the API response policy.

## Interactive Smartlog

Sapling SCM 0.2.20260811 is installed at `C:\Program Files\Sapling\sl.exe`.
Open it from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File infra\tools\open-smartlog.ps1
```

The helper opens the existing checkout locally on port 8081, without public
binding, fetching, switching branches, discarding files or committing. Source
changes appear in the working copy; saved commits appear in history. Each teammate
installs Sapling and authenticates to GitHub individually. Use `git fetch origin
--tags` to refresh remote history. Do not publish the tokenized ISL URL.

GitHub CLI authentication was confirmed with network access. The remote `main`
matched local `main` at `9c510003`; no remote `develop` existed at inspection.
Each teammate must still authenticate their own account independently.

## Acceptance and scope

Before declaring the beta ready, verify public health, email verification,
login persistence, India to USA trip and expense invitations, shared membership,
expenses, Socket.IO updates and a CI-triggered deployment of the expected commit.
Record commit SHA, migration revision and database backup together. No local
accounts/invitations are copied automatically into the new shared database.

Render Free sleeps and uses ephemeral storage. The image bundles reference
catalogs but does not make runtime uploads durable. Persistent partner images and
vault files require durable storage or a paid disk before testing restart
durability. Staff console hosting, background workers and optional AI providers
are separate deployment work; this Blueprint does not provision them. This task
does not certify every existing app feature or promise production availability.

The local machine had no Docker CLI available. CI now builds the beta Linux image
on develop pushes and PRs targeting develop, checking assets and secret exclusions.
An actual PostgreSQL migration, Redis TLS, Gmail OAuth authorization and remote collaboration
must be validated on the configured hosting environment. Provider credentials
were not supplied, so cloud acceptance remains pending.

## References

- [Render Blueprint fields](https://render.com/docs/blueprint-spec)
- [Render Free service restrictions](https://render.com/docs/free)
- [Supabase database connection modes](https://supabase.com/docs/guides/database/connecting-to-postgres)
- [Gmail sending API](https://developers.google.com/workspace/gmail/api/guides/sending)
- [Sapling web](https://sapling-scm.com/docs/commands/web/)

The user has Gmail but no Render, Supabase or Upstash accounts yet. Those accounts
and the Google Cloud OAuth sender setup must be completed before cloud deployment.
No hosting subscription or paid resource was created.
