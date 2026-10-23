# Employee access portal implementation scope

Updated October 21, 2026. Automatic GitHub onboarding remains postponed; trusted welcome-email processing is implemented.

Employee authentication, CTO-only administration, internal team/role assignment, access requests, approvals, expiration, suspension, offboarding and auditing are implemented in the feature worktree. The [operating guide](../operations/employee-access.md) describes configuration, local demonstration, migration review and executor boundaries.

GitHub organization invitations and team memberships are managed manually by the CTO. Username is optional during onboarding. The portal records manually maintained organization/invitation status and GitHub teams with an audit trail. No dashboard requires a GitHub App, API credentials, webhooks or GitHub availability. Existing integration code remains hard disabled; previously queued GitHub jobs cannot execute automatically.

| Phase | Local implementation |
|---|---|
| A: Safety and architecture | Separate feature worktree; relevant local source preserved; customer and supplier authentication retained. |
| B: Models, APIs and authorization | Six additive tables, Alembic revision, dedicated employee sessions, immutable CTO UUID configuration, strict inputs and authorization tests. |
| C: Dashboards | Separate CTO `/access-administration`, employee `/employee-access` and website-admin `/admin/login` entry points in `apps/admin`. |
| D: Approvals and lifecycle | Decisions, more-information/resubmission, renewals, temporary entitlements, expiration, notifications, offboarding jobs and append-only auditing. |
| E: Controlled operations | Durable approved work, supervised trusted executor polling every five seconds for welcome email/entitlements/optional developer-role disabling, CTO-review SQL drafts and manual GitHub tasks. Automatic GitHub provisioning postponed. |

All development SQL credentials are individual restricted identities for the same tripraft-dev database. Neither a local employee Flask process nor an engineer-writable database is an authoritative approval source. Hosting the protected control plane, auditing the live database grants/schema and provisioning actual identities remain CTO-controlled setup actions.

The CTO authorized an additional isolated feature-branch checkpoint and push for review. Opening a PR is postponed by the latest instruction. No live Supabase migration, production deployment, real employee/GitHub invitation, membership change or merge is authorized. Review the migration and rehearse backup restoration before authorizing any database deployment. Real SMTP remains disabled until the public portal, protected control plane and trusted worker configuration are separately approved.
