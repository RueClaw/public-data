# Policy-Gated Social Intelligence CLI

**Source:** [0xNyk/xint](https://github.com/0xNyk/xint)
**License:** MIT
**Extracted:** 2026-07-05

## Problem

Agents often need current social-platform context: what people are saying, which posts are spreading, who is reacting, and whether sentiment is shifting. Direct API access is risky because the same credential surface can read private user context, spend money per request, and perform public actions.

## Pattern

Wrap social-platform APIs in a local CLI or MCP server that makes authority explicit:

1. **Split capability modes.** Classify tools as `read_only`, `engagement`, or `moderation`. Run agents in read-only mode by default and require explicit opt-in for likes, follows, blocks, mutes, bookmarks, or posts.
2. **Expose cost before action.** Track per-operation rates, show estimated spend, provide dry-run previews for expensive commands, and fail closed when a daily budget is exceeded.
3. **Prefer structured output.** Return JSON, JSONL, CSV, Markdown, or MCP envelopes instead of terminal-only prose so downstream agents can cite and filter results.
4. **Keep servers local by default.** Use stdio or loopback binds. Refuse non-loopback HTTP/SSE binds unless bearer auth is configured.
5. **Gate outbound webhooks.** Require HTTPS for remote webhook destinations, reject embedded URL credentials, block private/link-local/cloud-metadata IP ranges unless explicitly allowlisted, and allow host allowlists.
6. **Make credentials visible in metadata, not logs.** Document required env vars and file writes. Never echo bearer/OAuth/API tokens in outputs.
7. **Use local state deliberately.** Cache search results, exports, OAuth tokens, cost ledgers, and snapshots in scoped local directories with restrictive permissions for token files.
8. **Harden release paths.** Verify installer checksums, block committed `.env` files in CI, and fail CI on dynamic-eval/backdoor patterns.

## Why It Works

Social APIs combine three risky properties: public side effects, paid metering, and sensitive account context. A policy-gated CLI turns those into explicit tool contracts that an agent runtime can reason about.

The important design move is separating "the API can do this" from "this agent is allowed to do this now." Read-only research, engagement actions, and moderation actions should never share the same default authority.

## Good Fit

- X/Twitter, Reddit, GitHub, or Discord research tools
- OSINT and market-intelligence agents
- MCP servers exposing paid APIs
- Agent skills that can optionally perform public actions
- Local-first tools with sensitive OAuth tokens

## Bad Fit

- Fully hosted multi-tenant tools without stronger server-side tenancy
- Anonymous scraping tools with unstable upstream behavior
- Workflows where public posting must be human-authored
- Platforms whose terms prohibit automation for the intended use

## Implementation Notes

- Keep read-only mode useful enough that most research never needs higher authority.
- Use dry-run previews for high-volume reads and archive/full-history queries.
- Store raw exports as sensitive local artifacts; social search queries can reveal intent.
- Do not let webhook URL validation rely only on scheme checks; private-network SSRF is still a problem over HTTPS.
- Treat AI-generated engagement drafts as drafts unless the user explicitly authorizes execution.

---

**Attribution:** Extracted from 0xNyk/xint, especially `xint.ts`, `lib/mcp.ts`, `lib/costs.ts`, `lib/webhook-security.ts`, `lib/package_api_server.ts`, `install.sh`, and `.github/workflows/ci.yml`. MIT License.
