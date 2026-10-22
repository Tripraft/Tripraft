# Employee access portal implementation scope

Updated October 20, 2026 after the CTO postponed automatic GitHub onboarding.

Employee authentication, CTO-only administration, internal team/role assignment, access requests, approvals, expiration, suspension, offboarding and auditing are implemented in the feature worktree. The [operating guide](../operations/employee-access.md) describes configuration, local demonstration, migration review and executor boundaries.

GitHub organization invitations and team memberships are managed manually by the CTO. Username is optional during onboarding. The portal records manually maintained organization/invitation status and GitHub teams with an audit trail. No dashboard requires a GitHub App, API credentials, webhooks or GitHub availability. Existing integration code remains hard disabled; previously queued GitHub jobs cannot execute automatically.

| Phase | Local implementation |
|---|---|
| A: Safety and architecture | Separate feature worktree; relevant local source preserved; customer and supplier authentication retained. |
| B: Models, APIs and authorization | Six additive tables, Alembic revision, dedicated employee sessions, immutable CTO UUID configuration, strict inputs and authorization tests. |
| C: Dashboards | CTO directory/onboarding/role/team management and employee self-service under `/employee-access` in `apps/admin`. |
| D: Approvals and lifecycle | Decisions, more-information/resubmission, renewals, temporary entitlements, expiration, notifications, offboarding jobs and append-only auditing. |
| E: Controlled operations | Queued work, separate trusted executor for portal email/entitlements/optional developer-role disabling, CTO-review SQL drafts and manual GitHub tasks. Automatic GitHub provisioning postponed. |

All development SQL credentials are individual restricted identities for the same tripraft-dev database. Neither a local employee Flask process nor an engineer-writable database is an authoritative approval source. Hosting the protected control plane, auditing the live database grants/schema and provisioning actual identities remain CTO-controlled setup actions.

No live Supabase migrations, production deployments, real GitHub invitations or membership changes, branch pushes or merges form part of this local implementation. Review the migration and rehearse backup restoration before authorizing any database deployment.
