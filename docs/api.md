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
contract. See the [partner API and implementation report](reports/partners-onboarding-foundation-2026-10-18.md).

The separate staff console signs in through `POST /api/v1/admin/session`, which
rejects customer and supplier credentials before issuing an employee session.
Approved verified suppliers can create/read/save/copy private drafts through
`/api/v1/partners/packages`. These endpoints do not publish tours or configure
customer prices. See the [staff and draft contracts](reports/staff-console-package-drafts-2026-10-19.md).

## Partner agreement draft

`GET /api/v1/partners/agreement` returns the complete versioned draft with ordered paragraph/heading/bullet/table blocks, original header/footer text, source SHA-256 and the exact reading-acknowledgment wording. `GET /api/v1/partners/agreement/download` returns the original DOCX attachment. Both require a live supplier session. Staff equivalents are `GET /api/v1/admin/partners/agreement` and `/agreement/download`, requiring a verified, allowlisted employee account. All responses use `Cache-Control: no-store`.

`POST /api/v1/partners/me/agreement/acknowledge` accepts `{version, document_version, source_sha256, acknowledged: true}` with partner CSRF. It requires the verified owner, current application version and current document identity. It appends one reading acknowledgment per owner/source and returns the partner snapshot. False, numeric/string consent, privilege fields, stale versions/hashes and closed/suspended applications are rejected. It does not collect signatures. New application submissions require current acknowledgment; existing applications are not automatically acknowledged.

Partner snapshots and staff review rows include the agreement version/hash, acknowledgment actor/time, `execution_status: NOT_EXECUTED` and `commercial_activation_allowed: false`. Application responses include `is_demo`; only the explicitly configured local sample is marked demo. Final contract execution, publication, checkout and payments have no new endpoints in this change. See [agreement operations](partner-agreement.md).
