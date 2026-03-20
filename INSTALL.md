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

```bash
chezmoi init --apply github.com/Villoh/dotfiles
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
| 2 | `run_once_10_restore-windhawk` | Import Windhawk settings from registry |
| 3 | `run_once_20_setup-windows-symlinks` | Create junctions for zed, yazi, vencord, btop |
| 4 | `run_onchange_install-ditto-themes` | Copy Ditto XML themes to `Program Files` |
| 5 | `run_onchange_install-nilesoft-imports` | Copy Nilesoft `.nss` imports to `Program Files` |

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
