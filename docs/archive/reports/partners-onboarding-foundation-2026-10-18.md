# Partner onboarding foundation and native startup

> Historical report. Results, local accounts, file counts and open findings describe the original checkpoint. For current setup and contracts, use the [documentation index](../../README.md). Raw CSV/JSON/ZIP exports referenced here are preserved locally and in earlier Git history; they are not current repository inputs.

Implemented 18 October 2026 from the active [Places Search tour-package plan](../../plans/places-search-tour-packages/README.md). This is the first phase-one vertical slice. The full publishing, discovery and commercial roadmap remains open.

## Available behavior

The shared footer's Company list now links **Partner with TripRaft** to `/partners`. The landing explains the workflow and opens real partner registration and sign-in forms. An applicant can save a business profile, verify their account email with the existing verification service, attest to their information and submit it for review. They see review feedback, can correct a changes-requested application, and can refresh their status.

The existing admin application includes a paginated business review queue behind its administrator identity check. Administrators approve, request changes, reject, suspend, or reinstate through the permitted state transitions. Every decision requires an applicant-visible reason and expected application version. Review history stores the previous profile snapshot, reviewer and time. Submitted and approved profiles stay locked against applicant edits.

Business approval opens a dashboard shell which explicitly says package submission is not available yet. No package wizard, public tour cards, rates, checkout or payouts are claimed by this checkpoint.

## Implementation placement

| Location | Responsibility |
| --- | --- |
| `apps/web/src/components/layout/jsx/Footer.jsx` | Company entry beside About Us and Contact |
| `apps/web/src/features/partners/PartnerPortal.tsx` | Landing, registration/login, onboarding, status and approved shell |
| `apps/web/src/features/partners/partnerApi.ts` | Dedicated partner cookies/CSRF, single shared read refresh, no mutation replay |
| `apps/web/src/features/partners/partners.css` | Isolated responsive portal styles and focus states |
| `apps/admin/src/PartnerReviewPanel.tsx` | Admin queue, status filters, pagination and review controls |
| `services/api/app/partners/` | Input schemas, business/session services, route guards, application and review models |
| `services/api/app/auth/` | Partner identity classification and distinct token builders; traveler login/refresh boundary |
| `services/api/app/core/security.py` | Independent partner double-submit CSRF cookies |
| `services/api/migrations/versions/a18b2c3d4e5f_partner_onboarding.py` | Add identity classification and three onboarding tables |
| `packages/types/src/partners.ts` | Shared private onboarding/review contracts |
| `infra/tools/export_openapi.py`, `services/api/openapi.json`, `packages/api-client/src/generated/schema.d.ts` | Explicit new input/output contracts and generated declarations |
| `start.py`, `services/api/run.py` | Native startup, backups, repeated-start reuse, frontend HMR and API reload |

The business profile and its versioned application currently share `agents`; `agent_users` records owner membership and `agent_reviews` retains submitted snapshots at decisions. Additional staff invitation/role administration is a follow-up. Do not assume the future package/revision tables from the architecture document already exist.

## Access and data boundary

Existing accounts migrate with `portal_kind=traveler`. New partner registrations create supplier-only users with `partner_access` and `partner_refresh` JWT types, separate httpOnly cookies and a readable partner CSRF cookie. Access checks validate the stored user, live session, expiry and active business membership on each request. Refresh rotates stored token digests; logout revokes the stored session so its access token stops working immediately.

General sign-in and refresh do not issue traveler credentials to partner-only users. Protected traveler HTTP routes and private Socket.IO connections reject partner accounts, including an accidentally issued generic access token. Business IDs, roles, approval states and ownership cannot be supplied through profile input. The applicant APIs address only the authenticated owner's application. Optimistic ORM versions prevent stale writes and decisions. These profiles and responses are never cached or saved into browser local storage by the partner adapter.

Bank accounts, identity evidence, private rates and customer records are not collected in this slice. Registration reuses the configured verification email service; tests stub delivery and do not send email. Production contact delivery still depends on actual SMTP configuration.

## API surface

| Method/path under `/api/v1` | Purpose |
| --- | --- |
| `POST /partners/register`, `POST /partners/login` | Supplier-only account/session |
| `GET /partners/me` | Own profile, application and current capabilities |
| `POST /partners/refresh`, `POST /partners/logout` | Rotation and revocation |
| `POST /partners/resend-verification` | Re-send the account verification link |
| `PATCH /partners/me/application` | Full editable draft field set with expected version |
| `POST /partners/me/application/submit` | Verified account, complete profile and explicit information attestation |
| `GET /admin/partners` | Bounded status-filtered review queue |
| `POST /admin/partners/{agent_id}/decision` | Reasoned, versioned administrator decision |

Generic `/auth/verify-email` verifies contact without issuing traveler credentials. Public package projections and price-visibility responses remain phase-three work. Existing country/state/place search readers and source data are preserved.

## Native launcher correction

The launcher previously replaced development-port listeners on every start and reported a generic error when any child exited. Overlapping starts or a smoke check could therefore terminate a live session. Logs from the reported shutdown contained no API crash traceback; a continuous run remained healthy.

Repeated native starts now verify ownership and all three HTTP services, reuse a healthy session and open its site. A smoke check also preserves an already healthy session. Failed children report their service name, exit code and exact log path. New launches wait through a short stability check after HTTP readiness. Windows process creation checks and owned process-tree cleanup remain in place.

Native startup selects the same database URL as Flask and creates a consistent SQLite backup before pending migrations. It supports the normal Windows Node installation even when `.py` association PATH is stale. Setup fingerprints include workspace manifests. Vite serves web/admin with HMR; native Python source changes use the API development reloader. Run `python start.py --stop` followed by `python start.py` after changing environment or migrations. See [startup instructions](../../setup/startup.md).

An earlier, uncommitted draft migration had already been applied to the local development database. All three partner tables were verified empty, a backup was saved under ignored `.tripraft/backups/`, and only that empty onboarding schema was rebuilt. Existing traveler data and source catalogs were retained. Later applicant activity is not reset.

## Verification

- Full API suite: 417 passed. Follow-up onboarding/migration tests: 21 passed. Final onboarding/private realtime regressions: 29 passed, covering partner and accidental generic-token rejection on private sockets as well as existing planner/expense live events.
- Full web suite: 41 suites / 366 tests passed. The final partner-specific suite has 11 passing tests after adding concurrent refresh coverage.
- Admin: 2 suites / 5 tests passed.
- Launcher: 14 tests passed, including repeated-start reuse, smoke reuse, process identity, startup cleanup and named failure reporting.
- Workspace lint, TypeScript/Python syntax checks, production builds, structure and static infrastructure validation pass.
- SQLite fresh install, upgrade preserving existing users, downgrade/reinstall, metadata parity and offline SQLite/PostgreSQL migration SQL were checked. A live PostgreSQL server/concurrency run is still required before production approval.
- Native API/web/admin startup passed a fresh smoke run. A continuous normal run and a second normal start stayed healthy. `/`, `/partners`, `/partners/register`, `/places`, `/place-search` returned HTTP 200.
- A real Vite WebSocket received a partner CSS update event; a Python source timestamp change caused a new API startup followed by HTTP 200 health.
- The available browser automation inventory was empty; no visual browser QA is claimed. DOM interaction tests and production builds cover the new screens, and the normal launcher opens the user's browser.

## Remaining phase-zero/one work and next delivery

Match the checked-out Places Search to the deployed country/trending rails; no deployed reference was supplied. Confirm launch visibility and the supplier reviewer/terms policy. Entity, receiving-bank and pilot supplier countries remain undecided.

Before opening supplier applications publicly, finish account recovery, staff invitations/role administration, country-specific review evidence/terms, production contact-delivery checks, real PostgreSQL migration/concurrency validation and responsive visual review. No production launch has been authorized or performed.

Next, implement the approved-agent package wizard and immutable submitted revision review. Only approved package content should then feed separate cards and details within the existing Places Search. Pricing, tax, payment and payout gates remain later work.
