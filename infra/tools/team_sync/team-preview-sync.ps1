param(
    [Parameter(Mandatory=$true)][string]$Preview,
    [Parameter(Mandatory=$true)][string]$EnvFile,
    [Parameter(Mandatory=$true)][string]$PythonExe,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$checker = Join-Path $PSScriptRoot "check-team-preview-schema.py"

foreach ($path in @($Preview, $EnvFile, $PythonExe, $checker)) {
    if (!(Test-Path -LiteralPath $path)) {
        throw "Required path missing: $path"
    }
}

# Never overwrite local changes.
$changes = @(git -C $Preview status --porcelain)
if ($LASTEXITCODE -ne 0 -or $changes.Count -gt 0) {
    throw "Preview contains changes. Update cancelled."
}

# Get approved code.
git -C $Preview fetch origin develop
if ($LASTEXITCODE -ne 0) {
    throw "GitHub fetch failed."
}

$current = (git -C $Preview rev-parse HEAD).Trim()
$latest = (git -C $Preview rev-parse origin/develop).Trim()

if ($current -eq $latest -and !$CheckOnly) {
    Write-Host "Already updated: $($current.Substring(0,7))"
    exit 0
}

# Reject rewritten Git history.
git -C $Preview merge-base --is-ancestor $current $latest
if ($LASTEXITCODE -ne 0) {
    throw "Git history changed. Manual review required."
}

# Inspect incoming code without changing the preview.
$temp = Join-Path $env:TEMP (
    "tripraft-incoming-" + [guid]::NewGuid().ToString("N")
)
$created = $false

try {
    git -C $Preview worktree add --detach $temp $latest

    if ($LASTEXITCODE -ne 0) {
        throw "Temporary checkout failed."
    }

    $created = $true

    & $PythonExe $checker $temp $EnvFile

    if ($LASTEXITCODE -ne 0) {
        throw "Incoming code is incompatible with Supabase."
    }

    if ($CheckOnly) {
        Write-Host "PASS - Incoming code verified. Preview unchanged."
    }
    else {
        git -C $Preview switch --detach --quiet $latest

        if ($LASTEXITCODE -ne 0) {
            throw "Preview update failed."
        }

        Write-Host "Preview updated: $($latest.Substring(0,7))"
    }
}
finally {
    if ($created) {
        git -C $Preview worktree remove --force $temp

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Temporary checkout cleanup needs review."
        }
    }
}
