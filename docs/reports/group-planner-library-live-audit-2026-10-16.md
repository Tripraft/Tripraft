# Family/friends Group Planner refresh — October 16, 2026

The planner now has separate Places, Restaurants, and Festivals Library sections,
catalog details, and Add to plan with dated or unscheduled stops. Restaurant
filtering happens before pagination, and festivals use the catalog's separate
festivals table. That table currently has no records in the local catalog;
the interface displays an empty state. Only actual saved coordinates produce
map markers. Coordinates are copied into a stop when it is added; a later
catalog import does not rewrite existing trip records automatically.

The map's country/name/coordinate banner and destination-focus button have been
removed. All returns to the selected destination extent. Selected-stop cards
show the name, description, time and day; imagery, category/address blocks and
map-card action buttons were removed. Date dropdowns offer the created group's
dates and Unscheduled, and the API rejects new schedules outside that range.

Chat actions are in a three-dot menu inline with the timestamp. Authors can
edit ordinary text messages; owners/admins can remove other members' messages.
Own-message timestamps use white text against blue. Menus support keyboard
navigation, outside-click dismissal and direction changes near the feed edge.

The workspace header shows the group count and a plain group name. Group cards
open from their content, and have separate leave/delete actions. Deletion
requires typing the group name. The Circle shows the complete active member
list and explains access roles and responsibilities. The shared site header
is unchanged.

## Family access and treasury responsibility

The referenced enterprise implementation plan was used as design context for
the family/friends experience. This checkpoint does not implement enterprise
tenancy, corporate approvals, agency operations, or the entire proposed plan.

- Owner controls trip membership and deletion; Owner/Admin manage settings and roles.
- Members contribute to the shared itinerary, decisions, tasks and messages.
- Viewers read the planner and linked expenses. Message deletion, voting and
  financial writes are denied on the server as well as hidden in the UI.
- Navigator coordinates routes and transport; Culture Scout coordinates local
  experiences. These responsibilities retain the member's access role.
- One lead Treasurer owns linked shared expenses. Assigning a new Treasurer
  replaces the previous lead and transfers existing linked-ledger ownership,
  as explicitly requested. Clearing the duty, downgrading the lead to Viewer,
  or removing/leaving returns treasury ownership to the trip owner.
- Trip Owner/Admin retain expense admin access. Member/Viewer expense access
  matches their trip role. Balances, transaction history and amounts are preserved
  across ownership changes. Linked financial records survive trip deletion.

New treasury creation and membership synchronization use one database transaction.
Failure rolls back the new group and its link. Ownership transfer rejects a
ledger linked to multiple trips or an owner outside the trip, so unrelated
financial groups cannot be taken over through a trip role change.

## Live updates and security findings addressed

Committed ORM changes notify authenticated user rooms for settings, membership,
responsibilities, places, polls, checklists, vault records and linked money changes.
Cache invalidation precedes notification. The frontend refreshes matching group
queries, ignores other groups' events, clears private caches on revocation and
recovers state after reconnect. A disconnected client uses a 15-second fallback;
instant delivery requires an available socket connection. Group IDs are normalized
so vault changes do not miss recipients when IDs arrive as text.

Delivery rechecks active membership and group status, preventing a previously
joined socket from receiving later group data after removal. Private assistant
cards are filtered in REST history, unread counts and socket delivery. User
messages cannot supply reserved assistant metadata or reply to inaccessible or
cross-group messages. The unused socket message-writing endpoint was removed;
the application sends through validated, rate-limited REST endpoints.

Unused legacy destination queries, the unreachable Library marker branch, old
message-delete styles, group-switcher styles and duplicate synchronous AI
handlers were removed. This is a scoped code review and regression verification,
not a guarantee that the entire platform has no vulnerabilities. Cross-worker
delivery and production PostgreSQL behavior require deployment-level checks.

## Verification and local save

- Frontend: 346 tests across 38 suites passed; lint, TypeScript and production build passed.
- Backend: 408 tests passed, including Treasurer-removal and currency regressions.
- Independent authenticated socket clients test private cards, committed changes,
  rollback/savepoint behavior, removed-member revocation, vault and linked expenses.
- Treasury tests cover ownership transfers with unchanged balances, Viewer read-only
  access, trip-date enforcement and complete rollback after a link failure.
- Browser checks use isolated demo state and public catalog reads, with no live
  user-group mutations or invitation delivery. Desktop and mobile screenshots
  are retained under ignored `.tripraft/test-temp/group-planner-ui/`.

Saved locally in Interactive Smartlog on `group-planner-family-currency-refresh`.
No push or deployment was performed. Currency integration and the pasted browser errors are documented in `group-planner-currency-errors-2026-10-16.md`.
