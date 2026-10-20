# Group Planner crew responsibilities - October 15, 2026

> Historical report. Results, local accounts, file counts and open findings describe the original checkpoint. For current setup and contracts, use the [documentation index](../../README.md). Raw CSV/JSON/ZIP exports referenced here are preserved locally and in earlier Git history; they are not current repository inputs.

Interactive Smartlog checkpoint: `group-planner-crew-responsibilities`.

The uploaded HTML contains Trip Admin, Treasurer, Navigator, and Culture Scout.
The user confirmed that Treasurer, Navigator, and Culture Scout should be extra
responsibilities alongside the existing access roles. Trip Admin corresponds to
the existing Admin access role; Owner remains the protected group owner.

## Result

- Circle keeps Owner/Admin/Member/Viewer access roles and adds a separate
  "Trip responsibility" selector for Treasurer, Navigator, Culture Scout, or
  "Not assigned".
- Owners and admins can assign or clear responsibilities for every active member,
  including themselves and the owner. The owner's access role remains protected.
- Member/viewer views show assigned responsibilities and their descriptions
  without assignment controls. Settings and access-role controls retain their
  existing permissions.
- Responsibility cards explain each job and list the assigned crew members.
  Multiple people can hold the same responsibility. Each person has one optional
  responsibility in addition to their access role.
- Assignments persist through the API and appear in the member response and
  activity timeline. Inactive members are excluded from the active crew list.
- Demo Sarah is Admin + Treasurer, Marcus is Member + Navigator, and Elena is
  Viewer + Culture Scout. Existing saved demo state gains defaults only where a
  responsibility field is missing; explicit assignments and cleared values remain.
- Mobile crew cards use one column so role and assignment controls remain readable.

Responsibilities coordinate the crew's work. They do not change access ranks,
grant admin rights, or change the linked expense group's payment permissions.

## Backend and schema

`TripMember.crew_role` is a nullable string with supported values `treasurer`,
`navigator`, and `culture_scout`. Existing rows remain unassigned. Both the HTTP
route and service enforce active Owner/Admin membership before changing a member
in the same group; unsupported values and inactive targets are rejected.

```text
PATCH /api/v1/group-planner/groups/<group-id>/members/<user-id>/crew-role
Body: {"crew_role": "treasurer"}  // use null to clear
```

Alembic revision `e1f2a3b4c5d6` adds the optional column. It follows
`c9d2e4f6a8b0` and supports fresh installs, upgrades, offline SQL generation, and
downgrade. The additive migration was applied to the local runtime database at
`data/runtime/dev/tripraft.db`. A SQLite backup was saved first in ignored
`.tripraft/backups/trip-member-crew-role-before.db`. The place catalog is unchanged.

## Validation and save

The full frontend suite passed 324 tests across 35 suites, and the full API suite
passed 379 tests. Web lint, TypeScript, production build, backend Ruff, and Git
whitespace checks passed. The existing expense bundle-size and API deprecation
warnings remain.

API coverage verifies each responsibility, owner/admin assignment and clearing,
the fixed owner access role, unchanged member/viewer access after assignment,
direct service authorization, malformed values, cross-group targets, and inactive
members. Migration contract checks validate schema parity, data-preserving
upgrades, fresh install/downgrade/reinstall, and offline SQL.

Frontend coverage checks both Owner and Admin assignment controls and requests,
read-only Member/Viewer views, and demo assignments independent from access.
Headless Chromium checked all four views on desktop and mobile, including assign,
clear, and admin assignment to the owner: eight screenshots, no browser errors,
no document-level horizontal overflow, and zero live API requests. No real member
responsibilities were assigned by browser verification.

Changes are saved locally with the API/schema and Circle UI in separate
checkpoints, followed by validation documentation. Interactive Smartlog reads
the shared repository history. No remote push or deployment is included.
