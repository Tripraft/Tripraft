# Staff application review

For local development, open **http://127.0.0.1:5174** and use **Staff sign in**.
After signing in, choose **Partner applications**, keep the status filter on
**under review**, and open the submitted business details. Enter an applicant-visible
reason before approving, requesting corrections or rejecting an application.

Only active, email-verified platform accounts explicitly enabled by the server's
`ADMIN_EMAILS` setting can access operations. Supplier identities are excluded.
The staff console has no public registration and is not linked from the traveler
or agent websites. Knowing its address does not authorize its protected APIs.

Employee access is configured in ignored `services/api/.env`, for example:

```dotenv
ADMIN_EMAILS=employee@example.com
```

The address must belong to the intended, verified employee identity. Do not add
customer or supplier addresses to grant staff access. Configuration changes require
an API restart: run `python start.py --stop`, then `python start.py`. Normal repeated
starts reuse a healthy existing session and do not reload environment settings.

A user's explicit demo-to-employee conversion is separate from ordinary role
assignment: preserve its application, retire supplier membership, revoke old
sessions and require fresh staff sign-in. The local demo conversion performed in
this checkpoint followed that procedure and retained the existing password.

Employees cannot review their own business application. Such records remain
visible with a notice, and another authorized employee must review them. The local
demo now has a separate supplier owner, as described below; self-review remains blocked.

Agents use `/partners/status` for their own application and feedback. Approved,
verified agents sign the agreement after approval, then use `/partners/dashboard` for private package drafts. Staff review
does not itself publish tours or enable customer pricing, inventory or payments.

See the [implementation report](reports/staff-console-package-drafts-2026-10-19.md)
for delivered code, validation and the next package-media/review work.

## Partner agreement and demo

Partner applications include a complete draft-agreement reader, protected Word download and the agent signature status/receipt. Approve the business first, then the agent signs before private package access. There is no TripRaft signing action. Historical reading acknowledgments are not signatures. The current source is a draft and commercial activation remains unavailable.

The previously staff-owned demo application was transferred to `demo.operator@example.com` and approved locally at the user's request. `tripraft@gmail.com` retains staff access; its supplier membership stays inactive. Local demo login details are in ignored `.tripraft/demo-partner-access.json`. The normal staff HTTP API still rejects self-review. See [agreement and demo access](partner-agreement.md).

If the local API reloads, a temporary-unavailability response is 503 rather than an opaque proxy 500. Use **Retry connection** or **Refresh applications** once it recovers. Approvals, credentials and signatures are not automatically replayed.
