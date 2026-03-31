
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -Native -CommandName 'zellij' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandElements = $commandAst.CommandElements
    $command = @(
        'zellij'
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
        'zellij' {
            [CompletionResult]::new('--max-panes', 'max-panes', [CompletionResultType]::ParameterName, 'Maximum panes on screen, caution: opening more panes will close old ones')
            [CompletionResult]::new('--data-dir', 'data-dir', [CompletionResultType]::ParameterName, 'Change where zellij looks for plugins')
            [CompletionResult]::new('--server', 'server', [CompletionResultType]::ParameterName, 'Run server listening at the specified socket path')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 'Specify name of a new session')
            [CompletionResult]::new('--session', 'session', [CompletionResultType]::ParameterName, 'Specify name of a new session')
            [CompletionResult]::new('-l', 'l', [CompletionResultType]::ParameterName, 'Name of a predefined layout inside the layout directory or the path to a layout file if inside a session (or using the --session flag) will be added to the session as a new tab or tabs, otherwise will start a new session')
            [CompletionResult]::new('--layout', 'layout', [CompletionResultType]::ParameterName, 'Name of a predefined layout inside the layout directory or the path to a layout file if inside a session (or using the --session flag) will be added to the session as a new tab or tabs, otherwise will start a new session')
            [CompletionResult]::new('-n', 'n', [CompletionResultType]::ParameterName, 'Name of a predefined layout inside the layout directory or the path to a layout file Will always start a new session, even if inside an existing session')
            [CompletionResult]::new('--new-session-with-layout', 'new-session-with-layout', [CompletionResultType]::ParameterName, 'Name of a predefined layout inside the layout directory or the path to a layout file Will always start a new session, even if inside an existing session')
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Change where zellij looks for the configuration file')
            [CompletionResult]::new('--config', 'config', [CompletionResultType]::ParameterName, 'Change where zellij looks for the configuration file')
            [CompletionResult]::new('--config-dir', 'config-dir', [CompletionResultType]::ParameterName, 'Change where zellij looks for the configuration directory')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('-V', 'V', [CompletionResultType]::ParameterName, 'Print version information')
            [CompletionResult]::new('--version', 'version', [CompletionResultType]::ParameterName, 'Print version information')
            [CompletionResult]::new('-d', 'd', [CompletionResultType]::ParameterName, 'Specify emitting additional debug information')
            [CompletionResult]::new('--debug', 'debug', [CompletionResultType]::ParameterName, 'Specify emitting additional debug information')
            [CompletionResult]::new('options', 'options', [CompletionResultType]::ParameterValue, 'Change the behaviour of zellij')
            [CompletionResult]::new('setup', 'setup', [CompletionResultType]::ParameterValue, 'Setup zellij and check its configuration')
            [CompletionResult]::new('web', 'web', [CompletionResultType]::ParameterValue, 'Run a web server to serve terminal sessions')
            [CompletionResult]::new('action', 'action', [CompletionResultType]::ParameterValue, 'Send actions to a specific session')
            [CompletionResult]::new('list-sessions', 'list-sessions', [CompletionResultType]::ParameterValue, 'List active sessions')
            [CompletionResult]::new('list-aliases', 'list-aliases', [CompletionResultType]::ParameterValue, 'List existing plugin aliases')
            [CompletionResult]::new('attach', 'attach', [CompletionResultType]::ParameterValue, 'Attach to a session')
            [CompletionResult]::new('watch', 'watch', [CompletionResultType]::ParameterValue, 'Watch a session (read-only)')
            [CompletionResult]::new('kill-session', 'kill-session', [CompletionResultType]::ParameterValue, 'Kill a specific session')
            [CompletionResult]::new('delete-session', 'delete-session', [CompletionResultType]::ParameterValue, 'Delete a specific session')
            [CompletionResult]::new('kill-all-sessions', 'kill-all-sessions', [CompletionResultType]::ParameterValue, 'Kill all sessions')
            [CompletionResult]::new('delete-all-sessions', 'delete-all-sessions', [CompletionResultType]::ParameterValue, 'Delete all sessions')
            [CompletionResult]::new('run', 'run', [CompletionResultType]::ParameterValue, 'Run a command in a new pane Returns: Created pane ID (format: terminal_<id>)')
            [CompletionResult]::new('plugin', 'plugin', [CompletionResultType]::ParameterValue, 'Load a plugin Returns: Created pane ID (format: plugin_<id>)')
            [CompletionResult]::new('edit', 'edit', [CompletionResultType]::ParameterValue, 'Edit file with default $EDITOR / $VISUAL Returns: Created pane ID (format: terminal_<id>)')
            [CompletionResult]::new('convert-config', 'convert-config', [CompletionResultType]::ParameterValue, 'convert-config')
            [CompletionResult]::new('convert-layout', 'convert-layout', [CompletionResultType]::ParameterValue, 'convert-layout')
            [CompletionResult]::new('convert-theme', 'convert-theme', [CompletionResultType]::ParameterValue, 'convert-theme')
            [CompletionResult]::new('pipe', 'pipe', [CompletionResultType]::ParameterValue, 'Send data to one or more plugins, launch them if they are not running')
            [CompletionResult]::new('subscribe', 'subscribe', [CompletionResultType]::ParameterValue, 'Subscribe to pane render updates (viewport and scrollback)')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'zellij;options' {
            [CompletionResult]::new('--simplified-ui', 'simplified-ui', [CompletionResultType]::ParameterName, 'Allow plugins to use a more simplified layout that is compatible with more fonts (true or false)')
            [CompletionResult]::new('--theme', 'theme', [CompletionResultType]::ParameterName, 'Set the default theme')
            [CompletionResult]::new('--default-mode', 'default-mode', [CompletionResultType]::ParameterName, 'Set the default mode')
            [CompletionResult]::new('--default-shell', 'default-shell', [CompletionResultType]::ParameterName, 'Set the default shell')
            [CompletionResult]::new('--default-cwd', 'default-cwd', [CompletionResultType]::ParameterName, 'Set the default cwd')
            [CompletionResult]::new('--default-layout', 'default-layout', [CompletionResultType]::ParameterName, 'Set the default layout')
            [CompletionResult]::new('--layout-dir', 'layout-dir', [CompletionResultType]::ParameterName, 'Set the layout_dir, defaults to subdirectory of config dir')
            [CompletionResult]::new('--theme-dir', 'theme-dir', [CompletionResultType]::ParameterName, 'Set the theme_dir, defaults to subdirectory of config dir')
            [CompletionResult]::new('--mouse-mode', 'mouse-mode', [CompletionResultType]::ParameterName, 'Set the handling of mouse events (true or false) Can be temporarily bypassed by the [SHIFT] key')
            [CompletionResult]::new('--pane-frames', 'pane-frames', [CompletionResultType]::ParameterName, 'Set display of the pane frames (true or false)')
            [CompletionResult]::new('--mirror-session', 'mirror-session', [CompletionResultType]::ParameterName, 'Mirror session when multiple users are connected (true or false)')
            [CompletionResult]::new('--on-force-close', 'on-force-close', [CompletionResultType]::ParameterName, 'Set behaviour on force close (quit or detach)')
            [CompletionResult]::new('--scroll-buffer-size', 'scroll-buffer-size', [CompletionResultType]::ParameterName, 'scroll-buffer-size')
            [CompletionResult]::new('--copy-command', 'copy-command', [CompletionResultType]::ParameterName, 'Switch to using a user supplied command for clipboard instead of OSC52')
            [CompletionResult]::new('--copy-clipboard', 'copy-clipboard', [CompletionResultType]::ParameterName, 'OSC52 destination clipboard')
            [CompletionResult]::new('--copy-on-select', 'copy-on-select', [CompletionResultType]::ParameterName, 'Automatically copy when selecting text (true or false)')
            [CompletionResult]::new('--osc8-hyperlinks', 'osc8-hyperlinks', [CompletionResultType]::ParameterName, 'Enable OSC8 hyperlink output (true or false)')
            [CompletionResult]::new('--scrollback-editor', 'scrollback-editor', [CompletionResultType]::ParameterName, 'Explicit full path to open the scrollback editor (default is $EDITOR or $VISUAL)')
            [CompletionResult]::new('--session-name', 'session-name', [CompletionResultType]::ParameterName, 'The name of the session to create when starting Zellij')
            [CompletionResult]::new('--attach-to-session', 'attach-to-session', [CompletionResultType]::ParameterName, 'Whether to attach to a session specified in "session-name" if it exists')
            [CompletionResult]::new('--auto-layout', 'auto-layout', [CompletionResultType]::ParameterName, 'Whether to lay out panes in a predefined set of layouts whenever possible')
            [CompletionResult]::new('--session-serialization', 'session-serialization', [CompletionResultType]::ParameterName, 'Whether sessions should be serialized to the HD so that they can be later resurrected, default is true')
            [CompletionResult]::new('--serialize-pane-viewport', 'serialize-pane-viewport', [CompletionResultType]::ParameterName, 'Whether pane viewports are serialized along with the session, default is false')
            [CompletionResult]::new('--scrollback-lines-to-serialize', 'scrollback-lines-to-serialize', [CompletionResultType]::ParameterName, 'Scrollback lines to serialize along with the pane viewport when serializing sessions, 0 defaults to the scrollback size. If this number is higher than the scrollback size, it will also default to the scrollback size')
            [CompletionResult]::new('--styled-underlines', 'styled-underlines', [CompletionResultType]::ParameterName, 'Whether to use ANSI styled underlines')
            [CompletionResult]::new('--serialization-interval', 'serialization-interval', [CompletionResultType]::ParameterName, 'The interval at which to serialize sessions for resurrection (in seconds)')
            [CompletionResult]::new('--disable-session-metadata', 'disable-session-metadata', [CompletionResultType]::ParameterName, 'If true, will disable writing session metadata to disk')
            [CompletionResult]::new('--support-kitty-keyboard-protocol', 'support-kitty-keyboard-protocol', [CompletionResultType]::ParameterName, 'Whether to enable support for the Kitty keyboard protocol (must also be supported by the host terminal), defaults to true if the terminal supports it')
            [CompletionResult]::new('--web-server', 'web-server', [CompletionResultType]::ParameterName, 'Whether to make sure a local web server is running when a new Zellij session starts. This web server will allow creating new sessions and attaching to existing ones that have opted in to being shared in the browser')
            [CompletionResult]::new('--web-sharing', 'web-sharing', [CompletionResultType]::ParameterName, 'Whether to allow new sessions to be shared through a local web server, assuming one is running (see the `web_server` option for more details)')
            [CompletionResult]::new('--stacked-resize', 'stacked-resize', [CompletionResultType]::ParameterName, 'Whether to stack panes when resizing beyond a certain size default is true')
            [CompletionResult]::new('--show-startup-tips', 'show-startup-tips', [CompletionResultType]::ParameterName, 'Whether to show startup tips when starting a new session default is true')
            [CompletionResult]::new('--show-release-notes', 'show-release-notes', [CompletionResultType]::ParameterName, 'Whether to show release notes on first run of a new version default is true')
            [CompletionResult]::new('--advanced-mouse-actions', 'advanced-mouse-actions', [CompletionResultType]::ParameterName, 'Whether to enable mouse hover effects and pane grouping functionality default is true')
            [CompletionResult]::new('--mouse-hover-effects', 'mouse-hover-effects', [CompletionResultType]::ParameterName, 'Whether to enable mouse hover visual effects (frame highlight and help text) default is true')
            [CompletionResult]::new('--visual-bell', 'visual-bell', [CompletionResultType]::ParameterName, 'Whether to show visual bell indicators (pane/tab frame flash and [!] suffix) default is true')
            [CompletionResult]::new('--focus-follows-mouse', 'focus-follows-mouse', [CompletionResultType]::ParameterName, 'Whether to focus panes on mouse hover (true or false) default is false')
            [CompletionResult]::new('--mouse-click-through', 'mouse-click-through', [CompletionResultType]::ParameterName, 'Whether clicking a pane to focus it also sends the click into the pane (true or false) default is false')
            [CompletionResult]::new('--post-command-discovery-hook', 'post-command-discovery-hook', [CompletionResultType]::ParameterName, 'A command to run after the discovery of running commands when serializing, for the purpose of manipulating the command (eg. with a regex) before it gets serialized')
            [CompletionResult]::new('--client-async-worker-tasks', 'client-async-worker-tasks', [CompletionResultType]::ParameterName, 'Number of async worker tasks to spawn per active client')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;setup' {
            [CompletionResult]::new('--dump-layout', 'dump-layout', [CompletionResultType]::ParameterName, 'Dump specified layout to stdout')
            [CompletionResult]::new('--dump-swap-layout', 'dump-swap-layout', [CompletionResultType]::ParameterName, 'Dump the specified swap layout file to stdout')
            [CompletionResult]::new('--dump-plugins', 'dump-plugins', [CompletionResultType]::ParameterName, 'Dump the builtin plugins to DIR or "DATA DIR" if unspecified')
            [CompletionResult]::new('--generate-completion', 'generate-completion', [CompletionResultType]::ParameterName, 'Generates completion for the specified shell')
            [CompletionResult]::new('--generate-auto-start', 'generate-auto-start', [CompletionResultType]::ParameterName, 'Generates auto-start script for the specified shell')
            [CompletionResult]::new('--dump-config', 'dump-config', [CompletionResultType]::ParameterName, 'Dump the default configuration file to stdout')
            [CompletionResult]::new('--clean', 'clean', [CompletionResultType]::ParameterName, 'Disables loading of configuration file at default location, loads the defaults that zellij ships with')
            [CompletionResult]::new('--check', 'check', [CompletionResultType]::ParameterName, 'Checks the configuration of zellij and displays currently used directories')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;web' {
            [CompletionResult]::new('--timeout', 'timeout', [CompletionResultType]::ParameterName, 'Timeout in seconds for the status check (default: 30)')
            [CompletionResult]::new('--server-startup-timeout', 'server-startup-timeout', [CompletionResultType]::ParameterName, 'Timeout in seconds waiting for the server to start (default: 10). Only used on Windows where the daemonized server is polled via TCP. On Unix, startup signaling uses pipes and this option is ignored')
            [CompletionResult]::new('--token-name', 'token-name', [CompletionResultType]::ParameterName, 'Optional name for the token')
            [CompletionResult]::new('--revoke-token', 'revoke-token', [CompletionResultType]::ParameterName, 'Revoke a login token by its name')
            [CompletionResult]::new('--ip', 'ip', [CompletionResultType]::ParameterName, 'The ip address to listen on locally for connections (defaults to 127.0.0.1)')
            [CompletionResult]::new('--port', 'port', [CompletionResultType]::ParameterName, 'The port to listen on locally for connections (defaults to 8082)')
            [CompletionResult]::new('--cert', 'cert', [CompletionResultType]::ParameterName, 'The path to the SSL certificate (required if not listening on 127.0.0.1)')
            [CompletionResult]::new('--key', 'key', [CompletionResultType]::ParameterName, 'The path to the SSL key (required if not listening on 127.0.0.1)')
            [CompletionResult]::new('--start', 'start', [CompletionResultType]::ParameterName, 'Start the server (default unless other arguments are specified)')
            [CompletionResult]::new('--stop', 'stop', [CompletionResultType]::ParameterName, 'Stop the server')
            [CompletionResult]::new('--status', 'status', [CompletionResultType]::ParameterName, 'Get the server status')
            [CompletionResult]::new('-d', 'd', [CompletionResultType]::ParameterName, 'Run the server in the background')
            [CompletionResult]::new('--daemonize', 'daemonize', [CompletionResultType]::ParameterName, 'Run the server in the background')
            [CompletionResult]::new('--create-token', 'create-token', [CompletionResultType]::ParameterName, 'Create a login token for the web interface, will only be displayed once and cannot later be retrieved. Returns the token name and the token')
            [CompletionResult]::new('--create-read-only-token', 'create-read-only-token', [CompletionResultType]::ParameterName, 'Create a read-only login token (can only attach to existing sessions as watcher)')
            [CompletionResult]::new('--revoke-all-tokens', 'revoke-all-tokens', [CompletionResultType]::ParameterName, 'Revoke all login tokens')
            [CompletionResult]::new('--list-tokens', 'list-tokens', [CompletionResultType]::ParameterName, 'List token names and their creation dates (cannot show actual tokens)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('write', 'write', [CompletionResultType]::ParameterValue, 'Write bytes to the terminal')
            [CompletionResult]::new('write-chars', 'write-chars', [CompletionResultType]::ParameterValue, 'Write characters to the terminal')
            [CompletionResult]::new('paste', 'paste', [CompletionResultType]::ParameterValue, 'Paste text to the terminal (using bracketed paste mode)')
            [CompletionResult]::new('send-keys', 'send-keys', [CompletionResultType]::ParameterValue, 'Send one or more keys to the terminal (e.g., "Ctrl a", "F1", "Alt Shift b")')
            [CompletionResult]::new('resize', 'resize', [CompletionResultType]::ParameterValue, '[increase|decrease] the focused panes area at the [left|down|up|right] border')
            [CompletionResult]::new('focus-next-pane', 'focus-next-pane', [CompletionResultType]::ParameterValue, 'Change focus to the next pane')
            [CompletionResult]::new('focus-previous-pane', 'focus-previous-pane', [CompletionResultType]::ParameterValue, 'Change focus to the previous pane')
            [CompletionResult]::new('move-focus', 'move-focus', [CompletionResultType]::ParameterValue, 'Move the focused pane in the specified direction. [right|left|up|down]')
            [CompletionResult]::new('move-focus-or-tab', 'move-focus-or-tab', [CompletionResultType]::ParameterValue, 'Move focus to the pane or tab (if on screen edge) in the specified direction [right|left|up|down]')
            [CompletionResult]::new('move-pane', 'move-pane', [CompletionResultType]::ParameterValue, 'Change the location of the focused pane in the specified direction or rotate forwrads [right|left|up|down]')
            [CompletionResult]::new('move-pane-backwards', 'move-pane-backwards', [CompletionResultType]::ParameterValue, 'Rotate the location of the previous pane backwards')
            [CompletionResult]::new('clear', 'clear', [CompletionResultType]::ParameterValue, 'Clear all buffers for a focused pane')
            [CompletionResult]::new('dump-screen', 'dump-screen', [CompletionResultType]::ParameterValue, 'Dumps the viewport and optionally scrollback of a pane to a file or STDOUT')
            [CompletionResult]::new('dump-layout', 'dump-layout', [CompletionResultType]::ParameterValue, 'Dump current layout to stdout')
            [CompletionResult]::new('save-session', 'save-session', [CompletionResultType]::ParameterValue, 'Save the current session state to disk immediately')
            [CompletionResult]::new('edit-scrollback', 'edit-scrollback', [CompletionResultType]::ParameterValue, 'Open the pane scrollback in your default editor')
            [CompletionResult]::new('scroll-up', 'scroll-up', [CompletionResultType]::ParameterValue, 'Scroll up in the focused pane')
            [CompletionResult]::new('scroll-down', 'scroll-down', [CompletionResultType]::ParameterValue, 'Scroll down in focus pane')
            [CompletionResult]::new('scroll-to-bottom', 'scroll-to-bottom', [CompletionResultType]::ParameterValue, 'Scroll down to bottom in focus pane')
            [CompletionResult]::new('scroll-to-top', 'scroll-to-top', [CompletionResultType]::ParameterValue, 'Scroll up to top in focus pane')
            [CompletionResult]::new('page-scroll-up', 'page-scroll-up', [CompletionResultType]::ParameterValue, 'Scroll up one page in focus pane')
            [CompletionResult]::new('page-scroll-down', 'page-scroll-down', [CompletionResultType]::ParameterValue, 'Scroll down one page in focus pane')
            [CompletionResult]::new('half-page-scroll-up', 'half-page-scroll-up', [CompletionResultType]::ParameterValue, 'Scroll up half page in focus pane')
            [CompletionResult]::new('half-page-scroll-down', 'half-page-scroll-down', [CompletionResultType]::ParameterValue, 'Scroll down half page in focus pane')
            [CompletionResult]::new('toggle-fullscreen', 'toggle-fullscreen', [CompletionResultType]::ParameterValue, 'Toggle between fullscreen focus pane and normal layout')
            [CompletionResult]::new('toggle-pane-frames', 'toggle-pane-frames', [CompletionResultType]::ParameterValue, 'Toggle frames around panes in the UI')
            [CompletionResult]::new('toggle-active-sync-tab', 'toggle-active-sync-tab', [CompletionResultType]::ParameterValue, 'Toggle between sending text commands to all panes on the current tab and normal mode')
            [CompletionResult]::new('new-pane', 'new-pane', [CompletionResultType]::ParameterValue, 'Open a new pane in the specified direction [right|down] If no direction is specified, will try to use the biggest available space. Returns: Created pane ID (format: terminal_<id> or plugin_<id>)')
            [CompletionResult]::new('edit', 'edit', [CompletionResultType]::ParameterValue, 'Open the specified file in a new zellij pane with your default EDITOR Returns: Created pane ID (format: terminal_<id>)')
            [CompletionResult]::new('switch-mode', 'switch-mode', [CompletionResultType]::ParameterValue, 'Switch input mode of all connected clients [locked|pane|tab|resize|move|search|session]')
            [CompletionResult]::new('toggle-pane-embed-or-floating', 'toggle-pane-embed-or-floating', [CompletionResultType]::ParameterValue, 'Embed focused pane if floating or float focused pane if embedded')
            [CompletionResult]::new('toggle-floating-panes', 'toggle-floating-panes', [CompletionResultType]::ParameterValue, 'Toggle the visibility of all floating panes in the current Tab, open one if none exist')
            [CompletionResult]::new('show-floating-panes', 'show-floating-panes', [CompletionResultType]::ParameterValue, 'Show all floating panes in the specified tab (or active tab if tab_id is not provided)')
            [CompletionResult]::new('hide-floating-panes', 'hide-floating-panes', [CompletionResultType]::ParameterValue, 'Hide all floating panes in the specified tab (or active tab if tab_id is not provided)')
            [CompletionResult]::new('close-pane', 'close-pane', [CompletionResultType]::ParameterValue, 'Close the focused pane')
            [CompletionResult]::new('rename-pane', 'rename-pane', [CompletionResultType]::ParameterValue, 'Renames the focused pane')
            [CompletionResult]::new('undo-rename-pane', 'undo-rename-pane', [CompletionResultType]::ParameterValue, 'Remove a previously set pane name')
            [CompletionResult]::new('go-to-next-tab', 'go-to-next-tab', [CompletionResultType]::ParameterValue, 'Go to the next tab')
            [CompletionResult]::new('go-to-previous-tab', 'go-to-previous-tab', [CompletionResultType]::ParameterValue, 'Go to the previous tab')
            [CompletionResult]::new('close-tab', 'close-tab', [CompletionResultType]::ParameterValue, 'Close the current tab')
            [CompletionResult]::new('go-to-tab', 'go-to-tab', [CompletionResultType]::ParameterValue, 'Go to tab with index [index]')
            [CompletionResult]::new('go-to-tab-name', 'go-to-tab-name', [CompletionResultType]::ParameterValue, 'Go to tab with name [name]')
            [CompletionResult]::new('rename-tab', 'rename-tab', [CompletionResultType]::ParameterValue, 'Renames the focused pane')
            [CompletionResult]::new('undo-rename-tab', 'undo-rename-tab', [CompletionResultType]::ParameterValue, 'Remove a previously set tab name')
            [CompletionResult]::new('go-to-tab-by-id', 'go-to-tab-by-id', [CompletionResultType]::ParameterValue, 'Go to tab with stable ID')
            [CompletionResult]::new('close-tab-by-id', 'close-tab-by-id', [CompletionResultType]::ParameterValue, 'Close tab with stable ID')
            [CompletionResult]::new('rename-tab-by-id', 'rename-tab-by-id', [CompletionResultType]::ParameterValue, 'Rename tab by stable ID')
            [CompletionResult]::new('new-tab', 'new-tab', [CompletionResultType]::ParameterValue, 'Create a new tab, optionally with a specified tab layout and name')
            [CompletionResult]::new('move-tab', 'move-tab', [CompletionResultType]::ParameterValue, 'Move the focused tab in the specified direction. [right|left]')
            [CompletionResult]::new('previous-swap-layout', 'previous-swap-layout', [CompletionResultType]::ParameterValue, 'previous-swap-layout')
            [CompletionResult]::new('next-swap-layout', 'next-swap-layout', [CompletionResultType]::ParameterValue, 'next-swap-layout')
            [CompletionResult]::new('override-layout', 'override-layout', [CompletionResultType]::ParameterValue, 'Override the layout of the active tab')
            [CompletionResult]::new('query-tab-names', 'query-tab-names', [CompletionResultType]::ParameterValue, 'Query all tab names')
            [CompletionResult]::new('start-or-reload-plugin', 'start-or-reload-plugin', [CompletionResultType]::ParameterValue, 'start-or-reload-plugin')
            [CompletionResult]::new('launch-or-focus-plugin', 'launch-or-focus-plugin', [CompletionResultType]::ParameterValue, 'Returns: Plugin pane ID (format: plugin_<id>) when creating or focusing plugin')
            [CompletionResult]::new('launch-plugin', 'launch-plugin', [CompletionResultType]::ParameterValue, 'Returns: Plugin pane ID (format: plugin_<id>)')
            [CompletionResult]::new('rename-session', 'rename-session', [CompletionResultType]::ParameterValue, 'rename-session')
            [CompletionResult]::new('pipe', 'pipe', [CompletionResultType]::ParameterValue, 'Send data to one or more plugins, launch them if they are not running')
            [CompletionResult]::new('list-clients', 'list-clients', [CompletionResultType]::ParameterValue, 'list-clients')
            [CompletionResult]::new('list-panes', 'list-panes', [CompletionResultType]::ParameterValue, 'List all panes in the current session')
            [CompletionResult]::new('list-tabs', 'list-tabs', [CompletionResultType]::ParameterValue, 'List all tabs with their information')
            [CompletionResult]::new('current-tab-info', 'current-tab-info', [CompletionResultType]::ParameterValue, 'Get information about the currently active tab')
            [CompletionResult]::new('toggle-pane-pinned', 'toggle-pane-pinned', [CompletionResultType]::ParameterValue, 'toggle-pane-pinned')
            [CompletionResult]::new('stack-panes', 'stack-panes', [CompletionResultType]::ParameterValue, 'Stack pane ids Ids are a space separated list of pane ids. They should either be in the form of `terminal_<int>` (eg. terminal_1), `plugin_<int>` (eg. plugin_1) or bare integers in which case they''ll be considered terminals (eg. 1 is the equivalent of terminal_1)')
            [CompletionResult]::new('change-floating-pane-coordinates', 'change-floating-pane-coordinates', [CompletionResultType]::ParameterValue, 'change-floating-pane-coordinates')
            [CompletionResult]::new('toggle-pane-borderless', 'toggle-pane-borderless', [CompletionResultType]::ParameterValue, 'toggle-pane-borderless')
            [CompletionResult]::new('set-pane-borderless', 'set-pane-borderless', [CompletionResultType]::ParameterValue, 'set-pane-borderless')
            [CompletionResult]::new('detach', 'detach', [CompletionResultType]::ParameterValue, 'Detach from the current session')
            [CompletionResult]::new('switch-session', 'switch-session', [CompletionResultType]::ParameterValue, 'Switch to a different session')
            [CompletionResult]::new('set-pane-color', 'set-pane-color', [CompletionResultType]::ParameterValue, 'Set the default foreground/background color of a pane')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'zellij;action;write' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;write-chars' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;paste' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;send-keys' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;resize' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;focus-next-pane' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;focus-previous-pane' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;move-focus' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;move-focus-or-tab' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;move-pane' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;move-pane-backwards' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;clear' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;dump-screen' {
            [CompletionResult]::new('--path', 'path', [CompletionResultType]::ParameterName, 'File path to dump the pane content to. If omitted, prints to STDOUT')
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3). If not specified, dumps the focused pane')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3). If not specified, dumps the focused pane')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'Dump the pane with full scrollback')
            [CompletionResult]::new('--full', 'full', [CompletionResultType]::ParameterName, 'Dump the pane with full scrollback')
            [CompletionResult]::new('-a', 'a', [CompletionResultType]::ParameterName, 'Preserve ANSI styling in the dump output')
            [CompletionResult]::new('--ansi', 'ansi', [CompletionResultType]::ParameterName, 'Preserve ANSI styling in the dump output')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;dump-layout' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;save-session' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;edit-scrollback' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-a', 'a', [CompletionResultType]::ParameterName, 'Preserve ANSI styling in the scrollback dump')
            [CompletionResult]::new('--ansi', 'ansi', [CompletionResultType]::ParameterName, 'Preserve ANSI styling in the scrollback dump')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;scroll-up' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;scroll-down' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;scroll-to-bottom' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;scroll-to-top' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;page-scroll-up' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;page-scroll-down' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;half-page-scroll-up' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;half-page-scroll-down' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;toggle-fullscreen' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;toggle-pane-frames' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;toggle-active-sync-tab' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('--tab-id', 'tab-id', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;new-pane' {
            [CompletionResult]::new('-d', 'd', [CompletionResultType]::ParameterName, 'Direction to open the new pane in')
            [CompletionResult]::new('--direction', 'direction', [CompletionResultType]::ParameterName, 'Direction to open the new pane in')
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'p')
            [CompletionResult]::new('--plugin', 'plugin', [CompletionResultType]::ParameterName, 'plugin')
            [CompletionResult]::new('--cwd', 'cwd', [CompletionResultType]::ParameterName, 'Change the working directory of the new pane')
            [CompletionResult]::new('-n', 'n', [CompletionResultType]::ParameterName, 'Name of the new pane')
            [CompletionResult]::new('--name', 'name', [CompletionResultType]::ParameterName, 'Name of the new pane')
            [CompletionResult]::new('--configuration', 'configuration', [CompletionResultType]::ParameterName, 'configuration')
            [CompletionResult]::new('-x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('-y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--width', 'width', [CompletionResultType]::ParameterName, 'The width if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--height', 'height', [CompletionResultType]::ParameterName, 'The height if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--pinned', 'pinned', [CompletionResultType]::ParameterName, 'Whether to pin a floating pane so that it is always on top')
            [CompletionResult]::new('--borderless', 'borderless', [CompletionResultType]::ParameterName, 'start this pane without a border (warning: will make it impossible to move with the mouse)')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'Open the new pane in floating mode')
            [CompletionResult]::new('--floating', 'floating', [CompletionResultType]::ParameterName, 'Open the new pane in floating mode')
            [CompletionResult]::new('-i', 'i', [CompletionResultType]::ParameterName, 'Open the new pane in place of the current pane, temporarily suspending it')
            [CompletionResult]::new('--in-place', 'in-place', [CompletionResultType]::ParameterName, 'Open the new pane in place of the current pane, temporarily suspending it')
            [CompletionResult]::new('--close-replaced-pane', 'close-replaced-pane', [CompletionResultType]::ParameterName, 'Close the replaced pane instead of suspending it (only effective with --in-place)')
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Close the pane immediately when its command exits')
            [CompletionResult]::new('--close-on-exit', 'close-on-exit', [CompletionResultType]::ParameterName, 'Close the pane immediately when its command exits')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 'Start the command suspended, only running it after the you first press ENTER')
            [CompletionResult]::new('--start-suspended', 'start-suspended', [CompletionResultType]::ParameterName, 'Start the command suspended, only running it after the you first press ENTER')
            [CompletionResult]::new('--skip-plugin-cache', 'skip-plugin-cache', [CompletionResultType]::ParameterName, 'skip-plugin-cache')
            [CompletionResult]::new('--stacked', 'stacked', [CompletionResultType]::ParameterName, 'stacked')
            [CompletionResult]::new('-b', 'b', [CompletionResultType]::ParameterName, 'Block until the command has finished and its pane has been closed')
            [CompletionResult]::new('--blocking', 'blocking', [CompletionResultType]::ParameterName, 'Block until the command has finished and its pane has been closed')
            [CompletionResult]::new('--block-until-exit-success', 'block-until-exit-success', [CompletionResultType]::ParameterName, 'Block until the command exits successfully (exit status 0) OR its pane has been closed')
            [CompletionResult]::new('--block-until-exit-failure', 'block-until-exit-failure', [CompletionResultType]::ParameterName, 'Block until the command exits with failure (non-zero exit status) OR its pane has been closed')
            [CompletionResult]::new('--block-until-exit', 'block-until-exit', [CompletionResultType]::ParameterName, 'Block until the command exits (regardless of exit status) OR its pane has been closed')
            [CompletionResult]::new('--near-current-pane', 'near-current-pane', [CompletionResultType]::ParameterName, 'if set, will open the pane near the current one rather than following the user''s focus')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;edit' {
            [CompletionResult]::new('-d', 'd', [CompletionResultType]::ParameterName, 'Direction to open the new pane in')
            [CompletionResult]::new('--direction', 'direction', [CompletionResultType]::ParameterName, 'Direction to open the new pane in')
            [CompletionResult]::new('-l', 'l', [CompletionResultType]::ParameterName, 'Open the file in the specified line number')
            [CompletionResult]::new('--line-number', 'line-number', [CompletionResultType]::ParameterName, 'Open the file in the specified line number')
            [CompletionResult]::new('--cwd', 'cwd', [CompletionResultType]::ParameterName, 'Change the working directory of the editor')
            [CompletionResult]::new('-x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('-y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--width', 'width', [CompletionResultType]::ParameterName, 'The width if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--height', 'height', [CompletionResultType]::ParameterName, 'The height if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--pinned', 'pinned', [CompletionResultType]::ParameterName, 'Whether to pin a floating pane so that it is always on top')
            [CompletionResult]::new('-b', 'b', [CompletionResultType]::ParameterName, 'start this pane without a border (warning: will make it impossible to move with the mouse)')
            [CompletionResult]::new('--borderless', 'borderless', [CompletionResultType]::ParameterName, 'start this pane without a border (warning: will make it impossible to move with the mouse)')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'Open the new pane in floating mode')
            [CompletionResult]::new('--floating', 'floating', [CompletionResultType]::ParameterName, 'Open the new pane in floating mode')
            [CompletionResult]::new('-i', 'i', [CompletionResultType]::ParameterName, 'Open the new pane in place of the current pane, temporarily suspending it')
            [CompletionResult]::new('--in-place', 'in-place', [CompletionResultType]::ParameterName, 'Open the new pane in place of the current pane, temporarily suspending it')
            [CompletionResult]::new('--close-replaced-pane', 'close-replaced-pane', [CompletionResultType]::ParameterName, 'Close the replaced pane instead of suspending it (only effective with --in-place)')
            [CompletionResult]::new('--near-current-pane', 'near-current-pane', [CompletionResultType]::ParameterName, 'if set, will open the pane near the current one rather than following the user''s focus')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;switch-mode' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;toggle-pane-embed-or-floating' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;toggle-floating-panes' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('--tab-id', 'tab-id', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;show-floating-panes' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 't')
            [CompletionResult]::new('--tab-id', 'tab-id', [CompletionResultType]::ParameterName, 'tab-id')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;hide-floating-panes' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 't')
            [CompletionResult]::new('--tab-id', 'tab-id', [CompletionResultType]::ParameterName, 'tab-id')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;close-pane' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;rename-pane' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;undo-rename-pane' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;go-to-next-tab' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;go-to-previous-tab' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;close-tab' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('--tab-id', 'tab-id', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;go-to-tab' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;go-to-tab-name' {
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Create a tab if one does not exist')
            [CompletionResult]::new('--create', 'create', [CompletionResultType]::ParameterName, 'Create a tab if one does not exist')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;rename-tab' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('--tab-id', 'tab-id', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;undo-rename-tab' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('--tab-id', 'tab-id', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;go-to-tab-by-id' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;close-tab-by-id' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;rename-tab-by-id' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;new-tab' {
            [CompletionResult]::new('-l', 'l', [CompletionResultType]::ParameterName, 'Layout to use for the new tab')
            [CompletionResult]::new('--layout', 'layout', [CompletionResultType]::ParameterName, 'Layout to use for the new tab')
            [CompletionResult]::new('--layout-dir', 'layout-dir', [CompletionResultType]::ParameterName, 'Default folder to look for layouts')
            [CompletionResult]::new('-n', 'n', [CompletionResultType]::ParameterName, 'Name of the new tab')
            [CompletionResult]::new('--name', 'name', [CompletionResultType]::ParameterName, 'Name of the new tab')
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Change the working directory of the new tab')
            [CompletionResult]::new('--cwd', 'cwd', [CompletionResultType]::ParameterName, 'Change the working directory of the new tab')
            [CompletionResult]::new('--initial-plugin', 'initial-plugin', [CompletionResultType]::ParameterName, 'Initial plugin to load in the new tab')
            [CompletionResult]::new('--close-on-exit', 'close-on-exit', [CompletionResultType]::ParameterName, 'Close the pane immediately when its command exits')
            [CompletionResult]::new('--start-suspended', 'start-suspended', [CompletionResultType]::ParameterName, 'Start the command suspended, only running it after you first press ENTER')
            [CompletionResult]::new('--block-until-exit-success', 'block-until-exit-success', [CompletionResultType]::ParameterName, 'Block until the command exits successfully (exit status 0) OR its pane has been closed')
            [CompletionResult]::new('--block-until-exit-failure', 'block-until-exit-failure', [CompletionResultType]::ParameterName, 'Block until the command exits with failure (non-zero exit status) OR its pane has been closed')
            [CompletionResult]::new('--block-until-exit', 'block-until-exit', [CompletionResultType]::ParameterName, 'Block until the command exits (regardless of exit status) OR its pane has been closed')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;move-tab' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('--tab-id', 'tab-id', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;previous-swap-layout' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('--tab-id', 'tab-id', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;next-swap-layout' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('--tab-id', 'tab-id', [CompletionResultType]::ParameterName, 'Target a specific tab by ID')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;override-layout' {
            [CompletionResult]::new('--layout-dir', 'layout-dir', [CompletionResultType]::ParameterName, 'Default folder to look for layouts')
            [CompletionResult]::new('--retain-existing-terminal-panes', 'retain-existing-terminal-panes', [CompletionResultType]::ParameterName, 'Retain existing terminal panes that do not fit in the layout (default: false)')
            [CompletionResult]::new('--retain-existing-plugin-panes', 'retain-existing-plugin-panes', [CompletionResultType]::ParameterName, 'Retain existing plugin panes that do not fit with the layout default: false)')
            [CompletionResult]::new('--apply-only-to-active-tab', 'apply-only-to-active-tab', [CompletionResultType]::ParameterName, 'Only apply the layout to the active tab (uses just the first layout tab if it has multiple)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;query-tab-names' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;start-or-reload-plugin' {
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'c')
            [CompletionResult]::new('--configuration', 'configuration', [CompletionResultType]::ParameterName, 'configuration')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;launch-or-focus-plugin' {
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'c')
            [CompletionResult]::new('--configuration', 'configuration', [CompletionResultType]::ParameterName, 'configuration')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'f')
            [CompletionResult]::new('--floating', 'floating', [CompletionResultType]::ParameterName, 'floating')
            [CompletionResult]::new('-i', 'i', [CompletionResultType]::ParameterName, 'i')
            [CompletionResult]::new('--in-place', 'in-place', [CompletionResultType]::ParameterName, 'in-place')
            [CompletionResult]::new('--close-replaced-pane', 'close-replaced-pane', [CompletionResultType]::ParameterName, 'Close the replaced pane instead of suspending it (only effective with --in-place)')
            [CompletionResult]::new('-m', 'm', [CompletionResultType]::ParameterName, 'm')
            [CompletionResult]::new('--move-to-focused-tab', 'move-to-focused-tab', [CompletionResultType]::ParameterName, 'move-to-focused-tab')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 's')
            [CompletionResult]::new('--skip-plugin-cache', 'skip-plugin-cache', [CompletionResultType]::ParameterName, 'skip-plugin-cache')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;launch-plugin' {
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'c')
            [CompletionResult]::new('--configuration', 'configuration', [CompletionResultType]::ParameterName, 'configuration')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'f')
            [CompletionResult]::new('--floating', 'floating', [CompletionResultType]::ParameterName, 'floating')
            [CompletionResult]::new('-i', 'i', [CompletionResultType]::ParameterName, 'i')
            [CompletionResult]::new('--in-place', 'in-place', [CompletionResultType]::ParameterName, 'in-place')
            [CompletionResult]::new('--close-replaced-pane', 'close-replaced-pane', [CompletionResultType]::ParameterName, 'Close the replaced pane instead of suspending it (only effective with --in-place)')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 's')
            [CompletionResult]::new('--skip-plugin-cache', 'skip-plugin-cache', [CompletionResultType]::ParameterName, 'skip-plugin-cache')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;rename-session' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;pipe' {
            [CompletionResult]::new('-n', 'n', [CompletionResultType]::ParameterName, 'The name of the pipe')
            [CompletionResult]::new('--name', 'name', [CompletionResultType]::ParameterName, 'The name of the pipe')
            [CompletionResult]::new('-a', 'a', [CompletionResultType]::ParameterName, 'The args of the pipe')
            [CompletionResult]::new('--args', 'args', [CompletionResultType]::ParameterName, 'The args of the pipe')
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The plugin url (eg. file:/tmp/my-plugin.wasm) to direct this pipe to, if not specified, will be sent to all plugins, if specified and is not running, the plugin will be launched')
            [CompletionResult]::new('--plugin', 'plugin', [CompletionResultType]::ParameterName, 'The plugin url (eg. file:/tmp/my-plugin.wasm) to direct this pipe to, if not specified, will be sent to all plugins, if specified and is not running, the plugin will be launched')
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'The plugin configuration (note: the same plugin with different configuration is considered a different plugin for the purposes of determining the pipe destination)')
            [CompletionResult]::new('--plugin-configuration', 'plugin-configuration', [CompletionResultType]::ParameterName, 'The plugin configuration (note: the same plugin with different configuration is considered a different plugin for the purposes of determining the pipe destination)')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'If launching a plugin, should it be floating or not, defaults to floating')
            [CompletionResult]::new('--floating-plugin', 'floating-plugin', [CompletionResultType]::ParameterName, 'If launching a plugin, should it be floating or not, defaults to floating')
            [CompletionResult]::new('-i', 'i', [CompletionResultType]::ParameterName, 'If launching a plugin, launch it in-place (on top of the current pane)')
            [CompletionResult]::new('--in-place-plugin', 'in-place-plugin', [CompletionResultType]::ParameterName, 'If launching a plugin, launch it in-place (on top of the current pane)')
            [CompletionResult]::new('-w', 'w', [CompletionResultType]::ParameterName, 'If launching a plugin, specify its working directory')
            [CompletionResult]::new('--plugin-cwd', 'plugin-cwd', [CompletionResultType]::ParameterName, 'If launching a plugin, specify its working directory')
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'If launching a plugin, specify its pane title')
            [CompletionResult]::new('--plugin-title', 'plugin-title', [CompletionResultType]::ParameterName, 'If launching a plugin, specify its pane title')
            [CompletionResult]::new('-l', 'l', [CompletionResultType]::ParameterName, 'Launch a new plugin even if one is already running')
            [CompletionResult]::new('--force-launch-plugin', 'force-launch-plugin', [CompletionResultType]::ParameterName, 'Launch a new plugin even if one is already running')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 'If launching a new plugin, skip cache and force-compile the plugin')
            [CompletionResult]::new('--skip-plugin-cache', 'skip-plugin-cache', [CompletionResultType]::ParameterName, 'If launching a new plugin, skip cache and force-compile the plugin')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;list-clients' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;list-panes' {
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Include tab information (name, position, ID)')
            [CompletionResult]::new('--tab', 'tab', [CompletionResultType]::ParameterName, 'Include tab information (name, position, ID)')
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Include running command information')
            [CompletionResult]::new('--command', 'command', [CompletionResultType]::ParameterName, 'Include running command information')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 'Include pane state (focused, floating, exited, etc.)')
            [CompletionResult]::new('--state', 'state', [CompletionResultType]::ParameterName, 'Include pane state (focused, floating, exited, etc.)')
            [CompletionResult]::new('-g', 'g', [CompletionResultType]::ParameterName, 'Include geometry (position, size)')
            [CompletionResult]::new('--geometry', 'geometry', [CompletionResultType]::ParameterName, 'Include geometry (position, size)')
            [CompletionResult]::new('-a', 'a', [CompletionResultType]::ParameterName, 'Include all available fields')
            [CompletionResult]::new('--all', 'all', [CompletionResultType]::ParameterName, 'Include all available fields')
            [CompletionResult]::new('-j', 'j', [CompletionResultType]::ParameterName, 'Output as JSON')
            [CompletionResult]::new('--json', 'json', [CompletionResultType]::ParameterName, 'Output as JSON')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;list-tabs' {
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 'Include state information (active, fullscreen, sync, floating visibility)')
            [CompletionResult]::new('--state', 'state', [CompletionResultType]::ParameterName, 'Include state information (active, fullscreen, sync, floating visibility)')
            [CompletionResult]::new('-d', 'd', [CompletionResultType]::ParameterName, 'Include dimension information (viewport, display area)')
            [CompletionResult]::new('--dimensions', 'dimensions', [CompletionResultType]::ParameterName, 'Include dimension information (viewport, display area)')
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Include pane counts')
            [CompletionResult]::new('--panes', 'panes', [CompletionResultType]::ParameterName, 'Include pane counts')
            [CompletionResult]::new('-l', 'l', [CompletionResultType]::ParameterName, 'Include layout information (swap layout name and dirty state)')
            [CompletionResult]::new('--layout', 'layout', [CompletionResultType]::ParameterName, 'Include layout information (swap layout name and dirty state)')
            [CompletionResult]::new('-a', 'a', [CompletionResultType]::ParameterName, 'Include all available fields')
            [CompletionResult]::new('--all', 'all', [CompletionResultType]::ParameterName, 'Include all available fields')
            [CompletionResult]::new('-j', 'j', [CompletionResultType]::ParameterName, 'Output as JSON')
            [CompletionResult]::new('--json', 'json', [CompletionResultType]::ParameterName, 'Output as JSON')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;current-tab-info' {
            [CompletionResult]::new('-j', 'j', [CompletionResultType]::ParameterName, 'Output as JSON with full TabInfo')
            [CompletionResult]::new('--json', 'json', [CompletionResultType]::ParameterName, 'Output as JSON with full TabInfo')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;toggle-pane-pinned' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Target a specific pane by ID (eg. terminal_1, plugin_2, or 3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;stack-panes' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;change-floating-pane-coordinates' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The pane_id of the floating pane, eg.  terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'The pane_id of the floating pane, eg.  terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('-x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('-y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--width', 'width', [CompletionResultType]::ParameterName, 'The width if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--height', 'height', [CompletionResultType]::ParameterName, 'The height if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--pinned', 'pinned', [CompletionResultType]::ParameterName, 'Whether to pin a floating pane so that it is always on top')
            [CompletionResult]::new('-b', 'b', [CompletionResultType]::ParameterName, 'change this pane to be with/without a border (warning: will make it impossible to move with the mouse if without a border)')
            [CompletionResult]::new('--borderless', 'borderless', [CompletionResultType]::ParameterName, 'change this pane to be with/without a border (warning: will make it impossible to move with the mouse if without a border)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;toggle-pane-borderless' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;set-pane-borderless' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3)')
            [CompletionResult]::new('-b', 'b', [CompletionResultType]::ParameterName, 'Whether the pane should be borderless (flag present) or bordered (flag absent)')
            [CompletionResult]::new('--borderless', 'borderless', [CompletionResultType]::ParameterName, 'Whether the pane should be borderless (flag present) or bordered (flag absent)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;detach' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;switch-session' {
            [CompletionResult]::new('--tab-position', 'tab-position', [CompletionResultType]::ParameterName, 'Optional tab position to focus')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Optional pane ID to focus (eg. "terminal_1" for terminal pane with id 1, or "plugin_2" for plugin pane with id 2)')
            [CompletionResult]::new('-l', 'l', [CompletionResultType]::ParameterName, 'Layout to apply when switching to the session (relative paths start at layout-dir)')
            [CompletionResult]::new('--layout', 'layout', [CompletionResultType]::ParameterName, 'Layout to apply when switching to the session (relative paths start at layout-dir)')
            [CompletionResult]::new('--layout-dir', 'layout-dir', [CompletionResultType]::ParameterName, 'Default folder to look for layouts')
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Change the working directory when switching')
            [CompletionResult]::new('--cwd', 'cwd', [CompletionResultType]::ParameterName, 'Change the working directory when switching')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;set-pane-color' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3). Defaults to $ZELLIJ_PANE_ID if not provided')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'The pane_id of the pane, eg. terminal_1, plugin_2 or 3 (equivalent to terminal_3). Defaults to $ZELLIJ_PANE_ID if not provided')
            [CompletionResult]::new('--fg', 'fg', [CompletionResultType]::ParameterName, 'Foreground color (e.g. "#00e000", "rgb:00/e0/00")')
            [CompletionResult]::new('--bg', 'bg', [CompletionResultType]::ParameterName, 'Background color (e.g. "#001a3a", "rgb:00/1a/3a")')
            [CompletionResult]::new('--reset', 'reset', [CompletionResultType]::ParameterName, 'Reset pane colors to terminal defaults')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;action;help' {
            break
        }
        'zellij;list-sessions' {
            [CompletionResult]::new('-n', 'n', [CompletionResultType]::ParameterName, 'Do not add colors and formatting to the list (useful for parsing)')
            [CompletionResult]::new('--no-formatting', 'no-formatting', [CompletionResultType]::ParameterName, 'Do not add colors and formatting to the list (useful for parsing)')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 'Print just the session name')
            [CompletionResult]::new('--short', 'short', [CompletionResultType]::ParameterName, 'Print just the session name')
            [CompletionResult]::new('-r', 'r', [CompletionResultType]::ParameterName, 'List the sessions in reverse order (default is ascending order)')
            [CompletionResult]::new('--reverse', 'reverse', [CompletionResultType]::ParameterName, 'List the sessions in reverse order (default is ascending order)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;list-aliases' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;attach' {
            [CompletionResult]::new('--index', 'index', [CompletionResultType]::ParameterName, 'Number of the session index in the active sessions ordered creation date')
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Authentication token for remote sessions')
            [CompletionResult]::new('--token', 'token', [CompletionResultType]::ParameterName, 'Authentication token for remote sessions')
            [CompletionResult]::new('--ca-cert', 'ca-cert', [CompletionResultType]::ParameterName, 'Path to a custom CA certificate (PEM format) for verifying the remote server')
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Create a session if one does not exist')
            [CompletionResult]::new('--create', 'create', [CompletionResultType]::ParameterName, 'Create a session if one does not exist')
            [CompletionResult]::new('-b', 'b', [CompletionResultType]::ParameterName, 'Create a detached session in the background if one does not exist')
            [CompletionResult]::new('--create-background', 'create-background', [CompletionResultType]::ParameterName, 'Create a detached session in the background if one does not exist')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'If resurrecting a dead session, immediately run all its commands on startup')
            [CompletionResult]::new('--force-run-commands', 'force-run-commands', [CompletionResultType]::ParameterName, 'If resurrecting a dead session, immediately run all its commands on startup')
            [CompletionResult]::new('-r', 'r', [CompletionResultType]::ParameterName, 'Save session for automatic re-authentication (4 weeks)')
            [CompletionResult]::new('--remember', 'remember', [CompletionResultType]::ParameterName, 'Save session for automatic re-authentication (4 weeks)')
            [CompletionResult]::new('--forget', 'forget', [CompletionResultType]::ParameterName, 'Delete saved session before connecting')
            [CompletionResult]::new('--insecure', 'insecure', [CompletionResultType]::ParameterName, 'Skip TLS certificate validation (DANGEROUS — development only)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('options', 'options', [CompletionResultType]::ParameterValue, 'Change the behaviour of zellij')
            [CompletionResult]::new('help', 'help', [CompletionResultType]::ParameterValue, 'Print this message or the help of the given subcommand(s)')
            break
        }
        'zellij;attach;options' {
            [CompletionResult]::new('--simplified-ui', 'simplified-ui', [CompletionResultType]::ParameterName, 'Allow plugins to use a more simplified layout that is compatible with more fonts (true or false)')
            [CompletionResult]::new('--theme', 'theme', [CompletionResultType]::ParameterName, 'Set the default theme')
            [CompletionResult]::new('--default-mode', 'default-mode', [CompletionResultType]::ParameterName, 'Set the default mode')
            [CompletionResult]::new('--default-shell', 'default-shell', [CompletionResultType]::ParameterName, 'Set the default shell')
            [CompletionResult]::new('--default-cwd', 'default-cwd', [CompletionResultType]::ParameterName, 'Set the default cwd')
            [CompletionResult]::new('--default-layout', 'default-layout', [CompletionResultType]::ParameterName, 'Set the default layout')
            [CompletionResult]::new('--layout-dir', 'layout-dir', [CompletionResultType]::ParameterName, 'Set the layout_dir, defaults to subdirectory of config dir')
            [CompletionResult]::new('--theme-dir', 'theme-dir', [CompletionResultType]::ParameterName, 'Set the theme_dir, defaults to subdirectory of config dir')
            [CompletionResult]::new('--mouse-mode', 'mouse-mode', [CompletionResultType]::ParameterName, 'Set the handling of mouse events (true or false) Can be temporarily bypassed by the [SHIFT] key')
            [CompletionResult]::new('--pane-frames', 'pane-frames', [CompletionResultType]::ParameterName, 'Set display of the pane frames (true or false)')
            [CompletionResult]::new('--mirror-session', 'mirror-session', [CompletionResultType]::ParameterName, 'Mirror session when multiple users are connected (true or false)')
            [CompletionResult]::new('--on-force-close', 'on-force-close', [CompletionResultType]::ParameterName, 'Set behaviour on force close (quit or detach)')
            [CompletionResult]::new('--scroll-buffer-size', 'scroll-buffer-size', [CompletionResultType]::ParameterName, 'scroll-buffer-size')
            [CompletionResult]::new('--copy-command', 'copy-command', [CompletionResultType]::ParameterName, 'Switch to using a user supplied command for clipboard instead of OSC52')
            [CompletionResult]::new('--copy-clipboard', 'copy-clipboard', [CompletionResultType]::ParameterName, 'OSC52 destination clipboard')
            [CompletionResult]::new('--copy-on-select', 'copy-on-select', [CompletionResultType]::ParameterName, 'Automatically copy when selecting text (true or false)')
            [CompletionResult]::new('--osc8-hyperlinks', 'osc8-hyperlinks', [CompletionResultType]::ParameterName, 'Enable OSC8 hyperlink output (true or false)')
            [CompletionResult]::new('--scrollback-editor', 'scrollback-editor', [CompletionResultType]::ParameterName, 'Explicit full path to open the scrollback editor (default is $EDITOR or $VISUAL)')
            [CompletionResult]::new('--session-name', 'session-name', [CompletionResultType]::ParameterName, 'The name of the session to create when starting Zellij')
            [CompletionResult]::new('--attach-to-session', 'attach-to-session', [CompletionResultType]::ParameterName, 'Whether to attach to a session specified in "session-name" if it exists')
            [CompletionResult]::new('--auto-layout', 'auto-layout', [CompletionResultType]::ParameterName, 'Whether to lay out panes in a predefined set of layouts whenever possible')
            [CompletionResult]::new('--session-serialization', 'session-serialization', [CompletionResultType]::ParameterName, 'Whether sessions should be serialized to the HD so that they can be later resurrected, default is true')
            [CompletionResult]::new('--serialize-pane-viewport', 'serialize-pane-viewport', [CompletionResultType]::ParameterName, 'Whether pane viewports are serialized along with the session, default is false')
            [CompletionResult]::new('--scrollback-lines-to-serialize', 'scrollback-lines-to-serialize', [CompletionResultType]::ParameterName, 'Scrollback lines to serialize along with the pane viewport when serializing sessions, 0 defaults to the scrollback size. If this number is higher than the scrollback size, it will also default to the scrollback size')
            [CompletionResult]::new('--styled-underlines', 'styled-underlines', [CompletionResultType]::ParameterName, 'Whether to use ANSI styled underlines')
            [CompletionResult]::new('--serialization-interval', 'serialization-interval', [CompletionResultType]::ParameterName, 'The interval at which to serialize sessions for resurrection (in seconds)')
            [CompletionResult]::new('--disable-session-metadata', 'disable-session-metadata', [CompletionResultType]::ParameterName, 'If true, will disable writing session metadata to disk')
            [CompletionResult]::new('--support-kitty-keyboard-protocol', 'support-kitty-keyboard-protocol', [CompletionResultType]::ParameterName, 'Whether to enable support for the Kitty keyboard protocol (must also be supported by the host terminal), defaults to true if the terminal supports it')
            [CompletionResult]::new('--web-server', 'web-server', [CompletionResultType]::ParameterName, 'Whether to make sure a local web server is running when a new Zellij session starts. This web server will allow creating new sessions and attaching to existing ones that have opted in to being shared in the browser')
            [CompletionResult]::new('--web-sharing', 'web-sharing', [CompletionResultType]::ParameterName, 'Whether to allow new sessions to be shared through a local web server, assuming one is running (see the `web_server` option for more details)')
            [CompletionResult]::new('--stacked-resize', 'stacked-resize', [CompletionResultType]::ParameterName, 'Whether to stack panes when resizing beyond a certain size default is true')
            [CompletionResult]::new('--show-startup-tips', 'show-startup-tips', [CompletionResultType]::ParameterName, 'Whether to show startup tips when starting a new session default is true')
            [CompletionResult]::new('--show-release-notes', 'show-release-notes', [CompletionResultType]::ParameterName, 'Whether to show release notes on first run of a new version default is true')
            [CompletionResult]::new('--advanced-mouse-actions', 'advanced-mouse-actions', [CompletionResultType]::ParameterName, 'Whether to enable mouse hover effects and pane grouping functionality default is true')
            [CompletionResult]::new('--mouse-hover-effects', 'mouse-hover-effects', [CompletionResultType]::ParameterName, 'Whether to enable mouse hover visual effects (frame highlight and help text) default is true')
            [CompletionResult]::new('--visual-bell', 'visual-bell', [CompletionResultType]::ParameterName, 'Whether to show visual bell indicators (pane/tab frame flash and [!] suffix) default is true')
            [CompletionResult]::new('--focus-follows-mouse', 'focus-follows-mouse', [CompletionResultType]::ParameterName, 'Whether to focus panes on mouse hover (true or false) default is false')
            [CompletionResult]::new('--mouse-click-through', 'mouse-click-through', [CompletionResultType]::ParameterName, 'Whether clicking a pane to focus it also sends the click into the pane (true or false) default is false')
            [CompletionResult]::new('--post-command-discovery-hook', 'post-command-discovery-hook', [CompletionResultType]::ParameterName, 'A command to run after the discovery of running commands when serializing, for the purpose of manipulating the command (eg. with a regex) before it gets serialized')
            [CompletionResult]::new('--client-async-worker-tasks', 'client-async-worker-tasks', [CompletionResultType]::ParameterName, 'Number of async worker tasks to spawn per active client')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;attach;help' {
            break
        }
        'zellij;watch' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;kill-session' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;delete-session' {
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'Kill the session if it''s running before deleting it')
            [CompletionResult]::new('--force', 'force', [CompletionResultType]::ParameterName, 'Kill the session if it''s running before deleting it')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;kill-all-sessions' {
            [CompletionResult]::new('-y', 'y', [CompletionResultType]::ParameterName, 'Automatic yes to prompts')
            [CompletionResult]::new('--yes', 'yes', [CompletionResultType]::ParameterName, 'Automatic yes to prompts')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;delete-all-sessions' {
            [CompletionResult]::new('-y', 'y', [CompletionResultType]::ParameterName, 'Automatic yes to prompts')
            [CompletionResult]::new('--yes', 'yes', [CompletionResultType]::ParameterName, 'Automatic yes to prompts')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'Kill the sessions if they''re running before deleting them')
            [CompletionResult]::new('--force', 'force', [CompletionResultType]::ParameterName, 'Kill the sessions if they''re running before deleting them')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;run' {
            [CompletionResult]::new('-d', 'd', [CompletionResultType]::ParameterName, 'Direction to open the new pane in')
            [CompletionResult]::new('--direction', 'direction', [CompletionResultType]::ParameterName, 'Direction to open the new pane in')
            [CompletionResult]::new('--cwd', 'cwd', [CompletionResultType]::ParameterName, 'Change the working directory of the new pane')
            [CompletionResult]::new('-n', 'n', [CompletionResultType]::ParameterName, 'Name of the new pane')
            [CompletionResult]::new('--name', 'name', [CompletionResultType]::ParameterName, 'Name of the new pane')
            [CompletionResult]::new('-x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('-y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--width', 'width', [CompletionResultType]::ParameterName, 'The width if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--height', 'height', [CompletionResultType]::ParameterName, 'The height if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--pinned', 'pinned', [CompletionResultType]::ParameterName, 'Whether to pin a floating pane so that it is always on top')
            [CompletionResult]::new('-b', 'b', [CompletionResultType]::ParameterName, 'start this pane without a border (warning: will make it impossible to move with the mouse)')
            [CompletionResult]::new('--borderless', 'borderless', [CompletionResultType]::ParameterName, 'start this pane without a border (warning: will make it impossible to move with the mouse)')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'Open the new pane in floating mode')
            [CompletionResult]::new('--floating', 'floating', [CompletionResultType]::ParameterName, 'Open the new pane in floating mode')
            [CompletionResult]::new('-i', 'i', [CompletionResultType]::ParameterName, 'Open the new pane in place of the current pane, temporarily suspending it')
            [CompletionResult]::new('--in-place', 'in-place', [CompletionResultType]::ParameterName, 'Open the new pane in place of the current pane, temporarily suspending it')
            [CompletionResult]::new('--close-replaced-pane', 'close-replaced-pane', [CompletionResultType]::ParameterName, 'Close the replaced pane instead of suspending it (only effective with --in-place)')
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Close the pane immediately when its command exits')
            [CompletionResult]::new('--close-on-exit', 'close-on-exit', [CompletionResultType]::ParameterName, 'Close the pane immediately when its command exits')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 'Start the command suspended, only running after you first presses ENTER')
            [CompletionResult]::new('--start-suspended', 'start-suspended', [CompletionResultType]::ParameterName, 'Start the command suspended, only running after you first presses ENTER')
            [CompletionResult]::new('--stacked', 'stacked', [CompletionResultType]::ParameterName, 'stacked')
            [CompletionResult]::new('--blocking', 'blocking', [CompletionResultType]::ParameterName, 'Block until the command has finished and its pane has been closed')
            [CompletionResult]::new('--block-until-exit-success', 'block-until-exit-success', [CompletionResultType]::ParameterName, 'Block until the command exits successfully (exit status 0) OR its pane has been closed')
            [CompletionResult]::new('--block-until-exit-failure', 'block-until-exit-failure', [CompletionResultType]::ParameterName, 'Block until the command exits with failure (non-zero exit status) OR its pane has been closed')
            [CompletionResult]::new('--block-until-exit', 'block-until-exit', [CompletionResultType]::ParameterName, 'Block until the command exits (regardless of exit status) OR its pane has been closed')
            [CompletionResult]::new('--near-current-pane', 'near-current-pane', [CompletionResultType]::ParameterName, 'if set, will open the pane near the current one rather than following the user''s focus')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;plugin' {
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Plugin configuration')
            [CompletionResult]::new('--configuration', 'configuration', [CompletionResultType]::ParameterName, 'Plugin configuration')
            [CompletionResult]::new('-x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('-y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--width', 'width', [CompletionResultType]::ParameterName, 'The width if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--height', 'height', [CompletionResultType]::ParameterName, 'The height if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--pinned', 'pinned', [CompletionResultType]::ParameterName, 'Whether to pin a floating pane so that it is always on top')
            [CompletionResult]::new('-b', 'b', [CompletionResultType]::ParameterName, 'start this pane without a border (warning: will make it impossible to move with the mouse)')
            [CompletionResult]::new('--borderless', 'borderless', [CompletionResultType]::ParameterName, 'start this pane without a border (warning: will make it impossible to move with the mouse)')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'Open the new pane in floating mode')
            [CompletionResult]::new('--floating', 'floating', [CompletionResultType]::ParameterName, 'Open the new pane in floating mode')
            [CompletionResult]::new('-i', 'i', [CompletionResultType]::ParameterName, 'Open the new pane in place of the current pane, temporarily suspending it')
            [CompletionResult]::new('--in-place', 'in-place', [CompletionResultType]::ParameterName, 'Open the new pane in place of the current pane, temporarily suspending it')
            [CompletionResult]::new('--close-replaced-pane', 'close-replaced-pane', [CompletionResultType]::ParameterName, 'Close the replaced pane instead of suspending it (only effective with --in-place)')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 'Skip the memory and HD cache and force recompile of the plugin (good for development)')
            [CompletionResult]::new('--skip-plugin-cache', 'skip-plugin-cache', [CompletionResultType]::ParameterName, 'Skip the memory and HD cache and force recompile of the plugin (good for development)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;edit' {
            [CompletionResult]::new('-l', 'l', [CompletionResultType]::ParameterName, 'Open the file in the specified line number')
            [CompletionResult]::new('--line-number', 'line-number', [CompletionResultType]::ParameterName, 'Open the file in the specified line number')
            [CompletionResult]::new('-d', 'd', [CompletionResultType]::ParameterName, 'Direction to open the new pane in')
            [CompletionResult]::new('--direction', 'direction', [CompletionResultType]::ParameterName, 'Direction to open the new pane in')
            [CompletionResult]::new('--cwd', 'cwd', [CompletionResultType]::ParameterName, 'Change the working directory of the editor')
            [CompletionResult]::new('-x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--x', 'x', [CompletionResultType]::ParameterName, 'The x coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('-y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--y', 'y', [CompletionResultType]::ParameterName, 'The y coordinates if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--width', 'width', [CompletionResultType]::ParameterName, 'The width if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--height', 'height', [CompletionResultType]::ParameterName, 'The height if the pane is floating as a bare integer (eg. 1) or percent (eg. 10%)')
            [CompletionResult]::new('--pinned', 'pinned', [CompletionResultType]::ParameterName, 'Whether to pin a floating pane so that it is always on top')
            [CompletionResult]::new('-b', 'b', [CompletionResultType]::ParameterName, 'start this pane without a border (warning: will make it impossible to move with the mouse)')
            [CompletionResult]::new('--borderless', 'borderless', [CompletionResultType]::ParameterName, 'start this pane without a border (warning: will make it impossible to move with the mouse)')
            [CompletionResult]::new('-i', 'i', [CompletionResultType]::ParameterName, 'Open the new pane in place of the current pane, temporarily suspending it')
            [CompletionResult]::new('--in-place', 'in-place', [CompletionResultType]::ParameterName, 'Open the new pane in place of the current pane, temporarily suspending it')
            [CompletionResult]::new('--close-replaced-pane', 'close-replaced-pane', [CompletionResultType]::ParameterName, 'Close the replaced pane instead of suspending it (only effective with --in-place)')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'Open the new pane in floating mode')
            [CompletionResult]::new('--floating', 'floating', [CompletionResultType]::ParameterName, 'Open the new pane in floating mode')
            [CompletionResult]::new('--near-current-pane', 'near-current-pane', [CompletionResultType]::ParameterName, 'if set, will open the pane near the current one rather than following the user''s focus')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;convert-config' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;convert-layout' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;convert-theme' {
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;pipe' {
            [CompletionResult]::new('-n', 'n', [CompletionResultType]::ParameterName, 'The name of the pipe')
            [CompletionResult]::new('--name', 'name', [CompletionResultType]::ParameterName, 'The name of the pipe')
            [CompletionResult]::new('-a', 'a', [CompletionResultType]::ParameterName, 'The args of the pipe')
            [CompletionResult]::new('--args', 'args', [CompletionResultType]::ParameterName, 'The args of the pipe')
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'The plugin url (eg. file:/tmp/my-plugin.wasm) to direct this pipe to, if not specified, will be sent to all plugins, if specified and is not running, the plugin will be launched')
            [CompletionResult]::new('--plugin', 'plugin', [CompletionResultType]::ParameterName, 'The plugin url (eg. file:/tmp/my-plugin.wasm) to direct this pipe to, if not specified, will be sent to all plugins, if specified and is not running, the plugin will be launched')
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'The plugin configuration (note: the same plugin with different configuration is considered a different plugin for the purposes of determining the pipe destination)')
            [CompletionResult]::new('--plugin-configuration', 'plugin-configuration', [CompletionResultType]::ParameterName, 'The plugin configuration (note: the same plugin with different configuration is considered a different plugin for the purposes of determining the pipe destination)')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;subscribe' {
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Pane ID(s) to subscribe to (e.g. terminal_1, plugin_2, or bare number like 1)')
            [CompletionResult]::new('--pane-id', 'pane-id', [CompletionResultType]::ParameterName, 'Pane ID(s) to subscribe to (e.g. terminal_1, plugin_2, or bare number like 1)')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 'Include scrollback lines in initial delivery. Bare --scrollback = all scrollback, --scrollback N = last N lines')
            [CompletionResult]::new('--scrollback', 'scrollback', [CompletionResultType]::ParameterName, 'Include scrollback lines in initial delivery. Bare --scrollback = all scrollback, --scrollback N = last N lines')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'Output format')
            [CompletionResult]::new('--format', 'format', [CompletionResultType]::ParameterName, 'Output format')
            [CompletionResult]::new('--ansi', 'ansi', [CompletionResultType]::ParameterName, 'Preserve ANSI styling in the output')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help information')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help information')
            break
        }
        'zellij;help' {
            break
        }
    })

    $completions.Where{ $_.CompletionText -like "$wordToComplete*" } |
        Sort-Object -Property ListItemText
}
