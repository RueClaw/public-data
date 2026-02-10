# Skills as Context Injection for Coding Agents

> **Source:** [google-gemini/gemini-skills](https://github.com/google-gemini/gemini-skills) (Apache-2.0)
> **Extracted:** 2026-02-10

## The Pattern

Use distributable "skill" files (markdown with frontmatter) to inject up-to-date API knowledge into coding agents whose training data is stale. The skill acts as a context patch — overriding outdated model knowledge with current facts.

## Why It Works

LLMs are trained on snapshots. APIs evolve faster than retraining cycles. By injecting a skill file into an agent's context at generation time, you get:

1. **Correct model names** — No more hallucinating deprecated model IDs
2. **Current SDK patterns** — Right imports, right syntax, right library
3. **Live schema access** — Point agents to discovery endpoints for real-time accuracy

## Key Techniques from Google's Implementation

### 1. Authoritative Override Framing
```markdown
> [!IMPORTANT]
> Models like `gemini-2.5-*` are legacy and deprecated. Your knowledge is outdated.
```
Directly tells the agent its training data is wrong. Aggressive but effective for steering.

### 2. llms.txt as Documentation Index
```
https://ai.google.dev/gemini-api/docs/llms.txt
```
A plain-text index of all doc pages in `.md.txt` format. Agents can:
1. Fetch the index to discover what docs exist
2. Fetch specific pages on demand (e.g., `function-calling.md.txt`)

This is a lightweight alternative to RAG — the agent does its own retrieval from a curated index. See also: [llmstxt.org](https://llmstxt.org/) for the emerging convention.

### 3. Discovery Spec as Source of Truth
```
https://generativelanguage.googleapis.com/$discovery/rest?version=v1beta
```
Points agents to the live REST API discovery document for exact field names, types, and operations. No stale docs — always current.

### 4. Distribution via npx
```bash
npx skills add google-gemini/gemini-skills --skill gemini-api-dev --global
```
Skills are GitHub repos with a convention (`skills/<name>/SKILL.md`). The `npx skills` CLI pulls them down. Simple, no registry needed — just git.

### 5. Context7 Integration
A `context7.json` at repo root registers the skill with [Context7](https://context7.com), a skill aggregation platform, for broader discovery.

## Reusable Ideas

- **Any API provider** can ship a skill file to keep coding agents current
- **llms.txt** is a pattern any documentation site should adopt — it's trivial to generate and massively useful for agents
- **Discovery/OpenAPI specs** as canonical references beat prose documentation for agent consumption
- **Frontmatter metadata** (`name`, `description`) enables skill routers to select the right context automatically
- **The "your knowledge is outdated" framing** is a blunt instrument but solves a real problem — agents confidently using deprecated APIs

## Comparison to OpenClaw Skills

| Aspect | Google gemini-skills | OpenClaw Skills |
|--------|---------------------|-----------------|
| Format | `SKILL.md` with frontmatter | `SKILL.md` with frontmatter |
| Distribution | `npx skills add` from GitHub | Built-in + local directories |
| Scope | API knowledge injection | Full tool orchestration (scripts, CLIs, assets) |
| Trigger | Coding agent context | Agent skill router (description matching) |
| Bundled tools | None (docs only) | Scripts, configs, references |

Google's version is purely informational — context injection for coding. OpenClaw skills are operational — they include tooling. But the core insight is the same: **markdown files with metadata are a great unit of distributable agent knowledge.**
