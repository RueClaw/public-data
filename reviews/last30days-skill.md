# last30days-skill (mvanhorn/last30days-skill)

**Repo:** https://github.com/mvanhorn/last30days-skill
**License:** MIT
**Reviewed:** 2026-06-07
**Stack:** Python 3.12+, Agent Skills / Claude Code skill packaging, stdlib HTTP, Reddit/HN/Polymarket/GitHub/web adapters, optional X/YouTube/TikTok/Instagram/Threads/Bluesky/Perplexity/Digg integrations, pytest
**What it is:** A multi-harness agent skill that researches a topic across recent social, market, developer, and web sources, scores the evidence, clusters it, and renders a grounded last-30-days brief.

---

## Verdict

✅ **Deploy candidate for personal research, with credential boundaries.** last30days-skill is much more than a prompt: it is a full Python research engine wrapped as an Agent Skill, with broad source adapters, a planner, fan-out retrieval, scoring, reranking, clustering, HTML export, setup flows, and a large passing test suite. The main caution is trust and blast radius: it can read browser cookies, API keys, local keychain entries, and write research artifacts, so install it only where that access is acceptable.

---

## What It Is

last30days-skill is an agent-operated search/research tool for recency-heavy topics. It pulls signals from places where people actually discuss, watch, bet, and build: Reddit, Hacker News, Polymarket, GitHub, X/Twitter, YouTube, TikTok, Instagram, Threads, Bluesky, Digg, Perplexity, and web search depending on configured credentials and local tools.

The skill is distributed for Claude Code, Codex, Cursor, Copilot, Gemini CLI, OpenClaw, claude.ai, and other Agent Skills hosts. The skill contract in `skills/last30days/SKILL.md` is intentionally strict: it tells the hosting model when to run the Python engine, how to plan named-entity searches, how to handle output format, and how not to improvise a generic web-search answer.

The current repo is version 3.3.2. Latest reviewed commit: `122158415ae421da83e739f2668032f6bc78d39c`.

## Stack

| Layer | Tech |
|-------|------|
| Skill packaging | Agent Skills, Claude Code plugin/marketplace metadata, OpenClaw metadata |
| Engine | Python 3.12+ |
| Dependencies | Runtime dependency list is empty; stdlib-heavy implementation |
| Reasoning/rerank providers | Gemini, OpenAI/Codex auth, xAI, OpenRouter, local fallback paths |
| Sources | Reddit, Hacker News, Polymarket, GitHub, X/Twitter, YouTube, TikTok, Instagram, Threads, Bluesky, Truth Social, Digg, Pinterest, Perplexity, web grounding |
| Storage/output | Markdown, JSON, HTML, SQLite research store, saved raw run artifacts |
| Tests | pytest, coverage config, fixtures |

## Key Features

### Multi-Source Social Signal Search

The engine does not treat the web as one source. It fans out to multiple channels, normalizes results into a common `SourceItem` schema, attaches engagement and relevance signals, dedupes, ranks, clusters, and renders a brief.

This is the core value: Reddit upvotes, Hacker News points, Polymarket odds, GitHub activity, YouTube transcripts, X posts, and web citations each carry different kinds of signal.

### Strict Skill Contract

`SKILL.md` is long because it encodes the failure history of the tool. It requires the hosting model to run the Python engine, pass through the badge/footer, avoid trailing source dumps, generate plans for named entities, and respect a precise output shape.

That is useful discipline for agent tools: the skill is not just "here is a script," it is a behavioral contract between the host model and the engine.

### Planning, Fan-Out, Reranking, Clustering

The pipeline resolves available sources, plans subqueries, runs source fetches in parallel, normalizes/scales scores, combines candidates with weighted reciprocal rank fusion, reranks them, scores "fun" or viral takes, and clusters related evidence.

That architecture is stronger than a simple "search each source then concatenate" approach.

### Credential and Runtime Flexibility

Zero-config sources include Reddit public JSON, Hacker News, Polymarket, and usually GitHub if the `gh` CLI is present. Optional integrations use environment variables, config files, browser cookies, macOS Keychain, local CLIs, or third-party APIs.

The project documents this honestly, and it includes permission checks, config tests, and source availability diagnostics.

### HTML Brief Export

`--emit=html` produces a self-contained, shareable brief. That is a practical feature for passing research into Slack, email, Notion, or local archives without leaking raw debug dumps.

## Architecture

The repo is organized as an installable skill plus an engine:

- `skills/last30days/SKILL.md` defines routing, behavior, permissions, and output contracts.
- `skills/last30days/scripts/last30days.py` is the CLI entry point.
- `skills/last30days/scripts/lib/pipeline.py` orchestrates source planning, retrieval, scoring, reranking, clustering, and report construction.
- `skills/last30days/scripts/lib/schema.py` defines normalized reports, candidates, clusters, source items, query plans, and provider runtime objects.
- `skills/last30days/scripts/lib/*` contains source adapters and support modules.
- `tests/` is broad and active.
- `CONFIGURATION.md`, `CHANGELOG.md`, and `AGENTS.md` document install, security, and contributor constraints.

Validation on this review:

- `uv run pytest` passed: 1,617 tests, 4 skipped, 2 subtests passed.
- Basic secret scan found documented placeholders, fixtures, and test tokens, not obvious live credentials.

## Comparison

| Aspect | last30days-skill | Generic Web Search | NotebookLM-style RAG | Social Listening SaaS |
|--------|------------------|--------------------|----------------------|-----------------------|
| Primary value | Recent social/market/developer signal synthesis | Editorial/web pages | User-provided docs | Brand/channel monitoring |
| Source control | User brings keys/cookies/tools | Search provider decides | User uploads sources | Vendor integrations |
| Agent integration | Skill-native | Usually external tool | App/API dependent | Usually dashboard/API |
| Output | Grounded brief + raw artifacts + HTML | Search results/snippets | Notebook answers | Dashboards/alerts |
| Main risk | Local credential/cookie access | SEO/editor bias | Stale/private corpus only | Cost/vendor lock-in |

## Self-Hosting Notes

Install via the target skill host or run the Python engine directly. Keep the trust boundary clear:

- Review `SKILL.md` before installing, because it instructs the host model and can write local artifacts.
- Store optional credentials in a controlled config location or keychain.
- Avoid installing in environments where browser cookies or API keys should never be read.
- Use `EXCLUDE_SOURCES` and `INCLUDE_SOURCES` to shape what the tool can query.
- Treat fetched social content as untrusted data, especially when synthesizing into agent workflows.

---

**Attribution:** mvanhorn/last30days-skill, MIT.
