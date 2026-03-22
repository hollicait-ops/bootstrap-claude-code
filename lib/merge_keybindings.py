#!/usr/bin/env python3
"""Merge two keybindings.json files non-destructively.

Only bindings whose key slot is not already occupied in target are added.
"""
import sys
import json


def strip_jsonc_comments(text: str) -> str:
    """Strip // line comments and /* */ block comments, respecting strings."""
    result = []
    i = 0
    in_string = False
    while i < len(text):
        if in_string:
            if text[i] == '\\' and i + 1 < len(text):
                result.append(text[i])
                result.append(text[i + 1])
                i += 2
            elif text[i] == '"':
                result.append(text[i])
                in_string = False
                i += 1
            else:
                result.append(text[i])
                i += 1
        else:
            if text[i] == '"':
                result.append(text[i])
                in_string = True
                i += 1
            elif text[i:i + 2] == '//':
                while i < len(text) and text[i] != '\n':
                    i += 1
            elif text[i:i + 2] == '/*':
                i += 2
                while i < len(text) and text[i:i + 2] != '*/':
                    i += 1
                i += 2
            else:
                result.append(text[i])
                i += 1
    return ''.join(result)


def merge_keybindings(source: list, target: list) -> list:
    """Return target with any source bindings for unused key slots appended."""
    existing_keys = {b.get("key") for b in target}
    additions = [b for b in source if b.get("key") not in existing_keys]
    return list(target) + additions


if __name__ == "__main__":
    source_path, target_path = sys.argv[1], sys.argv[2]
    with open(source_path) as f:
        source = json.loads(strip_jsonc_comments(f.read()))
    with open(target_path) as f:
        target = json.loads(strip_jsonc_comments(f.read()))
    print(json.dumps(merge_keybindings(source, target), indent=2))
