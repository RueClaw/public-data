# Keel (codejunkie99/keel)

**Repo:** https://github.com/codejunkie99/keel  
**License:** MIT (© 2026 codejunkie99). Free reuse with attribution. Third-party parts keep their notices in `licenses/`: the GPUI UI base is MIT (© 2026 Wing, from the "Avid" coding app), the embedded agent loop is an MIT port of `deepseek-ai/deepseek-harness` v0.1.0-rc.5, the Laya Core ML runtime is Apache-2.0, and tree-sitter grammars carry their own licenses. GPUI comes from a pinned fork of Zed (`wingleeio/zed`). Zed's `gpui` crates are Apache-2.0, but the editor as a whole is mixed-license, so check the pinned crates before you ship a binary.  
**Reviewed:** 2026-09-28 (commit `5cef456`, v0.2.0)  
**Stack:** Rust 2024 (~168k lines, ~50 workspace crates), GPUI (Zed fork), tokio, rusqlite, Loro CRDT, alacritty_terminal, tree-sitter, Agent Client Protocol adapters, Python Core ML worker (laya-coreml), optional hosted TypeSafe Jev API  
**What it is:** A native macOS workspace for running existing coding agents (Claude Code, Codex, Cursor, Grok, Hermes, pi over ACP, plus an embedded DeepSeek loop). A small "selector" model (local Laya via Core ML, or hosted Jev) picks a route for each fresh task from candidates the host prepared, and the host re-validates the pick before applying it.

---

## Verdict

📚 **Study. The host-owned "selector picks an ID, host validates" boundary is well designed and honestly documented. The app itself is a four-day-old, macOS-only, unsigned dev build with no CI.**

The useful part is the decision architecture. The host builds candidates, the selector model returns an opaque candidate ID or abstains, and the host re-checks freshness (task revision, read-set fingerprint, expiry, permissions) before anything happens. A rejected or stale pick falls back to the normal route, and each decision leaves a bounded receipt you can export as JSONL for replay. The docs are unusually candid about limits: "a valid ID proves that a response fits the contract, it does not prove that the route improved the code", there's no automatic training, and external ACP agents keep their own tool loops, so the selector only affects the initial route.

Against that: the repo appeared on 2026-09-22 as a ~6 MB Rust import. It's a rebrand of someone else's GPUI coding app plus a port of DeepSeek's harness, with a build report that reads like an agent's task log. There are no GitHub Actions, no releases (you build from source), and packages are ad hoc signed. The engine exposes an unauthenticated WebSocket RPC on a fixed loopback port. There's also no evidence yet that selector routing beats just picking a model yourself, and the authors say so. Read `docs/decision-architecture.md` and `jev_routing.rs` for the pattern. Don't adopt it as a daily driver yet.

---

## What It Is

- **Workspace UI:** sessions, composer (images, macOS Dictation), transcript, terminal (alacritty_terminal + portable-pty), changes view with a git lane graph, and settings in one GPUI window. New in 0.2.0: an **agent graph** (⇧⌘G) that shows sessions, subagents, and files touched as nodes, with steer/stop on each node.
- **Coding agents:** external CLIs through ACP (each keeps its own auth, model config, and tool loop), plus an in-process DeepSeek agent loop where the host controls tool exposure.
- **Decision modes:** Laya (local Core ML, default), Jev (hosted by TypeSafe, opt-in, needs an existing key file or env var), or Normal (no selector).
- **CLI/ops:** `keel headless`, `keel daemon install`, `keel status`, `keel laya status`, `keel decisions export|report`, `keel computer-use decide` (returns an action ID only, never clicks).

## Stack

| Layer | Tech |
|-------|------|
| UI | GPUI from `wingleeio/zed` pinned at `5d1f83d` (backdrop blur, edge fades, GPU memory fixes), ~43k lines in `crates/ui` |
| Engine | `crates/engine` (~20k lines): sessions, run journal, registry, auth, routing, decision log, updater hooks |
| IPC | WebSocket JSON RPC (`crates/rpc`) on `127.0.0.1:27655` by default |
| Storage/sync | rusqlite (bundled), Loro CRDT + loro-protocol for a cloud "SessionRoom" edge that isn't in this repo (disabled in the local build) |
| Agents | `crates/harness` ACP adapters; `crates/dsh/*`: 18-crate Rust port of deepseek-harness |
| Selectors | `crates/laya-local` (Python JSONL worker over a Core ML checkpoint pinned by Hugging Face revision), `crates/jev-core` (direct `api.typesafe.ai/v1/systemone` client, model `jev-1.13.0`) |
| Packaging | `scripts/package-macos.sh`, ad hoc codesign, full (with model) and light (downloads model) ZIPs |

## Key Features

### Host-Prepared Candidates, Selector Picks an ID
`SelectionInput` carries bounded current state and opaque candidate IDs. Each prepared action stores its payload, task revision, read-set fingerprint, preconditions, expiry, and authorization result. The selector can't write commands or patches. It chooses, abstains, or gets overruled. Laya gets a smaller shortlist, and each backend has its own abstention thresholds (`min_confidence`, `min_fit`). Pinned routes, live sessions, and resumed sessions are never re-routed.

### Tool-Focus Gating in the Embedded Loop
For the in-process DeepSeek loop, the selector picks one of four focus IDs (`inspect`, `implement`, `verify`, `answer`). The host then advertises only that tool bundle and re-checks each tool call's name against it before dispatch. `answer` exposes no tools. This is a clean way to narrow a model's action space per step without trusting the model to stay in scope.

### Decision Receipts and Replay Export
Each decision writes a versioned record to the chat: candidates, result, confidence/fit, validation, fallback, and observed outcome (tool dispatch/denial/failure counts). It doesn't invent a natural-language rationale. `keel decisions export` emits one replay case per receipt, and `report` aggregates by backend, stage, and validation. The roadmap's next steps are replay against a baseline and held-out comparison sets, i.e. the evaluation loop the project doesn't have yet.

### Honest Scope on External Agents
The docs say plainly that ACP `availableCommands` is metadata, that Keel sends `/name` as prompt text, and that controlling an external agent's loop end to end would need an interception point ACP doesn't expose. Most "agent orchestrator" projects blur this line.

### Engine/Viewport Split
One engine owns one data directory (an instance lock rejects a second engine). The UI either attaches to a running daemon over IPC or embeds the engine in-process. An append-only run journal replays live streams after a crash and marks interrupted runs.

## Architecture

```
GPUI window ──ws://127.0.0.1:27655──▶ engine (in-process or daemon)
                                         ├─ jev_routing.rs   build candidates for a fresh, unpinned task
                                         ├─ decision_mode.rs Laya │ Jev │ Normal
                                         │     ├─ laya-local ─▶ python worker.py (Core ML, JSONL)
                                         │     └─ jev-core   ─▶ api.typesafe.ai (bounded request, 64 KB cap)
                                         ├─ re-validate (revision, fingerprint, expiry, auth) → apply or fall back
                                         ├─ harness: ACP adapters (Claude Code, Codex, Cursor, Grok, Hermes, pi)
                                         ├─ dsh agent-loop: embedded DeepSeek with focus-gated tools
                                         ├─ decision_log.rs  receipts → export/report
                                         └─ run_journal, sqlite, Loro docs
```

The codebase is large for its age: ~168k lines of Rust and ~1,500 `#[test]`/`#[tokio::test]` functions. Much of it is inherited (UI base, harness port, sync/cloud code for a hosted edge that isn't published). Comments reference internal docs (`ARCHITECTURE §1`, `docs/memory-plan.md`) that aren't in the repo.

## Security

- **Local IPC has no authentication.** The engine serves WebSocket RPC on `127.0.0.1:27655` (fixed default, `KEEL_IPC_PORT` to override). The only guard is rejecting handshakes that carry an `Origin` header. That blocks browser pages, since browsers always send Origin, but any local process or other local user can connect without a token and drive an engine that spawns coding agents and terminals. A per-launch token in a 0600 file would close this.
- **Sign-in callback** binds loopback only (`auth.rs`). The cloud/WorkOS paths are disabled in the local build.
- **Credentials:** the Jev key comes from an app-owned key file, which is refused unless it's owned by the current user and its mode is no wider than 0600, and optionally from `TYPESAFE_API_KEY` or a legacy `~/.codex/codex-router/typesafe-api-key.secret`. Both fallbacks are off in the `app_owned` config. There's no key-entry UI.
- **Jev data egress:** in Jev mode, a bounded decision request with task state and candidate summaries goes to TypeSafe's hosted API. Laya mode keeps selection local, though your coding agents still call their own providers.
- **Model download:** the Laya checkpoint (~680 MB) is pinned to a Hugging Face commit revision with expected file sizes. The docs say packaging checks SHA-256 for all eight runtime inputs.
- **Updater:** it verifies SHA-256 only when the manifest supplies one, and otherwise logs a warning and proceeds. It also downloads over whatever scheme the edge URL uses. The default edge is `http://127.0.0.1:8787` (dev), so it's effectively inert unless configured. Auto-apply needs `KEEL_AUTO_UPDATE`.
- **Shell use:** the embedded agent's shell tool runs `bash -c <command>`, which is expected for a coding agent and gated by focus bundle and approvals. The macOS relauncher interpolates the bundle path into a `/bin/sh -c` string.
- **No hardcoded secrets** (`sk-`, `AKIA`, `ghp_` patterns) found.
- **No CI at all.** There's no `.github/` directory, so none of the 1,477-test claim is independently visible.
- **Distribution:** ad hoc signed, not notarized. Gatekeeper will reject it as a downloaded app.

## Maturity

- Created 2026-09-22, last push 2026-09-25. 293 stars, 39 forks, and 2 open issues at review time. There are no releases. You build from source on Apple Silicon with macOS 15+.
- Single author, who also publishes `agentic-stack`, `sageroute`, and `jev-engineering`. Development is fast, merged through PRs with "address review findings" commits.
- The docs are good and scoped: guide, build, architecture, connections, onboarding, provenance, and a proposal clearly labeled as a proposal. `docs/archive/build-report-0.2.0.md` lists what was and wasn't checked. It notes that Hermes ACP was unavailable, Cursor and pi lacked auth, and no paid Jev call was made.

### Validation on 2026-09-28

- `git clone --depth=1` at `5cef456`; read README, LICENSE, THIRD_PARTY_NOTICES, `licenses/`, the docs above, and `rpc/server.rs`, `engine/lib.rs` (IPC), `update/lib.rs`, `jev-core`, `laya-local/worker.py`, and `apps/keel/src/main.rs`.
- `python3 -m py_compile` on both Python files: pass. `bash -n` on the three shell scripts: pass.
- **Rust suites not run.** There was no cargo toolchain on the review host (Linux), and resolving the workspace pulls a full Zed fork over git. The vendor's "1,477 tests across 153 targets" figure comes from their build report and wasn't reproduced. The app, the Laya worker (Core ML), and Jev routing are macOS/Apple Silicon or paid-API dependent and weren't exercised.

## Comparison

| Aspect | Keel | Conductor / Crystal-style agent GUIs | Zed agent panel | sageroute (same author) |
|--------|------|--------------------------------------|-----------------|--------------------------|
| Form | Native macOS app (GPUI) + headless daemon | Desktop app wrapping CLIs in worktrees | Editor-integrated | HTTP proxy |
| Agents | ACP (6 CLIs) + embedded DeepSeek loop | Mostly Claude Code / Codex | ACP agents | Any OpenAI/Anthropic client |
| Routing | Selector model picks among host-prepared routes per fresh task | Manual | Manual | Trajectory signals mid-session |
| Audit | Per-decision receipts, JSONL export | Session logs | Thread history | Headers/logs |
| Platform | macOS 15+ Apple Silicon | macOS mostly | macOS/Linux/Windows | Any |
| Maturity | Days old, no CI, unsigned | Shipped products | Mature | Early |

## Self-Hosting Notes

- Build from source per `docs/build.md`. You need to supply the Laya worker (and optionally the checkpoint) to `scripts/package-macos.sh`, or use the light package and download the model from onboarding.
- Normal mode works without any selector. Laya adds ~680 MB of Core ML weights. Jev needs a TypeSafe key placed as a file, and it sends task state off-box.
- Until the IPC gets a token, don't run `keel daemon` on a shared multi-user Mac. Change `KEEL_IPC_PORT` if 27655 collides.
- Leave `KEEL_AUTO_UPDATE` unset unless you control the edge and publish checksums in the manifest.

## Reusable Patterns

- **Selector returns an ID; host owns execution.** Keep models out of the permission path: prepare candidates with revision, fingerprint, and expiry, accept only an ID or abstention, re-validate at apply time, and fall back deterministically.
- **Per-step tool-bundle focus.** Pick a focus, advertise only that bundle, and re-check each tool name at dispatch.
- **Decision receipts as replay cases.** Record candidates, choice, validation, fallback, and observed outcome (no invented rationale), and export them for baseline-vs-candidate replay before changing policy.
- **Origin-rejecting loopback WebSocket** as a cheap anti-browser guard. Pair it with a token for local-process isolation.

---

**Attribution:** codejunkie99/keel, MIT (includes MIT UI base © Wing, MIT deepseek-harness port © DeepSeek, Apache-2.0 laya-coreml runtime)
