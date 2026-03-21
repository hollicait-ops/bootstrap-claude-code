# Claude Code Memory Index

This file is an index of Claude's persistent memory across sessions.
Individual memory entries are stored as sibling `.md` files in this directory.

## How Memory Works

Claude reads this index at the start of relevant conversations to recall
context about you, your projects, and your preferences. When Claude learns
something worth remembering, it creates a new file here and adds a pointer
to this index.

## Memory Entry Types

| Type | Purpose |
|------|---------|
| **user** | Your role, expertise, working style, and preferences |
| **feedback** | Corrections and guidance you've given Claude |
| **project** | Ongoing work, decisions, goals, and deadlines |
| **reference** | Pointers to external systems (Jira boards, Slack channels, dashboards) |

## Current Entries

<!-- Claude will add entries here as they are created -->
<!-- Format: - [entry-name.md](entry-name.md) — one-line description -->

## Example Entries

These examples show the format. Remove them and replace with your own entries as Claude builds up memory about you and your projects.

### User memories — who you are and how you work

- [user-profile.md](user-profile.md) — Senior full-stack developer; prefers TypeScript + React on the frontend and Python/FastAPI on the backend; values concise code over heavy abstraction.

### Feedback memories — corrections and preferences

- [feedback-no-default-exports.md](feedback-no-default-exports.md) — Always use named exports in TypeScript modules.
  **Why:** default exports make refactoring and auto-import harder across the codebase.
  **How to apply:** replace `export default function Foo` with `export function Foo` in every new or edited file.

- [feedback-terse-responses.md](feedback-terse-responses.md) — Keep responses short; skip summaries of work already visible in the diff.
  **Why:** user prefers to read diffs directly rather than prose recaps.
  **How to apply:** lead with the result or next action, never recap what was just done.

### Project memories — ongoing work and decisions

- [project-auth-overhaul.md](project-auth-overhaul.md) — Sprint 14 goal: migrate session-based auth to JWT + refresh-token flow by 2026-04-01.
  **Why:** remove the Redis session store dependency and unblock stateless horizontal-scaling work.
  **How to apply:** all new auth-related code should use JWT; flag any new Redis session usage for review.

### Reference memories — where to find things

- [reference-linear-board.md](reference-linear-board.md) — Bug tracking: Linear project "BACKEND" at linear.app/org/team/backend. Pipeline bugs go to project "INGEST".

## Tips

- Ask Claude to "remember" something and it will save it here automatically.
- Ask Claude to "forget" something and it will remove the relevant entry.
- Review and prune entries occasionally — stale memory can mislead.
- Never store passwords, API keys, or sensitive credentials here.
