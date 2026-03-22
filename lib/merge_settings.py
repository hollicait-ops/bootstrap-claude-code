#!/usr/bin/env python3
"""Merge two settings.json files non-destructively.

Source values are added to target only where target has no entry.
Permissions arrays (allow/deny/ask) are unioned without duplicates.
Hook events present in target are preserved; new events from source are added.
Top-level scalar keys from source are copied only when absent from target.
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


def merge_settings(source: dict, target: dict) -> dict:
    """Return a new dict with source merged non-destructively into target."""
    result = dict(target)

    # Merge permissions arrays (union, preserving order, no duplicates)
    if "permissions" in source:
        if "permissions" not in result:
            result["permissions"] = {}
        else:
            result["permissions"] = dict(result["permissions"])
        for key in ("allow", "deny", "ask"):
            if key in source["permissions"]:
                existing = list(result["permissions"].get(key, []))
                additions = [r for r in source["permissions"][key] if r not in existing]
                result["permissions"][key] = existing + additions

    # Merge hooks (add event handlers that don't already exist in target)
    if "hooks" in source:
        if "hooks" not in result:
            result["hooks"] = {}
        else:
            result["hooks"] = dict(result["hooks"])
        for event, handlers in source["hooks"].items():
            if event not in result["hooks"]:
                result["hooks"][event] = handlers

    # Copy top-level scalar settings absent from target
    for key, value in source.items():
        if key not in ("permissions", "hooks") and key not in result:
            result[key] = value

    return result


if __name__ == "__main__":
    source_path, target_path = sys.argv[1], sys.argv[2]
    with open(source_path) as f:
        source = json.loads(strip_jsonc_comments(f.read()))
    with open(target_path) as f:
        target = json.loads(strip_jsonc_comments(f.read()))
    print(json.dumps(merge_settings(source, target), indent=2))
