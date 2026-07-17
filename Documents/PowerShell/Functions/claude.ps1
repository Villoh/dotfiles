function Install-ClaudePlugins {
    $settings = Get-Content "$env:USERPROFILE\.claude\settings.json" -Raw | ConvertFrom-Json
    $wanted = $settings.enabledPlugins.PSObject.Properties.Name

    $installedJson = Get-Content "$env:USERPROFILE\.claude\plugins\installed_plugins.json" -Raw | ConvertFrom-Json
    $installed = $installedJson.plugins.PSObject.Properties |
        Where-Object { $_.Value | Where-Object { $_.scope -eq 'user' } } |
        ForEach-Object { $_.Name }

    foreach ($plugin in $wanted) {
        if ($installed -contains $plugin) {
            Write-Host "  skip  $plugin (already installed)"
        }
        else {
            Write-Host "install $plugin"
            claude plugin install $plugin --scope user
        }
    }
}

Set-Alias install-claude-plugins Install-ClaudePlugins

function Invoke-ClaudeX {
    $env:CLAUDE_CODE_SUBAGENT_MODEL = 'gpt-5.6-sol'
    $env:CLAUDE_CODE_ALWAYS_ENABLE_EFFORT = '1'
    $env:CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY = '3'
    $env:ENABLE_TOOL_SEARCH = 'false'

    try {
        claude --model gpt-5.6-sol @args
    }
    finally {
        Remove-Item Env:\CLAUDE_CODE_SUBAGENT_MODEL, Env:\CLAUDE_CODE_ALWAYS_ENABLE_EFFORT, Env:\CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY, Env:\ENABLE_TOOL_SEARCH -ErrorAction SilentlyContinue
    }
}

Set-Alias claudex Invoke-ClaudeX

