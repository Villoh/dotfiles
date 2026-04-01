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

$PSUserPath = Split-Path $PROFILE

# Source Functions, Completions and Secrets
@("Functions", "Completions", "Secrets") | ForEach-Object {
    Get-ChildItem "$PSUserPath\$_\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object { . $_ }
}

# Winget Completions
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# Force Fastfetch to use YOUR config every time (bypass path confusion)
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c "C:/Users/Mikel/.config/fastfetch/config.jsonc"
}
