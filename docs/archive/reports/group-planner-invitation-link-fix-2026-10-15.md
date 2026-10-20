# Group Planner email invitation links - October 15, 2026

> Historical report. Results, local accounts, file counts and open findings describe the original checkpoint. For current setup and contracts, use the [documentation index](../../README.md). Raw CSV/JSON/ZIP exports referenced here are preserved locally and in earlier Git history; they are not current repository inputs.

Interactive Smartlog checkpoint: `group-planner-invitation-link-fix`.

Opening an emailed `/trips/invite/<invitation-id>` link rendered a blank page
because the application had no matching route. SMTP also generated
`/expenses/invite/<id>` links while the registered expense invitation route was
`/invitation/<id>`.

The app now supports both old email URL formats. New emails use the existing
canonical routes: `/invitations/<id>` for trip invitations and `/invitation/<id>`
for expense invitations. Invitation dispatch recognizes the old trip URL as a
group invitation without probing the expense API.

The group acceptance page now waits for authentication to finish restoring.
Signed-out visitors return through sign-in or sign-up with `type=group`, so they
cannot be sent to the expense invitation flow. Auth forms preserve that type
without caching the trip ID as an expense invitation.

Once signed in, the page checks invitation details and the recipient email
before accepting. A shared in-flight operation survives React StrictMode's
effect replay without submitting acceptance twice. Invalid, expired, declined,
and wrong-account invitations display messages and recovery controls. Already
accepted invitations open the group without another acceptance POST. Retry
reloads details, allowing recovery when a prior response was lost.

Successful acceptance refreshes the group/member query caches, clears matching
pending invitation storage, and opens `/group-planner/<group-id>`. The old
`?group=` redirect was not handled by the current planner's route selection.

## Validation and save

- Full frontend suite: 321 tests across 35 suites passed, including legacy
  email routing, auth continuation, StrictMode, recipient mismatch, missing and
  expired links, already accepted links, and exact group navigation.
- Targeted API suite: 25 tests passed, including SMTP HTML/plain-text URL checks,
  invitation creation/acceptance, expiry, and endpoint regressions. SMTP was
  mocked; no email was sent by these checks.
- Web lint, TypeScript, production build, backend Ruff, and Git whitespace
  checks passed. The existing bundle-size and deprecation warnings remain.
- Headless Chromium opened the user's exact old email URL in an isolated,
  signed-out session. It rendered sign-in and preserved the group invitation
  through sign-up on mobile. A mocked signed-in recipient accepted once and
  navigated to the exact group route, with no uncaught browser errors.
- No real invitation was accepted, resent, or changed during verification.

Scripts, browser results, screenshots, and logs are retained in ignored
`.tripraft/test-temp/group-planner-ui/`. The fix is saved locally in the shared
Git/Sapling history and verified through Interactive Smartlog. There is no
remote push or deployment. Previously sent links work without sending new email.
