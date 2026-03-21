"""Unit tests for lib/merge_keybindings.py"""
import sys
import os
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "lib"))
from merge_keybindings import merge_keybindings

FIXTURES = os.path.join(os.path.dirname(__file__), "..", "fixtures")


def load(name):
    with open(os.path.join(FIXTURES, name)) as f:
        return json.load(f)


def test_new_bindings_are_added():
    """Bindings with keys absent from target are appended."""
    result = merge_keybindings(
        source=[{"key": "ctrl+b", "command": "cmd-b"}],
        target=[{"key": "ctrl+a", "command": "cmd-a"}],
    )
    assert len(result) == 2
    keys = [b["key"] for b in result]
    assert "ctrl+a" in keys
    assert "ctrl+b" in keys


def test_conflicting_binding_not_overwritten():
    """A source binding whose key already exists in target is ignored."""
    result = merge_keybindings(
        source=[{"key": "ctrl+a", "command": "source-cmd"}],
        target=[{"key": "ctrl+a", "command": "target-cmd"}],
    )
    assert len(result) == 1
    assert result[0]["command"] == "target-cmd"


def test_target_order_preserved():
    """Target bindings come first, additions come after."""
    result = merge_keybindings(
        source=[{"key": "ctrl+b", "command": "cmd-b"}],
        target=[{"key": "ctrl+a", "command": "cmd-a"}],
    )
    assert result[0]["key"] == "ctrl+a"
    assert result[1]["key"] == "ctrl+b"


def test_empty_target():
    """All source bindings are added when target is empty."""
    source = [{"key": "ctrl+a"}, {"key": "ctrl+b"}]
    result = merge_keybindings(source=source, target=[])
    assert len(result) == 2


def test_empty_source():
    """Target is returned unchanged when source is empty."""
    target = [{"key": "ctrl+a", "command": "cmd-a"}]
    result = merge_keybindings(source=[], target=target)
    assert result == target


def test_both_empty():
    result = merge_keybindings(source=[], target=[])
    assert result == []


def test_fixture_merge():
    """Fixture: ctrl+a preserved from target; ctrl+b and ctrl+c added from source."""
    src = load("keybindings_source.json")
    tgt = load("keybindings_target.json")
    result = merge_keybindings(src, tgt)

    assert len(result) == 3
    by_key = {b["key"]: b for b in result}
    assert by_key["ctrl+a"]["command"] == "custom-cmd-a"
    assert by_key["ctrl+b"]["command"] == "source-cmd-b"
    assert by_key["ctrl+c"]["command"] == "source-cmd-c"


def test_source_not_mutated():
    source = [{"key": "ctrl+a"}]
    target = []
    merge_keybindings(source, target)
    assert source == [{"key": "ctrl+a"}]


def test_target_not_mutated():
    source = [{"key": "ctrl+b"}]
    target = [{"key": "ctrl+a"}]
    merge_keybindings(source, target)
    assert target == [{"key": "ctrl+a"}]
