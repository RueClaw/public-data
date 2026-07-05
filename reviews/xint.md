# xint (0xNyk/xint)

**Repo:** https://github.com/0xNyk/xint
**License:** MIT. Safe to use, fork, and adapt with attribution.
**Reviewed:** 2026-07-05
**Stack:** TypeScript, Bun, X API v2, xAI/Grok APIs, MCP, OAuth 2.0 PKCE, local file-backed state
**What it is:** A terminal and MCP tool for searching, monitoring, analyzing, and selectively engaging with X/Twitter from agent workflows.

---

## Verdict

✅ **Deploy candidate for agent-assisted X/Twitter intelligence, with credential and cost guardrails.** xint is a real CLI, not just a prompt wrapper: it has typed API modules, MCP tools, OAuth flows, webhook/stream support, cost tracking, a TUI, CI, and a meaningful test suite. The July 2026 release also shows a serious hardening pass around network binds, billing webhooks, installer checksums, webhook SSRF, and CI security guards.

---

## What It Is

xint wraps X/Twitter and xAI workflows into a Bun-based command-line tool. It can search posts, read profiles, fetch threads, monitor queries, stream filtered events, inspect bookmarks/likes/following, download media, track follower diffs, generate sentiment and reports, fetch articles, run Grok analysis, and expose many of those functions as MCP tools.

The target user is an agent or researcher that needs recent social discourse without hand-writing API calls. The project positions itself as a spiritual successor to `twint`, but it is built around official APIs, prepaid X API credits, local cache/export directories, and machine-readable outputs such as JSON, JSONL, CSV, Markdown, and MCP envelopes.

The strongest current shape is "local social intelligence tool for agents": the CLI owns auth, cost tracking, output formatting, policy modes, and safety checks, while the calling agent asks higher-level research questions.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Bun 1.x, TypeScript ESM |
| CLI entry | `xint.ts` with command dispatcher and global policy mode |
| APIs | X API v2, xAI Chat/Responses/Search/Collections APIs |
| Auth | Bearer token for X API, OAuth 2.0 PKCE for user-context actions, xAI API keys |
| Agent integration | MCP stdio and optional HTTP/SSE mode |
| Local state | File-backed cache, exports, OAuth token file, cost ledger, snapshots, package API store |
| UI | Terminal output plus TUI helpers |
| Tests | Bun test, TypeScript typecheck, GitHub Actions CI/security guard |
| Release/install | Bash installer, checksum verification, Homebrew notes, release parity scripts |

## Key Features

### Agent-Friendly X Search

The core search/profile/thread/tweet flows return structured output and include agent-friendly details such as URLs, metrics, hashtags, mentions, pagination, and cost metadata. Search supports recent windows, sorting, server-side `min_likes:` when available, retweet/reply filtering, quick mode, and JSONL/CSV/Markdown export.

### MCP Surface

`lib/mcp.ts` exposes xint functions as MCP tools with schemas and a standard response envelope. The server supports local stdio by default and optional HTTP/SSE mode. Policy modes separate read-only, engagement, and moderation actions, and budget checks can block expensive tools.

### Cost Awareness

xint tracks X API and xAI costs, includes dry-run previews for expensive flows, and has current-model pricing updates in the changelog. This matters because X API pricing is per-resource and easy for agents to burn through accidentally.

### OAuth Write and Moderation Actions

The CLI includes bookmarks, likes, follows, lists, blocks, mutes, and engagement flows. That is useful but high-authority; the project handles this with OAuth-specific setup and policy gates instead of pretending all social actions are just reads.

### Security Hardening Pass

The 2026.7.5 changelog is unusually concrete:

- MCP SSE binds to `127.0.0.1` by default and refuses non-loopback binds without a bearer auth token.
- The package API server binds loopback by default and refuses non-loopback binds without configured API keys.
- Billing webhooks reject unsigned events unless `XINT_BILLING_WEBHOOK_SECRET` is configured.
- Webhook URLs require HTTPS for remote hosts, reject credentials, support host allowlists, and block private/link-local/cloud-metadata IP ranges unless explicitly allowlisted.
- The installer requires checksum verification by default.
- CI blocks tracked `.env` files, dynamic-eval implant patterns, and unexpected runtime dependencies.

## Architecture

The architecture is intentionally simple: one CLI entrypoint, many focused `lib/*` modules, and file-backed local state. That is a good fit for an agent skill because setup is inspectable and the runtime can be vendored or run locally without operating a hosted service.

The MCP implementation is the most reusable system piece. It defines tool schemas, policy requirements, budget-guarded tools, structured result envelopes, citation enforcement for package-query responses, and optional SSE auth. That turns a social API CLI into an agent-safe tool surface rather than a bag of shell commands.

The package API server is labeled development-only, but it is still treated as a sensitive local service: workspace scoping, plan/quota concepts, signed billing webhook ingestion, audit events, and refusal to bind publicly without auth.

## Comparison

| Aspect | xint | xurl | twint |
|--------|------|------|-------|
| Primary job | Agent-oriented X intelligence, monitoring, analysis, and MCP tools | Official-style X API CLI | Unofficial scraping/search |
| API model | Official X API + xAI APIs | Official X APIs | Scraping/guest endpoints, now archived |
| Agent posture | SKILL.md, MCP, policy modes, JSONL/CSV/Markdown outputs | Strong CLI and skill rules | Not agent-native |
| Write actions | OAuth engagement/moderation actions behind setup/policy | Broad official API support | Not the main focus |
| Main caveat | API cost/credential blast radius; repo docs drift | Verbose mode/header leakage caveat in prior review | Archived and brittle |

xint overlaps most with `xurl`, but it is more opinionated for agent research loops, Grok analysis, cost tracking, and MCP exposure.

## Self-Hosting Notes

The default mode is local CLI execution. Sensitive values are environment variables or local files under the project `data/` directory. For MCP stdio use, no inbound server is required.

If using HTTP/SSE MCP or the package API server, keep loopback defaults unless there is a strong reason to expose them. For non-loopback binds, configure long random bearer/API tokens and put the service behind a trusted private network boundary. Treat OAuth token files, exports, follower snapshots, and cost ledgers as sensitive local data.

## Caveats

- The README has a stale license section showing CC0, while `LICENSE`, `package.json`, and the badge say MIT.
- The README links to `docs/security.md`, but no `docs/` directory is present in this checkout.
- The install docs still show `curl | bash`; the installer has checksum verification, but the safer habit is still to inspect installer scripts before piping them to a shell.
- CI is now enabled for push/PR, but the changelog admits CI was workflow-dispatch-only before July 2026, which allowed a broken release with missing modules.
- Social API tools have high privacy, cost, and action-authority implications. Use read-only policy by default and explicitly opt into engagement/moderation.

## Verification

- Shallow cloned `https://github.com/0xNyk/xint.git` on 2026-07-05.
- Current commit: `b77683b96d8145b3e7ae7b7aa0f8c6fed064cbe0`.
- GitHub metadata: 179 stars, 13 forks, 0 open issues, latest push 2026-07-04.
- Latest release observed: `2026.7.5`.
- Ran `bun test`: 157 tests passed.
- Ran `bun install --frozen-lockfile && bun run typecheck`: passed. A pre-install `bun run typecheck` failed because `bun-types` and `@types/node` were not yet available in the fresh clone.

---

**Attribution:** 0xNyk/xint, MIT License.
