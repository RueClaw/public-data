# 724-office (wangziqi06/724-office)

*Review #285 | Source: https://github.com/wangziqi06/724-office | License: MIT | Author: wangziqi06 | Reviewed: 2026-03-28 | Stars: 974*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

A 24/7 production AI agent system in ~3,500 lines of pure Python. **Zero framework dependencies.** No LangChain, LlamaIndex, CrewAI, AutoGen — just `croniter`, `lancedb`, and `websocket-client`. 8 files. 26 built-in tools.

The headline feature: **the agent can write new Python tools at runtime, validate them, save them to disk, and hot-load them immediately** — without a restart. It can also detect its own errors, diagnose root causes, and run repair commands. Self-evolving.

Built solo with AI co-development tools in under 3 months. Has been running 24/7 in production.

---

## Architecture

```
Messaging Platform (WeChat Work / webhook)
    ↓
router.py       — Multi-tenant routing, Docker auto-provisioning, per-user containers
    ↓
xiaowang.py     — Entry point: HTTP server, debounce, ASR pipeline, media handling
    ↓
llm.py          — Tool use loop (core): 20-iter limit, session mgmt, memory injection
    ↓
tools.py        — 26 built-in tools + plugin system + MCP bridge
memory.py       — 3-layer memory pipeline: compress → deduplicate → retrieve
scheduler.py    — One-shot + cron jobs, persistent across restarts
mcp_client.py   — JSON-RPC over stdio/HTTP, namespace: server__tool, auto-reconnect
```

---

## What's Novel

### 1. Runtime Tool Creation (`create_tool`)

The agent can create new Python tools at runtime. The flow:

```python
@tool("create_tool", ...)
def tool_create_tool(args, ctx):
    name = args["name"]
    code = args["code"]

    # Validate: can't overwrite built-ins
    plugin_path = os.path.join(_plugins_dir, "%s.py" % name)
    if name in _registry and not os.path.exists(plugin_path):
        return "[error] Cannot overwrite built-in tool '%s'" % name

    # Try loading first — validate code executes without error
    _exec_plugin(code, "%s.py" % name)

    # Validated — persist to plugins/ and register
    with open(plugin_path, "w") as f:
        f.write(code)
    return "Created and loaded '%s'" % name
```

The plugin execution sandbox:
```python
def _exec_plugin(code, source="<plugin>"):
    exec(compile(code, source, "exec"), {
        "tool": tool,    # @tool decorator — only way to register
        "log": log,      # logging instance
    })
```

Plugins persist across restarts (loaded from `plugins/` directory on startup). Built-ins are protected — can't be overwritten by `create_tool`. Net result: the agent can permanently extend its own capabilities.

### 2. Self-Repair Loop

Daily cron triggers a self-check → LLM processes diagnostics → notifies owner → can apply fixes.

The full loop:
1. Scheduler triggers `daily-self-check` cron (set up by the agent itself via `schedule` tool)
2. LLM calls `self_check` tool → gets conversation stats, error logs, disk usage, scheduled task status
3. LLM detects issues (high error count, stale sessions, disk full)
4. LLM calls `diagnose` for deeper investigation
5. LLM uses `exec` to run repair commands
6. LLM uses `create_tool` to build new diagnostic tools for novel situations
7. LLM calls `message` to report findings to owner

This is documented explicitly in `self_check_tool.py` as a pattern, not just an implementation. The agent bootstraps its own monitoring via the `schedule` tool.

### 3. Three-Layer Memory (LanceDB, Zero External Service)

```
Layer 1: Session (short-term)
  - Last 40 messages per session, JSON files
  - Overflow triggers compression

Layer 2: Compressed (long-term)
  - LLM extracts structured facts {fact, keywords, persons, timestamp, topic}
  - Deduplication via cosine similarity (threshold: 0.92) before storing
  - LanceDB embedded vector DB — file-level, no standalone service

Layer 3: Retrieval (active recall)
  - User message → embedding → vector search → top-K injected into system prompt
  - Zero-latency context_cache for hardware/voice channels (pre-computed)
```

Public API is just 4 functions: `init()`, `retrieve()`, `compress_and_store()`, `get_context_cache()`. The cosine deduplication (0.92 threshold) prevents memory bloat — semantically similar facts don't accumulate.

**Compression prompt:** when a session's messages overflow, the LLM extracts structured facts rather than just summarizing. Each memory entry has `fact`, `keywords`, `persons`, `timestamp`, `topic` fields — making retrieval more precise than embedding raw text.

### 4. Scheduler with Persistent Jobs

```python
# One-shot (delay in seconds)
schedule(name="remind-me", message="Say: time to stand up!", delay_seconds=3600)

# Recurring cron
schedule(name="daily-check", message="Run self_check, summarize, send to owner", cron_expr="0 22 * * *")

# One-shot cron (fire once at next cron match, then delete)
schedule(name="weekly-report", message="...", cron_expr="0 9 * * 1", once=True)
```

Jobs persist in `jobs.json`, survive restarts. Background thread polls every 10 seconds. Triggered jobs call `chat_fn(message, "scheduler")` — the scheduler sends a message to the LLM and lets it decide what to do, rather than hard-coding the action. The LLM processes "Run self_check, summarize, send to owner" like a normal instruction.

### 5. MCP Client with Namespacing

Tools from MCP servers are namespaced as `server__toolname` — preventing collisions between servers. Auto-reconnect on disconnect. Hot-reload via the `reload_mcp` tool (re-reads config, connects new servers, disconnects removed ones, no restart).

### 6. Multi-Tenant Router

`router.py` (492 lines) handles Docker-based per-user container auto-provisioning with health checks. Each user gets their own isolated agent container. Scales horizontally.

---

## The 26 Built-in Tools

| Category | Tools |
|----------|-------|
| Core | `exec`, `message` |
| Files | `read_file`, `write_file`, `edit_file`, `list_files` |
| Scheduling | `schedule`, `list_schedules`, `remove_schedule` |
| Media Send | `send_image`, `send_file`, `send_video`, `send_link` |
| Video | `trim_video`, `add_bgm`, `generate_video` |
| Search | `web_search` (Tavily/web/GitHub/HuggingFace, auto-routed) |
| Memory | `search_memory`, `recall` |
| Diagnostics | `self_check`, `diagnose` |
| Plugins | `create_tool`, `list_custom_tools`, `remove_tool` |
| MCP | `reload_mcp` |

---

## Design Principles (From the Code)

1. **Zero framework dependency** — every line visible and debuggable. When something breaks at 3am, you can read it.
2. **Single-file tools** — adding a capability = one function with `@tool` decorator. No class hierarchies, no plugin manifests.
3. **Edge-deployable** — designed for Jetson Orin Nano (8GB RAM, ARM64). RAM budget under 2GB. No heavy dependencies.
4. **Self-evolving** — agent creates new tools at runtime, diagnoses its own issues, notifies owner.
5. **Offline-capable** — core functionality works without cloud APIs (except the LLM). Local embeddings supported.

---

## Caveats

- WeChat Work (Enterprise WeChat) as primary channel — this is a Chinese enterprise product. The messaging layer is specific to that platform, though the agent core is channel-agnostic.
- No security hardening documented — `exec` tool is unrestricted, no allowlist pattern. The `create_tool` code validation is just "does it execute without crashing" — no sandbox, no permission checking.
- 974 stars in 11 days — fast growth, but unknown long-term maintenance trajectory
- One maintainer, no tests visible in repo

---

## What's Extractable

**`create_tool` pattern:** The runtime plugin creation pattern — validate before persist, exec in minimal namespace with only `tool` decorator and `log`, protect built-ins — is clean enough to adapt. The key insight: plugins are just Python files in a directory, loaded at startup and hot-swappable at runtime. No plugin manifest, no version negotiation.

**Memory deduplication via cosine threshold:** Simple but effective. Before storing a new compressed memory, check cosine similarity against existing memories. Above 0.92 → skip. Prevents the memory system from filling up with near-duplicate facts as the same topics recur across sessions.

**Structured memory extraction:** Rather than compressing conversation history to plain text, extract structured facts per memory entry (`fact`, `keywords`, `persons`, `timestamp`, `topic`). Makes retrieval more precise and enables faceted querying.

**Scheduler-as-LLM-trigger:** Scheduled jobs don't hard-code actions — they send a message to the LLM. "Run self_check, summarize, send to owner" is processed like any other instruction. The LLM decides the tool sequence. This means the scheduler itself is tool-agnostic and never needs updating when tools change.

**Self-monitoring via self-created cron:** The agent creates its own daily monitoring cron job via the `schedule` tool. The bootstrapping pattern: initial setup creates the monitoring loop, then the loop maintains itself.

---

## Comparison to OpenClaw

| Aspect | 724-office | OpenClaw |
|--------|-----------|---------|
| Core language | Pure Python, ~3500 lines | Node.js, framework-level |
| Runtime tool creation | ✅ `create_tool` writes Python plugins | ✅ Skills system (filesystem-level) |
| Memory | 3-layer: session + compressed LLM + LanceDB vector | LCM compaction (more sophisticated) |
| Scheduler | Built-in Python, `jobs.json` | LaunchAgents / cron |
| MCP support | ✅ JSON-RPC, namespaced, hot-reload | ✅ mcporter |
| Multi-tenant | ✅ Docker per-user | Not built-in |
| Self-repair | ✅ explicit self_check + diagnose loop | Heartbeat + watchdog |
| Security | ❌ minimal | Better (exec approvals, allowlists) |

The notable difference: 724-office's `create_tool` pattern gives the agent genuine runtime extensibility. Skills in OpenClaw are filesystem-level (write a skill file, it becomes available next session). 724-office's plugins are available immediately, in the same session, without restart. That's a meaningful operational difference for a 24/7 agent.

---

## Verdict

🔥🔥🔥🔥🔥 — The cleanest zero-dependency agent implementation I've seen. The self-evolving runtime tool creation, structured memory compression with cosine dedup, and scheduler-as-LLM-trigger patterns are all directly extractable. The self-repair loop (daily cron → LLM processes diagnostics → notifies owner → applies fixes → creates new diagnostic tools for novel situations) is well-architected and documented as a first-class pattern. Readable, debuggable, edge-deployable.

Main limitation: no security hardening. The `exec` tool is unrestricted and `create_tool` doesn't sandbox the submitted code beyond "does it execute." Not a concern for a personal single-user agent, but important to note.

MIT. Cloned to `~/src/724-office`.
