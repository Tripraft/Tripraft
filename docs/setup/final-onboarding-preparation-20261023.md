# TripRaft final onboarding preparation — 23 October 2026

Scope: finish the existing setup for 3-5 engineers without production deployment.
This is the current operational addendum to the dated
[22 October audit](final-team-readiness-20261022.md) and
[demo/onboarding guide](engineer-onboarding-demo-20261022.md). Historical evidence
in those reports is preserved; the source-publication statuses below supersede
their earlier local-only status.

**Decision: core source integration is complete and verified. Shared engineer
onboarding is not yet accepted: personal identities, credential rotation,
independent review coverage, live cross-computer acceptance and off-machine
recovery coverage remain gates. No engineer was invited or provisioned.**

## Consolidated status

| Classification | Result |
| --- | --- |
| COMPLETED | All three approved source PRs merged in order; exact reviewed ancestry retained; restricted runtime-group grants applied only after separate CTO approval; local Sapling bookmark repair; separate employee/docs proposals and per-engineer acceptance template prepared. |
| VERIFIED | Actual develop `f23b385` passed fresh GitHub CI: 913 tests plus lint/type checks, builds and generated-contract verification. Its entire tree matches reviewed candidate `5ef37a2`. Runtime effective ACL checks pass for 40 application tables plus SELECT-only Alembic. Sapling labels match Git across installed/portable fresh processes; original metadata/undo history and all worktrees/indexes preserved. |
| BLOCKED | No approved engineer identities or private credential delivery; no personal LOGIN/startup acceptance; no independent-computer/inbox/private-origin/realtime acceptance; no approved encrypted off-machine backup destination. CTO database password rotation is required through the private CTO credential process. |
| CTO APPROVAL REQUIRED | Credential rotation with authenticated Supabase management access; named restricted roles and invitations; develop review-policy activation (held until reviewers are named); private origin/optional integrations; off-machine backup ownership/retention; separate docs or portal publication/integration. |
| DEFERRED | Production hosting/deployment, public exposure, custom portal redesign. Existing portal integration is separate and not a prerequisite for initial engineering work. |

## Approved GitHub integration

Repository: [Tripraft/Tripraft](https://github.com/Tripraft/Tripraft), public.
All publications, PR creations, ancestry updates and merges below had separate
explicit CTO approvals. No force push, squash/rebase, main promotion, deployment,
shared migration, stamp or downgrade was performed.

| PR | Reviewed source | Actual PR head | Merge commit into develop | Required CI |
| --- | --- | --- | --- | --- |
| [13](https://github.com/Tripraft/Tripraft/pull/13) | `83e83ec972a610762f6c2ae455bdb3f12ca04d53` | same | `5684d85dfcfe753ca4cbc206a309208c6cc01150` | [39866677312](https://github.com/Tripraft/Tripraft/actions/runs/39866677312), passed |
| [14](https://github.com/Tripraft/Tripraft/pull/14) | `7a1e1bd81e7e0681bdee7c7be7e7f35780aeb238` | `97f5d7e5692ea0564f7f2bcdfa3c9fc75f930ae2` | `fc57320ac5d1199373d0616b36dbaa05ffbf1cd5` | [39867596102](https://github.com/Tripraft/Tripraft/actions/runs/39867596102), passed |
| [15](https://github.com/Tripraft/Tripraft/pull/15) | `5ef37a25b6807526f45939b10a82dce0cd58280e` | `09a5be5e0dc4672b3890a5cee6daf8d6da42bfc1` | `f23b385abf04a0c531ac871b25a7f23d3fdd2895` | [39868249225](https://github.com/Tripraft/Tripraft/actions/runs/39868249225), passed |

The strict up-to-date rule required merging the newly approved develop ancestry
into PRs 2/3. Those reconciliation commits preserved the original reviewed
commits as parents and had identical trees to their reviewed source. The final
develop tree is `028d0d697812f7a5a04ae30d6cf9f24d27212e7e`, identical to `5ef37a2`.
All three original commits remain ancestors. Main stays at `76672c2`; no main
write or release was requested.

The [actual post-merge develop CI run 39987071243](https://github.com/Tripraft/Tripraft/actions/runs/39987071243)
passed on exact `f23b385`: infrastructure 25, backend 477, traveler 402, admin 9
= **913 tests**. Lint, type checks, production builds and generated API declarations
also passed. This is fresh CI on the merged revision, not only an earlier snapshot.
Previously completed demo/restore suites were not rerun to inflate evidence.

Existing dirty CTO checkouts were preserved. They were not switched/reset to
develop. Engineers should use their own clone of the approved develop source.

## Restricted development access

On 23 October, the CTO explicitly confirmed the audited Supabase project contains
approved synthetic development data and approved the existing runtime SQL.
Applied only `dev-runtime-proposal.sql`, SHA-256
`a3da6854df4a2c15cacaedaa5d9e6351ece0663a93c9bdee6800377e73526df3`.

`tripraft_dev_runtime` remains NOLOGIN, with no elevated flags, ownership or
inherited administrative role. CONNECT/public USAGE, CRUD on the fixed 40
application tables and SELECT-only Alembic bookkeeping are now granted. No future
table/default grants, public DDL, TRUNCATE, grant options or migration writes were
added. No engineer LOGIN, password or membership was created; no application row
or schema change was performed. TLS 1.3 was verified to the pooler; provider
upstream TLS and actual pool quotas are separate operational properties.

Before/after ACL snapshots and effective privilege checks pass. The existing
CTO `postgres` membership has ADMIN true, INHERIT false and SET false; it was
preserved. Its expected `SET ROLE` denial prevents using that session to pretend
to be a provisioned engineer. Actual runtime-session/positive-negative journey
acceptance remains pending named personal roles. Earlier disposable PostgreSQL
permission/journey results remain separate evidence; no shared row-write tests
are claimed here.

RLS is off. Direct SQL access covers every granted row, including identities and
sessions. The CTO accepted this scope for the confirmed synthetic project; it is
not suitable evidence for production row isolation. Per-person roles still need
exact approval, private secrets, explicit membership options, TLS/host/role checks,
pool capacity and revocation tests before LOGIN is enabled.

Owner credential rotation/reconnection must be completed through the CTO private management process before engineer credentials are issued. Do not share owner credentials or paste them into chat. Private incident/connection details are excluded from this publication proposal.

## Review policy and Sapling

The fresh GitHub audit finds organization MFA enabled, base repository permission
none and only one collaborator eligible to review. Develop currently requires
up-to-date `verify` but zero approvals; main's existing CTO controls remain.
A ready-to-review develop JSON proposal changes approvals to two, dismisses stale
approvals and requires last-push approval/resolved threads, retaining no bypass
and blocked force push/deletion. Activation needs explicit approval and deliberately
blocks new merges until two eligible reviewers besides the author are available.
On 23 October, the CTO explicitly directed: "Hold until reviewers are named."
The proposal remains unapplied; develop retains zero required approvals. No GitHub
policy, membership or invitation change is authorized by this decision.
Independent GitHub reviews are not claimed for the initial CTO-approved stack.

The local Sapling issue is repaired through a workspace-only compatibility
extension configured in `.git/sl/config`. It reads authoritative local Git branch
values and reports missing Windows paths via Python; it does not move branches,
contact remotes, fabricate journals or bypass transactions. Installed and verified
portable Sapling resolve the four prepared/checkpoint labels across fresh processes.
The original metadata/undo cache was restored after diagnosis and preserved in a
private backup. Program Files and global PATH were unchanged. In PowerShell use
`sl.exe` (not the `sl` Set-Location alias), or `.tripraft/tools/sl.ps1`.

## Separate employee and documentation proposals

`0dfb492` remains the local five-path fix on the existing employee checkpoint,
based on published `5881308`. It depends on the existing portal implementation.
Its cumulative portal proposal spans 83 paths and has two core-integration
conflicts: `start.py` and `test_migration_contract.py`. Employee a714 and recovery
a74 are sibling revisions from f63; a naive merge yields two heads. A future
reviewed additive merge revision must retain both histories and be tested from
each head; do not reparent, stamp or downgrade existing databases. Preserve the
migration-free core launcher and isolate portal/mail/control-plane startup.
This proposal is reviewed for dependency/scope, not certified merge-ready.

`a2e06b1` is documentation only. Its guide plus the referenced dated audit are
prepared together with this current-status addendum as a three-path docs-only
proposal against actual develop. The private-index scope/whitespace checks pass;
private operational details are redacted and the old guide has a historical-status
banner. Do not merge its whole checkpoint branch to obtain those documents. Publication/PR/merge
for those documents and for the portal are separate decisions.

The earlier five-person demo remains 102 passed employee API tests, 25 local
setup tests and two temporary PostgreSQL credential updates; one dedicated
PostgreSQL migration test was skipped. All five synthetic identities and queued
jobs disappeared with the temporary DB; delivery was mocked, and existing local
accounts were preserved. Those counts are not a claim about the combined portal/
core proposal or independent computers.

## Remaining engineer acceptance

1. Complete the private CTO credential rotation and verify reconnection.
2. Approve 3-5 named GitHub users/work identities, repository Write access and
   individual restricted development roles. Do not distribute CTO credentials,
   private login JSON, signing secrets or admin privileges.
3. Activate the approved develop policy at the chosen bootstrap point and assign
   eligible reviewers. No shared Git credentials or automatic reset/rebase sync.
4. Each engineer uses their own clone, Python 3.11, Node 22+ and pinned pnpm
   10.34.6. Follow the integrated `docs/setup/windows-team-dev.md`: setup, personal
   private settings, read-only DB preflight, startup smoke, start and owned stop.
5. Execute per-engineer positive/negative permissions, direct/proxied HTTP health,
   first scoped feature PR, CI and review. Staff/admin authorization stays separate.
6. Approve a reachable private origin/mailboxes/optional Redis, then complete the
   A/B/C cross-computer trip/group/expense/invitation/recovery matrix; extend to
   D/E. Do not infer link delivery, issuer compatibility or realtime from one
   machine's API tests or shared PostgreSQL alone.
7. Approve encrypted off-machine backup destination, owner, retention and recovery
   objectives. Preserve the already-restored local dump/source ZIPs. Include
   catalogs, uploads, provider-managed data, role/ACL configuration and private
   secrets separately; current ACL snapshots cover the newly applied grant delta.
   No off-machine job, deletion, shared restore or cutover was performed.

## Saved evidence

Private directory: `C:/Tripraft/.tripraft/analysis/final-onboarding-prep-20261022/`.
Receipts: `publication.json`, `pr1-merge.json`, `pr2-publication.json`,
`pr2-merge.json`, `pr3-publication.json`, `pr3-merge.json`.
Actual CI: `actual-develop-ci.json` / `.log`. Runtime:
`runtime-grants-approval.json`, `runtime-acls-before.json`,
`runtime-acls-after.json`, `runtime-grants-acceptance.json`,
`runtime-readonly-validation.json`. The initial session-probe failure is retained
in `runtime-grants-result.json` with its ADMIN/SET explanation.
Sapling: `sapling-repair.json`, `repaired-smartlog.txt`, original metadata/config
backups and the extension hash. Prepared approvals: runtime/policy JSON/SQL,
`employee-integration-proposal.md`, `onboarding-documentation-proposal.patch`,
`engineer-acceptance-template.md`. Private artifacts and settings are not published.
The private `credential-rotation-handoff.md` records the owner-only password-reset
step; it contains no password or token.
