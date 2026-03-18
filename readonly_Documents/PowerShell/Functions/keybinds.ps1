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

function Show-Keybinds-GlazeWM {
    $lines = Get-Content "$env:USERPROFILE\.glzr\glazewm\config.yaml"
    $output = @()
    $currentCommands = $null

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match "^-?\s*commands:\s*(.+)$") {
            $currentCommands = $Matches[1]
        } elseif ($trimmed -match "^bindings:\s*(.+)$" -and $currentCommands) {
            $output += "$($Matches[1].PadRight(40)) -> $currentCommands"
            $currentCommands = $null
        }
    }

    $output | less
}

function Show-Keybinds {
    $output = @()
    $output += "`n=== ALACRITTY ==="
    $output += Get-ConfigKeybinds "$env:APPDATA\alacritty\alacritty.toml" "key\s*="
    $output += "`n=== ZELLIJ ==="
    $output += Get-ConfigKeybinds "$env:USERPROFILE\.config\zellij\config.kdl" "bind"
    $output += "`n=== GLAZEWM ==="
    $output += Get-ConfigKeybinds "$env:USERPROFILE\.glzr\glazewm\config.yaml" "bindings:"
    $output | less
}

Set-Alias keybinds     Show-Keybinds
Set-Alias keybinds-al  Show-Keybinds-Alacritty
Set-Alias keybinds-zj  Show-Keybinds-Zellij
Set-Alias keybinds-gwm Show-Keybinds-GlazeWM
