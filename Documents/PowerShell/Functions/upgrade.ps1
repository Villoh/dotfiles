# upgrade.ps1

function Invoke-AllUpgrade {
    if (Get-Command winget -ErrorAction SilentlyContinue) { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent }
    if (Get-Command scoop  -ErrorAction SilentlyContinue) { scoop update * }
    if (Get-Command choco  -ErrorAction SilentlyContinue) { choco upgrade all -y }
    if (Get-Command npm    -ErrorAction SilentlyContinue) { npm update -g }
    if (Get-Command bun    -ErrorAction SilentlyContinue) { bun update --global }
    if (Get-Command uv     -ErrorAction SilentlyContinue) { uv tool upgrade --all }
}
Set-Alias -Name upgrade       -Value Invoke-AllUpgrade
Set-Alias -Name update        -Value Invoke-AllUpgrade

function Invoke-WingetUpgrade {
    if (Get-Command winget -ErrorAction SilentlyContinue) { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent }
    else { Write-Warning "winget not found." }
}
Set-Alias -Name update-winget  -Value Invoke-WingetUpgrade
Set-Alias -Name upgrade-winget -Value Invoke-WingetUpgrade

function Invoke-ScoopUpgrade {
    if (Get-Command scoop -ErrorAction SilentlyContinue) { scoop update * }
    else { Write-Warning "scoop not found." }
}
Set-Alias -Name update-scoop   -Value Invoke-ScoopUpgrade
Set-Alias -Name upgrade-scoop  -Value Invoke-ScoopUpgrade

function Invoke-ChocoUpgrade {
    if (Get-Command choco -ErrorAction SilentlyContinue) { choco upgrade all -y }
    else { Write-Warning "choco not found." }
}
Set-Alias -Name update-choco   -Value Invoke-ChocoUpgrade
Set-Alias -Name upgrade-choco  -Value Invoke-ChocoUpgrade

function Invoke-NodeUpgrade {
    if (Get-Command npm -ErrorAction SilentlyContinue) { npm update -g }
    else { Write-Warning "npm not found." }
    if (Get-Command bun -ErrorAction SilentlyContinue) { bun update --global }
    else { Write-Warning "bun not found." }
}
Set-Alias -Name update-node    -Value Invoke-NodeUpgrade
Set-Alias -Name upgrade-node   -Value Invoke-NodeUpgrade

function Invoke-UvUpgrade {
    if (Get-Command uv -ErrorAction SilentlyContinue) { uv tool upgrade --all }
    else { Write-Warning "uv not found." }
}
Set-Alias -Name update-uv      -Value Invoke-UvUpgrade
Set-Alias -Name upgrade-uv     -Value Invoke-UvUpgrade
