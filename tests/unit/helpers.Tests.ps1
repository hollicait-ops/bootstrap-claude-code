#Requires -Modules Pester
# Unit tests for lib/helpers.ps1
# Run with: Invoke-Pester tests/unit/helpers.Tests.ps1

# DryRun, Unattended, Force are set in test scope and read by helper functions
# (Invoke-Dry, Confirm-Action) via caller-scope variable lookup — not a bug.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    $script:ProjectDir  = Resolve-Path (Join-Path $PSScriptRoot "../..")
    $script:FixturesDir = Join-Path $script:ProjectDir "tests/fixtures"
    . (Join-Path $script:ProjectDir "lib/helpers.ps1")
}

# ─── Write-Utf8 ──────────────────────────────────────────────────────────────

Describe "Write-Utf8" {
    It "writes file content correctly" {
        $tmp = [System.IO.Path]::GetTempFileName()
        Write-Utf8 $tmp "hello world"
        Get-Content $tmp -Raw | Should -Be "hello world"
        Remove-Item $tmp
    }

    It "writes UTF-8 without BOM" {
        $tmp = [System.IO.Path]::GetTempFileName()
        Write-Utf8 $tmp "test"
        $bytes = [System.IO.File]::ReadAllBytes($tmp)
        # UTF-8 BOM is 0xEF 0xBB 0xBF — must not be present
        $bytes[0] | Should -Not -Be 0xEF
        Remove-Item $tmp
    }

    It "overwrites existing content" {
        $tmp = [System.IO.Path]::GetTempFileName()
        Write-Utf8 $tmp "original"
        Write-Utf8 $tmp "replacement"
        Get-Content $tmp -Raw | Should -Be "replacement"
        Remove-Item $tmp
    }
}

# ─── Set-ObjProp ─────────────────────────────────────────────────────────────

Describe "Set-ObjProp" {
    It "adds a new property" {
        $obj = [PSCustomObject]@{}
        Set-ObjProp $obj "NewProp" "value"
        $obj.NewProp | Should -Be "value"
    }

    It "updates an existing property" {
        $obj = [PSCustomObject]@{ ExistingProp = "original" }
        Set-ObjProp $obj "ExistingProp" "updated"
        $obj.ExistingProp | Should -Be "updated"
    }

    It "handles array values" {
        $obj = [PSCustomObject]@{}
        Set-ObjProp $obj "Items" @("a", "b")
        $obj.Items | Should -Be @("a", "b")
    }
}

# ─── Invoke-Dry ──────────────────────────────────────────────────────────────

Describe "Invoke-Dry" {
    It "executes action when DryRun is false" {
        $DryRun = $false
        $script:executed = $false
        Invoke-Dry "test action" { $script:executed = $true }
        $script:executed | Should -Be $true
    }

    It "skips action when DryRun is true" {
        $DryRun = $true
        $script:executed = $false
        Invoke-Dry "test action" { $script:executed = $true }
        $script:executed | Should -Be $false
    }
}

# ─── Confirm-Action ──────────────────────────────────────────────────────────

Describe "Confirm-Action" {
    It "returns true when Unattended is set" {
        $Unattended = $true
        $Force = $false
        Confirm-Action "Proceed?" | Should -Be $true
    }

    It "returns true when Force is set" {
        $Unattended = $false
        $Force = $true
        Confirm-Action "Proceed?" | Should -Be $true
    }

    # The interactive N path (user types "N" or presses Enter at the [y/N] prompt)
    # returns $false. This path is not covered by an automated test because
    # Confirm-Action uses Read-Host, which reads directly from the PowerShell
    # console host rather than from stdin — stdin redirection or mocking via
    # $Input does not work. The behaviour is: any reply that does not match
    # '^[Yy]$' (including empty string, "n", "N", or any other text) causes
    # Confirm-Action to return $false.
    # TODO: If helpers.ps1 is ever refactored to accept a -Reader scriptblock
    # parameter the N path can be unit-tested without a real interactive session.
}

# ─── Get-WinPkgManager ───────────────────────────────────────────────────────

Describe "Get-WinPkgManager" {
    It "returns a known value" {
        Get-WinPkgManager | Should -BeIn @("winget", "choco", "scoop", "unknown")
    }
}

# ─── Merge-SettingsJson ──────────────────────────────────────────────────────

Describe "Merge-SettingsJson" {
    BeforeAll {
        $script:Src = Join-Path $script:FixturesDir "settings_source.json"
        $script:Tgt = Join-Path $script:FixturesDir "settings_target.json"
        $script:TgtNoPerm = Join-Path $script:FixturesDir "settings_target_no_permissions.json"
    }

    It "target scalars win over source" {
        $result = Merge-SettingsJson $script:Src $script:Tgt | ConvertFrom-Json
        $result.model | Should -Be "claude-sonnet-4"
        $result.theme | Should -Be "dark"
    }

    It "source-only scalar is added to result" {
        $result = Merge-SettingsJson $script:Src $script:Tgt | ConvertFrom-Json
        $result.newScalar | Should -Be "from-source"
    }

    It "allow lists are unioned without duplicates" {
        $result = Merge-SettingsJson $script:Src $script:Tgt | ConvertFrom-Json
        $allow = [string[]]$result.permissions.allow
        ($allow | Where-Object { $_ -eq "Bash(git*)" }) | Should -Not -BeNullOrEmpty
        ($allow | Where-Object { $_ -eq "Bash(npm*)" }) | Should -Not -BeNullOrEmpty
        ($allow | Where-Object { $_ -eq "Bash(git*)" }).Count | Should -Be 1
    }

    It "deny entries from source added to empty target deny list" {
        $result = Merge-SettingsJson $script:Src $script:Tgt | ConvertFrom-Json
        $deny = [string[]]$result.permissions.deny
        ($deny | Where-Object { $_ -eq "Bash(rm -rf /)" }) | Should -Not -BeNullOrEmpty
    }

    It "ask lists are unioned" {
        $result = Merge-SettingsJson $script:Src $script:Tgt | ConvertFrom-Json
        $ask = [string[]]$result.permissions.ask
        ($ask | Where-Object { $_ -eq "Bash(git push*)" }) | Should -Not -BeNullOrEmpty
        ($ask | Where-Object { $_ -eq "Bash(curl*)" }) | Should -Not -BeNullOrEmpty
    }

    It "new hook events from source are added" {
        $result = Merge-SettingsJson $script:Src $script:Tgt | ConvertFrom-Json
        $result.hooks.PSObject.Properties.Name | Should -Contain "PreToolUse"
        $result.hooks.PSObject.Properties.Name | Should -Contain "PostToolUse"
    }

    It "existing hook events in target are not overwritten" {
        $result = Merge-SettingsJson $script:Src $script:Tgt | ConvertFrom-Json
        $postHook = @($result.hooks.PostToolUse)[0].hooks[0].command
        $postHook | Should -Be "echo post"
    }

    It "permissions block created when absent in target" {
        $result = Merge-SettingsJson $script:Src $script:TgtNoPerm | ConvertFrom-Json
        @($result.permissions.allow) | Should -Contain "Bash(npm*)"
    }

    It "returns valid JSON" {
        { Merge-SettingsJson $script:Src $script:Tgt | ConvertFrom-Json } | Should -Not -Throw
    }
}

# ─── Merge-KeybindingsJson ───────────────────────────────────────────────────

Describe "Merge-KeybindingsJson" {
    BeforeAll {
        $script:KbSrc = Join-Path $script:FixturesDir "keybindings_source.json"
        $script:KbTgt = Join-Path $script:FixturesDir "keybindings_target.json"
    }

    It "existing key slot is not overwritten" {
        # Avoid @() pipeline wrap — ConvertFrom-Json already returns System.Object[] in PS 5.1
        $result = Merge-KeybindingsJson $script:KbSrc $script:KbTgt | ConvertFrom-Json
        ($result | Where-Object { $_.key -eq "ctrl+a" }).command | Should -Be "custom-cmd-a"
    }

    It "new bindings from source are added" {
        $result = Merge-KeybindingsJson $script:KbSrc $script:KbTgt | ConvertFrom-Json
        ($result | Where-Object { $_.key -eq "ctrl+b" }) | Should -Not -BeNullOrEmpty
        ($result | Where-Object { $_.key -eq "ctrl+c" }) | Should -Not -BeNullOrEmpty
    }

    It "target bindings come before appended source bindings" {
        $result = Merge-KeybindingsJson $script:KbSrc $script:KbTgt | ConvertFrom-Json
        $result[0].key | Should -Be "ctrl+a"
    }

    It "result contains correct total count" {
        $result = Merge-KeybindingsJson $script:KbSrc $script:KbTgt | ConvertFrom-Json
        @($result).Count | Should -Be 3
    }

    It "returns valid JSON" {
        { Merge-KeybindingsJson $script:KbSrc $script:KbTgt | ConvertFrom-Json } | Should -Not -Throw
    }
}
