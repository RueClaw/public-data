# Tracebase (ssreeni1/tracebase)

**Repo:** https://github.com/ssreeni1/tracebase
**License:** MIT. Permissive reuse with attribution.
**Reviewed:** 2026-05-29
**Stack:** Node.js 24+, CommonJS, built-in `node:sqlite`, React/Vite dashboard, JSZip, MCP stdio
**What it is:** Tracebase is a local-first trace capture, search, analysis, and dashboard tool for Codex and Claude agent sessions. It imports local transcript JSONL, encrypts raw events, indexes redacted metadata, and serves a localhost UI/API for debugging agent runs.

---

## Verdict

✅ **Deploy candidate for local agent observability.** The implementation is small, privacy-conscious, and unusually well validated for a two-day-old repo: the full `npm test` suite passed locally, `npm install` reported no vulnerabilities, and the security model is documented and tested. The main caveat is freshness: this is version `0.1.0`, created on 2026-05-26, so use it first as a local developer tool rather than shared production infrastructure.

---

## What It Is

Tracebase turns local coding-agent transcripts into auditable traces. It reads existing Codex and Claude JSONL logs, normalizes transcript-visible events, stores raw payloads in encrypted local blobs, and indexes redacted metadata into SQLite/FTS for search, dashboards, exports, run comparisons, and MCP access.

The tool is deliberately workstation-scoped. It does not proxy network traffic, does not claim to recover hidden model reasoning, binds the dashboard to `127.0.0.1` by default, and requires explicit opt-ins for remote bind, live intake, raw blob reads, and raw exports.

The strongest product choice is that it treats agent debugging as an engineering trace problem, not only a chat-history problem. It records sessions, events, canonical traces/spans, LLMObs-shaped spans, token rollups, annotations for failures/loops/context waste, decision logs, and redacted incident bundles.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Node.js 24+, CommonJS |
| Storage | Append-only JSONL, AES-256-GCM encrypted blobs, SQLite/FTS5 via `node:sqlite` |
| Capture | Codex JSONL import, Claude JSONL import, Claude hooks, wrapper commands, explicit local intake |
| Dashboard/API | Node `http`, React 19, Vite 8, lucide-react |
| Exports | JSZip redacted/raw/incident bundles |
| Integrations | CLI, MCP stdio server, launchd watcher support, Datadog LLMObs-shaped projections |
| Validation | Syntax check, release audit, smoke, stress, UI, E2E, package, install smoke |

## Key Features

### Encrypted Raw Store With Redacted Index

Raw transcript payloads are encrypted locally with AES-256-GCM under `TRACE_HOME`, while searchable rows carry compact redacted text and structured metadata. This is the right default split for agent logs: keep forensic fidelity locally, but make normal search/export paths safer.

### Localhost-First Dashboard And API

The HTTP server binds to loopback by default and refuses non-loopback hosts unless explicitly allowed. Browser state-changing requests must match the server origin, raw blob reads are disabled by default, raw HTTP export requires a special header, and responses include defensive browser headers.

### Agent Run Intelligence

Tracebase derives practical run diagnostics: failed tools, repeated commands, approval denials, large outputs, context waste, token/cache/reasoning rollups, quality/efficiency/risk scores, and run-to-run comparisons. These are concrete signals for debugging agent sessions.

### Export And Incident Bundles

Default exports are redacted zip bundles containing sessions, events, traces, spans, metrics, annotations, and summaries. Raw exports are possible but intentionally gated. Incident exports package diagnostics without making raw payloads the default.

### Read-Only MCP Surface

The MCP server exposes trace search and canonical trace/span listing without write tools. That lets local agents inspect prior runs without broad mutation authority.

## Architecture

Tracebase uses a simple layered pipeline:

```text
Codex/Claude JSONL, hooks, wrappers, intake
  -> normalize + redact
  -> encrypted raw blobs
  -> append-only JSONL metadata
  -> SQLite/FTS index
  -> CLI, dashboard/API, MCP, exports, analysis
```

Two design decisions matter most. First, SQLite is rebuildable from append-only logs and encrypted blobs, so the database is an index rather than the only source of truth. Second, raw payload access is separated from routine search and export, so day-to-day inspection is less likely to leak sensitive transcript data.

The codebase is compact: 63 tracked files in the reviewed checkout, with core logic under `src/`, CLIs under `bin/`, tests under `test/`, and release smoke scripts under `scripts/`.

## Comparison

| Aspect | Tracebase | Agentmemory | CodeGraph |
|--------|-----------|-------------|-----------|
| Primary job | Inspect local agent runs | Persist/retrieve agent memory | Pre-index source code for agents |
| Data captured | Transcript-visible run events | Hooked observations, memories, lessons | Repository symbols/files/edges |
| Default posture | Local, encrypted raw blobs, redacted index | Local service with broader memory surface | Repo-local derived code index |
| Agent interface | Read-only MCP | MCP/REST memory tools | MCP code graph tools |
| Best fit | Debugging and auditing agent sessions | Long-term recall experiments | Reducing repeated codebase discovery |

Tracebase is closer to an observability/forensics tool than a memory system. It complements memory and code graph tools because it shows what actually happened during a run: commands, failures, outputs, recovery steps, and token usage.

## Self-Hosting Notes

Install requires Node.js 24 or newer:

```sh
npm install -g tracebase-local
tracebase init
tracebase import
tracebase serve
```

The dashboard defaults to `http://127.0.0.1:18427`. Treat `TRACE_HOME` as sensitive local state because raw transcripts may contain prompts, paths, tool outputs, and secrets even though normal search/export paths are redacted.

Local verification on 2026-05-29:

- `npm install`: passed, 0 vulnerabilities.
- `npm test`: passed all gates, including syntax, release audit, smoke, stress, UI build/smoke, local E2E, release E2E, package dry-run, and install smoke.
- Reviewed commit: `5a057f9541b1143f685585723320457b26cef6f4`.

---

**Attribution:** ssreeni1/tracebase, MIT.
