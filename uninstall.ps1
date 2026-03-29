#Requires -Version 5.1
# uninstall.ps1 -- Claude Code Bootstrapper Removal (Windows)
#
# Removes all files installed by install.ps1 and optionally restores a backup.
# Usage: .\uninstall.ps1 [-RestoreBackup <path>] [-DryRun]
#
# For macOS / Linux / WSL use: ./uninstall.sh

param(
    [string]$RestoreBackup = "",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$ClaudeDir   = Join-Path $HOME ".claude"
$VersionFile = Join-Path $ClaudeDir ".bootstrapper-version"

# --- Logging ------------------------------------------------------------------

function Log     ([string]$Msg) { Write-Host "[info]  $Msg" -ForegroundColor Cyan }
function Ok      ([string]$Msg) { Write-Host "[ok]    $Msg" -ForegroundColor Green }
function Warn    ([string]$Msg) { Write-Host "[warn]  $Msg" -ForegroundColor Yellow }
function Err     ([string]$Msg) { Write-Host "[error] $Msg" -ForegroundColor Red }
function Heading ([string]$Msg) { Write-Host "`n$Msg" -ForegroundColor White }

function Invoke-Dry ([string]$Description, [scriptblock]$Action) {
    if ($DryRun) {
        Write-Host "[dry-run] Would: $Description" -ForegroundColor Yellow
    } else {
        & $Action
    }
}

# Write a string to a file as UTF-8 without BOM
function Write-Utf8 ([string]$Path, [string]$Content) {
    $enc = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

# --- Header -------------------------------------------------------------------

Write-Host "Claude Code Bootstrapper -- Uninstall (Windows)" -ForegroundColor White
Write-Host "------------------------------------------------"

if ($DryRun) {
    Write-Host "DRY RUN MODE -- no changes will be made`n" -ForegroundColor Yellow
}

if (-not (Test-Path $VersionFile)) {
    Warn "No bootstrapper installation found (missing $VersionFile)."
    Warn "Files may still exist and will be processed below."
}

# Files installed by install.ps1
$installedFiles = @(
    (Join-Path $ClaudeDir "settings.json"),
    (Join-Path $ClaudeDir "CLAUDE.md"),
    (Join-Path $ClaudeDir "keybindings.json"),
    (Join-Path $ClaudeDir "memory\MEMORY.md"),
    (Join-Path $ClaudeDir "hooks\pre-tool-use.ps1"),
    (Join-Path $ClaudeDir "hooks\post-tool-use.ps1"),
    (Join-Path $ClaudeDir "hooks\session-start.ps1"),
    (Join-Path $ClaudeDir "hooks\stop.ps1"),
    (Join-Path $ClaudeDir "commands\commit.md"),
    (Join-Path $ClaudeDir "commands\review-pr.md"),
    (Join-Path $ClaudeDir "commands\security-check.md"),
    (Join-Path $ClaudeDir "commands\daily-standup.md"),
    (Join-Path $ClaudeDir "commands\fix-bug.md"),
    $VersionFile
)

# -- Option A: Restore from backup ---------------------------------------------

if ($RestoreBackup) {
    Heading "Restoring from backup: $RestoreBackup"

    if (-not (Test-Path $RestoreBackup -PathType Container)) {
        Err "Backup directory not found: $RestoreBackup"
        exit 1
    }

    # Remove current bootstrapper files first
    foreach ($f in $installedFiles) {
        if (Test-Path $f -PathType Leaf) {
            Invoke-Dry "Remove $f" { Remove-Item $f -Force }
            Ok "Removed: $f"
        }
    }

    # Restore backed-up items
    foreach ($item in (Get-ChildItem $RestoreBackup)) {
        $dst = Join-Path $ClaudeDir $item.Name
        if ($item.PSIsContainer) {
            Invoke-Dry "Restore directory ~/.claude/$($item.Name)/" {
                Copy-Item $item.FullName $dst -Recurse -Force
            }
            Ok "Restored: ~/.claude/$($item.Name)/"
        } else {
            # Skip files modified after the backup was taken
            if (Test-Path $dst -PathType Leaf) {
                $currentMtime = (Get-Item $dst).LastWriteTime
                $backupMtime  = $item.LastWriteTime
                if ($currentMtime -gt $backupMtime) {
                    Warn "Skipping ~/.claude/$($item.Name) -- modified after backup was taken (remove manually to restore)"
                    continue
                }
            }
            Invoke-Dry "Restore file ~/.claude/$($item.Name)" {
                Copy-Item $item.FullName $dst -Force
            }
            Ok "Restored: ~/.claude/$($item.Name)"
        }
    }

    Ok "Restore complete."
    exit 0
}

# -- Option B: Remove bootstrapper files ---------------------------------------

Heading "Removing bootstrapper files"

# List available backups
$backups = @(Get-ChildItem $ClaudeDir -Directory -Filter "bootstrapper-backup-*" -ErrorAction SilentlyContinue)
if ($backups.Count -gt 0) {
    Write-Host ""
    Log "Available backups (to restore, re-run with -RestoreBackup <path>):"
    foreach ($b in $backups) { Write-Host "  $($b.FullName)" }
}

Write-Host ""

# Handle CLAUDE.md specially: remove only the bootstrap sentinel section
function Remove-ClaudeMdSection {
    $dst           = Join-Path $ClaudeDir "CLAUDE.md"
    $sentinelBegin = "<!-- BEGIN bootstrap-claude-code -->"
    $sentinelEnd   = "<!-- END bootstrap-claude-code -->"

    if (-not (Test-Path $dst)) { return }

    $content = Get-Content $dst -Raw

    if ($content -match [regex]::Escape($sentinelBegin)) {
        if ($DryRun) {
            Write-Host "[dry-run] Would remove bootstrap section from ~/.claude/CLAUDE.md" -ForegroundColor Yellow
            return
        }
        # Remove the sentinel block including surrounding newlines
        $pattern = '\n?' + [regex]::Escape($sentinelBegin) + '[\s\S]*?' + [regex]::Escape($sentinelEnd) + '\n?'
        $updated = ([regex]::Replace($content, $pattern, '')).Trim()
        if ($updated) {
            Write-Utf8 $dst ($updated + "`n")
            Ok "Bootstrap section removed from ~/.claude/CLAUDE.md"
        } else {
            Remove-Item $dst -Force
            Ok "CLAUDE.md was empty after removal -- deleted"
        }
    } else {
        # No sentinel found -- file was created wholesale by the installer
        Invoke-Dry "Remove ~/.claude/CLAUDE.md" { Remove-Item $dst -Force }
        Ok "Removed: ~/.claude/CLAUDE.md"
    }
}

# Remove each installed file
foreach ($f in $installedFiles) {
    if ($f -eq (Join-Path $ClaudeDir "CLAUDE.md")) {
        Remove-ClaudeMdSection
        continue
    }

    if (Test-Path $f -PathType Leaf) {
        Invoke-Dry "Remove $f" { Remove-Item $f -Force }
        Ok "Removed: $f"
    } else {
        Log "Already absent: $f"
    }
}

# Clean up empty hooks/commands directories
foreach ($dir in @((Join-Path $ClaudeDir "hooks"), (Join-Path $ClaudeDir "commands"))) {
    if ((Test-Path $dir -PathType Container) -and
        -not @(Get-ChildItem $dir -ErrorAction SilentlyContinue)) {
        Invoke-Dry "Remove empty directory $dir" { Remove-Item $dir -Force }
        Ok "Removed empty directory: $dir"
    }
}

Write-Host ""
Write-Host "Uninstall complete." -ForegroundColor Green

if ($backups.Count -gt 0) {
    Write-Host ""
    Log "To restore your previous configuration:"
    Write-Host "  .\uninstall.ps1 -RestoreBackup `"$($backups[-1].FullName)`""
}
Write-Host ""
