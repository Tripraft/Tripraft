# Personal finance backend

All routes use the existing authenticated API envelope and CSRF protection.
The owner comes from the access token. Income does not accept a client-supplied
owner or group. Personal expenses always use their creator as payer and have one
split equal to the expense amount. Shared expenses and settlements remain in
their own ledger and do not affect personal cash flow.

## Endpoints

Paths below are relative to `/api/v1/expenses`.

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/incomes` | Record personal income |
| GET | `/incomes` | Paginated income list |
| GET | `/incomes/{id}` | Active income details |
| PUT, PATCH | `/incomes/{id}` | Edit supplied income fields |
| DELETE | `/incomes/{id}` | Soft-delete income |
| GET | `/incomes/{id}/history` | Creation, edits and deletion audit trail |
| POST | root path | Create an expense; omit `group_id` for personal |
| PUT, PATCH | `/{id}` | Edit supplied expense fields |
| DELETE | `/{id}` | Soft-delete expense |
| POST | `/{id}/restore` | Restore a soft-deleted expense |
| DELETE | `/{id}?permanent=true` | Permanently remove a soft-deleted expense, splits and history |
| GET | `/{id}/history` | Expense history, including after deletion |
| GET | `/personal` | Paginated personal expenses |
| GET | `/personal/transactions` | Combined active income and personal expense list |
| GET | `/personal/summary` | Income, expenses, net and opening/closing balances |
| GET | `/personal/analytics` | Monthly and category totals by currency and transaction type |
| GET | `/analytics/user/{id}` | Personal analytics alias; requires the caller's own ID |

## Create and edit

Income requires `description` and `amount`. It accepts `currency`, `income_date`
(or `date`), `category` and `notes`. An expense uses `expense_date` (or `date`)
and also supports `receipt_url`. Example income:

```json
{
  "description": "October salary",
  "amount": "2500.00",
  "currency": "USD",
  "income_date": "2026-10-01",
  "category": "salary"
}
```

Amounts must be finite, positive and within `MAX_EXPENSE_AMOUNT`. They are
stored and calculated as Decimal values rounded to cents with ROUND_HALF_UP.
JSON amounts remain numbers for compatibility. Currency codes are normalized
to uppercase three-letter codes. This checks the code's syntax, not currency
availability or exchange rates. Dates accept ISO calendar dates or timestamps;
the supplied calendar day is preserved. Missing creation dates use the UTC day.
If both date aliases are supplied they must agree.

PUT and PATCH update only supplied fields. Omitted fields retain their values;
`null` clears category, notes and receipt URL. Required values cannot be cleared.
Empty or unsupported-only edits are rejected. Identical edits do not create
personal audit events. Personal currency changes move the amount between that
user's currency totals; group currency changes cannot change the group's unit.

Successful personal expense and income mutations include `personal_summary`.
Expense mutations also return at most 100 recent expenses plus `expenses_total`
and `expenses_has_more`; use list pagination to fetch the remaining records.

## Lists and filters

Income, personal expense and combined transaction lists support `limit` (1–100),
`offset`, `currency`, `start_date`, `end_date`, `category` and `search`.
Search performs a literal, case-insensitive description match. Records are
ordered by date descending, creation time descending and ID descending.
Responses include `total`, `limit`, `offset` and `has_more`.

Deleted rows are excluded by default. Income and expense lists accept
`include_deleted=true` to inspect deleted records. Combined transactions and
reports always exclude them. The transaction list accepts `type=income` or
`type=expense`. Query dates must be `YYYY-MM-DD`; bounds are inclusive and
`start_date` must not exceed `end_date`.

## Balance and analysis rules

The personal web dashboard asks users to choose a display currency on their first
visit. It saves `personal_display_currency` on their account through
`PUT /api/v1/auth/user/profile`; `GET` of the same endpoint returns the saved
choice (or null before the first choice). A dropdown lets users change it anytime.
The nullable column is introduced by migration `c62f718293a4`; existing accounts
are prompted instead of silently receiving a default.

The dashboard combines all transactions in the selected currency. Entry currency
applies to the new transaction only: changing it does not switch dashboards or
hide previous transactions. The web client converts each original amount using
the exchange-rate API and rounds it to the selected currency's precision for summary cards, history,
analytics and PDF exports. History also shows the original amount for converted
rows, and editing always uses the saved original currency and amount. The selected
currency and loaded exchange-rate pairs stay cached during the session. Switching
dashboard tabs, changing modes, returning to the browser tab or live transaction
updates do not reload those pairs. A new transaction currency fetches only its
missing pair; an explicit display-currency change uses the selected target's
pairs. Failed requests can be retried. Saved records are not rewritten.
When a required rate is unavailable, original history remains accessible while
totals, analytics and export wait for a successful conversion. Cached rates are
identified. API reports below continue to expose original currency totals.

Committed personal transaction changes send private Socket.IO invalidations to
the owner's devices. The client updates the ledger in the background, preserving
the selected currency and loaded rates. Reconnect, visibility recovery and
polling catch missed transaction changes. Explicit currency-preference changes
also notify the owner's other devices. Rollbacks do not broadcast changes.

`/personal/summary` accepts currency and date bounds. Every currency has its own
row in `data.balances`; currencies are never added together or converted.

- `income` and `expenses`: active records inside the requested period.
- `net`: income minus expenses inside that period.
- `opening_balance`: all active income minus expenses before `start_date`, or
  zero if no start bound was supplied.
- `closing_balance`: opening balance plus net, through the inclusive end bound.
- `income_count`, `expense_count`, `transaction_count`: period counts.
- `savings_rate`: `net / income * 100`, or `null` when period income is zero.

Without date bounds, all recorded dates are included, including future dates.
Use `end_date` to request a balance as of a particular day. A negative balance
is valid. There is no separately stored balance counter: edits and deletions
change the underlying active ledger and subsequent reports reflect that change.
This is recorded cash flow; it does not import bank balances. Existing balances
can be entered as explicitly described opening income or expense records.

`/personal/analytics` returns `monthly` and `categories` arrays. Each row contains
`currency`, `type`, `amount` and `count`, plus `month` or `category`. Category and
search filters can narrow those breakdowns. Totals use every matching record,
independent of list pagination. Blank or missing categories use `uncategorized`.
Financial HTTP responses use `Cache-Control: private, no-store`.

## Audit, permissions and migration

Deletion persists who deleted the record and when. History retains before and
after snapshots and remains visible to its owner after soft deletion. Deleted
expenses show icon-only restore and permanent-delete controls. POST
`/{id}/restore` restores a soft-deleted expense. DELETE `/{id}?permanent=true`
permanently removes a soft-deleted expense together with its splits and history;
it returns 409 for an active expense. The UI asks for confirmation first and
shows “Transaction permanently deleted.” after success. Repeating a regular
DELETE keeps the expense recoverable. Deleted expenses cannot be edited.
Deleted incomes cannot be edited or deleted again. Income IDs belonging to another user return
404; existing expense permission errors return 403. Malformed IDs and filters
return 400, with expense schema failures retaining the existing 422 convention.
Row locks serialize concurrent money edits and deletions on SQLite and PostgreSQL.

Run `python -m alembic upgrade head` from `services/api` with the target database
configuration before starting this backend. Revision `c9d2e4f6a8b0` adds the
income and income-history tables and a personal expense query index. It preserves
existing expenses. Downgrading this revision removes income data.

Regression coverage: `services/api/tests/test_personal_finance.py`, existing money
integrity/concurrency tests, and migration contract tests. Tests use disposable
databases and never run against the configured application database.
