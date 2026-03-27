# seo-geo-claude-skills (aaron-he-zhu/seo-geo-claude-skills)

*Review #269 | Source: https://github.com/aaron-he-zhu/seo-geo-claude-skills | License: Apache 2.0 | Author: Aaron He Zhu | Version: 3.0.1 | Reviewed: 2026-03-26*

## Rating: 🔥🔥🔥🔥

---

## What It Is

20 Claude Code skills + 9 slash commands covering the full SEO + GEO (Generative Engine Optimization) workflow. "SEO" = traditional search rankings. "GEO" = getting cited by AI systems (ChatGPT, Perplexity, Google AI Overviews, Gemini). The library covers both, with dedicated skills for making content quotable by LLMs.

Apache 2.0. Works tool-agnostic (no external API required) or wired to Ahrefs/SEMrush/GA via CONNECTORS.md placeholders. Compatible with Claude Code, OpenClaw (listed on ClawHub), Codex, Cursor, and 35+ agents via skills.sh marketplace.

---

## Skill Inventory

**Research (4):** `keyword-research`, `competitor-analysis`, `serp-analysis`, `content-gap-analysis`

**Build (4):** `seo-content-writer`, `geo-content-optimizer`, `meta-tags-optimizer`, `schema-markup-generator`

**Optimize (4):** `on-page-seo-auditor`, `technical-seo-checker`, `internal-linking-optimizer`, `content-refresher`

**Monitor (4):** `rank-tracker`, `backlink-analyzer`, `performance-reporter`, `alert-manager`

**Cross-cutting (4):** `content-quality-auditor` (80-item CORE-EEAT), `domain-authority-auditor` (40-item CITE), `entity-optimizer`, `memory-management`

**Commands (9):** `/seo:audit-page`, `/seo:check-technical`, `/seo:generate-schema`, `/seo:optimize-meta`, `/seo:report`, `/seo:audit-domain`, `/seo:write-content`, `/seo:keyword-research`, `/seo:setup-alert`

---

## What's Notable

### GEO as a First-Class Concept

The `geo-content-optimizer` skill is the interesting piece — it's specifically for making content quotable by AI systems, not just Google-rankable. Targets: precise statistics with source citations, quotable declarative statements, structured Q&A format, FAQ schema, expert attribution. The rationale is correct: as AI increasingly answers queries directly, getting cited in those answers is a separate optimization problem from traditional SEO.

### CORE-EEAT Framework (80-item audit)

The `content-quality-auditor` runs against a proprietary 80-item benchmark called CORE-EEAT across dimensions: **C**ompleteness (C01-C10), **O**rganization (O01-O10), **R**elevance (R01-R10), **E**xclusivity (E01-E10), **Exp**erience (Exp01-Exp10), **Ept** (Expertise, Ept01-Ept10), **A**uthority (A01-A10), **T**rust (T01-T10). Full item reference table in the reference files. Dimension scoring, veto checks, weighted final score.

### CITE Domain Rating (40-item audit)

`domain-authority-auditor` runs a parallel 40-item framework called CITE with "veto checks" — conditions that can override the numeric score regardless of aggregate. Domain-type weighting (e-commerce vs. publisher vs. SaaS scored differently).

### Memory Management as a Skill

`memory-management` implements a two-layer hot cache + cold storage pattern for persisting SEO campaign context across sessions. Hot cache in CLAUDE.md (in-context, auto-loaded), cold storage for archival. Promotion/demotion rules, glossary templates. When active, other skills check the cache before re-running audits. Domain-specific application of a general pattern — same idea as Ori-Mnemos but scoped to SEO campaigns.

### Inter-Skill Handoff Protocol

The README documents a formal handoff protocol for passing context between skills: how to pass target keywords, CORE-EEAT scores (with specific item IDs like "improve O08, E07, R06"), CITE scores, content type. This is the right design for multi-skill workflows — structured handoffs rather than vague "see previous results."

### Entity Optimization

`entity-optimizer` handles Knowledge Graph presence, Wikidata, and AI system entity recognition — separate from content optimization. Includes a `knowledge-panel-wikidata-guide.md` reference for getting brand entities into Wikidata correctly.

---

## Honest Assessment

**The GEO angle is real.** Getting cited in AI Overviews vs. traditional search ranking are genuinely different problems with different techniques. That this library treats them separately and has dedicated tooling for each is the right call.

**The frameworks (CORE-EEAT, CITE) are proprietary scaffolding** — not academic standards, but well-structured rubrics that force systematic coverage. The 80-item CORE-EEAT is more comprehensive than most content audits I've seen. Whether the scoring weights are calibrated correctly is unknowable without data, but the item coverage is solid.

**Tool-agnostic is both a strength and a limitation.** Without Ahrefs/SEMrush/GSC integration, the skills work as structured prompting frameworks rather than data-driven tools. The CONNECTORS.md placeholder approach is the right design — use what you have, upgrade when you need real data.

**No license issues.** Apache 2.0, straightforward attribution.

---

## Relevance

**Direct use case:** mrchuck's marines.bluesun.net WordPress site. Running `/seo:audit-page` on it would give structured recommendations. The GEO angle is also relevant for any content site that wants visibility in AI answers.

**The `geo-content-optimizer` skill** is worth understanding for the research channel — the techniques for making content quotable by AI (precise stats, declarative quotable statements, FAQ schema, structured Q&A) are exactly the same techniques that make content good for RAG retrieval. The GEO optimization literature and the RAG optimization literature are converging.

**The memory-management skill pattern** — hot cache in CLAUDE.md, cold storage for archival, promotion/demotion rules — is directly stealable for any domain-specific agent that needs project context persistence.
