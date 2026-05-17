# Source-to-Compiled Wiki With Deterministic Gates

**Source:** https://github.com/wanderloots-tutorials/vibe-coding
**License:** No license specified; this is an original summary of the public idea, not a copy of repository text.
**Reviewed:** 2026-05-17

## Pattern

Maintain two knowledge layers:

- **Raw source layer:** original captured material, kept intact enough for later verification.
- **Compiled wiki layer:** short reusable notes extracted from sources, written for retrieval and reuse.
- **Schema/tooling layer:** templates, naming rules, catalog generation, source coverage checks, and public-audit checks.

The important rule is that agents query the compiled layer first. They open raw sources only when a compiled note is insufficient, stale, or needs verification.

## Why It Works

Agent-managed knowledge bases tend to fail in two opposite ways: raw dumps become too noisy to search, or summaries become detached from evidence. This pattern keeps both sides visible.

A compiled note is useful because it is short and indexed. A raw source is useful because it preserves provenance. Deterministic gates connect them by requiring source links, accurate source counts, catalog rebuilds, and coverage checks before changes are committed.

## Minimal Shape

A practical implementation can use plain files:

| Area | Role |
|------|------|
| `Raw/Sources/` | Source notes and imported material |
| `Wiki/` | Compiled notes grouped by topic, concept, entity, project, and log |
| `Schema/` | Frontmatter rules, naming rules, source manifest |
| `_templates/` | Note templates |
| `scripts/` | Build, lint, source coverage, search, audit |
| `Wiki/catalog.jsonl` | Machine-readable catalog for agents |
| `Schema/source-manifest.jsonl` | Source coverage state |

## Gate Checklist

Before committing meaningful wiki changes, run checks that answer:

- Can the catalog be rebuilt deterministically?
- Does every compiled note have a valid type/tag?
- Do source links point to real raw source files?
- Does `source_count` match the actual source list?
- Are processed sources represented in compiled notes?
- Are secrets, local paths, cache files, and private plugin state excluded?

## Useful Adaptations

- Use a pre-commit hook to rebuild the catalog and fail on broken source links.
- Make the catalog JSONL so shell tools, scripts, and agents can search it cheaply.
- Keep raw binary/source attachments out of Git unless explicitly intended.
- Add a public audit script when a wiki may be published or synced.

## Cautions

The reviewed repository is a tutorial resource, not a finished package, and it does not declare a license. Use the pattern, but write independent templates, scripts, and instructions.

---

**Attribution:** Pattern summarized from wanderloots-tutorials/vibe-coding, no license specified.

