# Develop consolidation — 23 October 2026

The migration, password-recovery and Windows team-startup stack was integrated
through PRs 13–15. This follow-up combines the existing employee portal and local
account-persistence fix with that source, rather than rebuilding either feature.

The engineer launcher stays byte-for-byte identical to the reviewed develop
launcher: no automatic migrations or employee demo startup. To run the separate
local employee demo, use `infra/tools/employee_local_start.py` explicitly.
The account helper remains `infra/tools/employee_local_accounts.py --role CTO`
or `--role Admin`; enter account details privately in your terminal.
Employee session tokens also check the existing recovery version: a successful
password reset revokes prior CTO and employee portal sessions, and signing in
again requires the new password.

Historical recovery revision `a74b8293a4b5` and employee revision `a714c3202601`
remain unchanged. New revision `b825c4202610` joins both; it contains no DDL itself.
Fresh installations and upgrades from either sibling are tested against disposable
databases. The PostgreSQL test also checks schema parity, data preservation,
control-plane isolation, append-only audit history and account/session behavior.

**No shared database upgrade is part of this source merge.** Existing shared
development remains at a74 until a separately approved migration. The combined
application requires the joined schema before shared startup; personal runtime
grants do not include employee control-plane tables. Do not run the combined
application against the old schema, grant portal table access to engineers, stamp,
downgrade, or restore automatic migrations to work around that requirement.

`/data/`, database files/dumps, private `.env` settings, dependencies, local
evidence and backups stay outside publication. Existing local catalogs are
preserved on disk; no catalog contents are part of this integration.

The 23 October readiness addendum and 22 October reports remain historical
evidence. Owner credential rotation, named restricted identities, independent
reviewers, private-origin/cross-computer acceptance and off-machine recovery
coverage remain onboarding gates. The develop review-policy proposal is still
held until reviewers are named. No invitations, database grants or deployment
are authorized by this consolidation.
