# Code-only GitHub publication and package review foundation

Prepared 19 October 2026 for the user's requested GitHub upload before further feature work.

## Publication contents

The updated README documents first setup, start/stop/check commands, local page URLs, live updates, permissions and the agent-to-review flow. Markdown plans/guides remain included. Original Office/PDF files and the `script` / `sql_database` workspaces are excluded from Git without removing local files. Databases, credentials, uploads and runtime signature evidence remain ignored.

The maintained canonical SQL schema now lives in `services/api/schema/`, with startup/tests/container context updated. Excluding the old SQL workspace therefore preserves fresh-checkout initialization. The app ships its reviewed agreement text and metadata as JSON; original Word files stay local. Authenticated agreement downloads fall back to complete text where Office originals are absent.

The publishing branch is based directly on the fetched GitHub base and contains the final code tree, so unpublished checkpoints containing the original Word binary are not sent to GitHub. Existing local Smartlog checkpoints are retained. No force-push or remote-history rewrite is required.

## Package review code included

Private image upload validates actual JPEG/PNG/WebP content, size/dimensions and explicit rights; re-encoding strips embedded metadata. Image files remain outside public static directories and require supplier ownership or staff authorization. Complete packages can submit a locked revision. Staff can approve, reject or request corrections; corrections create a new draft, and the previously submitted content remains unchanged. Version checks prevent stale decisions; duplicate packages receive their own image references.

The staff console includes a package-review queue and complete submission details. Agent previews include private images and an explicit submit action. Every new package initially requires review. Content approval does not publish a public Places Search card or enable bookings; public projections/pricing/inventory remain subsequent work.

The repository contains a complete five-day Kerala demo content fixture and original test illustration. Applying those fixtures to the live demo is the next task after the requested GitHub upload; this publication does not fabricate supplier inventory or submit a real agent signature.

## Verification

Focused API checks cover private media, image/rights validation, submission locking, immutable correction history, staff approval, duplicate image ownership, cross-package denial, migration parity/roundtrip, canonical startup and agreement operation without Office files. Web partner regressions, admin access/review tests, lint/types and frontend builds are checked before the push. The earlier signature checkpoint passed the complete 459-test API baseline; this report does not substitute that older count for a new full-suite run.

Local excluded-file integrity is checked before/after index removal. The publish tree and unpublished object list are checked for Office/PDF files, excluded workspace paths and private runtime files before pushing. Original files stay available locally.
