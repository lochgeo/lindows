# Lindows

Lightweight Linux commands made available in Windows (PowerShell + CMD), organized into small modular scripts.

## Commands Included

| Command | Source File | Description |
| :--- | :--- | :--- |
| `head` | `src/head.ps1` | Output the first part of files or piped input (`-n`, `-c`, `-q`, `-v`) |
| `tail` | `src/tail.ps1` | Output the last part of files or piped input (`-n`, `-n +K`, `-c`, `-f`, `-q`, `-v`) |
| `which` | `src/which.ps1` | Locate executables on Windows `PATH` (`-a`, `-i` for PowerShell aliases) |
| `tree` | `src/tree.ps1` | Recursive directory tree viewer (`-a`, `-d`, `-L`, `-P`, `-I`, `--dirsfirst`, `-h`, `-s`, `-D`) |
| `man` | `src/man.ps1` | View manual pages (`-f`, `-k`, `-w`) and PowerShell equivalents |
| `clear` | `src/meta.ps1` | Clear the terminal screen (`cls` shim in CMD, `Clear-Host` in PowerShell) |
| `lindows` | `src/meta.ps1` | Meta CLI (`lindows list`, `lindows doctor`, `lindows --version`) |

## Project Structure

```text
lindows/
├── Lindows.psm1          # Root PowerShell module loader
├── install.ps1           # Installs module, CMD shims, and PATH/profile hooks
├── uninstall.ps1         # Cleanly removes Lindows
├── src/
│   ├── common.ps1        # Shared stdin / file / pipeline readers
│   ├── head.ps1          # head command
│   ├── tail.ps1          # tail command
│   ├── which.ps1         # which command
│   ├── tree.ps1          # tree command
│   ├── man.ps1           # man command & embedded pages
│   └── meta.ps1          # lindows & clear commands
└── tests/
    └── Lindows.Tests.ps1 # Automated test suite
```

## Quick Start

### Import directly in PowerShell
```powershell
Import-Module .\Lindows.psm1 -DisableNameChecking
```

### Install for PowerShell + CMD
```powershell
.\install.ps1
```
This copies the module to `%LOCALAPPDATA%\lindows`, creates `.cmd` shims in `%LOCALAPPDATA%\lindows\shims` (added to your User `PATH`), and hooks your PowerShell profile.

### Run Tests
```powershell
pwsh -NoProfile -File .\tests\Lindows.Tests.ps1
```
