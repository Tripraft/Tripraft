# Expense collaboration, currency and analysis - October 26, 2026

This continues the invitation and latency work in commits `47fea32` and
`5e22a11`. Those fixes cover pending resend, same-person re-invitation,
idempotent cancellation, obsolete queued-mail guards and compact mutations.
An anonymous `/auth/me` 401 remains the expected signed-out response; React's
DevTools notice is informational. Neither message proves email delivery failed.

## Delivered behavior

- Committed group changes invalidate every affected member's private live
  query caches, including friends when membership changes. Settings and
  converted expense receipts are included. Three independent authenticated
  socket clients verify delivery, while unrelated accounts receive no ledger.
- Record payment disables all form controls while pending and has a synchronous
  duplicate-submit guard. Live refreshes preserve pending drafts.
- Scrolling past the group header reveals floating Add expense and Settle up
  buttons, using the personal expense pattern, existing form and settlement tab.
- Group creation selects the ledger currency and first expense choice. Any member can
  enter an expense in another currency. The API converts once into ledger money,
  allocates exact cents, and retains the original amount, currency, rate, date
  and source splits. Original money appears in receipts and edit forms. The
  split card divides the converted total with exact cents: INR 1000 at USD 10.53
  displays USD 5.27/5.26 for two equal participants. Inputs retain source units.
  All seven split algorithms remain available, including refunds and itemized bills.
- Owners can change the shared default/display currency, budget and group dates.
  Ledger currency remains stable after financial history exists. Budgets use
  ledger units and remain visible in settings, cards and group details.
- Browser display rates are pinned per currency pair for the session. Tab/focus
  changes do not reload them. An explicit group-header action refreshes quotes.
  Failed quotes retain original units and a missing server quote rolls back a
  financial change.
- Saved registered friends are reciprocal. Every active co-member in every
  direct active expense group is also a friend. Nicknames remain private to
  their saver. The friend graph shows only shared groups the viewer belongs to;
  the settlement graph shows directional suggested payments.
- Analysis presets span exactly 7/30/90/365 calendar days through today; custom
  dates are inclusive. Charts include zero days, averages use the full interval,
  and deleted/future records are excluded. Personal analysis reads real income
  records as well as expenses. Group cards display a complete 14-day sparkline.
- Personal/group PDF exports now use statement layouts with wrapped details,
  fitted money columns, original receipts, proper dates, repeated table headers
  and numbered pages. Personal income is separated from spending, including
  cumulative net activity. Saved settlement names and one-cent balances work.

## Persistence and operation

Migration `f95ba4c5d6e8` follows `e84a93b4c6d7`, adding nullable display currency,
budget minor units, start/end dates and expense source metadata. The restricted
development migration bridge was used; a read-only check confirmed the live
development revision and all five columns. No production deployment or role or
permission expansion was performed. Existing rows use compatible defaults.

Immediate Socket.IO fanout works for users connected to the same API service.
Multiple API processes require the existing shared broker configuration for
cross-process fanout; separate local backends without a broker cannot deliver
each other's socket events. Existing query fallback/reconnect behavior remains.
Full history/analytics still require paginated reads, and first-time FX requests
can involve the provider. No production latency percentile or email inbox
delivery guarantee is claimed. Native queued mail remains best effort.

No real invitation, payment or expense was created or changed for validation;
test mail and rates use mocks. Browser/native automation was unavailable in
this session, so visual interaction was checked through component regressions
and the production build. Live development schema checks were read-only after
the additive migration.

Current API details: [group finance](../../api/group-finance.md),
[friends](../../api/expense-friends.md),
[personal finance](../../api/personal-finance.md).
Local evidence is saved under ignored `.tripraft/expense-collaboration-*`.
The Git checkpoint excludes pre-existing planning document edits. No remote
branch is pushed.

## Validation

The complete API suite passed: **678 passed, 3 skipped** (optional service
coverage), including 12 collaboration regressions. Infrastructure tests passed:
**74 tests**. The final complete web suite passed **520 tests across 54 suites**,
including the converted split-card example, floating actions and real PDF output.
Python Ruff, changed expense ESLint, web/API-client typecheck, structure and
infrastructure static checks passed. The production web build passed with the
existing bundle-size advisory. The local Vite proxy returned HTTP 200 for API
liveness. Deprecation warnings remain in the existing dependencies/test harness.

PDF QA generated and inspected **12 pages** (six per mode) with synthetic long
descriptions and large amounts. Automated extraction confirmed full values,
source receipts, dates, page numbers and page bounds. The renderer is installed
only in the ignored QA directory; application dependencies did not change.

## Request-by-request completion audit

| Requested change | Result |
| --- | --- |
| Invitation 409, pending resend and delivery feedback | Fixed in preceding invitation commits; covered by the complete API/web regressions |
| Cancel, retry cancellation, re-invite/resend same email | Covered, including obsolete queued-mail guards and rejected cancelled acceptance |
| Expense add/delete/invite latency | Compact mutation results, background email and immediate cache updates are saved; remote database reads can still take seconds |
| Automatic group updates | Private commit notifications to all members; socket regression verified three clients |
| Disable settlement fields during save | Done, with duplicate-submit protection |
| Group currency, original receipt and editable default | Done; saved ledger remains consistent and browser quotes stay pinned across tab changes |
| INR 1000 split-card preview | Done: USD 10.53 divides as USD 5.27/5.26, preserving INR input |
| Mutual friends/all direct co-members/private nicknames | Done, including name/membership invalidation and privacy tests |
| Shared-group and payment graphs | Added inside existing expense/settlement screens |
| Visible editable group budget and settings | Done; owner controls budget, display/default currency and group dates |
| Correct personal/group time analysis | Done, including real income, complete calendar intervals and zero days |
| Floating group Add expense/Settle up | Done with scroll tracking, existing handlers and mobile safe-area spacing |
| Better personal/group PDFs | Done; rendered and visually checked with extreme content |
| Documentation, Git and Interactive Smartlog | Current guides, generated contracts and this report are included in the saved local feature branch; Smartlog uses localhost port 3011 |

No failing required check remains. Live inbox delivery was not tested with a real
recipient; mail regressions use mocks. Cancellation cannot recall mail already
sent. Immediate updates across multiple API processes require the existing
shared broker. Real browser automation was unavailable; component interactions
and rendered PDFs were verified. Production has not been deployed or pushed.
