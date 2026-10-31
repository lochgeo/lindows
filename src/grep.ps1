function Invoke-LindowsGrep {
    $ArgLine = @($args)
    $pipeData = @($input)

    $ignoreCase = $false
    $invert = $false
    $lineNumber = $false
    $countOnly = $false
    $filesWithMatches = $false
    $filesWithoutMatch = $false
    $onlyMatching = $false
    $fixedStrings = $false
    $wordRegexp = $false
    $lineRegexp = $false
    $recursive = $false
    $quiet = $false
    $noMessages = $false
    $withFilename = $null # $true, $false, or $null (auto)
    $maxCount = 0
    $beforeCtx = 0
    $afterCtx = 0

    $patterns = New-Object System.Collections.Generic.List[string]
    $includeGlobs = New-Object System.Collections.Generic.List[string]
    $excludeGlobs = New-Object System.Collections.Generic.List[string]
    $excludeDirs = New-Object System.Collections.Generic.List[string]
    $targets = New-Object System.Collections.Generic.List[string]

    $usage = @"
Usage: grep [OPTION]... PATTERNS [FILE]...
Search for PATTERNS in each FILE or standard input.

  -E, --extended-regexp     PATTERNS are extended regular expressions
  -F, --fixed-strings       PATTERNS are strings
  -i, --ignore-case         ignore case distinctions
  -v, --invert-match        select non-matching lines
  -w, --word-regexp         match only whole words
  -x, --line-regexp         match only whole lines
  -n, --line-number         print line number with output lines
  -c, --count               print only a count of selected lines per FILE
  -l, --files-with-matches  print only names of FILEs with selected lines
  -L, --files-without-match print only names of FILEs with no selected lines
  -o, --only-matching       show only nonempty parts of lines that match
  -r, -R, --recursive       search directories recursively
  -H, --with-filename       print file name with output lines
  -h, --no-filename         suppress the file name prefix on output
  -q, --quiet, --silent     suppress all normal output
  -s, --no-messages         suppress error messages
  -e, --regexp=PATTERN      use PATTERN for matching
  -m, --max-count=NUM       stop after NUM selected lines
  -A, --after-context=NUM   print NUM lines of trailing context
  -B, --before-context=NUM  print NUM lines of leading context
  -C, --context=NUM         print NUM lines of output context
      --include=GLOB        search only files that match GLOB
      --exclude=GLOB        skip files that match GLOB
      --exclude-dir=DIR     skip directories that match DIR
      --help                display this help and exit
      --version             output version information and exit
"@

    $i = 0
    $noMoreOpts = $false
    while ($i -lt $ArgLine.Count) {
        $a = [string]$ArgLine[$i]; $i++
        if (-not $noMoreOpts -and $a -eq '--') { $noMoreOpts = $true; continue }
        if (-not $noMoreOpts -and $a -eq '--help') { Write-Output $usage; return 0 }
        if (-not $noMoreOpts -and $a -cmatch '^--version$|^-V$') { Write-Output "grep (Lindows) $script:LindowsVersion"; return 0 }

        if (-not $noMoreOpts -and $a.StartsWith('--') -and $a.Length -gt 2) {
            switch -Regex ($a) {
                '^--extended-regexp$|^--basic-regexp$|^--perl-regexp$' { }
                '^--fixed-strings$' { $fixedStrings = $true }
                '^--ignore-case$' { $ignoreCase = $true }
                '^--invert-match$' { $invert = $true }
                '^--word-regexp$' { $wordRegexp = $true }
                '^--line-regexp$' { $lineRegexp = $true }
                '^--line-number$' { $lineNumber = $true }
                '^--count$' { $countOnly = $true }
                '^--files-with-matches$' { $filesWithMatches = $true }
                '^--files-without-match$' { $filesWithoutMatch = $true }
                '^--only-matching$' { $onlyMatching = $true }
                '^--recursive$|^--dereference-recursive$' { $recursive = $true }
                '^--with-filename$' { $withFilename = $true }
                '^--no-filename$' { $withFilename = $false }
                '^--quiet$|^--silent$' { $quiet = $true }
                '^--no-messages$' { $noMessages = $true }
                '^--color(=.*)?$|^--colour(=.*)?$|^--text$|^--binary-files=.*$' { }
                '^--regexp=(.+)$' { $patterns.Add($Matches[1]) }
                '^--regexp$' { if ($i -lt $ArgLine.Count) { $patterns.Add([string]$ArgLine[$i]); $i++ } }
                '^--max-count=(\d+)$' { $maxCount = [int]$Matches[1] }
                '^--after-context=(\d+)$' { $afterCtx = [int]$Matches[1] }
                '^--before-context=(\d+)$' { $beforeCtx = [int]$Matches[1] }
                '^--context=(\d+)$' { $beforeCtx = [int]$Matches[1]; $afterCtx = [int]$Matches[1] }
                '^--include=(.+)$' { $includeGlobs.Add($Matches[1]) }
                '^--exclude=(.+)$' { $excludeGlobs.Add($Matches[1]) }
                '^--exclude-dir=(.+)$' { $excludeDirs.Add($Matches[1]) }
                Default {
                    [Console]::Error.WriteLine("grep: unrecognized option '$a'")
                    $global:LASTEXITCODE = 2; return
                }
            }
            continue
        }

        if (-not $noMoreOpts -and $a.StartsWith('-') -and $a.Length -gt 1) {
            $chars = $a.Substring(1).ToCharArray()
            for ($c = 0; $c -lt $chars.Count; $c++) {
                $ch = [string]$chars[$c]
                switch -CaseSensitive ($ch) {
                    'E' { }
                    'G' { }
                    'P' { }
                    'F' { $fixedStrings = $true }
                    'i' { $ignoreCase = $true }
                    'v' { $invert = $true }
                    'w' { $wordRegexp = $true }
                    'x' { $lineRegexp = $true }
                    'n' { $lineNumber = $true }
                    'c' { $countOnly = $true }
                    'l' { $filesWithMatches = $true }
                    'L' { $filesWithoutMatch = $true }
                    'o' { $onlyMatching = $true }
                    'r' { $recursive = $true }
                    'R' { $recursive = $true }
                    'H' { $withFilename = $true }
                    'h' { $withFilename = $false }
                    'q' { $quiet = $true }
                    's' { $noMessages = $true }
                    'a' { }
                    'I' { }
                    'e' {
                        $rest = $a.Substring(2 + $c)
                        if ($rest) { $patterns.Add($rest) }
                        elseif ($i -lt $ArgLine.Count) { $patterns.Add([string]$ArgLine[$i]); $i++ }
                        $c = $chars.Count
                    }
                    'm' {
                        $rest = $a.Substring(2 + $c)
                        if ($rest) { $maxCount = [int]$rest }
                        elseif ($i -lt $ArgLine.Count) { $maxCount = [int]$ArgLine[$i]; $i++ }
                        $c = $chars.Count
                    }
                    'A' {
                        $rest = $a.Substring(2 + $c)
                        if ($rest) { $afterCtx = [int]$rest }
                        elseif ($i -lt $ArgLine.Count) { $afterCtx = [int]$ArgLine[$i]; $i++ }
                        $c = $chars.Count
                    }
                    'B' {
                        $rest = $a.Substring(2 + $c)
                        if ($rest) { $beforeCtx = [int]$rest }
                        elseif ($i -lt $ArgLine.Count) { $beforeCtx = [int]$ArgLine[$i]; $i++ }
                        $c = $chars.Count
                    }
                    'C' {
                        $rest = $a.Substring(2 + $c)
                        $val = if ($rest) { [int]$rest } elseif ($i -lt $ArgLine.Count) { $v = [int]$ArgLine[$i]; $i++; $v } else { 0 }
                        $beforeCtx = $val; $afterCtx = $val
                        $c = $chars.Count
                    }
                    Default {
                        if ($ch -match '^\d$') {
                            $rest = $a.Substring(1 + $c)
                            if ($rest -match '^\d+$') {
                                $beforeCtx = [int]$rest; $afterCtx = [int]$rest
                                $c = $chars.Count
                                continue
                            }
                        }
                        [Console]::Error.WriteLine("grep: invalid option -- '$ch'")
                        $global:LASTEXITCODE = 2; return
                    }
                }
            }
            continue
        }

        if ($patterns.Count -eq 0) {
            $patterns.Add($a)
        } else {
            $targets.Add($a)
        }
    }

    if ($patterns.Count -eq 0) {
        [Console]::Error.WriteLine($usage)
        $global:LASTEXITCODE = 2
        return
    }

    # Build combined .NET regex
    $regexParts = foreach ($p in $patterns) {
        $body = if ($fixedStrings) { [regex]::Escape($p) } else { $p }
        if ($wordRegexp) { "\b(?:$body)\b" }
        elseif ($lineRegexp) { "^(?:$body)$" }
        else { "(?:$body)" }
    }
    $combinedPattern = $regexParts -join '|'
    $rxOpts = [System.Text.RegularExpressions.RegexOptions]::None
    if ($ignoreCase) { $rxOpts = $rxOpts -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
    try {
        $rx = New-Object System.Text.RegularExpressions.Regex($combinedPattern, $rxOpts)
    } catch {
        [Console]::Error.WriteLine("grep: invalid regular expression: $($_.Exception.Message)")
        $global:LASTEXITCODE = 2
        return
    }

    # Expand files / recursive directories
    $fileList = New-Object System.Collections.Generic.List[string]
    $hadError = $false

    function Add-GrepTarget([string]$t) {
        if ($t -eq '-') { $fileList.Add('-'); return }
        if (Test-Path -LiteralPath $t -PathType Container) {
            if (-not $recursive) {
                if (-not $noMessages) { [Console]::Error.WriteLine("grep: $t`: Is a directory") }
                $script:hadError = $true
                return
            }
            $dirItems = Get-ChildItem -LiteralPath $t -Recurse -File -ErrorAction SilentlyContinue
            foreach ($item in $dirItems) {
                $relPath = $item.FullName
                $skip = $false
                foreach ($ed in $excludeDirs) {
                    if ($relPath -match "(^|[\\/])$([regex]::Escape($ed))([\\/]|$)") { $skip = $true; break }
                }
                if ($skip) { continue }
                if ($excludeGlobs.Count -gt 0) {
                    foreach ($eg in $excludeGlobs) { if ($item.Name -like $eg) { $skip = $true; break } }
                }
                if ($skip) { continue }
                if ($includeGlobs.Count -gt 0) {
                    $incMatch = $false
                    foreach ($ig in $includeGlobs) { if ($item.Name -like $ig) { $incMatch = $true; break } }
                    if (-not $incMatch) { continue }
                }
                $fileList.Add($item.FullName)
            }
        } elseif (Test-Path -LiteralPath $t -PathType Leaf) {
            $fileList.Add($t)
        } elseif ($t -match '[\*\?]') {
            $globItems = Get-ChildItem -Path $t -File -ErrorAction SilentlyContinue
            if ($globItems) {
                foreach ($gi in $globItems) { $fileList.Add($gi.FullName) }
            } else {
                if (-not $noMessages) { [Console]::Error.WriteLine("grep: $t`: No such file or directory") }
                $script:hadError = $true
            }
        } else {
            if (-not $noMessages) { [Console]::Error.WriteLine("grep: $t`: No such file or directory") }
            $script:hadError = $true
        }
    }

    if ($targets.Count -eq 0) {
        if ($recursive) {
            Add-GrepTarget '.'
        } else {
            $fileList.Add('-')
        }
    } else {
        foreach ($t in $targets) { Add-GrepTarget $t }
    }

    $showFilePrefix = if ($null -ne $withFilename) { $withFilename } else { ($fileList.Count -gt 1) -or $recursive }
    $anyMatch = $false
    $out = New-Object System.Collections.Generic.List[string]

    foreach ($f in $fileList) {
        try {
            $lines = Read-LindowsInputLines -FilePath $f -PipelineInput $pipeData
        } catch {
            if (-not $noMessages) { [Console]::Error.WriteLine("grep: $f`: No such file or directory") }
            $hadError = $true
            continue
        }

        $fileMatchCount = 0
        $matchedIndices = New-Object 'System.Collections.Generic.HashSet[int]'

        for ($idx = 0; $idx -lt $lines.Count; $idx++) {
            $line = $lines[$idx]
            $isMatch = $rx.IsMatch($line)
            if ($invert) { $isMatch = -not $isMatch }

            if ($isMatch) {
                $anyMatch = $true
                $fileMatchCount++
                [void]$matchedIndices.Add($idx)

                if ($quiet) {
                    $global:LASTEXITCODE = 0
                    return
                }
                if ($filesWithMatches) { break }
                if ($maxCount -gt 0 -and $fileMatchCount -ge $maxCount) { break }
            }
        }

        $displayPath = if ($f -eq '-') { '(standard input)' } else { $f }

        if ($filesWithMatches) {
            if ($fileMatchCount -gt 0) { $out.Add($displayPath) }
            continue
        }
        if ($filesWithoutMatch) {
            if ($fileMatchCount -eq 0) { $out.Add($displayPath) }
            continue
        }
        if ($countOnly) {
            if ($showFilePrefix) { $out.Add("${displayPath}:${fileMatchCount}") }
            else { $out.Add("$fileMatchCount") }
            continue
        }

        if ($fileMatchCount -eq 0) { continue }

        # Determine lines to print (including context if requested)
        $toPrint = New-Object 'System.Collections.Generic.SortedSet[int]'
        foreach ($mIdx in $matchedIndices) {
            $start = [Math]::Max(0, $mIdx - $beforeCtx)
            $end = [Math]::Min($lines.Count - 1, $mIdx + $afterCtx)
            for ($cIdx = $start; $cIdx -le $end; $cIdx++) {
                [void]$toPrint.Add($cIdx)
            }
        }

        foreach ($pIdx in $toPrint) {
            $line = $lines[$pIdx]
            $isActualMatch = $matchedIndices.Contains($pIdx)
            $sep = if ($isActualMatch) { ':' } else { '-' }

            if ($onlyMatching -and -not $invert) {
                if (-not $isActualMatch) { continue }
                foreach ($m in $rx.Matches($line)) {
                    if ($m.Length -gt 0) {
                        $prefix = ''
                        if ($showFilePrefix) { $prefix += "${displayPath}:" }
                        if ($lineNumber) { $prefix += "$($pIdx + 1):" }
                        $out.Add("${prefix}$($m.Value)")
                    }
                }
            } else {
                $prefix = ''
                if ($showFilePrefix) { $prefix += "${displayPath}${sep}" }
                if ($lineNumber) { $prefix += "$($pIdx + 1)${sep}" }
                $out.Add("${prefix}${line}")
            }
        }
    }

    if (-not $quiet -and $out.Count -gt 0) {
        $out | ForEach-Object { Write-Output $_ }
    }

    if ($hadError) {
        $global:LASTEXITCODE = 2
    } elseif ($anyMatch -or ($filesWithoutMatch -and $out.Count -gt 0)) {
        $global:LASTEXITCODE = 0
    } else {
        $global:LASTEXITCODE = 1
    }
}
