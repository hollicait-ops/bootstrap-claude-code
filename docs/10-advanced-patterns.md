# Advanced Patterns

Combining Claude Code features for powerful workflows.

## Hooks + Slash Commands: Automated Workflows

Combine a PostToolUse hook with a custom command to build automated pipelines.

**Example: Auto-run tests after every edit, report failures back to Claude**

`~/.claude/hooks/post-tool-use.sh`:
```bash
#!/usr/bin/env bash
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]]; then
  if [ -f "package.json" ] && command -v npm &>/dev/null; then
    RESULT="$(npm test --silent 2>&1)" || true
    if echo "$RESULT" | grep -q "failing"; then
      # Write failure summary to a temp file Claude can read
      echo "$RESULT" | tail -20 > /tmp/test-failures.txt
    fi
  fi
fi
exit 0
```

Then in your CLAUDE.md:
```markdown
After making code changes, check /tmp/test-failures.txt — if it exists and
is non-empty, read it and fix the failures before moving on.
```

## Per-Project CLAUDE.md + Global Fallback

Structure instructions hierarchically:

- `~/.claude/CLAUDE.md` — universal rules (security, git discipline, style)
- `.claude/CLAUDE.md` — project-specific conventions, architecture, commands
- `src/CLAUDE.md` — rules for a specific subdirectory (e.g., "this is legacy code, don't refactor")

Claude reads all applicable files. This lets you share global rules across
all projects while keeping project-specific rules colocated with the code.

## Running Claude in CI/CD

Use Claude Code non-interactively in automated pipelines:

```bash
# Generate a PR description
git diff main...HEAD | claude --print "Write a PR description for these changes"

# Auto-review changed files
claude --print "/review-pr" --no-interactive

# Security scan on every PR
claude --print "/security-check src/" --no-interactive
```

`--print` outputs Claude's response to stdout and exits. `--no-interactive`
prevents prompts for permission approval (use only in trusted CI environments
with appropriate deny rules in settings.json).

## Session Management

**Resume a session:**
```
/resume
```
Loads a previous session's context. Useful for picking up long tasks after
a break.

**Branch a session:**
```
/branch
```
Creates a new session that shares the current conversation history. Experiment
without losing your main thread.

**Compact context:**
```
/compact
```
Summarizes the conversation history to free up context window space. Useful
for very long sessions. Claude summarizes what happened and continues with the
summary as context.

## MCP + Subagents: Research Pipeline

Combine MCP web search with subagents for comprehensive research:

```
"I need to understand the best approach for implementing distributed locking
in Go. Use the web search tool to find current best practices, then analyze
our existing locking code in pkg/lock/, and give me a recommendation."
```

Claude might:
1. Launch an Explore agent to read `pkg/lock/`
2. Use the Brave Search MCP tool to find current Go distributed locking patterns
3. Synthesize both into a recommendation

## Worktrees for Parallel Development

Work on multiple features simultaneously without branch switching:

```bash
# Claude can create and manage worktrees
git worktree add ../feature-a feature-a
git worktree add ../feature-b feature-b
```

Then launch background agents in each:
```
"Start two background agents:
 - Agent 1: implement feature A in ../feature-a
 - Agent 2: implement feature B in ../feature-b
Notify me when both are done."
```

## CLAUDE.md for Legacy Code

When Claude needs to work with legacy code that doesn't follow your standards:

```markdown
## Legacy Code: src/legacy/

The code in `src/legacy/` is intentionally not touched. Do not refactor,
modernize, or apply code style rules to anything in this directory.
Make the minimum change needed to fix bugs. Never add new files here.
```

This prevents Claude from "improving" code that should be left alone.

## Terse Mode via CLAUDE.md

If you find Claude's responses too verbose, add to your global CLAUDE.md:

```markdown
## Communication Style
- Skip preamble. Lead with the answer or the first action.
- Don't summarize what you just did — I can see it in the diff.
- Use bullet points for lists. Short sentences. No filler.
- If something needs explanation, one paragraph maximum.
```

## Git Workflow Automation

A pattern for disciplined, automated git workflows:

1. Add to CLAUDE.md:
```markdown
## Git Workflow
1. Always work on a feature branch — never commit to main
2. Branch naming: feature/<ticket>-<description> or fix/<ticket>-<description>
3. Before committing: run tests, run linter
4. Use /commit to create commits — don't use git commit directly
```

2. The `/commit` command handles the actual commit with proper formatting.

3. A PreToolUse hook blocks direct `git commit` calls:
```bash
if [[ "$TOOL_NAME" == "Bash" ]]; then
  CMD="$(get_command)"
  if echo "$CMD" | grep -q '^git commit' && ! echo "$CMD" | grep -q '/commit'; then
    echo "Please use the /commit command instead of git commit directly."
    exit 2
  fi
fi
```

## Cross-Surface Workflows

> **Research preview:** These features are available on select plans and may
> change. Check your subscription for availability.

Claude Code can span multiple devices and surfaces. Three features enable this:

### Remote Control

Connect your local Claude Code terminal session to claude.ai or the Claude
mobile app. Once connected, you can send instructions from your phone and
Claude Code executes them locally.

```bash
claude remote-control
```

Key properties:
- Only chat messages travel over the network — your code and files stay local
- The session runs in an encrypted channel
- The env var `CLAUDE_CODE_REMOTE` is set to `"true"` inside remote-triggered
  sessions (useful in hooks to detect remote vs. local execution)

### `/teleport` — Web to Terminal

Pull an active web or cloud session into your local terminal:

```
/teleport
```

The session context moves to the terminal; the web session ends. Use this when
you started a task in the browser and want to continue with full local tool
access (filesystem, shell, git).

### `/desktop` — Terminal to Desktop App

Hand off your terminal session to the Claude Desktop app:

```
/desktop
```

Use this to review diffs visually, access Desktop-specific features, or get
a better UI for long-running tasks.

---

**Note:** These are research preview features. Availability depends on your
subscription plan and may change.

## Handling Secrets in Projects

Best practice for projects with secrets:

1. Add to project CLAUDE.md:
```markdown
## Secrets
- Never read, print, or reference .env files or their contents
- If you need a config value, ask me — don't look it up
- Use environment variable names in code, never actual values
```

2. Add to `settings.json`:
```json
"deny": [
  "Read(.env)",
  "Read(.env.*)",
  "Read(**/.env)",
  "Edit(.env)",
  "Edit(.env.*)"
]
```

Both layers provide defense in depth — CLAUDE.md as a behavioral instruction
and settings.json as a hard technical block.
