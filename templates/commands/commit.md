---
description: Create a well-formed git commit from staged changes
allowed-tools: Bash, Read
---

Review the staged changes and create a clean, atomic git commit.

## Steps

1. Run `git status` to see the full picture.
2. Run `git diff --staged` to review exactly what is staged.
3. If nothing is staged, ask the user which files to stage — do not `git add .` without asking.
4. Draft a commit message:
   - Subject line: imperative mood, under 72 characters ("Add X" not "Added X")
   - Body (if the change is non-trivial): explain *why*, not *what*
   - No trailing period on the subject line
5. Show the proposed commit message to the user before committing.
6. Run `git commit -m "..."` using a heredoc to preserve formatting.
7. Confirm success with `git log --oneline -1`.

## Rules

- Never use `git add -A` or `git add .` without explicit user approval.
- Never use `--no-verify`.
- If pre-commit hooks fail, fix the underlying issue — do not bypass.
- One logical change per commit. If the staged changes span multiple concerns, say so and ask.
