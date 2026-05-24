# CodeGraph (colbymchenry/codegraph)

- Repository: https://github.com/colbymchenry/codegraph
- Reviewed: 2026-05-23
- License: MIT
- Current commit reviewed: f366222dbd6b7e43047072a9417289b1b02ae457
- Latest GitHub release observed: v0.9.3, published 2026-05-22
- Package version observed: 0.9.4
- Stack: TypeScript, Node.js 20-24, tree-sitter WASM grammars, SQLite/FTS5, MCP stdio server, Vitest, npm CLI

## Verdict

✅ Deploy candidate, with dependency and runtime caveats.

CodeGraph is a strong local code-intelligence layer for coding agents. It pre-indexes a repository into a local SQLite graph, exposes MCP tools for search/context/callers/callees/impact analysis, and ships with broad language/framework extraction plus a practical installer for Claude Code, Codex, Cursor, OpenCode, and Hermes Agent.

The implementation is more credible than the marketing pitch alone: tests are broad, the CLI has real indexing/query/watch paths, and the MCP surface is shaped around agent workflows rather than IDE-only diagnostics. The main caveats are operational: stay on Node 20/22/24, avoid Node 25 for now, and update the production dependency chain for the high picomatch advisory before treating it as hardened.

## What It Is

CodeGraph is a local semantic code graph for agents. Instead of repeatedly spending tool calls on grep/read exploration, an agent can query a precomputed graph of symbols, files, imports, calls, routes, and surrounding context.

The core idea is straightforward and useful:

- Parse source files with tree-sitter grammars.
- Store extracted nodes and edges in a local SQLite database under .codegraph/.
- Add full-text search with SQLite FTS5.
- Resolve references after extraction so calls/imports/routes become graph edges.
- Serve compact query tools through MCP and a CLI.
- Keep the index fresh with native file watchers and debounce logic.

## Notable Capabilities

- MCP tools: codegraph_search, codegraph_context, codegraph_callers, codegraph_callees, codegraph_impact, codegraph_node, codegraph_explore, codegraph_files, and codegraph_status.
- CLI commands: install, uninstall, init, uninit, index, sync, status, query, files, context, callers, callees, impact, affected, and serve --mcp.
- Language coverage includes TypeScript, JavaScript, Python, Go, Rust, Java, C#, PHP, Ruby, C/C++, Swift, Kotlin, Scala, Dart, Svelte, Vue, Liquid, Pascal/Delphi, Lua, and Luau.
- Framework route extraction covers common Python, Node, PHP, Ruby, Java, Go, Rust, .NET, Swift, and frontend routing patterns.
- Installer support covers several agent hosts and writes reversible MCP configuration.
- Auto-sync respects gitignore and source-file filtering.
- codegraph affected can map file changes to likely relevant tests.

## Architecture Notes

The project is structured as a CLI plus library. The CodeGraph path is roughly:

1. Discover source files and respect ignore rules.
2. Parse files with language-specific tree-sitter extractors.
3. Store nodes and raw relationships in SQLite.
4. Run reference resolution for calls, imports, inheritance, and routes.
5. Expose graph queries through CLI commands and an MCP stdio server.
6. Format context for agent consumption.

This is the right shape for agent tooling because it separates expensive repository indexing from cheap repeated lookups. It also avoids shipping source code to a remote service, which matters for private repositories.

## Verification

Verification was run locally from a fresh clone.

- npm ci completed, but Node 25 emitted an engine warning because the package declares Node >=20 <25.
- npm test under Node 25 reproduced the repository's documented unsupported-runtime problem: many tests passed, but the run failed with tree-sitter/V8 WASM instability and related MCP test failures.
- npm run build under Node 25 completed.
- Re-running tests under Node 22.22.2 passed: 35 test files, 776 tests passed, 2 skipped.
- npm pack --dry-run under Node 22 succeeded and included built dist files plus WASM grammars: 407 files, 1.2 MB package, 8.1 MB unpacked.
- node dist/bin/codegraph.js --version returned 0.9.4.
- npm audit --omit=dev --audit-level moderate reported one production high vulnerability in picomatch 4.0.0-4.0.3.
- Full npm audit reported 8 vulnerabilities total: 6 moderate, 2 high, mostly dev/build chain plus picomatch.
- A basic secret scan found no obvious committed secrets.

## Risks And Caveats

- Node 25 is explicitly unsafe for this package today. The package blocks it by default because of a V8/tree-sitter WASM failure mode. Use Node 20, 22, or 24.
- The production dependency audit currently has a high picomatch advisory. This should be updated before broad deployment in sensitive environments.
- The README's token/tool-call savings are plausible for this category, but should be treated as project-published benchmark claims until independently reproduced on representative repositories.
- The .codegraph/ directory is a local derived index. Teams should decide whether to ignore, retain, or regenerate it and avoid accidentally publishing private code-derived graph artifacts.
- Broad language coverage is valuable, but extractor quality will vary by language and framework. Test on the target stack before relying on impact analysis.

## Comparison

Compared with plain ripgrep, CodeGraph has higher upfront cost but gives agents graph-aware answers instead of repeated text search. That matters when the same codebase is queried repeatedly.

Compared with LSP/LSIF-style tooling, CodeGraph is more agent-oriented: it emphasizes compact context, impact queries, and MCP tools rather than editor diagnostics.

Compared with Understand Anything, CodeGraph is narrower and more operationally direct. Understand Anything is closer to a dashboard/knowledge-graph workbench; CodeGraph is a local CLI/MCP index for code agents.

## Best Use

Use CodeGraph when an agent will repeatedly inspect a medium-to-large codebase and needs cheap local answers about symbols, files, callers, callees, routes, and likely impact.

I would start with Node 22, install it into one non-sensitive repository, run a full index, and compare agent behavior against a baseline session using normal file search. If the graph answers are accurate on that codebase, it is worth adding to the agent tool stack.

