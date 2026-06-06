# Oh My Pi (can1357/oh-my-pi)

**Repo:** https://github.com/can1357/oh-my-pi
**License:** MIT. Permissive reuse with attribution.
**Reviewed:** 2026-06-06
**Stack:** TypeScript/Bun monorepo, Rust native crates via N-API, Python/FastAPI bot, React/Solid dashboards, SQLite memory, Docker/GitHub Actions
**What it is:** Oh My Pi is a terminal coding-agent harness that turns IDE features, native search/shell primitives, browser automation, debugging, subagents, memory, GitHub objects, and plugin/skill loading into one model-facing CLI.

---

## Verdict

✅ **Deploy candidate for people who want a full-power local coding agent.** The project is not just another prompt wrapper: it has a serious tool surface, native performance work, LSP/DAP integration, hash-anchored edits, session machinery, memory, and a self-hosted GitHub triage bot. The caveat is operational complexity: it is a fast-moving monorepo with a large runtime surface, and the local TypeScript check currently fails on one Biome formatting issue in a test file.

---

## What It Is

Oh My Pi, shipped as `omp`, is a fork/evolution of Pi that aims to make the coding-agent harness itself the advantage. Instead of only asking a model to call `read`, `write`, and `bash`, it gives the agent richer primitives: language-server operations, debugger operations, hashline edits, structural rewrites, internal URL schemes for PRs/issues/skills/rules, persistent Python and JavaScript eval kernels, browser control, model/provider routing, session trees, subagents, and local memory.

The repo is also a collection of reusable packages. `@oh-my-pi/pi-coding-agent` is the CLI, `pi-agent-core` is the agent loop, `pi-ai` is the multi-provider model layer, `pi-tui` is the terminal UI, `pi-natives` is the Rust-backed native layer, `hashline` is the edit format, `pi-mnemopi` is the local memory engine, and `omp-stats` is local usage observability.

The strongest product idea is that the harness does not treat every hard action as a shell command. Renames can go through LSP, debugging can go through DAP, edits can be snapshot-anchored, AST rewrites can be previewed before application, and GitHub PRs/issues can be read as filesystem-like paths. That is the right direction for coding agents.

## Stack

| Layer | Tech |
|-------|------|
| CLI/runtime | Bun 1.3.14+, TypeScript packages, terminal TUI |
| Agent core | `pi-agent-core`, typed tools, streaming agent loop, compaction, telemetry |
| Model/provider layer | `pi-ai`, OpenAI/Anthropic/Gemini/Copilot/Ollama/OpenAI-compatible and many other provider adapters |
| Native layer | Rust workspace, N-API package, vendored `brush`, in-process search/glob/shell/PTY helpers |
| Editing | Hashline content-hash patches, AST edit previews, write/edit/resolve flow |
| Code intelligence | LSP operations, DAP debugger tool, Biome/SwiftLint/linter adapters |
| Memory | `pi-mnemopi`, SQLite, local embeddings/LLM options, MCP memory tools |
| Automation | Python FastAPI `robomp` GitHub triage bot, Docker Compose, GitHub sidecar proxy |
| UI/observability | Terminal TUI, React stats dashboard, Solid dashboard for `robomp` |
| CI/release | GitHub Actions with Bun checks, native Rust artifact caching, cross-platform release binaries |

## Key Features

### Hash-Anchored Edits

`@oh-my-pi/hashline` is a compact patch language where each file section carries a snapshot hash. If the live file has moved since the model saw it, the patcher rejects or recovers instead of blindly applying stale text. That directly attacks one of the common failure modes in model-written patches.

### IDE-Wired Tooling

The `lsp` tool exposes diagnostics, definitions, references, hover, symbols, rename, file rename, code actions, capabilities, and raw requests. The `debug` tool exposes a DAP session with launch/attach, breakpoints, stepping, evaluation, stack/scopes/variables, memory reads, modules, and output. This makes the agent use the same semantic machinery an IDE uses.

### Native Runtime Surface

The Rust/native layer pulls expensive or platform-sensitive operations closer to the process: search, globbing, PTY/shell behavior, image/clipboard/system utilities, and release binaries. For a terminal agent that runs constantly, this is more important than it looks.

### Subagents And Structured Results

The `task` surface can fan out worker agents and return typed results. That lets the parent delegate review, search, or implementation slices without parsing a pile of prose from each worker.

### Local Memory And Session Continuity

The built-in memory docs describe a local summary backend that extracts durable signal from previous persisted sessions, consolidates it, injects compact project-scoped guidance on startup, and exposes memory artifacts through `memory://` URLs. It is disabled by default, which is the right default.

### GitHub And Internal URL Schemes

The project treats GitHub objects and internal resources as readable paths: PRs, issues, agent outputs, skills, rules, conflicts, memory, and docs can all be routed through familiar read/search-style surfaces. That reduces the number of special tools a model must learn.

### Self-Hosted GitHub Triage Bot

`python/robomp` is a serious side project inside the repo: a FastAPI webhook receiver, SQLite event queue, per-issue worktrees, an `omp --mode rpc` worker, and a GitHub proxy sidecar that holds the PAT. It includes useful guardrails such as HMAC webhook verification, token isolation, env scrubbing, branch/author gates, PR-body validation, and pre-PR checks.

## Architecture

The repo is a layered monorepo rather than a single CLI script:

```text
model/provider adapters
  -> agent loop and typed tool scheduler
  -> coding-agent CLI/TUI/session layer
  -> tool surfaces: read/write/edit/search/lsp/debug/browser/task/eval/github/memory
  -> native Rust helpers, package APIs, local files, subprocesses, DAP/LSP servers
```

The architectural bet is that a coding agent improves when its tools are narrow, typed, inspectable, and closer to the real development environment. That shows up repeatedly: preview/apply flows for structural edits, hashline stale-anchor checks, LSP rename/file-rename, DAP session state, bounded debug read actions, memory as heuristic context rather than authority, and hidden tool discovery through a BM25 index.

The risky side is the same as the impressive side: the surface area is large. Browser automation ships stealth scripts; local tools can run shell commands; OAuth/provider tokens are handled across multiple adapters; memory and session logs may contain sensitive content; and `robomp` can mutate GitHub when configured. This is a power tool, not a low-risk default for untrusted repositories.

## Comparison

| Aspect | Oh My Pi | Webwright | Tracebase | CodeGraph |
|--------|----------|-----------|-----------|-----------|
| Primary job | Full local coding-agent harness | Browser tasks as rerunnable scripts | Local agent run observability | Repo code graph for agents |
| Agent tools | Broad CLI/TUI tool suite | Browser/script workspace | Read-only trace search/MCP | Code search/impact MCP |
| IDE integration | LSP and DAP built in | Browser-focused | None | Code graph/query focused |
| Edit strategy | Hashline, write, AST preview/apply | Script artifacts | No editing focus | No editing focus |
| Best fit | Replacing or extending a daily coding-agent CLI | Web automation research | Auditing agent runs | Reducing repeated codebase discovery |

Oh My Pi overlaps with several agent infrastructure projects, but its distinctive value is breadth inside one local harness. It is less focused than Tracebase or CodeGraph, but much closer to a complete daily driver.

## Self-Hosting Notes

Install paths include:

```sh
curl -fsSL https://omp.sh/install | sh
bun install -g @oh-my-pi/pi-coding-agent
```

The repo currently publishes release binaries for macOS arm64/x64, Linux arm64/x64, and Windows x64. Latest GitHub release observed during review: `v15.9.67`, published 2026-06-06.

Local verification on 2026-06-06:

- Reviewed commit: `3d93ab6ec9bf23046e9032accfc1c2e2eafc1f05`.
- GitHub metadata: 10,853 stars, 917 forks, 328 open issues, pushed 2026-06-06.
- `bun install --frozen-lockfile`: passed on Bun 1.3.14.
- `bun run ci:check:full`: failed in `biome check` because `packages/coding-agent/test/extensions-runner.test.ts` has one formatter-only blank-line issue.
- Basic secret-pattern scan found expected environment variable names, documentation examples, and test tokens, not obvious live credentials.

---

**Attribution:** can1357/oh-my-pi, MIT.
