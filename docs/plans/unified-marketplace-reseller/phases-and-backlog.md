# TripRaft implementation phases and execution backlog

This is the complete delivery sequence for the supplied blueprint, adapted to the current repository. Phase durations are initial engineering estimates for one full-time experienced engineer, with part-time finance/legal and supplier operations support. They exclude external approval delays and should be revised after phase zero. Later phase durations are less certain.

Execution update for 18 October 2026: phase-zero inventory, backup/restore tooling and verification capture have started. See the [baseline report](../../reports/marketplace-phase0-baseline-2026-10-18.md) and [open commercial decisions](../../decisions/marketplace-phase0-decisions.md). Phase one workspace implementation has not started in this checkpoint.

Engineering owner means the assigned developer; founder owns business decisions; finance/accounting owns tax and ledger policy; supplier operations owns supplier commitments; provider owns account approval. One person may fill multiple roles, but every gate still needs a named accountable person.

## Dependencies and releases

```text
P0 baseline and decisions
  -> P1 workspaces and access
  -> P2 supplier contracts
  -> P3 products offers departures
  -> P4 quotes inventory booking state
  -> P5 verified sandbox payments and ledger foundation
  -> P6 fulfillment trip linkage and support
  -> P7 invoices refunds payouts and reconciliation
  -> P8 controlled marketplace pilot
       -> P9 selected reseller pricing promotions and first external integration
       -> P10 organization travel and approvals
       -> P11 richer Scout/Crew and travel intelligence
       -> P12 expansion and optional commercial products
```

Accounting templates, observability, security and failure tests are developed with the relevant feature, not postponed to phase eight. Basic AI and group integration land in phase six; phase eleven expands them. Reseller logic is designed from phase two and tested before launch, but its production gate stays closed until separately approved.

| Phase | Planning range | Result |
| --- | --- | --- |
| 0 | 1–2 weeks | Reconciled baseline and decisions |
| 1 | 3–5 weeks | Isolated workspaces and preserved existing workflows |
| 2 | 2–3 weeks | Verified supplier and signed versioned contract |
| 3 | 2–3 weeks | Reviewed offer and truthful departure availability |
| 4 | 3–4 weeks | Immutable quotes, safe holds and reservation lifecycle |
| 5 | 3–5 weeks | Verified sandbox payment with balanced posting |
| 6 | 2–3 weeks | End-to-end traveler/supplier fulfillment and support |
| 7 | 3–5 weeks | Reconciled refunds, invoices and supplier money movement |
| 8 | 2–4 elapsed pilot weeks | Controlled real-world operations with limited inventory |
| 9 | 4–8+ weeks | Selected reseller and measured optimization; stage subreleases |
| 10 | 4–8+ weeks | Company workspaces, approvals, budgets and reports |
| 11 | 4–8+ weeks | Grounded AI and reliable travel intelligence |
| 12 | Scope after evidence | Broader commercial/platform expansion |

Phases zero through seven total approximately 19–30 engineering weeks. Including pilot stabilization, allow 21–34 weeks through phase eight. Supplier interviews, contract review, accounting fixtures and provider onboarding can overlap engineering. A 14-week target requires validated capacity for parallel work, a smaller baseline gap and a narrower agreed pilot; it does not cover all later phases. Never shrink correctness gates to meet the date.

## Phase 0 Baseline preservation and commercial decisions

**Purpose:** establish what this checkout actually contains and remove expensive architectural uncertainty. Source sections 1–6, 25, 46, 62, 73 and 79.

Tasks:

1. Record current Git status and preserve unrelated local work. Capture framework/runtime versions and a fresh test baseline. Existing modified scripts/data are not a clean implementation starting point.
2. Inventory all operational/catalog databases read-only, record schema/version/counts and file hashes, identify every configured reader and reconcile the empty-default/populated-planner discrepancy.
3. Back up operational data, catalogs and enrichment checkpoints. Rehearse a restore to a disposable location. Decide approved catalog distribution and namespace mapping.
4. Record legal entity, initial customer/supplier countries, one charge currency, seller model, refund exposure and supplier niche.
5. Compare one-provider candidates on eligibility, travel onboarding, marketplace/reseller funds flow, vendor verification, split/refund support, settlement timing, chargebacks, signed webhooks and reporting. Request approved product access before selecting implementation.
6. Obtain commercial term definitions and accountant-approved calculation fixtures. Keep tax assumptions explicitly sandbox-only until approved.
7. Select the pilot: proposed 3–5 verified suppliers, 10–20 reviewed departures, one geography, support coverage and simple full-payment booking.

Deliverables: baseline report, catalog release decision, provider capability matrix, initial seller/funds-flow decisions, supplier contract checklist, pilot scope and risk register. Use `docs/decisions/` for non-sensitive approved summaries; keep signed sensitive evidence in restricted storage.

**Exit gate:** the team can identify each live data source, restore a copy, name the legal seller for a pilot offer and show a viable provider-onboarding path. Engineering sandbox work may proceed while external approval is pending; paid publication cannot.

## Phase 1 Workspaces permissions and infrastructure foundations

**Purpose:** allow one login to participate safely in personal, group, organization and supplier contexts. Source sections 8–12, 35 and 40.

Tasks:

1. Add workspaces, membership and capability services with explicit actor context. Preserve existing global `User`; add no duplicate customer/supplier login table.
2. Map current `creator/admin/member/viewer` trip roles to capability checks without silently changing stored semantics. Keep functional Crew roles separate from administrative authority.
3. Add nullable ownership links and restartable backfill for existing trips/expense groups. Review ambiguous mixed-owner groups. Keep existing IDs, invites, balances and realtime behavior.
4. Introduce backend scoped repositories and document grants. Supplier and buyer sides of a future booking use separate projections.
5. Add workspace switcher, scoped cache keys, logout/workspace-switch cache clearing and safe persistence allowlists.
6. Expand TypeScript coverage and TSX test tooling for new frontend modules. Define exact minor-unit contracts without changing legacy expenses.
7. Establish PostgreSQL integration-test mode before application imports; existing `tests/conftest.py` unconditionally selects SQLite and must be refactored or isolated.
8. Add durable operation/outbox schema foundations and private storage interfaces. Introduce MFA/step-up authentication for finance and high-risk supplier/admin actions; exercise recovery.

Deliverables: workspace API/UI, ownership backfill report, capability matrix, cross-tenant tests, typed frontend setup, isolated PostgreSQL test harness.

**Exit gate:** users in two unrelated workspaces cannot read/change each other's trips, documents or draft supplier resources. Existing planner/chat/polls/expenses/auth regressions pass. Ownership backfill is complete before required constraints activate.

## Phase 2 Supplier onboarding contracts and verification

**Purpose:** make a supplier an approved business with clear pricing/seller authority. Source sections 10, 19, 27, 51–53, 61–62.

Tasks:

1. Build mobile onboarding, supplier staff capabilities, contact verification, legal/tax profile and required safety/licensing evidence.
2. Integrate provider-hosted business/beneficiary verification where supported; persist tokens, masked data and status. Bank changes require re-verification and payout freeze policy.
3. Add legal entities and versioned contracts: sale model, currency, inclusive/exclusive input, price authority, commission or supplier net cost, floor/cap, allotment, hold/acceptance SLA, payout milestones and refund liability.
4. Keep marketplace and reseller contracts separate even for the same operator. Reject inconsistent contract/offer seller combinations.
5. Add internal supplier review, evidence requests, rejection/remediation and suspension. Audit approvals and prevent self-approval.
6. Interview 10 of a proposed 20–30 regional prospects; sign 3–5 pilot partners and complete one test package each. Acquisition work belongs to founder/supplier operations.

Deliverables: supplier portal onboarding/team/contracts, internal review screens, approved pilot supplier records and contract fixtures for both sale models.

**Exit gate:** an operator can onboard on a phone, see verification issues, accept versioned terms and receive approval. An unverified/suspended beneficiary cannot receive payout. No supplier can see another supplier's contract.

## Phase 3 Products offers departures and public discovery

**Purpose:** publish genuinely bookable package inventory with clear seller identity. Source sections 7, 11–18, 52 and 60–61.

Tasks:

1. Add supplier product descriptions, inclusions/exclusions, daily itinerary, pickup points, traveler bands, photos/rights and catalog place links.
2. Add contractual offers and publication review. Lock sale model/seller/contract version when published; material changes require reviewed versioning or a replacement offer.
3. Add departure calendar, IANA time zones, cutoffs, blackouts, minimum group rules, allotment/capacity revisions and audit history.
4. Implement `ALLOCATED`, `SUPPLIER_MANUAL` and future `PROVIDER_API` classification. Manual unknown capacity stays null; only approved allocations promise exact remaining seats.
5. Build public package search/detail and date selection with mandatory price/seller/cancellation/freshness disclosures.
6. Build supplier calendar and safe change preview. Reject capacity reductions below held plus confirmed quantities. Rate changes affect new quotes only.
7. Add basic public search analytics and supplier reliability timestamps. Do not present unverifiable reviews or false scarcity.

Deliverables: offer/departure API, public package screens, supplier editors/calendar, internal publication review and catalog mapping validation.

**Exit gate:** a verified operator creates an approved package/departure, a traveler sees source-appropriate availability, and unauthorized supplier edits fail. No live checkout yet.

## Phase 4 Pricing quotes holds and booking orchestration

**Purpose:** convert availability into a capacity-safe reservation with frozen economics. Source sections 14–16, 19–23, 24, 58, 65–67.

Tasks:

1. Implement exact money arithmetic, currency exponents, approved inclusive/exclusive tax fixtures, discount funding and rate-version selection. Keep dynamic demand adjustments disabled initially.
2. Issue immutable scoped quotes with public/private snapshots, all mandatory fees, purchase terms and server expiry. Repricing requires explicit acceptance.
3. Build durable commerce idempotency with request hashes, result/resource references and business uniqueness constraints.
4. Implement PostgreSQL row-locked hold create/consume/release/expiry, materialized counter reconciliation and deterministic lock order.
5. Create bookings with independent booker/payer/travelers/group linkage. Implement supplier reservation adapter for allocated and manual flows.
6. Add manual request queue, supplier acceptance/rejection, commitment expiry and quote refresh after supplier delay.
7. Build checkout review/traveler forms/countdown and clear pending/confirmed state labels. Use fake payment facts for deterministic demonstrations.
8. Add late-capture compensation design, external-operation intents and transactional outbox before provider calls are introduced.

Deliverables: quote/hold/booking endpoints, buyer/supplier projections, checkout review, expiry jobs and PostgreSQL contention tests.

**Exit gate:** exactly one buyer can reserve the last seat; retries create one reservation; expiry versus confirmation never oversells; manual supplier interest never masquerades as guaranteed inventory; accepted economics remain unchanged.

## Phase 5 Payment provider sandbox and commercial ledger foundation

**Purpose:** accept trusted provider facts and prove safe recovery before real charges. Source sections 24–29, 39, 59, 68 and 77.

Tasks:

1. Implement a provider-neutral contract with explicit capabilities and a deterministic fake. Add exactly one selected provider adapter using approved sandbox access.
2. Create server-side payment orders from accepted quote totals. Persist intent before external calls and reconcile ambiguous timeouts; never trust browser amount/status.
3. Use hosted checkout, verify raw-body signatures, durably deduplicate webhook receipts and enqueue processing. Narrowly exempt webhook routes from browser CSRF.
4. Fetch provider order/payment state and validate account, environment, order binding, exact amount/currency and capture. Multiple successful attempts create an overpayment exception.
5. Implement balanced journal services and source-event uniqueness. Commit capture facts and accounting effects atomically with local state.
6. Implement inbox/outbox retries, dead-letter handling, safe replay and provider API catch-up after missing callbacks/queue loss.
7. Recheck supply on capture; keep payment and supply states separate. Test late success, rejection, browser close, forged callback and duplicate/out-of-order events.
8. Add payment and booking exception views before pilot operations.

Deliverables: sandbox checkout, provider adapter/fixtures, trusted payment facts, balanced capture journals, recovery jobs and payment operations UI.

**Exit gate:** a real sandbox capture reaches exactly one booking/payment journal; browser success alone cannot confirm it; database/queue/network failures recover without duplicate charge/booking. No live enablement until phase seven/eight gates pass.

## Phase 6 Fulfillment group linkage documents and support

**Purpose:** make the full traveler-to-operator journey usable. Source sections 7–12, 28, 30, 48, 52 and 60.

Tasks:

1. Issue booking confirmation/voucher only after valid supply and verified payment. Record supplier confirmation reference and document version.
2. Build supplier booking queue, least-privilege manifests, pickup instructions, fulfillment status and customer-support contact workflow.
3. Add private storage, short-lived authorized download, document access events and retention rules. Generate accessible confirmations and downloadable records.
4. Attach booking summaries to the existing group planner, itinerary and notification feed. Keep full passenger documents and private finances out of group summaries.
5. Add optional expense draft from a confirmed purchase, requiring an authorized treasurer/member's action and duplicate prevention. A refund creates a visible adjustment proposal; it must not silently settle interpersonal debts.
6. Add support cases for pending supplier confirmation, failed payment, disruptions and cancellations, with assigned owners and SLAs.
7. Extend Scout/Crew to search approved offers and prepare booking proposals via typed tools. A human takes checkout/cancellation actions through the same authorized APIs.
8. Add verified-fulfillment feedback collection; publish ratings only after evidence/abuse checks.

Deliverables: booking portal, vouchers, supplier manifests, group booking panel, notifications, support queue and basic grounded offer tools.

**Exit gate:** family organizer plans, reserves and completes a sandbox purchase; supplier sees only required passengers; trip members see authorized status; support can trace and resolve a failed supplier confirmation.

## Phase 7 Invoices refunds payouts and reconciliation

**Purpose:** prove where every unit of money goes. Source sections 25–29, 49, 54–57, 59, 68–71.

Tasks:

1. Finalize accountant-approved posting templates for marketplace and reseller, including deferred revenue, taxes, commission, supplier cost/credit evidence, fees and reserve/recovery accounts.
2. Implement model-specific invoice issuer/numbering and immutable invoice lines; credit notes link adjustments to the original invoice. Obtain supplier invoices or authorized issuance workflow where required.
3. Add cancellation policy evaluation, partial traveler cancellation, refundable balance locks, refund approvals/intents and provider status reconciliation.
4. Create supplier payables and milestone schedules. A proposed 30/70 schedule is configurable only when contract and provider allow it; it is not a default guarantee.
5. Add maker/checker approval, beneficiary version binding, available-funds checks, payout submission, provider-settled versus bank-reconciled states and reversals.
6. Add daily gateway/settlement/bank imports with line uniqueness, UTR/references, fee decomposition and evidence-backed manual matching.
7. Handle refund-after-payout as supplier recovery/reserve/adjustment, not fictitious automatic clawback. Handle chargebacks and supplier failure with support cases and audit.
8. Build finance traces and metrics: GMV, revenue excluding tax, supplier liabilities, fees, contribution, cash, refunds, reserves and aging. Keep fixed operating costs separate from per-booking contribution.

Deliverables: correct invoices/credit notes, balanced model-specific journals, reconciled sandbox refunds/payouts, finance screens, accounting fixtures and operational runbooks.

**Exit gate:** finance can trace capture → booking → invoice → liability → payout/refund → provider/bank evidence. Duplicate/replayed actions do not change totals. Refund after supplier payment, payout reversal and tax-inclusive pricing fixtures pass.

## Phase 8 Controlled marketplace launch

**Purpose:** validate fulfillment and contribution with bounded operational exposure. Source sections 43–45, 71–72 and 76–78.

Tasks:

1. Verify entity, seller contracts, provider approval, tax/invoice configuration, refund reserves and support coverage. Enable only reviewed marketplace offers.
2. Rehearse staging booking/refund/payout lifecycle and recovery from an actual restored backup. Confirm production/sandbox keys and webhook environments cannot mix.
3. Launch proposed 3–5 suppliers and 10–20 departures in one geography. Use booking/value limits and allow purchases only within supported operations coverage.
4. Inspect the first 100 paid bookings at the ledger/fulfillment level. Review aging pending supply, refund state, payout exceptions and contribution daily.
5. Collect post-trip evidence and customer/supplier feedback. Resolve false availability, late confirmation and unmatched cash before increasing inventory.
6. Keep emergency pause controls for supplier/offer/checkout/payout independently available. Disabling sales must not disable refunds or reconciliation.
7. Review pilot exit evidence weekly and decide whether to expand, fix or pause acquisition.

Deliverables: signed launch checklist, first fulfilled bookings, reconciled money, incident evidence, unit economics dashboard and post-pilot backlog.

**Exit gate:** no unresolved critical financial/security defect; verified payment/supply state on every confirmed booking; daily reconciliation with every exception assigned; successful refund; measured fulfillment accuracy and support SLA. The source's 95% operational target is a proposed business metric, not permission for any double charge or overbooking.

## Phase 9 Selected reseller offers and measured commerce expansion

Deliver this as small independent releases, not one large launch. Source sections 20–23, 29, 51, 54–59 and external integration requirements.

1. **Selected reseller:** approve wholesale terms, seller identity, invoice chain, tax-credit evidence and customer/refund obligations. Enable only reviewed offers. Re-run the full ledger/refund/payout acceptance suite with reseller fixtures.
2. **Explainable dynamic pricing:** use verified occupancy, booking velocity, departure horizon and approved bands. Store inputs/rule version/reason and measure conversion/contribution. Never use repeat searches as a punitive input; respect quote locks and contractual price authority.
3. **Promotions:** explicit TRIPRAFT/SUPPLIER/SHARED funding, budget caps, stacking, eligibility, redemption locks and defensible reference prices. Gate loyalty/referral rewards behind abuse controls and positive economics.
4. **Saved payment methods:** provider tokens only, explicit consent, list/remove/default; capability/region review. No new raw card form or credential storage.
5. **First external provider:** choose one approved activities, lodging or supplier booking adapter. Implement provider-specific availability/price check, hold/confirm/cancel/fetch, timeout recovery, rate limits, freshness and licensed content rules. Redirect/referral is a distinct flow with truthful responsibility labels.
6. **Bulk supplier tools:** dry-run CSV import, field validation, row-level errors, revision preview and rollback by compensating updates; no direct inventory table imports.
7. **Browse FX:** timestamped estimate, source/currency exponent and clear charge-currency label. Actual multi-currency settlement is a separate approved project.

**Exit gate:** each subrelease preserves accepted quotes and journal invariants, has measured benefit, safe disablement and no cross-provider/tenant leakage. Hotel occupancy/rate plans and flight fare availability require dedicated resource contracts; do not reuse a tour seat counter as their complete model.

## Phase 10 Company education and organization travel

Source section 9 and the earlier enterprise plan provide the deeper corporate scope.

Tasks: organization membership and scoped guests; teams/cost centers; traveler profiles; policy versions and permitted booking classes; draft/submitted/approved/rejected travel requests; approval delegation and separation of duties; budget reservations; invoices/expense reports; duty-of-care contacts; organization-specific document retention. Start with manual approvals and explicit exceptions before automatic policy execution. Add billing/credit only after financial review.

Revalidate price and policy at booking time. Manager approval of an estimated budget is not an unexpired supplier quote. A changed total requires policy re-evaluation and, where applicable, new approval. Corporate approval cannot bypass payer authorization, inventory or captured-payment rules.

**Exit gate:** an employee requests travel, an independent approver approves within budget/policy, an authorized payer books, and finance receives correctly scoped records. Organization reports reveal no personal trips or another company's passenger information.

## Phase 11 Scout Crew intelligence localization and search

Source sections 30–33 and 70.

Tasks:

1. Add hybrid catalog retrieval and optional embeddings after catalog release/provenance is stable. No populated embeddings are assumed from the blueprint.
2. Add source-aware weather, route/time matrices, opening times, calendar export/sync and reference FX adapters. Track provider terms, attribution, cache limits, timestamp and degraded behavior.
3. Respect missing coordinates and unknown hours/durations; show partial routes or ask for a user choice instead of fabricating a feasible itinerary.
4. Implement durable AI proposals with preview/accept/reject, strict tool schemas, actor/workspace/resource authorization, consent and redacted trace/version metadata.
5. Evaluate groundedness, route feasibility, live availability claims, privacy, duplicate action prevention, prompt injection, price math, latency and cost per completed trip.
6. Add multilingual UI/content workflow, translated error/cancellation text, locale currency/time handling, keyboard/screen-reader verification and verified accessibility information.

**Exit gate:** AI can research and draft useful plans using permitted sources; it cannot invent supplier stock/prices, reveal private margins/documents or independently charge, refund, cancel or pay suppliers. Cost and quality are measured before premium positioning.

## Phase 12 Expansion after evidence

Optional work, ordered by observed customer demand and contribution:

- Multi-component packages with resource conversion/occupancy, reservation saga and compensating cancellation. Multiple suppliers/sellers require component-level legal seller, tax, payable and refund allocation. Do not promise distributed atomicity that providers cannot supply.
- Deposits/installments, split payer collection and group payment links, with outstanding balance, expiry, overpayment and refund allocation contracts.
- Multi-currency/cross-border processing with approved countries, FX execution, currency-specific ledger clearing and reconciliation.
- Supplier subscription plans, billing/entitlements and clearly labeled sponsored placements with transparent ranking rules.
- Loyalty/referral programs, negotiated corporate rates and broader partner integrations after fraud/economics review.
- Demand forecasting/ML pricing only with sufficient actual conversion data, explainability, fairness checks and holdout evaluation.
- Search infrastructure/replication, read replicas or service extraction only when measured limits or team ownership justify them.
- Native mobile and richer offline trip access when web usage proves the need; define private data/device revocation and offline reconciliation.

Each item requires its own requirements, migration/API contract, failure matrix, operating owner and release gate before implementation.

## Initial issue backlog

These are local planning IDs, not issues created in an external tracker. Split each into reviewable implementation PRs as necessary.

| ID | Phase | Priority | Reviewable result | Depends on |
| --- | --- | --- | --- | --- |
| UMR-001 | 0 | P0 | Recorded test baseline and protected working-tree inventory | None |
| UMR-002 | 0 | P0 | Catalog reader/count/hash report and non-destructive mapping decision | UMR-001 |
| UMR-003 | 0 | P0 | Seller/country/currency/provider capability decisions | Founder/advisor/provider input |
| UMR-004 | 0 | P0 | Approved contract fields and sandbox financial fixtures | UMR-003 |
| UMR-005 | 1 | P0 | Isolated PostgreSQL CI harness and migration baseline | UMR-001 |
| UMR-006 | 1 | P0 | Workspaces/memberships/capability API with denial tests | UMR-005 |
| UMR-007 | 1 | P0 | Restartable trip/expense ownership backfill and compatibility tests | UMR-006 |
| UMR-008 | 1 | P0 | Scoped frontend context/cache and expanded TSX checks | UMR-006 |
| UMR-009 | 1 | P0 | MFA/step-up and restricted document access foundation | UMR-006 |
| UMR-010 | 2 | P0 | Supplier onboarding/team with verification history | UMR-004, UMR-006 |
| UMR-011 | 2 | P0 | Versioned contracts, seller profiles and beneficiary validation | UMR-010 |
| UMR-012 | 2 | P1 | Internal supplier review/suspension screens | UMR-009, UMR-011 |
| UMR-013 | 3 | P1 | Products/catalog references/licensed media editor | UMR-002, UMR-011 |
| UMR-014 | 3 | P0 | Offer publication locks and seller consistency constraints | UMR-012, UMR-013 |
| UMR-015 | 3 | P0 | Departure calendar/allotment/source freshness | UMR-014 |
| UMR-016 | 3 | P1 | Public offer search/detail and disclosures | UMR-015 |
| UMR-017 | 4 | P0 | Exact pricing/tax version engine and immutable quote | UMR-004, UMR-015 |
| UMR-018 | 4 | P0 | Durable operation keys, request hashes and outbox | UMR-005, UMR-006 |
| UMR-019 | 4 | P0 | Row-locked holds, expiry and counter reconciliation | UMR-017, UMR-018 |
| UMR-020 | 4 | P0 | Booking machine and supplier commitment flow | UMR-019 |
| UMR-021 | 4 | P1 | Buyer review/traveler forms and pending state UI | UMR-016, UMR-020 |
| UMR-022 | 5 | P0 | Fake provider plus selected sandbox order adapter | UMR-003, UMR-018, UMR-020 |
| UMR-023 | 5 | P0 | Signed durable webhook inbox and trusted capture validation | UMR-022 |
| UMR-024 | 5 | P0 | Balanced journal service and unique capture posting | UMR-004, UMR-023 |
| UMR-025 | 5 | P0 | Late capture, missing webhook and ambiguous timeout recovery | UMR-019, UMR-024 |
| UMR-026 | 6 | P1 | Confirmation documents, manifests and notifications | UMR-020, UMR-024 |
| UMR-027 | 6 | P1 | Group booking summary and explicit expense proposal | UMR-007, UMR-026 |
| UMR-028 | 6 | P0 | Support cases and supplier confirmation escalation | UMR-025, UMR-026 |
| UMR-029 | 7 | P0 | Invoice issuance, tax evidence and credit notes | UMR-011, UMR-024 |
| UMR-030 | 7 | P0 | Policy cancellation and partial/full refund reconciliation | UMR-028, UMR-029 |
| UMR-031 | 7 | P0 | Milestone payables and approved payout instructions | UMR-011, UMR-024, UMR-030 |
| UMR-032 | 7 | P0 | Provider/bank matching, reversals and recovery ledger | UMR-031 |
| UMR-033 | 7 | P0 | Finance trace/exception/contribution screens | UMR-029, UMR-032 |
| UMR-034 | 8 | P0 | Staging recovery drill and launch checklist evidence | UMR-025 through UMR-033 |
| UMR-035 | 8 | P0 | Limited live pilot, daily audit and post-pilot report | UMR-034 plus business approvals |
| UMR-036 | 9 | P1 | Separately approved reseller release | UMR-035 and reseller policy approval |
| UMR-037 | 9 | P2 | Explainable price bands and funded promotions | UMR-035 |
| UMR-038 | 9 | P2 | First licensed supplier integration and freshness recovery | UMR-035 plus partner approval |
| UMR-039 | 9 | P2 | Consent-based saved provider methods | UMR-035 plus provider capability |
| UMR-040 | 10 | P2 | Organization request/approval/budget vertical slice | UMR-006, UMR-035 |
| UMR-041 | 11 | P2 | Grounded AI/intelligence evaluation and localized UI | UMR-002, UMR-027, UMR-035 |
| UMR-042 | 12 | P3 | Expansion design selected using pilot evidence | Phase-specific business case |

P0 means a live-money/security/correctness dependency, not that it must be implemented before every P1 usability task. P1 delivers the usable pilot. P2/P3 expand after pilot evidence.

## First ten working days

**Days 1–2:** execute UMR-001/002: record test failures without conflating them with new work, inventory and back up catalogs, trace reader paths and agree the approved release/mapping approach. Founder begins UMR-003 and supplier/provider outreach concurrently.

**Days 3–4:** approve architectural decisions and minimum seller/contract field definitions; prepare explicit sandbox tax/commission fixtures. Add PostgreSQL test isolation and a fresh/upgrade migration smoke job.

**Days 5–7:** implement workspaces/membership/capabilities and a safe ownership bridge. Include cross-tenant denial tests and legacy group regression coverage. Do not make incomplete backfills mandatory at deployment.

**Days 8–10:** complete workspace UI/cache/typing setup; begin supplier draft onboarding and versioned contract validation. Demo two users in separate supplier workspaces with rejected cross-workspace access. Publish a revised estimate using actual baseline/provider findings.

Expected first-sprint result: reliable foundations and a concrete supplier draft flow, not a claim of production checkout. If legal/accounting decisions remain open, use explicit mocks and sandbox fixtures; continue independent engineering while keeping dependent live features disabled.

## Definition of done for each implementation PR

Changed behavior has a clear acceptance example, scoped API contract and permission decision. New tables have an Alembic revision and imports in both registries. Money-changing operations have durable idempotency and business uniqueness. Appropriate regressions and PostgreSQL tests pass. UI has accessible pending/error states. Logs avoid private data. Required runbook/metric/release flag accompanies risky behavior. Generated contracts/workflow copies/file guide are updated when affected. No placeholder claims about provider approval, live inventory or financial finality ship.
