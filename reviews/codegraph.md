# CodeGraph (colbymchenry/codegraph)

- Repository: https://github.com/colbymchenry/codegraph
- Reviewed: 2026-05-23
- Updated: 2026-07-18
- License: MIT
- Prior commit reviewed: f366222dbd6b7e43047072a9417289b1b02ae457
- Current commit checked: 5955d04
- Latest GitHub release observed: v1.4.1, published 2026-07-10
- Package version observed: 1.4.1
- Stack: TypeScript, bundled Node runtime, node:sqlite/FTS5, tree-sitter WASM, optional Rust/N-API extraction kernel, MCP stdio server, Vitest, standalone installers

## Update Notes

Checked 2026-07-18 against the prior 2026-05-23 review. This is a material update: CodeGraph moved from 0.9.4 to 1.4.1, added self-contained runtime bundles, switched the default MCP surface to a single primary `codegraph_explore` tool, added anonymous telemetry with documented opt-outs, added verified release/provenance language, expanded language/framework coverage, and introduced an optional native extraction kernel for TS/JS, Java, Python, Go, C, and C++.

The verdict stays ✅ Deploy candidate. The main caveats changed: the old Node 25 install/runtime concern is mostly softened for CLI users by bundled Node releases, but the package still declares `node >=20 <25` for source/library/dev use. The production `picomatch` advisory remains open in `npm audit --omit=dev`.

## Verdict

✅ Deploy candidate, with telemetry and dependency caveats.

CodeGraph remains a strong local code-intelligence layer for coding agents. It pre-indexes a repository into a local SQLite/FTS graph, exposes agent-friendly MCP/CLI queries, and now emphasizes one high-signal `codegraph_explore` tool that returns source, call paths, and blast radius in one bounded answer.

The implementation matured substantially since the first review: self-contained install bundles, npm/GitHub provenance, upgrade/uninstall flows, multi-project MCP behavior, broader framework dispatch synthesis, native extraction acceleration, and more explicit telemetry documentation. The remaining caution is not about the architecture; it is operational hygiene: opt out of telemetry where appropriate, patch the production `picomatch` advisory before sensitive deployments, and pin versions when relying on the fast-moving analysis behavior.

## What It Is

CodeGraph is a local semantic code graph for agents. Instead of repeatedly spending tool calls on grep/read exploration, an agent can query a precomputed graph of symbols, files, imports, calls, routes, framework dispatch edges, and surrounding context.

The core shape is still straightforward:

- Parse source files with tree-sitter grammars.
- Store extracted nodes and edges in a local `.codegraph/` SQLite database.
- Add full-text search with SQLite FTS5.
- Resolve references and framework edges after extraction.
- Serve compact query tools through MCP and a CLI.
- Keep the index fresh with native file watchers and debounced sync.

The packaging story changed materially. CodeGraph now ships self-contained platform bundles with a vendored Node runtime and built-in `node:sqlite`, so the CLI can be installed without a local Node version or native SQLite addon build. npm installs act as a shim to the same bundle.

## Notable Capabilities

- Default MCP surface is now `codegraph_explore`: one primary tool for source-backed exploration, flow tracing, and blast-radius context.
- Narrower tools still exist but are unlisted by default: `codegraph_node`, `codegraph_search`, `codegraph_callers`, `codegraph_callees`, `codegraph_impact`, `codegraph_files`, and `codegraph_status`.
- CLI commands cover install, uninstall, upgrade, init, uninit, index, sync, status, query, files, context, callers, callees, impact, affected, telemetry, and MCP serving.
- Standalone installers support macOS/Linux shell and Windows PowerShell with bundled runtime artifacts.
- Agent installer targets include Claude Code, Cursor, Codex CLI, opencode, Hermes Agent, Gemini, Antigravity, and Kiro.
- Language support has expanded to include TypeScript/JavaScript, Python, Go, Rust, Java, C#, PHP, Ruby, C/C++, Swift, Kotlin, Scala, Dart, Svelte, Vue, Astro, Liquid, Pascal/Delphi, Lua/Luau, CFML, COBOL, VB.NET, Erlang, Solidity, Terraform/OpenTofu, Nix, Metal, CUDA, Objective-C, and ArkTS.
- Framework/dynamic-dispatch work now includes React/Next/React Native/Expo bridges, RTK Query, Celery, Spring events, MediatR, Sidekiq, Laravel events, GoFrame routes, Lombok-generated Java members, C/C++ function-pointer dispatch, and more.
- Releases now claim npm provenance and GitHub release attestations.

## Architecture Notes

CodeGraph is still a CLI plus library, but the internals have grown:

1. Discover source files and respect gitignore plus `codegraph.json` include/exclude and extension mappings.
2. Parse with tree-sitter WASM, or an optional Rust/N-API extraction kernel when a prebuilt binary is available.
3. Store nodes and relationships in SQLite using built-in `node:sqlite` and FTS5.
4. Run cross-file reference resolution and framework/dynamic-dispatch synthesis.
5. Expose graph queries through CLI commands and MCP stdio.
6. Keep the index fresh through file watching, incremental sync, and shared background server/daemon behavior.

The most interesting update is product/tool design: defaulting the MCP server to one strong `codegraph_explore` tool. That is a good agent ergonomics move. Agents often mis-pick among many narrow tools; a single "give me relevant source plus flow plus impact" tool better matches how coding agents actually work.

## Verification

This check-in used a fresh clone and upstream metadata.

- GitHub metadata on 2026-07-18: 60,771 stars, 3,807 forks, 91 open issues, latest release v1.4.1.
- Latest commit checked: `5955d04`, pushed 2026-07-18.
- `git diff --stat f366222d..HEAD` shows a major change set: 505 files changed, including the bundling system, telemetry worker, site docs, Rust extraction kernel, MCP daemon/proxy/session code, expanded tests, and many extraction/resolution modules.
- `npm audit --omit=dev --audit-level moderate` still reports one production high vulnerability in `picomatch 4.0.0 - 4.0.3`.
- Full `npm audit --audit-level moderate` reports 8 vulnerabilities across production and dev dependencies.
- Basic secret-pattern scan found no obvious committed credentials; matches were docs, tests, placeholders, or token/security terminology.
- I did not rerun the full test suite locally in this check-in because the current local runtime is Node 25.9.0 and the package still declares `node >=20 <25` for source/library/dev use.

## Risks And Caveats

- Anonymous telemetry is now part of the product. It is documented, constrained, and opt-out via `codegraph telemetry off`, `CODEGRAPH_TELEMETRY=0`, or `DO_NOT_TRACK=1`, but privacy-sensitive teams should set that deliberately before first use.
- The production dependency audit still has a high `picomatch` advisory. Patch before broad deployment in sensitive environments.
- The self-contained CLI reduces Node-version pain, but source/library/dev use still declares Node >=20 <25. Treat Node 25 as unsupported unless the project removes that gate.
- Release docs are stronger, but code signing is still called out as a gap in bundling notes for direct download trust on macOS/Windows.
- `.codegraph/` is derived local metadata. Do not publish private indexes accidentally.
- The project is moving fast. Re-index after upgrades and pin versions if relying on specific graph semantics.

## Comparison

Compared with plain ripgrep, CodeGraph has higher upfront cost but gives agents graph-aware answers instead of repeated text search. That matters when the same codebase is queried repeatedly.

Compared with LSP/LSIF-style tooling, CodeGraph is more agent-oriented: it emphasizes compact context, impact queries, and MCP tools rather than editor diagnostics.

Compared with GitNexus, CodeGraph is smaller, MIT-licensed, and more deployable as a permissive local sidecar. GitNexus is broader and more ambitious in graph/process tooling, but its PolyForm Noncommercial license changes reuse.

## Best Use

Use CodeGraph when an agent will repeatedly inspect a medium-to-large codebase and needs cheap local answers about symbols, files, callers, callees, framework flows, routes, and likely impact.

The best pilot remains one non-sensitive repository with a known architecture question set. Install, run `codegraph init`, ask the same questions with and without CodeGraph, and check whether `codegraph_explore` actually prevents follow-up file reads.

