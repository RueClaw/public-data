# DeepSeek Harness (deepseek-ai/deepseek-harness)

**Repo:** https://github.com/deepseek-ai/deepseek-harness
**License:** MIT; permissive reuse with attribution
**Reviewed:** 2026-08-13
**Stack:** TypeScript, Node 22/24, pnpm, Vite/React, Cordis, Python SDK/runtime, JSON-RPC ACP
**What it is:** DeepSeek's open-source agent harness: a plugin-composed web/headless/automation runtime where models, tools, sessions, persistence, sandboxing, approvals, UI modules, jobs, subagents, and provider adapters are all replaceable Cordis services.

---

## Verdict

✅ **Deploy candidate for architecture study and cautious local pilots.** DeepSeek Harness is not a thin demo: it has a real monorepo, CLI, web app, headless mode, ACP bridge, Python runtime, session persistence, sandbox seams, provider seams, documentation, and a very large test suite. The caveat is timing: the README labels it developer preview with compatibility-breaking changes, and the repo was created the day of review, so treat it as a serious early platform rather than stable infrastructure.

---

## What It Is

DeepSeek Harness, launched as `dsh`, is a local agent platform built around the idea that every capability is a plugin. The root product ships profile bundles such as `web` and `headless`; profiles are ordered Cordis patch layers that mount model adapters, tools, persistence, sandbox policy, approvals, settings, credentials, UI modules, and runtime services.

The important design choice is that there is very little privileged "core" behavior to patch. New behavior attaches to documented extension points: register an LLM adapter, tool, filesystem provider, sandbox backend, subagent provider, job service, command, UI conversation node, or durable session event. That makes the repo more like a harness framework than a single agent app.

It also has automation surfaces. The `@deepseek-ai/dsh-acp` package exposes fresh Harness agents over Agent Client Protocol JSON-RPC stdio, returning committed assistant text and handling one-shot permission requests. The Python runtime packages make the same composition usable from Python-oriented host environments.

## Stack

| Layer | Tech |
|-------|------|
| Runtime/composition | Cordis plugin tree, YAML patch layers, package `dsh` metadata |
| CLI | TypeScript ESM, Node 22/24, pnpm, `dsh web`, `dsh --profile headless`, plugin profile management |
| Web app | Vite frontend, modular client packages, e2e-heavy web test suite |
| Agent core | Event-sourced sessions, agent loop, prompt assembly, scoped tool registry, LLM adapter seam |
| Automation | ACP JSON-RPC stdio server, subagent providers, SDK/server/client packages |
| Persistence | JSONL and SQLite session persistence backends, session-query packages |
| Sandboxing | Abstract sandbox seam, local bwrap/Landlock/macOS Seatbelt/Windows ACL backends, E2B proof-of-concept overlay |
| Tooling | TypeScript 6, Vitest, oxlint, tsdown, generated docs/catalogs, GitHub Actions |
| Python | Python SDK and SDK runtime packages with Hatch build support |

## Key Features

### Everything-Is-A-Plugin Composition

Profiles compose bundles plus user patches into one Cordis tree. The base bundle mounts the common runtime services, the web bundle adds the browser app, and the headless bundle adds a one-shot runner. Because bundles are patchable config rows rather than opaque code paths, operators can inspect and replace rows with `dsh --profile web --dump-config`.

This is the main reason the project is interesting. Many agent runtimes claim extensibility but keep the loop, tools, persistence, and UI tightly coupled. Harness makes those replacement points explicit.

### Event-Sourced Sessions

The session system is an append-only log of typed `SessionEvent`s. LLM history is derived from the log instead of stored as a parallel transcript. Raw stream chunks, assistant messages, tool calls/results, request headers, route context, todos, and turn/step boundaries all live in the event vocabulary.

The docs are unusually strict about replay: model-visible input must be reconstructable from the log, unknown required event types refuse load rather than silently dropping meaning, and crash recovery closes interrupted turns instead of truncating flushed events.

### Guarded Tool Pipeline

Tools have typed parameter and output schemas, canonical JSON outputs, render projections, optional UI presentation, cancellation-aware execution, and concurrency metadata. Execution flows through pre-execute policy, monotonic guards, around-dispatch wrappers, post-execute transforms, final content shaping, and immutable result observation.

That gives policy and observability somewhere to live without forking every tool.

### Sandboxing as a Capability Seam

The process sandbox API is explicit about what it does and does not promise. `read-only` and `workspace-write` govern filesystem effects; network and process visibility are outside that vocabulary. `danger-full-access` bypasses the sandbox provider rather than pretending confinement exists.

The local provider supports Linux bwrap/Landlock, macOS Seatbelt, and a Windows ACL restricted-token backend. The docs also distinguish full vs partial enforcement and require confined providers to fail closed instead of silently passing through unconfined execution.

### Automation and Subagent Surfaces

The ACP package is intentionally narrow: fresh sessions only, text prompts only, committed-message output only, and no editor/UI surfaces. That is a good automation boundary. Parent agents can drive Harness sessions without inheriting the whole web UI protocol or leaking partial provider chunks.

The monorepo also includes subagent providers, jobs, workflows, session query/export, tool-session-query, web/search/fetch provider seams, and many client-side UI modules.

## Architecture

Harness's architecture reads as "service spine plus replaceable providers." Important services include:

- `ctx.sessions` for the in-memory event-sourced session store
- `ctx.sessionPersistence` for durable logs
- `ctx.llm` for provider adapters
- `ctx.tools` for the guarded model-facing tool registry
- `ctx.sandbox` and `ctx.sandboxPolicy` for per-call process confinement
- `ctx.fs`, `ctx.subprocess`, `ctx.shell`, `ctx.terminals`, and `ctx.lsp` for execution-world capabilities
- `ctx.subagents`, `ctx.jobs`, `ctx.commands`, `ctx.goals`, and `ctx.skills` for higher-level agent operations

The generated docs are part of the architecture, not just prose. Capability graphs, event producer/consumer maps, config catalogs, persistence catalogs, and Cordis API sections are generated from source and verified in CI. That makes the docs more trustworthy than hand-maintained diagrams.

## Comparison

| Aspect | DeepSeek Harness | Kimi Code | Oh My Pi | OpenAI Symphony |
|--------|------------------|-----------|----------|-----------------|
| Primary shape | Plugin-composed agent harness/runtime | Full coding-agent product/runtime | Terminal coding harness with mounted tool devices | Issue-tracker-driven autonomous work daemon |
| Extension model | Cordis service tree and patchable bundles | Plugins, skills, MCP, ACP, runtime services | `xd://` devices, MCP/custom tools, subagents | Repo-owned `WORKFLOW.md`, tracker tools |
| Session model | Append-only typed event log with replay invariants | Transcript/runtime persistence | Session tree/memory/tool traces | Work-item run state and Codex app-server events |
| Automation | ACP stdio server, Python runtime, headless profile | ACP/server/editor surfaces | Subagents/collab/headless workers | Codex app-server orchestration |
| Best lesson | Treat every capability as a swappable seam | Product-grade local agent permissions/plugins | Tool-surface scaling and IDE wiring | Tracker-owned background work |
| Main caveat | Developer preview and very fresh public repo | High-authority fast-moving runtime | Broad local authority/default-yolo concerns | Engineering preview, trusted environments |

## Self-Hosting Notes

The advertised quick start is:

```sh
npx @deepseek-ai/dsh web
```

From source:

```sh
git clone https://github.com/deepseek-ai/deepseek-harness.git
cd deepseek-harness
pnpm install
pnpm run build
pnpm dsh web
```

The default web UI serves on `http://127.0.0.1:3080`. Real model use expects `DEEPSEEK_API_KEY`, with optional `DEEPSEEK_BASE_URL`. The CLI docs say credentials resolve from environment, `$DSH_HOME/.credentials.yaml`, local `.env`, and `$DSH_HOME/.env`; managed credentials are not materialized into `process.env`.

Do not expose the web/server surfaces casually. The project has serious permission and sandbox abstractions, but a developer-preview agent harness with filesystem, shell, terminal, LSP, subagent, MCP, and web capabilities should start loopback-only in a disposable workspace.

---

**Attribution:** deepseek-ai/deepseek-harness, MIT License
