# Lindows

Lightweight Linux commands made available in Windows (PowerShell + CMD), organized into small modular scripts.

## Motivation

When running AI coding agents on Windows, almost all of them naturally assume they are operating in a Linux or macOS environment. They frequently invoke standard Unix commands—such as `grep`, `head`, `tail`, `which`, `tree`, etc.—expecting them to just work, and fail or waste turns when those commands aren't found in PowerShell or `cmd.exe`.

**Lindows** is a lightweight shim project built to bridge that gap so coding agents (and developers) running natively on Windows can find and run the Unix tools they expect.

## Commands Included

| Command | Source File | Description |
| :--- | :--- | :--- |
| `grep` | `src/grep.ps1` | Search for patterns in files or piped input (`-i`, `-v`, `-n`, `-c`, `-l`, `-r`, `-F`, `-E`, `-w`, `-A`/`-B`/`-C`) |
| `head` | `src/head.ps1` | Output the first part of files or piped input (`-n`, `-c`, `-q`, `-v`) |
| `tail` | `src/tail.ps1` | Output the last part of files or piped input (`-n`, `-n +K`, `-c`, `-f`, `-q`, `-v`) |
| `which` | `src/which.ps1` | Locate executables on Windows `PATH` (`-a`, `-i` for PowerShell aliases) |
| `tree` | `src/tree.ps1` | Recursive directory tree viewer (`-a`, `-d`, `-L`, `-P`, `-I`, `--dirsfirst`, `-h`, `-s`, `-D`) |
| `man` | `src/man.ps1` | View manual pages (`-f`, `-k`, `-w`) and PowerShell equivalents |
| `clear` | `src/meta.ps1` | Clear the terminal screen (`cls` shim in CMD, `Clear-Host` in PowerShell) |
| `lindows` | `src/meta.ps1` | Meta CLI (`lindows list`, `lindows doctor`, `lindows --version`) |

## Pairing with `uutils` Coreutils & `ripgrep`

For the rest of the standard GNU/Linux toolset (`ls`, `cat`, `cp`, `mv`, `rm`, `wc`, `sort`, `uniq`, `cut`, `tr`, `basename`, `dirname`, etc.) and fast code search (`rg`), you can install the native Windows Rust ports via `winget`:

```powershell
# GNU coreutils (ls, cat, cp, mv, rm, wc, sort, uniq, cut, tr, etc.)
winget install uutils.coreutils

# ripgrep (rg)
winget install BurntSushi.ripgrep.MSVC
```

Lindows works standalone with zero dependencies (providing `grep`, `head`, `tail`, `which`, `tree`, `man`, `clear` out of the box) or side-by-side with `uutils.coreutils` and `ripgrep` across both PowerShell and CMD.

## Project Structure

```text
lindows/
├── Lindows.psm1          # Root PowerShell module loader
├── install.ps1           # Installs module, CMD shims, and PATH/profile hooks
├── uninstall.ps1         # Cleanly removes Lindows
├── src/
│   ├── common.ps1        # Shared stdin / file / pipeline readers
│   ├── grep.ps1          # grep command
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
