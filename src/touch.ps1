function Invoke-LindowsTouch {
    $ArgLine = @($args)

    $noCreate = $false
    $files = New-Object System.Collections.Generic.List[string]

    $usage = @"
Usage: touch [-c] [-a] [-m] FILE...
Update the access and modification times of each FILE to the current time.
A FILE argument that does not exist is created empty, unless -c is supplied.

  -a                     change only the access time
  -c, --no-create        do not create any files
  -m                     change only the modification time
      --help             display this help and exit
      --version          output version information and exit
"@

    $i = 0
    while ($i -lt $ArgLine.Count) {
        $a = [string]$ArgLine[$i]; $i++
        if ($a -eq '--help') { Write-Output $usage; return 0 }
        if ($a -eq '--version') { Write-Output "touch (Lindows) $script:LindowsVersion"; return 0 }
        if ($a -eq '--no-create' -or $a -eq '-c') { $noCreate = $true; continue }
        if ($a -eq '-t' -or $a -eq '-d' -or $a -eq '-r') {
            if ($i -lt $ArgLine.Count) { $i++ }
            continue
        }
        if ($a.StartsWith('-') -and $a.Length -gt 1) {
            if ($a -match 'c') { $noCreate = $true }
            continue
        }
        $files.Add($a)
    }

    if ($files.Count -eq 0) {
        [Console]::Error.WriteLine("touch: missing file operand")
        $global:LASTEXITCODE = 1
        return
    }

    $now = Get-Date
    $rc = 0

    foreach ($f in $files) {
        try {
            if (Test-Path -LiteralPath $f) {
                $item = Get-Item -LiteralPath $f -Force
                $item.LastWriteTime = $now
                $item.LastAccessTime = $now
            } elseif (-not $noCreate) {
                $parent = Split-Path -Parent $f
                if ($parent -and -not (Test-Path -LiteralPath $parent)) {
                    New-Item -ItemType Directory -Path $parent -Force | Out-Null
                }
                [System.IO.File]::WriteAllBytes($f, [byte[]]@())
            }
        } catch {
            [Console]::Error.WriteLine("touch: cannot touch '$f': $($_.Exception.Message)")
            $rc = 1
        }
    }

    $global:LASTEXITCODE = $rc
}
