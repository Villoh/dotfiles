$regFile = "{{ .chezmoi.sourceDir }}\packages\windows\windhawk-settings.reg"

if (Test-Path $regFile) {
    Write-Host "Importing Windhawk settings..."
    Start-Process -FilePath "reg.exe" `
        -ArgumentList "import `"$regFile`"" `
        -Verb RunAs `
        -Wait
    Write-Host "Windhawk settings imported."
} else {
    Write-Warning "Windhawk settings file not found: $regFile"
}
