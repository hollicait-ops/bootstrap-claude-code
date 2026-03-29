# Plan Mode

Plan mode makes Claude design an implementation plan and get your approval before
making any changes. It's a structured way to tackle complex or risky tasks.

## How It Works

In plan mode, Claude:
1. Explores the relevant code (read-only)
2. Asks clarifying questions
3. Writes a plan to a markdown file
4. Waits for your review and approval
5. Only starts implementing after you approve

Claude cannot make file edits, run shell commands, or take any action with side
effects while in plan mode. This is enforced — not just a guideline.

## Entering Plan Mode

**Via slash command:**
```
/plan
```

With an optional description:
```
/plan refactor the authentication middleware to use JWT
```

**Via keyboard shortcut** (if configured):
`ctrl+shift+p` (bootstrapper default)

**Always on** — set in `settings.json`:
```json
{
  "defaultMode": "plan"
}
```

With `defaultMode: "plan"`, every new session starts in plan mode. Useful for
teams that want to review all changes before they happen.

## The Planning Workflow

### Phase 1: Exploration
Claude reads relevant files and understands the codebase. It may ask you
clarifying questions about requirements or constraints. You should answer fully —
the quality of the plan depends on Claude's understanding of the task.

### Phase 2: Design
Claude designs the implementation approach, considering trade-offs and alternatives.
It identifies which files need to change and in what order.

### Phase 3: The Plan File
Claude writes its plan to `~/.claude/plans/<session-name>.md`. The plan includes:
- Context (why this change is needed)
- Recommended approach
- Files to be modified
- Implementation steps
- Verification steps (how to test the result)

### Phase 4: Your Review
You read the plan. You can:
- **Approve** — Claude proceeds with implementation
- **Request changes** — Tell Claude what to adjust; it revises the plan
- **Reject** — Cancel and start over

### Phase 5: Implementation
After approval, Claude exits plan mode and implements the plan step by step.

## Reviewing Plans in VS Code

When using Claude Code inside VS Code, the plan file opens in the editor with
full markdown rendering. You can comment directly on the plan file — Claude reads
your comments as feedback.

## When to Use Plan Mode

**Recommended for:**
- Multi-file refactors
- Database migrations
- Changes to authentication or security-critical code
- Any task where getting it wrong would be expensive to undo
- Tasks where you're not sure about the right approach

**Not needed for:**
- Simple bug fixes in one file
- Typo corrections
- Adding a single test case
- Renaming a variable

## Tips

**Be specific in your plan request.** `/plan` gives Claude latitude to interpret
the task broadly. `/plan extract the user validation logic from auth.go into a
new validators package` gives it a specific target.

**Answer clarifying questions fully.** Claude asks because it needs the information
to make good decisions. Short or vague answers lead to vague plans.

**Read the plan before approving.** Don't rubber-stamp it. The plan exists so you
can catch misunderstandings before they become code changes.

**Push back on the plan.** If the plan proposes something you don't like, say why.
Claude will revise. It's much easier to change a plan than to revert code.

## Checkpointing

Claude Code automatically saves a checkpoint before each file change. This
means you can always undo to a known-good state, even mid-implementation.

**Restore a checkpoint:**
```
/rewind
```

Or press **Esc+Esc** to open the restore dialog.

You'll be asked what to restore:

| Option | What it does |
|--------|-------------|
| **Code only** | Reverts file changes to the checkpoint state; conversation history is kept intact so you can redirect Claude without losing context |
| **Code + conversation** | Fully rewinds both files and the conversation to that exact point — a complete reset |

"Code only" is useful when Claude went down the wrong implementation path but
you still want the conversation context. "Code + conversation" is a clean slate
from that point.

Esc+Esc works anywhere in the session — not just in plan mode. Checkpointing is
automatic; there's nothing to configure.
