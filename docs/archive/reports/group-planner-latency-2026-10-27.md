# Group planner latency, timestamps and uploads

October 27, 2026 (America/Los_Angeles). Baseline: `a74e647` on develop.

## Result

Group creation, invitations, poll creation/voting and checklist creation perform
fewer database round trips. The group opens before its initial invitations finish;
invitations run in batches of three. SMTP delivery runs in the existing bounded
executor, with explicit queue availability states. Successful group/poll/task
responses render immediately while collection reads reconcile in the background.

Poll creation locks the complete composer and rejects duplicate submission.
Failure preserves the editable draft. Created questions/options/settings remain
immutable; PUT/PATCH return 405. Permission checks still deny viewers/nonmembers.

Poll notifications share the poll transaction. Voting locks the poll row and loads
votes in a subsequent SELECT, so PostgreSQL lock waits do not reuse an earlier
vote snapshot. Updated counts/voter details return with the vote response. Cache
invalidation precedes poll/checklist creation broadcasts. Checklist creation now
has a live event; checklist writes and invitation changes invalidate activity data.

All planner timestamp serializers now include a UTC offset, including chat,
polls, places, checklist completion/creation, invitations, activity and documents.
Local display handles legacy cached UTC timestamps without suffixes. Calendar
dates and stop times keep their intended date/clock values.

Uploads retain the existing 10 MB product limit, now checked using a bounded
10,485,761-byte read. Exactly 10,485,760 bytes is allowed; an extra byte returns
413 and stores neither metadata nor bytes. Multipart body overflow also returns
413 instead of being caught as a 500. The UI shows the size error inline and
clears the file input so the user can select again. Treasury's standalone currency
exchange cards were removed.

The expanded file-sharing change defaults to the current Supabase PostgreSQL
connection. An additive migration stores bounded file bodies separately from
vault metadata, without requiring another key. A private Supabase Storage bucket
backend is also available explicitly; missing credentials fail visibly. Upload
and deletion events refresh other members' lists. All same-group roles can read,
and outsiders, other groups and revoked members cannot. Preview downloads reuse
the already loaded object URL, removing the former second GET; the shared header
button has the same position and behavior for all members.

## Measurement

The [raw samples](../../operations/group-planner-latency-evidence-2026-10-27.json)
contain five warm samples per operation/version from Flask's HTTP test client,
a migrated disposable SQLite database, one actor and no SMTP/network delivery.
A complete warmup workflow was excluded for each version. The same process and
database engine ran the original services/routes loaded from baseline Git source
in memory, then the final implementations. Authentication and authorization were
included. SQLite data never touched the development or production account database.

| Operation | Before median ms | After median ms | SQL before → after |
|---|---:|---:|---:|
| Create group | 9.821 | 7.494 | 11 → 8 |
| Create poll | 10.734 | 7.331 | 13 → 8 |
| Vote on poll | 8.907 | 6.949 | 13 → 7 |
| Create checklist task | 9.173 | 7.424 | 10 → 8 |
| Create invitation | 9.149 | 7.552 | 12 → 8 |
| Add place | 11.874 | 10.741 | 15 → 15 |
| Send chat message | 8.300 | 7.305 | 8 → 8 |

These are isolated application timings, **not deployed API or browser timings**.
Small SQLite wall-clock differences can vary with host load. Place/chat query
paths were measured but not optimized; their timing differences are not attributed
to an implementation improvement. Invitation SMTP was stubbed in both versions,
so the table excludes the removed email-network wait. The deterministic HTTP
regression verifies that SMTP never runs before create/resend returns.

The local ignored measurement helper is `.tripraft/profile-planner-writes.py`;
it reads original source using `git show a74e647:<path>`, imports the disposable
pytest fixture, runs each workflow six times and writes only counts, statuses
and timings. Run with `.venv/Scripts/python.exe .tripraft/profile-planner-writes.py`.
The published `test_planner_latency.py` enforces the final write query budgets
without a flaky wall-clock threshold.

Remote PostgreSQL latency, browser interaction timings and actual SMTP delivery
remain unmeasured in the timing table. The storage migration is separately tested
on disposable PostgreSQL. The approved development migration bridge applied
`a06cb5d6e7f9` to the configured development Supabase database. A subsequent schema
comparison passed; the backend has CRUD and the `anon`/`authenticated` Data API
roles have no access to the content table. No production migration was performed.
No API readiness endpoint was reachable on local port 5001 during the final check;
restart the application to load this source revision.

## Validation

- Complete final web suite: **568 tests across 62 suites passed**.
- Final planner, upload, sharing, migration, authorization and delivery regression
  run: **97 passed**. After adding the 10 MB database round-trip and download query
  budget assertions, the final shared-file suite passed **8 tests**.
- Disposable PostgreSQL migration, additive startup bridge, permission and
  data-preservation checks: **3 passed**. Infrastructure checks: **74 passed**.
- Web lint/typecheck/build, changed-Python Ruff, Python 3.11 syntax,
  structure/import checks and infrastructure validation passed. OpenAPI
  regeneration retained the same 210 paths and no contract diff.
- Local-time tests passed in America/Los_Angeles and Asia/Kolkata.
- An earlier complete API run had 706 passes, three environment-dependent skips
  and one legacy synchronous-email expectation. Both affected delivery contract
  modules were updated for deferred delivery and rerun successfully (25 tests);
  they also pass in the final 97-test regression run.

Existing Vite chunk-size, React act and Python deprecation warnings remain.
