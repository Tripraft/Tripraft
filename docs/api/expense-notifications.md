# Expense notifications

Expense updates now have a durable private inbox, separate from transient live
refresh. Every active member except the actor receives updates for expenses added,
edited, deleted and restored; settlements recorded and deleted; group settings
and currency changes; and membership and member role changes. Converted receipts
include their source amount, currency and saved rate in the expense update.

The expenses header shows the total unread count. Each group card shows a bell
and clickable count beside its name. The selected group's **Group activity**
button opens, scrolls to and focuses the **Activity & history** tab. The inbox
shows unread cards only, with all-groups or single-group filters and older pages.
Counts above 99 display as `99+`, with the exact count in the accessible
button label. Timestamps are returned in UTC and formatted in the viewer's local
time. Viewing a ledger or opening the inbox does not clear unread state. Opening
a notification's group acknowledges that card; users can also mark one card or
all unread notifications in the selected view as read. Acknowledged cards leave
the inbox, and counters update across views/devices. Mark all covers every page
in the selected group, or all accessible groups when no group is selected.
Stored notifications and expense audit history are retained. Arrivals after the
acknowledgement write remain unread.

## API

Both endpoints require authentication, use private/no-store responses, and check
current active group membership. Archived groups and revoked memberships are
excluded, including during acknowledgements.

- `GET /api/v1/expenses/groups/notifications`: accepts `group_id`, `unread_only`,
  `limit` (1–100, default 30), and `offset`. Returns `notifications`, the global
  `unread_count`, independent `group_counts`, active `groups` for filtering, and
  `pagination` with `total`, `limit`, `offset`, and `has_more`.
- `POST /api/v1/expenses/groups/notifications/read`: accepts `{"ids":["uuid"]}`
  with 1–100 IDs. Marks only the caller's accessible unread rows and returns
  `marked`. Repeated acknowledgements are safe. Other users' IDs are ignored.
  Alternatively, `{"all":true,"group_id":"uuid"}` acknowledges all unread rows
  in one accessible group; omit `group_id` for all the caller's accessible groups.
  The `ids` and `all` forms are mutually exclusive. A supplied group ID must be
  valid, including when it is empty or null. Bulk updates use one database write
  and publish only a private post-commit invalidation.

Inbox rows are staged within the same database transaction as the business
change, so failed writes and rollbacks do not produce notifications. Persistence
also works when Socket.IO is disabled. Socket messages contain only private
invalidation signals. Events are coalesced; reconnect, focus, and visible-tab
polling reconcile missed events. Read changes notify the same user's other
connected devices. Revoked group data is removed from browser caches immediately.
Financial notification queries are excluded by the existing expense cache
persistence policy.

## Schema and validation

Revision `b17dc6e7f801` follows `a06cb5d6e7f9` and creates
`expense_notifications` without changing existing ledgers. Its development
manifest supports the approved additive startup bridge. Regular Alembic releases
also create inbox indexes and restrict PostgreSQL public API grants.
The additive development bridge cannot create secondary indexes. Development
startup permits only these two missing, nonunique notification lookup indexes;
all other schema checks still apply, and production requires them. Startup does
not modify the database to repair drift.
Notifications begin with changes made after this migration and application
update; historical changes are not backfilled as unread.

Regression coverage includes group and user isolation, pagination, concurrent
arrival acknowledgements, every supported update type, source conversions, UTC
timestamps, authorization/revocation, rollback, private device invalidation,
filtering, retry states, local-time rendering, and accessible clickable badges.
