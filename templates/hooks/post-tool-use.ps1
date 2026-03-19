# PostToolUse Hook — runs after every tool call (Windows / PowerShell)
#
# Environment variables available:
#   CLAUDE_TOOL_NAME    — name of the tool that ran
#   CLAUDE_TOOL_INPUT   — JSON-encoded tool input
#   CLAUDE_TOOL_RESULT  — JSON-encoded tool result
#
# Exit code is ignored by Claude Code for PostToolUse hooks.
#
# All behaviors below are commented out — opt in by uncommenting.

$ToolName = $env:CLAUDE_TOOL_NAME
# $ToolInput  = $env:CLAUDE_TOOL_INPUT
# $ToolResult = $env:CLAUDE_TOOL_RESULT

# ── Optional: append every tool call to an audit log ─────────────────────────
# $LogFile = Join-Path $HOME ".claude\tool-audit.log"
# $stamp   = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
# Add-Content -Path $LogFile -Value "$stamp POST TOOL=$ToolName"

# ── Optional: run tests automatically after any file edit ────────────────────
# if ($ToolName -in @('Edit', 'Write')) {
#     if (Test-Path 'package.json') {
#         npm test --silent 2>$null
#     }
# }

# ── Optional: auto-format after edits (e.g., prettier) ───────────────────────
# if ($ToolName -eq 'Edit') {
#     try {
#         $inputData = $env:CLAUDE_TOOL_INPUT | ConvertFrom-Json
#         $file = $inputData.file_path
#         if ($file -and (Get-Command prettier -ErrorAction SilentlyContinue)) {
#             prettier --write $file 2>$null
#         }
#     } catch {}
# }

exit 0
