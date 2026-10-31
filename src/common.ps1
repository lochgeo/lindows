function Get-LindowsStdinReader {
    if (-not [Console]::IsInputRedirected) { return $null }
    try {
        return New-Object System.IO.StreamReader([Console]::OpenStandardInput(), (New-Object System.Text.UTF8Encoding($false)))
    } catch {
        return [Console]::In
    }
}

function Read-LindowsInputLines {
    param(
        [string]$FilePath,
        [array]$PipelineInput
    )

    $lines = New-Object System.Collections.Generic.List[string]

    if ($FilePath -and $FilePath -ne '-') {
        if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
            throw "No such file or directory: $FilePath"
        }
        $resolved = (Resolve-Path -LiteralPath $FilePath).ProviderPath
        foreach ($line in [System.IO.File]::ReadLines($resolved)) {
            $lines.Add($line)
        }
        return ,$lines
    }

    if ($PipelineInput -and $PipelineInput.Count -gt 0) {
        foreach ($item in $PipelineInput) {
            if ($null -ne $item) {
                foreach ($sub in ([string]$item -split "`r?`n")) {
                    $lines.Add($sub)
                }
            }
        }
        return ,$lines
    }

    $reader = Get-LindowsStdinReader
    if ($null -ne $reader) {
        try {
            while ($null -ne ($line = $reader.ReadLine())) {
                $lines.Add($line)
            }
        } finally {
            $reader.Close()
        }
    }

    return ,$lines
}

function Read-LindowsInputBytes {
    param(
        [string]$FilePath,
        [array]$PipelineInput
    )

    if ($FilePath -and $FilePath -ne '-') {
        if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
            throw "No such file or directory: $FilePath"
        }
        $resolved = (Resolve-Path -LiteralPath $FilePath).ProviderPath
        return [System.IO.File]::ReadAllBytes($resolved)
    }

    if ($PipelineInput -and $PipelineInput.Count -gt 0) {
        $text = ($PipelineInput | ForEach-Object { [string]$_ }) -join "`n"
        return [System.Text.Encoding]::UTF8.GetBytes($text)
    }

    if ([Console]::IsInputRedirected) {
        $ms = New-Object System.IO.MemoryStream
        $stdin = [Console]::OpenStandardInput()
        try {
            $stdin.CopyTo($ms)
            return $ms.ToArray()
        } finally {
            $ms.Dispose()
        }
    }

    return [byte[]]@()
}
