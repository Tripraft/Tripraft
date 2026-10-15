# Backend checkpoints and Interactive Smartlog

| Branch/bookmark | Checkpoint |
| --- | --- |
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
