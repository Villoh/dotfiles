# upgrade-harness.ps1

function Invoke-HarnessUpgrade {
    Invoke-SkillsUpgrade
    Invoke-Context7Upgrade
    Invoke-CavemanUpgrade
    Invoke-HeadroomUpgrade
    Invoke-SerenaUpgrade
    Invoke-ImpeccableUpgrade
}


function Invoke-SkillsUpgrade {
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) { Write-Warning "npx not found."; return }
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Updating skills.sh skills..." -ForegroundColor Cyan
    npx --yes skills update -g -y
    if ($LASTEXITCODE -eq 0) { Write-Host "skills.sh skills updated." -ForegroundColor Green }
    else { Write-Warning "skills.sh update failed (exit code $LASTEXITCODE)." }
}

function Invoke-Context7Upgrade {
    if (-not (Get-Command ctx7 -ErrorAction SilentlyContinue)) { Write-Warning "ctx7 not found; skipping Context7."; return }
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Updating Context7 for coding agents..." -ForegroundColor Cyan
    ctx7 setup --cli --opencode --claude --codex --yes
    if ($LASTEXITCODE -eq 0) { Write-Host "Context7 configured for coding agents." -ForegroundColor Green }
    else { Write-Warning "Context7 setup failed (exit code $LASTEXITCODE)." }
}

function Invoke-CavemanUpgrade {
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) { Write-Warning "npx not found; skipping caveman."; return }
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Updating Caveman for OpenCode..." -ForegroundColor Cyan
    npx -y github:JuliusBrussee/caveman -- --only opencode --force --non-interactive
    if ($LASTEXITCODE -eq 0) { Write-Host "Caveman updated." -ForegroundColor Green }
    else { Write-Warning "Caveman update failed (exit code $LASTEXITCODE)." }
}

function Invoke-HeadroomUpgrade {
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) { Write-Warning "uv not found; skipping headroom."; return }

    # NOTE: do NOT use `headroom update` / plain `uv tool upgrade headroom-ai`.
    # The published wheel metadata omits the ast-grep-cli !=0.44.1 exclusion
    # (headroom issue #2462), so a plain re-resolve pulls the trojaned
    # ast-grep-cli 0.44.1 (Trojan:Win64/Lazy!MTB, headroom issue #2332).
    # --force reinstalls/upgrades headroom-ai to latest while excluding it.
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Updating headroom (safe, ast-grep-cli 0.44.1 excluded)..." -ForegroundColor Cyan
    uv tool install "headroom-ai[all]" --with "ast-grep-cli>=0.30.0,!=0.44.0,!=0.44.1" --python 3.13 --force
    if ($LASTEXITCODE -eq 0) { Write-Host "headroom updated." -ForegroundColor Green }
    else { Write-Warning "headroom update failed (exit code $LASTEXITCODE)." }
}

function Invoke-SerenaUpgrade {
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) { Write-Warning "uv not found; skipping serena."; return }
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Updating serena..." -ForegroundColor Cyan
    uv tool upgrade serena-agent
    if ($LASTEXITCODE -eq 0) { Write-Host "serena updated." -ForegroundColor Green }
    else { Write-Warning "serena update failed (exit code $LASTEXITCODE)." }
}

function Invoke-ImpeccableUpgrade {
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) { Write-Warning "npx not found; skipping impeccable."; return }
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Updating impeccable..." -ForegroundColor Cyan
    npx impeccable update -y --providers=codex,cursor,opencode,pi --scope=global
    if ($LASTEXITCODE -eq 0) { Write-Host "impeccable updated." -ForegroundColor Green }
    else { Write-Warning "impeccable update failed (exit code $LASTEXITCODE)." }
}

Set-Alias -Name update-serena  -Value Invoke-SerenaUpgrade
Set-Alias -Name upgrade-serena -Value Invoke-SerenaUpgrade
Set-Alias -Name update-context7 -Value Invoke-Context7Upgrade
Set-Alias -Name upgrade-context7 -Value Invoke-Context7Upgrade
Set-Alias -Name update-caveman  -Value Invoke-CavemanUpgrade
Set-Alias -Name upgrade-caveman -Value Invoke-CavemanUpgrade
Set-Alias -Name update-headroom  -Value Invoke-HeadroomUpgrade
Set-Alias -Name upgrade-headroom -Value Invoke-HeadroomUpgrade
Set-Alias -Name update-skills  -Value Invoke-SkillsUpgrade
Set-Alias -Name upgrade-skills -Value Invoke-SkillsUpgrade
Set-Alias -Name update-harness  -Value Invoke-HarnessUpgrade
Set-Alias -Name upgrade-harness -Value Invoke-HarnessUpgrade
Set-Alias -Name update-impeccable  -Value Invoke-ImpeccableUpgrade
Set-Alias -Name upgrade-impeccable -Value Invoke-ImpeccableUpgrade





