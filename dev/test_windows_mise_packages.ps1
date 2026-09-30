# Offline regression checks; no real package manager or selection command runs.
$ErrorActionPreference = 'Stop'
$script:testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "mise-packages-test-$([guid]::NewGuid())"
$script:miseAvailable = $true
$script:listJson = '{}'
$script:listExit = 0
$script:installExit = 0
$script:upgradeExit = 0
$script:miseCalls = [System.Collections.Generic.List[string]]::new()
$script:warnings = [System.Collections.Generic.List[string]]::new()
$script:messages = [System.Collections.Generic.List[string]]::new()
$script:selectionCalls = [System.Collections.Generic.List[string]]::new()
$script:selectionMode = 'all'

function Assert {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}
function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)
    $threw = $false
    try { & $Action } catch { $threw = $true }
    Assert $threw $Message
}
function chezmoi {
    Assert (($args -join ' ') -eq 'source-path') 'Expected chezmoi source-path.'
    $script:testRoot
}
function Get-Command {
    [CmdletBinding()]
    param([Parameter(Position = 0)][string]$Name)
    if ($Name -eq 'mise' -and -not $script:miseAvailable) { return }
    Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
}
function mise {
    $call = $args -join ' '
    $script:miseCalls.Add($call)
    switch -Regex ($call) {
        '^ls --installed --json$' {
            $script:LASTEXITCODE = $script:listExit
            $script:listJson
            break
        }
        '^install -- ' {
            $script:LASTEXITCODE = $script:installExit
            break
        }
        '^upgrade$' {
            $script:LASTEXITCODE = $script:upgradeExit
            break
        }
        default { throw "Unexpected mise command: $call" }
    }
}
function Write-Warning {
    param([string]$Message)
    $script:warnings.Add($Message)
}
function Write-Host {
    param([string]$Object, [ConsoleColor]$ForegroundColor)
    $script:messages.Add($Object)
}

try {
    $functionsDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'Documents/PowerShell/Functions'
    . (Join-Path $functionsDir 'backup.ps1')
    . (Join-Path $functionsDir 'restore.ps1')
    . (Join-Path $functionsDir 'upgrade.ps1')
    function Select-WithFzf {
        param([string[]]$Items, [string]$Prompt, [string]$Header)
        $script:selectionCalls.Add("${Prompt}:$($Items -join '|')")
        if ($Prompt -eq 'Package managers>') { return @($Items | Where-Object { $_ -eq 'mise' }) }
        switch ($script:selectionMode) {
            'all' { return $Items }
            'subset' { return @($Items | Where-Object { $_ -eq 'npm:@scope/pkg@3.2.1' }) }
            'none' { return @() }
        }
    }

    $file = Join-Path $PackagesDir 'mise-tools.txt'
    Assert ($file -eq (Join-Path $script:testRoot 'packages/windows/mise-tools.txt')) 'Inventory must use chezmoi source-path.'
    foreach ($entry in @{
        'backup-mise' = 'Invoke-MiseBackup'; 'restore-mise' = 'Invoke-MiseRestore'
        'update-mise' = 'Invoke-MiseUpgrade'; 'upgrade-mise' = 'Invoke-MiseUpgrade'
    }.GetEnumerator()) {
        Assert ((Get-Alias $entry.Key).Definition -eq $entry.Value) "Wrong alias: $($entry.Key)"
    }

    New-Item -ItemType Directory -Force -Path $PackagesDir | Out-Null
    Set-Content $file 'prior@1' -Encoding UTF8
    $prior = Get-Content $file -Raw
    $script:listJson = @'
{
  "npm:@scope/pkg": [{"version":"3.2.1"}],
  "node": [{"version":"22.0.0"},{"version":"20.0.0"},{"version":"22.0.0","symlinked_to":null}],
  "rust": [{"version":"1.88.0","symlinked_to":"C:/local/rust"}],
  "ruby": [{"version":"system"}],
  "aqua:cli/tool": [{"version":"1.4.0"}]
}
'@
    Assert (backup-mise) 'Backup should succeed.'
    $expected = @('aqua:cli/tool@1.4.0', 'node@20.0.0', 'node@22.0.0', 'npm:@scope/pkg@3.2.1')
    Assert (((Get-Content $file) -join '|') -ceq ($expected -join '|')) 'Backup must sort, deduplicate, preserve scoped/backend tools and multiple versions.'
    Assert ((Get-Content "$file.bak" -Raw) -ceq $prior) '.bak must contain prior inventory.'
    Assert ($script:warnings.Count -eq 2) 'Symlink and system omissions must warn.'
    Assert (($script:miseCalls -join '|') -eq 'ls --installed --json') 'Backup must query installed JSON only.'
    $saved = Get-Content $file -Raw
    $savedBak = Get-Content "$file.bak" -Raw

    foreach ($badJson in @(
        '{broken', 'null', '[]', '[{"node":[]}]', '"text"',
        '{"node":{"version":"20"}}', '{"node":[null]}', '{"node":[["20"]]}',
        '{"node":[{"version":20}]}', '{"node":[{"version":null}]}',
        '{"node":[{}]}', '{"node":[{"version":""}]}', '{"node":[{"version":"--bad"}]}',
        '{"node":[{"version":"20 1"}]}', '{"node":[{"version":"20\n"}]}',
        '{"":[]}', '{"--bad":[]}', '{"bad name":[]}', '{"bad\n":[]}'
    )) {
        $script:listJson = $badJson
        Assert (-not (Invoke-MiseBackup)) "Malformed JSON should fail: $badJson"
        Assert ((Get-Content $file -Raw) -ceq $saved) "Malformed JSON changed inventory: $badJson"
        Assert ((Get-Content "$file.bak" -Raw) -ceq $savedBak) "Malformed JSON changed .bak: $badJson"
    }
    $script:listJson = '{}'
    $script:listExit = 7
    Assert (-not (Invoke-MiseBackup)) 'Query failure should fail backup.'
    Assert ((Get-Content $file -Raw) -ceq $saved) 'Query failure must retain inventory.'
    Assert ((Get-Content "$file.bak" -Raw) -ceq $savedBak) 'Query failure must retain .bak.'
    $script:listExit = 0
    $script:miseAvailable = $false
    $script:miseCalls.Clear()
    $script:warnings.Clear()
    Assert (Invoke-MiseBackup) 'Missing optional mise should skip successfully.'
    Assert ($script:miseCalls.Count -eq 0 -and $script:warnings.Count -eq 1) 'Missing mise must warn without querying.'
    Assert ((Get-Content $file -Raw) -ceq $saved) 'Missing mise must retain inventory.'
    Assert ((Get-Content "$file.bak" -Raw) -ceq $savedBak) 'Missing mise must retain .bak.'
    $script:miseAvailable = $true
    Assert (Invoke-MiseBackup) 'Empty object should succeed.'
    Assert ((Get-Item $file).Length -eq 0) 'Empty inventory must truncate file.'
    Assert ((Get-Content "$file.bak" -Raw) -ceq $saved) 'Empty inventory must back up prior content.'
    $script:listJson = '{"node":[]}'
    Assert (Invoke-MiseBackup) 'Empty version array should succeed.'
    Assert ((Get-Item $file).Length -eq 0) 'Empty version array must remain empty.'

    # Restore validates every line before selection or installation.
    Set-Content $file ($expected + @('', '   ')) -Encoding UTF8
    $script:miseCalls.Clear()
    $script:selectionCalls.Clear()
    $script:selectionMode = 'subset'
    restore-mise
    Assert (($script:miseCalls -join '|') -eq 'install -- npm:@scope/pkg@3.2.1') 'Restore must install selected scoped spec with --, without activation.'
    Assert (($script:selectionCalls -join '|') -eq "mise>:$($expected -join '|')") 'Restore selection must ignore blank lines.'
    $script:selectionMode = 'none'
    $script:miseCalls.Clear()
    Invoke-MiseRestore
    Assert ($script:miseCalls.Count -eq 0) 'Cancelled selection must not install.'
    $script:selectionMode = 'all'
    foreach ($badSpec in @('--help', '--bad@1', 'node', 'node@', '@1', 'node@--bad', 'node@20 --force', ' node@20', 'node@20 ')) {
        Set-Content $file @('node@20.0.0', $badSpec) -Encoding UTF8
        $script:miseCalls.Clear()
        $script:selectionCalls.Clear()
        Assert-Throws { Invoke-MiseRestore } "Invalid spec must throw: $badSpec"
        Assert ($script:miseCalls.Count -eq 0 -and $script:selectionCalls.Count -eq 0) "Validation must precede selection and all installers: $badSpec"
    }

    Set-Content $file $expected -Encoding UTF8
    $script:miseCalls.Clear()
    $script:selectionCalls.Clear()
    Invoke-AllRestore -Manager mise
    Assert (($script:miseCalls -join '|') -eq (($expected | ForEach-Object { "install -- $_" }) -join '|')) 'Direct manager dispatch must install exact versions.'
    Assert ($script:selectionCalls.Count -eq 1 -and $script:selectionCalls[0].StartsWith('mise>:')) 'Direct manager dispatch must bypass manager menu.'
    $script:miseCalls.Clear()
    $script:selectionCalls.Clear()
    Invoke-AllRestore
    Assert ($script:selectionCalls[0] -eq 'Package managers>:mise') 'Menu must offer mise inventory.'
    Assert ($script:miseCalls.Count -eq $expected.Count) 'Menu must dispatch mise restore.'
    foreach ($pluginArgs in @(@{ Plugin = @('example') }, @{ All = $true }, @{ Yes = $true })) {
        $script:miseCalls.Clear()
        Assert-Throws { Invoke-AllRestore -Manager mise @pluginArgs } 'Mise must reject Herdr-only arguments.'
        Assert ($script:miseCalls.Count -eq 0) 'Rejected Herdr arguments must not install.'
    }
    $script:installExit = 3
    $script:miseCalls.Clear()
    $script:messages.Clear()
    Assert-Throws { Invoke-AllRestore } 'Failed install must throw through menu dispatch.'
    Assert ($script:miseCalls.Count -eq 1) 'Failed install must stop remaining installs.'
    Assert (@($script:messages | Where-Object { $_ -match 'restore OK|Restore completado' }).Count -eq 0) 'Failed install must not report success.'
    $script:installExit = 0
    $script:miseAvailable = $false
    $script:miseCalls.Clear()
    $script:warnings.Clear()
    Invoke-MiseRestore
    Assert ($script:miseCalls.Count -eq 0 -and $script:warnings.Count -eq 1) 'Missing mise restore must warn and skip.'
    $script:miseAvailable = $true
    $inventoryFile = $file
    $PackagesDir = Join-Path $script:testRoot 'no-inventory'
    $script:warnings.Clear()
    Invoke-MiseRestore
    Assert ($script:miseCalls.Count -eq 0 -and $script:warnings.Count -eq 1) 'Missing inventory must warn and skip.'
    $PackagesDir = Split-Path $inventoryFile -Parent
    [System.IO.File]::WriteAllText($file, '')
    Invoke-MiseRestore
    Assert ($script:miseCalls.Count -eq 0) 'Empty inventory must not install.'

    # Stub sibling managers; aggregate entry points must reach mise once.
    function Invoke-WingetBackup { return $true }
    function Invoke-ScoopBackup { return $true }
    function Invoke-NodeBackup { return $true }
    function Invoke-BunBackup { return $true }
    function Invoke-PnpmBackup { return $true }
    function Invoke-UvBackup { return $true }
    function Invoke-BinBackup { return $true }
    function Invoke-CargoBackup { return $true }
    function Invoke-HerdrBackup { return $true }
    $script:listJson = '{}'
    $script:miseCalls.Clear()
    Assert (Invoke-AllBackup) 'Aggregate backup should succeed.'
    Assert (($script:miseCalls -join '|') -eq 'ls --installed --json') 'Aggregate backup must include mise once.'
    $script:listExit = 2
    Assert (-not (Invoke-AllBackup)) 'Aggregate backup must propagate mise failure.'
    $script:listExit = 0
    function Invoke-WingetUpgrade {}
    function Invoke-ScoopUpgrade {}
    function Invoke-NodeUpgrade {}
    function Invoke-UvUpgrade {}
    $script:miseCalls.Clear()
    update-mise
    upgrade-mise
    Invoke-AllUpgrade
    Assert (($script:miseCalls -join '|') -eq 'upgrade|upgrade|upgrade') 'Aliases and aggregate must use mise upgrade, no --bump or self-update.'
    $script:upgradeExit = 9
    $script:warnings.Clear()
    Invoke-MiseUpgrade
    Assert ($script:warnings.Count -eq 1 -and $script:warnings[0] -match 'exit code 9') 'Failed upgrade must warn.'
    $script:miseAvailable = $false
    $script:miseCalls.Clear()
    $script:warnings.Clear()
    Invoke-MiseUpgrade
    Assert ($script:miseCalls.Count -eq 0 -and $script:warnings.Count -eq 1) 'Missing mise upgrade must warn and skip.'
    Write-Output 'Windows mise package checks passed'
}
finally {
    if (Test-Path $script:testRoot) {
        Remove-Item $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
