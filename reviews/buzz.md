# Buzz (block/buzz)

**Repo:** https://github.com/block/buzz
**License:** Apache-2.0. Permissive reuse with attribution.
**Reviewed:** 2026-07-23
**Stack:** Rust, Axum, Nostr, Postgres, Redis, S3/MinIO, Tauri, React, Flutter, pnpm
**What it is:** Buzz is a self-hostable team workspace where humans, agents, workflows, git events, media, and approvals share one signed Nostr event log behind a relay you operate.

---

## Verdict

✅ **Deploy candidate for a serious pilot, with realistic expectations.** Buzz has a coherent event-log architecture, a broad but concrete Rust crate map, Apache-2.0 licensing, packaged app direction, and unusually strong agent-first CLI/workflow thinking. The caution is scope: mobile, approval glue, huddles, and some larger vision pieces are still being wired up, so treat it as an active platform to pilot rather than finished Slack-for-agents replacement.

---

## What It Is

Buzz is a collaboration system built around a Nostr relay. Messages, reactions, channels, DMs, workflows, media, git events, audit entries, and agent actions are all represented as signed events. Humans and agents use the same identity model: a person, a CLI process, and an agent harness all act through keypairs and leave signed records.

The product shape is a team workspace: desktop app, web/mobile clients, channels, threads, canvases, media comments, search, workflows, git hosting, and agent participation. The implementation shape is a Rust relay with Postgres persistence, Redis fan-out/presence, S3-compatible media storage, and a JSON-first CLI meant to be driven by agents.

Its strongest idea is that agent collaboration should not be a bot integration bolted onto chat. Buzz makes the relay the single source of truth, puts every actor in the same signed event substrate, and uses channel membership plus tenant/community binding as the security boundary.

## Stack

| Layer | Tech |
|-------|------|
| Relay/backend | Rust workspace, Axum, Tokio, Nostr NIP-01/NIP-42/NIP-98 |
| Data | Postgres via SQLx, Redis pub/sub/presence, S3/MinIO Blossom-style media |
| Auth/security | Schnorr signatures, NIP-42 WebSocket auth, NIP-98 HTTP auth, API tokens/scopes, rate limiting |
| Agent surface | `buzz-cli`, `buzz-acp`, `buzz-agent`, `buzz-dev-mcp`, YAML workflows |
| Desktop | Tauri, React, TypeScript |
| Web | Vite, React, TypeScript, Tailwind |
| Mobile | Flutter |
| Tooling | Hermit, Just, pnpm, Biome, Playwright, Docker Compose, Prometheus |

## Key Features

### Signed Shared Event Log

Buzz uses Nostr events as the common representation for chat, workflow, git, media, and agent actions. The architecture document describes the relay pipeline as auth check, pubkey match, signature verification, membership check, DB insert, Redis publish, local fan-out, search indexing, audit logging, and workflow trigger. That is the right backbone for an auditable agent workspace.

### Agent-First CLI

`buzz-cli` is explicitly JSON-in/JSON-out and covers messages, channels, DMs, workflows, canvases, reactions, users, repository announcements/protection, uploads, and memory operations. That matters because it gives agents a narrow, scriptable surface instead of asking them to screen-scrape a GUI or hold brittle browser state.

### Multi-Community Boundary

Buzz treats the URL/host as the authority for the visible workspace. Multi-community support binds request handling to a host-derived `TenantContext` before auth, event ingestion, REST, media, git, search, workflow, or pub/sub work. Unknown hosts fail closed. This is a strong design choice for hosted operators because tenant selection is not client-supplied state.

### Workflow and Approval Substrate

The workflow schema supports message, reaction, diff, schedule, and webhook triggers with actions for sending messages/DMs, setting topics, adding reactions, calling webhooks, requesting approval, and delaying execution. It is not a full enterprise automation engine yet, but the primitives match the collaboration model instead of living in a separate CI-only plane.

### Git and Media in the Same Workspace

Buzz includes NIP-34 git event support, repository protection commands, git credential/signing helper crates, and media upload/validation/storage crates. That pushes the workspace beyond chat into project memory: code changes, reviews, media discussion, and release decisions can live in the same event timeline.

## Architecture

The crate boundary is clean: `buzz-core` owns zero-I/O types, verification, filters, and kind constants; `buzz-relay` orchestrates storage, auth, pub/sub, search, audit, and workflow services; adjacent crates expose CLI, SDK, ACP harness, media, git helpers, conformance, and admin tooling.

The most important pattern is the guarded fan-out chokepoint. Local and cross-node event delivery re-check tenant, author-only constraints, private-channel visibility, and membership before sending events to subscribers. That is the right place to enforce "a stale subscription is not enough to receive data."

The self-hosting path is heavy but understandable: Docker Compose brings Postgres, Redis, MinIO, Prometheus, Adminer, and Keycloak for development, while Hermit pins Rust, Node, pnpm, and `just`. Operators should expect real infrastructure, not a single binary toy.

## Comparison

| Aspect | Buzz | Zulip/Matrix/Slack-style chat | Agent ops dashboards | Event-sourced agent runtimes |
|--------|------|-------------------------------|----------------------|------------------------------|
| Primary job | Human+agent workspace on a signed relay | Human communication with bot integrations | Monitor/control agents | Model auditable agent state |
| Event model | Nostr signed event log | App-specific message DB | Task/session records | Event graph/log |
| Agent identity | First-class keypair actor | Usually bot/app integration | Runtime/agent records | Varies by framework |
| Self-hosting | Core design goal | Varies | Usually local/admin focused | Usually library/runtime focused |
| Best fit | Teams wanting agents inside the workspace substrate | Human chat first | Operations visibility | Workflow replay/fork/eval |

Buzz is closest to a chat/workspace product built from event-sourced agent-infrastructure ideas. It is less mature than established chat systems, but much more opinionated about agents as equal participants.

## Self-Hosting Notes

The developer path is documented and credible: clone, activate Hermit, run `just setup`, then `just dev` or split relay/desktop commands. The default relay runs at `ws://localhost:3000`, with health/readiness on a separate port.

For production or sensitive use, plan for normal service hardening: TLS/reverse proxy, Postgres backup, Redis isolation, S3/MinIO bucket policy, key lifecycle, relay admission limits, workflow/webhook egress policy, and explicit handling of local dev credentials in Compose. Buzz has solid primitives, but operating it still means operating a multi-service collaboration backend.

---

**Attribution:** block/buzz, Apache License 2.0
