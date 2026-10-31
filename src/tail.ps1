function Invoke-LindowsTail {
    $ArgLine = @($args)
    $pipeData = @($input)

    $linesSpec = '10'
    $bytesSpec = $null
    $follow = $false
    $quiet = $false
    $verbose = $false
    $files = New-Object System.Collections.Generic.List[string]

    $usage = @"
Usage: tail [-n LINES] [-c BYTES] [-f] [-q] [-v] [FILE]...
Print the last 10 lines of each FILE to standard output.
With more than one FILE, precede each with a header giving the file name.

  -n, --lines=[+]NUM   output the last NUM lines, or use -n +NUM to output
                       starting with line NUM (1-indexed)
  -c, --bytes=[+]NUM   output the last NUM bytes, or use -c +NUM to output
                       starting with byte NUM
  -f, --follow         output appended data as the file grows
  -q, --quiet          never output headers giving file names
  -v, --verbose        always output headers giving file names
  -h, --help           display this help and exit
      --version        output version information and exit
"@

    $i = 0
    $noMoreOpts = $false
    while ($i -lt $ArgLine.Count) {
        $a = [string]$ArgLine[$i]; $i++
        if (-not $noMoreOpts -and $a -eq '--') { $noMoreOpts = $true; continue }
        if (-not $noMoreOpts -and $a -match '^--help$|^-h$') { Write-Output $usage; return 0 }
        if (-not $noMoreOpts -and $a -eq '--version') { Write-Output "tail (Lindows) $script:LindowsVersion"; return 0 }
        if (-not $noMoreOpts -and $a -cmatch '^--follow$|^-f$|^-F$') { $follow = $true; continue }
        if (-not $noMoreOpts -and $a -cmatch '^--quiet$|^--silent$|^-q$') { $quiet = $true; $verbose = $false; continue }
        if (-not $noMoreOpts -and $a -cmatch '^--verbose$|^-v$') { $verbose = $true; $quiet = $false; continue }

        if (-not $noMoreOpts -and $a -match '^--lines=(.+)$') {
            $linesSpec = $Matches[1]; $bytesSpec = $null; continue
        }
        if (-not $noMoreOpts -and $a -match '^--bytes=(.+)$') {
            $bytesSpec = $Matches[1]; continue
        }
        if (-not $noMoreOpts -and ($a -eq '-n' -or $a -eq '--lines')) {
            if ($i -ge $ArgLine.Count) { [Console]::Error.WriteLine("tail: option '$a' requires an argument"); $global:LASTEXITCODE = 1; return }
            $linesSpec = [string]$ArgLine[$i]; $bytesSpec = $null; $i++; continue
        }
        if (-not $noMoreOpts -and ($a -eq '-c' -or $a -eq '--bytes')) {
            if ($i -ge $ArgLine.Count) { [Console]::Error.WriteLine("tail: option '$a' requires an argument"); $global:LASTEXITCODE = 1; return }
            $bytesSpec = [string]$ArgLine[$i]; $i++; continue
        }
        if (-not $noMoreOpts -and $a -match '^-n(.+)$') {
            $linesSpec = $Matches[1]; $bytesSpec = $null; continue
        }
        if (-not $noMoreOpts -and $a -match '^-c(.+)$') {
            $bytesSpec = $Matches[1]; continue
        }
        if (-not $noMoreOpts -and $a -match '^-(\d+)$') {
            $linesSpec = $Matches[1]; $bytesSpec = $null; continue
        }
        if (-not $noMoreOpts -and $a.StartsWith('-') -and $a.Length -gt 1) {
            [Console]::Error.WriteLine("tail: invalid option -- '$a'")
            $global:LASTEXITCODE = 1; return
        }
        $files.Add($a)
    }

    if ($files.Count -eq 0) { $files.Add('-') }

    if ($follow -and $files.Count -eq 1 -and $files[0] -ne '-') {
        $target = $files[0]
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
            [Console]::Error.WriteLine("tail: cannot open '$target' for reading: No such file or directory")
            $global:LASTEXITCODE = 1; return
        }
        $num = [int](([string]$linesSpec).TrimStart('-', '+'))
        Get-Content -LiteralPath $target -Tail $num -Wait
        return
    }

    $out = New-Object System.Collections.Generic.List[string]
    $rc = 0
    $showHeader = ($verbose -or (-not $quiet -and $files.Count -gt 1))

    for ($fi = 0; $fi -lt $files.Count; $fi++) {
        $f = $files[$fi]
        $label = if ($f -eq '-') { 'standard input' } else { $f }

        try {
            if ($null -ne $bytesSpec) {
                $raw = Read-LindowsInputBytes -FilePath $f -PipelineInput $pipeData
                $bStr = [string]$bytesSpec
                $fromStart = $bStr.StartsWith('+')
                $num = [int]($bStr.TrimStart('-', '+'))

                if ($showHeader) {
                    if ($fi -gt 0) { $out.Add('') }
                    $out.Add("==> $label <==")
                }

                $startIdx = if ($fromStart) { [Math]::Max(0, $num - 1) } else { [Math]::Max(0, $raw.Length - $num) }
                $len = [Math]::Max(0, $raw.Length - $startIdx)
                if ($len -gt 0) {
                    $slice = New-Object byte[] $len
                    [Array]::Copy($raw, $startIdx, $slice, 0, $len)
                    $out.Add([System.Text.Encoding]::UTF8.GetString($slice))
                }
            } else {
                $lines = Read-LindowsInputLines -FilePath $f -PipelineInput $pipeData
                $lStr = [string]$linesSpec
                $fromStart = $lStr.StartsWith('+')
                $num = [int]($lStr.TrimStart('-', '+'))

                if ($showHeader) {
                    if ($fi -gt 0) { $out.Add('') }
                    $out.Add("==> $label <==")
                }

                $startIdx = if ($fromStart) { [Math]::Max(0, $num - 1) } else { [Math]::Max(0, $lines.Count - $num) }
                for ($k = $startIdx; $k -lt $lines.Count; $k++) {
                    $out.Add($lines[$k])
                }
            }
        } catch {
            [Console]::Error.WriteLine("tail: cannot open '$f' for reading: No such file or directory")
            $rc = 1
        }
    }

    if ($out.Count -gt 0) { $out | ForEach-Object { Write-Output $_ } }
    $global:LASTEXITCODE = $rc
}
