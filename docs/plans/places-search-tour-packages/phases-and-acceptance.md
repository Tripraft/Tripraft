# Tour package delivery phases and acceptance

This plan implements the updated document's tour-package vertical and Appendix B's selective publication policy. It does not reopen the retired broad workspace/catalog implementation program. Each phase adds a reviewable end-to-end behavior. New commercial capability remains disabled until its own gate passes.

## Release order

```text
0 Verify current Places Search and establish scoped contracts
  → 1 Footer entry and supplier onboarding/access
  → 2 Agent package wizard and first-package review
  → 3 Approved tour cards and details in Places Search
  → 4 Safe routine-update automation and cache consistency
  → 5 Authoritative inventory and TripRaft retail quotes
  → 6 Controlled booking and verified payments
  → 7 Supplier settlement invoices and operations
  → 8 Limited production pilot
  → 9 Measured optimization and optional supplier integrations
```

**First release:** phases 1–4 can deliver an onboarding/publishing/discovery pilot with price visibility controlled and checkout disabled. It does not need to wait for a real payment provider. The full paid pilot needs phases 5–8 plus signed commercial decisions.

The source's indicative weeks 1–20+ cover audit through a controlled pilot, not a guaranteed deadline. Use it as a planning envelope and re-estimate after phase zero using actual supplier-access, deployed UI and provider gaps. Agent content/operations and advisor work can overlap engineering; money and inventory acceptance cannot be skipped to meet a date.

## Phase 0 Inspect the actual integration and decide the first release

**Purpose:** confirm exactly what is extended and protect the existing product. Do this with the existing repository checks and normal backups; do not rebuild a catalog migration project.

Tasks:

1. Record branch/current changes and baseline behavior for `/places`, `/place-search`, grouped country/state results, autocomplete, detail modal and shared footer.
2. Compare the inspected checkout with the deployed/reference page's country and trending sections. Identify their actual components, APIs and ranking/editorial source. If absent here, make the missing rail an explicit task with a real data source.
3. Record backend route/auth boundaries, user/session behavior, current admin check, model imports and migration head. Check how a supplier-only session will be denied across unrelated private APIs.
4. Agree the independent tour API/DTO and package draft/public revision boundary. Document private/public field allowlists and price visibility before frontend work.
5. Select discovery-only first release or a later paid pilot. Record the user's undecided entity/bank/supplier countries, price visibility choice and supplier review ownership; do not invent them.
6. Run current structure/lint/typing/relevant regressions and record failures separately from new work. Earlier launcher-test failures need a scoped resolution before claiming the root verification gate green.

**Done:** mapped real integration points; defined partner scope, public DTO, initial visibility and first-release gate; existing data/readers preserved. A catalog match/release is not a prerequisite for a supplier tour.

## Phase 1 Footer partner entry onboarding and access

Source: sections 2, 5, 16 and B2–B3.

Tasks:

1. Add `/partners` with the listing workflow, requirements, FAQs, terms/contact and truthful benefits. Add the **Partner with TripRaft** link to `Footer.jsx` under Company, next to About Us and Contact, in the same release.
2. Add partner registration/login/recovery, verified contact, onboarding and status/corrections screens. Reuse identity primitives with supplier-only portal grants and scoped sessions.
3. Add business applications, reviewer decisions, roles and supplier isolation. Applicants can see only their own application; approved staff receive own-business capabilities.
4. Enforce partner audience permissions server-side across unrelated private APIs and realtime/export endpoints. Ordinary traveler accounts keep their existing behavior.
5. Add internal admin approve/reject/request-changes/suspend screens and audit. Supplier owners cannot self-approve or assign themselves platform powers.
6. Keep payout credentials/documents private and provider-hosted where later available. Country-specific evidence requirements stay configurable pending business decisions.

**Done:** footer opens the real landing; an applicant submits and sees review status; admin approves/rejects with reason; an unapproved/suspended supplier cannot publish; supplier login cannot access unrelated private TripRaft services. Partner layout shows its own permitted navigation.

## Phase 2 Package dashboard wizard and initial approval

Source: sections 4–7, appendix A and B4–B5.

Tasks:

1. Build My packages, duplicate/save draft/preview/submit and per-package revision status. Every record is owned by the authenticated agent.
2. Deliver the seven-step wizard: basics; origin/destinations/finish; complete daily itinerary; services; media/policies; departures/private rate proposals; review/attestations.
3. Validate duration/day sequence, route fallback, services, cancellation terms, contact SLA, currency/rate flags and media rights. Keep raw upload staging private with file/type/size/scan checks.
4. Store optimistic versions and immutable submitted content. Parallel staff edits conflict explicitly. A published package edit creates a draft revision rather than changing current public terms.
5. Review the first package manually, with checklist/comments and changes-requested flow. All later new packages also start with review until a trusted-tier policy is explicitly enabled.
6. Add private agreement/rate inputs and a preview that uses the same public allowlist, without exposing costs to public users. Price configuration can follow while inquiry-only discovery remains explicit.

**Done:** an approved agent creates a complete package without administrator data entry, uploads cleared media, receives review feedback and produces an approved revision. Agent A cannot read/edit Agent B's draft, media, rates or reviews. No unapproved content is publicly reachable.

## Phase 3 Tour packages inside existing Places Search

Source: sections 3–4, 14, 17 and B1/B6/B10.

Tasks:

1. Build public allowlisted projection and `/api/v1/tours` list/detail/departure APIs, using current active supplier and approved revision checks.
2. Add independent featured/available tour sections or a Tours content tab to `PlaceSearchPage`. Keep place results/autocomplete/grouping/modal and existing country/trending behavior stable.
3. Build cards with licensed cover, route, days/nights, factual inclusions, legitimate availability status, price according to visibility policy and View details CTA.
4. Add `/tours/:slug`: gallery, route/key facts, daily itinerary, hotels/transport, dates/traveler options, inclusions/exclusions, policies, legal seller/support and freshness. Inquiry is explicit when booking is disabled or supply unknown.
5. Add destination/date/duration/traveler/budget/service filters as supported. Price-based filters/sorts are unavailable when policy hides public prices. Preserve route query and back navigation.
6. Handle empty/error/loading independently for places and tours. No failed adapter replaces the other with an empty page; do not generate fake packages from place rows.
7. Add editorial featured selection and valid metadata/canonical slugs. Public SEO renders only approved fields; noindex/private exclusion for draft/rejected/deleted pages. Introduce focused pre-rendering/server rendering only if needed for this public route, not a whole framework rewrite.
8. Track card impression/click, detail and inquiry events without supplier costs, private contracts or hidden amounts.

**Done:** an approved supplier tour appears and opens correct details in the existing website. Package revision and card/detail agree; countries/trending and place search regressions pass. Agent packages can display even when no optional internal catalog match exists. A suspended/rejected package is absent from search, direct public APIs and indexed metadata.

## Phase 4 Routine update automation and versioned publication

Source: B3–B6, B9 and B10. This is a required capability, not a policy of reviewing every edit manually forever.

Tasks:

1. Implement a server change classifier using field diffs and semantic-risk rules. Mark itinerary/route/duration, hotel standard, key inclusions, cancellation and commercial/identity changes as material.
2. Auto-validate safe typo/formatting edits and trusted inventory open/close adjustments. Media needs automated checks and escalation for flags. Unknown or risky changes default to review.
3. Store pending material revisions while continuing to serve the last approved revision. Approve a specific expected revision atomically; reject stale review actions.
4. Persist domain state plus versioned outbox in one transaction. Idempotent workers update the public projection/search index, invalidate cache and record consumption. Replay cannot roll back a newer revision.
5. Add bounded public refetch or authorized invalidation events for inventory/content/price changes. Proposed healthy-service target: safe routine changes visible within one minute, then measure and revise.
6. Suspend/withdraw immediately blocks new sales/public eligibility and purges caches. Preserve purchase-time snapshots and assigned customer support cases.
7. Add trusted-tier thresholds, reasoned decisions, revocation and audit. Enable later new-package automation only after fulfillment/moderation evidence supports it.

**Done:** safe updates appear promptly; major route changes remain pending with old content still live; out-of-order/replayed events do not regress content; suspended suppliers disappear promptly and cannot use cached content to sell.

## Phase 5 Inventory retail pricing and immutable quotes

Source: sections 6, 8–10, 12, 15 and B7–B8.

Tasks:

1. Model each departure's dates/zone/cutoff, min party, allocated/confirmed/held/blocked quantities and authoritative source/freshness.
2. Separate exclusive allotment, connected source, manual shared pool and unspecified inventory. Exact remaining seats require actual authority; manual unknown remains Check availability/inquiry.
3. Build safe operator inventory edits with revision checks, audit and rejection below commitments. Stop-sale is immediate; resume revalidates policy and supplier status.
4. Build private agreements/rate proposals and admin-approved fixed retail rules/floors/caps, tax/fee profiles and minimum contribution checks. Do not expose rate proposals as retail prices.
5. Enforce the public visibility policy across API/HTML/SEO/analytics/caches. Re-evaluate safe From price against an eligible actual departure and occupancy.
6. Implement exact minor-unit math, versioned immutable quotes, expiry and explicit re-acceptance. An authorized buyer must see total and mandatory taxes/fees before any payment authorization.
7. Add durable request operation keys/body hashes and atomic holds on PostgreSQL; lock counter/hold updates, expire old holds transactionally and schedule recovery.
8. Add manual supplier commitments and SLA/expiry handling. Do not capture unsupported nonrefundable money before supply commitment.

**Done:** truthful statuses and reproducible customer totals; no supplier-cost leaks; one winner for last seat; no negative/oversold allocation; expired quotes/holds cannot be reused silently. Postgres tests use independent connections and real migrations.

## Phase 6 Controlled booking hosted checkout and refunds

Source: sections 10–11, 15–16 and B8.

Tasks:

1. Select one approved provider after country/entity/seller review; use a deterministic fake first and one approved sandbox adapter next. Document supported capabilities and test/live separation.
2. Create server provider orders from accepted quote/party/booking state and persist intent before network calls. Reconcile ambiguous timeouts before retrying.
3. Verify raw-body webhook signature and provider account/environment; persist receipt/deduplicate before acknowledgement; verify trusted order, exact amount/currency and capture.
4. Keep payment, supplier confirmation and booking states separate. Confirm only with valid supply and verified payment; issue one voucher and one effective supplier notification.
5. Handle late capture, browser close, duplicate capture, supplier rejection and expired commitment. Reacquire/reconfirm safely or create controlled refund/remedy; never oversell or discard a captured payment fact.
6. Add buyer booking details, authorized private documents, minimum supplier manifest and support escalation. Booking IDs/public references do not replace authorization.
7. Implement cancellation/full/partial refund policy with locked refundable balances and idempotent provider actions. Include accountant-approved balanced capture/refund journal foundations before live money.

**Done:** one verified sandbox purchase produces one booking, journal and notification; forged callbacks/replays do not; late/rejected cases reconcile/refund accurately. Supplier-only sessions remain unable to access unrelated traveler features.

## Phase 7 Payout invoices reconciliation and operations

Source: sections 8, 11–12, 16 and B7–B8.

Tasks:

1. Finalize model-specific approved accounting templates, legal seller/invoice issuer, tax/credit/withholding evidence and numbered invoices/credit notes.
2. Create supplier payables/milestones, beneficiary verification and finance approval. Enforce funds/reserve/liability checks; a 30/70 schedule is not assumed without an approved contract/provider flow.
3. Track payout scheduled/submitted/processed/failed/reversed separately from bank unmatched/matched/exception. Save provider/bank references and reconciliation evidence.
4. Import gateway settlement/bank lines with duplicate protection; reconcile fees, timing, reversals, overpayments and orphan captures daily. Assign every exception.
5. Handle refund after payout as explicit supplier recovery/reserve/adjustment, not guaranteed automatic clawback. Add chargeback/disruption support and payout freeze controls.
6. Audit all approvals, pricing overrides, bank/identity changes, publication actions and financial transitions with redacted actor/version/reason/correlation records.
7. Deploy required workers/scheduler, alerts, restoration/replay runbooks and separate sales/payout pause controls that preserve refund/reconciliation access.

**Done:** finance traces each payment from frozen quote through invoice/liability/journal to supplier/bank or refund evidence. Both commercial models have distinct correct private accounting while the public layout remains consistent.

## Phase 8 Limited production pilot

Source: sections 18–20 and B10–B11.

Begin with a small verified operator cohort and reviewed packages/departures, one chosen market/currency/provider and named support coverage. The document's milestone of five approved agents is a target, not current supply. A publishing-only pilot can precede a paid pilot.

Before real money, require business/provider/tax/invoice/contract approval; all stock/quote/payment/refund/financial race tests; private data/portal isolation; backup/restore and event replay drills; correct public price disclosure; media rights; operational exception ownership and a tested pause/rollback switch. Inspect early paid bookings and fulfillment manually, reconcile daily and monitor supplier acceptance/refund aging.

Disable only tour capabilities if problems occur. Countries/places/trending and unrelated features remain available. Turning off new sales must not turn off existing buyer support, refunds or reconciliation.

**Done:** evidence of reliable fulfilled bookings and reconciled cash, no unresolved critical security/financial defects, measured supplier SLA and a written expansion decision. Do not equate GMV with revenue or profit.

## Phase 9 Optimization after pilot evidence

Add contract-bounded demand tiers, seasonal/departure timing, measured booking velocity and promotions with funding/eligibility/caps; never repeat-search punishment or false scarcity. Track conversion and contribution after taxes, supplier obligation, gateway/support/refund/discount costs.

Add one licensed supplier booking connector when justified, implementing price/availability rechecks, reservation/confirm/cancel/fetch, rate limits, freshness and timeout recovery. Hotels/room occupancy and transport inventory require appropriate resource models rather than a tour-seat shortcut. Saved provider payment methods, multi-currency display, package comparison and verified reviews are optional separately approved releases.

Evaluate trusted-tier publication expansion with revocable thresholds and abuse monitoring. Public source content, price and moderation controls remain authoritative. Improve SEO/merchandising using real relevance/fulfillment evidence, and label sponsored placements where applicable. Hire supplier operations/support when measured volume and contribution/runway support it, not because payment volume looks large.

## Ordered implementation backlog

These are local planning IDs, not external tracker issues. Each result should be delivered as reviewable source plus focused validation.

| ID | Phase | Result | Dependencies |
| --- | --- | --- | --- |
| TPK-001 | 0 | Current/deployed search/footer audit and regression contract | None |
| TPK-002 | 0 | Public/private DTO and launch visibility specification | TPK-001 |
| TPK-003 | 1 | Partner-only account/session grants and denial matrix | TPK-002 |
| TPK-004 | 1 | Footer link, real `/partners` landing and register/login/status routes | TPK-003 |
| TPK-005 | 1 | Business applications/staff/review/suspension | TPK-003 |
| TPK-006 | 2 | Package/revision/media schema and wizard draft flow | TPK-005 |
| TPK-007 | 2 | First-package review/diff/changes-requested/published pointer | TPK-006 |
| TPK-008 | 3 | Allowlisted public tour projection and search/detail APIs | TPK-002, TPK-007 |
| TPK-009 | 3 | Cards/featured sections/filters in existing Places Search | TPK-001, TPK-008 |
| TPK-010 | 3 | `/tours/:slug` details, inquiry and approved SEO metadata | TPK-008, TPK-009 |
| TPK-011 | 4 | Change classifier and safe automatic updates | TPK-007 |
| TPK-012 | 4 | Durable outbox/projection versioning/cache invalidation | TPK-008, TPK-011 |
| TPK-013 | 4 | Suspension/withdrawal/trust-policy enforcement and audit | TPK-005, TPK-012 |
| TPK-014 | 5 | Departures/source trust/allocations/freshness UI | TPK-006, TPK-012 |
| TPK-015 | 5 | Private agreements and approved retail/tax/visibility rules | TPK-002, TPK-014; commercial inputs |
| TPK-016 | 5 | Exact immutable quotes, durable operations and atomic holds | TPK-014, TPK-015 |
| TPK-017 | 6 | Fake/selected sandbox provider and server-created orders | TPK-016; provider approval |
| TPK-018 | 6 | Durable signed webhooks, capture verification and journal | TPK-017 |
| TPK-019 | 6 | Booking confirmation/voucher/manifest/notification | TPK-018 |
| TPK-020 | 6 | Rejection/expiry/duplicate-charge/partial-refund recovery | TPK-016, TPK-018, TPK-019 |
| TPK-021 | 7 | Seller-correct invoices/credit notes/payables | TPK-015, TPK-018; accountant review |
| TPK-022 | 7 | Verified/approved payouts and bank reconciliation | TPK-020, TPK-021 |
| TPK-023 | 7 | Support/audit/alerts and restoration/replay operations | TPK-012, TPK-020, TPK-022 |
| TPK-024 | 8 | Bounded pilot, early order audit and rollout review | Applicable publishing/paid launch gates |
| TPK-025 | 9 | Measured pricing/trust/merchandising improvements | TPK-024 |
| TPK-026 | 9 | First licensed supplier connector/optional customer extras | TPK-024 and capability approvals |

## First implementation sprint

1. Audit the actual Places Search/deployed reference and define the separate tour result shape and partner permission matrix.
2. Add partner application/membership/session scope migrations and API contracts; establish isolated PG tests without changing the current catalog or trip/expense schemas.
3. Implement partner landing/onboarding/status and supplier reviewer vertical slice. Add the footer Company link only with its real route.
4. Demo applicant submission → admin decision → approved supplier dashboard shell. Verify a supplier-only session is denied by unrelated private APIs.
5. Begin the wizard's draft basics/route/duration flow after that boundary passes. Follow with full content/media/review before public package cards.

Supplier publishing/discovery remains the priority. Do not begin with external travel APIs, broad organization workspaces, dynamic pricing ML or payment complexity.

## Acceptance matrix

| Scenario | Required outcome |
| --- | --- |
| Footer partner entry | Company contains About Us, Contact and Partner with TripRaft; target route works on keyboard/mobile |
| Existing discovery regression | Country/state grouped results, place modal, autocomplete and actual country/trending sections preserve behavior |
| Tours unavailable | Existing place content still works; local tour error/empty state is honest |
| Catalog unavailable/no match | Supplier tour draft/review/publication works independently; existing catalog error stays isolated |
| Partner A requests B's package/media/rate | Denied without metadata leakage or mutation |
| Supplier-only session hits trips/expenses/AI/private exports/socket | Backend denies; login/refresh cannot elevate its audience |
| Unapproved/suspended supplier | Cannot publish or sell; suspended listings removed from public cache/search/direct detail |
| Draft/rejected/pending revision URL | No public draft content, media or metadata; previous approved material revision stays live |
| Stale staff edit or reviewer decision | Version conflict, no silent overwrite |
| Routine typo/trusted inventory change | Validated auto publication and prompt projected update |
| Major route/hotel/policy change | Material review; no automatic consumer-term replacement |
| Duplicate/out-of-order publication events | One effect, newest approved revision preserved |
| Public/API/HTML/SEO inspection | No net cost, commission, margin, agreement mode, bank/tax evidence or admin notes |
| Price-hidden policy | No price values/aliases in public payload/HTML/JSON-LD/analytics/cached content; no inferred price filter/sort |
| Card/detail pricing enabled | Same current public revision; valid selectable From amount/conditions; full mandatory charges disclosed |
| Unknown/manual supply | Check availability/inquiry, no invented numerical seats or instant confirmation |
| Two buyers race last seat | Exactly one guaranteed hold/confirmation; other gets unavailable |
| Expiry versus payment | One legal transition; safe reacquire/reconfirm or refund, never oversell |
| Lower capacity below commitments | Rejected/audited; existing holds/confirmed bookings retained |
| Repeated search twenty times | No individual punitive price increase; quote lock intact |
| Forged/duplicate/out-of-order payment callback | Signature/order/amount/account checks; one capture/booking/journal/notification |
| Provider order/payout timeout | Persistent correlation/reconciliation before retry, no blind duplicate action |
| Supplier rejection after capture | Pending/remedy/refund status, no false voucher |
| Partial/refund after payout | Correct item/tax allocation, refund cap, supplier recovery and reconciliation |
| Payout processed but bank unmatched/reversed | Separate states, evidence and assigned finance exception |
| Inclusive/exclusive tax examples | Approved exact math/issuer/credit policy, no doubled tax or assumed eligibility |
| Public route accessibility/SEO | Labels/focus/alt text, responsive gallery/forms; approved pages only; hidden prices not in structured data |
| Restore and replay | Inventory/publication/ledger state consistent; external side effects reconciled once |

## Verification deployment and operations

Use existing lint/typecheck/tests/build and structure commands. Add explicit request/response schema and public-field snapshot tests. Extend TS checks to new components and configure TSX tests. Backend conftest currently forces SQLite; isolate PG test configuration before application imports. Run real PostgreSQL fresh/upgrade migrations, concurrent row-lock cases and financial uniqueness/rollback tests. Use the deterministic fake for browser journeys and selected provider sandbox tests before a paid release.

CI must discover the new suites, verify generated client drift and preserve canonical workflow synchronization. No tests should open personal databases. Do not claim production integration from static Compose validation or a passing fake-provider test.

Suggested separately controlled backend gates: `TOURS_DISCOVERY_ENABLED`, `PARTNER_PORTAL_ENABLED`, `TOURS_ROUTINE_AUTOPUBLISH_ENABLED`, `TOURS_TRUSTED_NEW_PACKAGE_ENABLED`, `TOURS_CHECKOUT_ENABLED`, `TOURS_PAYOUTS_ENABLED`, plus the versioned `public_price_visibility` policy. Default riskier capabilities off until their acceptance passes. Feature disablement preserves non-tour features and existing transaction support.

Deploy private upload storage and approved public media delivery, PostgreSQL backups/restore, Redis, API, required Celery workers and one effective scheduler. Persist inbox/outbox retries and dead letters. Keep test/live provider credentials and webhook objects isolated; store secrets outside Git.

Measure publication lag/review age, price/availability freshness, card/detail conversion, source failures, supplier confirmation SLA, hold expiry, captured-unconfirmed money, refund/payout aging and reconciliation. Alert on public private-field exposure, suspension/cache inconsistencies, negative inventory, duplicate postings and unexplained bank differences. Runbooks cover stop sales, publication replay, captured/unconfirmed booking, refund after payout, beneficiary change, payout reversal, reconciliation and restore.

GMV is not net revenue/contribution/profit. Track tax, supplier liability, fees, discounts, support/refund/AI variable costs and fixed runway separately. Supplier operations/support hiring follows actual bottlenecks and sustainable contribution; customer deposits and supplier liabilities are not payroll reserves.

## Remaining decisions

| Decision | Owner/dependency |
| --- | --- |
| Entity/bank/supplier/customer countries and charge currency | Founder; explicitly undecided as of 18 October |
| Discovery launch price visibility | Product/finance; backend-controlled policy, not scattered UI hiding |
| Operator verification evidence and terms | Supplier operations/legal; country-specific |
| Legal seller, marketplace/reseller authority, taxes/invoices/refund responsibility | Qualified accounting/legal review and signed supplier terms |
| Gateway eligibility, settlement timing, reserves, refunds and transfer support | Provider after entity/country selection; no provider selected by this plan |
| Actual deployed country/trending components and ranking source | Engineering/product in phase zero |
| Inventory trust/staleness and supplier acceptance SLA | Operations and each contract |
| Trusted-tier automation, material-change policy and exception thresholds | Review/risk owner; versioned and revocable |
| Pilot operators/support coverage and operating limits | Founder/operations before public/paid rollout |

## Source coverage

| Source | Plan coverage |
| --- | --- |
| Sections 1–4 | Scope, preserved search, public cards/detail and phases 0/3 |
| Sections 5–7 | Portal wizard, inventory controls, review and admin pricing, phases 1–5 |
| Sections 8–12 | Private agreement/pricing, truthful seats, quotes, tax/payment/settlement phases 5–7 |
| Sections 13–16 | Data/API/model registration, transactional workflows, authorization/media/audit/recovery |
| Section 17 | Separate tour ranking, approved SEO and privacy-safe analytics |
| Sections 18–20 and appendix A | Milestones, backlog, launch gates and open decisions |
| B1–B4 | Same Places Search vertical, footer partner entry, limited supplier account and wizard |
| B5–B6 | First review, safe automatic changes, pending material revisions and outbox/cache consistency |
| B7–B9 | Retail authority, hidden-price enforcement, inventory and normalized API scope |
| B10–B11 | Stage acceptance, regression matrix and unresolved launch inputs |

All external provider/tax references in the source need version/current applicability checks when selecting that integration. This planning task does not claim account approval, legal determination, live seats, signed suppliers or deployed features.
