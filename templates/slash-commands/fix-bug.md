---
description: Fix a bug using test-driven development — reproduce, test, fix, verify
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Glob
  - Grep
  - TodoWrite
---

A bug has been identified. Follow this workflow to fix it:

## 1. Understand the bug

Read the relevant code and any linked issue or error message. Identify:
- What is the expected behaviour?
- What is the actual behaviour?
- Which file and function is responsible?

## 2. Reproduce it

Write a failing test that demonstrates the bug **before touching any production code**. The test must fail now and pass after the fix.

If no test harness exists, use the smallest possible reproduction — a script, a curl call, a REPL session — and document the steps.

## 3. Fix the bug

Make the minimal change needed to make the failing test pass. Do not refactor surrounding code, add unrelated features, or change behaviour beyond what the test verifies.

## 4. Verify

- Run the full test suite (or the relevant subset). All tests must pass.
- Confirm the reproduction case no longer triggers the bug.
- Check for regressions in related areas.

## 5. Commit

Write a commit message in imperative mood that explains *what* was broken and *why* the fix works. Reference the issue ID if one exists.

---

**Anti-patterns to avoid:**
- Do not delete or weaken a test to make a build pass.
- Do not add error-swallowing (`try/catch` with empty catch) as a "fix".
- Do not fix symptoms without understanding the root cause.
