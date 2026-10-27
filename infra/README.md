# Infrastructure developer guide

Reviewed against GitHub `main` and the local infrastructure utilities on 2026-10-20. This guide documents **21 infrastructure files**, plus this README (22 files total), and explains their responsibilities, inputs and side effects. File paths are relative to `infra/`.

## Folder responsibilities

| Folder | Purpose |
|---|---|
| `docker/` | Local PostgreSQL, Redis, Flask API and optional Celery services, plus an environment example. |
| `github/workflows/` | Canonical CI and release definitions. GitHub executes their matching `.github/workflows/` discovery copies. |
| `terraform/` | Provisioning placeholder and decisions required before adding Terraform modules. |
| `tests/` | Launcher regressions and isolated catalog-export/Supabase-configuration tests. |
| `tools/` | Workspace checks, environment setup, contract/document generation, controlled data utilities and workflow synchronization. |

Each source/configuration file has a specific `Purpose:` comment. Update that comment and its guide entry when its responsibility changes. GitHub's last-commit column displays the latest commit touching a file; this update uses separate descriptive commits for each file. Folder rows inherit the latest child-file commit rather than an independent folder description.

## File index

| File | What it does | Inputs and effects |
|---|---|---|
| [docker/.env.example](docker/.env.example) | Documents local Compose PostgreSQL/password, application-secret and staff-email settings; the sample values are development placeholders. | Template only; real `.env` values remain ignored. |
| [docker/docker-compose.yml](docker/docker-compose.yml) | Runs local PostgreSQL, Redis and the Flask API with loopback ports and persistent data volumes; an optional workers profile starts Celery after API readiness. | Used by `start.py --docker`; starting Compose creates containers/volumes and initializes the API database. |
| [github/workflows/ci.yml](github/workflows/ci.yml) | Defines canonical CI dependency installation, workspace checks, generated API-contract verification and frontend artifact upload; sync its discovery copy with sync-workflows.mjs. | Installs dependencies, runs workspace verification and checks regenerated API declarations on CI triggers. |
| [github/workflows/deploy.yml](github/workflows/deploy.yml) | Verifies and migrates development/staging releases, then requires staged-commit evidence and administrator approval for production. | Environment-scoped credentials and `DATABASE_RELEASES_ENABLED` control activation; see the release guide. |
| [terraform/README.md](terraform/README.md) | Explains that Terraform provisioning is a placeholder, lists the hosting decisions needed before implementation, and links deployment guidance. | Documentation only; no resources are provisioned. |
| [tests/test_catalog_supabase_import.py](tests/test_catalog_supabase_import.py) | Tests PostgreSQL COPY escaping, supported canonical SQLite DDL conversion and stable export ordering with temporary or in-memory data; no remote database is contacted. | Uses in-memory SQLite and temporary COPY files; no remote database. |
| [tests/test_launcher.py](tests/test_launcher.py) | Tests start.py setup preservation, random secrets, process identity and owned-child cleanup, port/session reuse, child environments and reload recovery using mocks and temporary files. | Uses temporary workspace files and mocks for process/configuration behavior. |
| [tests/test_supabase_setup.py](tests/test_supabase_setup.py) | Tests password-safe database URL construction and useful SQLSTATE diagnostics with raw/encoded credential redaction; no Supabase connection is made. | Uses sample configuration and simulated errors; no remote database. |
| [tools/audit_supabase_security.py](tools/audit_supabase_security.py) | Reads public-schema RLS flags, Data API role privileges, duplicate index definitions, default ACLs and migration metadata, optionally writing a JSON report without reading application rows. | Reads ignored `services/api/.env.supabase`; connects to PostgreSQL metadata. `--output` writes a report. |
| [tools/check_python.py](tools/check_python.py) | Parses services/api Python files using the Python 3.11 grammar to catch syntax incompatible with CI and Docker; it does not import or execute those modules. | Reads backend source and reports Python 3.11 syntax failures; no imports or source writes. |
| [tools/check_structure.py](tools/check_structure.py) | Checks required workspace paths, exact workflow-copy synchronization, optional archive mappings and resolvable local Python/JavaScript/TypeScript imports. | Reads repository files; fails if canonical and discovery workflows differ byte-for-byte. |
| [tools/dev-env.ps1](tools/dev-env.ps1) | Creates or reuses the workspace .venv with the selected Python version and installs backend runtime/test requirements; start.py remains the full-project launcher. | Creates/reuses `.venv` and installs Python dependencies; requires the selected Python launcher version. |
| [tools/document_files.py](tools/document_files.py) | Inventories Git-visible project files, adds missing format-valid purpose headers and rewrites docs/files.md using description rules; strict JSON and binary files are described only in the guide. | Can change source headers throughout the repository and overwrite `docs/files.md`; review generated descriptions before committing. |
| [tools/render_expense_latency_report.py](tools/render_expense_latency_report.py) | Builds a self-contained filterable HTML table from the disposable expense benchmark summary. | Reads an explicit JSON input; writes the selected HTML output, defaulting to `docs/operations/expense-latency.html`; no network/database access. |
| [tools/export_openapi.py](tools/export_openapi.py) | Builds services/api/openapi.json from Flask routes and explicit admin/partner schemas using a migrated temporary SQLite database; unspecified response payloads remain unknown. | Migrates a disposable SQLite database under ignored `extra/build/schema-export/` and rewrites `services/api/openapi.json`. |
| [tools/import_catalog_supabase.py](tools/import_catalog_supabase.py) | Prepares canonical SQLite catalog snapshots, PostgreSQL DDL and COPY exports; explicit apply imports into a new private catalog schema and verifies ordered row hashes before commit. | Default prepares local exports under `.tripraft/catalog-supabase/`; `--check-schema` connects and rolls back DDL; `--apply` creates/populates a new catalog schema. |
| [tools/import_partner_agreement.py](tools/import_partner_agreement.py) | Extracts ordered paragraphs, tables and document furniture from a supplied DOCX, records its SHA-256 and preserves the original in the API agreement directory for review. | Takes an explicit DOCX path; writes extracted JSON and an original-document copy under `services/api/app/partners/agreements/`. |
| [tools/promote_enriched_catalog.py](tools/promote_enriched_catalog.py) | Builds and validates an enriched SQLite catalog preview against the canonical schema; explicit apply backs up and fills an empty target transactionally while preserving sequences and FTS data. | Requires a compatible enriched source and an empty canonical target. Default prepares `.tripraft/catalog-promotions/`; `--apply` backs up and fills the target. |
| [tools/setup_demo_partner.py](tools/setup_demo_partner.py) | Backs up a local development SQLite database, transfers an explicitly selected staff-owned demo application to a separate partner identity, and records approval without signing terms or granting staff access. | Requires an application UUID and existing staff reviewer; restricted to development SQLite under `data/runtime/`. Credentials/backups stay in ignored `.tripraft/`. |
| [tools/setup_supabase.py](tools/setup_supabase.py) | Builds TLS PostgreSQL URLs from ignored Supabase settings, checks connectivity by default, and supports offline migration SQL or explicit fresh-setup/upgrade actions with redacted errors. | Default connects and checks tables. `--sql PATH` exports migration SQL offline; `--apply` creates a fresh public application schema; `--upgrade` migrates an existing one. |
| [tools/sync-workflows.mjs](tools/sync-workflows.mjs) | Copies the canonical infra CI/deployment YAML files into .github/workflows so GitHub discovers the same definitions validated by the workspace checks. | Overwrites `.github/workflows/ci.yml` and `deploy.yml` with their canonical files. |
| [tools/validate_infra.py](tools/validate_infra.py) | Statically validates Compose build contexts, Dockerfiles, named/bind volumes and service dependencies plus workflow job/step structure; it does not start containers or deploy. | Reads Compose/workflow YAML and local paths. Static validation does not establish live Docker or hosting readiness. |

## Database release tools

Follow the [shared development and release guide](../docs/operations/database-releases.md)
or open its [interactive checklist](../docs/operations/database-release-checklist.html).

| File | Responsibility |
| --- | --- |
| [tools/deploy_database.py](tools/deploy_database.py) | Read-only migration planning by default; explicit authorized upgrades with target pins, session locking and schema verification. |
| [tools/request_development_migration.py](tools/request_development_migration.py) | Employee startup requests a fixed owner-approved development migration without general DDL credentials. |
| [sql/development/enable_approved_startup_migrations.sql](sql/development/enable_approved_startup_migrations.sql) | One-time owner installation of the development-only approved migration function. |
| [tools/check_release_gate.py](tools/check_release_gate.py) | Verify the selected environment, exact-commit staging evidence and production approval protections. |
| [tools/deploy_application.py](tools/deploy_application.py) | Send an exact commit SHA to the hosting adapter and wait for matching readiness. |
| [tests/test_database_releases.py](tests/test_database_releases.py) | Release credential isolation, provenance, workflow ordering and hosting verification regressions. |

## Common development checks

Run from the repository root with Python runtime/test dependencies installed. On Windows, use `.venv/Scripts/python.exe` in place of `python` when the virtual environment is not active.

```powershell
python infra/tools/check_python.py
python infra/tools/check_structure.py
python infra/tools/validate_infra.py
python -m pytest infra/tests -q
```

These checks validate source structure and isolated regressions. They do not run database setup, transfer catalog data, approve a demo supplier or call a hosting deployment hook.

## Workflow changes

Edit the canonical files under `infra/github/workflows/`, preserve the current trigger/job/dependency settings, then synchronize their GitHub discovery copies:

```powershell
node infra/tools/sync-workflows.mjs
```

Commit each canonical file and its discovery copy with a message describing its own role. `check_structure.py` requires the contents of each pair to match exactly. The current deployment verification job is named `release-verify`, and the deploy job depends on it.

## Operational tool prerequisites

The Supabase tools use the backend dependencies from `services/api/requirements.txt` and an ignored `services/api/.env.supabase` for live connections. That file supplies `SUPABASE_DB_HOST`, `SUPABASE_DB_USER`, `SUPABASE_DB_PASSWORD` and optional port/database-name settings. The URL builder requires TLS. Application schema setup uses the migrations checked into the same repository revision; it does not publish separate backend changes from a local checkout.

Catalog promotion/import tools require compatible local catalog inputs. The default enriched source under `script/data/catalog/` is a local input, not a file distributed by this infrastructure upload. Use explicit source/target paths appropriate to the operation. Publishing these utilities does not run their data-changing modes or change the API's selected database.

The older `remote-beta/` files and `tools/open-smartlog.ps1` still present in some local/develop checkouts were removed from GitHub `main`; this update preserves those removals. Python `__pycache__/`, actual environment files, generated exports, database snapshots and credentials are local artifacts excluded from publication.

## Commit notes

Keep commits focused on the file being documented and explain its actual responsibility. Examples:

```text
docs(infra/docker): explain local database, Redis, API and optional worker services
docs(infra/tools): describe workspace paths, workflow synchronization and import checks
test(infra): verify COPY escaping, canonical DDL conversion and export ordering
```

The table above describes files; commit messages describe changes to those files. Preserve Git history as the source of truth rather than recording example subjects as completed work.
