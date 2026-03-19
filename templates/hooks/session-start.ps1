# SessionStart Hook — runs when a new Claude Code session begins (Windows / PowerShell)
#
# Use for: environment checks, welcome messages, context loading, reminders.
# All behaviors below are commented out — opt in by uncommenting.

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
