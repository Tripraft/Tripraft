# Backend checkpoints and Interactive Smartlog

| Branch/bookmark | Checkpoint |
| --- | --- |
| `personal-finance-backend` | Personal income, expense edits/deletion, balances and analytics; `43990e456750` |
| `group-expenses-backend` | Descendant checkpoint for group lifecycle, invitations, permissions and group ledger/reporting |
| `group-expenses-create-fix` | Fix expense group creation HTTP 422, show validation details, and verify form/API contracts; [findings](reports/expense-group-creation-fix.md) |

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
