# Migrated by Pretty PowerShell setup
# Migration date: 2026-05-21 18:00:12 +02:00
# Repo-managed logic lives in standalone PrettyPowerShell.ps1
# Previous main profile backup: C:\Users\mikel\Documents\PowerShell\Backups\20260521-180005\Microsoft.PowerShell_profile.ps1
# Previous custom profile backup: C:\Users\mikel\Documents\PowerShell\Backups\20260521-180005\profile.ps1

# Pretty PowerShell loader
if (Test-Path 'C:\Users\mikel\Documents\PowerShell\PrettyPowerShell\PrettyPowerShell.ps1') {
    . 'C:\Users\mikel\Documents\PowerShell\PrettyPowerShell\PrettyPowerShell.ps1'
}

# ---- BEGIN MIGRATED USER CUSTOMIZATIONS ----

# Load PATH (for alacritty)
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH", "User")

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

# ---- END MIGRATED USER CUSTOMIZATIONS ----
