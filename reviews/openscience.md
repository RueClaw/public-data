# OpenScience (synthetic-sciences/openscience)

**Repo:** https://github.com/synthetic-sciences/openscience
**License:** Apache-2.0, permissive reuse with attribution and notice preservation
**Reviewed:** 2026-07-30
**Stack:** TypeScript, Bun, Hono, SolidJS, Vite, Astro, MCP, Agent Client Protocol, scientific database connectors
**What it is:** A local AI workbench for scientific research that combines an agent runtime, browser workspace, research-specialist prompts, scientific database tools, skills, provider routing, and optional managed Atlas services.

---

## Verdict

✅ **Deploy candidate for local scientific-agent pilots, with security and dependency caveats.** OpenScience is not just a README wrapper around prompts: it has a real local server, workspace UI, provider routing, tool registry, scientific connector layer, skill system, CI, releases, and native packaging. The rough edges are also real: the agent is intentionally unsandboxed, one backend test currently fails in the SPA fallback path, and `bun audit --omit dev` reports production dependency advisories that need triage before sensitive or exposed use.

---

## What It Is

OpenScience is a local research-agent environment aimed at machine learning, biology, physics, chemistry, and adjacent scientific workflows. The product pitch is "give it a goal and let it read literature, write code, run experiments, query scientific databases, and write up findings." In practice, the repo implements a Codex/Claude-style local workbench with scientific tooling layered into the agent surface.

The strongest part is the amount of product substrate already wired together. Running `openscience` starts a loopback Hono server and browser workspace with session history, file tree, editor, terminal, provider configuration, MCP, skills, and scientific tools. The repo also ships releases through npm/native platform packages and has GitHub workflows for CI, CodeQL, gitleaks, Scorecard, E2E, and publish verification.

The science layer is still early but unusually concrete. The connector registry covers literature, proteins, genomics, chemistry, pathways, and omics sources; `science_list_dbs`, `science_search`, and the newer `science_fetch` tool expose those connectors through a flat agent-facing API rather than one tool per database.

## Stack

| Layer | Tech |
|-------|------|
| CLI/runtime | Bun, TypeScript, native binary build scripts |
| Server | Hono, SSE, WebSocket, loopback-only local API |
| Frontend | SolidJS workspace, shared UI package, Astro docs/share site |
| Agent runtime | Provider-specific system prompts, agent prompts, sessions, compaction, tools, permissions |
| Providers | AI SDK provider packages for OpenAI, Anthropic, Google, OpenRouter, Bedrock, Azure, Groq, Mistral, xAI, Cerebras, and others |
| Scientific tools | Connector registry, public scientific APIs, record/file fetch, scientific file inspection |
| Extensibility | MCP, ACP, plugins, skills, custom agents, commands |
| CI/security | Typecheck, tests, build jobs, CodeQL, gitleaks, OSSF Scorecard, release smoke tests |

## Key Features

### Local Workbench Runtime

The server binds to loopback and serves the workspace UI, session APIs, file APIs, provider configuration, MCP routes, terminal routes, and settings. Host and Origin checks are explicit, including DNS-rebinding and cross-origin WebSocket protection. This is a much better default than a casual `localhost` app with permissive CORS.

### Scientific Connector Registry

The connector registry keeps the agent API flat: databases register behind one catalog, and the model discovers `db` ids through `science_list_dbs`. The current source tree includes 42 connectors spanning arXiv, PubMed, Europe PMC, Semantic Scholar, UniProt, RCSB PDB, AlphaFold, Ensembl, PubChem, ChEMBL, KEGG, Reactome, GTEx, GEO, DepMap, and others.

The newer `science_fetch` design is particularly important because search-only scientific tools tend to dead-end at the record URL. OpenScience now has a path for retrieving records and spilling large records/files into `.openscience/fetch/<db>/...` with sanitized filenames and size-aware handling.

### Agent and Skill Surfaces

OpenScience ships a research harness plus specialist prompts for biology, physics, ML, literature review, critique, writing, exploration, and review. It also bundles 290+ skill files. The important caveat is that skills are instruction bundles, not guaranteed executable integrations; the model receives guidance and paths, then still has to run the right command or script correctly.

### BYOK and Managed Model Boundary

The billing/credential code is more careful than average. It separates bring-your-own-key, first-party OAuth subscription paths, and managed proxy credentials by the resolved credential source, not just provider id. The synced-env policy also blocks Atlas-synced provider keys from shadowing local BYOK credentials except for the explicit managed OpenRouter path.

### Release Discipline

The repo has real release automation: npm/native package publish, platform smoke tests, Node wrapper checks, binary version checks, CodeQL, gitleaks, Scorecard, and scheduled E2E/catalog jobs. Recent releases are active: v2.0.1 was published 2026-07-29, and the reviewed HEAD was pushed 2026-07-30.

## Architecture

OpenScience is a monorepo with clear runtime boundaries:

- `backend/cli` holds the CLI, server, agent runtime, tools, provider integrations, sessions, and bundled skills.
- `frontend/workspace` is the SolidJS browser workspace served by the CLI.
- `frontend/ui` is the shared UI package.
- `frontend/docs` and `frontend/landing` handle docs and marketing surfaces.
- `tooling/sdk/js` is generated from the server contract.
- `tooling/plugin` provides the plugin runtime.

The prompt architecture is two-layered: provider-specific system prompts live under `backend/cli/src/session/prompt/`, while domain/workflow agent prompts live under `backend/cli/src/agent/prompt/`. The routing is explicit in TypeScript rather than hidden in config alone.

The connector architecture is the best reusable pattern: a small `Connector` interface, a central registry, typed catalog entries, opt-in rate limits, and a tool layer that never needs to know about individual scientific databases. That is the right shape for agent tools where hundreds of sources would otherwise explode the tool list.

## Comparison

| Aspect | OpenScience | Wandr | Open Notebook |
|--------|-------------|-------|---------------|
| Primary goal | Scientific research workbench and agent runtime | Deep/wide research benchmark | Self-hosted NotebookLM-style source workspace |
| Agent runtime | Full local session/tool/provider runtime | Benchmark harness, not a user workbench | Source ingestion and notebook workflows |
| Science-specific tooling | First-class scientific connectors, skills, file inspection | General web/research evaluation tasks | General knowledge sources, not scientific DB tooling |
| Deployment posture | Local app with optional managed services | Evaluation runs with provider/network cost caveats | Self-hosted app/API stack |
| Main caveat | Unsandboxed agent plus dependency/test cleanup needed | Benchmark cost and network surface | Deployment/auth hardening and app complexity |

## Self-Hosting Notes

Install path is straightforward:

```bash
npm install -g @synsci/openscience
openscience
```

Development uses Bun 1.3+:

```bash
bun install --frozen-lockfile
bun run typecheck
bun run --cwd backend/cli test
```

Local verification on 2026-07-30:

- `bun install --frozen-lockfile` passed.
- `bun run typecheck` passed across 7 package tasks.
- `bun run --cwd backend/cli test` produced 1432 pass / 1 skip / 1 fail. The failing test is `spa fallback > browser navigation to an unmatched route still gets the SPA index.html`, receiving 404 instead of expected 200.
- `bun audit --omit dev` reported 75 advisories: 2 critical, 24 high, 38 moderate, 11 low. Notable packages include `seroval`, `tar`, `hono`, `minimatch`, `undici`, `@modelcontextprotocol/sdk`, `fast-uri`, and `postcss`.

Use it locally first. Do not expose the server remotely without an additional containment layer, and run inside a VM/container for untrusted projects because the README and security policy correctly state that the permission system is not a sandbox.

---

**Attribution:** synthetic-sciences/openscience, Apache-2.0
