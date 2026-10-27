# Expense request performance

Date: October 26, 2026 (America/Los_Angeles).

## Findings and changes

Currency conversion was one source of waiting. The exchange-rate cache held a
single lock while requesting external data, serializing unrelated pairs and
even cached currency-list reads behind a slow lookup. The cache now deduplicates
in-flight work per key and releases its shared lock before network I/O. Existing
TTL, explicit refresh, outage cooldown, bounded stale fallback and provider
validation remain. Financial writes continue rejecting stale conversion quotes.

The personal dashboard loaded every expense page before requesting income.
Those two independent pagination sequences now start together. The combined
ledger is published only when both complete, preserving complete totals and
deleted expense history. Group mode does not start a personal-ledger read.
Live personal changes refresh personal data; group changes refresh the affected
groups without also reading personal expenses or the currently selected unrelated
group. Reconnect, visibility recovery and fallback polling still reconcile all
relevant caches. Loaded browser-session conversion quotes remain pinned.

Group creation accepts `compact=true` to skip rebuilding all account group
summaries before responding. The web requests this mode, inserts the saved card
immediately and refreshes cards in the background. Default API behavior remains
compatible. Group create/update/archive and personal expense create/edit build
their response before commit to avoid expired-object reads after commit. A
response is returned only after commit succeeds.

Settlement create/delete serialize one balance snapshot and derive simplified
debts from it inside the locked write transaction. Routes use that committed
result instead of opening separate services for balances, debts and history.
Creation retains the existing first-page settlement list, ordering and delete
permissions. Redundant membership queries were removed where `access` already
performs the same active-membership authorization. Ledger locks, Decimal math,
overpayment limits and audit behavior remain covered by regressions.

New-group invitation requests use a pool of at most three concurrent requests.
Each completion updates its delivery feedback immediately. Failed delivery
retries preserve the invitation ID; successful recipients are skipped. No group
is recreated during invitation retries. SMTP delivery continues using the existing
background transport.

## Verification and measurements

A disposable SQLite API fixture compared the Git baseline `a081542305ce` route
and service code with the updated request paths. Both settlement versions saved
a payment of 4 against a debt of 10, returned balances of -6/+6, and restored
-10/+10 after deletion. The group comparison used the default baseline request
and the new web client's compact request.

| Request | Baseline SQL statements | Updated SQL statements |
| --- | ---: | ---: |
| Group creation | 25 | 15 |
| Settlement creation | 28 | 14 |
| Settlement deletion | 22 | 16 |

These measure database round trips in that fixture, not production response
times or latency percentiles. Counts include authenticated request handling and
the application's synchronous live-notification recipient lookup. The fixture
uses disposable users/groups and does not modify the configured development or
production database. Email is disabled for the comparison.

Targeted regressions prove a stalled currency pair does not block an independent
pair or cached listing, duplicate pair requests share one lookup, compact group
creation never calls the account listing, and settlement writes do not reopen
balance/debt/history services. Browser regressions cover parallel complete-ledger
loading, disabled personal reads, targeted live invalidation, bounded invitation
concurrency, per-recipient progress and retry behavior.

Full web validation: **524 tests passed across 54 suites**. Production build,
changed web/Python lint, web typecheck and generated API-client typecheck passed.
The API schema and generated TypeScript declarations include compact group
creation. Full backend validation: **681 passed, 3 skipped**. The skips require
an optional PostgreSQL test service. Infrastructure validation: **74 tests
passed**, along with repository/import checks and Python 3.11 syntax validation.
Existing dependency deprecations and the production bundle-size advisory remain.

## Operational limits

Cold currency requests still need the external provider. The cache is per API
worker; no Redis requirement or new dependency was introduced. Large ledgers
still load every page before complete analytics become available. Remote database
and provider latency still affect requests. This change establishes fewer serial
operations and SQL statements without claiming a measured production speedup.

Changes are saved in local Git history and verified with Sapling Interactive
Smartlog. Existing planning edits remain separate. Runtime environment files are
excluded. Local diagnostics are under ignored `.tripraft/expense-performance-*`.
