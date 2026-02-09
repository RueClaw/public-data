# Koda — Agent Architecture

> **Source:** [ImTheMars/koda](https://github.com/ImTheMars/koda) (MIT License)
> **Author:** ImTheMars
> **Stack:** TypeScript + Bun, ~5,900 LOC across 43 files

## Overview

Koda is a personal AI assistant with a clean, composable architecture. Key design principles: message bus decoupling, progressive skill loading, fire-and-forget memory, and autonomous innovation via a "subconscious" loop.

## Architecture Diagram

```
User → Telegram → MessageBus (inbound) → AgentLoop → LLM (OpenRouter)
                                              ↕              ↕
                                         SessionMgr      Tools (memory, search, soul, skills, fs)
                                              ↕
                  Telegram ← MessageBus (outbound) ← AgentLoop
```

## Key Patterns

### 1. Message Bus Decoupling
Channels (Telegram, CLI) never call the agent directly. All messages flow through async queues (`inbound` / `outbound` / `control`). This enables:
- Adding new channels without touching agent code
- Synthetic messages from scheduler, heartbeat, subconscious
- Control signals (typing indicators) without coupling

### 2. AsyncLocalStorage for Per-Request Context
Each message is processed inside `contextStore.run(context, ...)`, making userId/chatId available to any tool without passing it through every function signature. Clean alternative to globals.

### 3. Progressive Skill Loading
- Skill *summaries* (name + description) are always in the system prompt
- Full SKILL.md content is loaded on-demand when the agent reads the file
- "Always-on" skills (marked `always: true` in frontmatter) get full content injected every turn
- This keeps the base prompt small while allowing unlimited skill expansion

### 4. Fire-and-Forget Memory
Conversations are auto-saved to Supermemory after each exchange, but only if both user message and response are >100 chars and aren't simple acknowledgments. This filtering prevents polluting memory with "ok" / "thanks" exchanges.

### 5. Token Budget Manager
Context window is partitioned into fixed-percentage budgets:
- System prompt: 15%
- Memory: 10%
- Skills: 10%
- History: 50%
- Reserve (response headroom): 15%

History trimming uses **importance scoring** rather than simple recency:
- System messages (summaries) get highest priority
- Messages with tool usage get a boost
- Decision/preference language gets a boost
- Short acknowledgments ("ok", "thanks") get penalized
- Last 5 messages always get a recency bonus

### 6. Subconscious Innovation Loop
A timer fires every 30-60 minutes (random interval) and injects a prompt asking the agent to run a small experiment or optimization. Results are stored in SUBCONSCIOUS.md. The subconscious content is conditionally injected into the system prompt only when the user's query relates to ideas/improvements (detected via keyword matching).

### 7. Focus Mode
When activated, non-urgent proactive messages (heartbeat, scheduler, subconscious) are held. Urgency is determined by a fast keyword pre-filter (~95% hit rate), falling back to a minimal LLM call for ambiguous cases (`maxTokens: 5`, `temperature: 0`).

### 8. Hook System
Event-driven lifecycle hooks (`message:received`, `tool:after_call`, `soul:updated`, etc.) with:
- Parallel execution via `Promise.allSettled`
- Per-handler 5-second timeout
- Errors caught per-handler without blocking others

## Directory Structure

```
src/
  agent/       — Core loop, context builder, sub-agents, vision, subconscious
  bus/         — Message bus (async queues, event types)
  channels/    — Channel adapters (Telegram, CLI)
  hooks/       — Hook runner
  providers/   — LLM, Memory, Search, Voice interfaces
  scheduler/   — Task store, scheduler, heartbeat
  session/     — JSONL session store
  skills/      — Skill loader + registry
  soul/        — Personality loader with hot-reload + backup
  tools/       — Vercel AI SDK tool definitions
  utils/       — Logger, retry, circuit breaker, rate limiter, usage tracker
```

## Notable Implementation Details

- **Soul hot-reload:** File watcher on soul.md with 300ms debounce. Modifications to personality sections create timestamped backups automatically.
- **Prompt injection detection:** Regex-based pattern matching (logs warnings, doesn't block). Patterns include "ignore previous instructions", "you are now", `[INST]`, `<|im_start|>`.
- **Conversation summarization:** Triggered when history exceeds ~40k tokens. Uses structured summary format (Decisions/Preferences/Action Items/Context). Graceful degradation: returns original history on any failure.
- **Subagent steering:** Running sub-agents can receive mid-execution instructions via a queue, processed after each LLM step completes.
- **Smart heartbeat skip:** HEARTBEAT.md is parsed to detect if there's actually actionable content (skips headers, completed checkboxes, example items, instruction text).
