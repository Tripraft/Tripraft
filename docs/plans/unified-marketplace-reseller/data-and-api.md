# TripRaft commerce data model and API contracts

All tables, endpoints and payloads here are proposed. Use the current SQLAlchemy base, UUIDv7 helpers and Alembic chain. The source document's SQL samples are conceptual and must not be executed unchanged.

## Ownership and relationships

```text
existing User
  -> workspace_memberships -> workspaces
  -> booker/payer of bookings

supplier workspace -> suppliers -> supplier_contracts (versioned)
                                -> products -> product_places -> catalog reference
                                -> offers -> departures -> inventory_holds
                                    |           |             |
                                    +------ price_quotes ------+
                                                |
buyer workspace + existing TravelGroup -------- bookings
                                                |
                         travelers / supplier reservation / documents
                                                |
                   payment_attempts -> verified provider facts
                                                |
           journal_entries + journal_lines -> payables -> payout instructions
                                                |
                    invoices / credit notes / refunds / disputes
                                                |
                      settlement imports -> reconciliation exceptions
```

A booking has a buyer workspace and a supplier association. Those are different security scopes. Public listing does not grant access to the supplier's other bookings; trip membership does not grant payment-method or passenger-document access. Organization, personal and supplier workspaces share identity without sharing data.

## Common persistence rules

- New IDs use the existing `uuid7`/UUID column conventions. Preserve current user, trip and expense IDs. Store external provider IDs as strings with unique scoped indexes.
- Store instants in UTC using time-zone-aware timestamps; store the departure's IANA zone and local service date separately. Calendar days and booking cutoffs follow that zone.
- Money uses signed/unsigned `BIGINT` minor units as appropriate, ISO currency and a currency exponent registry. Use `Decimal` or rational arithmetic for tax/FX intermediate calculations. Define line-versus-invoice rounding in a versioned policy and allocate remainder deterministically.
- API minor-unit amounts use base-10 **strings**, avoiding JavaScript precision loss for PostgreSQL `BIGINT`. Frontend display helpers parse safely; they do not calculate authoritative payable totals. Do not change legacy expense payloads as a side effect.
- User-visible and private financial projections are separate schemas. Quotes keep a public breakdown and a protected financial snapshot. Public quotes never expose supplier cost, commission or contribution.
- Include status, created/updated timestamps, revision and appropriate tenant keys. Index actual access patterns: tenant/status/date, departure/status/expiry, provider/external ID and booking creation time.
- Foreign keys and composite constraints enforce supplier/contract/offer consistency. A UUID supplied by a caller is never accepted as proof of ownership.
- Financial records are append-only once posted. Corrections use explicit reversal/adjustment records; deletion of a user/trip does not cascade-delete bookings, journals or required invoices.
- Define field retention and redaction separately from immutable financial evidence. Restrict any encrypted raw webhook archive by purpose and short retention; retain normalized financial facts and payload hash as needed.

## Proposed tables by phase

| Phase | Tables | Important fields and constraints |
| --- | --- | --- |
| 0–1 | `catalog_releases`, `catalog_references` | Catalog namespace/release fingerprint, source entity type and ID, mapping provenance; unique source identity; no cross-database FK pretending SQLite is PostgreSQL |
| 1 | `workspaces`, `workspace_memberships`, `workspace_grants` | Kind PERSONAL/GROUP/ORGANIZATION/SUPPLIER; membership role/status; unique workspace/user; narrowly scoped guest resource grants |
| 1 | Existing `travel_groups` and expense `groups` ownership extension | Nullable workspace FK, backfill and validation before required enforcement; preserve distinct trip and expense membership rules |
| 2 | `legal_entities`, `supplier_tax_profiles` | Legal seller/invoice identity, country, effective tax profile, evidence reference; approval status and effective dates |
| 2 | `suppliers`, `supplier_verifications`, `supplier_beneficiaries` | Supplier workspace, business details, verification history; provider account/beneficiary tokens, masked bank details, bank-change version and verification |
| 2 | `supplier_contracts`, `supplier_contract_versions` | Supplier, sale model, currency, legal seller, inclusivity, pricing authority, commission/net-cost terms, cancellation liability, allocation and payout milestones; signed evidence and effective dates |
| 3 | `products`, `product_places`, `product_media` | Supplier-owned descriptive package; inclusions, itinerary, licensed media; stable catalog references; no operational seat count on places |
| 3 | `offers`, `offer_versions` | Product/contract version, immutable sale model, seller, policy version, publication review/status, rate plan, traveler bands and public terms |
| 3 | `departures`, `inventory_events` | Offer, start/cutoff/zone, capacity/allotment, confirmed/held counts, version, source mode, confirmation mode, blackout and last verification; audited capacity deltas |
| 4 | `supplier_rate_versions`, `tax_rule_versions`, `price_rule_versions` | Effective approved rules, base/commission and inclusivity, constraints, applicability, evidence/approver; preserve old versions |
| 4 | `price_quotes`, `quote_lines`, `quote_acceptances` | Actor/buyer scope, departure/party, immutable public and private snapshots, total/currency, all source versions, expiry, accepted terms and consent; one acceptance event per accepted quote |
| 4 | `inventory_holds` | Departure/quote, seat count, active/confirmed/released/expired status, expiry and operation key; one consumption per hold |
| 4 | `bookings`, `booking_travelers`, `booking_events` | Booker, payer, buyer workspace, supplier, optional existing group trip ID; immutable economics, state/revision, required passenger fields and append-only transitions |
| 4 | `supplier_reservations` | Booking, local/provider reservation ID, acceptance/expiry, quantity and confirmation evidence; distinct from local hold |
| 4 | `commerce_operations` | Actor/tenant/operation/idempotency key, request hash, processing state, resource/result reference, external request correlation; unique scope/key |
| 5 | `payment_attempts`, `payment_facts` | Booking, server expected total, provider order/payment IDs, attempt state, verified amount/currency, verification timestamp and normalized provider evidence |
| 5 | `webhook_inbox`, `outbox_events`, `event_consumptions` | Provider event uniqueness, raw hash/signature result, processing attempts; domain event sequence, retry time, unique consumer/event consumption |
| 5 | `ledger_accounts`, `journal_entries`, `journal_lines` | Currency, legal entity, booking/supplier refs, event uniqueness, debit/credit amounts, posting template/version; balanced posting and immutable posted journals |
| 6 | `booking_documents`, `document_grants`, `support_cases`, `support_case_events` | Private storage keys, issuer/version, audience, retention, case SLA/reason/status and audited access |
| 7 | `supplier_payables`, `payable_milestones`, `payout_instructions`, `payout_events` | Liability separate from movement; amount/currency, beneficiary version, approval, provider transfer ID, settlement reference/UTR, reversal and matching evidence |
| 7 | `cancellation_requests`, `refunds`, `refund_allocations`, `disputes` | Traveler/item-level quantity, policy snapshot, refund cap, provider refund ID, fee/tax allocation, supplier recovery and dispute outcome |
| 7 | `invoices`, `invoice_lines`, `invoice_sequences`, `credit_notes` | Seller/recipient, financial period, immutable number, taxes, jurisdiction and source booking; unique issuer/series/period/number; correction links |
| 7 | `settlement_imports`, `settlement_lines`, `bank_statement_lines`, `reconciliation_matches`, `reconciliation_exceptions` | Source hash/line uniqueness, provider and bank references, gross/net/fees/taxes, amount/currency, allocation and match reason |
| 7 | `supplier_recoveries`, `reserve_allocations` | Amount owed after refunds or reversals, reserve purpose and release conditions; do not represent unrestricted spendable cash |
| 1 onward | `commerce_audit_events`, `notification_deliveries` | Actor/workspace/tenant, target, action, reason, request ID, redacted diff, delivery attempts; integrate existing notifications rather than replace trip feed |
| 9 | `promotions`, `promotion_redemptions`, `pricing_decisions`, `stored_payment_methods`, `supplier_connections`, `supplier_sync_runs` | Funding split, eligibility and usage locks; actual demand inputs; provider-only payment token and consent; connector freshness/capabilities |
| 10 | `organizations`, `organization_memberships`, `cost_centers`, `travel_policies`, `travel_requests`, `approval_steps`, `budget_reservations` | Reuse workspaces; approval/policy revisions, employee/trip ownership, currency and budget commitment; prevent self-approval and expired-quote booking |
| 11 | `ai_proposals`, `ai_tool_actions`, `intelligence_source_checks` | Extend existing AI consent/logs; authorized scope, proposal hash, source provenance, outcome, evaluation and cost |

Combine closely related tables where a phase does not need independent lifecycle/history, but preserve every invariant. This is a logical schema, not a direction to create all tables at once.

### Catalog references

Use `(catalog_namespace, entity_type, source_id)` as durable identity, plus a release/fingerprint on the mapping/evidence. A release version change does not automatically create a different physical place. Preserve previous mappings and detect reused IDs. Package and itinerary links refer to this registry, allowing current SQLite readers to remain active during reconciliation. Replicated search content is a derived read model with source provenance and refresh status.

### Capacity constraints

For an exclusive allotment:

```text
capacity >= 0
confirmed_seats >= 0
held_seats >= 0
confirmed_seats + held_seats <= capacity
available = capacity - confirmed_seats - held_seats
```

Counters and active hold rows must agree transactionally. Expiry is not just a UI countdown. Reconcile expired rows inside reservation transactions as well as through scheduled jobs. Capacity reduction below committed quantities returns a conflict and an operations task.

For supplier-manual inventory, `remaining` is null unless a real allocation exists. A local request row records interest and workflow, not exclusive inventory ownership. For provider inventory, record provider reservation tokens and enforce provider validity; a local counter cannot reserve stock sold elsewhere.

### Immutable price snapshot

Persist sale model, contract and seller identity, rate/tax/rule versions, traveler composition, cancellation policy version, source/checked time, charge currency/exponent, quote expiry and every component. Keep supplier payable, commission, credit eligibility and contribution in the restricted snapshot.

```json
{
  "quote_id": "<uuid>",
  "departure_id": "<uuid>",
  "sale_model": "MARKETPLACE",
  "seller": {"id": "<uuid>", "display_name": "Verified operator"},
  "party": {"adults": 2, "children": 0},
  "money": {"currency": "INR", "exponent": 2},
  "lines": [
    {"kind": "PACKAGE_BASE", "amount_minor": "2800000"},
    {"kind": "PACKAGE_TAX", "amount_minor": "0"},
    {"kind": "SERVICE_FEE", "amount_minor": "0"},
    {"kind": "SERVICE_TAX", "amount_minor": "0"},
    {"kind": "DISCOUNT", "amount_minor": "0"}
  ],
  "total_minor": "2800000",
  "pricing_status": "SANDBOX_ONLY",
  "tax_rule_version": "sandbox-fixture-not-production",
  "cancellation_policy_version": "<version>",
  "confirmation_mode": "REQUEST_TO_BOOK",
  "source_checked_at": "2026-10-17T12:00:00Z",
  "expires_at": "2026-10-17T12:10:00Z"
}
```

The payload illustrates shape, not valid tax treatment or commercial prices. Sandbox quotes cannot create live provider orders. Production tax lines come from approved rules, not the example's zero values.

Database enforcement prevents updates to accepted price/contract snapshots; acceptance metadata lives separately. Public drafts can be superseded but never silently edited into a different accepted price. Booking changes create adjustment quotes and fresh consent. At checkout, expiry or a mandatory provider price change yields `QUOTE_EXPIRED`/`PRICE_CHANGED` and a replacement quote requiring acceptance.

## Marketplace and reseller finance

| Concern | MARKETPLACE | RESELLER |
| --- | --- | --- |
| Customer seller | Operator named by offer contract | TripRaft legal entity |
| Customer tour invoice | Operator-issued or authorized issuance on its behalf | TripRaft-issued |
| TripRaft revenue model | Commission and justified separately sold services, excluding collected tax | Customer sale excluding tax; supplier procurement cost tracked separately |
| Supplier amount | Contractual settlement less valid commission/adjustments | Contractual B2B procurement payable |
| Commission tax | Separate approved commission service treatment | Do not invent a commission in addition to an already agreed resale margin |
| Input tax | Evidence-based policy; not implied by UI | Supplier tax is creditable only when approved and supported by invoice evidence |
| Refund | Model-aware liability/fee/tax allocation | TripRaft seller obligation and supplier recovery policy |
| Funds flow | Provider-approved marketplace structure | Approved merchant/vendor structure |

Do not hardcode the source's illustrative 5% tour tax or 18% commission tax as universal rules. Store inclusive/exclusive status per priced supply. Inclusive extraction uses exact arithmetic and the approved rounding policy; never add the same tax twice. Withholding/TCS/TDS, where determined applicable, belong in explicit liability/credit records rather than platform revenue.

### Journal design

Prepare accountant-approved posting templates for each sale model and legal entity. Engineering enforces double-entry and source-event uniqueness; finance determines account classification and revenue recognition timing.

At capture, a generic operational template debits processor receivable and credits customer booking liability for the same amount. When performance/recognition conditions are met, reclassify the liability using the approved model-specific template into supplier payable, tax liabilities, deferred/recognized platform revenue and any explicit fees. A confirmed booking does not automatically mean all revenue is earned. Record processor fees and settlement deductions separately.

Provider-to-bank settlement reclassifies processor receivable to bank cash, reconciling fees and timing differences. A supplier payout instruction alone does not clear payable as a completed bank transfer; use clearing/in-transit accounts until validated provider/bank evidence supports the final posting. Reversals create compensating entries. Refunds after payout may create supplier receivables/recoveries and reserve movements.

Requirements:

- Each posted journal balances in one currency and legal entity. Cross-currency operations require explicit FX clearing entries and are outside the pilot.
- One journal per posting type and source event/business action. Duplicate webhook delivery cannot produce duplicate journals.
- Posting and related local state updates commit atomically. Enforce immutability, closed periods and balanced posting using transaction-level checks plus database protection/constraints appropriate to cross-row totals.
- Sum of successful/pending reserved refunds cannot exceed refundable captured funds. Lock the relevant balance before reserving a partial refund.
- Supplier payout reservations cannot exceed payable minus prior disbursements, active refund liabilities, contractual reserves and approved deductions. Also check provider funds availability.
- Every invoice, refund, payable and payout can be traced to booking, quote, contract version, seller, provider evidence and journal.

## State machines and workflow

Keep inventory, supplier reservation, payment, booking, refund and payout states separate. UI status is a projection of these facts, not a single overloaded payment label.

| Aggregate | States and guarded transitions |
| --- | --- |
| Booking | DRAFT → QUOTED → HELD or SUPPLIER_PENDING → AWAITING_PAYMENT → PAID_PENDING_SUPPLY or CONFIRMED → FULFILLED; EXPIRED/REJECTED/CANCELLED branches |
| Local hold | ACTIVE → CONFIRMED / RELEASED / EXPIRED, exactly once |
| Supplier reservation | REQUESTED → ACCEPTED / REJECTED / EXPIRED; ACCEPTED → CONFIRMED / CANCELLED; provider-specific uncertainty requires reconciliation |
| Payment attempt | CREATED → PENDING / AUTHORIZED → CAPTURED; FAILED/CANCELLED; reversed capture is a separate fact |
| Refund | REQUESTED → POLICY_APPROVED → SUBMITTED → PROCESSING → SUCCEEDED; REJECTED/FAILED with controlled retry |
| Payout | SCHEDULED → APPROVED → SUBMITTED → PROCESSING → PROVIDER_SETTLED → BANK_RECONCILED; FAILED/REVERSED branches |
| Support dispute | OPEN → INVESTIGATING → RESOLUTION_PENDING → RESOLVED; reopening audited |

Refund and dispute state remain visible after cancellation/fulfillment; a partially refunded booking is not simply `REFUNDED` with lost traveler details. Transitions validate role, prior revision, quantity, payment facts and supplier commitment. Record actor, reason and correlation ID for every transition.

### Allocated booking sequence

1. Read approved offer/contract and current availability; issue quote with source/rule versions.
2. In PostgreSQL, scope buyer, claim durable operation key, lock departure, expire eligible holds and validate quote/cutoff/quantity. Create hold and draft booking, increment held count and write inventory/outbox events in one commit.
3. Persist payment-order intent. Release locks, call gateway with deterministic correlation/idempotency where supported, then persist result. An uncertain external timeout becomes reconciliation work, not an automatic new order.
4. Hosted checkout completes; browser result page polls the authorized booking projection.
5. Verify and store webhook durably. Fetch provider state and validate order, booking, exact amount, currency, account/environment and captured state.
6. Lock in a consistent order: departure, hold, booking, then financial balance rows. Recheck expiry, quantity and supplier allocation. Confirm/consume hold once; record payment and balanced journal using shared transactional services. Mark booking confirmed only when all gates pass.
7. Commit outbox events. Generate confirmation/voucher and notifications idempotently. Schedule payout only under approved contract and funds policy.

External supplier confirmation may require a durable saga between steps rather than one transaction. Never keep PostgreSQL inventory locks open while waiting for a supplier/gateway network response.

### Manual request-to-book sequence

1. Traveler submits party, desired departure and displayed terms; create a pending request with an SLA, not a guaranteed local hold.
2. Supplier accepts with a real reservation reference, quantity, agreed price and expiry. An email click requires authenticated/one-time narrowly scoped authorization; a public URL alone cannot accept arbitrary bookings.
3. Reissue/revalidate quote if the initial quote expired during supplier response. Traveler explicitly accepts changes and pays before supplier commitment expires.
4. Verify capture and confirm against the still-valid supplier commitment. If it expires before payment success, revalidate supply or trigger refund/remedy with a visible pending state.
5. Supplier rejection/timeouts notify the traveler. No confirmed voucher is issued. A separately approved capture-before-acceptance variant must automatically initiate and reconcile refunds on rejection.

### Expiry and late capture

The expirer and payment completion use the same lock order and active-hold transition check. On late capture, atomically reacquire allocatable stock if possible, or attempt provider/supplier reconfirmation. If unavailable, retain the captured payment fact, keep the booking unconfirmed and create an idempotent refund/remediation case. Never discard a paid event because its hold expired.

### Durable idempotency and event delivery

Require `Idempotency-Key` for commerce mutations. Scope it to authenticated actor, tenant, operation and route/resource; hash the normalized request body. Same key/body returns the same resource/result; same key/different body returns `409 IDEMPOTENCY_CONFLICT`. Persist keys/results with business records in PostgreSQL. Do not allow Redis failure to bypass this requirement.

Persist external operation intents before network calls. Where a provider lacks idempotency support, query by known correlation/order reference and resolve ambiguity before retry. Enforce business uniqueness even when a client invents a new key. Multiple payment attempts are allowed, but multiple successful charges for one full-payment booking create an overpayment exception and controlled refund rather than a second confirmation.

For webhooks, verify the raw body and endpoint-specific signature before mutation. Deduplicate using `(provider, account, environment, external_event_id)` where supplied; document a safe provider-specific fallback when absent. Store receipt before acknowledgement. If DB persistence fails, return retryable failure. Workers use retry limits, dead-letter state and authenticated operator replay. Webhook arrival order does not define financial truth; fetch provider state and apply aggregate-specific legal transitions, including reversals.

Outbox consumers are at-least-once and idempotent. A transaction writes domain changes plus outbox rows; dispatch leases rows, delivers and marks progress. Recovery polls persisted rows after queue loss. Event payloads contain reference IDs and necessary non-sensitive facts; workers load authorized records directly.

## API conventions

Use the existing `/api/v1` prefix. Blueprint examples beginning `/v1` are adapted to the actual project. Keep the existing `{success, data, error, meta}` envelope and add explicit schemas. New list endpoints use bounded cursor pagination. Mutation errors include a stable code and safe message. Never return provider secrets or private pricing in generic error details.

| Method and path | Actor | Outcome |
| --- | --- | --- |
| `GET /api/v1/workspaces` | Signed-in user | Own memberships and capabilities |
| `POST /api/v1/workspaces` | Authorized account | Create allowed workspace kind |
| `POST /api/v1/partners/applications` | Signed-in applicant | Supplier onboarding draft |
| `GET /api/v1/partners/{supplier_id}` | Own supplier staff | Verification and profile projection |
| `POST /api/v1/partners/{supplier_id}/contracts` | Supplier owner | Submit versioned terms for approval |
| `POST /api/v1/partners/{supplier_id}/products` | Product manager | Draft product |
| `POST /api/v1/partners/{supplier_id}/offers` | Product manager | Draft contractual offer |
| `POST /api/v1/partners/offers/{offer_id}/submit` | Own supplier manager | Publication review request |
| `POST /api/v1/partners/offers/{offer_id}/departures` | Own supplier inventory manager | Validated departure |
| `PATCH /api/v1/partners/departures/{departure_id}` | Own supplier inventory manager | Version-checked capacity/rate revision; cannot mutate accepted quotes |
| `GET /api/v1/offers` | Public | Reviewed public search, currency and source freshness |
| `GET /api/v1/offers/{offer_id}` | Public | Public offer/seller/terms/media projection |
| `GET /api/v1/offers/{offer_id}/departures` | Public | Availability classifications; unknown exact count stays null |
| `POST /api/v1/checkout/quotes` | Buyer | Server-calculated immutable quote |
| `POST /api/v1/checkout/holds` | Buyer | Allocated hold and draft booking, or provider-backed reservation |
| `POST /api/v1/bookings/requests` | Buyer | Manual supplier request, no invented hold |
| `POST /api/v1/checkout/orders` | Authorized payer | Gateway order from accepted quote/booking |
| `POST /api/v1/webhooks/payments/{provider}` | Signature-authenticated provider | Durable receipt; no cookie auth required |
| `GET /api/v1/bookings` | Buyer | Own scoped bookings |
| `GET /api/v1/bookings/{booking_id}` | Buyer or explicit grant | Authorized view; state timeline |
| `POST /api/v1/bookings/{booking_id}/trip-link` | Buyer plus trip booking capability | Attach booking summary to existing group trip |
| `POST /api/v1/partners/bookings/{booking_id}/accept` | Own supplier confirmer | Supplier commitment with expiry/reference |
| `POST /api/v1/partners/bookings/{booking_id}/reject` | Own supplier confirmer | Rejection and compensation workflow if charged |
| `GET /api/v1/partners/{supplier_id}/bookings` | Own supplier staff | Fulfillment queue, minimal necessary passenger data |
| `GET /api/v1/partners/bookings/{booking_id}/manifest` | Manifest capability | Audited manifest projection/download |
| `GET /api/v1/bookings/{booking_id}/documents` | Document grant | Metadata and short-lived authorized access |
| `POST /api/v1/bookings/{booking_id}/cancellations` | Buyer or authorized support | Policy evaluation and cancellation request |
| `GET /api/v1/bookings/{booking_id}/refunds` | Buyer | Safe refund status, no supplier margin |
| `GET /api/v1/partners/{supplier_id}/payouts` | Own supplier finance role | Payable/payout state and masked references |
| `POST /api/v1/admin/suppliers/{supplier_id}/review` | Supplier reviewer | Approve/reject/freeze with reason |
| `POST /api/v1/admin/offers/{offer_id}/review` | Listing reviewer | Publication decision |
| `POST /api/v1/admin/refunds/{refund_id}/approve` | Finance approver | Approved refund execution intent |
| `POST /api/v1/admin/payouts/{payout_id}/approve` | Finance approver | Approved payout intent; separation of duties |
| `GET /api/v1/admin/reconciliation` | Finance/reconciliation role | Unmatched provider/bank records and exception aging |
| `POST /api/v1/admin/reconciliation/{exception_id}/resolve` | Reconciliation role | Evidence-backed match/adjustment with audit |
| `GET /api/v1/admin/finance/bookings/{booking_id}/trace` | Finance investigator | Quote-to-bank journal trace |
| `POST /api/v1/bookings/{booking_id}/support-cases` | Buyer or assigned operator | Track assistance/dispute case |

Future phase endpoints add promotion administration, provider token list/removal, licensed supplier webhooks, corporate requests/approvals and previewed AI actions. They need separate operation schemas when enabled; do not expose placeholder mutation endpoints.

### Representative requests

```json
{
  "departure_id": "<uuid>",
  "buyer_workspace_id": "<uuid>",
  "party": {"adults": 2, "children": 0},
  "charge_currency": "INR"
}
```

This quote request has no trusted price, tax, commission, supplier cost or seller field. Backend resolves and validates those values.

```json
{
  "quote_id": "<uuid>",
  "accepted_terms_version": "<version>",
  "payer_user_id": "<uuid>",
  "group_trip_id": null
}
```

This reservation request requires actor-to-payer and workspace authorization. A payer cannot be assigned merely by submitting another user's UUID. Travelers and seat quantities remain separate from trip member count.

Errors: `INVENTORY_UNAVAILABLE`, `QUOTE_EXPIRED`, `PRICE_CHANGED`, `SUPPLIER_PENDING`, `SUPPLIER_REJECTED`, `PAYMENT_PENDING`, `PAYMENT_MISMATCH`, `REFUND_PENDING`, `PAYOUT_BLOCKED`, `VERSION_CONFLICT`, `IDEMPOTENCY_CONFLICT`, `FORBIDDEN`. Use HTTP 409 for business/version conflicts, 422 for invalid fields, 401/403 for account/capability failures, and safe 404 handling where existence itself is private.

## Migration strategy

1. Audit actual Alembic heads and branch state. Add small additive revisions; do not copy fabricated revision IDs from this plan.
2. Register new models in migration environment and startup import registry. Startup continues to validate schema; it must not run `create_all` against production.
3. Add nullable ownership keys and new tables, deploy compatible readers/writers, then run restartable ownership backfills in bounded batches. Ambiguous existing groups go to a review report rather than being assigned to an arbitrary tenant.
4. Validate foreign keys, orphan records, catalog references and row counts. Enforce required ownership only after all active code paths populate it and access tests pass.
5. Add PostgreSQL constraints, indexes, journal immutability and scoped row access. If using row-level security, set transaction-local actor/tenant context, separate privileged workers, test pooling reset and cross-party booking projections. Repository authorization remains mandatory.
6. Legacy SQLite development remains usable with commerce disabled. Isolate PostgreSQL-only DDL by dialect; run the authoritative commerce concurrency and financial tests on PostgreSQL. Update disposable schema export to use a supported dialect when new models require it.
7. Back up and rehearse restore before each operational migration. Rollback normally disables new writes/flags and runs a backward-compatible application; after paid records exist, never drop financial tables as a rollback shortcut.
