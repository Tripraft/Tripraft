# Staff console and supplier review

For native development, open http://127.0.0.1:5174 and use **Staff sign in**. The separate console is not linked from the traveler or supplier navigation. Server authorization protects every staff API.

## Configure staff access

Use an active, verified platform identity permitted by `ADMIN_EMAILS` in ignored `services/api/.env`:

```dotenv
ADMIN_EMAILS=employee@example.com
```

Supplier identities are excluded. There is no staff self-registration. After changing configuration, run `python start.py --stop`, then `python start.py` from the repository root. A repeated normal start reuses healthy processes and does not reload their environment.

## Review business applications

Choose **Partner applications**, select an application under review and inspect its business details. Approve, request corrections or reject it with an applicant-visible reason. Version checks reject stale decisions. Employees cannot review their own business application; another authorized employee must decide it.

Agents see their own status and feedback at `/partners/status`. Approval does not publish tours or enable payments. An approved, verified supplier must sign the current agreement before opening the private dashboard. See [agreement access and evidence](partner-agreement.md).

## Review private packages

Signed, approved suppliers author private drafts, upload validated images with rights metadata and submit a complete revision. Submission locks that revision. Staff review its content and images, then approve, request corrections or reject it with a reason. Corrections create an editable draft; previous submitted content and decisions remain preserved. Staff cannot review their own supplier package.

Approval sets an approved revision pointer; it does not expose public tour listings, set retail prices or enable booking. See [the API contracts](../api/README.md#private-package-images-and-content-review) for current routes.

## Connection recovery

During a native API reload the console may receive HTTP 503. Use **Retry connection** or refresh after the API recovers. Approvals, credentials and signatures are not automatically replayed. Setup instructions and logs are documented in [startup](../setup/startup.md).

Local demo accounts, passwords and staff allowlists are environment-specific. Do not assume accounts described in historical reports exist in a fresh checkout.
