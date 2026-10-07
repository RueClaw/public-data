# Octop (TencentCloud/Octop)

**Repo:** https://github.com/TencentCloud/Octop
**License:** MIT (free extraction and reuse)
**Reviewed:** 2026-10-05
**Stack:** Python 3.12+, FastAPI + uvicorn, React 18/TS/Vite/Ant Design dashboard, SQLite (WAL) or PostgreSQL control plane, composes four sister packages (octop-harness, -gateway, -memory, -browser) from PyPI
**What it is:** A self-hosted, multi-user, multi-agent AI assistant platform — one process serving a web dashboard, CLI, IM channels (Feishu/DingTalk/QQ/WeChat/Telegram/Discord/WeCom), and cron — with per-user teams of specialized "expert" agents, shared expert/skill pools, RAG knowledge bases, and bidirectional ACP for delegating to external coding agents.

---

## Verdict

⚠️ **Interesting — the most complete multi-*user* agent platform we've reviewed, and a direct category sibling to OpenClaw/Hermes-style assistants.** The differentiator is not the agent loop (that's in the external `octop-harness` package) but the multi-tenant product shape: JWT-isolated users, one admin per household/team, per-user expert teams with their own workspaces/providers/channels/cron, an expert library + market + in-deployment sharing, and pluggable workspace backends (local disk, Docker sandbox, Postgres, S3/COS). Verified locally: `uv sync` clean, **3,712 unit tests pass, 2 fail** — both failures are FnOS NAS-specific process-management tests on macOS, not core logic. Caveats: v1.0.2 beta, 734 open issues, the interesting runtime pieces live in separate PyPI packages (this repo is the composition layer), Chinese-ecosystem gravity (Feishu/DingTalk/WeCom first, installer curls from a Tencent COS bucket), and the roadmap's "Managed Agents" item telegraphs a hosted future.

---

## What It Is

Octop is Tencent Cloud's open-source self-hosted assistant for "teams, families, and individuals." A single `octop run` process serves everything: web dashboard, CLI, IM channel bridge, cron — all state in one control-plane DB (SQLite default, PostgreSQL optional), all files under `~/.octop/`.

The product model is **experts**: each user has multiple specialized agents, each with its own workspace, providers, channels, and cron jobs. A built-in library of expert templates is scanned at boot; users can publish experts to others in the same deployment, and a shared pool of skills/sub-agents avoids rebuilding configs. Sixteen MBTI persona templates give agents character presets. **AgentTeams** (beta) adds a coordinator that schedules multiple experts on multi-step work.

Capability surfaces beyond chat: in-browser terminal with AI assistance, headless Chromium automation with persistent profiles, remote desktop control (live screen + input from the dashboard), RAG knowledge bases shareable within a deployment, a plugin system, and **bidirectional ACP** — external IDEs can use Octop as an agent (`octop acp`), and Octop can delegate coding tasks out to OpenCode/Claude Code/Codex with permission gates.

The repo itself is the composition layer: the agent runtime (model routing, tools, skills, checkpointing), IM gateway, hierarchical memory, and browser automation are separate `octop-*` PyPI packages (source in sibling TencentCloud repos).

## Stack

| Layer | Tech |
|-------|------|
| Language | Python 3.12+ (~144K lines src, ~90K lines tests in this repo) |
| Web | FastAPI + uvicorn; scalar-fastapi docs (off by default) |
| Control plane | SQLite WAL default; PostgreSQL optional (langgraph checkpoints) |
| Agent runtime | `octop-harness[all]` (external package) |
| IM gateway | `octop-gateway` — normalizes Feishu/DingTalk/QQ/WeChat/Telegram/Discord/WeCom into one pipeline |
| Memory | `octop-memory` — hierarchical recall + FTS, portable with workspace |
| Frontend | React 18 + TS + Vite + Ant Design |
| Scheduling | APScheduler |
| Security | JWT multi-user, argon2, tool approval, shell guardrails, PII redaction |
| Tests | 501 files, ~90K lines; verified 3,712 pass / 2 platform-specific fails |

## Key Features

### Multi-user as a first-class product concept

Most self-hosted assistants are single-operator. Octop is household/team-shaped: JWT isolation, admin role, per-user experts with independent workspaces/providers/channels, expert sharing between users, and shared skill pools. "One admin, shared household" is a genuinely different product stance.

### Experts: packaging agent configs as reusable, shareable units

An expert bundles persona (MBTI template or custom system prompt), workspace, providers, channels, and cron. The library/market/sharing mechanics mean good configurations propagate instead of being rebuilt — the same insight as agent skill systems, applied at the whole-agent level.

### Pluggable workspace backends

Expert files can live on local disk, in a Docker sandbox, PostgreSQL, or COS/S3 — separated from the control-plane DB. Memory is designed to migrate with the workspace, so an agent's identity is portable across backends.

### Single-process unified pipeline

Web UI, IM, and cron all route through one in-process `HarnessProcessor`; no external queue or broker; restart-safe rebuild from the control-plane DB. Operationally simple in a way multi-service assistants aren't.

### Bidirectional ACP

Inbound: `octop acp` serves any agent to ACP clients (Zed, OpenCode). Outbound: delegate to OpenCode/Claude Code/Codex/CodeBuddy with permission gates. Both directions of agent interop in one product.

## Architecture

`src/octop/` splits into `api` (FastAPI surface), `cli`, `config`, `i18n`, and `infra` — where infra holds agents (builtin skills, expert library), connectors (OAuth + MCP gateway), channels, knowledge, plugins, and workspace backends. The heavy lifting (agent loop, memory, IM normalization, browser) is imported from the four `octop-*` packages. State discipline: one control-plane DB rebuilds everything on boot; workspace files are a separate, pluggable concern.

## Comparison

| Aspect | Octop | OpenHuman (reviewed 2026-10-05) | Hermes/OpenClaw-style assistants |
|--------|-------|--------------------------------|----------------------------------|
| Core | Python, FastAPI, external runtime pkgs | Rust, in-process | Python/TS, single operator |
| Multi-user | ✅ JWT users, admin, expert sharing | Single-user desktop | ❌ single operator |
| License | MIT | GPL-3.0 | MIT |
| Channels | 8+ IM incl. Chinese suite | 15 incl. email | A few |
| Memory | Portable hierarchical (external pkg) | CortexDB hosted default | Local files/SQLite |
| Security | JWT, tool approval, shell guardrails, PII redaction | Approval gates, sandboxes, injection screening | Varies |
| Maturity | v1.0.2 beta, 7.5K★, 734 open issues | v0.64, 41K★ | — |

Versus OpenHuman: Octop trades engine depth for product breadth (multi-user, channels, desktop/NAS clients) and wins the license (MIT vs GPL). Versus single-operator assistants like ours, the multi-user expert model is the thing we don't have.

## Self-Hosting Notes

One-line installer (provisions Python 3.12 via uv under `~/.octop/`) — note it curls from a Tencent COS bucket, so audit the script or `pip install octop` instead. `octop init` runs a setup wizard; `octop run` starts everything. Docker sandbox backend available for workspace isolation. Desktop clients for Win/macOS/Linux plus FnOS NAS packages. API docs off by default.

---

**Attribution:** TencentCloud/Octop, MIT
