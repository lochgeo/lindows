#requires -Version 5.1
# Lindows.psm1 - Lightweight Linux commands for Windows (PowerShell + CMD)
# Commands: grep, find, head, tail, wc, touch, cat, rm, mkdir, lsof, pkill, which, tree, man, clear, lindows

$script:LindowsVersion = '1.0.0'

$srcFiles = @(
    'common.ps1'
    'grep.ps1'
    'find.ps1'
    'head.ps1'
    'tail.ps1'
    'wc.ps1'
    'touch.ps1'
    'fs.ps1'
    'proc.ps1'
    'which.ps1'
    'tree.ps1'
    'man.ps1'
    'meta.ps1'
)

foreach ($file in $srcFiles) {
    . (Join-Path $PSScriptRoot "src\$file")
}

# Override built-in PowerShell aliases/functions that collide with Unix syntax
Remove-Item -Path Alias:man -Force -ErrorAction SilentlyContinue
Remove-Item -Path Alias:cat -Force -ErrorAction SilentlyContinue
Remove-Item -Path Alias:rm -Force -ErrorAction SilentlyContinue
Remove-Item -Path Function:mkdir -Force -ErrorAction SilentlyContinue

function man   { $input | Invoke-LindowsMan @args }
function cat   { $input | Invoke-LindowsCat @args }
function rm    { Invoke-LindowsRm @args }
function mkdir { Invoke-LindowsMkdir @args }

Set-Alias -Name grep    -Value Invoke-LindowsGrep
Set-Alias -Name find    -Value Invoke-LindowsFind
Set-Alias -Name head    -Value Invoke-LindowsHead
Set-Alias -Name tail    -Value Invoke-LindowsTail
Set-Alias -Name wc      -Value Invoke-LindowsWc
Set-Alias -Name touch   -Value Invoke-LindowsTouch
Set-Alias -Name lsof    -Value Invoke-LindowsLsof
Set-Alias -Name pkill   -Value Invoke-LindowsPkill
Set-Alias -Name killall -Value Invoke-LindowsPkill
Set-Alias -Name which   -Value Invoke-LindowsWhich
Set-Alias -Name tree    -Value Invoke-LindowsTree
Set-Alias -Name lindows -Value Invoke-LindowsMeta

Export-ModuleMember -Function @(
    'Invoke-LindowsGrep'
    'Invoke-LindowsFind'
    'Invoke-LindowsHead'
    'Invoke-LindowsTail'
    'Invoke-LindowsWc'
    'Invoke-LindowsTouch'
    'Invoke-LindowsCat'
    'Invoke-LindowsRm'
    'Invoke-LindowsMkdir'
    'Invoke-LindowsLsof'
    'Invoke-LindowsPkill'
    'Invoke-LindowsWhich'
    'Invoke-LindowsTree'
    'Invoke-LindowsMan'
    'Invoke-LindowsClear'
    'Invoke-LindowsMeta'
    'man'
    'cat'
    'rm'
    'mkdir'
) -Alias @(
    'grep'
    'find'
    'head'
    'tail'
    'wc'
    'touch'
    'lsof'
    'pkill'
    'killall'
    'which'
    'tree'
    'lindows'
)
