# Understand Anything (Lum1104/Understand-Anything)

**Repo:** https://github.com/Lum1104/Understand-Anything
**License:** MIT; permissive reuse with attribution
**Reviewed:** 2026-05-23
**Stack:** TypeScript, pnpm workspaces, Claude Code plugins/skills, React 19, Vite, Tailwind CSS, XYFlow/React Flow, tree-sitter, Fuse.js, Zod
**What it is:** Multi-platform AI coding assistant plugin that analyzes a codebase or knowledge base, builds a persistent knowledge graph, and serves an interactive dashboard for search, exploration, onboarding, diff impact, and component explanation.

---

## Update Notes

**Checked:** 2026-05-23  
**Prior review:** 2026-03-24, no commit recorded  
**Current ref:** 35699dd82bdaa29f56c9e09aa2878a7254d1a512, package version 2.7.4

Material changes since the prior review:

- Broader platform support across Claude Code, Cursor, VS Code/Copilot, Copilot CLI, Codex, OpenCode, Antigravity, Gemini CLI, Pi Agent, Vibe CLI, Hermes, Cline, KIMI, and related coding-agent environments.
- Expanded graph scope beyond code: business-domain graphs and Karpathy-pattern knowledge-base graphs.
- Added deterministic parsers/extractors for many languages and non-code formats, plus an explicit plugin registry.
- Hardened dashboard serving with localhost binding, token-gated graph/file endpoints, path normalization, file allow-listing from the graph, and absolute-path sanitization.
- Test posture is now substantial: verified locally with 46 test files and 775 passing tests for the skill workspace.
- Dependency audit still reports high/moderate advisories in dev/homepage/dashboard transitive packages, mostly Vite/Vitest, picomatch, Astro/devalue/smol-toml, PostCSS, and brace-expansion.

---

## Verdict

✅ **Deploy candidate, with dependency hygiene caveats.** Understand Anything has grown from a promising Claude Code graph plugin into a real multi-platform codebase-understanding system with deterministic extraction, LLM-assisted summarization, impact analysis, dashboard exploration, and meaningful tests. The main cautions are operational cost on large repositories, graph quality dependence on agent output, and current audit findings in transitive dev/homepage/dashboard dependencies.

---

## What It Is

Understand Anything turns a repository into a structured knowledge graph. The /understand workflow scans project files, extracts functions/classes/imports/config/docs/infrastructure structure, runs specialized analysis agents, writes .understand-anything/knowledge-graph.json, and then powers commands for dashboard exploration, natural-language chat, diff impact analysis, deep file/function explanations, onboarding guides, business-domain extraction, and knowledge-base graphing.

The tool is built for the common codebase-onboarding problem: a new developer or agent enters a large project and needs an architectural map before making changes. Rather than only summarizing files, it persists nodes, edges, layers, and guided tour steps so later commands can query the same graph.

The repo also includes a React dashboard. It can display structural graphs, domain graphs, diff overlays, file content previews, fuzzy/semantic search results, filtered layers, tours, and localized UI labels.

## Stack

| Layer | Tech |
|-------|------|
| Plugin/skills | Claude Code plugin format, multi-platform symlink installers |
| Core analysis | TypeScript, pnpm workspaces, tree-sitter, web-tree-sitter, Zod |
| Search | Fuse.js, embedding-search utilities |
| Dashboard | React 19, Vite, Tailwind CSS, @xyflow/react, ELK/Dagre/d3-force, graphology |
| Knowledge-base support | Python scripts for deterministic wiki parsing and graph merge |
| Tests | Vitest |
| Install | Plugin marketplace plus shell/PowerShell installer |

## Key Features

### Multi-Agent Analysis Pipeline

The main workflow uses specialized agent definitions:

- project-scanner discovers files, languages, frameworks, file categories, and import maps.
- file-analyzer extracts code and non-code structure into graph nodes and edges.
- architecture-analyzer groups components into layers.
- tour-builder builds a guided learning path.
- graph-reviewer validates graph completeness and referential integrity.
- domain-analyzer and article-analyzer extend the graph into business-process and knowledge-base analysis.

### Deterministic Extractors Before LLM Judgment

The newer architecture leans on deterministic extraction before asking LLM agents to summarize. The core package includes tree-sitter extractors for TypeScript/JavaScript, Python, Go, Rust, Java, Ruby, PHP, C/C++, and C#, plus parsers for JSON, YAML, Dockerfile, Terraform, SQL, Markdown, Protobuf, GraphQL, shell, Makefiles, and related config formats.

This is the right direction: LLMs should explain and connect structure, not be the only source of structural truth.

### Persistent Graph as Shared Artifact

The README encourages committing .understand-anything/knowledge-graph.json so teammates can skip the analysis pipeline. That makes the graph useful for onboarding, review, documentation, and agent workflows, but teams should use Git LFS for large graphs and exclude intermediate/diff scratch files.

### Dashboard With Local Data Controls

The dashboard serves graph data from a local Vite server. Current code binds to 127.0.0.1, prints a one-time tokenized URL, requires that token for graph/file endpoints, sanitizes absolute paths, prevents path traversal, limits file previews to 1 MB, blocks binary previews, and only serves file content for paths present in the graph.

### Diff and Explanation Commands

The /understand-diff command maps changed files to graph nodes and 1-hop neighbors, then reports affected components, layers, relationships, and risk. /understand-explain builds a focused context for a file or function, including child nodes, connected nodes, relationships, layer membership, and language notes.

## Architecture

Understand Anything is organized as a monorepo:

| Area | Role |
|------|------|
| understand-anything-plugin/skills/ | User-facing slash-command skill definitions |
| understand-anything-plugin/agents/ | Specialized analyzer/reviewer/tour/domain agents |
| understand-anything-plugin/packages/core/ | Graph schema, extractors, parsers, registry, search, persistence, tests |
| understand-anything-plugin/packages/dashboard/ | React graph dashboard and Vite data server |
| understand-anything-plugin/src/ | Command helper libraries for diff, explain, onboard, chat, context |
| homepage/ | Astro marketing/demo site |
| .claude-plugin, .cursor-plugin, .copilot-plugin | Platform plugin metadata |

The core design is sound: a durable typed graph model sits between analysis and UI. Commands do not need to re-understand the whole repo each time; they can query the graph and then ask the model for focused interpretation.

## Verification

Local checks on 2026-05-23:

- pnpm install --frozen-lockfile passed.
- pnpm lint passed.
- pnpm --filter @understand-anything/core test passed: 33 files, 670 tests.
- pnpm --filter @understand-anything/skill build && pnpm --filter @understand-anything/skill test passed: 46 files, 775 tests.
- pnpm audit --audit-level moderate failed with 14 vulnerabilities: 7 high and 7 moderate, mostly in Vite/Vitest/dev tooling and homepage transitive dependencies.

## Security Notes

The dashboard code shows good local-server hygiene for an agent tool: localhost binding, token-gated endpoints, path traversal checks, graph-based file allow-listing, binary rejection, and file-size limits.

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

    /plugin marketplace add Lum1104/Understand-Anything
    /plugin install understand-anything

Other platforms can use the shell/PowerShell installer, but users should prefer pinned commits in sensitive environments:

    git clone https://github.com/Lum1104/Understand-Anything.git
    cd Understand-Anything
    ./install.sh codex

The graph output lives in .understand-anything/. Commit knowledge-graph.json only when team sharing is desired; keep intermediate/ and diff-overlay.json local.

---

**Attribution:** Lum1104/Understand-Anything, MIT
