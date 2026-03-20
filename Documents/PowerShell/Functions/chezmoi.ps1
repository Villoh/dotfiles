# chezmoi.ps1
function Invoke-DotfilesSync {
    chezmoi git -- add .
    chezmoi git -- commit -m "auto: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    chezmoi git -- push
}
Set-Alias -Name dotfiles-sync  -Value Invoke-DotfilesSync
Set-Alias -Name dsync          -Value Invoke-DotfilesSync

function Invoke-DotfilesApply  { chezmoi apply }
Set-Alias -Name dapply         -Value Invoke-DotfilesApply

function Invoke-DotfilesEdit   { chezmoi edit $args }
Set-Alias -Name dedit          -Value Invoke-DotfilesEdit

function Invoke-DotfilesUpdate {
    chezmoi git -- pull
    chezmoi apply
}
Set-Alias -Name dupdate        -Value Invoke-DotfilesUpdate

<#
.SYNOPSIS
    Clears chezmoi's recorded state for a script so it re-runs on next apply.
.DESCRIPTION
    chezmoi tracks run_once_ and run_onchange_ scripts in the entryState bucket.
    This function deletes the entry for a given script name so chezmoi will
    re-execute it on the next 'chezmoi apply'.
.PARAMETER Name
    Script filename without extension (e.g. "windows-setup", "00_install-packages").
.EXAMPLE
    Reset-ChezmoiScript windows-setup
    chezmoi apply
#>
function Reset-ChezmoiScript {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    $key = ($env:USERPROFILE.Replace('\', '/')) + "/.chezmoiscripts/$Name.ps1"
    chezmoi state delete --bucket=entryState --key=$key
    Write-Host "  [OK] Reset: $key" -ForegroundColor Green
    Write-Host "  Run 'chezmoi apply' to re-execute." -ForegroundColor DarkGray
}
Set-Alias -Name reset-chezmoi-script -Value Reset-ChezmoiScript
