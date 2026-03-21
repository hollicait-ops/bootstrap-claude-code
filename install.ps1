#Requires -Version 5.1
# install.ps1 — Claude Code Bootstrapper for Windows
# Sets up best-practice ~/.claude/ configurations for new Claude Code users.
# Usage: .\install.ps1 [-DryRun] [-Force] [-Minimal] [-Unattended] [-Verify]
#
# For macOS / Linux / WSL use: ./install.sh

param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Minimal,
    [switch]$Unattended,
    [switch]$Verify
)

$ErrorActionPreference = 'Stop'

# ─── Constants ────────────────────────────────────────────────────────────────

$BootstrapperVersion = "1.0.0"
$ClaudeDir           = Join-Path $HOME ".claude"
$ScriptDir           = $PSScriptRoot
$TemplatesDir        = Join-Path $ScriptDir "templates"
$Timestamp           = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupDir           = Join-Path $ClaudeDir "bootstrapper-backup-$Timestamp"
$VersionFile         = Join-Path $ClaudeDir ".bootstrapper-version"

# Load shared helpers (Write-Utf8, Set-ObjProp, Invoke-Dry, Confirm-Action,
#                      Get-WinPkgManager, Merge-SettingsJson, Merge-KeybindingsJson)
. "$ScriptDir\lib\helpers.ps1"

# ─── Platform Guard ───────────────────────────────────────────────────────────
# $IsWindows is only defined in PowerShell 6+; PS 5.1 is Windows-only so default true.

$RunningOnWindows = if ($PSVersionTable.PSVersion.Major -ge 6) { $IsWindows } else { $true }
if (-not $RunningOnWindows) {
    Write-Host "[error] install.ps1 is for Windows only. On macOS/Linux use: ./install.sh" -ForegroundColor Red
    exit 1
}

# ─── Logging ──────────────────────────────────────────────────────────────────
# Write-Utf8, Set-ObjProp, Invoke-Dry, Confirm-Action, Get-WinPkgManager,
# Merge-SettingsJson, Merge-KeybindingsJson are provided by lib/helpers.ps1 (loaded above).

function Log     ([string]$Msg) { Write-Host "[info]  $Msg" -ForegroundColor Cyan }
function Ok      ([string]$Msg) { Write-Host "[ok]    $Msg" -ForegroundColor Green }
function Warn    ([string]$Msg) { Write-Host "[warn]  $Msg" -ForegroundColor Yellow }
function Err     ([string]$Msg) { Write-Host "[error] $Msg" -ForegroundColor Red }
function Heading ([string]$Msg) { Write-Host "`n$Msg" -ForegroundColor White }

# ─── Phase 1: Preflight Checks ────────────────────────────────────────────────

function Invoke-CheckClaude {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Ok "claude CLI found: $((Get-Command claude).Source)"
        return
    }

    Warn "claude CLI not found on PATH."
    Write-Host ""
    Write-Host "  Claude Code can be installed via:"
    Write-Host "    npm install -g @anthropic-ai/claude-code"
    Write-Host "  Or downloaded from: https://claude.ai/download"
    Write-Host ""

    if (Confirm-Action "Install Claude Code now? (requires npm/Node.js)") {
        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            Warn "npm not found. Node.js is required to install Claude Code via npm."
            if (Confirm-Action "Install Node.js via package manager?") {
                $pkgMgr = Get-WinPkgManager
                switch ($pkgMgr) {
                    "winget" { winget install OpenJS.NodeJS -e --silent }
                    "choco"  { choco install nodejs -y }
                    "scoop"  { scoop install nodejs }
                    default  {
                        Warn "No supported package manager found. Install Node.js from https://nodejs.org then re-run."
                        Warn "Continuing without Claude Code — configs will be pre-staged."
                        return
                    }
                }
            } else {
                Warn "Continuing without Claude Code — configs will be pre-staged."
                return
            }
        }
        npm install -g @anthropic-ai/claude-code
        $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
        Ok "Claude Code installed: $(if ($claudeCmd) { $claudeCmd.Source } else { 'unknown location' })"
    } else {
        Warn "Continuing without Claude Code — configs will be pre-staged for when you install it."
    }
}

function Invoke-Preflight {
    Heading "Phase 1: Preflight checks"

    # PowerShell version
    $psVer = $PSVersionTable.PSVersion
    if ($psVer.Major -ge 7) {
        Ok "PowerShell version: $psVer"
    } elseif ($psVer.Major -ge 5 -and $psVer.Minor -ge 1) {
        Ok "PowerShell version: $psVer (PowerShell 7+ recommended)"
    } else {
        Err "PowerShell 5.1 or higher is required. Found: $psVer"
        Err "Install PowerShell 7: winget install Microsoft.PowerShell"
        exit 1
    }

    # WSL detection — recommend install.sh inside WSL instead
    if ($env:WSL_DISTRO_NAME -or $env:WSLENV) {
        Warn "WSL environment detected. For WSL, use the bash installer instead:"
        Warn "  ./install.sh"
        Warn "Continuing with Windows PowerShell install..."
    }

    Ok "OS: Windows ($([System.Environment]::OSVersion.VersionString))"

    Invoke-CheckClaude

    # Home directory writability
    if (-not (Test-Path $HOME)) {
        Err "HOME directory not found: $HOME"
        exit 1
    }
    try {
        $testFile = Join-Path $HOME ".claude-bootstrap-write-test"
        [System.IO.File]::WriteAllText($testFile, "")
        Remove-Item $testFile -ErrorAction SilentlyContinue
        Ok "Home directory is writable: $HOME"
    } catch {
        Err "Home directory is not writable: $HOME"
        exit 1
    }

    # Templates directory
    if (-not (Test-Path $TemplatesDir -PathType Container)) {
        Err "Templates directory not found: $TemplatesDir"
        Err "Run this script from the bootstrap-claude-code project root."
        exit 1
    }
    Ok "Templates directory found: $TemplatesDir"

    # Existing install check
    if (Test-Path $VersionFile) {
        $existingVersion = (Get-Content $VersionFile -Raw).Trim()
        if ($existingVersion -eq $BootstrapperVersion) {
            Warn "Already installed at version $existingVersion."
            if (-not (Confirm-Action "Reinstall?")) {
                Log "Skipping. Use -Force to reinstall without prompting."
                exit 0
            }
        } else {
            Log "Upgrading from version $existingVersion -> $BootstrapperVersion"
        }
    }
}

# ─── Phase 2: Backup Existing Configs ─────────────────────────────────────────

function Invoke-Backup {
    Heading "Phase 2: Backup existing configs"

    if (-not (Test-Path $ClaudeDir -PathType Container)) {
        Log "No existing ~/.claude/ directory. Skipping backup."
        return
    }

    $backedUp      = $false
    $filesToBackup = @("settings.json", "CLAUDE.md", "keybindings.json")
    $dirsToBackup  = @("hooks", "commands", "memory")

    foreach ($f in $filesToBackup) {
        $src = Join-Path $ClaudeDir $f
        if (Test-Path $src -PathType Leaf) {
            Invoke-Dry "Backup ~/.claude/$f" {
                New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
                Copy-Item $src (Join-Path $BackupDir $f)
            }
            Ok "Backed up: ~/.claude/$f"
            $backedUp = $true
        }
    }

    foreach ($d in $dirsToBackup) {
        $src = Join-Path $ClaudeDir $d
        if (Test-Path $src -PathType Container) {
            Invoke-Dry "Backup ~/.claude/$d/" {
                New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
                Copy-Item $src (Join-Path $BackupDir $d) -Recurse
            }
            Ok "Backed up: ~/.claude/$d/"
            $backedUp = $true
        }
    }

    if ($backedUp) { Log "Backup location: $BackupDir" }
}

# ─── Phase 3: Directory Setup ─────────────────────────────────────────────────

function Invoke-SetupDirs {
    Heading "Phase 3: Setting up directory structure"

    $dirs = @(
        $ClaudeDir,
        (Join-Path $ClaudeDir "hooks"),
        (Join-Path $ClaudeDir "memory"),
        (Join-Path $ClaudeDir "commands"),
        (Join-Path $ClaudeDir "plans")
    )

    foreach ($d in $dirs) {
        Invoke-Dry "Create directory: $d" {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
        }
        Ok "Directory ready: $d"
    }
}

# ─── Phase 4: Install Templates ───────────────────────────────────────────────
# Merge-SettingsJson and Merge-KeybindingsJson are provided by lib/helpers.ps1

function Install-SettingsJson {
    $src = Join-Path $TemplatesDir "settings.json"
    $dst = Join-Path $ClaudeDir    "settings.json"

    Log "Installing settings.json..."

    if (-not (Test-Path $src)) { Warn "Template not found: $src — skipping"; return }

    if ((Test-Path $dst) -and -not $Force) {
        Log "Merging with existing settings.json"
        $merged = Merge-SettingsJson $src $dst
        if ($DryRun) {
            Write-Host "[dry-run] Would write merged settings.json to $dst" -ForegroundColor Yellow
        } else {
            Write-Utf8 $dst $merged
        }
    } else {
        Invoke-Dry "Copy settings.json to $dst" {
            Copy-Item $src $dst -Force
        }
    }
    Ok "settings.json installed"
}

function Install-ClaudeMd {
    $src           = Join-Path $TemplatesDir "CLAUDE.md"
    $dst           = Join-Path $ClaudeDir    "CLAUDE.md"
    $sentinelBegin = "<!-- BEGIN bootstrap-claude-code -->"
    $sentinelEnd   = "<!-- END bootstrap-claude-code -->"

    Log "Installing CLAUDE.md..."

    if (-not (Test-Path $src)) { Warn "Template not found: $src — skipping"; return }

    if ($DryRun) {
        Write-Host "[dry-run] Would append/update bootstrap section in $dst" -ForegroundColor Yellow
        return
    }

    $newContent = (Get-Content $src -Raw).Trim()

    if (Test-Path $dst) {
        $existing = Get-Content $dst -Raw
        if ($existing -match [regex]::Escape($sentinelBegin)) {
            # Update existing bootstrap section
            $pattern     = [regex]::Escape($sentinelBegin) + '[\s\S]*?' + [regex]::Escape($sentinelEnd)
            $replacement = "$sentinelBegin`n$newContent`n$sentinelEnd"
            $updated     = [regex]::Replace($existing, $pattern, $replacement)
            Write-Utf8 $dst $updated
            Ok "CLAUDE.md updated (existing bootstrap section replaced)"
        } else {
            # Append new bootstrap section
            $appended = $existing.TrimEnd() + "`n`n$sentinelBegin`n$newContent`n$sentinelEnd`n"
            Write-Utf8 $dst $appended
            Ok "CLAUDE.md updated (bootstrap section appended)"
        }
    } else {
        Write-Utf8 $dst "$sentinelBegin`n$newContent`n$sentinelEnd`n"
        Ok "CLAUDE.md created"
    }
}

function Install-Keybindings {
    $src = Join-Path $TemplatesDir "keybindings.json"
    $dst = Join-Path $ClaudeDir    "keybindings.json"

    Log "Installing keybindings.json..."

    if (-not (Test-Path $src)) { Warn "Template not found: $src — skipping"; return }

    if ((Test-Path $dst) -and -not $Force) {
        $merged = Merge-KeybindingsJson $src $dst
        if ($DryRun) {
            Write-Host "[dry-run] Would write merged keybindings.json to $dst" -ForegroundColor Yellow
        } else {
            Write-Utf8 $dst $merged
        }
    } else {
        Invoke-Dry "Copy keybindings.json to $dst" {
            Copy-Item $src $dst -Force
        }
    }
    Ok "keybindings.json installed"
}

function Install-Memory {
    $src = Join-Path $TemplatesDir "memory\MEMORY.md"
    $dst = Join-Path $ClaudeDir    "memory\MEMORY.md"

    Log "Installing memory/MEMORY.md..."

    if (-not (Test-Path $src)) { Warn "Template not found: $src — skipping"; return }

    if (Test-Path $dst) {
        Log "memory/MEMORY.md already exists — skipping (never overwrite user memory)"
    } else {
        Invoke-Dry "Copy MEMORY.md to $dst" {
            Copy-Item $src $dst
        }
        Ok "memory/MEMORY.md created"
    }
}

# Detect the best available PowerShell executable for hook registration
function Get-PwshExe {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) { return "pwsh" }
    return "powershell.exe"
}

function Register-HooksInSettings {
    $settingsPath = Join-Path $ClaudeDir "settings.json"
    $hooksDir     = Join-Path $ClaudeDir "hooks"
    $pwshExe      = Get-PwshExe

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    if (-not $settings.PSObject.Properties['hooks']) {
        $settings | Add-Member -MemberType NoteProperty -Name hooks -Value ([PSCustomObject]@{})
    }

    $hookMap = [ordered]@{
        PreToolUse   = 'pre-tool-use.ps1'
        PostToolUse  = 'post-tool-use.ps1'
        Stop         = 'stop.ps1'
        SessionStart = 'session-start.ps1'
    }

    foreach ($hookName in $hookMap.Keys) {
        $scriptName = $hookMap[$hookName]
        $scriptPath = Join-Path $hooksDir $scriptName
        if (-not (Test-Path $scriptPath)) { continue }

        # Quote path if it contains spaces
        $quotedPath  = if ($scriptPath -match ' ') { "`"$scriptPath`"" } else { $scriptPath }
        $hookCommand = "$pwshExe -NonInteractive -ExecutionPolicy Bypass -File $quotedPath"
        $hookEntry   = @(@{ type = "command"; command = $hookCommand })

        if (-not $settings.hooks.PSObject.Properties[$hookName]) {
            if ($hookName -in @('PreToolUse', 'PostToolUse')) {
                $settings.hooks | Add-Member -MemberType NoteProperty -Name $hookName `
                    -Value @(@{ matcher = "*"; hooks = $hookEntry })
            } else {
                $settings.hooks | Add-Member -MemberType NoteProperty -Name $hookName `
                    -Value @(@{ hooks = $hookEntry })
            }
        }
    }

    Write-Utf8 $settingsPath ($settings | ConvertTo-Json -Depth 10)
    Ok "Hooks registered in settings.json"
}

function Install-Hooks {
    if ($Minimal) { Log "Skipping hooks (-Minimal mode)"; return }

    Log "Installing hooks..."

    $hooksSrc = Join-Path $TemplatesDir "hooks"
    if (-not (Test-Path $hooksSrc -PathType Container)) {
        Warn "No hooks/ template directory found — skipping"
        return
    }

    $ps1Hooks = @(Get-ChildItem $hooksSrc -Filter "*.ps1" -ErrorAction SilentlyContinue)
    if (-not $ps1Hooks) {
        Warn "No .ps1 hook templates found in $hooksSrc — skipping"
        return
    }

    foreach ($hookFile in $ps1Hooks) {
        $dst = Join-Path $ClaudeDir "hooks\$($hookFile.Name)"
        Invoke-Dry "Copy hook $($hookFile.Name) to ~/.claude/hooks/" {
            Copy-Item $hookFile.FullName $dst -Force
        }
        Ok "Hook installed: ~/.claude/hooks/$($hookFile.Name)"
    }

    if ($DryRun) {
        Write-Host "[dry-run] Would register hooks in ~/.claude/settings.json" -ForegroundColor Yellow
    } else {
        Register-HooksInSettings
    }
}

function Install-Commands {
    if ($Minimal) { Log "Skipping commands (-Minimal mode)"; return }

    Log "Installing slash commands..."

    $commandsSrc = Join-Path $TemplatesDir "commands"
    if (-not (Test-Path $commandsSrc -PathType Container)) {
        Warn "No commands/ template directory found — skipping"
        return
    }

    foreach ($cmdFile in @(Get-ChildItem $commandsSrc -Filter "*.md")) {
        $dst = Join-Path $ClaudeDir "commands\$($cmdFile.Name)"
        if ((Test-Path $dst) -and -not $Force) {
            Log "Skipping ~/.claude/commands/$($cmdFile.Name) (already exists)"
        } else {
            Invoke-Dry "Copy $($cmdFile.Name) to ~/.claude/commands/" {
                Copy-Item $cmdFile.FullName $dst -Force
            }
            Ok "Command installed: ~/.claude/commands/$($cmdFile.Name)"
        }
    }
}

function Install-All {
    Heading "Phase 4: Installing templates"
    Install-SettingsJson
    Install-ClaudeMd
    Install-Keybindings
    Install-Memory
    Install-Hooks
    Install-Commands
}

# ─── Phase 5: Verify ──────────────────────────────────────────────────────────

function Invoke-Verify {
    Heading "Phase 5: Verification"

    $script:allOk = $true

    function Assert-Exists ([string]$Path, [string]$Label = $Path) {
        if (Test-Path $Path -PathType Leaf) {
            Ok $Label
        } else {
            Err "MISSING: $Label"
            $script:allOk = $false
        }
    }

    function Assert-ValidJson ([string]$Path, [string]$Label = $Path) {
        try {
            Get-Content $Path -Raw | ConvertFrom-Json | Out-Null
            Ok "$Label (valid JSON)"
        } catch {
            Err "INVALID JSON: $Label"
            $script:allOk = $false
        }
    }

    Assert-Exists (Join-Path $ClaudeDir "settings.json")    "~/.claude/settings.json"
    Assert-Exists (Join-Path $ClaudeDir "CLAUDE.md")         "~/.claude/CLAUDE.md"
    Assert-Exists (Join-Path $ClaudeDir "keybindings.json")  "~/.claude/keybindings.json"
    Assert-Exists (Join-Path $ClaudeDir "memory\MEMORY.md")  "~/.claude/memory/MEMORY.md"

    if (-not $Minimal) {
        Assert-Exists (Join-Path $ClaudeDir "hooks\pre-tool-use.ps1")  "~/.claude/hooks/pre-tool-use.ps1"
        Assert-Exists (Join-Path $ClaudeDir "hooks\post-tool-use.ps1") "~/.claude/hooks/post-tool-use.ps1"
        Assert-Exists (Join-Path $ClaudeDir "hooks\session-start.ps1") "~/.claude/hooks/session-start.ps1"
        Assert-Exists (Join-Path $ClaudeDir "hooks\stop.ps1")          "~/.claude/hooks/stop.ps1"
        Assert-Exists (Join-Path $ClaudeDir "commands\commit.md")      "~/.claude/commands/commit.md"
        Assert-Exists (Join-Path $ClaudeDir "commands\review-pr.md")   "~/.claude/commands/review-pr.md"
        Assert-Exists (Join-Path $ClaudeDir "commands\fix-bug.md")     "~/.claude/commands/fix-bug.md"
    }

    Assert-ValidJson (Join-Path $ClaudeDir "settings.json")   "~/.claude/settings.json"
    Assert-ValidJson (Join-Path $ClaudeDir "keybindings.json") "~/.claude/keybindings.json"

    if ($script:allOk) {
        Write-Host "`nAll checks passed." -ForegroundColor Green
    } else {
        Write-Host "`nSome checks failed. See errors above." -ForegroundColor Red
    }
    return $script:allOk
}

function Write-VersionMarker {
    if (-not $DryRun) {
        Write-Utf8 $VersionFile $BootstrapperVersion
    }
}

function Write-NextSteps {
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "  1. Open Claude Code:          claude"
    Write-Host "  2. Read the user guide:       $ScriptDir\docs\00-overview.md"
    Write-Host "  3. Customize your CLAUDE.md:  $ClaudeDir\CLAUDE.md"
    Write-Host "  4. Review permissions:        $ClaudeDir\settings.json"
    if (Test-Path $BackupDir -PathType Container) {
        Write-Host "  5. Previous configs backed up: $BackupDir"
    }
    Write-Host ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────

Write-Host "Claude Code Bootstrapper v$BootstrapperVersion (Windows)" -ForegroundColor White
Write-Host "────────────────────────────────────────────────────────"

if ($DryRun) {
    Write-Host "DRY RUN MODE — no changes will be made`n" -ForegroundColor Yellow
}

if ($Verify) {
    $ok = Invoke-Verify
    exit $(if ($ok) { 0 } else { 1 })
}

Invoke-Preflight
Invoke-Backup
Invoke-SetupDirs
Install-All
Write-VersionMarker
Invoke-Verify
Write-NextSteps
