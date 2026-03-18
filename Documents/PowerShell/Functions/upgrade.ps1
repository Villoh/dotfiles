# upgrade.ps1

function Invoke-AllUpgrade {
    winget upgrade --all --accept-package-agreements --accept-source-agreements --silent
    scoop update *
    choco upgrade all -y
    npm update -g
    bun update --global
    uv tool upgrade --all
}
Set-Alias -Name upgrade       -Value Invoke-AllUpgrade
Set-Alias -Name update        -Value Invoke-AllUpgrade

function Invoke-WingetUpgrade { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent }
Set-Alias -Name update-winget  -Value Invoke-WingetUpgrade
Set-Alias -Name upgrade-winget -Value Invoke-WingetUpgrade

function Invoke-ScoopUpgrade  { scoop update * }
Set-Alias -Name update-scoop   -Value Invoke-ScoopUpgrade
Set-Alias -Name upgrade-scoop  -Value Invoke-ScoopUpgrade

function Invoke-ChocoUpgrade  { choco upgrade all -y }
Set-Alias -Name update-choco   -Value Invoke-ChocoUpgrade
Set-Alias -Name upgrade-choco  -Value Invoke-ChocoUpgrade

function Invoke-NodeUpgrade    { npm update -g; bun update --global }
Set-Alias -Name update-node    -Value Invoke-NodeUpgrade
Set-Alias -Name upgrade-node   -Value Invoke-NodeUpgrade

function Invoke-UvUpgrade      { uv tool upgrade --all }
Set-Alias -Name update-uv      -Value Invoke-UvUpgrade
Set-Alias -Name upgrade-uv     -Value Invoke-UvUpgrade
