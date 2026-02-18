# Pattern: Persistent Headless Chrome via CLI

**Source:** [simonw/rodney](https://github.com/simonw/rodney) (Apache 2.0)
**Author:** Simon Willison

## Core Idea

Instead of running a daemon that wraps Chrome, make Chrome itself the persistent process. Each CLI invocation is a short-lived process that:

1. Reads a state file (`state.json`) containing the WebSocket debug URL
2. Connects to Chrome via CDP over WebSocket
3. Executes the command
4. Disconnects (Chrome stays running)

## State File

```json
{
  "debug_url": "ws://127.0.0.1:PORT/devtools/browser/UUID",
  "chrome_pid": 12345,
  "active_page": 0,
  "data_dir": "~/.rodney/chrome-data"
}
```

## Key Implementation Details

- Launch Chrome with `Leakless(false)` (rod-specific) so Chrome survives after launcher exits
- Multiple clients can connect to the same Chrome instance simultaneously
- Pages/tabs persist between connections
- Directory-scoped sessions (`--local`) for per-project isolation

## Exit Code Convention for Scriptability

```
0 = success
1 = check failed (assertion false, element not found) — not an error
2 = actual error (no browser, timeout, bad args)
```

This enables `set -e` in shell scripts without aborting on expected check failures.

## Proxy Auth Pattern

For authenticated proxies where Chrome can't send credentials during CONNECT:

```
Chrome → localhost proxy (no auth) → upstream proxy (with auth header) → target
```

Spawn a local forwarding proxy as a background process that injects `Proxy-Authorization` headers into CONNECT requests. Store proxy PID in state file, kill on `stop`.
