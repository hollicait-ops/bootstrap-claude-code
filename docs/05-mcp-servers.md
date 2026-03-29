# MCP Servers

The Model Context Protocol (MCP) is an open standard that lets Claude connect
to external tools and data sources. MCP servers extend Claude Code with
capabilities beyond the built-in tools.

## How It Works

An MCP server is a process that exposes tools to Claude via a standardized
protocol. Claude Code launches the server, discovers its tools, and can call
them just like built-in tools (Bash, Read, Edit, etc.).

Popular MCP servers provide access to: GitHub, Jira, Slack, web search,
databases, file systems, and more.

## Configuration

MCP servers are configured in `settings.json` under `mcpServers`, or in a
project-local `.mcp.json` file at the project root.

**Global (`~/.claude/settings.json`):**
```json
{
  "mcpServers": {
    "server-name": {
      "command": "command-to-run",
      "args": ["arg1", "arg2"],
      "env": {
        "API_KEY": "your-key"
      }
    }
  }
}
```

**Project-local (`.mcp.json` in project root):**
```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@some/mcp-server"]
    }
  }
}
```

Project-local servers are added on top of global ones for that project.

## Setting Up Common MCP Servers

### Filesystem Server

Gives Claude access to a specific directory with explicit path scoping:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/you/documents",
        "/Users/you/projects"
      ]
    }
  }
}
```

Claude can read/write files in the listed directories. Good for giving Claude
access to a notes directory or a specific project without broad filesystem access.

### GitHub Server

Lets Claude create issues, PRs, and browse repositories via the GitHub API:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here"
      }
    }
  }
}
```

Required token scopes: `repo`, `read:org` (for org repos).

**Security note:** Store the token in your shell environment and reference it:
```json
"env": {"GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"}
```

### Web Search Server (Brave Search)

Lets Claude search the web for current information:

```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "your-brave-api-key"
      }
    }
  }
}
```

Get a free API key at https://api.search.brave.com

### PostgreSQL Server

Lets Claude query your database (read-only or read-write depending on credentials):

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://user:password@localhost/dbname"
      ]
    }
  }
}
```

Use a read-only database user for safety.

## Managing MCP Servers

Check server status and available tools in a Claude session:

```
/mcp
```

This shows connected servers, their tools, and connection status.

If a server disconnects or fails to authenticate:

```
/mcp reconnect server-name
```

For OAuth-based servers, re-authenticate with:

```
/mcp auth server-name
```

## Security Considerations

MCP servers run with the permissions of your current user. Before installing
an MCP server:

1. **Check the source** — prefer servers from `@modelcontextprotocol/` or
   well-known publishers
2. **Scope access tightly** — filesystem servers should only get the directories
   they need
3. **Use read-only credentials** where possible (database users, API tokens with
   minimal scopes)
4. **Never put credentials directly in settings files** that are committed to git

## Finding MCP Servers

- Official servers: https://github.com/modelcontextprotocol/servers
- Community registry: https://mcp.so
- npm: search `@modelcontextprotocol/server-*`

## MCP Elicitation

Some MCP servers can pause mid-task and ask you for input — credentials, a
choice between options, a URL to open in your browser, or any other structured
data the server needs to continue.

When elicitation occurs:
1. An interactive dialog appears with the server's request
2. The current task is paused until you respond
3. Your input is sent back to the server and the task resumes

**Example:** A database MCP server might elicit your password on first
connection rather than requiring it in settings. A GitHub server might request
OAuth authorization the first time it needs to write to a repo.

For hook authors, two events are available:

| Event | When |
|-------|------|
| `Elicitation` | When the MCP server sends an elicitation request |
| `ElicitationResult` | When the user submits their response |

These can be used for logging or to pre-fill responses automatically.

## Troubleshooting

**Server not connecting**
- Run `claude --verbose` to see the server startup output
- Check the `command` and `args` are correct (test the command manually in a terminal)

**Tools not appearing**
- Run `/mcp` to check server status
- Some servers require authentication before tools are available

**Authentication failures**
- Verify the API key or token in the `env` section
- Check token scopes and expiration

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
