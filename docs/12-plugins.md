# Plugins

Plugins are installable packages that bundle slash commands, MCP servers, and
hooks into a single unit. Installing a plugin gives you all of its capabilities
at once — no manual configuration of each component.

## How It Works

A plugin is a Git-hosted package containing any combination of:

- Custom slash commands (`.claude/commands/*.md`)
- MCP server configurations
- Hook scripts

When you install a plugin, Claude Code downloads it and activates its components
in your session. You can toggle plugins on or off without uninstalling them.

## Installing Plugins

**Browse available plugins:**
```
/plugin marketplace
```

This opens the plugin marketplace where you can search and preview plugins.

**Install by name:**
```
/plugin install plugin-name@source
```

For example:
```
/plugin install formatter@anthropic-tools
```

**Install from a GitHub repo directly:**
```
/plugin marketplace add owner/repo-name
```

You'll see a trust warning before installation — review what the plugin does
before confirming.

## Configuration

Enabled plugins are stored in `settings.json`:

```json
{
  "enabledPlugins": {
    "formatter@anthropic-tools": true,
    "my-plugin@my-marketplace": true
  }
}
```

The key format is `plugin-name@marketplace-id`. Set the value to `false` to
disable a plugin without uninstalling it.

## Plugin State

Plugins that need to store data across updates have access to two environment
variables in their hook scripts and commands:

| Variable | Description |
|----------|-------------|
| `CLAUDE_PLUGIN_DATA` | Persistent storage directory for this plugin. Data here survives plugin updates. |
| `CLAUDE_PLUGIN_ROOT` | The plugin's installation directory. Use for reading bundled assets. |

## Managing Plugins

**List installed plugins and their status:**
```
/plugin list
```

**Toggle a plugin off for the current session:**
```
/plugin disable plugin-name
```

**Uninstall a plugin:**
```
/plugin uninstall plugin-name@source
```

## Security

Claude Code shows a trust warning before installing any plugin. Review the
warning and check the plugin's source repository before confirming.

For organizations:

- Admins can restrict which plugins users can install via the
  `allowedChannelPlugins` managed setting
- Blocked plugins are hidden from the marketplace for affected users
- Plugins installed before a block policy takes effect are disabled automatically

## Finding Plugins

- **Official Anthropic plugins** — available in the marketplace under `@anthropic-tools`
  and `claude-plugins-official`
- **Community plugins** — search the marketplace or browse GitHub repos that
  publish a `.claude-plugin/marketplace.json`
- **Team plugins** — your organization may maintain a private marketplace;
  ask your admin for the source to add
