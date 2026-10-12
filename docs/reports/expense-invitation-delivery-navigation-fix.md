# Expense invitation delivery and group destination — 2026-10-12

The updated API environment contained SMTP credentials but omitted
`EMAIL_ENABLED`, leaving expense invitation mail disabled. The earlier API logs
reported “Email service is disabled”; no successful delivery was logged. The
login address also had `gmal.com` instead of `gmail.com`, and `FROM_EMAIL` was
the literal text `SMTP_USER`.

After the user confirmed the company mailbox, the ignored `services/api/.env`
was corrected to enable delivery and use `tripraft@gmail.com` for both SMTP
login and sender. The password was preserved and never printed or committed.
The root `.env` was empty; the active API configuration comes from
`services/api/.env`. A fresh process loaded the enabled configuration. A real
SMTP connection to Gmail on port 587 completed STARTTLS and authenticated
successfully with the saved company credentials. Earlier diagnostic attempts
disconnected; the final check succeeded. No message was sent by the diagnostic.

Recipients receive company-branded mail from TripRaft; the existing subject and
body name the inviter and group. Users sending invitations do not need personal
SMTP credentials. SMTP authentication verifies access to the sending account;
it does not prove delivery to any recipient’s inbox.

Previously saved pending invitations are not mailed automatically by restarting
the API. Their inviter or a group admin can now use **Resend email** beside
**Copy invite link**. The new authenticated, rate-limited POST endpoint
`/api/v1/expenses/invitations/{id}/resend` retries transport without duplicating
the row, extending expiry or changing membership. Disabled, queued, failed and
sent results are reported accurately in a transient alert; the removed
persistent delivery banner and raw URL input remain absent. Declined or expired
invitations retain their existing separate renewal workflow.

Acceptance previously navigated to `/expenses`, defaulting to personal mode.
The dashboard also discarded `groupId` and selected its first group. Accepted
links now navigate to `/expenses/{userId}/group?groupId={joinedGroupId}` after
login or signup. Already accepted links resolve their private details and open
the same group. The dashboard reads mode and group selection directly from the
URL, preserving deep links, refreshes, browser back and newly created groups.
Dashboard invitation acceptance also unwraps the API envelope and selects the
returned group rather than the first listed group.

## Verification

- Six frontend regression suites: 65 tests passed, including the actual smart
  invitation handler, login/signup, reopened invitations, exact group selection,
  browser back, group creation and email retry feedback.
- Backend group lifecycle suite: 35 tests passed, including resend permissions,
  delivery status, unchanged link/expiry, rejected inactive invitations and
  unchanged membership/ledger behavior. SMTP delivery is mocked in these tests.
- Changed-file frontend lint and web typecheck passed; production build passed
  with the existing large chunk warning.
- The existing Tripraft launcher and only its owned local service tree were
  restarted to load the corrected environment. API health, web and admin each
  returned 200. Anonymous invitation details and resend requests through the
  Vite proxy returned 401 with `private, no-store`, confirming the live routes
  exist and require authentication. No real invitation was accepted and no real
  email was sent during this work.

The source changes, regression tests, API/setup documentation and this report
are saved in the local `group-invitation-delivery-navigation-fix` Interactive
Smartlog checkpoint. Secret environment files stay local and ignored; unrelated
pre-existing workspace changes are excluded from the checkpoint.
