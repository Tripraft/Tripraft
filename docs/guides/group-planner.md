# Group planner behavior

Groups open as soon as creation succeeds. Initial invitations continue in batches
of at most three requests, with failed addresses retained for retry. Saved group,
poll and checklist responses populate the current workspace before background
refreshes finish. A result from a previous group cannot overwrite the current
group's poll form or invitation retry form.

Poll questions, options and multiple-choice settings are fixed after creation.
The composer disables every field, option action, close action and submit action
while saving. Duplicate submits are ignored. A failed save preserves the draft
and enables retry. Members can vote and delete their own polls; viewers cannot
create polls or vote. Poll voting returns the saved poll with counts and voter
details, so results update without waiting for another collection request.

Checklist creation emits `checklist:created` after saving and invalidating the
checklist and activity caches. Other connected group members refresh their task
list and Pulse feed when the event arrives.

Planner timestamps identify UTC instants with an explicit `+00:00` offset,
including values reloaded from SQLite. The browser displays those instants in
each member's system timezone. Existing cached timestamps without an offset
are interpreted as UTC. Changing the user's system timezone changes local
display; the app does not need geolocation permission. Trip start/end dates,
visit dates, date-only checklist due dates and destination stop clock times
retain their calendar meaning.

The Logistics vault accepts PDF, JPEG, PNG and WebP files up to **10,485,760 bytes**
(the UI labels this 10 MB). The browser checks size before upload. The API checks
actual bytes even if size metadata is absent, reads no more than the limit plus
one byte, and returns HTTP 413 for oversized files. Exactly the limit is accepted.
Oversized files create no vault document or stored file. An inline error remains
visible and selecting another file is possible immediately. Uploaded documents
show their stored size in the vault list.

New uploads default to `VAULT_STORAGE_BACKEND=database`: metadata and file content
use the existing `DATABASE_URL`, so the current Supabase PostgreSQL settings work
without a new API key. Migration `a06cb5d6e7f9` adds `gp_vault_file_contents`, with
bounded base64 payloads separate from metadata so listings never fetch whole PDFs.
Content and metadata commit together and deletion removes the content atomically.
The new table denies Supabase's `anon`/`authenticated` Data API roles direct access.
The approved development migration manifest grants only the backend runtime role.
Use the [normal development/release migration workflow](../operations/database-releases.md).

Every active member of the **same group**, including viewers, can list, preview
and download the group's files. Outsiders, other groups and revoked members are
denied on every API read. Upload/delete events refresh other members' vault lists.
The preview has one consistent Download button in its header. Downloading a loaded
preview reuses its object URL, with no second HTTP request; standalone downloads
show progress and reject duplicate in-flight requests. Failed previews offer retry.

Existing disk uploads remain readable. Explicit `VAULT_STORAGE_BACKEND=local` is
available for offline development. Optional `VAULT_STORAGE_BACKEND=supabase` uses
a private object bucket instead: configure API-only `SUPABASE_URL`,
`SUPABASE_SERVICE_ROLE_KEY` and `SUPABASE_VAULT_BUCKET=tripraft-group-vault`, then run
`python infra/tools/setup_planner_storage.py --create` once. The command checks an
existing bucket without changing it, or creates a missing private bucket with the
10 MB and MIME limits. Runtime uploads refuse a public bucket. Storage keys/object
paths are never returned to browsers; downloads pass through group authorization.
This optional backend follows [Supabase's private download API](https://supabase.com/docs/guides/storage/serving/downloads).

The Treasury tab shows spend, budget, per-person totals, balances and recent
expenses. The standalone currency exchange cards have been removed. Budget
display currency calculations continue to keep totals comparable.

See [trip invitation delivery](../setup/email.md#trip-planner-invitation-delivery)
and [measured latency and verification](../archive/reports/group-planner-latency-2026-10-27.md).
