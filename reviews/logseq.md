# logseq/logseq Review

- Source: https://github.com/logseq/logseq
- Author: Logseq
- License: AGPL-3.0
- Reviewed: 2026-08-09
- Verdict: ✅ Deploy candidate

## Summary

Logseq is a privacy-first, local-first knowledge graph and outliner for personal knowledge management and collaboration. It supports Markdown and Org-mode graphs, backlinks, queries, tasks, PDF annotation, plugins/themes, desktop/mobile/web targets, sync/RTC work, a CLI, and a local desktop MCP server.

This is a mature project with a large user base and active development: about 44k stars, 2.7k forks, recent commits, broad CI, and a July 2026 `2.0.1` desktop beta release. The strongest fit is using Logseq as an app or studying its architecture. The two big caveats are license and operational maturity: the repo is AGPL-3.0, and the README explicitly warns that DB graphs, mobile, and RTC features are beta/alpha and can lose data.

## What It Is

Logseq is a Clojure/ClojureScript application centered on block-based notes and graph relationships. The current architecture spans:

- Electron desktop app with React UI
- Mobile app through Capacitor
- Web/static publishing targets
- DataScript for in-memory graph work
- SQLite, `sqlite-wasm`, and `better-sqlite3` for DB graph storage
- Shadow CLJS builds for app, mobile, Electron, publishing, and DB workers
- Cloudflare Worker and Node adapters for DB sync
- Plugin/theme ecosystem
- Local CLI and MCP surfaces for agent/tool access

The project is unusually relevant to agent-operated knowledge systems because it has first-party structured interfaces. The repo includes a Logseq CLI skill, CLI commands for graph inspection/editing, an `agent bridge` mode, and a local MCP server with tools for listing pages, reading pages, upserting nodes, searching blocks, listing tags, and listing properties.

## Architecture Notes

The codebase is split into several local Clojure/ClojureScript dependency areas, including `deps/db`, `deps/db-sync`, `deps/graph-parser`, `deps/outliner`, `deps/common`, `deps/publishing`, and `deps/shui`.

The DB layer is the most interesting part. `deps/db` describes the core API for frontend DataScript graphs and backend SQLite DB graphs, with compatibility for ClojureScript and `nbb-logseq`. The sync package adds Cloudflare Worker and Node.js adapters, D1 migrations, administrative graph operations, and documented protocol work.

The Electron posture is better than many desktop apps: `nodeIntegration` is disabled, `contextIsolation` is enabled, production `webSecurity` is enabled, and external URL opening is constrained to expected protocols. The main remaining desktop trust boundaries are the disabled Electron sandbox, plugins, local API/MCP exposure, sync, and imported content.

The GitHub workflows are broad. CI covers Clojure tests, ClojureScript tests, CLI E2E tests, linting, worker/frontend separation checks, DB graph tests, and desktop release checks. That said, recent dependency/security automation shows failures, and dependency audit output needs attention.

## Security And Maintenance

Observed risk areas:

- The README warns that DB graphs are beta and recommends backups, test graphs, and non-crucial projects.
- `pnpm audit --prod` reported 2 critical, 21 high, 25 moderate, and 5 low advisories at review time.
- Notable advisories appeared around packages such as `posthog-js`, `dompurify`, `hono` through MCP SDK paths, tar/canvas/pdfjs-related chains, `fast-uri`, and `yargs-parser`.
- The plugin ecosystem and GitHub-release install flow are powerful but are also a major trust boundary.
- The MCP/local server surface is useful, but it should be treated like a local automation API with access to private notes.
- The Dockerfile's nginx base is old and appears secondary to the desktop/web build story.

None of these are automatic blockers for personal use, but they do argue for conservative deployment: keep backups, avoid beta DB graphs for irreplaceable data, install only trusted plugins, and review local API/MCP exposure.

## License Notes

The project is AGPL-3.0. That is fine for using, studying, or contributing to Logseq, and fine for AGPL-compatible forks. It is not a casual source of code snippets for proprietary software. Prefer documenting patterns and architectural lessons rather than copying implementation.

## Verdict

✅ Deploy candidate, with caveats.

Use Logseq as a private knowledge-management app if its workflow fits, especially with the stable file-graph path and a real backup routine. Treat DB graphs, RTC, and mobile alpha/beta paths as test-graph territory until the project marks them stable. As a research target, the CLI/MCP/agent bridge work and the DataScript-to-SQLite DB graph architecture are the most valuable pieces to study.
