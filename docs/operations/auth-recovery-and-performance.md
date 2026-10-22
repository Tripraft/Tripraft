# Traveler authentication fixes

Checkpoint: `auth-password-recovery-performance` · October 21, 2026.

Login, signup and password recovery now provide accessible show/hide controls.
Signup and reset show a live checklist for length, UTF-8 byte limit, uppercase,
lowercase, number and supported special characters. The checklist shares the
submission validator. Existing passwords remain usable on the login form.

“Forgot password?” opens a public email request form. Recovery links expire after
one hour and become unusable after a successful password change. Account lookup
and email delivery run outside the HTTP request, so known and unknown addresses
receive the same response. Resetting a password atomically changes its version,
deletes refresh sessions and rejects old access tokens on protected HTTP routes
and new socket connections. Reset does not automatically sign the user in.
New emails put the token in the URL fragment; older path links also work.

## Loading changes

- Credentials can be submitted while cookie restoration is pending. Explicit
  sign-in/signup supersedes late restoration results; duplicate submissions stay
  blocked. Returning-device restoration and invitation routing are preserved.
- The decorative QR library loads after the auth form renders. Its production
  chunk is approximately 24.5 kB before compression and is no longer a static
  dependency of Login or Signup.
- Signup queues verification delivery on a bounded, two-worker email executor.
  SMTP or HTTP provider latency therefore no longer holds the signup response.
  Password hashing strength and request timeouts are unchanged.

These changes remove identified waits; production network latency was not
benchmarked. Email work is best effort within the API process, with logged
failure/capacity feedback; users can request another reset link or resend
verification if delivery fails or the process restarts before delivery.

## Validation and local use

Auth form, service, session, routing and recovery tests cover visibility,
checklist updates, pending startup, validation, duplicates, retry and completion.
Backend tests cover non-enumerating responses, expiry, wrong token types,
single use, old-password rejection, session revocation and nonblocking signup.
Migration tests cover fresh install, upgrade with preserved data, downgrade and
reinstall. Web and API-client lint/type checks and the web production build pass.

The reviewed schema owner applies migrations separately to a target that needs
them; `python start.py` never upgrades, downgrades or stamps a database. The shared
development database is already at `a74b8293a4b5`, so align its source revision
and models without reapplying or downgrading its history. The integration launcher
only verifies readiness and restricted credentials. Recovery emails use the
configured email provider and approved frontend URL; tests mock delivery and do
not send real email. Cross-computer email/link testing remains a separate
approval-dependent validation step.

Source files and this report are saved in the local Git/Sapling history for
Interactive Smartlog. Existing unrelated working-tree edits remain separate.
