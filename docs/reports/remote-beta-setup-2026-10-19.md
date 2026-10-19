# Remote beta setup verification

Reviewed `TripRaft_Remote_Beta_and_Sapling_Interactive_Smartlog_Setup.docx` and
implemented a same-origin hosted beta configuration, optional Gmail/Resend HTTPS
email delivery, explicit inline invitation delivery without a worker, a private configuration wizard, a local checklist and a Sapling
launcher. Added `develop` to both canonical and discovery CI workflow push triggers.

The user has Gmail and does not yet have the proposed cloud service accounts.
The deployment therefore defaults to Gmail API OAuth rather than requiring a new
email provider account and custom domain. Local SMTP remains available.

Verification completed:

- Full backend suite: 490 passed. This run began before the final Gmail and queue-configuration tests
  were added; the final focused rerun below covers those changes.
- Latest focused beta/invitation suite: 25 passed, including both Gmail mailer paths,
  OAuth failure handling, MIME encoding, secret-log protection and hosted SPA routes.
- Web production build passed using repository-pinned pnpm. Existing chunk-size
  advisory remains; it did not fail the build.
- Critical-error Ruff checks passed for API app/tests and beta scripts.
- Repository structure and existing infrastructure validators passed.
- Beta YAML paths, Free plan, develop branch and secret prompts checked locally.
- Interactive checklist executed in jsdom: public settings update, checkboxes save
  progress, and credential-bearing URLs are rejected from saved state and output.
- The private beta file path is ignored by Git. The configuration wizard fails
  clearly when no credentials file exists; no private beta file was created.

Not executed:

- Local Docker/Linux image build: Docker CLI is unavailable on this laptop. A
  GitHub CI image-build and asset/secret-exclusion job was added for develop.
- Cloud provisioning, PostgreSQL beta migrations, Redis TLS connection and Gmail
  OAuth authorization: the user has not created/configured those accounts yet.
- Actual email delivery and cross-country invitation/realtime acceptance.
- Visual browser QA: the computer-use inventory exposed no available browsers.

No claim of a live or fully accepted hosted beta is made. Runtime uploads on
Render Free are ephemeral; staff-console hosting, workers and durable uploads are
outside this Blueprint. Reference catalogs are bundled separately from shared
operational data. Developer `.env`, existing accounts and runtime databases were
not migrated or replaced.
