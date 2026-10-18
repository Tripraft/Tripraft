# TripRaft unified marketplace and reseller implementation plan

Prepared 17 October 2026. Status: proposed implementation, based on the supplied Word blueprint and inspection of this checkout. This package defines the work; it does not establish deployed functionality, passing tests, tax treatment, or payment-provider approval.

TripRaft can implement this blueprint by extending the current React and Flask project with a PostgreSQL commerce system. Reuse identity, discovery, trip planning, chat, polls, expenses, Scout/Crew, and the admin shell. Add supplier operations, contractual offers, inventory, quotes, bookings, payments, and commercial finance as separate modules. Launch a narrow operator-led marketplace first; enable selected reseller offers after their contracts and financial flows are approved.

Implementation started with the [phase-zero engineering baseline](../../reports/marketplace-phase0-baseline-2026-10-18.md) on 18 October 2026. Reusable inventory/backup tooling and the first baseline evidence are implemented. Commercial country/entity/provider decisions remain open, as recorded in the [decision register](../../decisions/marketplace-phase0-decisions.md); the complete phase-zero commercial exit gate is not yet satisfied.

## How to use this package

| File | Purpose |
| --- | --- |
| [This overview](README.md) | Direction, actual project baseline, release scope, decisions, and requirements coverage |
| [Architecture and file structure](architecture-and-files.md) | Target folders, concrete files, module ownership, routes, and existing integration changes |
| [Data model and API contracts](data-and-api.md) | Tables, constraints, immutable economics, state machines, concurrency, endpoints, and financial behavior |
| [Phases and execution backlog](phases-and-backlog.md) | All implementation phases, dependency order, deliverables, acceptance gates, estimates, and first sprint |
| [Verification and operations](verification-and-operations.md) | Failure tests, CI changes, environments, dashboards, runbooks, security, and launch criteria |

Source: root file `TripRaft_Unified_Marketplace_Reseller_Complete_Implementation_2026.docx`, version 2.0, sections 1 through 81 and appendices A through D. All nonempty main-body paragraphs and table text were extracted and reviewed. This is a requirements review, not a Word layout review. No changes were made to the source document.

The earlier [enterprise platform plan](../enterprise-platform-implementation-plan.md) remains useful for corporate workspaces, responsibilities, publication, and approvals. This package refines its overlapping marketplace and commerce proposals. For that scope use the module names and financial rules here; reconcile any remaining naming differences before coding. Both plans are proposals, not existing implementations.

## Recommended implementation decisions

1. Keep React/Vite, Flask, SQLAlchemy, Alembic, Redis, Celery, pnpm, and Turbo. The blueprint's FastAPI/Next.js suggestions do not require a framework migration. Revisit server rendering separately if measured public search acquisition requires it.
2. Keep one API and one operational PostgreSQL database initially. Use the existing shared ORM base and migration history. Keep catalog SQLite separate. Add domain boundaries before considering service extraction.
3. Use `apps/web` for travelers, groups, company users, and suppliers with a workspace switcher. Use `apps/admin` for internal platform operations. A supplier does not become a global administrator.
4. Model a product as descriptive package content and an offer as the contractual sale of that product. A departure belongs to an offer. One supplier can have separate marketplace and reseller offers with separate contracts.
5. Lock `sale_model`, legal seller, contract version, and tax policy on published offers and accepted quotes. Changing models requires a new offer/version; finance cannot relabel a paid booking.
6. Default to `MARKETPLACE`. Put `RESELLER`, live checkout, payouts, saved methods, external booking, and dynamic pricing behind independent backend release gates.
7. Start with one geography, one charge/settlement currency, one supplier per booking, one payer, full payment, and simple traveler bands. Broader currencies, deposits, split group payment, and multiple sellers are later capabilities.
8. Support allocated and manual request-to-book inventory first. External supplier integrations follow the same booking contracts but retain their own resource and confirmation semantics.
9. Prefer supplier acceptance and a time-bounded supplier commitment before requesting payment for manual inventory. A request is not a local guaranteed seat hold. Capturing before acceptance requires a separately approved, disclosed compensation/refund flow.
10. Build balanced commercial accounting, refunds, reconciliation, monitoring, and support before live money. Existing traveler expense settlement is a different financial system.

## What is already present

Evidence is from repository files, not a running production environment.

| Area | Inspected evidence | Plan |
| --- | --- | --- |
| Monorepo | Root `package.json`, `pnpm-workspace.yaml`, `turbo.json` | Extend existing workspaces |
| Traveler UI | `apps/web/src/App.jsx`, `features/trips`, `features/discover`, `features/expenses` | Preserve current URLs and workflows; add new typed features |
| Collaboration | `TravelGroup`, `TripMember`, polls, chat, vault, checklist and itinerary models/services | Link commerce bookings into existing trips; add tenant ownership incrementally |
| Identity | `app/auth/models.py`, cookie sessions, CSRF, auth route tests | Reuse users; add workspace membership and step-up authentication |
| Backend | `app/core/factory.py`, shared SQLAlchemy `Base`, domain routes/services | Register new Flask blueprints; do not build a second API |
| Migrations | `services/api/migrations`, startup schema verification | Add revisions from actual current head, including all model imports |
| Catalog | Independent catalog paths and planner-specific catalog configuration | Reconcile versions and establish stable cross-catalog references |
| AI | `app/scout/services`, consent gate, LLM validator, Celery tasks | Extend tools and evaluation; backend remains authority for prices and transactions |
| Admin | `apps/admin/src/App.tsx`: health/audit, server-derived `is_admin` | Add internal supplier, booking, finance and support screens; granular permissions required |
| Idempotency | `app/core/idempotency.py`: optional Redis key/replay mechanism | Add durable commerce idempotency and business uniqueness; Redis alone is insufficient |
| Background processing | Celery application, tasks and beat schedule definitions | Add durable outbox/inbox handling and deploy a scheduler; Compose currently has an optional worker but no beat service |
| API contracts | Route exporter plus generated TypeScript, largely unspecified legacy responses | Fully describe every new commerce request/response and error |
| Frontend checking | Web `tsconfig.json` includes only `main.tsx` and `env.d.ts`; Babel lacks the TypeScript preset | Expand checks and configure TSX tests before new typed features land |
| Infrastructure | Docker PostgreSQL/Redis/API/optional worker; canonical CI/deployment workflows | Add PostgreSQL commerce CI, staging, secrets, storage, recovery and release gates |

### Catalog finding that changes phase zero

Read-only SQLite counts in this checkout on 17 October 2026:

| File under `data/catalog` | Countries | States | Cities | Places | Airports |
| --- | ---: | ---: | ---: | ---: | ---: |
| `tripraft-canonical.db` | 0 | 0 | 0 | 0 | 0 |
| `tripraft_places.db` | 191 | 1,790 | 6,478 | 30,339 | 0 |
| `travel_data_complete.db` | 82 | 837 | 889 | 16,830 | 892 |

The Word document's 190 countries / 22,925 places is a different supplied snapshot. Do not use that count as this project's live database count. `Config.TRAVEL_DATABASE_PATH` defaults to the empty canonical file; `GROUP_PLANNER_CATALOG_PATH` defaults to the populated planner file. The planner file is untracked in the current working tree. A fresh clone and a running developer checkout can therefore behave differently.

Before consolidation, identify all readers, compare schemas and provenance, record database fingerprints, map collisions, and choose the distribution mechanism for the approved catalog. Preserve original IDs using a catalog namespace and mapping. Never merge files simply because numeric place IDs match. Do not seed all historical country scripts automatically. Operational booking data must never be written into catalog tables.

## Product and release scope

| Release | Included | Deliberately scheduled later |
| --- | --- | --- |
| Foundation | Existing-feature baseline, catalog resolution, workspaces, permissions, supplier contracts, finance decisions | Commercial launch |
| Bookable sandbox | Mobile supplier portal, reviewed products/offers/departures, fixed prices, immutable quotes, holds, manual acceptance | Live money |
| Controlled marketplace pilot | One approved gateway, verified capture, confirmation/vouchers, invoices, refunds, payouts/reconciliation, support, trip linkage | Broad geography or many suppliers |
| Selected reseller release | Separate contracts, seller/invoice identity, supplier-cost and input-tax evidence, refund liability and accounting templates | Automatic mode conversion |
| Optimization | Explainable pricing, promotions, improved search, affiliate and one licensed provider adapter | Multiple simultaneous travel integrations |
| Corporate and platform expansion | Organization approvals, cost centers, policy, budgets, billing exports; richer AI and intelligence | Multi-seller carts and native mobile until justified |

All customer prices show mandatory fees and applicable taxes before commitment. Public offers disclose the seller, confirmation mode, source freshness, departure time zone and cancellation terms. Browsing currency conversions are estimates; the accepted checkout currency is binding.

## Commercial decisions and gates

These are unresolved business inputs. Engineering can prepare schemas, mocks and sandbox flows while decisions are open. Production pricing and money movement depend on approved values.

| Decision record | Accountable person | Needed before |
| --- | --- | --- |
| Legal entity, merchant/bank country, customer and supplier geographies | Founder with legal/payments advisors | Provider selection and live checkout |
| Legal seller and allowed funds flow for each sale model | Founder, legal and payment provider | Offer publication with checkout enabled |
| Contract terms: price authority, commission/net cost, tax inclusivity, allotment, cancellation and liability | Supplier operations with finance/legal | Pilot offer approval |
| Effective tax rules, invoice chain, place of supply, credit eligibility and withholding applicability | Qualified accountant/legal advisor | Financial acceptance fixtures and live invoices |
| Provider onboarding, travel category, account eligibility, settlement timing and refund/transfer support | Payment provider and founder | Live gateway or payouts flag |
| Supplier confirmation SLA and real source of seat truth | Supplier operations | Instant or request-to-book activation |
| Refund reserve, support hours and exception ownership | Finance and operations | First live booking |
| Approved catalog release and ID mapping | Engineering/data owner | Catalog consolidation |

Use versioned decision files with status `OPEN`, `APPROVED`, or `REJECTED`, owner, date, evidence, scope and next review. Do not put identity documents, bank credentials or secrets in Git. An unapproved tax configuration makes an offer unpublishable for paid checkout; demo calculations may still run in sandbox.

### Payment-provider research update

Official pages were checked on 17 October 2026. They describe product capabilities, not approval of TripRaft.

- [Razorpay Route](https://razorpay.com/docs/payments/route/) describes linked accounts and split transfers, and publishes financial eligibility and payer/payee transparency requirements. Validate TripRaft's eligibility early; ordinary payment gateway access does not prove Route eligibility.
- [Cashfree Easy Split](https://www.cashfree.com/docs/payments/split/overview) describes vendor onboarding, splits, settlements and refund adjustments. Its documentation says account enablement requires contacting the account manager.
- [Razorpay webhook validation](https://razorpay.com/docs/webhooks/validate-test/) covers signature checking, duplicate event identification and event ordering considerations. Implement provider-specific validation against the raw request body.

Choose one approved provider using a documented capability matrix; do not implement both gateways in the pilot. If split payments are unavailable, record an approved alternative funds flow or use a licensed referral/redirect product while commerce approval is pending. Never improvise marketplace collection through an unrelated personal account. Revalidate all source-document regulatory links and applicable rules before relying on them; linked examples are not legal determinations.

## Planning assumptions and schedule

The source's 14-week launch sequence is a target for a narrow pilot, conditional on a stable baseline, concurrent supplier/advisor work, and completed provider onboarding. It is not an estimate for the entire consumer, corporate, AI and global booking platform.

For one full-time engineer, allow roughly **21 to 34 engineering weeks through a controlled marketplace pilot**, with external onboarding potentially on the critical path. This is a planning estimate, not a commitment. A focused small team with existing tenancy/payment components may compress the pilot toward 14 weeks after scope and integrations are validated. Later features are additional releases. See the detailed phase estimates and gates in [the execution plan](phases-and-backlog.md).

## Requirement coverage

| Source sections | Implementation location | Delivery |
| --- | --- | --- |
| 1–6: strategy, existing status, catalog boundary | Overview; catalog registry and adapters | Phase 0 |
| 7–8, 11–12: traveler/group screens, accessibility, privacy | Existing trip UI plus marketplace/booking features | Phases 1, 3, 6, 8 |
| 9: company and education travel | Organizations, approvals and corporate UI | Phase 10 |
| 10, 17, 52–53, 60: supplier operations | Supplier backend and `features/agency` | Phases 2–3 and 6–8 |
| 13–18, 66: sourcing, capacity, holds, synchronization | Inventory and supplier adapter contracts | Phases 3–4 and 9 |
| 19–23, 51, 54–58, 61–62: modes, pricing and tax | Versioned contracts, offers, pricing, finance | Phases 0, 2–4, 7 and 9 |
| 24–29, 59, 68–69: checkout, payouts, saved methods | Bookings, payments, finance, support | Phases 5–8; saved methods in 9 |
| 30–33, 70: AI and travel intelligence | Extend Scout/Crew and provider tools | Basic scoped linkage in 6; expanded in 11 |
| 34–40, 63–67: architecture, schema, APIs, reliability | Architecture and data/API documents | Foundations through phase 7 |
| 41–50, 73–80: roadmap, backlog, tests and launch | Execution and verification documents | All phases |
| 71–72: economics, hiring and founder controls | Finance metrics and operating gates | Phases 7–8 onward |
| 81, appendix D: sources | Decision records and integration-specific reference checks | Before each external integration |
| Appendices A–C: domain fields, role criteria and distinctions | Data/API contracts and acceptance matrix | Applicable phase gates |

The full platform includes later capabilities even when they are absent from the pilot. Multi-component/multi-seller booking, supplier subscriptions, sponsored placements, loyalty, international settlements, ML pricing and native mobile require separate release decisions and acceptance contracts; see phases 9–12.

## Recommended next implementation slice

Start with phase 0 and the first sprint in the execution document. The first demonstrable vertical slice is: a verified supplier workspace creates a reviewed marketplace offer and departure; a traveler gets an immutable sandbox quote and capacity-safe reservation; an authorized supplier accepts a manual request; simulated verified payment produces a confirmed booking and balanced journal. Add real gateway money only after that chain and its failure cases pass.
