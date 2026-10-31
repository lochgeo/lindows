#requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$NoProfile,
    [switch]$NoPath,
    [switch]$SkipExtras
)

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'lindows'
$srcDir = Join-Path $installRoot 'src'
$shimsDir = Join-Path $installRoot 'shims'

New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
New-Item -ItemType Directory -Path $srcDir -Force | Out-Null
New-Item -ItemType Directory -Path $shimsDir -Force | Out-Null

$srcFiles = @(
    'common.ps1'
    'grep.ps1'
    'find.ps1'
    'head.ps1'
    'tail.ps1'
    'wc.ps1'
    'touch.ps1'
    'fs.ps1'
    'proc.ps1'
    'which.ps1'
    'tree.ps1'
    'man.ps1'
    'meta.ps1'
)

if ($PSScriptRoot -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'Lindows.psm1'))) {
    Write-Host "[..] Installing Lindows from local directory..."
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Lindows.psm1') -Destination $installRoot -Force
    Copy-Item -Path (Join-Path $PSScriptRoot 'src\*.ps1') -Destination $srcDir -Force
} else {
    Write-Host "[..] Downloading Lindows from GitHub..."
    $baseUrl = 'https://raw.githubusercontent.com/lochgeo/lindows/main'
    Invoke-RestMethod -Uri "$baseUrl/Lindows.psm1" -OutFile (Join-Path $installRoot 'Lindows.psm1')
    foreach ($f in $srcFiles) {
        Invoke-RestMethod -Uri "$baseUrl/src/$f" -OutFile (Join-Path $srcDir $f)
    }
}

$shimCommands = @{
    'grep'    = 'Invoke-LindowsGrep'
    'find'    = 'Invoke-LindowsFind'
    'head'    = 'Invoke-LindowsHead'
    'tail'    = 'Invoke-LindowsTail'
    'wc'      = 'Invoke-LindowsWc'
    'touch'   = 'Invoke-LindowsTouch'
    'cat'     = 'Invoke-LindowsCat'
    'rm'      = 'Invoke-LindowsRm'
    'lsof'    = 'Invoke-LindowsLsof'
    'pkill'   = 'Invoke-LindowsPkill'
    'killall' = 'Invoke-LindowsPkill'
    'which'   = 'Invoke-LindowsWhich'
    'tree'    = 'Invoke-LindowsTree'
    'man'     = 'Invoke-LindowsMan'
    'lindows' = 'Invoke-LindowsMeta'
}

foreach ($cmd in $shimCommands.Keys) {
    $fn = $shimCommands[$cmd]
    $shimPath = Join-Path $shimsDir "$cmd.cmd"
    $shimBody = @"
@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '%LOCALAPPDATA%\lindows\Lindows.psm1' -DisableNameChecking; $fn %*; exit `$LASTEXITCODE"
"@
    [System.IO.File]::WriteAllText($shimPath, $shimBody, [System.Text.Encoding]::ASCII)
}

$clearShim = Join-Path $shimsDir 'clear.cmd'
[System.IO.File]::WriteAllText($clearShim, "@echo off`r`ncls`r`n", [System.Text.Encoding]::ASCII)

if (-not $NoPath) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = if ($userPath) { $userPath -split ';' | Where-Object { $_ } } else { @() }
    if ($parts -notcontains $shimsDir) {
        $newPath = ($parts + $shimsDir) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        $env:Path = "$env:Path;$shimsDir"
        Write-Host "[ok] Added $shimsDir to User PATH"
    } else {
        Write-Host "[ok] $shimsDir already in User PATH"
    }
}

if (-not $NoProfile) {
    $prof = $PROFILE.CurrentUserAllHosts
    $profDir = Split-Path -Parent $prof
    if (-not (Test-Path -LiteralPath $profDir)) {
        New-Item -ItemType Directory -Path $profDir -Force | Out-Null
    }
    $hookLine = "Import-Module `"$installRoot\Lindows.psm1`" -DisableNameChecking"
    $existing = if (Test-Path -LiteralPath $prof) { Get-Content -LiteralPath $prof -Raw -ErrorAction SilentlyContinue } else { '' }
    if ($existing -notmatch 'Lindows\.psm1') {
        Add-Content -LiteralPath $prof -Value "`r`n# Lindows`r`n$hookLine"
        Write-Host "[ok] Added Lindows import to $prof"
    } else {
        Write-Host "[ok] PowerShell profile already imports Lindows"
    }
}

if (-not $SkipExtras) {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($winget) {
        foreach ($pkg in @('Microsoft.Coreutils', 'BurntSushi.ripgrep.MSVC')) {
            Write-Host "[..] Ensuring $pkg is installed via winget..."
            & winget.exe install --id $pkg --exact --accept-source-agreements --accept-package-agreements
        }
    } else {
        Write-Host "[warn] winget not found; skipping Microsoft.Coreutils and ripgrep install."
    }
}

Import-Module (Join-Path $installRoot 'Lindows.psm1') -Force -DisableNameChecking -Global
Write-Host "[ok] Lindows installed to $installRoot"
