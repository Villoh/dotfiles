# upgrade.ps1

function Invoke-PackageUpdate {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidateSet('winget', 'scoop', 'mise')]
        [string[]]$Manager = @('winget', 'scoop', 'mise')
    )
    if ($Manager -contains 'winget') { Invoke-WingetUpgrade }
    if ($Manager -contains 'scoop') { Invoke-ScoopUpgrade }
    if ($Manager -contains 'mise') { Invoke-MiseUpgrade }
}
Set-Alias -Name update -Value Invoke-PackageUpdate

function Invoke-AllUpgrade {
    [CmdletBinding()]
    param()
    Invoke-PackageUpdate
}

Set-Alias -Name upgrade-all       -Value Invoke-AllUpgrade
Set-Alias -Name update-all        -Value Invoke-AllUpgrade

function Invoke-WingetUpgrade {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Warning "winget not found."; return }
    winget upgrade --all --accept-package-agreements --accept-source-agreements --silent
}
Set-Alias -Name update-winget  -Value Invoke-WingetUpgrade
Set-Alias -Name upgrade-winget -Value Invoke-WingetUpgrade

function Invoke-ScoopUpgrade {
    if (Get-Command scoop -ErrorAction SilentlyContinue) { scoop update --all }
    else { Write-Warning "scoop not found." }
}
Set-Alias -Name update-scoop   -Value Invoke-ScoopUpgrade
Set-Alias -Name upgrade-scoop  -Value Invoke-ScoopUpgrade

function Invoke-MiseUpgrade {
    if (-not (Get-Command mise -ErrorAction SilentlyContinue)) { Write-Warning "mise not found; skipping upgrade."; return }
    mise upgrade
    if ($LASTEXITCODE -ne 0) { Write-Warning "mise upgrade failed (exit code $LASTEXITCODE)." }
}
Set-Alias -Name update-mise  -Value Invoke-MiseUpgrade
Set-Alias -Name upgrade-mise -Value Invoke-MiseUpgrade

function Invoke-WingetReinstall {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Id
    )
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Warning "winget not found."; return }
    Write-Host "Reinstalling $Id (requesting elevation)..." -ForegroundColor Cyan

    # Write to a temp script so the elevated process can poll until uninstall actually finishes
    $script = [System.IO.Path]::GetTempFileName() + '.ps1'
    Set-Content $script @"
winget uninstall --id '$Id' --accept-source-agreements --all-versions --interactive
Write-Host 'Waiting for uninstall to complete...' -ForegroundColor Yellow
do { Start-Sleep 2 } until (-not (winget list --id '$Id' | Out-String | Select-String '$Id'))
winget install -e --id '$Id' --accept-package-agreements --accept-source-agreements --interactive
"@
    Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile", "-File", $script -Wait
    Remove-Item $script -ErrorAction SilentlyContinue
    Write-Host "$Id reinstalled successfully." -ForegroundColor Green
}
Set-Alias -Name winget-reinstall -Value Invoke-WingetReinstall

