# Group Planner tabs and demo preview - October 15, 2026

> Historical report. Results, local accounts, file counts and open findings describe the original checkpoint. For current setup and contracts, use the [documentation index](../../README.md). Raw CSV/JSON/ZIP exports referenced here are preserved locally and in earlier Git history; they are not current repository inputs.

Local Interactive Smartlog checkpoint: `group-planner-tabs-refresh`.

The supplied `group_travel_planner_ui (1).html` provides the visual and feature
reference. Its sample scripts are treated as prototype behavior, rather than
instructions to run against the application. The existing Tripraft global
header, navigation, account controls, and logout remain unchanged. The new
workspace starts below that header, with the group hub and cards first.

## Updated tabs

| Tab | Result |
| --- | --- |
| Itinerary | Dated day pills, illustrated stop cards, notes and times, persisted ordering, selected map pins, night map, live trip mode, and a route preview that applies a shorter suggested order through the existing place API. Chat and polls include choosing a poll winner for an itinerary day. |
| Library | Searchable place cards, category filters, place details, a saved shortlist, and a day selector to add chosen places to the itinerary. Partial failures keep unsaved choices available for retry. |
| Logistics | Booking vault, original document preview/download, supported uploads, pre-trip and packing lists, progress, priorities, due dates, and member assignment. |
| Treasury | Complete linked expense ledger, budget progress, per-person totals, settlement suggestions and records, expense creation, and itemized receipt splitting with exact cent allocation. |
| Pulse | Filterable activity timeline with member details, complete pagination, and links to the relevant workspace feature. |
| Circle | Members, owner/admin/member/viewer roles, pending invitations, copyable invite links, group settings, permission matrix, AI consent, and authorized leave/remove/delete controls. |

The manager shares itinerary selection with the map. Other tabs use the full
workspace width. Leaflet is bundled locally; map tiles still use the existing
external provider. The browser can render pins and route overlays over a dotted
fallback when tiles are unavailable.

## Demo preview

Open `/group-planner?demo=1`, select a sample trip, and use the demo person
selector to preview the owner, admin, member, and viewer experience. Three trips
include Kyoto, Lisbon, and the Alps. The sample Kyoto trip contains people,
places, scheduled stops, bookings, packing tasks, expenses, messages, polls,
and an invitation. Travel and avatar photos are bundled in
`apps/web/public/images/planner-demo/` with source credits.

Demo planner requests use a local adapter and isolated query state. Changes
persist in this browser's demo storage and can be reset. Unhandled demo planner
requests are rejected instead of falling through to real APIs. The demo can be
opened without signing in; normal planner routes retain authentication. The
global header continues to reflect the actual signed-in account.

## Backend and permissions

Normal planner actions use the existing group, place, checklist, invitation,
chat, poll, activity, consent, document, and expense services. Checklist routes
now return explicit forbidden responses for viewers and return the updated
completion state. Invitation creation rejects viewers, and pending invitation
listing checks admin access before cached data is returned. Owner checks handle
UUID/string identifiers consistently for member removal, group deletion, and
the prohibition on an owner leaving their own group.

No schema migration or production data seed is required. Expense permissions
continue to follow the linked expense group's own roles.

## Validation

- Web Jest: 308 tests across 33 suites passed.
- API pytest: 368 tests passed, including viewer restrictions, checklist
  metadata/state, and owner lifecycle regression coverage.
- Web ESLint, TypeScript, production build, backend Ruff checks, and Git
  whitespace checks passed.
- Headless Chromium checked all six tabs at desktop and mobile sizes, with
  14 screenshots, no uncaught browser errors, no document-level horizontal
  overflow, and zero live planner API requests from demo mode. Checks also
  exercised voting, adding a poll winner to a day, and role switching.
- The original shared header source and stylesheet have no changes from the
  previous UI checkpoint.

Browser scripts, results, logs, and screenshots remain in ignored
`.tripraft/test-temp/group-planner-ui/`. The browser checks exercise the local
demo adapter; authenticated server persistence is covered by the API suite,
rather than an end-to-end browser run. Existing API deprecation warnings and
the expense bundle-size warning remain; checks pass.

Receipt items are entered manually; automatic OCR is not implemented. Currency
conversion uses a user-entered estimate and does not rewrite the ledger's
currency. Route suggestions compare straight-line distances, rather than road
travel times. Sample booking PDFs and QR codes are clearly marked as demo
content and are not valid travel documents.

## Save

The original header and isolated demo foundation were saved first, followed by
separate local checkpoints for the six tabs, role enforcement, demo refinements,
and this report. Git and Sapling Interactive Smartlog read the same repository
history using the [checkpoint workflow](https://github.com/deeppatel1842/Tripraft/blob/aeb599bd399e7aa0f61cc376b56527c190e4b819/docs/backend-checkpoints.md). No remote
push or deployment is included.
