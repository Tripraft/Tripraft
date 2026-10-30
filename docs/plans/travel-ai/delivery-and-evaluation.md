# Implementation sequence and release gates

Status: proposed backlog. No runtime feature is implemented by these documents. [Plan index](README.md).

## Product acceptance

TripRaft AI must answer travel questions, produce editable day plans, read requested authorized project data, and execute supported group/expense/planning tasks. Group Companion must participate in the selected group's chat with a clearly bounded audience and read-only tools under the current scope. Both share knowledge, citations and infrastructure; they do not share private conversation memory.

Optimize cost per correctly completed task subject to privacy, evidence and latency requirements. Do not optimize raw price per call by accepting unsupported facts or unsafe actions. Launch can be useful before every task is automated: clearly show supported actions and hand off unsupported operations to the existing app UI.

## Phase 0: baseline and contracts

Deliver:

- Confirm two-assistant capability matrix, group enablement/trigger policy, purpose scopes and publication rules.
- Record current deployed catalog paths/schema capabilities, provider configuration and feature flags without exposing secrets.
- Audit Scout/Crew fallbacks, current origin inference, cache invalidation, confirmation semantics, websocket recipients and service-owned transaction boundaries.
- Capture a read-only catalog coverage report by field, source age, geography and verification state, including coordinate identity checks.
- Build a synthetic/curated benchmark and instrument metadata-only request timings and usage.

Gate: signed-off product/engineering policy, known current-state gaps, reproducible baseline and explicit provider/hosting budget assumptions. No claim that repository defaults match production.

## Phase 1: shared policy and knowledge foundations

Deliver the server-owned profile registry, request context, model/provider adapter, read-only CatalogGateway, evidence contract, safe research gateway, quotas, purpose checks and private/group audience projection. Use canonical aliases/full text first. Publish catalog manifests and test planner identity mapping before switching its catalog source.

Gate: synthetic cross-user/group requests fail; Companion has no write tools; source IDs/links are server-generated; unavailable evidence results are typed; budgets remain enforced during Redis failures. Verify that a canonical read cannot write and a research result cannot invoke an action.

## Phase 2: TripRaft AI read-only assistant

Deliver global private chat and contextual entry points, place answers/cards, weather, official-source visa flow, authorized group/expense summaries, progress and citations. Public travel answers work without history/memory permission. Add disclosure and controls before any hosted private-context processing. Keep history/file reading disabled until their specific controls pass.

Gate: held-out factual and scope metrics pass; all live claims expose provider/effective/check times as applicable; no phone/currency-based nationality inference; money matches the domain service exactly. Expense answers never call public search with private content.

## Phase 3: Group Companion

Deliver explicit group mention/reply, read-only group-safe answers, optional bounded consented history summary, opt-in shared preferences, private consent UI and handoff into TripRaft AI. Avoid automatic participation on every message.

Gate: other groups and personal ledgers are unreachable; history from nonconsenting authors is excluded, including summaries derived from it; private prompts/cards are absent from other recipients' HTTP, websocket, exports and unread counts. A handoff reauthorizes all references and never executes implicitly.

## Phase 4: itinerary drafts and edits

Deliver a structured timeline/map draft, assumptions and evidence, deterministic feasibility checks, route estimates, locked/manual/booked items and patch previews. Integrate the existing planner UI instead of introducing a second source of itinerary truth.

Gate: zero hard-constraint violations in plans labelled feasible; unknown hours/prices stay explicit; explicit plan requests produce useful schedules even with incomplete optional preferences; incremental edits preserve locked items and detect concurrent changes. Apply remains off until Phase 5 action guarantees pass.

## Phase 5: durable application actions

Implement in this order: low-risk creation, selected itinerary apply, expense creation, expense editing/deletion/restore, group settings and collaboration tools. Add durable proposals/idempotency, unit-of-work transaction support, outbox and receipt recovery. Keep each tool behind an independent flag.

Gate: no duplicate side effects under concurrent approval, queue redelivery, browser retry or timeout-after-commit; exact money/split/history invariants hold; permission revocation and stale versions block commit; a receipt exists for every successful mutation. No success is announced before commit.

## Phase 6: controlled expansion and optimization

Deliver selected-file reading, exports, invitations, membership/role operations and settlement recording only after each tool's audience and side effects are specified. Add proactive suggestions only through explicit opt-in with frequency/time controls. Use frequent public knowledge gaps to prioritize enrichment. Run load/restore drills and optimize based on actual task cost and latency.

Gate: source licences/provider regions verified, background budgets isolated, deletion targets demonstrated, dashboards/runbooks active and canary outcomes acceptable. Actual purchases/transfers and autonomous third-party actions remain separate product/security projects.

## Repository implementation map

All `new` paths below are proposals. Preserve the existing `scout` domain initially to avoid a disruptive rename. Update current developer guides when behavior actually ships.

| Path | Proposed responsibility |
|---|---|
| `services/api/app/scout/services/assistant_orchestrator.py` (new) | Bounded request state machine shared by both profiles |
| `services/api/app/scout/services/assistant_policy.py` (new) | Profiles, capability/audience checks and data minimization |
| `services/api/app/scout/services/context_builder.py` (new) | Request-relevant authorized context with dependency lineage |
| `services/api/app/scout/services/evidence_service.py` (new) | Normalized claims, evidence checks and citations |
| `services/api/app/scout/services/itinerary_planner.py` (new) | Candidate selection, schedule draft, patch and validation |
| `services/api/app/scout/services/action_service.py` (new) | Durable proposals, idempotency, commit/reconciliation |
| `services/api/app/scout/services/tool_registry.py` (new) | Versioned allowlisted tool schemas and profile eligibility |
| `services/api/app/scout/llm/provider_client.py` (new) | Typed provider contract; add hosted and retain Ollama adapters |
| `services/api/app/scout/routes/assistant.py` (new) | Private app-assistant conversation/request API |
| `services/api/app/scout/routes/group_companion.py` (new) | Group-only read-only entry and handoffs |
| `services/api/app/scout/models.py` plus focused new model modules | Consent scope migration, durable requests/actions/usage/dependencies |
| `services/api/app/places/services/catalog_gateway.py` (new) | Versioned read-only catalog facts, identities and sources |
| `services/api/app/places/search/web_search.py` | Adapt provider result contract and test cascade/deadlines |
| `services/api/app/core/external/weather.py` (new) | Structured weather API and attribution |
| `services/api/app/core/external/research.py` (new) | Safe fetch/extraction and public-query minimization |
| `services/api/app/core/workers/tasks/ai_tasks.py` and dedicated tasks | Queue policy, request processing, erasure and enrichment |
| Existing trip/itinerary/expense services | Reuse authorization/calculation; add unit-of-work and idempotency support where needed |
| `services/api/app/core/config.py` | Provider, caps, flags, freshness and regional policy settings |
| `services/api/migrations/versions/` | Additive reviewed application schema migrations |
| `apps/web/src/features/scout/` | Shared citation, clarification, preview and receipt cards |
| `apps/web/src/features/assistant/` (new) | Global private assistant UI, conversations and task progress |
| Existing trip chat/planner and expense views | Companion entry, itinerary draft/apply, context selection and handoff |
| `apps/web/src/services/assistantApi.js` (new) | Request/status/events/actions client |
| `packages/api-client/src/generated/schema.d.ts` | Regenerate from accepted API contracts, never hand-edit generated declarations |
| `infra/tools/` | Synthetic load, coverage, cost reports and restore/reconciliation tooling |
| `docs/architecture/`, `docs/api/`, `docs/guides/`, `docs/operations/` | Implemented contracts and operating procedures after delivery |

Keep existing domain endpoint behavior stable. Old `@scout` requests can route to read-only Companion when posted in group chat. Existing `@crew` write behavior needs explicit product migration: offer an app-assistant handoff or retain a separately flagged legacy path until the replacement is ready. Do not call legacy Crew the new read-only Companion while leaving its mutation behavior enabled.

## Evaluation dataset

Start with 600 curated cases: 150 place/retrieval, 80 weather/temporal, 70 visa/applicability, 100 itinerary, 100 group/expense actions and 100 privacy/adversarial cases. Reserve at least 20% as a held-out set; maintain a separate never-tuned security regression suite. Add real corrected failures with consent and de-identification where permitted. Coverage matters more than reaching a nominal case count.

Include typos, short follow-ups, local scripts/mixed language, repeated place/member names, multi-city trips, missing data, stale official pages and compound requests. Cover representative launch languages/geographies explicitly; do not claim global quality from English-only testing. Each factual expected answer has authoritative evidence and an applicability/check date. Refresh time-sensitive fixtures. External failures are simulated separately from live integration checks.

| Area | Required representative cases |
|---|---|
| Places | One exact match; identical names in different countries; partial record; wrong coordinates; conflicting source; deleted/retired record |
| Weather | Past date; future beyond horizon; local-midnight boundary; modelled vs observed conditions; provider outage |
| Visa | Different passport/residence; dual nationality; transit; missing purpose/date; official conflict; phone/currency misleading |
| Planning | Arrival late; closed weekday; holiday exception; unknown hours; inaccessible route; booked/locked visit; impossible budget |
| Expenses | Equal/exact/percentage/share splits; multiple payers; currency precision; inactive members; no linked ledger; unauthorized edit/delete |
| Concurrency | Simultaneous approvals; stale amount; membership revoked; timeout after commit; duplicate queue delivery; lost realtime |
| Privacy | Group A/B isolation; personal query in group; another author opts out; revoked consent during streaming; private cache poisoning |
| Injection | Malicious webpage/catalog/file/chat asking to reveal data, change profile or issue tool calls |
| Erasure | Queued/in-flight writes to memory after revocation; derived summaries; restore from backup with tombstones |

## Release thresholds

Initial targets below are gates to validate and refine, not measured results:

| Metric | Gate |
|---|---|
| Authorization/audience regression cases | 100% pass; zero observed cross-user/group leaks |
| Critical financial/action invariants | 100% pass, including concurrency/retry fault cases |
| High-consequence unsupported current claims | Zero in release suite; abstain when evidence is insufficient |
| Ordinary factual claims supported by applicable evidence | At least 98% on held-out reviewed claims |
| Citation reference/link validity | 100% schema checks; at least 98% human-reviewed support |
| Supported task success | At least 95% on defined held-out end-to-end workflows |
| Plans marked feasible | 100% hard-constraint satisfaction in evaluated inputs |
| Useful planning quality | At least 90% meet the published human rubric for fit, pacing and clarity |
| Quota and erasure race cases | 100% pass; access revoked immediately |
| Latency and variable spend | Meet declared p95 per-route budgets under measured workload |

Report numerator/denominator, confidence intervals where meaningful, abstention rate and geography/language breakdown. A high support score achieved by refusing every question is not acceptable; track answer coverage and useful task completion together. Zero observed failures is a test result, not proof that failure is impossible. Use independent human review for entry-rule and privacy cases; model graders supplement, never replace, critical checks.

## Tests and checks

Extend existing backend regressions such as `test_ai_consent.py`, `test_crew_expense_deletion.py`, `test_canonical_catalog.py`, `test_group_access_controls.py`, `test_planner_live_security.py` and expense split/collaboration tests. Add focused tests for evidence applicability, profile isolation, action idempotency/transactions, outbox recovery, erasure races and weather/visa adapters. Frontend checks cover audience-safe cards, reconnected event streams, progress, citations and version conflicts.

Use synthetic ledgers for financial fault injection and read-only public fixtures for catalog tests. Unit/mock checks do not establish provider accuracy or production latency; add controlled integration and load tests with declared environments. Run the repository's required verification commands for implementation changes and only repeat broader suites when changes or unresolved failures justify them.

For this documentation-only proposal, validate local links and document consistency. Runtime tests are not evidence of this proposed system because no implementation has been added.

## Operational launch checklist

- Approved provider, model/region policy, commercial API licences and cost caps.
- Separate two-assistant capability registries, consent/audience behavior and tested migration from Scout/Crew.
- Catalog version/identity mapping, field coverage report and safe missing-evidence behavior.
- Reproducible held-out quality, privacy, financial and fault-injection reports.
- Measured load/cost report and quotas that survive dependency failures.
- Backup/restore drill, action reconciliation, deletion replay and catalog rollback tested.
- Owned dashboards, alerts, runbooks, incident routing and independent feature kill switches.
- Staging acceptance and production release through the existing database/deployment process.

## Remaining product decisions

The architecture uses actionable defaults while these details are finalized: Companion is read-only; current-request processing and history/memory are separate; app-assistant answers are private; no automatic invites/purchases/transfers; no default background chat reading. Before implementation, choose launch geographies/languages, supported operation list, external-processing mode and provider region, monthly traffic/spend envelope, official-source coverage policy and retention settings.

Measure the first read-only pilot before final hosting/model procurement. These choices can refine configuration and delivery order without weakening the core permission, evidence and action contracts.
