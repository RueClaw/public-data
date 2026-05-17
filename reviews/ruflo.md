# Ruflo (ruvnet/ruflo)

**Repo:** https://github.com/ruvnet/ruflo
**License:** MIT in repository and npm metadata; permissive reuse with attribution.
**Reviewed:** 2026-05-17
**Stack:** TypeScript/Node.js, Claude Code plugins, MCP, WASM/Rust-adjacent kernels, vector memory, Vitest, Docker
**What it is:** Ruflo is a large multi-agent orchestration platform for Claude Code, packaging swarms, plugins, memory, federation, verification, and hosted/web UI surfaces around the older Claude Flow line.

---

## Verdict

📚 **Study, selectively harvest.** Ruflo is too broad and alpha-shaped to treat as a drop-in orchestration base, but it contains several useful patterns for agent ecosystems: plugin packaging, skill/agent marketplaces, signed regression witnesses, and federation budget controls. The strongest reusable idea is its verification witness layer, which turns past bug fixes into auditable markers that CI can keep checking.

---

## What It Is

Ruflo markets itself as a Claude Code orchestration layer: install once, then let hooks, skills, agents, MCP tools, and memory coordinate coding tasks in the background. The README describes two install modes: a lightweight Claude Code plugin marketplace path and a full CLI install via npx ruflo init, with very different blast radii.

The repository is effectively a platform monorepo. It includes an npm package named ruflo, compatibility/package metadata for claude-flow, a v3 workspace with many @claude-flow packages, a plugin catalog under plugins/ruflo-*, bundled .agents/skills, a web UI subtree, and verification infrastructure. Public GitHub metadata at review time showed the repo as public, heavily starred, recently pushed, and actively changing.

The project is ambitious and crowded. That is both the value and the risk: there are many concrete patterns to learn from, but the install surface, marketing claims, generated artifacts, and alpha package versions make careful adoption more important than enthusiasm.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Node.js >= 20, TypeScript, ESM |
| Package management | npm, pnpm workspace in v3 |
| Agent surface | Claude Code plugins, .agents/skills, CLI commands, MCP tools |
| Memory/search | AgentDB, RuVector packages, HNSW/vector memory claims |
| Federation/security | Ed25519, mTLS-oriented docs, Zod validation, safe executor/path validation claims |
| Verification | SHA-256 marker manifests, Ed25519-signed witness records, CI smoke tests |
| UI/deploy | Svelte/Vite web UI subtree, Docker/Cloud Run artifacts |

## Key Features

### Plugin and Skill Marketplace Shape

The repo ships a large plugins/ruflo-* catalog and a .claude-plugin marketplace manifest. The public docs separate lightweight plugin install from the full CLI install, which is a useful product boundary: quick trials should not mutate a user's workspace the same way production setup does.

### Agent and Swarm Catalog

The .agents/skills tree contains many specialized agent skill definitions for reviewers, planners, memory coordinators, swarm roles, GitHub automation, security, performance, and workflow automation. Even if the individual skills need validation, the taxonomy is useful as a map of roles people expect from a multi-agent coding system.

### Verification Witnesses

The verification/ system is the strongest design artifact. It documents a three-layer regression guard: behavioral smoke tests, a signed witness manifest of fix markers, and per-OS JSONL history. Instead of trusting that a past bug fix remains present because tests once passed, Ruflo records load-bearing marker substrings and verifies them over time.

### Federation Safety Controls

The status docs call out federation budget and hop-limit controls, including constant error reasons such as HOP_LIMIT_EXCEEDED and BUDGET_EXCEEDED. For agent-to-agent delegation systems, default recursion limits are a practical requirement, not a nice-to-have.

## Architecture

Ruflo is organized as a broad monorepo rather than a single tight library. Important top-level areas include:

- package.json and ruflo/package.json for the published npm surfaces.
- v3/@claude-flow/* for modular packages such as CLI, MCP, memory, embeddings, providers, security, browser, swarm, and federation.
- plugins/ruflo-* for Claude Code plugin packages.
- .agents/skills for bundled agent role definitions.
- verification/ for witness manifests and capability baselines.
- ruflo/src/ruvocal for the web UI/deployment surface.

The design leans toward capability aggregation: CLI commands, MCP tools, plugins, skills, hooks, browser automation, memory, and hosted UI are all presented as pieces of the same ecosystem. That makes Ruflo useful as a pattern mine, but also means adopters should evaluate individual subsystems instead of assuming the whole stack has uniform maturity.

## Comparison

| Aspect | Ruflo | Smaller agent frameworks | Plugin-only Claude Code packages |
|--------|-------|--------------------------|----------------------------------|
| Scope | Very broad platform | Usually one orchestration layer | Narrow command/skill additions |
| Install blast radius | High in full mode | Varies | Lower |
| Reusable patterns | Many | Fewer but clearer | Focused |
| Maturity signal | Active, large, alpha-heavy | Often simpler to audit | Easier to reason about |
| Best use | Study and selective extraction | Direct adoption | Lightweight extension |

## Self-Hosting Notes

Ruflo documents npm install, Claude Code plugin install, MCP server registration, Docker-based web UI deployment, and Cloud Run-oriented artifacts. A practical self-host should start with a disposable test workspace, inspect every generated file, and avoid enabling full hooks/federation/memory features until the workspace mutations are understood.

During review, a shallow clone on a case-insensitive filesystem reported filename collisions between SKILL.md and skill.md in a few .agents/skills directories. That is a portability issue to watch for on macOS defaults.

## Security and Maturity Notes

- SECURITY.md documents vulnerability reporting, safe harbor, and boundary controls such as input validation, parameterized SQL, path traversal prevention, and command injection protection.
- npm audit --package-lock-only reported 23 vulnerabilities during reconnaissance: 13 high and 10 moderate. That needs upstream triage before production trust.
- Root scripts include build:ts and lint commands with || true, which can hide failed build/lint signal.
- Coverage thresholds are explicitly disabled in v3/vitest.config.ts.
- The README and status docs make large capability claims, including hundreds of tools and dozens of plugins/agents. Verify the specific feature path you need before relying on it.
- Secret-like strings found in docs appear to be examples, but the repo is broad enough that downstream adopters should run their own secret and supply-chain scans before install.

---

**Attribution:** ruvnet/ruflo, MIT License.
