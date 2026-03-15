---
description: Generate a daily standup summary from git activity and open tasks
allowed-tools: Bash, Read
---

Generate a concise daily standup update based on recent work.

## Steps

1. Check recent git activity:
   ```
   git log --oneline --since="yesterday" --author="$(git config user.name)"
   ```

2. Check any open issues or PRs if `gh` is available:
   ```
   gh pr list --author @me --state open
   ```

3. Check for any TODO/FIXME comments recently touched:
   ```
   git diff HEAD~5 HEAD | grep -E '^\+.*TODO|^\+.*FIXME'
   ```

4. Format the standup:

```
## Standup — [today's date]

**Yesterday**
- [bullet per commit or logical work item]

**Today**
- [inferred from open PRs, recent branches, or ask user]

**Blockers**
- [none] or [describe if any found]
```

## Notes

- Keep each bullet to one line — standup format, not an essay.
- If git log is empty (no commits yesterday), say so explicitly.
- Ask the user what they plan to do today rather than guessing.
