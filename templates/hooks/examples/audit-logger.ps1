# Audit Logger Hook — logs every tool call and result to a file (Windows / PowerShell)
#
# Installation:
#   1. Copy this file to: C:\Users\you\.claude\hooks\audit-logger.ps1
#   2. Register it in ~/.claude/settings.json for PreToolUse and PostToolUse:
#
#      "PreToolUse":  [{"matcher":"*","hooks":[{"type":"command","command":"pwsh -NonInteractive -ExecutionPolicy Bypass -File \"C:\\Users\\you\\.claude\\hooks\\audit-logger.ps1\""}]}]
#      "PostToolUse": [{"matcher":"*","hooks":[{"type":"command","command":"pwsh -NonInteractive -ExecutionPolicy Bypass -File \"C:\\Users\\you\\.claude\\hooks\\audit-logger.ps1\""}]}]
#
# The log file is created at $HOME\.claude\tool-audit.log
# Each line: ISO timestamp, hook phase (PRE/POST), tool name, and truncated input.

$LogFile  = Join-Path $HOME ".claude\tool-audit.log"
$ToolName  = $env:CLAUDE_TOOL_NAME
$ToolInput = $env:CLAUDE_TOOL_INPUT
$HookName  = $env:CLAUDE_HOOK_NAME  # "PreToolUse" or "PostToolUse"

$phase = if ($HookName -eq 'PreToolUse') { 'PRE ' } else { 'POST' }
$stamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')

# Truncate input to 200 chars to keep log lines readable
$inputPreview = if ($ToolInput.Length -gt 200) { $ToolInput.Substring(0, 200) + '...' } else { $ToolInput }
# Collapse whitespace for compactness
$inputPreview = $inputPreview -replace '\s+', ' '

Add-Content -Path $LogFile -Value "$stamp $phase TOOL=$ToolName INPUT=$inputPreview"

exit 0
