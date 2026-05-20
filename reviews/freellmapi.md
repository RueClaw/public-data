# FreeLLMAPI (tashfeenahmed/freellmapi)

**Repo:** https://github.com/tashfeenahmed/freellmapi
**License:** MIT - permissive reuse with attribution
**Reviewed:** 2026-05-20
**Stack:** TypeScript, Node.js, Express, SQLite, React, Vite, Tailwind/shadcn-style UI, Vitest
**What it is:** A self-hosted, OpenAI-compatible proxy that routes one chat-completions endpoint across many free-tier LLM providers, with key management, fallback routing, streaming, tool calls, and a local dashboard.

---

## Verdict

⚠️ **Interesting local proxy, not a production substrate.** FreeLLMAPI is a polished single-user experiment for stretching free LLM quotas behind one OpenAI-shaped API. The implementation is more serious than the premise sounds, with encrypted key storage, fallback routing, health checks, and a real test suite, but the value depends on unstable provider free tiers and ToS boundaries.

---

## What It Is

FreeLLMAPI aggregates free inference quotas from providers such as Google, Groq, Cerebras, SambaNova, Mistral, OpenRouter, GitHub Models, Cohere, Cloudflare, Z.ai, Ollama Cloud, Pollinations, and LLM7. Clients call a local /v1/chat/completions endpoint with an OpenAI-compatible request, and the proxy chooses an available model/key from a configurable fallback chain.

The target user is an individual developer who wants a local inference router for experimentation, not a team or hosted API business. The README is explicit about this: there is no multi-tenant auth, no SLA, provider limits can change without notice, and the endpoint should not be exposed publicly.

The dashboard handles provider keys, fallback ordering, analytics, key health, and a playground. The server stores upstream keys in SQLite encrypted with AES-256-GCM and exposes a single generated freellmapi bearer token for non-local proxy calls.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Node.js 20+, Express 5, TypeScript |
| Frontend | React 19, Vite 8, Tailwind CSS, shadcn-style components |
| Database | SQLite via better-sqlite3 |
| Validation | Zod request schemas |
| Security helpers | helmet, AES-256-GCM key encryption, timing-safe API-key compare |
| Provider adapters | Custom Gemini, Cohere, Cloudflare adapters plus generic OpenAI-compatible adapter |
| Tests | Vitest server suite |

## Key Features

### OpenAI-Compatible Proxy

The core surface is intentionally narrow: GET /v1/models and POST /v1/chat/completions. That makes the tool easy to point at existing OpenAI-compatible clients while avoiding the complexity of embeddings, image, audio, vision, moderation, and legacy completion APIs.

### Fallback Routing

The router checks enabled models, healthy keys, cooldowns, request limits, token limits, and a user-configured fallback priority. When a provider returns a retryable failure such as a 429, timeout, or 5xx, the proxy cools down that model/key and tries the next viable route.

The useful design choice is that routing is key-aware, not just model-aware. Multiple keys for the same provider can be rotated, exhausted, and skipped independently.

### Sticky Sessions

For multi-turn conversations without an explicit model, the proxy hashes the first user message and tries to keep the conversation on the same model for 30 minutes. That is a pragmatic mitigation for the quality drop that happens when a conversation silently switches model families midstream.

### Provider-Specific Translation

Most providers are OpenAI-compatible enough to share an adapter, but Gemini, Cohere, and Cloudflare get custom handling. Gemini translation includes system-message mapping, function declarations, function responses, and preservation of thought signatures for multi-turn tool-calling.

### Local Dashboard

The dashboard is practical rather than decorative: keys, fallback chain, health, analytics, and a playground. It is meant as a local admin surface, not as a SaaS control plane.

## Architecture

The repo is a small TypeScript monorepo:

| Path | Role |
|------|------|
| server/src/routes/proxy.ts | OpenAI-compatible chat and model endpoints |
| server/src/services/router.ts | Model/key selection, dynamic 429 penalties, cooldown-aware routing |
| server/src/services/ratelimit.ts | In-memory RPM/RPD/TPM/TPD accounting |
| server/src/providers/*.ts | Provider adapters |
| server/src/db/index.ts | SQLite schema, migrations, model catalog, unified API key |
| client/src/pages/* | Admin dashboard pages |
| shared/types.ts | Shared model, key, fallback, and chat-completion types |

Security posture is reasonable for the stated local-only model. Upstream keys are encrypted before storage, non-local proxy requests require the unified bearer token, and the API-key comparison is timing-safe. The project also documents that CORS is open, CSP/HSTS are disabled, and localhost access has an auth bypass, which is acceptable only if the server stays private.

The sharp edge is deployment: the server listens on 0.0.0.0, dashboard/admin routes are not independently authenticated, and cors() is unrestricted. That combination is fine on a trusted LAN or loopback-only reverse proxy, but it is a bad shape for internet exposure.

## Comparison

| Aspect | FreeLLMAPI | LiteLLM | OpenRouter |
|--------|------------|---------|------------|
| Primary goal | Stack personal free-tier quotas locally | Production-grade provider abstraction and gateway | Hosted multi-provider model marketplace |
| Deployment | Self-hosted single-user Node app | Self-hosted or managed | Hosted service |
| Admin UI | Built in | Available in broader platform setups | Hosted dashboard |
| Free-tier strategy | Explicitly optimized around no-card/free quotas | Provider-agnostic; not free-tier focused | Has free routes, but still a hosted intermediary |
| Production fit | Low | High | Medium to high, depending on use |

FreeLLMAPI is more of a quota-aware personal router than a general gateway. That is its strength and its ceiling.

## Self-Hosting Notes

Use it locally or behind a private network boundary. Do not expose the admin surface directly to the internet. If deployed on a LAN, bind carefully, add a reverse proxy with access controls, and treat the SQLite database as a secret because it contains encrypted upstream keys and the stored encryption material unless ENCRYPTION_KEY is supplied externally.

Verification notes from review:

- npm install completed, but npm reported 7 production vulnerabilities: 2 high and 5 moderate.
- npm test ran the server suite successfully: 14 files, 98 tests passed. The root test command then failed because the client workspace has no test script.
- npm run build passed for both server and client. Vite warned that the client bundle is larger than 500 kB after minification.

---

**Attribution:** tashfeenahmed/freellmapi, MIT
