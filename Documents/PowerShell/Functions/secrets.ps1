function Update-Secrets {
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Path }

    $scriptItem = Get-Item -LiteralPath $scriptPath
    if ($scriptItem.Target) {
        $scriptPath = $scriptItem.Target
    }

    $scriptDir = Split-Path -Parent $scriptPath
    $repoRoot = Resolve-Path (Join-Path $scriptDir "..\..\..")
    $configFile = Join-Path $repoRoot "packages\windows\system\secrets.json"

    if (-not (Test-Path $configFile)) {
        Write-Host "  [SKIP] secrets.json not found" -ForegroundColor DarkGray
        return
    }

    $scriptFile = Join-Path $repoRoot ".chezmoiscripts\run_onchange_01_windows-secrets.ps1.tmpl"
    if (-not (Test-Path $scriptFile)) {
        Write-Host "  [FAIL] Windows secrets template not found: $scriptFile" -ForegroundColor Red
        return
    }

    $content = Get-Content $scriptFile -Raw
    $content = $content -replace '^\{\{ if.*?\}\}\r?\n', ''
    $content = $content -replace '\r?\n\{\{ end -\}\}\s*$', ''
    $content = $content -replace '\{\{ \.chezmoi\.sourceDir \}\}', ($repoRoot.Path.Replace('\\', '/'))
    $content = $content -replace '^# secrets\.json.*\r?\n', ''

    $scriptBlock = [scriptblock]::Create($content)
    & $scriptBlock
}

Set-Alias secrets Update-Secrets
