# Lindows

Lightweight Linux commands made available in Windows (PowerShell + CMD), organized into small modular scripts.

🌐 **Documentation & Project Page:** [https://lochgeo.github.io/lindows/](https://lochgeo.github.io/lindows/)

## Quick Install

Want to try Lindows? Open PowerShell and run this one-liner to install **Lindows**, **GNU Coreutils**, and **ripgrep** in one go:

```powershell
irm https://raw.githubusercontent.com/lochgeo/lindows/main/install.ps1 | iex
```

That's it!

*(Or if you've cloned this repo locally, run `.\install.ps1`. Pass `-SkipExtras` if you only want the Lindows shims without running `winget` for `Microsoft.Coreutils` and `ripgrep`.)*

---

## Motivation — Why `Microsoft.Coreutils` Alone Isn't Enough

When running AI coding agents on Windows (Claude Code, OpenCode, Cursor, Codex, etc.), almost all of them naturally assume they are operating in a Linux or macOS environment.

Even if you install `Microsoft.Coreutils` via `winget`, coding agents still fail constantly on Windows because of **three major gaps**:

1. **PowerShell Built-in Alias Collisions:** PowerShell aliases and functions take higher precedence than `PATH` executables. Even with `Microsoft.Coreutils` installed, when an agent runs `rm -rf dist`, `mkdir -p a/b/c`, or `cat -n file.txt`, PowerShell intercepts the command with its own built-in aliases (`Remove-Item`, `mkdir`, `Get-Content`) and crashes on the Unix flags! **Lindows overrides those colliding PowerShell aliases so Unix flags work.**
2. **`System32\find.exe` & `tree.com` Shadowing:** Windows ships legacy `C:\Windows\System32\find.exe` and `tree.com` at the top of the system `PATH`. When an agent runs `find . -name "*.ts"` or `tree -L 2 -I node_modules`, Windows invokes the legacy DOS binaries and fails (`FIND: Parameter format not correct`). **Lindows intercepts `find` and `tree` so Unix syntax works.**
3. **Tools Not Included in `Microsoft.Coreutils`:** `Microsoft.Coreutils` only ships basic file/text coreutils. It **does not include** `grep`, `which`, `lsof` (for `lsof -i :3000` port checks), `pkill` / `killall` (for stopping background dev servers), `tree`, or `man`. **Lindows provides all of them out of the box.**

## Commands Included in Lindows

| Command | Source File | Description |
| :--- | :--- | :--- |
| `grep` | `src/grep.ps1` | Search for patterns in files or piped input (`-i`, `-v`, `-n`, `-c`, `-l`, `-r`, `-F`, `-E`, `-w`, `-A`/`-B`/`-C`) |
| `find` | `src/find.ps1` | Search directory trees (`-name`, `-iname`, `-path`, `-type f\|d`, `-maxdepth`, `-mindepth`, `-not`/`!`, `-empty`, `-delete`) |
| `head` | `src/head.ps1` | Output the first part of files or piped input (`-n`, `-c`, `-q`, `-v`) |
| `tail` | `src/tail.ps1` | Output the last part of files or piped input (`-n`, `-n +K`, `-c`, `-f`, `-q`, `-v`) |
| `wc` | `src/wc.ps1` | Count lines, words, characters, and bytes (`-l`, `-w`, `-c`, `-m`) |
| `touch` | `src/touch.ps1` | Create empty files or update file timestamps (`-c`, `-a`, `-m`) |
| `cat` | `src/fs.ps1` | Concatenate and print files with Unix flags (`-n`, `-b`, `-s`, `-E`) |
| `rm` | `src/fs.ps1` | Remove files and directories with Unix flags (`rm -rf`, `rm -f`, `rm -r`) |
| `mkdir` | `src/fs.ps1` | Create directories with Unix flags (`mkdir -p`, `mkdir -v`) |
| `lsof` | `src/proc.ps1` | List open network ports and owning PIDs (`lsof -i :3000`, `lsof -t -i :3000`, `lsof -p PID`) |
| `pkill` / `killall` | `src/proc.ps1` | Find or stop processes by name or command line (`pkill -f`, `pkill -l`, `pkill -c`) |
| `which` | `src/which.ps1` | Locate executables on Windows `PATH` (`-a`, `-i` for PowerShell aliases) |
| `tree` | `src/tree.ps1` | Recursive directory tree viewer (`-a`, `-d`, `-L`, `-P`, `-I`, `--dirsfirst`, `-h`, `-s`, `-D`) |
| `man` | `src/man.ps1` | View manual pages (`-f`, `-k`, `-w`) and PowerShell equivalents |
| `clear` | `src/meta.ps1` | Clear the terminal screen (`cls` shim in CMD, `Clear-Host` in PowerShell) |
| `lindows` | `src/meta.ps1` | Meta CLI (`lindows list`, `lindows doctor`, `lindows --version`) |

## Pairing with `Microsoft.Coreutils` & `ripgrep`

The installer automatically installs `Microsoft.Coreutils` and `ripgrep` via `winget` so your environment also has the rest of the standard GNU/Linux toolset (`ls`, `cp`, `mv`, `sort`, `uniq`, `cut`, `tr`, `basename`, `dirname`, `rg`, etc.). You can also install them manually:

```powershell
# GNU coreutils for Windows (ls, cp, mv, sort, uniq, cut, tr, etc.)
winget install Microsoft.Coreutils

# ripgrep (rg)
winget install BurntSushi.ripgrep.MSVC
```

## Project Structure

```text
lindows/
├── Lindows.psm1          # Root PowerShell module loader
├── install.ps1           # One-step installer (Lindows + coreutils + ripgrep)
├── uninstall.ps1         # Cleanly removes Lindows
├── docs/
│   └── index.html        # GitHub Pages documentation site
├── src/
│   ├── common.ps1        # Shared stdin / file / pipeline readers
│   ├── grep.ps1          # grep command
│   ├── find.ps1          # find command
│   ├── head.ps1          # head command
│   ├── tail.ps1          # tail command
│   ├── wc.ps1            # wc command
│   ├── touch.ps1         # touch command
│   ├── fs.ps1            # cat, rm, and mkdir commands
│   ├── proc.ps1          # lsof and pkill/killall commands
│   ├── which.ps1         # which command
│   ├── tree.ps1          # tree command
│   ├── man.ps1           # man command & embedded pages
│   └── meta.ps1          # lindows & clear commands
└── tests/
    └── Lindows.Tests.ps1 # Automated test suite
```

## Development & Testing

```powershell
# Load module into current session without installing
Import-Module .\Lindows.psm1 -DisableNameChecking

# Run automated test suite
pwsh -NoProfile -File .\tests\Lindows.Tests.ps1
```
