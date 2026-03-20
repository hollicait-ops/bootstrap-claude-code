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
| `2` | Block the tool call (Claude sees an error message) |
| Any other | Treated as an error; tool may still run |

**Fix:** Check your hook's exit path:
```bash
# Block the call
echo "Blocked: reason" >&2
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

## Getting more help

- Run `./install.sh --verify` to check the health of your installation at any time.
- Run `./install.sh --dry-run` to preview what a re-install would change.
- See [docs/04-hooks.md](04-hooks.md) for the full hook reference including exit code behaviour.
- See [docs/01-settings.md](01-settings.md) for the full `settings.json` reference.
