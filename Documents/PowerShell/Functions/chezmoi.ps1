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
    Resets run_once_ script state so all run_once_ scripts re-run on next apply.
.DESCRIPTION
    chezmoi tracks run_once_ scripts in the scriptState bucket, keyed by content
    hash. Individual scripts cannot be targeted by name, so this always clears
    the entire bucket.
.EXAMPLE
    Reset-RunOnceScripts
    chezmoi apply
#>
function Reset-RunOnceScripts {
    chezmoi state delete-bucket --bucket=scriptState
    Write-Host "  [OK] Cleared scriptState — all run_once_ scripts will re-run." -ForegroundColor Green
    Write-Host "  Run 'chezmoi apply' to re-execute." -ForegroundColor DarkGray
}
Set-Alias -Name reset-run-once-scripts -Value Reset-RunOnceScripts

<#
.SYNOPSIS
    Resets run_onchange_ script state so the script re-runs on next apply.
.DESCRIPTION
    chezmoi tracks run_onchange_ scripts in entryState, keyed by destination path.
    Without -Name, resets all run_onchange_ scripts.
.PARAMETER Name
    Script filename without extension (e.g. "windows-setup").
    Omit to reset all run_onchange_ scripts.
.EXAMPLE
    Reset-RunOnchangeScript windows-setup   # reset one script
    Reset-RunOnchangeScript                 # reset all run_onchange_ scripts
    chezmoi apply
#>
function Reset-RunOnchangeScript {
    param([string]$Name)

    if ($Name) {
        $key = ($env:USERPROFILE.Replace('\', '/')) + "/.chezmoiscripts/$Name.ps1"
        chezmoi state delete --bucket=entryState --key=$key
        Write-Host "  [OK] Reset: $key" -ForegroundColor Green
    } else {
        $state = chezmoi state dump --format=json | ConvertFrom-Json
        $state.entryState.PSObject.Properties.Name |
            Where-Object { $_ -like "*/.chezmoiscripts/*" } |
            ForEach-Object {
                chezmoi state delete --bucket=entryState --key=$_
                Write-Host "  [OK] Reset: $_" -ForegroundColor Green
            }
    }
    Write-Host "  Run 'chezmoi apply' to re-execute." -ForegroundColor DarkGray
}
Set-Alias -Name reset-run-onchange-script -Value Reset-RunOnchangeScript
