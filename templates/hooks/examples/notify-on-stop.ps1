# Notify on Stop Hook — shows a Windows notification when Claude finishes (Windows / PowerShell)
#
# Installation:
#   1. Copy this file to: C:\Users\you\.claude\hooks\stop.ps1
#      (or merge the relevant block into your existing stop.ps1)
#   2. Register it in ~/.claude/settings.json under the Stop hook:
#
#      "Stop": [{"hooks":[{"type":"command","command":"pwsh -NonInteractive -ExecutionPolicy Bypass -File \"C:\\Users\\you\\.claude\\hooks\\stop.ps1\""}]}]
#
# Two notification methods are provided — use whichever fits your setup.
# Method A uses BurntToast for a modern Windows 10/11 toast notification (install once).
# Method B uses only built-in Windows APIs (no extra modules required).

# ── Method A: modern toast via BurntToast module (install once, then uncomment) ──
#
# Install-Module BurntToast -Scope CurrentUser   # run once in a PowerShell window
#
# if (Get-Command New-BurntToastNotification -ErrorAction SilentlyContinue) {
#     New-BurntToastNotification -Text "Claude Code", "Claude has finished." -Silent
# }

# ── Method B: balloon tip via System.Windows.Forms (built-in, no install needed) ──
#
# NOTE: Start-Sleep is required here. Without it the script exits before the
# balloon tip has time to display, because the hook process terminates immediately.
#
Add-Type -AssemblyName System.Windows.Forms
$notify         = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon    = [System.Drawing.SystemIcons]::Information
$notify.Visible = $true
$notify.ShowBalloonTip(3000, "Claude Code", "Claude has finished.", [System.Windows.Forms.ToolTipIcon]::Info)
Start-Sleep -Milliseconds 3500
$notify.Dispose()

exit 0
