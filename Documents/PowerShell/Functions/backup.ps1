# backup.ps1
$PackagesDir = "$env:USERPROFILE\.local\share\chezmoi\packages\windows"

function Save-ExistingBackup {
    param([string]$Path)
    if (Test-Path $Path) {
        Copy-Item $Path "$Path.bak" -Force
    }
}

function Invoke-AllBackup {
    New-Item -ItemType Directory -Force -Path $PackagesDir | Out-Null
    Invoke-WingetBackup
    Invoke-ScoopBackup
    Invoke-NodeBackup
    Invoke-BunBackup
    Invoke-UvBackup
    Invoke-BinBackup
    Write-Host "Backup completado en $PackagesDir" -ForegroundColor Green
}
Set-Alias -Name backup         -Value Invoke-AllBackup
Set-Alias -Name backup-pkgs    -Value Invoke-AllBackup

function Invoke-WingetBackup {
    $file        = "$PackagesDir\winget\packages.json"
    $excludeFile = "$PackagesDir\winget\exclude.txt"
    $tmp         = "$env:TEMP\winget-export-raw.json"

    Save-ExistingBackup $file
    winget export -o $tmp --source winget --accept-source-agreements

    $data = Get-Content $tmp | ConvertFrom-Json

    if (Test-Path $excludeFile) {
        $excluded = Get-Content $excludeFile | Where-Object { $_.Trim() -and -not $_.StartsWith('#') }
        foreach ($source in $data.Sources) {
            $source.Packages = $source.Packages | Where-Object {
                $_.PackageIdentifier -notin $excluded
            }
        }
        Write-Host "  (excluded $($excluded.Count) packages from winget/exclude.txt)" -ForegroundColor DarkGray
    }

    $data | ConvertTo-Json -Depth 10 | Set-Content $file -Encoding UTF8
    Remove-Item $tmp -ErrorAction SilentlyContinue

    $count = ($data.Sources | ForEach-Object { $_.Packages.Count } | Measure-Object -Sum).Sum
    Write-Host "winget backup OK ($count packages)" -ForegroundColor Green
}
Set-Alias -Name backup-winget  -Value Invoke-WingetBackup

function Invoke-ScoopBackup {
    $file = "$PackagesDir\scoop\packages.json"
    Save-ExistingBackup $file
    scoop export > $file
    Write-Host "scoop backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-scoop   -Value Invoke-ScoopBackup

function Invoke-NodeBackup {
    $file = "$PackagesDir\node\npm-packages.json"
    Save-ExistingBackup $file
    npm list -g --depth=0 --json > $file
    Write-Host "npm backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-node    -Value Invoke-NodeBackup

function Invoke-BunBackup {
    $file = "$PackagesDir\node\bun-packages.txt"
    Save-ExistingBackup $file
    bun pm ls -g | Select-Object -Skip 1 | ForEach-Object {
        $_ -replace '\x1b\[[0-9;]*m', '' -replace '^[^\w@]+', ''
    } | Where-Object { $_ } | Out-File $file -Encoding UTF8
    Write-Host "bun backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-bun     -Value Invoke-BunBackup

function Invoke-UvBackup {
    $file = "$PackagesDir\uv-tools.txt"
    Save-ExistingBackup $file
    uv tool list | Where-Object { $_ -and $_ -notmatch '^\s*-' } | ForEach-Object {
        $parts = $_ -split ' '
        if ($parts.Count -gt 0) { $parts[0].Trim() }
    } | Where-Object { $_ } | Out-File $file -Encoding UTF8
    Write-Host "uv backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-uv      -Value Invoke-UvBackup

function Invoke-BinBackup {
    $file = "$PackagesDir\bin-packages.txt"
    Save-ExistingBackup $file
    bin list | Where-Object { $_ -match 'https?://' } | ForEach-Object {
        $parts = $_ -split '\s{2,}'
        if ($parts.Count -ge 3) { $parts[2].Trim() }
    } | Where-Object { $_ } | Out-File $file -Encoding UTF8
    Write-Host "bin backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-bin     -Value Invoke-BinBackup

function Invoke-WindhawkBackup {
    $sourceDir   = chezmoi source-path
    $regFile     = "$sourceDir\packages\windows\system\windhawk\settings.reg"
    $pfDir       = "$sourceDir\program_files\windhawk"
    $tmpScript   = "$env:TEMP\windhawk-backup.ps1"
    $logFile     = "$env:TEMP\windhawk-backup.log"
    New-Item -ItemType Directory -Force -Path (Split-Path $regFile) | Out-Null
    Save-ExistingBackup $regFile
    @"
`$outputFile = "$regFile"
`$pfDir      = "$pfDir"
`$logFile    = "$logFile"
`$lines      = @()
`$mods = Get-ChildItem "HKLM:\SOFTWARE\Windhawk\Engine\Mods" -ErrorAction SilentlyContinue |
    Where-Object { `$_.PSChildName -ne "SymbolCache" }
"Windows Registry Editor Version 5.00" | Out-File `$outputFile -Encoding Unicode
foreach (`$mod in `$mods) {
    `$regPath = `$mod.PSPath -replace 'Microsoft.PowerShell.Core\\Registry::', ''
    `$tmp = "`$env:TEMP\wh-mod.reg"
    reg export `$regPath `$tmp /y | Out-Null
    Get-Content `$tmp | Select-Object -Skip 1 | Add-Content `$outputFile
    Remove-Item `$tmp -ErrorAction SilentlyContinue
}
`$lines += "reg:OK (`$(`$mods.Count) mods)"
New-Item -ItemType Directory -Force -Path "`$pfDir\32", "`$pfDir\64" | Out-Null
`$dlls32 = Copy-Item "C:\ProgramData\Windhawk\Engine\Mods\32\*.dll" "`$pfDir\32\" -Force -PassThru -ErrorAction SilentlyContinue
`$dlls64 = Copy-Item "C:\ProgramData\Windhawk\Engine\Mods\64\*.dll" "`$pfDir\64\" -Force -PassThru -ErrorAction SilentlyContinue
`$lines += "dlls:OK (32-bit: `$(`$dlls32.Count)  64-bit: `$(`$dlls64.Count))"
`$lines | Set-Content `$logFile
"@ | Set-Content $tmpScript
    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile", "-File", $tmpScript -Wait
    Remove-Item $tmpScript -ErrorAction SilentlyContinue

    if (Test-Path $logFile) {
        Get-Content $logFile | ForEach-Object { Write-Host "  [OK] $_" -ForegroundColor Green }
        Remove-Item $logFile
    } else {
        Write-Warning "windhawk backup: no output from elevated script (UAC cancelled or failed)"
        return
    }

    # userprofile.json and ModsSource are readable without elevation
    if (Test-Path "C:\ProgramData\Windhawk\userprofile.json") {
        Copy-Item "C:\ProgramData\Windhawk\userprofile.json" "$pfDir\userprofile.json" -Force
        Write-Host "  [OK] userprofile.json" -ForegroundColor Green
    } else {
        Write-Warning "windhawk backup: userprofile.json not found"
    }
    $wh_cpp = Get-ChildItem "C:\ProgramData\Windhawk\ModsSource\*.wh.cpp" -ErrorAction SilentlyContinue
    if ($wh_cpp) {
        New-Item -ItemType Directory -Force -Path "$pfDir\ModsSource" | Out-Null
        $wh_cpp | Copy-Item -Destination "$pfDir\ModsSource\" -Force
        Write-Host "  [OK] ModsSource ($($wh_cpp.Count) files)" -ForegroundColor Green
    } else {
        Write-Warning "windhawk backup: no .wh.cpp files found in ModsSource"
    }
    Write-Host "windhawk backup OK" -ForegroundColor Green
}
Set-Alias -Name backup-windhawk -Value Invoke-WindhawkBackup
