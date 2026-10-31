function Invoke-LindowsClear {
    Clear-Host
    $global:LASTEXITCODE = 0
}

function Invoke-LindowsMeta {
    $ArgLine = @($args)
    $cmd = if ($ArgLine.Count -gt 0) { $ArgLine[0].ToLower() } else { '' }

    switch ($cmd) {
        '' {
            Write-Output @"
Lindows $script:LindowsVersion - Linux commands for Windows (PowerShell + CMD).
Provided: grep, head, tail, which, tree, man, clear, lindows
Use 'lindows list', 'lindows doctor', or '<command> --help'.
"@
            $global:LASTEXITCODE = 0
        }
        'list' {
            Write-Output @"
grep     - search for patterns in files or input
head     - output the first part of files
tail     - output the last part of files
which    - locate commands on PATH
tree     - recursive directory tree
man      - manual pages (embedded) + PowerShell pointers
clear    - clear terminal screen
lindows  - meta command (list / doctor)
"@
            $global:LASTEXITCODE = 0
        }
        'doctor' {
            Show-LindowsDoctor
        }
        '--help' {
            Write-Output "Usage: lindows [list|doctor|--version|--help]"
            $global:LASTEXITCODE = 0
        }
        '--version' {
            Write-Output "lindows $script:LindowsVersion"
            $global:LASTEXITCODE = 0
        }
        default {
            [Console]::Error.WriteLine("lindows: unknown command '$cmd' (try: list, doctor, --help)")
            $global:LASTEXITCODE = 1
        }
    }
}

function Show-LindowsDoctor {
    $homeDir = Join-Path $env:LOCALAPPDATA 'lindows'
    $ok = $true
    Write-Output "doctor - lindows install check"

    if (Test-Path (Join-Path $homeDir 'Lindows.psm1')) {
        Write-Output "  [ok]    install present: $homeDir"
    } else {
        Write-Output "  [fail]  install directory missing: $homeDir - run .\install.ps1"
        $ok = $false
    }

    $pathEntry = Join-Path $homeDir 'shims'
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -and $userPath -like "*$pathEntry*") {
        Write-Output "  [ok]    PATH contains: $pathEntry"
    } else {
        Write-Output "  [fail]  PATH missing shims folder: $pathEntry - run .\install.ps1"
        $ok = $false
    }

    $prof = $PROFILE.CurrentUserAllHosts
    if ((Test-Path $prof) -and ((Get-Content $prof -Raw -ErrorAction SilentlyContinue) -match 'lindows')) {
        Write-Output "  [ok]    PowerShell profile hooks lindows"
    } else {
        Write-Output "  [warn]  PowerShell profile does not import lindows (CMD shims still work); run .\install.ps1"
    }

    $global:LASTEXITCODE = if ($ok) { 0 } else { 1 }
}
