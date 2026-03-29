# Example: Audit Logger (PostToolUse) -- Windows / PowerShell
#
# Logs every tool call to ~/.claude/tool-audit.log with timestamp, tool name,
# and (for Bash tools) the command that was run.
#
# To use:
#   1. Copy to ~/.claude/hooks/post-tool-use.ps1 (or add this logic to it)
#   2. Ensure it is registered in settings.json under PostToolUse
#   3. Register it with a pwsh invocation, e.g.:
#        pwsh -NonInteractive -ExecutionPolicy Bypass -File "C:\Users\you\.claude\hooks\post-tool-use.ps1"

$ToolName  = $env:CLAUDE_TOOL_NAME
$ToolInput = $env:CLAUDE_TOOL_INPUT  # JSON-encoded input arguments for the tool call that triggered this hook
$LogFile   = Join-Path $HOME ".claude\tool-audit.log"
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$Extra = ""

# For Bash tools, log the first line of the command (up to 120 chars)
if ($ToolName -eq "Bash" -and $ToolInput) {
    try {
        $parsed = $ToolInput | ConvertFrom-Json
        $cmd = ($parsed.command -split "`n")[0]
        if ($cmd.Length -gt 120) { $cmd = $cmd.Substring(0, 120) }
        if ($cmd) { $Extra = " CMD=$cmd" }
    } catch {}
}

# For Edit/Write tools, log the file path
if ($ToolName -in @("Edit", "Write") -and $ToolInput) {
    try {
        $parsed  = $ToolInput | ConvertFrom-Json
        $filePath = $parsed.file_path
        if ($filePath) { $Extra = " FILE=$filePath" }
    } catch {}
}

Add-Content -Path $LogFile -Value "${Timestamp} TOOL=${ToolName}${Extra}"

exit 0
