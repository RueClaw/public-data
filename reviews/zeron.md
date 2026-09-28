# Zeron (zeronsh/zeron)

**Repo:** https://github.com/zeronsh/zeron  
**License:** MIT. Free reuse with attribution. Third-party portions are listed in `THIRD_PARTY_NOTICES.md`: tree-sitter grammars (MIT), a `gpui-component` fork (Apache-2.0), mermaid-rs-renderer and Ropey (MIT), Symbols icons (MIT), and curated theme palettes with per-theme upstream notices. GPUI is pinned to a Zed revision (Apache-2.0), and the architecture doc says Zed's GPL crates are deliberately not used.  
**Reviewed:** 2026-09-28 (commit `c2744c2`, v0.2.97)  
**Stack:** Rust (tokio, GPUI UI, Loro CRDT, SQLite snapshots, alacritty_terminal + portable-pty, tree-sitter), TypeScript Cloudflare Worker + Durable Objects + R2 for optional sync (WorkOS auth), Swift iOS client  
**What it is:** A native desktop and headless "control plane" for coding agents (Claude Code, Codex, Cursor, Devin, Grok, Hermes, Pi, Antigravity, opencode, plus ACP agents). A per-device Rust engine runs the agents, owns terminals, worktrees, and diffs, and stores sessions locally. Optional sign-in syncs sessions over a hosted relay so you can start an agent on one device and drive it from another.

---

## Verdict

⚠️ **Interesting. It's an ambitious, well-architected multi-device agent cockpit with real engineering depth. But it runs every agent in full-bypass ("yolo") mode, its local RPC port has no authentication, and sync depends on the vendor's hosted edge. Use it on a single-user machine you're comfortable handing to autonomous agents. Don't use it on shared hosts.**

What's good: the design doc is unusually honest and specific. It has a clean split between an immutable `WorkspaceScope` (Local / Synced / Development, fixed at engine start) and live `AuthState`, so a token refresh or sign-in can never silently swap databases or attach network transports to a local-only run. Session transcripts and a durable command queue live in Loro CRDT docs. Send, steer, and interrupt are ledger entries executed only by the owning host device, marked processed *before* execution, so offline sends queue and replays are idempotent. The UI is a GPUI app with block-granularity virtualized transcripts, incremental markdown re-parse of the streaming tail, and paint-only syntax colouring. There are ~2,700 Rust tests, no telemetry SDKs, and a local-only mode that needs no account.

What gives pause:
- **All agents run fully unattended.** The Codex harness forces `approvalPolicy: "never"` plus the `danger-full-access` sandbox. The Claude adapter auto-approves every `can_use_tool`. ACP permission requests are auto-accepted. The code comments call this "yolo mode" and say it's for parity. There's no per-session permission setting yet.
- **Local RPC trust is "anything on loopback".** The engine serves WebSocket RPC on `127.0.0.1:27654` with no token. Browser pages are blocked by rejecting any handshake that carries an `Origin` header, which is a good anti-CSRF/DNS-rebinding measure. But any local process or user can drive agents, terminals, and workspace files. That matters for the "always-on VPS" use case the README promotes.
- **Synced devices are fully trusted.** Any device on the account can list, read, and write another device's workspace files, including `.env` when "Show ignored files" is on. The docs state this plainly.
- **Sync isn't self-hostable yet.** A self-hosted backend contract is explicitly deferred. The edge runs on zeron.sh with WorkOS.
- **Very young and moving fast:** repo created 2026-07-20, v0.2.95→v0.2.97 in one day, 140 open issues.

---

## What It Is

- **Engine (`zeron-engine`):** a headless-capable Rust daemon. It runs harness subprocesses, keeps an on-disk run journal (resumable `seq` replay, crash auto-resume, 10-minute stall watchdog), manages repos and worktrees under `~/.zeron/worktrees`, captures diffs (patch + numstat + untracked, 3 MiB cap), handles uploads and terminals, and does agent-account credential slot swapping (macOS Keychain, files elsewhere).
- **UI (`zeron-ui`):** a GPUI viewport that speaks the same typed RPC whether the engine is in-process or a separate daemon. It has an attention-sorted Sessions sidebar, "spaces" (device + folder pairs), a composer with Send→Steer→Stop, a question panel for agent `AskUserQuestion`, a terminal, a diff pane, and a theme system that compiles VS Code themes.
- **Headed/headless single binary:** `zeron` opens the UI and also serves its embedded engine on the IPC port so other viewports can attach. `zeron headless` runs only the engine (e.g. on a VPS).
- **Optional sync:** Loro docs ride a row protocol to per-chat ChatRoom Durable Objects. Devices connect through a DeviceRoom relay (the WebRTC stack was removed). A private per-user registry room holds the sidebar index, and attachments go to R2. APNs push goes to the iOS app.
- **MCP (`crates/mcp`):** proxies the engine's IPC to MCP clients.
- **Harnesses (`crates/harness`):** Claude Code via stream-json subprocess, Codex via app-server JSON-RPC, Cursor, opencode, a generic ACP adapter, adapter/archive installers, secret redaction, and shell-env capture.

## Stack

| Layer | Tech |
|-------|------|
| Device side | Rust (~355k lines incl. tests), tokio, tokio-tungstenite, serde/ndjson framing |
| UI | GPUI (pinned Zed rev) + `zeronsh/gpui-component` fork, pulldown-cmark, tree-sitter highlighting |
| State | Loro CRDT (session doc + workspace registry), SQLite snapshots, processed-command ledger |
| Terminal | alacritty_terminal (vte) + portable-pty |
| Sync edge | TypeScript Cloudflare Worker, Durable Objects (ChatRoom, DeviceRoom, registry), R2, WorkOS JWKS auth, APNs |
| Mobile | Swift iOS app (`apps/ios`, TestFlight workflow) |
| Distribution | curl installer (Linux), macOS desktop release, Windows per-user installer and portable ZIP, in-app updater |
| CI | UI tests, preview tests, Windows build, release, TestFlight, Cursor SDK compatibility, edge auto-deploy |

## Key Features

### Local-first profile boundary
`WorkspaceScope` is captured once at startup and selects the store root (`profiles/local/` vs `orgs/{org}/{user}/`), journals, and upload jail. `zeron login`/`logout` refuse to change credentials while an engine owns the data directory, and the switch takes effect on the next start. Signing in never uploads or imports local sessions. This is a clean answer to the common failure where a sign-in flow quietly starts syncing data the user thought was local.

### Durable command plane
Send, steer, interrupt, and respond-input are append-only per-device entries in the session doc's `commands` list, with host-only outcomes and dedupe/TTL/supersede rules. Only the chat's host device executes them, and it marks them processed before executing. A peer can queue a run while the host is asleep, and a durable nudge wakes it. `scripts/e2e-smoke.sh` proves this with two headless engines against a real edge.

### CRDT schema choices with measured rationale
Message bodies are `LoroText` (the doc cites a measured 1.03× oplog overhead) rather than last-writer-wins value rewrites. Continuations split at 256 KB, compaction happens at 8 MB, and full tool inputs stay in the host's local run journal while only render parts sync. Token-usage display was deliberately dropped because it's a poor fit for CRDTs.

### Transcript rendering
Rows are one per markdown block or tool group, with stable `msgId#blockId` IDs. Row heights are memoized by (id, length, width). A stick-to-bottom spring breaks on user scroll and re-engages within 70 px. Only the streaming tail is re-parsed from the last stable block boundary. Code block height is lines × line-height, so highlighting never affects layout.

### Updater
The updater streams through a `.partial` sidecar and verifies the manifest's sha256. If the manifest has no checksum, it logs a warning and **skips verification**. There are no signatures, and the manifest and binaries come from the same edge. A service-installed daemon restarts into a new version only once no agent run or terminal is active.

## Architecture

```
gpui UI ─ in-proc/localhost RPC ─ engine A ══ DeviceRoom DO relay ══ engine B ─ RPC ─ gpui UI
                    │       optional edge Worker: auth, rooms, R2        │
                    └── optional chat2 sync ──  ChatRoom DO (per chat) ──┘
                                          └─ Workspace registry room ────┘
```
(from ARCHITECTURE.md)

This is a ground-up Rust/GPUI rewrite of an earlier Electron + Postgres + Hono + WebRTC version. Postgres, the server, and WebRTC are gone, and the edge absorbed auth routes. Milestones M0–M4 are marked shipped. M5/M6 are "shipped with named gaps" (composer attachment UI, reduced motion, engine hardening such as an instance lock and watchdogs, edge production deploy per the doc; the doc may lag the code). The Durable Objects stay in TypeScript by recorded decision (`docs/research/durable-objects-language.md`). The `docs/` tree is extensive: ADRs, performance write-ups per platform, regression notes, sync capacity calibration.

## Security

- **Agent autonomy:** Codex runs with sandbox `danger-full-access` and approval policy `never`. Claude runs `--dangerously-skip-permissions` when `auto_approve` is set and auto-approves `can_use_tool` regardless. ACP permission requests are auto-accepted with the agent's preferred allow option. Title-generation runs are the exception (read-only sandbox). Treat every session as an agent with your user's full privileges.
- **Local IPC:** WebSocket on `127.0.0.1` (default port 27654), no authentication token. It rejects any handshake with an `Origin` header, which blocks browser pages, including DNS-rebinding attacks. Native local clients are trusted unconditionally. On multi-user machines, other local users can connect.
- **Remote workspace access:** relay-forwarded file requests are checked by the owning engine for workspace-relative paths, containment, symlinks, and write conflicts. `.git` is always excluded. Ignored files (`.env`) are readable and writable by any signed-in device when requested. The docs explicitly say ignored-file visibility isn't an authorization boundary.
- **OAuth callbacks:** loopback listeners on `127.0.0.1`/`::1` for agent-account PKCE flows.
- **Secrets:** no `sk-`/`AKIA`/`ghp_`/`sk_live_` patterns in the tree. The harness crate has a `redact.rs` for output redaction.
- **Telemetry:** no PostHog, Sentry, or other analytics SDK found in the Rust crates.
- **CI:** 7 of 8 workflows declare `permissions:` (`deploy.yml` doesn't). All actions use floating major tags (`actions/checkout@v4`, `Swatinem/rust-cache@v2`, `softprops/action-gh-release@v2`, `dtolnay/rust-toolchain@stable`), with no SHA pinning, including in the release workflow. The edge auto-deploys on push to main with a Cloudflare token.
- **Supply chain:** `curl | sh` installer. Updates verify sha256 from a same-origin manifest when present, and there's no signing.

## Maturity

- 2,254★, 220 forks, 140 open issues. Created 2026-07-20, last push 2026-09-28. Releases ship several times a day (v0.2.95, .96, and .97 on 2026-09-27/28).
- ~2,676 Rust `#[test]`/`#[tokio::test]` functions, edge Vitest unit tests plus 9 workerd-tier test files, iOS unit and UI test targets, and a two-engine e2e smoke script.
- Sponsored (The Context Company), with GitHub Sponsors. Chinese README provided.
- Parity gaps are tracked in `docs/PARITY.md`.

### Validation on 2026-09-28

Static review only.
- `git clone --depth=1` at `c2744c2`. I read README, ARCHITECTURE.md, THIRD_PARTY_NOTICES.md, CI workflows, the RPC server (`crates/rpc/src/server.rs`), harness adapters (`codex/mod.rs`, `claude/mod.rs`, `acp/mod.rs`), and the updater (`crates/update/src/lib.rs`).
- Secret, telemetry, and bind-address greps are summarised above.
- **Not run:** there's no Rust toolchain on the review host, and a GPUI workspace with a Zed git dependency isn't buildable on a 2 GB machine. The edge's `npm ci` was blocked by the host's package threat-intel gate in this unattended run, so the Vitest suites weren't executed either. No test results or performance claims are reproduced here.

## Comparison

| | Zeron | TUIOS | Plain tmux + agent CLIs |
|---|---|---|---|
| Form | Native GPUI desktop + headless engine + iOS | Terminal multiplexer + daemon | Terminal |
| Multi-device | Yes (hosted CRDT relay; self-host deferred) | SSH hosts, federation | ssh |
| Agent permissions | Always bypass/yolo | Pane grants, Inbox approvals | Whatever the CLI does |
| Local control auth | Loopback TCP, no token (Origin-rejecting) | Unix socket 0700 | Unix socket |
| Transcript model | Structured (stream-json / app-server), CRDT-synced | Terminal screen + hooks | Terminal screen |
| License | MIT | MIT | ISC |

## Self-Hosting Notes

- Linux: `curl -fsSL https://zeron.sh/install.sh | sh` installs and starts a persistent daemon (local-only, no account). The desktop sidebar browser needs an extra Linux browser runtime.
- macOS: desktop release, or build from source and `zeron daemon install` (launchd). Windows: per-user installer, no admin rights.
- Run it only on single-user machines, or firewall the loopback port with per-user network namespaces or containers. Agents have full access, so pair it with a disposable VM or container if you let it touch anything important.
- For VPS use, remember that the IPC port is open to every local user, and signed-in devices can read that VPS's workspaces, including ignored files when requested.
- `ZERON_AUTO_UPDATE=0` disables background update downloads. Pin versions if you need stability; the release cadence is multiple times a day.
- Sync requires the vendor edge (WorkOS + Cloudflare). There's no supported self-hosted backend contract yet.

## Reusable Patterns

- **Immutable storage scope vs live auth state:** capture the storage/transport boundary once per process and never re-resolve it because credentials changed.
- **Host-executed durable command ledger in a CRDT:** append-only per-device commands, host-only outcomes, mark-processed-before-execute, and nudges to wake an offline host.
- **Origin-rejecting loopback WebSocket:** native clients send no `Origin` and browsers always do, so rejecting any `Origin` blocks cross-site and rebinding attacks with no token. Add a token too if the machine is shared.
- **Block-granularity virtualized transcript with tail-only re-parse:** keeps streaming cost O(delta).
- **Explicit "not a security boundary" documentation:** the architecture doc names what UI filters don't protect (ignored files), which is better than an implied denylist.

---

**Attribution:** zeronsh/zeron, MIT License
