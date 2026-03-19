# CLAUDE.md — Instruction Files

CLAUDE.md files contain natural-language instructions that Claude reads at the
start of every session. They're the primary way to shape Claude's behavior for
a project or globally.

## File Locations and Loading Order

| Path | Scope | Committed to git? |
|------|-------|-------------------|
| `~/.claude/CLAUDE.md` | Global — all sessions | No (personal) |
| `.claude/CLAUDE.md` | Project root | Usually yes |
| `src/CLAUDE.md` | Subdirectory | Yes |

Claude reads all applicable files and merges them. More specific files (deeper
in the directory tree) take precedence for conflicting instructions.

Claude also loads `.claude/rules/*.md` — modular rule files alongside the main
CLAUDE.md. Useful for keeping large instruction sets organized.

## What to Put in CLAUDE.md

Effective instructions are **specific and behavioral**. Tell Claude what to *do*,
not what to *value*.

### Good
```markdown
## Testing
Always run `npm test` after making changes to files in `src/`.
Never mock the database — integration tests must use a real test DB.
```

### Bad
```markdown
## Testing
Write good tests that ensure correctness.
```

The bad example tells Claude what outcome to aim for, not how to achieve it.
Claude already knows to write correct tests — what it needs is your specific
rules and constraints.

## Recommended Sections

### Project Description
A 2-4 sentence description of what the project does, the main tech stack,
and any non-obvious architectural decisions.

```markdown
## Project
A real-time collaborative code editor built on WebSockets and CRDT for
conflict resolution. The frontend is React with CodeMirror; the backend is
Go. All WebSocket state is managed in `pkg/session/`.
```

### Common Commands
The commands Claude will need to run regularly:

```markdown
## Commands
- Start dev server: `make dev`
- Run tests: `make test`
- Build for production: `make build`
- Lint: `golangci-lint run ./...`
```

### Code Style
Rules Claude should follow when writing code:

```markdown
## Code Style
- Use `snake_case` for all Go variable and function names
- Maximum function length: 40 lines. Split larger functions.
- All exported functions require godoc comments
- Use `errors.As`/`errors.Is` for error checking, never string comparison
```

### Architecture Constraints
Things Claude should not change without a discussion:

```markdown
## Architecture
- All database access goes through `pkg/db/`. Never query the DB directly
  from handler code.
- The `api/` package must not import from `internal/`. One-way dependency.
- New endpoints require a corresponding integration test in `tests/api/`.
```

### What to Avoid
Explicit anti-patterns for your codebase:

```markdown
## Do Not
- Use `any` type in Go (use concrete types or generics)
- Add `fmt.Println` debugging — use the structured logger in `pkg/log/`
- Commit directly to `main` — always use a feature branch
```

## Hidden Comments

Use HTML comments to add notes visible when reading the file, but hidden from
Claude's context:

```markdown
<!-- This section was last reviewed 2025-01 — update if auth changes -->
## Authentication
...
```

Claude will not see or respond to the comment. Useful for maintenance notes.

## Global vs Project Instructions

Use `~/.claude/CLAUDE.md` for:
- Your personal working style (communication preferences, commit message format)
- Security rules that apply everywhere (never read `.env` files)
- Tools and habits that follow you across projects

Use `.claude/CLAUDE.md` for:
- Project-specific conventions, architecture, and tech stack details
- Team-shared rules that should be committed to the repo
- Commands specific to this project

## Tips

**Keep instructions actionable.** Claude reads these files as constraints to
follow, not aspirations to aim for.

**Update when conventions change.** Stale instructions are worse than no
instructions — Claude will follow them confidently even when they're wrong.

**Test your instructions.** Start a new session and ask Claude to describe the
project. If it gets something wrong, update the relevant instruction.

**Don't duplicate what's obvious.** Claude knows to write secure code, handle
errors, and follow language idioms. Focus on what's *specific to your project*.
