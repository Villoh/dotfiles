# backup.ps1
$PackagesDir = "$env:USERPROFILE\.local\share\chezmoi\packages\windows"

function Invoke-AllBackup {
    New-Item -ItemType Directory -Force -Path $PackagesDir | Out-Null
    Invoke-WingetBackup
    Invoke-ScoopBackup
    Invoke-ChocoBackup
    Invoke-NodeBackup
    Invoke-BunBackup
    Invoke-UvBackup
    Invoke-BinBackup
    Write-Host "Backup completado en $PackagesDir" -ForegroundColor Green
}
Set-Alias -Name backup         -Value Invoke-AllBackup
Set-Alias -Name backup-pkgs    -Value Invoke-AllBackup

function Invoke-WingetBackup {
    $file = "$PackagesDir\winget-packages.json"
    winget export -o $file --accept-source-agreements
    Write-Host "winget backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-winget  -Value Invoke-WingetBackup

function Invoke-ScoopBackup {
    $file = "$PackagesDir\scoop-packages.json"
    scoop export > $file
    Write-Host "scoop backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-scoop   -Value Invoke-ScoopBackup

function Invoke-ChocoBackup {
    $file = "$PackagesDir\chocolatey-packages.config"
    choco export $file
    Write-Host "choco backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-choco   -Value Invoke-ChocoBackup

function Invoke-NodeBackup {
    $file = "$PackagesDir\npm-packages.json"
    npm list -g --depth=0 --json > $file
    Write-Host "npm backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-node    -Value Invoke-NodeBackup

function Invoke-BunBackup {
    $file = "$PackagesDir\bun-packages.txt"
    bun pm ls -g | Select-Object -Skip 1 | ForEach-Object {
        $_ -replace '\x1b\[[0-9;]*m', '' -replace '^[^\w@]+', ''
    } | Where-Object { $_ } | Out-File $file -Encoding UTF8
    Write-Host "bun backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-bun     -Value Invoke-BunBackup

function Invoke-UvBackup {
    $file = "$PackagesDir\uv-tools.txt"
    uv tool list | Where-Object { $_ -and $_ -notmatch '^\s*-' } | ForEach-Object {
        $parts = $_ -split ' '
        if ($parts.Count -gt 0) { $parts[0].Trim() }
    } | Where-Object { $_ } | Out-File $file -Encoding UTF8
    Write-Host "uv backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-uv      -Value Invoke-UvBackup

function Invoke-BinBackup {
    $file = "$PackagesDir\bin-packages.txt"
    bin list | Where-Object { $_ -match 'https?://' } | ForEach-Object {
        $parts = $_ -split '\s{2,}'
        if ($parts.Count -ge 3) { $parts[2].Trim() }
    } | Where-Object { $_ } | Out-File $file -Encoding UTF8
    Write-Host "bin backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-bin     -Value Invoke-BinBackup

function Invoke-WindhawkBackup {
    $file = "$PackagesDir\windhawk-settings.reg"
    $mods = Get-ChildItem "HKLM:\SOFTWARE\Windhawk\Engine\Mods" |
        Where-Object { $_.PSChildName -ne "SymbolCache" }

    "Windows Registry Editor Version 5.00" | Out-File $file -Encoding Unicode
    foreach ($mod in $mods) {
        $settingsPath = "$($mod.PSPath)\Settings"
        if (Test-Path $settingsPath) {
            reg export ($settingsPath -replace 'Microsoft.PowerShell.Core\\Registry::', '') ($file + ".tmp") /y | Out-Null
            Get-Content ($file + ".tmp") | Select-Object -Skip 1 | Add-Content $file
            Remove-Item ($file + ".tmp")
        }
    }
    Write-Host "windhawk backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-windhawk -Value Invoke-WindhawkBackup
