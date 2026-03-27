# Installation Guide

> [!WARNING]
> **This installation is not 100% tested and is still under construction. Use at your own risk.**

> [!NOTE]
> Package selection is interactive — the install script uses [fzf](https://github.com/junegunn/fzf) to let you pick exactly which packages to install. You can also review and edit the lists beforehand in [`packages/windows/`](packages/windows/) (Windows) or [`packages/linux/`](packages/linux/) (Linux).

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

chezmoi runs scripts automatically in this order:

**Phase 1 — after files (run_once / run_onchange, alphabetical):**

| Script | What it does |
|--------|--------------|
| `run_once_windows-install` *(Windows)* | Bootstrap (Scoop, fzf, Dev Mode, Node, Bun, uv, bin) + interactive package install (winget, scoop, npm, bun, uv, PowerShell modules, bin, cargo) + GlazeWM win-keys |
| `run_onchange_windows-setup` *(Windows)* | Junctions, startup registry entries, program files (Ditto/Nilesoft/themes/cursors), accent color, theme |
| `run_once_linux-install` *(Linux)* | Git submodules, bootstrap (paru, flatpak, Node, Bun, uv, bin) + packages (pacman/AUR, flatpak, npm, bun, uv, bin) |

> `run_once_` sorts before `run_onchange_` alphabetically, so install always runs before setup.

**Phase 2 — after everything (run_after, alphabetical):**

| Script | What it does |
|--------|--------------|
| `run_onchange_after_windows-wallpaper` *(Windows)* | Desktop wallpaper + lock screen (runs after symlinks are guaranteed to exist) |

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

> Requires WSL installed (included in winget packages). Uses fzf to pick the distro — locale, user creation, and packages are configured automatically.

### Spicetify Marketplace

The Marketplace config (theme + extensions) is backed up at `other_config/spicetify/spicetify-marketplace.json`.

**Current setup:**
- Theme: **Comfy** — scheme `catppuccin-mocha`
- Extensions: Shuffle+, Bookmark, Full Screen, adblockify

1. Install Spicetify and patch Spotify:
   ```powershell
   winget install Spicetify.Spicetify
   spicetify backup apply
   ```

2. Install Spicetify Marketplace:
   ```powershell
   iwr -useb https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.ps1 | iex
   ```

3. Open Spotify → **Marketplace → Settings (gear icon) → Import backup** → load `other_config/spicetify/spicetify-marketplace.json`.

Marketplace will reinstall the theme and all extensions automatically.

> To update the backup: **Marketplace → Settings → Export backup** → overwrite the file → commit with `chore(spicetify): update marketplace backup`.

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
reset-run-onchange-script windows-wallpaper && chezmoi apply

# Re-run all run_onchange_ scripts on next apply
reset-run-onchange-script && chezmoi apply
```

Run a script manually without resetting state (renders the template first):
```powershell
# Windows
Get-Content "$(chezmoi source-path)\.chezmoiscripts\run_once_windows-install.ps1.tmpl" |
    chezmoi execute-template | powershell -NoProfile -Command -

# Linux
chezmoi execute-template "$(chezmoi source-path)/.chezmoiscripts/run_once_linux-install.sh.tmpl" | bash
```
