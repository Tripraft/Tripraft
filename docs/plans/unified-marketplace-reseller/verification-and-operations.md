# TripRaft verification operations and launch gates

This document defines future implementation acceptance, not test results from this planning task. Targets are proposed until measured. Correct inventory, money and permissions are hard invariants; latency and conversion are operating objectives.

## Test strategy

Preserve existing auth, CSRF, invitations, trip membership, polls/chat, expense balances and money-integrity tests. Add pure calculation/transition tests, service/API authorization tests, real PostgreSQL transaction tests, provider sandbox contract tests and a small number of browser journeys. Do not treat a SQLite-only concurrency test as evidence of PostgreSQL row-lock behavior.

The existing `services/api/tests/conftest.py` assigns a temporary SQLite URL before imports. A new PostgreSQL suite under that directory inherits the file. Refactor the fixture into explicit isolated modes, or place PostgreSQL tests outside that conftest tree; setting an environment variable in CI alone will not override the current assignment. Use a dedicated database per test run and reject non-test connection targets.

### Required acceptance and failure cases

| Area | Scenario | Required result | Phase |
| --- | --- | --- | --- |
| Migration | Fresh database and upgrade from current head | Required models/constraints registered; existing IDs/rows preserved | 1 onward |
| Catalog | Same numeric place ID in different sources | Namespace prevents collision; source evidence retained | 0–3 |
| Catalog | Default catalog absent/empty | Explicit unavailable/degraded response; no silent destructive seeding | 0–3 |
| Ownership | Backfill stops midway and restarts | No duplicate tenants/memberships or altered balances | 1 |
| Tenant scope | User guesses another workspace/supplier/booking ID | No private disclosure; 403 or safe 404; no side effect | Every phase |
| Membership | Suspended user or changed role with cached UI | Backend rejects action immediately | 1 onward |
| Documents | Group member requests another passenger's private document | Denied unless explicit document grant exists | 1, 6 |
| Publication | Supplier self-approves or changes published sale model | Rejected; new reviewed version/offer required | 2–3 |
| Bank change | Verified supplier edits beneficiary | New verification/approval required; pending payouts blocked or rebound under controlled review | 2, 7 |
| Inventory | Two independent connections race for last seat | Exactly one active hold; other gets unavailable | 4 |
| Inventory | Hold creation commits but HTTP response is lost | Same key/body returns same reservation | 4 |
| Idempotency | Same key used with different quantity/quote | 409 conflict; no second action | 4 |
| Idempotency | Redis unavailable or worker restarts | PostgreSQL operations and uniqueness still prevent duplicate money actions | 4–7 |
| Inventory | Expirer races capture/confirmation | One legal hold transition; no negative counter/oversell | 4–5 |
| Inventory | Supplier reduces capacity below commitments | Conflict and remediation path, no silent deletion | 3–4 |
| Manual supply | Operator sells offline without an allotment | Request-to-book, unknown exact seats, no instant guarantee | 3–6 |
| Supplier | Request rejected or acceptance SLA expires | Pending/rejected UI; no voucher; refund/remedy if captured | 4–7 |
| Quote | Supplier rate/tax rule changes after acceptance | Accepted economics remain fixed; adjustment requires fresh consent | 4 |
| Quote | Quote expires while supplier decides | Requote and acceptance; no stale-order payment | 4–5 |
| Pricing | User refreshes/searches 20 times | No user-specific punitive increase; valid quote lock preserved | 4, 9 |
| Taxes | Inclusive versus exclusive and mixed fee fixtures | Exact minor-unit totals; no double tax; correct issuer/model | 4, 7 |
| Rounding | Multiple traveler bands, discounts, partial refunds | Deterministic rounding and allocated remainders; sum matches quote/invoice | 4, 7 |
| Frontend money | Amount exceeds JS safe integer range | String/BigInt handling or explicit validation; no silent precision loss | 1, 4 |
| Gateway | Browser forges success | No paid/confirmed transition | 5 |
| Webhooks | Invalid signature or changed body | Rejected; no trusted state mutation | 5 |
| Webhooks | Duplicate or out-of-order events | One business effect; current provider facts reconciled; stale events cannot regress capture | 5 |
| Webhooks | Valid receipt but queue publish fails | Inbox/outbox polling recovers durable event | 5 |
| Webhooks | Database fails before receipt commit | Retryable provider response; event not acknowledged as durable | 5 |
| Payment | Captured amount/currency/order/account mismatch | Exception; booking unconfirmed and payout blocked | 5 |
| Payment | Gateway order request times out after creation | Correlation lookup/reconciliation; no blind second charge/order | 5 |
| Payment | Customer closes tab after successful capture | Server-side processing completes; returning user sees authoritative status | 5–6 |
| Payment | Two attempts both capture for one booking | One booking confirmation; overpayment exception and controlled refund | 5–7 |
| Late payment | Captured after hold/commitment expires | Reacquire/reconfirm safely or refund; never oversell | 5 |
| Journal | Duplicate source event or worker crash on posting | One balanced posting; atomic local state | 5–7 |
| Journal | Posted record edited/deleted or unbalanced total | Database/service protections reject it; adjustment path exists | 5–7 |
| Confirmation | Paid but supplier not committed | Visible pending state; no fake confirmation/voucher | 5–6 |
| Trip linkage | Another trip member views booking summary | Only permitted status/public information, no net rate/card/passport fields | 6 |
| Expenses | Confirmed purchase imported twice | One explicit expense proposal/action; existing traveler balances remain correct | 6 |
| Refund | Cancel two of five travelers | Correct item/quantity/policy/tax allocation and remaining seats | 7 |
| Refund | Concurrent partial refunds | Total reserved/succeeded refunds never exceeds refundable capture | 7 |
| Refund | Refund response lost and job retries | Same provider operation/result, one customer refund | 7 |
| Recovery | Refund after supplier already paid | Supplier receivable/reserve/recovery plus correct customer refund | 7 |
| Payout | API accepts transfer instruction | UI says submitted/processing, not received in bank | 7 |
| Payout | Worker dies after external transfer before local acknowledgement | Provider lookup resolves; no duplicate payout | 7 |
| Payout | Provider success followed by bank reversal | Reversal recorded; cash/payable clearing corrected; exception visible | 7 |
| Reconciliation | Statement imported/replayed twice | No duplicate line/journal; explicit matched/unmatched states | 7 |
| Invoices | Parallel issuance or re-download | Unique legal numbering; same issued document; changes use credit/adjustment | 7 |
| Reseller | Tax-inclusive sale with eligible/ineligible input-credit fixtures | Correct separately approved journals; credit never assumed from supplier tax alone | 7, 9 |
| Saved method | Consent off/removal requested | No reusable token stored; removal ownership checked | 9 |
| AI | Supplier text/page contains hostile instructions | Treated as untrusted data; no unauthorized tool execution | 6, 11 |
| AI | Agent requests charge/refund/payout without approved scope | Rejected before external action | 6, 11 |
| Organization | Employee approves own exception or approval uses expired quote | Denied/reapproval required | 10 |
| Intelligence | Coordinates/hours/provider freshness missing | Explicit partial/degraded result; no fabricated route/availability | 9, 11 |
| Disaster recovery | Restore staging backup and replay pending events | Inventory/journals consistent; pending provider operations reconciled once | 8 |

### Browser journeys

1. Organizer creates a trip, compares an approved package, selects an allocated departure, accepts full total/terms, completes hosted sandbox checkout, sees confirmed voucher and permitted group summary.
2. Manual supplier receives a request on a phone, accepts with commitment expiry, traveler pays a fresh quote, operator sees a limited manifest and payout schedule. Repeat with rejection and timeout.
3. Traveler requests partial cancellation; support/finance approves policy result; one refund is reconciled, invoice adjustment is visible and supplier recovery is tracked if previously paid.
4. Two supplier users and two company users attempt cross-scope URLs, documents, caches and realtime subscriptions; private content never appears.
5. Employee submits company travel, independent approver approves within policy, checkout revalidates amount and finance sees scoped invoice/report.

Introduce a browser runner such as Playwright with explicit workspace scripts, fixtures and CI configuration when these flows exist. It is proposed tooling, not already installed by this plan.

## CI and validation

Current repository checks are `pnpm structure:check`, `pnpm lint`, `pnpm typecheck`, `pnpm test`, `pnpm build`, or aggregated `pnpm verify`. These cover current behavior only; new commerce suites must be added to actual task discovery.

Add the following required CI jobs in canonical `infra/github/workflows/ci.yml` and synchronize discovery copies:

| Job | Validation |
| --- | --- |
| Existing regressions | Existing backend/frontend tests and full monorepo checks |
| Commerce contracts | Explicit request/response/error validation; generated client drift; public/private projection tests |
| PostgreSQL migrations | Fresh head, upgrade from previous application release, ownership backfill/restart, metadata drift and financial constraints |
| PostgreSQL race/recovery | Multiple independent connections/processes for contention, expiry/capture, refund/payout reservation and event crash boundaries |
| Frontend typed features | Include all new TS/TSX, exact money display and cross-workspace cache invalidation |
| Browser acceptance | Critical journeys against isolated fake-provider service; no real credentials or money |
| Provider sandbox | Separately gated scheduled/pre-release checks for selected API version, signature fixtures and order/refund behavior |
| Security/quality | Secret detection, dependency review, permissions, redacted logs and upload validation |

Run OpenAPI export and `pnpm api:generate` after route/schema changes. The current exporter uses a migrated disposable SQLite database. If a new PostgreSQL-only feature prevents that, deliberately move contract export to an isolated PostgreSQL database rather than skipping schema validation. Never open personal application data for code generation.

## Deployment and configuration

Maintain isolated development, staging and production accounts, databases, object storage and provider/webhook secrets. No test/live provider object can be matched across environments. Settings are validated at startup; required commerce workers and dependencies fail readiness when enabled and unavailable.

Suggested configuration names, to be implemented in `core/config.py` and example files:

```text
COMMERCE_ENABLED
COMMERCE_LIVE_CHECKOUT_ENABLED
COMMERCE_ALLOWED_SALE_MODELS
COMMERCE_PAYMENT_PROVIDER
COMMERCE_PROVIDER_ENVIRONMENT
COMMERCE_CHARGE_CURRENCIES
COMMERCE_HOLD_TTL_SECONDS
COMMERCE_SUPPLIER_ACCEPTANCE_TIMEOUT_SECONDS
COMMERCE_PAYOUTS_ENABLED
COMMERCE_DYNAMIC_PRICING_ENABLED
COMMERCE_SAVED_METHODS_ENABLED
COMMERCE_EXTERNAL_BOOKING_ENABLED
COMMERCE_STORAGE_BUCKET
COMMERCE_DOCUMENT_URL_TTL_SECONDS
```

Provider credentials/webhook signing secrets belong in a secret manager or ignored local configuration. The approval records for seller/provider/tax policy are durable controlled records, not merely environment booleans. A frontend flag cannot enable blocked backend capability. Offer approval, supplier suspension and live-money pause are separately enforced controls.

Deployment components:

- React static web/admin hosting with TLS, supported origins and correct API proxy/cookie settings.
- Flask API with isolated provider credentials, connection pooling and primary database writes. Preserve authenticated realtime scope.
- Managed PostgreSQL backups and point-in-time recovery where selected; catalog version backups and private object-storage retention.
- Redis for broker/cache with monitored persistence/availability as appropriate; durable inbox/outbox survives Redis loss.
- Commerce workers with retry/time limits and a single effective periodic scheduler. Deploy beat explicitly; schedule definitions alone do not run jobs.
- Private object storage with authorized signed URL issuance, upload MIME/size validation, scanning/quarantine and license/retention metadata.
- Central logs/metrics/traces, alert routing and protected admin access.

Choose hosting provider and implement Terraform only after requirements and budget are approved. Do not interpret the existing `infra/terraform` reservation as provisioned infrastructure. Update the launcher/Compose so enabling local commerce starts/checks PostgreSQL and the necessary worker/scheduler; SQLite-only planner mode stays supported.

## Background work and recovery

| Task | Initial cadence proposal | Recovery guarantee |
| --- | --- | --- |
| Hold expiry | Every 15–30 seconds plus transactional expiry at reservation | Lease/batch-safe; transition once under same locks |
| Inbox/outbox processing | Continuous with recovery scan every 15–30 seconds | Retry persisted rows, deduplicate each consumer |
| Pending payment recheck | Every 1–5 minutes within provider limits | Correlate known order; no duplicate order creation |
| Supplier SLA escalation | Every minute during operating coverage | One actionable escalation, no false confirmation |
| Eligible payout evaluation | Scheduled milestones and controlled periodic scan | Lock/reserve payable; check provider approval/funds |
| Refund/payout status polling | Provider-specific bounded cadence | Preserve uncertainty and reconcile before retry |
| Settlement reconciliation | At least daily and after settlement files arrive | Unique source lines; exceptions owned and aged |
| Inventory counter audit | Regular background scan and incident-triggered | Compare events/holds; freeze inconsistent sales, repair under audit |
| Supplier sync | Provider-specific events plus catch-up polling | Staleness downgrades availability and booking eligibility |
| Retention | Daily, by data class/legal hold | Redact eligible personal data without erasing required financial records |

Cadences are tunable proposals. Use leases or database locks so multiple schedulers/workers do not execute non-idempotent actions twice. Persist retry counts, last error, next retry and responsible operator. Operational replay is authenticated and audited; never directly change status in SQL to clear an alert.

## Dashboards and alerts

Track correlation/request ID, booking/quote/hold/supplier IDs, actor/workspace, event ID, provider order/payment/transfer/refund IDs, inventory/rule version and source freshness. Do not log raw passenger documents, full card data, payment tokens, secret signatures or unredacted webhook/customer payloads.

| Dashboard | Metrics |
| --- | --- |
| Funnel | Search → quote → hold/request → payment → confirmed → fulfilled, by supplier/channel and new/repeat buyer |
| Inventory/supply | Hold expiry, remaining allocation, stale sync, acceptance latency, supplier rejection/cancellation, overbooking count |
| Money | Captured value, GMV, recognized/deferred revenue excl. tax, supplier liabilities, processor fees, tax, payout/refund/reserve/recovery balances |
| Reconciliation | Unmatched/aged provider settlements, orphan capture, bank reference mismatch, reversals, failed refunds and stale payouts |
| Economics | Contribution after direct costs, discounts by funder, CAC, repeat/referral mix, gateway/support/refund loss and supplier performance |
| Reliability | API p95/error rate, job lag/retries/dead letters, inbox/outbox age, database contention and restore status |
| AI/content | Cost per itinerary, groundedness, unauthorized attempts, retrieval/source freshness, missing coordinates/hours and photo rights |

Proposed initial service objectives from the source: controlled-inventory lookup p95 below 2 seconds; checkout API p95 below 3 seconds excluding external redirect; critical endpoint availability objective 99.9%; reconciliation at least daily. Benchmark in staging and set alert thresholds from evidence. A fast API is not acceptable if it creates inconsistent money or inventory.

Page an assigned operator for captured money with no valid supply, inventory invariant failure, duplicate financial posting, unauthorized finance action, payout to an unverified beneficiary or unexplained financial mismatch. Alert on stale pending states, queue backlog, sync failure, unusual refunds, reserve shortfall and repeated supplier SLA breaches. Every alert links to a scoped trace and a runbook.

## Security and permissions

Keep cookie authentication and CSRF for browser mutations. Signed webhooks use exact authentication exceptions, raw payload verification and environment/account checks. Add step-up MFA for finance approvals, beneficiary changes and privileged supplier/platform actions. Distinguish reviewer, support, finance maker, finance approver and reconciliation roles; global email-derived `is_admin` alone is too broad for commercial operations.

Test tenant scope in reads, writes, exports, realtime rooms, background tasks and AI retrieval. Prevent support tools from exposing unrelated customers or bypassing finance approvals. A supplier sees its contract and necessary manifests, while platform contribution, fraud investigations and other suppliers' records remain restricted.

Use provider-hosted card collection/tokenization and explicit save consent if enabled. TripRaft stores no raw PAN/CVV/card screenshots. Provider references and last-four metadata remain private. Delete/revoke tokens through provider-supported flows. Do not imply that saving a method authorizes unattended future charges.

Document upload/download needs purpose, minimum required fields, size/type validation, malware handling, access grants, retention/deletion policy and audit. Store tax and verification evidence only when necessary; prefer provider-hosted verification. Supplier-supplied content and retrieved websites are untrusted input to AI, never authority to execute tools.

## Required runbooks

Create these with the corresponding feature, under `docs/runbooks/commerce/`:

| Runbook | Required procedure |
| --- | --- |
| `captured-payment-unconfirmed.md` | Locate trusted capture/supply facts; pause affected inventory; reconfirm or refund; notify and reconcile |
| `webhook-recovery.md` | Verify provider event/account, locate durable receipt, inspect business effects and safely replay |
| `inventory-repair.md` | Freeze departure, inspect holds/events/supplier evidence, apply audited correction and recheck invariants |
| `refund-after-payout.md` | Calculate policy/tax adjustment, reserve refund, execute once, book supplier recovery and reconcile |
| `payout-failed-or-reversed.md` | Freeze retries, resolve beneficiary/provider state, handle clearing/reversal and record bank evidence |
| `reconciliation-exceptions.md` | Import unique source lines, match references, obtain evidence, approve adjustments and track aging |
| `supplier-failure.md` | Stop sales, identify affected travelers, provide replacement/refund process, recover supplier obligations |
| `beneficiary-change.md` | Reverify, apply freeze/approval policy, prevent stale approved payout using changed bank token |
| `data-restore.md` | Restore to isolation, verify catalog mappings/inventory/journals, reconcile external side effects before reopening |
| `privacy-or-access-incident.md` | Restrict access, preserve redacted evidence, assess exposure and execute reviewed response |
| `live-money-pause.md` | Pause new sales/payouts independently while preserving customer access, refunds and reconciliation |

## Launch checklist and evidence

Every checklist item has an owner, evidence link, approval date and applicable scope. External legal/tax/payment approval belongs to qualified owners and the provider; engineering records the gating result.

- Entity, seller identity, supplier contract and allowed funds flow are documented for each enabled sale model.
- Provider approves the actual travel/category/country setup, supplier verification and settlement/refund behavior.
- Tax/invoice/credit/withholding fixtures are approved, versioned and pass in the deployed build.
- Suppliers/departures are reviewed; allocations or request-to-book commitments are truthful and tested.
- Last-seat, duplicate event, late capture, rejection, full/partial refund, refund after payout, payout reversal and reconciliation tests pass on the production-equivalent stack.
- Invoices/vouchers identify the correct issuer/seller and pending states never claim confirmation.
- Finance can explain every sandbox capture, fee, payable, refund and settlement with balanced journals and matching evidence.
- Granular permissions, MFA, private documents, cross-tenant tests, backups and restore/replay drill pass.
- Alerts and support coverage have named operators; live controls and incident runbooks are rehearsed.
- Customer terms, full prices, source freshness, support and cancellation paths are visible and usable on a phone and keyboard.
- First pilot is bounded by supplier/departure/booking-value limits and an explicit review date.

## Founder economics and hiring gates

Track GMV separately from platform revenue excluding tax, contribution after direct costs, customer liabilities and company operating profit. Model gateway/support/refund/discount/AI costs explicitly. A large payment volume can coexist with very low contribution and large refund obligations.

The source's INR 100–150 contribution per completed booking is a scenario, not a forecast. At INR 125 contribution, an additional INR 50,000 monthly fully loaded hire needs 400 additional completed bookings merely to cover that cost, before other fixed costs. Do not fund payroll from reserved customer/supplier liabilities.

Proposed gates: founder plus qualified contractors for the prelaunch; part-time supplier/support assistance if 50–100 paid and fulfilled bookings produce a genuine backlog; consider the first employee after at least three months of positive contribution and a separate 6–12 month payroll runway. Hire to remove the measured bottleneck, commonly supplier operations/support before a large engineering team. Keep operating runway and refund/reserve cash forecasts separate.

Weekly review: paid/fulfilled bookings and repeat demand; funnel losses; supplier acceptance/fulfillment; refunds/chargebacks; recognized revenue and contribution; unpaid suppliers and cash obligations; support backlog; next measurable improvement. Expand only when financial and operational evidence supports it.
