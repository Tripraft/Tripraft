# Partner agreement integration and local demo approval

Implemented 19 October 2026; local checkpoint `partner-agreement-demo-approval`. Historical workflow: the later [agent-only signing checkpoint](agent-signature-and-live-reload-2026-10-19.md) supersedes pre-submission acknowledgment and adds post-approval signing/dashboard enforcement.

## Delivered behavior

- Read the supplied v3.0 Word agreement in full, including tables, Master Terms §§1–24, Schedules A–F, both appendices, header and footer. Preserved the exact source bytes and added a deterministic ordered JSON import. This is a content review, not a Word layout review or legal sign-off.
- Added authenticated agent and staff readers and original-document downloads. The source's confidentiality and DRAFT status remain visible; the agreement is not a public static asset.
- Added separate, explicit draft-reading acknowledgment with current version/hash checks, verified-owner identity, CSRF, optimistic application version checks and append-only evidence. New application submissions require it. No prior application receives automatic assent.
- Added staff acknowledgment evidence and an explicit unsigned/commercial-inactive status. Private business approval does not become contract execution.
- Approved the user-identified demo for private testing through a separate reserved supplier login, preserving `tripraft@gmail.com` staff access and the HTTP prohibition on self-review. Ownership transfer, simulated local email verification and approval are audited. The demo is labeled throughout the portal and in staff review.
- Saved a fictional three-day private package draft through the running API. It cannot be submitted/published or sold in the current feature.
- Migrated the local database to `c30d4e5f6071` after a consistent backup; created a separate pre-demo-approval backup. Native website/admin/API services run with source reload enabled.

## Files

| Area | Files |
| --- | --- |
| Original policy and content | `services/api/app/partners/agreements/partner-agreement-v3-2026-10-18.{docx,json}` |
| Reading/evidence services | `services/api/app/partners/agreement_service.py`, existing `models.py`, `routes.py`, `schemas.py`, `services.py` |
| Schema | `services/api/migrations/versions/c30d4e5f6071_partner_agreement.py`, model registration in `migrations/env.py` |
| Agent experience | `PartnerAgreement.tsx`, `PartnerPortal.tsx`, `partnerApi.ts`, `partners.css` in `apps/web/src/features/partners/` |
| Staff experience | `apps/admin/src/PartnerAgreementPanel.tsx`, `PartnerReviewPanel.tsx` |
| Contracts | `packages/types/src/partners.ts`, `index.ts`, OpenAPI exporter/spec and generated API schema |
| Local tools | `infra/tools/import_partner_agreement.py`, `infra/tools/setup_demo_partner.py` |
| Verification | Agreement/demo API tests, partner/migration tests, agent reader/API tests and staff review tests |
| Documentation | Agreement guide, active plan updates, API/staff guides, checkpoint index and published file guide |

## Verification

Final verification: **443 API tests**, **389 web tests across 43 suites**, and **8 staff-console tests across two suites** passed. Workspace lint (six tasks), types/Python syntax (five tasks), both production frontend builds, import/structure checks and static infrastructure validation passed. The native launcher smoke check reused the healthy running services. Test databases are disposable; no tests deliver email or accept/sign the agreement for the live demo.

- Source fidelity and exact authenticated download bytes; anonymous/traveler/supplier/staff access boundaries.
- Explicit checkbox, false/string/numeric rejection, CSRF, stale application version, incorrect document hash, current acknowledgment submission requirement, idempotent evidence and no retroactive assent.
- Separate demo owner/staff membership, audit snapshots, preserved staff password, no staff role for the demo and no signature/acknowledgment creation.
- Fresh SQLite migrations, schema parity, existing-application preservation, downgrade/reinstall and offline PostgreSQL DDL generation.
- Native HTTP: demo password login, APPROVED + demo capabilities, private draft create/save/read, policy read/download, web/Places/admin shells, and denial of staff APIs to the demo. Logged out the verification session afterward.

Actual PostgreSQL execution, visual browser review, Docker deployment, final contract execution and paid booking workflows are not claimed.

## Remaining work

Continue phase two with private media storage/validation, immutable package submission and staff moderation, then the approved public projection inside Places Search. Agreement execution requires completed commercial/legal inputs, both signatures and evidence storage before any commercial activation. The source's example commissions/GST/service targets remain examples, not configured business rules.

Generated credentials, SQLite backups, runtime state, logs and live sample data remain ignored local files. Related source, original policy, tests, generated contracts and documentation are saved in Smartlog; unrelated catalog scripts and datasets are left untouched.
