function Invoke-WindhawkRestore {
    <#
    .SYNOPSIS
        Imports Windhawk settings from the chezmoi source registry file.
    .DESCRIPTION
        Windhawk must be fully closed before running this. Install all desired
        mods first, then close Windhawk, then run this function.
    #>
    $windhawk = Get-Process -Name "Windhawk*" -ErrorAction SilentlyContinue
    if ($windhawk) {
        Write-Warning "Windhawk is running. Close it first, then run restore-windhawk again."
        return
    }

    $sourceDir     = chezmoi source-path
    $regFile       = Join-Path $sourceDir "packages\windows\system\windhawk\settings.reg"
    $pfDir         = Join-Path $sourceDir "program_files\windhawk"
    $profileDst    = "C:\ProgramData\Windhawk\userprofile.json"
    $modsSrcDst    = "C:\ProgramData\Windhawk\ModsSource"

    if (-not (Test-Path $regFile)) {
        Write-Warning "Registry file not found: $regFile"
        return
    }

    $logFile   = "$env:TEMP\windhawk-restore.log"
    $tmpScript = "$env:TEMP\windhawk-restore.ps1"

    @"
reg import "$regFile" 2>`$null
if (`$LASTEXITCODE -eq 0) {
    Set-Content -Path "$logFile" -Value "OK"
} else {
    Set-Content -Path "$logFile" -Value "ERROR: reg import failed (exit code `$LASTEXITCODE)"
}
"@ | Set-Content $tmpScript

    Write-Host "[windhawk] Requesting elevation..." -ForegroundColor Cyan
    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile", "-File", $tmpScript -Wait

    if (Test-Path $logFile) {
        $result = Get-Content $logFile
        Remove-Item $logFile
        if ($result -eq "OK") {
            Write-Host "[windhawk] Registry imported successfully." -ForegroundColor Green
        } else {
            Write-Host "[windhawk] $result" -ForegroundColor Red
        }
    } else {
        Write-Warning "No output received (UAC cancelled or import failed)"
    }
    Remove-Item $tmpScript -ErrorAction SilentlyContinue

    # Restore userprofile.json and ModsSource (needed so Windhawk reads correct installed versions)
    Copy-Item "$pfDir\userprofile.json" $profileDst -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $modsSrcDst | Out-Null
    Copy-Item "$pfDir\ModsSource\*.wh.cpp" "$modsSrcDst\" -Force -ErrorAction SilentlyContinue
    Write-Host "[windhawk] userprofile.json and ModsSource restored." -ForegroundColor Green

    # Init cycle — start Windhawk so the engine injects mods into running processes,
    # then stop cleanly so the next user launch finds everything already initialized
    $whExe = (Get-ItemProperty "HKLM:\SOFTWARE\Windhawk" -ErrorAction SilentlyContinue).InstallPath
    if (-not $whExe) { $whExe = "C:\Program Files\Windhawk" }
    $whExe = Join-Path $whExe "Windhawk.exe"
    if (Test-Path $whExe) {
        Write-Host "[windhawk] Running init cycle..." -ForegroundColor Cyan
        Start-Process $whExe -WindowStyle Hidden
        Start-Sleep -Seconds 10
        Stop-Process -Name "Windhawk*" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host "[windhawk] Init cycle complete." -ForegroundColor Green
    }
}

Set-Alias -Name restore-windhawk -Value Invoke-WindhawkRestore
