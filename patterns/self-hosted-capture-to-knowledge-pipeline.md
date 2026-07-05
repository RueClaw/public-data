# Self-Hosted Capture-to-Knowledge Pipeline

**Source:** [karakeep-app/karakeep](https://github.com/karakeep-app/karakeep)
**License:** AGPL-3.0
**Extracted:** 2026-07-05

## Problem

Saved links and files are cheap to collect but expensive to make useful. A bookmark manager that only stores URLs quickly becomes a graveyard. A knowledge system needs content extraction, screenshots, archives, search, tags, summaries, OCR, rules, and APIs, but doing all of that synchronously makes the save path slow and brittle.

## Pattern

Use the bookmark record as a durable coordination point, then enrich it asynchronously:

1. **Accept quickly.** Create a minimal bookmark/note/asset row with owner, type, source URL or content, created time, and initial status fields.
2. **Probe before heavy crawl.** Fetch enough metadata to classify the target as webpage, PDF, image, text, or unsupported content.
3. **Fan out through workers.** Queue crawler, parser, search, inference, embedding, webhook, video, asset preprocessing, and maintenance jobs separately.
4. **Store assets by type.** Keep screenshots, PDFs, archived pages, images, OCR text, readable HTML, and videos as explicit assets with sizes, content types, and ownership.
5. **Track status per enrichment.** Use independent status fields for crawling, tagging, summarization, embedding, and indexing so partial success remains useful.
6. **Index after content lands.** Feed text, metadata, tags, lists, and optional vectors into search as a follow-up job instead of blocking save.
7. **Make automation declarative.** Apply rules, smart lists, tags, webhooks, and API clients on top of the enriched bookmark state.
8. **Expose constrained agent tools.** Provide typed API/CLI/MCP operations for search, create, update, tag, list, and retrieve content with scoped credentials.
9. **Isolate untrusted content work.** Keep browser/crawler/archive/video/OCR workers behind private networks, timeouts, quotas, egress policy, and explicit internal-host allowlists.

## Why It Works

The user-facing action is "save this," but the system-facing work is a pipeline. Splitting the pipeline means the app can preserve a useful record even when a screenshot fails, a model times out, an archive tool crashes, or search indexing lags.

This also gives agents a better surface. Agents can ask for bookmarks by search/list/tag/status, inspect content when needed, and create new items without needing permission to run the whole crawler directly.

## Good Fit

- Self-hosted bookmark/read-it-later systems
- Personal knowledge bases with web capture
- Research vault ingestion
- Agent-accessible archives
- Compliance or investigation notebooks that need provenance and search
- Local-first apps that enrich untrusted web content

## Bad Fit

- Tiny bookmark lists where browser bookmarks are enough
- Hosted multi-tenant services without strong worker isolation
- Systems that cannot tolerate delayed enrichment
- Environments where AGPL-derived implementation reuse is not acceptable
- Workflows that need legally robust archival guarantees

## Implementation Notes

- Keep the initial save path narrow and reliable.
- Treat crawler/browser/video workers as a security boundary, not just background jobs.
- Validate URLs, redirects, DNS-resolved addresses, and browser subrequests.
- Do not expose browser debugging endpoints.
- Store raw captured content and screenshots as sensitive user data.
- Make destructive tool actions explicit in CLI/MCP descriptions.
- Keep API keys scoped and track last use.
- Use storage quotas before saving derived assets; enrichment can multiply data size.
- Keep AI tagging/summarization optional and provider-configurable.

---

**Attribution:** Extracted from karakeep-app/karakeep, especially the README, `apps/workers`, `packages/db/schema.ts`, `packages/trpc`, `packages/open-api`, `apps/cli`, `apps/mcp`, and `docker/`. AGPL-3.0 License. This pattern is prose only and does not embed Karakeep code.
