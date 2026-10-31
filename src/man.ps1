$script:ManPages = @{
'lindows' = @'
LINDOWS(1)                      User Commands                     LINDOWS(1)

NAME
    lindows - lightweight Linux commands for Windows (PowerShell + CMD)

SYNOPSIS
    lindows [list|doctor|--help|--version]

DESCRIPTION
    Lindows provides essential Linux utilities natively on Windows:
    grep, head, tail, which, tree, man, clear, and lindows.

SUBCOMMANDS
    list      list the commands lindows provides
    doctor    check the installation (PATH, profile hook, shims)

SEE ALSO
    grep(1), head(1), tail(1), which(1), tree(1), man(1), clear(1)

Lindows 1.0.0                    2026                          LINDOWS(1)
'@
'grep' = @'
GREP(1)                         User Commands                        GREP(1)

NAME
    grep - print lines that match patterns

SYNOPSIS
    grep [-E|-F] [-ivwxnclLorHhq] [-e PATTERN] [-m NUM] [-A NUM] [-B NUM]
         [-C NUM] [--include=GLOB] [--exclude=GLOB] [PATTERN] [FILE]...

DESCRIPTION
    grep searches for PATTERN in each FILE or standard input and prints
    each line that matches.

OPTIONS
    -E, --extended-regexp     PATTERN is an extended regular expression
    -F, --fixed-strings       PATTERN is a literal string
    -i, --ignore-case         case-insensitive search
    -v, --invert-match        select non-matching lines
    -w, --word-regexp         match whole words only
    -x, --line-regexp         match whole lines only
    -n, --line-number         prefix each line with its 1-based line number
    -c, --count               print only a count of matching lines per file
    -l, --files-with-matches  print only names of files with matches
    -L, --files-without-match print only names of files with no matches
    -o, --only-matching       print only the matched parts of a matching line
    -r, -R, --recursive       search directories recursively
    -A, -B, -C NUM            print NUM lines of trailing/leading/both context

Lindows 1.0.0                    2026                            GREP(1)
'@
'head' = @'
HEAD(1)                         User Commands                        HEAD(1)

NAME
    head - output the first part of files

SYNOPSIS
    head [-n [+]NUM] [-c [+]NUM] [-q] [-v] [FILE]...

DESCRIPTION
    Print the first 10 lines of each FILE to standard output. With more
    than one FILE, precede each with a header giving the file name. With
    no FILE, or when FILE is -, read standard input.

OPTIONS
    -n, --lines=[-]NUM   print the first NUM lines instead of the first 10;
                         with a leading '-', print all but the last NUM lines
    -c, --bytes=[-]NUM   print the first NUM bytes of each file
    -q, --quiet          never print headers giving file names
    -v, --verbose        always print headers giving file names

Lindows 1.0.0                    2026                            HEAD(1)
'@
'tail' = @'
TAIL(1)                         User Commands                        TAIL(1)

NAME
    tail - output the last part of files

SYNOPSIS
    tail [-n [+]NUM] [-c [+]NUM] [-f] [-q] [-v] [FILE]...

DESCRIPTION
    Print the last 10 lines of each FILE to standard output. With more
    than one FILE, precede each with a header giving the file name. With
    no FILE, or when FILE is -, read standard input.

OPTIONS
    -n, --lines=[+]NUM   output the last NUM lines, or use -n +NUM to output
                         starting with line NUM
    -c, --bytes=[+]NUM   output the last NUM bytes
    -f, --follow         output appended data as the file grows
    -q, --quiet          never output headers giving file names
    -v, --verbose        always output headers giving file names

Lindows 1.0.0                    2026                            TAIL(1)
'@
'which' = @'
WHICH(1)                        User Commands                       WHICH(1)

NAME
    which - locate a command on the Windows PATH

SYNOPSIS
    which [-a] [-i] [--skip-alias] [--help] [--version] name...

DESCRIPTION
    Prints the PATH-resolved executable(s) for each name. Understands
    Windows executable extensions (.exe .cmd .bat .ps1). With -i also
    resolves PowerShell aliases.

OPTIONS
    -a, --all        print all matches in PATH order
    -i, --read-alias also resolve PowerShell aliases
    --skip-alias     cancel -i

Lindows 1.0.0                    2026                           WHICH(1)
'@
'man' = @'
MAN(1)                          Manual viewer                         MAN(1)

NAME
    man - show manual pages for lindows commands and Windows equivalents

SYNOPSIS
    man [-d] [-f] [-k] [-w] [-l FILE] NAME

DESCRIPTION
    Displays embedded lindows man pages, or shows the PowerShell /
    Microsoft.Coreutils equivalent for other common Linux commands.

OPTIONS
    -k, --apropos        search all pages for keyword
    -f, --whatis         one-line summaries
    -w, --path, --where  show whether the page exists (exit 0/1)
    -l FILE              display FILE as a local page

Lindows 1.0.0                    2026                             MAN(1)
'@
'tree' = @'
TREE(1)                     Directory listings                       TREE(1)

NAME
    tree - list contents of directories recursively, in a tree

SYNOPSIS
    tree [-a] [-d] [-f] [-F] [-i] [-L level] [-P pattern] [-I pattern]
         [--dirsfirst] [-t] [-r] [-s] [-h] [-D] [-o FILE] [--charset=C]
         [dir...]

DESCRIPTION
    Recursive tree listing of the given directory (or current directory).
    Hidden dot-prefixed files are listed only with -a.

Lindows 1.0.0                    2026                            TREE(1)
'@
'clear' = @'
CLEAR(1)                        User Commands                       CLEAR(1)

NAME
    clear - clear the terminal screen

DESCRIPTION
    Clears the terminal screen in PowerShell and CMD.

Lindows 1.0.0                    2026                           CLEAR(1)
'@
}

function Invoke-LindowsMan {
    $ArgLine = @($args)

    $apropos = $false; $whatis = $false; $where = $false; $dry = $false; $local = $null
    $names = @()
    $k = 0
    while ($k -lt $ArgLine.Count) {
        $a = $ArgLine[$k]; $k++
        if ($a -eq '--') { foreach ($r in @($ArgLine[$k..($ArgLine.Count - 1)])) { $names += $r }; break }
        switch -Regex -CaseSensitive ($a) {
            '^--apropos$|^-k$' { $apropos = $true }
            '^--whatis$|^-f$' { $whatis = $true }
            '^--path$|^--where$|^--whereis$|^-w$' { $where = $true }
            '^--debug$|^-d$' { $dry = $true }
            '^--local$|^-l$' { if ($k -lt $ArgLine.Count) { $local = $ArgLine[$k]; $k++ } }
            '^--help$|^-h$' { Write-Output "Usage: man [-dfkwl] NAME"; return 0 }
            '^--version$' { Write-Output "man (Lindows) $script:LindowsVersion"; return 0 }
            Default { $names += $a }
        }
    }
    if ($dry) { $where = $true }
    if (-not $apropos -and -not $whatis -and -not $local -and $names.Count -eq 0) {
        [Console]::Error.WriteLine('What manual page do you want?')
        $global:LASTEXITCODE = 1
        return
    }
    $out = New-Object System.Collections.Generic.List[string]

    $emitPage = {
        param([string]$t)
        if ($script:ManPages.ContainsKey($t)) {
            if ($where) { $out.Add("embedded page: $t (Lindows)"); return 0 }
            if ($whatis) {
                $nl = $script:ManPages[$t] -split "`n" | Where-Object { $_ -match '^    [A-Za-z0-9]+ - ' } | Select-Object -First 1
                if ($nl) { $out.Add($nl.Trim()) }
                return 0
            }
            $out.Add($script:ManPages[$t])
            return 0
        }
        $core = @{
            'ls' = 'Get-ChildItem (PowerShell built-in)'; 'cp' = 'Copy-Item'; 'mv' = 'Move-Item'
            'rm' = 'Remove-Item'; 'cat' = 'Get-Content'; 'wc' = 'Measure-Object -Line -Word -Character'
            'grep' = 'Select-String'; 'find' = 'Get-ChildItem -Recurse -Filter'
            'sort' = 'Sort-Object'; 'basename' = 'Split-Path -Leaf'; 'dirname' = 'Split-Path'
            'kill' = 'Stop-Process'; 'ps' = 'Get-Process'; 'less' = 'more.com'
            'diff' = 'Compare-Object'; 'touch' = 'New-Item -ItemType File'; 'date' = 'Get-Date'
        }
        if ($core.ContainsKey($t)) {
            $out.Add("No manual entry for $t")
            $out.Add("")
            $out.Add("    PowerShell equivalent: $($core[$t])")
            $out.Add("    Or install GNU coreutils via: winget install Microsoft.Coreutils")
            return 3
        }
        $out.Add("No manual entry for $t")
        return 3
    }

    $rc = 0
    if ($local) {
        if (Test-Path -LiteralPath $local) {
            $out.Add([System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $local).ProviderPath))
        } else {
            [Console]::Error.WriteLine("man: $local`: No such file")
            $rc = 3
        }
    } elseif ($apropos) {
        $pat = if ($names.Count -gt 0) { $names[0] } else { '' }
        foreach ($key in ($script:ManPages.Keys | Sort-Object)) {
            $p = $script:ManPages[$key]
            if ($pat -eq '' -or $p -match [regex]::Escape($pat)) {
                $sum = ($p -split "`n" | Where-Object { $_ -match ' - ' } | Select-Object -First 1)
                if ($sum) { $out.Add($sum.Trim()) } else { $out.Add("$key - (Lindows)") }
            }
        }
        if ($out.Count -eq 0) { $out.Add("Nothing appropriate for '$pat'") }
    } else {
        foreach ($t in $names) {
            $r = & $emitPage $t
            if ($r -ne 0) { $rc = $r }
        }
    }
    if ($out.Count) { Write-Output ($out -join "`n") }
    $global:LASTEXITCODE = $rc
}
