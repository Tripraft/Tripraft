# Staff review access and private package drafts

Implemented 19 October 2026. This continues the [tour-package roadmap](../plans/places-search-tour-packages/README.md) with a separate staff sign-in and the first phase-two draft-authoring release.

## Where applications are reviewed

Open the staff console at `http://127.0.0.1:5174`, sign in with an authorized employee account, and choose **Partner applications → under review**. The review queue is served by `/api/v1/admin/partners`. Customer and supplier identities cannot authorize themselves through a request field or the UI. Neither the traveler website nor the agent portal contains an admin link.

The staff app now has its own sign-in form and sign-out control. `/api/v1/admin/session` issues httpOnly credentials only after checking the employee allowlist, verified email, active account, non-supplier identity and password. The page verifies the resulting identity again before loading privileged operations. Administrator authorization also rechecks the current verified, active database identity on every protected request rather than relying on a token email claim. Existing customer sessions see a denial and a staff sign-in form; anonymous visitors see staff sign-in without review records or operations navigation. Admin APIs independently enforce server authorization. The staff HTML also requests no indexing; authorization is the access control.

At the user's explicit request, the local demo supplier identity was converted into the intended employee identity. Its supplier membership was deactivated and its old sessions revoked. Its submitted business application was preserved. The employee allowlist remains in ignored API configuration, and no password was changed or copied into source. Consistent SQLite and configuration backups were saved under ignored `.tripraft/backups/` before the change.

Staff may view their own preserved application, but self-review remains forbidden. The queue labels an own application and hides its decision controls; the API also rejects self-approval. Another authorized employee is required to approve that application. New actual supplier accounts use a separate identity and the partner portal.

## Package workspace

Approved, verified supplier owners can open `/partners/dashboard` to create, list, duplicate and edit private package drafts. `/partners/packages/:packageId` provides seven preparation steps:

1. Basics: title, summary, duration, language and supplier reference.
2. Route: ordered starting/intermediate/finishing locations without requiring a place-catalog match.
3. Itinerary: numbered days, descriptions, meals and accommodation. Adding missing days preserves existing writing.
4. Services: inclusions, exclusions, transport and accessibility information.
5. Media and policies: cancellation/safety text; a truthful placeholder for the pending photo-upload workflow.
6. Departures and rates: optional private date/time-zone/rate proposals and conditions.
7. Private preview: entered content, saved preparation notes and submission status.

Save draft, Save and continue, and Save and return persist incomplete content. Expected versions reject stale writes instead of overwriting another edit. A failed save preserves the unsaved text and offers an explicit reload. Closing a tab with unsaved edits triggers the normal browser protection. Draft list pagination is bounded, and copies receive independent IDs and content. The list omits private departure/rate bodies.

The rate form accepts decimal amounts and serializes exact minor-unit strings without floating-point arithmetic. Rates are private proposals. They do not set customer prices, taxes, guaranteed inventory, quotes or bookable departures. Currency and its decimal precision remain explicit; no operating country or currency is inferred.

## Backend and data

| File/area | Change |
| --- | --- |
| `apps/admin/src/StaffLogin.tsx`, `App.tsx`, `PartnerReviewPanel.tsx` | Dedicated staff session UX, restricted operations and self-review notice |
| `services/api/app/partners/staff_routes.py` | Allowlisted employee sign-in; supplier credentials excluded |
| `apps/web/src/features/partners/PackageWorkspace.tsx`, `rateAmounts.ts` | Draft list, seven-step editor, private preview and exact amount conversion |
| `services/api/app/partners/package_models.py` | Supplier-owned `tour_packages` roots and `tour_package_revisions` |
| `services/api/app/partners/package_schemas.py` | Bounded draft input, private response schemas and exact proposal validation |
| `services/api/app/partners/package_services.py`, `package_routes.py` | Ownership, approval, version checks and private draft operations |
| `packages/types/src/tourDrafts.ts` | Shared draft/list/content types |
| `services/api/migrations/versions/b29c3d4e5f60_tour_drafts.py` | Incremental two-table migration after partner onboarding |
| OpenAPI exporter/spec/generated declarations | Explicit staff and package request/response contracts with resolved nested references |

New endpoints are `GET/POST /api/v1/partners/packages`, `GET/PATCH /api/v1/partners/packages/{package_id}`, and `POST /api/v1/partners/packages/{package_id}/duplicate`. They require a live partner session, active membership, approved business and verified owner. Mutations require partner CSRF. Cross-supplier IDs return no record. Input cannot assign owner, agent, publication status or unchecked media URLs.

Draft saves modify only the current draft revision and increment the aggregate version. The service refuses to change a non-draft revision. Immutable submitted revisions and moderation transitions are the next delivery; this checkpoint does not claim submitted package history or public publication.

The native development migration ran after its migration checks and created a pre-upgrade SQLite backup. Existing users and the submitted business application remain present. The place catalogs and their readers were not rewritten.

## Validation

Verification results:

- Full backend suite: 437 passed, including the new migration preservation test. After the final verified-employee authorization change, 62 focused staff/onboarding/auth/session/CSRF/endpoint tests passed. A final three-test staff run also verified immediate role loss for a previously issued token when email verification is revoked.
- Full web suite: 43 suites / 385 tests passed.
- Admin suite: 2 suites / 7 tests passed.
- Launcher: 14 tests passed.
- Workspace lint, type/syntax checks, production builds, structure and static infrastructure validation passed.
- The running database is at `b29c3d4e5f60`, retains the submitted application, and reports no foreign-key violations. The employee identity satisfies the configured staff checks.
- Local web/admin/API services remain healthy. Anonymous admin-review and package-draft API requests return 401 without records; staff, partner and existing Places pages return HTTP 200.

 Coverage includes fresh/upgraded/downgraded schema parity and preserving existing supplier applications; dedicated employee authentication; converted-demo isolation and self-review denial; unapproved/suspended supplier denial; cross-supplier access; exact rates; duplicate independence; stale edits; private preview; and unchanged traveler/planner/expense behavior. Test identity/SMTP activity is isolated from the user's real accounts and does not send mail.

The local web/admin/API services are checked separately from test fixtures. Browser visual QA and real PostgreSQL concurrency validation remain deployment gates; automated DOM interaction and schema/build checks are not described as a production rollout.

## Next work and release boundary

Connect private media staging, type/size/rights/security checks and reviewer access. Then implement immutable package submission, human first-package review, requested corrections and approval history. Only approved content should subsequently feed the public projection, cards and `/tours/:slug` inside Places Search. The submission button is deliberately unavailable until that workflow exists; there is no hidden publishing endpoint to bypass it.

Account recovery, supplier staff-role administration, agreement/evidence policy, deployed country/trending comparison and live PostgreSQL checks remain open. Country/entity/bank decisions, consumer price visibility and all booking/payment/tax/payout releases remain separate gates. No public package release or payment functionality was enabled.
