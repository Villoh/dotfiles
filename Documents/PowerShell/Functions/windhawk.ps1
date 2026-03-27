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

    $sourceDir  = chezmoi source-path
    $regFile    = Join-Path $sourceDir "packages\windows\system\windhawk-settings.reg"
    $profileSrc = Join-Path $sourceDir "packages\windows\system\windhawk-userprofile.json"
    $profileDst = "C:\ProgramData\Windhawk\userprofile.json"

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

    # Restore userprofile.json (controls update status display in Windhawk UI)
    if (Test-Path $profileSrc) {
        Copy-Item $profileSrc $profileDst -Force
        Write-Host "[windhawk] userprofile.json restored." -ForegroundColor Green
    } else {
        Write-Host "[windhawk] userprofile.json not found in backup - skipping." -ForegroundColor Yellow
    }
}

Set-Alias -Name restore-windhawk -Value Invoke-WindhawkRestore
