#requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'lindows'
$shimsDir = Join-Path $installRoot 'shims'

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
    $parts = $userPath -split ';' | Where-Object { $_ -and ($_ -ne $shimsDir) }
    [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
    Write-Host "[ok] Removed $shimsDir from User PATH"
}

$prof = $PROFILE.CurrentUserAllHosts
if (Test-Path -LiteralPath $prof) {
    $lines = Get-Content -LiteralPath $prof | Where-Object { $_ -notmatch 'Lindows\.psm1' -and $_ -ne '# Lindows' }
    Set-Content -LiteralPath $prof -Value $lines
    Write-Host "[ok] Removed Lindows hook from $prof"
}

if (Test-Path -LiteralPath $installRoot) {
    Remove-Item -LiteralPath $installRoot -Recurse -Force
    Write-Host "[ok] Removed $installRoot"
}

Write-Host "[ok] Lindows uninstalled."
