# Purpose: Open local Sapling Interactive Smartlog without the PowerShell sl alias or public binding.
param([int]$Port = 8081)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$saplingCommand = Get-Command sl.exe -ErrorAction SilentlyContinue
$saplingPath = if ($saplingCommand) { $saplingCommand.Source } else { Join-Path $env:ProgramFiles 'Sapling/sl.exe' }
if (-not (Test-Path -LiteralPath $saplingPath)) { throw 'Install Meta Sapling SCM for Windows first.' }
Push-Location -LiteralPath $projectRoot
try {
    & $saplingPath web --port $Port --no-app
    if ($LASTEXITCODE -ne 0) { throw 'Sapling failed; check its message above.' }
} finally { Pop-Location }
