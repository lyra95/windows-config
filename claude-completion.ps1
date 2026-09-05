# claude-completion.ps1
# PowerShell argument completer for the Claude Code CLI.
#
# Usage:
#   . .\claude-completion.ps1        # dot-source into the current session
#   # or add the line above to your $PROFILE to load it automatically.
#
# Generated from `claude -h` (Claude Code 2.1.258). Options that accept a fixed
# set of values ("choice" type) offer those values as completions; every option
# and command shows its description as a tooltip.

using namespace System.Management.Automation

# --- Option definitions -----------------------------------------------------
# Each entry: Name, Description, and (optionally) Choices for choice-type options.
$script:ClaudeOptions = @(
    @{ Name = '--add-dir';                             Description = 'Additional directories to allow tool access to' }
    @{ Name = '--agent';                               Description = "Agent for the current session. Overrides the 'agent' setting." }
    @{ Name = '--agents';                              Description = 'JSON object defining custom agents (e.g. ''{"reviewer": {"description": "Reviews code", "prompt": "You are a code reviewer"}}'')' }
    @{ Name = '--allow-dangerously-skip-permissions';  Description = 'Enable bypassing all permission checks as an option, without it being enabled by default. Recommended only for sandboxes with no internet access.' }
    @{ Name = '--allowedTools';                        Description = 'Comma or space-separated list of tool names to allow (e.g. "Bash(git *) Edit")' }
    @{ Name = '--allowed-tools';                       Description = 'Comma or space-separated list of tool names to allow (e.g. "Bash(git *) Edit")' }
    @{ Name = '--append-system-prompt';                Description = 'Append a system prompt to the default system prompt' }
    @{ Name = '--autocompact';                         Description = 'Auto-compact window size (auto, or 100k-1M tokens)' }
    @{ Name = '--ax-screen-reader';                    Description = 'Render screen-reader friendly output (flat text, no decorative borders or animations).' }
    @{ Name = '--bg';                                  Description = 'Start the session in the background and return immediately. Prints the id that `claude attach`, `logs`, `stop` and `rm` take; `claude agents` lists them.' }
    @{ Name = '--background';                          Description = 'Start the session in the background and return immediately. Prints the id that `claude attach`, `logs`, `stop` and `rm` take; `claude agents` lists them.' }
    @{ Name = '--bare';                                Description = 'Minimal mode: skip hooks, LSP, plugin sync, attribution, auto-memory, background prefetches, keychain reads, and CLAUDE.md auto-discovery. Sets CLAUDE_CODE_SIMPLE=1. Anthropic auth is strictly ANTHROPIC_API_KEY or apiKeyHelper via --settings.' }
    @{ Name = '--betas';                               Description = 'Beta headers to include in API requests (API key users only)' }
    @{ Name = '--brief';                               Description = 'Enable SendUserMessage tool for agent-to-user communication' }
    @{ Name = '--chrome';                              Description = 'Enable Claude in Chrome integration' }
    @{ Name = '--cloud';                               Description = 'Create a cloud session with the given description, or attach to an existing one by session ID or claude.ai/code URL' }
    @{ Name = '-c';                                    Description = 'Continue the most recent conversation in the current directory' }
    @{ Name = '--continue';                            Description = 'Continue the most recent conversation in the current directory' }
    @{ Name = '--dangerously-skip-permissions';        Description = 'Bypass all permission checks. Recommended only for sandboxes with no internet access.' }
    @{ Name = '-d';                                    Description = 'Enable debug mode with optional category filtering (e.g., "api,hooks" or "!1p,!file")' }
    @{ Name = '--debug';                               Description = 'Enable debug mode with optional category filtering (e.g., "api,hooks" or "!1p,!file")' }
    @{ Name = '--debug-file';                          Description = 'Write debug logs to a specific file path (implicitly enables debug mode)' }
    @{ Name = '--disable-slash-commands';              Description = 'Disable all skills' }
    @{ Name = '--disallowedTools';                     Description = 'Comma or space-separated list of tool names to deny (e.g. "Bash(git *) Edit")' }
    @{ Name = '--disallowed-tools';                    Description = 'Comma or space-separated list of tool names to deny (e.g. "Bash(git *) Edit")' }
    @{ Name = '--effort';                              Description = 'Effort level for the current session (low, medium, high, xhigh, max)'; Choices = @('low', 'medium', 'high', 'xhigh', 'max') }
    @{ Name = '--environment';                         Description = 'Create a new cloud session that runs on the given self-hosted environment (ccpool_...).' }
    @{ Name = '--exclude-dynamic-system-prompt-sections'; Description = 'Move per-machine sections (cwd, env info, memory paths, git status) from the system prompt into the first user message. Improves cross-user prompt-cache reuse. Only applies with the default system prompt. (default: false)' }
    @{ Name = '--fallback-model';                      Description = 'Enable automatic fallback to specified model(s) when the default model is overloaded or not available. Accepts a comma-separated list to try each in order. (only works with --print)' }
    @{ Name = '--file';                                Description = 'File resources to download at startup. Format: file_id:relative_path (e.g. --file file_abc:doc.txt file_def:img.png)' }
    @{ Name = '--fork-session';                        Description = 'When resuming, create a new session ID instead of reusing the original (use with --resume or --continue)' }
    @{ Name = '--forward-subagent-text';               Description = 'Forward subagent text and thinking blocks as assistant/user messages with parent_tool_use_id set (only works with --print and --output-format=stream-json)' }
    @{ Name = '--from-pr';                             Description = 'Resume a session linked to a PR by PR number/URL, or open interactive picker with optional search term' }
    @{ Name = '-h';                                    Description = 'Display help for command' }
    @{ Name = '--help';                                Description = 'Display help for command' }
    @{ Name = '--ide';                                 Description = 'Automatically connect to IDE on startup if exactly one valid IDE is available' }
    @{ Name = '--include-hook-events';                 Description = 'Include all hook lifecycle events in the output stream (only works with --output-format=stream-json)' }
    @{ Name = '--include-partial-messages';            Description = 'Include partial message chunks as they arrive (only works with --print and --output-format=stream-json)' }
    @{ Name = '--input-format';                        Description = 'Input format (only works with --print): "text" (default), or "stream-json" (realtime streaming input)'; Choices = @('text', 'stream-json') }
    @{ Name = '--json-schema';                         Description = 'JSON Schema for structured output validation.' }
    @{ Name = '--max-budget-usd';                      Description = 'Maximum dollar amount to spend on API calls (only works with --print)' }
    @{ Name = '--mcp-config';                          Description = 'Load MCP servers from JSON files or strings (space-separated)' }
    @{ Name = '--model';                               Description = "Model for the current session. Provide an alias for the latest model (e.g. 'fable', 'opus', or 'sonnet') or a model's full name (e.g. 'claude-fable-5-1')."; Choices = @('default', 'fable', 'opus', 'opusplan', 'sonnet', 'sonnet[1m]', 'haiku', 'claude-fable-5-1', 'claude-opus-5', 'claude-sonnet-5', 'claude-haiku-4-5-20251001') }
    @{ Name = '-n';                                    Description = 'Set a display name for this session (shown in the prompt box, /resume picker, and terminal title)' }
    @{ Name = '--name';                                Description = 'Set a display name for this session (shown in the prompt box, /resume picker, and terminal title)' }
    @{ Name = '--no-chrome';                           Description = 'Disable Claude in Chrome integration' }
    @{ Name = '--no-session-persistence';              Description = 'Disable session persistence - sessions will not be saved to disk and cannot be resumed (only works with --print)' }
    @{ Name = '--output-format';                       Description = 'Output format (only works with --print): "text" (default), "json" (single result), or "stream-json" (realtime streaming)'; Choices = @('text', 'json', 'stream-json') }
    @{ Name = '--permission-mode';                     Description = 'Permission mode to use for the session'; Choices = @('acceptEdits', 'auto', 'bypassPermissions', 'manual', 'dontAsk', 'plan') }
    @{ Name = '--plugin-dir';                          Description = 'Load a plugin from a directory or .zip for this session only (repeatable) (default: [])' }
    @{ Name = '--plugin-url';                          Description = 'Fetch a plugin .zip from a URL for this session only (repeatable) (default: [])' }
    @{ Name = '-p';                                    Description = 'Print response and exit (useful for pipes). The workspace trust dialog is skipped in non-interactive mode - only use this in directories you trust.' }
    @{ Name = '--print';                               Description = 'Print response and exit (useful for pipes). The workspace trust dialog is skipped in non-interactive mode - only use this in directories you trust.' }
    @{ Name = '--prompt-suggestions';                  Description = 'Enable prompt suggestions. In print/SDK mode, emits a prompt_suggestion message after each turn with a predicted next user prompt'; Choices = @('true', 'false', '1', '0', 'yes', 'no', 'on', 'off') }
    @{ Name = '--remote-control';                      Description = 'Start an interactive session with Remote Control enabled (optionally named)' }
    @{ Name = '--remote-control-session-name-prefix';  Description = 'Prefix for auto-generated Remote Control session names (default: hostname)' }
    @{ Name = '--replay-user-messages';                Description = 'Re-emit user messages from stdin back on stdout for acknowledgment (only works with --input-format=stream-json and --output-format=stream-json)' }
    @{ Name = '--restricted';                          Description = 'Restricted mode: removes the built-in command/code-running tools and WebFetch unless --tools names them, ignores user/project/local settings files, confines the file tools to the working directories, and refuses bypassPermissions.' }
    @{ Name = '-r';                                    Description = 'Resume a conversation by session ID, or open interactive picker with optional search term' }
    @{ Name = '--resume';                              Description = 'Resume a conversation by session ID, or open interactive picker with optional search term' }
    @{ Name = '--safe-mode';                           Description = 'Start with all customizations (CLAUDE.md, skills, plugins, hooks, MCP servers, custom commands and agents, output styles, workflows, custom themes, keybindings, and more) disabled - useful for troubleshooting a broken configuration. Sets CLAUDE_CODE_SAFE_MODE=1.' }
    @{ Name = '--session-id';                          Description = 'Use a specific session ID for the conversation (must be a valid UUID)' }
    @{ Name = '--setting-sources';                     Description = 'Comma-separated list of setting sources to load (user, project, local).' }
    @{ Name = '--settings';                            Description = 'Path to a settings JSON file or a JSON string to load additional settings from' }
    @{ Name = '--strict-mcp-config';                   Description = 'Only use MCP servers from --mcp-config, ignoring all other MCP configurations' }
    @{ Name = '--system-prompt';                       Description = 'System prompt to use for the session' }
    @{ Name = '--system-prompt-snapshot';              Description = 'Record the system prompt once per conversation and reuse it verbatim on every request and resume (recommended: on)'; Choices = @('on', 'off') }
    @{ Name = '--teleport';                            Description = 'Resume a teleport session, optionally specify session ID' }
    @{ Name = '--tmux';                                Description = 'Create a tmux session for the worktree (requires --worktree). Uses iTerm2 native panes when available; use --tmux=classic for traditional tmux.' }
    @{ Name = '--tools';                               Description = 'Specify the list of available tools from the built-in set. Use "" to disable all tools, "default" to use all tools, or specify tool names (e.g. "Bash,Edit,Read").' }
    @{ Name = '--verbose';                             Description = 'Override verbose mode setting from config' }
    @{ Name = '-v';                                    Description = 'Output the version number' }
    @{ Name = '--version';                             Description = 'Output the version number' }
    @{ Name = '-w';                                    Description = 'Create a new git worktree for this session (optionally specify a name)' }
    @{ Name = '--worktree';                            Description = 'Create a new git worktree for this session (optionally specify a name)' }
)

# --- Subcommand definitions -------------------------------------------------
$script:ClaudeCommands = @(
    @{ Name = 'agents';       Description = 'Manage background agents' }
    @{ Name = 'attach';       Description = 'Open a background session in this terminal. <id> is the short id that `claude --bg` prints and `claude agents` lists' }
    @{ Name = 'auth';         Description = 'Manage authentication' }
    @{ Name = 'auto-mode';    Description = 'Inspect or reset auto mode classifier configuration' }
    @{ Name = 'doctor';       Description = 'Check the health of your Claude Code installation. For a full checkup that can also fix issues, run /doctor in a session.' }
    @{ Name = 'gateway';      Description = 'Run the enterprise auth/telemetry gateway' }
    @{ Name = 'import';       Description = 'Import config from another AI coding agent into Claude Code' }
    @{ Name = 'install';      Description = 'Install Claude Code native build. Use [target] to specify version (stable, latest, or specific version)' }
    @{ Name = 'logs';         Description = "Print a background session's recent terminal output" }
    @{ Name = 'mcp';          Description = 'Configure and manage MCP servers' }
    @{ Name = 'plugin';       Description = 'Manage Claude Code plugins' }
    @{ Name = 'plugins';      Description = 'Manage Claude Code plugins' }
    @{ Name = 'project';      Description = 'Manage Claude Code project state' }
    @{ Name = 'respawn';      Description = 'Restart a background session, or all of them with --all, so it runs the current Claude Code version' }
    @{ Name = 'rm';           Description = 'Delete a background session, and its worktree when that is safe. Works on sessions that have already exited' }
    @{ Name = 'setup-token';  Description = 'Set up a long-lived authentication token (requires Claude subscription)' }
    @{ Name = 'stop';         Description = 'Stop a background session. Its conversation is kept: `claude attach <id>` opens it again' }
    @{ Name = 'kill';         Description = 'Stop a background session. Its conversation is kept: `claude attach <id>` opens it again' }
    @{ Name = 'ultrareview';  Description = 'Run a cloud-hosted multi-agent code review of the current branch (or a PR number / base branch) and print the findings' }
    @{ Name = 'update';       Description = 'Check for updates and install if available' }
    @{ Name = 'upgrade';      Description = 'Check for updates and install if available' }
)

# --- Completer --------------------------------------------------------------
Register-ArgumentCompleter -Native -CommandName 'claude' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    # Collapse leading '=' so `--effort=` style completions work too.
    $word = $wordToComplete

    # Find the token immediately preceding the word being completed.
    $elements = $commandAst.CommandElements
    $prevToken = $null
    if ($elements.Count -ge 1) {
        $lastText = $elements[-1].Extent.Text
        if ($lastText -eq $word -and $elements.Count -ge 2) {
            $prevToken = $elements[-2].Extent.Text
        }
        elseif ($lastText -ne $word) {
            $prevToken = $lastText
        }
    }

    # If the previous token is a choice-type option, complete its choices.
    if ($prevToken) {
        $opt = $script:ClaudeOptions | Where-Object { $_.Name -eq $prevToken -and $_.Choices } | Select-Object -First 1
        if ($opt) {
            return $opt.Choices |
                Where-Object { $_ -like "$word*" } |
                ForEach-Object {
                    [CompletionResult]::new($_, $_, [CompletionResultType]::ParameterValue, "$($opt.Name): $_")
                }
        }
    }

    # Otherwise complete options and/or subcommands.
    $results = [System.Collections.Generic.List[CompletionResult]]::new()

    if ($word -like '-*') {
        # Completing an option flag.
        foreach ($o in $script:ClaudeOptions) {
            if ($o.Name -like "$word*") {
                $tooltip = $o.Description
                if ($o.Choices) { $tooltip += " (choices: $($o.Choices -join ', '))" }
                $results.Add([CompletionResult]::new($o.Name, $o.Name, [CompletionResultType]::ParameterName, $tooltip))
            }
        }
    }
    else {
        # Completing a subcommand (only meaningful as the first non-option token).
        $hasCommand = $false
        foreach ($e in $elements) {
            $t = $e.Extent.Text
            if ($t -eq 'claude') { continue }
            if ($t -eq $word) { continue }
            if ($t -notlike '-*') { $hasCommand = $true; break }
        }
        if (-not $hasCommand) {
            foreach ($c in $script:ClaudeCommands) {
                if ($c.Name -like "$word*") {
                    $results.Add([CompletionResult]::new($c.Name, $c.Name, [CompletionResultType]::Command, $c.Description))
                }
            }
        }
    }

    return $results
}
