# Groups and personal expense load follow-up

October 26, 2026 (America/Los_Angeles). Baseline: `c00e267`.

The supplied browser evidence is valid: a text balance heading took 10.56s to
become LCP, with groups/invitations/full reads taking 9.48s/4.34s/14.05s.
Existing backend logs independently recorded successful requests taking
14.85s/10.16s/20.09s. This work targets database waits and repeated reads.

## Direct measurement

Both versions were measured with curl against the same local gevent application,
development PostgreSQL account and development group. The baseline service
implementations were loaded from Git in memory; the final implementations used
the working files. Authentication, middleware, database, response contracts and
gevent cooperation were the same. This isolates these code changes, but does
not reproduce the original long-running worker's entire runtime state.

Three serial samples per endpoint/version; medians below are milliseconds.
HTTP SQL counts include the unchanged authentication lookup (one query).

| Endpoint | Browser before, ms | Direct before total | Direct after total | SQL before → after |
|---|---:|---:|---:|---:|
| `groups?mode=summary` | 9,480 | 1,315.099 | 1,304.360 | 9 → 6 |
| `invitations` | 4,340 | 807.338 | 786.333 | 3 → 2 |
| `groups/{id}/full?...limit=100...` | 14,050 | 2,307.774 | 1,593.769 | 15 → 8 |

| Endpoint | Before TTFB | After TTFB | Before download | After download |
|---|---:|---:|---:|---:|
| Groups summary | 1,315.031 | 1,304.258 | 0.114 | 0.102 |
| Invitations | 807.251 | 786.180 | 0.087 | 0.092 |
| Full detail | 2,307.250 | 1,593.205 | 0.444 | 0.564 |

TTFB includes network, acceptance/queueing, authentication, connection acquisition,
SQL and serialization. Curl cannot separate those components on its own.
Tiny download times and backend logs prove that frontend assets/download
bandwidth are not the bottleneck.

With all three endpoints running concurrently, baseline medians were
1,410.502/816.153/1,962.779ms (summary/invitations/full); final medians were
1,200.161/747.206/1,379.177ms. All nine final concurrent samples were below
1.5s. The fresh cooperative worker serves requests concurrently; it does not
reproduce a single-threaded queue. The original 10–20s worker state remains
unexplained by these fresh-worker measurements, so this report does not claim
that SQL changes alone explain that whole gap.

The serial final full-detail samples were 1,593.769, **2,214.795**, and
1,223.923ms. The requirement that every call be under two seconds has therefore
**not** passed universally. Groups and invitations were under two seconds in
all final HTTP samples. Fewer round trips helped full detail; summary and
invitation wall-clock changes were small relative to network variation.

All HTTP responses were 200. Before/after hashes of the complete JSON `data`
objects matched in every sample, including fields, totals, balances, pagination,
expenses and settlements. The direct service hashes independently matched.
Only timings, hashes and SQL/plan diagnostics were retained; no financial
response bodies or credentials were saved. Each diagnostic token expired after
two minutes and was discarded from process memory when its measurement ended.

The [machine-readable evidence](../../operations/groups-page-load-evidence-2026-10-26.json)
contains every HTTP sample, response hashes, service query counts, the exact
parameterized slowest SQL statements and their redacted PostgreSQL
`EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` output.

## Causes and changes

**Summary:** `GroupServiceSQL.get_user_groups` used eight service queries,
including four separate executes in `group_summaries`. Those aggregates already
avoided N+1 loading. `UNION ALL` now sends the same four aggregates in one
execute; service SQL is five. Decimal sums, category tie ordering, deleted-row
exclusion and the fourteen-day trend retain their original behavior.

**Invitations:** `get_pending_invitations_for_user` separately fetched the user
before reading invitations. One outer join now retains the user-not-found error,
even with no invitations, and keeps the same expiry, active-group and existing
membership filters. Service SQL falls from two to one.

**Full:** `_full_group_data` repeated four summary executes, separately counted
both paginated ledgers, loaded splits separately, and re-read member balances
already available in the snapshot. It now uses the combined summary, window
counts with SQL pagination, eager split loading, and the loaded balance snapshot.
An empty nonzero offset still performs its count query, preserving totals beyond
the end of a ledger. Normal first-page service SQL falls from fourteen to seven.

No index migration was added: measured plans do not show expensive scans on
this dataset. The slowest observed client queries and actual database execution:

| Endpoint | Slowest code/query | Client SQL call, ms | PostgreSQL execution, ms |
|---|---|---:|---:|
| Summary | Membership-filtered group/owner SELECT with group ordering | 385.634 | 0.102 |
| Invitations | Recipient/pending invitation outer join and membership exclusion | 213.734 | 0.149 |
| Full | `Group.balances` batch SELECT, bitmap heap/index scan | 403.826 | 0.054 |

These are different observations of the same statements, not a subtraction of
identical executions. They show that network/driver/remote pool wait dominates
server execution. Cold direct-service runs also include establishing a new
connection. No authentication caching, permission change or connection-health
check removal was introduced to hide that cost. Request logs now populate SQL
count/time and slowest-query fingerprints, and `Server-Timing` exposes app/DB
timings for follow-up correlation. Parameters are never logged by this tracking.

**Repeated requests:** React Query already coalesces equal query keys, and the
successful 200s do not trigger retries. StrictMode is covered by an integration
test with the real hooks, API service and APIClient. The confirmed extra fetch
paths were initial socket recovery after a completed read, focus/visibility
recovery, and unconditional polling every minute even with a healthy socket.
Recovery coalesces recent/in-flight reads; a healthy socket flushes accumulated
change events when visibility returns and no longer polls unchanged ledgers.
Disconnected fallback polling, genuine ledger events and reconnect reconciliation
remain active. APIClient also shares identical pending GETs, clearing entries on
success/error and separating accounts, options, pages, cancellations and writes.
It stores no completed financial response cache. Remount authorization checks
remain intact, including revoked membership regression coverage.

**First content:** `ExpenseManager` already ran the three query hooks in parallel;
there was no three-request sequential waterfall. The balance `h3.is-negative`
was nevertheless gated by full detail. It can now render from the exact summary
card while detail/invitations load. The page heading and an overview heading
render before either group response. Each failed API has a visible error and
retry path. Personal mode retains its parallel expense/income reads and benefits
from the shared GET/recovery fixes. No additional live personal endpoint requests
were made outside the user's three-endpoint diagnostic authorization.

## Verification and remaining acceptance

- Complete web suite: 551 tests across 59 suites; final recovery/authorization
  integration checks also pass.
- Admin suite: 29 tests across five suites passed.
- API regression checks cover group lifecycle, personal finance, invitations,
  query counts, exact cents/category ties, trend limits, pagination/split joins,
  beyond-end offsets and request-local SQL timing. The full API regression run
  passed 687 tests with three environment-dependent skips; the final focused
  run passed 51 checks, including the two new SQL/pagination tests.
- Web build, lint/typecheck, changed-Python Ruff and import/structure checks
  passed. All 74 infrastructure tests passed. Existing React act warnings,
  Python deprecations/cache-directory warnings and Vite's chunk warning remain.
- Foreground browser Network/LCP/CLS/INP are **pending the user's measurement**.
  Computer-use initialization reported no available native browser connection.
  No post-fix LCP, CLS or INP number is claimed. The supplied 10.56s/0.03/32ms
  are baseline evidence only. The foreground browser check must establish one
  initial request per endpoint, LCP <2.5s, CLS <0.1 and INP <200ms.

## Exact measurement commands

Run from `C:/Tripraft`. The private helpers remain in ignored `.tripraft/` and
contain the approved development IDs, never a saved token. They created the
two-minute token in memory and called curl with this argument list:

```text
curl.exe --silent --show-error --max-time 45 --config - --write-out "\n%{json}" http://127.0.0.1:5001/<one-of-the-three-approved-paths>
```

The Authorization config was passed through the subprocess's stdin. Stdout was
parsed only in memory to hash `data` and retain curl's timing/status fields.

```powershell
C:/Tripraft/.venv/Scripts/python.exe .tripraft/profile-expense-reads.py before
C:/Tripraft/.venv/Scripts/python.exe .tripraft/measure-expense-curl.py
C:/Tripraft/.venv/Scripts/python.exe .tripraft/measure-expense-parallel.py
C:/Tripraft/.venv/Scripts/python.exe infra/tools/profile_expense_reads.py --user-id <same-development-user-uuid> --group-id <same-development-group-uuid> --explain --output .tripraft/expense-read-final.json
```

The last command uses the committed reusable SQL profiler; IDs are redacted in
this document. Actual parameterized statements/plans are in the evidence JSON.
The `before` service command ran before edits; the HTTP helpers reconstruct the
baseline services from Git in memory when re-run.

Validation commands (run in the indicated working directory):

```powershell
# C:/Tripraft/services/api
C:/Tripraft/.venv/Scripts/python.exe -m pytest -q
C:/Tripraft/.venv/Scripts/python.exe -m pytest tests/test_expense_read_latency.py tests/test_expense_mutation_latency.py tests/test_expense_group_lifecycle.py -q
C:/Tripraft/.venv/Scripts/python.exe -m ruff check app/core/db/timing.py app/core/db/connection.py app/core/middleware.py app/expenses/services/expense_group_service.py app/expenses/services/expense_invite_service.py app/expenses/services/ledger_math.py tests/test_expense_read_latency.py ../../infra/tools/profile_expense_reads.py
# C:/Tripraft/apps/web
& 'C:/Program Files/nodejs/node.exe' C:/Tripraft/apps/web/node_modules/jest/bin/jest.js --runInBand --json --outputFile=C:/Tripraft/.tripraft/groups-load-web-final-results.json
& 'C:/Program Files/nodejs/node.exe' C:/Tripraft/node_modules/eslint/bin/eslint.js src tests
& 'C:/Program Files/nodejs/node.exe' C:/Tripraft/node_modules/typescript/bin/tsc --noEmit
& 'C:/Program Files/nodejs/node.exe' C:/Tripraft/apps/web/node_modules/vite/bin/vite.js build
# C:/Tripraft
C:/Tripraft/.venv/Scripts/python.exe -m unittest discover -s infra/tests -q
C:/Tripraft/.venv/Scripts/python.exe infra/tools/check_structure.py
git diff --check
# C:/Tripraft/apps/admin
& 'C:/Program Files/nodejs/node.exe' C:/Tripraft/apps/admin/node_modules/jest/bin/jest.js --runInBand
```

## Changed files

- `apps/web/src/utils/apiClient.js`
- `apps/web/src/hooks/useExpenseLiveUpdates.js`
- `apps/web/src/features/expenses/jsx/ExpenseManager.jsx`
- `apps/web/src/__tests__/apiClient.test.js`
- `apps/web/src/__tests__/expenseLiveUpdates.test.jsx`
- `apps/web/src/__tests__/expenseInitialRequests.test.jsx`
- `apps/web/src/__tests__/expenseGroupNavigation.test.jsx`
- `services/api/app/expenses/services/expense_group_service.py`
- `services/api/app/expenses/services/expense_invite_service.py`
- `services/api/app/expenses/services/ledger_math.py`
- `services/api/app/core/db/connection.py`
- `services/api/app/core/db/timing.py`
- `services/api/app/core/middleware.py`
- `services/api/tests/test_expense_read_latency.py`
- `infra/tools/profile_expense_reads.py`
- `docs/operations/groups-page-load-evidence-2026-10-26.json`
- `docs/archive/reports/groups-page-load-fix-2026-10-26.md`
- `docs/archive/reports/expense-browser-delay-fix-2026-10-26.md`
