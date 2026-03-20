# Installation Guide

> [!WARNING]
> Before running, review the package lists in [`packages/windows/`](packages/windows/) (Windows) or [`packages/linux/`](packages/linux/) (Linux) and remove anything you don't want installed.
> **This installation is not 100% tested and is still under construction. Use at your own risk.**

## Prerequisites

### Windows

Install **Git** and **chezmoi** via winget:

```powershell
winget install -e --id Git.Git
winget install -e --id twpayne.chezmoi
```

### Linux

Install **Git** and **chezmoi** via pacman:

```bash
sudo pacman -S git chezmoi
```

---

## Install

**With GPG key** (full install):
```bash
chezmoi init --apply github.com/Villoh/dotfiles
```

**Without GPG key** (skips encrypted files like `sshcontrol`):
```bash
chezmoi init --apply --exclude=encrypted github.com/Villoh/dotfiles
```

During `init --apply`, chezmoi will:
1. Clone the repo to `~/.local/share/chezmoi`
2. Prompt for module enable/disable options (all default to `true`)
3. Generate `~/.config/chezmoi/chezmoi.toml`
4. Create symlinks for all managed files

Then run scripts in this order (Windows only):

| Script | What it does |
|--------|--------------|
| `run_once_00_install-packages` | Developer Mode, Scoop, winget, npm, cargo, uv packages, win-keys |
| `run_onchange_windows-setup` | Junctions, startup registry entries, program files, cursor schemes |

---

## Manual steps (Windows)

Some steps require manual intervention and are exposed as PowerShell functions available in any session after install.

### Windhawk

Windhawk launches automatically on install. First install your desired mods inside the app, then close it completely and run:

```powershell
restore-windhawk
```

### GPG as SSH agent

Only needed if you want to use your GPG authentication subkey for SSH:

```powershell
setup-gpg-ssh
```

### WSL distro setup

Launches an fzf picker to select a distro, installs it, and sets up packages (Arch: locale + pacman + AUR):

```powershell
setup-wsl
```

> Requires WSL installed (included in winget packages). First run will open an interactive terminal for first-time distro setup (username/password).

---

## Re-running scripts

chezmoi tracks script state in two buckets:
- `scriptState` — `run_once_` scripts, keyed by content hash
- `entryState` — `run_onchange_` scripts, keyed by destination path

```powershell
# Re-run all run_once_ scripts on next apply
reset-run-once-scripts && chezmoi apply

# Re-run a specific run_onchange_ script on next apply
reset-run-onchange-script windows-setup && chezmoi apply

# Re-run all run_onchange_ scripts on next apply
reset-run-onchange-script && chezmoi apply
```

Run a script manually without resetting state (renders the template first):
```powershell
# Windows
Get-Content "$(chezmoi source-path)\.chezmoiscripts\run_once_00_install-packages.ps1.tmpl" |
    chezmoi execute-template | powershell -NoProfile -Command -

# Linux
chezmoi execute-template "$(chezmoi source-path)/.chezmoiscripts/my-script.sh.tmpl" | bash
```
