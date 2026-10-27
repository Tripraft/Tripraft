# API contracts

Flask API URLs remain `/api/v1/*`; health probes remain `/api/health/live` and
`/api/health/ready`. Domain source directories do not add or change URL prefixes.
The OpenAPI route inventory is `services/api/openapi.json`; generated TypeScript
declarations are `packages/api-client/src/generated/schema.d.ts`.

Regenerate after route changes:

```sh
python infra/tools/export_openapi.py
pnpm api:generate
```

The exporter applies Alembic migrations to a disposable database under ignored
`extra/build/schema-export` and never uses personal application data. Paths and
methods come from the registered Flask routes. Explicit response contracts cover
authenticated account identity, service health, and admin ingestion audit data.
Other response payloads are deliberately `unknown`, not invented schemas. This
is a usable typed admin client and route inventory; full request/response schema
coverage remains future work.

Most application responses wrap payloads in `{ success, data, message?, meta? }`.
Health probes return plain JSON. Account identity returns `data.user`; admin audit
returns `data.total` and `data.logs`. A 503 readiness response reports degraded
database status. UUID identifiers remain strings.

`createApiClient(baseUrl)` from `@tripraft/api-client` sends `credentials: include`.
For admin, `baseUrl` is the API origin (or empty for the local proxy); generated
paths already include `/api`. The existing web client’s configured base includes
`/api`, as documented in `apps/web/.env.example`.
For mutations it echoes `csrf_token` into `X-CSRF-Token`. Existing web services use
their tested cookie-authenticated client; money and chat POST requests are not
automatically retried. The console's admin flag is only a UI gate; backend admin
decorators remain the security boundary.

Web login and signup use ordinary submit buttons and native form submission
(including Enter and password-manager autofill). Signup validates the server's
password requirements before sending the request. Existing-account login does
not apply signup password rules.

Browser sessions are remembered on that browser/device by persistent httpOnly
cookies, including after reopening the site. Startup checks the cookies even
when there is no cached local profile, and renews an expired access token.
The refresh session defaults to 30 days and renews on successful refresh;
explicit logout clears only the current device's session. The web app does
not automatically log out after 15 minutes of inactivity. Expired, revoked,
or otherwise rejected sessions still require login. Temporary network/server
failures preserve the saved profile while API authorization remains enforced
by the backend.

The web API base defaults to `/api` on the current origin, so opening the
site on another device does not send login requests to that device's localhost.
Vite proxies `/api` and `/socket.io` to the local backend. A separately hosted
API can still be selected with `VITE_API_BASE_URL`.

Supplier onboarding uses separate `/api/v1/partners/*` endpoints, partner-only
JWT types and `partner_*` cookies. Its mutations echo `partner_csrf_token` in
`X-CSRF-Token`; general admin review uses the normal administrator cookie/CSRF
contract. See the [partner API and implementation report](../archive/reports/partners-onboarding-foundation-2026-10-18.md).

The separate staff console signs in through `POST /api/v1/admin/session`, which
rejects customer and supplier credentials before issuing an employee session.
Approved verified suppliers can create/read/save/copy private drafts through
`/api/v1/partners/packages`. These endpoints do not publish tours or configure
customer prices. See the [staff and draft contracts](../archive/reports/staff-console-package-drafts-2026-10-19.md).

## Saved friends for expense invitations

`/api/v1/expenses/friends` saves private reusable recipients and searches their
names, nicknames or email addresses. See [the saved-friends contract](expense-friends.md).

## Partner agreement and post-approval agent signature

Applications submit before agreement signing. `GET /api/v1/partners/agreement` and `/agreement/download` provide the complete supplied draft and exact original Word file after staff approval/email verification. Staff equivalents remain `/api/v1/admin/partners/agreement` and `/agreement/download`. All are private and never cached.

`POST /api/v1/partners/me/agreement/sign` accepts current application version, document version/SHA-256, signer name/title, strict true authority/e-sign/draft confirmations and all eight Schedule F confirmation IDs. It requires the active verified supplier owner and APPROVED business, with partner CSRF. It stores agent-only evidence and an integrity hash, returning the current partner snapshot. An identical retry returns the original signature; overwrite/stale/false/missing consent is rejected. There is no TripRaft signing endpoint.

`GET /api/v1/partners/me/agreement/signature` returns the own-business signing receipt; `/signature/download` returns the raw receipt JSON as an attachment. Staff may read `/api/v1/admin/partners/{agent_id}/agreement/signature`. Receipt payloads contain private account, business, consent and connection evidence and must never be projected into public package payloads.

Snapshot/review agreement status includes `agent_signed`, `signature_required`, signature ID/time/name/title and `execution_status` (`NOT_EXECUTED` or `AGENT_SIGNED_DRAFT`). `commercial_activation_allowed` remains false for this unfinished draft. Every package list/create/read/save/copy operation rejects an approved but unsigned agent. A new source version/hash requires a new explicit signature. Suspension and verification revocation still deny access.

The historical `/me/agreement/acknowledge` endpoint is retained after approval for compatibility and cannot unlock package access. Existing acknowledgment records are not signatures, and no migration fabricates acceptance. See [agreement operations](../guides/partner-agreement.md).

## Private package images and content review

`POST /api/v1/partners/packages/{id}/media` accepts one multipart image with version, caption, rights source and `rights_attestation=true`. It requires the signed approved owner and an editable draft, validates bytes and bounds, strips metadata and returns the updated package/version. Supplier/staff image GETs are authenticated and never cached; no private storage path is exposed.

`POST /api/v1/partners/packages/{id}/submit` takes the current version and strict `information_attestation: true`. Complete content plus owned uploaded images becomes an immutable submitted revision. Repeated/stale or incomplete submissions fail. Editing is locked during review.

Staff use `GET /api/v1/admin/partner-packages` with bounded status/limit/offset and `POST /api/v1/admin/partner-packages/{id}/decision` with expected package version, submitted revision, reason and APPROVED/CHANGES_REQUESTED/REJECTED. Staff cannot self-review their supplier package. Corrections create a new draft revision; approval sets the approved revision pointer. These endpoints do not publish public cards or configure retail prices.
