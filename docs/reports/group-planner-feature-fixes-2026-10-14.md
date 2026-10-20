# Group Planner feature review and bug fixes

Date: October 14, 2026 (America/Los_Angeles).
Local Interactive Smartlog checkpoint: `group-planner-features-fix`.

## Feature names and scope

| Feature | Name in the app | What was reviewed |
| --- | --- | --- |
| Group dashboard | Group Planner | Creation, selection, names, returning to all groups |
| Scheduled places | Itinerary | Dates, times, notes, removal, budget and trip name/date edits |
| Destination discovery | Library / Local Gems | Places, restaurants, events and adding catalog places |
| Map | Map panel | Valid/zero coordinates, day selection, markers, calendar gaps |
| Conversation | Group chat | Messages, replies, read receipts, optimistic sends and sockets |
| Voting | Polls | Creation, choices, expiry, vote changes, voter names/counts and deletion |
| Tasks and files | Logistics | Checklist updates, assignment contracts and vault access/lifecycle |
| Expenses | Treasury | Linked-group access controls and existing expense regression coverage |
| Activity | Pulse | Poll summaries and refreshing activity after collaborative changes |
| Members | Circle | Membership/role contracts and existing access-control regressions |
| Joining | Invite Friend | Existing invitation and membership regression coverage |
| Assistants | Scout / Crew | Existing consent, chat card and action regression coverage |

This is a source/API/component-test review. It does not claim a manual browser
walkthrough of every feature or external provider integration.

## Fixed issues

| ID | Problem | Result |
| --- | --- | --- |
| GP-01 | Startup rejected an existing SQLite catalog file with no schema. The observed file was 4 KB with no schema objects or records. | Missing files and valid, unmarked files with no schema can initialize. Creation uses a write lock and transaction; failed schema statements roll back. Established incompatible catalogs still fail validation and remain untouched. |
| GP-02 | Local `.venv` referenced a Python 3.11 installation that no longer existed. | Its local configuration now points to the already available workspace Python 3.11 runtime; the original configuration is backed up. No dependency manifests changed. |
| GP-03 | Voting on dated polls could compare SQLite's timezone-naive datetime with timezone-aware UTC and fail. Invalid expiry text was silently ignored. | New expiry values normalize to UTC, stored naive expiry values are interpreted as UTC, expired polls reject votes, and invalid expiry input rejects creation. |
| GP-04 | Repeating a single-choice vote removed and recreated the same vote. | Clicking a selected option toggles it off; selecting another option replaces the previous choice. The response reports no selection after removal. |
| GP-05 | Multiple-choice polls counted the same voter repeatedly because UUID objects were compared with strings. | `voted_by` contains each user once; counts and percentages use unique voters. |
| GP-06 | Regular members could create polls but the delete route required admin; UUID/string creator comparisons could also reject the creator. Every member saw a delete control. | Active members can delete their own polls, other members are denied, and the UI displays deletion only for the creator. |
| GP-07 | HTML removal/whitespace trimming could turn poll choices into empty or duplicate values and leave blank questions. | Poll creation validates the sanitized question and choices before saving. |
| GP-08 | The mounted chat socket did not subscribe to workspace place/poll/checklist/member events. Raw UUID event values could fail JSON serialization. | The existing joined socket refreshes relevant workspace queries and activity, resynchronizes on connection, and broadcasts normalize values through `json_safe`. |
| GP-09 | Editing/removing places and deleting polls emitted no corresponding live event. | `place:updated`, `place:deleted` and `poll:deleted` events refresh other connected clients. |
| GP-10 | Group, place and poll queries displayed only the first API page; checklists stopped after 100 items. | These complete-list views load every reported API page. Later-page errors propagate instead of returning a silently incomplete list. |
| GP-11 | Adding an existing catalog place sent unsupported `place_id`, could send a photo object as a URL, and replaced a zero rating with a fallback. | Requests contain supported fields, photo objects become URL strings, official websites are retained, and zero ratings/coordinates survive. |
| GP-12 | Map and itinerary day numbers compressed gaps between dates. A stop on the fourth calendar day could appear as Day 2. | Both surfaces use the trip start date for calendar day numbering and filtering, with ordered-date fallback when no start date is available. |
| GP-13 | Clearing trip dates sent null values that were ignored; malformed dates and reversed ranges could appear to save successfully. | Empty strings explicitly clear dates. Invalid input and end-before-start ranges reject the update before changing either date. |
| GP-14 | Checklist optimistic updates expected a nested checklist object although the API returns an array. | The actual array envelope updates immediately and restores the original data after a failed request. |
| GP-15 | Back to all groups immediately auto-opened the remembered group. Tab-local editing state could survive switching groups. | Returning clears the remembered selection; changing groups remounts the active tab's local state. |
| GP-16 | Unexpected errors in the poll list route returned a successful empty list. | Unexpected route failures return HTTP 500 instead of masquerading as no polls. |

## Verification

| Check | Result |
| --- | --- |
| Complete backend suite | 348 passed (`.venv/Scripts/python.exe -m pytest -q -p no:cacheprovider --show-capture=no services/api/tests`) |
| Final catalog verification after supporting multiple SQL statements on one line | 12 passed, including one additional edge-case regression |
| Complete web suite | 273 passed across 28 suites |
| Final itinerary/map component verification after memo dependency adjustment | 21 passed |
| Launcher regressions | 6 passed |
| Backend Ruff | Passed |
| Web ESLint and TypeScript | Passed |
| Web production build | Passed |
| Catalog schema, integrity and foreign keys | Passed: 31 logical tables, 0 travel records |
| Launcher prerequisites/setup | Passed |
| Fresh launcher smoke | Blocked by an already running service on port 5173; existing services preserved |
| Existing API/web/admin HTTP checks | HTTP 200 on ports 5000, 5173 and 5174 |
| Git whitespace validation | Passed |

Existing Pydantic/Werkzeug deprecation warnings remain. The web build emits a
bundle-size warning for the expense page; the build succeeds.

The new regressions cover blank/invalid catalogs and rollback, populated-catalog
preservation, poll expiry after SQLite roundtrips, toggling/switching votes,
unique voters, member-owned deletion, sanitized input, place schedule clearing,
group renaming and date clearing, and actual Socket.IO delivery to an authenticated
group member. Component tests cover poll controls/names, socket invalidation and
reconnects, complete pagination, catalog payloads, checklist rollback, calendar
day selection, and map marker filtering.

## Local startup and data

The canonical catalog currently passes schema, SQLite integrity and foreign-key
checks: **31 logical tables, 0 travel records**. An empty catalog provides no
destination discovery results until real travel data is imported. Initialization
does not invent or import records. The original geography import workflow was
documented in local `sql_database/README.md`, which is not published. For the
current checkout requirements, see [local catalog setup](../../services/README.md#local-catalog-setup).

The original local virtual-environment/runtime path configurations and a catalog snapshot are
retained under `.tripraft/backups/group-planner-20261014/`. These local files and
the runtime databases are excluded from the source checkpoint.

`start.py --check` passes. A fresh `start.py --smoke --no-browser` run stopped
because port 5173 was already occupied. The already running API, web and admin
surfaces responded with HTTP 200 on ports 5000, 5173 and 5174; those existing
processes were preserved. This does not prove that the existing API process has
loaded the new Python code. Restart the current TripRaft session to load it:

```powershell
python start.py --no-browser
```

Run that command after stopping the existing TripRaft session normally. The
launcher refuses occupied service ports instead of stopping another process.

## Changed source files

- Startup/catalog: `services/api/init_travel_db.py`, `data/catalog/README.md`.
- Backend: `app/trips/services/poll_service.py`, `travel_group_service.py`,
  `app/trips/routes/gp_polls.py`, `app/trips/models.py`,
  `app/trips/realtime/events.py`, `app/itinerary/services/travel_place_service.py`
  (all under `services/api/`).
- Frontend: `features/trips/jsx/GroupPlannerManager.jsx`, `map/MapPanel.jsx`,
  `tabs/ItineraryTab.jsx`, `features/trips/utils/groupPlannerUtils.js`,
  `features/polls/PollFeed.jsx`, `hooks/useChatSocket.js`,
  `hooks/useGroupPlannerQuery.js`, `services/groupPlannerApi.js`
  (all under `apps/web/src/`; map/tab paths are under `features/trips/jsx/`).
- Backend regressions: `test_canonical_catalog.py`, `test_group_planner_features.py`
  under `services/api/tests/`.
- Frontend regressions: `chatSocket.test.jsx`, `p3Behavior.test.jsx`,
  `pollFeed.test.jsx`, `groupPlannerApi.test.js`, `groupPlannerWorkspace.test.jsx`
  under `apps/web/src/__tests__/`.
- Documentation: this report and `docs/backend-checkpoints.md`.

The checkpoint remains local. Existing unrelated untracked files are preserved
outside this checkpoint. No remote publication or deployment is included.
