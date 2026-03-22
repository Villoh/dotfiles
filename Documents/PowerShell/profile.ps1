# Load PATH (for alacritty)
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH", "User")

# Overrides
$EDITOR_Override = 'zed'

# oh-my-posh
function Get-Theme_Override {
	#oh-my-posh init pwsh --config 'catppuccin' | Invoke-Expression
	Invoke-Expression (&starship init powershell)
}

# Terminal Icons
Import-Module -Name Terminal-Icons

# Functions
. "$HOME\Documents\PowerShell\Functions\upgrade.ps1"
. "$HOME\Documents\PowerShell\Functions\bitwarden.ps1"
. "$HOME\Documents\PowerShell\Functions\keybinds.ps1"
. "$HOME\Documents\PowerShell\Functions\win-keys.ps1"
. "$HOME\Documents\PowerShell\Functions\backup.ps1"
. "$HOME\Documents\PowerShell\Functions\restore.ps1"
. "$HOME\Documents\PowerShell\Functions\chezmoi.ps1"
. "$HOME\Documents\PowerShell\Functions\devmode.ps1"
. "$HOME\Documents\PowerShell\Functions\gpg-ssh-setup.ps1"
. "$HOME\Documents\PowerShell\Functions\windhawk.ps1"
. "$HOME\Documents\PowerShell\Functions\wsl-arch-setup.ps1"
. "$HOME\Documents\PowerShell\Functions\startup.ps1"

# Force Fastfetch to use YOUR config every time (bypass path confusion)
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c "C:/Users/Mikel/.config/fastfetch/config.jsonc"
}
