# Purpose: Creates or reuses the workspace .venv with the selected Python version and installs backend runtime/test requirements; start.py remains the full-project launcher.
<# Optional backend-only setup; start.py provides the complete project launcher. #>
[CmdletBinding()]
param([string]$PythonVersion = '3.11')
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$taskVenv = [System.IO.Path]::GetFullPath((Join-Path $taskRoot '.venv'))
if (-not $taskVenv.StartsWith($taskRoot + '\')) { throw 'Environment path escapes workspace' }
if (-not (Test-Path -LiteralPath (Join-Path $taskVenv 'Scripts/python.exe'))) {
    & py "-$PythonVersion" -m venv $taskVenv
    if ($LASTEXITCODE -ne 0) { throw 'Python environment creation failed' }
}
$taskPython = Join-Path $taskVenv 'Scripts/python.exe'
& $taskPython -m pip install -r (Join-Path $taskRoot 'services/api/requirements.txt') -r (Join-Path $taskRoot 'services/api/requirements-dev.txt')
if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed' }
Write-Output "Activate: $taskVenv/Scripts/Activate.ps1"
Write-Output 'Run pnpm install --frozen-lockfile from the repository root.'
