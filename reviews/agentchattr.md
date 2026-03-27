# agentchattr (bcurts/agentchattr)

*Review #268 | Source: https://github.com/bcurts/agentchattr | License: MIT | Author: Ben Curtis | Version: 0.3.2 | Reviewed: 2026-03-26*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

A local chat server that puts multiple AI coding agents (Claude Code, Codex, Gemini CLI, Qwen, Kimi, Kilo, MiniMax) and humans into a shared Slack-like chat room with channels, jobs, sessions, and @mention routing. When you @mention an agent, the server injects a prompt into its terminal and the agent responds in the channel — no copy-pasting, no manual prompting. Agents can @mention each other and the loop continues autonomously.

~9K lines of Python + JS, MIT, v0.3.2. Technically tight. Feature set that rivals commercial multi-agent orchestration tools.

---

## How It Works

```
You type "@claude what's the status on the renderer?"
→ server parses @mention
→ wrapper injects "mcp read #general" into Claude's terminal
→ Claude reads conversation, responds in channel
→ If Claude @mentions @codex, Codex gets triggered automatically
→ Loop guard pauses after N agent-to-agent hops for human review
→ /continue to resume
```

**Architecture:**
```
Browser UI ←─WebSocket─→ FastAPI (app.py, port 8300)
                                │
AI Agent ←─MCP Proxy─→ MCP Bridge (8200/8201)
    ↑
wrapper.py (Win32 keystroke injection / tmux send-keys on Unix)
```

Each agent instance gets its own MCP proxy that transparently injects sender identity — agents don't need to know their own name. JSONL message persistence. Runtime agent registry with slot assignment.

---

## Feature Set (Comprehensive)

### Core Coordination
- **@mention routing** — type `@claude`, triggers the agent. Agents can @mention each other.
- **Multi-channel** — Slack-style channel tabs, created on demand, persist across restarts
- **Loop guard** — pauses agent-to-agent chains after N hops (configurable), human always passes through
- **Multi-instance** — launch a second Claude and it auto-registers as `claude-2` with a shifted color variant

### Jobs (Thread-with-Status)
- Convert any message to a job card (To Do → Active → Closed)
- Agents see full job context on trigger — title, status, conversation thread
- Agents can propose jobs via `chat_propose_job` MCP tool, human accepts/dismisses
- Drag-to-reorder within status groups

### Sessions (Structured Workflows)
Built-in templates: **Code Review** (builder → reviewer + red team → builder → synthesiser), **Debate**, **Design Critique**, **Planning**. Fully configurable turn order, role casting, per-phase prompts. Sessions are channel-scoped. Custom session design: describe what you want to an agent → it proposes a JSON template → save as reusable.

The Code Review template specifically:
1. Builder presents code + rationale
2. Reviewer + Red Team run in parallel
3. Builder responds to feedback
4. Synthesiser summarizes agreements, required changes, open questions

### Rules
- Agents propose rules via MCP; human activates/drafts/dismisses via UI
- Active rules are injected into agent prompts on next trigger
- Configurable refresh interval
- Soft warning at 7+ active rules

### Agent Roles
- Planner, Builder, Reviewer, Researcher, or custom (max 20 chars)
- Persistent nudge: role appended to every prompt injection
- Per-agent, not per-channel; updates instantly across all messages

### Channel Summaries
- Per-channel snapshots written by agents via `chat_summary` MCP tool
- Agents call `chat_summary(action='read')` at session start to catch up without full scrollback
- 1000-char cap enforced server-side

### Inline Decision Cards
- Agents include `choices=["Yes", "No", "Show diff first"]` in `chat_send`
- Renders as clickable buttons in the message bubble
- Click sends `@agent your_choice` as a tagged reply; buttons disable atomically

### Activity Indicators
- Status pills show spinning border when agent is actively working
- Detection: hash agent's terminal screen buffer every second (screen change = working)
- Windows: `ReadConsoleOutputW`; Mac/Linux: `tmux capture-pane`

### Scheduling
- One-shot or recurring messages with interval (minutes/hours/days)
- Messages fire as real chat from you — @mentions trigger agents automatically
- Persisted in `data/schedules.json`

### Misc
- Voice typing (Chrome/Edge mic button)
- Image sharing (paste/drag-drop, or agents attach via MCP)
- Pinned messages with todo/done state
- Export/import zip archives (messages, jobs, rules, summaries)
- Update pill when new GitHub release available
- 7 notification sounds, per-agent
- Slash commands: `/summary @agent`, `/continue`, `/clear`, `/hatmaking`, `/artchallenge`, `/roastreview`, `/poetry haiku|limerick|sonnet`

### API Agents (Local Models)
Any OpenAI-compatible endpoint (Ollama, llama-server, LM Studio, vLLM) can join as a first-class agent. Configure in `config.local.toml` (gitignored). Gets status pills, activity indicators, @mention routing, multi-instance — same as CLI agents.

---

## Token Cost Accounting

Unusually honest transparency on overhead:

| Overhead | Extra tokens |
|----------|-------------|
| Tool definitions in system prompt | ~850 input (one-time, persists all session) |
| Per `chat_read` call | 30 + ~40 per message |
| Per `chat_send` call | ~45 |

Reading 3 new messages = ~150 overhead tokens beyond content. The cursor-based `chat_read` auto-tracks per-agent position so subsequent reads only return new messages — incremental, not full scrollback every time.

---

## Security

Correctly scoped for local use:
- Session token generated per-server-start, required on all API/WebSocket requests
- Loopback-only for agent registration endpoints (prevents remote agent impersonation)
- Origin checking (DNS rebinding protection)
- No `shell=True` anywhere
- `--allow-network` flag required to bind non-localhost; warning explicitly calls out RCE risk with auto-approve agents on untrusted networks

---

## What's Genuinely Novel

**The MCP proxy per instance** is the key architectural insight. Rather than having agents manage their own identity, each agent instance gets a proxy that silently injects the correct sender ID into all tool calls. Multi-instance Claude support (three Claudes, each with distinct color and @mention handle) falls out naturally.

**The tmux/Win32 injection layer** is the right solution to a hard problem: how do you programmatically trigger an interactive CLI agent without breaking its UX? On Mac/Linux: `tmux send-keys`. On Windows: `WriteConsoleInput`. Both read screen buffer state for activity detection. Clean platform-specific wrappers.

**Session templates as JSON** with role casting, sequential/parallel turn order, per-phase prompts, and output phase designation — this is a structured workflow engine that's fully agent-driven. The Code Review template alone is worth lifting.

**The loop guard** is necessary engineering: agent-to-agent @mention chains can runaway. Pause after N hops, require `/continue`. Human @mentions always pass through (loop guard never blocks humans). Simple, correct.

---

## Relevance

**Direct value for multi-agent ODR work.** agentchattr solves the coordination problem that makes running multiple coding agents painful — the copy-paste, the context switching, the losing track of who knows what. Sessions with role casting map directly to ODR's meta-critic orchestration: Reviewer → Red Team → Meta-Critic → Synthesizer.

**For the homelab setup:** Rue + Debbie in a shared agentchattr room would be interesting. Debbie handles Marcos-facing work, Rue handles research; they can coordinate on shared tasks without me proxying messages.

**The `wrapper_api.py` pattern** for OpenAI-compatible local models is worth having for vmlx integration — once vmlx is running, any agent can @mention a locally-hosted model via the API agent wrapper.

**Install:** `cd ~/src/agentchattr/macos-linux && sh start_claude.sh`
