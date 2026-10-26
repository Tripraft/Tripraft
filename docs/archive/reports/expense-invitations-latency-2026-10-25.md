# Expense invitations and mutation latency

Date: October 25, 2026 (America/Los_Angeles).

## Findings

The reported POST `/api/v1/expenses/invitations` 409 is consistent with the
service rejecting a second creation while the same group's invitation remains
pending. A saved invitation could have an earlier failed delivery. Creating it
again did not retry delivery. The form also displayed the same "Invitation
created" alert for queued, disabled and failed delivery, hiding the next action.

The local API log recorded a 409 invitation request at 1,311.4 ms, group-list
reads around 4,092 ms, an invitation read at 1,951.1 ms and a personal expense
read at 2,093.3 ms. These are historical local observations, not a controlled
before/after latency benchmark. The application uses remote PostgreSQL. Each
additional database round trip and sequential API refresh adds visible delay.

Email is enabled, SMTP credentials are present, Redis is empty and no separate
Celery broker is configured. SMTP TLS negotiation and authentication with the
configured Gmail account succeeded in approximately 600 ms. This diagnostic
sent no email. Credentials, sender addresses and database URLs are excluded
from this report and Git. No `.env` setting was changed.

The React DevTools line is informational. `/auth/me` 401 means an anonymous,
expired or rejected session; it is separate from an authenticated invitation
409. Existing auth code checks the cookie session, attempts a refresh and asks
for sign-in when the refresh session is rejected. This change does not suppress
401s or weaken authentication. The supplied console excerpt alone cannot
establish which session condition produced that particular 401.

## Changes

- The member form recognizes the same pending, unexpired invitee and calls the
  existing resend endpoint. If its list is stale, the web API wrapper recovers
  only the specific pending-duplicate 409 by reading the group's invitations
  and resending the matching row. Other conflicts remain errors. The server
  still checks inviter/admin authorization, active membership and expiry.
- Delivery alerts distinguish sent, queued, disabled and failed, with copy-link
  and retry guidance. Invitation creation no longer triggers a list reload,
  member refresh and second parent refresh together. The saved result updates
  the pending list, followed by one parent refresh in the background.
- With no broker, the existing bounded email worker submits SMTP outside the
  HTTP request. Its two workers and 32 capacity slots bound pending work.
  Full or unavailable capacity returns `failed`; accepted work returns `queued`.
  Invitation/contact persistence commits before any external delivery starts.
- Invitation serialization and group expense balance snapshots happen before
  commit. Group create/update/soft-delete no longer reopen the balance service
  after commit, avoiding repeated authorization queries and expired-object
  reloads. Decimal ledger updates, locks and audit history remain in place.
- Expense create, update and delete accept optional `compact=true`. The web
  requests this mode to skip account-wide ledger pages and personal summary
  work on every write. Default responses remain compatible. OpenAPI and the
  generated TypeScript declarations document the parameter.
- Personal/group save, delete and restore apply the committed result immediately
  and refresh in the background. Group deletion removes its card immediately;
  settlement mutations update their saved row/balances before refreshing.
  Independent detail/card refreshes run concurrently. A failed reconciliation
  reports "Saved, but the latest details could not load" instead of treating a
  successful write as a failure. Successful soft deletion immediately enables
  restore/permanent-delete actions even while reconciliation is slow.
- Toast IDs use a component counter to prevent duplicate keys when several
  mutation notifications occur in the same millisecond.

## Verification

- Full backend suite: **649 passed, 3 skipped**. This run collected before the
  second query-count test was added. Final invitation/compact regressions:
  **45 passed**, including both new backend tests.
- Full web suite: **498 passed across 52 suites**. Final targeted invitation,
  slow deletion, group navigation and settlement checks: **40 passed**.
- Changed Python Ruff checks, changed web ESLint checks, web typecheck and
  generated API-client typecheck passed. Production web build passed.
- The query-count regression measured **26 SQL statements for the default
  group create response and 22 for compact mode** in the same disposable SQLite
  fixture. This establishes fewer queries, not a percentage improvement in
  remote PostgreSQL wall-clock time. Tests also forbid account-ledger and
  personal-summary calls during compact group create/edit/delete and verify
  resulting balances and permanent deletion.
- A UI regression holds the group refresh unresolved and verifies that a
  committed deletion still closes its confirmation, shows success and exposes
  permanent deletion. Permission flags are included to match actual full-group
  responses. Other tests preserve conflict/authorization errors and test
  duplicate resend, disabled/failed/queued feedback and bounded-worker refusal.
- Existing dependency deprecations, a CurrencySelect React test warning and
  the production bundle-size advisory remain. Optional PostgreSQL-specific
  checks are skipped when their test service is not configured.

## Limits and operation

Remote-database reads can still take seconds; full ledgers and analytics still
require their normal reads. No new production latency percentile or inbox
delivery guarantee is claimed. Native `queued` work is best effort and can be
lost on API restart. Check delivery logs and use **Resend email** or **Copy invite
link** if needed. A configured broker also requires a running worker.

`FRONTEND_URL=http://localhost:5173` works on the development computer. Invitations
to other devices need a reachable frontend URL, as described in the
[email guide](../../setup/email.md). Existing links and expiry are preserved
when pending invitations are resent. A recipient must sign in with the invited
email address before accepting.

The implementation, regression tests, current guides, generated contracts and
this report belong to the local Git/Interactive Smartlog checkpoint
`fix/expense-invitations-latency-20261025`. Pre-existing planning edits remain
separate. No remote branch is pushed and no shared database migration, role or
permission change is part of this fix.

Local verification logs are under ignored `.tripraft/expense-latency-*`; they
are not required to run the committed regressions.

## Cancellation and resend follow-up — October 26, 2026

The first fix is Git commit `47fea32`. Its corrected local API, web and admin
services each returned HTTP 200, and Interactive Smartlog resolves its Git
branch and commit correctly.

The additional lifecycle audit confirmed that cancellation already prevented
acceptance, but queued email jobs had no current-state check. Both native
background and Celery delivery now check status, group activity, expiry and the
invitation creation timestamp immediately before SMTP. Jobs for cancelled,
declined, accepted, expired, archived or superseded invitations are skipped.
An old job cannot become active again when a cancelled recipient is re-invited.
Already-sent email cannot be recalled, and a cancellation racing after SMTP
starts may still allow that message to arrive; its link cannot join while the
invitation remains cancelled.

Authorized repeated cancellation is idempotent and preserves the original
response timestamp. Resend now checks the group lock and current contributor
role, including an inviter who has since become a viewer. Viewer UI actions
are hidden accordingly. Cancellation failures retain the pending link and allow
retry; success removes it. Re-inviting the same person resets the permanent row
to a new pending generation. Pending resend keeps the original ID/link/expiry;
accepted/cancelled resend remains rejected. No duplicate invitation or membership
rows are created. A reissued invitation intentionally reuses its existing link.

Cancelled/declined acceptance pages now explain the unavailable invitation and
clear saved login continuation, without redirecting into a group. Expiry checks
in the form consistently treat the database's naive timestamps as UTC.

Follow-up regressions cover the endpoint sequence from send to cancel, repeated
cancel, rejected acceptance/resend, re-invitation, resend and acceptance; wrong
accounts and viewer restrictions; both delivery transports across all six
obsolete states; successful current-generation delivery; failed cancellation
retry; and browser handling of cancelled/declined links. Mail is mocked in all
of these tests. Local follow-up logs use `.tripraft/expense-cancellation-*`.

Final follow-up validation: **90 backend tests passed**, including **16 new
cancellation/delivery tests**, and **39 web invitation tests passed**. Changed
Python/web lint, web typecheck and production build passed. The running Vite
proxy returned 200 for API liveness and 401 with `private, no-store` for anonymous
cancel/resend requests. No real invitation was changed and no email was sent by
the live-route verification. The API's source reloader picked up the follow-up.
