# Services developer guide

Reviewed against GitHub `main` on 2026-10-20. This guide explains the service layout and **all 263 published service files**, plus this README (264 files including the guide). Paths in the file index are relative to `services/`. Local environment files, uploaded files, caches and unpublished backend work are outside that inventory.

## Why services/api/app exists

The nesting has three different responsibilities:

| Path | Meaning |
|---|---|
| `services/` | Repository category for deployable backend services. There is currently one: `api/`. |
| `services/api/` | The Flask service's project root: startup, dependencies, Docker configuration, migrations, catalog SQL and tests. |
| `services/api/app/` | The importable Python package that implements this service. Its imports begin with `app.`. |
| `app/<domain>/services/` | Business-logic modules inside that same process; these folders are not additional deployed servers. |

`api/` is the service boundary, while `app/` is the Python code package. The service also contains files that are not application modules, which is why everything does not live inside `app/`.

```text
services/
  README.md                 This guide
  api/                      One deployable Flask API project
    app/                    Python application package
      auth/                 Accounts, tokens and sessions
      core/                 Factory, configuration, databases and shared infrastructure
      expenses/             Personal/group ledgers and settlements
      itinerary/            Trip generation, saved stops, checklists and exports
      notifications/        SMTP delivery and in-app notifications
      partners/             Supplier applications, agreements and private tour drafts
      places/               Geography, discovery catalogs and ingestion
      scout/                Scout/Crew consent, parsing and model integration
      trips/                Collaborative trips, chat, polls, membership and vaults
    migrations/             Alembic application-database history
      versions/             20 retained migration revision modules
    schema/                 Maintained and older reference-catalog SQL
    tests/                  Shared fixtures and 40 regression test modules
    run.py                  Native development server entry
    gunicorn.conf.py        Production process settings
    init_travel_db.py       Reference-catalog initialization/validation
    Dockerfile              API image built from repository-root context
    package.json            pnpm/Turbo task integration for the Python service
```

## Structure review decision

The existing nesting is appropriate and the path checks resolve its imports. The [root launcher](../start.py), [workspace definition](../pnpm-workspace.yaml), [Docker topology](../infra/docker/docker-compose.yml), migration configuration and test/tooling paths intentionally reference `services/api/`. Flattening `api/` or renaming `app/` would require coordinated changes across those entry points and Python imports without simplifying the current service responsibilities.

Keep domain routes, business logic and data access together. A typical request follows **Flask blueprint/validation -> domain service -> repository or ORM session -> configured database**. Socket.IO handlers reuse the same identities, permissions and persisted domain state. Flask constructs the application through `app.core.factory:create_app()`, re-exported as `app.create_app` for the native entry.

The `__init__.py` files mark importable Python packages; some also provide compatibility/public exports. The partner domain keeps related route/service/schema modules directly in its folder, while other domains use subfolders. This variation does not create duplicate deployments or require a file move. The `core/external/` package is currently a placeholder; concrete clients are also located with their owning domains.

Existing migration IDs, compatibility exports and deprecated route aliases are part of established behavior. Retain them when organizing code. No source files or migration paths were moved as part of this review.

## Main folder responsibilities

| Area | Where to make changes |
|---|---|
| Service startup/dependencies | `api/run.py`, `gunicorn.conf.py`, Docker files, requirements and service configuration. |
| `api/app/auth/` | User/session/audit models, profile/authentication services, token/password helpers and route guards. |
| `api/app/core/` | Flask setup, settings, security, responses, validation, database sessions, caching, logging and workers. |
| `api/app/expenses/` | Shared/private money records, permissions, balance math, settlement and treasury synchronization. |
| `api/app/itinerary/` | Generated trip itineraries, saved stops, checklist operations, external events and PDF/calendar exports. |
| `api/app/notifications/` | In-app notification state and SMTP delivery/templates; retained email entry points serve existing callers. |
| `api/app/partners/` | Isolated supplier identity, versioned business applications, agreement evidence and private package authoring/review. |
| `api/app/places/` | Catalog search/geography, planner destination cards/viewports and authorized ingestion. |
| `api/app/scout/` | AI consent/privacy decisions, Crew command conversations and Scout model/search context. |
| `api/app/trips/` | Groups, memberships/access roles, independent crew duties, invitations, chat, polls, vault and realtime behavior. |
| `api/migrations/` | Application ORM schema history. Add reviewed revisions rather than renumbering or moving applied revisions. |
| `api/schema/` | Reference-catalog SQL, distinct from ORM application migrations. |
| `api/tests/` | Isolated backend regressions using migrated throwaway databases. |

## Data, configuration and generated artifacts

The operational application database and travel reference catalogs have different jobs. Accounts, sessions, groups, invitations, expenses and supplier records use the application database selected by `DATABASE_URL`. General discovery data uses the configured travel catalog/replica; planner cards use `GROUP_PLANNER_CATALOG_PATH`. Environment overrides determine actual locations, so this guide does not infer the active database from a filename.

`init_travel_db.py` selects `schema/tripraft-global-schema-v2.1.sql` for maintained reference-catalog initialization. `schema/tripraft-canonical-schema.sql` is an older seed/reference design with proposed extensions. It is retained as a reference and is not the selected startup initializer. Application table changes belong in Alembic revisions, not in either reference-catalog SQL file.

There are 20 retained revision modules. Some older revision names describe retired operations: date partitioning, JSONB conversion and materialized views currently have no-op upgrades. The UUID migration retains its ID and rejects unsafe legacy rewrites. Filenames describe history; inspect the revision body before assuming an operation will run. The migration environment registers shared ORM metadata and supports both online and offline modes.

`openapi.json` is exported API contract data, consumed by [the typed client](../packages/api-client/src/index.ts). To intentionally update contracts, run the exporter and client generator together; their workflows are documented in the [packages guide](../packages/README.md) and [infrastructure guide](../infra/README.md).

The service-root `.dockerignore` and `Dockerfile.dockerignore` address different build-context discovery rules. The current root-context API build uses the Dockerfile-specific allowlist. It includes the maintained runtime schema and excludes local environment values, uploads, databases, test files and Office/PDF originals. Agreement JSON retains a text representation for environments without the original draft attachment.

Actual `.env`/`.env.supabase` files, `uploads/`, Python/test/lint caches and process logs are local runtime/development artifacts. They are not extra source services and do not belong in this source inventory. Additional pending local backend/schema work or files removed from `main` may remain in a developer checkout; this guide indexes the published revision and does not publish those unrelated changes.

## Local catalog setup

`data/` and `wikidata/` are local workspaces and are excluded from the published repository. A fresh clone includes schema SQL and source code, but no catalog records, demo seed files or database journals. The launcher creates its application database and initializes the empty canonical catalog; this does not populate search or planner destinations.

For manual canonical initialization, from the repository root after installing API dependencies:

```powershell
python services/api/init_travel_db.py --database data/catalog/tripraft-canonical.db
python services/api/init_travel_db.py --database data/catalog/tripraft-canonical.db --check
```

The initializer preserves and validates an existing database; it does not import travel records. Supply an authorized, compatible populated catalog separately and configure `TRAVEL_DATABASE_PATH`/`TRAVEL_DATA_URL` for general discovery. Planner queries use `GROUP_PLANNER_CATALOG_PATH` (default `data/catalog/tripraft_places.db`) and expect the geography/place tables used by [the planner reader](api/app/places/services/planner_catalog_service.py). Set that path to a compatible supplied catalog; the empty canonical initializer alone does not supply planner content. Without that input, catalog-dependent endpoints can report unavailable data.

Keep catalogs, uploads, SQLite WAL/SHM files and local configuration outside Git. API regressions create throwaway databases and synthetic package/image inputs, so tests do not require the removed demo dataset. The four root-level planning PDF/Word originals are also local-only; the agreement DOCX inside `api/app/partners/agreements/` remains a runtime attachment for protected downloads and is intentionally retained.

## Development commands

From the repository root, the existing [launcher](../start.py) manages setup and API/web/admin process startup:

```powershell
python start.py --setup
python start.py
```

With the project Python dependencies installed, use the structure/syntax validators from the repository root:

```powershell
python infra/tools/check_structure.py
python infra/tools/check_python.py
```

Run API tests/lint from `services/api/` (or use the corresponding `@tripraft/api` pnpm tasks):

```powershell
python -m pytest -q
python -m ruff check app tests
```

The pytest fixtures configure a temporary application database before importing app modules and migrate that database for the suite. A passing suite is evidence for those tested contracts, not proof of a configured cloud database, email provider or external model service.

## File index

Each published file appears once below. The index covers strict JSON, SQL, historical migration files and the binary agreement original as well as ordinary Python modules. Source purposes are described without rewriting established per-file GitHub history.

### Service entry and configuration (15 files)

| File | What it does |
|---|---|
| [api/.dockerignore](api/.dockerignore) | Keeps caches, local environment files, logs, uploads, tests and databases out of a service-local Docker build context; the repository-root build uses Dockerfile.dockerignore. |
| [api/.env.example](api/.env.example) | Documents backend configuration keys and placeholders for local settings; actual .env and .env.supabase values remain outside Git. |
| [api/Dockerfile](api/Dockerfile) | Builds the Python API image from the repository root, installs runtime dependencies, copies service code and starts it as a non-root user. |
| [api/Dockerfile.dockerignore](api/Dockerfile.dockerignore) | Restricts the repository-root API build context to service code/schema and excludes secrets, runtime data, tests and Office/PDF artifacts. |
| [api/alembic.ini](api/alembic.ini) | Configures the application's Alembic migration directory, logging and database connection defaults. |
| [api/docker-entrypoint.sh](api/docker-entrypoint.sh) | Initializes the reference catalog and starts the server/worker against a separately migrated schema; startup never applies application migrations. |
| [api/gunicorn.conf.py](api/gunicorn.conf.py) | Defines production binding, gevent workers, timeouts, recycling and logging; disables application preload so workers create their own connections. |
| [api/init_travel_db.py](api/init_travel_db.py) | Initializes the maintained reference-catalog schema and validates existing catalog structure, integrity, foreign keys and optional emptiness without loading seed rows. |
| [api/openapi.json](api/openapi.json) | Contains exported API routes and explicit request/response schemas used to generate the shared TypeScript API client. |
| [api/package.json](api/package.json) | Registers @tripraft/api in the pnpm/Turbo workspace and maps test, lint and syntax-check tasks to Python commands. |
| [api/pytest.ini](api/pytest.ini) | Selects backend test discovery, marker declarations, failure reporting and coverage configuration sections. |
| [api/requirements-dev.txt](api/requirements-dev.txt) | Adds the test, coverage, critical-error lint and YAML validation tools used in development and CI. |
| [api/requirements.txt](api/requirements.txt) | Pins the Python API runtime dependencies for Flask, databases, authentication, validation, sockets, workers and external integrations. |
| [api/ruff.toml](api/ruff.toml) | Selects the Python 3.11 syntax/error lint baseline and excludes migration files from ordinary lint checks. |
| [api/run.py](api/run.py) | Starts the native Flask/Socket.IO development server, applies gevent patching before imports, and prepares explicitly enabled source reload behavior. |
| [api/schema_status.py](api/schema_status.py) | Explains migration graph differences and pending revisions without importing application settings or writing to a database. |

### Application package entry (1 file)

| File | What it does |
|---|---|
| [api/app/__init__.py](api/app/__init__.py) | Exposes create_app from app.core.factory so the Python package has a stable application-factory entry. |

### Authentication (13 files)

| File | What it does |
|---|---|
| [api/app/auth/__init__.py](api/app/auth/__init__.py) | Re-exports the shared account/session models and their repositories for authentication consumers. |
| [api/app/auth/models.py](api/app/auth/models.py) | Defines the unified User, UserSession and security AuditLog ORM models. |
| [api/app/auth/repository.py](api/app/auth/repository.py) | Implements account/session lookups and persistence behind authentication services. |
| [api/app/auth/routes/__init__.py](api/app/auth/routes/__init__.py) | Declares the app.auth.routes Python package used by the service imports. |
| [api/app/auth/routes/auth.py](api/app/auth/routes/auth.py) | Exposes traveler signup/login, session refresh/logout, verification, profile and expense-bootstrap endpoints. |
| [api/app/auth/routes/users.py](api/app/auth/routes/users.py) | Provides the user API surface, delegating authentication to AuthService and profile changes to UserService. |
| [api/app/auth/security/__init__.py](api/app/auth/security/__init__.py) | Re-exports route guards, token/cookie helpers and password functions through one authentication entry. |
| [api/app/auth/security/decorators.py](api/app/auth/security/decorators.py) | Resolves authenticated identity and enforces session, administrator and group/message-role access consistently across routes. |
| [api/app/auth/security/jwt.py](api/app/auth/security/jwt.py) | Creates/verifies traveler and partner tokens, supports signing-key selection, hashes refresh tokens and sets/clears auth cookies. |
| [api/app/auth/security/password.py](api/app/auth/security/password.py) | Hashes and verifies bcrypt passwords and evaluates signup password requirements. |
| [api/app/auth/services/__init__.py](api/app/auth/services/__init__.py) | Declares the app.auth.services Python package used by the service imports. |
| [api/app/auth/services/auth_service.py](api/app/auth/services/auth_service.py) | Implements registration, login, refresh rotation, session revocation and authentication lifecycle behavior. |
| [api/app/auth/services/user_service.py](api/app/auth/services/user_service.py) | Implements current-user/profile retrieval and updates plus authenticated password changes. |

### Core infrastructure (28 files)

| File | What it does |
|---|---|
| [api/app/core/__init__.py](api/app/core/__init__.py) | Re-exports configuration access and shared application exceptions for backend consumers. |
| [api/app/core/apiutils/__init__.py](api/app/core/apiutils/__init__.py) | Re-exports reference-database compatibility helpers, response builders and input-validation utilities. |
| [api/app/core/apiutils/database.py](api/app/core/apiutils/database.py) | Adapts the shared travel database to the older init_database/get_db interface used by existing routes and factory initialization. |
| [api/app/core/apiutils/responses.py](api/app/core/apiutils/responses.py) | Builds standard success/error/pagination envelopes with request metadata and appropriate HTTP statuses. |
| [api/app/core/apiutils/validators.py](api/app/core/apiutils/validators.py) | Validates request schemas, bounded query/pagination values, UUIDs, search text, sort fields and filters. |
| [api/app/core/cache/__init__.py](api/app/core/cache/__init__.py) | Re-exports Redis caching, route-cache invalidation and login-lockout/trusted-device helpers. |
| [api/app/core/cache/redis.py](api/app/core/cache/redis.py) | Manages optional Redis access, JSON caching, route caching, login failure tracking and temporary lockout state. |
| [api/app/core/config.py](api/app/core/config.py) | Loads environment-backed application settings and selects development, production or testing configuration; includes operational and reference-data paths. |
| [api/app/core/db/__init__.py](api/app/core/db/__init__.py) | Re-exports ORM engines, routed sessions, shared Base, database initialization and compatibility access helpers. |
| [api/app/core/db/base.py](api/app/core/db/base.py) | Defines the shared SQLAlchemy declarative Base so application models register in one metadata registry. |
| [api/app/core/db/connection.py](api/app/core/db/connection.py) | Creates operational/reference engines, routes ORM sessions and manages transactions; verifies migrations rather than silently creating missing application tables. |
| [api/app/core/db/migration_checks.py](api/app/core/db/migration_checks.py) | Detects incompatible legacy identifier column/storage types before accepting an existing application database. |
| [api/app/core/db/travel_db.py](api/app/core/db/travel_db.py) | Manages SQLite reference-catalog connections, validated identifiers, queries and controlled transaction helpers. |
| [api/app/core/db/uuid7.py](api/app/core/db/uuid7.py) | Generates time-ordered UUIDv7 identifiers and provides a SQLAlchemy UUID type that accepts string inputs. |
| [api/app/core/dev_reload.py](api/app/core/dev_reload.py) | Performs the explicitly requested native-development reload preparation while keeping production behavior separate. |
| [api/app/core/exceptions.py](api/app/core/exceptions.py) | Defines application exception classes carrying HTTP status/error context for centralized API handling. |
| [api/app/core/external/__init__.py](api/app/core/external/__init__.py) | Reserves a Python package for external integrations; current concrete clients also live with their owning domains. |
| [api/app/core/factory.py](api/app/core/factory.py) | Builds Flask, initializes required components, registers domain blueprints, middleware, errors, health routes, legacy aliases and realtime extensions. |
| [api/app/core/health.py](api/app/core/health.py) | Implements liveness/readiness endpoints and probes application database, cache and configured worker availability. |
| [api/app/core/idempotency.py](api/app/core/idempotency.py) | Scopes and reserves mutating request keys and replays stored results to prevent duplicate execution after retries. |
| [api/app/core/json_utils.py](api/app/core/json_utils.py) | Normalizes ORM-emitted values into JSON-compatible data at API/event boundaries. |
| [api/app/core/logging.py](api/app/core/logging.py) | Configures application logging and structured production log formatting. |
| [api/app/core/middleware.py](api/app/core/middleware.py) | Assigns validated correlation/request identifiers and emits structured request/response logs and headers. |
| [api/app/core/rate_limiter.py](api/app/core/rate_limiter.py) | Configures shared request limits, endpoint limit helpers and trusted-proxy-aware client identity. |
| [api/app/core/resilience.py](api/app/core/resilience.py) | Defines circuit breakers and logging for failure-prone external service calls. |
| [api/app/core/route_viewer.py](api/app/core/route_viewer.py) | Provides an authenticated administrator-only HTML/JSON listing of registered Flask routes. |
| [api/app/core/sanitize.py](api/app/core/sanitize.py) | Sanitizes untrusted text/rich text before persistence or display using the configured HTML policy. |
| [api/app/core/security.py](api/app/core/security.py) | Adds response security headers and handles readable CSRF-cookie generation and cookie-request validation. |

### Validation schemas (17 files)

| File | What it does |
|---|---|
| [api/app/core/schemas/__init__.py](api/app/core/schemas/__init__.py) | Re-exports domain validation schemas through the existing shared import surface. |
| [api/app/core/schemas/auth.py](api/app/core/schemas/auth.py) | Validates traveler signup, login, password and profile request fields. |
| [api/app/core/schemas/common.py](api/app/core/schemas/common.py) | Retains backward-compatible validation-schema exports and the shared validate_request decorator. |
| [api/app/core/schemas/expense_groups.py](api/app/core/schemas/expense_groups.py) | Validates expense-group creation, metadata and membership changes with persisted limits and restricted role fields. |
| [api/app/core/schemas/expenses.py](api/app/core/schemas/expenses.py) | Validates expense create/update amounts, payer, split and metadata inputs. |
| [api/app/core/schemas/fields.py](api/app/core/schemas/fields.py) | Defines shared UUID, currency, calendar-date and trimmed-text field behavior for request schemas. |
| [api/app/core/schemas/gp_chat.py](api/app/core/schemas/gp_chat.py) | Validates message creation/editing and read-receipt inputs. |
| [api/app/core/schemas/gp_checklist.py](api/app/core/schemas/gp_checklist.py) | Validates shared checklist item creation, editing and assignment. |
| [api/app/core/schemas/gp_places.py](api/app/core/schemas/gp_places.py) | Validates itinerary-place additions, edits, remarks and geocoding requests. |
| [api/app/core/schemas/gp_polls.py](api/app/core/schemas/gp_polls.py) | Validates poll creation and option-index voting inputs. |
| [api/app/core/schemas/group_planner.py](api/app/core/schemas/group_planner.py) | Validates trip-group metadata, budget and itinerary-document updates. |
| [api/app/core/schemas/incomes.py](api/app/core/schemas/incomes.py) | Validates personal income requests while identity/ownership come from authentication. |
| [api/app/core/schemas/invitations.py](api/app/core/schemas/invitations.py) | Validates and normalizes member invitation email/input fields for expense and trip flows. |
| [api/app/core/schemas/places.py](api/app/core/schemas/places.py) | Defines Pydantic ingestion models for geography, places, photos, tags, hours and bulk validation results. |
| [api/app/core/schemas/settlements.py](api/app/core/schemas/settlements.py) | Validates settlement participant, amount and note inputs. |
| [api/app/core/schemas/trips.py](api/app/core/schemas/trips.py) | Validates single-trip itinerary generation parameters. |
| [api/app/core/schemas/users.py](api/app/core/schemas/users.py) | Defines typed account registration/login/profile/password/token request and response models. |

### Background workers (11 files)

| File | What it does |
|---|---|
| [api/app/core/workers/__init__.py](api/app/core/workers/__init__.py) | Declares the app.core.workers Python package used by the service imports. |
| [api/app/core/workers/celery_app.py](api/app/core/workers/celery_app.py) | Configures the Celery application, broker/backend, task loading and failure handling. |
| [api/app/core/workers/schedules.py](api/app/core/workers/schedules.py) | Defines periodic maintenance, cache and analytics task schedules for Celery Beat. |
| [api/app/core/workers/tasks/__init__.py](api/app/core/workers/tasks/__init__.py) | Declares the app.core.workers.tasks Python package used by the service imports. |
| [api/app/core/workers/tasks/ai_tasks.py](api/app/core/workers/tasks/ai_tasks.py) | Processes Scout mentions, consent-aware chat summarization and AI-log retention through Celery tasks. |
| [api/app/core/workers/tasks/analytics_tasks.py](api/app/core/workers/tasks/analytics_tasks.py) | Defines popular-search cache warming and daily usage aggregation tasks. |
| [api/app/core/workers/tasks/chat_tasks.py](api/app/core/workers/tasks/chat_tasks.py) | Archives old messages reversibly and dispatches supported AI mentions to background processing. |
| [api/app/core/workers/tasks/cleanup_tasks.py](api/app/core/workers/tasks/cleanup_tasks.py) | Removes expired sessions and performs configured cleanup of older soft-deleted records. |
| [api/app/core/workers/tasks/crew_tasks.py](api/app/core/workers/tasks/crew_tasks.py) | Processes Crew commands, conversation/card responses and rate limits in the background. |
| [api/app/core/workers/tasks/email_tasks.py](api/app/core/workers/tasks/email_tasks.py) | Wraps invitation, verification, password-reset and expense-notification delivery as retryable Celery tasks. |
| [api/app/core/workers/tasks/notification_tasks.py](api/app/core/workers/tasks/notification_tasks.py) | Defines group/user realtime notification tasks that emit through the shared Socket.IO extension. |

### Expenses and money (23 files)

| File | What it does |
|---|---|
| [api/app/expenses/__init__.py](api/app/expenses/__init__.py) | Re-exports expense/group/settlement models while retaining the unified account model through compatibility imports. |
| [api/app/expenses/models.py](api/app/expenses/models.py) | Defines expense groups, memberships, expenses, income/history, splits, settlements, balances and invitations on the shared ORM Base. |
| [api/app/expenses/realtime.py](api/app/expenses/realtime.py) | Emits authenticated private cache-invalidations after committed expense changes without broadcasting ledger rows. |
| [api/app/expenses/routes/__init__.py](api/app/expenses/routes/__init__.py) | Declares the app.expenses.routes Python package used by the service imports. |
| [api/app/expenses/routes/currencies.py](api/app/expenses/routes/currencies.py) | Exposes anonymous read-only currency listings and dated exchange-rate observations. |
| [api/app/expenses/routes/expense_groups.py](api/app/expenses/routes/expense_groups.py) | Implements authenticated expense-group creation, details, membership, role, leave and archive operations. |
| [api/app/expenses/routes/expense_invitations.py](api/app/expenses/routes/expense_invitations.py) | Exposes private expense invitation lookup, creation, acceptance, decline, resend and cancellation with cache refresh. |
| [api/app/expenses/routes/expenses.py](api/app/expenses/routes/expenses.py) | Exposes expense CRUD, soft delete/restore, personal/group lists and edit history with permission and freshness handling. |
| [api/app/expenses/routes/friends.py](api/app/expenses/routes/friends.py) | Lists and saves the signed-in user's private contacts for reusable expense invitations. |
| [api/app/expenses/routes/group_finance.py](api/app/expenses/routes/group_finance.py) | Exposes authorized group analytics, balances, simplified debts and compatibility balance-repair endpoints. |
| [api/app/expenses/routes/personal_finance.py](api/app/expenses/routes/personal_finance.py) | Exposes private income CRUD/history and currency-separated personal summaries, transactions and analytics. |
| [api/app/expenses/routes/settlements.py](api/app/expenses/routes/settlements.py) | Exposes authorized payment recording/deletion and group settlement/balance/debt reads. |
| [api/app/expenses/services/__init__.py](api/app/expenses/services/__init__.py) | Declares the app.expenses.services Python package used by the service imports. |
| [api/app/expenses/services/exchange_rates.py](api/app/expenses/services/exchange_rates.py) | Fetches and validates public currency/rate reference data with caching and explicit bounded stale fallback; it does not alter ledgers. |
| [api/app/expenses/services/expense_group_service.py](api/app/expenses/services/expense_group_service.py) | Applies group/member lifecycle rules, serialized ownership/role changes and truthful ledger summary snapshots. |
| [api/app/expenses/services/expense_invite_service.py](api/app/expenses/services/expense_invite_service.py) | Implements recipient checks, expiry and membership transitions for expense invitations. |
| [api/app/expenses/services/expense_service.py](api/app/expenses/services/expense_service.py) | Validates and persists expense/split edits, balance changes, soft deletion/restoration and audit history. |
| [api/app/expenses/services/group_access.py](api/app/expenses/services/group_access.py) | Centralizes ledger access, ownership/role checks, former-member balance preservation and invitation/member invariants. |
| [api/app/expenses/services/friend_service.py](api/app/expenses/services/friend_service.py) | Upserts private contacts atomically and resolves registered names, nicknames and literal searches. |
| [api/app/expenses/services/group_finance_service.py](api/app/expenses/services/group_finance_service.py) | Derives group spending/trends and balance recalculation from persisted financial records. |
| [api/app/expenses/services/ledger_math.py](api/app/expenses/services/ledger_math.py) | Serializes decimal balances and simplifies debts while retaining single-cent obligations. |
| [api/app/expenses/services/money_lock.py](api/app/expenses/services/money_lock.py) | Locks financial groups/records so validation and monetary mutation share a serialized transaction. |
| [api/app/expenses/services/personal_finance_service.py](api/app/expenses/services/personal_finance_service.py) | Applies ownership-aware income CRUD and computes currency-separated personal cash-flow/transaction reports. |
| [api/app/expenses/services/settlement_service.py](api/app/expenses/services/settlement_service.py) | Validates settlement parties and debt limits, updates balances and supports authorized payment reversal. |
| [api/app/expenses/services/trip_treasury.py](api/app/expenses/services/trip_treasury.py) | Creates and synchronizes the expense-domain side of verified linked trip treasuries and membership. |

### Itinerary and logistics (12 files)

| File | What it does |
|---|---|
| [api/app/itinerary/__init__.py](api/app/itinerary/__init__.py) | Declares the app.itinerary Python package used by the service imports. |
| [api/app/itinerary/routes/__init__.py](api/app/itinerary/routes/__init__.py) | Declares the app.itinerary.routes Python package used by the service imports. |
| [api/app/itinerary/routes/gp_checklist.py](api/app/itinerary/routes/gp_checklist.py) | Exposes trip checklist listing, creation, toggle, metadata updates, assignment, deletion and statistics. |
| [api/app/itinerary/routes/gp_events.py](api/app/itinerary/routes/gp_events.py) | Exposes destination event discovery and event-category information through the event service. |
| [api/app/itinerary/routes/gp_export.py](api/app/itinerary/routes/gp_export.py) | Exposes trip PDF/iCalendar export, cloning and group-code joining with trip access checks. |
| [api/app/itinerary/routes/gp_places.py](api/app/itinerary/routes/gp_places.py) | Exposes saved trip places, votes, schedule/details/remarks edits, deletion and geocoding. |
| [api/app/itinerary/routes/trips.py](api/app/itinerary/routes/trips.py) | Generates single-trip itineraries and exposes city lookups with pacing, preference and place-filter handling. |
| [api/app/itinerary/services/__init__.py](api/app/itinerary/services/__init__.py) | Declares the app.itinerary.services Python package used by the service imports. |
| [api/app/itinerary/services/checklist_service.py](api/app/itinerary/services/checklist_service.py) | Persists shared checklist state and validates categories, priority, due dates and active-member assignments. |
| [api/app/itinerary/services/events_service.py](api/app/itinerary/services/events_service.py) | Looks up travel-destination events using the configured Ticketmaster integration and external-call safeguards. |
| [api/app/itinerary/services/export_service.py](api/app/itinerary/services/export_service.py) | Produces trip PDF and iCalendar data and implements the related export/clone helpers. |
| [api/app/itinerary/services/travel_place_service.py](api/app/itinerary/services/travel_place_service.py) | Applies authorization and validation to stored trip stops, votes, coordinates, timing and metadata changes. |

### Notifications (10 files)

| File | What it does |
|---|---|
| [api/app/notifications/__init__.py](api/app/notifications/__init__.py) | Declares the app.notifications Python package used by the service imports. |
| [api/app/notifications/email/__init__.py](api/app/notifications/email/__init__.py) | Exposes the SMTP EmailService and its shared email_service instance. |
| [api/app/notifications/email/config.py](api/app/notifications/email/config.py) | Centralizes feature-level email notification enablement settings. |
| [api/app/notifications/email/links.py](api/app/notifications/email/links.py) | Builds canonical expense-invitation frontend links shared by responses and email templates. |
| [api/app/notifications/email/smtp.py](api/app/notifications/email/smtp.py) | Implements SMTP delivery with HTML/plain-text templates for application notification emails. |
| [api/app/notifications/routes/__init__.py](api/app/notifications/routes/__init__.py) | Declares the app.notifications.routes Python package used by the service imports. |
| [api/app/notifications/routes/gp_notifications.py](api/app/notifications/routes/gp_notifications.py) | Exposes a user's paginated in-app notifications and single/all-read updates. |
| [api/app/notifications/services/__init__.py](api/app/notifications/services/__init__.py) | Declares the app.notifications.services Python package used by the service imports. |
| [api/app/notifications/services/email_service.py](api/app/notifications/services/email_service.py) | Provides the expense invitation SMTP service and its invitation templates/configured enablement checks. |
| [api/app/notifications/services/notification_service.py](api/app/notifications/services/notification_service.py) | Creates and queries in-app notifications and updates read state for the owning user. |

### Partners and private packages (16 files)

| File | What it does |
|---|---|
| [api/app/partners/__init__.py](api/app/partners/__init__.py) | Declares the app.partners Python package used by the service imports. |
| [api/app/partners/agreement_service.py](api/app/partners/agreement_service.py) | Loads the agreement draft, checks approved-agent access and records explicit version/hash-bound acknowledgments, signatures and receipts. |
| [api/app/partners/agreements/partner-agreement-v3-2026-10-18.docx](api/app/partners/agreements/partner-agreement-v3-2026-10-18.docx) | Preserves the original supplied agreement draft bytes for authorized document download and source-hash verification. |
| [api/app/partners/agreements/partner-agreement-v3-2026-10-18.json](api/app/partners/agreements/partner-agreement-v3-2026-10-18.json) | Stores ordered agreement text/table blocks, document furniture and original-source hash for the protected reader. |
| [api/app/partners/media_service.py](api/app/partners/media_service.py) | Validates/sanitizes supplier images and stores private media with controlled path and ownership handling. |
| [api/app/partners/models.py](api/app/partners/models.py) | Defines supplier businesses, partner memberships, application review evidence and agreement acknowledgment/signature records. |
| [api/app/partners/package_models.py](api/app/partners/package_models.py) | Defines private tour packages, immutable content revisions, media metadata and staff review records. |
| [api/app/partners/package_review_routes.py](api/app/partners/package_review_routes.py) | Exposes protected image upload/read, supplier submission and staff package-list/decision endpoints. |
| [api/app/partners/package_routes.py](api/app/partners/package_routes.py) | Exposes private supplier package listing, creation, retrieval, versioned saving and duplication. |
| [api/app/partners/package_schemas.py](api/app/partners/package_schemas.py) | Validates package content, itinerary/departure/rate/media inputs and defines draft/review response contracts. |
| [api/app/partners/package_services.py](api/app/partners/package_services.py) | Enforces approved-owner access and versioned private draft changes, preparation checks, media selection and submission/review transitions. |
| [api/app/partners/routes.py](api/app/partners/routes.py) | Exposes isolated partner identity/application/agreement endpoints and authorized staff application review routes with explicit errors and no-store responses. |
| [api/app/partners/schemas.py](api/app/partners/schemas.py) | Validates partner identity, business application, review and agreement-signing inputs and response shapes. |
| [api/app/partners/security.py](api/app/partners/security.py) | Resolves isolated partner tokens/sessions, sets/clears partner cookies and guards supplier requests separately from traveler authentication. |
| [api/app/partners/services.py](api/app/partners/services.py) | Implements partner registration/login, application versions, snapshots, submission and staff review decisions. |
| [api/app/partners/staff_routes.py](api/app/partners/staff_routes.py) | Implements employee-only staff-console login without granting staff access to customer or partner identities. |

### Places and catalog data (17 files)

| File | What it does |
|---|---|
| [api/app/places/__init__.py](api/app/places/__init__.py) | Declares the app.places Python package used by the service imports. |
| [api/app/places/location_models.py](api/app/places/location_models.py) | Queries and adapts catalog geography/place rows for the existing location APIs. |
| [api/app/places/location_repository.py](api/app/places/location_repository.py) | Preserves location init_database/get_db compatibility over the shared catalog connection pool. |
| [api/app/places/models.py](api/app/places/models.py) | Defines place-search result, geography, photo, hours and autocomplete data objects. |
| [api/app/places/repository.py](api/app/places/repository.py) | Supplies pooled travel-catalog connections shared by place search and location lookups. |
| [api/app/places/routes/__init__.py](api/app/places/routes/__init__.py) | Declares the app.places.routes Python package used by the service imports. |
| [api/app/places/routes/admin_places.py](api/app/places/routes/admin_places.py) | Exposes authenticated staff geography/place/media ingestion, validation, bulk import and audit endpoints. |
| [api/app/places/routes/gp_destinations.py](api/app/places/routes/gp_destinations.py) | Exposes planner catalog destinations, cards/viewports and related destination/activity lookup endpoints. |
| [api/app/places/routes/locations.py](api/app/places/routes/locations.py) | Retains deprecated unified location/geography/place endpoints with bounded queries and deprecation headers. |
| [api/app/places/routes/places.py](api/app/places/routes/places.py) | Exposes place search, autocomplete, detail and catalog statistics with pagination/freshness metadata. |
| [api/app/places/search/__init__.py](api/app/places/search/__init__.py) | Declares the app.places.search Python package used by the service imports. |
| [api/app/places/search/web_search.py](api/app/places/search/web_search.py) | Queries the configured web-search backends with fallback and circuit-breaker behavior for Scout discovery. |
| [api/app/places/services/__init__.py](api/app/places/services/__init__.py) | Declares the app.places.services Python package used by the service imports. |
| [api/app/places/services/data_ingestion_service.py](api/app/places/services/data_ingestion_service.py) | Validates and applies single/bulk writes for geography, places, photos, tags and opening hours with ingestion results. |
| [api/app/places/services/destination_service.py](api/app/places/services/destination_service.py) | Resolves destination and popular-place lookups from the configured travel catalog. |
| [api/app/places/services/place_search_service.py](api/app/places/services/place_search_service.py) | Implements ranked/filtered place search, autocomplete, details and statistics over catalog data. |
| [api/app/places/services/planner_catalog_service.py](api/app/places/services/planner_catalog_service.py) | Reads destination-scoped planner geography, place/festival cards and map viewports from the configured read-only planner catalog. |

### Scout and Crew (15 files)

| File | What it does |
|---|---|
| [api/app/scout/__init__.py](api/app/scout/__init__.py) | Declares the app.scout Python package used by the service imports. |
| [api/app/scout/llm/__init__.py](api/app/scout/llm/__init__.py) | Declares the app.scout.llm Python package used by the service imports. |
| [api/app/scout/llm/ollama_client.py](api/app/scout/llm/ollama_client.py) | Calls the configured Ollama generation endpoint with timeouts, circuit-breaker state and explicit unavailable errors. |
| [api/app/scout/llm/output_validator.py](api/app/scout/llm/output_validator.py) | Sanitizes and validates generated response text before storage or presentation. |
| [api/app/scout/llm/prompt_templates.py](api/app/scout/llm/prompt_templates.py) | Builds server-owned Scout prompts from structured context and explicitly delimited untrusted text. |
| [api/app/scout/models.py](api/app/scout/models.py) | Defines per-group AI consent, preference profiles and interaction-log ORM records. |
| [api/app/scout/routes/__init__.py](api/app/scout/routes/__init__.py) | Declares the app.scout.routes Python package used by the service imports. |
| [api/app/scout/routes/ai_confirm.py](api/app/scout/routes/ai_confirm.py) | Validates confirmation/cancellation of pending Crew actions and rechecks permissions before destructive execution. |
| [api/app/scout/routes/ai_consent.py](api/app/scout/routes/ai_consent.py) | Exposes current-user group consent lookup, updates and revocation with preference-data cleanup. |
| [api/app/scout/services/__init__.py](api/app/scout/services/__init__.py) | Declares the app.scout.services Python package used by the service imports. |
| [api/app/scout/services/consent_gate.py](api/app/scout/services/consent_gate.py) | Resolves per-user/per-group consent and privacy overrides before agent data access. |
| [api/app/scout/services/crew_agent_service.py](api/app/scout/services/crew_agent_service.py) | Dispatches Crew command intents, collects missing fields, requests confirmation and invokes authorized domain operations. |
| [api/app/scout/services/crew_conversation.py](api/app/scout/services/crew_conversation.py) | Stores per-user/per-group multi-step Crew conversation state and expiry in Redis. |
| [api/app/scout/services/crew_parsers.py](api/app/scout/services/crew_parsers.py) | Classifies Crew commands and extracts structured entities using staged parsing strategies. |
| [api/app/scout/services/scout_agent_service.py](api/app/scout/services/scout_agent_service.py) | Coordinates consent-aware Scout intent handling, reference/web context, rate limits and optional language-model responses. |

### Collaborative trips (19 files)

| File | What it does |
|---|---|
| [api/app/trips/__init__.py](api/app/trips/__init__.py) | Re-exports the collaborative trip, member, place, poll, checklist, activity, vault and chat ORM models. |
| [api/app/trips/models.py](api/app/trips/models.py) | Defines collaborative trip/member entities and their saved places, votes, invitations, logistics, activity, notifications and chat records. |
| [api/app/trips/realtime/__init__.py](api/app/trips/realtime/__init__.py) | Declares the app.trips.realtime Python package used by the service imports. |
| [api/app/trips/realtime/changes.py](api/app/trips/realtime/changes.py) | Captures committed planner changes and sends authorized clients private refresh notifications. |
| [api/app/trips/realtime/events.py](api/app/trips/realtime/events.py) | Authenticates Socket.IO clients, verifies group-room membership and handles presence, message and collaboration events. |
| [api/app/trips/realtime/socketio_ext.py](api/app/trips/realtime/socketio_ext.py) | Owns the shared Flask-SocketIO singleton and its application initialization. |
| [api/app/trips/routes/__init__.py](api/app/trips/routes/__init__.py) | Declares the app.trips.routes Python package used by the service imports. |
| [api/app/trips/routes/gp_chat.py](api/app/trips/routes/gp_chat.py) | Exposes group message pagination/send/edit/delete, read/unread state and supported consent/AI dispatch behavior. |
| [api/app/trips/routes/gp_groups.py](api/app/trips/routes/gp_groups.py) | Exposes group lifecycle, memberships/access roles, independent crew duties, settings, activities and linked-treasury endpoints. |
| [api/app/trips/routes/gp_invitations.py](api/app/trips/routes/gp_invitations.py) | Exposes trip invitation creation, lookup, acceptance, decline, resend and cancellation. |
| [api/app/trips/routes/gp_polls.py](api/app/trips/routes/gp_polls.py) | Exposes group poll creation/listing, option voting and authorized deletion. |
| [api/app/trips/routes/gp_vault.py](api/app/trips/routes/gp_vault.py) | Exposes authorized trip-vault file upload, listing, download and deletion. |
| [api/app/trips/services/__init__.py](api/app/trips/services/__init__.py) | Declares the app.trips.services Python package used by the service imports. |
| [api/app/trips/services/chat_service.py](api/app/trips/services/chat_service.py) | Implements message CRUD, visibility, cursor pagination, read receipts and unread counts on persisted chat records. |
| [api/app/trips/services/poll_service.py](api/app/trips/services/poll_service.py) | Applies poll creation/expiry, option voting, voter counting and deletion rules. |
| [api/app/trips/services/travel_group_service.py](api/app/trips/services/travel_group_service.py) | Implements trip group lifecycle, membership, settings, role policy and group-code generation on shared accounts. |
| [api/app/trips/services/treasury_service.py](api/app/trips/services/treasury_service.py) | Applies trip-level authorization/responsibility policy when linking and synchronizing an expense treasury. |
| [api/app/trips/services/trip_invite_service.py](api/app/trips/services/trip_invite_service.py) | Applies trip invitation recipient/expiry checks and group membership transitions. |
| [api/app/trips/services/vault_service.py](api/app/trips/services/vault_service.py) | Validates stored vault uploads and controls disk-backed file retrieval/deletion under the configured upload directory. |

### Application migrations (23 files)

| File | What it does |
|---|---|
| [api/migrations/README](api/migrations/README) | Retains the Alembic template's short single-database configuration note. |
| [api/migrations/env.py](api/migrations/env.py) | Registers all ORM model metadata and runs Alembic online/offline against the selected database with percent-safe URL handling. |
| [api/migrations/script.py.mako](api/migrations/script.py.mako) | Templates newly generated Alembic revision modules and their upgrade/downgrade functions. |
| [api/migrations/versions/119b418945ce_json_to_jsonb_postgresql.py](api/migrations/versions/119b418945ce_json_to_jsonb_postgresql.py) | Preserves a retired JSONB-conversion revision as a no-op; the portable frozen baseline owns current JSON types. |
| [api/migrations/versions/60621bfec6f2_add_missing_composite_indexes.py](api/migrations/versions/60621bfec6f2_add_missing_composite_indexes.py) | Adds the defined composite/query lookup indexes across account, expense and planner records. |
| [api/migrations/versions/74866d910457_uuidv7_primary_keys.py](api/migrations/versions/74866d910457_uuidv7_primary_keys.py) | Retains the historical UUID migration ID while rejecting unsafe legacy integer-storage rewrites rather than silently converting them. |
| [api/migrations/versions/75118e6ab634_initial_schema.py](api/migrations/versions/75118e6ab634_initial_schema.py) | Defines the frozen UUID-native application schema used for fresh operational database installations. |
| [api/migrations/versions/83f1d84d08e4_add_ai_consent_preferences_agent_logs.py](api/migrations/versions/83f1d84d08e4_add_ai_consent_preferences_agent_logs.py) | Preserves the legacy AI-table revision, tolerating the complete baseline and rejecting partial incompatible table sets. |
| [api/migrations/versions/a0a12823fc65_materialized_views_postgresql.py](api/migrations/versions/a0a12823fc65_materialized_views_postgresql.py) | Preserves a retired materialized-view revision as a no-op pending a separate reviewed design. |
| [api/migrations/versions/a18b2c3d4e5f_partner_onboarding.py](api/migrations/versions/a18b2c3d4e5f_partner_onboarding.py) | Adds partner business/member/review records and portal identity classification while preserving existing users as travelers. |
| [api/migrations/versions/a5b6c7d8e9f0_add_checklist_metadata_and_chat_fks.py](api/migrations/versions/a5b6c7d8e9f0_add_checklist_metadata_and_chat_fks.py) | Adds persisted checklist metadata and missing chat-reference constraints for supported existing databases. |
| [api/migrations/versions/b29c3d4e5f60_tour_drafts.py](api/migrations/versions/b29c3d4e5f60_tour_drafts.py) | Adds private supplier package and content-revision storage. |
| [api/migrations/versions/b7c8d9e0f1a2_complete_vault_and_place_time_schema.py](api/migrations/versions/b7c8d9e0f1a2_complete_vault_and_place_time_schema.py) | Completes supported vault/place-time schema coverage and validates UUID-native storage. |
| [api/migrations/versions/c30d4e5f6071_partner_agreement.py](api/migrations/versions/c30d4e5f6071_partner_agreement.py) | Adds demo classification and explicit agreement-reading acknowledgment evidence; reading is separate from signature. |
| [api/migrations/versions/c4d5e6f7a8b9_add_chat_tables.py](api/migrations/versions/c4d5e6f7a8b9_add_chat_tables.py) | Preserves legacy chat-table creation, tolerating the complete baseline while rejecting partial incompatible chat schemas. |
| [api/migrations/versions/c62f718293a4_personal_display_currency.py](api/migrations/versions/c62f718293a4_personal_display_currency.py) | Adds a nullable per-user personal dashboard currency preference without choosing a default for existing users. |
| [api/migrations/versions/d73f8293a5b6_friend_contacts.py](api/migrations/versions/d73f8293a5b6_friend_contacts.py) | Adds private saved friends and backfills the original inviter's historical expense recipients. |
| [api/migrations/versions/c9d2e4f6a8b0_add_personal_income_ledger.py](api/migrations/versions/c9d2e4f6a8b0_add_personal_income_ledger.py) | Adds personal income records, their audit history and related personal-ledger indexes. |
| [api/migrations/versions/d41e5f607182_agent_signatures.py](api/migrations/versions/d41e5f607182_agent_signatures.py) | Adds approved-agent signature evidence and receipt fields for the agreement draft workflow. |
| [api/migrations/versions/d4a1c3e8f9b0_add_settlement_and_verification_audit_columns.py](api/migrations/versions/d4a1c3e8f9b0_add_settlement_and_verification_audit_columns.py) | Adds persisted settlement-deletion and account email-verification audit fields. |
| [api/migrations/versions/e1f2a3b4c5d6_add_trip_member_crew_role.py](api/migrations/versions/e1f2a3b4c5d6_add_trip_member_crew_role.py) | Adds optional trip responsibilities independently of membership access roles. |
| [api/migrations/versions/e336ee48cb0f_add_date_partitioning_postgresql.py](api/migrations/versions/e336ee48cb0f_add_date_partitioning_postgresql.py) | Preserves the retired date-partitioning revision as a no-op for the UUID-native baseline. |
| [api/migrations/versions/e52f60718293_package_review_media.py](api/migrations/versions/e52f60718293_package_review_media.py) | Adds package submission/approval revision metadata, private media records and staff review evidence. |
| [api/migrations/versions/e80825488cb5_add_audit_log_table.py](api/migrations/versions/e80825488cb5_add_audit_log_table.py) | Ensures security audit storage exists on supported legacy databases and completes its relationship metadata. |
| [api/migrations/versions/f2a3b4c5d6e7_add_chat_message_archival.py](api/migrations/versions/f2a3b4c5d6e7_add_chat_message_archival.py) | Adds reversible persisted chat archival state and adjusts the PostgreSQL active-message index. |

### Reference SQL (2 files)

| File | What it does |
|---|---|
| [api/schema/tripraft-canonical-schema.sql](api/schema/tripraft-canonical-schema.sql) | Preserves the older seed/reference schema and proposed extensions; it is not the initializer's selected runtime schema. |
| [api/schema/tripraft-global-schema-v2.1.sql](api/schema/tripraft-global-schema-v2.1.sql) | Defines the maintained empty SQLite travel/reference catalog initialized by init_travel_db.py, including geography, place data and full-text structures. |

### Backend tests (41 files)

| File | What it does |
|---|---|
| [api/tests/conftest.py](api/tests/conftest.py) | Configures a throwaway application database before app imports and provides migrated Flask, CSRF-aware clients, users and trip/expense fixtures. |
| [api/tests/test_agent_signatures.py](api/tests/test_agent_signatures.py) | Verifies post-approval signing, immutable/private receipts, exact document versions/hashes and failure cases that must not unlock package tools. |
| [api/tests/test_ai_consent.py](api/tests/test_ai_consent.py) | Verifies consent revocation, deletion of preference/log/summary data and repeatable privacy operations. |
| [api/tests/test_auth_lifecycle.py](api/tests/test_auth_lifecycle.py) | Verifies signup/login, persistent device sessions, refresh renewal, logout isolation, validation and authentication error behavior. |
| [api/tests/test_auth_tokens.py](api/tests/test_auth_tokens.py) | Verifies refresh-token hashing, rotation and rejection/revocation behavior instead of storing readable refresh tokens. |
| [api/tests/test_canonical_catalog.py](api/tests/test_canonical_catalog.py) | Verifies empty catalog initialization, maintained schema selection, FTS updates, foreign keys and preservation/rollback of existing databases. |
| [api/tests/test_crew_expense_deletion.py](api/tests/test_crew_expense_deletion.py) | Verifies confirmed Crew expense deletion, ledger reversal, exact pending actions and authorization rechecks. |
| [api/tests/test_csrf.py](api/tests/test_csrf.py) | Verifies CSRF requirements for cookie-authenticated account, logout, refresh and related mutations. |
| [api/tests/test_demo_partner_setup.py](api/tests/test_demo_partner_setup.py) | Verifies separate demo supplier ownership and approval preserve staff identity without manufacturing agreement assent. |
| [api/tests/test_dev_reload.py](api/tests/test_dev_reload.py) | Verifies native migration/reload preparation is explicit and stays out of production. |
| [api/tests/test_endpoint_inventory.py](api/tests/test_endpoint_inventory.py) | Exercises previously fragile registered endpoints covering consent, chat read state, expenses, invitations, account operations and malformed inputs. |
| [api/tests/test_exchange_rates.py](api/tests/test_exchange_rates.py) | Verifies dated read-only rates, supported currency validation, caching, stale fallback and provider-failure behavior. |
| [api/tests/test_expense_group_lifecycle.py](api/tests/test_expense_group_lifecycle.py) | Verifies group ownership/membership, invitations, whole-ledger summaries and financial lifecycle invariants. |
| [api/tests/test_expense_friends.py](api/tests/test_expense_friends.py) | Verifies private contacts, invitation atomicity, nickname search and signup name resolution. |
| [api/tests/test_expense_realtime.py](api/tests/test_expense_realtime.py) | Verifies authenticated devices receive only authorized, committed expense-change notifications and lose access after removal. |
| [api/tests/test_expense_restore.py](api/tests/test_expense_restore.py) | Verifies soft-deleted expenses restore once with their identifiers, splits, balances, history and permissions preserved. |
| [api/tests/test_family_treasury_roles.py](api/tests/test_family_treasury_roles.py) | Verifies linked-treasury ownership, independent trip duties, viewer restrictions, date bounds and rollback on incomplete linking. |
| [api/tests/test_group_access_controls.py](api/tests/test_group_access_controls.py) | Verifies active membership and role requirements across exports, vault files and expense-group linking/summary reads. |
| [api/tests/test_group_planner_features.py](api/tests/test_group_planner_features.py) | Verifies poll lifecycle/voting, valid saved-stop behavior and related planner feature permissions. |
| [api/tests/test_group_planner_smoke.py](api/tests/test_group_planner_smoke.py) | Exercises representative UUID-based chat, checklist, place and planner endpoints against the migrated test application. |
| [api/tests/test_group_planner_tabs.py](api/tests/test_group_planner_tabs.py) | Verifies checklist metadata/assignment and group membership actions for viewer, member and owner roles. |
| [api/tests/test_idempotency.py](api/tests/test_idempotency.py) | Verifies request-key caller/method/path scoping, atomic reservations, replay and duplicate-request handling with an in-memory Redis substitute. |
| [api/tests/test_migration_contract.py](api/tests/test_migration_contract.py) | Verifies fresh schema parity, reversible/data-preserving upgrades, frozen baseline behavior and rejection of unsupported legacy/drifted identifier storage. |
| [api/tests/test_money_concurrency.py](api/tests/test_money_concurrency.py) | Verifies concurrent settlements, deletion and edits serialize financial validation and balance changes correctly. |
| [api/tests/test_money_integrity.py](api/tests/test_money_integrity.py) | Verifies split totals, participant/payer rules, edits and ledger/balance reversals retain exact monetary invariants. |
| [api/tests/test_p3_contracts.py](api/tests/test_p3_contracts.py) | Verifies deprecated route forwarding/method rules, configured health versions and JSON-safe activity/notification values. |
| [api/tests/test_package_review.py](api/tests/test_package_review.py) | Verifies private package submission/locking/corrections/approval, image validation, rights metadata and cross-package access restrictions using synthetic in-memory inputs. |
| [api/tests/test_partner_agreement.py](api/tests/test_partner_agreement.py) | Verifies faithful agreement import, protected original/text access and explicit reading evidence separate from signature. |
| [api/tests/test_partners.py](api/tests/test_partners.py) | Verifies isolated supplier authentication, application validation/version conflicts, verification and staff review lifecycle. |
| [api/tests/test_personal_finance.py](api/tests/test_personal_finance.py) | Verifies private personal income/expense lifecycle, currency separation, filtered reports and pagination. |
| [api/tests/test_phase1_contracts.py](api/tests/test_phase1_contracts.py) | Verifies response/profile/input contracts and invitation/chat lifecycle regressions from the first audit phase. |
| [api/tests/test_phase2_continued.py](api/tests/test_phase2_continued.py) | Verifies follow-up robustness for Crew parsing, exact AI mentions, untrusted prompt delimiting, cursor IDs and ingestion bounds. |
| [api/tests/test_phase2_contracts.py](api/tests/test_phase2_contracts.py) | Verifies bounded query parsing, itinerary filters, exact money rounding, access policy, date validation and calendar export contracts. |
| [api/tests/test_planner_catalog.py](api/tests/test_planner_catalog.py) | Verifies scoped geography/cards, selected catalog IDs, missing-catalog errors and map viewports without invented coordinates. |
| [api/tests/test_planner_live_security.py](api/tests/test_planner_live_security.py) | Verifies message authorship, private assistant cards, viewer restrictions and immediate revoked-room/data access across realtime transports. |
| [api/tests/test_security_hardening.py](api/tests/test_security_hardening.py) | Verifies trusted-proxy identity, safe correlation IDs and administrator-only route discovery. |
| [api/tests/test_staff_console.py](api/tests/test_staff_console.py) | Verifies employee-only staff sessions and isolation from traveler/supplier credentials and demo identities. |
| [api/tests/test_tour_drafts.py](api/tests/test_tour_drafts.py) | Verifies approved supplier access, private partial draft edits, version conflicts and cross-supplier isolation. |
| [api/tests/test_trip_crew_roles.py](api/tests/test_trip_crew_roles.py) | Verifies assigning/clearing trip responsibilities does not promote or change membership access roles. |
| [api/tests/test_trip_invitation_email_link.py](api/tests/test_trip_invitation_email_link.py) | Verifies trip invitation email points to a registered frontend acceptance route. |
| [api/tests/test_uuid_ids.py](api/tests/test_uuid_ids.py) | Verifies UUID field handling and UUID-native API/ORM operations while rejecting legacy integer identifiers. |
| [api/tests/test_websocket_auth.py](api/tests/test_websocket_auth.py) | Verifies Socket.IO authentication, UUID identities, group-room access and presence identifiers. |
