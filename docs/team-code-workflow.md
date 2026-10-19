# Shared code history in Sapling

GitHub holds the shared code. Sapling Interactive Smartlog displays that history
on each developer's laptop. Everyone sees a pushed commit after fetching it;
uncommitted changes stay on the laptop where they were made.

Use `develop` for the shared beta, `feature/<topic>` for individual work, and
`main` for reviewed stable releases. A branch name alone does not certify tests,
review or deployment. Record the exact commit SHA when agreeing a final version.

## First setup on another laptop

Use a new empty destination so you do not overwrite existing local work:

```powershell
git clone https://github.com/deeppatel1842/Tripraft.git C:\Tripraft-Team
cd C:\Tripraft-Team
git switch develop
git log -1 --oneline
& "C:\Program Files\Sapling\sl.exe" web --port 8081 --no-app
```

Each developer needs individual access to the private GitHub repository and a
local Meta Sapling SCM installation. Use `sl.exe` in PowerShell; `sl` is also a
PowerShell alias. Open the local URL that Sapling generates. Never publish the
tokenized Smartlog URL on the internet.

## Refresh the agreed beta code

First check that local work is saved. If `git status` shows edits, commit them on
your feature branch or deliberately preserve them before switching branches.
With a clean working tree:

```powershell
git fetch origin --tags
git switch develop
git pull --ff-only origin develop
git log -1 --format="%h %an %ad %s" --date=iso
powershell -ExecutionPolicy Bypass -File infra\tools\open-smartlog.ps1
```

The commit SHA should match `origin/develop`. Refresh Smartlog if it was already
open. Select the commit to inspect files, before/after differences, author and
time. Fetching updates source history; run the project's setup/start commands
separately when you want to execute it locally.

## Submit new work

```powershell
git switch -c feature/your-topic
# Edit code, run relevant tests, and review git diff.
git add path/to/your/changed/file
git commit -m "Describe the behavior you changed"
git push -u origin feature/your-topic
```

Open a GitHub PR from the feature branch into `develop`. Review, resolve feedback
and merge after CI passes. Other developers then fetch the merged commit. The
configured Render beta deploys passing `develop` commits once connected.

When a stable release is approved, merge `develop` into `main` through a reviewed
PR and tag that exact known-good commit. Do not create a stable release tag until
the shared beta acceptance checks and database backup are recorded. A tag stores
code history; it does not back up database rows, uploads or secrets.

## What is separate

The HTML setup checklist is just a local guide. It is not the Smartlog interface
and does not share source code. The public beta is the running app; GitHub and
Sapling provide source history. Shared data comes from the hosted API/database,
not from cloning code or copying a development `.env`.
