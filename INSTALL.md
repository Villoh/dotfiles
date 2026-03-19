# Installation Guide

## Prerequisites

### Windows

1. **Developer Mode** — required for symlinks without elevation:
   `Settings → System → For developers → Developer Mode`

2. **Scoop** — install before running chezmoi (used for CLI tools, fonts, btop):
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   irm get.scoop.sh | iex
   ```

3. **Chocolatey** — install before running chezmoi (used for packages not in winget/scoop):
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```

4. **GPG** — required for encrypted files. Install via scoop, then import your key:
   ```powershell
   scoop install gpg
   gpg --import your-key.asc
   ```

### Linux

1. **HyDE** — this setup builds on top of [HyDE](https://github.com/HyDE-Project/HyDE). Install it first for the full Hyprland desktop.

2. **GPG** — import your key:
   ```bash
   gpg --import your-key.asc
   ```

---

## Install

```bash
chezmoi init --apply github.com/Villoh/dotfiles
```

> **Without GPG key** — skip encrypted files:
> ```bash
> chezmoi init github.com/Villoh/dotfiles
> chezmoi apply --exclude=encrypted
> ```

During `init --apply`, chezmoi will:
1. Clone the repo to `~/.local/share/chezmoi`
2. Prompt for module enable/disable options (all default to `true`)
3. Generate `~/.config/chezmoi/chezmoi.toml`
4. Create symlinks for all managed files

Then run scripts in this order (Windows only):

| # | Script | What it does |
|---|--------|--------------|
| 1 | `run_once_install-packages` | winget, scoop, chocolatey, npm, bun, uv, PowerShell modules |
| 2 | `run_once_restore-windhawk` | Import Windhawk settings from registry |
| 3 | `run_once_setup-windows-symlinks` | Create junctions for zed, yazi, vencord, btop |
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
```bash
# Windows
chezmoi execute-template < $(chezmoi source-path)/.chezmoiscripts/run_once_install-packages.ps1.tmpl | pwsh -File -

# Linux
chezmoi execute-template < $(chezmoi source-path)/.chezmoiscripts/my-script.sh.tmpl | bash
```
