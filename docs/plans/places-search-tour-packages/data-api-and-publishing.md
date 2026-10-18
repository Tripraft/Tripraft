# Tour package data API and publication contracts

Proposed contracts for the updated tour-package vertical. Appendices B1–B11 of the supplied document refine the initial review flow, selective automation and price visibility. None of the tables or endpoints below is implemented by this planning checkpoint.

## Package information collected from agents

| Wizard step | Fields | Validation and visibility |
| --- | --- | --- |
| Basics | Title, slug proposal, summary, language, category, highlights, age limits, supplier SKU | Title 15–120 characters; unique server-approved public slug; descriptions sanitized |
| Route | Start/end, country, city, intermediate stops, pickup/drop-off variants, optional coordinates | Ordered stops with human-readable fallback; optional read-only catalog references; no catalog match required |
| Itinerary | Day number/title/details, sightseeing, meals, hotel nights, transfer and activity windows | Complete sequence for declared days; no unsupported guarantees; preserve booking-time revision |
| Services | Hotel/category or similar-category terms, occupancy, transport, activities, inclusions/exclusions, accessibility | Explicit facts and change conditions; do not infer verified accessibility |
| Media and policies | Cover/gallery, alt text, rights attestation/evidence, cancellation policy, deadlines, guarantees, FAQs/safety | Staged uploads, scanning, moderation and approved media only; versioned material policies |
| Departures and rates | Start/end, IANA zone, capacity/allotment, min party, cutoffs, blackouts, source mode, confirmation mode, private supplier rate/tax inputs | Departure-specific inventory; positive quantities; rates private and subject to commercial rules |
| Preview and submit | Complete review preview, operations contact/SLA, attestations, version and submit action | Server recomputes completeness; ownership and approved-agent status enforced |

Days must be at least one. Nights normally equal days minus one; exceptions need explanation. Supply currency/exponent explicitly; initial INR examples are not a confirmed operating currency. Do not collect passport/date-of-birth/payment data at browsing or draft listing stages unless required by a later authorized booking purpose.

## Logical database model

Use the current operational ORM base and incremental Alembic history. PostgreSQL is the transactional authority for live commerce. Keep catalog SQLite records and IDs unchanged; no writes of supplier rates, seat counters or booking state into `places`.

| Group | Proposed tables | Required guarantees |
| --- | --- | --- |
| Access | `user_portal_grants`, existing user/session extension, `agents`, `agent_users` | Partner-only audience, membership role/status, one supplier scope per request; no implicit traveler privilege |
| Verification | `agent_applications`, `agent_verifications`, `agent_beneficiaries` | Applicant/reviewer history, status/reason/evidence refs; provider tokens and masked bank data, no public verification documents |
| Package root | `tour_packages` | Agent FK, UUID, slug, lifecycle state, row version, current draft and last approved published revision pointers |
| Revisions | `tour_package_revisions`, `tour_package_days`, `tour_package_stops` | Immutable submitted/approved content snapshots; day/stop rows belong to a revision, not mutable shared content |
| Media/policies | `tour_package_media`, `tour_media_checks`, `tour_cancellation_policy_versions` | Staged/checked/published media states, rights, ordering, public-safe URLs, policy version and retention |
| Moderation | `tour_moderation_reviews`, `tour_publication_policies`, `tour_agent_trust_history` | Change category, automated/human decision, reason, effective policy version and revocable trust status |
| Published read model | `tour_public_projections`, `tour_featured_placements` | Approved revision only, public allowlist, supplier eligibility, publication version/epoch, editorial order and validity |
| Departures | `tour_package_departures`, `inventory_allocations`, `tour_inventory_events` | Capacity, confirmed/held/blocked, booking/source modes, cutoff, freshness and revision; nonnegative capacity invariant |
| Commercial | `supplier_agreements`, `supplier_agreement_versions`, `supplier_departure_rates` | Private mode/seller/commission/net-rate, terms, price authority, effective dates, liability and tax inclusivity |
| Retail pricing | `retail_pricing_rule_versions`, `tour_tax_profile_versions`, `tour_price_versions`, `tour_promotions` | Approved floors/caps, optional demand tiers, complete public total, tax/fee rules, funding source and audit |
| Quote/reservation | `tour_quotes`, `tour_quote_lines`, `tour_quote_acceptances`, `booking_holds`, `tour_supplier_reservations` | Immutable financial snapshot, actor/party/expiry, one legal hold consumption, source commitment reference |
| Booking | `tour_bookings`, `tour_booking_travelers`, `tour_booking_events`, `tour_booking_documents` | Separate buyer/payer/passengers, purchase revision/terms, supplier confirmation, private documents and append-only state history |
| Reliable operations | `tour_operations`, `tour_outbox_events`, `tour_event_consumptions`, `tour_webhook_inbox` | Durable request key/body hash; event uniqueness, aggregate version, retry/lease and safe replay |
| Payments | `tour_payment_attempts`, `tour_payment_facts`, `tour_refunds`, `tour_refund_allocations`, `tour_disputes` | Provider account/environment/object binding, verified amount/currency, refund balance reservation and unique effects |
| Finance | `tour_ledger_accounts`, `tour_journals`, `tour_journal_lines`, `tour_supplier_payables`, `tour_payable_milestones`, `tour_payouts` | Balanced immutable postings, model-specific liabilities, approved beneficiary/milestones, unique provider/action references |
| Invoices/reconciliation | `tour_tax_documents`, `tour_tax_document_lines`, `tour_invoice_sequences`, `tour_credit_notes`, `tour_settlement_lines`, `tour_bank_lines`, `tour_reconciliation_exceptions` | Correct legal issuer/number, credits/evidence, unique imports and bank/provider matching |
| Audit/support | `tour_audit_events`, `tour_notification_deliveries`, `tour_support_cases`, `tour_inquiries` | Redacted actor/action/version/reason history, deduplicated delivery, inquiry abuse controls and assigned exceptions |

Introduce these tables by phase. Do not create unused finance modules in the first discovery release. Keep all supplier-owned data reachable through an enforced agent ownership join. Optional catalog IDs never replace supplier ownership or public package UUIDs.

## Public private and supplier projections

| Audience | Allowed | Excluded |
| --- | --- | --- |
| Public card/detail | Approved package/route/itinerary/services/media/policies, legal seller identity, safe availability, permitted customer price | Supplier net cost, agreement mode, commission, margin, payout rules, bank/tax evidence, draft revisions, admin notes and fraud signals |
| Supplier content staff | Own drafts/reviews/content/departures and permitted private rate proposals | Other agents; platform margin/formula; unrelated traveler app data |
| Supplier operations | Own authorized booking queue and minimum fulfillment passenger data | Full card/payment tokens, unrelated passengers/documents and platform finance investigations |
| Supplier finance | Own contracted payable/payout status and references | Platform contribution, competitors and other agents' settlements |
| Admin reviewer/pricer/finance | Fields needed by explicit role and step-up policy | Unrestricted access merely because the UI has an admin button |
| Authorized buyer | Own quote, full payable before authorization, own booking/refund/documents | Internal sale-model label, supplier cost/commission/margin and unrelated buyer data |

Apply field allowlists before serialization. Do not return raw ORM dictionaries and hide fields in React. Private agreement mode remains internal even in public quote/detail DTOs; the required legal seller/invoice disclosures are explicit fields, not a reason to expose contract classification.

Amounts use integer minor units plus ISO currency and exponent. To avoid JavaScript precision loss, new API amounts are decimal strings, e.g. `"1550000"` paise; normalize the document's illustrative numeric payload through the typed contract. Use exact decimal/rational calculation for tax/FX, with approved rounding and deterministic remainder allocation. Do not change legacy expense money payloads.

### Public card example with prices enabled

```json
{
  "type": "tour_package",
  "id": "<package-uuid>",
  "slug": "kashmir-explorer-6d",
  "revision": 4,
  "name": "Kashmir Explorer",
  "days": 6,
  "nights": 5,
  "route": ["Srinagar", "Gulmarg", "Pahalgam"],
  "cover_image": {"url": "<approved-public-image-url>", "alt": "Supplier-approved tour image"},
  "starting_price": {
    "amount_minor": "1550000",
    "currency": "INR",
    "exponent": 2,
    "includes_mandatory_taxes": true,
    "basis": "per_person",
    "departure_id": "<eligible-departure-uuid>",
    "conditions": "<actual traveler and occupancy conditions>"
  },
  "availability": {"status": "LIMITED", "seats_left": 8, "checked_at": "<timestamp>"},
  "featured": true
}
```

The amount and seat count are examples, not invented launch inventory. A From price must correspond to a valid eligible departure/occupancy that can actually be selected at that amount. In hidden-price mode, omit `starting_price` and all monetary aliases entirely; do not substitute zero or serialize a hidden value in another field.

## Price visibility and commercial approval

Define a backend policy `public_price_visibility` with documented states:

- `HIDDEN`: public search/detail/HTML/structured data omit amounts and show View details or Check availability. For the first discovery-only release, checkout is disabled. A later enabled buyer quote flow still must display the full total before authorization.
- `DETAIL_ONLY`: cards omit amounts; approved details may show the complete customer price.
- `VISIBLE`: cards and details show approved customer amounts and necessary conditions/fees/taxes.

Enforce it in API serializers, public projections, CDN/cache keys, metadata/JSON-LD, media alt/copy validation and analytics properties. Disable price filters/sorts or price-derived labels that would reveal hidden amounts. A policy change increments a visibility version and purges/rebuilds affected public caches; a stale cached projection cannot bypass current policy. Check private draft/rate endpoints independently.

Supplier price input is a rate/proposal, not the retail amount. Admin-authorized pricing selects an effective contract, approved supplier rate, retail rule, tax profile, promotions and source inventory. Marketplace retail control requires supplier-authorized bounds; reseller control requires resale rights. Store mode, seller, rule/tax/agreement versions and all restricted economics privately. No blanket 5%/18% tax toggles or automatic input-credit assumptions; approved accounting rules determine classification and invoices.

Initially use fixed/approved departure prices and floors/caps. Demand tiers may later use confirmed occupancy, real booking velocity, departure proximity and approved seasonal signals. Never raise a user's amount solely because that person searched repeatedly. Price/rate changes apply to new quotes; accepted valid quotes and confirmed booking economics remain fixed. Material changes use adjustments and explicit consent.

## Selective approval and automatic publishing

Application states: `DRAFT_APPLICATION → UNDER_REVIEW → APPROVED`, with `CHANGES_REQUESTED`, `REJECTED` and `SUSPENDED` branches. Pending applicants can see/correct their own onboarding status, not create live packages.

Package revisions: `DRAFT → SUBMITTED → CHANGES_REQUESTED / APPROVED → PUBLISHED`. A published package can be paused/archived independently while preserving history. New edits create a draft/pending revision; the last approved revision remains public until a replacement is approved and atomically promoted.

| Change | Initial decision | Public effect |
| --- | --- | --- |
| New supplier | Human business verification with automated completeness/risk checks | No publication until approved |
| First package | Human content/fulfillment review | Publish only after approval and visibility eligibility |
| Later new package | Human review initially; later configured risk-based trusted-tier policy | No blanket bypass based on account age |
| Valid trusted inventory update or open/close | Automatic bounds/source/ownership/version validation | Prompt inventory refresh; no content approval delay |
| Pause/stop sales | Immediate authorized safety action | Stop new sales/hide according to policy; preserve bookings |
| Resume | Revalidate current agent/package/rate/inventory eligibility | Cannot bypass suspension or pending material review |
| Typo/formatting | Automated sanitation, field-level allowlist and audit | Publish routine revision after checks |
| New/reordered photos | Rights attestation, file/abuse checks and moderation; flags to humans | Only cleared media appears publicly |
| Route, duration, major itinerary, hotel standard, inclusion or cancellation change | Material review | Continue previous approved content until promotion |
| Supplier rate/agreement | Private commercial validation/review | Never serialize supplier costs; re-evaluate permitted retail separately |
| Retail price inside approved rules | Pricing service plus bounds/audit | New public price/version and cache refresh where visible |
| Identity, tax, ownership or bank change | Reverification and payout/booking restrictions as applicable | No autonomous approval of sensitive changes |

Do not let a free-form description bypass material-field checks: new guarantees, refund claims or fulfillment changes need semantic/manual escalation even if submitted as a typo. Trusted-tier criteria are explicit, versioned, revocable and based on actual fulfillment/moderation history.

Publication transaction: validate actor/agent eligibility and optimistic version; persist revision and moderation decision; promote `published_revision_id` if allowed; write a versioned outbox event in the same commit. The worker idempotently builds the allowlisted projection, updates index/caches and records consumption. Stale/out-of-order events cannot replace a newer revision. Public reads check active agent, current publication epoch and price-visibility policy, including after cache hits.

Suspension/withdrawal immediately blocks new holds/quotes and invalidates public eligibility. Purge caches/search/CDN and notify affected sessions via realtime invalidation or bounded polling. Do not delete historical booking snapshots. Proposed routine-update target: public refresh within one minute under healthy services, measured end to end; failures become retryable operations alerts.

## API contracts

Normalize all document examples to the actual `/api/v1` prefix and one naming scheme. Keep legacy place endpoints stable. Existing response envelope remains `{success, data, error?, meta?}`; lists use bounded cursor pagination, errors have safe stable codes, and all mutations validate version/idempotency where applicable.

| Method/path | Actor | Result |
| --- | --- | --- |
| `POST /api/v1/partners/applications` | Partner applicant | Own business draft/submission |
| `GET /api/v1/partners/me/status` | Applicant/member | Own verification status and allowed actions |
| `PATCH /api/v1/partners/me/application` | Own applicant | Requested corrections, concurrency checked |
| `GET /api/v1/partner/packages` | Approved staff | Own packages/draft/pending/public version summaries |
| `POST /api/v1/partner/packages` | Approved content role | New private draft |
| `PATCH /api/v1/partner/packages/{id}` | Owning content role | Draft update or new pending revision, not direct live mutation |
| `POST /api/v1/partner/packages/{id}/media` | Owning content role | Staged upload intent; no unchecked public URL |
| `POST /api/v1/partner/packages/{id}/submit` | Owning content role | Classification/review submission |
| `POST /api/v1/partner/packages/{id}/pause` | Owning operations/owner | Stop public eligibility/new sales |
| `POST /api/v1/partner/packages/{id}/departures` | Owning operations | Validated departure draft |
| `PATCH /api/v1/partner/departures/{id}/inventory` | Owning operations | Source-appropriate audited inventory update |
| `POST /api/v1/partner/departures/{id}/rate-proposals` | Own commercial role | Private supplier rate proposal |
| `POST /api/v1/admin/partners/{id}/decision` | Supplier reviewer | Approve/reject/request changes/suspend with reason |
| `POST /api/v1/admin/tours/{id}/revisions/{revision}/decision` | Content reviewer | Approve/promote or reject a specific revision |
| `PUT /api/v1/admin/tours/{id}/agreement` | Commercial admin | Private effective contract version |
| `PUT /api/v1/admin/departures/{id}/pricing-rules` | Pricing role | Approved versioned retail rules |
| `POST /api/v1/admin/tours/{id}/feature` | Merchandising role | Curated placement and validity |
| `GET /api/v1/tours` | Public | Approved search/cards respecting visibility and inventory truth |
| `GET /api/v1/tours/{slug}` | Public | Approved detail projection only |
| `GET /api/v1/tours/{id}/departures` | Public | Public-safe dates/status and permitted customer prices |
| `POST /api/v1/tours/{id}/inquiries` | Rate-limited visitor/customer | Contact/availability request, no booking guarantee |
| `POST /api/v1/tours/{id}/quotes` | Authorized buyer, booking enabled | Server quote and accepted policy input |
| `POST /api/v1/bookings/holds` | Authorized buyer | Atomic guaranteed hold or explicit request workflow |
| `POST /api/v1/checkout/orders` | Authorized payer | Provider order for stored quote total |
| `POST /api/v1/payments/webhooks/{provider}` | Verified provider signature | Durable deduplicated receipt |
| `GET /api/v1/bookings/{id}` | Authorized buyer/role-specific view | Own status; a public reference is not authorization |
| `GET /api/v1/partner/bookings` | Own supplier operations | Own fulfillment queue |
| `POST /api/v1/partner/bookings/{id}/confirm` | Own supplier confirmer | Supplier commitment, not fabricated paid state |
| `POST /api/v1/bookings/{id}/cancellations` | Buyer/authorized support | Versioned policy evaluation and refund request |
| `GET /api/v1/partner/payouts` | Own finance role | Payable/transfer/bank status, no platform margins |
| `GET /api/v1/admin/settlements/reconciliation` | Finance role | Exceptions and evidence-backed matching |

A composed discovery endpoint is optional; the initial React page can request place/tour adapters independently. If later added, return typed collections for places/countries/tours, not a changed legacy place object. Tour detail requests use server-owned IDs/slugs; supplier-provided IDs are SKU input only.

Errors include `PARTNER_NOT_APPROVED`, `FORBIDDEN`, `VERSION_CONFLICT`, `MATERIAL_REVIEW_REQUIRED`, `PRICE_NOT_CONFIGURED`, `INVENTORY_UNAVAILABLE`, `QUOTE_EXPIRED`, `IDEMPOTENCY_CONFLICT`, `PAYMENT_MISMATCH` and `SUPPLIER_PENDING`. Cross-supplier requests disclose no fields; use the documented 403/404 policy consistently.

## Inventory booking and money guarantees

For trusted exclusive allocation: `available = allocated_capacity - confirmed - active_unexpired_holds - blocked`, all nonnegative. Offline sales update the contractual allocation or its explicit adjustment once; do not count them twice. Lock the departure and affected hold/balance rows in a deterministic order when creating/releasing/consuming reservations or reducing capacity. Expire stale holds inside transactions as well as in scheduled jobs. Reject reduction below commitments.

Manual shared-pool reports do not create a guaranteed seat counter. Display Check availability and obtain a time-bounded supplier commitment before payment where possible. Unspecified inventory is inquiry-only. Provider stock is rechecked/held through its own approved API; a local counter cannot lock another system's inventory.

Quotes pin published content, party/occupancy, agreement/seller/tax/rate/retail versions, all charge lines, cancellation policy, currency and expiry. Keep restricted economics in a private snapshot. Repricing after expiry or supplier changes requires a new quote and buyer acceptance. Never bind a payment order to browser-supplied totals.

Persist durable operation keys scoped to actor/agent/operation, a normalized request hash and resource/result. Same key/body returns the same effect; changed body conflicts. The current optional Redis idempotency middleware is not enough for monetary operations. Use unique business constraints and persisted external-operation intents so process/queue/Redis loss cannot create duplicate captures/refunds/payouts.

Hosted checkout collects card credentials. Webhooks verify raw-body signatures/account/environment, persist event receipt before acknowledgement, and validate trusted provider order/payment/amount/currency/capture. Out-of-order callbacks fetch current provider facts. Confirm only after valid inventory/supplier commitment and verified payment. A browser success screen alone has no authority. A late capture after expiry either safely reacquires/reconfirms stock or opens a refund/remedy case; it never oversells.

Track independent payment, supplier booking, refund, payout and bank-reconciliation states. Payout submission is not bank receipt. Maintain accountant-approved balanced journals and source-action uniqueness for capture liabilities, model-specific revenue/taxes/commission/procurement, payables, fees, refunds, reserves and reversals. Refunds after payout can create supplier recoveries; do not assume automatic clawback. Reserve refundable balances/payables under locks to prevent over-refund/overpayment.

Issue the legal seller's correct invoice and applicable separate service/commission invoices; preserve numbering and credit-note evidence. Marketplace/reseller modes share public layout but have distinct private accounting. Country-specific tax, credit and withholding rules remain open until qualified review and provider approval. Never store PAN/CVV; saved provider methods, if later enabled, require explicit consent and removal controls.
