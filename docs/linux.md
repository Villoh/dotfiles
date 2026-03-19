# Linux configuration

## Stack

CachyOS (Arch-based) + Hyprland (Wayland compositor).

## dot_config — key apps

| Path | Description |
|------|-------------|
| `hypr/hyprland.conf` | Hyprland main config. Includes: `animations.conf`, `keybindings.conf`, `monitors.conf`, `windowrules.conf`, `userprefs.conf`, `shaders.conf`, `pyprland.toml` |
| `hypr/hypridle.conf` | Hypridle idle daemon config |
| `hypr/hyprlock/` | Hyprlock screen locker. `catppuccin/` and `vivek-hyprlock-styles/` are git submodules |
| `waybar/` | Waybar status bar config and CSS |
| `swaync/` | SwayNC notification center |
| `swayosd/` | OSD overlays (volume, brightness) |
| `kitty/` | Kitty terminal |
| `ghostty/` | Ghostty terminal |
| `tmux/` | Tmux multiplexer |
| `zsh/` | Zsh functions, aliases, completions. `functions/bitwarden.zsh` holds sensitive helpers |
| `cliphist/` | Cliphist clipboard history |
| `aerc/` | Aerc terminal email client. `aerc.template.conf` is the base template |
| `nchat/` | Terminal chat client |
| `FreeTube/` | FreeTube YouTube frontend (settings are `.db`, gitignored) |
| `fastfetch/` | System info display config |
| `cava/` | Audio visualizer |
| `btop/` | Resource monitor |
| `yazi/` | File manager. `plugins/` and `flavors/` are gitignored — install with `ya pack` |

## dot_local/bin — scripts

All scripts use `$(chezmoi source-path)` instead of hardcoded paths.

| Script | Description |
|--------|-------------|
| `dotfiles-sync` | Sync: `chezmoi re-add` + git add/commit/push |
| `backup-packages` | Export installed packages to `packages/linux/` (pacman, AUR, flatpak, npm, bun, uv) |
| `restore-packages` | Reinstall packages from `packages/linux/` lists |
| `list-packages` | List currently installed packages |
| `extract-claude-config` | Export Claude config docs to `other_config/claude/` |
| `cleanup` | System cleanup (cache, logs, orphan packages) |
| `plymouth-themes` | Install/switch Plymouth boot themes from `other_config/plymouth/themes/` |
| `sddm-themes` | Install/switch SDDM login themes from `other_config/sddm/themes/` |
| `cliphist.sh` | Cliphist clipboard history helper |
| `dontkillsteam.sh` | Prevents Steam from being killed by memory pressure |
| `fontman` | Font manager helper |
| `migrate-to-cachyos` / `migrate-aur` / `migrate-flatpak` | CachyOS migration helpers |
| `post-hyde-install` / `pre-hyde-install` | HyDE desktop environment install hooks |
| `openvpn-*` / `ikev2-*` | VPN management |
| `hytale-launcher` / `fit-launcher-update` | Game launcher helpers |

## Shell configs

| File | Shell |
|------|-------|
| `dot_bashrc`, `dot_bash_profile`, `dot_bash_logout` | Bash |
| `dot_zshenv`, `dot_zprofile` | Zsh |
| `dot_profile` | POSIX |

## Reference-only (other_config)

Not deployed by chezmoi — installed manually via scripts.

| Path | Description |
|------|-------------|
| `other_config/plymouth/themes/` | Boot splash themes (4 submodules). Managed by `plymouth-themes` script |
| `other_config/sddm/themes/` | SDDM login themes (1 submodule). Managed by `sddm-themes` script |
| `other_config/system/pacman/` | Pacman config reference |
| `other_config/system/sdboot/` | Systemd-boot config reference |
| `other_config/linux-cachyos-pollrate.toml` | USB polling rate config |
