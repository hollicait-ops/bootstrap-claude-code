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
