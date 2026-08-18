# Magnitude (magnitudedev/magnitude)

**Repo:** https://github.com/magnitudedev/magnitude  
**License:** Apache-2.0; permissive reuse with attribution  
**Reviewed:** 2026-08-18  
**Stack:** TypeScript/Bun, Effect-TS, React/OpenTUI, Electron/Vite, Rust, llama.cpp via llama-cpp-rs  
**What it is:** Magnitude is an open-source local coding-agent platform that bundles model recommendation, download, and llama.cpp-backed inference with terminal, web, and desktop clients.

---

## Verdict

✅ **Deploy candidate for local-agent evaluation, with a young-release caveat.** Magnitude is more than a wrapper around Ollama: it owns the local model catalog, hardware fit assessment, download/inventory lifecycle, inference server, agent daemon, clients, release packaging, and tests. The public release is still very early (`@magnitudedev/cli@0.0.6`), so I would pilot it in disposable repos first, but the architecture is serious.

---

## What It Is

Magnitude is a local-first coding agent. The README pitch is simple: install `@magnitudedev/cli`, run `magnitude` inside a project, and get an agent that can run fully private/offline after the required model assets are present.

The interesting part is below that pitch. The repo includes a TypeScript monorepo for CLI, shared client state, SDK, daemon, agent runtime, storage, providers, skills, VCS, tracing, release tooling, and UI, plus a Rust inference workspace called ICN. ICN provides OpenAI-compatible chat-completions endpoints, hardware/model fit estimation, managed GGUF artifacts, catalog locking, native llama.cpp parity tests, and release-bundled planning inputs.

That gives Magnitude a different shape from tools that expect users to configure Ollama, LM Studio, or a remote API. It is trying to make "local model included" a product boundary: profile the machine, recommend a model, acquire exact artifacts, serve the model, and connect the agent to it.

## Stack

| Layer | Tech |
|-------|------|
| CLI/TUI | TypeScript ESM, Bun, React 19, OpenTUI |
| Web UI | React, Vite, Effect Atom |
| Desktop | Electron, electron-vite, SQLite |
| Daemon/API | Effect-TS, `@effect/rpc`, ACN protocol packages |
| Agent runtime | Event/projection-heavy TypeScript runtime, tools, roles, skills, VCS integration |
| Local inference | Rust workspace, OpenAI-compatible HTTP/SSE, llama.cpp through pinned `llama-cpp-rs` |
| Model management | Curated catalog, locked package metadata, GGUF inspection, managed model store |
| Release | Bun workspaces, Turbo, Changesets, GitHub Actions, npm package, multi-platform native artifacts |

## Key Features

### Integrated Local Inference

The `inference/` workspace is a real subsystem, not a launch script. It separates backend-neutral contracts, model lifecycle, hardware/fit assessment, runtime engine, HTTP API, catalog generation, and parity evidence. The ICN README documents fake-backend smoke tests, real GGUF serving, streamed OpenAI-compatible responses, timing snapshots, and native parity workflows.

### Deterministic Model Recommendation

Magnitude's local model recommendation policy is explicit and testable. Candidates are ranked by weighted geometric utility over capability, speed, fidelity, and memory; the four user intents are just different weight vectors. That is much better than vague "best for your machine" copy because the tradeoffs are encoded in normal source and mirrored in design docs.

### Artifact Inventory Is Treated as Authority

The model-management docs are unusually careful about partial downloads, exact package identities, content hashes, immutable catalog entries, external Hugging Face cache roots, interrupted acquisition, deletion, and garbage collection. The key design choice is that completed files are the authority for installed state; metadata and cached records cannot pretend an artifact exists.

### Agent Runtime as a Layered Product

The root `AGENTS.md` documents a clean layering contract: clients consume `client-common` and SDK, SDK talks to ACN, ACN hosts the runtime and session/file/display services, provider abstractions stay separate, and protocol packages define the wire boundary. That kind of boundary is a good sign in a fast-moving agent codebase.

### Skills

Magnitude loads `SKILL.md` files from common global and project-local directories, including Claude-style, cross-agent, and Magnitude-native paths. Later directories override earlier ones, and parse/read errors are surfaced as diagnostics. It is a pragmatic compatibility move for the growing agent-skill ecosystem.

## Architecture

The core product split is:

```text
clients -> client-common -> sdk -> ACN daemon -> agent/runtime/services
                                         |
                                         v
                                  ICN local inference
```

ACN owns session lifecycle, file operations, model slots, provider credentials, mirrored state, local-model projections, display streams, leases, and onboarding. ICN owns catalog/model/inference facts. Clients receive projections and call RPCs rather than inferring filesystem or model state locally.

The release pipeline is also stronger than the version number suggests. GitHub Actions build catalog inputs, host artifacts, backend artifacts, release candidates, npm candidates, and public CLI verification. Release workflows pin Bun, Rust, and npm versions and run generated-protocol and release-preflight checks.

## Comparison

| Aspect | Magnitude | Kimi Code | Open Multi-Agent | Ollama |
|--------|-----------|-----------|------------------|--------|
| Main value | Local coding agent with built-in model management and inference | Full coding-agent runtime/platform | Embeddable TypeScript multi-agent framework | Local model server/runtime |
| Inference ownership | First-class Rust/llama.cpp subsystem | Primarily provider/runtime oriented | Caller/provider supplied | Core product |
| Agent runtime | Built-in daemon, tools, sessions, skills, VCS | Built-in CLI/server/plugins/subagents/goals | Library-level DAG orchestration | Not an agent |
| Best fit | Private local coding-agent pilot | Mature local-agent comparison | App-embedded orchestration | Model serving substrate |
| Caveat | Very early public release | High-authority broad runtime | Dynamic plans need gates | Needs an agent/client layer |

Magnitude sits between local model servers and full coding-agent runtimes. Its differentiator is owning both the agent shell and the local model lifecycle.

## Self-Hosting Notes

Basic install is npm-based:

```sh
npm install -g @magnitudedev/cli
cd your-project
magnitude
```

For development, the repo expects Bun `1.3.14`, Rust `1.91.1`, and recursive submodules for the native inference binding. ICN can run with a fake backend for smoke testing, or with an absolute GGUF model path through `bun icn:serve -- --model /path/to/model.gguf`.

Security posture looks reasonable on inspection: no obvious committed production secrets in a quick scan, design docs explicitly avoid storing auth secrets in model endpoint config, and lifecycle docs say prompts/secrets/auth values should not be attached to lifecycle diagnostics. The operational caveat is still large: a local coding agent can read files and run commands, so plugin/skill/MCP provenance matters.

## Verification

- Cloned `https://github.com/magnitudedev/magnitude.git` shallowly to `/tmp/magnitude`.
- Reviewed README, package manifests, root project instructions, ICN README, model-management design docs, service lifecycle docs, representative ACN/skills/recommendation source, CI/release workflows, and prior comparable reviews.
- GitHub API reported Apache-2.0 license, 1,140 stars, 98 forks, 7 open issues, and last push on 2026-08-18.
- Latest GitHub release and npm package at review time: `@magnitudedev/cli@0.0.6`, published 2026-08-17.
- Counted 398 test/Rust files in the checkout. No full build/test run was attempted because dependency/native setup is non-trivial for a review pass.

---

**Attribution:** magnitudedev/magnitude, Apache-2.0
