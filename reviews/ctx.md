# ctx (stevesolun/ctx)

**Repo:** https://github.com/stevesolun/ctx
**License:** MIT; reusable with attribution.
**Reviewed:** 2026-05-17
**Stack:** Python 3.11+, NetworkX, NumPy, Markdown/MkDocs, Claude Code hooks, MCP server, generic LiteLLM harness, GitHub Actions, Git LFS graph artifacts
**What it is:** ctx is a graph-backed recommendation system for AI coding contexts. It scans the current repo, walks a large shipped knowledge graph of skills, agents, MCP servers, and harnesses, then recommends a capped execution bundle for the current work.

---

## Verdict

📚 **Study and selectively harvest; validate before adopting wholesale.** ctx attacks the right problem: with tens of thousands of skills and tools, the hard part is not having more context, it is loading the right small set at the right time. The project has serious engineering signals: packaged CLIs, docs, CI, clean-host contracts, graph artifact validation, and many tests in-repo. The practical risk is weight and complexity: the shipped graph/wiki artifacts are huge, Git LFS is required, and the recommendation stack has many moving parts.

---

## What It Is

ctx is a context selection and recommendation layer for Claude Code and custom LLM harnesses. It maintains a large LLM-wiki and knowledge graph containing skills, agents, MCP servers, and harness records. At runtime it scans a repository, detects stack and task signals, scores relevant graph entities, and recommends a small bundle instead of loading everything.

The current README claims a shipped snapshot of 102,717 graph nodes, 2.9M edges, 91,448 skills, 467 agents, 10,787 MCP servers, and 15 harnesses. The repo also ships dashboard docs, local monitor flows, quality scoring, lifecycle hooks, toolbox/council runs, graph artifact validation, and clean-host install contracts.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python >=3.11 |
| Graph | NetworkX, NumPy, optional sentence-transformers/torch/hnswlib |
| Knowledge base | Markdown entity pages, graph/wiki tarballs, Skills.sh catalog |
| Claude integration | PostToolUse/Stop hooks, skill/agent/MCP load/unload/install commands |
| Generic harness | LiteLLM optional dependency, ctx run/resume/sessions CLI |
| Dashboard | stdlib HTTP server, MkDocs-compatible Markdown rendering, Cytoscape/Plotly graph views |
| Packaging | setuptools, PyPI package claude-ctx, console scripts |
| CI | GitHub Actions tests, docs, publish, clean-host contract |

## Key Features

### Graph-Backed Context Bundle Selection

The core idea is to treat skills, agents, MCP servers, and harnesses as graph entities rather than flat files. Recommendations combine stack signals, tags, slug tokens, semantic similarity, quality, usage, and graph structure to produce a capped bundle.

### Repo Scanner and Resolver

scan_repo.py detects languages, frameworks, infrastructure, docs, testing, AI tooling, and package/build systems from file and config evidence. resolve_skills.py maps the stack profile into load/unload recommendations and can augment with graph traversal.

### Runtime Dashboard

ctx-monitor serve exposes loaded skills, agents, MCP servers, harness records, wiki pages, graph views, skill quality, session timelines, audit/runtime logs, and live events. That is useful for making context selection observable instead of invisible prompt plumbing.

### Harness Catalog for Non-Claude-Code Models

ctx separates Claude Code helper recommendations from custom/API/local model harness recommendations. Harness installation is deliberately conservative: dry-run first, update/uninstall controls, and setup/verify commands do not run unless explicitly approved.

### Quality and Safety Gates

The repo includes skill quality scoring, health checks, dedup checks, source registry tooling, graph artifact validation, clean-host install contracts, and toolbox guardrails that can block pre-commit on high/critical findings.

## Security and Maturity Notes

- Public repo metadata at review time: 341 stars, 44 forks, pushed 2026-05-15.
- License: MIT.
- Package version in pyproject.toml: claude-ctx 1.0.8.
- README and docs claim 3,823 collected tests and CI coverage across Ubuntu, Windows, and macOS for Python 3.11/3.12.
- GitHub Actions include test, docs, publish, xdist experiment, and clean-host contract workflows.
- Quick secret scan found redaction test fixtures and documentation examples, not obvious live credentials.
- The largest operational concern is artifact weight: full graph/wiki tarballs and catalog files are large enough that Git LFS and release artifact discipline are core to the project.
- Local verification was limited because this machine lacks git-lfs and pytest; source/docs were inspected through the available checkout and Git object reads.

## Comparison

| Aspect | ctx | Vibe Coding LLM Wiki | Decapod | Ruflo |
|--------|-----|----------------------|---------|-------|
| Primary role | Graph-backed context recommender | Tutorial for Raw/Wiki/Schema knowledge workflow | Governance kernel for coding agents | Broad Claude Code orchestration platform |
| Artifact model | LLM-wiki + graph + runtime/full tarballs | Raw/compiled notes + JSONL catalog | .decapod specs/proofs | Plugins, skills, memory, witnesses |
| Runtime coupling | Claude Code plus generic harness/MCP options | Agent-agnostic tutorial | Agent-agnostic CLI | Claude Code oriented |
| Best pattern | Capped graph-ranked context bundle | Source-to-compiled note provenance | Governance around inference | Signed regression witnesses |
| Risk | Large artifacts and complex install surface | No implementation/license gap | Young and broadening | Huge alpha-heavy install surface |

ctx is the most direct answer so far to "which skills/tools should be in context right now?" It is heavier than Vibe Coding's wiki pattern and more focused on context selection than Decapod's governance loop.

## Self-Hosting Notes

Treat ctx as infrastructure, not a casual helper script. Before using it in a serious environment, install with a disposable profile first, run ctx-init before enabling hooks, prefer dry-run/update/uninstall flows for harnesses, keep the dashboard bound locally unless protected, and validate graph artifacts after upgrades.

---

**Attribution:** stevesolun/ctx, MIT License.

