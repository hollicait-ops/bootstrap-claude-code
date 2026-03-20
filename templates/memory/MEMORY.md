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

<!--
EXAMPLES — copy, uncomment, and edit these to get started:

(user) Developer role and preferred stack
- [user-profile.md](user-profile.md) — Senior full-stack developer; prefers TypeScript + React on the frontend and Python/FastAPI on the backend; values concise code over heavy abstraction.

(feedback) Code style correction
- [feedback-no-default-exports.md](feedback-no-default-exports.md) — Always use named exports in TypeScript modules.
  Why: default exports make refactoring and auto-import harder across the codebase.
  How to apply: replace `export default function Foo` with `export function Foo` in every new or edited file.

(project) Current sprint goal
- [project-auth-overhaul.md](project-auth-overhaul.md) — Sprint 14 goal: migrate session-based auth to JWT + refresh-token flow by 2026-04-01.
  Motivation: remove the Redis session store dependency and unblock the stateless horizontal-scaling work.
-->

## Tips

- Ask Claude to "remember" something and it will save it here automatically.
- Ask Claude to "forget" something and it will remove the relevant entry.
- Review and prune entries occasionally — stale memory can mislead.
- Never store passwords, API keys, or sensitive credentials here.
