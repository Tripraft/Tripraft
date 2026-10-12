# Invitation email setup

The active local API settings are in `services/api/.env`. Gmail's SMTP hostname
and port are already supplied, but the sender and credentials must be configured:

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
The expense group screen offers **Copy invite link** for pending invitations.
The inviter and group admins can also choose **Resend email** to retry delivery
of an unexpired pending invitation after correcting SMTP settings. This keeps
the same link and expiry and reports the new delivery result. It does not send
old invitations automatically when the application restarts.
It does not display a persistent delivery banner or raw URL box. If the clipboard
is unavailable, requesting a copy shows the link in an alert.

Expense invitation links use `/invitation/{id}`. The recipient must sign in with
the invited email address before accepting. A signed-out visitor goes directly
to sign-in, and the same invitation resumes after login or signup. Private details
are not fetched before authentication.
After joining, recipients open `/expenses/{userId}/group?groupId={groupId}` for
the exact joined group. Opening an already accepted invitation opens that same
group again.
