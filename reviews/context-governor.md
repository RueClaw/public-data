# Context Governor (gbgh1/context-governor)

**Repo:** https://github.com/gbgh1/context-governor  
**License:** MIT; permissive reuse with attribution and license preservation  
**Reviewed:** 2026-08-15  
**Stack:** Python 3.11+, FastAPI, httpx, uvicorn, SQLite/FTS5, MCP, rapidfuzz, llama.cpp/OpenAI-compatible APIs  
**What it is:** A local context-management layer for long-running agent sessions: an OpenAI-compatible proxy plus MCP server that stores bulky context off-wire, sends bounded stubs upstream, and rehydrates relevant memory when needed.

---

## Verdict

⚠️ **Strong idea and strong proxy core, blocked from clean deployment by an unpinned MCP dependency.** Context Governor attacks a real local-agent failure mode: transcripts grow until the host CLI's own compaction loops or destroys useful context. The proxy/store/wiring core is unusually well-tested and locally passed a large non-MCP subset, but a fresh install currently pulls `mcp 2.0.0`, which no longer exposes `mcp.server.fastmcp`; full test collection and the MCP surface fail until the project pins the compatible MCP line or updates the import.

---

## What It Is

Context Governor sits between an OpenAI-compatible agent CLI and an upstream model server, originally `llama-server`. Instead of forwarding every giant tool output, file dump, and transcript tail verbatim forever, it stores bulky stable content in a durable local store and replaces it on the wire with compact handles. The upstream prompt stays bounded, while the full content remains recoverable.

The repo exposes two surfaces over the same store. Surface A is a transparent OpenAI-compatible reverse proxy on `127.0.0.1:8900` by default. Surface B is an MCP stdio server with tools for saving, searching, checkpointing, loading state, and rehydrating context. The design supports both non-cooperating CLIs, which benefit from the proxy automatically, and cooperating agents, which can explicitly decide what to externalize and recall.

The README claims a live instance saved roughly 1.6M tokens, about 72%, across 115 requests with peak prompt under 10K tokens. Treat that as field evidence, not a benchmark suite. The stronger evidence is the code and tests around deterministic rewriting, lossless storage, dynamic context-window sensing, prefix stability, loop guarding, and config-root anchoring.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python 3.11+ package named `contextmanager` |
| Proxy API | FastAPI, uvicorn, OpenAI-compatible `/v1/chat/completions` and model/props passthrough |
| Upstream client | httpx async client, SSE passthrough |
| Store | Markdown notes, gzip archive tier, `state.json`, SQLite/FTS5 lexical index, hotness DB |
| Context logic | Deterministic prompt rewriter, handle stubs, lossless windowing, recall, loop guard |
| MCP surface | Python MCP server with six cooperative memory/state tools |
| Config | Env vars, TOML config, provider profiles, CLI wiring for Hermes/OpenCode |
| Tests | pytest, pytest-asyncio, hypothesis; substantial offline suite |

## Key Features

### Lossless Off-Wire Context

The proxy stores bulky messages before removing them from the upstream payload. It emits parseable stubs such as `[[cm:stored handle=...]]`, keeps previews small, and can rehydrate exact content by handle. Evicted notes move to a gzip archive tier rather than being deleted, and later access can resurrect them.

This is the central distinction from ordinary summarization. Summaries are lossy; Context Governor uses handles and retrieval so the original bytes can still come back.

### Prefix-Stable Prompt Rewriting

The rewriter is designed to avoid creating its own cache churn. It normalizes known volatile system-prompt stamps, makes handle IDs deterministic, keeps already-stubbed messages byte-stable, and uses hysteresis so windowing cuts deeper only when pressure crosses thresholds. That matters for local inference because prompt-cache reuse can be as important as raw token count.

### Dynamic Window Sensing

For llama.cpp, the proxy reads `/props` and `/tokenize` so thresholds scale against the real model context window. It also observes provider usage/timing fields to maintain prompt-pressure metrics and learned ceilings. Remote OpenAI-compatible providers can be used with a heuristic counter and explicit `upstream_n_ctx`, though that path is less exact.

### Shared Proxy And MCP Store

The MCP server exposes six tools:

- `store_save`
- `store_search`
- `state_snapshot`
- `state_load`
- `context_checkpoint`
- `context_rehydrate`

The proxy and MCP server share the same durable store, so a handle created by one surface can resolve through the other. That is the right product shape: automatic relief plus deliberate memory operations.

### Operational Guardrails

The project defaults to loopback binding, names the absolute store path at launch, redacts API keys from dry-run output and wire captures, and keeps forensic wire capture opt-in. It also has tests around config-root anchoring after a real bug where one config file could address different stores depending on the process working directory.

## Architecture

The implementation is split cleanly:

- `proxy/app.py` owns FastAPI routes, upstream calls, metrics, stream/non-stream handling, and context-window adoption.
- `proxy/rewriter.py` owns the deterministic message transform and recall/windowing logic.
- `durable.py`, `note_store.py`, `state_store.py`, and `retriever.py` own persistence, search, archive/restore, and hotness ranking.
- `mcp/server.py` is intentionally thin: tool wrappers delegate to `GovernorService`.
- `launcher.py` resolves layered config and can wire supported CLIs.

The strongest design decision is treating the upstream prompt as a bounded projection over a fuller local store. The proxy does not need every CLI to learn new tools, but the MCP server gives capable agents a more precise cooperative path.

## Comparison

| Aspect | Context Governor | agentmemory | Tracebase | SageRoute |
|--------|------------------|-------------|-----------|-----------|
| Primary job | Keep active agent context bounded | Persist agent memory across sessions | Inspect what happened in agent runs | Route models based on trajectory evidence |
| Runtime shape | OpenAI proxy + MCP server | Hooks/API/MCP memory service | Local trace store/dashboard/MCP | OpenAI/Anthropic proxy |
| Storage | Lossless notes/state/search store | Memory graph/search store | Encrypted raw blobs + redacted index | In-memory routing sessions |
| Best fit | Long local agent sessions near context limits | Long-term recall experiments | Debug/audit agent sessions | Cheap-to-strong model routing |
| Main caveat | Current MCP dependency break | Sensitive passive capture surface | Fresh local observability tool | External decision dependency / early maturity |

Context Governor is closest to a context-window pressure valve. It complements memory and observability tools rather than replacing them.

## Self-Hosting Notes

Use it on loopback first. The store and optional wire captures can contain sensitive prompts, file contents, and tool outputs, so do not sync or expose `contextstore` casually.

For a clean install today, pin or verify the MCP dependency before depending on the MCP surface. A fresh install during this review pulled `mcp 2.0.0` and failed because `mcp.server.fastmcp` was missing. The proxy/store core still tested well when MCP-dependent tests were excluded.

Local verification on 2026-08-15:

```bash
python3.13 -m venv .venv313
.venv313/bin/python -m pip install -e '.[dev]'
.venv313/bin/python -m pytest -q
```

Full test collection failed with `ModuleNotFoundError: No module named 'mcp.server.fastmcp'`. A non-MCP subset passed:

```bash
.venv313/bin/python -m pytest -q \
  --ignore=tests/mcp_server \
  --ignore=tests/proxy/test_remote_providers.py \
  --ignore=tests/test_cross_surface.py
```

Result: `653 passed, 1 skipped`.

---

**Attribution:** gbgh1/context-governor, MIT, https://github.com/gbgh1/context-governor
