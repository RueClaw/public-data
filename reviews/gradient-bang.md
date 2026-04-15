# gradient-bang

- **Repo:** <https://github.com/pipecat-ai/gradient-bang>
- **License:** MIT
- **Commit reviewed:** `a60b3b0` (2026-04-14)

## What it is

Gradient Bang is an online multiplayer universe where the player ship, NPCs, and surrounding systems are all AI-agent driven. It combines:

- Supabase as game server plus edge-function backend
- Pipecat for realtime voice agent pipelines
- a React/Zustand client
- autonomous NPC/task agents
- world generation and simulation scripts

This is basically "what if your MMO backend, voice copilot, and NPC autonomy stack were one repo instead of three regrettable ones taped together later".

## High-level architecture

The repo is much more substantial than the playful branding suggests.

Core layers:
- **Supabase edge functions** as the only backend
- **Pipecat bot** for realtime voice interaction
- **Task/NPC agents** for autonomous play
- **React client** for the game UI
- **Universe/worldgen scripts** for content seeding

The top-level `CLAUDE.md` and deployment docs are unusually detailed, which helps a lot because otherwise this thing would be a small city.

## What is technically interesting

### 1. Realtime voice agent architecture is not toy-grade
The Pipecat stack is doing real orchestration work here:
- STT/TTS wiring
- subagent structure
- client message handling
- inference gating
- context upload/history handling
- smart turn analysis

The `bot.py` startup flow is serious infrastructure, not demo fluff.

### 2. Local API bypass for latency is a good move
One of the best patterns in the repo is `LocalApiServer`, which runs the equivalent of Supabase edge function logic locally against Postgres when `LOCAL_API_POSTGRES_URL` is set.

That avoids the edge-function HTTP hop and cuts latency in co-located deployments. Very sane. It's a strong example of **preserving the backend contract while optimizing the hot path locally**.

### 3. Inference gating is worth stealing
`inference_gate.py` is doing disciplined coordination around when the LLM is allowed to run, based on:
- user speaking state
- bot speaking state
- cooldowns
- post-LLM grace periods
- pending inference reasons with priority

That is exactly the kind of annoying orchestration layer many voice-agent demos skip, then act surprised when they become chaotic interruption goblins.

### 4. NPC launcher is operationally thoughtful
`npc/run_npc.py` includes session locking, actor-vs-ship distinction, clearer error reporting, and controlled launch semantics. That's solid operator-facing tooling.

### 5. Repo treats docs as part of the system
The various `CLAUDE.md` files are actually useful. They encode architecture boundaries, slice responsibilities, map rendering responsibilities, deployment rules, and testing guidance. Bless them for that.

## Strong design patterns

### Backend as contract, local fast path as optimization
This is the cleanest pattern in the repo. Keep the same logical API, but provide a local execution route when latency matters.

### Agent decomposition by role
Even from the partial view here, the repo is separating voice interaction, task execution, event relay, and UI control. That is better than stuffing all behavior into one immortal god-agent.

### State discipline in client docs
The client-side docs explicitly distinguish routing, state mutation, and rendering responsibilities. That's boring in the best possible way.

## Caveats

### 1. This is an ambitious pile of moving parts
Supabase, Docker, Node, uv, Pipecat, browser client, voice services, multiple providers, Tailscale, deployment to cloud products. Cool, but fragile.

### 2. Operational complexity is not optional here
This is not a clone-and-run repo unless you already enjoy infrastructure as a personality trait.

### 3. Game feel still depends on model quality and latency
The architecture can be clever and still feel bad if the live voice loop is slow or the agent behavior is incoherent. Realtime agent games are brutally exposed to that.

### 4. Supabase as sole backend is both elegant and dangerous
Elegant because the architecture stays simple. Dangerous because when edge functions, DB state, or auth assumptions wobble, a lot wobbles with them.

## Why it matters

Gradient Bang is one of the more interesting examples of **agentic software as product, not benchmark**.

It is not asking, "can an LLM solve a task in isolation?"
It is asking, "what does a realtime multi-agent world look like when voice, game state, autonomy, and UI all have to coexist?"

That's a much more interesting question.

## Verdict

This is a serious systems repo hiding inside a playful game wrapper. The standout ideas are not the game premise itself, but the operational patterns around realtime inference control, local backend bypass, and role-separated agent design.

Messy? Inevitably. But real.

**Rating:** 4.5/5

## Patterns worth stealing

- Local execution fast path behind an unchanged backend contract
- Priority-based inference gating for voice/realtime agent pipelines
- Role-separated subagents for voice, tasks, events, and UI
- Operator-friendly NPC/session launch tooling with lock semantics
- Architecture docs that specify layer boundaries, not just setup steps
