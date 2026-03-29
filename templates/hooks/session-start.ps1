# SessionStart Hook — runs when a new Claude Code session begins (Windows / PowerShell)
#
# Use for: environment checks, welcome messages, context loading, reminders.
#
# This hook has NO active code by default — it does nothing until you opt in.
#
# =============================================================================
# OPTIONAL — uncomment any section below to enable it
# =============================================================================

# ── Optional: pre-warm bash to prevent first-use freeze on Windows ────────────
# On Windows, the first bash process spawn (Git Bash / MSYS2) can freeze while
# loading its runtime DLLs. Warming it up at session start forces that cost to
# happen early so the first Bash tool call responds immediately.
#
# $bash = Get-Command bash -ErrorAction SilentlyContinue
# if ($bash) {
#     $job = Start-Job { bash -c "exit 0" 2>$null }
#     $null = $job | Wait-Job -Timeout 5   # give bash up to 5 s to initialize
#     $job | Remove-Job -Force
# }

# ── Optional: print a reminder if the project has a PROJECT.md ───────────────
# if (Test-Path '.claude\PROJECT.md') {
#     Write-Host "Project context available in .claude\PROJECT.md"
# }

# ── Optional: warn if there are uncommitted changes ──────────────────────────
# if (Get-Command git -ErrorAction SilentlyContinue) {
#     try {
#         $null = git rev-parse --is-inside-work-tree 2>$null
#         $changed = (git status --porcelain | Measure-Object -Line).Lines
#         if ($changed -gt 0) {
#             $root = git rev-parse --show-toplevel
#             Write-Host "You have $changed uncommitted change(s) in $root"
#         }
#     } catch {}
# }

# ── Optional: print the current git branch ───────────────────────────────────
# if (Get-Command git -ErrorAction SilentlyContinue) {
#     try {
#         $branch = git branch --show-current 2>$null
#         if ($branch) { Write-Host "Branch: $branch" }
#     } catch {}
# }

exit 0
