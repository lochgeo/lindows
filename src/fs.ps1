function Invoke-LindowsCat {
    $ArgLine = @($args)
    $pipeData = @($input)

    $numberAll = $false
    $numberNonBlank = $false
    $squeezeBlank = $false
    $showEnds = $false
    $files = New-Object System.Collections.Generic.List[string]

    $usage = @"
Usage: cat [-n] [-b] [-s] [-E] [FILE]...
Concatenate FILE(s) to standard output.

  -b, --number-nonblank    number nonempty output lines, overrides -n
  -E, --show-ends          display $ at end of each line
  -n, --number             number all output lines
  -s, --squeeze-blank      suppress repeated empty output lines
  -A, -v, -T, -u           accepted for compatibility
      --help               display this help and exit
      --version            output version information and exit
"@

    foreach ($a in $ArgLine) {
        $s = [string]$a
        if ($s -eq '--help') { Write-Output $usage; return 0 }
        if ($s -eq '--version') { Write-Output "cat (Lindows) $script:LindowsVersion"; return 0 }
        if ($s -eq '--number') { $numberAll = $true; continue }
        if ($s -eq '--number-nonblank') { $numberNonBlank = $true; continue }
        if ($s -eq '--squeeze-blank') { $squeezeBlank = $true; continue }
        if ($s -eq '--show-ends') { $showEnds = $true; continue }

        if ($s.StartsWith('-') -and $s.Length -gt 1) {
            foreach ($ch in $s.Substring(1).ToCharArray()) {
                switch -CaseSensitive ([string]$ch) {
                    'n' { $numberAll = $true }
                    'b' { $numberNonBlank = $true }
                    's' { $squeezeBlank = $true }
                    'E' { $showEnds = $true }
                    'e' { $showEnds = $true }
                    'A' { $showEnds = $true }
                    'v' { }
                    'T' { }
                    't' { }
                    'u' { }
                    Default {
                        [Console]::Error.WriteLine("cat: invalid option -- '$ch'")
                        $global:LASTEXITCODE = 1; return
                    }
                }
            }
            continue
        }
        $files.Add($s)
    }

    if ($numberNonBlank) { $numberAll = $false }
    if ($files.Count -eq 0) { $files.Add('-') }

    $out = New-Object System.Collections.Generic.List[string]
    $lineNum = 1
    $prevBlank = $false
    $rc = 0

    foreach ($f in $files) {
        try {
            $lines = Read-LindowsInputLines -FilePath $f -PipelineInput $pipeData
            foreach ($ln in $lines) {
                $isBlank = ($ln.Length -eq 0)
                if ($squeezeBlank -and $isBlank -and $prevBlank) { continue }
                $prevBlank = $isBlank

                $text = if ($showEnds) { "$ln`$" } else { $ln }
                if ($numberNonBlank) {
                    if (-not $isBlank) {
                        $text = ('{0,6}  {1}' -f $lineNum, $text)
                        $lineNum++
                    }
                } elseif ($numberAll) {
                    $text = ('{0,6}  {1}' -f $lineNum, $text)
                    $lineNum++
                }
                $out.Add($text)
            }
        } catch {
            [Console]::Error.WriteLine("cat: $f`: No such file or directory")
            $rc = 1
        }
    }

    if ($out.Count -gt 0) { $out | ForEach-Object { Write-Output $_ } }
    $global:LASTEXITCODE = $rc
}

function Invoke-LindowsRm {
    $ArgLine = @($args)

    $recurse = $false
    $force = $false
    $verbose = $false
    $targets = New-Object System.Collections.Generic.List[string]

    $usage = @"
Usage: rm [-r] [-f] [-v] FILE...
Remove (unlink) the FILE(s).

  -f, --force           ignore nonexistent files and arguments, never prompt
  -r, -R, --recursive   remove directories and their contents recursively
  -d, --dir             remove empty directories
  -v, --verbose         explain what is being done
      --help            display this help and exit
      --version         output version information and exit
"@

    $noMoreOpts = $false
    foreach ($a in $ArgLine) {
        $s = [string]$a
        if (-not $noMoreOpts -and $s -eq '--') { $noMoreOpts = $true; continue }
        if (-not $noMoreOpts -and $s -eq '--help') { Write-Output $usage; return 0 }
        if (-not $noMoreOpts -and $s -eq '--version') { Write-Output "rm (Lindows) $script:LindowsVersion"; return 0 }
        if (-not $noMoreOpts -and $s -eq '--recursive') { $recurse = $true; continue }
        if (-not $noMoreOpts -and $s -eq '--force') { $force = $true; continue }
        if (-not $noMoreOpts -and $s -eq '--verbose') { $verbose = $true; continue }
        if (-not $noMoreOpts -and $s -eq '--dir') { continue }

        if (-not $noMoreOpts -and $s.StartsWith('-') -and $s.Length -gt 1) {
            foreach ($ch in $s.Substring(1).ToCharArray()) {
                switch -CaseSensitive ([string]$ch) {
                    'r' { $recurse = $true }
                    'R' { $recurse = $true }
                    'f' { $force = $true }
                    'v' { $verbose = $true }
                    'd' { }
                    'i' { }
                    'I' { }
                    Default {
                        [Console]::Error.WriteLine("rm: invalid option -- '$ch'")
                        $global:LASTEXITCODE = 1; return
                    }
                }
            }
            continue
        }
        $targets.Add($s)
    }

    if ($targets.Count -eq 0) {
        if ($force) { $global:LASTEXITCODE = 0; return }
        [Console]::Error.WriteLine("rm: missing operand")
        $global:LASTEXITCODE = 1
        return
    }

    $rc = 0
    foreach ($t in $targets) {
        if (-not (Test-Path -Path $t)) {
            if (-not $force) {
                [Console]::Error.WriteLine("rm: cannot remove '$t': No such file or directory")
                $rc = 1
            }
            continue
        }
        try {
            $item = Get-Item -Path $t -Force -ErrorAction SilentlyContinue
            if ($item -and $item.PSIsContainer -and -not $recurse) {
                $children = Get-ChildItem -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue
                if ($children) {
                    [Console]::Error.WriteLine("rm: cannot remove '$t': Is a directory (use -r to remove recursively)")
                    $rc = 1
                    continue
                }
            }
            Remove-Item -Path $t -Recurse:$recurse -Force -ErrorAction Stop
            if ($verbose) { Write-Output "removed '$t'" }
        } catch {
            if (-not $force) {
                [Console]::Error.WriteLine("rm: cannot remove '$t': $($_.Exception.Message)")
                $rc = 1
            }
        }
    }

    $global:LASTEXITCODE = $rc
}

function Invoke-LindowsMkdir {
    $ArgLine = @($args)

    $verbose = $false
    $dirs = New-Object System.Collections.Generic.List[string]

    $usage = @"
Usage: mkdir [-p] [-v] DIRECTORY...
Create the DIRECTORY(ies), if they do not already exist.

  -p, --parents     no error if existing, make parent directories as needed
  -v, --verbose     print a message for each created directory
  -m, --mode=MODE   accepted for compatibility (no-op on Windows)
      --help        display this help and exit
      --version     output version information and exit
"@

    $i = 0
    while ($i -lt $ArgLine.Count) {
        $s = [string]$ArgLine[$i]; $i++
        if ($s -eq '--help') { Write-Output $usage; return 0 }
        if ($s -eq '--version') { Write-Output "mkdir (Lindows) $script:LindowsVersion"; return 0 }
        if ($s -eq '--parents' -or $s -eq '-p') { continue }
        if ($s -eq '--verbose' -or $s -eq '-v') { $verbose = $true; continue }
        if ($s -eq '-m' -or $s -eq '--mode') { if ($i -lt $ArgLine.Count) { $i++ }; continue }
        if ($s.StartsWith('--mode=')) { continue }
        if ($s.StartsWith('-') -and $s.Length -gt 1) {
            if ($s -match 'v') { $verbose = $true }
            continue
        }
        $dirs.Add($s)
    }

    if ($dirs.Count -eq 0) {
        [Console]::Error.WriteLine("mkdir: missing operand")
        $global:LASTEXITCODE = 1
        return
    }

    $rc = 0
    foreach ($d in $dirs) {
        try {
            if (-not (Test-Path -LiteralPath $d -PathType Container)) {
                New-Item -ItemType Directory -Path $d -Force -ErrorAction Stop | Out-Null
                if ($verbose) { Write-Output "mkdir: created directory '$d'" }
            }
        } catch {
            [Console]::Error.WriteLine("mkdir: cannot create directory '$d': $($_.Exception.Message)")
            $rc = 1
        }
    }

    $global:LASTEXITCODE = $rc
}
