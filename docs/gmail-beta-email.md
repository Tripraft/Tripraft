# Gmail HTTPS email for the beta

Use this option to keep your existing Gmail sender when hosting on Render Free.
Gmail SMTP with an app password remains available locally. Render Free blocks
outbound SMTP ports 25, 465 and 587, so the hosted beta uses Gmail's HTTPS API.
No Resend account or custom sender domain is required for this Gmail option.

## What you need

Your sender Gmail account and a Google Cloud project owned by you. The project
must have Gmail API enabled and an OAuth client configured for your sender.
The app needs an offline OAuth refresh token with only this sending scope:

```text
https://www.googleapis.com/auth/gmail.send
```

An ordinary Google API key, Gmail password, Gmail app password or service-account
JSON file does not replace this OAuth grant. The grant allows the application to
send messages from the authorized mailbox. Testers do not authorize their own
Gmail accounts; only the chosen sender account does.

## Obtain the sender grant yourself

1. Open [Google Cloud Console](https://console.cloud.google.com/), create a project
   for the beta, and enable Gmail API under APIs and Services.
2. Configure Google Auth Platform branding, audience and OAuth consent for your
   project. For initial External Testing, add your sender Gmail as a test user.
3. Create an OAuth client of type Web application. For this manual setup, add
   `https://developers.google.com/oauthplayground` as an authorized redirect URI.
4. Open the official [OAuth Playground](https://developers.google.com/oauthplayground/).
   In its settings enable Use your own OAuth credentials and enter this client's
   ID and secret. Request offline access. Authorize the `gmail.send` scope above
   while signed in as the sender Gmail account.
5. Exchange the authorization code for tokens. Keep the refresh token privately;
   do not paste it into chat, commit it, or use Playground's default OAuth client.
   The Playground page explains that default-client refresh tokens are revoked
   automatically; using your own client is required for this setup.
6. Enter these values in Render service Environment, or use the local terminal
   wizard to import them privately:

```dotenv
EMAIL_PROVIDER=gmail
EMAIL_ENABLED=true
GMAIL_CLIENT_ID=<YOUR_OAUTH_CLIENT_ID>
GMAIL_CLIENT_SECRET=<YOUR_OAUTH_CLIENT_SECRET>
GMAIL_REFRESH_TOKEN=<YOUR_OFFLINE_REFRESH_TOKEN>
FROM_EMAIL=<THE_SAME_AUTHORIZED_SENDER>@gmail.com
```

Restart/redeploy after configuration. The code exchanges the refresh token for
an access token and submits base64url MIME messages to Gmail over HTTPS. It never
uses SMTP on this path or logs provider response bodies or OAuth credentials.

## Token lifetime and delivery verification

Google documents a seven-day refresh-token lifetime for External OAuth apps in
Testing when scopes beyond basic identity are used. The Gmail sending scope is
one of those scopes. Initial testing therefore needs reauthorization when the
grant expires. Before depending on unattended email, move the OAuth app to an
appropriate publishing status and follow Google's verification requirements;
production status is not a guarantee that refresh tokens can never expire.
Reauthorize and replace the refresh token if Google revokes it.

Check signup verification, password reset and both invitation emails using your
beta environment. Check Spam and sender account limits. A successful API response
means Gmail accepted the message; it does not prove mailbox delivery. No email was
sent during the local setup work.

## References

- [Gmail message creation and sending](https://developers.google.com/workspace/gmail/api/guides/sending)
- [Google OAuth refresh token expiration](https://developers.google.com/identity/protocols/oauth2#expiration)
- [Official OAuth Playground](https://developers.google.com/oauthplayground/)
- [Render Free outbound SMTP restrictions](https://render.com/docs/free)
