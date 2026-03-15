---
description: Review a pull request for quality, security, and correctness
allowed-tools: Bash, Read, Glob, Grep
---

Perform a thorough code review. Arguments: $ARGUMENTS (PR number, branch name, or git range)

## Steps

1. Determine the diff to review:
   - If a PR number was given: `gh pr diff $ARGUMENTS`
   - If a branch name was given: `git diff main...$ARGUMENTS`
   - If no argument: `git diff main...HEAD`

2. Read the changed files in full (not just the diff) to understand context.

3. Check each changed file for:
   - **Correctness**: logic errors, off-by-one errors, unhandled edge cases
   - **Security**: injection vulnerabilities, missing auth checks, secrets in code, unsafe deserialization
   - **Error handling**: unhandled exceptions, missing null checks, silent failures
   - **Tests**: are the changes covered? do existing tests still make sense?
   - **Documentation**: are public APIs, config options, or breaking changes documented?
   - **Performance**: N+1 queries, unnecessary allocations, blocking calls in async contexts

4. Output a structured review:

```
## Summary
[1-2 sentences describing what the PR does]

## Issues

### Critical
- [issue] — [file:line] — [why it matters and suggested fix]

### Major
- [issue] — [file:line] — [suggested fix]

### Minor / Nits
- [issue] — [file:line]

## Suggestions
- [optional improvements that aren't blocking]

## Verdict
[ ] Approve  [ ] Approve with nits  [ ] Request changes
```

## Rules

- Be specific — cite file names and line numbers.
- Distinguish between blocking issues and optional improvements.
- Don't flag style preferences as bugs unless there's an established linter rule.
