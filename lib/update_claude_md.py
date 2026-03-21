#!/usr/bin/env python3
"""Update or append the bootstrap sentinel section in CLAUDE.md.

The sentinel section is delimited by:
  <!-- BEGIN bootstrap-claude-code -->
  ...content...
  <!-- END bootstrap-claude-code -->

If the sentinel is present, the section is replaced in-place.
If absent, the section is appended to the end of the file.
"""
import sys
import re

BEGIN = "<!-- BEGIN bootstrap-claude-code -->"
END = "<!-- END bootstrap-claude-code -->"


def has_sentinel(content: str) -> bool:
    return BEGIN in content


def update_sentinel(content: str, new_section: str) -> str:
    """Replace an existing sentinel section with new_section."""
    pattern = re.escape(BEGIN) + r".*?" + re.escape(END)
    replacement = f"{BEGIN}\n{new_section.strip()}\n{END}"
    return re.sub(pattern, replacement, content, flags=re.DOTALL)


def append_sentinel(content: str, new_section: str) -> str:
    """Append a new sentinel section to content."""
    return content.rstrip() + f"\n\n{BEGIN}\n{new_section.strip()}\n{END}\n"


def create_with_sentinel(new_section: str) -> str:
    """Create new file content wrapping new_section in the sentinel."""
    return f"{BEGIN}\n{new_section.strip()}\n{END}\n"


def apply(dst_content: str, src_content: str) -> str:
    """Apply src_content to dst_content, updating or appending the sentinel."""
    if has_sentinel(dst_content):
        return update_sentinel(dst_content, src_content)
    return append_sentinel(dst_content, src_content)


if __name__ == "__main__":
    # Called by install.sh: dst_path src_path
    dst_path, src_path = sys.argv[1], sys.argv[2]
    with open(src_path) as f:
        new_content = f.read().strip()
    with open(dst_path) as f:
        existing = f.read()
    updated = apply(existing, new_content)
    with open(dst_path, "w") as f:
        f.write(updated)
