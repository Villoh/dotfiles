function Install-ClaudePlugins {
    $settings  = Get-Content "$env:USERPROFILE\.claude\settings.json" -Raw | ConvertFrom-Json
    $wanted    = $settings.enabledPlugins.PSObject.Properties.Name

    $installedJson = Get-Content "$env:USERPROFILE\.claude\plugins\installed_plugins.json" -Raw | ConvertFrom-Json
    $installed = $installedJson.plugins.PSObject.Properties |
        Where-Object { $_.Value | Where-Object { $_.scope -eq 'user' } } |
        ForEach-Object { $_.Name }

    foreach ($plugin in $wanted) {
        if ($installed -contains $plugin) {
            Write-Host "  skip  $plugin (already installed)"
        } else {
            Write-Host "install $plugin"
            claude plugin install $plugin --scope user
        }
    }
}

Set-Alias install-claude-plugins Install-ClaudePlugins
