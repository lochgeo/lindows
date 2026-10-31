function Invoke-LindowsFind {
    $ArgLine = @($args)

    # Detect legacy Windows FIND.EXE usage: find [/V] [/C] [/N] [/I] "string" [file...]
    if ($ArgLine.Count -gt 0 -and ($ArgLine[0] -match '^/[VCNI]' -or ($ArgLine.Count -ge 2 -and -not ($ArgLine -match '^-')))) {
        # Check if any arg starts with '-' (Unix style); if none and first arg isn't a directory, could still be Unix `find src`
    }

    $paths = New-Object System.Collections.Generic.List[string]
    $namePatterns = New-Object System.Collections.Generic.List[string]
    $inamePatterns = New-Object System.Collections.Generic.List[string]
    $pathPatterns = New-Object System.Collections.Generic.List[string]
    $notNames = New-Object System.Collections.Generic.List[string]
    $notPaths = New-Object System.Collections.Generic.List[string]
    $typeFilter = $null # 'f' or 'd'
    $maxDepth = -1
    $minDepth = 0
    $deleteMatch = $false
    $emptyOnly = $false

    $usage = @"
Usage: find [PATH...] [EXPRESSION]
Search for files in a directory hierarchy.

  -name PATTERN       base of file name matches shell PATTERN (case-sensitive)
  -iname PATTERN      like -name, but the match is case-insensitive
  -path PATTERN       file path matches shell PATTERN
  -type [f|d]         file is of type f (regular file) or d (directory)
  -maxdepth LEVELS    descend at most LEVELS of directories
  -mindepth LEVELS    do not apply tests or actions at levels less than LEVELS
  -empty              file is empty and is either a regular file or a directory
  -not, !             negate the next -name, -iname, or -path pattern
  -delete             delete found files/directories
  -print              print the full file name (default)
  --help              display this help and exit
  --version           output version information and exit
"@

    $i = 0
    $inExpr = $false
    $negateNext = $false

    while ($i -lt $ArgLine.Count) {
        $a = [string]$ArgLine[$i]; $i++

        if ($a -eq '--help') { Write-Output $usage; return 0 }
        if ($a -eq '--version') { Write-Output "find (Lindows) $script:LindowsVersion"; return 0 }

        if (-not $inExpr -and -not $a.StartsWith('-') -and $a -ne '!' -and $a -ne '(' -and $a -ne ')') {
            $paths.Add($a)
            continue
        }
        $inExpr = $true

        switch -Exact ($a) {
            '!' { $negateNext = $true }
            '-not' { $negateNext = $true }
            '-a' { }
            '-and' { }
            '-o' { }
            '-or' { }
            '(' { }
            ')' { }
            '-print' { }
            '-empty' { $emptyOnly = $true }
            '-delete' { $deleteMatch = $true }
            '-name' {
                if ($i -lt $ArgLine.Count) {
                    $pat = [string]$ArgLine[$i]; $i++
                    if ($negateNext) { $notNames.Add($pat); $negateNext = $false }
                    else { $namePatterns.Add($pat) }
                }
            }
            '-iname' {
                if ($i -lt $ArgLine.Count) {
                    $pat = [string]$ArgLine[$i]; $i++
                    if ($negateNext) { $notNames.Add($pat); $negateNext = $false }
                    else { $inamePatterns.Add($pat) }
                }
            }
            '-path' {
                if ($i -lt $ArgLine.Count) {
                    $pat = [string]$ArgLine[$i]; $i++
                    if ($negateNext) { $notPaths.Add($pat); $negateNext = $false }
                    else { $pathPatterns.Add($pat) }
                }
            }
            '-wholename' {
                if ($i -lt $ArgLine.Count) {
                    $pat = [string]$ArgLine[$i]; $i++
                    if ($negateNext) { $notPaths.Add($pat); $negateNext = $false }
                    else { $pathPatterns.Add($pat) }
                }
            }
            '-type' {
                if ($i -lt $ArgLine.Count) { $typeFilter = [string]$ArgLine[$i]; $i++ }
            }
            '-maxdepth' {
                if ($i -lt $ArgLine.Count) { $maxDepth = [int]$ArgLine[$i]; $i++ }
            }
            '-mindepth' {
                if ($i -lt $ArgLine.Count) { $minDepth = [int]$ArgLine[$i]; $i++ }
            }
            '-prune' { }
            Default {
                # Ignore unknown flags gracefully so complex agent find invocations still succeed
            }
        }
    }

    if ($paths.Count -eq 0) { $paths.Add('.') }

    $out = New-Object System.Collections.Generic.List[string]
    $rc = 0

    function Test-FindEntry($item, [string]$displayPath, [bool]$isDir, [int]$depth) {
        if ($depth -lt $minDepth) { return $false }
        if ($typeFilter -eq 'f' -and $isDir) { return $false }
        if ($typeFilter -eq 'd' -and -not $isDir) { return $false }

        $leafName = if ($null -ne $item) { $item.Name } else { Split-Path -Leaf $displayPath }
        $normPath = $displayPath.Replace('\', '/')

        foreach ($np in $notNames) {
            if ($leafName -like $np) { return $false }
        }
        foreach ($npp in $notPaths) {
            $cleanNp = $npp.Replace('\', '/')
            if ($normPath -like $cleanNp) { return $false }
        }

        if ($namePatterns.Count -gt 0) {
            $matched = $false
            foreach ($p in $namePatterns) {
                if ($leafName -clike $p) { $matched = $true; break }
            }
            if (-not $matched) { return $false }
        }

        if ($inamePatterns.Count -gt 0) {
            $matched = $false
            foreach ($p in $inamePatterns) {
                if ($leafName -ilike $p) { $matched = $true; break }
            }
            if (-not $matched) { return $false }
        }

        if ($pathPatterns.Count -gt 0) {
            $matched = $false
            foreach ($p in $pathPatterns) {
                $cleanP = $p.Replace('\', '/')
                if ($normPath -ilike $cleanP) { $matched = $true; break }
            }
            if (-not $matched) { return $false }
        }

        if ($emptyOnly -and $null -ne $item) {
            if ($isDir) {
                $children = Get-ChildItem -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue
                if ($children) { return $false }
            } else {
                if ($item.Length -gt 0) { return $false }
            }
        }

        return $true
    }

    function Walk-Find([string]$fsPath, [string]$dispPrefix, [int]$depth) {
        if ($maxDepth -ge 0 -and $depth -gt $maxDepth) { return }

        $children = Get-ChildItem -LiteralPath $fsPath -Force -ErrorAction SilentlyContinue
        if ($null -eq $children) { return }

        foreach ($child in $children) {
            $isDir = $child.PSIsContainer
            $sep = if ($dispPrefix.EndsWith('/') -or $dispPrefix.EndsWith('\')) { '' } else { '/' }
            $childDisp = "${dispPrefix}${sep}$($child.Name)"

            # Skip walking into excluded path patterns (like */node_modules/* or */.git/*)
            $skipWalk = $false
            foreach ($npp in $notPaths) {
                $cleanNp = $npp.Replace('\', '/').TrimEnd('/*')
                if ($childDisp.Replace('\', '/') -like $cleanNp -or $child.Name -like $cleanNp.TrimStart('*/')) {
                    $skipWalk = $true; break
                }
            }
            foreach ($np in $notNames) {
                if ($isDir -and ($child.Name -like $np)) { $skipWalk = $true; break }
            }

            if (Test-FindEntry $child $childDisp $isDir $depth) {
                if ($deleteMatch) {
                    Remove-Item -LiteralPath $child.FullName -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    $out.Add($childDisp)
                }
            }

            if ($isDir -and -not $skipWalk) {
                Walk-Find $child.FullName $childDisp ($depth + 1)
            }
        }
    }

    foreach ($p in $paths) {
        if (-not (Test-Path -LiteralPath $p)) {
            [Console]::Error.WriteLine("find: '$p': No such file or directory")
            $rc = 1
            continue
        }
        $item = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
        $isDir = $item.PSIsContainer
        if (Test-FindEntry $item $p $isDir 0) {
            if (-not $deleteMatch) { $out.Add($p) }
        }
        if ($isDir) {
            Walk-Find $item.FullName $p 1
        }
    }

    if ($out.Count -gt 0) {
        $out | ForEach-Object { Write-Output $_ }
    }
    $global:LASTEXITCODE = $rc
}
