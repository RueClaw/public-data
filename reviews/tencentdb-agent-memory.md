# TencentDB Agent Memory Review

- Source: https://github.com/TencentCloud/TencentDB-Agent-Memory
- Author: TencentCloud
- License: MIT text in `LICENSE`; GitHub currently reports `NOASSERTION` because of a custom Tencent header
- Reviewed: 2026-07-06
- Commit reviewed: `4339e63650920871eb0e8888083a1779d114e3ae`
- Verdict: ✅ Deploy candidate

## What It Is

TencentDB Agent Memory is a TypeScript memory plugin for OpenClaw and Hermes-style agents. It combines two related ideas:

1. Local long-term memory that stores conversations as progressive layers rather than a flat vector pile.
2. Short-term context offload that replaces verbose history and tool output with compact symbolic references, especially Mermaid task graphs.

The default path is local-first: SQLite, FTS, `sqlite-vec`, local files, and optional local embedding support. Tencent Cloud VectorDB is an optional backend, not the baseline requirement.

The package is published as `@tencentdb-agent-memory/memory-tencentdb` and includes an OpenClaw plugin manifest, runtime hooks, CLI helpers, a Hermes Gateway server, a Hermes Python client package, and diagnostic/setup scripts.

## Architecture

The long-term memory model is explicitly layered:

- `L0`: raw conversation records.
- `L1`: extracted memory atoms.
- `L2`: scene or scenario blocks.
- `L3`: longer-lived persona/profile summaries.

The host-facing entry point is `src/core/tdai-core.ts`, which keeps the core memory engine separate from host adapters. OpenClaw and standalone/Hermes adapters provide the runtime-specific pieces.

Storage is abstracted under `src/core/store/`. The local SQLite implementation uses ordinary relational tables, FTS5, and `sqlite-vec`. The Tencent Cloud VectorDB path adds dense/sparse hybrid search, BM25-style sparse encoding, and reciprocal-rank-fusion reranking.

The context offload layer under `src/offload/` writes raw material to JSONL and reference files, builds compact Mermaid summaries, injects active MMD context back into prompts, and avoids splitting tool-call/tool-result pairs. That matters: context compression systems often break agent conversations by clipping structured tool pairs in the middle.

The Gateway in `src/gateway/` exposes HTTP endpoints such as `/recall`, `/capture`, memory search, conversation search, session end, and seed. It supports optional Bearer auth through `server.apiKey` / `TDAI_GATEWAY_API_KEY`, constant-time token comparison, and configurable CORS.

## Strong Parts

- The memory stack is not just vector recall. The L0/L1/L2/L3 model gives the agent raw evidence, compact facts, scenario context, and durable profile-level state.
- The short-term context offload design is practical. Storing heavy logs externally and feeding the model a compact symbolic canvas is a good answer to long-running agent sessions.
- The implementation is host-aware without being fully host-coupled. The core, adapters, plugin entry, Gateway, and Hermes client are separate enough to reason about.
- Retrieval is layered: keyword/FTS, vector search, sparse BM25-style vectors, and fusion are all represented.
- Local-first defaults are real. SQLite and local vector search are the normal path; remote VectorDB and remote embeddings are optional.
- The repo has useful hardening details: sanitized path components, JSONL parsing defenses, retention minimums, gateway auth/CORS controls, diagnostic redaction, and no-tools LLM runners for extraction calls.
- The README and changelog are unusually candid about performance changes, compatibility fixes, and operational setup.

## Caveats

- The benchmark claims are impressive but author-provided. The README reports OpenClaw improvements such as WideSearch success from 33% to 50% with 61.38% fewer tokens, SWE-bench from 58.4% to 64.2% with 33.09% fewer tokens, AA-LCR from 44.0% to 47.5%, and PersonaMem from 48% to 76%. I did not reproduce the benchmark harness locally.
- CI is light for the size of the repo. The visible PR workflow installs dependencies, packs the npm package, validates the plugin manifest, and checks package size. It does not run the package test suite.
- Only four `.test.ts` files are present in the current tree: sanitizer behavior, auth-profile key lookup, no-thinking fetch body rewriting, and time utilities.
- `package.json` has a `postinstall` script: `bash scripts/openclaw-after-tool-call-messages.patch.sh 2>/dev/null || true`. It is convenient, but it means installing the package may silently patch the host if conditions match. Operators should understand that side effect before installing.
- Gateway auth is optional and defaults off for backward compatibility. The code warns loudly when auth is disabled or a non-loopback bind is used, but an exposed gateway without `TDAI_GATEWAY_API_KEY` is still an unsafe deployment.
- The package targets a narrow environment: Node >=22.16.0, OpenClaw >=2026.3.7, optional `node-llama-cpp`, and Hermes/OpenClaw assumptions.
- The repo has a large open-issue count for a young project, which suggests active interest but also a meaningful support backlog.

## Security Notes

The most important secure deployment rule is: keep the Gateway loopback-only or require a strong Bearer token. The implementation has a good constant-time compare path and CORS defaults that emit no CORS headers unless configured, but the default open-auth mode is for compatibility, not internet exposure.

The local storage path is a privacy boundary. L0 raw conversation records, extracted memories, JSONL offload files, references, and profiles may contain sensitive user context. Treat the data directory like a private agent memory vault.

The optional Tencent Cloud VectorDB backend and remote embedding providers can move memory material off-device. That is fine when intentional, but the local SQLite path is the cleaner default for sensitive deployments.

The install-time patch script should be reviewed before broad rollout. It is not necessarily malicious; it is just a high-trust installation behavior.

## Reusable Patterns

- Progressive memory layers: raw history, extracted atoms, scene summaries, and durable profiles should be separate artifacts, not one mixed vector store.
- Symbolic context offload: move bulky traces to references, then inject a compact graph with stable node IDs for drill-down.
- Tool-pair preservation: context compression must treat tool calls and tool results as structural pairs.
- White-box memory storage: keep Markdown/JSONL/SQLite artifacts inspectable by humans and agents.
- Hybrid recall: combine FTS/BM25, embeddings, and rank fusion instead of relying on a single retrieval mode.
- Gateway hardening as configuration: loopback defaults, optional shared-secret auth, CORS allowlists, warnings for unsafe exposure.

## Verification

Static review covered the README, changelog, package metadata, plugin manifest, OpenClaw entry point, core memory facade, storage backends, embedding code, offload pipeline, gateway server/config, tests, scripts, and CI workflow.

I did not run the package tests because dependencies are not installed in the clean clone and there is no lockfile to reproduce an install without adding local dependency state. The visible CI workflow also does not run tests.

## Bottom Line

This is one of the more practically interesting agent-memory repos in the OpenClaw/Hermes space. It is not just a vector database wrapper; it is a full attempt at long-running agent memory plus context-budget management.

I would pilot it for local OpenClaw/Hermes memory work, with three conditions: review the install-time patch script, enable Gateway auth before any non-local exposure, and treat benchmark claims as promising until reproduced in the target environment.
