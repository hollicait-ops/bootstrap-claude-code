# lib/helpers.ps1 — Shared helper functions for install.ps1 / uninstall.ps1
# Dot-source this file: . "$PSScriptRoot\..\lib\helpers.ps1"

$script:HelpersDir = $PSScriptRoot
$script:ProjectDir = Split-Path $PSScriptRoot -Parent

# ─── UTF-8 file writing ───────────────────────────────────────────────────────
# Writes a string as UTF-8 without BOM (safe for both PS 5.1 and PS 7).
function Write-Utf8 ([string]$Path, [string]$Content) {
    $enc = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

# ─── PSCustomObject property helper ──────────────────────────────────────────
# Add or overwrite a named property on a PSCustomObject.
function Set-ObjProp ($Object, [string]$Name, $Value) {
    if ($null -ne $Object.PSObject.Properties[$Name]) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
    }
}

# ─── Dry-run wrapper ──────────────────────────────────────────────────────────
# Requires: $DryRun variable in caller scope.
function Invoke-Dry ([string]$Description, [scriptblock]$Action) {
    if ($DryRun) {
        Write-Host "[dry-run] Would: $Description" -ForegroundColor Yellow
    } else {
        & $Action
    }
}

# ─── Interactive confirmation ─────────────────────────────────────────────────
# Requires: $Unattended and $Force variables in caller scope.
function Confirm-Action ([string]$Prompt = "Continue?") {
    if ($Unattended -or $Force) { return $true }
    $reply = Read-Host "$Prompt [y/N]"
    return ($reply -match '^[Yy]$')
}

# ─── Package manager detection ───────────────────────────────────────────────
function Get-WinPkgManager {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return "winget" }
    if (Get-Command choco  -ErrorAction SilentlyContinue) { return "choco"  }
    if (Get-Command scoop  -ErrorAction SilentlyContinue) { return "scoop"  }
    return "unknown"
}

# ─── JSON merge helpers ───────────────────────────────────────────────────────
# Merge two settings.json files: source values added non-destructively to target.
# Returns merged JSON string.
# Uses an ordered hashtable as the output to avoid PS 5.1 PSCustomObject mutation
# bugs where ConvertTo-Json collapses arrays that were originally single-element
# (ConvertFrom-Json unwraps ["x"] → "x" on PS 5.1, breaking in-place reassignment).
function Merge-SettingsJson ([string]$SourcePath, [string]$TargetPath) {
    $src = Get-Content $SourcePath -Raw | ConvertFrom-Json
    $tgt = Get-Content $TargetPath -Raw | ConvertFrom-Json

    # Seed result from target (deep-clone via JSON round-trip to avoid reference aliasing)
    $result = $tgt | ConvertTo-Json -Depth 10 | ConvertFrom-Json

    # Merge permissions arrays (union, no duplicates)
    # [array] cast corrects PS 5.1's single-element JSON array unwrapping
    if ($src.permissions) {
        if (-not $result.PSObject.Properties['permissions']) {
            $result | Add-Member -MemberType NoteProperty -Name permissions -Value ([PSCustomObject]@{})
        }
        foreach ($key in @('allow', 'deny', 'ask')) {
            if ($src.permissions.$key) {
                $existing = [array]($result.permissions.$key)
                if (-not $existing) { $existing = @() }
                $toAdd    = [array]($src.permissions.$key) | Where-Object { $_ -notin $existing }
                if (-not $toAdd) { $toAdd = @() }
                $merged   = [string[]]($existing + $toAdd)
                Set-ObjProp $result.permissions $key $merged
            }
        }
    }

    # Merge hooks (add event handlers not already in target)
    if ($src.hooks) {
        if (-not $result.PSObject.Properties['hooks']) {
            $result | Add-Member -MemberType NoteProperty -Name hooks -Value ([PSCustomObject]@{})
        }
        foreach ($prop in $src.hooks.PSObject.Properties) {
            if (-not $result.hooks.PSObject.Properties[$prop.Name]) {
                $result.hooks | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value
            }
        }
    }

    # Copy top-level scalar settings absent from target
    foreach ($prop in $src.PSObject.Properties) {
        if ($prop.Name -notin @('permissions', 'hooks') -and
            -not $result.PSObject.Properties[$prop.Name]) {
            $result | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value
        }
    }

    return $result | ConvertTo-Json -Depth 10
}

# Merge keybindings: only add bindings whose key slot is unused in target.
# Returns merged JSON string.
# [array] cast corrects PS 5.1's single-element JSON array unwrapping behaviour.
function Merge-KeybindingsJson ([string]$SourcePath, [string]$TargetPath) {
    $src = [array](Get-Content $SourcePath -Raw | ConvertFrom-Json)
    $tgt = [array](Get-Content $TargetPath -Raw | ConvertFrom-Json)

    $existingKeys = $tgt | ForEach-Object { $_.key }
    $toAdd        = $src | Where-Object { $_.key -notin $existingKeys }
    $merged       = [array]$tgt + [array]$toAdd

    return $merged | ConvertTo-Json -Depth 5
}
