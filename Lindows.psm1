#requires -Version 5.1
# Lindows.psm1 - Lightweight Linux commands for Windows (PowerShell + CMD)
# Commands: grep, head, tail, which, tree, man, clear, lindows

$script:LindowsVersion = '1.0.0'

$srcFiles = @(
    'common.ps1'
    'grep.ps1'
    'head.ps1'
    'tail.ps1'
    'which.ps1'
    'tree.ps1'
    'man.ps1'
    'meta.ps1'
)

foreach ($file in $srcFiles) {
    . (Join-Path $PSScriptRoot "src\$file")
}

function man {
    $input | Invoke-LindowsMan @args
}

Set-Alias -Name grep -Value Invoke-LindowsGrep
Set-Alias -Name head -Value Invoke-LindowsHead
Set-Alias -Name tail -Value Invoke-LindowsTail
Set-Alias -Name which -Value Invoke-LindowsWhich
Set-Alias -Name tree -Value Invoke-LindowsTree
Set-Alias -Name lindows -Value Invoke-LindowsMeta
Remove-Item -Path Alias:man -Force -ErrorAction SilentlyContinue

Export-ModuleMember -Function @(
    'Invoke-LindowsGrep'
    'Invoke-LindowsHead'
    'Invoke-LindowsTail'
    'Invoke-LindowsWhich'
    'Invoke-LindowsTree'
    'Invoke-LindowsMan'
    'Invoke-LindowsClear'
    'Invoke-LindowsMeta'
    'man'
) -Alias @(
    'grep'
    'head'
    'tail'
    'which'
    'tree'
    'lindows'
)
