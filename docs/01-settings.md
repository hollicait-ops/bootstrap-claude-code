# Settings Reference

Claude Code settings control model selection, permissions, hooks, and behavior.

## Understanding the ~ Symbol in Paths

Throughout this guide you will see paths like `~/.claude/settings.json`.
The `~` is shorthand for your **home directory** — the personal folder your
operating system assigns to your user account:

| OS | Your home directory |
|----|---------------------|
| macOS | `/Users/yourname` |
| Linux / WSL | `/home/yourname` |
| Windows (native) | `C:\Users\yourname` |

So `~/.claude/settings.json` means a file named `settings.json` inside a
folder called `.claude` inside your home directory. Claude Code creates this
file automatically the first time you run it.

## File Locations

There are three levels of settings, each with a different scope:

| File | Scope | Committed to git? |
|------|-------|-------------------|
| `~/.claude/settings.json` | **Global** — applies to every project on your machine | Never |
| `.claude/settings.json` | **Project** — applies only in this directory tree | Optional (yes for team defaults) |
| `.claude/settings.local.json` | **Local** — personal overrides for one project | No (gitignored) |

Settings load in order: global first, then project, then local. Later settings
override earlier ones for the same key.

**When to use each level:**

- **Start with global** (`~/.claude/settings.json`) for anything that should
  apply everywhere: safety rules, your preferred model, personal permissions.
- **Add project settings** (`.claude/settings.json`) when a specific repo
  needs different behavior — for example, allowing a project-specific test
  command, or sharing hook configurations with your team by committing the file.
- **Use local settings** (`.claude/settings.local.json`) for personal
  overrides that differ from your team's project settings.

Project settings override global settings. Local settings override project settings.

> **Note:** Claude Code's settings parser accepts `//` line comments (JSONC format).
> Comments are stripped before parsing, so you can annotate your settings freely.
> Standard JSON validators (e.g. `python3 -m json.tool`) will reject commented files —
> use a JSONC-aware linter such as VS Code's built-in JSON language server instead.

## Shell Configuration (Windows)

Claude Code uses **Git Bash** as its underlying shell on Windows (required -- it cannot be replaced). By default it also generates **Unix shell syntax** regardless of what you have configured. There are two separate problems Windows users typically face, with different solutions:

### Problem 1: Bash commands freeze or hang

The most common cause is the `.claude/shell-snapshots/` directory accumulating corrupted files. Clear it:

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\shell-snapshots"
```

This may need to be done periodically. See [troubleshooting](11-troubleshooting.md) for the full freeze diagnosis.

### Problem 2: Commands use Unix syntax instead of PowerShell

Two steps are needed -- one to enable the native PowerShell tool, one to make Claude generate PowerShell syntax.

**Step 1 -- Enable the PowerShell tool in `settings.json`:**

```json
{
  "env": {
    "CLAUDE_CODE_USE_POWERSHELL_TOOL": "1"
  },
  "defaultShell": "powershell"
}
```

`CLAUDE_CODE_USE_POWERSHELL_TOOL` enables an opt-in preview PowerShell tool alongside the Bash tool. `defaultShell: "powershell"` routes interactive (`!`) commands through PowerShell. Claude Code auto-detects `pwsh.exe` (PowerShell 7+) with fallback to `powershell.exe` (5.1).

> **Important:** Do **not** set `shellPath` or `env.SHELL` to `powershell.exe`/`pwsh.exe`. The Bash tool requires Git Bash as its POSIX shell. Setting `shellPath` to PowerShell breaks the Bash tool entirely with "No suitable shell found."

> **Preview limitations:** Auto mode is not supported with the PowerShell tool. PowerShell profiles are not loaded. Sandboxing is not supported.

**Step 2 -- Add a PowerShell syntax instruction to `~/.claude/CLAUDE.md`:**

```markdown
## PowerShell syntax

Use PowerShell-native syntax when executing shell commands. This means:
- Use `$null` instead of `/dev/null`
- Use backslashes in Windows paths (e.g. `C:\Users\...`)
- Use PowerShell cmdlets (Get-ChildItem, Get-Content, Select-String, etc.)
- Use semicolons or pipeline operators, not `&&` to chain commands
- Use `Remove-Item` instead of `rm`, `Copy-Item` instead of `cp`, etc.
- Use `$env:VAR` instead of `$VAR` for environment variables
```

This overrides Claude Code's built-in "use Unix shell syntax" default. Without it, Claude may still generate bash-style commands even when PowerShell is configured. A ready-to-use template is at [`examples/claude-md/CLAUDE.md-windows`](../examples/claude-md/CLAUDE.md-windows).

---

## Core Settings

```json
{
  "model": "claude-sonnet-4-6",
  "theme": "dark",
  "autoMemory": true,
  "includeGitInstructions": true
}
```

| Setting | Values | Description |
|---------|--------|-------------|
| `model` | model ID string | Default model for all sessions |
| `theme` | `"dark"`, `"light"`, `"auto"` | Terminal color theme |
| `autoMemory` | `true` / `false` | Enable automatic memory saving |
| `includeGitInstructions` | `true` / `false` | Inject git context into sessions |
| `effortLevel` | `"low"`, `"medium"`, `"high"` | Persisted thinking/effort level. Also set with `/effort`. |
| `alwaysThinkingEnabled` | `true` / `false` | When `false`, disables extended thinking entirely. Default: enabled for supported models. |
| `fastMode` | `true` / `false` | Enable fast mode for quicker responses. Also toggle with `/fast`. |
| `voiceEnabled` | `true` / `false` | Enable voice push-to-talk. Also activate with `/voice`. |
| `autoMemoryEnabled` | `true` / `false` | Enable auto-memory for this project. When `false`, Claude won't read or write the auto-memory directory. |
| `autoMemoryDirectory` | path string | Custom path for auto-memory storage. Supports `~/` prefix. Cannot be set in project settings for security. |
| `defaultView` | `"chat"`, `"transcript"` | Default transcript view. `chat` shows only user/assistant turns; `transcript` shows full tool history. |
| `showThinkingSummaries` | `true` / `false` | Show thinking summaries in transcript view (Ctrl+O). Default: `false`. |
| `feedbackSurveyRate` | `0.0` – `1.0` | Probability the session quality survey appears. `0.05` means 5% of sessions. |

### Model Selection

| Model | Best for |
|-------|---------|
| `claude-opus-4-6` | Complex reasoning, architecture decisions, large codebases |
| `claude-sonnet-4-6` | Everyday coding — best speed/quality balance (recommended default) |
| `claude-haiku-4-5-20251001` | Fast lookups, simple edits, high-volume tasks |

Set per-session with `/model <model-id>` or permanently in `settings.json`.

## Permissions

The permissions system controls which tool calls Claude can make and how.

```json
{
  "permissions": {
    "allow": ["Bash(git status)", "Edit(./src/**)"],
    "deny":  ["Bash(rm -rf*)", "Read(.env)"],
    "ask":   ["Bash(git push*)"]
  }
}
```

### Rule Syntax

Rules follow the pattern `Tool(pattern)`:

| Tool | Matches |
|------|---------|
| `Bash(command*)` | Shell commands matching the glob |
| `Read(path)` | File reads matching the path glob |
| `Edit(path)` | File edits matching the path glob |
| `Write(path)` | File writes matching the path glob |
| `*` | All tools |

**Glob patterns** use `*` (any chars except `/`) and `**` (any chars including `/`).

### Rule Precedence

`deny` > `allow` > `ask` > default (prompt user)

A matching `deny` rule always wins, even if an `allow` rule also matches.

### Examples

```json
"allow": [
  "Bash(git *)",          // all git subcommands
  "Edit(./src/**)",       // edit anything under src/
  "Bash(npm run *)",      // any npm script
  "Bash(* --version)"    // version checks for any tool
],
"deny": [
  "Bash(rm -rf *)",       // no recursive deletes
  "Read(.env)",           // protect .env in current dir
  "Read(**/.env)",        // protect .env anywhere
  "Read(~/.ssh/**)",      // protect SSH keys
  "Bash(git push --force*)"
],
"ask": [
  "Bash(git push *)",     // confirm before any push
  "Bash(curl *)"          // confirm before network calls
]
```

## Hooks Configuration

Hooks are registered in `settings.json` after the hook scripts are installed.
The installer does this automatically. Manual format:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [{"type": "command", "command": "/path/to/hook.sh"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "/path/to/hook.sh"}]
      }
    ],
    "Stop": [
      {
        "hooks": [{"type": "command", "command": "/path/to/hook.sh"}]
      }
    ]
  }
}
```

The `matcher` field is a tool name or `"*"` for all tools. `PreToolUse` and
`PostToolUse` support matchers; `Stop` and `SessionStart` do not.

See [04-hooks.md](04-hooks.md) for full hook documentation.

## MCP Server Configuration

MCP servers extend Claude with additional tools. Add them to `settings.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/dir"]
    }
  }
}
```

See [05-mcp-servers.md](05-mcp-servers.md) for setup guides.

## Troubleshooting

**Claude isn't following my deny rules**
- Verify the rule syntax — the pattern must match exactly. Test with `/permissions` in a session.
- `deny` takes effect at the permission prompt, not before Claude decides to try the command.

**settings.json isn't being loaded**
- Check for JSON syntax errors: `python3 -m json.tool ~/.claude/settings.json`
- Project settings (`.claude/settings.json`) override global ones — check both.

**Changes not taking effect**
- Settings are loaded at session start. Restart the Claude Code session after editing.

---

## User Guide

| Guide | Topic |
|-------|-------|
| [00-overview.md](00-overview.md) | Overview and quick start |
| [01-settings.md](01-settings.md) | settings.json permissions, model, all options |
| [02-claude-md.md](02-claude-md.md) | Writing effective CLAUDE.md instruction files |
| [03-memory.md](03-memory.md) | Persistent memory system |
| [04-hooks.md](04-hooks.md) | Shell hooks for automation and safety |
| [05-mcp-servers.md](05-mcp-servers.md) | Extending Claude with MCP tools |
| [06-slash-commands.md](06-slash-commands.md) | Custom slash commands / skills |
| [07-keybindings.md](07-keybindings.md) | Keyboard shortcuts |
| [08-plan-mode.md](08-plan-mode.md) | Structured planning before execution |
| [09-subagents.md](09-subagents.md) | Parallel and specialized subagents |
| [10-advanced-patterns.md](10-advanced-patterns.md) | Combining features for powerful workflows |
| [11-troubleshooting.md](11-troubleshooting.md) | Common problems and how to fix them |
| [12-plugins.md](12-plugins.md) | Installing and managing plugins |
| [13-voice-mode.md](13-voice-mode.md) | Voice input with push-to-talk |
| [14-scheduled-tasks.md](14-scheduled-tasks.md) | Recurring tasks with /loop and /schedule |
