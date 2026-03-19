# Repository structure

```
chezmoi/
├── .chezmoi.toml.tmpl          # Chezmoi config: mode=symlink, GPG recipient, OS vars
├── .chezmoiignore              # Platform-conditional ignore rules
├── .chezmoiscripts/            # Scripts run by chezmoi on install/change
├── .chezmoitemplates/          # Shared template partials
│
├── dot_config/                 # → ~/.config/
├── dot_local/bin/              # → ~/.local/bin/ (Linux scripts)
├── dot_bashrc, dot_zshenv…     # Shell configs (Linux)
│
├── AppData/                    # → ~/AppData/ (Windows)
├── Documents/                  # → ~/Documents/ (Windows)
├── scoop/                      # → ~/scoop/ (Windows, Scoop package manager)
├── program_files/              # Portable Windows programs (Ditto, Nilesoft) — not deployed
│
├── packages/                   # Package lists — reference only, not deployed
│   ├── linux/                  # pacman.txt, aur.txt, flatpak.txt, npm, bun, uv-tools
│   └── windows/                # Scoop/Winget lists, windhawk-settings.reg
│
├── other_config/               # Reference configs not deployed by chezmoi
│   ├── plymouth/themes/        # Boot splash themes (4 submodules)
│   ├── sddm/themes/            # Login manager themes (1 submodule)
│   ├── system/                 # pacman, sdboot configs (reference)
│   ├── claude/                 # Claude AI config docs
│   └── linux-cachyos-pollrate.toml
│
├── docs/                       # Context docs for Claude
├── .github/assets/             # README screenshots and logos
├── .gitmodules                 # Submodule definitions
├── .gitleaks.toml              # Gitleaks config (allowlists Vencord/Vesktop)
├── .pre-commit-config.yaml     # Pre-commit: gitleaks on every commit
├── README.md
└── LICENSE
```

## Submodules

| Path | Repo |
|------|------|
| `other_config/plymouth/themes/adi1090x-themes` | adi1090x/plymouth-themes |
| `other_config/plymouth/themes/cachyos` | CachyOS/cachyos-plymouth-theme |
| `other_config/plymouth/themes/onepiece` | Anxhul10/onePiece-plymouth |
| `other_config/plymouth/themes/vortex-ubuntu` | emanuele-scarsella/vortex-ubuntu-plymouth-theme |
| `other_config/sddm/themes/sddm-astronaut-theme` | Keyitdev/sddm-astronaut-theme |
| `dot_config/hypr/hyprlock/catppuccin` | catppuccin/hyprlock |
| `dot_config/hypr/hyprlock/vivek-hyprlock-styles` | MrVivekRajan/Hyprlock-Styles |
