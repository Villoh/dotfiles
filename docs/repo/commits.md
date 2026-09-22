# Conventional Commits

This repo uses [Conventional Commits](https://www.conventionalcommits.org/) for all commit messages.

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

## Types

| Type | When to use |
|------|-------------|
| `feat` | New config, tool, or feature added to the dotfiles |
| `fix` | Correcting a broken config, script, or symlink |
| `refactor` | Restructuring without changing behavior (e.g. renaming, moving files) |
| `chore` | Maintenance: updating package lists, submodule bumps, chezmoi housekeeping |
| `docs` | Changes to files in `docs/`, `CLAUDE.md`, or `README.md` |
| `style` | Formatting-only changes (whitespace, indentation) |
| `revert` | Reverting a previous commit |

## Scopes (optional but recommended)

Use the app or area being changed:

- `glazewm`, `vesktop`, `nvim`, `wezterm`, `zsh`, `powershell`, `hyprland`, `starship`, etc.
- `chezmoi` for chezmoi scripts or ignore rules
- `scoop`, `winget`, `pacman` for package list changes
- `scripts` for files in `.chezmoiscripts/` or `dot_local/bin/`

## Examples

```
feat(glazewm): add keybind to cycle through workspaces
fix(chezmoi): guard AppData symlinks behind Windows platform check
chore(scoop): add ripgrep and fd to packages list
refactor(wezterm): split config into separate lua modules
docs: add conventional commits guide
fix(vesktop): remove broken settings symlink, rename .tmp
```

## Rules

- Use **imperative mood** in the description: "add", "fix", "remove" — not "added", "fixes", "removed"
- Keep the description under **72 characters**
- Do not end the description with a period
- Breaking changes: add `!` after the type/scope and explain in the footer with `BREAKING CHANGE:`
