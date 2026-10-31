function Invoke-LindowsTree {
    $ArgLine = @($args)

    $opts = @{
        all = $false; dirs = $false; full = $false; F = $false; i = $false
        L = 0; s = $false; h = $false; D = $false; t = $false; r = $false
        o = $null; dirsfirst = $false; prune = $false; charset = 'utf8'
    }
    $incPat = $null; $excPat = $null
    $dirs = @()

    $it = 0
    while ($it -lt $ArgLine.Count) {
        $a = $ArgLine[$it]; $it++
        if ($a -like '--charset=*') { $opts.charset = $a.Substring(10); continue }
        if ($a -eq '--dirsfirst') { $opts.dirsfirst = $true; continue }
        if ($a -eq '--prune') { $opts.prune = $true; continue }
        if ($a -eq '--version') { Write-Output "tree (Lindows) $script:LindowsVersion"; return 0 }
        if ($a -eq '--help') {
            Write-Output @"
Usage: tree [-a] [-d] [-f] [-F] [-i] [-L n] [-P pat] [-I pat] [-t] [-r] [-s] [-h] [-D] [-o file] [--dirsfirst] [dir...]
Recursive directory tree listing. Use -a to include hidden files.
"@
            return 0
        }
        if ($a -ne '--' -and $a -like '-*') {
            $chars = $a.TrimStart('-', '/').ToCharArray()
            for ($c = 0; $c -lt $chars.Count; $c++) {
                switch -CaseSensitive ([string]$chars[$c]) {
                    'a' { $opts.all = $true }
                    'd' { $opts.dirs = $true }
                    'f' { $opts.full = $true }
                    'F' { $opts.F = $true }
                    'i' { $opts.i = $true }
                    'P' { if ($it -lt $ArgLine.Count) { $incPat = $ArgLine[$it]; $it++ } }
                    'I' { if ($it -lt $ArgLine.Count) { $excPat = $ArgLine[$it]; $it++ } }
                    'L' { if ($it -lt $ArgLine.Count) { try { $opts.L = [int]$ArgLine[$it] } catch { }; $it++ } }
                    't' { $opts.t = $true }
                    'r' { $opts.r = $true }
                    's' { $opts.s = $true }
                    'h' { $opts.h = $true }
                    'D' { $opts.D = $true }
                    'o' { if ($it -lt $ArgLine.Count) { $opts.o = $ArgLine[$it]; $it++ } }
                    'q' { }
                    'n' { }
                    'x' { }
                    'N' { }
                    'C' { }
                    default {
                        [Console]::Error.WriteLine("tree: invalid option -- '$([string]$chars[$c])'")
                        $global:LASTEXITCODE = 1
                        return
                    }
                }
            }
        } else {
            $dirs += $a
        }
    }

    if ($dirs.Count -eq 0) { $dirs = @((Get-Location).ProviderPath) }

    $out = New-Object System.Collections.Generic.List[string]
    $execExts = @()
    if ($env:PATHEXT) { $execExts = ($env:PATHEXT -split ';' | ForEach-Object { $_.ToLower() }) }

    $counts = @{ dirs = 0; files = 0 }

    function Format-TreeSize([long]$b, [bool]$hum) {
        if (-not $hum) { return "$b" }
        if ($b -ge 1TB) { return ('{0:0.0}T' -f ($b / 1TB)) }
        if ($b -ge 1GB) { return ('{0:0.0}G' -f ($b / 1GB)) }
        if ($b -ge 1MB) { return ('{0:0.0}M' -f ($b / 1MB)) }
        if ($b -ge 1KB) { return ('{0:0.0}K' -f ($b / 1KB)) }
        return "$b"
    }

    function Walk-Trees([string]$path, [int]$depth, [string]$prefix) {
        if ($opts.L -gt 0 -and $depth -gt $opts.L) { return }
        $kids = Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if ($null -eq $kids) { return }

        $list = New-Object System.Collections.Generic.List[object]
        foreach ($k in $kids) {
            $isDir = $k.PSIsContainer
            if (-not $opts.all -and ($k.Name.StartsWith('.') -or (($k.Attributes -band [System.IO.FileAttributes]::Hidden) -ne 0))) { continue }
            if ($excPat -and $k.Name -like $excPat) { continue }
            if ($incPat -and (-not $isDir) -and (-not ($k.Name -like $incPat))) { continue }
            if ($opts.dirs -and -not $isDir) { continue }
            $list.Add($k)
        }

        $sorted = @()
        if ($opts.t) {
            $sorted = @($list | Sort-Object -Property @{ Expression = 'LastWriteTime'; Descending = (-not $opts.r) })
        } else {
            $sorted = @($list | Sort-Object -Property @{ Expression = 'Name'; Descending = $opts.r })
        }
        if ($opts.dirsfirst) {
            $dd = @($sorted | Where-Object { $_.PSIsContainer })
            $df = @($sorted | Where-Object { -not $_.PSIsContainer })
            $sorted = [object[]]$dd + [object[]]$df
        }

        $cnt = $sorted.Count
        $kk = 0
        foreach ($item in $sorted) {
            $last = ($kk -eq ($cnt - 1))
            $kk++
            if ($opts.charset -eq 'ascii') {
                $connector = if ($last) { '`-- ' } else { '|-- ' }
                $childBar = if ($last) { '   ' } else { '|   ' }
            } else {
                $connector = if ($last) { [string][char]0x2514 + [char]0x2500 + [char]0x2500 + ' ' } else { [string][char]0x251C + [char]0x2500 + [char]0x2500 + ' ' }
                $childBar = if ($last) { '   ' } else { [string][char]0x2502 + '  ' }
            }

            $name = if ($opts.full) { $item.FullName } else { $item.Name }
            $suffix = ''
            if ($opts.F -and $item.PSIsContainer) {
                $suffix = '/'
            } elseif ($opts.F) {
                $ext = [System.IO.Path]::GetExtension($item.Name).ToLower()
                if ($execExts -contains $ext) { $suffix = '*' }
            }
            $line = if ($opts.i) { "$name$suffix" } else { "$prefix$connector$name$suffix" }
            if ($opts.s) {
                $line = "$line  [$(Format-TreeSize $item.Length $opts.h)]"
            } elseif ($opts.D) {
                $line = "$line  [$($item.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))]"
            }
            $out.Add($line)
            if ($item.PSIsContainer) {
                $counts.dirs++
                $next = if ($opts.i) { '' } else { $prefix + $childBar }
                Walk-Trees $item.FullName ($depth + 1) $next
            } else {
                $counts.files++
            }
        }
    }

    foreach ($d in $dirs) {
        if (-not (Test-Path -LiteralPath $d -PathType Container)) {
            [Console]::Error.WriteLine("tree: $d`: No such directory")
            $global:LASTEXITCODE = 1
            return
        }
        $rootPath = (Resolve-Path -LiteralPath $d).ProviderPath
        $rootDisp = if ($opts.full) { $rootPath } else { $d.TrimEnd('\', '/') + '/' }
        $out.Add($rootDisp)
        Walk-Trees $rootPath 1 ''
    }

    if (-not $opts.i) { $out.Add("$($counts.dirs) directories, $($counts.files) files") }

    $text = [string]::Join("`n", $out.ToArray())
    if ($opts.o) {
        $op = if ([System.IO.Path]::IsPathRooted($opts.o)) { $opts.o } else { Join-Path (Get-Location).ProviderPath $opts.o }
        [System.IO.File]::WriteAllText($op, $text + "`n", (New-Object System.Text.UTF8Encoding($false)))
    } else {
        Write-Output $text
    }
    $global:LASTEXITCODE = 0
}
