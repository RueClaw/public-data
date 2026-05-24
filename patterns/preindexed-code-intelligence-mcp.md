# Pattern: Pre-Indexed Code Intelligence MCP

## Summary

A useful coding-agent pattern is to keep a local, pre-indexed code graph beside the repository and expose it through small MCP tools. The agent spends fewer repeated tool calls on raw file search, while the indexer handles expensive parsing and relationship extraction ahead of time.

## Core Shape

1. Parse source files with structured language parsers rather than regular expressions.
2. Extract symbols, imports, calls, routes, classes, functions, and file-level metadata.
3. Store the graph locally in a queryable database.
4. Add full-text search for fuzzy discovery.
5. Resolve cross-file references after extraction.
6. Expose focused MCP tools for search, context, callers, callees, impact, file listing, and status.
7. Keep the index fresh with an incremental watcher.
8. Enforce path, file-size, and input-size limits.

## Why It Works

Agents are often inefficient at codebase exploration. They repeatedly search for the same symbols, read nearby files, and reconstruct dependency relationships from text. A pre-indexed graph turns that repeated exploration into a cheap local lookup.

The pattern is especially valuable when:

- Multiple agents work on the same repository.
- The repository is large enough that repeated grep/read loops are expensive.
- The task needs impact analysis, caller/callee traversal, route discovery, or test selection.
- Private code should stay local.

## MCP Tool Design

Keep the tool surface small and purpose-built:

- Search: find symbols, files, and text matches.
- Context: return the local code context around a symbol or file.
- Callers/callees: traverse graph relationships.
- Impact: show likely affected files or tests.
- Node lookup: fetch one graph object by identifier.
- Explore: batch a bounded codebase reconnaissance query.
- Files/status: let the agent understand index coverage and freshness.

The best tools return compact, ranked, source-grounded results. They should not dump the whole graph into context.

## Storage Notes

A local embedded database is usually enough. SQLite with full-text search is a strong default because it is portable, inspectable, and does not require a service. The index should be treated as derived data: easy to delete, rebuild, and exclude from public commits when it contains private code-derived metadata.

## Safety Checklist

- Respect gitignore and explicit ignore rules.
- Cap file sizes and result sizes.
- Block traversal outside the repository root.
- Validate MCP inputs and reject oversized requests.
- Use file locks or equivalent coordination during writes.
- Make concurrent reads safe.
- Provide a clear status command so agents know whether the index is fresh.
- Document supported runtimes and parser failure modes.

## Good Fit

- Coding agents that repeatedly inspect the same repositories.
- Local-first developer tools.
- Large monorepos where text search alone causes context churn.
- CI helpers that need changed-file or likely-test mapping.

## Poor Fit

- One-off inspection of a tiny repository.
- Repositories dominated by unsupported languages.
- Teams that cannot tolerate local derived indexes.
- Security-sensitive deployments where dependencies are not regularly patched.

## Implementation Guidance

Start narrow. Support a few high-value languages and query types well before claiming universal coverage. Add framework-specific route and dependency extractors only where they materially improve real agent workflows. Keep the MCP server boring: deterministic local lookups, clear errors, bounded output, and no network dependency.

