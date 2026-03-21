#Requires -Version 5.1
# tests/run-tests.ps1 — Run the full unit test suite (PowerShell)
# Usage: .\tests\run-tests.ps1

$ErrorActionPreference = 'Continue'
$ProjectDir = Split-Path $PSScriptRoot -Parent
$TestsDir   = $PSScriptRoot

$pass = 0
$fail = 0
$skip = 0

function Header ([string]$Msg) { Write-Host "`n$Msg" -ForegroundColor White }
function Pass   ([string]$Msg) { Write-Host "[pass] $Msg" -ForegroundColor Green;  $script:pass++ }
function Fail   ([string]$Msg) { Write-Host "[fail] $Msg" -ForegroundColor Red;    $script:fail++ }
function Skip   ([string]$Msg) { Write-Host "[skip] $Msg" -ForegroundColor Yellow; $script:skip++ }

# ─── Pester unit tests ───────────────────────────────────────────────────────

Header "Pester unit tests (PowerShell helpers)"

if (-not (Get-Module -ListAvailable -Name Pester)) {
    Skip "Pester module not found — install with: Install-Module Pester -Force -Scope CurrentUser"
} else {
    Import-Module Pester -MinimumVersion 5.0 -ErrorAction SilentlyContinue
    if (-not (Get-Module Pester)) {
        Skip "Pester 5.0+ required — install with: Install-Module Pester -Force -Scope CurrentUser"
    } else {
        $config = New-PesterConfiguration
        $config.Run.Path      = Join-Path $TestsDir "unit/helpers.Tests.ps1"
        $config.Output.Verbosity = "Detailed"
        $config.Run.PassThru  = $true

        $result = Invoke-Pester -Configuration $config
        if ($result.FailedCount -eq 0) {
            Pass "Pester unit tests passed ($($result.PassedCount) tests)"
        } else {
            Fail "Pester unit tests: $($result.FailedCount) failed, $($result.PassedCount) passed"
        }
    }
}

# ─── Summary ─────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Results: " -NoNewline
Write-Host "$pass passed  " -ForegroundColor Green -NoNewline
Write-Host "$fail failed  " -ForegroundColor Red -NoNewline
Write-Host "$skip skipped"  -ForegroundColor Yellow

exit $(if ($fail -gt 0) { 1 } else { 0 })
