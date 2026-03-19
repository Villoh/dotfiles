# CLAUDE.md

## What is this repo

Dual-platform dotfiles managed with [chezmoi](https://chezmoi.io):
- **Windows** — AtlasOS (Win11): AppData, Documents, PowerShell, Scoop, program_files
- **Linux** — CachyOS + Hyprland: dot_config, dot_local/bin, shell configs

## chezmoi essentials

**Mode: symlink.** Source files are symlinked into `$HOME`. Editing a file in `~/.config/` edits the chezmoi source directly — no `chezmoi re-add` needed.

**Platform branching** is done in `.chezmoiignore` with Go templates:
```
{{ if eq .chezmoi.os "windows" }}   # ignored on Linux
{{ if ne .chezmoi.os "windows" }}   # ignored on Windows (covers Linux + macOS)
```

**Always use `chezmoi source-path`** instead of hardcoded `~/.local/share/chezmoi` in scripts.

**Secrets** are GPG-encrypted. Never store plaintext secrets. gitleaks pre-commit hook runs on every commit.

**Submodules** are used for external theme repos. Clone with `--recurse-submodules`.

## Key instructions

- When adding a new config file, check if it needs a platform guard in `.chezmoiignore`. Repo metadata files (docs, scripts, package lists, reference configs) must also be listed there so chezmoi never deploys them to `$HOME`
- Windows apps that can't use chezmoi symlinks directly get a **junction** via `.chezmoiscripts/run_once_setup-windows-symlinks.ps1.tmpl` — junctions always point to the chezmoi source dir, never to `~/.config/` as intermediary
- When purging large files from git history, use `git filter-repo` (installed via scoop). Python at `~/AppData/Local/Programs/Python/Python314/python.exe` — the `python` command redirects to the Microsoft Store on Windows
- After `filter-repo`, the `origin` remote is removed and must be re-added manually
- For Python tooling, use `uv tool install` (not pip, not scoop)
- `.tmp` files in AppData dirs are created by apps when they can't write to a broken symlink — fix by removing the broken symlink and renaming the `.tmp`

## Reference docs

Load these only when the task is relevant to them:

| File | When to read |
|------|-------------|
| `docs/structure.md` | Exploring the repo, adding new configs, understanding what's tracked |
| `docs/windows.md` | Any Windows-specific config, junctions, AppData, scripts |
| `docs/linux.md` | Any Linux/Hyprland config, dot_config, dot_local/bin |
