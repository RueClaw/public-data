# dev-browser — #258

**Repo:** https://github.com/SawyerHood/dev-browser  
**Author:** Sawyer Hood (Do Browser / dobrowser.io)  
**License:** MIT (Sawyer Hood 2025)  
**Language:** TypeScript (daemon) + Rust (CLI)  
**Stars:** 4101 | **Forks:** 260  
**Created:** 2025-12-02 | **Reviewed:** 2026-03-25  
**Rating:** 🔥🔥🔥🔥🔥  
**Cloned:** ~/src/dev-browser

---

## What It Is

Browser automation for AI agents — specifically designed to give Claude Code (and any other agent) persistent, sandboxed browser control via a simple CLI.

```bash
npm install -g dev-browser
dev-browser install    # installs Playwright + Chromium

dev-browser --headless <<'EOF'
const page = await browser.getPage("main");
await page.goto("https://example.com");
console.log(await page.title());
EOF

# Connect to running Chrome
dev-browser --connect <<'EOF'
const tabs = await browser.listPages();
EOF
```

Agents invoke `dev-browser` as a bash command. The help output is an LLM usage guide — no plugin required.

---

## Architecture

Two-layer system:

**Rust CLI (`cli/`)** — ~1000 lines. Handles invocation, daemon lifecycle (auto-start/stop), Unix socket IPC to daemon, flags, `--connect` mode, `install` subcommand. Embeds the entire daemon bundle at compile time (`include_str!`) so the distributed binary is self-contained.

**TypeScript Daemon (`daemon/`)** — ~3600 lines. Long-running Node.js process managing:
- Playwright browser contexts and named pages (persistent across scripts)
- Script execution in **QuickJS WASM sandbox** (`quickjs-emscripten`) — not Node.js VM
- CDP connections for attaching to existing Chrome instances
- HTTP API for page management
- Temp file I/O bridge between sandbox and host

**Sandbox design (key insight):**
Scripts run in QuickJS WASM with a curated API surface:
- `browser` global (pre-connected Playwright handle, proxied through sandbox boundary)
- `console` (routed to CLI output)
- `saveScreenshot()`, `writeFile()`, `readFile()` (temp dir only)
- `setTimeout/clearTimeout`
- NO: `require/import`, `process`, `fs`, `fetch`, `WebSocket`
- Memory + CPU limits enforced. Infinite loops interrupted.

This means agents can run arbitrary browser scripts without being able to exfiltrate data via direct network calls or read the host filesystem. The Playwright API is proxied — the sandbox calls JS methods that are marshaled across the QuickJS↔Node.js boundary to real Playwright.

**Persistent pages** — named pages survive between script invocations. Navigate once, interact across multiple scripts. This is the key behavioral difference from vanilla Playwright.

---

## Why It Matters

**This is the missing piece for web-capable agents.** The gap has always been: browser automation requires either (a) giving the agent raw Playwright access (too powerful, unsafe) or (b) a pre-built click-by-click computer-use model (too slow, too fragile). dev-browser gives agents a principled middle ground:

- Sandboxed JS execution — agents write real scripts, not NL→click chains
- Persistent state — browse a site, then interact with it in subsequent turns
- Connect to user's running Chrome — agents can operate within authenticated sessions
- Self-contained binary — no infrastructure, no server to run, no Docker

**Relation to our stack:**
- **OpenClaw** — currently uses the browser tool (OpenClaw's own CDP-based automation). dev-browser is an alternative approach oriented toward code-generation rather than accessibility-tree actions.
- **ghost-os** (#236) — complementary. ghost-os does accessibility-tree-first computer use; dev-browser does sandboxed-script browser use. Different threat models and use cases.
- **ODR** — could use dev-browser for automated acceptance testing of the frontend. Agent writes test scripts, they run in sandbox without needing full Playwright environment setup.
- **Agent-driven research** — automated web research pipelines where the agent navigates, logs in, scrapes, without getting direct network access from within the script.

---

## Standout Patterns

**Embedded daemon in Rust binary** — `include_str!("../../daemon/dist/daemon.bundle.mjs")` embeds the entire compiled JS bundle. Ships as a single binary, extracts on first run. Clean distribution pattern for polyglot tools.

**QuickJS sandbox with proxied Playwright API** — the `quickjs-host.ts` (~630 lines) and `quickjs-sandbox.ts` (~750 lines) together implement the JS↔WASM API proxy layer. This is non-trivial and worth studying for any agent tool that wants principled sandbox boundaries without full containerization.

**Help-as-LLM-guide** — the CLI `--help` output is written as an LLM usage guide with examples and API reference. Agents can bootstrap themselves by reading it. Pattern worth stealing for any agent-targeted CLI.

**Named pages** — `browser.getPage("name")` creates or retrieves a persistent named page. Trivial concept, significant practical value: the agent can maintain multiple browser "workspaces" across turns.

---

## Caveats

- Sandboxed scripts can't do direct network calls, but they control a real browser — a script that navigates to `attacker.com` with sensitive data in the URL would exfiltrate via the browser. The sandbox prevents agent-written code from calling `fetch()` directly, not from using the browser as a conduit.
- Windows not supported
- The service backing the `--connect` use case (existing Chrome) requires `chrome://inspect/#remote-debugging` to be enabled — not a default state
- 4100 stars in ~4 months — actively maintained, real traction

---

## Verdict

🔥🔥🔥🔥🔥 — The architecture is the right answer to the agent-browser problem. QuickJS sandbox + Playwright proxy is genuinely clever. The embedded binary distribution and help-as-LLM-guide patterns are immediately stealable. 4100 stars in 4 months is real signal.

**Install on ODR for browser-based acceptance testing:** `npm install -g dev-browser && dev-browser install`  
**Pattern to steal:** QuickJS WASM as a sandboxed script execution layer for any agent tool that needs code execution without full host access.
