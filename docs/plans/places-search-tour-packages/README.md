# Places Search live tour packages implementation plan

Prepared 18 October 2026. Status: implementation started; the first phase-one onboarding/access vertical and native launcher fixes are implemented locally. See the [implementation report](../../reports/partners-onboarding-foundation-2026-10-18.md) for delivered files, checks and remaining gates. This remains the active roadmap and replaces the earlier unified-marketplace plan and its retired phase-zero scaffolding.

19 October update: the [staff console and private package draft workspace](../../reports/staff-console-package-drafts-2026-10-19.md) are implemented. Approved suppliers can author drafts; media, immutable package submission/review and public cards remain next. The separate employee console reviews business applications and is not linked from the public or agent websites.

Source specification: `TripRaft_Places_Search_Live_Tour_Packages_Complete_UPDATED_2026 (1).docx`, version 3.0, all 20 sections and appendices A and B. The complete main-body/table text was read; this is a requirements review rather than a Word layout review. Appendix B takes precedence where earlier wording differs. The user's footer placement instruction takes precedence over the document's optional header/About alternatives.

## The feature we are building

Tour agents enter their package information in a dedicated dashboard: where the tour starts and ends, destinations, days/nights, daily itinerary, photos, hotels, transport, inclusions/exclusions, departure dates, inventory, private supplier rates and policies. TripRaft verifies the agent, reviews the first package and controls the customer-facing pricing rules. Approved packages appear as cards **inside the existing Places Search feature**. Travelers open a card to see the package details and, when enabled, availability, a final quote and checkout.

The existing country/place discovery and trending content is retained. Static place records are not converted into bookable packages, and supplier costs are not copied into public card prices. The agent portal does not grant access to Scout/Crew, group planning, personal trips or expense features.

```text
Footer: Company → Partner with TripRaft
                  ↓
              /partners
                  ↓
    Register/login → business onboarding → review
                  ↓
     Agent dashboard → package wizard → first review
                  ↓
      Approved package revision + public projection
                  ↓
 Existing Places Search → tour card → /tours/:slug
                  ↓
     Quote/hold/checkout after booking release gates
```

## Planning files

| File | Covers |
| --- | --- |
| [Architecture and files](architecture-and-files.md) | Existing integration points, future folders, route placement and partner access isolation |
| [Data APIs and publishing](data-api-and-publishing.md) | Package fields, tables, response boundaries, price visibility, publication automation, inventory and money workflows |
| [Phases and acceptance](phases-and-acceptance.md) | Complete delivery sequence, ordered backlog, verification, rollout and unresolved decisions |

## Confirmed product decisions

| Topic | Decision |
| --- | --- |
| Entry point | Add **Partner with TripRaft** to the shared footer's Company list, alongside About Us and Contact; target `/partners` |
| Public feature | Extend `/places` and its existing `/place-search` alias; no disconnected packages website |
| Existing content | Retain countries, places, destination navigation and current trending/editorial behavior; no catalog rewrite |
| Package content source | Agent-submitted and approved package revisions; optional catalog IDs only help reference geography |
| Package details | A separate `/tours/:slug` page in the same React app, linked from the package card |
| Agent portal | `/partners/*`, supplier-only navigation and server-enforced permissions |
| First approval | Verify the supplier and manually review its first package before any public listing |
| Later updates | Safe routine updates can publish automatically after validation; major changes require selective review |
| Price owner | TripRaft pricing service under administrator rules and supplier contract authority |
| Public prices | Explicit server-side visibility policy; hidden prices must be absent from public payloads, HTML and metadata |
| Commercial model | Marketplace/reseller agreement type, net cost, commission and margin are private; required legal seller disclosures remain public |
| Inventory | Departure-specific; exact seats only for trusted allocated/synchronized stock; otherwise Check availability/inquiry |
| Launch sequence | Agent onboarding and package publishing/discovery first; booking/payments/payouts follow separate gates |
| Other product features | No new corporate workspace program, AI redesign, expense integration or group-planner modifications in this vertical |

The footer link ships together with a functioning `/partners` landing page, not as a dead link to an unfinished dashboard. Header placement is not part of the initial scope.

## What the current repository actually contains

| Area | Inspected path | Implementation consequence |
| --- | --- | --- |
| Current stack | Root workspace, `apps/web`, `apps/admin`, `services/api` | Keep React/Vite and Flask/SQLAlchemy/Alembic; add domain modules rather than replacing frameworks |
| Places routes | `apps/web/src/App.jsx` | `/places` and `/place-search` already render `PlaceSearchPage`; preserve both |
| Search page | `apps/web/src/features/discover/jsx/PlaceSearchPage.jsx` | Compose a separate tour section with independent loading/error/filter state |
| Existing place components | `SearchBar`, `PlaceGrid`, `GroupedPlaceGrid`, `PlaceDetailModal` | Keep their place payloads and behavior; create `TourPackageCard`/detail components |
| Existing search service | `apps/web/src/services/placeSearchService.js` | Preserve current place calls; add a distinct `tourPackagesApi` adapter |
| Shared footer | `apps/web/src/components/layout/jsx/Footer.jsx` | Company already contains About Us and Contact; add the partner link here |
| Existing authentication | `auth/models.py`, cookie sessions, `require_auth`, frontend `ProtectedRoute` | Reuse identity primitives but add partner realm/capabilities; authentication alone currently grants too broad a surface |
| Internal console | `apps/admin/src/App.tsx` | Extend with supplier/package/pricing review; keep the existing server account check |
| Backend registration | `services/api/app/core/factory.py` | Register explicit partner, tours, publication and later checkout/finance blueprints |
| Operational persistence | `app/core/db/base.py`, `connection.py`, existing Alembic migrations | Extend the shared operational ORM history; PostgreSQL for commerce transactions |
| Catalog readers | `app/places`, planner catalog service and travel DB configuration | Leave source files, schema, identifiers and existing readers intact |
| API contracts | Route inventory exporter and generated `packages/api-client` types | New operations require real request/response/error schemas; do not leave them `unknown` |
| Frontend typing | Web tsconfig currently includes entrypoint/environment declarations only | Include each new TS/TSX feature and configure typed test transpilation before relying on typecheck |
| Test harness | Backend `tests/conftest.py` currently chooses SQLite before app imports | Add an explicitly isolated PostgreSQL harness for transaction/race tests |

The specification says countries/trending sections exist in the live experience. This checkout's inspected `PlaceSearchPage` has a search hero, grouped results and welcome/empty states; separate named country/trending rails were not found in that component. Phase zero must compare the deployed revision/reference with this checkout and preserve the actual modules. Do not claim a trending implementation or fabricate popularity data. If a required rail is absent here, implement it as an explicit discovery task with a real editorial/data source.

The document's attached empty SQLite snapshot is not a count of every local database or of production. No further catalog consolidation or migration is required to begin supplier package creation. Audit and preserve existing data as normal development practice; do not make the retired catalog project a dependency of this vertical.

## User experiences

**Agent:** footer link → partner landing → register/verify → submit business profile → approval → seven-step package wizard → preview/submit → review status → published package → manage departures and validated routine updates → later fulfill bookings and inspect own payouts.

**Traveler:** current Places Search → existing discovery sections plus featured/available packages → destination/date/duration filters → package card → detail page → select departure/travelers → availability request or final quote → payment only when booking is enabled → clear confirmed/pending status.

**Administrator:** supplier review → first package review → approve public revision → private agreement/rate/pricing policy → featured selections → monitor automated updates, stale inventory, suspended suppliers → later money/refund/reconciliation operations.

## Commercial and policy inputs still open

The user has confirmed that legal entity country, receiving-bank country and initial supplier country are undecided. Record them as open; do not infer an India-incorporated business or payment eligibility from rupee examples. Supplier terms, legal seller, currencies, tax/invoice rules, provider approval, refund liabilities and settlement timing must be approved before live commerce.

The initial **public-price policy** also needs a launch choice: hidden on cards/details, visible on details only, or visible on both. Implement the policy in the backend. A conservative discovery-only preview can use hidden prices and inquiry with booking disabled until prices/taxes are approved. If checkout is enabled later, an authorized buyer must always see the full payable amount and mandatory fees/taxes before authorizing payment, even when search cards hide prices.

Automated publication trust thresholds, inventory staleness limits and high-risk approval thresholds need named owners and versioned configuration. Begin with manual approval of all new packages; introduce trusted-tier shortcuts only after measurable history and tests.

## Scope and completion

The first usable release is a verified agent creating a package without administrator data entry, approved content appearing in Places Search, and card/detail updates following the publication rules. It can launch without taking payments. The subsequent release adds accurate departures/pricing/quotes and controlled checkout; supplier settlements and operations follow.

The source's approximately 20-week pilot schedule is an indicative planning window, not a commitment. Estimate after checking deployed discovery, supplier authentication and provider requirements. See the phase document for gates and a first implementation sprint. This planning checkpoint delivers no live portal, listing, footer route or payment integration.
