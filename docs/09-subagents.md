# Subagents

Claude Code can spawn specialized child agents — subagents — to handle tasks
in parallel or to delegate specific work while the main session continues.

## What Are Subagents?

A subagent is a separate Claude process launched by the main session via the
`Agent` tool. Each subagent:
- Has its own isolated context window
- Can use a different model
- Runs independently (potentially in parallel with other subagents)
- Returns a single result to the parent session when done

Subagents are powerful for tasks that would otherwise fill the main context
window with search results, or that can be parallelized.

## Agent Types

Claude Code ships with several built-in agent types:

| Agent | Best for |
|-------|---------|
| `general-purpose` | Multi-step research, open-ended exploration, complex tasks |
| `Explore` | Read-only codebase exploration, searching, answering questions |
| `Plan` | Designing implementation strategies, architecture decisions |
| `claude-code-guide` | Questions about Claude Code itself |
| `statusline-setup` | Configuring the Claude Code status line |

## When to Use Subagents

**Use subagents when:**
- You need to search broadly across a large codebase and don't want search results
  filling the main context
- Multiple independent tasks can run in parallel (e.g., reviewing several files
  at once, running tests while exploring code)
- A task requires deep exploration that would distract from the main conversation

**Don't use subagents when:**
- You need to search a specific known file (just use Read/Grep directly)
- The task is simple and fast
- Results from one task are needed before starting another (sequential dependency)

## Parallel Subagents

The main power of subagents is parallelism. Claude can launch multiple agents
in a single message, and they all run concurrently:

```
"Launch two agents in parallel:
 - Agent 1: Find all API endpoints in src/api/
 - Agent 2: Find all database models in src/models/"
```

Both agents run simultaneously, and the results are combined when they finish —
dramatically faster than sequential exploration.

## Background Agents

For long-running tasks, subagents can run in the background:

```
"Start a background agent to run the full test suite and notify me when done."
```

You can continue working in the main session while the background agent runs.
You'll be notified when it completes.

## Subagents with Worktrees

Combine subagents with git worktrees for parallel development on isolated branches:

```
"Create two worktrees and launch agents to implement features A and B in parallel,
 then merge both when done."
```

Each agent works on its own isolated copy of the repository with no risk of
conflicts during development.

## Model Selection for Subagents

Subagents can use a different model than the main session. Useful for cost
optimization — use a fast, cheap model for bulk search and a powerful model
for synthesis:

```
"Use Haiku to scan all 200 files for TODOs, then summarize the results."
```

## Context Isolation

Each subagent starts with a fresh context. It doesn't inherit the parent's
conversation history unless you explicitly pass relevant context in the prompt.
This is a feature — it prevents the subagent from being confused by irrelevant
prior conversation — but it means you need to provide enough context in the
agent prompt for it to do its job.

## Practical Example

Asking Claude to do a broad security audit of a large codebase:

```
/security-check
```

Behind the scenes, Claude might:
1. Launch an Explore agent to map the codebase structure
2. Launch 3 parallel Explore agents to scan different subsystems for vulnerabilities
3. Synthesize all results in the main session
4. Present a unified security report

This happens in a fraction of the time it would take sequentially, and the
main context window stays clean.

## Tips

- **Provide complete context** in agent prompts — agents don't see the main conversation.
- **Use agents for isolation** — if a search might return thousands of lines, let
  an agent handle it instead of flooding your context.
- **Foreground vs background** — use foreground (default) when you need results
  before proceeding; use background for fire-and-forget tasks.
- **Agents are disposable** — don't try to maintain state across multiple agent
  invocations. Each invocation starts fresh.

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
