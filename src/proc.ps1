function Invoke-LindowsLsof {
    $ArgLine = @($args)

    $terse = $false
    $ports = New-Object System.Collections.Generic.List[int]
    $pids = New-Object System.Collections.Generic.List[int]

    $usage = @"
Usage: lsof [-i [:PORT]] [-t] [-p PID]
List open network ports and associated processes on Windows.

  -i [:PORT]    select network connections (optionally matching PORT)
  -p PID        select by process ID
  -t            terse output (print only process IDs, useful for kill)
  -P, -n        accepted for compatibility (numeric ports/addresses)
  --help        display this help and exit
  --version     output version information and exit
"@

    $i = 0
    while ($i -lt $ArgLine.Count) {
        $a = [string]$ArgLine[$i]; $i++
        if ($a -eq '--help' -or $a -eq '-h') { Write-Output $usage; return 0 }
        if ($a -eq '--version') { Write-Output "lsof (Lindows) $script:LindowsVersion"; return 0 }
        if ($a -eq '-t') { $terse = $true; continue }
        if ($a -match '^-[Pn]+$') { continue }

        if ($a -eq '-p') {
            if ($i -lt $ArgLine.Count) {
                foreach ($pStr in ([string]$ArgLine[$i] -split ',')) {
                    if ($pStr -match '^\d+$') { $pids.Add([int]$pStr) }
                }
                $i++
            }
            continue
        }
        if ($a -match '^-i(.*)$') {
            $rest = $Matches[1]
            if (-not $rest -and $i -lt $ArgLine.Count -and -not ([string]$ArgLine[$i]).StartsWith('-')) {
                $rest = [string]$ArgLine[$i]; $i++
            }
            if ($rest -match ':(\d+)$') {
                $ports.Add([int]$Matches[1])
            } elseif ($rest -match '^(\d+)$') {
                $ports.Add([int]$Matches[1])
            }
            continue
        }
        if ($a -match '^:(\d+)$') {
            $ports.Add([int]$Matches[1])
            continue
        }
    }

    $conns = @()
    try {
        $conns = @(Get-NetTCPConnection -ErrorAction Stop)
    } catch {
        # Fallback to netstat -ano if Get-NetTCPConnection is unavailable
        $netstatLines = netstat -ano | Where-Object { $_ -match '^\s*(TCP|UDP)\s+' }
        foreach ($nl in $netstatLines) {
            $tokens = ($nl.Trim() -split '\s+')
            if ($tokens.Count -ge 4) {
                $localAddr = $tokens[1]
                $state = if ($tokens[0] -eq 'TCP') { $tokens[3] } else { 'LISTEN' }
                $procId = [int]$tokens[$tokens.Count - 1]
                $localPort = 0
                if ($localAddr -match ':(\d+)$') { $localPort = [int]$Matches[1] }
                $conns += [PSCustomObject]@{
                    LocalAddress = ($localAddr -replace ':\d+$', '')
                    LocalPort    = $localPort
                    State        = $state
                    OwningProcess = $procId
                }
            }
        }
    }

    if ($ports.Count -gt 0) {
        $conns = @($conns | Where-Object { $ports.Contains([int]$_.LocalPort) })
    }
    if ($pids.Count -gt 0) {
        $conns = @($conns | Where-Object { $pids.Contains([int]$_.OwningProcess) })
    }

    if ($conns.Count -eq 0) {
        $global:LASTEXITCODE = 1
        return
    }

    if ($terse) {
        $uniquePids = $conns | Select-Object -ExpandProperty OwningProcess -Unique
        foreach ($up in $uniquePids) { Write-Output "$up" }
        $global:LASTEXITCODE = 0
        return
    }

    $out = New-Object System.Collections.Generic.List[string]
    $out.Add(('{0,-18} {1,8} {2,-10} {3,-22} {4}' -f 'COMMAND', 'PID', 'TYPE', 'NAME', 'STATE'))

    foreach ($c in $conns) {
        $procName = '-'
        try {
            $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
            if ($p) { $procName = $p.ProcessName }
        } catch { }
        $addr = "$($c.LocalAddress):$($c.LocalPort)"
        $out.Add(('{0,-18} {1,8} {2,-10} {3,-22} {4}' -f $procName, $c.OwningProcess, 'IPv4/TCP', $addr, $c.State))
    }

    $out | ForEach-Object { Write-Output $_ }
    $global:LASTEXITCODE = 0
}

function Invoke-LindowsPkill {
    $ArgLine = @($args)

    $fullCmdMatch = $false
    $ignoreCase = $false
    $exact = $false
    $listOnly = $false
    $countOnly = $false
    $patterns = New-Object System.Collections.Generic.List[string]

    $usage = @"
Usage: pkill [-f] [-i] [-x] [-l] [-c] PATTERN
Find or signal processes by name or command line.

  -f, --full         match against full command line or process name
  -i, --ignore-case  case-insensitive match
  -x, --exact        require an exact match of the process name
  -l, --list-name    list matching process IDs and names (without killing)
  -c, --count        count matching processes
  -9, -TERM, -KILL   accepted signal flags
  --help             display this help and exit
  --version          output version information and exit
"@

    foreach ($a in $ArgLine) {
        $s = [string]$a
        if ($s -eq '--help') { Write-Output $usage; return 0 }
        if ($s -eq '--version') { Write-Output "pkill (Lindows) $script:LindowsVersion"; return 0 }
        if ($s -eq '--full' -or $s -eq '-f') { $fullCmdMatch = $true; continue }
        if ($s -eq '--ignore-case' -or $s -eq '-i') { $ignoreCase = $true; continue }
        if ($s -eq '--exact' -or $s -eq '-x') { $exact = $true; continue }
        if ($s -eq '--list-name' -or $s -eq '-l') { $listOnly = $true; continue }
        if ($s -eq '--count' -or $s -eq '-c') { $countOnly = $true; continue }
        if ($s -match '^-(9|15|KILL|SIGKILL|TERM|SIGTERM|INT|SIGINT|HUP|SIGHUP)$') { continue }
        if ($s.StartsWith('-') -and $s.Length -gt 1) {
            if ($s -match 'f') { $fullCmdMatch = $true }
            if ($s -match 'i') { $ignoreCase = $true }
            if ($s -match 'x') { $exact = $true }
            continue
        }
        $patterns.Add($s)
    }

    if ($patterns.Count -eq 0) {
        [Console]::Error.WriteLine("pkill: no matching criteria specified")
        $global:LASTEXITCODE = 2
        return
    }

    $pat = $patterns[0]
    $cleanPat = $pat -replace '\.exe$', ''
    $rxBody = if ($exact) { "^(?:$([regex]::Escape($cleanPat)))$" } else { $cleanPat }
    $rxOpts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    if (-not $ignoreCase -and $exact) { $rxOpts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
    $rx = New-Object System.Text.RegularExpressions.Regex($rxBody, $rxOpts)

    $matchedProcs = New-Object System.Collections.Generic.List[object]

    if ($fullCmdMatch) {
        try {
            $cimProcs = Get-CimInstance Win32_Process -ErrorAction Stop
            foreach ($cp in $cimProcs) {
                if ($cp.ProcessId -eq $PID) { continue }
                $haystack = "$($cp.Name) $($cp.CommandLine)"
                if ($rx.IsMatch($haystack)) {
                    $matchedProcs.Add([PSCustomObject]@{ Id = $cp.ProcessId; Name = $cp.Name })
                }
            }
        } catch {
            foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) {
                if ($p.Id -eq $PID) { continue }
                if ($rx.IsMatch($p.ProcessName)) {
                    $matchedProcs.Add([PSCustomObject]@{ Id = $p.Id; Name = $p.ProcessName })
                }
            }
        }
    } else {
        foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) {
            if ($p.Id -eq $PID) { continue }
            if ($rx.IsMatch($p.ProcessName)) {
                $matchedProcs.Add([PSCustomObject]@{ Id = $p.Id; Name = $p.ProcessName })
            }
        }
    }

    if ($countOnly) {
        Write-Output "$($matchedProcs.Count)"
        $global:LASTEXITCODE = if ($matchedProcs.Count -gt 0) { 0 } else { 1 }
        return
    }

    if ($matchedProcs.Count -eq 0) {
        $global:LASTEXITCODE = 1
        return
    }

    foreach ($mp in $matchedProcs) {
        if ($listOnly) {
            Write-Output "$($mp.Id) $($mp.Name)"
        } else {
            Stop-Process -Id $mp.Id -Force -ErrorAction SilentlyContinue
        }
    }

    $global:LASTEXITCODE = 0
}
