# Copied expense invitation links — 2026-10-12

> Historical report. Results, local accounts, file counts and open findings describe the original checkpoint. For current setup and contracts, use the [documentation index](../../README.md). Raw CSV/JSON/ZIP exports referenced here are preserved locally and in earlier Git history; they are not current repository inputs.

The frontend requested `GET /api/v1/expenses/invitations/{id}/details`, but that
route was missing. The live API log confirmed HTTP 405. The invitation page,
login form and signup form also attempted private detail requests before the
visitor signed in, leading to repeated errors instead of a normal sign-in flow.

The private GET route now exists. The recipient, inviter and group admins may
read it; anonymous visitors receive 401 and unrelated accounts receive 403.
Reading an expired invitation reports its expiry without changing stored status.
Responses remain private and non-cacheable.

Copied links now send signed-out visitors directly to login with the invitation
ID in the URL. Login/signup preserve it and return to the same invitation after
authentication. The flow works without browser storage, ignores stale invitation
email data and gives the explicit copied link priority over older stored invites.
Only the invitation page submits acceptance, with a guard against duplicate calls.
A wrong account can switch to sign-in without fetching another account's details.

The requested persistent email-disabled message and URL input have been removed.
Creating an invitation opens the Pending tab with **Copy invite link** available.
Copying an existing pending invitation remains supported; a raw URL is shown only
on request when the clipboard is unavailable.

## Verification

- Five frontend suites passed: 46 tests, including signed-out links, resumed
  acceptance, signup/login without storage, stale invitations, wrong accounts,
  session restoration and absence of the removed banner/URL input.
- Backend group lifecycle suite passed: 26 tests, including the real GET details
  route's 200/401/403/404 responses, private caching and read-only expiry behavior.
- Changed-file frontend lint, web typecheck and production build passed. Vite
  retained its existing large expense-page chunk warning.
- The running development API was checked through the Vite proxy on port 5173;
  an anonymous details request returned 401 with `private, no-store`, replacing
  the missing-route 405. Signed-out UI flows make no private details requests.
- Backend tests used a throwaway migrated database; no real invitations were
  accepted and no email was sent by tests.

Local Interactive Smartlog checkpoint: `group-invitation-link-fix`.
