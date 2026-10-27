# Live development waits and expense layout shifts

October 26, 2026 (America/Los_Angeles). Follow-up to `c25fa15`.

The user's new personal/group/currency/settlement recordings demonstrate that
the earlier work did not meet acceptance. Soft-navigation observations were
LCP 1.26s / CLS 0.38 / INP 16ms and LCP 0.06s / CLS 0.19 / INP 16ms. Personal
expense/income reads still took 3–5.54s; group batches took up to 6.30s.
The visible batches show one request per endpoint, rather than duplicate reads.

## Reproduced cause: development reloader blocks the server

The local launcher sets `TRIPRAFT_DEV_RELOAD=1`. Flask-SocketIO's gevent runner
uses Werkzeug's stat reloader after monkey-patching Python threads. The nominal
reloader thread therefore runs as a greenlet on the request event loop. Its
filesystem scan uses synchronous `os.walk`, `isfile` and `stat` calls. Those
calls block other greenlets, including requests waiting on PostgreSQL sockets.

This explains the discrepancy between the prior fast fresh-worker benchmark
(no reloader) and the actual development app. Query timings can include a
reloader pause while a database socket is waiting; some requests also spend
seconds outside cursor execution. Earlier query-count improvements alone could
not remove that delay.

A heartbeat test against a fully imported development application reproduced:

| Scan | Scan time, ms | Largest event-loop heartbeat gap, ms |
|---|---:|---:|
| Existing scan on hub | 2,473.03 | 2,473.53 |
| Same scan on native thread | 2,372.46 | 71.29 |
| Existing scan on hub | 1,134.58 | 1,138.03 |
| Same scan on native thread | 1,255.74 | 43.91 |

`prepare_native_reload` now selects a stat-reloader subclass whose scan runs in
gevent's native thread pool. It retains Werkzeug's file selection, change
detection and exit-code-3 restart behavior. Tests verify another request can run
during a scan and that the restart signal reaches the main reloader. Production
and unpatched processes keep their existing behavior. No migration or schema
change runs during reload.

## Same-worker HTTP verification

Curl measured the actual running server at `127.0.0.1:5000`, including its source
reloader, before and after the fix. Same development account/group, three
serial samples per endpoint; no financial writes were made by the diagnostic.

| Endpoint | Before median, s | After median, s | After range, s | SQL before/after |
|---|---:|---:|---:|---:|
| Groups summary | 3.645 | 1.141 | 1.098–1.508 | 6 / 6 |
| Invitations | 1.830 | 0.752 | 0.716–0.765 | 2 / 2 |
| Full detail | 2.461 | 1.357 | 1.307–1.540 | 8 / 8 |

The slowest pre-fix full-detail sample was 6.816s. All nine post-fix samples
were under two seconds. Almost all duration was TTFB; post-fix download time
was 0.100–0.358ms. Complete JSON `data` response hashes matched before/after
for every endpoint and sample. Query counts and response shapes did not change
in this follow-up.

Read-only EXPLAIN ANALYZE of all involved statements found no expensive plan or
JIT compilation. Execution times were 0.033–2.377ms; synthetic SELECTs from
0–10KB took about 75–119ms with both native and cooperative I/O. This ruled out
query length and expensive execution as the cause of the multi-second live
worker stalls. The [evidence JSON](../../operations/expense-reloader-evidence-2026-10-26.json)
retains all before/after HTTP timings/hashes, heartbeat observations and redacted
parameterized plans for summary, invitations and the full expense page.

The approved diagnostic tokens lasted two minutes, remained in process memory,
and were passed to curl through stdin only. Every diagnostic process discarded
its token. No token or financial response body was saved to files, logs, Git or
Smartlog. No extra authenticated personal reads or live expense/settlement writes
were added outside the previously approved three-GET token scope.

## Layout changes

- Personal summaries retain all three cards while ledger/currency data loads;
  unknown totals display a dash, rather than a temporary zero. Cards remain
  mounted during conversion. Currency preference controls retain their structure
  during profile loading, and currency status retains space after confirmation
  disappears.
- Group detail uses the same header/hero from loading through summary and full
  detail. Financial loading placeholders have no invented balances. The summary
  cards also reserve their place while transaction/settlement detail loads.
- Paired original/converted currency rows exist while the rate is pending;
  conversion no longer inserts a new secondary line afterward. Header, summary,
  and status regions reserve responsive space for their expected content.
- Loaded group headers still use the query hook's current member, expense and
  balance snapshots, preserving optimistic updates after expense/settlement edits.
  Settlement math, totals, stored amounts, authorization and permissions are
  unchanged.

DOM regression tests verify cards/heroes/status regions retain their nodes
across pending, loaded, saving, conversion and confirmation-expiry states.
They do **not** measure CLS. Browser automation became available, but its policy
check stopped the selected Chrome window because it could not determine the
current URL confidently. No further browser input was issued. Foreground
post-fix LCP/CLS/INP measurement is still required; no CLS <0.1 claim is made.

## Validation

Passed: 554 web tests across 60 suites; 79 focused API tests covering the
reloader, cooperative PostgreSQL waiting, personal finance and paginated group
reads; 74 infrastructure tests; web lint/typecheck/build; changed-Python Ruff;
repository import/structure and Git whitespace checks. Existing React act,
Python deprecation/cache-directory and Vite chunk warnings remain. The earlier
full API run (687 passed, three skips) belongs to the previous report; this
follow-up did not rerun the entire backend suite.

```powershell
# C:/Tripraft/services/api
C:/Tripraft/.venv/Scripts/python.exe -m pytest tests/test_dev_reload.py tests/test_cooperative_database.py tests/test_personal_finance.py tests/test_expense_read_latency.py -q
# C:/Tripraft/apps/web
& 'C:/Program Files/nodejs/node.exe' C:/Tripraft/apps/web/node_modules/jest/bin/jest.js --runInBand --json --outputFile=C:/Tripraft/.tripraft/expense-reloader-cls-web-final.json
& 'C:/Program Files/nodejs/node.exe' C:/Tripraft/node_modules/eslint/bin/eslint.js src tests
& 'C:/Program Files/nodejs/node.exe' C:/Tripraft/node_modules/typescript/bin/tsc --noEmit
& 'C:/Program Files/nodejs/node.exe' C:/Tripraft/apps/web/node_modules/vite/bin/vite.js build
# C:/Tripraft
C:/Tripraft/.venv/Scripts/python.exe -m ruff check services/api/app/core/dev_reload.py services/api/run.py services/api/tests/test_dev_reload.py
C:/Tripraft/.venv/Scripts/python.exe -m unittest discover -s infra/tests -q
C:/Tripraft/.venv/Scripts/python.exe infra/tools/check_structure.py
git diff --check
```

## Reproduction

From `C:/Tripraft` (private helpers remain ignored and contain no saved token):

```powershell
C:/Tripraft/.venv/Scripts/python.exe .tripraft/measure-running-expense-curl.py reloader-before
C:/Tripraft/.venv/Scripts/python.exe .tripraft/measure-running-expense-curl.py reloader-after
# Run this from services/api to match the server's working directory:
C:/Tripraft/.venv/Scripts/python.exe C:/Tripraft/.tripraft/profile-reloader-lag.py
C:/Tripraft/.venv/Scripts/python.exe .tripraft/profile-db-protocol.py --gevent
C:/Tripraft/.venv/Scripts/python.exe .tripraft/profile-db-protocol.py
C:/Tripraft/.venv/Scripts/python.exe .tripraft/profile-expense-all-plans.py
```

The HTTP helper calls only the three approved paths, using:

```text
curl.exe --silent --show-error --max-time 35 --config - --write-out "\n%{json}" http://127.0.0.1:5000/<approved-path>
```

The Authorization config goes through subprocess stdin; raw response stdout is
hashed in memory and discarded. The `before` command was run before installing
the cooperative reloader; running it now will measure the current code.

## Changed files

- `services/api/app/core/dev_reload.py`
- `services/api/run.py`
- `services/api/tests/test_dev_reload.py`
- `apps/web/src/features/expenses/jsx/ExpenseManager.jsx`
- `apps/web/src/features/expenses/jsx/ExpenseSummary.jsx`
- `apps/web/src/features/expenses/jsx/GroupDetailHeader.jsx`
- `apps/web/src/features/expenses/jsx/GroupSummaryCards.jsx`
- `apps/web/src/features/expenses/jsx/GroupManager.jsx`
- `apps/web/src/features/expenses/jsx/CurrencyChangeStatus.jsx`
- `apps/web/src/features/expenses/css/CurrencyChangeStatus.css`
- `apps/web/src/features/expenses/css/ExpenseResponsive.css`
- `apps/web/src/__tests__/expenseLayoutStability.test.jsx`
- `docs/operations/expense-reloader-evidence-2026-10-26.json`
- `docs/archive/reports/expense-reloader-and-layout-fix-2026-10-26.md`
- `docs/archive/reports/groups-page-load-fix-2026-10-26.md`
- `docs/archive/reports/expense-browser-delay-fix-2026-10-26.md`
