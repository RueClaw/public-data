# Knowledge Catalog (GoogleCloudPlatform/knowledge-catalog)

**Repo:** https://github.com/GoogleCloudPlatform/knowledge-catalog
**License:** Apache-2.0 at the repository root; permissive reuse with attribution. Some package metadata still says ISC and should be treated as repo-hygiene drift until fixed upstream.
**Reviewed:** 2026-06-17
**Stack:** Python 3.11+, Google ADK, Gemini, BigQuery, Dataplex/Knowledge Catalog, TypeScript, Bun, MCP, Cytoscape.js
**What it is:** A Google Cloud sample and tooling repository for turning data-catalog metadata into file-based knowledge artifacts, enriching them with agents, and serving them back through CLIs, MCP, static viewers, and Dataplex workflows.

---

## Verdict

⚠️ **Interesting, mostly for the file-based knowledge format and catalog-agent patterns.** The strongest idea is Open Knowledge Format: markdown plus YAML frontmatter, organized as a directory tree, with links, citations, generated indexes, and git history. The repo is too young and fragmented to deploy as a production catalog platform as-is, but it is a good reference for metadata-as-code, agent-enriched data documentation, and portable knowledge bundles.

---

## What It Is

Knowledge Catalog collects several related experiments around Google Cloud Knowledge Catalog, formerly Dataplex. The repo is not one polished application. It contains an OKF proof of concept, a TypeScript metadata-as-code CLI and MCP server, an enrichment agent, a discovery agent sample, demos, generated bundles, and a larger agent implementation under `agents/enrichment`.

The clearest contribution is OKF, described as a vendor-neutral bundle format for knowledge. A bundle is just a directory of markdown files with YAML frontmatter. Each markdown file is a concept, links between files express graph relationships, optional `index.md` files support progressive disclosure, and the whole thing can live in git. That makes data catalog enrichment reviewable with normal code-review workflows instead of burying it in a service database.

The agent side demonstrates how to populate these artifacts from BigQuery metadata and web documentation. The TypeScript side demonstrates bidirectional sync with Dataplex/Knowledge Catalog through a local snapshot format plus an MCP server exposing list, lookup, and modify tools.

## Stack

| Layer | Tech |
|-------|------|
| OKF enrichment agent | Python 3.11+, `google-adk`, Gemini, BigQuery client, PyYAML, Pydantic, markdownify |
| Metadata-as-code CLI | TypeScript, Bun, `cac`, `yaml`, `zod`, Google Cloud auth through `gcloud` |
| MCP server | TypeScript, `@modelcontextprotocol/sdk`, stdio transport |
| Discovery sample | Python, Google ADK, Vertex Gemini, Dataplex search API |
| Viewer | Static HTML, Cytoscape.js, marked |
| Auth/runtime | Google Application Default Credentials, Gemini API key or Vertex AI |

## Key Features

### Open Knowledge Format

OKF is the best part of the repo. It intentionally keeps the interchange layer boring: markdown body, YAML frontmatter, normal file paths, normal links, optional indexes, optional logs. Required fields are small enough for agents and humans to produce consistently, while extensions are allowed without forcing a central schema registry.

This is a good pattern for agent-readable operational knowledge because it makes the artifact inspectable before any model sees it. A catalog entry can be reviewed in a pull request, linked like a wiki page, indexed with normal text tooling, rendered as documentation, or loaded directly into an agent context.

### Agentic Enrichment Pipeline

The `okf/` package has a BigQuery source implementation and two Google ADK agents: one for source metadata, one for web ingestion. The web fetch tool enforces scheme checks, host allowlists, optional path filters, denied substrings, visited-URL tracking, fetch budgets, and crawl depth. That is the right instinct for agentic enrichment: the crawler has hard tool-side bounds instead of relying only on prompt instructions.

The bundle writer also has an augmentation guard during web enrichment. For existing BigQuery table documents, it refuses writes that remove schema fields or shrink citations. That is a practical guardrail for a common failure mode: a later LLM pass replacing grounded metadata with a prettier but incomplete summary.

### Metadata as Code and MCP

The TypeScript `kcmd` package models catalog snapshots as local YAML and markdown files. It can initialize snapshots for BigQuery datasets, entry groups, or knowledge bases, pull from the catalog, push changes, and expose MCP tools for list, lookup, and modify operations.

The MCP server is intentionally small: it exposes a local snapshot instead of giving an agent direct unstructured API access. That is a useful control-plane pattern for data catalogs, where agent edits should happen against reviewable files and then be pushed explicitly.

### Self-Contained Viewer

The OKF visualizer generates a single HTML file containing the bundle and a graph view. It renders concept nodes, links, backlinks, metadata, markdown detail panes, search, type filters, and layout switches. This matters because a portable knowledge format needs at least one simple consumer to prove that the format is not just write-only agent output.

## Architecture

The repo is currently split across several overlapping areas:

- `okf/` contains the cleanest proof of concept: OKF spec, Python package, tests, samples, generated bundles, and static viewer.
- `toolbox/mdcode/` contains a TypeScript library, CLI, and MCP server for Dataplex metadata-as-code.
- `toolbox/enrichment/` contains a TypeScript enrichment agent wrapper around `kcmd` and file-set tools.
- `agents/enrichment/` contains a larger Python enrichment system with table, doc, and context-overlay modes, Drive/local markdown inputs, GitHub context ingestion, refinement, and evaluation.
- `samples/discovery/` contains a small ADK search assistant over Knowledge Catalog semantic search.

That spread makes the repo useful as a research/sample collection, but it also makes the product boundary muddy. There are duplicate-looking `toolbox/` and `agents/` tracks, no visible GitHub Actions workflows, and package licenses in TypeScript subprojects declare ISC despite the repository root declaring Apache-2.0.

## Comparison

| Aspect | Knowledge Catalog | Traditional data catalog | Markdown wiki / docs repo |
|--------|-------------------|--------------------------|---------------------------|
| Artifact model | Git-friendly markdown/frontmatter bundles plus catalog snapshots | Service-owned metadata records | Free-form pages |
| Agent use | Explicit producer/consumer format, MCP, enrichment agents | Usually API-driven, service-specific | Easy to read, weak structure |
| Review workflow | Pull-request friendly | Often UI/API audit logs | Pull-request friendly |
| Query/structure | Minimal frontmatter plus links | Strong service schema | Usually inconsistent |
| Maturity | Fresh sample repo, fragmented | Mature products exist | Mature tooling, no catalog semantics |

## Security and Maturity Notes

The repo has good instincts around web-crawl budgets, host allowlists, schema-preservation guards, and explicit ADC/GCP auth requirements. I did not find hardcoded secrets in the scanned source; the hits were references to token handling, test tokens, and documentation examples.

The maturity story is still early. GitHub metadata at review time showed 3,416 stars, 226 forks, 22 open issues, created 2026-05-04, and pushed 2026-06-17. The latest cloned commit was `2d0bb3f` from 2026-06-14. Local verification was limited: Python tests could not start because `pytest` was not installed in the current Python, and `toolbox/mdcode` tests failed before execution because package dependencies were not installed in the fresh clone. No GitHub Actions workflows were present in the checked-out tree.

## Self-Hosting Notes

This is not a turnkey self-hosted catalog. Expect to bring Google Cloud credentials, BigQuery/Dataplex access, Vertex or Gemini credentials, Python, Node/Bun, and `gcloud` ADC. The OKF bundle format and viewer are the easiest pieces to reuse independently. The Dataplex sync and enrichment agents are more tied to Google Cloud.

For production use, treat the agent-generated bundle as a proposed change set: commit it, diff it, review it, run validators/evals, and only then push to a catalog service.

---

**Attribution:** GoogleCloudPlatform/knowledge-catalog, Apache-2.0. Review based on repository source, README files, OKF spec, package manifests, GitHub metadata, and local static inspection on 2026-06-17.
