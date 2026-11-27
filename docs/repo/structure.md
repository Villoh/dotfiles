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
├── dot_zprofile, dot_profile   # Shell configs (Linux)
│
├── AppData/                    # → ~/AppData/ (Windows)
├── Documents/                  # → ~/Documents/ (Windows)
├── scoop/                      # → ~/scoop/ (Windows, Scoop package manager)
├── program_files/              # Portable Windows programs (Nilesoft) — not deployed
│
├── packages/                   # Package lists — reference only, not deployed
│   ├── linux/                  # Linux package lists and Herdr plugin inventory
│   └── windows/                # Windows package lists, Herdr inventory, startup/junction lists, pinned Aether release
│
├── other_config/               # Reference configs not deployed by chezmoi
│   ├── plymouth/themes/        # Boot splash themes (4 submodules)
│   ├── sddm/themes/            # Login manager themes (1 submodule)
│   ├── system/                 # pacman, sdboot configs (reference)
│   ├── claude/                 # Claude AI config docs
│   └── linux-cachyos-pollrate.toml
│
├── docs/                       # Context docs for Claude
├── installer/                  # Windows installer GUI (Go + MyGo, Material 3) — not deployed
├── install.ps1                 # One-shot CLI `irm … | iex` bootstrap — not deployed
├── install-gui.ps1             # Downloads and runs the installer GUI — not deployed
├── .github/assets/             # README screenshots and logos
├── .github/workflows/          # installer-ci.yml (test + build), installer-release.yml (tag → release)
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
| `other_config/plymouth/themes/onepiece` | Anxhul10/onePiece-plymouth |
| `other_config/plymouth/themes/vortex-ubuntu` | emanuele-scarsella/vortex-ubuntu-plymouth-theme |
| `other_config/sddm/themes/sddm-astronaut-theme` | Keyitdev/sddm-astronaut-theme |
