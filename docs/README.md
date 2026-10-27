# Developer documentation

Start with the guide for your task. Commands in these guides run from the repository root unless a different working directory is stated. The published source excludes local databases, credentials and data-processing workspaces.

## Current guides

| Area | Guide | Use it for |
|---|---|---|
| Setup | [Start and recover the project](setup/startup.md) | Prerequisites, native/Docker setup, ports, live reload and checks. |
| Setup | [Email](setup/email.md) | Mail settings, invitation delivery states and account verification links. |
| Setup | [Maps and catalog inputs](setup/maps.md) | Planner styles, destination coordinates and external catalog requirements. |
| Architecture | [System overview](architecture/overview.md) | Application/package boundaries, databases, authentication and workflows. |
| API | [Contracts and sessions](api/README.md) | API envelopes, generated types, identity realms and private review endpoints. |
| API | [Personal finance](api/personal-finance.md) | Income, expenses, history, summaries and currency boundaries. |
| API | [Group finance](api/group-finance.md) | Roles, invitations, shared ledgers, settlement and analytics. |
| Guides | [Staff console](guides/staff-console.md) | Configure staff access and review supplier applications/packages. |
| Guides | [Partner agreement](guides/partner-agreement.md) | Agreement versions, agent signatures, protected downloads and evidence. |
| Operations | [Runbook](operations/runbook.md) | Verification, deployment hooks, backup and recovery responsibilities. |
| Operations | [Database releases](operations/database-releases.md) · [Interactive checklist](operations/database-release-checklist.html) | Employee CRUD, automatic development/staging migrations and administrator-approved production releases. |

## Source and design references

- [Apps](../apps/README.md), [services](../services/README.md), [shared packages](../packages/README.md) and [infrastructure](../infra/README.md) explain their files individually.
- [Every published file](files.md) provides the repository-wide inventory.
- [Repository review](repository-review.md) explains what stays published and what was removed.
- [Plans](plans/README.md) describe proposed architecture and release gates.
- [Historical reports](archive/README.md) retain dated implementation and audit evidence.

## Folder conventions

```text
docs/
  README.md              Entry point and reading paths
  files.md               Complete published file inventory
  repository-review.md   Publication decisions and cleanup scope
  setup/                 Installation and integration setup
  architecture/          Current system design
  api/                   Current API behavior and contracts
  guides/                Developer workflows for product features
  operations/            Release, backup and recovery procedures
  plans/                 Proposed work and acceptance gates
  archive/               Dated reports, separate from current instructions
```

Update the owning guide when changing behavior and fix links when moving files. Keep credentials, personal account setup, raw database/CSV exports and compressed report bundles outside published docs. Historical findings are not a statement of current feature status; API source and regression tests establish current behavior.
