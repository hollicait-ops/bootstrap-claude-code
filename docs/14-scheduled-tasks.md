# Scheduled Tasks

Claude Code has two ways to run tasks on a schedule: `/loop` for in-session
recurring prompts, and `/schedule` for persistent cloud tasks that run even
when your machine is off.

## /loop — In-Session Recurring Tasks

`/loop` repeats a prompt on a fixed interval within your current session.

**Syntax:**
```
/loop [interval] [prompt]
```

**Examples:**
```
/loop 5m check if the staging build is passing
/loop 10m summarize any new errors in the logs
/loop 1h remind me to commit my changes
```

If no interval is given, it defaults to 10 minutes.

**Interval units:** `s` (seconds), `m` (minutes), `h` (hours)

**Limits:**
- Maximum 50 concurrent loop tasks per session
- Tasks expire automatically after 3 days
- All tasks stop when you end the session

**Use cases:**
- Polling a CI build until it passes or fails
- Monitoring a deploy for errors
- Periodic reminders during long work sessions

## /schedule — Cloud Scheduled Tasks

`/schedule` creates tasks that run on Anthropic's infrastructure. They persist
across machine sleep, shutdown, and restarts.

**Create a scheduled task:**
```
/schedule
```

This opens an interactive form where you set the prompt, schedule (cron or
natural language like "every weekday at 9am"), and any context the task needs.

You can also create scheduled tasks from:
- The Claude web app at claude.ai/code
- The Claude Desktop app

**Use cases:**
- Nightly code quality summaries
- Daily standup prep from recent git activity
- Scheduled security scans
- Weekly dependency update checks

## Comparison

| | `/loop` | `/schedule` |
|---|---------|-------------|
| Runs when | Session is active | Any time, including when machine is off |
| Persistence | Session only | Survives restarts |
| Setup | Inline command | Interactive form |
| Max tasks | 50 concurrent | Varies by plan |
| Expiry | 3 days | Until cancelled |

Use `/loop` for tasks that only make sense while you're working. Use `/schedule`
for tasks that should run on a fixed calendar schedule regardless of whether
you're at your computer.

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
