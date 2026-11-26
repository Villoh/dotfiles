function Get-ConfigKeybinds {
    param(
        [string]$Path,
        [string]$Pattern
    )
    Select-String -Path $Path -Pattern $Pattern |
        ForEach-Object { $_.Line.Trim() } |
        Select-Object -Unique
}

function Show-Keybinds-Alacritty {
    Get-ConfigKeybinds "$env:APPDATA\alacritty\alacritty.toml" "key\s*=" | less
}

function Show-Keybinds-Zellij {
    Get-ConfigKeybinds "$env:USERPROFILE\.config\zellij\config.kdl" "bind" | less
}

function Show-Keybinds-Aether {
    # AetherWM reads Hyprland's own config, so the binds are the `bind` lines of hyprland.conf.
    Get-ConfigKeybinds "$env:USERPROFILE\.config\hypr\hyprland.conf" "^\s*bind[a-z]*\s*=" | less
}

function Show-Keybinds {
    $output = @()
    $output += "`n=== ALACRITTY ==="
    $output += Get-ConfigKeybinds "$env:APPDATA\alacritty\alacritty.toml" "key\s*="
    $output += "`n=== ZELLIJ ==="
    $output += Get-ConfigKeybinds "$env:USERPROFILE\.config\zellij\config.kdl" "bind"
    $output += "`n=== AETHERWM ==="
    $output += Get-ConfigKeybinds "$env:USERPROFILE\.config\hypr\hyprland.conf" "^\s*bind[a-z]*\s*="
    $output | less
}

Set-Alias keybinds     Show-Keybinds
Set-Alias keybinds-al  Show-Keybinds-Alacritty
Set-Alias keybinds-zj  Show-Keybinds-Zellij
Set-Alias keybinds-aw  Show-Keybinds-Aether
