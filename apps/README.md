# Apps developer guide

Reviewed against the local source on 2026-10-20. This guide explains every project file under `apps/`, its role in the application, and a suggested Git commit scope.

There are **300 application files: 19 in `admin/` and 281 in `web/`**, plus this README (301 files including the guide). Paths below are relative to `apps/`. Dependencies, generated builds and local task caches are excluded from those counts.

## Reading and maintaining the code

Each JavaScript, TypeScript, CSS, HTML, SVG and environment-example file starts with a format-valid `Purpose:` comment describing its actual responsibility. Keep that comment and the matching guide entry current when behavior changes. Explain non-obvious constraints near the relevant implementation; avoid comments that merely repeat a variable or function name.

JSON manifests/configurations and binary PNG/JPEG images cannot contain ordinary source comments without changing their format. Their responsibilities are documented here. Existing Markdown asset guides explain their own contents. This README documents itself as the apps file index and commit guide.

The descriptions cover current behavior, not a promise that every exported component is mounted or every service method has a visible screen. In particular:

- `Analytics.jsx` and `ExpenseAnalytics.jsx` currently show access/unavailable messages.
- `InactivityTracker.jsx` is optional and is not mounted by current application routes.
- OpenFreeMap in the group planner uses public styles without a map key; the single-trip map uses OpenStreetMap tiles.
- Partner package drafts and staff approvals remain private; approval does not enable public booking or checkout.
- The demo stores workspace changes in the browser, while explicitly permitted public catalog/currency reads can use the API.

## Applications and data flow

| Application | Local port | Main responsibility | Shared workspace dependencies |
|---|---|---|---|
| `admin/` | 5174 | Staff login, supplier applications, protected agreement reading, package review, service readiness and ingestion audit | `@tripraft/api-client`, `@tripraft/types`, `@tripraft/config` |
| `web/` | 5173 | Traveler accounts, discovery, trip planning, chat, expenses and the isolated partner portal | `@tripraft/ui`, `@tripraft/types`, `@tripraft/config` |

Both Vite apps proxy `/api` to the local Flask API on port 5000. Web also proxies `/socket.io`. Web's configured API base normally includes `/api`; the staff generated client uses paths that already include `/api`, so its default base is empty.

The usual web flow is **page/component -> query hook or service -> API client -> Flask**. React Query manages server-state freshness; Socket.IO notifications trigger recovery/refetch where needed. Traveler and partner authentication use separate cookie/CSRF flows. Server authorization remains authoritative for all privileged actions.

## Folder map

| Folder | Developer responsibility |
|---|---|
| `admin/src/` | Staff application entry, login, operations and review panels; `styles.css` is shared by these views. |
| `admin/tests/` | Staff authorization/review regressions and the Vite environment Babel transform. |
| `web/public/` | Static URLs copied into the web build, including favicon, illustrations and local demo media. |
| `web/src/assets/` | Assets imported and processed by the bundler. |
| `web/src/components/common/` | Shared UI; `jsx/` contains components and `css/` their styles. |
| `web/src/components/layout/` | Shared Header/Footer components and their `jsx/`/`css/` implementations. |
| `web/src/config/` and `context/` | Public application settings and traveler authentication state. |
| `web/src/features/auth/` | Traveler forms, route protection and helpers, split into `jsx/`, `css/` and `utils/`. |
| `web/src/features/discover/` | Catalog search and place details, with `jsx/` views and `css/` styles. |
| `web/src/features/expenses/` | Expense/settlement UI in `jsx/`, visual rules in `css/`, and calculations/permissions in `utils/`. |
| `web/src/features/itinerary/` | Single-trip generated itineraries in `jsx/`, styled by `css/TripPlanner.css`. |
| `web/src/features/partners/` | Separate supplier identity, agreement, application and package flow; `__tests__/` covers these contracts. |
| `web/src/features/polls/` and `scout/` | Chat poll rendering and Scout/Crew identity, consent and interaction cards. |
| `web/src/features/trips/` | Collaborative planner; `constants/`, `demo/`, `hooks/`, `utils/` and `css/` support its views. |
| `web/src/features/trips/jsx/` | Planner page/manager; `chat/`, `map/`, `shared/` and `tabs/` split the workspace into focused components. |
| `web/src/hooks/` | Query/mutation state, live updates, currency display and local note drafts. |
| `web/src/lib/` | Message cache reconciliation and permitted query persistence. |
| `web/src/pages/` | Routed pages and wrappers; `styles/` contains page-specific CSS. |
| `web/src/services/` and `utils/` | Backend domain calls, transport, error/money/date/coordinate helpers. |
| `web/src/__tests__/` and `web/tests/` | Web regression suites and test transforms/mocks. |

`node_modules/`, `dist/` and `.turbo/` inside either app are local dependencies/build output/task cache and are ignored by Git. Local `.env` files are also ignored; only `.env.example` belongs in the upload.

## Git commits

Use focused commits with a clear subject. Conventional Commit syntax is a suggested convention for this guide, not an existing repository-wide enforcement rule:

```text
<type>(<scope>): <specific change>
```

Useful types are `feat`, `fix`, `refactor`, `style`, `test`, `chore` and `docs`. The scope column in the file index identifies the owning area; related hooks, services and tests can share the feature scope when changed together. Examples describe possible future changes, not completed work:

```text
fix(web/auth): preserve invitation destination after login
test(web/expenses): cover failed settlement saves
style(web/trips): improve planner layout on narrow screens
docs(apps): explain file responsibilities and configuration
```

Stage the exact files belonging to the change, review the staged diff and run checks appropriate to it. A file-purpose comment explains a file; a Git commit message explains a particular change. Git records the actual history.

## File index

The following tables contain one entry for each of the 300 application files. Follow a file link to inspect its implementation. Suggested scopes are labels for commit messages, not code exports.

### Staff application (19 files)

| File | What it does | Suggested scope |
|---|---|---|
| [admin/.env.example](admin/.env.example) | Documents the public API origin and web URL settings; admin API paths already include /api, so the API base defaults to an empty string. | `admin` |
| [admin/babel.config.cjs](admin/babel.config.cjs) | Compiles JavaScript, React JSX and TypeScript for Jest, replacing import.meta.env through tests/viteEnvTransform.cjs. | `admin` |
| [admin/eslint.config.mjs](admin/eslint.config.mjs) | Re-exports the shared @tripraft/config/eslint rules for the staff application. | `admin` |
| [admin/index.html](admin/index.html) | Defines the staff application's root element and main.tsx entry, with noindex/nofollow/noarchive metadata. | `admin` |
| [admin/jest.config.cjs](admin/jest.config.cjs) | Runs tests/*.test.jsx in jsdom with Babel transforms and Testing Library DOM assertions. | `admin` |
| [admin/package.json](admin/package.json) | Defines @tripraft/admin dependencies and its Vite, ESLint, TypeScript and Jest commands. | `admin` |
| [admin/src/App.tsx](admin/src/App.tsx) | Verifies the server account before loading privileged readiness and ingestion-audit data; renders staff login, review panels, refresh and logout controls. | `admin` |
| [admin/src/PackageReviewPanel.tsx](admin/src/PackageReviewPanel.tsx) | Lists package submissions by status and shows private content, media and proposed rates; sends versioned approval, correction or rejection decisions with required reasons. | `admin` |
| [admin/src/PartnerAgreementPanel.tsx](admin/src/PartnerAgreementPanel.tsx) | Loads the protected agreement draft on demand, renders its text and tables, and links to the original document download. | `admin` |
| [admin/src/PartnerReviewPanel.tsx](admin/src/PartnerReviewPanel.tsx) | Paginates supplier applications, displays business and signature evidence, and submits versioned review decisions while blocking self-review controls. | `admin` |
| [admin/src/StaffLogin.tsx](admin/src/StaffLogin.tsx) | Submits employee credentials to /api/v1/admin/session and asks App to recheck identity before showing privileged operations. | `admin` |
| [admin/src/env.d.ts](admin/src/env.d.ts) | References vite/client so TypeScript recognizes Vite's browser and import.meta.env types. | `admin` |
| [admin/src/main.tsx](admin/src/main.tsx) | Mounts App in React StrictMode, loads staff-console styles, and fails explicitly if the HTML root is missing. | `admin` |
| [admin/src/styles.css](admin/src/styles.css) | Styles staff login, readiness and audit sections, tables, agreement content, and responsive partner-review controls. | `admin` |
| [admin/tests/access.test.jsx](admin/tests/access.test.jsx) | Verifies identity loading, non-admin rejection, retry after API failure, dedicated staff login, and degraded readiness or audit errors. | `admin` |
| [admin/tests/partners.test.jsx](admin/tests/partners.test.jsx) | Verifies decision reasons and version payloads, conflict handling without replay, self-review restrictions, and protected agreement reading. | `admin` |
| [admin/tests/viteEnvTransform.cjs](admin/tests/viteEnvTransform.cjs) | Provides the Babel visitor that rewrites import.meta.env as process.env during CommonJS Jest execution. | `admin` |
| [admin/tsconfig.json](admin/tsconfig.json) | Extends the shared TypeScript configuration and checks src plus vite.config.ts. | `admin` |
| [admin/vite.config.ts](admin/vite.config.ts) | Serves the staff app on port 5174, proxies /api to Flask on port 5000, and returns a structured 503 if the proxy cannot connect. | `admin` |

### Web configuration and entry (17 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/.env.example](web/.env.example) | Documents public API, timeout, branding, support and feature-flag settings; the API base includes /api and OpenFreeMap requires no key. | `web/config` |
| [web/babel.config.cjs](web/babel.config.cjs) | Compiles JSX and TypeScript for Jest and applies tests/viteEnvTransform.cjs to Vite environment expressions. | `web/config` |
| [web/eslint.config.js](web/eslint.config.js) | Re-exports the shared @tripraft/config/eslint rules for web source and tests. | `web/config` |
| [web/index.html](web/index.html) | Defines the traveler app's title, favicon, root element and /src/main.tsx module entry. | `web/config` |
| [web/jest.config.cjs](web/jest.config.cjs) | Configures jsdom, Babel, test discovery, shared Toast resolution, source aliases, and CSS/SVG mocks. | `web/config` |
| [web/package.json](web/package.json) | Defines @tripraft/web scripts and dependencies for React, routing, queries, maps, sockets, charts and PDF export. | `web/config` |
| [web/src/App.jsx](web/src/App.jsx) | Defines lazy-loaded public, invitation and protected routes, supplies AuthProvider and feature recovery boundaries, and allows the opt-in planner demo. | `web/app` |
| [web/src/assets/placeholder-place.svg](web/src/assets/placeholder-place.svg) | Supplies the local fallback image used by discovery cards and place details when a destination photo is unavailable. | `web/app` |
| [web/src/config/globalConfig.js](web/src/config/globalConfig.js) | Centralizes public environment settings, API prefixes, storage keys, search defaults, synchronization intervals and PDF theme values. | `web/app` |
| [web/src/context/AuthContext.jsx](web/src/context/AuthContext.jsx) | Exposes traveler identity, sign-in, sign-up, profile updates and sign-out; clears query state and persisted caches when signing out. | `web/app` |
| [web/src/env.d.ts](web/src/env.d.ts) | References vite/client for browser asset imports and import.meta.env TypeScript declarations. | `web/config` |
| [web/src/main.tsx](web/src/main.tsx) | Mounts React with BrowserRouter and QueryClientProvider, initializes optional query persistence, and loads global styles. | `web/app` |
| [web/src/setupTests.js](web/src/setupTests.js) | Loads Testing Library DOM assertions and supplies TextEncoder/TextDecoder for the jsdom test environment. | `web/config` |
| [web/src/styles.css](web/src/styles.css) | Applies the app-wide reset, shared color and spacing variables, root geometry, and responsive typography helpers. | `web/app` |
| [web/src/styles/global.css](web/src/styles/global.css) | Defines shared theme variables, layout utilities, form/control defaults, animations and responsive global rules. | `web/app` |
| [web/tsconfig.json](web/tsconfig.json) | Extends the shared TypeScript settings; checks the entry, environment declarations and partner TypeScript source, excluding partner tests. | `web/config` |
| [web/vite.config.js](web/vite.config.js) | Serves web on port 5173, proxies API and Socket.IO traffic to Flask, handles API proxy outages, and strips console/debugger calls in production. | `web/config` |

### Shared components and layout (23 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/components/common/css/AnimatedBackground.css](web/src/components/common/css/AnimatedBackground.css) | Defines positioning and animation timing for the landing-page travel illustrations and brand elements. | `web/ui` |
| [web/src/components/common/css/CurrencyConversion.css](web/src/components/common/css/CurrencyConversion.css) | Styles the currency calculator, totals, rate status, swap/refresh controls and responsive layout. | `web/ui` |
| [web/src/components/common/css/DestinationAutocomplete.css](web/src/components/common/css/DestinationAutocomplete.css) | Styles the destination input, suggestion list, type indicators, loading state and responsive variants. | `web/ui` |
| [web/src/components/common/css/ErrorBoundary.css](web/src/components/common/css/ErrorBoundary.css) | Styles rendering-error recovery panels and query loading, error and cached-data states. | `web/ui` |
| [web/src/components/common/css/FeatureErrorBoundary.css](web/src/components/common/css/FeatureErrorBoundary.css) | Styles feature failure messages, retry controls and development diagnostic details. | `web/ui` |
| [web/src/components/common/css/Skeleton.css](web/src/components/common/css/Skeleton.css) | Defines shimmer animation and shared page, place-card and group-card skeleton geometry. | `web/ui` |
| [web/src/components/common/css/UserAvatar.css](web/src/components/common/css/UserAvatar.css) | Defines avatar sizes, image/initials presentation, optional names and responsive/theme variants. | `web/ui` |
| [web/src/components/common/index.js](web/src/components/common/index.js) | Re-exports shared common components and the workspace Toast from @tripraft/ui/Toast. | `web/ui` |
| [web/src/components/common/jsx/AnimatedBackground.jsx](web/src/components/common/jsx/AnimatedBackground.jsx) | Composes the landing-page travel animation from local PNG illustrations and configured branding. | `web/ui` |
| [web/src/components/common/jsx/CurrencyConversion.jsx](web/src/components/common/jsx/CurrencyConversion.jsx) | Shows original and converted summaries plus an independent currency calculator, including rate freshness, refresh and unavailable-rate states. | `web/ui` |
| [web/src/components/common/jsx/CurrencySelect.jsx](web/src/components/common/jsx/CurrencySelect.jsx) | Loads supported currencies with a local fallback, preserves an existing saved currency, and reports stale or unavailable listings. | `web/ui` |
| [web/src/components/common/jsx/DestinationAutocomplete.jsx](web/src/components/common/jsx/DestinationAutocomplete.jsx) | Debounces destination suggestions, supports keyboard selection and type filters, and returns selected destination metadata to the caller. | `web/ui` |
| [web/src/components/common/jsx/ErrorBoundary.jsx](web/src/components/common/jsx/ErrorBoundary.jsx) | Catches rendering errors with retry/home recovery and exports QueryErrorBoundary for query loading, errors and cached-data fallback. | `web/ui` |
| [web/src/components/common/jsx/FeatureErrorBoundary.jsx](web/src/components/common/jsx/FeatureErrorBoundary.jsx) | Contains a feature's rendering failure and offers retry with development-only diagnostic details. | `web/ui` |
| [web/src/components/common/jsx/GroupCardSkeleton.jsx](web/src/components/common/jsx/GroupCardSkeleton.jsx) | Renders placeholder group-card geometry while group data is loading. | `web/ui` |
| [web/src/components/common/jsx/PageSkeleton.jsx](web/src/components/common/jsx/PageSkeleton.jsx) | Renders the page-level loading skeleton used while lazy routes load. | `web/ui` |
| [web/src/components/common/jsx/PlaceCardSkeleton.jsx](web/src/components/common/jsx/PlaceCardSkeleton.jsx) | Renders placeholder image, title and rating blocks while a place card is loading. | `web/ui` |
| [web/src/components/common/jsx/UserAvatar.jsx](web/src/components/common/jsx/UserAvatar.jsx) | Shows a user's image or derived initials, with size variants and optional display name and click behavior. | `web/ui` |
| [web/src/components/layout/css/Footer.css](web/src/components/layout/css/Footer.css) | Styles footer columns, navigation links, branding and mobile layout. | `web/layout` |
| [web/src/components/layout/css/Header.css](web/src/components/layout/css/Header.css) | Styles the site logo, navigation, authentication controls and responsive mobile menu. | `web/layout` |
| [web/src/components/layout/index.js](web/src/components/layout/index.js) | Re-exports the shared Header and Footer layout components. | `web/layout` |
| [web/src/components/layout/jsx/Footer.jsx](web/src/components/layout/jsx/Footer.jsx) | Renders the configured site branding and product/company navigation links. | `web/layout` |
| [web/src/components/layout/jsx/Header.jsx](web/src/components/layout/jsx/Header.jsx) | Renders site navigation and account actions with a mobile menu, outside-click/Escape dismissal and body-scroll handling. | `web/layout` |

### Authentication (9 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/features/auth/css/Login.css](web/src/features/auth/css/Login.css) | Styles the boarding-pass login form, decorative panel, validation feedback and responsive layout. | `web/auth` |
| [web/src/features/auth/css/Signup.css](web/src/features/auth/css/Signup.css) | Styles the signup form, password-strength presentation, decorative panel and responsive layout. | `web/auth` |
| [web/src/features/auth/index.js](web/src/features/auth/index.js) | Re-exports traveler login, signup, auth switching, route protection and the optional inactivity tracker. | `web/auth` |
| [web/src/features/auth/jsx/AuthPage.jsx](web/src/features/auth/jsx/AuthPage.jsx) | Switches between the traveler Login and Signup forms within the /auth page. | `web/auth` |
| [web/src/features/auth/jsx/InactivityTracker.jsx](web/src/features/auth/jsx/InactivityTracker.jsx) | Implements an optional 15-minute idle logout with a one-minute warning; current app routes do not mount this component. | `web/auth` |
| [web/src/features/auth/jsx/Login.jsx](web/src/features/auth/jsx/Login.jsx) | Submits traveler login, handles loading and server errors, and preserves invitations or return destinations through authentication. | `web/auth` |
| [web/src/features/auth/jsx/ProtectedRoute.jsx](web/src/features/auth/jsx/ProtectedRoute.jsx) | Waits for traveler session initialization and displays sign-in/signup actions before rendering authenticated content. | `web/auth` |
| [web/src/features/auth/jsx/Signup.jsx](web/src/features/auth/jsx/Signup.jsx) | Validates traveler signup and password confirmation, submits account creation, and preserves invitations or requested return destinations. | `web/auth` |
| [web/src/features/auth/utils/authForms.js](web/src/features/auth/utils/authForms.js) | Provides auth validation, storage helpers that tolerate unavailable browser storage, and invitation/return-destination handling. | `web/auth` |

### Place discovery (15 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/features/discover/css/GroupedPlaceGrid.css](web/src/features/discover/css/GroupedPlaceGrid.css) | Styles location group headings and horizontally arranged place-card groups. | `web/discover` |
| [web/src/features/discover/css/PlaceCard.css](web/src/features/discover/css/PlaceCard.css) | Styles discovery cards, photos, loading placeholders, badges, hover states and metadata. | `web/discover` |
| [web/src/features/discover/css/PlaceDetailModal.css](web/src/features/discover/css/PlaceDetailModal.css) | Styles the place-detail overlay, photo hero, information sections and responsive dialog layout. | `web/discover` |
| [web/src/features/discover/css/PlaceGrid.css](web/src/features/discover/css/PlaceGrid.css) | Defines responsive column layout and gaps for the place-search grid. | `web/discover` |
| [web/src/features/discover/css/PlaceSearchPage.css](web/src/features/discover/css/PlaceSearchPage.css) | Styles the discovery page, results toolbar, filters and loading/error/empty-state presentation. | `web/discover` |
| [web/src/features/discover/css/SearchBar.css](web/src/features/discover/css/SearchBar.css) | Styles the search input, submit/clear actions, loading indicator and mobile controls. | `web/discover` |
| [web/src/features/discover/css/SearchSuggestions.css](web/src/features/discover/css/SearchSuggestions.css) | Styles autocomplete rows, location-type labels, selection states and the scrollable suggestion list. | `web/discover` |
| [web/src/features/discover/index.js](web/src/features/discover/index.js) | Re-exports discovery components and place-search service functions through one feature entry. | `web/discover` |
| [web/src/features/discover/jsx/GroupedPlaceGrid.jsx](web/src/features/discover/jsx/GroupedPlaceGrid.jsx) | Groups results by city or state and virtualizes larger collections of location groups. | `web/discover` |
| [web/src/features/discover/jsx/PlaceCard.jsx](web/src/features/discover/jsx/PlaceCard.jsx) | Renders a place's photo, location, rating and tags with lazy image loading, a local fallback and map links. | `web/discover` |
| [web/src/features/discover/jsx/PlaceDetailModal.jsx](web/src/features/discover/jsx/PlaceDetailModal.jsx) | Fetches full place details and renders photos, hours, costs, tips and sharing/map actions with modal dismissal behavior. | `web/discover` |
| [web/src/features/discover/jsx/PlaceGrid.jsx](web/src/features/discover/jsx/PlaceGrid.jsx) | Renders responsive place-card rows and virtualizes large result lists. | `web/discover` |
| [web/src/features/discover/jsx/PlaceSearchPage.jsx](web/src/features/discover/jsx/PlaceSearchPage.jsx) | Coordinates catalog search, autocomplete selections, statistics, filtering, sorting and detail dialogs with explicit loading/error/empty states. | `web/discover` |
| [web/src/features/discover/jsx/SearchBar.jsx](web/src/features/discover/jsx/SearchBar.jsx) | Debounces autocomplete requests, discards stale responses, supports cancellation and passes submitted queries or selected suggestions to the parent. | `web/discover` |
| [web/src/features/discover/jsx/SearchSuggestions.jsx](web/src/features/discover/jsx/SearchSuggestions.jsx) | Renders location suggestions with selected-row highlighting and suggestion-selection callbacks. | `web/discover` |

### Expenses and settlements (38 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/features/expenses/css/ExpenseAnalysisView.css](web/src/features/expenses/css/ExpenseAnalysisView.css) | Styles analysis filters, insight cards, category/daily charts, legends and responsive chart sizing. | `web/expenses` |
| [web/src/features/expenses/css/ExpenseAnalytics.css](web/src/features/expenses/css/ExpenseAnalytics.css) | Retains the older exp-analytics dashboard styles; ExpenseAnalytics.jsx currently re-exports the newer ExpenseAnalysisView. | `web/expenses` |
| [web/src/features/expenses/css/ExpenseDialog.css](web/src/features/expenses/css/ExpenseDialog.css) | Defines isolated dialog/backdrop geometry, responsive expense forms and a separate currency/amount column layout. | `web/expenses` |
| [web/src/features/expenses/css/ExpenseGroups.css](web/src/features/expenses/css/ExpenseGroups.css) | Styles the searchable expense-group dashboard, group detail header and new-group dialog using theme variables. | `web/expenses` |
| [web/src/features/expenses/css/ExpenseHistoryModal.css](web/src/features/expenses/css/ExpenseHistoryModal.css) | Styles the expense edit-history timeline, field changes, loading state and responsive dialog contents. | `web/expenses` |
| [web/src/features/expenses/css/ExpenseManager.css](web/src/features/expenses/css/ExpenseManager.css) | Defines the main expense interface styles for cards, transactions, members, forms, summaries and action states. | `web/expenses` |
| [web/src/features/expenses/css/ExpenseResponsive.css](web/src/features/expenses/css/ExpenseResponsive.css) | Applies shared responsive sizing, wrapping and overflow rules across expense screens and dialogs. | `web/expenses` |
| [web/src/features/expenses/css/SettlementHistoryModal.css](web/src/features/expenses/css/SettlementHistoryModal.css) | Styles settlement-history headings, summary figures, payment rows, status indicators and responsive layout. | `web/expenses` |
| [web/src/features/expenses/css/SettlementModal.css](web/src/features/expenses/css/SettlementModal.css) | Styles settlement-entry fields, overlay, action buttons, validation feedback and saving indicator. | `web/expenses` |
| [web/src/features/expenses/index.js](web/src/features/expenses/index.js) | Re-exports expense UI components and currency definitions for feature consumers. | `web/expenses` |
| [web/src/features/expenses/jsx/ExpenseAnalysisView.jsx](web/src/features/expenses/jsx/ExpenseAnalysisView.jsx) | Renders spending insights, category and daily charts, date-range filters and group-total versus saved-share analysis. | `web/expenses` |
| [web/src/features/expenses/jsx/ExpenseAnalytics.jsx](web/src/features/expenses/jsx/ExpenseAnalytics.jsx) | Re-exports ExpenseAnalysisView as a compatibility entry for existing expense imports. | `web/expenses` |
| [web/src/features/expenses/jsx/ExpenseDialog.jsx](web/src/features/expenses/jsx/ExpenseDialog.jsx) | Provides a portalled expense dialog with focus containment, Escape handling, scroll locking and focus restoration. | `web/expenses` |
| [web/src/features/expenses/jsx/ExpenseHistoryModal.jsx](web/src/features/expenses/jsx/ExpenseHistoryModal.jsx) | Fetches an expense's edit history and shows a timeline of field, payer and split changes with member names and currency formatting. | `web/expenses` |
| [web/src/features/expenses/jsx/ExpenseManager.jsx](web/src/features/expenses/jsx/ExpenseManager.jsx) | Coordinates personal/group expense data, group selection, transaction editing, invitations, settlements, history, PDF export and live refresh. | `web/expenses` |
| [web/src/features/expenses/jsx/ExpenseSummary.jsx](web/src/features/expenses/jsx/ExpenseSummary.jsx) | Calculates visible personal balance/income/spending or group expense totals while excluding deleted transactions. | `web/expenses` |
| [web/src/features/expenses/jsx/GroupBalances.jsx](web/src/features/expenses/jsx/GroupBalances.jsx) | Displays member balances, suggests payments, and opens settlement entry with currency conversion for display. | `web/expenses` |
| [web/src/features/expenses/jsx/GroupDashboard.jsx](web/src/features/expenses/jsx/GroupDashboard.jsx) | Shows searchable expense-group cards with member avatars, spending trends, personal share and outstanding position. | `web/expenses` |
| [web/src/features/expenses/jsx/GroupDetailHeader.jsx](web/src/features/expenses/jsx/GroupDetailHeader.jsx) | Renders the selected group's members, overview figures, navigation and permission-aware add/settle actions. | `web/expenses` |
| [web/src/features/expenses/jsx/GroupManager.jsx](web/src/features/expenses/jsx/GroupManager.jsx) | Manages expense-group metadata, membership and invitations with role-aware actions, confirmation and retryable API errors. | `web/expenses` |
| [web/src/features/expenses/jsx/GroupSummaryCards.jsx](web/src/features/expenses/jsx/GroupSummaryCards.jsx) | Shows outstanding balance, settlement totals and personal-share figures using the selected display currency. | `web/expenses` |
| [web/src/features/expenses/jsx/MemberSpending.jsx](web/src/features/expenses/jsx/MemberSpending.jsx) | Aggregates paid amounts per member, preserves former-member attribution, and renders spending breakdowns. | `web/expenses` |
| [web/src/features/expenses/jsx/ModeToggle.jsx](web/src/features/expenses/jsx/ModeToggle.jsx) | Renders the switch between personal and group expense modes. | `web/expenses` |
| [web/src/features/expenses/jsx/NewExpenseGroupModal.jsx](web/src/features/expenses/jsx/NewExpenseGroupModal.jsx) | Collects a new expense group's name and original currency, retaining the form when creation fails. | `web/expenses` |
| [web/src/features/expenses/jsx/PendingInvitations.jsx](web/src/features/expenses/jsx/PendingInvitations.jsx) | Displays pending expense invitations and coordinates acceptance/decline with immediate parent-state refresh. | `web/expenses` |
| [web/src/features/expenses/jsx/PersonalTabbedView.jsx](web/src/features/expenses/jsx/PersonalTabbedView.jsx) | Presents personal transaction history and analysis tabs with type filters and sorting. | `web/expenses` |
| [web/src/features/expenses/jsx/SettlementHistoryModal.jsx](web/src/features/expenses/jsx/SettlementHistoryModal.jsx) | Displays settlement records and payment status; confirms authorized deletions and keeps failures retryable. | `web/expenses` |
| [web/src/features/expenses/jsx/SettlementModal.jsx](web/src/features/expenses/jsx/SettlementModal.jsx) | Collects payer, recipient, amount and notes, validates against outstanding debt, and closes only after a successful save. | `web/expenses` |
| [web/src/features/expenses/jsx/SettlementView.jsx](web/src/features/expenses/jsx/SettlementView.jsx) | Presents suggested debt-clearing payments, settlement entry and settlement history using permission-aware controls. | `web/expenses` |
| [web/src/features/expenses/jsx/TabbedGroupView.jsx](web/src/features/expenses/jsx/TabbedGroupView.jsx) | Composes balances, settlements, member spending, transaction history and analysis into the group expense tabs. | `web/expenses` |
| [web/src/features/expenses/jsx/TransactionActivity.jsx](web/src/features/expenses/jsx/TransactionActivity.jsx) | Renders transaction activity rows with split/history actions and permission-aware edit, delete and restore controls. | `web/expenses` |
| [web/src/features/expenses/jsx/TransactionList.jsx](web/src/features/expenses/jsx/TransactionList.jsx) | Filters, sorts and paginates transactions, renders split receipts/history actions, and preserves deleted-row restoration where permitted. | `web/expenses` |
| [web/src/features/expenses/jsx/TransactionModal.jsx](web/src/features/expenses/jsx/TransactionModal.jsx) | Creates or edits personal/group expenses, validating amount, payer and participants while preserving an editing draft across live refetches. | `web/expenses` |
| [web/src/features/expenses/utils/currencies.js](web/src/features/expenses/utils/currencies.js) | Defines local currency metadata used as a fallback when the supported-currency API is unavailable. | `web/expenses` |
| [web/src/features/expenses/utils/expenseAnalysis.js](web/src/features/expenses/utils/expenseAnalysis.js) | Builds spending totals, saved-share breakdowns, category aggregates and complete calendar-day series while excluding income and deleted entries. | `web/expenses` |
| [web/src/features/expenses/utils/groupOverview.js](web/src/features/expenses/utils/groupOverview.js) | Derives group spending, personal share, paid amounts, settlements and net position using server summaries or available ledger data. | `web/expenses` |
| [web/src/features/expenses/utils/groupPermissions.js](web/src/features/expenses/utils/groupPermissions.js) | Resolves group, expense and settlement UI permissions from user identity, ownership, roles and server-provided action flags. | `web/expenses` |
| [web/src/features/expenses/utils/personalTransactions.js](web/src/features/expenses/utils/personalTransactions.js) | Identifies personal income, including legacy Salary/Income entries, so spending calculations exclude it. | `web/expenses` |

### Single-trip itineraries (11 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/features/itinerary/css/TripPlanner.css](web/src/features/itinerary/css/TripPlanner.css) | Styles the single-trip planning form, generated plan cards, timeline, map, suggested places, tips and packing checklist. | `web/itinerary` |
| [web/src/features/itinerary/index.js](web/src/features/itinerary/index.js) | Re-exports the single-trip planner's form, itinerary, stops, map, suggested places, tips, checklist and icon component. | `web/itinerary` |
| [web/src/features/itinerary/jsx/Checklist.jsx](web/src/features/itinerary/jsx/Checklist.jsx) | Renders a static travel-packing checklist with component-local checked state; it is separate from shared group checklists. | `web/itinerary` |
| [web/src/features/itinerary/jsx/Icon.jsx](web/src/features/itinerary/jsx/Icon.jsx) | Maps named travel-planner icons to inline SVG artwork. | `web/itinerary` |
| [web/src/features/itinerary/jsx/Itinerary.jsx](web/src/features/itinerary/jsx/Itinerary.jsx) | Renders day-by-day generated itinerary entries using ItineraryStop. | `web/itinerary` |
| [web/src/features/itinerary/jsx/ItineraryStop.jsx](web/src/features/itinerary/jsx/ItineraryStop.jsx) | Displays a generated stop's times, place metadata, photos and available details within the itinerary timeline. | `web/itinerary` |
| [web/src/features/itinerary/jsx/SuggestedPlaces.jsx](web/src/features/itinerary/jsx/SuggestedPlaces.jsx) | Shows additional recommendations, including early-morning and late-night choices, and invokes the supplied add-place callback. | `web/itinerary` |
| [web/src/features/itinerary/jsx/TripForm.jsx](web/src/features/itinerary/jsx/TripForm.jsx) | Collects city, trip length and pacing, supports city autocomplete, and submits the requested plan parameters. | `web/itinerary` |
| [web/src/features/itinerary/jsx/TripMap.jsx](web/src/features/itinerary/jsx/TripMap.jsx) | Renders generated plans on Leaflet/OpenStreetMap with numbered stops, day routes and safe text popups; supports switching between returned plans. | `web/itinerary` |
| [web/src/features/itinerary/jsx/TripPlanCard.jsx](web/src/features/itinerary/jsx/TripPlanCard.jsx) | Displays a generated trip plan and its day-by-day itinerary, with plan summary metadata. | `web/itinerary` |
| [web/src/features/itinerary/jsx/TripTips.jsx](web/src/features/itinerary/jsx/TripTips.jsx) | Displays static travel advice alongside generated single-trip itineraries. | `web/itinerary` |

### Partner portal and package drafts (10 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/features/partners/PackageWorkspace.tsx](web/src/features/partners/PackageWorkspace.tsx) | Lists and duplicates private supplier packages and provides a seven-step editor for route, itinerary, services, media, proposed rates and review submission. | `web/partners` |
| [web/src/features/partners/PartnerAgreement.tsx](web/src/features/partners/PartnerAgreement.tsx) | Loads the full agreement draft for approved agents and collects the explicit version/hash-bound signature before opening package tools. | `web/partners` |
| [web/src/features/partners/PartnerPortal.tsx](web/src/features/partners/PartnerPortal.tsx) | Owns partner-only routes, registration/login, business application drafts and submission, verification status, agreement gating and private package access. | `web/partners` |
| [web/src/features/partners/__tests__/PackageWorkspace.test.tsx](web/src/features/partners/__tests__/PackageWorkspace.test.tsx) | Verifies private draft creation, save-and-continue edits, exact proposed rates, conflict preservation and text edits saved before blur. | `web/partners` |
| [web/src/features/partners/__tests__/PartnerPortal.test.tsx](web/src/features/partners/__tests__/PartnerPortal.test.tsx) | Verifies partner routing, signup, application versions and verification gates, approval/signature prerequisites and agreement-load failures. | `web/partners` |
| [web/src/features/partners/__tests__/partnerApi.test.ts](web/src/features/partners/__tests__/partnerApi.test.ts) | Verifies isolated session probes, partner CSRF, shared refresh, no mutation replay and version/hash-bound agreement acknowledgment. | `web/partners` |
| [web/src/features/partners/__tests__/rateAmounts.test.ts](web/src/features/partners/__tests__/rateAmounts.test.ts) | Verifies exact rate conversion for supported exponents, invalid-input rejection and leading fractional zeros. | `web/partners` |
| [web/src/features/partners/partnerApi.ts](web/src/features/partners/partnerApi.ts) | Calls partner endpoints with isolated partner cookies and CSRF; shares read-probe refresh and never automatically replays failed mutations. | `web/partners` |
| [web/src/features/partners/partners.css](web/src/features/partners/partners.css) | Styles the partner landing page, onboarding/status forms, agreement reader and private package authoring workspace. | `web/partners` |
| [web/src/features/partners/rateAmounts.ts](web/src/features/partners/rateAmounts.ts) | Converts supplier rate inputs to exact decimal-string minor units and back, validating exponent and range without floating-point conversion. | `web/partners` |

### Chat polls and AI cards (4 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/features/polls/PollFeed.jsx](web/src/features/polls/PollFeed.jsx) | Renders poll choices, voting results and voter details, submits option indexes, and exposes deletion only when permitted by the supplied poll state. | `web/chat` |
| [web/src/features/scout/CrewCards.jsx](web/src/features/scout/CrewCards.jsx) | Renders Crew follow-up questions, expiring confirmation cards, added-place cards and success messages, with multi-step answer handling. | `web/scout` |
| [web/src/features/scout/ScoutConsentCard.jsx](web/src/features/scout/ScoutConsentCard.jsx) | Presents per-group Scout privacy choices and retries the original request only after the returned consent state allows it. | `web/scout` |
| [web/src/features/scout/aiBots.js](web/src/features/scout/aiBots.js) | Defines the shared Scout and Crew identities used in planner chat and member displays. | `web/scout` |

### Collaborative trips and demo (37 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/features/trips/constants/crewRoles.js](web/src/features/trips/constants/crewRoles.js) | Defines Treasurer, Navigator and Culture Scout responsibility labels and descriptions separately from group access roles. | `web/trips` |
| [web/src/features/trips/constants/mapConfig.js](web/src/features/trips/constants/mapConfig.js) | Defines public OpenFreeMap day/night styles, attribution, fallback viewport values and marker/day colors and icons. | `web/trips` |
| [web/src/features/trips/constants/tabConfig.js](web/src/features/trips/constants/tabConfig.js) | Defines the workspace tab keys and labels: Itinerary, Library, Logistics, Treasury, Pulse and Circle. | `web/trips` |
| [web/src/features/trips/css/CreateGroupModal.css](web/src/features/trips/css/CreateGroupModal.css) | Styles the group-creation form, catalog destination suggestions, fields, actions and responsive modal layout. | `web/trips` |
| [web/src/features/trips/css/GroupPlannerPage.css](web/src/features/trips/css/GroupPlannerPage.css) | Styles the planner hub, workspace tabs, map overlays, chat, dialogs, demo toolbar and responsive planner layouts. | `web/trips` |
| [web/src/features/trips/demo/DemoPlannerProvider.jsx](web/src/features/trips/demo/DemoPlannerProvider.jsx) | Provides an isolated demo identity and query client, role switching and reset controls around the planner workspace. | `web/trips` |
| [web/src/features/trips/demo/demoApi.js](web/src/features/trips/demo/demoApi.js) | Handles demo workspace requests in local state with role checks and reset support; unsupported actions fail instead of reaching live mutation endpoints. | `web/trips` |
| [web/src/features/trips/demo/demoData.js](web/src/features/trips/demo/demoData.js) | Builds illustrative trips, people, places, chat, polls, logistics and expense data with local photo paths for the planner demo. | `web/trips` |
| [web/src/features/trips/demo/demoMode.js](web/src/features/trips/demo/demoMode.js) | Detects opt-in planner demo routes, preserves the demo query in planner links, and defines demo storage keys. | `web/trips` |
| [web/src/features/trips/hooks/useFloatingPosition.js](web/src/features/trips/hooks/useFloatingPosition.js) | Manages saved floating-chat positions with pointer/keyboard movement, viewport clamping, resize recovery and drag-click suppression. | `web/trips` |
| [web/src/features/trips/hooks/useMapRenderer.js](web/src/features/trips/hooks/useMapRenderer.js) | Initializes Leaflet and its MapLibre adapter/worker and styles, detects WebGL2 support, and provides a fallback capability flag. | `web/trips` |
| [web/src/features/trips/index.js](web/src/features/trips/index.js) | Exports GroupPlannerPage as the collaborative-trip feature entry. | `web/trips` |
| [web/src/features/trips/jsx/CreateGroupModal.jsx](web/src/features/trips/jsx/CreateGroupModal.jsx) | Collects trip name, dates, budget currency and optional invitees, requiring a selected catalog destination and validating invitation addresses. | `web/trips` |
| [web/src/features/trips/jsx/GroupPlannerManager.jsx](web/src/features/trips/jsx/GroupPlannerManager.jsx) | Orchestrates planner routing, group selection, tabs, shared query/socket state, map days, movable chat, invitations and group creation. | `web/trips` |
| [web/src/features/trips/jsx/GroupPlannerPage.jsx](web/src/features/trips/jsx/GroupPlannerPage.jsx) | Wraps the planner in shared site navigation, measures header height for layout, and enables DemoPlannerProvider only for demo=1. | `web/trips` |
| [web/src/features/trips/jsx/InvitationAcceptPage.jsx](web/src/features/trips/jsx/InvitationAcceptPage.jsx) | Restores auth before validating and accepting a trip invitation, shares StrictMode acceptance work and opens the exact joined group. | `web/trips` |
| [web/src/features/trips/jsx/chat/ChatPanel.jsx](web/src/features/trips/jsx/chat/ChatPanel.jsx) | Renders paginated/live messages, edits, mentions, Scout/Crew cards and polls while coordinating optimistic sends and group-specific composer state. | `web/trips` |
| [web/src/features/trips/jsx/chat/MessageMenu.jsx](web/src/features/trips/jsx/chat/MessageMenu.jsx) | Provides an inline message action menu for permitted edit/delete operations, with outside-click and Escape dismissal. | `web/trips` |
| [web/src/features/trips/jsx/map/MapPanel.jsx](web/src/features/trips/jsx/map/MapPanel.jsx) | Renders planner stops and day routes on Leaflet/OpenFreeMap, focuses the destination viewport, filters days and handles theme/coordinate fallbacks. | `web/trips` |
| [web/src/features/trips/jsx/shared/AddStopModal.jsx](web/src/features/trips/jsx/shared/AddStopModal.jsx) | Adds a stop through the place APIs, optionally schedules it, and refreshes planner queries while reporting partial-save failures. | `web/trips` |
| [web/src/features/trips/jsx/shared/GroupSelector.jsx](web/src/features/trips/jsx/shared/GroupSelector.jsx) | Shows searchable trip cards, locally pinned trips and invitation joining, with separate member actions and typed-name deletion confirmation. | `web/trips` |
| [web/src/features/trips/jsx/shared/PlannerExpenseModal.jsx](web/src/features/trips/jsx/shared/PlannerExpenseModal.jsx) | Collects a planner expense and participant/itemized split details for the linked ledger, retaining validation and saving errors. | `web/trips` |
| [web/src/features/trips/jsx/shared/PlannerHeader.jsx](web/src/features/trips/jsx/shared/PlannerHeader.jsx) | Renders the current group's title, group-count return action and planner context/actions without a separate dropdown group picker. | `web/trips` |
| [web/src/features/trips/jsx/shared/RouteOptimizer.jsx](web/src/features/trips/jsx/shared/RouteOptimizer.jsx) | Previews a reordered itinerary using local route helpers and saves the selected day's updated stop schedule through the planner API. | `web/trips` |
| [web/src/features/trips/jsx/shared/TripDateSelect.jsx](web/src/features/trips/jsx/shared/TripDateSelect.jsx) | Offers the trip's calendar dates plus an unscheduled option for assigning a stop to a day. | `web/trips` |
| [web/src/features/trips/jsx/tabs/CircleTab.jsx](web/src/features/trips/jsx/tabs/CircleTab.jsx) | Manages trip members, access roles, independent crew responsibilities, group settings, invitations and Scout consent controls. | `web/trips` |
| [web/src/features/trips/jsx/tabs/ItineraryTab.jsx](web/src/features/trips/jsx/tabs/ItineraryTab.jsx) | Displays the daily schedule, including empty trip dates, and supports stop edits, moves and removal with query refresh. | `web/trips` |
| [web/src/features/trips/jsx/tabs/LibraryTab.jsx](web/src/features/trips/jsx/tabs/LibraryTab.jsx) | Browses destination-scoped catalog places with state/city filters, pagination and details, and adds selected places to the trip. | `web/trips` |
| [web/src/features/trips/jsx/tabs/LogisticsTab.jsx](web/src/features/trips/jsx/tabs/LogisticsTab.jsx) | Manages vault uploads/downloads and shared pre-trip/packing checklists with assignments, permissions and optimistic toggle rollback. | `web/trips` |
| [web/src/features/trips/jsx/tabs/PulseTab.jsx](web/src/features/trips/jsx/tabs/PulseTab.jsx) | Shows a filterable activity feed alongside group/poll/member context and links relevant activity to workspace tabs. | `web/trips` |
| [web/src/features/trips/jsx/tabs/TreasuryTab.jsx](web/src/features/trips/jsx/tabs/TreasuryTab.jsx) | Connects the trip to an expense group and displays budgets, converted summaries, balances, suggested settlements and recent expenses. | `web/trips` |
| [web/src/features/trips/utils/formatters.js](web/src/features/trips/utils/formatters.js) | Formats planner dates, times, relative activity, initials, currency and file sizes with safe fallbacks for missing or invalid values. | `web/trips` |
| [web/src/features/trips/utils/groupPlannerUtils.js](web/src/features/trips/utils/groupPlannerUtils.js) | Normalizes API envelopes/arrays, classifies map markers, calculates trip day numbers and escapes popup text. | `web/trips` |
| [web/src/features/trips/utils/mapViewport.js](web/src/features/trips/utils/mapViewport.js) | Fits the map to a catalog destination or valid coordinates and wraps longitudes near the viewport for date-line destinations. | `web/trips` |
| [web/src/features/trips/utils/openFreeMapStyle.js](web/src/features/trips/utils/openFreeMapStyle.js) | Adjusts selected provider shield-label expressions to tolerate missing ref_length values while preserving the rest of the map style. | `web/trips` |
| [web/src/features/trips/utils/plannerMoney.js](web/src/features/trips/utils/plannerMoney.js) | Builds itemized participant splits in whole cents and suggests payments that clear debtor/creditor balances. | `web/trips` |
| [web/src/features/trips/utils/plannerSchedule.js](web/src/features/trips/utils/plannerSchedule.js) | Enumerates trip calendar dates, calculates geographic route distances, reorders stops and preserves available schedule time slots. | `web/trips` |

### React hooks (12 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/hooks/useAiConsentQuery.js](web/src/hooks/useAiConsentQuery.js) | Defines query keys and React Query reads/mutations for granting, declining or revoking per-group Scout consent. | `web/hooks` |
| [web/src/hooks/useChatQuery.js](web/src/hooks/useChatQuery.js) | Manages cursor-paginated messages, optimistic sends, edits/deletes, read markers and unread counts without losing concurrent messages. | `web/hooks` |
| [web/src/hooks/useChatSocket.js](web/src/hooks/useChatSocket.js) | Maintains cookie-authenticated live chat, typing/presence/read events, session renewal and query recovery after reconnect or revoked access. | `web/hooks` |
| [web/src/hooks/useExchangeRate.js](web/src/hooks/useExchangeRate.js) | Fetches and validates the selected currency pair, ignores stale responses, refreshes on focus/timer and exposes loading/error state. | `web/hooks` |
| [web/src/hooks/useExpenseLiveUpdates.js](web/src/hooks/useExpenseLiveUpdates.js) | Uses private Socket.IO change notifications to invalidate expense queries, clears revoked data, and catches up through polling/reconnect/visibility changes. | `web/hooks` |
| [web/src/hooks/useExpenseQuery.js](web/src/hooks/useExpenseQuery.js) | Centralizes expense query keys, bootstrap/ledger/history reads, optimistic financial mutations with rollback, invitations and group/personal manager hooks. | `web/hooks` |
| [web/src/hooks/useGroupPlannerQuery.js](web/src/hooks/useGroupPlannerQuery.js) | Defines planner query keys and hooks for groups, destination viewports, places, polls, members, expenses, checklists, vault files and activities. | `web/hooks` |
| [web/src/hooks/useGroupSocket.js](web/src/hooks/useGroupSocket.js) | Subscribes to authenticated group collaboration/presence events and forwards handlers for places, polls, checklists, itineraries and membership. | `web/hooks` |
| [web/src/hooks/useMoneyDisplay.js](web/src/hooks/useMoneyDisplay.js) | Formats amounts in a chosen display currency using the exchange-rate hook while leaving stored amounts and calculation units unchanged. | `web/hooks` |
| [web/src/hooks/usePersonalCurrency.js](web/src/hooks/usePersonalCurrency.js) | Caches the account's chosen dashboard currency across tabs and saves explicit changes. | `web/hooks` |
| [web/src/hooks/usePersonalDashboard.js](web/src/hooks/usePersonalDashboard.js) | Converts personal transactions into one dashboard currency without changing saved records. | `web/hooks` |
| [web/src/hooks/useNotesAutoSave.js](web/src/hooks/useNotesAutoSave.js) | Saves and clears a group-scoped notes draft in localStorage; it does not send notes to the server. | `web/hooks` |
| [web/src/hooks/usePlaceSearchQuery.js](web/src/hooks/usePlaceSearchQuery.js) | Provides cached React Query reads for place search, details and catalog statistics. | `web/hooks` |
| [web/src/hooks/useTripPlannerQuery.js](web/src/hooks/useTripPlannerQuery.js) | Provides city-search/list and pacing queries plus the generated-trip mutation through tripPlannerService. | `web/hooks` |

### Query cache and persistence (3 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/lib/chatCache.js](web/src/lib/chatCache.js) | Updates, removes and deduplicates messages across flat or enveloped cached pages, reconciling optimistic results and socket echoes. | `web/lib` |
| [web/src/lib/indexedDBPersister.js](web/src/lib/indexedDBPersister.js) | Implements optional React Query snapshot storage, restoration, deletion and statistics in IndexedDB, tolerating unavailable browser storage. | `web/lib` |
| [web/src/lib/queryClientPersist.js](web/src/lib/queryClientPersist.js) | Configures query freshness/retries and optional IndexedDB/localStorage persistence, excludes private queries and all mutations, and clears persisted state at logout. | `web/lib` |

### Pages and page styles (20 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/pages/About.jsx](web/src/pages/About.jsx) | Renders static product, mission and team information with shared navigation and scroll-triggered animations. | `web/pages` |
| [web/src/pages/Analytics.jsx](web/src/pages/Analytics.jsx) | Checks administrator identity and shows an access-denied or analytics-unavailable message; no analytics dashboard endpoint is called. | `web/pages` |
| [web/src/pages/Contact.jsx](web/src/pages/Contact.jsx) | Shows support email only when a valid VITE_SUPPORT_EMAIL is configured and renders static account, invitations and beta-access help. | `web/pages` |
| [web/src/pages/ExpenseAnalytics.jsx](web/src/pages/ExpenseAnalytics.jsx) | Displays the protected legacy analytics route's access-denied or unavailable state; no expense analytics dashboard is implemented here. | `web/pages` |
| [web/src/pages/ExpensePage.jsx](web/src/pages/ExpensePage.jsx) | Wraps ExpenseManager in shared site navigation, authenticated account actions and the footer. | `web/pages` |
| [web/src/pages/HomePage.jsx](web/src/pages/HomePage.jsx) | Renders the marketing landing page, animated travel artwork, tool links and destination-to-planner navigation. | `web/pages` |
| [web/src/pages/InvitationAccept.jsx](web/src/pages/InvitationAccept.jsx) | Handles expense invitation details, sign-in continuation, account mismatch and single acceptance, then navigates to the joined expense group. | `web/pages` |
| [web/src/pages/Pricing.jsx](web/src/pages/Pricing.jsx) | Explains the current free beta and future plans and links to signup or the planner; no payment checkout is offered. | `web/pages` |
| [web/src/pages/SmartInvitationHandler.jsx](web/src/pages/SmartInvitationHandler.jsx) | Resolves expense versus trip invitation routes from explicit path/query hints or API probes, then renders the matching acceptance flow. | `web/pages` |
| [web/src/pages/TripPlanner.jsx](web/src/pages/TripPlanner.jsx) | Calls tripPlannerService and adapts returned plans/place metadata for the single-trip map, itinerary cards, tips and packing checklist. | `web/pages` |
| [web/src/pages/VerifyEmail.jsx](web/src/pages/VerifyEmail.jsx) | Verifies a public email token with shared in-flight work under StrictMode, reports missing/expired/error states and offers explicit resend when signed in. | `web/pages` |
| [web/src/pages/index.js](web/src/pages/index.js) | Re-exports the main page components for consumers that use the pages entry module. | `web/pages` |
| [web/src/pages/styles/About.css](web/src/pages/styles/About.css) | Styles the about page's product, mission, team and call-to-action sections and scroll animations. | `web/pages` |
| [web/src/pages/styles/Analytics.css](web/src/pages/styles/Analytics.css) | Styles the analytics route, including its current loading/error/unavailable state and retained dashboard selectors. | `web/pages` |
| [web/src/pages/styles/Contact.css](web/src/pages/styles/Contact.css) | Styles the support/contact and FAQ sections, with retained selectors for earlier contact-form layouts. | `web/pages` |
| [web/src/pages/styles/ExpenseAnalytics.css](web/src/pages/styles/ExpenseAnalytics.css) | Styles the legacy expense-analytics page's loading/error layout and retained dashboard-frame selectors. | `web/pages` |
| [web/src/pages/styles/ExpensePage.css](web/src/pages/styles/ExpensePage.css) | Sets the expense page's content width, background and responsive container spacing. | `web/pages` |
| [web/src/pages/styles/HomePage.css](web/src/pages/styles/HomePage.css) | Styles the landing hero, destination form, feature sections, expense promotion and responsive layouts. | `web/pages` |
| [web/src/pages/styles/Pricing.css](web/src/pages/styles/Pricing.css) | Styles the pricing page and cards, including retained selectors for billing controls that the current beta page does not render. | `web/pages` |
| [web/src/pages/styles/VerifyEmail.css](web/src/pages/styles/VerifyEmail.css) | Styles the centered email-verification card, outcome icons, recovery links and keyboard-focus states. | `web/pages` |

### API services (9 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/services/aiConsentApi.js](web/src/services/aiConsentApi.js) | Calls the planner's consent-status, grant/decline and revoke endpoints through the shared API client. | `web/services` |
| [web/src/services/chatApi.js](web/src/services/chatApi.js) | Wraps group message pagination, send/edit/delete, read-marker and unread-count endpoints. | `web/services` |
| [web/src/services/currencyApi.js](web/src/services/currencyApi.js) | Fetches supported currencies with short-lived listing reuse and requests current or explicitly refreshed exchange rates. | `web/services` |
| [web/src/services/expenseApi.js](web/src/services/expenseApi.js) | Wraps expense profiles, groups, members, invitations, expenses, settlements, balances, analytics and bootstrap endpoints using the shared API client. | `web/services` |
| [web/src/services/groupPlannerApi.js](web/src/services/groupPlannerApi.js) | Wraps planner groups, paginated collections, invitations, places, polls, schedules, checklist/vault data, catalog reads and linked-expense operations. | `web/services` |
| [web/src/services/pdfExportService.js](web/src/services/pdfExportService.js) | Generates branded personal/group expense PDF reports with summary, transaction, balance and settlement tables using jsPDF and AutoTable. | `web/services` |
| [web/src/services/placeSearchService.js](web/src/services/placeSearchService.js) | Wraps place search, cancellable autocomplete, place-detail and catalog-statistics API calls. | `web/services` |
| [web/src/services/sqlAuthService.js](web/src/services/sqlAuthService.js) | Restores traveler sessions from cookies, handles signup/login/verification/logout, shares refresh work and exposes auth-state listeners without storing tokens locally. | `web/services` |
| [web/src/services/tripPlannerService.js](web/src/services/tripPlannerService.js) | Calls itinerary generation, city search/list and pacing endpoints, unwraps API envelopes and adapts generated place/stop data. | `web/services` |

### Shared utilities (7 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/utils/apiClient.js](web/src/utils/apiClient.js) | Sends cookie-authenticated requests with CSRF, timeout/cancellation and structured errors; retries GET failures, refreshes a rejected session once, and routes isolated demo requests. | `web/utils` |
| [web/src/utils/apiLogger.js](web/src/utils/apiLogger.js) | Exposes a silent logger compatibility interface so API callers can retain logging hooks without emitting request data. | `web/utils` |
| [web/src/utils/coordinates.js](web/src/utils/coordinates.js) | Validates finite latitude/longitude bounds, accepting zero coordinates while rejecting missing or empty values. | `web/utils` |
| [web/src/utils/errorHandler.js](web/src/utils/errorHandler.js) | Converts structured API errors into display messages, field errors and authentication-redirect hints with status-code fallbacks. | `web/utils` |
| [web/src/utils/money.js](web/src/utils/money.js) | Formats currency, allocates equal splits in whole cents, preserves unchanged saved split fields and caps payments by both debt and credit. | `web/utils` |
| [web/src/utils/placeRating.js](web/src/utils/placeRating.js) | Derives a bounded 0-5 display rating from explicit rating or rank_score, returning zero for invalid numeric values. | `web/utils` |
| [web/src/utils/timezoneUtils.js](web/src/utils/timezoneUtils.js) | Provides local date/time formatting, date-input conversion, relative dates, browser timezone/geolocation and coordinate-to-city lookup helpers. | `web/utils` |

### Web regression tests and harnesses (41 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/src/__tests__/apiClient.test.js](web/src/__tests__/apiClient.test.js) | Verifies cookies/CSRF, empty and non-JSON responses, one session refresh, GET retries, no ambiguous mutation replay, blobs, cancellation and validation errors. | `web/tests` |
| [web/src/__tests__/authPages.test.jsx](web/src/__tests__/authPages.test.jsx) | Verifies click/Enter/autofill submissions, validation, duplicate prevention, session initialization and invitation/return-state preservation, including disabled storage. | `web/tests` |
| [web/src/__tests__/authService.test.js](web/src/__tests__/authService.test.js) | Verifies cookie restoration/refresh, verification and resend, session rejection versus transient errors, CSRF/logout and token-free local storage. | `web/tests` |
| [web/src/__tests__/authSession.test.jsx](web/src/__tests__/authSession.test.jsx) | Verifies returning-device restoration, identity-before-redirect, retryable login errors, logout cache cleanup and the absence of a mounted idle logout. | `web/tests` |
| [web/src/__tests__/cacheAndFreshness.test.jsx](web/src/__tests__/cacheAndFreshness.test.jsx) | Verifies private-query/mutation persistence exclusions, disabled mutation retries, old-snapshot invalidation, logout cleanup and fresh bootstrap balances. | `web/tests` |
| [web/src/__tests__/chatPanelState.test.jsx](web/src/__tests__/chatPanelState.test.jsx) | Verifies inline message actions, group-switch composer reset, loading state, Crew answer failures and card-specific expense deletion. | `web/tests` |
| [web/src/__tests__/chatQuery.test.jsx](web/src/__tests__/chatQuery.test.jsx) | Verifies optimistic rollback preserves incoming messages, echo deduplication across pages, and results update the original group after a switch. | `web/tests` |
| [web/src/__tests__/chatSocket.test.jsx](web/src/__tests__/chatSocket.test.jsx) | Verifies cookie-authenticated sockets, message/edit reconciliation, read throttling, group changes, reconnect/refresh recovery and revoked-access cleanup. | `web/tests` |
| [web/src/__tests__/consentAndSettlement.test.jsx](web/src/__tests__/consentAndSettlement.test.jsx) | Verifies Scout privacy overrides, visible settlement save failures and client-side over-settlement rejection. | `web/tests` |
| [web/src/__tests__/currencyConversion.test.jsx](web/src/__tests__/currencyConversion.test.jsx) | Verifies original versus converted totals, currency-pair races, stale/unavailable rates, fixed saved currencies and independent calculator pairs. | `web/tests` |
| [web/src/__tests__/expenseAnalysisAndDialogs.test.jsx](web/src/__tests__/expenseAnalysisAndDialogs.test.jsx) | Verifies stored-share analysis, calendar/deleted-row handling, history data, dialog focus/scroll behavior, creation retries and former-member attribution. | `web/tests` |
| [web/src/__tests__/expenseFollowupFixes.test.jsx](web/src/__tests__/expenseFollowupFixes.test.jsx) | Verifies personal history and income classification, deleted-row restore permissions, currency/amount layout, live edit-draft retention and split receipts. | `web/tests` |
| [web/src/__tests__/expenseGroupCreation.test.jsx](web/src/__tests__/expenseGroupCreation.test.jsx) | Verifies API-compatible group creation fields and preserving the entered name after validation failure. | `web/tests` |
| [web/src/__tests__/expenseGroupNavigation.test.jsx](web/src/__tests__/expenseGroupNavigation.test.jsx) | Verifies exact group URLs, browser back, selected-group restoration, dashboard/empty states and navigation after group creation or invitation acceptance. | `web/tests` |
| [web/src/__tests__/expenseGroupOverview.test.jsx](web/src/__tests__/expenseGroupOverview.test.jsx) | Verifies paid/share/net distinctions, full-ledger summaries, custom splits, deleted expenses and searchable dashboard/error states. | `web/tests` |
| [web/src/__tests__/expenseInvitationDelivery.test.jsx](web/src/__tests__/expenseInvitationDelivery.test.jsx) | Verifies expired-link restrictions, copying without resending, clipboard fallback, invitation permissions and cancellation cleanup. | `web/tests` |
| [web/src/__tests__/expenseInvitationFlow.test.jsx](web/src/__tests__/expenseInvitationFlow.test.jsx) | Verifies copied-link sign-in continuation, one acceptance, disabled-storage recovery, wrong-account handling and already-joined navigation. | `web/tests` |
| [web/src/__tests__/expenseLiveUpdates.test.jsx](web/src/__tests__/expenseLiveUpdates.test.jsx) | Verifies private socket invalidation, burst coalescing, revoked-data cleanup, reconnect/polling recovery, visibility handling and session renewal. | `web/tests` |
| [web/src/__tests__/floatingChat.test.jsx](web/src/__tests__/floatingChat.test.jsx) | Verifies pointer dragging, viewport bounds, click suppression, keyboard movement, saved positions, resize/reset and composer isolation. | `web/tests` |
| [web/src/__tests__/groupExpensePermissions.test.jsx](web/src/__tests__/groupExpensePermissions.test.jsx) | Verifies server edit/delete flags, settlement permissions, one-cent debts, role-based management, confirmed archive and revoked-access controls. | `web/tests` |
| [web/src/__tests__/groupLedgerApi.test.js](web/src/__tests__/groupLedgerApi.test.js) | Verifies complete independent ledger pagination and failure of the full read when a later page denies access. | `web/tests` |
| [web/src/__tests__/groupLedgerLoading.test.jsx](web/src/__tests__/groupLedgerLoading.test.jsx) | Verifies all personal pages include deleted rows, revoked membership removes cached controls/data and group switches do not leak earlier ledgers. | `web/tests` |
| [web/src/__tests__/groupPlannerApi.test.js](web/src/__tests__/groupPlannerApi.test.js) | Verifies full planner collection pagination, later-page errors and supported catalog-place payloads including zero coordinates. | `web/tests` |
| [web/src/__tests__/groupPlannerCatalog.test.jsx](web/src/__tests__/groupPlannerCatalog.test.jsx) | Verifies required catalog selections, optional/deduplicated invites, destination-scoped filters and adding places without invented coordinates. | `web/tests` |
| [web/src/__tests__/groupPlannerDemo.test.js](web/src/__tests__/groupPlannerDemo.test.js) | Verifies local demo request isolation, permitted public reference reads, role checks, reset/settings behavior, polls and independent crew roles. | `web/tests` |
| [web/src/__tests__/groupPlannerNewUI.test.jsx](web/src/__tests__/groupPlannerNewUI.test.jsx) | Verifies trip-card actions, typed-name deletion, date choices, search/pins, safe invitation links and retryable or partial stop-creation failures. | `web/tests` |
| [web/src/__tests__/groupPlannerTabs.test.jsx](web/src/__tests__/groupPlannerTabs.test.jsx) | Verifies exact itemized splits and small settlements, empty trip dates, preserved time slots and independent access/responsibility permissions. | `web/tests` |
| [web/src/__tests__/groupPlannerWorkspace.test.jsx](web/src/__tests__/groupPlannerWorkspace.test.jsx) | Verifies calendar-based itinerary day filtering and optimistic checklist toggling with rollback after failure. | `web/tests` |
| [web/src/__tests__/money.test.js](web/src/__tests__/money.test.js) | Verifies exact cent allocation, UUID participants, invalid amounts, preserved custom splits/payer edits, settlement caps and currency formatting. | `web/tests` |
| [web/src/__tests__/openFreeMap.test.js](web/src/__tests__/openFreeMap.test.js) | Verifies safe provider style expressions, key-free OpenFreeMap attribution, zero/missing coordinates and date-line marker wrapping. | `web/tests` |
| [web/src/__tests__/ownerAndInactivity.test.jsx](web/src/__tests__/ownerAndInactivity.test.jsx) | Verifies UUID owner controls and actual personal share, and tests the optional idle tracker's warning/activity reset in isolation. | `web/tests` |
| [web/src/__tests__/p3Behavior.test.jsx](web/src/__tests__/p3Behavior.test.jsx) | Verifies safe date/file formatting, Crew question transitions, long-trip day lists and map viewport, theme and calendar-day behavior. | `web/tests` |
| [web/src/__tests__/personalCurrency.test.jsx](web/src/__tests__/personalCurrency.test.jsx) | Verifies account-backed currency persistence, save failures and user isolation. | `web/tests` |
| [web/src/__tests__/personalDashboard.test.jsx](web/src/__tests__/personalDashboard.test.jsx) | Verifies mixed-currency personal totals, original records, failed rates and stale response isolation. | `web/tests` |
| [web/src/__tests__/plannerHeader.test.jsx](web/src/__tests__/plannerHeader.test.jsx) | Verifies group count and plain current title, with a return-to-cards group-selection action. | `web/tests` |
| [web/src/__tests__/pollFeed.test.jsx](web/src/__tests__/pollFeed.test.jsx) | Verifies unique voters, option-index vote payloads, creator-only deletion and member-name resolution from UUIDs. | `web/tests` |
| [web/src/__tests__/routes.test.jsx](web/src/__tests__/routes.test.jsx) | Verifies invitation route dispatch and administrator access/unavailable analytics behavior without absent-endpoint calls. | `web/tests` |
| [web/src/__tests__/searchCancellation.test.jsx](web/src/__tests__/searchCancellation.test.jsx) | Verifies stale autocomplete responses cannot replace a newer query and clearing search cancels its pending debounce. | `web/tests` |
| [web/src/__tests__/serviceContracts.test.js](web/src/__tests__/serviceContracts.test.js) | Verifies service timeouts and response-envelope adaptation, preserved place metadata, real search results, rating normalization and coordinate validity. | `web/tests` |
| [web/src/__tests__/tripInvitationFlow.test.jsx](web/src/__tests__/tripInvitationFlow.test.jsx) | Verifies auth restoration, preserved trip invitation type, single StrictMode acceptance, wrong-account/expired links and already-accepted navigation. | `web/tests` |
| [web/src/__tests__/verifyEmail.test.jsx](web/src/__tests__/verifyEmail.test.jsx) | Verifies public verification routing, one request under StrictMode, loading/missing/expired/error states, explicit resend and preserved invitations. | `web/tests` |
| [web/tests/styleMock.cjs](web/tests/styleMock.cjs) | Exports an empty object for CSS and SVG imports mapped by the Jest configuration. | `web/config` |
| [web/tests/viteEnvTransform.cjs](web/tests/viteEnvTransform.cjs) | Rewrites import.meta.env expressions to process.env so Jest can execute Vite-oriented source. | `web/config` |

### Public assets and image notes (25 files)

| File | What it does | Suggested scope |
|---|---|---|
| [web/public/favicon.svg](web/public/favicon.svg) | Defines the SVG browser-tab icon referenced by web/index.html. | `web/assets` |
| [web/public/images/ANIMATION_IMAGES.md](web/public/images/ANIMATION_IMAGES.md) | Maps the current landing-page PNG filenames to CSS animation slots and explains timing, artwork replacement and source evidence. | `web/assets` |
| [web/public/images/README.md](web/public/images/README.md) | Explains the actual public-image structure, browser URL usage, bundled versus uploaded assets, optimization and related source guides. | `web/assets` |
| [web/public/images/confuse_man.png](web/public/images/confuse_man.png) | Supplies the confused-traveler illustration rendered by AnimatedBackground.jsx. | `web/assets` |
| [web/public/images/happy.png](web/public/images/happy.png) | Supplies the celebration illustration rendered by AnimatedBackground.jsx. | `web/assets` |
| [web/public/images/man.png](web/public/images/man.png) | Supplies a traveler character illustration rendered by AnimatedBackground.jsx. | `web/assets` |
| [web/public/images/map.png](web/public/images/map.png) | Supplies the map illustration rendered by AnimatedBackground.jsx. | `web/assets` |
| [web/public/images/passport.png](web/public/images/passport.png) | Supplies the travel-document illustration rendered by AnimatedBackground.jsx. | `web/assets` |
| [web/public/images/plane.png](web/public/images/plane.png) | Supplies the airplane illustration rendered by AnimatedBackground.jsx. | `web/assets` |
| [web/public/images/planner-demo/README.md](web/public/images/planner-demo/README.md) | Records source photo IDs for local demo images and explains that sample people, trips and booking documents are illustrative. | `web/assets` |
| [web/public/images/planner-demo/alex.jpg](web/public/images/planner-demo/alex.jpg) | Supplies Alex's local sample portrait through the demoData.js photo mapping. | `web/assets` |
| [web/public/images/planner-demo/alps.jpg](web/public/images/planner-demo/alps.jpg) | Supplies a local mountain-trip cover for the demo data and demo request responses. | `web/assets` |
| [web/public/images/planner-demo/elena.jpg](web/public/images/planner-demo/elena.jpg) | Supplies Elena's local sample portrait through the demoData.js photo mapping. | `web/assets` |
| [web/public/images/planner-demo/kyoto-lanterns.jpg](web/public/images/planner-demo/kyoto-lanterns.jpg) | Supplies a local sample destination photo through the demoData.js photo mapping. | `web/assets` |
| [web/public/images/planner-demo/kyoto-market.jpg](web/public/images/planner-demo/kyoto-market.jpg) | Supplies a local sample destination photo through the demoData.js photo mapping. | `web/assets` |
| [web/public/images/planner-demo/kyoto-pavilion.jpg](web/public/images/planner-demo/kyoto-pavilion.jpg) | Supplies a local sample destination photo through the demoData.js photo mapping. | `web/assets` |
| [web/public/images/planner-demo/kyoto-river.jpg](web/public/images/planner-demo/kyoto-river.jpg) | Supplies a local sample destination photo through the demoData.js photo mapping. | `web/assets` |
| [web/public/images/planner-demo/kyoto-temple.jpg](web/public/images/planner-demo/kyoto-temple.jpg) | Supplies a local sample destination/trip-cover photo through the demoData.js photo mapping. | `web/assets` |
| [web/public/images/planner-demo/kyoto-torii.jpg](web/public/images/planner-demo/kyoto-torii.jpg) | Supplies a local sample destination photo through the demoData.js photo mapping. | `web/assets` |
| [web/public/images/planner-demo/lisbon.jpg](web/public/images/planner-demo/lisbon.jpg) | Supplies a local Lisbon trip/destination cover for the demo data and demo request responses. | `web/assets` |
| [web/public/images/planner-demo/marcus.jpg](web/public/images/planner-demo/marcus.jpg) | Supplies Marcus's local sample portrait through the demoData.js photo mapping. | `web/assets` |
| [web/public/images/planner-demo/sarah.jpg](web/public/images/planner-demo/sarah.jpg) | Supplies Sarah's local sample portrait through the demoData.js photo mapping. | `web/assets` |
| [web/public/images/search.png](web/public/images/search.png) | Supplies the search illustration rendered by AnimatedBackground.jsx. | `web/assets` |
| [web/public/images/travel_man.png](web/public/images/travel_man.png) | Supplies another traveler character illustration rendered by AnimatedBackground.jsx. | `web/assets` |
| [web/public/images/trip_plan.png](web/public/images/trip_plan.png) | Supplies the trip-planning illustration rendered by AnimatedBackground.jsx. | `web/assets` |

## Verification commands

Run from the repository root with dependencies installed:

```powershell
pnpm --filter @tripraft/admin lint
pnpm --filter @tripraft/admin typecheck
pnpm --filter @tripraft/admin test
pnpm --filter @tripraft/admin build
pnpm --filter @tripraft/web lint
pnpm --filter @tripraft/web typecheck
pnpm --filter @tripraft/web test
pnpm --filter @tripraft/web build
```

Web's current `typecheck` covers its configured TypeScript entry/declarations and partner source. It does not mean the entire JavaScript application has static type coverage. Jest uses mocked browser/API interactions; these suites do not establish a deployed end-to-end workflow. Use the relevant screen and API together for behavior changes affecting integration.

For documentation/comment changes, verify inventory completeness, relative links, comment syntax and unchanged executable source. Do not put comments inside strict JSON or image bytes.

## Commit notes

Use this optional table to record relevant GitHub commits after they exist. Copy the actual SHA/link and describe what changed; the source of truth remains Git history.

| Date | GitHub commit | Files/area | Change and validation |
|---|---|---|---|
| YYYY-MM-DD | Link to the real commit | Relative paths or feature | Actual behavior/documentation change and checks run |
