# TripRaft

[![Repository](https://img.shields.io/badge/GitHub-deeppatel1842%2FTripraft-blue)](https://github.com/deeppatel1842/Tripraft)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB)](https://python.org)
[![Node](https://img.shields.io/badge/Node-22%2B-339933)](https://nodejs.org)
[![Vite](https://img.shields.io/badge/Frontend-React%20%7C%20Vite-646CFF)](https://vitejs.dev)
[![Flask](https://img.shields.io/badge/Backend-Flask%20%7C%20SQLAlchemy-000000)](https://flask.palletsprojects.com)

TripRaft is a modern, collaborative travel platform that brings together trip planning, global place discovery, shared expense splitting, and a verified tour-operator partner ecosystem with an internal staff operations review console.

---

## Key Features

- **Global Place Discovery**: Searchable travel destination catalog with SQLite FTS5 full-text indexing, categorized by country, state, and city, backed by interactive OpenFreeMap day and night map styles.
- **Collaborative Group Trip Planner**: Real-time group travel workspace featuring shared itineraries, route previews, packing checklists, draggable group chat, interactive voting/polls, and Crew Responsibilities (Treasurer, Navigator, Culture Scout).
- **Treasury & Expense Splitting**: Multi-currency expense ledger, exact receipt splitting, balance tracking, and real-time synchronization across member devices.
- **Tour-Operator Partner Portal**: Operator registration, email verification, digital agreement signing workflow, private tour package drafts, and media uploads with explicit usage rights.
- **Staff Operations & Review Console**: Dedicated internal console for business application vetting, package content review, correction requests, and immutable audit trails.
- **Zero-Friction Local Launcher**: Native single-command launcher (`python start.py`) managing API, Web, and Admin processes with clean graceful shutdown, port lifecycle protection, and optional Docker support.

---

## Start the Project

### Prerequisites
- **Python 3.11**
- **Node.js 22 or newer**
- Windows, macOS, or Linux

### Running Locally (Native Mode)

From the project root:

```powershell
# First-time setup (installs virtualenv, pnpm, Python and Node dependencies)
python start.py --setup

# Start all TripRaft services (Web, Admin, API)
python start.py
```

> **Tip**: If `python` defaults to a different version on Windows, use `py -3.11 start.py`.

The launcher starts all services, checks health readiness, opens your browser, and manages child processes. When you're done, simply press **Ctrl+C** to stop all services and free the ports.

### Useful Launcher Commands

```powershell
python start.py --check               # Verify environment and prerequisites
python start.py --smoke --no-browser  # Full startup test, HTTP health check, then clean exit
python start.py --stop                # Stop lingering services and free ports 5000, 5173, 5174
python start.py --docker              # Run PostgreSQL, Redis, API and worker in Docker
```

---

## Service URLs

| Service / Page | Local URL | Description |
| :--- | :--- | :--- |
| **Traveler Web App** | [http://127.0.0.1:5173](http://127.0.0.1:5173) | Main public travel exploration and group trip planner |
| **Places Search** | [http://127.0.0.1:5173/places](http://127.0.0.1:5173/places) | Search destination catalog, view details and maps |
| **Partner Landing & Apply** | [http://127.0.0.1:5173/partners](http://127.0.0.1:5173/partners) | Tour operator onboarding and application submission |
| **Partner Login** | [http://127.0.0.1:5173/partners/login](http://127.0.0.1:5173/partners/login) | Verified operator portal sign-in |
| **Partner Dashboard** | [http://127.0.0.1:5173/partners/dashboard](http://127.0.0.1:5173/partners/dashboard) | Private package draft management and submission |
| **Staff Console** | [http://127.0.0.1:5174](http://127.0.0.1:5174) | Employee portal for business reviews and package approvals |
| **API Health Endpoint** | [http://127.0.0.1:5000/api/health/live](http://127.0.0.1:5000/api/health/live) | Liveness and health check probe |

> **Security Note**: Staff and agent identities have separate authentication contexts. The Staff Console is not linked from public pages and is restricted to accounts configured in the server's `ADMIN_EMAILS` setting.

---

## Tour-Operator Flow

```
1. Application  ──>  2. Staff Review  ──>  3. Agent Signs  ──>  4. Package Drafts  ──>  5. Review & Approval
(Operator applies    (TripRaft staff       (Agent digitally      (Private drafts,       (Staff review, corrections,
 & verifies email)    review business)      signs agreement)      media upload, submit)  or content approval)
```

1. **Application**: The operator applies via the **Partner with TripRaft** page and verifies their email.
2. **Staff Review**: Staff review the business credentials in the operations console (`:5174`).
3. **Digital Signing**: After approval, the agent signs the exact version of the digital partner agreement.
4. **Draft Preparation**: The approved, signed agent creates package drafts and uploads media with confirmed usage rights.
5. **Staff Package Review**: Staff inspect package submissions, request corrections, or approve. Submitted content remains immutable; corrections generate revision snapshots.

---

## Workspace Structure

```text
Tripraft/
├── apps/
│   ├── web/                     # React 18 / Vite public traveler app and partner portal
│   └── admin/                   # React 18 / Vite internal staff console for package/business reviews
├── services/
│   └── api/                     # Flask REST API, domain models, migrations, tests
│       └── schema/              # Canonical travel SQL schema (tripraft-global-schema-v2.1.sql)
├── packages/
│   ├── ui/                      # Shared React UI components
│   ├── api-client/              # OpenAPI TypeScript client & types
│   ├── types/                   # Shared TypeScript domain models & contracts
│   └── config/                  # Shared ESLint, Prettier, and TypeScript configurations
├── data/
│   ├── catalog/                 # Travel catalog databases and documentation
│   ├── runtime/                 # Runtime application SQLite databases (local & ignored)
│   └── seeds/                   # Demo fixtures and sample tour data
├── infra/
│   ├── docker/                  # Docker Compose configuration (PostgreSQL, Redis, API)
│   ├── github/workflows/        # Canonical CI/CD workflows
│   └── tools/                   # Workspace verification, OpenAPI export, and code utilities
├── docs/                        # Architecture, API specifications, and operational runbooks
├── start.py                     # Project supervisor: setup, start, stop, smoke check
└── package.json                 # Monorepo root scripts (pnpm workspace)
```

---

## Verification & Development Commands

With dependencies installed, run tests and verifications across the monorepo:

```powershell
# Run monorepo checks: linting, TypeScript typing, frontend and backend tests
pnpm verify

# Regenerate API contracts and TypeScript client from Flask OpenAPI
python infra/tools/export_openapi.py
pnpm api:generate

# Sync GitHub CI workflows
pnpm workflows:sync
```

---

## What Is Published to Git

- **Published**: Source code, frontend apps, Flask services, canonical schema (`services/api/schema/`), migrations, unit and integration tests, Docker configurations, CI workflows, application assets, and Markdown documentation.
- **Kept Local & Ignored**: Local runtime databases (`*.db`), `.env` secrets, virtual environments (`.venv`), temporary logs (`.tripraft/logs`), uploaded user media (`services/api/uploads/`), binary Office/Word source documents, and local scratch/data-processing workspaces (`script/`, `sql_database/`).

---

## Documentation Links

- [Startup Guide](docs/startup.md) - Detailed prerequisites, environment variables, and Docker usage.
- [Staff Console Guide](docs/staff-console.md) - Internal operations review process and security rules.
- [Partner Agreement Flow](docs/partner-agreement.md) - Operator digital signing architecture.
- [Places Search & Packages Plan](docs/plans/places-search-tour-packages/README.md) - Active roadmap and design specifications.
- [API Documentation](docs/api.md) - REST API endpoints and authentication specifications.
- [File Purpose Guide](docs/files.md) - Comprehensive index of monorepo source files.
