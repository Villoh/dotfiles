$ErrorActionPreference = 'Stop'

function chezmoi { Split-Path $PSScriptRoot -Parent }
$script:plugins = @(
    [pscustomobject]@{
        plugin_id = 'example.pinned'
        enabled = $true
        source = [pscustomobject]@{ kind = 'github'; owner = 'example'; repo = 'plugin'; subdir = $null; requested_ref = 'deadbeef'; resolved_commit = 'deadbeef' }
        plugin_root = $null
    },
    [pscustomobject]@{
        plugin_id = 'example.local'
        enabled = $false
        source = [pscustomobject]@{ kind = 'local' }
        plugin_root = Join-Path $HOME 'tools\plugin'
    }
)
function herdr {
    $script:LASTEXITCODE = 0
    [pscustomobject]@{ result = [pscustomobject]@{ plugins = $script:plugins } } | ConvertTo-Json -Depth 8 -Compress
}

. "$PSScriptRoot\..\Documents\PowerShell\Functions\backup.ps1"
$tempDir = Join-Path $env:TEMP "herdr-backup-test-$PID"
$HerdrPluginsFile = Join-Path $tempDir 'herdr-plugins.json'
try {
    if (-not (Invoke-HerdrBackup)) { throw 'Herdr backup failed.' }
    $saved = Get-Content $HerdrPluginsFile -Raw | ConvertFrom-Json
    if ($saved.Count -ne 2 -or $null -ne $saved[0].ref -or $saved[0].source -ne 'example/plugin') {
        throw 'Backup should preserve plugin source but omit commit refs.'
    }
    if ($saved[1].source -ne 'tools/plugin' -or $saved[1].kind -ne 'local') {
        throw 'Local plugin should be stored relative to HOME.'
    }
    Write-Output 'Windows Herdr backup checks passed'
}
finally {
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
