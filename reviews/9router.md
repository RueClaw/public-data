# 9Router Review

- **Source:** https://github.com/decolua/9router
- **Author:** decolua and contributors
- **License:** MIT
- **Reviewed:** 2026-05-19
- **Verdict:** ⚠️ Interesting

## Summary

9Router is a local AI routing gateway and dashboard for coding tools. It exposes OpenAI-compatible API routes on a local server, then translates requests across many upstream provider shapes including Claude, OpenAI-compatible APIs, Gemini-style routes, Cursor/VS Code toolchains, and several provider-specific OAuth/API-key flows.

The project is much larger than a simple proxy. It includes a Next.js dashboard, CLI install flow, Docker deployment, provider/account management, quota and usage tracking, model aliases, fallback chains, request translation, token refresh, local database state, tunnel helpers, MCP surfaces, and a token-saving layer called RTK.

The strongest idea is not merely "route to many providers"; it is treating local AI tooling as a programmable edge appliance with account selection, format translation, observability, and preflight request shaping before the model provider ever sees the request.

## What It Does

- Runs a local API gateway at `localhost:20128` with OpenAI-compatible `/v1` endpoints.
- Provides a dashboard for managing providers, keys, OAuth connections, model aliases, combos, usage, quota, and CLI tool setup.
- Supports many coding clients and agent tools, including Claude Code, Codex, Cursor, Copilot, Cline, Gemini CLI, OpenCode, OpenClaw, and related tools.
- Routes across 40+ providers / 100+ models according to the README.
- Implements fallback and quota-aware account selection.
- Tracks request logs, usage stats, provider availability, and pricing configuration.
- Ships CLI, Docker, and local app modes.
- Includes optional MITM and tunnel helpers for tools that need host-level interception or remote access.

## Architecture Notes

The implementation is a Next.js app with a Node-oriented runtime surface. Public routing and management endpoints live under the `src/app/api/` route tree; the shared streaming and translation core is under `open-sse/`.

Important modules:

- `open-sse/index.js` wires request handling, provider selection, translation, and streaming behavior.
- `open-sse/handlers/chatCore.js` contains much of the chat/completion request core.
- `open-sse/services/combo.js` handles multi-provider combo routing and fallback.
- `open-sse/rtk/` contains the tool-result compression layer.
- `src/dashboardGuard.js` protects dashboard and management routes.
- `src/app/api/v1/` implements OpenAI-compatible endpoints.
- `src/lib/db*.js` and related modules handle local SQLite/sql.js-backed state.
- `src/lib/mitm*.js` handles local MITM support.

The app distinguishes between public LLM proxy routes and protected management routes. Management APIs are gated by local/CLI/API-key/JWT checks, while host-sensitive actions such as tunnel, MCP, OAuth auto-import, and MITM-related paths receive additional local-only restrictions.

## Strong Patterns

### Provider Translation As A Local Control Plane

9Router sits between tools and providers, which gives it a place to normalize request/response formats, select accounts, retry or fallback across providers, track quota, and apply local policy. This is useful for coding-agent stacks because clients can stay configured against one stable local endpoint while provider details change behind it.

### RTK Tool Result Compression

The standout reusable pattern is RTK: compressing verbose tool outputs before forwarding a request upstream. It detects shapes such as Claude `tool_result`, OpenAI tool messages, OpenAI Responses `function_call_output`, and Kiro-style tool-result structures. It then applies filters for known noisy formats such as git diffs, git status, grep output, file listings, tree output, find output, build logs, and repeated logs.

The important safety choices:

- Skip error tool results so debugging traces are preserved.
- Do not process very small or overly large raw content.
- Auto-detect a filter rather than forcing every output through one reducer.
- Never replace content with an empty result.
- Never keep a compressed result if it is larger than the input.
- Track bytes before/after and log which filters saved tokens.

See extracted pattern: [`patterns/rtk-tool-result-compression.md`](../patterns/rtk-tool-result-compression.md).

### Dashboard Guard For Local Appliances

`src/dashboardGuard.js` is worth reading because the project is explicit about which paths are public LLM API paths, which are always protected, and which require local-only or CLI-token access. That is the correct direction for a local secrets appliance, even though this project still needs careful deployment.

## Risks

9Router handles provider credentials, OAuth tokens, local config, request logs, optional tunnel exposure, and optional MITM behavior. That makes it security-sensitive by nature. The project appears conscious of those risks, but deployment should still be treated like installing a local credentials gateway, not like installing a harmless UI.

Particular areas to review before serious use:

- MITM support, certificate handling, DNS changes, and privileged operations.
- OAuth import flows and token storage.
- Tunnel exposure and any path reachable from non-loopback interfaces.
- Request/response logging defaults and redaction behavior.
- Provider fallback behavior when requests include private data.
- Dashboard authentication defaults.

## Verification

Local verification on 2026-05-19:

- `npm run build` completed successfully with Next.js 16.2.6.
- Direct Vitest execution in `tests/` completed with `316 passed / 24 failed / 24 skipped`.
- The top-level `npm test` script failed because it hardcoded `/tmp/node_modules/.bin/vitest`, which was not present in the local checkout.
- `npm audit --omit=dev --audit-level=moderate` reported 4 moderate advisories, including `dompurify` via `monaco-editor` and `postcss` via `next`.

The failures look like a mix of missing test fixtures/dependencies and stale expectations around RTK, Cursor import, translator normalization, provider duplicate handling, and proxy-aware fetch behavior. That does not mean the app is unusable, but it does mean the test suite is not currently a clean reliability signal.

## Recommendation

Use 9Router as a study target or controlled local pilot, not as an unreviewed production gateway.

It is valuable for:

- Understanding how to build a local AI provider router.
- Studying provider/account fallback and quota management.
- Harvesting RTK-style tool-output compression.
- Studying guard patterns for local dashboards and host-sensitive APIs.

It needs more confidence before broad deployment:

- Clean test suite or documented test matrix.
- More explicit security documentation for MITM, tunnel, OAuth, and secret storage.
- Clear default hardening guidance.
- Audit dependency cleanup or documented accepted risk.

The project is substantial and actively maintained, but its blast radius is high enough that the correct posture is careful adoption.
