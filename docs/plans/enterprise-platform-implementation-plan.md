# TripRaft enterprise platform implementation plan

Prepared: 16 October 2026. Status: proposed implementation plan, grounded in the current repository.

Source specification: `TripRaft_Enterprise_Platform_Master_Blueprint.pdf`, version 1.0, all 23 pages. Page references below refer to that document. Repository findings are a read-only inspection; they do not establish production readiness or a passing test baseline.

## 1. Recommended direction

Evolve this project into one platform with one global identity, isolated workspaces, and three customer experiences: personal travel, corporate travel, and agency operations. Share the itinerary, catalog, maps, collaboration, notifications, and authorization infrastructure.

Keep React/Vite, Flask, SQLAlchemy, Alembic, Redis, Celery, and the existing pnpm/Turbo monorepo. Use PostgreSQL for enterprise operations. The blueprint explicitly describes Next.js and FastAPI as recommendations rather than requirements (pages 2 and 12). A framework rewrite would add work without delivering tenant isolation, approvals, or bookings. Reconsider server rendering for public package pages when public acquisition and SEO require it.

Use a modular monolith: one API deployment, with domain modules and independently running workers. Add new modules as their phase begins. Do not create three application backends or a folder full of empty microservices.

The first meaningful release is a tenant-aware personal product that preserves existing trips and expenses. Corporate and agency features follow behind workspace entitlements and release flags.

## 2. What exists and what must change

| Area | Current evidence | Implementation decision |
| --- | --- | --- |
| Monorepo | `apps/web`, `apps/admin`, `services/api`, four shared packages, pnpm/Turbo | Extend these boundaries. |
| Frontend | React/Vite, mostly JavaScript; TypeScript checks only the entry point and selected contracts | New enterprise features use TypeScript; include their files in typechecking. Convert existing modules when changing their behavior. |
| Global identity | Shared `User` and `UserSession`; cookie authentication, CSRF, verification and session flows | Reuse identity; add workspace relationships. MFA must precede organizational administrator and financial approver pilots. |
| Collaborative trips | `TravelGroup` / `travel_groups`, `TripMember` / `gp_group_members`; itinerary, map, polls, chat, tasks, vault | Keep IDs and tables initially; evolve the existing aggregate. |
| Trip access | Stored roles are `creator`, `admin`, `member`, `viewer` | Introduce canonical `owner`, `admin`, `member`, `viewer` with a compatibility adapter for `creator`. |
| Responsibilities | One nullable `TripMember.crew_role` | Replace with multiple responsibility assignment rows. A badge must not grant unrestricted privileges. |
| Expenses | Separate expense `Group` / `groups`, membership, splits, settlements, personal income and analytics | Preserve shared-expense logic; scope it to workspaces. Build commercial finance separately. |
| Organization model | No enterprise workspace/organization model found in inspected application source | Add tenancy, organizations, organization membership and resource-scoped guest grants. |
| Policy and entitlements | Existing domain-specific access checks and configuration flags | Centralize decisions and add workspace plans/entitlements; keep release flags separate. |
| Publication | Existing mutable itinerary document and planned places; no blueprint-style immutable publication model found | Add draft revision checks, publication snapshots, proposals and change acknowledgments. |
| AI | Scout/Crew services, consent, Ollama client, web search, background tasks | Extend the existing services with verified actor/workspace/resource context. |
| Files | Trip vault stored on local disk | Add a storage adapter, private object storage and document-level visibility. |
| API contracts | OpenAPI route inventory; most non-admin payloads remain `unknown` | Document actual request/response contracts for every new endpoint and progressively cover touched legacy endpoints. |
| Admin | `apps/admin` checks global `is_admin`, derived from configured admin emails; health and ingestion audit console | Keep this as internal platform operations. Organization administration belongs in the customer web app. |
| Infrastructure | Docker PostgreSQL 16/Redis/API/optional worker; CI; deployment hook; Terraform reservation | Add PostgreSQL integration CI, scheduler, durable event delivery, staging and managed production resources. |

### Catalog discrepancy to resolve first

The PDF reports 22,925 places in a populated canonical database (page 13). Direct read-only table counts in this checkout show:

| Local file | Countries | States | Cities | Places | Airports | Festivals |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `data/catalog/tripraft-canonical.db` | 0 | 0 | 0 | 0 | 0 | 0 |
| `data/catalog/tripraft_places.db` | 191 | 1,790 | 6,478 | 30,339 | 0 | 0 |
| `data/catalog/travel_data_complete.db` | 82 | 837 | 889 | 16,830 | 892 | Table absent |

The Group Planner reader explicitly uses `GROUP_PLANNER_CATALOG_PATH`, defaulting to `tripraft_places.db`. Other travel readers default to `TRAVEL_DATABASE_PATH`, pointing to the empty canonical database. README/architecture documentation predates this distinction. The planner database is currently untracked in this checkout, so a fresh clone cannot be assumed to have it.

Counts establish local inventory only; they do not establish geographic accuracy, licenses, unique physical places, or freshness. Before choosing a canonical release, compare schemas, existing referenced IDs, provenance and data quality. Keep the current planner working through an adapter during reconciliation. Do not load historical SQL files indiscriminately: the existing seed audit documents schema mismatches and cross-country ID collisions.

## 3. Target structure

`[existing]` means present now; `[new]` means proposed; `[extend]` means extend the current folder. Children shown under a new folder are proposed. This is a target structure, not a request to move all current files immediately.

```text
Tripraft/
├── apps/
│   ├── web/                                      [extend] customer application
│   │   └── src/
│   │       ├── app/                              [new]
│   │       │   ├── router.tsx
│   │       │   ├── providers.tsx
│   │       │   └── layouts/
│   │       │       ├── PublicLayout.tsx
│   │       │       ├── WorkspaceLayout.tsx
│   │       │       └── TravelerLayout.tsx
│   │       ├── features/
│   │       │   ├── auth/                         [extend] identity, MFA/SSO UI
│   │       │   ├── workspaces/                   [new] switcher, home, context
│   │       │   ├── organizations/                [new] staff, roles, departments
│   │       │   ├── trips/                        [extend] current planner
│   │       │   ├── itinerary/                    [extend] drafts and publications
│   │       │   ├── discover/                     [extend] unified catalog reader
│   │       │   ├── expenses/                     [extend] shared/personal expenses
│   │       │   ├── polls/                        [existing]
│   │       │   ├── scout/                        [extend] scoped AI proposals
│   │       │   ├── approvals/                    [new] reusable approval queue
│   │       │   ├── corporate/                    [new] requests, policies, reports
│   │       │   ├── agency/                       [new] packages, departures, ops
│   │       │   ├── bookings/                     [new] traveler booking portal
│   │       │   └── commerce/                     [new] payments, invoices, refunds
│   │       ├── components/                       [extend] application-specific UI
│   │       ├── hooks/                            [extend] retain existing hooks
│   │       ├── services/                         [extend] legacy API adapters
│   │       ├── lib/                              [extend] scoped cache/query keys
│   │       └── __tests__/                        [extend] existing regressions
│   └── admin/                                    [extend] internal operations only
├── services/
│   └── api/
│       ├── app/
│       │   ├── core/                             [extend]
│       │   │   ├── tenancy/                      [new] request/job/socket context
│       │   │   ├── policy/                       [new] capabilities and decisions
│       │   │   ├── events/                       [new] outbox dispatcher/consumers
│       │   │   ├── storage/                      [new] local/object-store adapters
│       │   │   ├── db/                           [extend] scoped transactions/RLS
│       │   │   ├── schemas/                      [extend] existing contracts
│       │   │   └── workers/                      [extend] Celery and schedules
│       │   ├── auth/                             [extend] global identity
│       │   ├── workspaces/                       [new] memberships and invitations
│       │   ├── organizations/                    [new] company/agency profiles
│       │   ├── entitlements/                     [new] plans, limits, usage
│       │   ├── trips/                            [extend] current trip aggregate
│       │   ├── itinerary/                        [extend] revisions/publication
│       │   ├── expenses/                         [extend] shared expense domain
│       │   ├── places/                           [extend] catalog API and adapters
│       │   ├── scout/                            [extend] existing AI orchestration
│       │   ├── notifications/                    [extend] scoped delivery
│       │   ├── approvals/                        [new] exact-action approval records
│       │   ├── corporate/                        [new] policies/requests/cost centers
│       │   ├── agency/                           [new] packages/departures/inventory
│       │   ├── bookings/                         [new] customers/travelers/claims
│       │   ├── suppliers/                        [new] reservations/provider adapters
│       │   ├── commerce/                         [new] ledger/payments/refunds
│       │   ├── files/                            [new] document access/retention
│       │   └── audit/                            [new] scoped immutable events
│       ├── migrations/versions/                  [extend] additive Alembic revisions
│       ├── tests/                                [extend] retain existing tests
│       │   ├── tenancy/                          [new]
│       │   ├── policy/                           [new]
│       │   ├── corporate/                        [new]
│       │   ├── agency/                           [new]
│       │   └── commerce/                         [new]
│       └── openapi.json                          [extend] complete new contracts
├── packages/
│   ├── ui/src/                                  [extend] shared components/tokens
│   ├── api-client/src/                           [extend] generated contracts/client
│   ├── types/src/                                [extend] IDs and frontend domain types
│   └── config/                                   [extend] common tooling
├── data/
│   ├── catalog/                                  [extend] versioned catalog artifacts
│   ├── runtime/                                  [existing] ignored local private data
│   └── seeds/                                    [extend] reviewed non-private fixtures
├── infra/
│   ├── docker/                                   [extend] API, DB, cache, worker, beat
│   ├── github/workflows/                         [extend] canonical workflows
│   ├── terraform/                                [extend] implement after host choice
│   ├── tools/                                    [extend] audits/import/backfill checks
│   └── tests/                                    [existing]
├── tests/e2e/                                    [new] browser journeys across modes
├── docs/
│   ├── plans/enterprise-platform-implementation-plan.md
│   ├── decisions/                                [new] architecture decision records
│   ├── domains/                                  [new] ownership and lifecycle contracts
│   └── runbooks/                                 [new] tenancy, queues, restore, commerce
└── .github/workflows/                            [existing] synchronized CI copies
```

### Module conventions and ownership

For each new backend domain, begin with `models.py`, `schemas.py`, `repository.py`, `services/`, `routes/`, and `__init__.py`; add `events.py` only when needed. A route validates input and context; a service authorizes and executes a use case; a repository reads/writes within the verified scope. The application factory registers blueprints. Register new model modules in `_import_all_models()` and Alembic metadata discovery, otherwise startup parity checks and migrations will miss them.

For each new frontend feature, use `components/`, `pages/`, `hooks/`, `api.ts`, `types.ts`, and colocated styles/tests as needed. Do not duplicate shared API types already generated from OpenAPI. Extend `apps/web/tsconfig.json` to cover new TS/TSX files, while retaining the legacy JavaScript migration boundary.

Keep domain logic out of `core`. For example, `core/policy` evaluates decisions, but organization role assignments are owned by `organizations`, responsibility rows by `trips`, and commercial payment records by `commerce`. Use service interfaces or events across domains; avoid arbitrary writes to another domain's tables. Gradually change existing services that open their own sessions to accept a caller-managed transaction when a use case must atomically save several domain changes and an outbox event.

Do not create another auth implementation, another expense engine, or duplicate the Group Planner for each mode. Shared UI belongs in `packages/ui`; permission enforcement remains on the Python server.

## 4. Core data model

### Identity and workspace ownership

Retain global `users` and `user_sessions`. Add:

| Entity | Important fields and invariant |
| --- | --- |
| `workspaces` | UUID, kind PERSONAL/CORPORATE/AGENCY, display name, status; personal owner where applicable. Enforce one personal workspace per user. |
| `workspace_memberships` | Workspace, user, active/revoked status and membership revision. Organization membership can extend this row rather than maintaining a second conflicting status. |
| `organizations` | One-to-one workspace, verified business profile, billing contacts, region. |
| `organization_role_assignments` | Membership, organization role/group; support multiple grants. Organization Owner is distinct from Trip Owner. |
| `workspace_invitations` | Workspace, intended role, verified recipient, token digest, expiry, redemption limit, revocation. |
| `resource_access_grants` | User or verified guest, workspace, resource, allowed actions, expiry, reason. Trip invitees gain only the invited resource scope. |
| `capability_grants` | Actor, action, workspace/trip/resource scope, expiry, grantor and revocation history. |
| `plans`, `subscriptions`, `feature_entitlements`, `usage_meters` | Purchased features/limits; not substitutes for actor authorization. Pilot plans may be assigned manually before paid billing exists. |

Users in a friend's personal trip must not gain access to that friend's income or other trips. Workspace membership is necessary context, not blanket permission. Resource-scoped grants also support one user participating in multiple personal workspaces without making them workspace administrators.

### Extend existing operational records

1. Add `workspace_id`, `mode`, `status`, and `revision` to `travel_groups`. Treat its existing UUID as the logical trip ID; expose a new `/trips` API facade if useful without creating a duplicate trip table.
2. Add workspace ownership to expense `groups`. Scope standalone personal income and expenses to their user's personal workspace. A trip-linked expense group must belong to the same workspace as the trip.
3. Add canonical `access_role` to `gp_group_members` during compatibility rollout. Map `creator` to `owner`; preserve existing wire fields until consumers migrate. Eventually retire the legacy storage field in a separate revision.
4. Add `trip_responsibility_assignments`, allowing multiple duties per member and shared duties across members. Backfill from `crew_role`; use an explicitly documented legacy projection during compatibility.
5. Introduce `itinerary_revisions`, `trip_publications`, `itinerary_proposals`, `change_notices` and `change_acknowledgments`. Keep existing places/documents as editable sources initially; save complete published snapshots and immutable publication identifiers.
6. Add stable catalog references to itinerary stops, plus a snapshot of name, coordinates and relevant verified facts. Custom places remain explicit custom records.
7. Extend existing audit coverage through a new platform audit module; add `workspace_id`, actor, action, resource, correlation ID, policy reason and safe change metadata. Preserve existing historical expense and audit records.
8. Add `outbox_events` and consumer deduplication records. The event and business state must commit in the same database transaction.

Children must have a verifiable workspace ownership chain. Store workspace IDs on independently queried, exported, queued or RLS-protected records. Enforce same-workspace relationships with composite keys/foreign keys where applicable, rather than trusting duplicated IDs. Index workspace plus the actual filter/order columns; scope customer-visible business reference uniqueness to the workspace.

### Corporate, agency and commercial entities

| Domain | Tables to add when the phase begins |
| --- | --- |
| Corporate | `departments`, `cost_centers`, `manager_assignments`, `travel_policies`, `travel_policy_versions`, `travel_requests`, `policy_evaluations`, `expense_reports` |
| Approvals | `approval_requests`, `approval_steps`, `approval_decisions`; bind approvals to exact target revision, action, amount and currency where relevant |
| Agency | `tour_packages`, `package_versions`, `departures`, `departure_inventory`, `inventory_holds`, `departure_staff_assignments`, `operational_incidents` |
| Bookings | `customers`, `travelers`, `bookings`, `booking_travelers`, `booking_access_grants`, `booking_change_requests` |
| Suppliers | `suppliers`, `supplier_reservations`, `supplier_confirmation_events` |
| Commerce | `ledger_accounts`, `ledger_transactions`, `ledger_entries`, `payment_intents`, `provider_webhook_events`, `invoices`, `refund_requests`, `refunds`, `reconciliation_runs` |
| Files | `documents`, document grants, storage object reference, scan status, sensitivity, retention/deletion metadata |

An agency departure links to an agency-workspace trip for reusable itinerary/map/chat functionality. A package is a reusable product; a departure has dates/capacity; a booking belongs to a departure. Customer/traveler rows do not imply staff membership. Copy a specific package version into a departure draft; later package edits must not silently change sold departures.

For new commerce APIs use decimal strings or integer minor units with currency-specific precision. Existing shared expenses currently assume two decimal places in parts of the implementation: preserve those contracts and audit supported currencies before broadening them. Never use the shared-expense balance table to represent customer collections, supplier payouts or platform revenue. Commercial ledger postings must balance within each currency, remain append-only, and use compensating entries for corrections.

Keep local itinerary date/time and IANA timezone alongside UTC event timestamps. Version policy, quotes and published documents so historical decisions can be reconstructed.

## 5. Tenant isolation and permissions

### Verified context at every boundary

Use explicit workspace routes for new APIs, for example `/api/v1/workspaces/{workspace_id}/trips`. Validate the path workspace against the actor's membership or resource grant and the loaded object's ownership. A browser-selected workspace ID is input, not proof of access.

Resolve context per request/tab. Do not make one globally mutable server-side active-workspace setting the authority for every tab. Legacy URLs resolve their trip/group's workspace server-side and apply the same checks. Unknown or unauthorized IDs should not reveal other tenants' record existence.

Every service receives an actor/context plus resource. Evaluate:

```text
authenticated identity or sufficiently verified guest
  + active membership or exact resource grant
  + matching workspace ownership
  + trip/booking visibility
  + capability or applicable base role
  + feature entitlement and quota
  + valid lifecycle state
  + exact current approval when required
  + field/document privacy rules
  = ALLOW, DENY, or REQUIRE_APPROVAL
```

Trip roles remain exactly Owner, Admin, Member, Viewer. Treasurer, Navigator and Culture Scout are duties. Organization roles include Owner, Admin, Operations Manager, Finance Manager, Staff/Employee and Auditor. Define named capabilities such as `trip.publish`, `request.approve`, `booking.manage`, `manifest.read_limited`, `finance.prepare_refund`, `finance.approve_refund`, and `finance.execute_refund`.

Return `allowed_actions` for UI rendering, but re-evaluate every mutation on the server. Organization ownership does not grant access to personal data; global `is_admin` does not become a bypass for customer APIs. Support access uses explicit reasoned, expiring and audited grants.

### Surfaces that must inherit the scope

- SQL queries, counts, autocomplete, reports and exports.
- Redis cache keys, query persistence, IndexedDB, optimistic mutations and stale responses.
- Socket room joins, event delivery and revocation; scope rooms by workspace/resource and do not broadcast private booking/finance payloads to trip-wide rooms.
- Jobs, retries and outbox consumers. Carry actor, workspace, resource and correlation IDs; reload ownership and current permission before sensitive work. System tasks use a narrowly defined service principal.
- Files, presigned URL issuance, thumbnails, generated PDFs and document search.
- AI retrieval, conversation state, summaries, tool actions and logs.

On workspace switch: cancel requests, retire subscriptions, clear displayed tenant state, select the new scoped cache, revalidate membership and join authorized rooms. Include user/workspace/resource in private query keys and persistence namespaces. Discard late responses from the old context. Revocation clears cached private data and blocks queued actions; do not log the user out of unrelated personal/organization sessions unnecessarily.

Add PostgreSQL row-level security as a second barrier for operational tenant tables. Use transaction-local tenant context on the same connection as the query, test pool reuse and workers, and use an application role without ownership or `BYPASSRLS`. Use a separate migration role and `FORCE ROW LEVEL SECURITY` where appropriate. PostgreSQL documents owner/superuser bypass behavior, so merely enabling RLS is insufficient: [PostgreSQL 16 row security](https://www.postgresql.org/docs/16/ddl-rowsecurity.html). RLS still does not implement trip capabilities or field-level privacy.

## 6. Catalog and maps

Start with one catalog repository interface inside `places`. Adapt the current planner source while reconciling it with the v2.1 target schema. Preserve old numeric/source IDs through `(source, source_id) -> canonical_place_id` mappings; do not assume equal IDs in different files represent the same place.

Publish a versioned catalog artifact with manifest, schema version, checksum, row counts, source/provenance details and retrieval instructions. Supply it to development, CI and Docker in a reproducible way; a private local untracked file is not a deployment strategy. The catalog can remain read-only SQLite initially, then move behind the same interface to a dedicated PostgreSQL catalog schema if operational needs justify it.

Migration acceptance: inventory/checksums, integrity/foreign-key checks, duplicate review, FTS coverage, sampled API results, coordinate validation, provenance/license review and a dry-run reference mapping report. Preserve all source data and existing trip references. While catalog and operations are in separate databases, validate catalog references through the service; do not attempt a cross-database SQL foreign key.

Keep the current MapLibre/OpenFreeMap integration. Add provider adapters for routing/ETA and geocoding only when needed. Straight-line ordering must not be presented as a road route. Track attribution, freshness and confidence. Hours, ticket prices, capacity and booking confirmation require distinct authoritative data; having a place pin does not establish availability.

## 7. Frontend navigation and screens

Use one customer web application with workspace-aware layouts. Keep the public discovery and demo journeys. Proposed routes:

| Route | Screen and access |
| --- | --- |
| `/workspaces` | Membership/resource access selector |
| `/w/:workspaceId` | Personal, corporate or agency dashboard |
| `/w/:workspaceId/trips/:tripId` | Existing planner extended with draft/publication status |
| `/w/:workspaceId/settings/members` | Organization staff and role administration |
| `/w/:workspaceId/settings/policies` | Organization policy administration |
| `/w/:workspaceId/requests` | Employee requests and scoped manager queue |
| `/w/:workspaceId/approvals` | Assigned approval tasks |
| `/w/:workspaceId/packages` | Agency package library/builder |
| `/w/:workspaceId/departures/:departureId` | Operations, capacity, staff, manifests |
| `/w/:workspaceId/bookings` | Authorized agency booking administration |
| `/bookings/:bookingId` | Verified customer's own booking, documents and published itinerary |

Keep `/group-planner/:groupId`, `/expenses/...` and existing invitation URLs functional through adapters or redirects after the new context is resolved. Preserve invitation intent through login/signup. Introduce distinct friend, staff and booking-claim invitation flows.

Reuse the six current planner tabs: Itinerary, Library, Logistics, Circle, Treasury and Pulse. Configure tab availability and actions through verified entitlements and capabilities. Add publication/review banners and proposal conflicts within the same planner. Corporate screens prioritize policy/request status; agency screens prioritize departure operations; travelers see a simpler portal without internal margins or package setup.

First shared UI additions: workspace switcher, status chip, approval banner, permission-aware action menu, responsibility badges, audit timeline and accessible data table. Keep existing tested navigation and maps while migrating feature by feature. On mobile, retain itinerary/map tabs and clear next actions.

## 8. API and event contracts

Retain `/api/v1`, existing cookie credentials, CSRF behavior, UUID strings and the existing success envelope. Add pagination, structured validation errors, request IDs, explicit state and `allowed_actions`. New mutation endpoints accept a revision/ETag where concurrent edits matter and return a conflict for stale updates.

| Proposed endpoint | Main control |
| --- | --- |
| `GET /api/v1/workspaces` | Return only accessible workspace summaries; resource guests get narrowed context |
| `POST /api/v1/workspaces` | Identity, creation entitlement, organization onboarding rules |
| `GET/POST /api/v1/workspaces/{w}/trips` | Scope list/create to workspace and mode |
| `PATCH /api/v1/workspaces/{w}/trips/{t}/draft` | Edit capability plus optimistic revision check |
| `POST /api/v1/workspaces/{w}/trips/{t}/publish` | Publish capability, exact revision and approval |
| `POST/DELETE /api/v1/workspaces/{w}/trips/{t}/responsibilities/...` | Assignment capability and active target membership |
| `POST /api/v1/workspaces/{w}/travel-requests` | Corporate member, policy evaluation and cost center |
| `POST /api/v1/workspaces/{w}/approvals/{a}/decision` | Current assigned approver, unexpired exact target |
| `POST /api/v1/workspaces/{w}/packages/{p}/departures` | Agency operations capability and package version |
| `POST /api/v1/workspaces/{w}/departures/{d}/holds` | Server-derived inventory, expiry and atomic allocation |
| `POST /api/v1/workspaces/{w}/departures/{d}/bookings` | Valid hold, actor/customer scope, idempotency |
| `GET /api/v1/bookings/{b}/portal` | Exact verified booking grant; filtered response |
| `POST /api/v1/workspaces/{w}/refund-requests` | Prepare capability; execution is a separate approved command |
| `POST /api/v1/payment-webhooks/{provider}` | Provider signature, raw-body validation, deduplication and internal tenant resolution |

Payment webhooks use provider authentication rather than browser CSRF/cookies. Apply only a narrowly scoped CSRF exemption to that endpoint, and derive workspace from the known provider account/payment mapping, never from unverified metadata alone.

Events include `trip.published`, `membership.revoked`, `invite.accepted`, `request.approved`, `booking.confirmed`, `payment.succeeded`, and `trip.change_acknowledgment_required`. Use event UUID, schema version, workspace/resource IDs, safe payload and correlation ID. Outbox delivery is at least once; consumers deduplicate and handle out-of-order provider events. Store sensitive details in authorized records rather than broad event payloads.

Existing Redis idempotency is useful but insufficient for commerce durability. Add database uniqueness/request fingerprints and provider idempotency; scope replay by workspace, actor, operation and request body. Re-check current authorization before returning a stored private result, including after membership revocation. A lost Redis key must not permit another charge.

Extend `infra/tools/export_openapi.py` to describe real new schemas, regenerate `packages/api-client`, and add contract tests. Do not hand-edit generated declarations. Keep compatibility adapters at route/client boundaries rather than duplicating business rules.

## 9. Workflows and consistency

### Personal and publication

Create draft -> invite participants -> collect suggestions/polls -> edit a versioned draft -> review -> publish immutable snapshot -> travel -> settle -> archive. Preserve existing collaborative defaults through an explicit personal policy. A stale editor gets a conflict with the latest revision. A subsequent draft never silently changes the published traveler document.

### Corporate

Employee request -> evaluate a versioned policy -> manager/finance queue -> approval bound to request and quote -> coordinator itinerary -> receipt/expense report -> reconciliation. Scope managers to assigned direct reports/cost centers. Any material amount, date, destination or currency change invalidates the relevant approval. Emergency changes have a separate logged escalation path.

### Agency

Package draft -> review/publish package version -> create departure -> set inventory -> hold seats -> create booking -> obtain payment/supplier confirmation -> publish operational itinerary -> fulfill -> reconcile/archive. Implement cancellation, waitlist, failed supplier confirmation and material change handling explicitly.

Seat holds are expiring records. Use a PostgreSQL transaction with locking or an atomic conditional capacity update so active holds plus confirmed allocations never exceed capacity. Expiry workers release holds idempotently. Capacity changes and conversion to booking must observe the same invariant. Test payment arriving after hold expiry; send it to a controlled reallocation/refund workflow rather than overbooking.

Payment status, booking status and supplier status are independent. A successful browser redirect is not confirmation. Verify signed webhooks, tolerate duplicates/out-of-order delivery and reconcile against provider records. Refund approvals bind to exact booking/payment, amount/currency and policy version; prevent self-approval where separation of duties applies. Supplier cancellation and seat release follow verified reservation state.

## 10. AI, files and operations

Extend Scout/Crew rather than replacing them. Catalog recommendations, route proposals and budget drafts pass through the same policy services as human requests. The model cannot publish, approve a refund, elevate a role or confirm a supplier by generating text. Re-authorize when an approved proposal executes, not only when generated.

Namespace AI memory/cache by workspace and permitted resource, retain consent controls, and keep passports/medical information out of general retrieval. Evaluate grounded place IDs, prompt injection, privacy, permission refusal, currency arithmetic, stale approvals and retry behavior. Record trace IDs and safe outcome metadata.

Keep local disk storage for development behind an adapter; use private object storage for enterprise files. Enforce purpose/visibility per traveler and document, scanning/quarantine before release, encryption, short-lived URLs and retention. Existing trip-wide vault membership checks are not enough for unrelated customers' passports. For especially sensitive documents, use an authenticated download proxy when immediate revocation is required; already issued presigned URLs remain usable until expiry.

Run API, worker and one scheduler separately. Docker currently has a worker profile but no beat service; add beat for hold expiry, outbox delivery and reconciliation scheduling. Retain the existing Redis dead-letter mechanism, redact raw task args/tracebacks, and add durable failed-delivery records and an audited retry action. Monitor backlog age and outcome rather than task counts alone.

Production needs managed PostgreSQL backups/PITR, private storage, secrets, HTTPS, staging, deployment rollback, request/tenant/actor correlation and alerts. Shared PostgreSQL backups restore the cluster; tenant-specific recovery/export requires its own tested process and must not be advertised as automatic tenant-level PITR. Define latency/error/queue targets from a baseline and pilot load. Track financial reconciliation drift separately.

## 11. Safe migration and rollout

Use expand -> backfill -> verify -> enforce -> contract. Never rewrite published Alembic history or recreate operational databases as a migration shortcut.

1. Establish baseline: record current migration head, run existing verification, inventory live database configuration and rehearse a backup/restore. Use disposable fixtures for development and tests.
2. Add workspace/membership/grant tables and nullable ownership columns. Add code that writes scope for new records before backfilling old ones.
3. Create one personal workspace per existing user. Assign each existing trip to its creator's personal workspace; preserve invited members through resource grants. Standalone expense groups use their creator's personal workspace; personal income/expenses use their owner's personal workspace.
4. Audit linked trip/expense groups before assignment. If ownership conflicts or one expense group is linked across differently owned trips, flag it for explicit resolution; do not infer an organization from shared email or silently copy financial history. Accounts, IDs, balances and invitation targets remain stable.
5. Backfill ownership in bounded batches, with restart checkpoints and dry-run counts. Verify every child chain, every financial link, orphan detection and before/after financial totals by group/currency.
6. Backfill `access_role` and responsibility rows. During compatibility, use one authoritative writer and tested projections to legacy fields; avoid indefinite dual-write disagreement.
7. Add policy enforcement to every existing route/service, export, worker, socket and file path. Legacy APIs must not become an unscoped escape route. Keep the public catalog read path explicitly separate.
8. Verify frontend cache separation, late-response handling, revocation and multi-tab behavior. Migrate old persisted data by clearing/rekeying private caches.
9. Enforce not-null scope, same-workspace constraints and production RLS after backfill validation. Rehearse both fresh-install and existing-data upgrades in PostgreSQL.
10. Enable workspace UI for an internal pilot, then personal users, then one corporate/agency pilot at a time. Retire legacy fields/routes only after consumer migration and an explicit deprecation window.

Rollback first disables the new feature and deploys a schema-compatible application version. Keep additive data intact. Destructive column drops and finance transformations require a later maintenance plan; downgrading code is not equivalent to restoring data.

## 12. Delivery phases and acceptance gates

Ranges below are planning estimates in engineering weeks of focused work for one experienced full-stack developer with review/QA support. They are not commitments. They exclude provider onboarding, legal/contract decisions, customer feedback delays and large data-cleaning surprises. Re-estimate after the baseline and tenant pilot; a larger team does not remove dependency order.

| Phase | Scope | Estimate | Exit gate |
| --- | --- | --- | --- |
| 0A: Baseline and catalog decision | Passing baseline, data inventory, catalog adapter/artifact, ownership ADR | 1-2 weeks | Reproducible fresh setup and approved migration mapping |
| 0B: Platform foundation | Workspaces, memberships/grants, policy, entitlements, ownership backfill, private cache/socket/job scope, audit/outbox skeleton, PostgreSQL CI | 5-8 weeks | Cross-tenant denial tests pass on real PostgreSQL; legacy features still work |
| 1: Personal product completion | Multiple duties, proposals/conflicts, publication snapshots, change notices, resilient invitations/tasks/expenses | 3-5 weeks | Family trip create-to-archive journey passes with all four roles |
| 2: Corporate pilot | Organization onboarding, MFA/admin safeguards, cost centers, manager routing, versioned policies/approvals, receipt reports | 5-8 weeks | Audited employee request-to-reconciliation pilot |
| 3: Agency pilot | Packages/departures, capacity/holds, traveler records, scoped portal, supplier status, guide operations | 6-10 weeks | Sample departure managed without oversell or traveler-data leakage; manual/offline collection only |
| 4: Commerce | PSP adapter, durable idempotency, ledger, invoices/refunds, webhook/reconciliation operations | 5-8 weeks | Sandbox and pilot financial invariants pass, including failure/retry cases |
| 5: Enterprise expansion | SSO/SCIM, advanced audit/retention, branding, integrations, measured scaling | Separate scoped estimates | Contract-specific security and operational readiness |

Phases 0A through 1 represent roughly 9-15 engineering weeks under these assumptions. Phases 0A through 4 represent roughly 25-41 engineering weeks. They are a basis for sequencing and resourcing, not a promised launch date. Corporate and agency product design can overlap once the foundation contracts are stable. Prioritize one pilot customer type if commercial demand changes the order.

Every phase includes tests, documentation, telemetry, migrations and rollout controls. Do not leave tenant isolation or payment consistency for a final hardening phase.

### First implementation sequence

| Order | Reviewable change | Main paths | Completion evidence |
| --- | --- | --- | --- |
| 1 | Baseline and architecture decisions | `docs/decisions`, `infra/tools`, current catalog docs | Verification report, catalog manifest proposal, ownership/role compatibility mapping |
| 2 | Add workspace schema and model registration | `app/workspaces`, `app/organizations`, migrations, DB model imports | Fresh and existing-data migration tests; personal workspace uniqueness |
| 3 | Add scoped service context/policy and one trip vertical slice | `app/core/tenancy`, `app/core/policy`, trip routes/services | Two-workspace read/write denial tests through both new and legacy URLs |
| 4 | Backfill ownership and cover remaining private domains | Trips, expenses, scout, notifications, vault, workers, sockets | No null/orphan/conflicting scope; preserved balances; revocation tests |
| 5 | Introduce workspace frontend and contracts | New workspace feature, API client, query/cache utilities, router | Switch/multi-tab/late-response tests; login and invite regressions |
| 6 | Add entitlements, scoped audit/outbox and PostgreSQL/RLS gates | New platform modules, workflows, migrations | Transaction rollback/delivery replay tests and pooled-connection isolation |
| 7 | Introduce multi-duty assignments and canonical role adapter | Trip models/services, Circle tab, existing role tests | Multiple badges work; badges do not escalate capability |
| 8 | Add publication/proposal flow | Itinerary models/services, editor, notification consumers | Stale drafts rejected; published snapshot and acknowledgment remain stable |

Until step 6 passes across private domains, workspace UI remains limited to the internal migration pilot. Steps are dependency-ordered review units and may require several pull requests each.

## 13. Verification strategy

Run the existing `pnpm verify` baseline with the project's Python environment before implementation. This planning task did not run the complete suite or launch a production stack. Retain existing invitation, auth, expense integrity, group permissions, websocket, map and migration regression suites.

Add focused tests for new behavior:

- Policy unit matrix: four trip roles, organization roles, duties, grants, expiry, lifecycle, feature limits and approval separation.
- PostgreSQL integration tests: tenant predicates/RLS, connection reuse, same-workspace foreign keys, backfills, locking and concurrent seat allocations. SQLite tests alone cannot certify these.
- API contract tests: actual response schemas, old/new route compatibility, pagination, CSRF, idempotency fingerprint conflicts and revoked replay access.
- Lifecycle tests: published snapshots, version conflicts, expired/revised approvals, supplier/payment disagreement and cancellation recovery.
- Delivery tests: transaction rollback has no event, committed event survives worker outage, duplicate consumer delivery has no duplicate business effect.
- Security tests: workspace A cannot read/count/export/search workspace B; resource guest cannot browse owner finances; removed member loses jobs/socket/file access; staff cannot read unrelated traveler documents.
- Browser journeys: one user switches personal/company/agency contexts; full family trip; corporate approval; agency reservation; verified traveler portal; mobile and keyboard access.
- AI evaluations: grounded catalog IDs, injection refusal, no privilege escalation, no fabricated booking confirmation and correct actor scope on execution.
- Commerce provider sandbox and concurrency tests: duplicate/out-of-order webhooks, stale holds, request timeouts, partial refunds, ledger balancing and reconciliation recovery.

Extend CI to use PostgreSQL/Redis services for applicable tests and browser end-to-end checks. Edit `infra/github/workflows`, then run `pnpm workflows:sync`; `.github/workflows` is the synchronized discovery copy. Regenerate and verify OpenAPI/client declarations as the current CI already expects.

## 14. Decisions and boundaries

Proceed with these defaults: React/Vite plus Flask; PostgreSQL enterprise operations; existing trip/expense IDs and domain behavior; shared workspace application; internal admin separated; read-only catalog adapter first; manually assigned pilot entitlements; no live payment processing until commerce readiness.

Resolve the following before their dependent milestone, without blocking unrelated foundation work:

| Decision | Needed before | Suggested owner |
| --- | --- | --- |
| Which catalog release is authoritative and how it is distributed | Catalog cutover | Engineering/data |
| First corporate or agency pilot and its precise acceptance scope | Phase 2/3 commitment | Product/customer |
| Hosting region/provider, recovery targets and storage | External enterprise pilot | Engineering/operations |
| MFA/identity provider and account-linking approach | Organization admin pilot; SSO later | Security/engineering |
| Organization verification and ownership transfer policy | Organization onboarding | Product/operations |
| Merchant of record, PSP account model, currencies and supplier settlement responsibilities | Live commerce | Business/finance/legal |
| Traveler document collection/retention and support-access policy | Traveler PII pilot | Product/security |
| Map/media data rights and production provider terms | Public/commercial launch | Data/business |
| Billing plans, quotas and actual enterprise pricing | Paid platform subscriptions | Product/finance |

Defer full flight ticketing/GDS, broad marketplace payouts, native mobile apps, dedicated tenant deployments, generalized customer scripting, ERP-scale integrations and microservice decomposition until a concrete customer or measured load justifies them.

## 15. Evidence and reference map

- Blueprint pages 4-7: workspace isolation, access roles, multiple responsibility assignments and entitlements.
- Blueprint pages 8-11: corporate/agency/customer journeys, lifecycles, publication and screen structure.
- Blueprint pages 12-16: modular architecture, catalog, tables, APIs/events, AI and maps.
- Blueprint pages 17-22: commerce consistency, privacy, operations, acceptance criteria and roadmap.
- Current source: `services/api/app/core/factory.py`, `core/config.py`, `core/db/connection.py`, `core/idempotency.py`; `auth/models.py`, `trips/models.py`, `expenses/models.py`; `places/services/planner_catalog_service.py`; `trips/services/vault_service.py`; `scout/services`; `core/workers`.
- Current UI/tooling: `apps/web/src/App.jsx`, planner features/hooks/cache utilities, `apps/web/tsconfig.json`, `apps/admin/src/App.tsx`, shared API packages, `infra/docker/docker-compose.yml`, canonical CI/deploy workflows and structure checks.
- Existing supporting docs: `docs/architecture.md`, `docs/api.md`, `data/catalog/README.md`, `docs/reports/sql-seed-audit/report.md`. Some catalog descriptions need updating after reconciliation.
- Flask's documented application-factory pattern supports retaining the current blueprint/module approach: [Flask application factories](https://flask.palletsprojects.com/en/stable/patterns/appfactories/). Applying that pattern to these new domains is this plan's recommendation.
- PostgreSQL's documented RLS bypass and default-deny behavior inform the database barrier design: [PostgreSQL 16 row security](https://www.postgresql.org/docs/16/ddl-rowsecurity.html).
- TanStack documents that query keys identify cached data and include variables used by a query. Including verified actor/workspace context is this plan's isolation recommendation: [TanStack Query keys](https://tanstack.com/query/latest/docs/framework/react/guides/query-keys).

Only this plan was authored. Application source, existing database contents, the supplied PDF and the unrelated working-tree files were not changed by the planning work.
