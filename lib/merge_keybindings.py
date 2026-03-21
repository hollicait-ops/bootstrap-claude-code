#!/usr/bin/env python3
"""Merge two keybindings.json files non-destructively.

Only bindings whose key slot is not already occupied in target are added.
"""
import sys
import json


def merge_keybindings(source: list, target: list) -> list:
    """Return target with any source bindings for unused key slots appended."""
    existing_keys = {b.get("key") for b in target}
    additions = [b for b in source if b.get("key") not in existing_keys]
    return list(target) + additions


if __name__ == "__main__":
    source_path, target_path = sys.argv[1], sys.argv[2]
    with open(source_path) as f:
        source = json.load(f)
    with open(target_path) as f:
        target = json.load(f)
    print(json.dumps(merge_keybindings(source, target), indent=2))
