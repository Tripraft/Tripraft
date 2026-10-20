# Email verification blank page — 2026-10-12

> Historical report. Results, local accounts, file counts and open findings describe the original checkpoint. For current setup and contracts, use the [documentation index](../../README.md). Raw CSV/JSON/ZIP exports referenced here are preserved locally and in earlier Git history; they are not current repository inputs.

The signup email links to `/verify-email/{token}`. The API already supported
public verification at `GET /api/v1/auth/verify-email?token=...`, but the web app
had no matching route or page. React Router therefore rendered no page for the
email link. The user's screenshot confirms that a company-branded signup email
was delivered; the blank screen was a frontend routing issue.

The new public `/verify-email/:token?` route submits verification without a
login or session refresh prerequisite. The page displays loading, success,
already verified, invalid/expired, missing-token and network failure states.
StrictMode effect replay shares its in-flight request. Signed-in users can
explicitly request another verification email using the existing authenticated,
CSRF-protected resend endpoint; signed-out users can sign in to request one.
No email is resent automatically. Successful verification refreshes an existing
signed-in profile, and Continue preserves a pending group invitation.

Verification tokens expire after 24 hours. The backend sets `email_verified`
and persists `email_verified_at`. The current application does not require
verification for login or group membership. Verification confirms control of
the account's email address; it does not itself join an expense group.

## Validation

- Four frontend regression suites passed: 56 tests, including the real App
  route, public verification, loading/errors/retry, explicit resend, pending
  invitations and the existing authentication/invitation route behavior.
- Backend auth token suite passed: 12 tests. Public verification succeeds and
  can be reopened; missing, invalid, expired and refresh tokens are rejected
  without verifying the account. Verification mail is mocked for all signups
  in this suite, and tests use a throwaway migrated database.
- Changed-file ESLint, web typecheck and production build passed, retaining
  the existing Vite large chunk warning.

The user's real token was not submitted, recorded in source, or used to change
their verification status. No real email was sent during this fix. The local
`email-verification-page-fix` checkpoint contains the implementation, tests,
setup documentation and this report; unrelated workspace changes are excluded.
