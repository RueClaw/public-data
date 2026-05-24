# agentmemory Review

- **Source:** https://github.com/rohitg00/agentmemory
- **Author:** Rohit Ghumare and contributors
- **License:** Apache-2.0
- **Reviewed:** 2026-05-23
- **Prior review:** 2026-05-19
- **Current release:** v0.9.21; reviewed commit `3551241`, one commit after the release tag
- **Verdict:** ⚠️ Interesting

## Update Notes

The project changed materially since the 2026-05-19 review. v0.9.19 through v0.9.21 added commit linking, Azure/OpenAI-compatible provider fixes, Dijkstra graph retrieval, lesson surfacing in smart search, viewer CSP hardening, filesystem-watcher redaction, more Codex/Claude hook wiring, a reproducible coding-agent-life benchmark harness, and CI/release workflow hardening.

The verification signal is stronger now: local build passed and the non-integration suite passed with 99 test files / 1096 tests. The caveat remains the optional local embedding dependency chain: `npm audit --audit-level moderate` still reports 4 advisories, including 1 critical and 3 high, through `@xenova/transformers` / `onnxruntime-web` / `onnx-proto` / `protobufjs`.

## Summary

agentmemory is a persistent memory server for AI coding agents. It captures agent sessions through hooks, stores observations and memories through the iii engine, exposes REST and MCP surfaces, and retrieves relevant context with BM25, vector search, graph search, lessons, profiles, and token-budgeted context injection.

The project is much more ambitious than a small MCP server. It includes a CLI, multi-agent wiring helpers, Claude Code and Codex plugin metadata, standalone MCP fallback behavior, a local viewer, session replay/import, privacy redaction, audit logging, retention and deletion flows, memory consolidation, lessons, temporal graph search, multimodal/image handling, Obsidian export, benchmarks, deployment docs, and a filesystem watcher.

The core idea is strong: treat agent memory as an event-sourced local service with automatic capture and progressive retrieval, rather than asking agents to manually edit a static memory file.

## What It Does

- Starts a local memory server, defaulting to REST on port 3111 and a viewer on port 3113.
- Provides MCP tools for memory recall, save, smart search, file history, sessions, timeline, relations, export, lessons, governance delete, and diagnostics.
- Wires into agent hosts through hooks, plugins, MCP config, or REST.
- Captures session starts, prompts, tool use, tool failures, compaction, stop/session-end events, and commit links.
- Stores observations, memories, sessions, lessons, graph nodes/edges, routines, signals, audit entries, and related state.
- Supports BM25 search, optional embeddings, graph retrieval, reranking, query expansion, compact result previews, and expand-on-demand recall.
- Includes privacy filtering for common secret formats before memory storage.
- Provides deletion, retention, auto-forget, audit, export/import, and viewer/replay paths.
- Publishes benchmark docs for LongMemEval-S retrieval, an in-house coding-agent-life corpus, quality, scale, and token-savings tests.

## Architecture Notes

The implementation is TypeScript/Node, packaged as `@agentmemory/agentmemory`.

Key areas:

- `src/index.ts` is the main server bootstrap. It registers memory functions, search, context, consolidation, graph, privacy, retention, MCP endpoints, REST triggers, viewer, health, telemetry, and hook-facing APIs.
- `src/mcp/server.ts` exposes the HTTP-backed MCP tool bridge with optional bearer-token auth through `AGENTMEMORY_SECRET`.
- `src/mcp/standalone.ts` provides MCP operation even when the main server is not reachable by falling back to an in-memory local store.
- `src/hooks/` contains host hook scripts for session and tool-event capture.
- `src/functions/remember.ts`, `observe.ts`, `context.ts`, `smart-search.ts`, `lessons.ts`, `consolidate.ts`, and `retention.ts` define the main memory lifecycle.
- `src/state/search-index.ts`, `hybrid-search.ts`, `vector-index.ts`, and `src/functions/graph-retrieval.ts` implement retrieval.
- `src/functions/privacy.ts` and `integrations/filesystem-watcher/watcher.mjs` strip private blocks and common secret/token patterns.
- `src/functions/audit.ts` documents and enforces audit expectations for delete paths.

## Strong Patterns

### Hook-Captured Memory Lifecycle

agentmemory's best reusable pattern is its lifecycle design:

1. Capture agent events through host hooks.
2. Normalize them into observations.
3. Strip private data and truncate large outputs.
4. Compress and consolidate observations into memories and lessons.
5. Index with keyword, vector, and graph retrieval.
6. Inject only relevant context at the next session or tool boundary.
7. Track access, deletion, retention, and audit state.

See extracted pattern: [`patterns/hook-captured-agent-memory.md`](../patterns/hook-captured-agent-memory.md).

### Progressive Disclosure For Recall

`memory_smart_search` returns compact search results first and supports expansion by observation ID. That is the right shape for agent tools: cheap scans first, full context only when needed. The newer lesson surfacing makes the recall path denser without dumping full session history into context.

### Memory Is A Service, Not A File

The project treats memory as a live service with REST, MCP, viewer, export/import, health, and hooks. That is heavier than a static `MEMORY.md`, but it makes cross-agent memory, observability, and policy enforcement possible.

### Privacy And Governance Are First-Class

The code includes secret stripping, private block redaction, audit rows, retention functions, governance delete, viewer DNS-rebinding tests, CSP hardening, and a security disclosure policy. These are necessary for any tool that passively captures agent work.

### Benchmark Receipts

The benchmark story is better than most agent-memory projects. The repo includes LongMemEval material, quality/scale notes, and a reproducible coding-agent-life harness comparing agentmemory against grep/vector baselines. The claims still need environment-specific validation, but the receipt trail is real enough to study.

## Risks

agentmemory captures prompts, tool inputs, tool outputs, file paths, sessions, and potentially screenshots or images. That makes privacy and access control central, not optional.

Important risks:

- The local REST/MCP surfaces are permissive unless `AGENTMEMORY_SECRET` is configured.
- Hook-based capture can store sensitive project details if redaction misses a format.
- The standalone MCP fallback can create a separate local memory island when the main server is unreachable.
- The package intentionally has no committed lockfile; CI generates one in-runner before `npm ci`, so consumers need to watch dependency drift.
- `npm audit --audit-level moderate` reports critical/high advisories through optional local embedding dependencies.
- The README is ambitious and marketing-heavy; deployment decisions should be based on code, local verification, and a threat model, not headline benchmark claims alone.

## Verification

Local verification on 2026-05-23 at commit `3551241`:

- `npm install --package-lock-only --legacy-peer-deps --no-audit --no-fund` passed.
- `npm ci --legacy-peer-deps --no-fund` passed after generating the lockfile, matching the repo's CI pattern.
- `npm run build` passed.
- `npm test -- --reporter=dot --pool=forks --testTimeout=10000` passed: 99 test files, 1096 tests.
- `npm audit --audit-level moderate` reported 4 vulnerabilities: 1 critical and 3 high, rooted in optional `@xenova/transformers` / `onnxruntime-web` / `onnx-proto` / `protobufjs` paths.
- A secret-pattern scan found no obvious live secrets in source; hits were expected config names, redaction code, and demo strings.

The passing suite is a strong signal. The optional dependency audit findings and passive-capture threat model are still real release-quality issues.

## Recommendation

Use agentmemory as a serious study target and controlled pilot, not as a blind install.

It is valuable for:

- Designing memory capture around hooks rather than manual notes.
- Studying progressive recall and expand-on-demand MCP tools.
- Studying hybrid retrieval over observations, memories, lessons, and graphs.
- Harvesting privacy, audit, retention, and governance patterns for agent memory systems.
- Comparing local memory services against static memory files.
- Studying how agent integrations can share one memory service without forcing every host to own storage.

Before relying on it with sensitive work:

- Require `AGENTMEMORY_SECRET` for anything beyond loopback toy use.
- Decide whether optional local embedding dependencies are worth the current audit exposure.
- Review bind addresses, viewer exposure, and bearer-token transport.
- Threat-model what hooks capture and what redaction misses.
- Test deletion, retention, export, and replay behavior with representative private data.

The project is impressive and actively maintained. It is close to deployable for controlled local experiments, but the dependency and privacy boundaries keep it at ⚠️ Interesting for now.

**Attribution:** [rohitg00/agentmemory](https://github.com/rohitg00/agentmemory), Apache-2.0.
