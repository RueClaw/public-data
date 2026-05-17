# Vibe Coding (wanderloots-tutorials/vibe-coding)

**Repo:** https://github.com/wanderloots-tutorials/vibe-coding
**License:** No license specified; summarize for educational use only, do not reuse or redistribute source text as licensed material.
**Reviewed:** 2026-05-17
**Stack:** Markdown tutorial resources, YouTube companion notes, Obsidian/LLM Wiki workflow guidance, Stripe architecture notes, design-system prompt notes
**What it is:** A small companion repository for Wanderloots tutorials. It contains Markdown resources for beginner Git/GitHub workflows, sandboxed Stripe integration, a tactical dashboard design system, and a detailed agent-facing LLM Wiki setup guide.

---

## Verdict

📚 **Study the knowledge-workflow pattern, do not treat this as reusable source.** The repository is tiny and mostly prose, but the LLM Wiki setup guide captures a useful workflow: split raw sources from compiled notes, make agents query the compiled catalog first, and enforce traceability with deterministic maintenance commands. The missing license matters. The ideas can be summarized and studied, but the source text should not be copied into other projects.

---

## What It Is

This is not an application repository. It is a public tutorial companion repo with four Markdown documents: a short README linking videos, a design-system note, a Stripe integration tutorial, and an LLM Wiki core setup guide for AI coding agents.

The most useful artifact is `wanderloots-llm-wiki-core-setup-v1.0.0.md`. It describes how an agent should scaffold a beginner-friendly Obsidian-style wiki from an empty folder: raw source notes under `Raw/Sources/`, compiled reusable notes under `Wiki/`, schema and templates under `Schema/` and `_templates/`, skills under `.agents/skills/`, and deterministic scripts for catalog generation, linting, source coverage, and public audit checks.

The Stripe note is also practical. It focuses on payment integration in ephemeral browser sandboxes, especially hybrid redirect/webhook confirmation, Firebase Admin graceful degradation, cross-origin popup messaging, JWT verification, server-side price validation, merge writes, and idempotent webhook handling.

## Stack

| Layer | Tech |
|-------|------|
| Content | Markdown tutorial documents |
| Knowledge workflow | Obsidian-style Raw/Wiki/Schema folder model |
| Agent instructions | AGENTS.md and .agents/skills conventions described in prose |
| Tooling concept | Standard-library Python `wiki_tool.py`, pre-commit hook, JSONL catalog/source manifest |
| Payment tutorial | React/Vite, Express/Node, Firebase Auth/Admin, Firestore, Stripe Checkout/webhooks |
| Verification | No runnable code, tests, CI, or package manifests in the repo |

## Key Features

### Agent-Buildable LLM Wiki

The LLM Wiki guide is structured as an agent execution plan. It gives a build order, expected files, commit checkpoints, tool commands, acceptance criteria, and maintenance gates. That makes it more actionable than a loose blog post.

### Raw vs Compiled Knowledge Boundary

The strongest idea is separating source capture from reusable compiled notes. Raw source material remains under `Raw/Sources/`; concise, queryable knowledge lives under `Wiki/`; compiled notes must cite sources and keep `source_count` accurate.

### Deterministic Maintenance Gates

The guide asks for a standard-library `wiki_tool.py` with commands for doctor, build, lint, source scan, source lint, source delta, source coverage, catalog search, and logs. That is a good instinct for agent-managed knowledge bases: force cheap checks before committing agent-generated notes.

### Practical Stripe Sandbox Advice

The Stripe tutorial is clear about a common failure mode: sandbox environments make backend secrets and webhook delivery awkward. The recommended hybrid flow, secure JWT validation, server-side price mapping, merge writes, and idempotency checks are sensible.

## Architecture

The repository itself has no code architecture. The architecture worth noting is the proposed knowledge-base layout:

| Area | Purpose |
|------|---------|
| `Raw/Sources/` | Original source notes, not reusable compiled knowledge |
| `Wiki/` | Short compiled notes organized as topics, concepts, entities, projects, and logs |
| `Schema/` | Frontmatter schema, naming conventions, lint checklist, source manifest |
| `_templates/` | Note templates for sources and compiled notes |
| `.agents/skills/` | Agent workflows for ingest, query, lint, and maintenance |
| `scripts/` | Deterministic build/lint/audit tooling |
| `Wiki/catalog.jsonl` | Machine-readable search/index layer for compiled notes |

The design is intentionally file-first. That makes it easy to inspect in Git and easy for coding agents to modify without a database.

## Comparison

| Aspect | Vibe Coding LLM Wiki guide | Decapod | Citadel |
|--------|----------------------------|---------|---------|
| Primary role | Tutorial for agent-managed knowledge base scaffolding | Governance kernel for coding agents | Claude Code orchestration and campaign persistence |
| Artifact model | Raw/Wiki/Schema folders plus JSONL catalogs | .decapod specs, context, proof artifacts | Markdown campaign files |
| Enforcement | Proposed lint/source/audit scripts | CLI gates and proof workflows | Hooks, policies, routing, campaign updates |
| Maturity | Prose guide only | Working Rust CLI with tests | Working plugin/orchestration framework |
| Best idea | Source-to-compiled-note traceability | Callable governance around inference | Persistent campaign state |

Compared with Decapod and Citadel, this repo is much lighter. It is closer to a tutorial pattern than a tool. Its value is the folder contract and maintenance-gate checklist, not implementation depth.

## Self-Hosting Notes

There is nothing to deploy. The repo can be cloned as reference material, but because no license is specified, treat it as educational reading. If implementing the LLM Wiki idea, write your own templates and tooling rather than copying the repository text.

---

**Attribution:** wanderloots-tutorials/vibe-coding, no license specified.

