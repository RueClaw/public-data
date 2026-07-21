# Kimi Code CLI (MoonshotAI/kimi-code)

**Repo:** https://github.com/MoonshotAI/kimi-code  
**License:** MIT; permissive reuse with attribution  
**Reviewed:** 2026-07-20  
**Stack:** TypeScript monorepo, Node.js/pnpm, custom terminal UI, Fastify server, Vue/Vite web UI, Agent Client Protocol, MCP, OAuth, Nix/native packaging  
**What it is:** Kimi Code CLI is Moonshot AI's open-source terminal coding agent and broader agent platform: a local TUI, web/server mode, ACP bridge, SDK, plugin system, MCP integration, subagents, goals, permissions, session replay, and native binary distribution.

---

## Verdict

✅ **Deploy candidate for serious agent-runtime evaluation.** Kimi Code is not a thin model wrapper; it is a substantial local agent platform with a real permission-policy layer, session/server architecture, plugin and MCP surfaces, subagents, goal mode, native packaging, CI, docs, and active releases. The caveat is authority: this tool is designed to read/write code, run shells, install plugins, and expose local server APIs, so pilot it like infrastructure rather than a casual CLI alias.

---

## What It Is

Kimi Code CLI is an AI coding agent that runs in a terminal, with Moonshot/Kimi models as the default path and other compatible providers configurable. The README pitch is familiar: read code, edit files, run commands, search, fetch pages, and continue from feedback. The repo itself is larger and more interesting than that pitch.

The codebase is a full TypeScript monorepo. It contains the published CLI/TUI app, a web UI, a VS Code extension, a server package, an Agent Client Protocol adapter, SDK/client packages, a transcript renderer, OAuth/MCP subsystems, native packaging scripts, a custom terminal UI library, test suites, and docs. Current release at review time was `@moonshot-ai/kimi-code@0.28.1`, published the same day as the review.

The strongest signal is that the project treats coding-agent runtime behavior as an engineering problem: permissions, sensitive-file detection, tool scheduling, truncation, replay, goals, subagents, plugin manifests, session storage, auth, host/origin checks, and debug endpoints all have concrete code and tests instead of living only in prompt text.

## Stack

| Layer | Tech |
|-------|------|
| CLI/TUI | TypeScript ESM, commander, custom `pi-tui`, optional `node-pty`, native single-binary packaging |
| Agent runtime | `packages/agent-core` and `packages/agent-core-v2`, DI/scoped services, tool executor, context memory, goals, swarm/subagents |
| Server/API | Fastify, REST/WebSocket under `/api/v1`, bearer auth, host/origin checks, debug RPC surface |
| Web UI | Vue 3, Vite, vue-i18n |
| Editor integration | ACP adapter, VS Code extension, JetBrains/Zed-compatible ACP command |
| Provider/auth | Moonshot managed OAuth, configurable providers, MCP OAuth and bearer-token support |
| Plugins/skills | `kimi.plugin.json` / `.kimi-plugin/plugin.json`, skills, hooks, commands, MCP servers, session-start injection |
| Build/release | pnpm 10.33.0, Node 24.15.0 root engine, Changesets, GitHub Actions, Nix build, signed/notarized native artifacts |

## Key Features

### Full Local Agent Platform

The CLI is the visible product, but the repo is organized like a reusable runtime. `apps/kimi-code` consumes shared packages rather than embedding everything in the app. `packages/kap-server` exposes sessions over HTTP and WebSocket. `packages/acp-adapter` bridges to ACP clients. `packages/transcript` owns rendering and replay data. This makes Kimi Code closer to Codex/Claude Code infrastructure than to a one-off terminal chat client.

### Permission and Safety Surfaces

The runtime has explicit permission policies for auto/yolo/manual behavior, sensitive-file access, plan-mode guards, goal starts, configured allow/ask/deny rules, and Git control path access. File tools use a shared path-access layer that canonicalizes paths lexically, detects workspace escapes, and asks on likely secret files such as `.env`, SSH keys, and cloud credential paths.

That is a strong baseline. It does not make arbitrary shell execution safe by itself, but it means the project has a place to enforce policy instead of relying entirely on model instructions.

### Plugin and MCP System

Kimi plugins can contribute skills, session-start guidance, MCP servers, hooks, commands, and interface metadata. The manifest parser validates plugin-local paths and explicitly ignores unsupported runtime-extension fields from other ecosystems. MCP support covers stdio, HTTP/SSE/remote clients, OAuth callback flow, token storage, bearer-token env vars, and tool naming.

The plugin surface is useful, but it is also the area to treat most carefully. A plugin can influence instructions and runtime wiring, so installation should be considered a trust decision.

### Subagents and Goal Mode

The v2 runtime includes `AgentSwarm` with up to 128 subagents, resumable agent IDs, prompt templating, timeout configuration, and per-subagent XML result rendering. Goal mode is also real code: goal snapshots, budgets, active/paused/blocked/complete state, reminders, deadline scheduling, and model tools for create/get/update/budget.

These are more advanced than the average coding-agent CLI. They point toward long-running autonomous work rather than only interactive pair programming.

### Serious Release Engineering

The repo has sharded tests, lint/typecheck jobs, Nix build checks, docs deploy, Changesets publishing, native artifact workflows across Linux/macOS/Windows architectures, macOS signing/notarization hooks, smoke tests, package preview publishing, and a root rule that workspace package changes must keep `flake.nix` in sync.

At review time, GitHub reported 4,214 stars, 623 forks, 393 open issues, latest release `0.28.1`, and a push on 2026-07-20. The local clone had about 3,838 files and 1,058 TypeScript test files by filename pattern.

## Architecture

The repo is split into app packages and reusable runtime packages:

- `apps/kimi-code` is the CLI/TUI entrypoint.
- `apps/kimi-web` is the browser UI.
- `apps/vscode` provides extension integration.
- `packages/agent-core` and `packages/agent-core-v2` hold agent/session/tool/permission/plugin/runtime logic.
- `packages/kap-server` exposes the server API and WebSocket transport.
- `packages/acp-adapter` implements Agent Client Protocol integration.
- `packages/klient`, `packages/node-sdk`, `packages/kosong`, and related packages form the client/provider/runtime substrate.
- `packages/transcript` owns transcript data and rendering.

The notable architectural choice is the scoped-service model in `agent-core-v2`. Many runtime domains are explicitly documented in file headers: context memory, permissions, goals, shell command execution, tool execution, plugin injection, MCP, task management, transcript, and server debug surfaces. That documentation is dense, but it is unusually helpful for a fast-moving agent runtime.

## Comparison

| Aspect | Kimi Code CLI | Omnigent | Superpowers | Codex Orchestration |
|--------|---------------|----------|-------------|---------------------|
| Primary role | Full coding-agent runtime and CLI | Multi-harness control plane | Portable workflow skill library | Codex-specific routing plugin |
| Runtime ownership | Owns TUI, server, agent engine, ACP, plugins | Wraps many agent harnesses | Mostly prompt/skill behavior | Configures Codex routing policy |
| Enforcement | Permission-policy and server auth layers | Policies, sandboxing, auth | Prompt/process discipline | Bounded setup/status/bridge rules |
| Best fit | Evaluate as a standalone coding-agent platform | Govern many agent tools together | Improve development workflow discipline | Improve Codex model routing |
| Main caveat | High-authority local runtime with fast-moving surface | Broad alpha control plane | Not a runtime guardrail | Policy-guided, not a full scheduler |

Kimi Code is closest to a standalone alternative to Codex or Claude Code, not to a plugin. Compared with Omnigent, it is less of a cross-harness operations layer and more of a complete first-party agent stack. Compared with Superpowers, it enforces more at runtime but is also a much larger trust surface.

## Self-Hosting Notes

The normal install paths are the official install script, Homebrew, npm, or native releases. For development, the repo requires Node.js 24.15.0 at the root and pnpm 10.33.0. The published `apps/kimi-code` package advertises a lower Node floor, but the monorepo itself is strict about Node 24.15.0.

Server mode defaults to loopback and refuses non-loopback binds without an explicit insecure/TLS opt-out. It uses bearer auth, host checks, origin checks, and rate limiting on non-loopback exposure. Debug RPC endpoints are only enabled on loopback when requested. That is the right default shape for a local agent server, but any remote exposure should sit behind deliberate TLS, auth, and network policy.

For evaluation, start in a disposable repository, leave permission prompts on, avoid installing untrusted plugins, and inspect generated config under the Kimi home directory before treating it as a daily driver.

## Verification Notes

Reviewed current `main` at `c2d7bebd0410` (`docs(changelog): sync 0.28.1 from apps/kimi-code/CHANGELOG.md (#1975)`). GitHub API reported MIT license, 4,214 stars, 623 forks, 393 open issues, latest release `@moonshot-ai/kimi-code@0.28.1`, and last push on 2026-07-20.

Local review was code inspection only. I did not run the full build/test suite because the monorepo is large and dependency installation would be expensive. Static inspection found no obvious committed production secret; the high-volume secret scan hits were documentation, tests, token-handling code, and fixtures that intentionally exercise redaction/auth behavior.

---

**Attribution:** MoonshotAI/kimi-code, MIT License
