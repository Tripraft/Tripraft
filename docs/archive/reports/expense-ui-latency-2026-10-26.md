# Expense UI, statements and workflow latency

Date: October 26, 2026 (America/Los_Angeles).

## Delivered changes

Converted group overview amounts have separate primary and secondary lines.
Settle up, Member Spending, Activity, transaction tables, split breakdowns and
History use the same two-line currency layout. The secondary line contains
only the currency and amount. Payment entry explicitly requests ledger units
and previews the selected display currency. Unavailable quotes retain source
units. Personal history uses the source amount as well as the source currency;
itemized history retains the receipt's currency for bill details.

Group settings now has a readable summary, preference cards and a responsive
form. Compact translucent floating actions retain accessible names, tooltips
and 44-pixel targets. The group friends/shared-groups card and display-rate /
Refresh conversion row are removed. Saved friends remain in invitation pickers.
Analytics uses one display currency in chart labels, compact donut totals and
an exact total below when shortened. Double-encoded separators were corrected.

Personal and group currency changes show animated progress while saving and
loading conversion rates, then briefly confirm completion. Failure shows an
error; cached conversions do not incur an artificial delay. Reduced-motion
preferences disable the spinner and moving progress bar.

PDF numeric headings, body cells and totals now share the same alignment.
The correction applies to member balances, payments, personal cash-flow columns
and the other statement tables. Long details wrap and headers repeat on pages.

## Performance changes

- PDF libraries load only when Export is clicked. A production build before and
  after this split measured the expense page's JavaScript at **601.81 to 173.96
  kB** (71.1% smaller); gzip **190.36 to 49.68 kB** (73.9% smaller). These are
  build artifact sizes, not measured page-opening milliseconds. PDF code is now
  a separate 427.35 kB chunk and downloads on first export.
- Copied invitation links open the joined group after successful acceptance;
  the previous fixed **2,000 ms** redirect delay is removed.
- Invitation send/accept requests support `compact=true`. The web uses it and
  updates local cards/invitations from committed results, then refreshes lists
  in the background. Default API responses remain compatible.
- In otherwise matching disposable fixtures, sending used **20 to 17 SQL
  statements**, acceptance **38 to 30**, and code joining **21 to 19**. Joining
  serializes its response before commit and returns only after commit succeeds.
  Statement counts are reproducible evidence; separate timing runs were noisy,
  so no production percentage speedup is inferred from them.
- Settings changes apply the committed group response before background reads.
  Group-query focus refetch is disabled because the live-update hook already
  reconciles on focus/reconnect. Membership revocation handling remains active.

## Measured request timings

Open the [interactive latency table](../../operations/expense-latency.html) to
filter personal/group/shared requests and sort by median, p95 or SQL count.

These measurements use Flask's test client and a disposable migrated SQLite
file. Each of 12 workflow runs creates its own users and group; the first run
is separate and the next 11 supply median/p95. The personal ledger contains one
expense; the group reaches three members and one expense. Authentication,
serialization, SQL, locks, commit and live-notification recipient lookups are
included. Account registration/setup is outside the timings. Cached FX uses a
primed real cache with a test rate; all real email and provider I/O is disabled.
No real user invitations, expenses, payments or development data were modified.

With only 11 warm observations, p95 is the maximum observed request in that
set. It is not a production latency percentile or a service-level guarantee.
Browser rendering, network travel, remote PostgreSQL, cold provider lookup and
email inbox delivery are excluded. Real end-to-end opening/switching timings
remain **unmeasured**. Computer Use was stopped by the user's Escape key after
the group overview had been visually checked; no further UI automation ran.

| Workflow / API portion | First run ms | Warm median ms | Warm p95 ms | SQL |
|---|---:|---:|---:|---:|
| Read signed-in session | 11.53 | 5.44 | 15.53 | 2 |
| Open personal page: currency preference | 7.52 | 4.76 | 9.29 | 2 |
| Read pending invitations | 35.44 | 7.80 | 14.80 | 3 |
| Add personal expense | 60.86 | 13.20 | 52.13 | 7 |
| Open personal page: expense page | 42.30 | 10.01 | 45.43 | 4 |
| Open personal page: income page | 34.62 | 6.53 | 13.44 | 3 |
| Edit personal expense | 47.15 | 20.05 | 32.99 | 12 |
| Change personal currency: save preference | 14.11 | 9.81 | 22.63 | 4 |
| Currency conversion: cached rate read | 4.91 | 1.82 | 3.38 | 0 |
| Delete personal expense | 19.76 | 14.85 | 24.55 | 9 |
| Create group | 66.75 | 21.83 | 30.02 | 15 |
| Switch to group: read group cards | 58.25 | 11.85 | 29.15 | 9 |
| Open empty group details | 77.18 | 18.06 | 30.63 | 17 |
| Save/send invitation request (mail disabled) | 55.02 | 20.93 | 34.61 | 17 |
| Read invitation details | 12.08 | 8.40 | 10.51 | 6 |
| Accept invitation and join | 66.43 | 32.39 | 68.69 | 30 |
| Join with group code | 33.82 | 23.44 | 59.40 | 19 |
| Add group expense | 60.66 | 36.54 | 69.59 | 24 |
| Edit group expense | 64.65 | 38.22 | 67.25 | 34 |
| Open group details with an expense | 46.92 | 27.50 | 46.81 | 20 |
| Record settlement | 42.27 | 22.71 | 46.85 | 14 |
| Delete settlement record | 26.14 | 21.32 | 108.58 | 16 |
| Change group display currency: save | 19.28 | 16.85 | 105.32 | 14 |
| Delete group expense | 45.38 | 25.95 | 87.74 | 23 |
| Delete/archive settled group | 16.64 | 12.04 | 19.70 | 10 |

Opening personal expenses involves session/profile, expense and income reads;
the expense and income pagination chains run in parallel. Group cards and
selected group details are separate reads. A previously loaded personal tab
reuses its cached ledger. Larger ledgers add paginated reads. These individual
request measurements must not be added and presented as page-render times.
Currency saving is separate from FX lookup; session-loaded browser pairs need
no new quote. A cold provider call was not timed.

## Can it be reduced further?

Yes. The first follow-up should measure real browser navigation and the shared
PostgreSQL deployment under realistic ledger sizes. Group editing still uses
34 SQL statements and acceptance uses 30 in this fixture; batch/eager-load
related member/audit data after profiling those paths. Large ledgers still
load all pages for complete analytics, so server-side aggregate reads could
reduce initial transfer. Cold FX and mail transport need separate operational
measurements. The existing provider timeout is not a promise of completion
time. None of these unimplemented follow-ups is claimed as a delivered speedup.

## Reproduce

From `services/api`, with the project Python environment:

```powershell
$env:TRIPRAFT_EXPENSE_BENCHMARK_OUTPUT='C:/Tripraft/.tripraft/expense-ui-workflow-latency.json'
python -m pytest tests/expense_workflow_benchmark.py -q -s
```

The benchmark imports the existing `conftest` fixture, which selects a temporary
SQLite database before application imports. It never reads application .env
credentials. From the repository root, regenerate the interactive HTML with:

```powershell
python infra/tools/render_expense_latency_report.py .tripraft/expense-ui-workflow-latency.json
```

Raw samples, SQL-count comparisons, PDF samples/PNGs and validation logs remain
under ignored `.tripraft/expense-ui-*` and `.tripraft/pdf-qa/`. The standalone
interactive HTML and this report are committed alongside the implementation.

## Validation

The complete web suite passed **537 tests across 56 suites**, including lazy PDF
loading, pinned personal rates and history source-unit coverage.
Production build, web lint/typecheck, generated API-client typecheck and changed
Python Ruff checks passed. API lifecycle/invitation/compact-write tests passed
**64 regressions plus the benchmark**; realtime, money concurrency and access
checks passed **29 more tests**. The final benchmark separately passed all 12
workflow runs. Infrastructure validation passed **74 tests**, structure/import
checks, Compose/workflow validation and Python 3.11 syntax checks. OpenAPI and
TypeScript declarations include compact invitations.

PDF QA rendered and inspected 12 pages (six per mode), including extreme money
values and long references. Text extraction confirmed exact money, receipt
units, page numbering and margins. Remaining dependency deprecations, an
existing test act warning and the unrelated map chunk-size warning are recorded
in the local logs. UI work after Escape was verified through component tests;
full manual interaction of all redesigned tabs remains unverified.

Pre-existing expense planning edits were preserved in their own local Git
commit. The implementation, benchmark and reports are saved in local Git and
checked through Sapling Interactive Smartlog. No remote push or deployment is
part of this checkpoint.
