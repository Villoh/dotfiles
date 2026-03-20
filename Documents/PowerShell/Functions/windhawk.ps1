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

    $regFile = (Join-Path (chezmoi source-path) "packages\windows\system\windhawk-settings.reg")
    if (-not (Test-Path $regFile)) {
        Write-Warning "Registry file not found: $regFile"
        return
    }

    $logFile   = "$env:TEMP\windhawk-restore.log"
    $tmpScript = "$env:TEMP\windhawk-restore.ps1"

    @"
reg import "$regFile" 2>`$null
if (`$LASTEXITCODE -eq 0) {
    Set-Content -Path "$logFile" -Value "Windhawk settings imported successfully."
} else {
    Set-Content -Path "$logFile" -Value "ERROR: reg import failed (exit code `$LASTEXITCODE)"
}
"@ | Set-Content $tmpScript

    Write-Host "[windhawk] Requesting elevation..." -ForegroundColor Cyan
    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile", "-File", $tmpScript -Wait

    if (Test-Path $logFile) {
        Get-Content $logFile | ForEach-Object { Write-Host $_ -ForegroundColor Green }
        Remove-Item $logFile
    } else {
        Write-Warning "No output received (UAC cancelled or import failed)"
    }
    Remove-Item $tmpScript -ErrorAction SilentlyContinue
}

Set-Alias -Name restore-windhawk -Value Invoke-WindhawkRestore
