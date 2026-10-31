#requires -Version 5.1
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'Lindows.psm1'
Import-Module $modulePath -Force -DisableNameChecking

$passed = 0
$failed = 0

function Assert-Equal($Name, $Actual, $Expected) {
    if ($Actual -eq $Expected) {
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $Name`n         Expected: [$Expected]`n         Actual:   [$Actual]" -ForegroundColor Red
        $script:failed++
    }
}

$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "lindows-test-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

try {
    $sampleFile = Join-Path $tmpDir 'lines.txt'
    [System.IO.File]::WriteAllLines($sampleFile, @('line1','line2','line3','line4','line5'))

    # head tests
    $h1 = (head -n 2 $sampleFile) -join ','
    Assert-Equal 'head -n 2 file' $h1 'line1,line2'

    $h2 = (head -n -3 $sampleFile) -join ','
    Assert-Equal 'head -n -3 file (exclude last 3)' $h2 'line1,line2'

    $h3 = ('a','b','c','d' | head -n 3) -join ','
    Assert-Equal 'head pipeline input' $h3 'a,b,c'

    # tail tests
    $t1 = (tail -n 2 $sampleFile) -join ','
    Assert-Equal 'tail -n 2 file' $t1 'line4,line5'

    $t2 = (tail -n +3 $sampleFile) -join ','
    Assert-Equal 'tail -n +3 file (from 3rd line)' $t2 'line3,line4,line5'

    $t3 = ('a','b','c','d' | tail -n 2) -join ','
    Assert-Equal 'tail pipeline input' $t3 'c,d'

    # which tests
    $w1 = which cmd
    Assert-Equal 'which cmd finds cmd.exe' ($w1 -match 'cmd\.exe$') $true

    # tree tests
    $subDir = Join-Path $tmpDir 'sub'
    New-Item -ItemType Directory -Path $subDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $subDir 'a.txt'), 'hello')
    $tr = (tree --charset=ascii $tmpDir) -join "`n"
    Assert-Equal 'tree lists files and directories' ($tr -match '1 directories, 2 files') $true

    # man tests
    $m1 = (man -f head) -join ''
    Assert-Equal 'man -f head summary' ($m1 -match 'head - output the first part of files') $true

    # lindows meta
    $l1 = (lindows --version) -join ''
    Assert-Equal 'lindows --version' $l1 'lindows 1.0.0'
} finally {
    Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nSummary: $passed passed, $failed failed."
if ($failed -gt 0) { exit 1 }
