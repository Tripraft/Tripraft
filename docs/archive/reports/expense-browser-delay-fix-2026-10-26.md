# Expense browser delays and currency progress

Date: October 26, 2026 (America/Los_Angeles).

Latest follow-up: [live development reloader and layout stability](expense-reloader-and-layout-fix-2026-10-26.md)
identifies the multi-second event-loop stalls reproduced in the new recordings.

Follow-up: [groups-page load profiling and fixes](groups-page-load-fix-2026-10-26.md)
adds live PostgreSQL/curl before-and-after measurements, exact query plans,
pending-GET deduplication and earlier summary-heading rendering. The findings
below describe the earlier HAR investigation; its lack of live PostgreSQL
measurements is superseded by that follow-up.

## What the supplied recording shows

The supplied `download` file is a HAR browser network recording, treated as
diagnostic data. It contains 192 requests, including 36 API requests: nine
successful reads and 27 HTTP 503 responses. Account/group identifiers, request
headers, cookies, query strings and response bodies are excluded from this report.

| Read | Successful requests | Browser duration range, ms | Reported server work range, ms |
|---|---:|---:|---:|
| Signed-in session | 2 | 1,760–5,382 | 643–701 |
| Group cards | 2 | 1,376–3,122 | 1,352–1,369 |
| Group details | 2 | 5,756–5,840 | 2,481–2,712 |
| Pending invitations | 2 | 2,151–6,611 | 764–772 |
| Cached exchange rate | 1 | 1,755 | 1 |

Most of the browser duration is waiting for the first response byte. In
particular, the cached rate reports only 1 ms of server work yet takes 1.76 s.
The gap is consistent with requests queued behind blocking work; it is not
evidence of a slow external rate provider. The recording does not include
personal expense/income reads, so it cannot establish their browser durations.

The 503 bodies identify the local Vite proxy's `API_UNAVAILABLE` response.
Groups, details and invitations each fail nine times during the outage.
APIClient retries a GET up to three attempts; React Query then retries that
whole operation twice, permitting nine HTTP attempts per query. The recording
cannot establish why the backend stopped. Changes here do not claim to prevent
backend restarts or every cause of a 503.

## Fixes

The gevent server patches Python sockets but uses psycopg2, whose C-level
database I/O needs a wait callback. No callback was configured. PostgreSQL engine
creation now installs a cooperative gevent read/write callback before connecting
in patched workers, including the travel engine. Unpatched CLI/migration/test
processes and an explicitly configured custom callback retain their behavior.
Both local `run.py` and production's non-preloaded gevent workers already patch
before importing the application. The callback follows the
[gevent PostgreSQL example](https://docs.gevent.org/examples/psycopg2_pool.html)
and [psycopg2's documented coroutine integration](https://www.psycopg.org/docs/advanced.html#support-for-coroutine-libraries).

Personal and group expense queries no longer repeat APIClient's retry loop:
up to three HTTP attempts replace up to nine per affected query. Personal mode
defers the unrelated group-card read. The actual groups adapter now uses the
focus/reconnect policy intended for the live-update hook. Connection/focus/poll
recovery preserves an already-running read; an actual ledger-change event still
restarts it so an older response cannot hide a committed change.

Group detail/member reads eagerly load the owner, members and users, and load
balances separately to avoid multiplying rows across two collections.
Authorization reuses that membership snapshot. Writes retain their existing
locking and authorization path. Query counts remain constant when the test
group grows from one to six members.

Personal and group currency cards distinguish saving the preference from
calculating current exchange rates. The group card now waits for the shared
conversion hook and sits outside the collapsible settings. A failed conversion
shows an error with Retry conversion. Completion is announced only after the
rate is available; cached pairs still complete immediately. The existing
spinner/progress animation honors reduced-motion preferences.

## Measurements and validation

A fresh run of the existing disposable SQLite/Flask benchmark retained 12
iterations. Against the previous saved fixture results, SQL counts changed:

| Group details | Previous SQL | Updated SQL | Updated warm median, ms |
|---|---:|---:|---:|
| Empty ledger | 17 | 14 | 15.46 |
| Ledger with an expense | 20 | 15 | 19.01 |

The [interactive timing table](../../operations/expense-latency.html) contains
this run's first-request, warm median/p95 and SQL observations. These local
measurements exclude real network travel, PostgreSQL and browser rendering.
They cannot measure the production speedup from cooperative PostgreSQL I/O.
No post-fix recording against the user's PostgreSQL session was available.

Regression tests exercise socket-backed cooperative waiting, callback setup
before engine creation, unchanged custom/CLI callbacks, fixed query counts,
single-layer retries, live read preservation versus ledger-change invalidation,
and save/conversion/failure/retry states in the real group component.

Validation passed: 540 web tests across 57 suites, plus the new group currency
integration and in-flight recovery regressions (542 tests across 58 suites in
total). The final API run passed 109 tests; 55 additional group lifecycle and
collaboration checks passed earlier. The 12-iteration workflow benchmark passed.
Web lint/typecheck, the production build, changed Python Ruff checks and
repository structure/import checks passed. No live PostgreSQL benchmark was run.

The implementation and timing documentation are saved in separate local Git
commits and presented in Interactive Smartlog. Raw HAR contents remain outside
Git. Reproduction of the fixture timing table:

```powershell
$env:TRIPRAFT_EXPENSE_BENCHMARK_OUTPUT='C:/Tripraft/.tripraft/expense-har-workflow-latency.json'
Set-Location C:/Tripraft/services/api
C:/Tripraft/.venv/Scripts/python.exe -m pytest tests/expense_workflow_benchmark.py -q -s
Set-Location C:/Tripraft
python infra/tools/render_expense_latency_report.py .tripraft/expense-har-workflow-latency.json
```
