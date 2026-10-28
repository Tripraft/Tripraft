# Published file guide

Group planner additions on 2026-10-27 are documented in the
[planner guide](guides/group-planner.md):

| File | What it does |
|---|---|
| [apps/web/src/__tests__/plannerTime.test.js](../apps/web/src/__tests__/plannerTime.test.js) | Checks UTC/local timestamp conversion, calendar dates and bounded invitation batches. |
| [apps/web/src/__tests__/plannerUploads.test.jsx](../apps/web/src/__tests__/plannerUploads.test.jsx) | Verifies browser checks at and around the 10 MB upload limit. |
| [docs/guides/group-planner.md](guides/group-planner.md) | Describes planner writes, immutable polls, local timestamps, uploads and Treasury behavior. |
| [docs/archive/reports/group-planner-latency-2026-10-27.md](archive/reports/group-planner-latency-2026-10-27.md) | Records planner changes, measurement scope and validation. |
| [docs/operations/group-planner-latency-evidence-2026-10-27.json](operations/group-planner-latency-evidence-2026-10-27.json) | Stores isolated before/after HTTP timing and SQL count samples. |
| [services/api/app/notifications/email/trip_invitations.py](../services/api/app/notifications/email/trip_invitations.py) | Queues bounded trip invitation delivery and rechecks invitation generation/status before SMTP. |
| [services/api/tests/test_planner_latency.py](../services/api/tests/test_planner_latency.py) | Enforces planner create-operation query budgets on a disposable database. |
| [services/api/tests/test_planner_timestamps_and_delivery.py](../services/api/tests/test_planner_timestamps_and_delivery.py) | Checks UTC serializers, poll permissions/immutability, notifications and deferred invitation delivery. |
| [services/api/tests/test_planner_upload_limits.py](../services/api/tests/test_planner_upload_limits.py) | Checks exact-size upload boundaries, bounded reads and HTTP 413 responses. |
| [services/api/app/trips/services/vault_storage.py](../services/api/app/trips/services/vault_storage.py) | Provides the optional private Supabase Storage adapter with bounded downloads and credential-safe errors. |
| [services/api/tests/test_planner_shared_files.py](../services/api/tests/test_planner_shared_files.py) | Verifies same-group file sharing, revoked/outsider denial, storage rollback and private bucket behavior. |
| [services/api/migrations/versions/a06cb5d6e7f9_shared_vault_file_contents.py](../services/api/migrations/versions/a06cb5d6e7f9_shared_vault_file_contents.py) | Adds private document content using the existing database and removes public Data API grants. |
| [services/api/migrations/versions/a06cb5d6e7f9_shared_vault_file_contents.development.json](../services/api/migrations/versions/a06cb5d6e7f9_shared_vault_file_contents.development.json) | Applies the additive file-content table through the approved development startup bridge. |
| [infra/tools/setup_planner_storage.py](../infra/tools/setup_planner_storage.py) | Checks or explicitly creates the optional private object bucket without printing credentials. |

Reviewed on 2026-10-20. This inventory describes all **665 published files**, including **45 documentation files**. [Start with the documentation index](README.md), or read [the repository review](repository-review.md) for publication decisions. Ignored datasets, raw audit exports, checkpoint notes and root planning originals are excluded.

Each description explains the file responsibility. Strict JSON, lockfiles, generated declarations and binary assets are described without adding invalid inline comments. Update this index when published files change.

| Area | Files |
|---|---:|
| `(root)` | 9 |
| `.github` | 4 |
| `apps` | 301 |
| `docs` | 45 |
| `infra` | 22 |
| `packages` | 20 |
| `services` | 264 |

## (root)

| File | What it does |
|---|---|
| [.gitattributes](../.gitattributes) | Defines portable text line endings and binary handling for SQLite catalog files. |
| [.gitignore](../.gitignore) | Keeps local catalogs, Wikidata inputs, source originals, secrets, dependencies and runtime artifacts out of Git. |
| [README.md](../README.md) | Introduces the platform, setup, source layout, external catalog requirements and developer guide entry points. |
| [package.json](../package.json) | Pins workspace tooling and defines root setup-independent verification, generation and development tasks. |
| [pnpm-lock.yaml](../pnpm-lock.yaml) | Locks resolved dependencies for reproducible workspace installation with pnpm. |
| [pnpm-workspace.yaml](../pnpm-workspace.yaml) | Discovers apps, shared packages and the API as pnpm workspace projects. |
| [prettier.config.cjs](../prettier.config.cjs) | Re-exports the shared formatting configuration for repository-root tooling. |
| [start.py](../start.py) | Installs local tools/dependencies and manages native or Docker startup, readiness checks, logs and process shutdown. |
| [turbo.json](../turbo.json) | Defines workspace task dependencies, cache inputs/outputs and persistent development tasks. |

## .github

| File | What it does |
|---|---|
| [.github/CODEOWNERS](../.github/CODEOWNERS) | Assigns repository review ownership to @deeppatel1842. |
| [.github/instructions/intro.instructions.md](../.github/instructions/intro.instructions.md) | Provides repository context and expected collaboration behavior to development assistants. |
| [.github/workflows/ci.yml](../.github/workflows/ci.yml) | GitHub-discovered copy of the canonical CI workflow: validates the workspace, checks generated contracts and uploads frontend builds. |
| [.github/workflows/deploy.yml](../.github/workflows/deploy.yml) | GitHub-discovered copy of the canonical deploy workflow: verifies changes before invoking the configured environment deployment hook. |

## apps

| File | What it does |
|---|---|
| [apps/README.md](../apps/README.md) | Explains both frontend projects and gives a specific purpose for every published app file. |
| [apps/admin/.env.example](../apps/admin/.env.example) | Documents the public API origin and web URL settings; admin API paths already include /api, so the API base defaults to an empty string. |
| [apps/admin/babel.config.cjs](../apps/admin/babel.config.cjs) | Compiles JavaScript, React JSX and TypeScript for Jest, replacing import.meta.env through tests/viteEnvTransform.cjs. |
| [apps/admin/eslint.config.mjs](../apps/admin/eslint.config.mjs) | Re-exports the shared @tripraft/config/eslint rules for the staff application. |
| [apps/admin/index.html](../apps/admin/index.html) | Defines the staff application's root element and main.tsx entry, with noindex/nofollow/noarchive metadata. |
| [apps/admin/jest.config.cjs](../apps/admin/jest.config.cjs) | Runs tests/*.test.jsx in jsdom with Babel transforms and Testing Library DOM assertions. |
| [apps/admin/package.json](../apps/admin/package.json) | Defines @tripraft/admin dependencies and its Vite, ESLint, TypeScript and Jest commands. |
| [apps/admin/src/App.tsx](../apps/admin/src/App.tsx) | Verifies the server account before loading privileged readiness and ingestion-audit data; renders staff login, review panels, refresh and logout controls. |
| [apps/admin/src/PackageReviewPanel.tsx](../apps/admin/src/PackageReviewPanel.tsx) | Lists package submissions by status and shows private content, media and proposed rates; sends versioned approval, correction or rejection decisions with required reasons. |
| [apps/admin/src/PartnerAgreementPanel.tsx](../apps/admin/src/PartnerAgreementPanel.tsx) | Loads the protected agreement draft on demand, renders its text and tables, and links to the original document download. |
| [apps/admin/src/PartnerReviewPanel.tsx](../apps/admin/src/PartnerReviewPanel.tsx) | Paginates supplier applications, displays business and signature evidence, and submits versioned review decisions while blocking self-review controls. |
| [apps/admin/src/StaffLogin.tsx](../apps/admin/src/StaffLogin.tsx) | Submits employee credentials to /api/v1/admin/session and asks App to recheck identity before showing privileged operations. |
| [apps/admin/src/env.d.ts](../apps/admin/src/env.d.ts) | References vite/client so TypeScript recognizes Vite's browser and import.meta.env types. |
| [apps/admin/src/main.tsx](../apps/admin/src/main.tsx) | Mounts App in React StrictMode, loads staff-console styles, and fails explicitly if the HTML root is missing. |
| [apps/admin/src/styles.css](../apps/admin/src/styles.css) | Styles staff login, readiness and audit sections, tables, agreement content, and responsive partner-review controls. |
| [apps/admin/tests/access.test.jsx](../apps/admin/tests/access.test.jsx) | Verifies identity loading, non-admin rejection, retry after API failure, dedicated staff login, and degraded readiness or audit errors. |
| [apps/admin/tests/partners.test.jsx](../apps/admin/tests/partners.test.jsx) | Verifies decision reasons and version payloads, conflict handling without replay, self-review restrictions, and protected agreement reading. |
| [apps/admin/tests/viteEnvTransform.cjs](../apps/admin/tests/viteEnvTransform.cjs) | Provides the Babel visitor that rewrites import.meta.env as process.env during CommonJS Jest execution. |
| [apps/admin/tsconfig.json](../apps/admin/tsconfig.json) | Extends the shared TypeScript configuration and checks src plus vite.config.ts. |
| [apps/admin/vite.config.ts](../apps/admin/vite.config.ts) | Serves the staff app on port 5174, proxies /api to Flask on port 5000, and returns a structured 503 if the proxy cannot connect. |
| [apps/web/.env.example](../apps/web/.env.example) | Documents public API, timeout, branding, support and feature-flag settings; the API base includes /api and OpenFreeMap requires no key. |
| [apps/web/babel.config.cjs](../apps/web/babel.config.cjs) | Compiles JSX and TypeScript for Jest and applies tests/viteEnvTransform.cjs to Vite environment expressions. |
| [apps/web/eslint.config.js](../apps/web/eslint.config.js) | Re-exports the shared @tripraft/config/eslint rules for web source and tests. |
| [apps/web/index.html](../apps/web/index.html) | Defines the traveler app's title, favicon, root element and /src/main.tsx module entry. |
| [apps/web/jest.config.cjs](../apps/web/jest.config.cjs) | Configures jsdom, Babel, test discovery, shared Toast resolution, source aliases, and CSS/SVG mocks. |
| [apps/web/package.json](../apps/web/package.json) | Defines @tripraft/web scripts and dependencies for React, routing, queries, maps, sockets, charts and PDF export. |
| [apps/web/public/favicon.svg](../apps/web/public/favicon.svg) | Defines the SVG browser-tab icon referenced by web/index.html. |
| [apps/web/public/images/ANIMATION_IMAGES.md](../apps/web/public/images/ANIMATION_IMAGES.md) | Maps the current landing-page PNG filenames to CSS animation slots and explains timing, artwork replacement and source evidence. |
| [apps/web/public/images/README.md](../apps/web/public/images/README.md) | Explains the actual public-image structure, browser URL usage, bundled versus uploaded assets, optimization and related source guides. |
| [apps/web/public/images/confuse_man.png](../apps/web/public/images/confuse_man.png) | Supplies the confused-traveler illustration rendered by AnimatedBackground.jsx. |
| [apps/web/public/images/happy.png](../apps/web/public/images/happy.png) | Supplies the celebration illustration rendered by AnimatedBackground.jsx. |
| [apps/web/public/images/man.png](../apps/web/public/images/man.png) | Supplies a traveler character illustration rendered by AnimatedBackground.jsx. |
| [apps/web/public/images/map.png](../apps/web/public/images/map.png) | Supplies the map illustration rendered by AnimatedBackground.jsx. |
| [apps/web/public/images/passport.png](../apps/web/public/images/passport.png) | Supplies the travel-document illustration rendered by AnimatedBackground.jsx. |
| [apps/web/public/images/plane.png](../apps/web/public/images/plane.png) | Supplies the airplane illustration rendered by AnimatedBackground.jsx. |
| [apps/web/public/images/planner-demo/README.md](../apps/web/public/images/planner-demo/README.md) | Records source photo IDs for local demo images and explains that sample people, trips and booking documents are illustrative. |
| [apps/web/public/images/planner-demo/alex.jpg](../apps/web/public/images/planner-demo/alex.jpg) | Supplies Alex's local sample portrait through the demoData.js photo mapping. |
| [apps/web/public/images/planner-demo/alps.jpg](../apps/web/public/images/planner-demo/alps.jpg) | Supplies a local mountain-trip cover for the demo data and demo request responses. |
| [apps/web/public/images/planner-demo/elena.jpg](../apps/web/public/images/planner-demo/elena.jpg) | Supplies Elena's local sample portrait through the demoData.js photo mapping. |
| [apps/web/public/images/planner-demo/kyoto-lanterns.jpg](../apps/web/public/images/planner-demo/kyoto-lanterns.jpg) | Supplies a local sample destination photo through the demoData.js photo mapping. |
| [apps/web/public/images/planner-demo/kyoto-market.jpg](../apps/web/public/images/planner-demo/kyoto-market.jpg) | Supplies a local sample destination photo through the demoData.js photo mapping. |
| [apps/web/public/images/planner-demo/kyoto-pavilion.jpg](../apps/web/public/images/planner-demo/kyoto-pavilion.jpg) | Supplies a local sample destination photo through the demoData.js photo mapping. |
| [apps/web/public/images/planner-demo/kyoto-river.jpg](../apps/web/public/images/planner-demo/kyoto-river.jpg) | Supplies a local sample destination photo through the demoData.js photo mapping. |
| [apps/web/public/images/planner-demo/kyoto-temple.jpg](../apps/web/public/images/planner-demo/kyoto-temple.jpg) | Supplies a local sample destination/trip-cover photo through the demoData.js photo mapping. |
| [apps/web/public/images/planner-demo/kyoto-torii.jpg](../apps/web/public/images/planner-demo/kyoto-torii.jpg) | Supplies a local sample destination photo through the demoData.js photo mapping. |
| [apps/web/public/images/planner-demo/lisbon.jpg](../apps/web/public/images/planner-demo/lisbon.jpg) | Supplies a local Lisbon trip/destination cover for the demo data and demo request responses. |
| [apps/web/public/images/planner-demo/marcus.jpg](../apps/web/public/images/planner-demo/marcus.jpg) | Supplies Marcus's local sample portrait through the demoData.js photo mapping. |
| [apps/web/public/images/planner-demo/sarah.jpg](../apps/web/public/images/planner-demo/sarah.jpg) | Supplies Sarah's local sample portrait through the demoData.js photo mapping. |
| [apps/web/public/images/search.png](../apps/web/public/images/search.png) | Supplies the search illustration rendered by AnimatedBackground.jsx. |
| [apps/web/public/images/travel_man.png](../apps/web/public/images/travel_man.png) | Supplies another traveler character illustration rendered by AnimatedBackground.jsx. |
| [apps/web/public/images/trip_plan.png](../apps/web/public/images/trip_plan.png) | Supplies the trip-planning illustration rendered by AnimatedBackground.jsx. |
| [apps/web/src/App.jsx](../apps/web/src/App.jsx) | Defines lazy-loaded public, invitation and protected routes, supplies AuthProvider and feature recovery boundaries, and allows the opt-in planner demo. |
| [apps/web/src/__tests__/apiClient.test.js](../apps/web/src/__tests__/apiClient.test.js) | Verifies cookies/CSRF, empty and non-JSON responses, one session refresh, GET retries, no ambiguous mutation replay, blobs, cancellation and validation errors. |
| [apps/web/src/__tests__/authPages.test.jsx](../apps/web/src/__tests__/authPages.test.jsx) | Verifies click/Enter/autofill submissions, validation, duplicate prevention, session initialization and invitation/return-state preservation, including disabled storage. |
| [apps/web/src/__tests__/authService.test.js](../apps/web/src/__tests__/authService.test.js) | Verifies cookie restoration/refresh, verification and resend, session rejection versus transient errors, CSRF/logout and token-free local storage. |
| [apps/web/src/__tests__/authSession.test.jsx](../apps/web/src/__tests__/authSession.test.jsx) | Verifies returning-device restoration, identity-before-redirect, retryable login errors, logout cache cleanup and the absence of a mounted idle logout. |
| [apps/web/src/__tests__/cacheAndFreshness.test.jsx](../apps/web/src/__tests__/cacheAndFreshness.test.jsx) | Verifies private-query/mutation persistence exclusions, disabled mutation retries, old-snapshot invalidation, logout cleanup and fresh bootstrap balances. |
| [apps/web/src/__tests__/chatPanelState.test.jsx](../apps/web/src/__tests__/chatPanelState.test.jsx) | Verifies inline message actions, group-switch composer reset, loading state, Crew answer failures and card-specific expense deletion. |
| [apps/web/src/__tests__/chatQuery.test.jsx](../apps/web/src/__tests__/chatQuery.test.jsx) | Verifies optimistic rollback preserves incoming messages, echo deduplication across pages, and results update the original group after a switch. |
| [apps/web/src/__tests__/chatSocket.test.jsx](../apps/web/src/__tests__/chatSocket.test.jsx) | Verifies cookie-authenticated sockets, message/edit reconciliation, read throttling, group changes, reconnect/refresh recovery and revoked-access cleanup. |
| [apps/web/src/__tests__/consentAndSettlement.test.jsx](../apps/web/src/__tests__/consentAndSettlement.test.jsx) | Verifies Scout privacy overrides, visible settlement save failures and client-side over-settlement rejection. |
| [apps/web/src/__tests__/currencyConversion.test.jsx](../apps/web/src/__tests__/currencyConversion.test.jsx) | Verifies original versus converted totals, currency-pair races, stale/unavailable rates, fixed saved currencies and independent calculator pairs. |
| [apps/web/src/__tests__/expenseAnalysisAndDialogs.test.jsx](../apps/web/src/__tests__/expenseAnalysisAndDialogs.test.jsx) | Verifies stored-share analysis, calendar/deleted-row handling, history data, dialog focus/scroll behavior, creation retries and former-member attribution. |
| [apps/web/src/__tests__/expenseFollowupFixes.test.jsx](../apps/web/src/__tests__/expenseFollowupFixes.test.jsx) | Verifies personal history and income classification, deleted-row restore permissions, currency/amount layout, live edit-draft retention and split receipts. |
| [apps/web/src/__tests__/expenseFriends.test.jsx](../apps/web/src/__tests__/expenseFriends.test.jsx) | Verifies friend selection, nickname search, invitation draft retention and loading states. |
| [apps/web/src/__tests__/expenseGroupCreation.test.jsx](../apps/web/src/__tests__/expenseGroupCreation.test.jsx) | Verifies API-compatible group creation fields and preserving the entered name after validation failure. |
| [apps/web/src/__tests__/expenseGroupNavigation.test.jsx](../apps/web/src/__tests__/expenseGroupNavigation.test.jsx) | Verifies exact group URLs, browser back, selected-group restoration, dashboard/empty states and navigation after group creation or invitation acceptance. |
| [apps/web/src/__tests__/expenseGroupOverview.test.jsx](../apps/web/src/__tests__/expenseGroupOverview.test.jsx) | Verifies paid/share/net distinctions, full-ledger summaries, custom splits, deleted expenses and searchable dashboard/error states. |
| [apps/web/src/__tests__/expenseInvitationDelivery.test.jsx](../apps/web/src/__tests__/expenseInvitationDelivery.test.jsx) | Verifies expired-link restrictions, copying without resending, clipboard fallback, invitation permissions and cancellation cleanup. |
| [apps/web/src/__tests__/expenseInvitationFlow.test.jsx](../apps/web/src/__tests__/expenseInvitationFlow.test.jsx) | Verifies copied-link sign-in continuation, one acceptance, disabled-storage recovery, wrong-account handling and already-joined navigation. |
| [apps/web/src/__tests__/expenseLiveUpdates.test.jsx](../apps/web/src/__tests__/expenseLiveUpdates.test.jsx) | Verifies private socket invalidation, burst coalescing, revoked-data cleanup, reconnect/polling recovery, visibility handling and session renewal. |
| [apps/web/src/__tests__/floatingChat.test.jsx](../apps/web/src/__tests__/floatingChat.test.jsx) | Verifies pointer dragging, viewport bounds, click suppression, keyboard movement, saved positions, resize/reset and composer isolation. |
| [apps/web/src/__tests__/groupExpensePermissions.test.jsx](../apps/web/src/__tests__/groupExpensePermissions.test.jsx) | Verifies server edit/delete flags, settlement permissions, one-cent debts, role-based management, confirmed archive and revoked-access controls. |
| [apps/web/src/__tests__/groupLedgerApi.test.js](../apps/web/src/__tests__/groupLedgerApi.test.js) | Verifies complete independent ledger pagination and failure of the full read when a later page denies access. |
| [apps/web/src/__tests__/groupLedgerLoading.test.jsx](../apps/web/src/__tests__/groupLedgerLoading.test.jsx) | Verifies all personal pages include deleted rows, revoked membership removes cached controls/data and group switches do not leak earlier ledgers. |
| [apps/web/src/__tests__/groupPlannerApi.test.js](../apps/web/src/__tests__/groupPlannerApi.test.js) | Verifies full planner collection pagination, later-page errors and supported catalog-place payloads including zero coordinates. |
| [apps/web/src/__tests__/groupPlannerCatalog.test.jsx](../apps/web/src/__tests__/groupPlannerCatalog.test.jsx) | Verifies required catalog selections, optional/deduplicated invites, destination-scoped filters and adding places without invented coordinates. |
| [apps/web/src/__tests__/groupPlannerDemo.test.js](../apps/web/src/__tests__/groupPlannerDemo.test.js) | Verifies local demo request isolation, permitted public reference reads, role checks, reset/settings behavior, polls and independent crew roles. |
| [apps/web/src/__tests__/groupPlannerNewUI.test.jsx](../apps/web/src/__tests__/groupPlannerNewUI.test.jsx) | Verifies trip-card actions, typed-name deletion, date choices, search/pins, safe invitation links and retryable or partial stop-creation failures. |
| [apps/web/src/__tests__/groupPlannerTabs.test.jsx](../apps/web/src/__tests__/groupPlannerTabs.test.jsx) | Verifies exact itemized splits and small settlements, empty trip dates, preserved time slots and independent access/responsibility permissions. |
| [apps/web/src/__tests__/groupPlannerWorkspace.test.jsx](../apps/web/src/__tests__/groupPlannerWorkspace.test.jsx) | Verifies calendar-based itinerary day filtering and optimistic checklist toggling with rollback after failure. |
| [apps/web/src/__tests__/money.test.js](../apps/web/src/__tests__/money.test.js) | Verifies exact cent allocation, UUID participants, invalid amounts, preserved custom splits/payer edits, settlement caps and currency formatting. |
| [apps/web/src/__tests__/openFreeMap.test.js](../apps/web/src/__tests__/openFreeMap.test.js) | Verifies safe provider style expressions, key-free OpenFreeMap attribution, zero/missing coordinates and date-line marker wrapping. |
| [apps/web/src/__tests__/ownerAndInactivity.test.jsx](../apps/web/src/__tests__/ownerAndInactivity.test.jsx) | Verifies UUID owner controls and actual personal share, and tests the optional idle tracker's warning/activity reset in isolation. |
| [apps/web/src/__tests__/p3Behavior.test.jsx](../apps/web/src/__tests__/p3Behavior.test.jsx) | Verifies safe date/file formatting, Crew question transitions, long-trip day lists and map viewport, theme and calendar-day behavior. |
| [apps/web/src/__tests__/personalCurrency.test.jsx](../apps/web/src/__tests__/personalCurrency.test.jsx) | Verifies account-backed currency persistence, save failures and user isolation. |
| [apps/web/src/__tests__/personalDashboard.test.jsx](../apps/web/src/__tests__/personalDashboard.test.jsx) | Verifies mixed-currency personal totals, original records, failed rates and stale response isolation. |
| [apps/web/src/__tests__/plannerHeader.test.jsx](../apps/web/src/__tests__/plannerHeader.test.jsx) | Verifies group count and plain current title, with a return-to-cards group-selection action. |
| [apps/web/src/__tests__/pollFeed.test.jsx](../apps/web/src/__tests__/pollFeed.test.jsx) | Verifies unique voters, option-index vote payloads, creator-only deletion and member-name resolution from UUIDs. |
| [apps/web/src/__tests__/routes.test.jsx](../apps/web/src/__tests__/routes.test.jsx) | Verifies invitation route dispatch and administrator access/unavailable analytics behavior without absent-endpoint calls. |
| [apps/web/src/__tests__/searchCancellation.test.jsx](../apps/web/src/__tests__/searchCancellation.test.jsx) | Verifies stale autocomplete responses cannot replace a newer query and clearing search cancels its pending debounce. |
| [apps/web/src/__tests__/serviceContracts.test.js](../apps/web/src/__tests__/serviceContracts.test.js) | Verifies service timeouts and response-envelope adaptation, preserved place metadata, real search results, rating normalization and coordinate validity. |
| [apps/web/src/__tests__/tripInvitationFlow.test.jsx](../apps/web/src/__tests__/tripInvitationFlow.test.jsx) | Verifies auth restoration, preserved trip invitation type, single StrictMode acceptance, wrong-account/expired links and already-accepted navigation. |
| [apps/web/src/__tests__/verifyEmail.test.jsx](../apps/web/src/__tests__/verifyEmail.test.jsx) | Verifies public verification routing, one request under StrictMode, loading/missing/expired/error states, explicit resend and preserved invitations. |
| [apps/web/src/assets/placeholder-place.svg](../apps/web/src/assets/placeholder-place.svg) | Supplies the local fallback image used by discovery cards and place details when a destination photo is unavailable. |
| [apps/web/src/components/common/css/AnimatedBackground.css](../apps/web/src/components/common/css/AnimatedBackground.css) | Defines positioning and animation timing for the landing-page travel illustrations and brand elements. |
| [apps/web/src/components/common/css/CurrencyConversion.css](../apps/web/src/components/common/css/CurrencyConversion.css) | Styles the currency calculator, totals, rate status, swap/refresh controls and responsive layout. |
| [apps/web/src/components/common/css/DestinationAutocomplete.css](../apps/web/src/components/common/css/DestinationAutocomplete.css) | Styles the destination input, suggestion list, type indicators, loading state and responsive variants. |
| [apps/web/src/components/common/css/ErrorBoundary.css](../apps/web/src/components/common/css/ErrorBoundary.css) | Styles rendering-error recovery panels and query loading, error and cached-data states. |
| [apps/web/src/components/common/css/FeatureErrorBoundary.css](../apps/web/src/components/common/css/FeatureErrorBoundary.css) | Styles feature failure messages, retry controls and development diagnostic details. |
| [apps/web/src/components/common/css/Skeleton.css](../apps/web/src/components/common/css/Skeleton.css) | Defines shimmer animation and shared page, place-card and group-card skeleton geometry. |
| [apps/web/src/components/common/css/UserAvatar.css](../apps/web/src/components/common/css/UserAvatar.css) | Defines avatar sizes, image/initials presentation, optional names and responsive/theme variants. |
| [apps/web/src/components/common/index.js](../apps/web/src/components/common/index.js) | Re-exports shared common components and the workspace Toast from @tripraft/ui/Toast. |
| [apps/web/src/components/common/jsx/AnimatedBackground.jsx](../apps/web/src/components/common/jsx/AnimatedBackground.jsx) | Composes the landing-page travel animation from local PNG illustrations and configured branding. |
| [apps/web/src/components/common/jsx/CurrencyConversion.jsx](../apps/web/src/components/common/jsx/CurrencyConversion.jsx) | Shows original and converted summaries plus an independent currency calculator, including rate freshness, refresh and unavailable-rate states. |
| [apps/web/src/components/common/jsx/CurrencySelect.jsx](../apps/web/src/components/common/jsx/CurrencySelect.jsx) | Loads supported currencies with a local fallback, preserves an existing saved currency, and reports stale or unavailable listings. |
| [apps/web/src/components/common/jsx/DestinationAutocomplete.jsx](../apps/web/src/components/common/jsx/DestinationAutocomplete.jsx) | Debounces destination suggestions, supports keyboard selection and type filters, and returns selected destination metadata to the caller. |
| [apps/web/src/components/common/jsx/ErrorBoundary.jsx](../apps/web/src/components/common/jsx/ErrorBoundary.jsx) | Catches rendering errors with retry/home recovery and exports QueryErrorBoundary for query loading, errors and cached-data fallback. |
| [apps/web/src/components/common/jsx/FeatureErrorBoundary.jsx](../apps/web/src/components/common/jsx/FeatureErrorBoundary.jsx) | Contains a feature's rendering failure and offers retry with development-only diagnostic details. |
| [apps/web/src/components/common/jsx/GroupCardSkeleton.jsx](../apps/web/src/components/common/jsx/GroupCardSkeleton.jsx) | Renders placeholder group-card geometry while group data is loading. |
| [apps/web/src/components/common/jsx/PageSkeleton.jsx](../apps/web/src/components/common/jsx/PageSkeleton.jsx) | Renders the page-level loading skeleton used while lazy routes load. |
| [apps/web/src/components/common/jsx/PlaceCardSkeleton.jsx](../apps/web/src/components/common/jsx/PlaceCardSkeleton.jsx) | Renders placeholder image, title and rating blocks while a place card is loading. |
| [apps/web/src/components/common/jsx/UserAvatar.jsx](../apps/web/src/components/common/jsx/UserAvatar.jsx) | Shows a user's image or derived initials, with size variants and optional display name and click behavior. |
| [apps/web/src/components/layout/css/Footer.css](../apps/web/src/components/layout/css/Footer.css) | Styles footer columns, navigation links, branding and mobile layout. |
| [apps/web/src/components/layout/css/Header.css](../apps/web/src/components/layout/css/Header.css) | Styles the site logo, navigation, authentication controls and responsive mobile menu. |
| [apps/web/src/components/layout/index.js](../apps/web/src/components/layout/index.js) | Re-exports the shared Header and Footer layout components. |
| [apps/web/src/components/layout/jsx/Footer.jsx](../apps/web/src/components/layout/jsx/Footer.jsx) | Renders the configured site branding and product/company navigation links. |
| [apps/web/src/components/layout/jsx/Header.jsx](../apps/web/src/components/layout/jsx/Header.jsx) | Renders site navigation and account actions with a mobile menu, outside-click/Escape dismissal and body-scroll handling. |
| [apps/web/src/config/globalConfig.js](../apps/web/src/config/globalConfig.js) | Centralizes public environment settings, API prefixes, storage keys, search defaults, synchronization intervals and PDF theme values. |
| [apps/web/src/context/AuthContext.jsx](../apps/web/src/context/AuthContext.jsx) | Exposes traveler identity, sign-in, sign-up, profile updates and sign-out; clears query state and persisted caches when signing out. |
| [apps/web/src/env.d.ts](../apps/web/src/env.d.ts) | References vite/client for browser asset imports and import.meta.env TypeScript declarations. |
| [apps/web/src/features/auth/css/Login.css](../apps/web/src/features/auth/css/Login.css) | Styles the boarding-pass login form, decorative panel, validation feedback and responsive layout. |
| [apps/web/src/features/auth/css/Signup.css](../apps/web/src/features/auth/css/Signup.css) | Styles the signup form, password-strength presentation, decorative panel and responsive layout. |
| [apps/web/src/features/auth/index.js](../apps/web/src/features/auth/index.js) | Re-exports traveler login, signup, auth switching, route protection and the optional inactivity tracker. |
| [apps/web/src/features/auth/jsx/AuthPage.jsx](../apps/web/src/features/auth/jsx/AuthPage.jsx) | Switches between the traveler Login and Signup forms within the /auth page. |
| [apps/web/src/features/auth/jsx/InactivityTracker.jsx](../apps/web/src/features/auth/jsx/InactivityTracker.jsx) | Implements an optional 15-minute idle logout with a one-minute warning; current app routes do not mount this component. |
| [apps/web/src/features/auth/jsx/Login.jsx](../apps/web/src/features/auth/jsx/Login.jsx) | Submits traveler login, handles loading and server errors, and preserves invitations or return destinations through authentication. |
| [apps/web/src/features/auth/jsx/ProtectedRoute.jsx](../apps/web/src/features/auth/jsx/ProtectedRoute.jsx) | Waits for traveler session initialization and displays sign-in/signup actions before rendering authenticated content. |
| [apps/web/src/features/auth/jsx/Signup.jsx](../apps/web/src/features/auth/jsx/Signup.jsx) | Validates traveler signup and password confirmation, submits account creation, and preserves invitations or requested return destinations. |
| [apps/web/src/features/auth/utils/authForms.js](../apps/web/src/features/auth/utils/authForms.js) | Provides auth validation, storage helpers that tolerate unavailable browser storage, and invitation/return-destination handling. |
| [apps/web/src/features/discover/css/GroupedPlaceGrid.css](../apps/web/src/features/discover/css/GroupedPlaceGrid.css) | Styles location group headings and horizontally arranged place-card groups. |
| [apps/web/src/features/discover/css/PlaceCard.css](../apps/web/src/features/discover/css/PlaceCard.css) | Styles discovery cards, photos, loading placeholders, badges, hover states and metadata. |
| [apps/web/src/features/discover/css/PlaceDetailModal.css](../apps/web/src/features/discover/css/PlaceDetailModal.css) | Styles the place-detail overlay, photo hero, information sections and responsive dialog layout. |
| [apps/web/src/features/discover/css/PlaceGrid.css](../apps/web/src/features/discover/css/PlaceGrid.css) | Defines responsive column layout and gaps for the place-search grid. |
| [apps/web/src/features/discover/css/PlaceSearchPage.css](../apps/web/src/features/discover/css/PlaceSearchPage.css) | Styles the discovery page, results toolbar, filters and loading/error/empty-state presentation. |
| [apps/web/src/features/discover/css/SearchBar.css](../apps/web/src/features/discover/css/SearchBar.css) | Styles the search input, submit/clear actions, loading indicator and mobile controls. |
| [apps/web/src/features/discover/css/SearchSuggestions.css](../apps/web/src/features/discover/css/SearchSuggestions.css) | Styles autocomplete rows, location-type labels, selection states and the scrollable suggestion list. |
| [apps/web/src/features/discover/index.js](../apps/web/src/features/discover/index.js) | Re-exports discovery components and place-search service functions through one feature entry. |
| [apps/web/src/features/discover/jsx/GroupedPlaceGrid.jsx](../apps/web/src/features/discover/jsx/GroupedPlaceGrid.jsx) | Groups results by city or state and virtualizes larger collections of location groups. |
| [apps/web/src/features/discover/jsx/PlaceCard.jsx](../apps/web/src/features/discover/jsx/PlaceCard.jsx) | Renders a place's photo, location, rating and tags with lazy image loading, a local fallback and map links. |
| [apps/web/src/features/discover/jsx/PlaceDetailModal.jsx](../apps/web/src/features/discover/jsx/PlaceDetailModal.jsx) | Fetches full place details and renders photos, hours, costs, tips and sharing/map actions with modal dismissal behavior. |
| [apps/web/src/features/discover/jsx/PlaceGrid.jsx](../apps/web/src/features/discover/jsx/PlaceGrid.jsx) | Renders responsive place-card rows and virtualizes large result lists. |
| [apps/web/src/features/discover/jsx/PlaceSearchPage.jsx](../apps/web/src/features/discover/jsx/PlaceSearchPage.jsx) | Coordinates catalog search, autocomplete selections, statistics, filtering, sorting and detail dialogs with explicit loading/error/empty states. |
| [apps/web/src/features/discover/jsx/SearchBar.jsx](../apps/web/src/features/discover/jsx/SearchBar.jsx) | Debounces autocomplete requests, discards stale responses, supports cancellation and passes submitted queries or selected suggestions to the parent. |
| [apps/web/src/features/discover/jsx/SearchSuggestions.jsx](../apps/web/src/features/discover/jsx/SearchSuggestions.jsx) | Renders location suggestions with selected-row highlighting and suggestion-selection callbacks. |
| [apps/web/src/features/expenses/css/ExpenseAnalysisView.css](../apps/web/src/features/expenses/css/ExpenseAnalysisView.css) | Styles analysis filters, insight cards, category/daily charts, legends and responsive chart sizing. |
| [apps/web/src/features/expenses/css/ExpenseAnalytics.css](../apps/web/src/features/expenses/css/ExpenseAnalytics.css) | Retains the older exp-analytics dashboard styles; ExpenseAnalytics.jsx currently re-exports the newer ExpenseAnalysisView. |
| [apps/web/src/features/expenses/css/ExpenseDialog.css](../apps/web/src/features/expenses/css/ExpenseDialog.css) | Defines isolated dialog/backdrop geometry, responsive expense forms and a separate currency/amount column layout. |
| [apps/web/src/features/expenses/css/ExpenseGroups.css](../apps/web/src/features/expenses/css/ExpenseGroups.css) | Styles the searchable expense-group dashboard, group detail header and new-group dialog using theme variables. |
| [apps/web/src/features/expenses/css/ExpenseHistoryModal.css](../apps/web/src/features/expenses/css/ExpenseHistoryModal.css) | Styles the expense edit-history timeline, field changes, loading state and responsive dialog contents. |
| [apps/web/src/features/expenses/css/ExpenseManager.css](../apps/web/src/features/expenses/css/ExpenseManager.css) | Defines the main expense interface styles for cards, transactions, members, forms, summaries and action states. |
| [apps/web/src/features/expenses/css/ExpenseResponsive.css](../apps/web/src/features/expenses/css/ExpenseResponsive.css) | Applies shared responsive sizing, wrapping and overflow rules across expense screens and dialogs. |
| [apps/web/src/features/expenses/css/SettlementHistoryModal.css](../apps/web/src/features/expenses/css/SettlementHistoryModal.css) | Styles settlement-history headings, summary figures, payment rows, status indicators and responsive layout. |
| [apps/web/src/features/expenses/css/SettlementModal.css](../apps/web/src/features/expenses/css/SettlementModal.css) | Styles settlement-entry fields, overlay, action buttons, validation feedback and saving indicator. |
| [apps/web/src/features/expenses/index.js](../apps/web/src/features/expenses/index.js) | Re-exports expense UI components and currency definitions for feature consumers. |
| [apps/web/src/features/expenses/jsx/ExpenseAnalysisView.jsx](../apps/web/src/features/expenses/jsx/ExpenseAnalysisView.jsx) | Renders spending insights, category and daily charts, date-range filters and group-total versus saved-share analysis. |
| [apps/web/src/features/expenses/jsx/ExpenseAnalytics.jsx](../apps/web/src/features/expenses/jsx/ExpenseAnalytics.jsx) | Re-exports ExpenseAnalysisView as a compatibility entry for existing expense imports. |
| [apps/web/src/features/expenses/jsx/ExpenseDialog.jsx](../apps/web/src/features/expenses/jsx/ExpenseDialog.jsx) | Provides a portalled expense dialog with focus containment, Escape handling, scroll locking and focus restoration. |
| [apps/web/src/features/expenses/jsx/ExpenseFriendPicker.jsx](../apps/web/src/features/expenses/jsx/ExpenseFriendPicker.jsx) | Searches private saved expense contacts and selects recipients by name or nickname. |
| [apps/web/src/features/expenses/jsx/ExpenseHistoryModal.jsx](../apps/web/src/features/expenses/jsx/ExpenseHistoryModal.jsx) | Fetches an expense's edit history and shows a timeline of field, payer and split changes with member names and currency formatting. |
| [apps/web/src/features/expenses/jsx/ExpenseManager.jsx](../apps/web/src/features/expenses/jsx/ExpenseManager.jsx) | Coordinates personal/group expense data, group selection, transaction editing, invitations, settlements, history, PDF export and live refresh. |
| [apps/web/src/features/expenses/jsx/ExpenseSummary.jsx](../apps/web/src/features/expenses/jsx/ExpenseSummary.jsx) | Calculates visible personal balance/income/spending or group expense totals while excluding deleted transactions. |
| [apps/web/src/features/expenses/jsx/GroupBalances.jsx](../apps/web/src/features/expenses/jsx/GroupBalances.jsx) | Displays member balances, suggests payments, and opens settlement entry with currency conversion for display. |
| [apps/web/src/features/expenses/jsx/GroupDashboard.jsx](../apps/web/src/features/expenses/jsx/GroupDashboard.jsx) | Shows searchable expense-group cards with member avatars, spending trends, personal share and outstanding position. |
| [apps/web/src/features/expenses/jsx/GroupDetailHeader.jsx](../apps/web/src/features/expenses/jsx/GroupDetailHeader.jsx) | Renders the selected group's members, overview figures, navigation and permission-aware add/settle actions. |
| [apps/web/src/features/expenses/jsx/GroupManager.jsx](../apps/web/src/features/expenses/jsx/GroupManager.jsx) | Manages expense-group metadata, membership and invitations with role-aware actions, confirmation and retryable API errors. |
| [apps/web/src/features/expenses/jsx/GroupSummaryCards.jsx](../apps/web/src/features/expenses/jsx/GroupSummaryCards.jsx) | Shows outstanding balance, settlement totals and personal-share figures using the selected display currency. |
| [apps/web/src/features/expenses/jsx/MemberSpending.jsx](../apps/web/src/features/expenses/jsx/MemberSpending.jsx) | Aggregates paid amounts per member, preserves former-member attribution, and renders spending breakdowns. |
| [apps/web/src/features/expenses/jsx/ModeToggle.jsx](../apps/web/src/features/expenses/jsx/ModeToggle.jsx) | Renders the switch between personal and group expense modes. |
| [apps/web/src/features/expenses/jsx/NewExpenseGroupModal.jsx](../apps/web/src/features/expenses/jsx/NewExpenseGroupModal.jsx) | Collects a new expense group's name and original currency, retaining the form when creation fails. |
| [apps/web/src/features/expenses/jsx/PendingInvitations.jsx](../apps/web/src/features/expenses/jsx/PendingInvitations.jsx) | Displays pending expense invitations and coordinates acceptance/decline with immediate parent-state refresh. |
| [apps/web/src/features/expenses/jsx/PersonalTabbedView.jsx](../apps/web/src/features/expenses/jsx/PersonalTabbedView.jsx) | Presents personal transaction history and analysis tabs with type filters and sorting. |
| [apps/web/src/features/expenses/jsx/SettlementHistoryModal.jsx](../apps/web/src/features/expenses/jsx/SettlementHistoryModal.jsx) | Displays settlement records and payment status; confirms authorized deletions and keeps failures retryable. |
| [apps/web/src/features/expenses/jsx/SettlementModal.jsx](../apps/web/src/features/expenses/jsx/SettlementModal.jsx) | Collects payer, recipient, amount and notes, validates against outstanding debt, and closes only after a successful save. |
| [apps/web/src/features/expenses/jsx/SettlementView.jsx](../apps/web/src/features/expenses/jsx/SettlementView.jsx) | Presents suggested debt-clearing payments, settlement entry and settlement history using permission-aware controls. |
| [apps/web/src/features/expenses/jsx/TabbedGroupView.jsx](../apps/web/src/features/expenses/jsx/TabbedGroupView.jsx) | Composes balances, settlements, member spending, transaction history and analysis into the group expense tabs. |
| [apps/web/src/features/expenses/jsx/TransactionActivity.jsx](../apps/web/src/features/expenses/jsx/TransactionActivity.jsx) | Renders transaction activity rows with split/history actions and permission-aware edit, delete and restore controls. |
| [apps/web/src/features/expenses/jsx/TransactionList.jsx](../apps/web/src/features/expenses/jsx/TransactionList.jsx) | Filters, sorts and paginates transactions, renders split receipts/history actions, and preserves deleted-row restoration where permitted. |
| [apps/web/src/features/expenses/jsx/TransactionModal.jsx](../apps/web/src/features/expenses/jsx/TransactionModal.jsx) | Creates or edits personal/group expenses, validating amount, payer and participants while preserving an editing draft across live refetches. |
| [apps/web/src/features/expenses/utils/currencies.js](../apps/web/src/features/expenses/utils/currencies.js) | Defines local currency metadata used as a fallback when the supported-currency API is unavailable. |
| [apps/web/src/features/expenses/utils/expenseAnalysis.js](../apps/web/src/features/expenses/utils/expenseAnalysis.js) | Builds spending totals, saved-share breakdowns, category aggregates and complete calendar-day series while excluding income and deleted entries. |
| [apps/web/src/features/expenses/utils/groupOverview.js](../apps/web/src/features/expenses/utils/groupOverview.js) | Derives group spending, personal share, paid amounts, settlements and net position using server summaries or available ledger data. |
| [apps/web/src/features/expenses/utils/groupPermissions.js](../apps/web/src/features/expenses/utils/groupPermissions.js) | Resolves group, expense and settlement UI permissions from user identity, ownership, roles and server-provided action flags. |
| [apps/web/src/features/expenses/utils/personalTransactions.js](../apps/web/src/features/expenses/utils/personalTransactions.js) | Identifies personal income, including legacy Salary/Income entries, so spending calculations exclude it. |
| [apps/web/src/features/itinerary/css/TripPlanner.css](../apps/web/src/features/itinerary/css/TripPlanner.css) | Styles the single-trip planning form, generated plan cards, timeline, map, suggested places, tips and packing checklist. |
| [apps/web/src/features/itinerary/index.js](../apps/web/src/features/itinerary/index.js) | Re-exports the single-trip planner's form, itinerary, stops, map, suggested places, tips, checklist and icon component. |
| [apps/web/src/features/itinerary/jsx/Checklist.jsx](../apps/web/src/features/itinerary/jsx/Checklist.jsx) | Renders a static travel-packing checklist with component-local checked state; it is separate from shared group checklists. |
| [apps/web/src/features/itinerary/jsx/Icon.jsx](../apps/web/src/features/itinerary/jsx/Icon.jsx) | Maps named travel-planner icons to inline SVG artwork. |
| [apps/web/src/features/itinerary/jsx/Itinerary.jsx](../apps/web/src/features/itinerary/jsx/Itinerary.jsx) | Renders day-by-day generated itinerary entries using ItineraryStop. |
| [apps/web/src/features/itinerary/jsx/ItineraryStop.jsx](../apps/web/src/features/itinerary/jsx/ItineraryStop.jsx) | Displays a generated stop's times, place metadata, photos and available details within the itinerary timeline. |
| [apps/web/src/features/itinerary/jsx/SuggestedPlaces.jsx](../apps/web/src/features/itinerary/jsx/SuggestedPlaces.jsx) | Shows additional recommendations, including early-morning and late-night choices, and invokes the supplied add-place callback. |
| [apps/web/src/features/itinerary/jsx/TripForm.jsx](../apps/web/src/features/itinerary/jsx/TripForm.jsx) | Collects city, trip length and pacing, supports city autocomplete, and submits the requested plan parameters. |
| [apps/web/src/features/itinerary/jsx/TripMap.jsx](../apps/web/src/features/itinerary/jsx/TripMap.jsx) | Renders generated plans on Leaflet/OpenStreetMap with numbered stops, day routes and safe text popups; supports switching between returned plans. |
| [apps/web/src/features/itinerary/jsx/TripPlanCard.jsx](../apps/web/src/features/itinerary/jsx/TripPlanCard.jsx) | Displays a generated trip plan and its day-by-day itinerary, with plan summary metadata. |
| [apps/web/src/features/itinerary/jsx/TripTips.jsx](../apps/web/src/features/itinerary/jsx/TripTips.jsx) | Displays static travel advice alongside generated single-trip itineraries. |
| [apps/web/src/features/partners/PackageWorkspace.tsx](../apps/web/src/features/partners/PackageWorkspace.tsx) | Lists and duplicates private supplier packages and provides a seven-step editor for route, itinerary, services, media, proposed rates and review submission. |
| [apps/web/src/features/partners/PartnerAgreement.tsx](../apps/web/src/features/partners/PartnerAgreement.tsx) | Loads the full agreement draft for approved agents and collects the explicit version/hash-bound signature before opening package tools. |
| [apps/web/src/features/partners/PartnerPortal.tsx](../apps/web/src/features/partners/PartnerPortal.tsx) | Owns partner-only routes, registration/login, business application drafts and submission, verification status, agreement gating and private package access. |
| [apps/web/src/features/partners/__tests__/PackageWorkspace.test.tsx](../apps/web/src/features/partners/__tests__/PackageWorkspace.test.tsx) | Verifies private draft creation, save-and-continue edits, exact proposed rates, conflict preservation and text edits saved before blur. |
| [apps/web/src/features/partners/__tests__/PartnerPortal.test.tsx](../apps/web/src/features/partners/__tests__/PartnerPortal.test.tsx) | Verifies partner routing, signup, application versions and verification gates, approval/signature prerequisites and agreement-load failures. |
| [apps/web/src/features/partners/__tests__/partnerApi.test.ts](../apps/web/src/features/partners/__tests__/partnerApi.test.ts) | Verifies isolated session probes, partner CSRF, shared refresh, no mutation replay and version/hash-bound agreement acknowledgment. |
| [apps/web/src/features/partners/__tests__/rateAmounts.test.ts](../apps/web/src/features/partners/__tests__/rateAmounts.test.ts) | Verifies exact rate conversion for supported exponents, invalid-input rejection and leading fractional zeros. |
| [apps/web/src/features/partners/partnerApi.ts](../apps/web/src/features/partners/partnerApi.ts) | Calls partner endpoints with isolated partner cookies and CSRF; shares read-probe refresh and never automatically replays failed mutations. |
| [apps/web/src/features/partners/partners.css](../apps/web/src/features/partners/partners.css) | Styles the partner landing page, onboarding/status forms, agreement reader and private package authoring workspace. |
| [apps/web/src/features/partners/rateAmounts.ts](../apps/web/src/features/partners/rateAmounts.ts) | Converts supplier rate inputs to exact decimal-string minor units and back, validating exponent and range without floating-point conversion. |
| [apps/web/src/features/polls/PollFeed.jsx](../apps/web/src/features/polls/PollFeed.jsx) | Renders poll choices, voting results and voter details, submits option indexes, and exposes deletion only when permitted by the supplied poll state. |
| [apps/web/src/features/scout/CrewCards.jsx](../apps/web/src/features/scout/CrewCards.jsx) | Renders Crew follow-up questions, expiring confirmation cards, added-place cards and success messages, with multi-step answer handling. |
| [apps/web/src/features/scout/ScoutConsentCard.jsx](../apps/web/src/features/scout/ScoutConsentCard.jsx) | Presents per-group Scout privacy choices and retries the original request only after the returned consent state allows it. |
| [apps/web/src/features/scout/aiBots.js](../apps/web/src/features/scout/aiBots.js) | Defines the shared Scout and Crew identities used in planner chat and member displays. |
| [apps/web/src/features/trips/constants/crewRoles.js](../apps/web/src/features/trips/constants/crewRoles.js) | Defines Treasurer, Navigator and Culture Scout responsibility labels and descriptions separately from group access roles. |
| [apps/web/src/features/trips/constants/mapConfig.js](../apps/web/src/features/trips/constants/mapConfig.js) | Defines public OpenFreeMap day/night styles, attribution, fallback viewport values and marker/day colors and icons. |
| [apps/web/src/features/trips/constants/tabConfig.js](../apps/web/src/features/trips/constants/tabConfig.js) | Defines the workspace tab keys and labels: Itinerary, Library, Logistics, Treasury, Pulse and Circle. |
| [apps/web/src/features/trips/css/CreateGroupModal.css](../apps/web/src/features/trips/css/CreateGroupModal.css) | Styles the group-creation form, catalog destination suggestions, fields, actions and responsive modal layout. |
| [apps/web/src/features/trips/css/GroupPlannerPage.css](../apps/web/src/features/trips/css/GroupPlannerPage.css) | Styles the planner hub, workspace tabs, map overlays, chat, dialogs, demo toolbar and responsive planner layouts. |
| [apps/web/src/features/trips/demo/DemoPlannerProvider.jsx](../apps/web/src/features/trips/demo/DemoPlannerProvider.jsx) | Provides an isolated demo identity and query client, role switching and reset controls around the planner workspace. |
| [apps/web/src/features/trips/demo/demoApi.js](../apps/web/src/features/trips/demo/demoApi.js) | Handles demo workspace requests in local state with role checks and reset support; unsupported actions fail instead of reaching live mutation endpoints. |
| [apps/web/src/features/trips/demo/demoData.js](../apps/web/src/features/trips/demo/demoData.js) | Builds illustrative trips, people, places, chat, polls, logistics and expense data with local photo paths for the planner demo. |
| [apps/web/src/features/trips/demo/demoMode.js](../apps/web/src/features/trips/demo/demoMode.js) | Detects opt-in planner demo routes, preserves the demo query in planner links, and defines demo storage keys. |
| [apps/web/src/features/trips/hooks/useFloatingPosition.js](../apps/web/src/features/trips/hooks/useFloatingPosition.js) | Manages saved floating-chat positions with pointer/keyboard movement, viewport clamping, resize recovery and drag-click suppression. |
| [apps/web/src/features/trips/hooks/useMapRenderer.js](../apps/web/src/features/trips/hooks/useMapRenderer.js) | Initializes Leaflet and its MapLibre adapter/worker and styles, detects WebGL2 support, and provides a fallback capability flag. |
| [apps/web/src/features/trips/index.js](../apps/web/src/features/trips/index.js) | Exports GroupPlannerPage as the collaborative-trip feature entry. |
| [apps/web/src/features/trips/jsx/CreateGroupModal.jsx](../apps/web/src/features/trips/jsx/CreateGroupModal.jsx) | Collects trip name, dates, budget currency and optional invitees, requiring a selected catalog destination and validating invitation addresses. |
| [apps/web/src/features/trips/jsx/GroupPlannerManager.jsx](../apps/web/src/features/trips/jsx/GroupPlannerManager.jsx) | Orchestrates planner routing, group selection, tabs, shared query/socket state, map days, movable chat, invitations and group creation. |
| [apps/web/src/features/trips/jsx/GroupPlannerPage.jsx](../apps/web/src/features/trips/jsx/GroupPlannerPage.jsx) | Wraps the planner in shared site navigation, measures header height for layout, and enables DemoPlannerProvider only for demo=1. |
| [apps/web/src/features/trips/jsx/InvitationAcceptPage.jsx](../apps/web/src/features/trips/jsx/InvitationAcceptPage.jsx) | Restores auth before validating and accepting a trip invitation, shares StrictMode acceptance work and opens the exact joined group. |
| [apps/web/src/features/trips/jsx/chat/ChatPanel.jsx](../apps/web/src/features/trips/jsx/chat/ChatPanel.jsx) | Renders paginated/live messages, edits, mentions, Scout/Crew cards and polls while coordinating optimistic sends and group-specific composer state. |
| [apps/web/src/features/trips/jsx/chat/MessageMenu.jsx](../apps/web/src/features/trips/jsx/chat/MessageMenu.jsx) | Provides an inline message action menu for permitted edit/delete operations, with outside-click and Escape dismissal. |
| [apps/web/src/features/trips/jsx/map/MapPanel.jsx](../apps/web/src/features/trips/jsx/map/MapPanel.jsx) | Renders planner stops and day routes on Leaflet/OpenFreeMap, focuses the destination viewport, filters days and handles theme/coordinate fallbacks. |
| [apps/web/src/features/trips/jsx/shared/AddStopModal.jsx](../apps/web/src/features/trips/jsx/shared/AddStopModal.jsx) | Adds a stop through the place APIs, optionally schedules it, and refreshes planner queries while reporting partial-save failures. |
| [apps/web/src/features/trips/jsx/shared/GroupSelector.jsx](../apps/web/src/features/trips/jsx/shared/GroupSelector.jsx) | Shows searchable trip cards, locally pinned trips and invitation joining, with separate member actions and typed-name deletion confirmation. |
| [apps/web/src/features/trips/jsx/shared/PlannerExpenseModal.jsx](../apps/web/src/features/trips/jsx/shared/PlannerExpenseModal.jsx) | Collects a planner expense and participant/itemized split details for the linked ledger, retaining validation and saving errors. |
| [apps/web/src/features/trips/jsx/shared/PlannerHeader.jsx](../apps/web/src/features/trips/jsx/shared/PlannerHeader.jsx) | Renders the current group's title, group-count return action and planner context/actions without a separate dropdown group picker. |
| [apps/web/src/features/trips/jsx/shared/RouteOptimizer.jsx](../apps/web/src/features/trips/jsx/shared/RouteOptimizer.jsx) | Previews a reordered itinerary using local route helpers and saves the selected day's updated stop schedule through the planner API. |
| [apps/web/src/features/trips/jsx/shared/TripDateSelect.jsx](../apps/web/src/features/trips/jsx/shared/TripDateSelect.jsx) | Offers the trip's calendar dates plus an unscheduled option for assigning a stop to a day. |
| [apps/web/src/features/trips/jsx/tabs/CircleTab.jsx](../apps/web/src/features/trips/jsx/tabs/CircleTab.jsx) | Manages trip members, access roles, independent crew responsibilities, group settings, invitations and Scout consent controls. |
| [apps/web/src/features/trips/jsx/tabs/ItineraryTab.jsx](../apps/web/src/features/trips/jsx/tabs/ItineraryTab.jsx) | Displays the daily schedule, including empty trip dates, and supports stop edits, moves and removal with query refresh. |
| [apps/web/src/features/trips/jsx/tabs/LibraryTab.jsx](../apps/web/src/features/trips/jsx/tabs/LibraryTab.jsx) | Browses destination-scoped catalog places with state/city filters, pagination and details, and adds selected places to the trip. |
| [apps/web/src/features/trips/jsx/tabs/LogisticsTab.jsx](../apps/web/src/features/trips/jsx/tabs/LogisticsTab.jsx) | Manages vault uploads/downloads and shared pre-trip/packing checklists with assignments, permissions and optimistic toggle rollback. |
| [apps/web/src/features/trips/jsx/tabs/PulseTab.jsx](../apps/web/src/features/trips/jsx/tabs/PulseTab.jsx) | Shows a filterable activity feed alongside group/poll/member context and links relevant activity to workspace tabs. |
| [apps/web/src/features/trips/jsx/tabs/TreasuryTab.jsx](../apps/web/src/features/trips/jsx/tabs/TreasuryTab.jsx) | Connects the trip to an expense group and displays budgets, converted summaries, balances, suggested settlements and recent expenses. |
| [apps/web/src/features/trips/utils/formatters.js](../apps/web/src/features/trips/utils/formatters.js) | Formats planner dates, times, relative activity, initials, currency and file sizes with safe fallbacks for missing or invalid values. |
| [apps/web/src/features/trips/utils/groupPlannerUtils.js](../apps/web/src/features/trips/utils/groupPlannerUtils.js) | Normalizes API envelopes/arrays, classifies map markers, calculates trip day numbers and escapes popup text. |
| [apps/web/src/features/trips/utils/mapViewport.js](../apps/web/src/features/trips/utils/mapViewport.js) | Fits the map to a catalog destination or valid coordinates and wraps longitudes near the viewport for date-line destinations. |
| [apps/web/src/features/trips/utils/openFreeMapStyle.js](../apps/web/src/features/trips/utils/openFreeMapStyle.js) | Adjusts selected provider shield-label expressions to tolerate missing ref_length values while preserving the rest of the map style. |
| [apps/web/src/features/trips/utils/plannerMoney.js](../apps/web/src/features/trips/utils/plannerMoney.js) | Builds itemized participant splits in whole cents and suggests payments that clear debtor/creditor balances. |
| [apps/web/src/features/trips/utils/plannerSchedule.js](../apps/web/src/features/trips/utils/plannerSchedule.js) | Enumerates trip calendar dates, calculates geographic route distances, reorders stops and preserves available schedule time slots. |
| [apps/web/src/hooks/useAiConsentQuery.js](../apps/web/src/hooks/useAiConsentQuery.js) | Defines query keys and React Query reads/mutations for granting, declining or revoking per-group Scout consent. |
| [apps/web/src/hooks/useChatQuery.js](../apps/web/src/hooks/useChatQuery.js) | Manages cursor-paginated messages, optimistic sends, edits/deletes, read markers and unread counts without losing concurrent messages. |
| [apps/web/src/hooks/useChatSocket.js](../apps/web/src/hooks/useChatSocket.js) | Maintains cookie-authenticated live chat, typing/presence/read events, session renewal and query recovery after reconnect or revoked access. |
| [apps/web/src/hooks/useExchangeRate.js](../apps/web/src/hooks/useExchangeRate.js) | Fetches and validates the selected currency pair, ignores stale responses, refreshes on focus/timer and exposes loading/error state. |
| [apps/web/src/hooks/useExpenseLiveUpdates.js](../apps/web/src/hooks/useExpenseLiveUpdates.js) | Uses private Socket.IO change notifications to invalidate expense queries, clears revoked data, and catches up through polling/reconnect/visibility changes. |
| [apps/web/src/hooks/useExpenseQuery.js](../apps/web/src/hooks/useExpenseQuery.js) | Centralizes expense query keys, bootstrap/ledger/history reads, optimistic financial mutations with rollback, invitations and group/personal manager hooks. |
| [apps/web/src/hooks/useGroupPlannerQuery.js](../apps/web/src/hooks/useGroupPlannerQuery.js) | Defines planner query keys and hooks for groups, destination viewports, places, polls, members, expenses, checklists, vault files and activities. |
| [apps/web/src/hooks/useGroupSocket.js](../apps/web/src/hooks/useGroupSocket.js) | Subscribes to authenticated group collaboration/presence events and forwards handlers for places, polls, checklists, itineraries and membership. |
| [apps/web/src/hooks/useMoneyDisplay.js](../apps/web/src/hooks/useMoneyDisplay.js) | Formats amounts in a chosen display currency using the exchange-rate hook while leaving stored amounts and calculation units unchanged. |
| [apps/web/src/hooks/usePersonalCurrency.js](../apps/web/src/hooks/usePersonalCurrency.js) | Caches the account's chosen dashboard currency across tabs and saves explicit changes. |
| [apps/web/src/hooks/usePersonalDashboard.js](../apps/web/src/hooks/usePersonalDashboard.js) | Converts personal transactions into one dashboard currency without changing saved records. |
| [apps/web/src/hooks/useNotesAutoSave.js](../apps/web/src/hooks/useNotesAutoSave.js) | Saves and clears a group-scoped notes draft in localStorage; it does not send notes to the server. |
| [apps/web/src/hooks/usePlaceSearchQuery.js](../apps/web/src/hooks/usePlaceSearchQuery.js) | Provides cached React Query reads for place search, details and catalog statistics. |
| [apps/web/src/hooks/useTripPlannerQuery.js](../apps/web/src/hooks/useTripPlannerQuery.js) | Provides city-search/list and pacing queries plus the generated-trip mutation through tripPlannerService. |
| [apps/web/src/lib/chatCache.js](../apps/web/src/lib/chatCache.js) | Updates, removes and deduplicates messages across flat or enveloped cached pages, reconciling optimistic results and socket echoes. |
| [apps/web/src/lib/indexedDBPersister.js](../apps/web/src/lib/indexedDBPersister.js) | Implements optional React Query snapshot storage, restoration, deletion and statistics in IndexedDB, tolerating unavailable browser storage. |
| [apps/web/src/lib/queryClientPersist.js](../apps/web/src/lib/queryClientPersist.js) | Configures query freshness/retries and optional IndexedDB/localStorage persistence, excludes private queries and all mutations, and clears persisted state at logout. |
| [apps/web/src/main.tsx](../apps/web/src/main.tsx) | Mounts React with BrowserRouter and QueryClientProvider, initializes optional query persistence, and loads global styles. |
| [apps/web/src/pages/About.jsx](../apps/web/src/pages/About.jsx) | Renders static product, mission and team information with shared navigation and scroll-triggered animations. |
| [apps/web/src/pages/Analytics.jsx](../apps/web/src/pages/Analytics.jsx) | Checks administrator identity and shows an access-denied or analytics-unavailable message; no analytics dashboard endpoint is called. |
| [apps/web/src/pages/Contact.jsx](../apps/web/src/pages/Contact.jsx) | Shows support email only when a valid VITE_SUPPORT_EMAIL is configured and renders static account, invitations and beta-access help. |
| [apps/web/src/pages/ExpenseAnalytics.jsx](../apps/web/src/pages/ExpenseAnalytics.jsx) | Displays the protected legacy analytics route's access-denied or unavailable state; no expense analytics dashboard is implemented here. |
| [apps/web/src/pages/ExpensePage.jsx](../apps/web/src/pages/ExpensePage.jsx) | Wraps ExpenseManager in shared site navigation, authenticated account actions and the footer. |
| [apps/web/src/pages/HomePage.jsx](../apps/web/src/pages/HomePage.jsx) | Renders the marketing landing page, animated travel artwork, tool links and destination-to-planner navigation. |
| [apps/web/src/pages/InvitationAccept.jsx](../apps/web/src/pages/InvitationAccept.jsx) | Handles expense invitation details, sign-in continuation, account mismatch and single acceptance, then navigates to the joined expense group. |
| [apps/web/src/pages/Pricing.jsx](../apps/web/src/pages/Pricing.jsx) | Explains the current free beta and future plans and links to signup or the planner; no payment checkout is offered. |
| [apps/web/src/pages/SmartInvitationHandler.jsx](../apps/web/src/pages/SmartInvitationHandler.jsx) | Resolves expense versus trip invitation routes from explicit path/query hints or API probes, then renders the matching acceptance flow. |
| [apps/web/src/pages/TripPlanner.jsx](../apps/web/src/pages/TripPlanner.jsx) | Calls tripPlannerService and adapts returned plans/place metadata for the single-trip map, itinerary cards, tips and packing checklist. |
| [apps/web/src/pages/VerifyEmail.jsx](../apps/web/src/pages/VerifyEmail.jsx) | Verifies a public email token with shared in-flight work under StrictMode, reports missing/expired/error states and offers explicit resend when signed in. |
| [apps/web/src/pages/index.js](../apps/web/src/pages/index.js) | Re-exports the main page components for consumers that use the pages entry module. |
| [apps/web/src/pages/styles/About.css](../apps/web/src/pages/styles/About.css) | Styles the about page's product, mission, team and call-to-action sections and scroll animations. |
| [apps/web/src/pages/styles/Analytics.css](../apps/web/src/pages/styles/Analytics.css) | Styles the analytics route, including its current loading/error/unavailable state and retained dashboard selectors. |
| [apps/web/src/pages/styles/Contact.css](../apps/web/src/pages/styles/Contact.css) | Styles the support/contact and FAQ sections, with retained selectors for earlier contact-form layouts. |
| [apps/web/src/pages/styles/ExpenseAnalytics.css](../apps/web/src/pages/styles/ExpenseAnalytics.css) | Styles the legacy expense-analytics page's loading/error layout and retained dashboard-frame selectors. |
| [apps/web/src/pages/styles/ExpensePage.css](../apps/web/src/pages/styles/ExpensePage.css) | Sets the expense page's content width, background and responsive container spacing. |
| [apps/web/src/pages/styles/HomePage.css](../apps/web/src/pages/styles/HomePage.css) | Styles the landing hero, destination form, feature sections, expense promotion and responsive layouts. |
| [apps/web/src/pages/styles/Pricing.css](../apps/web/src/pages/styles/Pricing.css) | Styles the pricing page and cards, including retained selectors for billing controls that the current beta page does not render. |
| [apps/web/src/pages/styles/VerifyEmail.css](../apps/web/src/pages/styles/VerifyEmail.css) | Styles the centered email-verification card, outcome icons, recovery links and keyboard-focus states. |
| [apps/web/src/services/aiConsentApi.js](../apps/web/src/services/aiConsentApi.js) | Calls the planner's consent-status, grant/decline and revoke endpoints through the shared API client. |
| [apps/web/src/services/chatApi.js](../apps/web/src/services/chatApi.js) | Wraps group message pagination, send/edit/delete, read-marker and unread-count endpoints. |
| [apps/web/src/services/currencyApi.js](../apps/web/src/services/currencyApi.js) | Fetches supported currencies with short-lived listing reuse and requests current or explicitly refreshed exchange rates. |
| [apps/web/src/services/expenseApi.js](../apps/web/src/services/expenseApi.js) | Wraps expense profiles, groups, members, invitations, expenses, settlements, balances, analytics and bootstrap endpoints using the shared API client. |
| [apps/web/src/services/groupPlannerApi.js](../apps/web/src/services/groupPlannerApi.js) | Wraps planner groups, paginated collections, invitations, places, polls, schedules, checklist/vault data, catalog reads and linked-expense operations. |
| [apps/web/src/services/pdfExportService.js](../apps/web/src/services/pdfExportService.js) | Generates branded personal/group expense PDF reports with summary, transaction, balance and settlement tables using jsPDF and AutoTable. |
| [apps/web/src/services/placeSearchService.js](../apps/web/src/services/placeSearchService.js) | Wraps place search, cancellable autocomplete, place-detail and catalog-statistics API calls. |
| [apps/web/src/services/sqlAuthService.js](../apps/web/src/services/sqlAuthService.js) | Restores traveler sessions from cookies, handles signup/login/verification/logout, shares refresh work and exposes auth-state listeners without storing tokens locally. |
| [apps/web/src/services/tripPlannerService.js](../apps/web/src/services/tripPlannerService.js) | Calls itinerary generation, city search/list and pacing endpoints, unwraps API envelopes and adapts generated place/stop data. |
| [apps/web/src/setupTests.js](../apps/web/src/setupTests.js) | Loads Testing Library DOM assertions and supplies TextEncoder/TextDecoder for the jsdom test environment. |
| [apps/web/src/styles.css](../apps/web/src/styles.css) | Applies the app-wide reset, shared color and spacing variables, root geometry, and responsive typography helpers. |
| [apps/web/src/styles/global.css](../apps/web/src/styles/global.css) | Defines shared theme variables, layout utilities, form/control defaults, animations and responsive global rules. |
| [apps/web/src/utils/apiClient.js](../apps/web/src/utils/apiClient.js) | Sends cookie-authenticated requests with CSRF, timeout/cancellation and structured errors; retries GET failures, refreshes a rejected session once, and routes isolated demo requests. |
| [apps/web/src/utils/apiLogger.js](../apps/web/src/utils/apiLogger.js) | Exposes a silent logger compatibility interface so API callers can retain logging hooks without emitting request data. |
| [apps/web/src/utils/coordinates.js](../apps/web/src/utils/coordinates.js) | Validates finite latitude/longitude bounds, accepting zero coordinates while rejecting missing or empty values. |
| [apps/web/src/utils/errorHandler.js](../apps/web/src/utils/errorHandler.js) | Converts structured API errors into display messages, field errors and authentication-redirect hints with status-code fallbacks. |
| [apps/web/src/utils/money.js](../apps/web/src/utils/money.js) | Formats currency, allocates equal splits in whole cents, preserves unchanged saved split fields and caps payments by both debt and credit. |
| [apps/web/src/utils/placeRating.js](../apps/web/src/utils/placeRating.js) | Derives a bounded 0-5 display rating from explicit rating or rank_score, returning zero for invalid numeric values. |
| [apps/web/src/utils/timezoneUtils.js](../apps/web/src/utils/timezoneUtils.js) | Provides local date/time formatting, date-input conversion, relative dates, browser timezone/geolocation and coordinate-to-city lookup helpers. |
| [apps/web/tests/styleMock.cjs](../apps/web/tests/styleMock.cjs) | Exports an empty object for CSS and SVG imports mapped by the Jest configuration. |
| [apps/web/tests/viteEnvTransform.cjs](../apps/web/tests/viteEnvTransform.cjs) | Rewrites import.meta.env expressions to process.env so Jest can execute Vite-oriented source. |
| [apps/web/tsconfig.json](../apps/web/tsconfig.json) | Extends the shared TypeScript settings; checks the entry, environment declarations and partner TypeScript source, excluding partner tests. |
| [apps/web/vite.config.js](../apps/web/vite.config.js) | Serves web on port 5173, proxies API and Socket.IO traffic to Flask, handles API proxy outages, and strips console/debugger calls in production. |

## docs

| File | What it does |
|---|---|
| [docs/README.md](../docs/README.md) | Routes developers to current setup, architecture, API, feature and operations guides, plans, archive and source references. |
| [docs/api/README.md](../docs/api/README.md) | Documents API conventions, client contract generation and endpoint integration. |
| [docs/api/group-finance.md](../docs/api/group-finance.md) | Documents collaborative expense/ledger endpoint behavior and permissions. |
| [docs/api/personal-finance.md](../docs/api/personal-finance.md) | Documents personal finance API operations and monetary data conventions. |
| [docs/api/expense-friends.md](../docs/api/expense-friends.md) | Documents saved contacts, nickname/name display, invitation behavior and migration requirements. |
| [docs/architecture/overview.md](../docs/architecture/overview.md) | Explains frontend/backend boundaries, persistence, authentication, workflow ownership and launcher behavior. |
| [docs/archive/README.md](../docs/archive/README.md) | Indexes retained dated Markdown reports and explains the removal of raw exports and machine-specific recovery notes. |
| [docs/archive/reports/agent-signature-and-live-reload-2026-10-19.md](../docs/archive/reports/agent-signature-and-live-reload-2026-10-19.md) | Archived dated report: Agent-only signing after approval and local server recovery. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/email-verification-page-fix.md](../docs/archive/reports/email-verification-page-fix.md) | Archived dated report: Email verification blank page — 2026-10-12. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/expense-group-creation-fix.md](../docs/archive/reports/expense-group-creation-fix.md) | Archived dated report: Expense group creation fix — 2026-10-12. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/expense-invitation-delivery-navigation-fix.md](../docs/archive/reports/expense-invitation-delivery-navigation-fix.md) | Archived dated report: Expense invitation delivery and group destination — 2026-10-12. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/expense-invitation-email-fix.md](../docs/archive/reports/expense-invitation-email-fix.md) | Archived dated report: Expense invitation delivery findings — 2026-10-12. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/expense-invitation-link-fix.md](../docs/archive/reports/expense-invitation-link-fix.md) | Archived dated report: Copied expense invitation links — 2026-10-12. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/expenses-feature-audit-2026-10-13.md](../docs/archive/reports/expenses-feature-audit-2026-10-13.md) | Archived dated report: Personal and group expenses audit - October 13, 2026. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/full-data-import/report.md](../docs/archive/reports/full-data-import/report.md) | Archived dated report: Remaining-details import. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/github-code-only-publication-2026-10-19.md](../docs/archive/reports/github-code-only-publication-2026-10-19.md) | Archived dated report: Code-only GitHub publication and package review foundation. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-expense-permissions-audit.md](../docs/archive/reports/group-expense-permissions-audit.md) | Archived dated report: Group expense permissions and feature audit. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-catalog-library-2026-10-15.md](../docs/archive/reports/group-planner-catalog-library-2026-10-15.md) | Archived dated report: Group Planner catalog destinations and Library - October 15, 2026. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-compact-settings-sync-2026-10-17.md](../docs/archive/reports/group-planner-compact-settings-sync-2026-10-17.md) | Archived dated report: Compact currency display, settings sync and member controls. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-crew-responsibilities-2026-10-15.md](../docs/archive/reports/group-planner-crew-responsibilities-2026-10-15.md) | Archived dated report: Group Planner crew responsibilities - October 15, 2026. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-currency-errors-2026-10-16.md](../docs/archive/reports/group-planner-currency-errors-2026-10-16.md) | Archived dated report: Currency estimates and pasted browser errors. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-feature-fixes-2026-10-14.md](../docs/archive/reports/group-planner-feature-fixes-2026-10-14.md) | Archived dated report: Group Planner feature review and bug fixes. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-invitation-link-fix-2026-10-15.md](../docs/archive/reports/group-planner-invitation-link-fix-2026-10-15.md) | Archived dated report: Group Planner email invitation links - October 15, 2026. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-library-live-audit-2026-10-16.md](../docs/archive/reports/group-planner-library-live-audit-2026-10-16.md) | Archived dated report: Family/friends Group Planner refresh — October 16, 2026. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-movable-chat-2026-10-17.md](../docs/archive/reports/group-planner-movable-chat-2026-10-17.md) | Archived dated report: Movable Group Planner chat. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-openfreemap-2026-10-16.md](../docs/archive/reports/group-planner-openfreemap-2026-10-16.md) | Archived dated report: Group Planner OpenFreeMap checkpoint — October 16, 2026. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-tabs-refresh-2026-10-15.md](../docs/archive/reports/group-planner-tabs-refresh-2026-10-15.md) | Archived dated report: Group Planner tabs and demo preview - October 15, 2026. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/group-planner-ui-refresh-2026-10-14.md](../docs/archive/reports/group-planner-ui-refresh-2026-10-14.md) | Archived dated report: Group Planner UI refresh — October 14, 2026. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/partner-agreement-demo-approval-2026-10-19.md](../docs/archive/reports/partner-agreement-demo-approval-2026-10-19.md) | Archived dated report: Partner agreement integration and local demo approval. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/partners-onboarding-foundation-2026-10-18.md](../docs/archive/reports/partners-onboarding-foundation-2026-10-18.md) | Archived dated report: Partner onboarding foundation and native startup. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/sql-seed-audit/report.md](../docs/archive/reports/sql-seed-audit/report.md) | Archived dated report: SQL seed audit — 7 October 2026. Historical evidence; use current guides for setup and behavior. |
| [docs/archive/reports/staff-console-package-drafts-2026-10-19.md](../docs/archive/reports/staff-console-package-drafts-2026-10-19.md) | Archived dated report: Staff review access and private package drafts. Historical evidence; use current guides for setup and behavior. |
| [docs/files.md](../docs/files.md) | Indexes every file in the reviewed published tree with its role; local ignored inputs are excluded. |
| [docs/guides/partner-agreement.md](../docs/guides/partner-agreement.md) | Explains current agreement versions, agent signature evidence, protected runtime attachments and commercial boundaries. |
| [docs/guides/staff-console.md](../docs/guides/staff-console.md) | Explains generic staff configuration, business/package review, self-review restrictions and connection recovery. |
| [docs/operations/runbook.md](../docs/operations/runbook.md) | Provides maintenance, deployment/recovery and operational troubleshooting procedures. |
| [docs/operations/database-releases.md](../docs/operations/database-releases.md) | Shared employee test data, environment setup, migration deployment, production approval and recovery guide. |
| [docs/operations/database-release-checklist.html](../docs/operations/database-release-checklist.html) | Local interactive release checklist with no network access or deployment authority. |
| [docs/plans/README.md](../docs/plans/README.md) | Indexes the enterprise and tour-package proposals and separates delivered private supplier review from proposed public/commerce phases. |
| [docs/plans/enterprise-platform-implementation-plan.md](../docs/plans/enterprise-platform-implementation-plan.md) | Proposes enterprise platform work in stages against the locally retained blueprint; not an implementation guarantee. |
| [docs/plans/places-search-tour-packages/README.md](../docs/plans/places-search-tour-packages/README.md) | Introduces the proposed places-search and tour-package implementation plan and its source context. |
| [docs/plans/places-search-tour-packages/architecture-and-files.md](../docs/plans/places-search-tour-packages/architecture-and-files.md) | Proposes module boundaries and source-file responsibilities for places search and tour packages. |
| [docs/plans/places-search-tour-packages/data-api-and-publishing.md](../docs/plans/places-search-tour-packages/data-api-and-publishing.md) | Proposes data contracts, API operations and review/publishing rules for search and tour packages. |
| [docs/plans/places-search-tour-packages/phases-and-acceptance.md](../docs/plans/places-search-tour-packages/phases-and-acceptance.md) | Defines proposed implementation phases, acceptance criteria and sequencing for search/package work. |
| [docs/repository-review.md](../docs/repository-review.md) | Explains required repository areas, the docs reorganization and local preservation of removed raw audit/checkpoint files. |
| [docs/setup/email.md](../docs/setup/email.md) | Explains SMTP configuration and local verification of account/invitation email delivery. |
| [docs/setup/maps.md](../docs/setup/maps.md) | Explains planner map assets, external tiles/styles and destination catalog setup. |
| [docs/setup/startup.md](../docs/setup/startup.md) | Documents native/Docker setup, local data and credentials, service lifecycle, checks and recovery. |

## infra

| File | What it does |
|---|---|
| [infra/README.md](../infra/README.md) | Explains containers, workflow synchronization, infrastructure placeholders and every maintenance tool/test. |
| [infra/docker/.env.example](../infra/docker/.env.example) | Documents local Compose PostgreSQL/password, application-secret and staff-email settings; the sample values are development placeholders. |
| [infra/docker/docker-compose.yml](../infra/docker/docker-compose.yml) | Runs local PostgreSQL, Redis and the Flask API with loopback ports and persistent data volumes; an optional workers profile starts Celery after API readiness. |
| [infra/github/workflows/ci.yml](../infra/github/workflows/ci.yml) | Defines canonical CI dependency installation, workspace checks, generated API-contract verification and frontend artifact upload; sync its discovery copy with sync-workflows.mjs. |
| [infra/github/workflows/deploy.yml](../infra/github/workflows/deploy.yml) | Centralized development/staging migrations and production releases gated by exact-commit staging evidence and administrator environment approval. |
| [infra/tools/check_release_gate.py](../infra/tools/check_release_gate.py) | Rejects production releases without the exact successful staging commit, acceptance, backup evidence and reviewer protections. |
| [infra/tools/deploy_application.py](../infra/tools/deploy_application.py) | Deploys a selected application SHA through a hosting adapter and verifies matching readiness. |
| [infra/tools/deploy_database.py](../infra/tools/deploy_database.py) | Plans or explicitly applies migrations with separate pinned credentials, PostgreSQL session locking and schema verification. |
| [infra/tools/request_development_migration.py](../infra/tools/request_development_migration.py) | Lets restricted startup request only a fixed owner-approved development migration without migration credentials. |
| [infra/sql/development/enable_approved_startup_migrations.sql](../infra/sql/development/enable_approved_startup_migrations.sql) | One-time owner setup for narrowly scoped automatic shared-development migrations; no caller SQL or direct DDL grants. |
| [infra/sql/development/friend_contacts_runtime_grant.sql](../infra/sql/development/friend_contacts_runtime_grant.sql) | Proposes an owner-run development CRUD grant for the new private-contact table after migration. |
| [infra/terraform/README.md](../infra/terraform/README.md) | Explains that Terraform provisioning is a placeholder, lists the hosting decisions needed before implementation, and links deployment guidance. |
| [infra/tests/test_catalog_supabase_import.py](../infra/tests/test_catalog_supabase_import.py) | Tests PostgreSQL COPY escaping, supported canonical SQLite DDL conversion and stable export ordering with temporary or in-memory data; no remote database is contacted. |
| [infra/tests/test_launcher.py](../infra/tests/test_launcher.py) | Tests start.py setup preservation, random secrets, process identity and owned-child cleanup, port/session reuse, child environments and reload recovery using mocks and temporary files. |
| [infra/tests/test_database_releases.py](../infra/tests/test_database_releases.py) | Verifies release target pins, staging evidence, production protections and exact application commit checks. |
| [infra/tests/test_supabase_setup.py](../infra/tests/test_supabase_setup.py) | Tests password-safe database URL construction and useful SQLSTATE diagnostics with raw/encoded credential redaction; no Supabase connection is made. |
| [infra/tools/audit_supabase_security.py](../infra/tools/audit_supabase_security.py) | Reads public-schema RLS flags, Data API role privileges, duplicate index definitions, default ACLs and migration metadata, optionally writing a JSON report without reading application rows. |
| [infra/tools/check_python.py](../infra/tools/check_python.py) | Parses services/api Python files using the Python 3.11 grammar to catch syntax incompatible with CI and Docker; it does not import or execute those modules. |
| [infra/tools/check_structure.py](../infra/tools/check_structure.py) | Checks required published workspace paths and local Python/JavaScript import targets without requiring ignored datasets. |
| [infra/tools/dev-env.ps1](../infra/tools/dev-env.ps1) | Creates or reuses the workspace .venv with the selected Python version and installs backend runtime/test requirements; start.py remains the full-project launcher. |
| [infra/tools/document_files.py](../infra/tools/document_files.py) | Inventories Git-visible project files, adds missing format-valid purpose headers and rewrites docs/files.md using description rules; strict JSON and binary files are described only in the guide. |
| [infra/tools/export_openapi.py](../infra/tools/export_openapi.py) | Builds services/api/openapi.json from Flask routes and explicit admin/partner schemas using a migrated temporary SQLite database; unspecified response payloads remain unknown. |
| [infra/tools/import_catalog_supabase.py](../infra/tools/import_catalog_supabase.py) | Prepares canonical SQLite catalog snapshots, PostgreSQL DDL and COPY exports; explicit apply imports into a new private catalog schema and verifies ordered row hashes before commit. |
| [infra/tools/import_partner_agreement.py](../infra/tools/import_partner_agreement.py) | Extracts ordered paragraphs, tables and document furniture from a supplied DOCX, records its SHA-256 and preserves the original in the API agreement directory for review. |
| [infra/tools/promote_enriched_catalog.py](../infra/tools/promote_enriched_catalog.py) | Builds and validates an enriched SQLite catalog preview against the canonical schema; explicit apply backs up and fills an empty target transactionally while preserving sequences and FTS data. |
| [infra/tools/setup_demo_partner.py](../infra/tools/setup_demo_partner.py) | Backs up a local development SQLite database, transfers an explicitly selected staff-owned demo application to a separate partner identity, and records approval without signing terms or granting staff access. |
| [infra/tools/setup_supabase.py](../infra/tools/setup_supabase.py) | Builds TLS PostgreSQL URLs from ignored Supabase settings, checks connectivity by default, and supports offline migration SQL or explicit fresh-setup/upgrade actions with redacted errors. |
| [infra/tools/sync-workflows.mjs](../infra/tools/sync-workflows.mjs) | Copies the canonical infra CI/deployment YAML files into .github/workflows so GitHub discovers the same definitions validated by the workspace checks. |
| [infra/tools/validate_infra.py](../infra/tools/validate_infra.py) | Statically validates Compose build contexts, Dockerfiles, named/bind volumes and service dependencies plus workflow job/step structure; it does not start containers or deploy. |

## packages

| File | What it does |
|---|---|
| [packages/README.md](../packages/README.md) | Explains the four shared packages, generated API declarations and the purpose of every package file. |
| [packages/api-client/eslint.config.js](../packages/api-client/eslint.config.js) | Re-exports the shared critical JavaScript/TypeScript lint configuration for the typed API client; generated declarations are excluded by that configuration. |
| [packages/api-client/package.json](../packages/api-client/package.json) | Declares the typed API-client entry, openapi-fetch/runtime and workspace dependencies, and OpenAPI generation, lint and typecheck commands. |
| [packages/api-client/src/generated/schema.d.ts](../packages/api-client/src/generated/schema.d.ts) | Contains generated OpenAPI paths, operations and component types from services/api/openapi.json; regenerate with the package command instead of hand-editing declarations. |
| [packages/api-client/src/index.ts](../packages/api-client/src/index.ts) | Creates a typed openapi-fetch client with cookie credentials and mutation CSRF headers, and re-exports generated/shared types without adding retries or session refresh. |
| [packages/api-client/tsconfig.json](../packages/api-client/tsconfig.json) | Extends shared TypeScript settings and includes src/**/*.ts for checking the client and generated declarations without emitting JavaScript. |
| [packages/config/eslint.config.js](../packages/config/eslint.config.js) | Shares the TypeScript-capable parser and four critical error rules across workspaces, ignoring dependency/build output and generated declarations. |
| [packages/config/package.json](../packages/config/package.json) | Exports the shared ESLint, TypeScript and Prettier configuration entry points for workspace packages and applications. |
| [packages/config/prettier.json](../packages/config/prettier.json) | Defines shared formatting preferences: single quotes where supported, trailing commas where supported, and a print width of 100. |
| [packages/config/tsconfig.json](../packages/config/tsconfig.json) | Defines strict ES2022/browser TypeScript checking with bundler module resolution, React JSX and no emit; JavaScript is allowed but checkJs is disabled. |
| [packages/types/eslint.config.js](../packages/types/eslint.config.js) | Re-exports shared critical syntax/error lint rules for the handwritten domain contract package. |
| [packages/types/package.json](../packages/types/package.json) | Exports handwritten domain types from src/index.ts and declares shared configuration plus lint/typecheck commands; the package has no runtime dependency list. |
| [packages/types/src/index.ts](../packages/types/src/index.ts) | Exports UUID/Money aliases, API envelopes, account/health contracts and partner/package types; these declarations provide compile-time contracts, not runtime validation. |
| [packages/types/src/partners.ts](../packages/types/src/partners.ts) | Defines partner application/review states, capability snapshots, agreement document/signature evidence and version/hash-bound signing inputs for web and staff consumers. |
| [packages/types/src/tourDrafts.ts](../packages/types/src/tourDrafts.ts) | Defines private package content, itinerary days, exact string minor-unit rate proposals, media, review states and paginated draft/review responses. |
| [packages/types/tsconfig.json](../packages/types/tsconfig.json) | Extends shared TypeScript settings and includes handwritten src/**/*.ts domain declarations for no-emit type checking. |
| [packages/ui/eslint.config.js](../packages/ui/eslint.config.js) | Re-exports shared critical JavaScript/JSX lint rules for reusable UI components. |
| [packages/ui/package.json](../packages/ui/package.json) | Exports @tripraft/ui/Toast, preserves imported CSS as a side effect, and declares React/lucide-react peer dependencies plus the UI lint command. |
| [packages/ui/src/Toast.jsx](../packages/ui/src/Toast.jsx) | Renders success/error/info notifications with icons and manual close, schedules onClose for positive durations, and clears the timer when its effect resets or unmounts. |
| [packages/ui/src/styles/Toast.css](../packages/ui/src/styles/Toast.css) | Styles fixed-position Toast notifications, slide-in animation, status colors and close controls, with a full-width mobile layout. |

## services

| File | What it does |
|---|---|
| [services/README.md](../services/README.md) | Explains services/api/app nesting, domains, migrations, catalog provisioning and every existing service file. |
| [services/api/.dockerignore](../services/api/.dockerignore) | Keeps caches, local environment files, logs, uploads, tests and databases out of a service-local Docker build context; the repository-root build uses Dockerfile.dockerignore. |
| [services/api/.env.example](../services/api/.env.example) | Documents backend configuration keys and placeholders for local settings; actual .env and .env.supabase values remain outside Git. |
| [services/api/Dockerfile](../services/api/Dockerfile) | Builds the Python API image from the repository root, installs runtime dependencies, copies service code and starts it as a non-root user. |
| [services/api/Dockerfile.dockerignore](../services/api/Dockerfile.dockerignore) | Restricts the repository-root API build context to service code/schema and excludes secrets, runtime data, tests and Office/PDF artifacts. |
| [services/api/alembic.ini](../services/api/alembic.ini) | Configures the application's Alembic migration directory, logging and database connection defaults. |
| [services/api/app/__init__.py](../services/api/app/__init__.py) | Exposes create_app from app.core.factory so the Python package has a stable application-factory entry. |
| [services/api/app/auth/__init__.py](../services/api/app/auth/__init__.py) | Re-exports the shared account/session models and their repositories for authentication consumers. |
| [services/api/app/auth/models.py](../services/api/app/auth/models.py) | Defines the unified User, UserSession and security AuditLog ORM models. |
| [services/api/app/auth/repository.py](../services/api/app/auth/repository.py) | Implements account/session lookups and persistence behind authentication services. |
| [services/api/app/auth/routes/__init__.py](../services/api/app/auth/routes/__init__.py) | Declares the app.auth.routes Python package used by the service imports. |
| [services/api/app/auth/routes/auth.py](../services/api/app/auth/routes/auth.py) | Exposes traveler signup/login, session refresh/logout, verification, profile and expense-bootstrap endpoints. |
| [services/api/app/auth/routes/users.py](../services/api/app/auth/routes/users.py) | Provides the user API surface, delegating authentication to AuthService and profile changes to UserService. |
| [services/api/app/auth/security/__init__.py](../services/api/app/auth/security/__init__.py) | Re-exports route guards, token/cookie helpers and password functions through one authentication entry. |
| [services/api/app/auth/security/decorators.py](../services/api/app/auth/security/decorators.py) | Resolves authenticated identity and enforces session, administrator and group/message-role access consistently across routes. |
| [services/api/app/auth/security/jwt.py](../services/api/app/auth/security/jwt.py) | Creates/verifies traveler and partner tokens, supports signing-key selection, hashes refresh tokens and sets/clears auth cookies. |
| [services/api/app/auth/security/password.py](../services/api/app/auth/security/password.py) | Hashes and verifies bcrypt passwords and evaluates signup password requirements. |
| [services/api/app/auth/services/__init__.py](../services/api/app/auth/services/__init__.py) | Declares the app.auth.services Python package used by the service imports. |
| [services/api/app/auth/services/auth_service.py](../services/api/app/auth/services/auth_service.py) | Implements registration, login, refresh rotation, session revocation and authentication lifecycle behavior. |
| [services/api/app/auth/services/user_service.py](../services/api/app/auth/services/user_service.py) | Implements current-user/profile retrieval and updates plus authenticated password changes. |
| [services/api/app/core/__init__.py](../services/api/app/core/__init__.py) | Re-exports configuration access and shared application exceptions for backend consumers. |
| [services/api/app/core/apiutils/__init__.py](../services/api/app/core/apiutils/__init__.py) | Re-exports reference-database compatibility helpers, response builders and input-validation utilities. |
| [services/api/app/core/apiutils/database.py](../services/api/app/core/apiutils/database.py) | Adapts the shared travel database to the older init_database/get_db interface used by existing routes and factory initialization. |
| [services/api/app/core/apiutils/responses.py](../services/api/app/core/apiutils/responses.py) | Builds standard success/error/pagination envelopes with request metadata and appropriate HTTP statuses. |
| [services/api/app/core/apiutils/validators.py](../services/api/app/core/apiutils/validators.py) | Validates request schemas, bounded query/pagination values, UUIDs, search text, sort fields and filters. |
| [services/api/app/core/cache/__init__.py](../services/api/app/core/cache/__init__.py) | Re-exports Redis caching, route-cache invalidation and login-lockout/trusted-device helpers. |
| [services/api/app/core/cache/redis.py](../services/api/app/core/cache/redis.py) | Manages optional Redis access, JSON caching, route caching, login failure tracking and temporary lockout state. |
| [services/api/app/core/config.py](../services/api/app/core/config.py) | Loads environment-backed application settings and selects development, production or testing configuration; includes operational and reference-data paths. |
| [services/api/app/core/db/__init__.py](../services/api/app/core/db/__init__.py) | Re-exports ORM engines, routed sessions, shared Base, database initialization and compatibility access helpers. |
| [services/api/app/core/db/base.py](../services/api/app/core/db/base.py) | Defines the shared SQLAlchemy declarative Base so application models register in one metadata registry. |
| [services/api/app/core/db/connection.py](../services/api/app/core/db/connection.py) | Creates operational/reference engines, routes ORM sessions and manages transactions; verifies migrations rather than silently creating missing application tables. |
| [services/api/app/core/db/migration_checks.py](../services/api/app/core/db/migration_checks.py) | Detects incompatible legacy identifier column/storage types before accepting an existing application database. |
| [services/api/app/core/db/travel_db.py](../services/api/app/core/db/travel_db.py) | Manages SQLite reference-catalog connections, validated identifiers, queries and controlled transaction helpers. |
| [services/api/app/core/db/uuid7.py](../services/api/app/core/db/uuid7.py) | Generates time-ordered UUIDv7 identifiers and provides a SQLAlchemy UUID type that accepts string inputs. |
| [services/api/app/core/dev_reload.py](../services/api/app/core/dev_reload.py) | Performs the explicitly requested native-development reload preparation while keeping production behavior separate. |
| [services/api/app/core/exceptions.py](../services/api/app/core/exceptions.py) | Defines application exception classes carrying HTTP status/error context for centralized API handling. |
| [services/api/app/core/external/__init__.py](../services/api/app/core/external/__init__.py) | Reserves a Python package for external integrations; current concrete clients also live with their owning domains. |
| [services/api/app/core/factory.py](../services/api/app/core/factory.py) | Builds Flask, initializes required components, registers domain blueprints, middleware, errors, health routes, legacy aliases and realtime extensions. |
| [services/api/app/core/health.py](../services/api/app/core/health.py) | Implements liveness/readiness endpoints and probes application database, cache and configured worker availability. |
| [services/api/app/core/idempotency.py](../services/api/app/core/idempotency.py) | Scopes and reserves mutating request keys and replays stored results to prevent duplicate execution after retries. |
| [services/api/app/core/json_utils.py](../services/api/app/core/json_utils.py) | Normalizes ORM-emitted values into JSON-compatible data at API/event boundaries. |
| [services/api/app/core/logging.py](../services/api/app/core/logging.py) | Configures application logging and structured production log formatting. |
| [services/api/app/core/middleware.py](../services/api/app/core/middleware.py) | Assigns validated correlation/request identifiers and emits structured request/response logs and headers. |
| [services/api/app/core/rate_limiter.py](../services/api/app/core/rate_limiter.py) | Configures shared request limits, endpoint limit helpers and trusted-proxy-aware client identity. |
| [services/api/app/core/resilience.py](../services/api/app/core/resilience.py) | Defines circuit breakers and logging for failure-prone external service calls. |
| [services/api/app/core/route_viewer.py](../services/api/app/core/route_viewer.py) | Provides an authenticated administrator-only HTML/JSON listing of registered Flask routes. |
| [services/api/app/core/sanitize.py](../services/api/app/core/sanitize.py) | Sanitizes untrusted text/rich text before persistence or display using the configured HTML policy. |
| [services/api/app/core/schemas/__init__.py](../services/api/app/core/schemas/__init__.py) | Re-exports domain validation schemas through the existing shared import surface. |
| [services/api/app/core/schemas/auth.py](../services/api/app/core/schemas/auth.py) | Validates traveler signup, login, password and profile request fields. |
| [services/api/app/core/schemas/common.py](../services/api/app/core/schemas/common.py) | Retains backward-compatible validation-schema exports and the shared validate_request decorator. |
| [services/api/app/core/schemas/expense_groups.py](../services/api/app/core/schemas/expense_groups.py) | Validates expense-group creation, metadata and membership changes with persisted limits and restricted role fields. |
| [services/api/app/core/schemas/expenses.py](../services/api/app/core/schemas/expenses.py) | Validates expense create/update amounts, payer, split and metadata inputs. |
| [services/api/app/core/schemas/fields.py](../services/api/app/core/schemas/fields.py) | Defines shared UUID, currency, calendar-date and trimmed-text field behavior for request schemas. |
| [services/api/app/core/schemas/gp_chat.py](../services/api/app/core/schemas/gp_chat.py) | Validates message creation/editing and read-receipt inputs. |
| [services/api/app/core/schemas/gp_checklist.py](../services/api/app/core/schemas/gp_checklist.py) | Validates shared checklist item creation, editing and assignment. |
| [services/api/app/core/schemas/gp_places.py](../services/api/app/core/schemas/gp_places.py) | Validates itinerary-place additions, edits, remarks and geocoding requests. |
| [services/api/app/core/schemas/gp_polls.py](../services/api/app/core/schemas/gp_polls.py) | Validates poll creation and option-index voting inputs. |
| [services/api/app/core/schemas/group_planner.py](../services/api/app/core/schemas/group_planner.py) | Validates trip-group metadata, budget and itinerary-document updates. |
| [services/api/app/core/schemas/incomes.py](../services/api/app/core/schemas/incomes.py) | Validates personal income requests while identity/ownership come from authentication. |
| [services/api/app/core/schemas/invitations.py](../services/api/app/core/schemas/invitations.py) | Validates and normalizes member invitation email/input fields for expense and trip flows. |
| [services/api/app/core/schemas/places.py](../services/api/app/core/schemas/places.py) | Defines Pydantic ingestion models for geography, places, photos, tags, hours and bulk validation results. |
| [services/api/app/core/schemas/settlements.py](../services/api/app/core/schemas/settlements.py) | Validates settlement participant, amount and note inputs. |
| [services/api/app/core/schemas/trips.py](../services/api/app/core/schemas/trips.py) | Validates single-trip itinerary generation parameters. |
| [services/api/app/core/schemas/users.py](../services/api/app/core/schemas/users.py) | Defines typed account registration/login/profile/password/token request and response models. |
| [services/api/app/core/security.py](../services/api/app/core/security.py) | Adds response security headers and handles readable CSRF-cookie generation and cookie-request validation. |
| [services/api/app/core/workers/__init__.py](../services/api/app/core/workers/__init__.py) | Declares the app.core.workers Python package used by the service imports. |
| [services/api/app/core/workers/celery_app.py](../services/api/app/core/workers/celery_app.py) | Configures the Celery application, broker/backend, task loading and failure handling. |
| [services/api/app/core/workers/schedules.py](../services/api/app/core/workers/schedules.py) | Defines periodic maintenance, cache and analytics task schedules for Celery Beat. |
| [services/api/app/core/workers/tasks/__init__.py](../services/api/app/core/workers/tasks/__init__.py) | Declares the app.core.workers.tasks Python package used by the service imports. |
| [services/api/app/core/workers/tasks/ai_tasks.py](../services/api/app/core/workers/tasks/ai_tasks.py) | Processes Scout mentions, consent-aware chat summarization and AI-log retention through Celery tasks. |
| [services/api/app/core/workers/tasks/analytics_tasks.py](../services/api/app/core/workers/tasks/analytics_tasks.py) | Defines popular-search cache warming and daily usage aggregation tasks. |
| [services/api/app/core/workers/tasks/chat_tasks.py](../services/api/app/core/workers/tasks/chat_tasks.py) | Archives old messages reversibly and dispatches supported AI mentions to background processing. |
| [services/api/app/core/workers/tasks/cleanup_tasks.py](../services/api/app/core/workers/tasks/cleanup_tasks.py) | Removes expired sessions and performs configured cleanup of older soft-deleted records. |
| [services/api/app/core/workers/tasks/crew_tasks.py](../services/api/app/core/workers/tasks/crew_tasks.py) | Processes Crew commands, conversation/card responses and rate limits in the background. |
| [services/api/app/core/workers/tasks/email_tasks.py](../services/api/app/core/workers/tasks/email_tasks.py) | Wraps invitation, verification, password-reset and expense-notification delivery as retryable Celery tasks. |
| [services/api/app/core/workers/tasks/notification_tasks.py](../services/api/app/core/workers/tasks/notification_tasks.py) | Defines group/user realtime notification tasks that emit through the shared Socket.IO extension. |
| [services/api/app/expenses/__init__.py](../services/api/app/expenses/__init__.py) | Re-exports expense/group/settlement models while retaining the unified account model through compatibility imports. |
| [services/api/app/expenses/models.py](../services/api/app/expenses/models.py) | Defines expense groups, memberships, expenses, income/history, splits, settlements, balances and invitations on the shared ORM Base. |
| [services/api/app/expenses/realtime.py](../services/api/app/expenses/realtime.py) | Emits authenticated private cache-invalidations after committed expense changes without broadcasting ledger rows. |
| [services/api/app/expenses/routes/__init__.py](../services/api/app/expenses/routes/__init__.py) | Declares the app.expenses.routes Python package used by the service imports. |
| [services/api/app/expenses/routes/currencies.py](../services/api/app/expenses/routes/currencies.py) | Exposes anonymous read-only currency listings and dated exchange-rate observations. |
| [services/api/app/expenses/routes/expense_groups.py](../services/api/app/expenses/routes/expense_groups.py) | Implements authenticated expense-group creation, details, membership, role, leave and archive operations. |
| [services/api/app/expenses/routes/expense_invitations.py](../services/api/app/expenses/routes/expense_invitations.py) | Exposes private expense invitation lookup, creation, acceptance, decline, resend and cancellation with cache refresh. |
| [services/api/app/expenses/routes/expenses.py](../services/api/app/expenses/routes/expenses.py) | Exposes expense CRUD, soft delete/restore, personal/group lists and edit history with permission and freshness handling. |
| [services/api/app/expenses/routes/friends.py](../services/api/app/expenses/routes/friends.py) | Lists and saves the signed-in user's private contacts for reusable expense invitations. |
| [services/api/app/expenses/routes/group_finance.py](../services/api/app/expenses/routes/group_finance.py) | Exposes authorized group analytics, balances, simplified debts and compatibility balance-repair endpoints. |
| [services/api/app/expenses/routes/personal_finance.py](../services/api/app/expenses/routes/personal_finance.py) | Exposes private income CRUD/history and currency-separated personal summaries, transactions and analytics. |
| [services/api/app/expenses/routes/settlements.py](../services/api/app/expenses/routes/settlements.py) | Exposes authorized payment recording/deletion and group settlement/balance/debt reads. |
| [services/api/app/expenses/services/__init__.py](../services/api/app/expenses/services/__init__.py) | Declares the app.expenses.services Python package used by the service imports. |
| [services/api/app/expenses/services/exchange_rates.py](../services/api/app/expenses/services/exchange_rates.py) | Fetches and validates public currency/rate reference data with caching and explicit bounded stale fallback; it does not alter ledgers. |
| [services/api/app/expenses/services/expense_group_service.py](../services/api/app/expenses/services/expense_group_service.py) | Applies group/member lifecycle rules, serialized ownership/role changes and truthful ledger summary snapshots. |
| [services/api/app/expenses/services/expense_invite_service.py](../services/api/app/expenses/services/expense_invite_service.py) | Implements recipient checks, expiry and membership transitions for expense invitations. |
| [services/api/app/expenses/services/expense_service.py](../services/api/app/expenses/services/expense_service.py) | Validates and persists expense/split edits, balance changes, soft deletion/restoration and audit history. |
| [services/api/app/expenses/services/group_access.py](../services/api/app/expenses/services/group_access.py) | Centralizes ledger access, ownership/role checks, former-member balance preservation and invitation/member invariants. |
| [services/api/app/expenses/services/friend_service.py](../services/api/app/expenses/services/friend_service.py) | Upserts private contacts atomically and resolves registered names, nicknames and literal searches. |
| [services/api/app/expenses/services/group_finance_service.py](../services/api/app/expenses/services/group_finance_service.py) | Derives group spending/trends and balance recalculation from persisted financial records. |
| [services/api/app/expenses/services/ledger_math.py](../services/api/app/expenses/services/ledger_math.py) | Serializes decimal balances and simplifies debts while retaining single-cent obligations. |
| [services/api/app/expenses/services/money_lock.py](../services/api/app/expenses/services/money_lock.py) | Locks financial groups/records so validation and monetary mutation share a serialized transaction. |
| [services/api/app/expenses/services/personal_finance_service.py](../services/api/app/expenses/services/personal_finance_service.py) | Applies ownership-aware income CRUD and computes currency-separated personal cash-flow/transaction reports. |
| [services/api/app/expenses/services/settlement_service.py](../services/api/app/expenses/services/settlement_service.py) | Validates settlement parties and debt limits, updates balances and supports authorized payment reversal. |
| [services/api/app/expenses/services/trip_treasury.py](../services/api/app/expenses/services/trip_treasury.py) | Creates and synchronizes the expense-domain side of verified linked trip treasuries and membership. |
| [services/api/app/itinerary/__init__.py](../services/api/app/itinerary/__init__.py) | Declares the app.itinerary Python package used by the service imports. |
| [services/api/app/itinerary/routes/__init__.py](../services/api/app/itinerary/routes/__init__.py) | Declares the app.itinerary.routes Python package used by the service imports. |
| [services/api/app/itinerary/routes/gp_checklist.py](../services/api/app/itinerary/routes/gp_checklist.py) | Exposes trip checklist listing, creation, toggle, metadata updates, assignment, deletion and statistics. |
| [services/api/app/itinerary/routes/gp_events.py](../services/api/app/itinerary/routes/gp_events.py) | Exposes destination event discovery and event-category information through the event service. |
| [services/api/app/itinerary/routes/gp_export.py](../services/api/app/itinerary/routes/gp_export.py) | Exposes trip PDF/iCalendar export, cloning and group-code joining with trip access checks. |
| [services/api/app/itinerary/routes/gp_places.py](../services/api/app/itinerary/routes/gp_places.py) | Exposes saved trip places, votes, schedule/details/remarks edits, deletion and geocoding. |
| [services/api/app/itinerary/routes/trips.py](../services/api/app/itinerary/routes/trips.py) | Generates single-trip itineraries and exposes city lookups with pacing, preference and place-filter handling. |
| [services/api/app/itinerary/services/__init__.py](../services/api/app/itinerary/services/__init__.py) | Declares the app.itinerary.services Python package used by the service imports. |
| [services/api/app/itinerary/services/checklist_service.py](../services/api/app/itinerary/services/checklist_service.py) | Persists shared checklist state and validates categories, priority, due dates and active-member assignments. |
| [services/api/app/itinerary/services/events_service.py](../services/api/app/itinerary/services/events_service.py) | Looks up travel-destination events using the configured Ticketmaster integration and external-call safeguards. |
| [services/api/app/itinerary/services/export_service.py](../services/api/app/itinerary/services/export_service.py) | Produces trip PDF and iCalendar data and implements the related export/clone helpers. |
| [services/api/app/itinerary/services/travel_place_service.py](../services/api/app/itinerary/services/travel_place_service.py) | Applies authorization and validation to stored trip stops, votes, coordinates, timing and metadata changes. |
| [services/api/app/notifications/__init__.py](../services/api/app/notifications/__init__.py) | Declares the app.notifications Python package used by the service imports. |
| [services/api/app/notifications/email/__init__.py](../services/api/app/notifications/email/__init__.py) | Exposes the SMTP EmailService and its shared email_service instance. |
| [services/api/app/notifications/email/config.py](../services/api/app/notifications/email/config.py) | Centralizes feature-level email notification enablement settings. |
| [services/api/app/notifications/email/links.py](../services/api/app/notifications/email/links.py) | Builds canonical expense-invitation frontend links shared by responses and email templates. |
| [services/api/app/notifications/email/smtp.py](../services/api/app/notifications/email/smtp.py) | Implements SMTP delivery with HTML/plain-text templates for application notification emails. |
| [services/api/app/notifications/routes/__init__.py](../services/api/app/notifications/routes/__init__.py) | Declares the app.notifications.routes Python package used by the service imports. |
| [services/api/app/notifications/routes/gp_notifications.py](../services/api/app/notifications/routes/gp_notifications.py) | Exposes a user's paginated in-app notifications and single/all-read updates. |
| [services/api/app/notifications/services/__init__.py](../services/api/app/notifications/services/__init__.py) | Declares the app.notifications.services Python package used by the service imports. |
| [services/api/app/notifications/services/email_service.py](../services/api/app/notifications/services/email_service.py) | Provides the expense invitation SMTP service and its invitation templates/configured enablement checks. |
| [services/api/app/notifications/services/notification_service.py](../services/api/app/notifications/services/notification_service.py) | Creates and queries in-app notifications and updates read state for the owning user. |
| [services/api/app/partners/__init__.py](../services/api/app/partners/__init__.py) | Declares the app.partners Python package used by the service imports. |
| [services/api/app/partners/agreement_service.py](../services/api/app/partners/agreement_service.py) | Loads the agreement draft, checks approved-agent access and records explicit version/hash-bound acknowledgments, signatures and receipts. |
| [services/api/app/partners/agreements/partner-agreement-v3-2026-10-18.docx](../services/api/app/partners/agreements/partner-agreement-v3-2026-10-18.docx) | Preserves the original supplied agreement draft bytes for authorized document download and source-hash verification. |
| [services/api/app/partners/agreements/partner-agreement-v3-2026-10-18.json](../services/api/app/partners/agreements/partner-agreement-v3-2026-10-18.json) | Stores ordered agreement text/table blocks, document furniture and original-source hash for the protected reader. |
| [services/api/app/partners/media_service.py](../services/api/app/partners/media_service.py) | Validates/sanitizes supplier images and stores private media with controlled path and ownership handling. |
| [services/api/app/partners/models.py](../services/api/app/partners/models.py) | Defines supplier businesses, partner memberships, application review evidence and agreement acknowledgment/signature records. |
| [services/api/app/partners/package_models.py](../services/api/app/partners/package_models.py) | Defines private tour packages, immutable content revisions, media metadata and staff review records. |
| [services/api/app/partners/package_review_routes.py](../services/api/app/partners/package_review_routes.py) | Exposes protected image upload/read, supplier submission and staff package-list/decision endpoints. |
| [services/api/app/partners/package_routes.py](../services/api/app/partners/package_routes.py) | Exposes private supplier package listing, creation, retrieval, versioned saving and duplication. |
| [services/api/app/partners/package_schemas.py](../services/api/app/partners/package_schemas.py) | Validates package content, itinerary/departure/rate/media inputs and defines draft/review response contracts. |
| [services/api/app/partners/package_services.py](../services/api/app/partners/package_services.py) | Enforces approved-owner access and versioned private draft changes, preparation checks, media selection and submission/review transitions. |
| [services/api/app/partners/routes.py](../services/api/app/partners/routes.py) | Exposes isolated partner identity/application/agreement endpoints and authorized staff application review routes with explicit errors and no-store responses. |
| [services/api/app/partners/schemas.py](../services/api/app/partners/schemas.py) | Validates partner identity, business application, review and agreement-signing inputs and response shapes. |
| [services/api/app/partners/security.py](../services/api/app/partners/security.py) | Resolves isolated partner tokens/sessions, sets/clears partner cookies and guards supplier requests separately from traveler authentication. |
| [services/api/app/partners/services.py](../services/api/app/partners/services.py) | Implements partner registration/login, application versions, snapshots, submission and staff review decisions. |
| [services/api/app/partners/staff_routes.py](../services/api/app/partners/staff_routes.py) | Implements employee-only staff-console login without granting staff access to customer or partner identities. |
| [services/api/app/places/__init__.py](../services/api/app/places/__init__.py) | Declares the app.places Python package used by the service imports. |
| [services/api/app/places/location_models.py](../services/api/app/places/location_models.py) | Queries and adapts catalog geography/place rows for the existing location APIs. |
| [services/api/app/places/location_repository.py](../services/api/app/places/location_repository.py) | Preserves location init_database/get_db compatibility over the shared catalog connection pool. |
| [services/api/app/places/models.py](../services/api/app/places/models.py) | Defines place-search result, geography, photo, hours and autocomplete data objects. |
| [services/api/app/places/repository.py](../services/api/app/places/repository.py) | Supplies pooled travel-catalog connections shared by place search and location lookups. |
| [services/api/app/places/routes/__init__.py](../services/api/app/places/routes/__init__.py) | Declares the app.places.routes Python package used by the service imports. |
| [services/api/app/places/routes/admin_places.py](../services/api/app/places/routes/admin_places.py) | Exposes authenticated staff geography/place/media ingestion, validation, bulk import and audit endpoints. |
| [services/api/app/places/routes/gp_destinations.py](../services/api/app/places/routes/gp_destinations.py) | Exposes planner catalog destinations, cards/viewports and related destination/activity lookup endpoints. |
| [services/api/app/places/routes/locations.py](../services/api/app/places/routes/locations.py) | Retains deprecated unified location/geography/place endpoints with bounded queries and deprecation headers. |
| [services/api/app/places/routes/places.py](../services/api/app/places/routes/places.py) | Exposes place search, autocomplete, detail and catalog statistics with pagination/freshness metadata. |
| [services/api/app/places/search/__init__.py](../services/api/app/places/search/__init__.py) | Declares the app.places.search Python package used by the service imports. |
| [services/api/app/places/search/web_search.py](../services/api/app/places/search/web_search.py) | Queries the configured web-search backends with fallback and circuit-breaker behavior for Scout discovery. |
| [services/api/app/places/services/__init__.py](../services/api/app/places/services/__init__.py) | Declares the app.places.services Python package used by the service imports. |
| [services/api/app/places/services/data_ingestion_service.py](../services/api/app/places/services/data_ingestion_service.py) | Validates and applies single/bulk writes for geography, places, photos, tags and opening hours with ingestion results. |
| [services/api/app/places/services/destination_service.py](../services/api/app/places/services/destination_service.py) | Resolves destination and popular-place lookups from the configured travel catalog. |
| [services/api/app/places/services/place_search_service.py](../services/api/app/places/services/place_search_service.py) | Implements ranked/filtered place search, autocomplete, details and statistics over catalog data. |
| [services/api/app/places/services/planner_catalog_service.py](../services/api/app/places/services/planner_catalog_service.py) | Reads destination-scoped planner geography, place/festival cards and map viewports from the configured read-only planner catalog. |
| [services/api/app/scout/__init__.py](../services/api/app/scout/__init__.py) | Declares the app.scout Python package used by the service imports. |
| [services/api/app/scout/llm/__init__.py](../services/api/app/scout/llm/__init__.py) | Declares the app.scout.llm Python package used by the service imports. |
| [services/api/app/scout/llm/ollama_client.py](../services/api/app/scout/llm/ollama_client.py) | Calls the configured Ollama generation endpoint with timeouts, circuit-breaker state and explicit unavailable errors. |
| [services/api/app/scout/llm/output_validator.py](../services/api/app/scout/llm/output_validator.py) | Sanitizes and validates generated response text before storage or presentation. |
| [services/api/app/scout/llm/prompt_templates.py](../services/api/app/scout/llm/prompt_templates.py) | Builds server-owned Scout prompts from structured context and explicitly delimited untrusted text. |
| [services/api/app/scout/models.py](../services/api/app/scout/models.py) | Defines per-group AI consent, preference profiles and interaction-log ORM records. |
| [services/api/app/scout/routes/__init__.py](../services/api/app/scout/routes/__init__.py) | Declares the app.scout.routes Python package used by the service imports. |
| [services/api/app/scout/routes/ai_confirm.py](../services/api/app/scout/routes/ai_confirm.py) | Validates confirmation/cancellation of pending Crew actions and rechecks permissions before destructive execution. |
| [services/api/app/scout/routes/ai_consent.py](../services/api/app/scout/routes/ai_consent.py) | Exposes current-user group consent lookup, updates and revocation with preference-data cleanup. |
| [services/api/app/scout/services/__init__.py](../services/api/app/scout/services/__init__.py) | Declares the app.scout.services Python package used by the service imports. |
| [services/api/app/scout/services/consent_gate.py](../services/api/app/scout/services/consent_gate.py) | Resolves per-user/per-group consent and privacy overrides before agent data access. |
| [services/api/app/scout/services/crew_agent_service.py](../services/api/app/scout/services/crew_agent_service.py) | Dispatches Crew command intents, collects missing fields, requests confirmation and invokes authorized domain operations. |
| [services/api/app/scout/services/crew_conversation.py](../services/api/app/scout/services/crew_conversation.py) | Stores per-user/per-group multi-step Crew conversation state and expiry in Redis. |
| [services/api/app/scout/services/crew_parsers.py](../services/api/app/scout/services/crew_parsers.py) | Classifies Crew commands and extracts structured entities using staged parsing strategies. |
| [services/api/app/scout/services/scout_agent_service.py](../services/api/app/scout/services/scout_agent_service.py) | Coordinates consent-aware Scout intent handling, reference/web context, rate limits and optional language-model responses. |
| [services/api/app/trips/__init__.py](../services/api/app/trips/__init__.py) | Re-exports the collaborative trip, member, place, poll, checklist, activity, vault and chat ORM models. |
| [services/api/app/trips/models.py](../services/api/app/trips/models.py) | Defines collaborative trip/member entities and their saved places, votes, invitations, logistics, activity, notifications and chat records. |
| [services/api/app/trips/realtime/__init__.py](../services/api/app/trips/realtime/__init__.py) | Declares the app.trips.realtime Python package used by the service imports. |
| [services/api/app/trips/realtime/changes.py](../services/api/app/trips/realtime/changes.py) | Captures committed planner changes and sends authorized clients private refresh notifications. |
| [services/api/app/trips/realtime/events.py](../services/api/app/trips/realtime/events.py) | Authenticates Socket.IO clients, verifies group-room membership and handles presence, message and collaboration events. |
| [services/api/app/trips/realtime/socketio_ext.py](../services/api/app/trips/realtime/socketio_ext.py) | Owns the shared Flask-SocketIO singleton and its application initialization. |
| [services/api/app/trips/routes/__init__.py](../services/api/app/trips/routes/__init__.py) | Declares the app.trips.routes Python package used by the service imports. |
| [services/api/app/trips/routes/gp_chat.py](../services/api/app/trips/routes/gp_chat.py) | Exposes group message pagination/send/edit/delete, read/unread state and supported consent/AI dispatch behavior. |
| [services/api/app/trips/routes/gp_groups.py](../services/api/app/trips/routes/gp_groups.py) | Exposes group lifecycle, memberships/access roles, independent crew duties, settings, activities and linked-treasury endpoints. |
| [services/api/app/trips/routes/gp_invitations.py](../services/api/app/trips/routes/gp_invitations.py) | Exposes trip invitation creation, lookup, acceptance, decline, resend and cancellation. |
| [services/api/app/trips/routes/gp_polls.py](../services/api/app/trips/routes/gp_polls.py) | Exposes group poll creation/listing, option voting and authorized deletion. |
| [services/api/app/trips/routes/gp_vault.py](../services/api/app/trips/routes/gp_vault.py) | Exposes authorized trip-vault file upload, listing, download and deletion. |
| [services/api/app/trips/services/__init__.py](../services/api/app/trips/services/__init__.py) | Declares the app.trips.services Python package used by the service imports. |
| [services/api/app/trips/services/chat_service.py](../services/api/app/trips/services/chat_service.py) | Implements message CRUD, visibility, cursor pagination, read receipts and unread counts on persisted chat records. |
| [services/api/app/trips/services/poll_service.py](../services/api/app/trips/services/poll_service.py) | Applies poll creation/expiry, option voting, voter counting and deletion rules. |
| [services/api/app/trips/services/travel_group_service.py](../services/api/app/trips/services/travel_group_service.py) | Implements trip group lifecycle, membership, settings, role policy and group-code generation on shared accounts. |
| [services/api/app/trips/services/treasury_service.py](../services/api/app/trips/services/treasury_service.py) | Applies trip-level authorization/responsibility policy when linking and synchronizing an expense treasury. |
| [services/api/app/trips/services/trip_invite_service.py](../services/api/app/trips/services/trip_invite_service.py) | Applies trip invitation recipient/expiry checks and group membership transitions. |
| [services/api/app/trips/services/vault_service.py](../services/api/app/trips/services/vault_service.py) | Validates stored vault uploads and controls disk-backed file retrieval/deletion under the configured upload directory. |
| [services/api/docker-entrypoint.sh](../services/api/docker-entrypoint.sh) | Initializes the reference catalog and starts the requested command against a separately migrated application schema. |
| [services/api/gunicorn.conf.py](../services/api/gunicorn.conf.py) | Defines production binding, gevent workers, timeouts, recycling and logging; disables application preload so workers create their own connections. |
| [services/api/init_travel_db.py](../services/api/init_travel_db.py) | Initializes the maintained reference-catalog schema and validates existing catalog structure, integrity, foreign keys and optional emptiness without loading seed rows. |
| [services/api/migrations/README](../services/api/migrations/README) | Retains the Alembic template's short single-database configuration note. |
| [services/api/migrations/env.py](../services/api/migrations/env.py) | Registers all ORM model metadata and runs Alembic online/offline against the selected database with percent-safe URL handling. |
| [services/api/migrations/script.py.mako](../services/api/migrations/script.py.mako) | Templates newly generated Alembic revision modules and their upgrade/downgrade functions. |
| [services/api/migrations/versions/119b418945ce_json_to_jsonb_postgresql.py](../services/api/migrations/versions/119b418945ce_json_to_jsonb_postgresql.py) | Preserves a retired JSONB-conversion revision as a no-op; the portable frozen baseline owns current JSON types. |
| [services/api/migrations/versions/60621bfec6f2_add_missing_composite_indexes.py](../services/api/migrations/versions/60621bfec6f2_add_missing_composite_indexes.py) | Adds the defined composite/query lookup indexes across account, expense and planner records. |
| [services/api/migrations/versions/74866d910457_uuidv7_primary_keys.py](../services/api/migrations/versions/74866d910457_uuidv7_primary_keys.py) | Retains the historical UUID migration ID while rejecting unsafe legacy integer-storage rewrites rather than silently converting them. |
| [services/api/migrations/versions/75118e6ab634_initial_schema.py](../services/api/migrations/versions/75118e6ab634_initial_schema.py) | Defines the frozen UUID-native application schema used for fresh operational database installations. |
| [services/api/migrations/versions/83f1d84d08e4_add_ai_consent_preferences_agent_logs.py](../services/api/migrations/versions/83f1d84d08e4_add_ai_consent_preferences_agent_logs.py) | Preserves the legacy AI-table revision, tolerating the complete baseline and rejecting partial incompatible table sets. |
| [services/api/migrations/versions/a0a12823fc65_materialized_views_postgresql.py](../services/api/migrations/versions/a0a12823fc65_materialized_views_postgresql.py) | Preserves a retired materialized-view revision as a no-op pending a separate reviewed design. |
| [services/api/migrations/versions/a18b2c3d4e5f_partner_onboarding.py](../services/api/migrations/versions/a18b2c3d4e5f_partner_onboarding.py) | Adds partner business/member/review records and portal identity classification while preserving existing users as travelers. |
| [services/api/migrations/versions/a5b6c7d8e9f0_add_checklist_metadata_and_chat_fks.py](../services/api/migrations/versions/a5b6c7d8e9f0_add_checklist_metadata_and_chat_fks.py) | Adds persisted checklist metadata and missing chat-reference constraints for supported existing databases. |
| [services/api/migrations/versions/b29c3d4e5f60_tour_drafts.py](../services/api/migrations/versions/b29c3d4e5f60_tour_drafts.py) | Adds private supplier package and content-revision storage. |
| [services/api/migrations/versions/b7c8d9e0f1a2_complete_vault_and_place_time_schema.py](../services/api/migrations/versions/b7c8d9e0f1a2_complete_vault_and_place_time_schema.py) | Completes supported vault/place-time schema coverage and validates UUID-native storage. |
| [services/api/migrations/versions/c30d4e5f6071_partner_agreement.py](../services/api/migrations/versions/c30d4e5f6071_partner_agreement.py) | Adds demo classification and explicit agreement-reading acknowledgment evidence; reading is separate from signature. |
| [services/api/migrations/versions/c4d5e6f7a8b9_add_chat_tables.py](../services/api/migrations/versions/c4d5e6f7a8b9_add_chat_tables.py) | Preserves legacy chat-table creation, tolerating the complete baseline while rejecting partial incompatible chat schemas. |
| [services/api/migrations/versions/c62f718293a4_personal_display_currency.py](../services/api/migrations/versions/c62f718293a4_personal_display_currency.py) | Adds a nullable per-user personal dashboard currency preference without choosing a default for existing users. |
| [services/api/migrations/versions/d73f8293a5b6_friend_contacts.py](../services/api/migrations/versions/d73f8293a5b6_friend_contacts.py) | Adds private saved friends and backfills the original inviter's historical expense recipients. |
| [services/api/migrations/versions/c9d2e4f6a8b0_add_personal_income_ledger.py](../services/api/migrations/versions/c9d2e4f6a8b0_add_personal_income_ledger.py) | Adds personal income records, their audit history and related personal-ledger indexes. |
| [services/api/migrations/versions/d41e5f607182_agent_signatures.py](../services/api/migrations/versions/d41e5f607182_agent_signatures.py) | Adds approved-agent signature evidence and receipt fields for the agreement draft workflow. |
| [services/api/migrations/versions/d4a1c3e8f9b0_add_settlement_and_verification_audit_columns.py](../services/api/migrations/versions/d4a1c3e8f9b0_add_settlement_and_verification_audit_columns.py) | Adds persisted settlement-deletion and account email-verification audit fields. |
| [services/api/migrations/versions/e1f2a3b4c5d6_add_trip_member_crew_role.py](../services/api/migrations/versions/e1f2a3b4c5d6_add_trip_member_crew_role.py) | Adds optional trip responsibilities independently of membership access roles. |
| [services/api/migrations/versions/e336ee48cb0f_add_date_partitioning_postgresql.py](../services/api/migrations/versions/e336ee48cb0f_add_date_partitioning_postgresql.py) | Preserves the retired date-partitioning revision as a no-op for the UUID-native baseline. |
| [services/api/migrations/versions/e52f60718293_package_review_media.py](../services/api/migrations/versions/e52f60718293_package_review_media.py) | Adds package submission/approval revision metadata, private media records and staff review evidence. |
| [services/api/migrations/versions/e80825488cb5_add_audit_log_table.py](../services/api/migrations/versions/e80825488cb5_add_audit_log_table.py) | Ensures security audit storage exists on supported legacy databases and completes its relationship metadata. |
| [services/api/migrations/versions/f2a3b4c5d6e7_add_chat_message_archival.py](../services/api/migrations/versions/f2a3b4c5d6e7_add_chat_message_archival.py) | Adds reversible persisted chat archival state and adjusts the PostgreSQL active-message index. |
| [services/api/openapi.json](../services/api/openapi.json) | Contains exported API routes and explicit request/response schemas used to generate the shared TypeScript API client. |
| [services/api/package.json](../services/api/package.json) | Registers @tripraft/api in the pnpm/Turbo workspace and maps test, lint and syntax-check tasks to Python commands. |
| [services/api/pytest.ini](../services/api/pytest.ini) | Selects backend test discovery, marker declarations, failure reporting and coverage configuration sections. |
| [services/api/requirements-dev.txt](../services/api/requirements-dev.txt) | Adds the test, coverage, critical-error lint and YAML validation tools used in development and CI. |
| [services/api/requirements.txt](../services/api/requirements.txt) | Pins the Python API runtime dependencies for Flask, databases, authentication, validation, sockets, workers and external integrations. |
| [services/api/ruff.toml](../services/api/ruff.toml) | Selects the Python 3.11 syntax/error lint baseline and excludes migration files from ordinary lint checks. |
| [services/api/run.py](../services/api/run.py) | Starts the native Flask/Socket.IO development server, applies gevent patching before imports, and prepares explicitly enabled source reload behavior. |
| [services/api/schema_status.py](../services/api/schema_status.py) | Read-only migration graph status and pending change descriptions shared by startup and release tools. |
| [services/api/schema/tripraft-canonical-schema.sql](../services/api/schema/tripraft-canonical-schema.sql) | Preserves the older seed/reference schema and proposed extensions; it is not the initializer's selected runtime schema. |
| [services/api/schema/tripraft-global-schema-v2.1.sql](../services/api/schema/tripraft-global-schema-v2.1.sql) | Defines the maintained empty SQLite travel/reference catalog initialized by init_travel_db.py, including geography, place data and full-text structures. |
| [services/api/tests/conftest.py](../services/api/tests/conftest.py) | Configures a throwaway application database before app imports and provides migrated Flask, CSRF-aware clients, users and trip/expense fixtures. |
| [services/api/tests/test_agent_signatures.py](../services/api/tests/test_agent_signatures.py) | Verifies post-approval signing, immutable/private receipts, exact document versions/hashes and failure cases that must not unlock package tools. |
| [services/api/tests/test_ai_consent.py](../services/api/tests/test_ai_consent.py) | Verifies consent revocation, deletion of preference/log/summary data and repeatable privacy operations. |
| [services/api/tests/test_auth_lifecycle.py](../services/api/tests/test_auth_lifecycle.py) | Verifies signup/login, persistent device sessions, refresh renewal, logout isolation, validation and authentication error behavior. |
| [services/api/tests/test_auth_tokens.py](../services/api/tests/test_auth_tokens.py) | Verifies refresh-token hashing, rotation and rejection/revocation behavior instead of storing readable refresh tokens. |
| [services/api/tests/test_canonical_catalog.py](../services/api/tests/test_canonical_catalog.py) | Verifies empty catalog initialization, maintained schema selection, FTS updates, foreign keys and preservation/rollback of existing databases. |
| [services/api/tests/test_crew_expense_deletion.py](../services/api/tests/test_crew_expense_deletion.py) | Verifies confirmed Crew expense deletion, ledger reversal, exact pending actions and authorization rechecks. |
| [services/api/tests/test_csrf.py](../services/api/tests/test_csrf.py) | Verifies CSRF requirements for cookie-authenticated account, logout, refresh and related mutations. |
| [services/api/tests/test_demo_partner_setup.py](../services/api/tests/test_demo_partner_setup.py) | Verifies separate demo supplier ownership and approval preserve staff identity without manufacturing agreement assent. |
| [services/api/tests/test_dev_reload.py](../services/api/tests/test_dev_reload.py) | Verifies native migration/reload preparation is explicit and stays out of production. |
| [services/api/tests/test_endpoint_inventory.py](../services/api/tests/test_endpoint_inventory.py) | Exercises previously fragile registered endpoints covering consent, chat read state, expenses, invitations, account operations and malformed inputs. |
| [services/api/tests/test_exchange_rates.py](../services/api/tests/test_exchange_rates.py) | Verifies dated read-only rates, supported currency validation, caching, stale fallback and provider-failure behavior. |
| [services/api/tests/test_expense_group_lifecycle.py](../services/api/tests/test_expense_group_lifecycle.py) | Verifies group ownership/membership, invitations, whole-ledger summaries and financial lifecycle invariants. |
| [services/api/tests/test_expense_friends.py](../services/api/tests/test_expense_friends.py) | Verifies private contacts, invitation atomicity, nickname search and signup name resolution. |
| [services/api/tests/test_expense_realtime.py](../services/api/tests/test_expense_realtime.py) | Verifies authenticated devices receive only authorized, committed expense-change notifications and lose access after removal. |
| [services/api/tests/test_expense_restore.py](../services/api/tests/test_expense_restore.py) | Verifies soft-deleted expenses restore once with their identifiers, splits, balances, history and permissions preserved. |
| [services/api/tests/test_family_treasury_roles.py](../services/api/tests/test_family_treasury_roles.py) | Verifies linked-treasury ownership, independent trip duties, viewer restrictions, date bounds and rollback on incomplete linking. |
| [services/api/tests/test_group_access_controls.py](../services/api/tests/test_group_access_controls.py) | Verifies active membership and role requirements across exports, vault files and expense-group linking/summary reads. |
| [services/api/tests/test_group_planner_features.py](../services/api/tests/test_group_planner_features.py) | Verifies poll lifecycle/voting, valid saved-stop behavior and related planner feature permissions. |
| [services/api/tests/test_group_planner_smoke.py](../services/api/tests/test_group_planner_smoke.py) | Exercises representative UUID-based chat, checklist, place and planner endpoints against the migrated test application. |
| [services/api/tests/test_group_planner_tabs.py](../services/api/tests/test_group_planner_tabs.py) | Verifies checklist metadata/assignment and group membership actions for viewer, member and owner roles. |
| [services/api/tests/test_idempotency.py](../services/api/tests/test_idempotency.py) | Verifies request-key caller/method/path scoping, atomic reservations, replay and duplicate-request handling with an in-memory Redis substitute. |
| [services/api/tests/test_migration_contract.py](../services/api/tests/test_migration_contract.py) | Verifies fresh schema parity, reversible/data-preserving upgrades, frozen baseline behavior and rejection of unsupported legacy/drifted identifier storage. |
| [services/api/tests/test_database_release.py](../services/api/tests/test_database_release.py) | Verifies read-only planning, data-preserving upgrades, unknown-history rejection and deployed-commit readiness. |
| [services/api/tests/test_database_release_postgresql.py](../services/api/tests/test_database_release_postgresql.py) | Tests the real advisory lock and idempotent release runner in a disposable loopback PostgreSQL database. |
| [services/api/tests/test_money_concurrency.py](../services/api/tests/test_money_concurrency.py) | Verifies concurrent settlements, deletion and edits serialize financial validation and balance changes correctly. |
| [services/api/tests/test_money_integrity.py](../services/api/tests/test_money_integrity.py) | Verifies split totals, participant/payer rules, edits and ledger/balance reversals retain exact monetary invariants. |
| [services/api/tests/test_p3_contracts.py](../services/api/tests/test_p3_contracts.py) | Verifies deprecated route forwarding/method rules, configured health versions and JSON-safe activity/notification values. |
| [services/api/tests/test_package_review.py](../services/api/tests/test_package_review.py) | Verifies supplier isolation, validated private images, immutable submissions, corrections and staff approval using synthetic in-memory inputs. |
| [services/api/tests/test_partner_agreement.py](../services/api/tests/test_partner_agreement.py) | Verifies faithful agreement import, protected original/text access and explicit reading evidence separate from signature. |
| [services/api/tests/test_partners.py](../services/api/tests/test_partners.py) | Verifies isolated supplier authentication, application validation/version conflicts, verification and staff review lifecycle. |
| [services/api/tests/test_personal_finance.py](../services/api/tests/test_personal_finance.py) | Verifies private personal income/expense lifecycle, currency separation, filtered reports and pagination. |
| [services/api/tests/test_phase1_contracts.py](../services/api/tests/test_phase1_contracts.py) | Verifies response/profile/input contracts and invitation/chat lifecycle regressions from the first audit phase. |
| [services/api/tests/test_phase2_continued.py](../services/api/tests/test_phase2_continued.py) | Verifies follow-up robustness for Crew parsing, exact AI mentions, untrusted prompt delimiting, cursor IDs and ingestion bounds. |
| [services/api/tests/test_phase2_contracts.py](../services/api/tests/test_phase2_contracts.py) | Verifies bounded query parsing, itinerary filters, exact money rounding, access policy, date validation and calendar export contracts. |
| [services/api/tests/test_planner_catalog.py](../services/api/tests/test_planner_catalog.py) | Verifies scoped geography/cards, selected catalog IDs, missing-catalog errors and map viewports without invented coordinates. |
| [services/api/tests/test_planner_live_security.py](../services/api/tests/test_planner_live_security.py) | Verifies message authorship, private assistant cards, viewer restrictions and immediate revoked-room/data access across realtime transports. |
| [services/api/tests/test_security_hardening.py](../services/api/tests/test_security_hardening.py) | Verifies trusted-proxy identity, safe correlation IDs and administrator-only route discovery. |
| [services/api/tests/test_staff_console.py](../services/api/tests/test_staff_console.py) | Verifies employee-only staff sessions and isolation from traveler/supplier credentials and demo identities. |
| [services/api/tests/test_tour_drafts.py](../services/api/tests/test_tour_drafts.py) | Verifies approved supplier access, private partial draft edits, version conflicts and cross-supplier isolation. |
| [services/api/tests/test_trip_crew_roles.py](../services/api/tests/test_trip_crew_roles.py) | Verifies assigning/clearing trip responsibilities does not promote or change membership access roles. |
| [services/api/tests/test_trip_invitation_email_link.py](../services/api/tests/test_trip_invitation_email_link.py) | Verifies trip invitation email points to a registered frontend acceptance route. |
| [services/api/tests/test_uuid_ids.py](../services/api/tests/test_uuid_ids.py) | Verifies UUID field handling and UUID-native API/ORM operations while rejecting legacy integer identifiers. |
| [services/api/tests/test_websocket_auth.py](../services/api/tests/test_websocket_auth.py) | Verifies Socket.IO authentication, UUID identities, group-room access and presence identifiers. |

## Expense UI and latency additions (2026-10-26)

These entries extend the dated inventory above; existing file descriptions
remain a record of that earlier review.

| File | Responsibility |
|---|---|
| `apps/web/src/features/expenses/jsx/CurrencyAmount.jsx` | Paired converted/source amount presentation with pinned-rate support. |
| `apps/web/src/features/expenses/css/CurrencyAmount.css` | Responsive paired-money layout. |
| `apps/web/src/features/expenses/jsx/CurrencyChangeStatus.jsx` | Accessible currency save/conversion feedback. |
| `apps/web/src/features/expenses/css/CurrencyChangeStatus.css` | Currency animations and reduced-motion styles. |
| `apps/web/src/__tests__/currencyChangeStatus.test.jsx` | Currency progress/error/completion regressions. |
| `apps/web/src/__tests__/expenseCurrencyLayout.test.jsx` | Paired currencies and source-unit regressions across the expense views. |
| `services/api/tests/expense_workflow_benchmark.py` | Opt-in isolated local API timing/SQL-count benchmark. |
| `infra/tools/render_expense_latency_report.py` | Generates the interactive timing table from benchmark JSON. |
| `docs/operations/expense-latency.html` | Self-contained filterable local workflow timing evidence. |
| `docs/archive/reports/expense-ui-latency-2026-10-26.md` | UI changes, performance measurements, verification and limits. |
| `docs/plans/expenses/README.md` | Index and status of the proposed expense feature backlog. |
| `docs/plans/expenses/ranked-feature-backlog.md` | Combined ranked 60-item proposed backlog. |
| `docs/plans/expenses/advanced-concepts.md` | Advanced expense/travel concepts with examples and possible first versions. |
| `apps/web/src/__tests__/expenseReadLatency.test.jsx` | Verifies single-layer expense retries, deferred group reads and live-owned focus refresh. |
| `apps/web/src/__tests__/groupCurrencyProgress.test.jsx` | Verifies currency saving, pending conversion, failure and retry in group settings. |
| `services/api/app/core/db/cooperative.py` | Enables cooperative psycopg2 waits in gevent workers before PostgreSQL connections open. |
| `services/api/tests/test_cooperative_database.py` | Verifies concurrent work during database waits and callback setup and preservation. |
| `docs/archive/reports/expense-browser-delay-fix-2026-10-26.md` | Records browser HAR findings, expense delay fixes and scoped timing evidence. |
