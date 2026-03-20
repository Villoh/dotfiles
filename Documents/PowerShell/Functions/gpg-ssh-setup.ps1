function Setup-GpgSsh {
    $gpgConnect = Get-Command gpg-connect-agent -ErrorAction SilentlyContinue
    if (-not $gpgConnect) {
        Write-Warning "gpg-connect-agent not found - is Gpg4win installed?"
        return
    }

    # Create gpg-connect-agent startup shortcut (starts gpg-agent on login)
    $startup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut("$startup\gpg-connect-agent.lnk")
    $lnk.TargetPath = $gpgConnect.Source
    $lnk.Arguments = "/bye"
    $lnk.Save()
    Write-Host "[OK] gpg-connect-agent startup shortcut created" -ForegroundColor Green

    # Start agent now for current session
    gpg-connect-agent /bye 2>$null | Out-Null
    Write-Host "[OK] gpg-agent started" -ForegroundColor Green
    Write-Host "`nVerify SSH keys with: ssh-add -L" -ForegroundColor Cyan
}

Set-Alias -Name setup-gpg-ssh -Value Setup-GpgSsh
