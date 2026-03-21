# obsidian-claude-ide (petersolopov/obsidian-claude-ide)

**Rating:** 🔥🔥🔥🔥  
**License:** MIT  
**Source:** https://github.com/petersolopov/obsidian-claude-ide  
**Reviewed:** 2026-03-21

## What It Is

Obsidian plugin that makes Claude Code treat your vault as its IDE — like the VS Code or Neovim integrations, but for Obsidian. Zero config, zero runtime dependencies, single compiled `main.js`.

**Install:** Via BRAT (`petersolopov/obsidian-claude-ide`) or manual drop into `.obsidian/plugins/claude-code-ide/`. Community plugin submission pending.

## How It Works

1. Plugin starts a **WebSocket MCP server on `127.0.0.1`** inside Obsidian
2. Writes a **lock file at `~/.claude/ide/<port>.lock`** containing port, PID, auth token (random UUID), and vault base path
3. Claude Code's **`/ide` command** scans lock files, discovers Obsidian in the selector
4. Once connected, Claude Code can see open files and current selection — it reads/edits vault files directly via filesystem (it already has that access); the plugin provides editor *context* in the other direction

Auth: each session generates a fresh UUID stored only in the lock file. Only the local Claude Code CLI process can connect. Server binds to 127.0.0.1 only — nothing exposed to network.

## MCP Tools Exposed

| Tool | Description |
|------|-------------|
| `getCurrentSelection` | Active selection right now (file path, cursor, selected text, line range) |
| `getLatestSelection` | Cached from last cursor/selection change event (100ms debounce) |
| `getOpenEditors` | All open markdown tabs with active/inactive flags |
| `getWorkspaceFolders` | Vault base path |

**Stubbed (protocol-compatible no-ops):** `openDiff`, `getDiagnostics`, `checkDocumentDirty`, `saveDocument`, `close_tab`, `executeCode` — these are VS Code-isms Claude Code expects; Obsidian can't implement them but stubs keep the protocol happy.

## "Send to Claude" Command

Fires an `at_mentioned` RPC that injects the current selection as a `@file.md:lineStart-lineEnd` reference into Claude's active context. Equivalent to manually typing `@filename.md` in Claude Code, but with exact line range.

## Protocol

Documented by `claudecode.nvim` (the Neovim integration that reverse-engineered it). Pattern is simple: any editor that can run a local WebSocket server and write a lock file gets Claude Code IDE integration.

## Codebase

```
src/
├── main.ts      # Plugin entry, WebSocket server lifecycle, selection broadcast
├── server.ts    # IdeServer: WebSocket + HTTP server wrapper
├── tools.ts     # 4 real tools + stub handlers + RPC dispatch
├── lock.ts      # Lock file create/remove/stale cleanup
├── websocket.ts # WebSocket message framing
└── log.ts       # Debug logging
```
~400 lines total. No npm runtime dependencies.

## Alternatives

- `obsidian-claude-code-mcp` (iansinnott) — heavier alternative: embedded terminal, Claude Desktop support (not just Claude Code CLI)
- `claudecode.nvim` — Neovim equivalent, also the protocol source of truth

## Relevance

- Direct use: install in Obsidian, run `claude` in terminal, `/ide` → select Obsidian — vault notes become first-class Claude Code context
- No more manually typing `@~/src/shared-vault/Research/foo.md` — open the note, Claude already knows what you're reading
- Pairs well with Ori vault (once notes are in flat structure Claude Code can edit them too)
- Install requires manual action (BRAT or file drop into `.obsidian/plugins/`) — not automatable remotely
