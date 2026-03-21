# OpenClaw Multi-Agent Architecture Pattern
*A reference implementation for personal AI assistant deployments*
*Last updated: 2026-03-21*

## Overview

A personal OpenClaw deployment running two agents on Apple Silicon (macOS):
- **Main agent** — primary assistant, full context, all channels
- **Watcher agent** — lightweight periodic monitor, local model only

---

## Agent Split

### Main Agent
- **Model:** `anthropic/claude-sonnet-4-6` (primary)
- **Fallbacks:** `google/gemini-3-pro-preview` → `ollama/deepseek-r1:32b`
- **Heartbeat:** disabled — handled by Watcher
- **Channels:** Discord (primary), Slack
- **Workspace:** full boot context (SOUL, USER, AGENTS, MEMORY, TOOLS, HEARTBEAT)

### Watcher Agent
- **Model:** `ollama/qwen3-coder-next` (local, minimal cost)
- **Heartbeat:** every 30 min, active hours only (08:00–24:00)
- **lightContext:** true — minimal boot overhead
- **Delivers to:** owner's Discord DM
- **Purpose:** Background monitoring without burning cloud API tokens

**Why split?** Periodic checks (email triage, file watching, repo scanning) don't need a frontier model. Local model handles the routing; escalates to main agent only when something actually needs attention.

---

## Memory Architecture (3-tier)

### Tier 1 — Session (short-term)
- LCM (Lossless Context Manager) plugin
- Compressed summaries in SQLite
- Always keeps N most recent messages verbatim
- Compaction: safeguard mode (conservative)

### Tier 2 — Cross-session (medium-term)
- LCM summaries persist in DB, searchable via grep/expand
- Embedding search via external provider
- DAG structure: summaries reference parent summaries

### Tier 3 — Permanent (long-term)
- **`MEMORY.md`** — curated, human-editable, loaded at boot (main session only)
- **Daily notes** (`memory/YYYY-MM-DD.md`) — raw logs
- **Workspace files** — persona, user profile, operational rules

**Privacy note:** Long-term memory loaded only in private sessions. Group/public channel sessions boot without it to prevent personal context leakage.

---

## Storage Layout

```
~/.openclaw/
├── openclaw.json              # Main config
├── lcm.db                     # Context store (SQLite)
├── workspace/                 # Main agent workspace
│   ├── SOUL.md                # Identity/persona
│   ├── AGENTS.md              # Operational rules + boot sequence
│   ├── TOOLS.md               # Tool/infra reference
│   ├── HEARTBEAT.md           # Watcher checklist
│   ├── MEMORY.md              # Long-term memory (private, main session only)
│   ├── memory/                # Daily notes, active-tasks.md
│   ├── context/               # Channel/thread context caches
│   └── scripts/               # Utility scripts
├── workspace-watcher/         # Watcher workspace (minimal)
├── credentials/               # Secrets (never output to chat)
└── extensions/                # Plugins (lossless-claw, etc.)
```

---

## Content Storage Pattern

All produced content goes to a shared knowledge base (Obsidian vault, iCloud sync) — NOT in the agent workspace. Agent workspace is operational only.

| Type | Location |
|------|----------|
| Project designs/docs | `vault/Projects/<name>/` |
| Research | `vault/Research/` |
| Public extracts | separate public repo (attributed, license-checked) |

---

## Channel Configuration

| Channel | Use |
|---------|-----|
| Discord | Primary interface (DMs + guild) |
| Slack | Secondary (workplace/community) |

---

## Remote Agent Pattern

A second OpenClaw instance runs on a remote machine for a family member, connected via Tailscale. Channels: WhatsApp (primary), Discord (family). Managed remotely via Tailscale SSH + control UI.

Key lesson: safety-critical functions (medication reminders, emergency detection) run on cron/native reminders independent of the AI layer. AI is enrichment only.

---

## Key Design Decisions

1. **Watcher uses local model** — 30-min heartbeat on a cloud frontier model would be expensive and wasteful. Local model handles triage, escalates when needed.

2. **MEMORY.md privacy gating** — personal context only loads in private sessions. Prevents leaking personal info in group chats or to other users.

3. **Workspace ≠ content storage** — agent workspace is for operational state. All produced content goes to a synced vault accessible to the human.

4. **lightContext for watcher** — watcher doesn't need full boot context. Keeps heartbeat fast and cheap.

5. **Gateway loopback bind** — gateway only accessible via localhost (or Tailscale). Not exposed to LAN or internet directly.
