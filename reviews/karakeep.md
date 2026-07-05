# Karakeep (karakeep-app/karakeep)

**Repo:** https://github.com/karakeep-app/karakeep
**License:** AGPL-3.0. Safe to study and self-host; code reuse and network-service modifications carry AGPL obligations.
**Reviewed:** 2026-07-05
**Stack:** Next.js 16, React 19, TypeScript, Drizzle, SQLite, NextAuth, tRPC/Hono, Meilisearch, Playwright/Chrome, Tesseract, OpenAI/Ollama, Expo/React Native, browser extensions, CLI, MCP
**What it is:** A self-hostable bookmark-everything/read-it-later system for links, notes, images, PDFs, video, RSS, full-text search, and AI-assisted tagging/summarization.

---

## Verdict

✅ **Deploy candidate for self-hosted personal or team knowledge capture, with AGPL and crawler-isolation caveats.** Karakeep is much more than a bookmark UI: it has a real ingestion pipeline, background workers, mobile and browser clients, scoped API keys, OpenAPI/SDK/CLI/MCP surfaces, and active CI/release work. Treat it as internet-content processing infrastructure, not a harmless note app, because it runs browser crawls, archival tools, OCR, video download, webhooks, and optional LLM inference over untrusted URLs.

---

## What It Is

Karakeep, formerly Hoarder, is a self-hostable app for saving "anything" into a searchable personal archive. It supports link bookmarks, text notes, images, PDFs, full page archives, screenshots, highlights, RSS imports, browser extensions, mobile apps, REST clients, rules, lists, and collaboration.

Its strongest current shape is a local-first knowledge capture system. A saved URL can become a structured bookmark with fetched title/description/image metadata, readable content, screenshot/PDF/full-page archive assets, OCR output, search index entries, embeddings, inferred tags, summaries, webhooks, and optional video assets. That is a serious pipeline, and it makes the project relevant to both human read-it-later workflows and agent-driven knowledge management.

The project also exposes agent-friendly interfaces: an official CLI, SDK, OpenAPI spec, MCP server, and skill documentation. That matters because a bookmark manager becomes much more useful when an agent can search, create, tag, list, and retrieve content through constrained tool contracts instead of scraping the web UI.

## Stack

| Layer | Tech |
|-------|------|
| Web app | Next.js 16 app router, React 19, TypeScript, Tailwind CSS, Radix UI |
| API | Hono REST API, tRPC routers, generated OpenAPI/SDK |
| Auth | NextAuth, credentials, OAuth/OIDC, API keys with scopes, optional Turnstile/email verification |
| Database | SQLite via Drizzle and better-sqlite3, 80+ migrations |
| Search | Meilisearch, optional vector index support |
| Workers | Node workers, Liteque/ReState queue plugins, cron, webhooks |
| Crawling | Playwright/Chrome, adblocker, Readability/metascraper, monolith, yt-dlp |
| Document/media processing | Tesseract OCR, pdfjs/pdf2json/pdf2pic, ffmpeg, GraphicsMagick, Ghostscript |
| AI | OpenAI-compatible providers and local Ollama for tagging, summarization, OCR assist, embeddings |
| Clients | Web app, Expo/React Native mobile app, browser extension, CLI, MCP server |
| Deployment | Multi-target Dockerfile, Docker Compose, GHCR images, GitHub Actions releases |

## Key Features

### Bookmark-Everything Capture

Karakeep handles links, notes, images, PDFs, highlights, RSS feeds, and imports. The worker pipeline can fetch metadata, parse readable text, capture screenshots, archive full pages, store PDFs, run OCR, download videos, and keep assets under storage quotas.

The useful pattern is not any single crawler component; it is the staged capture model. A lightweight bookmark row becomes the coordination point for many optional enrichment jobs.

### Search, Tags, Lists, and Rules

The app combines full-text search, tag filters, list membership, smart-list queries, favorites, archives, and rule-based automation. This makes it closer to a small personal knowledge base than a simple browser-bookmark replacement.

The search query language and official skill docs are especially useful for agents because they give a compact way to ask for "saved things matching this condition" without loading the whole archive.

### Scoped Agent and API Surface

Karakeep ships REST/OpenAPI, SDK, CLI, and MCP surfaces. API keys have key IDs, hashed secrets, scopes, last-used tracking, and admin-only scope handling. The MCP server exposes bookmark/list/tag tools, including destructive operations with explicit tool descriptions.

That is the right direction for agent access: prefer scoped API keys and typed tools over sharing a browser session.

### Crawler Hardening

The crawler validates URL schemes, blocks private/internal/link-local/reserved IP ranges by default, validates DNS-resolved addresses, checks redirects, guards browser subrequests, supports explicit internal-host allowlists, and has optional domain rate limiting. It also documents a real limitation: `yt-dlp` performs its own network requests, so full SSRF protection for video download depends on egress proxying or network policy.

This is an unusually honest posture for a self-hosted content crawler. It does not remove the need for isolation, but it shows the maintainers are thinking about the right failure modes.

### Broad Product Surface

The repo includes the web app, workers, CLI, MCP server, SDK, browser extension, mobile apps, docs, landing page, CI, Docker packaging, security policy, and release workflows. That breadth is a strength for users and a maintenance cost for operators.

## Architecture

Karakeep is a pnpm/Turbo monorepo. Apps live under `apps/`, shared packages under `packages/`, and deployment assets under `docker/`. The split is practical: web, workers, CLI, MCP, mobile, browser extension, SDK, shared types, database schema, API routes, and plugin adapters each have a clear home.

The central architectural idea is asynchronous enrichment. Bookmark creation is fast, while crawling, parsing, search indexing, inference, embeddings, video download, webhooks, and admin maintenance happen in workers. Status fields on bookmark/link rows preserve progress and failure state.

The deployment model is also clear. The all-in-one Docker target bundles the web app and worker stack, with Meilisearch and Chrome as companion services in Compose. Separate Docker targets exist for web, workers, CLI, and MCP when operators want finer boundaries.

## Comparison

| Aspect | Karakeep | Wallabag | Linkwarden | Omnivore |
|--------|----------|----------|------------|----------|
| Primary job | Bookmark-everything archive with AI and agents | Read-it-later/article archival | Collaborative bookmark manager | Hosted/read-it-later archive, now discontinued upstream |
| AI posture | First-class tagging, summarization, embeddings, OCR assist | Not the main focus | Some AI-oriented/self-hosted workflows depending on version | Historically product-specific |
| Agent surface | CLI, SDK, MCP, skill docs, API keys | API, but less agent-native | API and integrations | Less relevant for new self-hosted deployment |
| Capture breadth | Links, notes, images, PDFs, RSS, video, full-page archive | Mostly web articles/pages | Links/bookmarks, collections | Articles/pages/highlights |
| Main caveat | AGPL and untrusted-content crawler isolation | Older PHP stack tradeoffs | Scope depends on deployment | Project continuity/self-hosting story |

Karakeep is the strongest reviewed candidate so far for a self-hosted, agent-accessible personal web archive. It is heavier than a minimalist read-it-later app, but the extra surface buys search, automation, client coverage, and agent integration.

## Self-Hosting Notes

The default Docker Compose stack runs the Karakeep image, Chrome, and Meilisearch. Operators must set the app URL and auth secret, keep signups/password/OAuth/email settings deliberate, and persist `/data` plus Meilisearch data.

Important deployment cautions:

- Keep Chrome DevTools/CDP private. The sample Chrome service is not port-mapped, which is good; do not expose it directly.
- Treat the worker network as untrusted-content processing. It visits arbitrary URLs and may run browser, archive, OCR, and video tooling.
- Prefer egress controls for crawler/video workers, especially if enabling video download or full-page archive.
- Leave internal hostname allowlists empty unless you truly intend to crawl internal services.
- Configure rate limiting, signup controls, storage quotas, and API-key scopes before multi-user exposure.
- Review AGPL obligations before modifying and offering the app as a network service.

## Caveats

- The repo describes itself as under heavy development and has hundreds of open issues.
- AGPL-3.0 is a strong copyleft license; do not copy code into proprietary systems casually.
- The crawler surface is inherently sensitive because it fetches attacker-controlled content and can invoke Chrome, monolith, OCR, PDF tools, and `yt-dlp`.
- Rate limiting is optional and off by default in config.
- OAuth sign-in includes a source TODO noting that OAuth providers are trusted to validate email.
- Full local install/test was not run for this review because the monorepo is large and already has broad CI coverage.

## Verification

- Shallow cloned `https://github.com/karakeep-app/karakeep.git` on 2026-07-05.
- Current commit: `aa78aa8f376e38864cadd14e2da661d7b9d1066e`.
- GitHub metadata: 26,551 stars, 1,299 forks, 589 open issues, latest push 2026-07-05.
- Latest release observed: `v0.32.0`; current checkout tag observed: `mcp/v0.32.1`.
- Reviewed README, LICENSE, SECURITY, AGENTS, Dockerfile/Compose, package manifests, CI/release workflows, database schema, config, auth, API key handling, crawler/network code, video worker notes, CLI, SDK, MCP server, and official skill docs.
- Confirmed pnpm version: 11.2.1.
- Did not run full tests or install dependencies in the fresh clone.

---

**Attribution:** karakeep-app/karakeep, AGPL-3.0 License.
