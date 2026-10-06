# OpenHuman (tinyhumansai/openhuman)

**Repo:** https://github.com/tinyhumansai/openhuman
**License:** GPL-3.0 (study and self-host freely; no code reuse in non-GPL projects)
**Reviewed:** 2026-10-05 (check-in; prior review 2026-05-23)
**Stack:** Rust core (~566K lines, 7 crates), Tauri v2 + React desktop app, ratatui TUI, JSON-RPC 2.0 + Socket.IO, MCP, pnpm/TypeScript frontend
**What it is:** An open-source agent harness — Rust core with desktop, browser, terminal, and embeddable-library front ends — with pluggable LLM/memory/search engines, durable visual workflows, and a deep security subsystem.

---

## Update Notes

- **Date checked:** 2026-10-05
- **Prior reviewed:** 2026-05-23 at commit `e9ca97c`, v0.54.0 (package 0.54.10), 26K★
- **Current:** v0.64.10 (released 2026-09-30), 41.4K★, 4.1K forks, 277 open issues
- **Material changes since prior review:**
  - **Memory subsystem replaced.** The prior review's headline pattern — local SQLite memory tree + Obsidian-style Markdown vault — is no longer the story. Memory v2 is Recall/Fetch/Store over a pluggable CortexDB engine: hosted TinyHumans by default, or your own CortexDB endpoint. With neither, memory is off. The local-first memory pattern the prior review praised has moved to a hosted-by-default service.
  - **New `openhuman-embed` crate**: typed library facade — one `Runtime` per process, N independent agents with per-agent provider/access/skills/sandbox.
  - **New Jev integration**: a small decision model (Choice/Score/Noul probabilities, no prose) behind their System One proxy, driving tool selection (62% top-1 vs 22.5% BM25 over 1,215 tools) and browser-action confirmation. BM25 fallback without a TinyHumans credential.
  - **New workflows product**: durable typed automation graphs (22 node kinds, approvals, mid-run resume) on their tinyflows engine; agent drafts, human reviews on canvas.
  - **New sandbox domain**: per-session backend resolution (Docker vs local OS jail via `tinybox-jail`), audited elevated ops, allowlisted env passthrough; remote sessions default to no network.
  - **Crate layout restructured**: `src/openhuman` → `crates/` workspace (core, cli, embed, rpc, tinyhumans, tui, app) with flat business domains and Cargo feature gates; `kernel-floor.sh` ratchets dependency count.
  - **New benchmark docs**: in-process fleet sweep (500 agents/process at ~1.8 MiB marginal each, ~25× denser than process-per-agent), cold turn 102 ms.
  - **Loadable native modules**: tinydocs, tinyvoice, tinyjuice (token compression), tinyruntime, tinywallet, tinymcp, tinychannels, tinyconnectors.
  - README now includes a competitor comparison table (Claude Cowork, OpenClaw, Hermes Agent) that is marketing, not fact — several competitor cells are wrong or outdated.

---

## Verdict

⚠️ **Interesting, not a casual deploy candidate.** (Unchanged from prior review.)

OpenHuman remains a serious, fast-moving agent harness with engineering most frameworks don't attempt: in-process multi-agent density, a real security subsystem (approval gates, sandbox backends, deterministic prompt-injection screening with MCP-tool-description scanning, audited elevated ops), and published benchmark methodology. The verdict holds because the concerns also hold: GPL-3.0 blocks code reuse in non-GPL projects; the managed TinyHumans account is the default path for sign-in, LLM, search, embeddings, memory, and the Jev ranker; and the Memory v2 shift makes the *default* configuration more cloud-dependent than the version previously reviewed, not less. One author accounts for 22.7K of the commits — extraordinary velocity, normal skepticism about review depth applies. Study and pilot with low-risk data; don't point it at sensitive personal data without a threat-model review.

---

## What It Is

OpenHuman is a Rust core with four faces: a Tauri v2 desktop app (Win/macOS/Linux), the same React SPA in a browser, a ratatui TUI, and `openhuman-embed`, a typed facade for embedding the core in another Rust process — one `Runtime`, any number of independent `Agent`s, each with its own provider, access tier, working directory, MCP servers, skills, prompt, and sandbox.

Engines are config-selected: 26+ BYOK LLM providers plus local (Ollama, LM Studio, MLX, any OpenAI-compatible server), pluggable embeddings, memory (Recall/Fetch/Store over hosted or self-hosted CortexDB), and web search (managed or your own Parallel/Brave/Exa/Tavily/SearXNG key). A single TinyHumans API key switches on all managed services at once.

Jev is a small decision model behind the TinyHumans System One proxy: it takes a question and a fixed option set and returns calibrated probabilities (Choice/Score/Noul) without generating text. Load-bearing uses: tool selection over 215 core tools + 1,000 Composio actions (embedding retrieval + Jev: 62.0% top-1, 1.5 s p50; hierarchical app-family routing: 80.3% on Composio-only), and browser-action gating where consequential actions return `NeedsConfirmation`. Falls back to BM25 with no credential.

Workflows are durable typed automation graphs — 22 node kinds (agent calls, HTTP, code, conditions, loops, sub-workflows, approvals), schedule/event/manual triggers, mid-run resume — drafted by the agent and reviewed by the user on a canvas before saving.

## Stack

| Layer | Tech |
|-------|------|
| Core | Rust workspace: `openhuman-core` (business domains), `-cli`, `-embed`, `-rpc`, `-tui`, `-tinyhumans`, `-app` |
| Desktop | Tauri v2 + Wry, React/Vite SPA (identical bundle runs in browser) |
| IPC | JSON-RPC 2.0 + Socket.IO; per-launch bearer token between shell and core |
| Sandboxing | Docker backend or local OS jail (`tinybox-jail`), per-session policy |
| Memory | CortexDB (hosted TinyHumans or self-hosted endpoint); off with neither |
| Modules | Loadable native modules: tinydocs, tinyvoice, tinyjuice, tinyruntime, tinywallet, tinymcp, tinychannels, tinyconnectors |
| Scale | ~566K lines Rust, ~52K lines integration/e2e tests, vendored submodule deps |

## Key Features

### In-process multi-agent density

500 agents in one process cost ~1,770 KiB marginal each (1,393 MiB total) vs ~48 MiB per instance as separate processes — ~25× density. Cold agent turn 102 ms; nine-phase bootstrap 476 ms; slim build ~42 MiB RSS (51 MiB stripped binary). Methodology published in `docs/library-benchmarking.md`. Cargo feature gates control what compiles; `scripts/kernel-floor.sh` ratchets the dependency floor down-only.

### Security subsystem with real depth

`src/security/` spans 20+ modules: approval gates (TTL, triage, origin intercept, redaction, persistence), audit, credentials/keyring with consent flows, device pairing, egress policy, encryption, live policy, PII scrubbing, and a deterministic prompt-injection screener. The screener normalizes text (leet-speak, Cyrillic homoglyphs, fullwidth folding, zero-width/bidi stripping), scores against a compiled `RegexSet` DFA plus heuristics, returns Allow/Review/Block — and also scans *remote MCP tool descriptions*, rejecting hostile tools at registration. Audit lines log a SHA-256 prompt hash, not the prompt.

The sandbox domain separates where a tool runs (Docker vs OS jail), which tools are allowed (tool policy), and elevated ops (`git_operations`, `install_tool`, `docker_management`, `process_management`) that always need host access and must be audited rather than silently bypassing. Env passthrough is allowlisted; channel/cron sessions default to no network.

### Jev: decisions without generation

Cheap calibrated classification over fixed option sets, reserving the big model for prose. The published tool-search baseline is honest about tradeoffs (28 ms BM25 vs 1.5 s Jev p50) and includes the negative case (26 needless tool calls from BM25 on tool-less requests vs 1 with Jev). Automatic degradation to BM25 offline.

### Agent-drafted durable workflows

22 node kinds, triggers, approvals, mid-run resume. Agent proposes the graph; human reviews on canvas and saves. Approval-gated automation rather than YOLO scripts.

## Architecture

Clean layering: `openhuman-core/src/<domain>/` holds flat business domains (agent, memory, tools, security, channels, mcp, flows, cron, ...); `src/core/` holds only the controller contract, dispatch, registry, and event bus — no business logic, no RPC server. The RPC crate serves app/CLI/TUI identically. The desktop core is a tokio task managed by the shell with a per-launch bearer for frontend RPC. AGENTS.md is an unusually good repo map with explicit product boundaries ("do not duplicate core policy in TypeScript").

## Security and Privacy Caveats

(Carried forward from prior review, still applicable.)

- Handles the data that makes small bugs expensive: messages, documents, OAuth integrations, memory, local files, voice, screen context, tool execution.
- Default managed experience uses hosted services for sign-in, model routing, search proxying, OAuth/integration flows — and now memory (CortexDB) by default.
- Treat every inbound message, web scrape, tool result, and MCP output as untrusted; verify injection screening is applied across all channel/tool paths.
- Review credential encryption/key management, webview/scanner permissions, and local config/MCP file permissions before production use.
- GPL-3.0: fine for study/self-host; reuse in proprietary products needs legal review. Pattern extraction stays architectural-summary level.
- Early beta; one dominant author; extraordinary commit velocity.

## Comparison

| Aspect | OpenHuman | zeron | openmuse |
|--------|-----------|-------|----------|
| Core | Rust, in-process multi-agent | Rust/GPUI control plane for external CLI agents | Hono + CopilotKit server |
| License | GPL-3.0 | MIT | MIT |
| Security posture | Approval gates, sandbox backends, injection screening, audited elevated ops | Agents run bypass/yolo, unauthenticated loopback RPC | Hash-bound approvals, SSRF-guarded browser |
| Hosted dependency | Strong defaults, degrades to BYOK (Jev→BM25, memory→off) | Optional CRDT sync relay | Hard-requires hosted key |
| Maturity | v0.64.x, 41K★, 8 months, extreme velocity | Young | Alpha |

## Self-Hosting Notes

Docker compose and fly.toml included; Homebrew/.deb/AUR installers. A fully local stack is plausible (Ollama/MLX + own CortexDB + SearXNG + Privacy Mode), but default onboarding pushes the managed account, and tool-search quality degrades to BM25 without a TinyHumans credential. Contributor setup: Node 24, pnpm 10.10, Rust 1.96.1, CMake/Ninja, recursive submodules under `vendor/`.

---

**Attribution:** tinyhumansai/openhuman, GPL-3.0
