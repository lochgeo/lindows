function Invoke-LindowsWhich {
    $ArgLine = @($args)

    $all = $false
    $readAlias = $false
    $skipAlias = $false
    $names = @()

    foreach ($a in $ArgLine) {
        switch -Regex -CaseSensitive ($a) {
            '^(--all|-a)$' { $all = $true }
            '^(--read-alias|-i)$' { $readAlias = $true }
            '^--skip-alias$' { $skipAlias = $true }
            '^(--show-dot|--show-tilde|--tty-only)$' { }
            '^(--help|-h)$' {
                Write-Output @"
Usage: which [-a] [-i] [--skip-alias] [--help] name...
Locate a command on the Windows PATH (or resolve a PowerShell alias).
  -a, --all         print all matching executables in PATH
  -i, --read-alias  also resolve PowerShell aliases for the name
"@
                return 0
            }
            '^--version$' { Write-Output "which (Lindows) $script:LindowsVersion"; return 0 }
            Default { $names += $a }
        }
    }

    if ($names.Count -eq 0) {
        [Console]::Error.WriteLine('Usage: which [-a] name ...')
        $global:LASTEXITCODE = 1
        return
    }
    if ($skipAlias) { $readAlias = $false }

    $exts = @('', '.exe', '.cmd', '.bat', '.ps1', '.com')
    $rc = 0
    $out = New-Object System.Collections.Generic.List[string]

    foreach ($nm in $names) {
        $found = $false
        if ($readAlias) {
            $alias = Get-Alias -Name $nm -ErrorAction SilentlyContinue
            if ($alias) {
                $out.Add("alias: $nm -> $($alias.Definition)")
                $found = $true
            }
        }
        if ($nm -match '[\\/]') {
            if (Test-Path -LiteralPath $nm) {
                $out.Add($nm)
                $found = $true
            }
            if (-not $found) { $rc = 1 }
            continue
        }
        $dirs = $env:Path -split ';' | Where-Object { $_ }
        foreach ($d in $dirs) {
            foreach ($e in $exts) {
                $cand = Join-Path $d ($nm + $e)
                if (Test-Path -LiteralPath $cand -PathType Leaf) {
                    $out.Add((Resolve-Path -LiteralPath $cand).ProviderPath)
                    $found = $true
                    if (-not $all) { break }
                }
            }
            if ($found -and -not $all) { break }
        }
        if (-not $found) { $rc = 1 }
    }

    if ($out.Count) { Write-Output ($out -join "`n") }
    $global:LASTEXITCODE = $rc
}
