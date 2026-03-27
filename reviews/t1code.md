# t1code (maria-rcks/t1code)

*Review #270 | Source: https://github.com/maria-rcks/t1code | License: MIT | Author: maria-rcks (fork of T3 Code by @t3dotgg / @juliusmarminge) | Reviewed: 2026-03-26*

## Rating: 🔥🔥🔥🔥

---

## What It Is

A terminal-native fork of **T3 Code** — a web UI + TUI wrapper around Codex (and Claude Code, in progress) that runs as a local Node.js WebSocket server serving a React app. The pitch in the README: *"T3Code, but in your terminal."*

Install: `bunx @maria_rcks/t1code` (requires Bun).

~126K lines of TypeScript across a Turborepo monorepo:
- `apps/server` — Node.js WebSocket server, orchestration engine, provider adapters
- `apps/web` — React + Vite frontend (shadcn/ui, TanStack Router)
- `apps/tui` — Ink-based terminal UI frontend
- `apps/desktop` — Electron wrapper
- `apps/marketing` — Astro marketing site
- `packages/contracts` — Zod-validated shared type contracts
- `packages/shared` — DrainableWorker, shell utils, model definitions
- `packages/client-core` — Shared client logic (sidebar sort, slash commands, session logic)

---

## Architecture

```
Browser/TUI ←─ WebSocket (ws://localhost:3773) ─→ Node.js Server
                                                        │
                                                JSON-RPC over stdio
                                                        │
                                              codex app-server (or claude)
```

**The key design insight:** The server wraps `codex app-server` (Codex CLI's internal JSON-RPC interface) over stdio and translates provider events into a canonical orchestration model. The web/TUI clients only see the orchestration model — never provider-native payloads.

**Orchestration pipeline:**
1. `ProviderRuntimeIngestion` — consumes provider runtime streams → emits orchestration commands
2. `ProviderCommandReactor` — reacts to intent events → dispatches provider calls
3. `CheckpointReactor` — captures git checkpoints on turn start/complete → runtime receipts

All workers use `DrainableWorker` for queue-backed processing with deterministic `drain()` for testing. Runtime receipts (checkpoint captured, diff finalized, turn quiescent) replace polling.

**Event sourcing:** Full orchestration event store (NDJSON → SQLite migrations), projection pipeline, snapshot queries. 15 database migrations tracked. The projection layer is properly separated from the event store — read models built by replaying events.

---

## What's Notable

### Contracts-First Architecture
`packages/contracts` defines Zod schemas for everything that crosses a boundary: WebSocket push channels, provider runtime events, orchestration commands, IPC. Schema decode failures at the transport boundary produce structured `WsDecodeDiagnostic` objects with code, reason, and path. This is the right way to build a multi-surface application — one truth for all surfaces.

The provider contract (`provider.ts`) and runtime contract (`providerRuntime.ts`) are explicitly typed as canonical, provider-agnostic shapes. Adapters (CodexAdapter, ClaudeAdapter) translate to/from these.

### Claude Code Integration In Progress
`.plans/17-claude-agent.md` documents the Claude integration plan, and `ClaudeAdapter.ts` exists in the provider layer. The plan is principled: Claude plugs into the existing canonical `ProviderRuntimeEvent` stream without new WS channels or bypass paths. Web UI currently shows `"Claude Code (soon)"` and model picker is Codex-only, but the architecture is ready. This is the most interesting near-term development.

### TUI Surface (Ink)
`apps/tui` is an Ink-based terminal UI that bundles the server and provides a full t1code experience without a browser. Distributed on npm (`@maria_rcks/t1code`), actively being iterated (10 version bumps in recent commits — all TUI stability fixes: server startup, ctrl-c handling, clipboard shortcuts).

### Remote Access Design
`REMOTE.md` documents a proper remote-access pattern: auth token via `--auth-token` or `--bootstrap-fd` (one-shot JSON envelope over inherited file descriptor — avoids token in env or CLI args), bind to LAN or Tailnet IP. Tailscale workflow documented explicitly. This is the right approach for running on a homelab server and accessing from other devices.

### Checkpoint System
Git checkpoints on turn start/complete with diff storage. `CheckpointDiffQuery` service lets you query diffs between checkpoints. Revert via `providerService.rollbackConversation()`. The checkpoint reactor uses runtime receipts so everything is event-driven rather than polling.

### Testing Infrastructure
`DrainableWorker.drain()` for deterministic queue synchronization in tests. Integration test harness (`OrchestrationEngineHarness`, `TestProviderAdapter`). 9+ integration tests in `apps/server/integration/`. Unit tests next to source throughout (`.test.ts` pattern). Browser-mode tests for UI components (`vitest.browser.config.ts`). OxFmt + OxLint for formatting/linting.

---

## Honest Assessment

**This is a serious codebase.** The architecture is notably more principled than most projects at this stage — full event sourcing, typed contracts everywhere, provider-agnostic orchestration, DrainableWorker for deterministic testing. The `.plans/` directory has 20+ numbered plans documenting architectural decisions and refactors in progress. This isn't just "fork T3 Code and make a TUI" — it's a genuine re-architecture toward a cleaner, more maintainable multi-provider system.

**The fork lineage matters.** T3 Code (by Theo + Julius Marminge of T3 stack fame) is the underlying project. maria-rcks has taken it in a more engineering-rigorous direction: event sourcing, typed IPC boundaries, Effect.ts exploration (plans 11-15 show Effect being evaluated for the server layer), Zod-validated contracts. Copyright says "T3 Tools Inc." so this is likely the actual T3 organization's codebase with a community contributor.

**Current state:** Codex is the only working provider. Claude integration is in progress but the architecture is designed for it. The TUI is actively getting stability fixes. The TODO list is short (5 small items, 1 big one).

**What it's not:** This isn't an agent framework. It's a UI layer for existing CLI coding agents. The value is the multi-surface (web + TUI + desktop), remote access, git checkpointing, and event-sourced architecture — not novel agent capabilities.

---

## Relevance

**The remote access pattern is immediately useful.** The `--bootstrap-fd` auth token delivery mechanism and Tailscale binding docs are directly applicable to running any coding agent on the homelab and accessing from other devices.

**The contracts-first approach** (Zod schemas at every boundary, canonical provider-agnostic events, `WsDecodeDiagnostic` at decode failures) is a design pattern worth lifting for any multi-surface project — relevant to VOS and ODR.

**The DrainableWorker + drain() pattern** for deterministic async queue testing is worth knowing. It's a clean solution to the "how do I write reliable tests for async workers without sleep()?" problem.

**The event sourcing + projection pipeline architecture** in `apps/server` is a reference implementation of that pattern in TypeScript — readable, well-structured, with explicit migration tracking.

**The Claude adapter plan** (`.plans/17-claude-agent.md`) is worth reading as a template for how to add a new provider to an existing orchestration system without breaking existing abstractions.
