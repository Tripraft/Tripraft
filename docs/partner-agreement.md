# Agent agreement, signature and demo access

Current flow: **application ? TripRaft staff approval ? agent agreement/signature ? private package dashboard**. Agents can submit their application before signing. Every approved agent, including the demo, must personally sign the current document before using package APIs. **There is no TripRaft signing step.**

## Agent and staff pages

Agents sign in at `/partners/login`. Approved unsigned accounts are directed to `/partners/agreement`; opening `/partners/dashboard` directly leads to the same signature step. Unapproved agents see their application status. Staff review business applications in the separate console and can read the agreement and inspect agent signature evidence; they cannot sign for an agent.

The reader preserves every supplied main-body paragraph/table, Master Terms ??1?24, Schedules A?F, both non-contractual appendices and original header/footer wording. Download returns the unchanged DOCX. The template includes signature fields for both parties, but the implemented onboarding flow collects **only the agent signature**, as the user requested.

The source is v3.0 dated 18 October 2026 and explicitly marked **DRAFT**. Entity, jurisdiction and commercial elections remain incomplete. The signature records agent-side acceptance of this exact supplied draft and opens private preparation. It does not finalize missing terms or enable public listings, checkout, payments or payouts. Its status is `AGENT_SIGNED_DRAFT`, not a completed commercial contract.

## Signature evidence and access

The verified partner owner must confirm all eight Schedule F declarations, authority to represent the business, electronic-signature consent and the draft limitation, then enter their full legal name and title/position. No boxes or signature fields are prefilled. The server validates approval, active supplier ownership, current application/document version, original source hash, all required confirmations and partner CSRF.

`agent_agreement_signatures` preserves account/business identity, verified email, typed signature/title, document version/hash/status, declaration and consent wording, all eight confirmation texts, timestamp and connection evidence. A SHA-256 covers the canonical evidence JSON. Repeating an identical submission returns the original signature; attempting to overwrite it fails. There are no signature-edit/delete or TripRaft-sign endpoints.

Agents can download their private JSON signature receipt. Staff can retrieve the business receipt through an authenticated staff-only route. These records and source downloads are never public or cached. The receipt is an authenticated typed-signature record and integrity hash; it is not a provider-issued signing certificate or a signed PDF.

Every package list/create/read/save/copy operation rechecks approval, verified ownership and a signature matching the **current** source version/hash. A changed agreement requires a new explicit signature. Suspension still blocks package access. Prior reading acknowledgments remain separate historical evidence and never become signatures. The old acknowledgment endpoint remains compatible after approval but does not unlock the dashboard.

## Demo and staff login

- Agent demo: `demo.operator@example.com` at `http://127.0.0.1:5173/partners/login`. Its generated password is in ignored `.tripraft/demo-partner-access.json`.
- Staff: `tripraft@gmail.com` at `http://127.0.0.1:5174`, using its existing password. It is intentionally excluded from partner sign-in and has no active supplier membership.

The previously staff-owned demo was transferred to the separate reserved supplier identity and approved locally at the user's request. Transfer, simulated local email verification and approval are audited. Demo setup does not sign or acknowledge an agreement. Any subsequently submitted agent signature belongs to the actual user's signing action and must be preserved.

The demo is labeled throughout the portal and staff review. A fictional three-day private package draft exercises the editor. It is not a public/bookable tour. Generated credentials, live signatures/drafts, SQLite data, backups and tokens remain local and ignored; source and documentation are saved in Smartlog.

## Source and commercial release

Original source and ordered JSON projection: `services/api/app/partners/agreements/partner-agreement-v3-2026-10-18.{docx,json}`. Source SHA-256:

`ddaf7462465856ac7973d39791e8bbfd622cc98f87fe3f65699ba9bffb1e7108`

The importer reproduces this version without filling blanks. Preserve previous source files and acceptance evidence when introducing a reviewed replacement. The current agent-only workflow does not silently rewrite the original template.

Before commercial launch, finalize entity/country, legal seller, reviewed commercial/tax/payment terms, bank/compliance verification and package/rate-plan scope. Implement the approved final contract/document retention and activation checks at publication/booking boundaries. Do not infer a commission, GST rule, payout deadline or signing certificate from illustrative source examples.

After agent signing, the next work is private package media validation, immutable submission and staff content moderation, then the approved public projection inside Places Search. Initially **every new package requires review**, not only the operator's first package. Later safe edits can publish automatically under the approved policy; material itinerary, hotel/inclusion, cancellation and commercial changes require review. No draft or pending revision should overwrite the public approved version.
