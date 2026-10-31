function Invoke-LindowsWc {
    $ArgLine = @($args)
    $pipeData = @($input)

    $showLines = $false
    $showWords = $false
    $showBytes = $false
    $showChars = $false
    $files = New-Object System.Collections.Generic.List[string]

    $usage = @"
Usage: wc [-l] [-w] [-c] [-m] [FILE]...
Print newline, word, and byte counts for each FILE, and a total line if
more than one FILE is specified.

  -c, --bytes            print the byte counts
  -m, --chars            print the character counts
  -l, --lines            print the newline counts
  -w, --words            print the word counts
      --help             display this help and exit
      --version          output version information and exit
"@

    foreach ($a in $ArgLine) {
        $s = [string]$a
        if ($s -eq '--help') { Write-Output $usage; return 0 }
        if ($s -eq '--version') { Write-Output "wc (Lindows) $script:LindowsVersion"; return 0 }
        if ($s -eq '--lines') { $showLines = $true; continue }
        if ($s -eq '--words') { $showWords = $true; continue }
        if ($s -eq '--bytes') { $showBytes = $true; continue }
        if ($s -eq '--chars') { $showChars = $true; continue }

        if ($s.StartsWith('-') -and $s.Length -gt 1) {
            foreach ($ch in $s.Substring(1).ToCharArray()) {
                switch -CaseSensitive ([string]$ch) {
                    'l' { $showLines = $true }
                    'w' { $showWords = $true }
                    'c' { $showBytes = $true }
                    'm' { $showChars = $true }
                    Default {
                        [Console]::Error.WriteLine("wc: invalid option -- '$ch'")
                        $global:LASTEXITCODE = 1; return
                    }
                }
            }
            continue
        }
        $files.Add($s)
    }

    $explicitFlags = ($showLines -or $showWords -or $showBytes -or $showChars)
    if (-not $explicitFlags) {
        $showLines = $true
        $showWords = $true
        $showBytes = $true
    }
    $flagCount = ([int]$showLines) + ([int]$showWords) + ([int]$showBytes) + ([int]$showChars)

    if ($files.Count -eq 0) { $files.Add('-') }

    $totalLines = 0
    $totalWords = 0
    $totalBytes = 0
    $totalChars = 0
    $rc = 0
    $out = New-Object System.Collections.Generic.List[string]

    function Format-WcRow([long]$l, [long]$w, [long]$c, [long]$m, [string]$name) {
        $parts = New-Object System.Collections.Generic.List[string]
        if ($showLines) { $parts.Add("$l") }
        if ($showWords) { $parts.Add("$w") }
        if ($showChars) { $parts.Add("$m") }
        if ($showBytes) { $parts.Add("$c") }

        # When a single metric is requested for stdin, output just the number
        if ($flagCount -eq 1 -and $name -eq '') {
            return $parts[0]
        }
        $line = ($parts | ForEach-Object { $_.PadLeft(7) }) -join ' '
        if ($name -ne '') { $line = "$line $name" }
        return $line.TrimStart()
    }

    foreach ($f in $files) {
        try {
            $lines = Read-LindowsInputLines -FilePath $f -PipelineInput $pipeData
            $rawBytes = if ($f -ne '-') {
                [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $f).ProviderPath)
            } else {
                [System.Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))
            }

            $lCount = $lines.Count
            $wCount = 0
            $mCount = 0
            foreach ($ln in $lines) {
                $mCount += $ln.Length + 1
                $trimmed = $ln.Trim()
                if ($trimmed.Length -gt 0) {
                    $wCount += ($trimmed -split '\s+').Count
                }
            }
            $bCount = $rawBytes.Length

            $totalLines += $lCount
            $totalWords += $wCount
            $totalBytes += $bCount
            $totalChars += $mCount

            $label = if ($f -eq '-') { '' } else { $f }
            $out.Add((Format-WcRow $lCount $wCount $bCount $mCount $label))
        } catch {
            [Console]::Error.WriteLine("wc: $f`: No such file or directory")
            $rc = 1
        }
    }

    if ($files.Count -gt 1) {
        $out.Add((Format-WcRow $totalLines $totalWords $totalBytes $totalChars 'total'))
    }

    if ($out.Count -gt 0) { $out | ForEach-Object { Write-Output $_ } }
    $global:LASTEXITCODE = $rc
}
