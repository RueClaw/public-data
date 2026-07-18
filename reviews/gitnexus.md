# GitNexus (abhigyanpatwari/GitNexus)

**Repo:** https://github.com/abhigyanpatwari/GitNexus
**License:** PolyForm Noncommercial 1.0.0; free for noncommercial use, not open source for commercial reuse without separate permission
**Reviewed:** 2026-07-18
**Stack:** TypeScript, Node.js, MCP, LadybugDB, Tree-sitter, React/Vite, Sigma.js, LangChain
**What it is:** Local-first code intelligence for AI coding agents. It indexes repositories into a code knowledge graph, exposes graph-aware MCP/CLI tools, and ships a browser graph explorer with chat.

---

## Verdict

✅ **Deploy candidate for noncommercial/local evaluation.** GitNexus is one of the more serious code-graph sidecars for coding agents: large test surface, active maintenance, local-first CLI/MCP path, browser bridge, and a thoughtful model of precomputed relationship tools rather than raw graph dumping. The license is the main limiter: PolyForm Noncommercial makes it suitable for personal, research, and evaluation use, but not commercial adoption without a separate license.

---

## What It Is

GitNexus targets the recurring weakness in AI coding agents: they can search files, but they often miss dependency chains, indirect callers, route consumers, response-shape contracts, or cross-file implications. The CLI runs `gitnexus analyze`, builds a graph-backed index, and then exposes compact tools such as `context`, `impact`, `trace`, `route_map`, `shape_check`, and `detect_changes` through MCP.

It has two usage modes. The recommended path is local CLI plus MCP, where the index lives on the developer machine and agents query it during coding sessions. The web UI is a React/Vite graph explorer that can either run browser-side for quick demos or connect to `gitnexus serve` for larger local indexes.

The project is moving quickly and is already large: a TypeScript monorepo, vendored tree-sitter grammars, a LadybugDB persistence layer, a worker-based parse pipeline, a web UI, agent skills, hooks for multiple coding harnesses, and an evaluation harness. That breadth is useful, but it also means this should be adopted as infrastructure, not casually dropped into every environment.

## Stack

| Layer | Tech |
|-------|------|
| CLI / MCP | Node.js 22+, TypeScript, Commander, Model Context Protocol SDK |
| Graph storage | LadybugDB native/WASM, single relation table with typed edges |
| Parsing | Tree-sitter native bindings and WASM grammars |
| Search | BM25, optional embeddings, Reciprocal Rank Fusion |
| Web UI | React 19, Vite, Tailwind, Sigma.js, graphology, D3, Mermaid |
| AI chat | LangChain provider adapters for OpenAI, Anthropic, Google, Ollama |
| Testing / CI | Vitest, Playwright, CodeQL, Gitleaks, Trivy, OpenSSF Scorecard, dependency review |

## Key Features

### Agent-Oriented MCP Tools

GitNexus does not just expose a generic search box. Its tools map directly to coding-agent questions: what depends on this symbol, what route handles this API, what clients consume this response shape, what changed in this diff, and what path connects two symbols. This is the right abstraction level for reducing blind edits.

### Precomputed Pipeline

The ingestion pipeline is explicit and dependency-ordered: scan, structure, markdown/COBOL handling, parse, routes, tools, ORM, cross-file resolution, scope resolution, pruning, MRO, dependency injection, communities, and processes. That design gives the query layer a richer substrate than plain embeddings or grep.

### Multi-Language Static Analysis

The repo carries resolver tests and fixtures for many languages, including TypeScript/JavaScript, Python, Ruby, Go, Java, C#, C/C++, Rust, PHP, Vue, Kotlin, Dart, Swift, and COBOL. That does not mean every language is equally deep, but the project is clearly investing in broad parser coverage instead of one-framework demos.

### Local-First With Web Bridge

The CLI/MCP path keeps repository data local. The web UI can operate as a visual client over a local `gitnexus serve` backend, which is a good split: graph visualization where it helps, MCP tools where agents need compact answers.

### Security Posture

The repo has visible hardening work: path traversal guards, type-confusion validation, route rate limiting, private-IP checks, same-host/origin controls in the server layer, read-only MCP mode, gitleaks configuration, CodeQL, Trivy, dependency review, OpenSSF Scorecard, and security documentation. A quick secret-pattern scan found no obvious committed credentials; the matches were documentation, config placeholders, or test strings.

## Architecture

The architecture is a monorepo with three main packages:

- `gitnexus/` contains the npm CLI, MCP server, HTTP API, ingestion pipeline, storage, search, and agent integration code.
- `gitnexus-web/` contains the React graph explorer and chat UI.
- `gitnexus-shared/` contains shared TypeScript schemas and language/scope-resolution types.

The strongest design choice is the phase-based indexer. Each phase declares dependencies and returns typed output, while the graph accumulator is shared through the run. The resulting graph powers three interfaces: direct CLI commands, MCP stdio tools, and an HTTP bridge for the web UI.

The second strong choice is response shaping. MCP responses are designed around bounded, agent-readable context: pagination for repository and taint results, maximum token controls, compact process grouping, and a read-only mode that removes mutation/raw-Cypher/group-routing surfaces.

## Comparison

| Aspect | GitNexus | CodeGraph | Codesherpa |
|--------|----------|-----------|------------|
| Primary target | Full code intelligence sidecar for agents plus graph UI | Local code graph/MCP server | Local structural memory and retrieval |
| Storage | LadybugDB graph | SQLite/FTS5 | SQLite/FTS5/sqlite-vec |
| Agent surface | Broad MCP tools, hooks, skills, setup | MCP tools and installer | Compact MCP retrieval tools |
| Visualization | React graph explorer | Primarily agent/tooling oriented | Primarily agent/tooling oriented |
| License | PolyForm Noncommercial | MIT | Apache-2.0 |
| Best fit | Noncommercial evaluation of rich graph-aware coding workflows | Open-source deployable MCP graph sidecar | Local agent memory/retrieval experiments |

GitNexus is richer than CodeGraph and Codesherpa in graph/process tooling and UI, but its source-available noncommercial license changes the adoption calculus. For commercial or permissive reuse, the lighter tools may be easier to integrate. For studying what a serious agent context engine can look like, GitNexus is currently more ambitious.

## Self-Hosting Notes

The CLI path is straightforward:

```bash
npx gitnexus analyze
npx gitnexus setup
```

The README calls out real install caveats: npm 11/arborist crashes, native tree-sitter grammar builds, optional embedding runtime downloads, Node version constraints, and cold `npx` startup time. For repeat use, install globally and connect MCP by absolute path rather than relying on cold `npx` startup inside an agent session.

Treat `gitnexus serve` as a local developer service. If binding beyond loopback, require authentication and network controls. The project has server hardening, but repository source indexes and graph-derived metadata can still contain sensitive code structure.

---

**Attribution:** abhigyanpatwari/GitNexus, PolyForm Noncommercial 1.0.0
