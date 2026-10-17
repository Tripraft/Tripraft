# Compact currency display, settings sync and member controls

The currency converter now uses a compact strip with short From/To controls,
swap and refresh icons, the reference rate and its date. The amount calculator
is collapsed until opened. Original and converted totals remain visible, with
each currency code appearing once. The prominent provider and checked-time
lines were removed; provider metadata remains available in the reference API.

Group-setting changes refresh planner queries and linked expense views. Linked
expense metadata receives the group name and description in the same transaction.
Expense snapshots include the trip dates and display currency. Treasury, expense
cards, overview, balances, spending, transaction display, settlements and analytics
use that display preference. The original ledger currency, saved amounts, splits,
settlement limits and mutation forms retain their existing units. Budget values
use the currency entered in group settings; their conversion is independent of
the ledger currency. PDF/audit history retains the recorded financial units.

Circle forms follow incoming settings updates while preserving an unfinished
local edit. Everyone in the group can see its active members and role/responsibility
tags. Owners and admins can remove other members after confirmation. Owner
membership is protected; admins use Leave group for themselves. The API enforces
the same restrictions, including after a member loses access. Treasurer removal
continues to transfer ownership safely and retain financial history.

Planner and expense sockets persist across group changes. They start with polling
and upgrade to WebSocket; group switching changes room membership. An expired
session gets one refresh/reconnect attempt, while repeated authentication failures
stop. The backend supplies an explicit authentication rejection. The temporary
duplicate variable declaration reported during editing was corrected.

Validation: 353 frontend tests across 38 suites passed, and 75 affected API tests
passed. Additional final converter/Circle checks, ESLint, TypeScript, Ruff and
production build verification passed. The existing large-chunk build advisory
and dependency deprecation warnings remain. This is scoped regression verification,
not a claim that every possible 401 has been eliminated: unauthenticated requests
must still be rejected.

Desktop/mobile browser checks use isolated demo groups and real public currency
GETs, verify compact layout, currency swap, read-only member views and immediate
settings propagation, and make no real user-group or financial mutations.
Screenshots/logs are in ignored `.tripraft/test-temp/group-planner-ui/`.

Saved locally in Interactive Smartlog on `group-planner-compact-settings-sync`.
No push or deployment was performed. Unrelated launcher edits and input data
were preserved outside this checkpoint.
