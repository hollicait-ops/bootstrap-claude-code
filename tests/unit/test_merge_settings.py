"""Unit tests for lib/merge_settings.py"""
import sys
import os
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "lib"))
from merge_settings import merge_settings

FIXTURES = os.path.join(os.path.dirname(__file__), "..", "fixtures")


def load(name):
    with open(os.path.join(FIXTURES, name)) as f:
        return json.load(f)


# ─── Scalar fields ────────────────────────────────────────────────────────────

def test_target_scalars_win_over_source():
    """Existing target scalars are never overwritten."""
    result = merge_settings(
        source={"model": "claude-opus", "theme": "light"},
        target={"model": "claude-sonnet", "theme": "dark"},
    )
    assert result["model"] == "claude-sonnet"
    assert result["theme"] == "dark"


def test_new_source_scalars_are_added():
    """Source scalars absent from target are copied in."""
    result = merge_settings(
        source={"newKey": "new-value"},
        target={"existingKey": "existing"},
    )
    assert result["newKey"] == "new-value"
    assert result["existingKey"] == "existing"


# ─── Permissions ──────────────────────────────────────────────────────────────

def test_permissions_allow_union():
    """New allow entries from source are appended."""
    result = merge_settings(
        source={"permissions": {"allow": ["Bash(git*)", "Bash(npm*)"]}},
        target={"permissions": {"allow": ["Bash(git*)"]}},
    )
    assert result["permissions"]["allow"] == ["Bash(git*)", "Bash(npm*)"]


def test_permissions_no_duplicates():
    """Entries already in target are not duplicated."""
    result = merge_settings(
        source={"permissions": {"allow": ["Bash(git*)", "Bash(npm*)"]}},
        target={"permissions": {"allow": ["Bash(git*)", "Bash(npm*)"]}},
    )
    assert result["permissions"]["allow"].count("Bash(git*)") == 1
    assert result["permissions"]["allow"].count("Bash(npm*)") == 1


def test_permissions_deny_union():
    """New deny entries from source are appended."""
    result = merge_settings(
        source={"permissions": {"deny": ["Bash(rm -rf /)"]}},
        target={"permissions": {"deny": []}},
    )
    assert "Bash(rm -rf /)" in result["permissions"]["deny"]


def test_permissions_ask_union():
    """New ask entries from source are appended; existing preserved."""
    result = merge_settings(
        source={"permissions": {"ask": ["Bash(curl*)"]}},
        target={"permissions": {"ask": ["Bash(git push*)"]}},
    )
    assert "Bash(git push*)" in result["permissions"]["ask"]
    assert "Bash(curl*)" in result["permissions"]["ask"]


def test_permissions_created_when_absent_in_target():
    """A permissions block is created in target when missing."""
    result = merge_settings(
        source={"permissions": {"allow": ["Bash(ls*)"]}},
        target={},
    )
    assert result["permissions"]["allow"] == ["Bash(ls*)"]


def test_target_without_permissions_uses_fixture():
    src = load("settings_source.json")
    tgt = load("settings_target_no_permissions.json")
    result = merge_settings(src, tgt)
    assert "Bash(npm*)" in result["permissions"]["allow"]


# ─── Hooks ────────────────────────────────────────────────────────────────────

def test_new_hook_events_added_from_source():
    """Hook events in source but not in target are added."""
    result = merge_settings(
        source={"hooks": {"PreToolUse": [{"matcher": "*", "hooks": []}]}},
        target={"hooks": {"PostToolUse": [{"hooks": []}]}},
    )
    assert "PreToolUse" in result["hooks"]
    assert "PostToolUse" in result["hooks"]


def test_existing_hook_events_not_overwritten():
    """Hook events already in target are not replaced by source."""
    original_handler = [{"hooks": [{"type": "command", "command": "echo target"}]}]
    result = merge_settings(
        source={"hooks": {"PostToolUse": [{"hooks": [{"type": "command", "command": "echo source"}]}]}},
        target={"hooks": {"PostToolUse": original_handler}},
    )
    assert result["hooks"]["PostToolUse"][0]["hooks"][0]["command"] == "echo target"


def test_hooks_created_when_absent_in_target():
    """A hooks block is created in target when missing."""
    result = merge_settings(
        source={"hooks": {"Stop": [{"hooks": []}]}},
        target={},
    )
    assert "Stop" in result["hooks"]


# ─── Fixture-based round-trip ─────────────────────────────────────────────────

def test_fixture_merge():
    """Full fixture merge produces expected shape."""
    src = load("settings_source.json")
    tgt = load("settings_target.json")
    result = merge_settings(src, tgt)

    # Target scalars win
    assert result["model"] == "claude-sonnet-4"
    assert result["theme"] == "dark"
    # Source-only scalar added
    assert result["newScalar"] == "from-source"
    # Permissions unioned
    assert "Bash(git*)" in result["permissions"]["allow"]
    assert "Bash(npm*)" in result["permissions"]["allow"]
    assert "Bash(curl*)" in result["permissions"]["ask"]
    assert "Bash(git push*)" in result["permissions"]["ask"]
    assert "Bash(rm -rf /)" in result["permissions"]["deny"]
    # Hooks merged
    assert "PreToolUse" in result["hooks"]
    assert "PostToolUse" in result["hooks"]


def test_source_not_mutated():
    """merge_settings does not modify the source dict."""
    src = {"permissions": {"allow": ["Bash(git*)"]}}
    tgt = {"permissions": {"allow": ["Bash(npm*)"]}}
    src_copy = json.loads(json.dumps(src))
    merge_settings(src, tgt)
    assert src == src_copy


def test_target_not_mutated():
    """merge_settings does not modify the target dict."""
    src = {"permissions": {"allow": ["Bash(git*)"]}}
    tgt = {"permissions": {"allow": ["Bash(npm*)"]}}
    tgt_copy = json.loads(json.dumps(tgt))
    merge_settings(src, tgt)
    assert tgt == tgt_copy
