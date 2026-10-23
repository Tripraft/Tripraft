# TripRaft final pre-integration audit and team readiness

Audit date: 22 October 2026, America/Los_Angeles. Scope: finish the existing
engineering setup for 3-5 engineers. No feature rebuild, new worktree, push, PR,
merge, protection change, shared grant/migration, deployment or invitation was
performed. This report supersedes the earlier two-PR sequence.

**Decision: ready for CTO review of the local integration stack; not yet ready
to issue shared-development credentials or start live employee onboarding.**
The source/schema dependency is reconciled locally. The approvals and operational
gates below must be closed before onboarding.

## Consolidated status

| Status | Result | Action |
| --- | --- | --- |
| Completed | Read-only pre-integration inventory; original branch verification; latest fetch/ancestry; existing password-recovery reconciliation; CI/rules audit; runtime proposal; recovery review; cross-computer and onboarding checklists. | Review the three exact proposed commits below. |
| Passed | Prepared-branch focused suite: 47. Reconciled full verification: 913 tests plus lint/type checks/builds. Forced Turbo run excludes cached task evidence. 19 PostgreSQL permission/journey checks, six recovery checks, five isolated HTTP/proxy checks, schema parity and real dump restoration pass. | Evidence and commands below. Counts are not additive across overlapping suites. |
| Failed | No current functional test failure. As supplied, the two prepared branches failed the shared-schema compatibility gate at f63 versus a74; the new local stack resolves it. Develop's independent-review gate is still unmet (zero required approvals). | Publish only the complete reviewed stack; obtain a separate decision on develop review policy. |
| Blocked | Live engineer-role startup, cross-computer email/link/realtime validation, approved identities and private credential delivery, and off-machine recovery coverage are unproven or not provisioned. | Assign CTO/engineering owners and execute the bounded checklist after approval. |
| CTO Approval Needed | Exact PR sequence; runtime privileges and access mode; 3-5 identities; reachable private origin/optional Redis; backup destination/retention; any ruleset change. | Approval to one action does not authorize another. |

## 1. Read-only pre-integration audit

The two requested refs match exactly and remain unchanged:

| Branch | Verified full commit | Parent / latest-develop comparison |
| --- | --- | --- |
| `feature/dev-migration-consistency-20261022` | `83e83ec972a610762f6c2ae455bdb3f12ca04d53` | Parent `809c4beec12de45bf9bf683b2f4cc88c961d9453`; 0 develop-only / 1 branch-only commits |
| `feature/windows-team-dev-integration-20261022` | `cadf0a85d458cc9beaf63c3ecd8f97497c33c33a` | Parent `83e83ec`; 0 develop-only / 2 branch-only commits |

`git fetch origin --prune` completed after checking that no active custom hook
was configured. Latest `origin/develop` is still
`809c4beec12de45bf9bf683b2f4cc88c961d9453`; the GitHub branch API independently
confirmed this SHA. The merge base for both prepared branches is that develop
commit. Existing open PR listing was empty at audit time. No unconditional
pull/rebase or source/index changes were used for the audit.

Ten registered worktrees were recorded, including the employee checkpoint now
at `58813088590f`. That is pre-existing work observed at the start of this audit;
it was not integrated or overwritten. No worktree was added or switched. Final
preservation evidence compares this audit's initial HEADs, statuses, index entries
and changed-source hashes; it does not assume earlier handoff snapshots remain
the user's current state.

The original migration proposal changes four text files; the launcher adds ten
more. No database, dump, ZIP, private `.env`, dependency cache, employee access
portal, or private login file is in those deltas. Credential-pattern matches were
reviewed: they are the compile-only localhost password fixture, synthetic
`private-password` credential-test string and documented `.env.example`
placeholders. No actual credential was identified. This is a scan/review of the
proposed files, not a certification of all historical Git objects. The open
`test-logins.json` was not read, copied, or included.

## 2. Migration and password-recovery reconciliation

The prepared source ended at `f63a718293a4`; shared development is already at
`a74b8293a4b5`. The missing revision adds nullable `users.password_reset_version`,
which belongs with recovery endpoints, token issuance/validation, refresh/session
revocation, WebSocket validation, email delivery support, UI and their tests.
Copying just a migration or stamping a database would not reconcile that behavior.

Reused the existing 27-path change from `7cc003510d53`, via reviewed three-way
hunks in the existing ignored source snapshot. It merged without conflicts,
retained the f63 token-index fix and historical-schema fixture repair, and
introduced no unrelated ancestors. Only its historical documentation was adapted
to state that the new launcher never applies migrations.

Verified chain: `e52f60718293 -> f63a718293a4 -> a74b8293a4b5`, one head.
`refresh_token` remains `VARCHAR(500) NOT NULL` with exactly the explicit
`idx_user_sessions_token` index. Fresh disposable PostgreSQL, a new restore of the
actual project dump, and current shared schema introspection all match the
reconciled models at a74 with **zero metadata differences**. Shared inspection
used server-enforced read-only transactions; no upgrade, downgrade, stamp or
data mutation was executed against Supabase. Tests applied migrations only to
new disposable local databases.

## 3. Precise PR sequence for approval

Use merge commits to preserve the reviewed stack ancestry. If squash is selected,
reconcile and retest the next branch against the actual merged base before its
PR; do not force-push or assume a changed parent SHA is equivalent. Target all PRs
at develop, one at a time. Hold engineer onboarding until all three are merged
and the final a74 source is selected. Do not point intermediate f63-only code at
the existing shared database.

| Order | Proposed title | Source branch / exact head | Scope |
| --- | --- | --- | --- |
| 1 | Repair PostgreSQL baseline and deduplicate refresh-token index | `feature/dev-migration-consistency-20261022` / `83e83ec972a610762f6c2ae455bdb3f12ca04d53` | Four migration/model/test files; parent latest develop |
| 2 | Integrate existing password recovery and align schema at a74b8293a4b5 | `feature/password-recovery-integration-20261022` / `7a1e1bd81e7e0681bdee7c7be7e7f35780aeb238` | 27 existing recovery paths; parent `83e83ec` |
| 3 | Layer verified Windows team startup on the reconciled recovery schema | `feature/team-ready-integration-20261022` / `5ef37a25b6807526f45939b10a82dce0cd58280e` | The ten already-reviewed launcher paths; parent PR 2's exact head |

The original `cadf0a8` remains a preserved proposal/reference, not the final PR 3
head. The replacement stack includes recovery and has been tested together.
Local commit preparation used private temporary indexes; no existing worktree's
index or branch was reset or rebased. Complete exact-path manifests are retained
with `reconciled-commits.json` in the evidence directory.

All 682 files in the final saved source tree match the tested snapshot; the
cumulative diff against latest develop has 39 reviewed paths and no workflow
changes. A final fetch still returned the same develop SHA (0 develop-only / 3
candidate-only commits). All nine other worktree HEADs, statuses, index entries
and previously changed-file hashes match this audit's initial inventory.

PR 1 body: PostgreSQL fresh install rejects the integer Boolean default and the
session model declares duplicate lookup indexes. Use `sa.false()`, retain the
token column and explicit index, and include the reversible f63 migration with
data-preserving regression coverage. Tests: 16 migration checks in the focused
suite and final full verification. It does not itself make f63-only source usable
with an already-a74 environment.

PR 2 body: Align source history and the password-reset version model with existing
a74 shared development, carrying the already-implemented recovery endpoints,
single-use tokens, session revocation, UI, delivery support and generated API
contracts together. Tests cover known/unknown account responses, validation,
expired/tampered/replayed tokens, new-password login and old HTTP/refresh/WS
rejection. Reuses existing code rather than rebuilding recovery.

PR 3 body: Preserve settings/catalogs, require read-only personal-role preflight,
remove automatic startup/reload migrations, reject the migrating Docker path and
stop only owned verified processes. Retain current develop CI and release-verify.
Tests: launcher/gate/reload regressions, complete verification and isolated
frontend/API/admin HTTP/proxy smoke. Live approved Supabase engineer startup is
a separate gate, not inferred from a synthetic local test.

Rollback for all proposals: revert source only after reviewing resulting source
and target-schema compatibility. A source revert is not a DB rollback. Do not
run f63 source against an a74 database after reverting PR 2; select a compatible
source checkpoint instead. No shared downgrade/stamp is proposed. If the launcher
is reverted, do not run its old automatic-migration behavior against shared dev.
Preserve backups and obtain separate approval for any database recovery/cutover.

## 4. Exact test evidence

Evidence directory: `C:/Tripraft/.tripraft/analysis/pre-integration-20261022/`.
Source snapshot: `C:/Tripraft/.tripraft/analysis/phases-p3-p7/integration`.
Python 3.11.4, pinned pnpm 10.34.6 and the existing lockfile were used. Explicit
import roots and disabled private dotenv/provider settings prevented accidental
testing of the original dirty source or shared data.

| Command/check | Actual result | Evidence file |
| --- | --- | --- |
| Prepared source: `pytest services/api/tests/test_migration_contract.py infra/tests/test_launcher.py infra/tests/test_dev_database.py services/api/tests/test_dev_reload.py -q --basetemp=.../prepared-temp` | 47 passed, exit 0 | `prepared-tests.log`, `prepared-tests-exit.txt` |
| Reconciled `pnpm verify` | Exit 0; structure, infrastructure, lint, type checks, tests, builds | `reconciled-verify.log`, `reconciled-verify-exit.txt` |
| `pnpm exec turbo run lint typecheck test build --force` | Exit 0, no cached tasks; backend 477, traveler 402, admin 9; both production builds | `forced-verify.log`, `forced-verify-exit.txt` |
| Infrastructure unittest discovery inside `pnpm verify` | 25 passed; with the above, 913 distinct tests in the combined check | `reconciled-verify.log` |
| OpenAPI export and `pnpm api:generate` | Exactly matches existing recovery commit's generated contracts; four canonical/discovery workflows unchanged | `openapi.log`, `api-generate.log`, `contracts-workflows.json` |
| `verify_dev_postgresql.py --source-root .../integration --port 55439 --user handoff_owner --data-directory .../postgres-data --output .../postgres-journeys.json` | 19 actual permission/API checks passed | `postgres-journeys.json`, `.log` |
| Additional restricted-PostgreSQL recovery check | Six checks passed: reset, replay denial, old-token rejection, password change, new refresh, old WS denial | `postgres-recovery.json`, `.log` |
| Isolated API/web/admin HTTP smoke | Five HTTP 200s on 15000/15173/15174, direct and proxied health; owned services stopped | `health-smoke.json` |
| Existing configured localhost health | Read-only GET results on 5000/5173/5174; separate from the tested candidate | `existing-local-health.json` |
| Fresh/restored PostgreSQL schema parity | a74 head, zero drift, token column/index intact | `schema-parity.json` |
| Current shared schema metadata | Read-only, a74 head, zero drift; no shared mutations | `shared-schema-parity.json` |
| New isolated restore of existing dump | 41 tables; row counts exactly match archive; zero invalid indexes or unvalidated constraints | `restore-report.json` |

Existing dependency deprecations, React test warnings and Vite large-chunk
warnings remain non-failing. No real outbound email, paid AI request, browser
cross-computer E2E or shared-development write test is claimed. An early verify
attempt started before source preparation finished and was stopped; its
`final-verify.log` is explicitly discarded evidence. The completed reconciled
and forced runs above are the authoritative runs.

## 5. GitHub ruleset and CI enforcement

GitHub connector was unavailable; installed `gh` made read-only API calls.
Current develop CI at `809c4be` has successful `verify`:
[run 39697141440](https://github.com/Tripraft/Tripraft/actions/runs/39697141440).
Current main CI at `76672c2` succeeded:
[run 39697932907](https://github.com/Tripraft/Tripraft/actions/runs/39697932907).
Its [release run 39697932826](https://github.com/Tripraft/Tripraft/actions/runs/39697932826)
has successful `release-verify` and skipped `deploy`. Repository
`DEPLOY_HOOKS_ENABLED` is unset. No new CI run was triggered by this local work.

| Control | develop | main |
| --- | --- | --- |
| Active ruleset | 25587363 | 25440648 |
| PR and up-to-date `verify` required | Yes | Yes |
| Required approvals | **0** | 1 |
| Code-owner approval | No | Yes |
| Stale approval dismissal / last-push approval | No / No | Yes / Yes |
| Resolved threads | No | Yes |
| Force-push/deletion | Blocked | Blocked |
| Ruleset bypass | None | OrganizationAdmin, PR mode |

CODEOWNERS assigns `@deeppatel1842` globally. Main also has legacy push restrictions
to that account with `enforce_admins=false`; do not claim admin bypass is impossible.
Proposed separate decision: require at least one independent develop approval
and decide stale/last-push review settings for 3-5 engineers. Nothing was changed.
Keep `release-verify` in the release workflow; do not make a main-only post-merge
job an impossible PR prerequisite. Existing PRs 11/12 are already merged.

## 6. Restricted Supabase implementation proposal

Read-only re-audit: 41 public tables, a74 revision; `tripraft_dev_runtime` is
NOLOGIN, has no elevated flags/memberships, effective public-table reads/writes,
ownership or callable non-system SECURITY DEFINER routines. RLS is disabled on
all 41 public tables. Merely issuing logins will not grant runtime access.

Review `infra/sql/dev-runtime-proposal.sql` from the existing operations checkpoint:
fixed 40-application-table SELECT/INSERT/UPDATE/DELETE allowlist, CONNECT and
schema USAGE, SELECT-only Alembic bookkeeping; no future-table grants, owner
membership, administrative flags, TRUNCATE, DDL or migration writes. UUID schema
needs no sequence grant today; any future sequence needs an explicit USAGE grant.
The guarded SQL and real positive/negative privilege checks passed only on
disposable local PostgreSQL. No Supabase grant was applied.

CTO implementation order after separate approval: (1) confirm development target
and synthetic-only data, (2) choose API-only access or accepted raw-DML access /
reviewed RLS, (3) inspect PUBLIC/effective grants and callable routines, (4) apply
reviewed runtime grants using the private migration identity, (5) create 3-5 unique
non-owner roles without admin options, initially NOLOGIN, (6) set unique secrets
through the approved private process, (7) enable LOGIN and prove allowed/denied
operations plus startup preflight for each engineer. Never put passwords in SQL,
chat, source, frontend VITE variables or a shared test-logins file.

Raw DML can access all granted rows; API user permissions do not constrain direct
SQL. Use API-only access if that is unacceptable. Keep CTO migration credentials
separate. Require TLS, exact approved endpoint/role, private rotation/offboarding
and no administrative memberships. Offboarding disables LOGIN, revokes membership
and terminates that identity's sessions under separate approval.

Budget up to 4 pooled connections per API process using current settings: up to
20 for five single API processes, potentially 40 during overlapping reloads,
plus preflight/tools/workers. Confirm the actual project/pooler budget before
issuing 3-5 logins. Do not solve capacity by copying privileged credentials.

## 7. Cross-computer validation plan (not yet executed)

Owner A, invited member B and outsider C use three distinct machines/accounts;
engineers D/E join the same matrix when five are provisioned. Record source SHA,
approved origin, role names (no passwords), timestamp and sanitized outcomes.

| Step | Expected outcome / required evidence |
| --- | --- |
| A/B/C independently start exact approved code | Personal-role preflight and direct/proxied health pass; no migration or unowned-process stop |
| Signup, login, logout, refresh | Separate sessions; expired/logged-out credentials rejected; no credential copying |
| A creates trip and expense group, invites B | B sees the intended group/trip and existing ledger after accepting exactly once; C is denied |
| A adds an expense; B reads it from a second computer | Same amount/currency/splits and persisted balances; C cannot read/delete; capture both views |
| B edits an allowed item or records a permitted settlement | Authorization and ledger effects match; forbidden member/outsider actions fail |
| Verification and password recovery | Approved mailboxes receive issuer-origin links; one-hour/replay/old-session cases pass without exposing tokens |
| D/E repeat and one user is offboarded | Provisioned users pass; revoked login and prior DB sessions fail after CTO revocation |
| Live updates | Test separately with approved Redis fanout if separate API processes are used; persistence/refetch success alone is not realtime evidence |

Shared PostgreSQL does not make `127.0.0.1` on A reachable from B. Approve a private
HTTPS frontend/API origin via an existing approved network/reverse proxy, or a
separately authorized private tunnel, before testing delivered links. Configure
FRONTEND_URL, CORS, cookies and trusted proxies for that exact origin. No public
binding, tunnel or deployment was enabled. Recovery/verification JWT links must
return to the issuing API; do not copy signing secrets between laptops to work
around issuer mismatches. Database-backed invitation IDs can be inspected in
an approved local route, but that does not prove real emailed-link reachability.
Redis is the existing cross-process Socket.IO message queue; these isolated tests
disabled it. Optional integrations need explicit owners and bounded test access.

## 8. Backup and restoration coverage

Verified dump remains `C:/Tripraft/.tripraft/private-backups/tripraft-project-20261022T170438Z.dump`,
117,418 bytes, SHA-256
`512d63a186a3c5cb59f17d8e01ecd57433c6bdd6bc969d935195c467d1bc9da1`.
Hash was rechecked, the dump restored again into a fresh local database and
all 41 restored table counts matched archive COPY records. It contains the public
application schema/data at a74, not cluster roles/grants, managed Supabase
auth/storage, uploaded files, private settings or local SQLite catalogs.

The earlier 673-file cadf source ZIP still passes CRC/hash but predates recovery.
A new exact reconciled source ZIP is recorded in `candidate-source-backup.json`
with the final source commit, SHA-256 and CRC verification. The new ZIP is
`C:/Tripraft/.tripraft/private-backups/tripraft-team-ready-5ef37a2-source.zip`
(682 files; SHA-256 `071ba9c8e03e688ea52481ed42e35ec09c38057074c84943507a5db4fa17ab0e`). Source ZIPs do not
preserve ignored settings or Git history and are not a substitute for DB recovery.

Before onboarding, assign backup owner, recovery time/point expectations, encrypted
off-machine destination, access/retention policy (proposed seven daily/four weekly
plus pre-migration copies), and a restoration exercise schedule. Back up catalogs
consistently with SQLite's backup API, and cover uploaded files/provider-managed
services/role definitions/secrets separately. Do not auto-delete the only verified
copy. No off-machine upload, retention job, shared restore or cutover was performed.

## 9. Employee/engineer onboarding readiness checklist

- [x] Preserve existing work and verify exact implementation history.
- [x] Reconcile a74 recovery source locally and test permitted/denied API journeys.
- [x] Verify current CI, rules and both source/runtime DB recovery evidence.
- [ ] CTO approves and integrates the three exact source proposals.
- [ ] CTO names 3-5 engineers and approves minimum repository access; require the
  organization's MFA/SSO and private credential-delivery process before invitations.
- [ ] Assign feature branches/review partners; decide develop's independent-review
  policy. Do not issue shared Git credentials or enable auto-reset/rebase sync.
- [ ] Each engineer installs Git, Python 3.11 and Node 22+, uses pinned pnpm setup,
  preserves existing files, and starts the approved source without migrations.
- [ ] Approve API-only versus raw-DML access and provision/validate each unique
  restricted identity, connection budget and revocation procedure.
- [ ] Grant staff-console access only to active verified accounts with explicitly
  approved ADMIN_EMAILS/roles. Being a code contributor does not authorize app-admin
  access. Private manual test accounts are not onboarding credentials.
- [ ] Approve reachable private origin/mailboxes/optional Redis and execute the
  A/B/C cross-computer matrix, then D/E as applicable.
- [ ] Configure and independently verify encrypted off-machine backup coverage,
  recovery owners and missing asset/provider scopes.
- [ ] CTO accepts remaining documented limits and authorizes invitations separately.

No Employee Access Portal features were rebuilt or integrated. Portal/onboarding
feature work, production hosting/release, full browser E2E, PostgreSQL-in-CI and
security/AI evaluation remain in their existing scopes/issues (QA 2-9); they are
not silently marked complete by this setup audit.

## 10. Approval request and immediate next steps

Approve or revise the exact three-PR sequence in section 3. Publication is the
next code action only after your explicit permission. Separately decide the
access mode and reviewed grants, develop review policy, three initial engineer
identities, private origin/email/Redis test scope and off-machine backup owner.
After those decisions, perform per-engineer startup and the cross-computer
acceptance matrix before authorizing onboarding of all 3-5 engineers.

All current evidence, prepared commit manifests and local backups stay private;
the report and reviewed source are saved in local Git/Sapling history. The two
original proposal refs remain exactly as supplied. No remote write or shared
database mutation is part of this handoff.
