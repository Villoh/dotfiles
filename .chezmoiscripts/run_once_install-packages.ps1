$pkgDir = "{{ .chezmoi.sourceDir }}\packages\windows"

# ── winget ────────────────────────────────────────────────────────────────────
if (Test-Path "$pkgDir\winget-packages.json") {
    Write-Host "Installing winget packages..."
    winget import --accept-package-agreements --accept-source-agreements "$pkgDir\winget-packages.json"
}

# ── scoop ─────────────────────────────────────────────────────────────────────
if (Test-Path "$pkgDir\scoop-packages.json") {
    Write-Host "Installing scoop buckets and apps..."
    $scoop = Get-Content "$pkgDir\scoop-packages.json" | ConvertFrom-Json

    foreach ($bucket in $scoop.buckets) {
        scoop bucket add $bucket.Name $bucket.Source 2>$null
    }
    foreach ($app in $scoop.apps) {
        scoop install "$($app.Source)/$($app.Name)"
    }
}

# ── chocolatey ────────────────────────────────────────────────────────────────
if (Test-Path "$pkgDir\chocolatey-packages.config") {
    Write-Host "Installing Chocolatey packages..."
    choco install "$pkgDir\chocolatey-packages.config" -y
}

# ── npm ───────────────────────────────────────────────────────────────────────
if (Test-Path "$pkgDir\npm-packages.json") {
    $npm = Get-Content "$pkgDir\npm-packages.json" | ConvertFrom-Json
    if ($npm.dependencies) {
        Write-Host "Installing npm global packages..."
        foreach ($pkg in $npm.dependencies.PSObject.Properties) {
            npm install -g "$($pkg.Name)@$($pkg.Value)"
        }
    }
}

# ── bun ───────────────────────────────────────────────────────────────────────
if (Test-Path "$pkgDir\bun-packages.txt") {
    $bunPkgs = Get-Content "$pkgDir\bun-packages.txt" | Where-Object { $_.Trim() -ne "" }
    if ($bunPkgs) {
        Write-Host "Installing bun global packages..."
        foreach ($pkg in $bunPkgs) {
            bun add -g $pkg
        }
    }
}

# ── uv tools ──────────────────────────────────────────────────────────────────
if (Test-Path "$pkgDir\uv-tools.txt") {
    $uvTools = Get-Content "$pkgDir\uv-tools.txt" | Where-Object { $_.Trim() -ne "" }
    if ($uvTools) {
        Write-Host "Installing uv tools..."
        foreach ($tool in $uvTools) {
            uv tool install $tool
        }
    }
}

# ── PowerShell modules ────────────────────────────────────────────────────────
Write-Host "Installing PowerShell modules..."
@("Terminal-Icons") | ForEach-Object {
    if (-not (Get-Module -ListAvailable -Name $_)) {
        Install-Module $_ -Scope CurrentUser -Force -SkipPublisherCheck
    }
}

# ── bin (GitHub release binaries) ─────────────────────────────────────────────
if (Test-Path "$pkgDir\bin-packages.txt") {
    $binPkgs = Get-Content "$pkgDir\bin-packages.txt" | Where-Object { $_.Trim() -ne "" }
    if ($binPkgs) {
        Write-Host "Installing bin packages..."
        foreach ($url in $binPkgs) {
            bin install $url
        }
    }
}
