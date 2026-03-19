# PreToolUse Hook — runs before every tool call (Windows / PowerShell)
#
# Environment variables available:
#   CLAUDE_TOOL_NAME   — name of the tool about to run (e.g., "Bash")
#   CLAUDE_TOOL_INPUT  — JSON-encoded tool input
#
# Exit codes:
#   0 — allow the tool to run
#   2 — block the tool (stdout is shown to Claude as the reason)
#
# This template blocks catastrophically destructive shell commands as a
# last-resort safety net below the deny rules in settings.json.
# All other behaviors are commented out — opt in by uncommenting.

$ToolName  = $env:CLAUDE_TOOL_NAME
$ToolInput = $env:CLAUDE_TOOL_INPUT

# ── Safety guard: block catastrophically destructive commands ─────────────────
if ($ToolName -eq 'Bash') {
    $cmd = ''
    try {
        $parsed = $ToolInput | ConvertFrom-Json
        $cmd = $parsed.command
    } catch {}

    # Block: Remove-Item -Recurse targeting root drives or home directory
    if ($cmd -match 'Remove-Item\b.*-Recurse\b.*\s+([A-Z]:\\|~|\\)' -or
        $cmd -match 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+(/|~)') {
        Write-Host "BLOCKED: Attempted to recursively delete a root or home directory. This is almost certainly a mistake."
        exit 2
    }

    # Block: Format-Volume or diskpart targeting whole drives
    if ($cmd -match '\bFormat-Volume\b' -or $cmd -match '\bdiskpart\b') {
        Write-Host "BLOCKED: Attempted to format a disk volume. This requires explicit manual execution."
        exit 2
    }
}

# ── Optional: log every tool call to an audit file ───────────────────────────
# $LogFile  = Join-Path $HOME ".claude\tool-audit.log"
# $stamp    = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
# Add-Content -Path $LogFile -Value "$stamp PRE  TOOL=$ToolName"

# ── Optional: require confirmation before any npm publish ────────────────────
# if ($ToolName -eq 'Bash' -and $cmd -match 'npm publish') {
#     $reply = Read-Host "About to run: $cmd  — Continue? [y/N]"
#     if ($reply -notmatch '^[Yy]$') { Write-Host "Cancelled by user."; exit 2 }
# }

exit 0
