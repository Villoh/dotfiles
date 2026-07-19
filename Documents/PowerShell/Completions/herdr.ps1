
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -Native -CommandName 'herdr' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandElements = $commandAst.CommandElements
    $command = @(
        'herdr'
        for ($i = 1; $i -lt $commandElements.Count; $i++) {
            $element = $commandElements[$i]
            if ($element -isnot [StringConstantExpressionAst] -or
                $element.StringConstantType -ne [StringConstantType]::BareWord -or
                $element.Value.StartsWith('-') -or
                $element.Value -eq $wordToComplete) {
                break
        }
        $element.Value
    }) -join ';'

    $completions = @(switch ($command) {
        'herdr' {
            [CompletionResult]::new('--session', '--session', [CompletionResultType]::ParameterName, 'Use or create a named persistent session')
            [CompletionResult]::new('--remote', '--remote', [CompletionResultType]::ParameterName, 'Attach through SSH to a remote Herdr server')
            [CompletionResult]::new('--remote-keybindings', '--remote-keybindings', [CompletionResultType]::ParameterName, 'Choose local or server keybindings for remote attach')
            [CompletionResult]::new('-h', '-h', [CompletionResultType]::ParameterName, 'Show help')
            [CompletionResult]::new('--help', '--help', [CompletionResultType]::ParameterName, 'Show help')
            [CompletionResult]::new('--no-session', '--no-session', [CompletionResultType]::ParameterName, 'Run monolithically without server/client session mode')
            [CompletionResult]::new('--handoff', '--handoff', [CompletionResultType]::ParameterName, 'Opt into live handoff for update or remote attach')
            [CompletionResult]::new('--default-config', '--default-config', [CompletionResultType]::ParameterName, 'Print default configuration and exit')
            [CompletionResult]::new('-V', '-V ', [CompletionResultType]::ParameterName, 'Print version and exit')
            [CompletionResult]::new('--version', '--version', [CompletionResultType]::ParameterName, 'Print version and exit')
            [CompletionResult]::new('completion', 'completion', [CompletionResultType]::ParameterValue, 'Generate shell completion scripts')
            [CompletionResult]::new('completions', 'completions', [CompletionResultType]::ParameterValue, 'Generate shell completion scripts')
            [CompletionResult]::new('update', 'update', [CompletionResultType]::ParameterValue, 'Download and install the latest version')
            [CompletionResult]::new('status', 'status', [CompletionResultType]::ParameterValue, 'Show local client and running server status')
            [CompletionResult]::new('config', 'config', [CompletionResultType]::ParameterValue, 'Manage local configuration')
            [CompletionResult]::new('channel', 'channel', [CompletionResultType]::ParameterValue, 'Manage stable and preview update channels')
            [CompletionResult]::new('server', 'server', [CompletionResultType]::ParameterValue, 'Run or control the headless server')
            [CompletionResult]::new('api', 'api', [CompletionResultType]::ParameterValue, 'Inspect socket API metadata and live runtime state')
            [CompletionResult]::new('workspace', 'workspace', [CompletionResultType]::ParameterValue, 'Manage workspaces over the socket API')
            [CompletionResult]::new('worktree', 'worktree', [CompletionResultType]::ParameterValue, 'Manage Git worktree-backed workspaces')
            [CompletionResult]::new('tab', 'tab', [CompletionResultType]::ParameterValue, 'Manage tabs over the socket API')
            [CompletionResult]::new('notification', 'notification', [CompletionResultType]::ParameterValue, 'Show Herdr notifications')
            [CompletionResult]::new('agent', 'agent', [CompletionResultType]::ParameterValue, 'Control and inspect agent panes')
            [CompletionResult]::new('pane', 'pane', [CompletionResultType]::ParameterValue, 'Control terminal panes')
            [CompletionResult]::new('wait', 'wait', [CompletionResultType]::ParameterValue, 'Wait for pane output or agent state')
            [CompletionResult]::new('terminal', 'terminal', [CompletionResultType]::ParameterValue, 'Attach to or observe raw terminal streams')
            [CompletionResult]::new('session', 'session', [CompletionResultType]::ParameterValue, 'Manage named persistent sessions')
            [CompletionResult]::new('integration', 'integration', [CompletionResultType]::ParameterValue, 'Manage built-in agent integrations')
            [CompletionResult]::new('plugin', 'plugin', [CompletionResultType]::ParameterValue, 'Install and run workflow plugins')
            break
        }
        'herdr;completion' {
            break
        }
        'herdr;completions' {
            break
        }
        'herdr;update' {
            [CompletionResult]::new('--handoff', '--handoff', [CompletionResultType]::ParameterName, 'Try live handoff after installing')
            break
        }
        'herdr;status' {
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            [CompletionResult]::new('server', 'server', [CompletionResultType]::ParameterValue, 'Show running server status')
            [CompletionResult]::new('client', 'client', [CompletionResultType]::ParameterValue, 'Show local client status')
            break
        }
        'herdr;status;server' {
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;status;client' {
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;config' {
            [CompletionResult]::new('check', 'check', [CompletionResultType]::ParameterValue, 'Validate config.toml and print diagnostics')
            [CompletionResult]::new('reset-keys', 'reset-keys', [CompletionResultType]::ParameterValue, 'Reset custom keybindings')
            break
        }
        'herdr;config;check' {
            break
        }
        'herdr;config;reset-keys' {
            break
        }
        'herdr;channel' {
            [CompletionResult]::new('show', 'show', [CompletionResultType]::ParameterValue, 'Print the configured update channel')
            [CompletionResult]::new('set', 'set', [CompletionResultType]::ParameterValue, 'Choose the update channel')
            break
        }
        'herdr;channel;show' {
            break
        }
        'herdr;channel;set' {
            break
        }
        'herdr;server' {
            [CompletionResult]::new('stop', 'stop', [CompletionResultType]::ParameterValue, 'Stop the running server')
            [CompletionResult]::new('reload-config', 'reload-config', [CompletionResultType]::ParameterValue, 'Reload config in the running server')
            [CompletionResult]::new('agent-manifests', 'agent-manifests', [CompletionResultType]::ParameterValue, 'Show active agent detection manifests')
            [CompletionResult]::new('update-agent-manifests', 'update-agent-manifests', [CompletionResultType]::ParameterValue, 'Fetch and reload agent detection manifests')
            [CompletionResult]::new('reload-agent-manifests', 'reload-agent-manifests', [CompletionResultType]::ParameterValue, 'Reload local agent detection manifest overrides')
            break
        }
        'herdr;server;stop' {
            break
        }
        'herdr;server;reload-config' {
            break
        }
        'herdr;server;agent-manifests' {
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;server;update-agent-manifests' {
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;server;reload-agent-manifests' {
            break
        }
        'herdr;api' {
            [CompletionResult]::new('snapshot', 'snapshot', [CompletionResultType]::ParameterValue, 'Print the live session snapshot')
            [CompletionResult]::new('schema', 'schema', [CompletionResultType]::ParameterValue, 'Print or write the bundled API schema')
            break
        }
        'herdr;api;snapshot' {
            break
        }
        'herdr;api;schema' {
            [CompletionResult]::new('--output', '--output', [CompletionResultType]::ParameterName, 'output')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;workspace' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List workspaces')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a workspace')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Show a workspace')
            [CompletionResult]::new('focus', 'focus', [CompletionResultType]::ParameterValue, 'Focus a workspace')
            [CompletionResult]::new('rename', 'rename', [CompletionResultType]::ParameterValue, 'Rename a workspace')
            [CompletionResult]::new('report-metadata', 'report-metadata', [CompletionResultType]::ParameterValue, 'Report display-only workspace metadata')
            [CompletionResult]::new('close', 'close', [CompletionResultType]::ParameterValue, 'Close a workspace')
            break
        }
        'herdr;workspace;list' {
            break
        }
        'herdr;workspace;create' {
            [CompletionResult]::new('--cwd', '--cwd', [CompletionResultType]::ParameterName, 'cwd')
            [CompletionResult]::new('--label', '--label', [CompletionResultType]::ParameterName, 'label')
            [CompletionResult]::new('--env', '--env', [CompletionResultType]::ParameterName, 'Set an environment variable for the launched process')
            [CompletionResult]::new('--focus', '--focus', [CompletionResultType]::ParameterName, 'focus')
            [CompletionResult]::new('--no-focus', '--no-focus', [CompletionResultType]::ParameterName, 'no-focus')
            break
        }
        'herdr;workspace;get' {
            break
        }
        'herdr;workspace;focus' {
            break
        }
        'herdr;workspace;rename' {
            break
        }
        'herdr;workspace;report-metadata' {
            [CompletionResult]::new('--source', '--source', [CompletionResultType]::ParameterName, 'source')
            [CompletionResult]::new('--token', '--token', [CompletionResultType]::ParameterName, 'token')
            [CompletionResult]::new('--clear-token', '--clear-token', [CompletionResultType]::ParameterName, 'clear-token')
            [CompletionResult]::new('--seq', '--seq', [CompletionResultType]::ParameterName, 'seq')
            [CompletionResult]::new('--ttl-ms', '--ttl-ms', [CompletionResultType]::ParameterName, 'ttl-ms')
            break
        }
        'herdr;workspace;close' {
            break
        }
        'herdr;worktree' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List worktree workspaces')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create and open a Git worktree')
            [CompletionResult]::new('open', 'open', [CompletionResultType]::ParameterValue, 'Open an existing Git worktree')
            [CompletionResult]::new('remove', 'remove', [CompletionResultType]::ParameterValue, 'Remove a worktree checkout')
            break
        }
        'herdr;worktree;list' {
            [CompletionResult]::new('--workspace', '--workspace', [CompletionResultType]::ParameterName, 'workspace')
            [CompletionResult]::new('--cwd', '--cwd', [CompletionResultType]::ParameterName, 'cwd')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;worktree;create' {
            [CompletionResult]::new('--workspace', '--workspace', [CompletionResultType]::ParameterName, 'workspace')
            [CompletionResult]::new('--cwd', '--cwd', [CompletionResultType]::ParameterName, 'cwd')
            [CompletionResult]::new('--branch', '--branch', [CompletionResultType]::ParameterName, 'branch')
            [CompletionResult]::new('--base', '--base', [CompletionResultType]::ParameterName, 'base')
            [CompletionResult]::new('--path', '--path', [CompletionResultType]::ParameterName, 'path')
            [CompletionResult]::new('--label', '--label', [CompletionResultType]::ParameterName, 'label')
            [CompletionResult]::new('--focus', '--focus', [CompletionResultType]::ParameterName, 'focus')
            [CompletionResult]::new('--no-focus', '--no-focus', [CompletionResultType]::ParameterName, 'no-focus')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;worktree;open' {
            [CompletionResult]::new('--workspace', '--workspace', [CompletionResultType]::ParameterName, 'workspace')
            [CompletionResult]::new('--cwd', '--cwd', [CompletionResultType]::ParameterName, 'cwd')
            [CompletionResult]::new('--path', '--path', [CompletionResultType]::ParameterName, 'path')
            [CompletionResult]::new('--branch', '--branch', [CompletionResultType]::ParameterName, 'branch')
            [CompletionResult]::new('--label', '--label', [CompletionResultType]::ParameterName, 'label')
            [CompletionResult]::new('--focus', '--focus', [CompletionResultType]::ParameterName, 'focus')
            [CompletionResult]::new('--no-focus', '--no-focus', [CompletionResultType]::ParameterName, 'no-focus')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;worktree;remove' {
            [CompletionResult]::new('--workspace', '--workspace', [CompletionResultType]::ParameterName, 'workspace')
            [CompletionResult]::new('--force', '--force', [CompletionResultType]::ParameterName, 'force')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;tab' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List tabs')
            [CompletionResult]::new('create', 'create', [CompletionResultType]::ParameterValue, 'Create a tab')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Show a tab')
            [CompletionResult]::new('focus', 'focus', [CompletionResultType]::ParameterValue, 'Focus a tab')
            [CompletionResult]::new('rename', 'rename', [CompletionResultType]::ParameterValue, 'Rename a tab')
            [CompletionResult]::new('close', 'close', [CompletionResultType]::ParameterValue, 'Close a tab')
            break
        }
        'herdr;tab;list' {
            [CompletionResult]::new('--workspace', '--workspace', [CompletionResultType]::ParameterName, 'workspace')
            break
        }
        'herdr;tab;create' {
            [CompletionResult]::new('--workspace', '--workspace', [CompletionResultType]::ParameterName, 'workspace')
            [CompletionResult]::new('--cwd', '--cwd', [CompletionResultType]::ParameterName, 'cwd')
            [CompletionResult]::new('--label', '--label', [CompletionResultType]::ParameterName, 'label')
            [CompletionResult]::new('--env', '--env', [CompletionResultType]::ParameterName, 'Set an environment variable for the launched process')
            [CompletionResult]::new('--focus', '--focus', [CompletionResultType]::ParameterName, 'focus')
            [CompletionResult]::new('--no-focus', '--no-focus', [CompletionResultType]::ParameterName, 'no-focus')
            break
        }
        'herdr;tab;get' {
            break
        }
        'herdr;tab;focus' {
            break
        }
        'herdr;tab;rename' {
            break
        }
        'herdr;tab;close' {
            break
        }
        'herdr;notification' {
            [CompletionResult]::new('show', 'show', [CompletionResultType]::ParameterValue, 'Show a notification')
            break
        }
        'herdr;notification;show' {
            [CompletionResult]::new('--body', '--body', [CompletionResultType]::ParameterName, 'body')
            [CompletionResult]::new('--position', '--position', [CompletionResultType]::ParameterName, 'position')
            [CompletionResult]::new('--sound', '--sound', [CompletionResultType]::ParameterName, 'sound')
            break
        }
        'herdr;agent' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List agents')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Show an agent')
            [CompletionResult]::new('read', 'read', [CompletionResultType]::ParameterValue, 'Read agent terminal output')
            [CompletionResult]::new('send', 'send', [CompletionResultType]::ParameterValue, 'Send text to an agent')
            [CompletionResult]::new('rename', 'rename', [CompletionResultType]::ParameterValue, 'Rename an agent')
            [CompletionResult]::new('focus', 'focus', [CompletionResultType]::ParameterValue, 'Focus an agent')
            [CompletionResult]::new('wait', 'wait', [CompletionResultType]::ParameterValue, 'Wait for an agent status')
            [CompletionResult]::new('attach', 'attach', [CompletionResultType]::ParameterValue, 'Attach directly to an agent terminal')
            [CompletionResult]::new('start', 'start', [CompletionResultType]::ParameterValue, 'Start an agent command')
            [CompletionResult]::new('explain', 'explain', [CompletionResultType]::ParameterValue, 'Explain agent detection state')
            break
        }
        'herdr;agent;list' {
            break
        }
        'herdr;agent;get' {
            break
        }
        'herdr;agent;read' {
            [CompletionResult]::new('--source', '--source', [CompletionResultType]::ParameterName, 'source')
            [CompletionResult]::new('--lines', '--lines', [CompletionResultType]::ParameterName, 'lines')
            [CompletionResult]::new('--format', '--format', [CompletionResultType]::ParameterName, 'format')
            [CompletionResult]::new('--ansi', '--ansi', [CompletionResultType]::ParameterName, 'ansi')
            break
        }
        'herdr;agent;send' {
            break
        }
        'herdr;agent;rename' {
            [CompletionResult]::new('--clear', '--clear', [CompletionResultType]::ParameterName, 'clear')
            break
        }
        'herdr;agent;focus' {
            break
        }
        'herdr;agent;wait' {
            [CompletionResult]::new('--status', '--status', [CompletionResultType]::ParameterName, 'status')
            [CompletionResult]::new('--timeout', '--timeout', [CompletionResultType]::ParameterName, 'timeout')
            break
        }
        'herdr;agent;attach' {
            [CompletionResult]::new('--takeover', '--takeover', [CompletionResultType]::ParameterName, 'takeover')
            break
        }
        'herdr;agent;start' {
            [CompletionResult]::new('--cwd', '--cwd', [CompletionResultType]::ParameterName, 'cwd')
            [CompletionResult]::new('--workspace', '--workspace', [CompletionResultType]::ParameterName, 'workspace')
            [CompletionResult]::new('--tab', '--tab', [CompletionResultType]::ParameterName, 'tab')
            [CompletionResult]::new('--split', '--split', [CompletionResultType]::ParameterName, 'split')
            [CompletionResult]::new('--env', '--env', [CompletionResultType]::ParameterName, 'Set an environment variable for the launched process')
            [CompletionResult]::new('--focus', '--focus', [CompletionResultType]::ParameterName, 'focus')
            [CompletionResult]::new('--no-focus', '--no-focus', [CompletionResultType]::ParameterName, 'no-focus')
            break
        }
        'herdr;agent;explain' {
            [CompletionResult]::new('--file', '--file', [CompletionResultType]::ParameterName, 'file')
            [CompletionResult]::new('--agent', '--agent', [CompletionResultType]::ParameterName, 'agent')
            [CompletionResult]::new('--format', '--format', [CompletionResultType]::ParameterName, 'format')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            [CompletionResult]::new('-v', '-v', [CompletionResultType]::ParameterName, 'v')
            [CompletionResult]::new('--verbose', '--verbose', [CompletionResultType]::ParameterName, 'verbose')
            break
        }
        'herdr;pane' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List panes')
            [CompletionResult]::new('current', 'current', [CompletionResultType]::ParameterValue, 'Show the current pane')
            [CompletionResult]::new('get', 'get', [CompletionResultType]::ParameterValue, 'Show a pane')
            [CompletionResult]::new('layout', 'layout', [CompletionResultType]::ParameterValue, 'Show pane layout information')
            [CompletionResult]::new('process-info', 'process-info', [CompletionResultType]::ParameterValue, 'Show pane process information')
            [CompletionResult]::new('neighbor', 'neighbor', [CompletionResultType]::ParameterValue, 'Find a pane neighbor')
            [CompletionResult]::new('edges', 'edges', [CompletionResultType]::ParameterValue, 'Show pane edge information')
            [CompletionResult]::new('focus', 'focus', [CompletionResultType]::ParameterValue, 'Focus a neighboring pane')
            [CompletionResult]::new('resize', 'resize', [CompletionResultType]::ParameterValue, 'Resize a pane split')
            [CompletionResult]::new('zoom', 'zoom', [CompletionResultType]::ParameterValue, 'Toggle or set pane zoom')
            [CompletionResult]::new('read', 'read', [CompletionResultType]::ParameterValue, 'Read pane terminal output')
            [CompletionResult]::new('rename', 'rename', [CompletionResultType]::ParameterValue, 'Rename a pane')
            [CompletionResult]::new('split', 'split', [CompletionResultType]::ParameterValue, 'Split a pane')
            [CompletionResult]::new('swap', 'swap', [CompletionResultType]::ParameterValue, 'Swap panes')
            [CompletionResult]::new('move', 'move', [CompletionResultType]::ParameterValue, 'Move a pane')
            [CompletionResult]::new('close', 'close', [CompletionResultType]::ParameterValue, 'Close a pane')
            [CompletionResult]::new('send-text', 'send-text', [CompletionResultType]::ParameterValue, 'Send literal text to a pane')
            [CompletionResult]::new('send-keys', 'send-keys', [CompletionResultType]::ParameterValue, 'Send key presses to a pane')
            [CompletionResult]::new('run', 'run', [CompletionResultType]::ParameterValue, 'Run a command in a pane')
            [CompletionResult]::new('report-agent', 'report-agent', [CompletionResultType]::ParameterValue, 'Report pane agent lifecycle state')
            [CompletionResult]::new('report-agent-session', 'report-agent-session', [CompletionResultType]::ParameterValue, 'Report pane agent session identity')
            [CompletionResult]::new('release-agent', 'release-agent', [CompletionResultType]::ParameterValue, 'Release pane agent lifecycle authority')
            [CompletionResult]::new('report-metadata', 'report-metadata', [CompletionResultType]::ParameterValue, 'Report display-only pane metadata')
            break
        }
        'herdr;pane;list' {
            [CompletionResult]::new('--workspace', '--workspace', [CompletionResultType]::ParameterName, 'workspace')
            break
        }
        'herdr;pane;current' {
            [CompletionResult]::new('--pane', '--pane', [CompletionResultType]::ParameterName, 'pane')
            [CompletionResult]::new('--current', '--current', [CompletionResultType]::ParameterName, 'current')
            break
        }
        'herdr;pane;get' {
            break
        }
        'herdr;pane;layout' {
            [CompletionResult]::new('--pane', '--pane', [CompletionResultType]::ParameterName, 'pane')
            [CompletionResult]::new('--current', '--current', [CompletionResultType]::ParameterName, 'current')
            break
        }
        'herdr;pane;process-info' {
            [CompletionResult]::new('--pane', '--pane', [CompletionResultType]::ParameterName, 'pane')
            [CompletionResult]::new('--current', '--current', [CompletionResultType]::ParameterName, 'current')
            break
        }
        'herdr;pane;neighbor' {
            [CompletionResult]::new('--direction', '--direction', [CompletionResultType]::ParameterName, 'direction')
            [CompletionResult]::new('--pane', '--pane', [CompletionResultType]::ParameterName, 'pane')
            [CompletionResult]::new('--current', '--current', [CompletionResultType]::ParameterName, 'current')
            break
        }
        'herdr;pane;edges' {
            [CompletionResult]::new('--pane', '--pane', [CompletionResultType]::ParameterName, 'pane')
            [CompletionResult]::new('--current', '--current', [CompletionResultType]::ParameterName, 'current')
            break
        }
        'herdr;pane;focus' {
            [CompletionResult]::new('--direction', '--direction', [CompletionResultType]::ParameterName, 'direction')
            [CompletionResult]::new('--pane', '--pane', [CompletionResultType]::ParameterName, 'pane')
            [CompletionResult]::new('--current', '--current', [CompletionResultType]::ParameterName, 'current')
            break
        }
        'herdr;pane;resize' {
            [CompletionResult]::new('--direction', '--direction', [CompletionResultType]::ParameterName, 'direction')
            [CompletionResult]::new('--amount', '--amount', [CompletionResultType]::ParameterName, 'amount')
            [CompletionResult]::new('--pane', '--pane', [CompletionResultType]::ParameterName, 'pane')
            [CompletionResult]::new('--current', '--current', [CompletionResultType]::ParameterName, 'current')
            break
        }
        'herdr;pane;zoom' {
            [CompletionResult]::new('--pane', '--pane', [CompletionResultType]::ParameterName, 'pane')
            [CompletionResult]::new('--current', '--current', [CompletionResultType]::ParameterName, 'current')
            [CompletionResult]::new('--toggle', '--toggle', [CompletionResultType]::ParameterName, 'toggle')
            [CompletionResult]::new('--on', '--on', [CompletionResultType]::ParameterName, 'on')
            [CompletionResult]::new('--off', '--off', [CompletionResultType]::ParameterName, 'off')
            break
        }
        'herdr;pane;read' {
            [CompletionResult]::new('--source', '--source', [CompletionResultType]::ParameterName, 'source')
            [CompletionResult]::new('--lines', '--lines', [CompletionResultType]::ParameterName, 'lines')
            [CompletionResult]::new('--format', '--format', [CompletionResultType]::ParameterName, 'format')
            [CompletionResult]::new('--ansi', '--ansi', [CompletionResultType]::ParameterName, 'ansi')
            [CompletionResult]::new('--raw', '--raw', [CompletionResultType]::ParameterName, 'raw')
            break
        }
        'herdr;pane;rename' {
            [CompletionResult]::new('--clear', '--clear', [CompletionResultType]::ParameterName, 'clear')
            break
        }
        'herdr;pane;split' {
            [CompletionResult]::new('--pane', '--pane', [CompletionResultType]::ParameterName, 'pane')
            [CompletionResult]::new('--direction', '--direction', [CompletionResultType]::ParameterName, 'direction')
            [CompletionResult]::new('--ratio', '--ratio', [CompletionResultType]::ParameterName, 'ratio')
            [CompletionResult]::new('--cwd', '--cwd', [CompletionResultType]::ParameterName, 'cwd')
            [CompletionResult]::new('--env', '--env', [CompletionResultType]::ParameterName, 'Set an environment variable for the launched process')
            [CompletionResult]::new('--current', '--current', [CompletionResultType]::ParameterName, 'current')
            [CompletionResult]::new('--focus', '--focus', [CompletionResultType]::ParameterName, 'focus')
            [CompletionResult]::new('--no-focus', '--no-focus', [CompletionResultType]::ParameterName, 'no-focus')
            break
        }
        'herdr;pane;swap' {
            [CompletionResult]::new('--direction', '--direction', [CompletionResultType]::ParameterName, 'direction')
            [CompletionResult]::new('--pane', '--pane', [CompletionResultType]::ParameterName, 'pane')
            [CompletionResult]::new('--source-pane', '--source-pane', [CompletionResultType]::ParameterName, 'source-pane')
            [CompletionResult]::new('--target-pane', '--target-pane', [CompletionResultType]::ParameterName, 'target-pane')
            [CompletionResult]::new('--current', '--current', [CompletionResultType]::ParameterName, 'current')
            break
        }
        'herdr;pane;move' {
            [CompletionResult]::new('--tab', '--tab', [CompletionResultType]::ParameterName, 'tab')
            [CompletionResult]::new('--split', '--split', [CompletionResultType]::ParameterName, 'split')
            [CompletionResult]::new('--target-pane', '--target-pane', [CompletionResultType]::ParameterName, 'target-pane')
            [CompletionResult]::new('--ratio', '--ratio', [CompletionResultType]::ParameterName, 'ratio')
            [CompletionResult]::new('--workspace', '--workspace', [CompletionResultType]::ParameterName, 'workspace')
            [CompletionResult]::new('--label', '--label', [CompletionResultType]::ParameterName, 'label')
            [CompletionResult]::new('--tab-label', '--tab-label', [CompletionResultType]::ParameterName, 'tab-label')
            [CompletionResult]::new('--new-tab', '--new-tab', [CompletionResultType]::ParameterName, 'new-tab')
            [CompletionResult]::new('--new-workspace', '--new-workspace', [CompletionResultType]::ParameterName, 'new-workspace')
            [CompletionResult]::new('--focus', '--focus', [CompletionResultType]::ParameterName, 'focus')
            [CompletionResult]::new('--no-focus', '--no-focus', [CompletionResultType]::ParameterName, 'no-focus')
            break
        }
        'herdr;pane;close' {
            break
        }
        'herdr;pane;send-text' {
            break
        }
        'herdr;pane;send-keys' {
            break
        }
        'herdr;pane;run' {
            break
        }
        'herdr;pane;report-agent' {
            [CompletionResult]::new('--source', '--source', [CompletionResultType]::ParameterName, 'source')
            [CompletionResult]::new('--agent', '--agent', [CompletionResultType]::ParameterName, 'agent')
            [CompletionResult]::new('--state', '--state', [CompletionResultType]::ParameterName, 'state')
            [CompletionResult]::new('--message', '--message', [CompletionResultType]::ParameterName, 'message')
            [CompletionResult]::new('--seq', '--seq', [CompletionResultType]::ParameterName, 'seq')
            [CompletionResult]::new('--agent-session-id', '--agent-session-id', [CompletionResultType]::ParameterName, 'agent-session-id')
            [CompletionResult]::new('--agent-session-path', '--agent-session-path', [CompletionResultType]::ParameterName, 'agent-session-path')
            break
        }
        'herdr;pane;report-agent-session' {
            [CompletionResult]::new('--source', '--source', [CompletionResultType]::ParameterName, 'source')
            [CompletionResult]::new('--agent', '--agent', [CompletionResultType]::ParameterName, 'agent')
            [CompletionResult]::new('--seq', '--seq', [CompletionResultType]::ParameterName, 'seq')
            [CompletionResult]::new('--agent-session-id', '--agent-session-id', [CompletionResultType]::ParameterName, 'agent-session-id')
            [CompletionResult]::new('--agent-session-path', '--agent-session-path', [CompletionResultType]::ParameterName, 'agent-session-path')
            [CompletionResult]::new('--session-start-source', '--session-start-source', [CompletionResultType]::ParameterName, 'session-start-source')
            break
        }
        'herdr;pane;release-agent' {
            [CompletionResult]::new('--source', '--source', [CompletionResultType]::ParameterName, 'source')
            [CompletionResult]::new('--agent', '--agent', [CompletionResultType]::ParameterName, 'agent')
            [CompletionResult]::new('--seq', '--seq', [CompletionResultType]::ParameterName, 'seq')
            break
        }
        'herdr;pane;report-metadata' {
            [CompletionResult]::new('--source', '--source', [CompletionResultType]::ParameterName, 'source')
            [CompletionResult]::new('--agent', '--agent', [CompletionResultType]::ParameterName, 'agent')
            [CompletionResult]::new('--applies-to-source', '--applies-to-source', [CompletionResultType]::ParameterName, 'applies-to-source')
            [CompletionResult]::new('--title', '--title', [CompletionResultType]::ParameterName, 'title')
            [CompletionResult]::new('--display-agent', '--display-agent', [CompletionResultType]::ParameterName, 'display-agent')
            [CompletionResult]::new('--state-label', '--state-label', [CompletionResultType]::ParameterName, 'state-label')
            [CompletionResult]::new('--token', '--token', [CompletionResultType]::ParameterName, 'token')
            [CompletionResult]::new('--clear-token', '--clear-token', [CompletionResultType]::ParameterName, 'clear-token')
            [CompletionResult]::new('--seq', '--seq', [CompletionResultType]::ParameterName, 'seq')
            [CompletionResult]::new('--ttl-ms', '--ttl-ms', [CompletionResultType]::ParameterName, 'ttl-ms')
            [CompletionResult]::new('--clear-title', '--clear-title', [CompletionResultType]::ParameterName, 'clear-title')
            [CompletionResult]::new('--clear-display-agent', '--clear-display-agent', [CompletionResultType]::ParameterName, 'clear-display-agent')
            [CompletionResult]::new('--clear-state-labels', '--clear-state-labels', [CompletionResultType]::ParameterName, 'clear-state-labels')
            break
        }
        'herdr;wait' {
            [CompletionResult]::new('output', 'output', [CompletionResultType]::ParameterValue, 'Wait for matching pane output')
            [CompletionResult]::new('agent-status', 'agent-status', [CompletionResultType]::ParameterValue, 'Wait for pane agent status')
            break
        }
        'herdr;wait;output' {
            [CompletionResult]::new('--match', '--match', [CompletionResultType]::ParameterName, 'match')
            [CompletionResult]::new('--source', '--source', [CompletionResultType]::ParameterName, 'source')
            [CompletionResult]::new('--lines', '--lines', [CompletionResultType]::ParameterName, 'lines')
            [CompletionResult]::new('--timeout', '--timeout', [CompletionResultType]::ParameterName, 'timeout')
            [CompletionResult]::new('--regex', '--regex', [CompletionResultType]::ParameterName, 'regex')
            [CompletionResult]::new('--raw', '--raw', [CompletionResultType]::ParameterName, 'raw')
            break
        }
        'herdr;wait;agent-status' {
            [CompletionResult]::new('--status', '--status', [CompletionResultType]::ParameterName, 'status')
            [CompletionResult]::new('--timeout', '--timeout', [CompletionResultType]::ParameterName, 'timeout')
            break
        }
        'herdr;terminal' {
            [CompletionResult]::new('attach', 'attach', [CompletionResultType]::ParameterValue, 'Attach directly to a terminal stream')
            [CompletionResult]::new('session', 'session', [CompletionResultType]::ParameterValue, 'Work with terminal sessions')
            [CompletionResult]::new('title', 'title', [CompletionResultType]::ParameterValue, 'Manage the outer terminal title')
            break
        }
        'herdr;terminal;attach' {
            [CompletionResult]::new('--takeover', '--takeover', [CompletionResultType]::ParameterName, 'takeover')
            break
        }
        'herdr;terminal;session' {
            [CompletionResult]::new('observe', 'observe', [CompletionResultType]::ParameterValue, 'Observe a terminal stream')
            break
        }
        'herdr;terminal;session;observe' {
            [CompletionResult]::new('--cols', '--cols', [CompletionResultType]::ParameterName, 'cols')
            [CompletionResult]::new('--rows', '--rows', [CompletionResultType]::ParameterName, 'rows')
            break
        }
        'herdr;terminal;title' {
            [CompletionResult]::new('set', 'set', [CompletionResultType]::ParameterValue, 'Set the outer terminal title')
            [CompletionResult]::new('clear', 'clear', [CompletionResultType]::ParameterValue, 'Clear the outer terminal title')
            break
        }
        'herdr;terminal;title;set' {
            break
        }
        'herdr;terminal;title;clear' {
            break
        }
        'herdr;session' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List sessions')
            [CompletionResult]::new('attach', 'attach', [CompletionResultType]::ParameterValue, 'Attach to a session')
            [CompletionResult]::new('stop', 'stop', [CompletionResultType]::ParameterValue, 'Stop a session')
            [CompletionResult]::new('delete', 'delete', [CompletionResultType]::ParameterValue, 'Delete a stopped session')
            break
        }
        'herdr;session;list' {
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;session;attach' {
            break
        }
        'herdr;session;stop' {
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;session;delete' {
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;integration' {
            [CompletionResult]::new('install', 'install', [CompletionResultType]::ParameterValue, 'Install an integration')
            [CompletionResult]::new('uninstall', 'uninstall', [CompletionResultType]::ParameterValue, 'Uninstall an integration')
            [CompletionResult]::new('status', 'status', [CompletionResultType]::ParameterValue, 'Show integration status')
            break
        }
        'herdr;integration;install' {
            break
        }
        'herdr;integration;uninstall' {
            break
        }
        'herdr;integration;status' {
            [CompletionResult]::new('--outdated-only', '--outdated-only', [CompletionResultType]::ParameterName, 'outdated-only')
            break
        }
        'herdr;plugin' {
            [CompletionResult]::new('install', 'install', [CompletionResultType]::ParameterValue, 'Install a plugin from GitHub')
            [CompletionResult]::new('uninstall', 'uninstall', [CompletionResultType]::ParameterValue, 'Uninstall a plugin')
            [CompletionResult]::new('link', 'link', [CompletionResultType]::ParameterValue, 'Link a local plugin')
            [CompletionResult]::new('unlink', 'unlink', [CompletionResultType]::ParameterValue, 'Unlink a local plugin')
            [CompletionResult]::new('enable', 'enable', [CompletionResultType]::ParameterValue, 'Enable a plugin')
            [CompletionResult]::new('disable', 'disable', [CompletionResultType]::ParameterValue, 'Disable a plugin')
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List installed plugins')
            [CompletionResult]::new('config-dir', 'config-dir', [CompletionResultType]::ParameterValue, 'Print a plugin config directory')
            [CompletionResult]::new('action', 'action', [CompletionResultType]::ParameterValue, 'List or invoke plugin actions')
            [CompletionResult]::new('log', 'log', [CompletionResultType]::ParameterValue, 'Inspect plugin command logs')
            [CompletionResult]::new('logs', 'logs', [CompletionResultType]::ParameterValue, 'Inspect plugin command logs')
            [CompletionResult]::new('pane', 'pane', [CompletionResultType]::ParameterValue, 'Manage plugin-owned panes')
            break
        }
        'herdr;plugin;install' {
            [CompletionResult]::new('--ref', '--ref', [CompletionResultType]::ParameterName, 'ref')
            [CompletionResult]::new('-y', '-y', [CompletionResultType]::ParameterName, 'y')
            [CompletionResult]::new('--yes', '--yes', [CompletionResultType]::ParameterName, 'yes')
            break
        }
        'herdr;plugin;uninstall' {
            break
        }
        'herdr;plugin;link' {
            [CompletionResult]::new('--disabled', '--disabled', [CompletionResultType]::ParameterName, 'disabled')
            [CompletionResult]::new('--enabled', '--enabled', [CompletionResultType]::ParameterName, 'enabled')
            break
        }
        'herdr;plugin;unlink' {
            break
        }
        'herdr;plugin;enable' {
            break
        }
        'herdr;plugin;disable' {
            break
        }
        'herdr;plugin;list' {
            [CompletionResult]::new('--plugin', '--plugin', [CompletionResultType]::ParameterName, 'plugin')
            [CompletionResult]::new('--json', '--json', [CompletionResultType]::ParameterName, 'json')
            break
        }
        'herdr;plugin;config-dir' {
            break
        }
        'herdr;plugin;action' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List plugin actions')
            [CompletionResult]::new('invoke', 'invoke', [CompletionResultType]::ParameterValue, 'Invoke a plugin action')
            break
        }
        'herdr;plugin;action;list' {
            [CompletionResult]::new('--plugin', '--plugin', [CompletionResultType]::ParameterName, 'plugin')
            break
        }
        'herdr;plugin;action;invoke' {
            [CompletionResult]::new('--plugin', '--plugin', [CompletionResultType]::ParameterName, 'plugin')
            break
        }
        'herdr;plugin;log' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List plugin command logs')
            break
        }
        'herdr;plugin;logs' {
            [CompletionResult]::new('list', 'list', [CompletionResultType]::ParameterValue, 'List plugin command logs')
            break
        }
        'herdr;plugin;log;list' {
            [CompletionResult]::new('--plugin', '--plugin', [CompletionResultType]::ParameterName, 'plugin')
            [CompletionResult]::new('--limit', '--limit', [CompletionResultType]::ParameterName, 'limit')
            break
        }
        'herdr;plugin;logs;list' {
            [CompletionResult]::new('--plugin', '--plugin', [CompletionResultType]::ParameterName, 'plugin')
            [CompletionResult]::new('--limit', '--limit', [CompletionResultType]::ParameterName, 'limit')
            break
        }
        'herdr;plugin;pane' {
            [CompletionResult]::new('open', 'open', [CompletionResultType]::ParameterValue, 'Open a plugin pane')
            [CompletionResult]::new('focus', 'focus', [CompletionResultType]::ParameterValue, 'Focus a plugin pane')
            [CompletionResult]::new('close', 'close', [CompletionResultType]::ParameterValue, 'Close a plugin pane')
            break
        }
        'herdr;plugin;pane;open' {
            [CompletionResult]::new('--plugin', '--plugin', [CompletionResultType]::ParameterName, 'plugin')
            [CompletionResult]::new('--entrypoint', '--entrypoint', [CompletionResultType]::ParameterName, 'entrypoint')
            [CompletionResult]::new('--placement', '--placement', [CompletionResultType]::ParameterName, 'placement')
            [CompletionResult]::new('--workspace', '--workspace', [CompletionResultType]::ParameterName, 'workspace')
            [CompletionResult]::new('--target-pane', '--target-pane', [CompletionResultType]::ParameterName, 'target-pane')
            [CompletionResult]::new('--direction', '--direction', [CompletionResultType]::ParameterName, 'direction')
            [CompletionResult]::new('--cwd', '--cwd', [CompletionResultType]::ParameterName, 'cwd')
            [CompletionResult]::new('--env', '--env', [CompletionResultType]::ParameterName, 'Set an environment variable for the launched process')
            [CompletionResult]::new('--focus', '--focus', [CompletionResultType]::ParameterName, 'focus')
            [CompletionResult]::new('--no-focus', '--no-focus', [CompletionResultType]::ParameterName, 'no-focus')
            break
        }
        'herdr;plugin;pane;focus' {
            break
        }
        'herdr;plugin;pane;close' {
            break
        }
    })

    $completions.Where{ $_.CompletionText -like "$wordToComplete*" } |
        Sort-Object -Property ListItemText
}
