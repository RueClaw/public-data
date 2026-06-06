# pi-observational-memory (elpapi42/pi-observational-memory)

**Repo:** https://github.com/elpapi42/pi-observational-memory  
**License:** MIT  
**Reviewed:** 2026-06-06  
**Stack:** TypeScript, Pi extension API, Vitest, model-backed observer/reflector/dropper workers  
**What it is:** A Pi extension that records session observations and durable reflections in a ledger so long coding sessions can survive compaction with less context drift.

---

## Verdict

✅ **Deploy candidate for Pi users who live in long sessions.** The implementation is focused, tested, and built around a clean idea: move memory extraction out of the latency-critical compaction path and render compaction summaries deterministically from a folded ledger. It is Pi-specific and young, but the architecture is strong enough to trial on real multi-day work.

---

## What It Is

`pi-observational-memory` tries to make Pi coding sessions feel continuous across compactions, restarts, and long-running work. Instead of relying on repeated summaries of summaries, it captures concrete observations during the session, distills stable reflections from them, and later uses those records as the memory payload for compaction.

The V3 design is ledger-centered. Memory events are appended as custom entries: observations recorded, reflections recorded, and observations dropped. A compaction hook folds those entries into active observations and reflections, then renders a deterministic summary. The model-heavy work happens earlier through background observer, reflector, and dropper stages.

This is not a general memory server. It is a Pi extension with Pi-specific hooks, settings, command surfaces, and a `recall` tool for recovering source evidence by memory id.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Pi extension API via `@earendil-works/pi-coding-agent` |
| Language | TypeScript ESM |
| Memory model | Append-only custom ledger entries folded into observations/reflections |
| Agent workers | Observer, reflector, dropper model calls |
| Commands | `/om:status`, `/om:view` |
| Tooling | `recall` tool for source-backed memory lookup |
| Tests | Vitest, TypeScript `tsc --noEmit` |

## Key Features

### Background observation and reflection

The extension watches Pi session progress and runs memory workers when token thresholds are crossed. The observer records concrete events from source entries. The reflector turns active observations into durable facts. The dropper trims active observations only after a same-run successful reflection, using reflection coverage as evidence that meaning has been preserved.

### Deterministic compaction hook

At `session_before_compact`, the hook avoids a fresh model call. It folds the ledger, applies the configured observation pool budget, renders the summary, and returns folded details. That keeps compaction fast and reduces the chance that compaction itself becomes another expensive summarization step.

### Source-backed recall

Memory ids are short deterministic ids, and the extension registers a `recall` tool. When a reflection or observation matters, the agent can fetch source evidence instead of treating compressed memory as unsupported truth.

### Operator controls

The repo includes status and view commands, passive mode, configurable thresholds, optional model override, and opt-in debug logging. That is the right shape for memory infrastructure: it needs visibility and a way to turn itself down.

## Architecture

The strongest pattern is the separation between memory extraction and memory rendering:

- source session entries are the raw material;
- observer and reflector workers append validated custom entries;
- dropper entries tombstone observations instead of deleting history;
- compaction folds valid entries from branch root to boundary;
- rendered summaries are deterministic products of the fold.

That is much sturdier than a pure rolling-summary chain. It also gives downstream tools a place to attach provenance through `sourceEntryIds` and `supportingObservationIds`.

## Comparison

| Aspect | pi-observational-memory | supermemory | agentmemory |
|--------|-------------------------|-------------|-------------|
| Scope | Pi session continuity | Hosted/API memory platform | Memory server for coding agents |
| Storage model | In-session custom ledger entries | External memory service/API | External MCP/REST memory server |
| Best use | Compaction resilience inside Pi | Cross-agent/user memory and retrieval | Persistent coding-agent memory |
| Main caveat | Pi-specific and young | Sensitive hosted memory surface | More operational surface area |

## Self-Hosting Notes

Install through Pi:

```bash
pi install npm:pi-observational-memory
```

Configuration lives under `observational-memory` in global or project-local Pi settings. The defaults are reasonable for a first trial, but memory-worker model selection and token thresholds should be tuned for cost, latency, and privacy.

Verification on 2026-06-06:

- `npm install` completed with one deprecated transitive warning.
- `npm test` passed: 21 files, 179 tests.
- `npm run typecheck` passed.
- `npm audit --omit=dev` reported 0 vulnerabilities.
- Full dev `npm audit` reported 7 transitive vulnerabilities, including protobuf/XML/ws advisories from the development dependency tree.

---

**Attribution:** elpapi42/pi-observational-memory, MIT License.
