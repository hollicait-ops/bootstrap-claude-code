"""Unit tests for lib/update_claude_md.py"""
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "lib"))
from update_claude_md import (
    BEGIN,
    END,
    has_sentinel,
    update_sentinel,
    append_sentinel,
    create_with_sentinel,
    apply,
)

FIXTURES = os.path.join(os.path.dirname(__file__), "..", "fixtures")


def load(name):
    with open(os.path.join(FIXTURES, name)) as f:
        return f.read()


# ─── has_sentinel ─────────────────────────────────────────────────────────────

def test_has_sentinel_true_when_present():
    assert has_sentinel(f"{BEGIN}\nsome content\n{END}") is True


def test_has_sentinel_false_when_absent():
    assert has_sentinel("# CLAUDE.md\n\nSome content.") is False


def test_has_sentinel_false_empty_string():
    assert has_sentinel("") is False


# ─── update_sentinel ──────────────────────────────────────────────────────────

def test_update_sentinel_replaces_content():
    content = f"# Header\n\n{BEGIN}\nOld content.\n{END}\n\nFooter."
    result = update_sentinel(content, "New content.")
    assert "Old content." not in result
    assert "New content." in result


def test_update_sentinel_preserves_surrounding_text():
    content = f"# Header\n\n{BEGIN}\nOld.\n{END}\n\nFooter."
    result = update_sentinel(content, "New.")
    assert "# Header" in result
    assert "Footer." in result


def test_update_sentinel_handles_multiline_old_content():
    old = "Line 1\nLine 2\nLine 3"
    content = f"{BEGIN}\n{old}\n{END}"
    result = update_sentinel(content, "Replacement.")
    assert "Line 1" not in result
    assert "Replacement." in result


def test_update_sentinel_wraps_with_sentinels():
    content = f"{BEGIN}\nOld.\n{END}"
    result = update_sentinel(content, "New.")
    assert result.startswith(BEGIN)
    assert END in result


# ─── append_sentinel ─────────────────────────────────────────────────────────

def test_append_sentinel_adds_section():
    content = "# Existing content."
    result = append_sentinel(content, "Bootstrap section.")
    assert "Bootstrap section." in result
    assert BEGIN in result
    assert END in result


def test_append_sentinel_preserves_existing_content():
    content = "# Existing content."
    result = append_sentinel(content, "Bootstrap section.")
    assert "# Existing content." in result


def test_append_sentinel_new_section_comes_after():
    content = "# Existing."
    result = append_sentinel(content, "Bootstrap.")
    assert result.index("# Existing.") < result.index(BEGIN)


# ─── create_with_sentinel ─────────────────────────────────────────────────────

def test_create_with_sentinel_wraps_content():
    result = create_with_sentinel("Hello world.")
    assert BEGIN in result
    assert END in result
    assert "Hello world." in result


def test_create_with_sentinel_ends_with_newline():
    result = create_with_sentinel("Content.")
    assert result.endswith("\n")


# ─── apply ───────────────────────────────────────────────────────────────────

def test_apply_updates_when_sentinel_exists():
    dst = f"# Header\n\n{BEGIN}\nOld.\n{END}\n"
    result = apply(dst, "New content.")
    assert "Old." not in result
    assert "New content." in result


def test_apply_appends_when_no_sentinel():
    dst = "# Header\n\nExisting."
    result = apply(dst, "Bootstrap.")
    assert "Existing." in result
    assert "Bootstrap." in result
    assert BEGIN in result


# ─── Fixture-based tests ─────────────────────────────────────────────────────

def test_apply_fixture_no_sentinel():
    dst = load("claude_md_no_sentinel.md")
    src = load("claude_md_source.md").strip()
    result = apply(dst, src)
    assert "Some existing content here." in result
    assert "Bootstrap Instructions" in result
    assert BEGIN in result
    assert END in result


def test_apply_fixture_with_sentinel():
    dst = load("claude_md_with_sentinel.md")
    src = load("claude_md_source.md").strip()
    result = apply(dst, src)
    assert "Old bootstrap content." not in result
    assert "Bootstrap Instructions" in result
    # Should not duplicate the sentinel
    assert result.count(BEGIN) == 1
    assert result.count(END) == 1


def test_apply_fixture_with_sentinel_preserves_content_after():
    dst = load("claude_md_with_sentinel.md")
    result = apply(dst, "Replacement.")
    assert "Content after sentinel." in result
