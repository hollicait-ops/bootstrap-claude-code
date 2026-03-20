# Example: Desktop Notification on Stop — Windows / PowerShell
#
# Sends a Windows desktop notification when Claude finishes responding.
# Useful when running long tasks — step away and get notified when done.
#
# To use:
#   1. Copy to ~/.claude/hooks/stop.ps1 (or add this logic to it)
#   2. Ensure it is registered in settings.json under Stop, e.g.:
#        pwsh -NonInteractive -ExecutionPolicy Bypass -File "C:\Users\you\.claude\hooks\stop.ps1"
#
# Requirements:
#   Option A (recommended): BurntToast module — Install-Module BurntToast -Scope CurrentUser
#   Option B (built-in fallback): System.Windows.Forms balloon tip — no install required

$Title   = "Claude Code"
$Message = "Claude has finished."

# ── Option A: BurntToast toast notification (modern Windows toast) ─────────────
if (Get-Command New-BurntToastNotification -ErrorAction SilentlyContinue) {
    New-BurntToastNotification -Text $Title, $Message -Silent
    exit 0
}

# ── Option B: System.Windows.Forms balloon tip (built-in fallback) ─────────────
try {
    Add-Type -AssemblyName System.Windows.Forms
    $notify         = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon    = [System.Drawing.SystemIcons]::Information
    $notify.Visible = $true
    $notify.ShowBalloonTip(3000, $Title, $Message, [System.Windows.Forms.ToolTipIcon]::Info)
    Start-Sleep -Milliseconds 3500
    $notify.Dispose()
} catch {
    # Notification not supported in this environment — fail silently
}

exit 0
