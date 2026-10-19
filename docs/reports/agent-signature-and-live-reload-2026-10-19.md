# Agent-only signing after approval and local server recovery

Implemented 19 October 2026; checkpoint `agent-signature-live-reload`. Supersedes the earlier pre-submission reading-acknowledgment workflow in checkpoint `829fcfb8cc96`.

## Delivered

Application submission no longer requires agreement acknowledgment. Staff approve the business first. An approved agent then reads the supplied document and signs with full name, title, all eight Schedule F confirmations, authority, electronic-signature consent and explicit draft acknowledgment. No TripRaft signature is requested or implemented.

The server stores immutable agent-side evidence and its integrity hash against the exact document version/hash. A private downloadable JSON receipt records the signing event. Approval alone or a historical reading acknowledgment cannot open package tools: each list/create/read/save/copy request checks the current agent signature. Duplicate identical signing preserves the original event; mismatched versions or overwrite attempts fail. The source remains DRAFT, and paid/public commercial activation remains unavailable.

The approved demo uses a separate operator identity. Its staff account and password are unchanged. Verification did not submit or fabricate a live signature. The actual user-submitted demo signature was found, preserved and verified through the running staff receipt endpoint; its evidence hash matched. Generated passwords are not included in source or this report.

## Local server errors

The reported admin 500s were Vite proxy connection failures while the API reloaded (`ECONNREFUSED` / `ECONNRESET`), including the signature receipt route. Local web/admin proxies now return a structured **503** with a clear temporary-unavailability message. The staff console offers **Retry connection** and does not resubmit credentials, approvals or signatures automatically.

Native development reload now invokes the existing migration command before Flask initialization, retaining its pending-SQLite-backup behavior. It is explicitly limited to the launcher's development reload mode and does not migrate production startup. A repeated launcher waits briefly for a verified running reloader to recover before considering cleanup. Ownership checks and named failure reporting remain intact.

The browser extension `composer.preload.js` context-invalidated error is separate from the TripRaft server/proxy connection issue.

## Validation

Focused checks passed for approval-before-signing, strict consent, exact source and versions, receipt integrity/privacy, immutable retry behavior, new-policy re-signing, suspension and package gates; fresh/upgrade/downgrade SQLite migrations and offline PostgreSQL SQL; agent and staff UI; and launcher/reload behavior. Final checks passed: 459 API tests, 391 web tests across 43 suites, nine staff-console tests, and 19 launcher/reload checks; workspace lint/type checks, both frontend builds, structure and migration checks also passed.

Running HTTP checks verified web/admin/API 200, demo password login through the frontend proxy, the agent agreement, signature-dependent package access, authenticated staff approved-list/receipt 200 and anonymous staff access 401. Existing user-submitted evidence was preserved. Actual PostgreSQL execution, external signing-provider certification, signed-PDF generation, visual browser QA and commercial launch are not claimed.

## Next package release

`agent signature → private package wizard/media → submit immutable revision → staff approve → approved public projection → Places Search cards/details`.

Every new package starts with review. Later safe operational/copy updates can be automatic after classification/validation; material changes need review while the last approved version remains public. Media, immutable content submission/moderation and public Places Search package cards remain the next implementation stages; signing does not publish existing private drafts.
