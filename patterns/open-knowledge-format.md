# Open Knowledge Format: Git-Native Knowledge Bundles

**Source:** GoogleCloudPlatform/knowledge-catalog
**Repo:** https://github.com/GoogleCloudPlatform/knowledge-catalog
**License:** Apache-2.0
**Extracted:** 2026-06-17

## Pattern

Represent operational knowledge as a directory of markdown files with YAML frontmatter, normal file paths, normal markdown links, optional generated indexes, and git history. Keep the storage layer simple enough that humans, agents, static renderers, search indexes, and review tools can all consume the same artifact.

## Shape

```text
bundle/
|-- index.md
|-- log.md
|-- datasets/
|   |-- index.md
|   `-- ecommerce.md
`-- tables/
    |-- index.md
    `-- events.md
```

Each concept document starts with frontmatter:

```yaml
---
type: BigQuery Table
title: Events
description: Daily event table for ecommerce analytics.
resource: https://console.cloud.google.com/bigquery?p=example&d=analytics&t=events
tags: [analytics, ecommerce]
timestamp: 2026-06-17T00:00:00Z
---
```

The body stays markdown. Links between files express relationships. A generated `index.md` at each directory gives agents progressive disclosure so they can navigate the bundle without loading every file into context.

## Why It Works

- **Reviewable knowledge:** proposed catalog changes become normal git diffs.
- **Agent-readable by default:** an agent can read one markdown concept without SDK setup.
- **Portable:** the bundle can be a repository, archive, static site input, or local folder.
- **Graph-friendly:** markdown links create relationships richer than the directory tree.
- **Extensible without central authority:** consumers use required/common keys and preserve unknown frontmatter.

## Implementation Notes

- Require a tiny frontmatter core: `type`, `title`, `description`, and `timestamp` are enough for routing, display, and freshness.
- Keep `resource` optional but strongly recommended for concepts tied to real assets.
- Use bundle-relative links (`/tables/events.md`) when possible so documents can move inside subdirectories.
- Generate directory indexes after writes instead of asking agents to maintain them by hand.
- Add write guards for enrichment passes. If a later agent augments a concept, it should not silently remove schema fields, citations, or other grounded source metadata.
- Treat generated knowledge as a proposal. Commit, diff, review, validate, then publish.

## Good Fit

- Data catalogs and schema documentation
- Agent-readable runbooks
- Domain knowledge bundles
- Static knowledge bases that need provenance and review
- RAG corpora where source artifacts should remain inspectable

## Caveats

Markdown/frontmatter is not a substitute for every domain schema. Use it as the reviewable knowledge layer, not as a replacement for strongly typed source schemas like SQL, OpenAPI, Protobuf, or Avro. If many agents write into the bundle, validators and preservation guards become necessary.

---

**Attribution:** Pattern extracted from GoogleCloudPlatform/knowledge-catalog, especially `okf/SPEC.md`, `okf/src/enrichment_agent/bundle/`, and the generated sample bundles. Apache-2.0.
