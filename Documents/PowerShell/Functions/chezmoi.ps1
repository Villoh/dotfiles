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
