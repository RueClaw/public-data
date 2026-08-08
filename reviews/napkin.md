# napkin (Michaelliv/napkin)

**Repo:** https://github.com/Michaelliv/napkin  
**License:** MIT; permissive reuse with attribution  
**Reviewed:** 2026-08-08  
**Stack:** TypeScript, Bun, Commander, FerroSearch/MiniSearch-compatible BM25, sql.js, gray-matter, Jexl, Obsidian Markdown/Canvas/Bases  
**What it is:** Local-first, file-based knowledge tooling for agents. It gives agents a progressive-disclosure interface over Markdown/Obsidian vaults: compact context, folder overview, ranked search, and explicit file reads.

---

## Update Notes

Checked against the older April review. Material changes warranted a rewrite:

- Current release is `0.9.2`, commit `bbea2920374829ca351a1290ad3d794eb0d6f903` from 2026-08-02.
- Search now uses `@shift-labs/ferrosearch`, a native MiniSearch-compatible engine with prebuilt binaries.
- The project now exposes a typed SDK in addition to the CLI.
- Obsidian-adjacent coverage is broader: Bases, Canvas, bookmarks, properties, links, tasks, templates, daily notes, and graph view.
- The package ships two agent skills, `distill` and `tend`, that operationalize capture and upkeep of vault knowledge.
- Verification is stronger than before: local tests passed after dependency install, but packaging/audit caveats remain.

---

## Verdict

✅ **Deploy candidate for local agent memory and vault tooling, with packaging hygiene checks.** napkin has the right core shape: no hosted service, no model dependency in the core, structured JSON output, and a practical disclosure ladder for context budgets. The main caveats are not conceptual; they are release hygiene: the committed lockfile is out of sync, `npm ci` fails on a fresh clone, and `npm audit --omit=dev` reports a high-severity `js-yaml` CPU-DoS advisory.

---

## What It Is

napkin is a CLI and TypeScript SDK for agent-operable Markdown vaults. It treats a knowledge base as normal files, not as an opaque vector database or SaaS memory store. Agents can start with `NAPKIN.md`, ask for a compact `overview`, run ranked `search`, then explicitly `read` only the files that matter.

That workflow is the point. A memory system for agents should not start by dumping a whole vault into the prompt. napkin makes the retrieval path legible and controllable: overview for orientation, search for candidate notes, read for full evidence.

The project is also Obsidian-aware without requiring Obsidian. It can work with Markdown notes, frontmatter properties, tasks, wikilinks, JSON Canvas files, `.base` database views, note templates, and daily notes from the command line or SDK.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | TypeScript, ESM, Bun for development/tests |
| CLI | Commander, Chalk |
| SDK | `Napkin` class wrapping pure core modules |
| Search | `@shift-labs/ferrosearch`, MiniSearch-compatible BM25/prefix/fuzzy search |
| Structured data | gray-matter, js-yaml, sql.js, Jexl |
| Vault format | Markdown, Obsidian-style wikilinks/frontmatter, JSON Canvas, Bases |
| Tests/tooling | Bun test, TypeScript, Biome |

## Key Features

### Progressive Disclosure

The README frames memory as four levels:

| Level | Surface | Purpose |
|-------|---------|---------|
| 0 | `NAPKIN.md` | Small pinned context |
| 1 | `napkin overview` | Vault map with folder keywords |
| 2 | `napkin search <query>` | Ranked results and optional snippets |
| 3 | `napkin read <file>` | Full file content on demand |

This is a clean contract for agent context management. It gives the agent a search path without pretending retrieval is magic.

### Agent-Usable CLI and SDK

Every major command supports `--json`, and the SDK methods return typed data instead of printing or exiting. The architecture split is healthy:

- `core/` owns pure logic and returns values.
- `commands/` owns CLI parsing and output.
- `sdk.ts` gives programmatic callers the same behavior without stdout coupling.

That makes napkin usable from shell-based agents, TypeScript agents, and ordinary scripts.

### Obsidian-Compatible Operations

The command surface is broad enough to make a vault actually maintainable:

- create/read/append/prepend/move/rename/delete notes
- list files/folders, outlines, word counts
- daily notes
- tags, aliases, properties, tasks, links, backlinks, unresolved links, orphans, deadends
- templates and bookmarks
- Canvas node/edge operations
- Bases querying via an in-memory SQLite model

This matters because read-only memory tools rot. Agents need narrowly-scoped write and upkeep operations too.

### Bundled Skills

The shipped `distill` skill is a good operational rulebook: gate whether anything is worth saving, search before creating, merge into existing notes when possible, verify unresolved links, and report what changed.

The `tend` skill is similarly conservative: fix a few broken links/tags/orphans/duplicates, avoid structural overreach, and prefer no-op over destructive cleanup. These skills are arguably as valuable as the CLI because they encode the behavior needed to keep a vault usable.

## Architecture

napkin's best architectural choice is the LLM-free core. Search, indexing, Markdown parsing, Obsidian metadata, and file mutation are deterministic local operations. Model behavior belongs at the caller or skill layer, not inside the storage engine.

The search path builds a local index over Markdown files, caches it under `.napkin`, and combines BM25 score with backlink count and recency. Snippets are extracted from the original file content when requested. Overview generation uses keyword extraction with explicit noise stripping for code blocks, URLs, emails, hashes, generated IDs, HTML tags, and similar converted-document debris.

The core/command split is also enforced by tests. There are tests checking that core modules do not import output utilities or call `console.log` / `process.exit`, which is the right kind of guard for a dual CLI/SDK project.

## Comparison

| Aspect | napkin | supermemory | agentmemory | GBrain-style systems |
|--------|--------|-------------|-------------|----------------------|
| Primary model | File-based vault CLI/SDK | Hosted/API memory platform | Passive agent-session memory capture | Larger operational knowledge system |
| Local-first | Strong | Partial/hosted-first | Stronger locally, broader daemon surface | Varies |
| Core dependency on LLMs | None | Service/API centric | Optional retrieval/enrichment paths | Often LLM-heavy |
| Best use | Agent-readable Markdown/Obsidian memory | Productized memory gateway | Capturing agent work history | Full knowledge operations |
| Main caveat | Packaging/audit cleanup | Trust and hosted data boundaries | Passive capture/privacy surface | Complexity |

napkin is not a complete memory product in the same way supermemory is, and it does not automatically capture sessions like agentmemory. Its strength is narrower: it gives agents a clean, local, inspectable interface to a human-editable knowledge base.

## Self-Hosting Notes

There is no service to host. Install the npm package or run from source:

```bash
npm install -g napkin-ai
napkin init --template coding
napkin overview --json
napkin search "authentication" --json
```

Fresh source install has one important gotcha. `npm ci` failed because `package-lock.json` is out of sync with `package.json`; `npm install` repaired the local dependency tree and triggered a successful TypeScript build. Until the lockfile is corrected upstream, reproducible CI/source installs are weaker than they should be.

## Verification

Reviewed shallow clone at `bbea2920374829ca351a1290ad3d794eb0d6f903`.

- `npm ci`: failed because the lockfile is out of sync. Missing entries include `@shift-labs/ferrosearch@0.1.1` and platform packages.
- `npm install`: passed and ran `npm run build` successfully during `prepare`.
- `npm test`: passed, 388 tests.
- `npm run check`: passed with 9 Biome warnings, mostly explicit `any` and unused imports.
- `npm audit --omit=dev --json`: failed with 1 high-severity advisory through `js-yaml`.
- Secret scan: no obvious hardcoded secrets; notable command-execution surfaces are expected CLI helpers (`open`, `pbcopy`, graph local server, update command, benchmark subprocesses).

---

**Attribution:** Michaelliv/napkin, MIT License.
