# restore.ps1
$PackagesDir = "$env:USERPROFILE\.local\share\chezmoi\packages\windows"

function Invoke-AllRestore {
    Invoke-WingetRestore
    Invoke-ScoopRestore
    Invoke-ChocoRestore
    Invoke-NodeRestore
    Invoke-BunRestore
    Invoke-UvRestore
    Invoke-BinRestore
    Write-Host "Restore completado" -ForegroundColor Green
}
Set-Alias -Name restore        -Value Invoke-AllRestore
Set-Alias -Name restore-pkgs   -Value Invoke-AllRestore

function Invoke-WingetRestore {
    $file = "$PackagesDir\winget-packages.json"
    if (Test-Path $file) {
        winget import -i $file --accept-package-agreements --accept-source-agreements --ignore-unavailable
        Write-Host "winget restore OK" -ForegroundColor Green
    } else { Write-Warning "No encontrado: $file" }
}
Set-Alias -Name restore-winget -Value Invoke-WingetRestore

function Invoke-ScoopRestore {
    $file = "$PackagesDir\scoop-packages.json"
    if (Test-Path $file) {
        $data = Get-Content $file | ConvertFrom-Json
        $data.buckets | ForEach-Object {
            Write-Host "Añadiendo bucket: $($_.Name)"
            scoop bucket add $_.Name $_.Source
        }
        $data.apps | ForEach-Object {
            Write-Host "Instalando: $($_.Name)"
            scoop install "$($_.Source)/$($_.Name)"
        }
        Write-Host "scoop restore OK" -ForegroundColor Green
    } else { Write-Warning "No encontrado: $file" }
}
Set-Alias -Name restore-scoop  -Value Invoke-ScoopRestore

function Invoke-ChocoRestore {
    $file = "$PackagesDir\chocolatey-packages.config"
    if (Test-Path $file) {
        choco install $file -y
        Write-Host "choco restore OK" -ForegroundColor Green
    } else { Write-Warning "No encontrado: $file" }
}
Set-Alias -Name restore-choco  -Value Invoke-ChocoRestore

function Invoke-NodeRestore {
    $file = "$PackagesDir\npm-packages.json"
    if (Test-Path $file) {
        $data = Get-Content $file | ConvertFrom-Json
        if ($data.dependencies) {
            $data.dependencies.PSObject.Properties.Name | ForEach-Object {
                Write-Host "Instalando npm: $_"
                npm install -g $_
            }
            Write-Host "npm restore OK" -ForegroundColor Green
        } else {
            Write-Host "npm: no hay paquetes que restaurar" -ForegroundColor Yellow
        }
    } else { Write-Warning "No encontrado: $file" }
}
Set-Alias -Name restore-node   -Value Invoke-NodeRestore

function Invoke-BunRestore {
    $file = "$PackagesDir\bun-packages.txt"
    if (Test-Path $file) {
        Get-Content $file | Where-Object { $_ } | ForEach-Object {
            $pkg = ($_ -split '@')[0]
            Write-Host "Instalando bun: $pkg"
            bun add -g $pkg
        }
        Write-Host "bun restore OK" -ForegroundColor Green
    } else { Write-Warning "No encontrado: $file" }
}
Set-Alias -Name restore-bun    -Value Invoke-BunRestore

function Invoke-UvRestore {
    $file = "$PackagesDir\uv-tools.txt"
    if (Test-Path $file) {
        Get-Content $file | Where-Object { $_ } | ForEach-Object {
            Write-Host "Instalando uv: $_"
            uv tool install $_
        }
        Write-Host "uv restore OK" -ForegroundColor Green
    } else { Write-Warning "No encontrado: $file" }
}
Set-Alias -Name restore-uv     -Value Invoke-UvRestore

function Invoke-BinRestore {
    $file = "$PackagesDir\bin-packages.txt"
    if (Test-Path $file) {
        Get-Content $file | Where-Object { $_ } | ForEach-Object {
            Write-Host "Instalando bin: $_"
            bin install $_
        }
        Write-Host "bin restore OK" -ForegroundColor Green
    } else { Write-Warning "No encontrado: $file" }
}
Set-Alias -Name restore-bin    -Value Invoke-BinRestore
