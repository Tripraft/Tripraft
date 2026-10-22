# Employee Access Portal isolated checkpoint

Prepared October 21, 2026. Source worktree: `C:/Tripraft/.tripraft/employee-access-portal` on `feature/employee-access-portal`. Additional branch: `feature/employee-access-onboarding-checkpoint-20261021`. Review worktree: `C:/Tripraft/.tripraft/worktrees/employee-access-onboarding-checkpoint-20261021`. Verified integration base: `809c4be` (`origin/develop` when the checkpoint was created).

## Scope and preservation

The original checkout and feature worktree retain all existing files and uncommitted changes. This checkpoint copies an explicit allowlist of Employee Portal, CTO Dashboard, role-separated Admin Console, isolated demo tooling, tests and documentation into a clean develop-based worktree. Core registrations and configuration were applied as focused edits. Inherited hosted-beta work, HTTP mail-provider integrations, unrelated auth-recovery changes, documentation rewrites, data files and private configuration are excluded. No reset, stash, clean or deletion of the original worktrees was performed.

The corresponding changed-file manifest is [employee-access-files.md](employee-access-files.md). The feature branch push is authorized; the CTO's latest instruction postpones opening a PR. Do not merge this checkpoint.

## Onboarding behavior

CTO creation requires explicit confirmation and server-side CTO authorization. Approval creates one idempotent employee record and a durable invitation job. A separately supervised trusted worker polls every five seconds and uses existing Gmail SMTP configuration. The web request does not send mail or receive privileged provisioning credentials. Public HTTPS portal routing and the protected approval database are mandatory before enabling the worker. Local demo email remains disabled.

The welcome message contains approved role/teams, verified TripRaft account signup/sign-in instructions, a single-use 48-hour acceptance link, employee dashboard URL and next steps. Only the matching verified identity can activate the employee. A tab-scoped token survives same-origin signup navigation, is removed from the address bar, and is cleared after acceptance. Tokens are never included in persisted audit/job responses.

Delivery claims and token digests commit before SMTP submission. Database row locks serialize concurrent workers and delivery against revocation. Known safe transient failures retry with bounded backoff. Uncertain delivery or interrupted dispatch requires CTO review; it is never automatically resent. A CTO replacement invitation invalidates the old token. SMTP acceptance is recorded separately from employee activation and does not guarantee inbox delivery.

GitHub remains manual, with mutation/token-generation paths hard disabled. No Supabase credential creation or administrative access is automatically provisioned. Optional individual database-role revocation requires additional explicit CTO configuration and approval.

## Migration requirements

The employee revision is `a714c3202601_employee_access.py`, parent `f63a718293a4`. It adds six control-plane tables, restricts SQL grants and enforces append-only audits. No new delivery migration is necessary; dispatch/retry states use the existing provisioning jobs.

The checkpoint includes missing prerequisite `f63a718293a4_deduplicate_session_index.py` and its matching ORM index correction. This removes one redundant refresh-token index while retaining the existing indexed lookup. It also includes the PostgreSQL-compatible Boolean default in the initial schema; fresh PostgreSQL installation otherwise fails before reaching the employee migration. These prerequisites do not delete application records. Review the complete chain before any shared migration. Do not stamp over an unknown revision or migrate a live/shared database as part of testing.

## Local validation

- Targeted backend/authorization/invitation/migration contract/staff checks: **97 passed**.
- Persistent-worker polling regression: **1 passed** (new approvals process without another CTO command).
- Admin/CTO/employee frontend: **26 tests passed** across five suites.
- Isolated local startup/demo: **23 tests passed**.
- Development proxy and cookie isolation: **3 tests passed**.
- Disposable PostgreSQL: **1 integration test passed**, covering schema parity, preserved application records, upgrade/downgrade/re-upgrade, restricted SQL credentials, immutable audits and two simultaneous workers producing one mocked email. Temporary PostgreSQL was stopped afterward.
- Admin TypeScript, ESLint and production build: **passed**.
- Backend Ruff, Python 3.11 syntax, repository structure and infrastructure/workflow validation: **passed**.

Full backend regression and remote CI results are reported with the final pushed commit. CI runs on the additional feature branch without opening a PR. The deploy workflow runs only on main/tags or an explicit dispatch, and was not invoked.

The first CI PostgreSQL run exposed a timing-dependent concurrency-test assertion: a peer may observe `dispatching` between the durable claim and delivery transactions. The corrected regression verifies one SMTP submission and the final committed `completed` state, allowing that intermediate observation. The corrected test passed again on disposable local PostgreSQL.

The earlier private backup path was unavailable during this checkpoint session; no new backup-restoration result is claimed. Current migration validation used a new empty disposable PostgreSQL cluster and synthetic records. The backup rehearsal tool accepts `--postgres-bin-dir` for a separate local PostgreSQL installation.

## Remaining CTO configuration and approvals

Before real invitations: approve protected control-plane hosting/database roles, the reviewed migration chain, immutable CTO UUID configuration, public HTTPS routing for customer authentication and employee pages on the same origin, Gmail SMTP secret delivery, and installation/startup of the supervised worker. See [employee-access.md](employee-access.md). No secrets are supplied by this checkpoint.

No real invitations, shared/live Supabase migration, GitHub permission change, deployment or merge was performed. The SMTP and GitHub test integrations use mocks. The additional branch is for review only; opening a PR requires the CTO's later direction.
