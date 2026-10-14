# Personal and group expenses audit - October 13, 2026

October 14 follow-up: personal pagination and the salary-in-spending display are
now fixed, with the requested history, amount-field, deletion/revert, and
settlement-card changes. See [the follow-up record](#october-14-follow-up).
The original income-ledger integration and mixed-currency findings remain open.

## Result and scope

The group dashboard, group detail, analysis, members, activity, split details,
expense history, and settlement interfaces were updated using
`tripraft-expenses-v3.html` and the supplied group-card screenshot as visual
references. The application keeps its existing purple/light theme and real API
data. The HTML was treated as a design reference, not as instructions.

This review covers the React expense feature, its query/API integration, and the
Flask personal/group expense, invitation, settlement, and money services. It
includes static review, frontend tests, backend integration tests, and build
checks. It is not a production penetration test. The open findings below mean
that the complete personal-finance feature should not yet be called bug-free.

## Fixed or implemented in this change

| Area | Result |
| --- | --- |
| Group landing screen | Selectable group cards with member avatars/count, dates, actual spending trend, total spend, personal share, paid amount, net balance, and top category. Search, loading, retry, and first-group empty states are included. |
| Group navigation | Opening a card shows its detail screen; All groups returns to the dashboard. Group deep links remain supported. New group is accessible from the dashboard and detail screen. |
| New group | Dedicated name/currency dialog, trimmed name validation, busy protection, and visible failure feedback. The exact `{name, currency}` payload has a backend regression test. |
| Complete card totals | Group list/full-detail responses provide full-ledger summary metrics. These do not depend on the transaction page size. Shares come from saved splits; settlements change net balances rather than historical shares. Deleted expenses are excluded. |
| Detail layout | Header and summary actions precede the Balances, Settle Up, Member Spending, Activity & history, Analytics, and Members tabs. Expense split/history/edit/delete controls remain available in activity cards, subject to permissions. |
| Members | Responsive member rows, role labels, paid totals, invitation form, pending invitation actions, and group settings retain owner/admin/member restrictions. Former members' recorded spending is retained. |
| Analysis | Insight cards, group-total/personal-share scope, category donut and bars, daily trend and table, top expenses, time filters, and export access use recorded amounts. Calendar-day calculations include gaps between spending days. |
| History crash | `ExpenseHistoryModal.jsx` imports the previously undefined `ExpenseDialog`. A regression test opens the history dialog. |
| Split history | Actual custom split amounts are displayed. Changes to amounts with an unchanged number of participants are detected. History supports both structured field keys and old/new values. |
| Settlement/dialog overlap | Shared dialogs render in a portal above page stacking contexts. The surface has its own opaque background, bounded viewport height, scrolling, and no blur/filter/transform. Nested dialogs handle Escape only on the top layer. |
| Dialog accessibility | Dialog labels, focus entry/return, Tab wrapping, body scroll locking, and disabled close/save controls during requests are shared across expense dialogs. |
| Responsive styles | Cards, tabs, filters, action menus, members, summaries, personal transactions, and dialogs use flexible widths, wrapping, and mobile breakpoints. Long names and amounts can wrap. |
| Invitation expiry | The UI uses the backend `is_expired` flag when available, avoiding a local-time reinterpretation of UTC expiry. |

### Reported create-group HTTP 500

The reported 500 was **not reproduced in the backend regression test**: the
dashboard's minimal payload returns HTTP 201 and a zero-spend group summary.
During the local checks, direct/proxied health endpoints returned 200 and the
unauthenticated group endpoint returned 401. These checks do not establish that
the user's authenticated browser failure has been resolved. No matching backend
500 traceback was captured during this review. The available API log also records
`POST /api/v1/expenses/groups` returning 201 at 10:43:03 local time. A repeat failure needs its
response body/request ID and matching server traceback; a hot-reload cause is
unconfirmed.

The React DevTools download message is an informational development notice. It
does not cause the undefined-component exception or the server's HTTP 500.

## Open findings

Priorities: P1 = incorrect financial records/totals; P2 = functional or usability
gap; P3 = maintenance/performance improvement. Findings are supported by current
source review; they are not all new regressions introduced by this UI change.

### P1 - Personal income uses the expense ledger

**Evidence:** `apps/web/src/features/expenses/jsx/ExpenseManager.jsx`,
`handleSaveTransaction` around line 366, always calls `createExpense` or
`updateExpense` in personal mode. `TransactionModal.jsx` sends a `type` field,
but the save handler does not select an income endpoint. The Income option sets
category to Salary. `apps/web/src/services/expenseApi.js` has no income CRUD
methods. The backend has a separate `Income` model and authenticated `/incomes`
routes in `services/api/app/expenses/routes/personal_finance.py`.

**Impact/reproduction:** Create a personal Income transaction for 1,000. It is
saved as a Salary expense, while the real personal summary derives income from
the separate Income table. UI income/balance values and backend financial
summaries can disagree. Genuine income API records are not loaded by the current
personal-expense query. Before the October 14 follow-up, spending analytics also
counted Salary records as spending; that display defect is now fixed.

**Required fix:** Connect personal create/edit/delete/history to the correct
income and expense endpoints, load both ledgers or use the personal transaction
endpoint, and consume the backend summary. Decide how to migrate existing Salary
expenses explicitly; do not silently change users' records based on a category.

### P1 - Personal transactions stop at the first API page (fixed October 14)

**Evidence:** `apps/web/src/hooks/useExpenseQuery.js`, `usePersonalExpenses`
around line 1275, makes one `getUserExpenses({personal_only: true})` request.
`services/api/app/expenses/services/expense_service.py`, `get_user_expenses`
around line 1122, defaults to 50 records and returns `total` and `has_more`.
The personal screen calculates totals, filtering, analytics, and exports from
the loaded array rather than consuming additional pages or server aggregates.

**Impact/reproduction:** With more than 50 personal expenses, older entries are
missing from the screen and its totals/export. The screen's own pagination only
pages through the already loaded subset.

**Required fix:** Use server pagination with server-side totals/filtering, or
fetch all pages where a complete ledger is required. Add a regression case with
at least 51 records. Group detail already fetches its ledger pages separately;
its dashboard totals now use full-ledger backend aggregates.

**October 14 status:** The personal query now fetches every page, including
soft-deleted rows for Revert. A 101-record regression verifies loading beyond
the first page. Analytics, summaries, and exports receive the complete array;
deleted rows remain excluded from financial aggregates.

### P1 - Personal totals combine currencies and label them USD

**Evidence:** `ExpenseSummary.jsx` formats USD unconditionally. Personal view,
analytics, dialogs, and report calls in `ExpenseManager.jsx` also pass USD.
Personal totals sum transaction amounts without separating currency, while the
backend accepts multiple currencies and its personal service supports
currency-separated summaries.

**Impact/reproduction:** Personal USD 100 and EUR 100 records can be displayed as
a single USD 200 total without conversion. Values read from the API can therefore
be mislabeled even though the current personal form defaults to USD.

**Required fix:** Select/filter a currency and use currency-separated backend
summaries, or define an explicit conversion policy with dated exchange rates.
Propagate each record's currency through editing and export.

### P2 - Personal loading/failure can look like an empty ledger

**Evidence:** `usePersonalExpenses` exposes `loading` and `error`.
`ExpenseManager.jsx` destructures personal loading but does not render a distinct
personal loading/error state or consume the personal error. Empty arrays are used
as the fallback data.

**Impact:** A failed request can appear as zero finances/no transactions instead
of a failed load, making the financial state misleading.

**Required fix:** Show loading placeholders and an error with retry; retain a
clearly marked previous result when appropriate. Test failed and pending reads.

### P2 - Custom split creation/editing is incomplete in the UI

**Evidence:** `TransactionModal.jsx` creates equal participant splits. Existing
non-equal splits disable amount/participant edits rather than providing exact,
percentage, or share editors. Backend split validation supports these modes.

**Impact:** Users can inspect preserved custom split values but cannot fully
create/edit every supported split type from this screen. The current protection
avoids accidentally replacing custom allocations with equal shares.

**Required fix:** Add explicit split-mode editors with total reconciliation,
rounding previews, and validation against the server contract. Preserve existing
allocations until a user intentionally changes them.

### P3 - Expense route still produces a large production chunk

The build succeeds, but Vite reports an expense-page chunk of approximately
559.6 kB before gzip, above its 500 kB warning threshold. Replacing the previous
chart implementation reduced it, but deferred PDF/export and tab-specific imports
are still candidates for route-level code splitting. Measure before further
optimization.

## Security review

No new authorization bypass was confirmed in the reviewed expense paths. This
statement is limited to the local source and automated tests below.

- Expense, personal-finance, group, invitation, and settlement routes require
  authentication. Personal record/history access is restricted to its owner;
  group data requires active membership.
- Owner/admin/member actions are checked in services, not only hidden in React.
  Settlement recording checks permitted participants/roles and outstanding
  balances. Ownership, membership removal, leaving, and deletion retain their
  balance/lifecycle constraints.
- Money services validate positive bounded amounts, cent precision, split
  totals, and currencies. Record/group locking and concurrency tests cover
  conflicting financial writes in the test environment.
- Global CSRF validation is wired in `services/api/app/core/factory.py`; the
  client attaches the CSRF header for state-changing requests. CSRF regression
  coverage is included.
- Expense components do not use `dangerouslySetInnerHTML`. Invitation email
  rendering has escaping tests. History and deleted records retain access checks.
- `apps/web/src/lib/queryClientPersist.js` excludes financial/group/invitation
  queries from persistent cache and does not persist/retry mutations. Logout in
  `AuthContext.jsx` clears query and persisted caches. Group-detail failures for
  lost access avoid displaying a previous group's cached ledger.

Unverified here: production PostgreSQL behavior under load, deployed
configuration, a full authenticated browser journey, and external penetration
testing. The P1 personal-ledger findings above are financial correctness risks
even where authorization checks pass.

## Unused files and cleanup candidates

No recovered source/data files were deleted as part of this audit. A filename,
duplicate-looking dataset, or lack of a direct import alone does not prove that
an operational script is useless.

| Candidate | Evidence and safe action |
| --- | --- |
| `apps/web/src/features/expenses/css/ExpenseAnalytics.css` | The feature analytics component now re-exports `ExpenseAnalysisView`; this old feature stylesheet has no current import. Candidate for removal after visual comparison. **Keep** the separate `apps/web/src/pages/styles/ExpenseAnalytics.css`, which is still imported by the page component. |
| Legacy receipt rules in `features/expenses/css/SettlementHistoryModal.css` from the `Legacy Receipt Modal Styles` section around line 313 | Selectors such as `.settlement-receipt-modal`, `.settlement-table`, and `.receipt-summary-box` have no current JSX references. Candidate for pruning. The file's active `shm-*` rules remain in use, so do not delete the whole stylesheet. |
| Legacy exports in `apps/web/src/hooks/useExpenseQuery.js` | `useBackgroundSync`, `usePrefetchGroups`, `useGroupHistory`, and the aggregate `useExpenseManager` have no current production callers found in the source search. Review public exports, indirect use, and tests before removal. Active hooks in the same file must remain. |
| Generated `dist`, `node_modules`, tool caches, and `__pycache__` | Regenerable artifacts, normally ignored. Optional disk cleanup only; they are not source features to remove. |
| `.tripraft/recovery-20261013/` | Intentional ignored recovery backups/manifests. Keep until the recovered work has been checked and backed up elsewhere. |
| Recovered `sql_database/Old`, catalog references, and import reports | Historical/import inputs, not established as useless. Keep; removal needs a separate data-dependency review. |
| Unrelated untracked databases and `script/` work | Left unchanged and excluded from these commits. Their purpose/ownership was not established; they are not approved cleanup targets. |

## Validation and limits

- Frontend full suite: **25 suites / 251 tests passed**. After the final expiry
  adjustment, the focused analysis/dialog and invitation suites passed again
  (**20 tests**).
- Backend expense/security audit: **170 tests passed** in 469.46 seconds across
  personal finance, money integrity/concurrency, group lifecycle/access,
  crew/expense deletion, CSRF, security hardening, and WebSocket authentication.
  The run emitted 293 dependency deprecation warnings (Pydantic configuration
  and Werkzeug version access); none were test failures.
- Separate recovery validation: **7 canonical catalog tests** passed; earlier
  combined catalog/group lifecycle run passed **49 tests**. Restored file contents
  were checked against the Git blob manifest.
- ESLint and TypeScript checks passed. Production Vite build passed; the expense
  chunk warning remains as recorded above. `git diff --check` found no whitespace
  errors.
- Local direct/proxy health checks passed. No external messages, deployment,
  production ledger mutations, or push were performed.
- Browser visual testing was interrupted by the user pressing Escape. Therefore
  pixel appearance, overlap removal, and touch behavior across actual viewport
  sizes remain **visually unverified**, despite responsive styles and component
  tests. Do not interpret this report as completed device/browser acceptance.

Backend audit command (uses isolated test databases):

```powershell
$env:PYTHONPATH='C:\Tripraft\.venv\Lib\site-packages'
py -3.11 -m pytest services/api/tests/test_personal_finance.py services/api/tests/test_money_integrity.py services/api/tests/test_money_concurrency.py services/api/tests/test_expense_group_lifecycle.py services/api/tests/test_group_access_controls.py services/api/tests/test_crew_expense_deletion.py services/api/tests/test_csrf.py services/api/tests/test_security_hardening.py services/api/tests/test_websocket_auth.py -q -p no:cacheprovider
```

Frontend checks (from `apps/web`):

```powershell
node node_modules/jest/bin/jest.js --runInBand
node ../../node_modules/eslint/bin/eslint.js src tests
node ../../node_modules/typescript/bin/tsc --noEmit
node node_modules/vite/bin/vite.js build
```

## Recovery and saved history

Recovery commit: `45280d4` (`Recover discarded catalog files and travel database
configuration`). It restores **639 missing files and 15 discarded edits** from
the latest complete recoverable local snapshot found, dated October 12. Changes
made after that snapshot are not guaranteed to be present. See
[the recovery report](smartlog-recovery-2026-10-13.md) and its linked hash manifest.

UI commit: `8f1cabc` (`Match expense group screens and analytics to the reference
layout`). Sapling's log was checked and shows both this commit and recovery
commit `45280d4`, including their descriptive messages.

This audit is saved as a separate documentation commit for review in Interactive
Smartlog. No history reset or remote push is part of this work.

## October 14 follow-up

- Personal edit history hides `splits`, `split_type`, `split_status`, and payer
  normalization changes because these are not personal form controls. The
  current user is identified as **You**. Group split histories remain visible.
- Personal analytics classifies legacy Salary/Income categories and explicit
  income records as received money. They are excluded from spending categories,
  trends, biggest expenses, and spending averages. Separate income, spending,
  and net-balance cards show the cash flow for the selected period. This is a
  display correction; it does not migrate legacy Salary rows into the Income
  table or resolve the original endpoint-integration finding.
- The add/edit amount field gives the currency code a separate flexible column
  instead of absolutely positioning it over the number.
- Personal and group activity retain gray soft-deleted rows after refresh, with
  a **Revert** button for authorized users. `POST /expenses/<id>/restore`
  restores the same record and saved splits, clears deletion metadata, records
  a restored history entry, and reapplies group balances under the money lock.
  Repeated/concurrent restores apply the balance once. Archived groups, lost
  membership, unauthorized users, and changes that would strand former-member
  debt are rejected. Existing default API reads still exclude deleted records;
  the expense UI explicitly requests them.
- The suggested-payment card and header settlement action open the Settle Up
  tab, focus it, and scroll the tab section into view. History & changes also
  uses this navigation behavior.
- No cleanup candidates or unrelated user files were deleted.

Follow-up validation:

- Full frontend suite: **29 suites / 282 tests passed**.
- New restore API/security/concurrency tests: **7 passed**.
- Existing group lifecycle, money integrity/concurrency, and access checks:
  **67 passed**, with one unrelated vault test unable to create its fixture in
  Windows' default pytest temp directory. That test **passed on an isolated
  retry using a fresh workspace `--basetemp` directory**. No application
  assertion failed in these runs.
- ESLint, TypeScript, and the production build passed. Vite's existing chunk
  warning remains; the expense route is now approximately 562.9 kB before gzip.
- A read-only GET probe of the running local restore route returned 405, as
  expected for this POST-only endpoint, confirming that the server loaded it.

Visual browser checks could not run: this session exposed no browser surfaces,
and opening the in-app browser returned `Browser is not available: iab`.

## October 14 group live updates

Expense screens now connect to the authenticated `/expenses` Socket.IO namespace.
The server selects a private user room from the verified JWT/cookie; clients do
not select users or subscribe to the group planner's unrelated group rooms.
Every connected device receives a small `expenses:changed` invalidation and
loads current data through the existing authenticated API.

ORM transaction hooks collect group, member, expense/history, settlement,
invitation, and balance changes. They publish after commit, discard rolled-back
changes, and delay savepoint notifications until the outer commit. This also
covers services called by linked-trip actions. Delivery failures are logged and
do not fail an already-committed financial operation.

Recipients are resolved from current active membership on each delivery.
Removed members receive a final access-revoked notice; later changes are not
sent to them. Group archival clears all members' stale views. The payload
contains only group/expense identifiers and an access-revoked flag, never money,
member details, invitation links, or ledger contents.

The client refreshes group cards, selected group details (including transactions,
balances, settlements, members and invitations), and open expense history.
Bursts are coalesced over a 150 ms window. Reconnect, browser focus, returning to
a visible tab, and coming online recover missed changes. A safety read runs
every 60 seconds while connected, or every 20 seconds when disconnected, only
while visible and online. This supports automatic updates when WebSockets are
disabled or temporarily unavailable; that fallback is periodic rather than
instant delivery. Existing Socket.IO Redis queue configuration supports delivery
between API workers; no additional package or service was introduced.

Background refetches preserve an open transaction draft instead of resetting it
when member or expense objects change. An expense deleted remotely cannot be
saved from its stale dialog. Unmount/logout disconnects the expense socket and
removes timers/listeners.

Open split receipts continue to follow the selected expense's actual ID, and
open history headers follow updated transaction values. Missing legacy IDs no
longer cause a receipt to switch to the first expense after a live refetch.

Live-update validation:

- Full frontend suite: **30 suites / 289 tests passed**. The final live-update
  suite passed again (**6 tests**) after the event-window adjustment.
- Backend: **20 tests passed** across live delivery/privacy/rollback/savepoints,
  expense restoration, and concurrent money writes. The **5 existing WebSocket
  authentication tests** also passed in the earlier targeted run.
- Final receipt/draft/follow-up suite: **9 tests passed**, including the new
  selected-receipt regression. ESLint, TypeScript, and the final production build
  passed. The existing bundle-size warning remains (expense route about 565.5 kB
  before gzip). Browser visual checks remain unavailable in this session.
