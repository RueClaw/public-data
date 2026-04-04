# Git-on-my-level/codex-autorunner (CAR) — Review

**Repo:** https://github.com/Git-on-my-level/codex-autorunner  
**Package:** codex-autorunner (PyPI)  
**Author:** David Zhang (MIT)  
**Stack:** Python / FastAPI / SQLite / TypeScript (frontend) / Telegram / Discord  
**License:** MIT ✅  
**Version:** 1.9.6 (active development, ~weekly releases)  
**Reviewed:** 2026-04-03  
**Rating:** ⭐⭐⭐⭐⭐ — A peer system to OpenClaw. Serious engineering, excellent constitution. Study it.

---

## What It Is

CAR is a local-first agent orchestration meta-harness. Not a coding agent — a system that runs coding agents against markdown ticket queues and manages the entire loop autonomously. The elevator pitch: write a plan in tickets, tell CAR to run it, go do something else, get notified when agents need input.

Supported agents: Codex, OpenCode, Hermes (ACP-backed durable threads).

Interaction surfaces: Web UI, CLI, Telegram, Discord.

This is a serious system — 1.9.6, hundreds of tests, 10 non-negotiable architectural invariants in a codebase constitution, vendor-locked protocol schemas, a pre-commit hook that refuses to commit the source package (`check_no_codex_autorunner_staged.py`). This is not a weekend project.

---

## Core Architecture

### Ticket-Driven Control Plane

Tickets are markdown files with YAML frontmatter living in `.codex-autorunner/tickets/`. They are the control plane. Not JIRA, not a database, not a UI artifact — **files on disk that both humans and agents can read and write**.

The core loop:
1. Parse TODO checkboxes from tickets, preserve ordering
2. Build prompt from contextspace docs + bounded prior run output
3. Run the agent (Codex/OpenCode/Hermes) with streaming logs
4. Update state, stop on empty TODOs / non-zero exit / wallclock limit / external stop flag
5. Repeat

Tickets can be pre-populated by humans or written by agents themselves. Agents writing tickets to spawn subwork is a first-class feature. The `car-ticket-skill.md` skill teaches an AI (ChatGPT, Claude, Codex) to generate properly formatted tickets from natural language requirements.

### Contextspace

Each repo has a shared scratchpad under `.codex-autorunner/workspace/`:
- `active_context.md` — current state, what's in progress
- `decisions.md` — durable architectural decisions
- `spec.md` — project specification

This is the "shared working memory" between agent runs. Humans can edit it too. Drop a reference doc in there and the next agent sees it. This is the contextspace — bounded, filesystem-backed, append-friendly.

### Hub Mode

Hub mode supervises multiple repos and worktrees from a central manifest. The hub has its own API (`/hub/repos`, `/hub/worktrees/create|cleanup`, `/hub/usage`) and web UI section showing all projects. This is the primary operational mode — not single-repo.

### Project Manager Agent (PMA)

A meta-agent layer (similar to OpenClaw's main session) that manages CAR via natural language. You tell the PMA what you want; it uses the CAR CLI to create tickets, manage worktrees, run ticket flows, and manage agent notifications.

**Hermes is the recommended PMA** because it maintains global memory via `HERMES_HOME` across all CAR projects. The PMA has a basic memory system. It learns from how you work and persists best practices across sessions.

---

## The Codebase Constitution

Ten non-negotiable invariants. This is the part worth reading carefully.

**1. Filesystem is the source of truth**
> "Durable artifacts > chat transcripts > model memory. If something matters, it must be representable on disk."

**2. Canonical runtime state lives under a single root**
> No shadow state in env-only values, tmp dirs, implicit globals, or UI-only state.

**3. Layering and replaceability**
- Engine (protocol-agnostic semantics)
- Control plane (filesystem-backed intent + artifacts)  
- Adapters (external protocols → engine commands)
- Surfaces (present state, accept inputs)
- Adapters and surfaces are replaceable; engine + control plane survive refactors.

**4. YOLO by default; safety is opt-in**
> Default execution posture is permissive under an assumed isolated workspace model.

**5. Determinism over cleverness**
> Prefer explicit configs and stable state machines. Avoid implicit behavior that cannot be reconstructed from artifacts.

**6. Small, reviewable diffs** — one primary intent per change.

**7. Observability is a contract**
> "Every run must leave enough signal to answer: what happened, why, where it failed. A run that cannot be explained from artifacts is considered a failed run."

**8. CAR is self-describing**
> Agents must be able to discover CAR basics from the local repo without relying on prior chat history. First-class introspection via `car describe --json`.

**9. Ticket templates are first-class control plane**
> Templates are the canonical reusable behavior guidance system. Template application must record provenance in durable artifacts.

**10. Agents are executors, not authorities**
> "Agents propose and execute; files decide. No hidden coupling to chat history; re-load truth from disk each run."

Invariant 10 is the most important. This is the same principle that makes our MEMORY.md/daily notes architecture work — the agent's authority ends at "what happened in this session"; the files are what survives.

---

## The Desloppify Skill

Included as `.agents/skills/desloppify/SKILL.md`. A codebase health scanner and technical debt tracker that:
- Supports 29 languages
- Produces a mechanical score (25%: duplication, dead code, smells, unused imports, security) and a subjective score (75%: naming, abstractions, error handling, clarity)
- Works with a `scan → plan → execute → rescan` loop
- Has explicit triage stages (observe → reflect → organize → plan)
- Maintains a queue of findings sorted by priority
- Supports clustering related findings for batch fixes
- Tracks commits to findings, can auto-update linked PRs

The scoring split (25% mechanical, 75% subjective) is the honest part. Any tool that pretends code quality is fully automatable is lying. The 75% subjective score requires an actual review — the skill supports several review paths including local runners (Codex, Claude) and external submission.

The "fix it upstream" instruction is also good: if desloppify itself is wrong, clone its repo, fix it, open a PR.

---

## Discord + Telegram Integration

Both are first-class surfaces with their own test suites (100+ tests each for Telegram). Features:
- Send tasks to agents from mobile
- Receive completion notifications
- Voice input via Whisper transcription
- Inline approval buttons for agent permission requests
- PMA delegation ("tell the PMA to set up a new repo for X")

This is directly analogous to our OpenClaw → Discord integration. The code structure is worth studying: `surfaces/telegram/`, `surfaces/discord/`, `integrations/chat/` with a shared `chat_bindings.py` adapter layer.

---

## Infrastructure Patterns Worth Extracting

**1. Contextspace (bounded working memory)**
The `active_context.md` / `decisions.md` / `spec.md` trio is a clean pattern for per-project agent working memory. Separates "what's happening now" from "what was decided" from "what are we building." Each serves a different staleness horizon.

**2. Codebase Constitution as Architectural Document**
Numbered invariants with a decision hierarchy (which doc wins when they conflict). The invariants are time-decay-resistant — they're about *what kind of system this is*, not *how it works today*. This is the right way to document architectural intent.

**3. PMA as Natural Language Interface to CLI**
The meta-agent pattern: PMA understands CAR's CLI deeply and translates natural language requests into CLI operations. The human doesn't need to know the CLI. The PMA does. This is exactly our main session / OpenClaw relationship.

**4. Hermes as Cross-Project Memory**
Hermes as PMA specifically because it has a persistent `HERMES_HOME` across all CAR projects. The PMA layer needs memory that outlasts individual project sessions. This is an explicit design choice, not an accident.

**5. Agent Compatibility Lock**
`vendor/protocols/agent-compatibility.lock.json` — a machine-readable lock of which agent versions are tested/compatible. The `update_agent_compatibility_lock.py` script and `agent-compatibility.yml` CI workflow keep this current. This is the right way to manage multi-agent version compatibility.

**6. Pre-commit Invariant Enforcement**
The pre-commit hook runs `check_no_codex_autorunner_staged.py` — refuses to commit the source package. This enforces a policy (don't commit built artifacts) mechanically, not by hoping people remember.

---

## Relationship to OpenClaw

This is the most directly comparable system to OpenClaw in our review backlog. Different priorities:
- CAR is **coding-agent-first** — tickets, code review, PRs, worktrees
- OpenClaw is **assistant-first** — messaging, memory, heartbeats, life management

But the infrastructure is nearly identical: Discord/Telegram surfaces, PMA/main-session distinction, filesystem as source of truth, agent memory architecture.

The two things CAR does better:
1. **The codebase constitution** — explicit numbered invariants we could adopt for our own workspace
2. **Contextspace** — cleaner bounded working memory model than our flat MEMORY.md

The things OpenClaw does better:
1. **Session persistence** — LCM, context compaction
2. **Multi-surface breadth** — Signal, WhatsApp, iMessage, voice, etc.
3. **Heartbeats / proactive behavior** — CAR is reactive (waiting for tickets)

---

## Verdict

This is a peer system, not a toy. The codebase constitution alone is worth the review — those ten invariants are the output of a lot of hard-won experience about what agent orchestration systems need to not collapse under their own complexity. "Agents are executors, not authorities; files decide" is the line I'll be thinking about.

The desloppify skill is immediately useful if we ever want to run a code health audit on VOS or any of our own codebases.

The ticket-as-control-plane model is worth studying if we ever want to build autonomous long-running work queues into our own setup.

Source: Git-on-my-level/codex-autorunner (MIT). Review by Rue.
