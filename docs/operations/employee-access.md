# Employee access portal

Current scope: employee administration and self-service are implemented locally. GitHub is **manually managed by the CTO**. No GitHub App, installation, secret, webhook, API availability or live provisioning is required by either dashboard.

## Run a safe local demonstration

### Prepared one-command review environment

In this workspace, run `python start.py` from `C:\Tripraft`. The optional local bridge detects this feature worktree, starts its isolated employee backend and prepared disposable PostgreSQL cluster, and serves the review UI on the existing admin port. It preserves saved demo passwords and does not copy portal implementation files into the original checkout. The two original-checkout changes are its launcher and admin Vite development configuration.

- Website Admin login: `http://127.0.0.1:5174/admin/login`.
- Employee login: `http://127.0.0.1:5174/employee-access/login`.
- CTO login: `http://127.0.0.1:5174/access-administration/login`.

These are separate workspaces on one frontend port. Sign-in screens have no dashboard sidebar. After sign-in, each navigation item opens its own distinct page. The website-admin demo account is `admin-demo@example.com`; its generated password is stored as `admin_account` in ignored `.tripraft/manual-test/test-logins.json`. The CTO and employee passwords remain unchanged. These accounts are independent: website-admin authorization does not confer CTO or employee access. Website click/visitor analytics are not implemented; the Admin Console explicitly distinguishes that from ingestion audit events. The canonical catalog lacks the legacy ingestion-log table, so that capability is reported as unavailable instead of returning HTTP 500.

Employee APIs and the `/local-admin/api` demo namespace are proxied to local port 5051. Demo-admin cookies have distinct names and paths; normal website credentials are filtered out before requests enter the demo backend. The existing main website/backend configuration is preserved. Review dashboards use only the disposable employee database and an empty local catalog. Native automatic server-database migrations are skipped; apply separately reviewed server migrations only after approval. `python start.py --stop` also stops demo processes recorded by this launcher. No frontend on port 5175 is needed.

The prepared database and password files remain inside ignored `.tripraft/manual-test`. Normal browsers and private windows can be used to keep CTO and employee cookies separate. GitHub automation is disabled in source, regardless of environment settings. The local demo is not an authoritative production control plane.

### Standalone synthetic demonstration

From the feature worktree, use Python 3.11 and Node 22 or later:

```powershell
python -m pip install -r services/api/requirements.txt -r services/api/requirements-dev.txt
pnpm install --frozen-lockfile
python infra/tools/employee_portal_demo.py
```

The demo migrates only `.tripraft/employee-demo/application.db`, seeds synthetic CTO/employee identities, prints distinct fresh local-only passwords, and starts Flask at `http://127.0.0.1:5051`. It overrides `DATABASE_URL`, disables email delivery, and does not read workstation database credentials. It never contacts GitHub or Supabase. Existing application databases are untouched. Without a saved credentials file, restarting generates fresh demo passwords. With --credentials-file, saved passwords and existing role/team/status settings are preserved; --rotate-credentials explicitly replaces the passwords. The signing secret rotates on restart, so existing sessions must sign in again.

In a second terminal:

```powershell
$env:VITE_API_BASE_URL = 'http://127.0.0.1:5051'
pnpm --filter @tripraft/admin dev
```

Open `http://127.0.0.1:5174/employee-access`. Sign in as `cto-demo@example.com` for the CTO Dashboard, or `engineer-demo@example.com` for the Employee Portal, using the generated password for that role. Use 127.0.0.1 for both servers so browser SameSite cookies work across their ports. Both are views of the same server-authorized application. The existing staff console remains at `/` and uses its existing authorization.

The demo is a synthetic review environment, not a shared-development database setup or a production bootstrap procedure. No real invitations are sent. Secure invite links can be generated for a profile awaiting onboarding; the intended person must sign in to a verified matching TripRaft identity before acceptance.

## Disposable PostgreSQL manual testing

The launcher also accepts an explicitly prepared disposable PostgreSQL URL file:

```powershell
python infra/tools/employee_portal_demo.py --postgres-url-file .tripraft/manual-test/database-url.txt --credentials-file .tripraft/manual-test/test-logins.json --port 5051
```

The URL must be inside this worktree's ignored `.tripraft` directory, use loopback PostgreSQL, a database name beginning `tripraft_employee_manual_`, and a role beginning `employee_manual_`. Remote URLs are rejected. The explicit option overrides the default SQLite demo only; ambient DATABASE_URL and dotenv files are never used. It applies Alembic only to that disposable database and creates different random credentials for CTO and employee. The credentials file is local-only and must not be committed or shared outside the testing group.

The prepared manual test session uses PostgreSQL on port 55441, Flask on 5051 and the shared admin frontend on 5174. Vite's cache is explicitly inside this worktree's `.tripraft/employee-admin-vite-cache`, avoiding writes through dependency links into the original project. Logs, role checks and saved logins are in the ignored manual-test directory. Open the CTO and employee in separate browser profiles or an incognito window.

### Empty employee directory after local testing

An explicitly cleared demo can retain CTO/admin credentials without recreating the sample engineer. Pass `--no-sample-employee` to the demo, or retain its ignored `.tripraft/employee-demo/no-sample-employee` marker across launcher restarts. This option only controls sample seeding; it never deletes database records. The demo health response reports `sample_employee_enabled`.

Local demo email is disabled by default. After the CTO's explicit local-email authorization, the separate email-only worker described below can use the existing Gmail service. Flask still does not load SMTP credentials. The API reports `invitation_delivery_mode=local_trusted_worker` when that local setup is configured, and onboarding shows **Gmail invitations enabled for local development**. Without setup it reports `disabled_local_demo`. A normal hosted portal reports `trusted_worker_queue`; none of these labels claims inbox delivery or employee acceptance.

### Enable email on the CTO's local computer

This is the explicitly approved local-development exception, not public hosting. Run from this portal worktree in the CTO terminal:

```powershell
& C:/Tripraft/.venv/Scripts/python.exe infra/tools/employee_local_mail.py --configure --approve-local-email --smtp-env-file C:/Tripraft/services/api/.env
& C:/Tripraft/.venv/Scripts/python.exe infra/tools/employee_local_mail.py --start
& C:/Tripraft/.venv/Scripts/python.exe infra/tools/employee_local_start.py --restart-api
& C:/Tripraft/.venv/Scripts/python.exe infra/tools/employee_local_mail.py --status
```

Configuration copies only the existing Gmail SMTP settings into a private OS-account directory (`%LOCALAPPDATA%/TripRaft/employee-control` on Windows), protected to the current CTO OS account and SYSTEM. Do not distribute that directory or the CTO's local control-plane database credentials. The website reads only a non-secret configured-mode indicator. SMTP credentials are not passed to Flask, React, employee browsers or engineer servers.

The worker pins the prepared disposable loopback PostgreSQL URL, immutable CTO UUID and the two explicitly reviewed local database login roles. It checks effective SQL privileges before processing; adding an engineer-writable login blocks delivery until reviewed. Shared Supabase cannot be selected. It processes **only `portal_invite`** every five seconds, using the existing durable claims, retries and audits. It never processes database-disable, entitlement or GitHub jobs. The ordinary local launcher starts/reuses this owned worker after setup and stops it with the other owned services. No scheduled task, public listener or production service is installed.

Emails are labelled **local development** and explain that `http://127.0.0.1:5174` requires the same CTO-managed environment. Another engineer's localhost and shared Supabase are different databases. Do not portray these links as externally reachable. Only this explicitly configured local worker can select the narrow HTTP loopback exception; the hosted executor still requires public HTTPS. Gmail acceptance appears as a completed invitation job; pending/retry/manual-review states remain visible. A worker crash or ambiguous SMTP acknowledgment never triggers an automatic duplicate.

The local email link also offers **Create local employee account**. Possession of a delivered, unexpired, single-use invitation verifies the invited address. The employee chooses a strong password and is activated only in that local employee database. Existing verified identities must provide their existing password; this form cannot reset someone else's password. The endpoint is registered only by the isolated local launcher, never by the normal application factory, and grants no CTO/admin/GitHub/database authority.

### Choose your CTO and website-admin logins

Use separate email identities. Passwords are prompted invisibly, checked, bcrypt-hashed and updated through parameterized PostgreSQL SQL. The configured identity UUID stays unchanged, existing role sessions are revoked, and the local services restart. This tool rejects shared/live database URLs.

```powershell
# Option 1: interactive prompts for email, display name and password.
& C:/Tripraft/.venv/Scripts/python.exe infra/tools/employee_local_accounts.py --role CTO
& C:/Tripraft/.venv/Scripts/python.exe infra/tools/employee_local_accounts.py --role Admin

# Option 2: choose the email/name as arguments; password is still prompted privately.
& C:/Tripraft/.venv/Scripts/python.exe infra/tools/employee_local_accounts.py --role CTO --email your-cto@example.com --name "Your name"

# Read-only persistence checks; these never display a password or restart services.
& C:/Tripraft/.venv/Scripts/python.exe infra/tools/employee_local_accounts.py --role CTO --check
& C:/Tripraft/.venv/Scripts/python.exe infra/tools/employee_local_accounts.py --role Admin --check
```

Run from `C:\Tripraft\.tripraft\employee-access-portal`. Password typing is invisible,
including no dots or stars. Use at least 12 characters (maximum 72 UTF-8 bytes),
with upper/lowercase, a number and a special character, then confirm it. Invalid
entries prompt again. Email is the login identifier; display name is not a separate
username. Setup reports saved-and-verified only after checking SQL against the
private settings. `--check` exits successfully only when chosen hash, identity and
display name all match. Original generated demo credentials report `configured:
false` until you choose credentials. If a service restart fails after saving,
check persistence before trying another reset.

There is no password command-line argument. Do not paste passwords into chat, Git or SQL history. Chosen credentials persist as hashes in the ignored local login settings and in `users.password_hash`; the old plaintext entry for the changed role is removed. This local tool does not update a shared Supabase account. `users` stores identity and password hash, while immutable `EMPLOYEE_CTO_USER_IDS` assigns CTO authority and `ADMIN_EMAILS` assigns website-admin authority independently. SQL edits to a user or employee role alone must never confer CTO authority. A future hosted account configuration requires a separately reviewed control-plane configuration and migration, especially when shared schema revisions differ.

## Backup migration rehearsal

`infra/tools/review_employee_backup.py --backup <approved-local-dump>` restores a custom-format archive into a new private PostgreSQL cluster on loopback port 55442. It refuses to reuse a running server. It hashes every original application's row set before and after upgrade, downgrade and re-upgrade, tests SQL grants and immutable audits, runs the PostgreSQL regression in a second empty database, verifies the source backup is unchanged and stops the temporary cluster. Reports and restored data stay private under ignored `.tripraft/backup-readiness-*`. No live database configuration is read. The October 20 backup contains 41 public tables: 40 application tables and `alembic_version`.

## Operational features

- CTO-only employee creation, directory, internal teams, roles, suspension, reactivation and offboarding.
- Explicit CTO identity UUID configuration (`EMPLOYEE_CTO_USER_IDS`), independent of `ADMIN_EMAILS`. There is no public CTO enrollment or API that changes this configuration.
- Dedicated 30-minute HttpOnly employee sessions, CSRF protection, login rate limiting/lockout, database session revocation and employee session epochs. Traveler and supplier sessions do not confer employee privileges.
- Hashed single-use employee invitation tokens, 48-hour expiration, CTO-generated links, revocation and queued email delivery. An accepted invitation links the employee to the matching verified user without changing customer/group roles.
- Employee role, internal teams, portal permissions, CTO-recorded GitHub information, requests and own audit history.
- Requests with resource, access level, justification, ticket, duration, approval/rejection, requests for more information, resubmission and renewal. Self-approval is rejected in both API and service code.
- Durable provisioning jobs, bounded retries, per-employee serialization, revision checks, independent offboarding steps and audit history. Approved does not mean provisioned.
- Time-limited supported portal entitlements (`portal:development.diagnostics`, `portal:staging.deploy` with read/write levels). These describe portal entitlements; they do not provide hosting credentials or operate deployment pipelines. Effective permissions exclude expired grants even if the scheduler is late.
- Administrative and unsupported resources require separate CTO execution. No production deployment, final merge, migration or GitHub administrative permission is granted by these records.

## Manual GitHub management

GitHub username is optional during onboarding. The CTO uses **Record manually managed GitHub access** to record username, organization status, invitation status and observed teams. Labels explicitly identify these as CTO records, not GitHub API verification.

Internal engineering teams are portal assignments. They do not change GitHub teams or repository permissions. The CTO performs real GitHub invitations, changes, cancellations and removals separately in GitHub. Offboarding creates a visible manual GitHub task and preserves the previously recorded status until the CTO updates it. Offboarded profiles can still receive manual GitHub record updates.

Retained future integration files are `github.py`, `security_baseline.py`, and the guarded GitHub branches of `provisioning.py`. `GITHUB_AUTOMATION_ENABLED` is hardcoded false. There is no environment variable or dashboard control to enable it. Installation-token generation and mutation calls fail before reading secrets or making network requests. Old queued GitHub jobs become `manual_required`. Re-enabling requires a reviewed source change and fresh CTO approval. Tests explicitly patch the guard only when exercising mocked future behavior.

## Trusted control plane

Host the authoritative portal, signing keys, approvals, audit history and executor in a CTO-controlled environment with a protected database. Never use an engineer-writable shared database as the authoritative approval store. Never copy control-plane signing secrets or privileged database credentials into engineer Flask instances, React variables or Git history.

`EMPLOYEE_CTO_USER_IDS` and `EMPLOYEE_SESSION_VERSION` are immutable server configuration. The latter can revoke all sessions after an incident. Use TLS, secure cookies, separate signing secrets and database identities per environment, restricted database roles, and appropriate backup/retention controls. Do not place real CTO control-plane accounts or sensitive audit history in the developer dataset.

The optional executor runs separately:

```powershell
# List pending work; does not execute jobs.
python -m app.employees.executor --config <CTO-owned-file-outside-repository>
```

Run from `services/api`. Set `TRIPRAFT_CONTROL_PLANE_DATABASE_URL` only in that trusted process. Example non-secret configuration shape:

```json
{
  "environment": "cto-controlled",
  "protected_approval_store": true,
  "cto_user_ids": ["<verified-CTO-user-UUID>"],
  "trusted_database_roles": ["<CTO-control-plane-application-role>", "<CTO-database-admin-role>"],
  "control_plane_database_name": "<protected-control-plane-database>",
  "external_changes_approved": false,
  "portal_url": "https://<employee-portal-host>",
  "database_revocation_approved": false
}
```

Execution additionally requires `--execute --approve-external-changes` and `external_changes_approved=true`. No external execution is authorized by this guide. Once the CTO approves the protected environment, run the worker continuously:

```powershell
python -m app.employees.executor --config <CTO-owned-file-outside-repository> --execute --approve-external-changes --watch --interval 5
```

Install this **once** as a supervised process in the trusted environment, never in engineer Flask startup. The prepared Linux unit is `infra/employee-access/employee-invitations.service`; review its account and installation paths before installation. Store its configuration and environment file outside the checkout with access limited to the service identity and CTO. On Windows use an equivalent service or scheduled task that starts at boot, restarts on failure, uses a dedicated account and runs the same watch command without an interactive window. Do not install or start a live worker during local review.

The worker checks effective database grants before processing approvals and every poll. A CTO-approved creation immediately enters the durable queue and is normally picked up within five seconds; the CTO does not execute a command per invitation. SMTP failure does not roll back the approved employee. Supported portal entitlement reconciliation, grant expiration notices and separately authorized database revocation use the same loop. Neither GitHub nor Supabase administrative provisioning is enabled.

Use the existing Gmail SMTP configuration only in the trusted worker: `EMAIL_ENABLED=true`, `EMAIL_PROVIDER=smtp` where supported, `SMTP_HOST=smtp.gmail.com`, `SMTP_PORT=587`, `SMTP_USER`, `SMTP_PASSWORD` (a separately issued Gmail app password), and `FROM_EMAIL`. Supply secrets through the service environment/secret manager, never React variables, CLI arguments or tracked `.env` files. SMTP TLS verifies the server certificate. Missing email configuration fails startup before consuming approvals. The dashboards themselves still work without SMTP.

`portal_url` must be a public HTTPS **origin**, for example the actual approved workspace origin. Localhost, literal private IPs, internal names, credentials, query strings and URL paths are rejected. Before enabling delivery, verify that employees can reach it externally, and that `/login`, `/signup`, `/employee-access` and `/api` are routed to the intended trusted applications on that **same origin**. Account login/verification cookies must reach the invitation API. A standalone admin Vite server does not serve the customer signup application: local demos use seeded verified test accounts. DNS, TLS and public hosting are CTO deployment prerequisites; a syntactically valid URL alone does not establish reachability.

Welcome mail includes the approved role and teams, signup/sign-in and verification instructions, single-use acceptance link, 48-hour expiry, employee sign-in URL and next steps. No password or database credential is emailed. GitHub/database access is explicitly described as separately CTO-managed. Accepting the token requires a matching active, verified TripRaft traveler identity. Only acceptance changes the employee to active.

The invitation worker commits a dispatch claim and token digest **before** SMTP, then serializes delivery against suspension/revocation. Completed jobs are never submitted again. Known pre-submission/temporary rejection failures retry with bounded backoff (six attempts). An ambiguous SMTP acknowledgment or interrupted dispatch becomes `manual_required`; it is never retried automatically. SMTP has no exactly-once guarantee. The CTO must check delivery before explicitly sending a replacement invitation, which invalidates the earlier token. Ordinary retry is blocked for uncertain delivery. A completed email job means SMTP accepted the message, not inbox delivery or employee acceptance. No tokens or SMTP error text are stored in job/audit records. The CTO history view refreshes delivery status every five seconds.

Optional developer-role revocation requires a separately approved credential supplied through `database_executor_url_env`, plus pinned `developer_database_host` and `developer_database_name` values and `database_revocation_approved=true`. The adapter restricts targets to deterministic `tripraft_dev_<employee UUID>` roles, refuses administrative roles, disables login and terminates existing sessions. Role creation remains generated SQL for CTO review, with no passwords in portal records. Failed or unconfigured steps are not reported as successful.

## Shared tripraft-dev development access

Engineers continue using the same Supabase development application database from their own React/Flask processes, with individual restricted login roles inheriting `tripraft_dev_runtime`. No Supabase organization/dashboard invitation is needed. CTO credentials are never distributed.

Review [the source table inventory](employee-database-review.md) and generated role SQL before provisioning. Developers can read or modify **all records allowed by their SQL grants**, including other shared test users/groups/expenses. Application RBAC cannot hide those rows from direct SQL. Authentication tables contain sensitive hashes/state even in development: only synthetic test identities may be shared. Keep production data separate. Developer runtime roles must not own tables, create schemas, execute migrations, access authoritative employee tables, or inherit administrative capabilities.

The new migration revokes default grants on its six new tables from PUBLIC and, where present, `anon`, `authenticated`, and `tripraft_dev_runtime`. Audit triggers reject updates and deletes. Review other inherited and custom role grants before approving deployment. The local schema inventory reports 40 application tables plus Alembic's version table; the supplied requirement reports 41 application tables. Reconcile the live inventory without assuming either number.

## Migration review

Proposed revision: `a714c3202601`, parent `f63a718293a4`.

Adds only `employees`, `employee_sessions`, `employee_access_requests`, `employee_access_events`, `employee_provisioning_jobs`, and `employee_developer_credentials`, their indexes/foreign keys, and append-only audit triggers. It does not modify existing customer tables or records. Registering the models intentionally makes startup require the new schema in the feature environment.

Generate offline SQL and review the actual head before deployment. Rehearse restoration of the existing backup. The downgrade drops the six new tables and their history; export/retain those records first. Prefer rolling back application code while retaining the additive schema. No downgrade or live migration has been authorized.

## Validation

```powershell
cd services/api
python -m pytest -q
python -m ruff check app tests
cd ../..
pnpm --filter @tripraft/admin test
pnpm --filter @tripraft/admin typecheck
pnpm --filter @tripraft/admin lint
pnpm --filter @tripraft/admin build
python infra/tools/check_structure.py
python infra/tools/check_python.py
```

`test_employee_postgresql.py` requires `EMPLOYEE_TEST_POSTGRES_URL` pointing to a disposable loopback database whose name starts with `tripraft_employee_test`. It refuses remote or nonempty databases. The CI job supplies PostgreSQL 16. Tests exercise preservation of existing records, upgrade/downgrade/re-upgrade, schema parity, append-only audit enforcement, individual SQL credentials and denial of control-plane/DDL access. GitHub tests use mocks only.

Before any live use, the CTO must approve the migration, control-plane deployment/configuration, development role grants and any external executor actions. Real GitHub management remains entirely manual.
