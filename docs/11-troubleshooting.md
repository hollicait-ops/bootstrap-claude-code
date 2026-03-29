# Troubleshooting

Common problems and how to fix them.

---

## Install fails on bash version check

**Symptom:** `install.sh` exits immediately with:
```
[warn]  Bash 4+ required (found: 3.2.57...)
```

**Cause:** macOS ships with Bash 3.2 (due to licensing). The installer requires Bash 4+.

**Fix:**
```bash
# Install a modern bash via Homebrew
brew install bash

# Re-run the installer with the new bash explicitly
/usr/local/bin/bash install.sh
# or on Apple Silicon:
/opt/homebrew/bin/bash install.sh
```

To make the new bash your default shell, add `/usr/local/bin/bash` (or `/opt/homebrew/bin/bash`) to `/etc/shells`, then run `chsh -s /usr/local/bin/bash`.

---

## python3 not found — JSON settings are overwritten instead of merged

**Symptom:** During install you see:
```
[warn]  python3 not found. Copying settings.json wholesale (existing settings overwritten).
```

**Note:** This applies to **Linux and macOS** only. The Windows installer (`install.ps1`) uses PowerShell's built-in JSON handling and does not require python3.

**Cause:** The installer uses `python3` to merge your existing `settings.json` with the template. Without it, it falls back to a full overwrite, losing any customizations you had.

**Fix — install python3:**
```bash
# macOS
brew install python3

# Debian/Ubuntu
sudo apt-get install -y python3

# Fedora / RHEL
sudo dnf install -y python3

# Arch
sudo pacman -S python
```

Then re-run `./install.sh --force` to re-merge settings correctly.

---

## Hook exit codes — hooks silently block or allow everything

**Symptom:** A `pre-tool-use` hook blocks all tool calls, or never blocks anything, even when you expect it to.

**Cause:** Claude Code uses a specific exit code convention that is easy to get wrong:

| Exit code | Meaning |
|-----------|---------|
| `0` | Allow the tool call to proceed |
| `2` | Block the tool call; stdout is shown to Claude as the blocking reason (only `PreToolUse` hooks can block) |
| Any other | Non-blocking error; stderr is shown in verbose mode (`Ctrl+O`) and execution continues |

**Fix:** Check your hook's exit path:
```bash
# Block the call (PreToolUse only) — write the reason to stdout
echo "Blocked: reason"
exit 2

# Allow the call
exit 0
```

If your hook exits with `1` on failure, Claude Code will not reliably block the action. Change `exit 1` to `exit 2` in blocking conditions.

---

## Permission denied on ~/.claude directory

**Symptom:**
```
mkdir: cannot create directory '/home/user/.claude': Permission denied
```
or
```
cp: cannot create regular file '/home/user/.claude/settings.json': Permission denied
```

**Cause:** The `~/.claude` directory or its parent was created with wrong ownership (e.g. by running the installer as root previously).

**Fix:**
```bash
# Check current ownership
ls -la ~ | grep .claude

# Reclaim ownership (replace 'user' with your username)
sudo chown -R $(whoami):$(whoami) ~/.claude

# Ensure the directory is writable
chmod 700 ~/.claude
```

---

## settings.json corrupted by manual edit

**Symptom:** Claude Code fails to start, or hook/permission rules are silently ignored. Running `./install.sh --verify` reports:
```
[error] INVALID JSON: ~/.claude/settings.json
```

**Cause:** A manual edit introduced a syntax error (trailing comma, unquoted key, missing bracket).

**Diagnosis:**
```bash
python3 -m json.tool ~/.claude/settings.json
```

This prints the exact line and column of the syntax error.

> **Note:** If your settings file contains `//` comments (JSONC format, as described in [01-settings.md](01-settings.md)), `python3 -m json.tool` will report them as errors even though they are valid. Use a JSONC-aware validator instead — VS Code highlights syntax errors inline, or strip comments first with `sed '/^\s*\/\//d' ~/.claude/settings.json | python3 -m json.tool`. Note that this `sed` command only removes standalone `//` comment lines; it does not strip inline comments (e.g. `"key": "value" // comment`). If your file uses inline comments, remove them manually before validating.

**Fix:** Correct the syntax error, or restore from the installer's backup:
```bash
# List available backups
ls ~/.claude/bootstrapper-backup-*/

# Restore settings.json from the most recent backup
cp ~/.claude/bootstrapper-backup-<timestamp>/settings.json ~/.claude/settings.json
```

---

## Claude doesn't find hooks — path with spaces in username (Windows)

**Symptom:** Hooks are registered in `settings.json` but never fire. Claude reports it cannot find the hook command.

**Cause:** On Windows, if your username contains a space (e.g. `C:\Users\Jane Doe`), paths without quotes break when passed to `pwsh`.

**Fix:** Ensure the hook command in `settings.json` quotes the script path:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NonInteractive -ExecutionPolicy Bypass -File \"C:\\Users\\Jane Doe\\.claude\\hooks\\pre-tool-use.ps1\""
          }
        ]
      }
    ]
  }
}
```

Note the escaped inner quotes (`\"`) around the file path.

---

## PowerShell execution policy blocks hook scripts

**Symptom:** Hook scripts fail silently or Claude reports:
```
File ...pre-tool-use.ps1 cannot be loaded because running scripts is disabled on this system.
```

**Cause:** Windows defaults to a restrictive PowerShell execution policy (`Restricted` or `AllSigned`).

**Fix — Option A (recommended): invoke with `-ExecutionPolicy Bypass` in the hook command:**
```json
"command": "pwsh -NonInteractive -ExecutionPolicy Bypass -File \"C:\\Users\\you\\.claude\\hooks\\pre-tool-use.ps1\""
```

This bypasses the policy for this one invocation only and requires no system-wide change.

**Fix — Option B: change execution policy for the current user:**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

`RemoteSigned` allows locally written scripts to run without signing, while still requiring signatures for scripts downloaded from the internet.

---

## Bash tool freezes sporadically (Windows)

**Symptom:** A Bash tool call hangs indefinitely. This can happen at any point in a session, not just on the first call, and does not occur every time. Closing the frozen window and asking Claude to retry the command usually succeeds.

**Cause:** A UI race condition in Claude Code on Windows — if the first thing Claude does in a response is open a Bash tool window (with no text output preceding it), the terminal window can freeze. Writing any text before the Bash call prevents it.

**Primary mitigation — add a global instruction to `~/.claude/CLAUDE.md`:**

Create or edit `C:\Users\you\.claude\CLAUDE.md` and add:

```markdown
## Windows bash freeze workaround

Always output at least one line of text before making any Bash tool call.
This prevents a UI race condition where the terminal window freezes when bash
is the first operation in a response.
```

Claude will follow this instruction in every session.

**Secondary mitigation — pre-warm bash at session start (optional):**

Uncomment the bash pre-warm block in `~/.claude/hooks/session-start.ps1`. This forces an initial MSYS2 DLL load at session start, which can reduce general bash startup latency.

**If freezes persist:**
- Check whether `.bashrc` or `.bash_profile` contain slow operations (network calls, heavy path scans).
- Check whether your home directory is on a network drive — Git Bash resolves `~` on startup.

If `~/.claude/hooks/session-start.ps1` does not exist yet, re-run `.\install.ps1` to create it.

---

## Getting more help

- **Linux/macOS:** Run `./install.sh --verify` to check the health of your installation at any time.
- **Linux/macOS:** Run `./install.sh --dry-run` to preview what a re-install would change.
- **Windows:** Run `.\install.ps1 -Verify` to check the health of your installation at any time.
- **Windows:** Run `.\install.ps1 -DryRun` to preview what a re-install would change.
- See [docs/04-hooks.md](04-hooks.md) for the full hook reference including exit code behaviour.
- See [docs/01-settings.md](01-settings.md) for the full `settings.json` reference.

---

## User Guide

| Guide | Topic |
|-------|-------|
| [00-overview.md](00-overview.md) | Overview and quick start |
| [01-settings.md](01-settings.md) | settings.json permissions, model, all options |
| [02-claude-md.md](02-claude-md.md) | Writing effective CLAUDE.md instruction files |
| [03-memory.md](03-memory.md) | Persistent memory system |
| [04-hooks.md](04-hooks.md) | Shell hooks for automation and safety |
| [05-mcp-servers.md](05-mcp-servers.md) | Extending Claude with MCP tools |
| [06-slash-commands.md](06-slash-commands.md) | Custom slash commands / skills |
| [07-keybindings.md](07-keybindings.md) | Keyboard shortcuts |
| [08-plan-mode.md](08-plan-mode.md) | Structured planning before execution |
| [09-subagents.md](09-subagents.md) | Parallel and specialized subagents |
| [10-advanced-patterns.md](10-advanced-patterns.md) | Combining features for powerful workflows |
| [11-troubleshooting.md](11-troubleshooting.md) | Common problems and how to fix them |
| [12-plugins.md](12-plugins.md) | Installing and managing plugins |
| [13-voice-mode.md](13-voice-mode.md) | Voice input with push-to-talk |
| [14-scheduled-tasks.md](14-scheduled-tasks.md) | Recurring tasks with /loop and /schedule |
