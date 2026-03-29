# Memory System

Claude Code has a persistent memory system that lets Claude remember information
across sessions — so you don't have to re-explain your preferences, project
context, or past decisions every time.

## How It Works

When `autoMemory` is enabled in `settings.json`, Claude automatically identifies
things worth remembering and saves them to files in `~/.claude/memory/`. An index
file (`MEMORY.md`) tracks all entries.

At the start of relevant conversations, Claude reads the index and loads entries
that seem applicable to the current task.

## Memory Entry Types

| Type | What it stores |
|------|---------------|
| `user` | Your role, expertise, working style, preferences |
| `feedback` | Corrections you've given Claude — what to do differently |
| `project` | Ongoing work, decisions, goals, deadlines |
| `reference` | Pointers to external systems (Jira, Slack, dashboards) |

## Asking Claude to Remember

You can explicitly ask Claude to save something:

> "Remember that we're using PostgreSQL 16, not MySQL."

> "Remember I prefer short, direct responses without trailing summaries."

> "Remember the API rate limit is 100 req/min — always mention this when writing
> code that calls the payments API."

Claude will write the entry to `~/.claude/memory/` and add a pointer to `MEMORY.md`.

## Asking Claude to Forget

> "Forget that I'm using PostgreSQL — we migrated to CockroachDB."

> "Remove your memory about the rate limit."

Claude will find and delete the relevant memory file and remove its index entry.

## Memory File Structure

Each memory entry is a markdown file with frontmatter:

```markdown
---
name: postgres-database
description: Project uses PostgreSQL 16, not MySQL
type: project
---

The project database is PostgreSQL 16 running on AWS RDS.
Connection details are in the .env file (never log or print these).
The ORM is SQLAlchemy; raw queries live in `db/queries/`.

**Why:** Migrated from MySQL in Q3 2024 for JSONB support.
**How to apply:** Always use PostgreSQL-specific syntax and features.
```

The `description` field is the most important — it's what Claude uses to decide
whether to load this entry for a given conversation.

## MEMORY.md Index

`~/.claude/MEMORY.md` is an index of all entries:

```markdown
# Claude Code Memory Index

## Current Entries
- [postgres-database.md](postgres-database.md) — Project uses PostgreSQL 16
- [user-preferences.md](user-preferences.md) — Terse responses, no trailing summaries
- [jira-board.md](jira-board.md) — Bug tracking in PROJ-* Jira project
```

Claude reads this index first, then loads individual files based on relevance.
Keep the index under ~200 lines — entries beyond that may be truncated.

## Memory Best Practices

**Do save:**
- Tech stack specifics that differ from defaults
- Constraints that aren't obvious from the code (rate limits, compliance requirements)
- Your working preferences (response style, commit message format)
- Pointers to external systems Claude might need

**Don't save:**
- Code patterns — Claude can read the current code
- Git history — `git log` is authoritative
- Anything already in CLAUDE.md
- Passwords, API keys, or credentials — **never**

**Prune regularly.** Memory entries don't expire automatically. Review every few
months and delete stale entries that no longer apply.

## Privacy

Memory is stored locally in `~/.claude/memory/`. It is not synced to Anthropic's
servers. However, relevant memory entries are sent to Claude as part of your
conversation context, so they are processed by the model.

Do not store sensitive credentials, personal data, or anything you wouldn't want
included in an API request.

## Configuration

Enable/disable auto-memory in `settings.json`:

```json
{
  "autoMemory": true
}
```

The memory directory location defaults to `~/.claude/memory/`. This is not
currently configurable via settings — it follows the Claude directory location.

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
