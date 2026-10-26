# Invitation email setup

Configure mail in the ignored `services/api/.env` for your environment. The
following example uses Gmail; replace the sender and credential placeholders:

```dotenv
EMAIL_ENABLED=true
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-sender@gmail.com
SMTP_PASSWORD=your-google-app-password
FROM_EMAIL=your-sender@gmail.com
FRONTEND_URL=http://localhost:5173
```

Use a Google app password for the sender account. Google requires 2-Step
Verification to create app passwords; see
[Google's app password instructions](https://support.google.com/accounts/answer/185833).
Keep the actual password in the ignored `.env` file, then restart the API so it
loads the updated settings.

`FROM_EMAIL` must contain the actual address, not the literal text `SMTP_USER`.
The company sender is independent of the inviter: recipients see TripRaft as the
sender, while the subject and message identify the person inviting them and their
group. The inviter does not need to supply email credentials.

`FRONTEND_URL` is the address included in invitation emails. The localhost value
works on the development computer. Set it to the reachable website URL when
inviting people on other devices.

Saving an invitation and sending its email are separate operations. The API
reports `disabled`, `queued`, `sent`, or `failed` in `data.email_status`.
`sent` means the SMTP server accepted it; it does not prove inbox delivery.
Without a task broker, expense mail uses a bounded background SMTP worker.
`queued` means accepted by that local worker. Check API logs for later delivery
failures, then use **Resend email** if needed. This queue is best effort and does
not survive an API restart; use a configured broker and running worker for
durable task delivery. A full/unavailable local queue reports `failed`.
The expense group screen offers **Copy invite link** for pending invitations.
The inviter and group admins can also choose **Resend email** to retry delivery
of an unexpired pending invitation after correcting SMTP settings. This keeps
the same link and expiry and reports the new delivery result. It does not send
old invitations automatically when the application restarts.
Submitting the same address again in the web form retries its pending invitation
instead of attempting another creation. Failed and disabled delivery are shown
explicitly, with retry/copy guidance. Saving an invitation does not prove that
an email was delivered.

**Cancel invitation** disables joining through its link and removes the pending
entry. Mail already sent cannot be recalled. Queued workers check for
cancellation before starting SMTP; old jobs also stay obsolete if the same
person is invited again. To invite a cancelled/declined/expired recipient again,
submit their address in **Invite Member**. This issues a new pending generation
using the same invitation row/link and resets its expiry. **Resend email** on an
existing pending invitation keeps its original expiry. Cancelled or declined
links display an unavailable message and clear saved login continuation.
It does not display a persistent delivery banner or raw URL box. If the clipboard
is unavailable, requesting a copy shows the link in an alert.

Expense invitation links use `/invitation/{id}`. The recipient must sign in with
the invited email address before accepting. A signed-out visitor goes directly
to sign-in, and the same invitation resumes after login or signup. Private details
are not fetched before authentication.
After joining, recipients open `/expenses/{userId}/group?groupId={groupId}` for
the exact joined group. Opening an already accepted invitation opens that same
group again.

Signup also sends an account verification email. Its `/verify-email/{token}`
link opens a public page that confirms ownership through
`GET /api/v1/auth/verify-email?token=...`; signing in is not required to use it.
Verification links expire after 24 hours. Invalid/expired links offer sign-in
and an explicit resend action for the signed-in account. Network failures offer
retry, and already verified links display success. A signed-in account's profile
is refreshed after verification; pending group invitations remain available
through the continue action. The current application records verification but
does not require it for login or group membership.
