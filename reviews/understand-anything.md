# Understand Anything (Egonex-AI/Understand-Anything)

**Repo:** https://github.com/Egonex-AI/Understand-Anything
**License:** MIT; permissive reuse with attribution
**Reviewed:** 2026-06-20
**Stack:** TypeScript, pnpm workspaces, Claude Code/plugins/skills, React 19, Vite, Tailwind CSS, XYFlow/React Flow, tree-sitter/web-tree-sitter, Dart/Kotlin extractors, graphology/Louvain, Fuse.js, Zod
**What it is:** Multi-platform AI coding assistant plugin that analyzes a codebase or knowledge base, builds a persistent knowledge graph, and serves an interactive dashboard for search, exploration, onboarding, diff impact, and component explanation.

---

## Update Notes

**Checked:** 2026-06-20
**Prior review:** 2026-05-23, current ref `35699dd82bdaa29f56c9e09aa2878a7254d1a512`, package version 2.7.4
**Current ref:** `7f5a717694d3a94f19f523b375c777eb21548ff5`, package version 2.8.1

Material changes since the prior review:

- The project has moved from `Lum1104/Understand-Anything` to `Egonex-AI/Understand-Anything`, while still crediting Lum1104 as the original creator.
- The analysis pipeline now front-loads deterministic scripts for project scanning, import-map extraction, ignore generation, and semantic batching before LLM analysis.
- Large graph generation is less brittle: batches can be split into parts, output filenames are specified more strictly, and agents receive cross-batch neighbor context.
- Language coverage expanded with Dart and Kotlin configs/extractors, plus a bundled tree-sitter Dart WASM package.
- The README now documents language auto-detection/persisted output language, incremental re-runs, subdirectory analysis, local model options, and token-usage expectations.
- Platform docs expanded across Claude Code, Codex, Cursor, Copilot, Gemini CLI, OpenCode, Antigravity, Trae, Nanobot, Kiro, and related coding-agent environments.
- Project governance is stronger: SECURITY.md, issue templates, PR template, code of conduct, and push/PR CI are now present.
- Local verification passed install and tests, but dependency audit now reports 31 advisories, including critical Vitest and several high-severity Vite/picomatch issues.

---

## Verdict

✅ **Deploy candidate, with dependency hygiene caveats.** Understand Anything remains one of the more useful agent-oriented codebase mapping projects: it creates a durable graph artifact instead of only producing one-off summaries, and the newer deterministic scan/batch/import-map pipeline is a meaningful improvement. The main cautions are dependency audit exposure, curl-pipe install ergonomics, operational token cost, and the risk that users over-trust stale or partially generated graphs.

---

## What It Is

Understand Anything turns a repository into a structured knowledge graph. The `/understand` workflow scans project files, extracts functions/classes/imports/config/docs/infrastructure structure, runs specialized analysis agents, writes `.understand-anything/knowledge-graph.json`, and then powers commands for dashboard exploration, natural-language chat, diff impact analysis, deep file/function explanations, onboarding guides, business-domain extraction, and knowledge-base graphing.

The tool is built for the codebase-onboarding problem: a new developer or agent enters a large project and needs an architectural map before making changes. Rather than only summarizing files, it persists nodes, edges, layers, and guided tour steps so later commands can query the same graph.

The repo also includes a React dashboard. It can display structural graphs, domain graphs, diff overlays, file content previews, fuzzy/semantic search results, filtered layers, tours, and localized UI labels.

## Stack

| Layer | Tech |
|-------|------|
| Plugin/skills | Claude Code plugin format, multi-platform symlink installers |
| Core analysis | TypeScript, pnpm workspaces, tree-sitter, web-tree-sitter, Zod |
| Scan/batch pipeline | Node scripts for project scans, import maps, ignore generation, semantic batching, and graph merging |
| Search/layout | Fuse.js, embedding-search utilities, graphology, Louvain clustering |
| Dashboard | React 19, Vite, Tailwind CSS, @xyflow/react, ELK/Dagre/d3-force |
| Knowledge-base support | Python scripts for deterministic wiki parsing and graph merge |
| Tests | Vitest |
| Install | Plugin marketplace plus shell/PowerShell installer |

## Key Features

### Multi-Agent Analysis Pipeline

The main workflow uses specialized agent definitions:

- `project-scanner` discovers files, languages, frameworks, file categories, and import maps.
- `file-analyzer` extracts code and non-code structure into graph nodes and edges.
- `architecture-analyzer` groups components into layers.
- `tour-builder` builds a guided learning path.
- `graph-reviewer` validates graph completeness and referential integrity.
- `domain-analyzer` and `article-analyzer` extend the graph into business-process and knowledge-base analysis.

### Deterministic Extractors Before LLM Judgment

The newer architecture leans harder on deterministic extraction before asking LLM agents to summarize. The core package includes tree-sitter extractors for TypeScript/JavaScript, Python, Go, Rust, Java, Ruby, PHP, C/C++, C#, Dart, and Kotlin, plus parsers for JSON, YAML, Dockerfile, Terraform, SQL, Markdown, Protobuf, GraphQL, shell, Makefiles, and related config formats.

This is the right direction: LLMs should explain and connect structure, not be the only source of structural truth.

### Semantic Batching for Large Repositories

The 2.8.x line adds a more explicit scan-and-batch pipeline. Deterministic scripts produce project inventories and import maps, then semantic batching groups files before agent analysis. Large batches can be split into parts, and neighbor maps give each batch limited cross-batch context.

That matters because the previous model was easier to overwhelm on large repos. The current shape is closer to a production-grade indexing pipeline: scan first, partition deliberately, enrich with models, then merge and validate.

### Persistent Graph as Shared Artifact

The README encourages committing `.understand-anything/knowledge-graph.json` so teammates can skip the analysis pipeline. That makes the graph useful for onboarding, review, documentation, and agent workflows, but teams should use Git LFS for large graphs and exclude intermediate/diff scratch files.

### Dashboard With Local Data Controls

The dashboard serves graph data from a local Vite server. Current code binds to localhost, prints a tokenized URL, requires that token for graph/file endpoints, sanitizes absolute paths, prevents path traversal, limits file previews, blocks binary previews, and only serves file content for paths present in the graph.

### Diff and Explanation Commands

The `/understand-diff` command maps changed files to graph nodes and neighbors, then reports affected components, layers, relationships, and risk. `/understand-explain` builds a focused context for a file or function, including child nodes, connected nodes, relationships, layer membership, and language notes.

## Architecture

Understand Anything is organized as a monorepo:

| Area | Role |
|------|------|
| `understand-anything-plugin/skills/` | User-facing slash-command skill definitions |
| `understand-anything-plugin/agents/` | Specialized analyzer/reviewer/tour/domain agents |
| `understand-anything-plugin/scripts/` | Scan, import-map, ignore, batch, merge, and install helpers |
| `understand-anything-plugin/packages/core/` | Graph schema, extractors, parsers, registry, search, persistence, tests |
| `understand-anything-plugin/packages/dashboard/` | React graph dashboard and Vite data server |
| `understand-anything-plugin/src/` | Command helper libraries for diff, explain, onboard, chat, context |
| `homepage/` | Astro marketing/demo site |
| `.claude-plugin`, `.cursor-plugin`, `.copilot-plugin` | Platform plugin metadata |

The core design is sound: a durable typed graph model sits between analysis and UI. Commands do not need to re-understand the whole repo each time; they can query the graph and then ask the model for focused interpretation.

## Verification

Local checks on 2026-06-20:

- `pnpm install --frozen-lockfile` passed.
- `pnpm test` passed: 16 test files, 207 tests.
- `pnpm audit --audit-level moderate` failed with 31 vulnerabilities: 2 low, 14 moderate, 13 high, and 2 critical.

Notable audit findings include critical Vitest advisories, high-severity picomatch ReDoS, high-severity Vite dev-server file-serving/WebSocket issues, PostCSS XSS, brace-expansion DoS, js-yaml DoS, Astro XSS, and Vite launch-editor NTLM hash disclosure.

## Security Notes

The project now includes a SECURITY.md with a sensible scope statement: static local analysis only, token-gated dashboard endpoints, graph-derived path allow-listing, and a responsible disclosure path.

The audit findings still matter. The Vite advisories include dev-server arbitrary file read/path traversal classes, and this project intentionally runs a local dashboard that serves project graph/file content. Even with the custom token gate, users should update dependencies before treating it as a hardened local introspection surface.

The install script supports curl-pipe installation. That is convenient, but security-conscious users should inspect the script or pin a commit before running it.

## Comparison

| Aspect | Understand Anything | Static docs | Generic repo summarizer |
|--------|---------------------|-------------|--------------------------|
| Output | Typed graph, dashboard, commands | Markdown pages | One-off prose |
| Freshness | Manual or incremental analysis | Often stale | Usually ephemeral |
| Structure | Nodes, edges, layers, tours | Human-authored hierarchy | Model-chosen summary |
| Interaction | Search, click, explain, diff | Read-only | Ask again from scratch |
| Risk | Local graph quality, dependency hygiene | Staleness | Hallucinated structure |

## Self-Hosting Notes

Install paths vary by platform. Claude Code can use the plugin marketplace:

    /plugin marketplace add Egonex-AI/Understand-Anything
    /plugin install understand-anything

Other platforms can use the shell/PowerShell installer, but users should prefer pinned commits in sensitive environments:

    git clone https://github.com/Egonex-AI/Understand-Anything.git
    cd Understand-Anything
    ./install.sh codex

The graph output lives in `.understand-anything/`. Commit `knowledge-graph.json` only when team sharing is desired; keep intermediate files and diff overlays local unless the team has an explicit generated-artifact policy.

---

**Attribution:** Egonex-AI/Understand-Anything, originally created by Lum1104, MIT
