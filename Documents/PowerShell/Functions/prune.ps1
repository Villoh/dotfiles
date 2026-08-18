function Invoke-DevCleanup {
    param(
        [Parameter(Position = 0)]
        [string] $Target
    )

    $steps = @(
        @{ Name = "scoop";  Check = "scoop";  Cmd = { scoop cleanup * | Out-Null; scoop cache rm * | Out-Null } }
        @{ Name = "npm";    Check = "npm";    Cmd = { npm cache clean --force | Out-Null } }
        @{ Name = "pnpm";   Check = "pnpm";   Cmd = { pnpm store prune | Out-Null } }
        @{ Name = "bun";    Check = "bun";    Cmd = { Remove-Item "$env:BUN_INSTALL\install\cache\*" -Recurse -Force -ErrorAction SilentlyContinue } }
        @{ Name = "uv";     Check = "uv";     Cmd = { uv cache clean | Out-Null } }
        @{ Name = "go";     Check = "go";     Cmd = { go clean -cache | Out-Null } }
        @{ Name = "nuget";  Check = "dotnet"; Cmd = { dotnet nuget locals all --clear | Out-Null } }
        @{ Name = "docker"; Check = "docker"; Ready = { docker info *> $null; $? }; Cmd = { docker system prune -a --volumes --force | Out-Null } }
    )

    if ($Target -ne "--all") {
        if (-not $Target -or $Target -notin $steps.Name) {
            Write-Host "Usage: prune <$($steps.Name -join '|')|--all>" -ForegroundColor Yellow
            return
        }
        $steps = $steps | Where-Object { $_.Name -eq $Target }
    }

    $before = (Get-PSDrive C).Free

    foreach ($step in $steps) {
        if (-not (Get-Command $step.Check -ErrorAction SilentlyContinue)) {
            Write-Host "  [SKIP] $($step.Name) not installed" -ForegroundColor DarkGray
            continue
        }
        if ($step.Ready) {
            $ready = & $step.Ready
            $global:LASTEXITCODE = 0
            if (-not $ready) {
                Write-Host "  [SKIP] $($step.Name) not running" -ForegroundColor DarkGray
                continue
            }
        }
        Write-Host "  [RUN]  $($step.Name)" -ForegroundColor Cyan
        try {
            & $step.Cmd
        } catch {
            Write-Host "  [FAIL] $($step.Name): $_" -ForegroundColor Red
        }
    }

    $after = (Get-PSDrive C).Free
    Write-Host ""
    Write-Host "Reclaimed: $([math]::Round(($after - $before) / 1GB, 2)) GB" -ForegroundColor Green
    if ($steps.Name -contains "docker") {
        Write-Host "Note: Docker's WSL vhdx doesn't shrink on disk until compacted (needs admin):" -ForegroundColor DarkGray
        Write-Host '  wsl --shutdown; diskpart /s <(select vdisk file="...docker_data.vhdx" & compact vdisk)' -ForegroundColor DarkGray
    }
}

Set-Alias prune Invoke-DevCleanup
