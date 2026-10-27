# TripRaft

TripRaft is a travel workspace with a React traveler app, a separate staff console and a Flask API. It includes collaborative trip planning, place discovery, shared expenses and private tour-operator onboarding/package review. Catalog-backed features and external integrations require their own configured inputs.

## Start locally

Install Python 3.11 and Node.js 22 or newer. From the repository root:

```powershell
python start.py --setup
python start.py
```

On Windows, use `py -3.11` if needed. Setup installs the pinned pnpm version, workspace dependencies and the API virtual environment, then creates local settings. Startup runs the API, web app and staff console:

| Application | Local URL |
|---|---|
| Traveler web app | http://127.0.0.1:5173 |
| Staff console | http://127.0.0.1:5174 |
| Flask API | http://127.0.0.1:5000 |

Keep the launcher terminal open; Ctrl+C stops its processes. Use `python start.py --stop` to stop a previous launcher session. See [startup and recovery](docs/setup/startup.md) for Docker mode, health checks and troubleshooting.

## Repository map

| Folder or file | Responsibility | Developer guide |
|---|---|---|
| `apps/web/` | Traveler UI, authentication, discovery, trip planning, expenses and operator portal. | [All app files](apps/README.md) |
| `apps/admin/` | Staff authentication, supplier applications, agreements and package review. | [All app files](apps/README.md) |
| `services/api/` | Flask routes, domain logic, persistence, migrations, catalogs and backend regressions. | [Service layout and every file](services/README.md) |
| `packages/` | Shared API client, contracts, UI and development configuration. | [Every package file](packages/README.md) |
| `infra/` | Docker topology, canonical workflows, checks and maintenance tools. | [Every infrastructure file](infra/README.md) |
| `.github/` | GitHub workflow discovery copies, ownership and contributor context. | [Workflow ownership](infra/README.md) |
| `docs/` | Current developer guides, design proposals and archived Markdown reports. | [Documentation index](docs/README.md) |
| `start.py` | Native/Docker setup, process startup, readiness and shutdown. | [Startup](docs/setup/startup.md) |
| Workspace manifests and lockfile | pnpm package discovery, locked dependencies and Turbo tasks. | [Complete file inventory](docs/files.md) |

`services/api/app/` is the Python code package inside the API project. Its domain `services/` directories hold business logic in the same process. The [service guide](services/README.md#why-servicesapiapp-exists) explains why these names are intentional.

## Data and configuration

The published source excludes `data/`, `wikidata/` and the four root-level planning PDF/Word originals. Local copies remain on the development machine. Removing tracking does not erase earlier Git history. Database schemas and migration code stay published.

Startup creates an empty canonical catalog and a separate application database; it does not load travel records. Supply compatible catalog data separately and configure the API before using catalog-backed discovery and planner features. See [local catalog setup](services/README.md#local-catalog-setup).

Real `.env` values, uploaded files, dependencies, caches, builds and process logs remain local. `.env.example` files document settings. SMTP, AI providers and external services require configured credentials; Redis-dependent workers require Redis. Staff access requires an active verified account permitted by `ADMIN_EMAILS`; see [staff access](docs/guides/staff-console.md) and [email setup](docs/setup/email.md).

The agreement DOCX under the partner service remains because authenticated endpoints offer its original attachment. Dated Markdown evidence is indexed in [the documentation archive](docs/archive/README.md); raw CSV/JSON/ZIP audit exports stay local. See [what is required versus optional](docs/repository-review.md).

## Development checks

After setup, make the virtual environment and launcher-installed pnpm available on your shell PATH, as described in [startup](docs/setup/startup.md#checks-and-recovery), then run:

```powershell
pnpm verify
```

This runs structure/infrastructure checks, lint, type checks, tests and builds. For backend-only changes, from `services/api/` with the project Python environment:

```powershell
python -m pytest -q
python -m ruff check app tests
```

Backend tests use temporary databases and synthetic inputs. Canonical CI/deployment workflow definitions live under `infra/github/workflows/`; after editing them, run `pnpm workflows:sync` to update `.github/workflows/`.

## Further documentation

- [Architecture](docs/architecture/overview.md) and [API conventions](docs/api/README.md)
- [Service file guide](services/README.md), [apps](apps/README.md), [packages](packages/README.md), [infrastructure](infra/README.md)
- [Published file inventory](docs/files.md) and [repository usefulness review](docs/repository-review.md)
- [Operator agreements](docs/guides/partner-agreement.md), [map setup](docs/setup/maps.md) and [operations runbook](docs/operations/runbook.md)
- [Shared development and database releases](docs/operations/database-releases.md) · [Interactive release checklist](docs/operations/database-release-checklist.html)

Planning documents describe proposed work; historical reports record results at their stated dates. Neither implies that every planned capability or external deployment is currently enabled.
