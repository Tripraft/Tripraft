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

`FRONTEND_URL` is the address included in invitation emails. The localhost value
works on the development computer. Set it to the reachable website URL when
inviting people on other devices.

Saving an invitation and sending its email are separate operations. The API
reports `disabled`, `queued`, `sent`, or `failed` in `data.email_status`.
`sent` means the SMTP server accepted it; it does not prove inbox delivery.
The expense group screen displays this result and keeps a selectable link.
Existing pending invitations also have a **Copy invite link** action.

Expense invitation links use `/invitation/{id}`. The recipient must sign in with
the invited email address before accepting.
