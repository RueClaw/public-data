# Hook-Captured Agent Memory

- **Source:** https://github.com/rohitg00/agentmemory
- **Author:** Rohit Ghumare and contributors
- **License:** Apache-2.0
- **Extracted from:** `src/hooks/`, `src/functions/`, `src/mcp/`
- **Reviewed:** 2026-05-19

## Pattern

Build agent memory as a local service fed by host lifecycle hooks, not as a static file that agents manually edit.

The service observes session events, normalizes them into memories, indexes them for retrieval, and injects relevant context back into later sessions. The agent does not need to remember to save everything manually; the platform captures the evidence stream and lets explicit saves supplement it.

## Lifecycle

1. **Session start:** register session metadata and optionally return relevant context.
2. **Prompt submit:** capture the user request and project/session identifiers.
3. **Tool use:** capture tool name, input, bounded output, file paths, image references, and errors.
4. **Privacy pass:** remove private blocks and common secret/token formats before durable storage.
5. **Observation write:** store normalized observations under the session.
6. **Compression:** summarize or compress large observations into denser memory candidates.
7. **Consolidation:** promote repeated or important observations into semantic memories and lessons.
8. **Indexing:** update keyword, vector, graph, and recency structures.
9. **Recall:** return compact matches first, then expand full observations only when requested.
10. **Governance:** support delete, retention, export, audit, and access tracking.

## Why Hooks Matter

Manual memory APIs are too sparse. Agents often forget to call them, and the most useful information is usually hidden in mundane work: tool failures, changed files, test output, commands, project paths, and repeated fixes.

Hooks make memory passive and evidence-rich:

- Session hooks capture project continuity.
- Prompt hooks capture user intent.
- Tool hooks capture what changed and what failed.
- Stop/session-end hooks trigger consolidation and summary.
- Pre-context hooks inject only relevant memories into future work.

This shifts memory from "what the agent remembered to write down" to "what the work actually produced."

## Retrieval Shape

Use progressive disclosure:

- Return compact hits first: IDs, titles, types, timestamps, and scores.
- Let the agent expand specific IDs into full observations.
- Include curated lessons separately from raw observations.
- Apply a token budget to context injection.
- Track access so high-value memories can be reinforced.

This prevents recall tools from flooding the context window while still giving the agent a path to inspect details.

## Safety Rules

Hook-captured memory is powerful because it is automatic. That is also why it needs hard boundaries:

- Secret redaction must happen before storage.
- Capture should truncate large tool outputs by default.
- Sensitive image or binary data should be stored by reference with quotas.
- REST/MCP access should require a bearer secret outside local toy use.
- Deletion and retention paths must write audit records.
- Export/import should preserve enough metadata to verify what was captured.
- Hook failures should time out quickly and never block the host agent.

## Implementation Notes

Useful modules to keep separate:

- **Hook adapters:** host-specific scripts that read hook payloads and POST normalized events.
- **Observation store:** append-only-ish session event records.
- **Memory store:** durable semantic memories with version/supersession metadata.
- **Search indexes:** BM25, vector, graph, and recency/rerank layers.
- **Context builder:** token-budgeted recall formatter.
- **Governance layer:** delete, retention, audit, privacy, and export.
- **Viewer:** local observability for what the memory system captured.

The cleanest design keeps host-specific integration at the edges and stores memory in host-neutral schemas.

## When To Use

Use this pattern when:

- Agents work across long-lived projects.
- Multiple agents or tools need shared memory.
- Static memory files are too small or stale.
- Tool histories and file histories matter.
- Users need recall without re-explaining project state every session.

Avoid it when:

- Work is highly sensitive and cannot tolerate passive capture.
- There is no clear deletion and retention story.
- The server cannot be protected from other local users or network peers.
- The memory system would become another unobserved source of prompt injection or stale facts.
