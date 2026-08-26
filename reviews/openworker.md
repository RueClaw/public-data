# OpenWorker (andrewyng/openworker)

**Repo:** https://github.com/andrewyng/openworker
**License:** MIT; permissive reuse with attribution
**Reviewed:** 2026-08-26
**Stack:** Python, FastAPI, React, Tauri, Rust sidecar, aisuite, MCP, Playwright, SQLite/local JSON state
**What it is:** Local-first desktop AI coworker that runs a provider-agnostic agent server on the user's machine, connects to desktop/files/tools/integrations, and approval-gates consequential actions.

---

## Verdict

✅ **Deploy candidate for local agent-runtime study and cautious desktop use.** OpenWorker is one of the more serious open-source "AI coworker" attempts: it has real desktop packaging, a local sidecar, broad provider support, MCP/connectors, unattended workflow routing, and an unusually well-tested permission model. The caveats are also real: it is beta, the browser UI tests currently fail locally under Vitest, and the GUI has a direct `xlsx` production advisory.

---

## What It Is

OpenWorker is a desktop agent harness aimed at producing finished artifacts rather than chat-only answers. The user starts from a native shell/GUI, the local Python server runs the agent loop, and model/tool actions flow through connectors, local files, terminal access, browser automation, MCP servers, and messaging surfaces such as Slack.

The repo is not just a prototype README. It includes a Python backend, React/Tauri GUI, packaging scripts for macOS and Windows, release CI, mocked and live e2e tests, connector setup flows, approval cards, scheduled automations, personas, skills, multi-root workspaces, and provider adapters for OpenAI, Anthropic, Gemini, Bedrock, Vertex, Ollama-style local setups, and other compatible providers.

The design is explicitly local-first: API keys and connector tokens live in a machine-local secret store, the sidecar is localhost-bound with a per-launch token in packaged flows, and cloud use is scoped mainly to OAuth brokering and whatever external model/connectors the user chooses.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Python 3.10+, FastAPI, Uvicorn |
| Agent/runtime | aisuite, custom TurnEngine, provider adapters, tool registry |
| Desktop/frontend | React 18, TypeScript, Vite, Tauri 2 |
| Browser automation | Playwright optional extra |
| Integrations | MCP SDK, Slack/Gmail/Calendar/GitHub/HubSpot/Outlook and other connector tools |
| Storage | Local JSON/SQLite-style state, local secret store |
| Packaging | PyInstaller sidecar, Rust/Tauri bundles, macOS DMG, Windows MSI/NSIS |
| Tests | pytest, Vitest, Playwright |

## Key Features

### Local Agent Sidecar

The backend exposes a FastAPI control plane and OpenAI-compatible endpoint while keeping session execution local. Browser-origin checks and token-gated HTTP/WS paths are treated as first-class security controls rather than afterthoughts.

### Permission Engine

The standout architecture is the permission model. Tools are classified as read, egress, local write, command execution, or external side effect. Read-only modes block consequential tools; write paths are scoped to writable roots; protected settings, CI files, hooks, and persistent-authority tools get stricter handling; and auto-approve routes only eligible prompts through a reviewer rather than blindly allowing broad action.

### Connectors and MCP

OpenWorker ships a catalog of connector tools and a thin async MCP manager over the official SDK. The connector definitions separate read/write kind, user-facing labels, target arguments for standing rules, and secret lookup from model-facing tool schemas.

### Unattended Runs

The unattended mode is framed as a routing change, not an autonomy upgrade: approvals and questions go to an inbox and the agent waits. That is a good product distinction for recurring work, because it keeps schedule-driven tasks from silently expanding their authority.

## Architecture

The repo is organized around a local control plane:

- `coworker/engine.py` owns the model/tool loop and approval flow.
- `coworker/permissions.py` and `coworker/risk.py` define side-effect classification and mode-specific gates.
- `coworker/connectors/` contains first-party integration plumbing.
- `coworker/mcp/` manages persistent MCP connections.
- `coworker/automation/` and `coworker/inbox.py` support scheduled and unattended work.
- `surfaces/gui/` is the React/Tauri desktop surface.

The code shows a lot of "owner-operated agent runtime" scars: origin-gated localhost APIs, frame/rate caps on WebSocket input, human-only floors for deferred authority, exact-target standing rules for automations, protected project files, and tests for approval provenance and cross-surface messaging.

## Comparison

| Aspect | OpenWorker | OpenHuman | Cloudflare Computer | 12-Factor Agents |
|--------|------------|-----------|--------------------|------------------|
| Runtime shape | Local desktop app plus Python sidecar | Personal desktop harness | Cloudflare Durable Object workspace runtime | Principles guide |
| Tool authority | Detailed local permission engine | Broad local desktop/MCP powers | Platform-scoped execution backends | Conceptual human/tool-call guidance |
| Maturity signal | Large backend suite, CI, release workflow | Useful but higher privacy/security burden | Preview APIs | Reference material |
| Best use | Study/pilot a full desktop coworker | Study personal-AI UX patterns | Study durable serverless workspaces | Design rubric |

## Self-Hosting Notes

Running from source needs Python 3.10+, Node 20+, and Rust. The documented flow bootstraps a Python venv, starts `openworker-server`, then runs the GUI from `surfaces/gui`. The packaged desktop path is the intended user path: macOS builds are signed/notarized when release secrets are present, while Windows signing is still in progress.

Local validation on 2026-08-26:

- `uv run --extra messaging --extra bedrock --extra dev pytest tests -q`: 1861 passed, 1 skipped, 1 warning.
- `npx tsc --noEmit`: passed.
- `npm test`: 129 passed, 5 failed, all in `src/components/Sidebar.test.tsx` due `localStorage.getItem` being undefined in the Vitest/jsdom environment.
- `npm audit --omit=dev --json`: 1 high production advisory, direct `xlsx` dependency affected by prototype pollution and ReDoS advisories with no npm fix available.

---

**Attribution:** andrewyng/openworker, MIT
