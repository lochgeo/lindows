$script:ManPages = @{
'lindows' = @'
LINDOWS(1)                      User Commands                     LINDOWS(1)

NAME
    lindows - lightweight Linux commands for Windows (PowerShell + CMD)

SYNOPSIS
    lindows [list|doctor|--help|--version]

DESCRIPTION
    Lindows provides essential Linux utilities natively on Windows:
    grep, find, head, tail, wc, touch, cat, rm, mkdir, lsof, pkill,
    which, tree, man, clear, and lindows.

SUBCOMMANDS
    list      list the commands lindows provides
    doctor    check the installation (PATH, profile hook, shims)

SEE ALSO
    grep(1), find(1), head(1), tail(1), wc(1), touch(1), cat(1), rm(1),
    mkdir(1), lsof(1), pkill(1), which(1), tree(1), man(1), clear(1)

Lindows 1.0.0                    2026                          LINDOWS(1)
'@
'find' = @'
FIND(1)                         User Commands                        FIND(1)

NAME
    find - search for files in a directory hierarchy

SYNOPSIS
    find [PATH...] [-name PATTERN] [-iname PATTERN] [-path PATTERN]
         [-type f|d] [-maxdepth N] [-mindepth N] [-empty] [-not] [-delete]

DESCRIPTION
    Searches the directory tree rooted at each PATH (defaults to '.')
    and evaluates the given expression.

Lindows 1.0.0                    2026                            FIND(1)
'@
'wc' = @'
WC(1)                           User Commands                          WC(1)

NAME
    wc - print newline, word, and byte counts for each file

SYNOPSIS
    wc [-l] [-w] [-c] [-m] [FILE]...

DESCRIPTION
    Print newline (-l), word (-w), char (-m), and byte (-c) counts for
    each FILE or standard input.

Lindows 1.0.0                    2026                              WC(1)
'@
'touch' = @'
TOUCH(1)                        User Commands                       TOUCH(1)

NAME
    touch - change file timestamps or create empty files

SYNOPSIS
    touch [-c] [-a] [-m] FILE...

DESCRIPTION
    Update the access and modification times of each FILE to the current
    time. Creates empty files if they do not exist (unless -c is passed).

Lindows 1.0.0                    2026                           TOUCH(1)
'@
'cat' = @'
CAT(1)                          User Commands                         CAT(1)

NAME
    cat - concatenate files and print on the standard output

SYNOPSIS
    cat [-n] [-b] [-s] [-E] [FILE]...

DESCRIPTION
    Concatenate FILE(s) or standard input to standard output. Supports
    line numbering (-n, -b), squeezing blank lines (-s), and showing line
    endings (-E).

Lindows 1.0.0                    2026                             CAT(1)
'@
'rm' = @'
RM(1)                           User Commands                          RM(1)

NAME
    rm - remove files or directories

SYNOPSIS
    rm [-r] [-f] [-v] FILE...

DESCRIPTION
    Remove (unlink) the FILE(s). Supports Unix-style combined flags like
    rm -rf and rm -f without failing in PowerShell.

Lindows 1.0.0                    2026                              RM(1)
'@
'mkdir' = @'
MKDIR(1)                        User Commands                       MKDIR(1)

NAME
    mkdir - make directories

SYNOPSIS
    mkdir [-p] [-v] DIRECTORY...

DESCRIPTION
    Create the DIRECTORY(ies), if they do not already exist. Supports
    mkdir -p to create parent directories without error.

Lindows 1.0.0                    2026                           MKDIR(1)
'@
'lsof' = @'
LSOF(1)                         User Commands                        LSOF(1)

NAME
    lsof - list open network ports and owning processes

SYNOPSIS
    lsof [-i [:PORT]] [-t] [-p PID]

DESCRIPTION
    Lists active TCP/UDP network connections and their owning PIDs on
    Windows. Use lsof -i :3000 to inspect port 3000, or lsof -t -i :3000
    to output only the PID.

Lindows 1.0.0                    2026                            LSOF(1)
'@
'pkill' = @'
PKILL(1)                        User Commands                       PKILL(1)

NAME
    pkill - look up or signal processes based on name and command line

SYNOPSIS
    pkill [-f] [-i] [-x] [-l] [-c] PATTERN

DESCRIPTION
    Terminates processes matching PATTERN. Use -f to match against the
    full command line, or -l to list matching processes without stopping
    them.

Lindows 1.0.0                    2026                           PKILL(1)
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
            $out.Add("    Or install GNU coreutils via: winget install uutils.coreutils")
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
