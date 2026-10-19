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

Employees cannot review their own business application. The record remains
visible with a notice, and another authorized employee must review it. This
restriction applies to the preserved demo application as well.

Agents use `/partners/status` for their own application and feedback. Approved,
verified agents use `/partners/dashboard` for private package drafts. Staff review
does not itself publish tours or enable customer pricing, inventory or payments.

See the [implementation report](reports/staff-console-package-drafts-2026-10-19.md)
for delivered code, validation and the next package-media/review work.
