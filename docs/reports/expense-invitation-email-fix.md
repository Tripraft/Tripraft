# Expense invitation delivery findings — 2026-10-12

The local API log recorded `Email service is disabled` when the reported
invitation was created. The invitation POST returned HTTP 201 because the
invitation was saved, but no email transport was attempted.

The active `services/api/.env` has Gmail's SMTP host and port, with empty
`SMTP_USER`, `SMTP_PASSWORD` and `FROM_EMAIL`; `EMAIL_ENABLED` is absent and
defaults to false. The checked example, archived configuration files and process
environment did not contain a configured sender or password. No credentials
were displayed or changed, and no real email was sent during verification.

## Repairs

- Unwrap the API response before reading `email_status` and `invitation_link`.
  The old screen read the envelope itself and hid the disabled-delivery result.
- Show distinct disabled, queued, sent and failed delivery messages, plus a
  selectable invitation link. Queue acceptance is not described as delivery.
- Add **Copy invite link** for existing pending invitations, with a selectable
  fallback if the clipboard is unavailable. This does not send another message.
- Use the registered `/invitation/{id}` expense route in both SMTP email content
  and API responses. The previous email and API links used different routes.
- Unwrap the fallback invitation list and pass the cache-busting timestamp in
  the expected argument position.
- Use synchronous SMTP directly when native development has no task broker
  configured; keep queued delivery when a broker is configured.
- Pass UTC timestamp strings to the existing timezone formatter so it can
  recognize the timezone before formatting invitation dates.

See [Gmail setup](../email-setup.md) for the remaining sender configuration.
Actual Gmail delivery remains unverified until sender credentials are supplied.

## Verification

- Three frontend suites passed: 14 tests covering email delivery status from the
  API envelope, selectable links, copying existing invitations, clipboard failure,
  group creation and registered invitation routes.
- The backend group lifecycle suite passed: 25 tests, including email template
  links, invitation response links for each delivery state, synchronous delivery
  without a broker, and existing acceptance/membership protections.
- Changed-file frontend lint, web TypeScript check and production build passed.
  Vite retained its existing large expense-page chunk warning.
- Email transports were mocked in tests; backend tests used a throwaway database.

Local Interactive Smartlog checkpoint: `group-invitation-email-fix`.
