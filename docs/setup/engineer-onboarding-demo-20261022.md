# TripRaft: demo results and engineer onboarding

> Historical 22 October demo/checklist. Source PRs 13-15 were merged on 23 October and runtime-group grants separately approved. Use [the current readiness addendum](final-onboarding-preparation-20261023.md) for live status; dated observations below remain historical. Personal engineer access is still pending.

22 October 2026. This supplements [the final readiness audit](final-team-readiness-20261022.md).
The CTO requested five synthetic engineers before supplying real identities.
No GitHub account, invitation, live email, shared database grant, public service,
PR, merge or deployment was created by this work.

## Consolidated result

| Classification | Evidence / remaining action |
| --- | --- |
| COMPLETED | Local login persistence fix, five-person demo, current GitHub read-only audit, invitation/setup/collaboration instructions. Existing worktrees reused. |
| VERIFIED | 25 local infrastructure tests; 102 employee API tests; both CTO/Admin updates exercised with actual PostgreSQL temporary tables and rolled back; five direct/frontend/proxy HTTP checks. Five demo engineers accepted invitations once, logged in independently, were denied CTO and another employee's history access; offboarding revoked one session while another remained valid. |
| BLOCKED | Real identities are deliberately not supplied. Shared-role startup, external inbox delivery, independent computers, private HTTPS origin, and encrypted off-machine backups remain operational gates. |
| CTO APPROVAL REQUIRED | Publish the three exact integration branches below; then approve each merge separately. Separately approve review-policy changes, access architecture/grants, network origin, backup destination, and named invitations. |
| DEFERRED | Production/public hosting and portal redesign. The existing portal remains a separate feature branch and is not required to onboard engineers. |

One broader test initially failed because the portable project venv lacked
`cryptography`. Reusing the already-installed `cryptography==50.0.2` from
`.tripraft/employee-python` resolved it without changing dependencies. Final runs
passed in both the active portal source and the saved employee checkpoint.
One PostgreSQL migration-specific test was skipped because its dedicated
`EMPLOYEE_TEST_POSTGRES_URL` was not configured; this is separate from the fresh
PostgreSQL credential round-trip check and earlier verified restoration tests.
Existing Pydantic/Flask deprecation warnings remain non-failing.

Private evidence: `C:/Tripraft/.tripraft/analysis/local-account-persistence-20261022/`:

- `checkpoint-focused-tests.log`: 25 passed.
- `checkpoint-employee-tests.log`: 102 passed, 1 skipped, including the five-person cohort.
- `postgres-account-check.json`: both roles verified; temporary tables only; rollback; public data unchanged.
- `existing-account-status.json`: existing CTO/Admin still use generated demo credentials;
  chosen email/password/name have not been configured. Passwords/hashes are omitted.
- `demo-cleanup.json`: synthetic database directory removed, SMTP mocked, exit 0.
- `github-current.json`: timestamped branch, ruleset, MFA/plan and CI evidence.
- `health-smoke.json` / `.log`: API, traveler/admin frontends and both API proxies
  returned HTTP 200 on 15000/15173/15174. All owned services stopped and ports
  released. The harness explicitly prepared a new disposable SQLite database;
  this did not run migrations against shared development or change the launcher.

The focused login fix and cohort test are saved locally as
`0dfb492ce8abb5da32554882b01b46b55d96b955` on the existing employee checkpoint
branch. The same helper changes are applied in the user's active
`C:/Tripraft/.tripraft/employee-access-portal` worktree. This local commit is not
published and does not belong in the three-PR integration stack below. Existing
dirty portal work was preserved. Local Git/Sapling history does not itself publish
files to GitHub.

For the CTO/Admin chosen-login issue, use the existing private terminal setup
commands in `docs/operations/employee-access.md` within the
employee checkpoint, or the same guide in the active portal worktree. The private
password cannot be chosen on the user's behalf. Retype the two original commands,
enter email/name and hidden password twice, and wait for **saved and verified**.
`--role CTO --check` / `--role Admin --check` then report matching settings without
printing password/hash or restarting services. Use email for sign-in; display name
is not another username. Hash-only storage is intentional.

Tests use disposable SQL/file fixtures. Mock delivery captures invitation content
inside the test process; it does not contact SMTP or demonstrate real inbox delivery.
Temporary cohort identities and queued jobs disappear with the isolated test DB;
there are no demo GitHub accounts or real employee records to remove. The user's
existing local accounts and database rows were preserved.

The earlier 913-test integrated-candidate verification remains evidence for exact
commit `5ef37a2`; it is not a new run against merged develop. A fresh acceptance
run on the actual merged develop revision remains required after integration.

## What is on GitHub now

Canonical repository: [Tripraft/Tripraft](https://github.com/Tripraft/Tripraft).
It is **public**, on the organization Free plan; default branch is `main`.
The organization's MFA requirement is enabled and base repository permission is
`none`. Public code can be read without membership; Write authorization is still
required for team branches. Keep credentials, private databases and employee
rosters out of published commits.

| Published ref | Current commit / purpose |
| --- | --- |
| `main` | `76672c249973c731ea7c5f51b6c09fc7aea58e9e`: stable source |
| `develop` | `809c4beec12de45bf9bf683b2f4cc88c961d9453`: current integration source |
| `feature/development-workflow-setup` | `47d4e34`: earlier workflow documentation |
| `feature/employee-access-onboarding-checkpoint-20261021` | `58813088590f8e19ac276a953cfadd103d933dac`: existing employee portal checkpoint; separate from develop |

The repository includes `apps/web` (traveler React/Vite app), `apps/admin`
(staff console), `services/api` (Flask/SQLAlchemy API and migrations), shared
`packages`, workflows, tests and documentation. A published branch does not imply
its features are merged into develop or deployed. No PR is currently open.

Latest checks observed: [develop CI](https://github.com/Tripraft/Tripraft/actions/runs/39697141440),
[main CI](https://github.com/Tripraft/Tripraft/actions/runs/39697932907), and
[employee checkpoint CI](https://github.com/Tripraft/Tripraft/actions/runs/39824012903)
all succeeded at the commits above. The latest main
[release run](https://github.com/Tripraft/Tripraft/actions/runs/39697932826)
has successful release verification; the earlier audit records skipped deployment.
No new remote run was triggered here.

Both main/develop require an up-to-date `verify` check and block force pushes and
deletion. Develop requires **zero** approvals. Main requires one, code-owner review,
stale-review dismissal, last-push approval and resolved threads, with an
organization-admin PR bypass. Global CODEOWNERS names the CTO; a CTO-authored PR
needs another eligible code owner or an explicitly reviewed exception.

Proposed develop policy: two independent approvals, stale dismissal, last-push
approval and resolved threads; preserve required `verify`, no bypass, blocked
force push/deletion. With three engineers plus CTO this requires scheduling two
eligible reviewers besides the author; one approval is a separate lower-friction
decision. Repository rulesets and CODEOWNERS are supported for this public Free
repository. Moving to a private repository would require reevaluating the plan.
See [GitHub rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
and [review rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).
No policy was changed. Before applying an approved change, save current rules,
apply only the reviewed fields, verify effective rules; rollback restores that
saved configuration and requires a separately authorized change.

## Integrate the existing reviewed code first

Fetch confirmed develop is unchanged; final candidate is 0 develop-only / 3
candidate-only commits. Reviewed cumulative scope remains 39 source paths.

| Order | Branch | Exact head |
| --- | --- | --- |
| 1 | `feature/dev-migration-consistency-20261022` | `83e83ec972a610762f6c2ae455bdb3f12ca04d53` |
| 2 | `feature/password-recovery-integration-20261022` | `7a1e1bd81e7e0681bdee7c7be7e7f35780aeb238` |
| 3 | `feature/team-ready-integration-20261022` | `5ef37a25b6807526f45939b10a82dce0cd58280e` |

After approval, publish these branches and open focused PRs into develop in order.
Wait for CI and a separately approved merge before advancing. Prefer merge commits
to preserve ancestry; reconcile/retest subsequent branches if squash is chosen.
Do not run the intermediate f63 source against shared a74. The old `cadf0a8`
launcher proposal is preserved but superseded. Never stamp/downgrade shared DB.
PR descriptions and rollback constraints are in the final readiness audit.

Publication exposes those reviewed commits in a public repository; no credentials,
DB dumps, local login settings or portal implementation belong in that stack.
Rollback before merge is closing the PR and, if approved, deleting the proposal
branch; publication cannot be assumed confidential or fully reversible. After
merge, review source/schema compatibility before any source revert. A source
revert does not roll back a database. No merge/deployment/grant is authorized by
publication approval alone.

## How to invite real engineers later

Keep these separate for each person:

| Access | What it enables | Who authorizes it |
| --- | --- | --- |
| Personal GitHub account, repository Write | Clone, feature branches, PRs and eligible reviews | CTO approves exact username and repository |
| Application test account | Signup/login, trips, group invitations and expenses | Approved synthetic development identity |
| Unique restricted DB login | The person's local API connects to shared development | CTO approves exact role/target/grants and private delivery |
| Employee portal account (optional) | Employee self-service only | Explicit portal onboarding approval |
| Staff/admin account | Internal business administration | Separate explicit authorization; contributor status is insufficient |

Start with repository-only outside collaborators: repository **Settings >
Collaborators and teams > Add people**, select each approved username and
**Write**, review, then send only after named approval. An organization Member
and approved engineering team with repository Write is an alternative decision;
never assign Owner/Admin. The user accepts the GitHub invitation using their own
account with MFA. Confirm accepted access and eligible review ability.
See [GitHub collaborator invitations](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-outside-collaborators/adding-outside-collaborators-to-repositories-in-your-organization)
and [repository roles](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization).

The portal's GitHub status is manually managed. Creating a portal profile, marking
an invitation sent, or accepting a portal link does **not** invite someone to
GitHub, grant DB access or install their development tools. The existing local
portal's localhost links work only in the CTO-managed local environment. Do not
send them as cross-computer onboarding links. Use the initial GitHub workflow
without requiring portal rollout. Configure/review a reachable private origin
separately before any real application-link test.

## Each engineer's Windows setup

Execute only after all three integrations, compatible a74 source selection and
personal DB provisioning are approved. These are instructions for each engineer's
own computer; the CTO's local venv/settings are not distributed.

Install Git, Python 3.11 and Node 22+, then use a new personal clone:

```powershell
git --version
py -3.11 --version
node --version
git clone --branch develop https://github.com/Tripraft/Tripraft.git TripRaft
cd TripRaft
git switch -c feature/yourname-first-task
py -3.11 start.py --setup
```

Authenticate Git with the person's own account using Git Credential Manager or
their approved SSH key. Never share the CTO's token/key. Setup installs pinned
pnpm 10.34.6, locked dependencies and Python venv and preserves existing files.
For an existing dirty checkout, inspect/preserve work first; do not reset it to
follow the new-clone example.

Privately configure backend `services/api/.env` with the unique approved
development URL, exact `TRIPRAFT_DEV_DB_ROLE`, `TRIPRAFT_DEV_DB_HOST`, TLS and
small connection pools. Preserve generated local signing secrets. See
`docs/setup/windows-team-dev.md` in the integrated source for exact fields.
No secrets in frontend `VITE_*`, Git, terminal history or shared login JSON.
Get an approved catalog snapshot if needed; startup does not create catalogs.
SMTP/AI/Redis are separate approved integrations, not prerequisites for all work.

```powershell
py -3.11 start.py --check
py -3.11 start.py --check-database
py -3.11 start.py --smoke --no-browser
py -3.11 start.py
```

Traveler: `http://127.0.0.1:5173`; API liveness:
`http://127.0.0.1:5000/api/health/live`; staff UI: `http://127.0.0.1:5174`.
Running that UI grants no staff account. Stop with Ctrl+C or
`py -3.11 start.py --stop` from the same clone. The reviewed launcher never
migrates shared data, overwrites work, or stops unrelated processes. Do not use
the older develop launcher or migrating Docker path for this onboarding.

Record per engineer: approved source SHA, prerequisite versions, personal-role
preflight, direct/proxied health, permitted app access and denied staff/outsider
access, first PR/CI/review result, and offboarding owner. No password in evidence.

## Daily collaboration and first PR

```powershell
git status --short --branch
git fetch origin --prune
git log --left-right --oneline origin/develop...HEAD
# Review and commit your own work; integrate the reviewed develop update explicitly.
# On a clean feature branch, if needed:
git merge origin/develop
# Resolve each conflict, inspect the result, and rerun affected tests.
# Abort an unresolved merge with git merge --abort rather than overwriting files.
```

Run `pnpm verify` with the project's Python venv/pinned pnpm on PATH and isolated
test fixtures. Stage only the reviewed task paths, review the staged diff and
commit. After repository access and branch publication approval, push the personal
feature branch and create a PR targeting develop. Request the assigned reviewers,
wait for checks, and have the authorized maintainer merge. Promotion to main is
a separate CTO decision. Shared schema changes need their own approved migration
window; startup/reload never applies them.

GitHub is canonical; optional Sapling Smartlog shows commits/authors locally.
In PowerShell use `sl.exe`, because `sl` is a Set-Location alias. Fetch does not
automatically merge active files. Never set up automatic reset/rebase/pull sync.
Engineers need to fetch and deliberately integrate one another's merged work.

## Shared access, recovery and acceptance gates

The existing runtime SQL proposal is reviewed and locally tested, not applied.
It grants DML on a fixed 40-application-table allowlist and read-only Alembic
bookkeeping, with no owner/admin/DDL/migration privileges. RLS is currently off:
direct SQL can read/change **all granted rows**, including identities. Accept that
only for approved synthetic development data, or choose API-only access/reviewed
row isolation before issuing DB logins. API-only architecture is a design decision;
the current personal-DB launcher does not magically implement it.

Confirm TLS, effective PUBLIC grants/routines, no elevated memberships and pool
capacity for 3-5 engineers. Keep migration credentials private to the CTO. Deliver
unique secrets through the approved private channel; test positive and negative
privileges for every role. Roll back access by disabling that login, revoking its
membership and terminating its sessions after approval; no shared schema rollback.

Run the existing A/B/C cross-computer matrix, then D/E: trip/group invite,
acceptance, shared expense visibility, outsider denials, refresh/logout/recovery,
issuer-correct HTTPS links, and separate realtime checks if Redis is approved.
Local simulated clients are not independent-computer or inbox evidence.

Preserve the verified local dump/source ZIPs. Before onboarding, approve an
encrypted off-machine destination, owner, retention and recovery objectives;
include catalogs, uploads, provider services, role definitions and private settings.
Restore an isolated copy and record results. No backup upload/job/cutover is set up
until the destination and scope are approved.

Offboarding requires separate removal of repository/team access, portal sessions,
DB login/sessions, private network access and per-user secrets. Revoking GitHub
does not delete code already cloned onto the employee's computer. After these
gates pass, approve the named real invitations and first three engineers, then
extend to five. This local demo alone does not establish final team readiness.
