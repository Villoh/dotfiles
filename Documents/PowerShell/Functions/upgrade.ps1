# upgrade.ps1

function Invoke-AllUpgrade {
    Invoke-WingetUpgrade
    Invoke-ScoopUpgrade
    Invoke-NodeUpgrade
    Invoke-UvUpgrade
}
Set-Alias -Name upgrade       -Value Invoke-AllUpgrade
Set-Alias -Name update        -Value Invoke-AllUpgrade

function Invoke-WingetUpgrade {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Warning "winget not found."; return }

    winget upgrade --all --accept-package-agreements --accept-source-agreements --silent

    # Check what's still pending after --all (packages that failed to upgrade)
    $pending = winget upgrade 2>&1
    $ids = @()
    $inTable = $false
    foreach ($line in $pending) {
        if ($line -match '^-{3,}')                     { $inTable = $true; continue }
        if ($inTable -and $line -match '\s+(\S+\.\S+)\s+') { $ids += $matches[1] }
    }

    # For each pending package, try individually to detect reinstall-required errors
    foreach ($id in $ids) {
        $result = winget upgrade --id $id --accept-package-agreements --accept-source-agreements 2>&1 | Out-String
        if ($result -match 'install technology is different') {
            Write-Host "Reinstalling $id (installer technology changed, requesting elevation)..." -ForegroundColor Cyan
            $cmd = "winget uninstall --id $id --accept-source-agreements --all-versions; winget install -e --id $id --accept-package-agreements --accept-source-agreements"
            Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile", "-Command", $cmd -Wait
            Write-Host "$id reinstalled successfully." -ForegroundColor Green
        }
    }
}
Set-Alias -Name update-winget  -Value Invoke-WingetUpgrade
Set-Alias -Name upgrade-winget -Value Invoke-WingetUpgrade

function Invoke-ScoopUpgrade {
    if (Get-Command scoop -ErrorAction SilentlyContinue) { scoop update * }
    else { Write-Warning "scoop not found." }
}
Set-Alias -Name update-scoop   -Value Invoke-ScoopUpgrade
Set-Alias -Name upgrade-scoop  -Value Invoke-ScoopUpgrade

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

function Invoke-WingetReinstall {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Id
    )
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Warning "winget not found."; return }
    Write-Host "Reinstalling $Id (requesting elevation)..." -ForegroundColor Cyan
    $cmd = "winget uninstall --id $Id --accept-source-agreements --all-versions; winget install -e --id $Id --accept-package-agreements --accept-source-agreements"
    Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile", "-Command", $cmd -Wait
    Write-Host "$Id reinstalled successfully." -ForegroundColor Green
}
Set-Alias -Name winget-reinstall -Value Invoke-WingetReinstall
