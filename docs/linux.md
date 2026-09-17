# Linux configuration

## Stack

NixOS + Hyprland (Wayland compositor) + Dank Material Shell (DMS).

NixOS/Home Manager is the declarative source of truth for the Linux system,
packages, services, hardware, Hyprland, and DMS. Chezmoi is only for personal
dotfiles, templates, and scripts that are not managed by Nix. Never let both
repositories manage the same file.

This repository no longer bootstraps Linux packages. Pacman/AUR package lists
and the Arch/CachyOS installation script were removed. Package installation
belongs in the NixOS configuration.

## dot_config — key apps

| Path | Description |
| ------ | ------------- |
| `hypr/hyprland.conf` | Hyprland main config. Includes: `animations.conf`, `keybindings.conf`, `monitors.conf`, `windowrules.conf`, `userprefs.conf`, `shaders.conf`, `pyprland.toml` |
| `hypr/hypridle.conf` | Hypridle idle daemon config |
| `hypr/hyprlock/` | Hyprlock screen locker. `catppuccin/` and `vivek-hyprlock-styles/` are git submodules |
| `waybar/` | Waybar status bar config and CSS |
| `swaync/` | SwayNC notification center |
| `swayosd/` | OSD overlays (volume, brightness) |
| `kitty/` | Kitty terminal |
| `ghostty/` | Ghostty terminal |
| `dot_tmux.conf.tmpl` | Tmux multiplexer (`~/.tmux.conf`) |
| `zsh/` | Zsh-specific functions, aliases, and completions |
| `cliphist/` | Cliphist clipboard history |
| `nchat/` | Terminal chat client |
| `FreeTube/` | FreeTube YouTube frontend (settings are `.db`, gitignored) |
| `cava/` | Audio visualizer |
| `btop/` | Resource monitor |
| `yazi/` | File manager. `plugins/` and `flavors/` are gitignored — install with `ya pack` |

## dot_local/bin — scripts

All scripts use `$(chezmoi source-path)` instead of hardcoded paths.

| Script | Description |
| -------- | ------------- |
| `dotfiles-sync` | Sync: `chezmoi re-add` + git add/commit/push |
| `backup-packages` | Export user-level package/tool lists to `packages/linux/` |
| `restore-packages` | Reinstall supported user-level tools from `packages/linux/` lists |
| `list-packages` | List currently installed packages (legacy Arch-oriented helper; review before use on NixOS) |
| `secrets` | Manual secret refresh with `fzf`, backed by `packages/linux/system/secrets.json` |
| `bwp` | Bitwarden Plus CLI helpers with shell-independent runtime session |
| `web-search` | Search DDG, Google, Brave, Wikipedia, GitHub, Stack Overflow, or Arch Wiki with `w3m` |
| `docker-service` | Start, stop, or inspect Docker systemd service |
| `extract-claude-config` | Export Claude config docs to `other_config/claude/` |
| `cleanup` | System cleanup (cache, logs, orphan packages) |
| `prune` | Gum-interactive cache cleanup for npm/pnpm/bun/uv/go/dotnet/docker |
| `update-packages` | Interactive updater for user-level tools; do not use it to replace NixOS updates |
| `plymouth-themes` | Install/switch Plymouth boot themes from `other_config/plymouth/themes/` |
| `sddm-themes` | Install/switch SDDM login themes from `other_config/sddm/themes/` |
| `fontman` | Font manager helper |
| `migrate-aur` / `migrate-flatpak` | Legacy Arch/Flatpak migration helpers; not part of the NixOS workflow |
| `post-hyde-install` / `pre-hyde-install` | HyDE desktop environment install hooks |
| `openvpn-*` / `ikev2-*` | VPN management |

## Shell configs

| File | Shell |
| ------ | ------- |
| `dot_profile` | POSIX |

*Zsh config (`dot_config/zsh/`, root `dot_zshenv`) was dropped entirely —
Omarchy's own shell defaults are used instead. `dot_zprofile` still sources
`~/.profile` but nothing reads `.zprofile` itself anymore now that zsh is
gone — candidate for removal too, not done yet since it wasn't asked for.*

## Reference-only (other_config)

Not deployed by chezmoi — installed manually via scripts.

| Path | Description |
| ------ | ------------- |
| `other_config/plymouth/themes/` | Boot splash themes (4 submodules). Managed by `plymouth-themes` script |
| `other_config/sddm/themes/` | SDDM login themes (1 submodule). Managed by `sddm-themes` script |
| `other_config/system/` | Legacy/reference system configuration; NixOS owns the active system configuration |
| `other_config/system/sdboot/` | Systemd-boot config reference |
| `other_config/linux-cachyos-pollrate.toml` | USB polling rate config |
