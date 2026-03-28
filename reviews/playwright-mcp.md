# playwright-mcp (microsoft/playwright-mcp)

*Review #275 | Source: https://github.com/microsoft/playwright-mcp | License: Apache-2.0 | Author: Microsoft | Reviewed: 2026-03-27 | Stars: 29,848*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

The official Microsoft MCP server for browser automation. Gives any MCP-compatible agent (Claude, Codex, VS Code, Cursor, etc.) full Playwright browser control through structured accessibility trees — no vision model required.

This is the production-grade, Microsoft-maintained answer to "how do agents reliably interact with browsers." 30K stars, actively maintained, ships as `@playwright/mcp` on npm.

---

## The Core Insight

**Accessibility tree over screenshots.** Instead of taking a screenshot and having a vision model guess what to click, it returns the structured DOM accessibility tree as text. The agent reads the tree, finds the `ref` for the element it wants, and calls `browser_click(ref: "e42")`. Deterministic. Works on any model including local/cheap ones with no vision capability.

The README explicitly says: "you can't perform actions based on the screenshot, use browser_snapshot for actions." Screenshots exist for observation only. Actions always go through the accessibility tree refs.

This is the same architecture OpenClaw's `browser` tool uses (it's built on Playwright underneath), but exposed as an MCP server so any agent can use it — including agents that don't natively have browser tools.

---

## Tool Surface (33+ tools across 4 categories)

**Core automation:**
- `browser_navigate` — go to URL
- `browser_click` — click by accessibility ref or CSS selector
- `browser_type` — type text into element
- `browser_fill_form` — fill multiple form fields in one call
- `browser_select_option` — dropdown selection
- `browser_hover`, `browser_drag` — mouse actions
- `browser_press_key` — keyboard input
- `browser_evaluate` — run arbitrary JavaScript on the page or element
- `browser_file_upload` — upload files
- `browser_handle_dialog` — accept/dismiss browser dialogs
- `browser_navigate_back`, `browser_navigate_forward` — history navigation

**Observation (read-only):**
- `browser_snapshot` — accessibility tree of current page (the primary tool)
- `browser_take_screenshot` — visual screenshot (observation only)
- `browser_network_requests` — all network requests since page load
- `browser_console_messages` — browser console output with level filtering
- `browser_wait_for_text`, `browser_wait_for_text_gone` — synchronization primitives

**Tab management:**
- `browser_tab_list`, `browser_tab_new`, `browser_tab_select`, `browser_tab_close`

**Browser lifecycle:**
- `browser_close`, `browser_resize`

**Optional capabilities (--caps flag):**
- `vision` — enables screenshot-based actions for cases where AX tree is insufficient
- `pdf` — PDF generation
- `devtools` — Chrome DevTools Protocol direct access

---

## Three Connection Modes

**1. Fresh headless browser** (default) — spawns a clean isolated Playwright browser. Default for automated/testing use.

**2. Persistent profile** — stores login state, cookies, etc. across sessions at `~/Library/Caches/ms-playwright/mcp-{channel}-profile`. Use `--user-data-dir` to override location. Good for agents that need to stay logged in.

**3. Browser Extension mode** (`--extension`)  — connects to an already-running Chrome/Edge instance via the "Playwright MCP Bridge" extension. Lets the agent use your existing logged-in browser state without any credential setup. This is the most powerful option for personal agent use.

**4. CDP endpoint** (`--cdp-endpoint`) — connects to any Chrome DevTools Protocol endpoint, including remote browsers or browser-in-Docker setups.

---

## Standout Configuration Options

`--codegen typescript` — automatically generates a Playwright test script as the agent takes actions. Turns agent actions into a replayable test suite. Run the agent once to figure out a workflow, get a test back for free.

`--snapshot-mode incremental` (default) — sends only the diff of the accessibility tree between snapshots, not the full tree every time. Massive token savings on complex pages.

`--isolated` — fresh browser context per session, no persistence. Good for test environments or untrusted automation.

`--storage-state <path>` — inject saved login state (cookies/localStorage) from a file into an isolated session. Standard Playwright auth pattern.

`--init-script <path>` — inject a JS file that runs in every page before page scripts. Useful for mocking APIs, overriding browser globals, bypassing anti-bot measures.

`--secrets <path>` — dotenv file of secrets injected into the server environment. Keeps credentials out of the config.

`--blocked-origins` / `--allowed-origins` — origin filtering. Note: the README explicitly says this is NOT a security boundary and does NOT prevent redirects. Don't rely on it for sandboxing.

`--allow-unrestricted-file-access` — by default, file:// URLs are blocked and file system access is restricted to workspace roots. This flag opens it up. Off by default is a good security default.

---

## Transport Modes

Runs as either:
- **stdio** (default) — standard MCP stdio transport, for local tooling
- **HTTP/SSE** — `--port <n>` enables an HTTP server with SSE transport for remote clients or multi-client scenarios. `--shared-browser-context` lets multiple HTTP clients share one browser instance.

---

## vs. Playwright CLI

The README itself recommends CLI+SKILLS over MCP for coding agents, with a link to `microsoft/playwright-cli`:

> "CLI invocations are more token-efficient: they avoid loading large tool schemas and verbose accessibility trees into the model context, allowing agents to act through concise, purpose-built commands."

The recommended split:
- **MCP**: exploratory automation, self-healing tests, long-running autonomous workflows where continuous browser context matters
- **CLI+Skills**: coding agents doing test automation where token efficiency matters more than persistent state

Both are worth knowing about.

---

## Relevance

🔥🔥🔥🔥🔥 — this is Microsoft's production browser automation layer for agents. 30K stars, Apache-2.0, actively maintained.

**For our setup:** OpenClaw already has the `browser` tool (Playwright-backed) which covers this for Rue directly. Where playwright-mcp becomes interesting:
- Wiring to **Claude Code** or **Codex** sessions that don't have native browser tools — `claude mcp add playwright npx @playwright/mcp@latest` is one command
- The **browser extension mode** (`--extension`) for connecting coding agents to an already-logged-in browser instance
- The **codegen mode** for turning agent browser sessions into replayable Playwright tests
- The `--cdp-endpoint` option for connecting to a browser running on another machine (Nautilus, Debbie, etc.)

For anyone building agents that need browser automation and doesn't already have it wired: this is the canonical solution. `npx @playwright/mcp@latest` and you're done.

Apache-2.0. Use freely.
