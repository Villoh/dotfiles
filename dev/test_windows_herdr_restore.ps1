$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\Documents\PowerShell\Functions\restore.ps1"

$script:herdrCalls = @()
function herdr {
    if (($args -join ' ') -eq 'plugin list --json') {
        $script:LASTEXITCODE = 0
        return '{"result":{"plugins":[{"plugin_id":"cloudmanic.herdr-plus","warnings":null}]}}'
    }
    $script:LASTEXITCODE = 0
    $script:herdrCalls += ,($args -join ' ')
}
function Select-WithFzf { return @() }

$manifest = Get-Content $HerdrPluginsFile -Raw | ConvertFrom-Json
$plugin = $manifest | Where-Object id -eq 'herdr-navigator' | Select-Object -First 1
$rejected = $false
try { Invoke-HerdrRestore -Plugin $plugin.id } catch { $rejected = $true }
if (-not $rejected -or $script:herdrCalls.Count) { throw 'Non-interactive restore must require -Yes.' }

Invoke-HerdrRestore -Plugin 'cloudmanic.herdr-plus' -Yes
if ($script:herdrCalls.Count) { throw 'Existing plugins with null warnings must be skipped.' }

Invoke-AllRestore -Manager herdr -Plugin $plugin.id -Yes
$expected = "plugin install $($plugin.source)"
if ($plugin.ref) { $expected += " --ref $($plugin.ref)" }
$expected += ' --yes'
if ($script:herdrCalls -notcontains $expected) { throw "Expected Herdr args: $expected" }
Write-Output 'Windows Herdr restore checks passed'
