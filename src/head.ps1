function Invoke-LindowsHead {
    $ArgLine = @($args)
    $pipeData = @($input)

    $linesCount = 10
    $bytesCount = $null
    $quiet = $false
    $verbose = $false
    $files = New-Object System.Collections.Generic.List[string]

    $usage = @"
Usage: head [-n LINES] [-c BYTES] [-q] [-v] [FILE]...
Print the first 10 lines of each FILE to standard output.
With more than one FILE, precede each with a header giving the file name.

  -n, --lines=[-]NUM   print the first NUM lines instead of the first 10;
                       with a leading '-', print all but the last NUM lines
  -c, --bytes=[-]NUM   print the first NUM bytes of each file
  -q, --quiet          never print headers giving file names
  -v, --verbose        always print headers giving file names
  -h, --help           display this help and exit
      --version        output version information and exit
"@

    $i = 0
    $noMoreOpts = $false
    while ($i -lt $ArgLine.Count) {
        $a = [string]$ArgLine[$i]; $i++
        if (-not $noMoreOpts -and $a -eq '--') { $noMoreOpts = $true; continue }
        if (-not $noMoreOpts -and $a -match '^--help$|^-h$') { Write-Output $usage; return 0 }
        if (-not $noMoreOpts -and $a -eq '--version') { Write-Output "head (Lindows) $script:LindowsVersion"; return 0 }
        if (-not $noMoreOpts -and $a -cmatch '^--quiet$|^--silent$|^-q$') { $quiet = $true; $verbose = $false; continue }
        if (-not $noMoreOpts -and $a -cmatch '^--verbose$|^-v$') { $verbose = $true; $quiet = $false; continue }

        if (-not $noMoreOpts -and $a -match '^--lines=(.+)$') {
            $linesCount = $Matches[1]; $bytesCount = $null; continue
        }
        if (-not $noMoreOpts -and $a -match '^--bytes=(.+)$') {
            $bytesCount = $Matches[1]; continue
        }
        if (-not $noMoreOpts -and ($a -eq '-n' -or $a -eq '--lines')) {
            if ($i -ge $ArgLine.Count) { [Console]::Error.WriteLine("head: option '$a' requires an argument"); $global:LASTEXITCODE = 1; return }
            $linesCount = [string]$ArgLine[$i]; $bytesCount = $null; $i++; continue
        }
        if (-not $noMoreOpts -and ($a -eq '-c' -or $a -eq '--bytes')) {
            if ($i -ge $ArgLine.Count) { [Console]::Error.WriteLine("head: option '$a' requires an argument"); $global:LASTEXITCODE = 1; return }
            $bytesCount = [string]$ArgLine[$i]; $i++; continue
        }
        if (-not $noMoreOpts -and $a -match '^-n(.+)$') {
            $linesCount = $Matches[1]; $bytesCount = $null; continue
        }
        if (-not $noMoreOpts -and $a -match '^-c(.+)$') {
            $bytesCount = $Matches[1]; continue
        }
        if (-not $noMoreOpts -and $a -match '^-(\d+)$') {
            $linesCount = $Matches[1]; $bytesCount = $null; continue
        }
        if (-not $noMoreOpts -and $a.StartsWith('-') -and $a.Length -gt 1) {
            [Console]::Error.WriteLine("head: invalid option -- '$a'")
            $global:LASTEXITCODE = 1; return
        }
        $files.Add($a)
    }

    if ($files.Count -eq 0) { $files.Add('-') }

    $out = New-Object System.Collections.Generic.List[string]
    $rc = 0
    $showHeader = ($verbose -or (-not $quiet -and $files.Count -gt 1))

    for ($fi = 0; $fi -lt $files.Count; $fi++) {
        $f = $files[$fi]
        $label = if ($f -eq '-') { 'standard input' } else { $f }

        try {
            if ($null -ne $bytesCount) {
                $raw = Read-LindowsInputBytes -FilePath $f -PipelineInput $pipeData
                $nStr = [string]$bytesCount
                $excludeLast = $nStr.StartsWith('-')
                $num = [int]($nStr.TrimStart('-', '+'))
                $take = if ($excludeLast) { [Math]::Max(0, $raw.Length - $num) } else { [Math]::Min($raw.Length, $num) }

                if ($showHeader) {
                    if ($fi -gt 0) { $out.Add('') }
                    $out.Add("==> $label <==")
                }
                if ($take -gt 0) {
                    $slice = New-Object byte[] $take
                    [Array]::Copy($raw, 0, $slice, 0, $take)
                    $out.Add([System.Text.Encoding]::UTF8.GetString($slice))
                }
            } else {
                $lines = Read-LindowsInputLines -FilePath $f -PipelineInput $pipeData
                $nStr = [string]$linesCount
                $excludeLast = $nStr.StartsWith('-')
                $num = [int]($nStr.TrimStart('-', '+'))
                $take = if ($excludeLast) { [Math]::Max(0, $lines.Count - $num) } else { [Math]::Min($lines.Count, $num) }

                if ($showHeader) {
                    if ($fi -gt 0) { $out.Add('') }
                    $out.Add("==> $label <==")
                }
                for ($k = 0; $k -lt $take; $k++) {
                    $out.Add($lines[$k])
                }
            }
        } catch {
            [Console]::Error.WriteLine("head: cannot open '$f' for reading: No such file or directory")
            $rc = 1
        }
    }

    if ($out.Count -gt 0) { $out | ForEach-Object { Write-Output $_ } }
    $global:LASTEXITCODE = $rc
}
