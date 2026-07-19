# Oh My Pi (can1357/oh-my-pi)

**Repo:** https://github.com/can1357/oh-my-pi
**License:** MIT. Permissive reuse with attribution.
**Reviewed:** 2026-07-19
**Prior review:** 2026-06-06 at `3d93ab6ec9bf23046e9032accfc1c2e2eafc1f05`, release `v15.9.67`
**Current review:** `39c95e5e29b1c8b082059f57421ce445c3dffdd4`, release `v17.0.5`
**Stack:** TypeScript/Bun monorepo, Rust native crates via N-API, Python/FastAPI bot, React/Solid dashboards, SQLite memory, Docker/GitHub Actions
**What it is:** Oh My Pi is a terminal coding-agent harness that gives a model IDE-grade tools: hash-anchored edits, LSP/DAP, native shell/search helpers, browser automation, subagents, memory, internal resource URLs, MCP, provider routing, collaboration, and GitHub automation.

---

## Update Notes - 2026-07-19

This is a material update, not a simple freshness check. Since the June review, Oh My Pi moved from `v15.9.67` to `v17.0.5`, grew from about 10.9k stars / 917 forks to 18.5k stars / 1.7k forks, and changed core tool presentation and runtime behavior.

Material changes:

- v17 introduced `xd://` virtual tool devices. Discoverable custom, extension, MCP, RPC host, image-generation, and TTS tools now mount behind read/write resource devices instead of all living as top-level schemas.
- `irc`, `job`, and `launch` became a unified `hub` tool for messaging, job control, and process supervision.
- BM25 tool discovery was removed. Connected MCP tools are enabled and mounted under `xd://`.
- The direct `ssh` execution tool was removed, while `ssh://` read/write/search and host-management paths remain.
- Collaboration matured into encrypted live session sharing with full-control and view-only links, native TUI guests, and a browser guest client.
- The auth-broker/auth-gateway docs now describe a remote credential vault plus provider forward-proxy that can keep OAuth refresh/access tokens off developer laptops.
- MCP lifecycle docs are much stronger: fast startup gate, cached deferred tools, reconnect behavior, per-server isolation, and teardown semantics.
- The prior local `bun run ci:check:full` Biome failure is gone.

Verdict remains ✅ Deploy candidate, with the caveat that this is a high-authority power-user harness. Default approval mode is still `yolo`, subagents run headless/yolo with the parent task as the authorization boundary, and browser/MCP/collab/auth/GitHub surfaces need explicit operator policy before sensitive use.

## Verdict

✅ **Deploy candidate for people who want a full-power local coding agent.** Oh My Pi remains one of the strongest public examples of an IDE-wired agent harness. It has moved beyond "terminal model with bash" into a broad local runtime: semantic code tools, native command/search execution, structured subagents, memory, collaboration, MCP, provider routing, and a serious GitHub bot.

The reason to use or study it is still the same: it attacks the reliability problems coding agents actually hit. Stale edits, weak renames, noisy command output, missing debugger state, unstructured worker handoffs, and repeated context rediscovery are all treated as harness problems, not just prompt problems.

The main risk is also the same, only larger: the surface area is big and capable. Do not treat it as low-risk in untrusted repositories or credential-heavy environments.

## What It Is

Oh My Pi, shipped as `omp`, is a fork/evolution of Mario Zechner's Pi. It has grown into a full local coding-agent harness with a TUI, provider adapters, typed tools, LSP, DAP, browser automation, hashline edits, AST previews, persistent eval kernels, internal URL schemes, local memory, subagents, plugins, skills, usage stats, collaboration, and a GitHub triage/fix bot.

The core product idea is that an agent should use the real development environment. A rename should go through LSP. A runtime failure should be inspectable through DAP. A patch should be tied to the file snapshot the model saw. Tool catalogs should be readable as resources. Subagent output should be structured enough for the parent to consume by path.

## Stack

| Layer | Tech |
|-------|------|
| CLI/runtime | Bun 1.3.14, TypeScript packages, terminal TUI |
| Agent core | `@oh-my-pi/pi-agent-core`, typed tools, streaming loop, compaction, session state |
| Provider layer | `@oh-my-pi/pi-ai`, `@oh-my-pi/pi-catalog`, many API/OAuth/local-provider adapters |
| Native layer | Rust workspace, N-API package, vendored shell/coreutils/search helpers |
| Editing | `@oh-my-pi/hashline`, write/edit/resolve paths, AST edit previews |
| Code intelligence | LSP operations, DAP debugger tool, linter adapters |
| Tool presentation | Essential tools plus discoverable `xd://` virtual devices |
| Memory | `@oh-my-pi/pi-mnemopi`, SQLite, Hindsight/Mnemopi docs, local memory tools |
| Collaboration | End-to-end encrypted `/collab`, relay, browser guest client, `pi-wire` protocol |
| Automation | `python/robomp`, FastAPI, SQLite event queue, GitHub proxy sidecar |
| CI/release | GitHub Actions, Bun/Biome/tsgo checks, Rust native artifacts, release binaries |

## Key Features

### `xd://` Tool Devices

The largest architectural change is the `xd://` tool transport. Instead of giving the model a huge flat schema list, OMP keeps essential tools up front and mounts discoverable tools as resources. `read xd://` lists devices, `read xd://<tool>` documents one, and `write xd://<tool>` executes it.

This is a good direction for large agent harnesses. It keeps the live tool surface smaller while preserving tool reachability. It also gives MCP and extension tools a more uniform presentation path.

### Hash-Anchored Edits

`@oh-my-pi/hashline` remains one of the repo's best reusable ideas. File sections carry snapshot anchors, so stale context can be rejected before a patch corrupts a file. v17 made the seen-line guard opt-in via `edit.enforceSeenLines`, which improves ergonomics for long/clipped lines but means strict read-before-edit enforcement is not the default.

### IDE-Wired Tooling

The LSP surface covers diagnostics, definitions, references, hover, symbols, rename, file rename, code actions, capabilities, and raw requests. The DAP surface covers launch/attach, breakpoints, stepping, evaluation, stack/scopes/variables, memory reads, modules, and output.

That remains the strongest argument for the harness. The agent can use IDE semantics instead of hand-rolling refactors through search and shell.

### Unified Hub And Structured Subagents

v17 folds `irc`, `job`, and `launch` into `hub`, making coordination, job control, and process supervision one essential surface. The `task` system can fan work into isolated workers and return structured outputs. v17 also fixed a serious class of issues where isolated `task` subagents could mutate the parent checkout or stack parallel branches.

### Collaboration

`/collab` now supports encrypted live session sharing. Full links include a write token; view-only links omit it. Payloads are AES-256-GCM sealed client-side, and the relay sees room ids, connection counts, ciphertext, and frame sizes. Guests can use native TUI or browser clients; full-control guests can prompt, interrupt, and control subagents through the host.

This is powerful and useful, but links are capability-bearing secrets.

### Auth Broker / Gateway

The auth broker and gateway are notable additions. The broker holds the canonical SQLite credential vault and refreshes OAuth tokens. The gateway is a forward proxy for OpenAI Chat Completions, Anthropic Messages, OpenAI Responses, and OMP-native streams, resolving credentials server-side so clients do not see access tokens.

This is the right pattern for shared or containerized agent runners, but it moves trust to the broker host and its bearer-token/network controls.

### `robomp` GitHub Bot

`python/robomp` is still a serious side project: FastAPI webhook receiver, SQLite queue, per-issue worktrees, `omp --mode rpc` workers, GitHub sidecar proxy, HMAC verification, token isolation, env scrubbing, status contracts, retry behavior, PR gates, and a much larger test suite than in June.

## Architecture

The useful mental model:

```text
model/provider adapters
  -> agent loop and typed tool scheduler
  -> coding-agent CLI/TUI/session layer
  -> essential tools + xd:// mounted devices
  -> LSP/DAP, browser, MCP, eval kernels, memory, shell/search/native helpers
  -> local files, subprocesses, browser/CDP, provider APIs, GitHub, SQLite
```

The design is more coherent than in June because `xd://` gives large tool sets a consistent shape. The tradeoff is that policy now matters even more: mounted tools may include MCP, custom extensions, browser/device actions, image generation, and TTS, and the model can discover them on demand.

## Security And Operational Notes

- Default `tools.approvalMode` is `yolo`; `--auto-approve` and `--yolo` also force yolo.
- Tools without an approval declaration are treated as `exec`, but in yolo mode they are allowed unless a user policy overrides them.
- Non-yolo modes exist: `always-ask` and `write`.
- Subagents run headless with yolo; the parent `task` approval is the authorization boundary.
- Secret obfuscation exists but is disabled by default.
- `/share` redacts configured secrets by default before uploading encrypted snapshots.
- Browser automation remains sensitive. The docs say stealth patches apply only in headless mode, not spawned or externally connected browsers.
- CI now has a stronger release/concurrency/native-artifact story, but many workflow/action references are still tag-based in non-release paths (`actions/checkout@v4`, cache/upload/download tags, vouch actions, etc.).
- Current HEAD's latest CI run was red, while the `v17.0.5` release commit was green.

## Local Verification

Reviewed current `main` at `39c95e5e29b1c8b082059f57421ce445c3dffdd4`.

Passed locally:

- `bun install --frozen-lockfile`
- `bun run ci:check:full`
- `bun run test:scripts` - 38 tests
- `bun run collab:web:build`
- `python/omp-rpc` tests - 53 passed
- `python/robomp` tests - 601 passed, 4 skipped
- Python `ruff check` and `ruff format --check`

Not completed locally:

- `bun run ci:test:ts:workspace` failed because native-dependent suites could not load `pi_natives.darwin-arm64.node`.
- `bun --cwd=packages/natives run build` failed on local stable Rust 1.95.0 because `pi-natives` uses `#![feature(alloc_error_hook)]`; upstream native CI installs nightly.
- Full Rust/native/release matrix was not run locally.

GitHub metadata on 2026-07-19:

- Stars: 18,476
- Forks: 1,720
- Open issues: 561
- Latest release: `v17.0.5`, published 2026-07-18
- License: MIT

## Recommendation

For a technical user who wants a powerful local coding harness, OMP is still a deploy candidate. Use it with a clear policy profile:

- Use `always-ask` or `write` approval mode for untrusted repos.
- Treat collab links, auth-broker tokens, provider OAuth, GitHub bot credentials, and session/share artifacts as sensitive.
- Keep MCP/custom extension tools scoped and reviewable.
- Prefer release commits with green CI over arbitrary HEAD.

For builders of agent infrastructure, the repo is a high-value pattern source. The biggest ideas to study are still IDE-wired tools, snapshot-anchored edits, structured subagent outputs, filesystem-shaped resources, local memory with freshness warnings, and now `xd://` as a scalable mounted-tool presentation model.

---

**Attribution:** can1357/oh-my-pi, MIT.
