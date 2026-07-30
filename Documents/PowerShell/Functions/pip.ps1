function Clear-PipEnvironment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param()

    $python = Get-Command python -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $python) {
        throw 'python not found in PATH.'
    }

    $packagesJson = & $python.Source -m pip list --disable-pip-version-check --format=json
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not list pip packages.'
    }

    $installed = ConvertFrom-Json -InputObject ($packagesJson -join [Environment]::NewLine)
    $packages = foreach ($package in $installed) {
        if ($package.name -ine 'pip') {
            $package.name
        }
    }

    if ($packages.Count -eq 0) {
        Write-Output 'Only pip remains.'
        return
    }

    if ($PSCmdlet.ShouldProcess($python.Source, "Uninstall $($packages.Count) package(s), preserving pip")) {
        & $python.Source -m pip uninstall --disable-pip-version-check -y @packages
        if ($LASTEXITCODE -ne 0) {
            throw 'pip uninstall failed.'
        }
    }
}

Set-Alias -Name clear-pip -Value Clear-PipEnvironment

