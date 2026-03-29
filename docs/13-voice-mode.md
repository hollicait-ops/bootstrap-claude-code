# Voice Mode

Voice mode lets you dictate prompts to Claude Code using push-to-talk instead
of typing. Hold a key, speak, release — your words are transcribed and submitted.

## Availability

Voice mode is included at no extra cost for paid Claude subscribers (Pro and Max
plans). It requires a working microphone.

## Enabling Voice Mode

Add to `~/.claude/settings.json`:

```json
{
  "voiceEnabled": true
}
```

Or activate for the current session with:

```
/voice
```

## Using Push-to-Talk

Hold **Space** to record. Release to transcribe and submit.

The default keybinding is the spacebar. To rebind it, edit
`~/.claude/keybindings.json`:

```json
[
  { "key": "ctrl+space", "command": "voice:pushToTalk" }
]
```

See [07-keybindings.md](07-keybindings.md) for keybinding syntax.

## Supported Languages

Voice mode supports 20 languages:

Arabic, Chinese, Czech, Danish, Dutch, English, Finnish, French, German,
Hindi, Italian, Japanese, Korean, Norwegian, Polish, Portuguese, Russian,
Spanish, Swedish, Turkish

Set your preferred language in `settings.json`:

```json
{
  "language": "spanish"
}
```

## Tips

- Works best in a quiet environment with minimal background noise
- Speak naturally — you don't need to pause between words or spell things out
- Technical terms, file names, and code identifiers are generally transcribed
  accurately
- If a transcription is wrong, you can edit the submitted text before Claude
  processes it

---

## User Guide

| Guide | Topic |
|-------|-------|
| [00-overview.md](00-overview.md) | Overview and quick start |
| [01-settings.md](01-settings.md) | settings.json permissions, model, all options |
| [02-claude-md.md](02-claude-md.md) | Writing effective CLAUDE.md instruction files |
| [03-memory.md](03-memory.md) | Persistent memory system |
| [04-hooks.md](04-hooks.md) | Shell hooks for automation and safety |
| [05-mcp-servers.md](05-mcp-servers.md) | Extending Claude with MCP tools |
| [06-slash-commands.md](06-slash-commands.md) | Custom slash commands / skills |
| [07-keybindings.md](07-keybindings.md) | Keyboard shortcuts |
| [08-plan-mode.md](08-plan-mode.md) | Structured planning before execution |
| [09-subagents.md](09-subagents.md) | Parallel and specialized subagents |
| [10-advanced-patterns.md](10-advanced-patterns.md) | Combining features for powerful workflows |
| [11-troubleshooting.md](11-troubleshooting.md) | Common problems and how to fix them |
| [12-plugins.md](12-plugins.md) | Installing and managing plugins |
| [13-voice-mode.md](13-voice-mode.md) | Voice input with push-to-talk |
| [14-scheduled-tasks.md](14-scheduled-tasks.md) | Recurring tasks with /loop and /schedule |
