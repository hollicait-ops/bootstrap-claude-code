---
description: Diagnose and fix a bug with root-cause discipline
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, TodoWrite
---

Diagnose and fix the bug described or implied by the current context (failing test, error message, or user description).

## Steps

1. **Read the evidence first.** If there is a failing test, run it and capture the full output. If there is an error message, read the relevant source files before touching anything.
2. **Identify the root cause** — the specific code path, assumption, or edge case that triggers the failure. State it explicitly before proposing any fix. Do not treat the symptom.
3. **Write a failing test** (or confirm the existing one fails) that reproduces the bug. The test must fail before any fix is applied.
4. **Make the minimal targeted change** that makes the failing test pass. Do not refactor unrelated code, add features, or clean up style in the same commit.
5. **Verify** by running the affected tests (and any broader test suite if fast). Confirm the previously failing test now passes and no regressions were introduced.
6. **Summarise** in one sentence: what was wrong and why the fix works.

## Rules

- Never skip straight to a fix without reading the error and the code involved.
- Do not widen a test's assertions or delete a test to make a build pass — that is not a fix.
- If the root cause is unclear after two investigation attempts, say so and ask the user for more context rather than guessing.
- Keep the commit atomic: one bug, one fix, one commit.
