# x64dbg-MCP Server (duty1g/x64dbg-mcp-server)

**Repo:** https://github.com/duty1g/x64dbg-mcp-server  
**License:** MIT  
**Reviewed:** 2026-08-23  
**Stack:** Zig, x64dbg plugin API, Win32 sockets/UI, MCP Streamable HTTP + SSE, JSON-RPC 2.0  
**What it is:** A native x64dbg plugin that exposes debugger control as MCP tools over HTTP so an MCP-compatible assistant can inspect and drive x64dbg.

---

## Verdict

⚠️ **Interesting authorized-lab tool, not a casual install.** The idea is strong: a zero-dependency Zig plugin that gives MCP clients first-class debugger access, with bearer auth, a config dialog, x32/x64 builds, and a broad tool surface. The caveat is equally large: it defaults to listening on `0.0.0.0`, uses unencrypted HTTP, has 36 write/control tools including arbitrary x64dbg command execution and memory patching, ships no tests or CI, and could not be locally built here because Zig is not installed.

---

## What It Is

x64dbg-MCP Server is a Windows debugger bridge. It loads inside x64dbg, resolves debugger API symbols at runtime, starts an HTTP server on a background thread, and dispatches MCP `tools/list` and `tools/call` requests into x64dbg operations.

The tool set covers the expected reverse-engineering workflow: load or attach to a process, wait for a break, inspect registers and memory, disassemble, set breakpoints, step, scan modules, inspect imports/exports, read PE structures, trace instructions, dump memory, and patch process state.

This is explicitly high-authority tooling. A connected client can control a debugger and modify a live target process. The README includes a responsible-use disclaimer and warns not to expose the server to untrusted networks.

## Stack

| Layer | Tech |
|-------|------|
| Language | Zig, minimum declared version 0.14.0 |
| Host app | x64dbg / x32dbg plugin API |
| Platform | Windows x32 and x64 plugin DLLs (`.dp32`, `.dp64`) |
| Network | Raw WinSock HTTP server |
| Protocol | MCP 2024-11-05, Streamable HTTP, legacy SSE, JSON-RPC 2.0 |
| UI/config | Raw Win32 configuration dialog |
| Auth | Bearer token stored in `mcp_config.json` beside the x64dbg executable |
| Build | `zig build -Doptimize=ReleaseSafe --prefix dist` cross-compiles both architectures |

## Key Features

### Broad debugger tool surface

The source defines 71 MCP tools. Static scan found 36 non-read-only tools and 10 tools available even before a debug session is active. The writable/control surface includes loading binaries, attaching to PIDs, executing arbitrary x64dbg commands, run/step/stop/restart, breakpoints, register writes, memory writes, assembly, thread suspend/resume, memory allocation/free, dump-to-file operations, and patch restoration.

That breadth is the project's main value. An assistant does not need a brittle screen-control loop to use x64dbg; it can ask for debugger state and call typed tools.

### Debug-session-aware tool listing

`tools/list` hides debug-only tools until there is an active debug session and adds MCP annotations such as `readOnlyHint`. That is a useful affordance: clients see a smaller, state-appropriate tool set before a target is loaded.

### In-process x64dbg bridge

The plugin lives inside x64dbg and calls bridge/debugger APIs directly. That avoids Python/.NET sidecars and external polling processes, but also means any server bug or unsafe tool call is inside the debugger's process.

### Bearer-token configuration

The config layer auto-generates a 32-character hex token with Windows randomness on first run, persists it to `mcp_config.json`, and exposes Generate/Copy controls in the plugin dialog. Requests without `Authorization: Bearer <token>` get `401 Unauthorized`.

### Dual transport

The server supports ordinary Streamable HTTP at `/` and SSE at `/sse` with `/messages` posting for older clients. That is useful for MCP compatibility, though both modes share the same HTTP/auth exposure concerns.

## Architecture

The project is small and direct:

- `src/main.zig` registers the x64dbg plugin, menu entries, commands, and debugger callbacks, then starts the server from saved config.
- `src/core/bridge.zig` defines x64dbg SDK types and runtime symbol resolution.
- `src/core/config.zig` handles Win32 UI, token generation, config persistence, and server restart after save.
- `src/core/mcp_server.zig` implements a minimal HTTP server, CORS headers, bearer auth, MCP initialize/tools/list/tools/call, and SSE.
- `src/mcp/tools.zig` contains the tool registry, JSON schemas, and handlers.
- `src/mcp/json.zig` provides a fixed-buffer JSON writer and helpers over `std.json.Value`.

The dependency story is excellent: no package manager graph, no runtime sidecar, no Python virtualenv, and no .NET runtime.

## Security Notes

The main risk is not hidden: this server deliberately exposes debugger control over HTTP.

Important caveats:

- Default bind address is `0.0.0.0`; change it to `127.0.0.1` unless remote access is truly required.
- Transport is HTTP, not TLS. A bearer token protects requests, but the token can be observed on the network.
- CORS is `Access-Control-Allow-Origin: *`. Auth is still required, but browser-based token exposure would be dangerous.
- `ExecuteDebuggerCommand` intentionally runs arbitrary x64dbg commands.
- Several wrapper tools interpolate user-provided strings into x64dbg command syntax. Use only with trusted clients/prompts.
- The config file stores the bearer token beside the x64dbg executable; protect that directory accordingly.
- No automated tests or CI workflows were present in the reviewed tree.

## Maturity

The repository is very fresh: created 2026-08-22, with 881 stars and 89 forks at review time. GitHub reports one release, `x64dbg - v1.0`, from 2026-08-22. There are no open issues, but that is not a maturity signal for a one-day-old repository.

Local validation was limited:

- Clone and static inspection succeeded.
- Tool registry counts matched the README claim of 71 tools.
- No tests were present.
- No `.github` workflow was present.
- `zig build` was not run because this review environment does not have Zig installed.

## Comparison

| Aspect | x64dbg-MCP Server | Screen/control automation | Scripted x64dbg commands |
|--------|-------------------|---------------------------|--------------------------|
| Agent interface | MCP tools over HTTP | GUI observation/actions | Manual or script-driven commands |
| Reliability | Typed calls into debugger API | Brittle visual state | Good, but less discoverable |
| Setup | x64dbg plugin | Browser/desktop automation harness | x64dbg scripting setup |
| Safety boundary | Bearer auth + bind address | Local desktop/session permissions | Local script permissions |
| Risk | Network-exposed debugger control | UI misclicks/state drift | Script mistakes |

For authorized reverse-engineering labs, MCP is a better interface than screen scraping. For anything outside a trusted lab, the network exposure and write-capable tool set need hard containment.

## Lab Deployment Notes

Use this only in an isolated, authorized analysis environment.

- Bind to `127.0.0.1` by default.
- Use remote access only through a trusted tunnel or isolated lab network.
- Treat the bearer token like a password.
- Rotate the token after demos or shared sessions.
- Run x64dbg and MCP clients in a disposable VM when analyzing untrusted binaries.
- Prefer a client-side approval policy for write/control tools such as memory patching, command execution, process attach, dump-to-file, and run/step control.
- Build from source or verify release checksums before copying plugin files into x64dbg.

---

**Attribution:** duty1g/x64dbg-mcp-server, MIT License.
