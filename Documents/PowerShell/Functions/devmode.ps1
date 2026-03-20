function Enable-DevMode {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
        -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force
    Write-Host "Developer Mode enabled." -ForegroundColor Green
}

function Disable-DevMode {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
        -Name "AllowDevelopmentWithoutDevLicense" -Value 0 -Type DWord -Force
    Write-Host "Developer Mode disabled." -ForegroundColor Yellow
}

Set-Alias -Name enable-devmode -Value Enable-DevMode
Set-Alias -Name disable-devmode -Value Disable-DevMode
