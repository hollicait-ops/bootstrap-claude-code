# Bootstrap Claude Code

A self-contained bootstrapper that sets up best-practice Claude Code configurations
for new and experienced users alike. Run one script, get a fully configured setup.

## Platform Support

| Platform          | Script          | Shell Required      |
|-------------------|-----------------|---------------------|
| macOS / Linux     | `install.sh`    | Bash 4+             |
| Windows (native)  | `install.ps1`   | PowerShell 5.1+     |
| Windows (WSL)     | `install.sh`    | Bash 4+ inside WSL  |

Each platform has its own dedicated installer. They are intentionally separate —
`install.sh` will refuse to run on native Windows, and `install.ps1` will refuse
to run on macOS/Linux. On Windows with WSL, you can use either: `install.ps1`
from PowerShell configures the Windows `~/.claude/` path; `install.sh` inside a
WSL terminal configures the Linux home path.

Hooks are platform-specific: `install.sh` installs `.sh` hook scripts;
`install.ps1` installs `.ps1` hook scripts. Slash commands (`.md` files) and
all other configs are shared and identical across platforms.

## What It Installs

| File | Description |
|------|-------------|
| `~/.claude/settings.json` | Sensible allow/deny/ask permission rules, model selection |
| `~/.claude/CLAUDE.md` | Global instructions for consistent behavior across all projects |
| `~/.claude/keybindings.json` | Useful keyboard shortcuts |
| `~/.claude/memory/MEMORY.md` | Persistent memory index |
| `~/.claude/hooks/*.sh` (macOS/Linux) or `*.ps1` (Windows) | Safety guards and automation hooks (opt-in behaviors) |
| `~/.claude/commands/*.md` | `/commit`, `/review-pr`, `/security-check`, `/daily-standup` |

All existing files are backed up before any changes are made.

## Quick Start

**macOS / Linux:**
```bash
git clone https://github.com/your-org/bootstrap-claude-code
cd bootstrap-claude-code
./install.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/your-org/bootstrap-claude-code
cd bootstrap-claude-code
.\install.ps1
```

> If you see an execution policy error on Windows, run:
> `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

### Options

**macOS / Linux:**
```bash
./install.sh --dry-run      # Preview changes without making them
./install.sh --minimal      # Only install settings.json and CLAUDE.md
./install.sh --force        # Overwrite existing files without prompting
./install.sh --unattended   # Accept all defaults (for CI/automation)
./install.sh --verify       # Check an existing install without changing anything
```

**Windows:**
```powershell
.\install.ps1 -DryRun       # Preview changes without making them
.\install.ps1 -Minimal      # Only install settings.json and CLAUDE.md
.\install.ps1 -Force        # Overwrite existing files without prompting
.\install.ps1 -Unattended   # Accept all defaults (for CI/automation)
.\install.ps1 -Verify       # Check an existing install without changing anything
```

## Requirements

**macOS / Linux:**
- **Bash 4+** — macOS ships with bash 3; upgrade: `brew install bash`
- **Claude Code** — installed automatically if missing (requires npm)
- **python3** — used for smart JSON merging; installed automatically if missing

**Windows:**
- **PowerShell 5.1+** — built into Windows 10/11; [PowerShell 7+](https://aka.ms/powershell) recommended
- **Claude Code** — installed automatically if missing (requires npm)
- JSON merging uses native PowerShell — no python3 required

The installer will detect missing requirements and offer to install them.

## What the Permission Rules Do

The installed `settings.json` configures three tiers of permission:

**Allow (no prompt):** Read-only git commands, file listing, test runners, build tools
**Ask (confirm first):** `git push`, `npm publish`, `curl`, `rm -rf`
**Deny (always blocked):** `rm -rf /`, `rm -rf ~`, reading `.env` files, reading SSH keys, force push

## The Slash Commands

After install, these commands are available in any Claude Code session:

| Command | Usage | Description |
|---------|-------|-------------|
| `/commit` | `/commit` | Review staged changes and create a well-formed git commit |
| `/review-pr` | `/review-pr 123` | Review a PR for quality, security, and correctness |
| `/security-check` | `/security-check src/` | Scan for common security vulnerabilities |
| `/daily-standup` | `/daily-standup` | Generate a standup from recent git activity |

## The Hook Scripts

Hooks are installed but **do nothing by default** — all behaviors are opt-in.
Edit the scripts to enable what you want:

**macOS / Linux** (`.sh`):

| Hook | What you can enable |
|------|---------------------|
| `~/.claude/hooks/pre-tool-use.sh` | Block dangerous commands, require confirmation |
| `~/.claude/hooks/post-tool-use.sh` | Audit logging, auto-format on edit, auto-test |
| `~/.claude/hooks/stop.sh` | Desktop notification when Claude finishes |
| `~/.claude/hooks/session-start.sh` | Show git status, load project context |

**Windows** (`.ps1`):

| Hook | What you can enable |
|------|---------------------|
| `~/.claude/hooks/pre-tool-use.ps1` | Block dangerous commands, require confirmation |
| `~/.claude/hooks/post-tool-use.ps1` | Audit logging, auto-format on edit, auto-test |
| `~/.claude/hooks/stop.ps1` | Windows toast notification when Claude finishes |
| `~/.claude/hooks/session-start.ps1` | Show git status, load project context |

See [docs/04-hooks.md](docs/04-hooks.md) and [examples/hooks/](examples/hooks/) for
ready-to-use hook scripts.

## Uninstalling

**macOS / Linux:**
```bash
./uninstall.sh
```

To restore a backup:
```bash
./uninstall.sh --restore-backup ~/.claude/bootstrapper-backup-20250315-143022
```

**Windows:**
```powershell
.\uninstall.ps1
```

To restore a backup:
```powershell
.\uninstall.ps1 -RestoreBackup "$HOME\.claude\bootstrapper-backup-20250315-143022"
```

## User Guide

The `docs/` directory contains a complete reference for every Claude Code feature:

- [docs/00-overview.md](docs/00-overview.md) — What this bootstrapper sets up and why
- [docs/01-settings.md](docs/01-settings.md) — settings.json: permissions, model, all options
- [docs/02-claude-md.md](docs/02-claude-md.md) — Writing effective CLAUDE.md instruction files
- [docs/03-memory.md](docs/03-memory.md) — Persistent memory system
- [docs/04-hooks.md](docs/04-hooks.md) — Shell hooks for automation and safety
- [docs/05-mcp-servers.md](docs/05-mcp-servers.md) — Extending Claude with MCP tools
- [docs/06-slash-commands.md](docs/06-slash-commands.md) — Custom slash commands / skills
- [docs/07-keybindings.md](docs/07-keybindings.md) — Keyboard shortcuts
- [docs/08-plan-mode.md](docs/08-plan-mode.md) — Structured planning before execution
- [docs/09-subagents.md](docs/09-subagents.md) — Parallel and specialized subagents
- [docs/10-advanced-patterns.md](docs/10-advanced-patterns.md) — Combining features for powerful workflows
- [docs/11-troubleshooting.md](docs/11-troubleshooting.md) — Common problems and how to fix them

## Examples

> **New to Claude Code?** Start here — the `examples/` directory has ready-to-use
> configurations so you don't have to build from scratch.

The `examples/` directory has concrete, copy-paste-ready configurations:

### Settings examples (`examples/settings/`)

| File | What it is |
|------|-----------|
| `settings-full.json` | Every permission rule with inline comments explaining what each one does and why — ideal for learning the permission system |
| `settings-full-windows.json` | Same as above but with Windows-style paths |
| `settings-minimal.json` | Bare minimum: just model and a few safety rules |
| `settings-strict.json` | Locked-down config that asks before most operations — good for sensitive codebases |

### Hook examples (`examples/hooks/`)

| File | What it does |
|------|-------------|
| `audit-logger.sh` / `.ps1` | Logs every tool call to a file for auditing |
| `block-dangerous-rm.sh` | Standalone safety guard for destructive deletions |
| `notify-on-stop.sh` / `.ps1` | Desktop notification when Claude finishes a response |

### MCP server configs (`examples/mcp/`)

Ready-made MCP configuration files for common tools. Copy to `.mcp.json` in your
project or merge into `~/.claude/mcp.json`.

### CLAUDE.md templates (`examples/claude-md/`)

| File | Best for |
|------|---------|
| `CLAUDE.md-python-project` | Python repos -- includes test runner, linting, import conventions |
| `CLAUDE.md-web-app` | React/Node web apps -- frontend patterns, API conventions |
| `CLAUDE.md-global-persona` | Global `~/.claude/CLAUDE.md` -- personal style and commit preferences |
| `CLAUDE.md-windows` | Global `~/.claude/CLAUDE.md` -- Windows-specific: PowerShell syntax instructions |

Copy the template that fits your project to `~/.claude/CLAUDE.md` (global) or
`.claude/CLAUDE.md` (project-specific) and customize from there.

## Customizing After Install

Everything installed is meant to be edited:

1. **`~/.claude/CLAUDE.md`** — Add your personal style, commit preferences, and project norms
2. **`~/.claude/settings.json`** — Tune the permission rules for your workflow
3. **`~/.claude/hooks/*.sh`** (macOS/Linux) or **`~/.claude/hooks/*.ps1`** (Windows) — Uncomment the behaviors you want
4. **`~/.claude/commands/*.md`** — Edit the slash commands or add your own

Project-specific configuration goes in `.claude/CLAUDE.md` in each project root —
that file is loaded alongside the global one, giving you per-project customization
without losing global rules.
