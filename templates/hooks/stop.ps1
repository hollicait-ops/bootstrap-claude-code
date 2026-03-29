# Stop Hook -- runs when Claude finishes generating a response (Windows / PowerShell)
#
# Use for: completion notifications, session logging, cleanup.
#
# This hook has NO active code by default -- it does nothing until you opt in.
#
# =============================================================================
# OPTIONAL -- uncomment any section below to enable it
# =============================================================================

# -- Optional: Windows balloon tip notification (via System.Windows.Forms) -----
# NOTE: The Start-Sleep below is required -- without it, the script exits before
# the balloon tip has time to display. This is expected in a hook context where
# the process terminates immediately after the script returns.
# Add-Type -AssemblyName System.Windows.Forms
# $notify        = New-Object System.Windows.Forms.NotifyIcon
# $notify.Icon   = [System.Drawing.SystemIcons]::Information
# $notify.Visible = $true
# $notify.ShowBalloonTip(3000, "Claude Code", "Claude has finished.", [System.Windows.Forms.ToolTipIcon]::Info)
# Start-Sleep -Milliseconds 3500
# $notify.Dispose()

# -- Optional: toast notification via BurntToast module -----------------------
# (Install once with: Install-Module BurntToast -Scope CurrentUser)
# if (Get-Command New-BurntToastNotification -ErrorAction SilentlyContinue) {
#     New-BurntToastNotification -Text "Claude Code", "Claude has finished." -Silent
# }

# -- Optional: play the Windows default notification sound --------------------
# [System.Media.SystemSounds]::Exclamation.Play()

# -- Optional: log session end timestamp --------------------------------------
# $LogFile = Join-Path $HOME ".claude\session.log"
# $stamp   = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
# Add-Content -Path $LogFile -Value "$stamp STOP"

exit 0
