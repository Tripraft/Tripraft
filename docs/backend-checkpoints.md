# Backend checkpoints and Interactive Smartlog

| Branch/bookmark | Checkpoint |
| --- | --- |
| `unified-marketplace-phase-0` | Start the marketplace implementation with catalog inventory, consistent SQLite snapshots/restore verification, reproducible baseline evidence and commercial decision records; [phase-zero report](reports/marketplace-phase0-baseline-2026-10-18.md) |
| `personal-finance-backend` | Personal income, expense edits/deletion, balances and analytics; `43990e456750` |
| `group-expenses-backend` | Descendant checkpoint for group lifecycle, invitations, permissions and group ledger/reporting |
| `group-expenses-create-fix` | Fix expense group creation HTTP 422, show validation details, and verify form/API contracts; [findings](reports/expense-group-creation-fix.md) |
| `group-invitation-email-fix` | Report actual email status, expose copyable invitation links, and align email links with the registered route; [findings](reports/expense-invitation-email-fix.md) |
| `group-invitation-link-fix` | Fix the missing details endpoint and copied-link sign-in flow; remove the delivery banner and keep copy-link controls; [findings](reports/expense-invitation-link-fix.md) |
| `group-invitation-delivery-navigation-fix` | Correct local Gmail setup, verify SMTP authentication, retry pending invitation email, and open the joined group after login/signup; [findings](reports/expense-invitation-delivery-navigation-fix.md) |
| `email-verification-page-fix` | Add the missing public verification page with success, invalid/expired link, retry and explicit resend behavior; [findings](reports/email-verification-page-fix.md) |
| `group-expense-permissions-audit` | Align owner/admin/member controls, expose settlement reversal and group management, fix one-cent and complete-ledger visibility, and hide revoked cached data; [findings](reports/group-expense-permissions-audit.md) |
| `group-planner-features-fix` | Repair empty-catalog startup and Group Planner polls, live updates, complete lists, place payloads, calendar days, trip dates, checklist feedback and dashboard navigation; [complete report](reports/group-planner-feature-fixes-2026-10-14.md) |
| `group-planner-ui-refresh` | Integrate the supplied travel workspace design with the existing Group Planner APIs, responsive group hub, shared itinerary/map day selection, stop creation, night map, chat/polls drawer, and quick search; [report](reports/group-planner-ui-refresh-2026-10-14.md) |
| `group-planner-tabs-refresh` | Preserve the shared Tripraft header, complete all six planner tabs, add isolated demo trips and role previews, and enforce checklist/invitation permissions; [report](reports/group-planner-tabs-refresh-2026-10-15.md) |
| `group-planner-catalog-library` | Use tripraft_places.db for country/state/city choices and scoped Library cards; add optional comma-separated invitations and remove the chat-input poll shortcut; [report](reports/group-planner-catalog-library-2026-10-15.md) |
| `group-planner-invitation-link-fix` | Support emailed trip invitation URLs, preserve group type through authentication, accept once and open the exact group; [report](reports/group-planner-invitation-link-fix-2026-10-15.md) |
| `group-planner-crew-responsibilities` | Owner/admin assignments for Treasurer, Navigator, and Culture Scout alongside access roles, with persistent API/schema support and demo views; [report](reports/group-planner-crew-responsibilities-2026-10-15.md) |
| `group-planner-map-key-setup` | Historical CARTO Basemaps key setup, superseded by the OpenFreeMap checkpoint below |
| `group-planner-openfreemap` | OpenFreeMap day/night maps without a key, scoped country/state/city focus using catalog coordinates, and missing-location handling; [setup guide](group-planner-map-setup.md), [report](reports/group-planner-openfreemap-2026-10-16.md) |
| `group-planner-family-currency-refresh` | Family roles, Treasurer ownership, Library sections, chat menus, group actions, secure live updates and daily currency estimates; [planner audit](reports/group-planner-library-live-audit-2026-10-16.md), [currency/error report](reports/group-planner-currency-errors-2026-10-16.md) |
| `group-planner-compact-settings-sync` | Compact currency controls, linked settings/display sync, owner/admin member removal and persistent session-aware sockets; [report](reports/group-planner-compact-settings-sync-2026-10-17.md) |

Each checkpoint has an explanatory commit message. API contracts are documented
in [personal finance](personal-finance-api.md) and [group finance](group-finance-api.md).
Changes remain local until a separate publish/push request.

Sapling reads this repository's shared `.git` history. The current system build
can read commits and run Interactive Smartlog, but mutation commands can fail
with a missing `journal` on Windows. The previously documented pinned workspace
Sapling executable is absent. These checkpoints were therefore committed with
Git and verified through Sapling against the same shared repository.

In PowerShell, use the full executable path because `sl` aliases `Set-Location`:

```powershell
& 'C:/Program Files/Sapling/sl.exe' smartlog
& 'C:/Program Files/Sapling/sl.exe' web --no-open --json
```

The second command starts or reconnects to the local Interactive Smartlog server.
Open the returned `url` to inspect checkpoint comments, diffs and branch history.
Do not store its authentication token in tracked files. The current session's
server details are in ignored `.tripraft/smartlog-current.json`.
