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
