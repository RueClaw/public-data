# agentmemory Review

- **Source:** https://github.com/rohitg00/agentmemory
- **Author:** Rohit Ghumare and contributors
- **License:** Apache-2.0
- **Reviewed:** 2026-05-19
- **Verdict:** ⚠️ Interesting

## Summary

agentmemory is a persistent memory server for AI coding agents. It captures agent sessions through hooks, stores observations and memories through the iii engine, exposes REST and MCP surfaces, and retrieves relevant context with BM25, vector search, graph search, lessons, profiles, and token-budgeted context injection.

The project is much more ambitious than a small MCP server. It includes a CLI, multi-agent wiring helpers, Claude Code and Codex plugin metadata, standalone MCP fallback behavior, a local viewer, session replay/import, privacy redaction, audit logging, retention and deletion flows, memory consolidation, lessons, temporal graph search, multimodal/image handling, Obsidian export, benchmarks, and a deployment story.

The core idea is strong: treat agent memory as an event-sourced local service with automatic capture and progressive retrieval, rather than asking agents to manually edit a single static memory file.

## What It Does

- Starts a local memory server, defaulting to REST on port 3111 and a viewer on port 3113.
- Provides MCP tools such as memory recall, save, smart search, file history, sessions, timeline, relations, export, lessons, governance delete, and more.
- Wires into multiple agent hosts through hooks, plugins, MCP config, or REST.
- Captures session starts, prompts, tool use, tool failures, compaction, stop/session-end events, and commit links.
- Stores observations, memories, sessions, lessons, graph nodes/edges, routines, signals, audit entries, and related state.
- Supports BM25 search, optional embeddings, graph retrieval, reranking, query expansion, and progressive disclosure.
- Includes privacy filtering for common secret formats before memory storage.
- Provides deletion, retention, auto-forget, audit, and export/import paths.
- Publishes benchmark docs for LongMemEval-S retrieval and internal quality/scale tests.

## Architecture Notes

The implementation is TypeScript/Node, packaged as `@agentmemory/agentmemory`.

Key areas:

- `src/index.ts` is the main server bootstrap. It registers memory functions, search, context, consolidation, graph, privacy, retention, MCP endpoints, REST triggers, viewer, health, telemetry, and hook-facing APIs.
- `src/mcp/server.ts` exposes the HTTP-backed MCP tool bridge with optional bearer-token auth through `AGENTMEMORY_SECRET`.
- `src/mcp/standalone.ts` provides MCP operation even when the main server is not reachable by falling back to an in-memory local store.
- `src/hooks/` contains host hook scripts for session and tool-event capture.
- `src/functions/remember.ts`, `observe.ts`, `context.ts`, `smart-search.ts`, `consolidate.ts`, `lessons.ts`, and `retention.ts` define the main memory lifecycle.
- `src/state/search-index.ts`, `hybrid-search.ts`, `vector-index.ts`, and `graph-retrieval.ts` implement retrieval.
- `src/functions/privacy.ts` strips private blocks and common secret/token patterns.
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

`memory_smart_search` returns compact search results first and supports expansion by observation ID. This is the right shape for agent tools: cheap scans first, full context only when needed.

### Memory Is A Service, Not A File

The project treats memory as a live service with REST, MCP, viewer, export/import, health, and hooks. That is heavier than a static `MEMORY.md`, but it makes cross-agent memory and observability possible.

### Privacy And Governance Are First-Class

The code includes secret stripping, private block redaction, audit rows, retention functions, governance delete, and a security disclosure policy. These are necessary for any tool that passively captures agent work.

## Risks

agentmemory captures prompts, tool inputs, tool outputs, file paths, sessions, and potentially screenshots or images. That makes privacy and access control central, not optional.

Important risks:

- The local REST/MCP surfaces are permissive unless `AGENTMEMORY_SECRET` is configured.
- Hook-based capture can store sensitive project details if redaction misses a format.
- The standalone MCP fallback can create a separate local memory island when the main server is unreachable.
- Fresh `npm install` currently fails on a peer dependency conflict.
- `npm audit --omit=dev` reports critical/high advisories through optional local embedding dependencies.
- The README is ambitious and marketing-heavy; deployment decisions should be based on code and local verification, not headline benchmark claims alone.

## Verification

Local verification on 2026-05-19:

- `npm install` failed with an `ERESOLVE` peer dependency conflict: `@anthropic-ai/claude-agent-sdk` requires `@anthropic-ai/sdk >=0.93.0`, while the package declares `@anthropic-ai/sdk ^0.39.0`.
- `npm install --legacy-peer-deps --include=dev` completed.
- `npm run build` passed.
- `npm test` passed: 95 test files, 1067 tests.
- `npm audit --omit=dev --json` reported 4 vulnerabilities: 1 critical and 3 high, rooted in optional `@xenova/transformers` / `onnxruntime-web` / `onnx-proto` / `protobufjs` paths.

The passing test suite is a strong signal. The fresh install failure and audit findings are also real release-quality issues.

## Recommendation

Use agentmemory as a serious study target and controlled pilot, not as a blind install.

It is valuable for:

- Designing memory capture around hooks rather than manual notes.
- Studying progressive recall and expand-on-demand MCP tools.
- Studying hybrid retrieval over observations, memories, lessons, and graphs.
- Harvesting privacy, audit, retention, and governance patterns for agent memory systems.
- Comparing local memory services against static memory files.

Before relying on it with sensitive work:

- Require `AGENTMEMORY_SECRET` for anything beyond loopback toy use.
- Resolve the npm peer dependency conflict.
- Review or disable optional embedding dependencies until critical audit findings are addressed.
- Threat-model what hooks capture and where the viewer/server bind.
- Test deletion/retention/export behavior with representative private data.

The project is impressive and actively maintained, but the packaging and dependency risks keep it at ⚠️ Interesting for now.
