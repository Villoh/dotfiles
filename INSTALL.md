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

| # | Script | What it does |
|---|--------|--------------|
| 1 | `run_once_00_install-packages` | Enable Developer Mode, bootstrap scoop + choco, then winget, scoop, npm, bun, uv, bin |
| 2 | `run_once_10_setup-windows-symlinks` | Create junctions for zed, yazi, vencord, btop |
| 3 | `run_onchange_install-ditto-themes` | Copy Ditto XML themes to `Program Files` |
| 4 | `run_onchange_install-nilesoft-imports` | Copy Nilesoft `.nss` imports to `Program Files` |

---

## Post-install

### Linux

Init submodules (sddm/plymouth themes):
```bash
cd ~/.local/share/chezmoi && git submodule update --init --recursive
```

### Windows

The symlinks script creates these junctions pointing directly to the chezmoi source:

| Junction | → Chezmoi source |
|----------|-----------------|
| `%APPDATA%\Zed` | `dot_config/zed` |
| `%APPDATA%\yazi\config` | `dot_config/yazi` |
| `%APPDATA%\Vencord\settings` | `dot_config/vesktop/settings` |
| `~/scoop/persist/btop/btop.conf` | `dot_config/btop/btop.conf` |
| `~/scoop/persist/btop/themes` | `dot_config/btop/themes` |

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

### Arch Linux in WSL

Installs Arch in WSL, configures locale, and installs packages from `wsl-pacman-packages.txt` and `wsl-aur-packages.txt`:

```powershell
setup-wsl-arch
```

> Requires WSL installed (included in winget packages). First run will open an interactive terminal for Arch first-time setup (username/password).

---

## Re-running scripts

Force re-run all `run_once_` scripts on next apply:
```bash
chezmoi state delete-bucket --bucket=scriptState && chezmoi apply
```

Run a specific script manually (renders the template first):
```powershell
# Windows
Get-Content "$(chezmoi source-path)\.chezmoiscripts\run_once_00_install-packages.ps1.tmpl" | chezmoi execute-template | powershell -NoProfile -Command -

# Linux
chezmoi execute-template "$(chezmoi source-path)/.chezmoiscripts/my-script.sh.tmpl" | bash
```
