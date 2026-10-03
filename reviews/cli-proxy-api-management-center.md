# CLI Proxy API Management Center (router-for-me/Cli-Proxy-API-Management-Center)

**Repo:** https://github.com/router-for-me/Cli-Proxy-API-Management-Center (backend: https://github.com/router-for-me/CLIProxyAPI)  
**License:** MIT. Free to fork, modify and embed with the notice kept. No THIRD_PARTY_NOTICES file; bundled provider icons/logos (OpenAI, Claude, Gemini, Grok, sponsors) are vendor trademarks, not MIT content.  
**Reviewed:** 2026-10-03 (commit `ee79a79`, release v1.25.3)  
**Stack:** React 19, TypeScript 6, Vite 8 + `vite-plugin-singlefile`, Zustand, Axios, React Router 7 (hash routing), CodeMirror 6 (YAML + merge view), SCSS Modules, i18next. Bun 1.3.14 for install/test.  
**What it is:** The official web admin UI for CLIProxyAPI, a Go proxy that turns subscription coding-agent logins (Claude Code, Codex, Antigravity, Grok, Devin, Kimi…) into OpenAI/Gemini/Claude-compatible API endpoints. This repo is only the UI. It builds to one self-contained `management.html` that the backend serves at `/management.html` and that talks to the backend's v8 Management API.

---

## Verdict

⚠️ **Interesting. A well-built, heavily tested single-file admin SPA, but it has no standalone value: you adopt it only if you run CLIProxyAPI, and that decision carries the real risk (using consumer subscription credentials as a general API, which most of those providers' terms don't allow).**

What's good:
- **Single-file deployment done properly.** Everything (JS, CSS, icons) is inlined into one HTML file. The backend ships it as a release asset, so there's no separate frontend server, CDN or CORS setup. Hash routing keeps it working from any path.
- **Serious test discipline for a UI.** 153 test files (~18.7k lines) under `bun:test` cover config YAML round-tripping, concurrent-edit rebasing, quota parsing per provider, auth-file policy normalisation, and SSR-rendered markup checks. That's unusual for an admin panel.
- **Config editing is careful.** Visual and YAML editors share one document model, saves show a CodeMirror diff first, unsaved-change guards exist, and stale-request guards keep a previous connection's late responses from overwriting the new session.
- **Honest about client-side secret storage.** The "remember password" option is off by default. When it's on, the management key is XOR-obfuscated in localStorage, and both the README and the code say plainly that this is not encryption.
- **Plugin trust is surfaced.** Store entries outside `https://github.com/router-for-me/` get a red "Third-party" badge and an extra confirmation gate. The banner says plugins run inside the proxy and can read credentials and traffic.

What gives pause:
- **It's a satellite of a ToS-grey backend.** The backend's whole purpose is relaying subscription-plan CLIs (Claude Code, Codex, Antigravity, etc.) as an API. Account bans and terms violations are the main operational risk, and this UI's quota/reset-grant pages exist to manage exactly that pooling.
- **Plugin UI pages are unsandboxed iframes.** `PluginResourcePage` renders a plugin-declared path in an `<iframe>` with no `sandbox` attribute. Relative paths resolve against the backend origin, so plugin-served HTML runs same-origin with the admin UI and can read its localStorage (including a remembered management key). That's consistent with "plugins are fully trusted", but it means a third-party plugin owns the admin session as well as the proxy.
- **Churn.** Three releases in four days and a hard v8-only cut (no v7/v0 fallback). Pin UI and backend versions together.
- **Sponsor block in the README.** It's a paid-API ad. Harmless, but the provider icon set also includes sponsor/reseller logos baked into the bundle.

## What It Is

CLIProxyAPI (Go, ~54k stars) runs OAuth/device flows against coding-agent products, stores the resulting "auth files", and exposes `/v1/...` endpoints in OpenAI, Gemini, Claude and Codex wire formats. It load-balances across accounts and API keys. The Management Center is its control plane:

| Area | What it does |
|---|---|
| Dashboard | Connection state, backend version/build date, model availability |
| Configuration | Visual sections (network, streaming, logging, quota, payload rules, OAuth behaviour) and a raw YAML editor with search and save-diff |
| AI providers | Gemini, Codex, Claude, Vertex, OpenAI-compatible providers: keys, headers, per-provider proxies, model mappings, browser-side connectivity test |
| Auth files & OAuth | Upload/download credential files, start OAuth/device flows, set per-file weights, cooldowns, model aliases and exclusions |
| Quotas | Per-provider quota/usage views for Claude, Antigravity, Codex, Devin, Kimi, Meta, xAI, with reset countdowns |
| Logs | Tail with auto-refresh and search, hide management traffic, download request-error logs |
| Plugins | Backend-advertised plugin store, install/config, plugin-provided UI pages |
| System | Update check, model list, clear local login data |

UI languages: English, Simplified Chinese, Traditional Chinese, Russian (fallback zh-CN).

## Stack

| Layer | Tech |
|---|---|
| UI | React 19, React Router 7 (HashRouter), Motion animations |
| State | Zustand stores (auth, config with TTL cache + in-flight dedupe, quota, models, theme) |
| HTTP | Axios `apiClient`: bearer auth, `/v8/management` prefix, error normalisation, version/plugin-support events from response headers |
| Editors | `@uiw/react-codemirror`, `@codemirror/lang-yaml`, `@codemirror/merge`, `yaml` |
| Crypto | `@noble/hashes` (SHA-2 for API-key display names) |
| Build | Vite 8 (rolldown), `vite-plugin-singlefile`, ES2020 target |
| Tests | `bun:test`, SSR static-markup rendering, source/contract checks |
| Size | ~59.5k lines TS/TSX in `src/`, ~18.7k lines of tests |

## Key Features

### One-file artifact
`vite.config.ts` sets `assetsInlineLimit` and `chunkSizeWarningLimit` to 1e8, disables CSS code splitting and rolldown code splitting, and strips the module loader. The release workflow builds `dist/index.html` and renames it to `management.html`. It's a clean pattern for any backend that wants to embed its own admin UI without serving a directory.

### Feature-sliced layout with descriptor-driven providers
`src/features/{config,providers,authFiles,quota,logs,plugins,dashboard}` own their pages, hooks and logic. Provider capabilities live in `features/providers/descriptors.ts`, and `adapters.ts` maps backend configs onto a shared resource model, so adding a provider is mostly data rather than scattered conditionals. Backend field names are normalised in `services/api/transformers.ts` and kept out of components.

### Server-proxied API calls
`services/api/apiCall.ts` posts `{authIndex, method, url, header, data}` to `/requests/api-call`, and the backend makes the upstream request using a stored credential. Quota pages and model discovery use this, so the browser never sees upstream OAuth tokens. It does mean the management key is effectively a "make authenticated requests as any pooled account" key.

### AGENTS.md as the contribution contract
The repo's `AGENTS.md` is a tight, specific guide (scope, v8-only rule, where normalisation happens, i18n parity across four locales, cache and stale-request invariants, "report what you didn't verify"). The recent commit stream (feature + test in the same change) looks agent-assisted and follows it.

## Architecture

```
browser ── management.html (this repo, inlined SPA)
              │  Authorization: Bearer <management key>
              ▼
CLIProxyAPI  /v8/management/*  ── config.yaml, auth files, logs, plugins
              │  /requests/api-call (server-side fetch with pooled creds)
              ▼
upstream providers (Claude, Codex, Gemini, Grok, Devin, …)
```

The API address is derived from the page URL, so served from the backend it needs no configuration. It can also point at a remote instance (`host:port`, the `/v8/management` suffix is stripped). Remote management has to be enabled on the backend (`management.allow-remote`), and the backend temporarily blocks IPs after repeated auth failures.

## Security

- **Secrets in repo:** none found (`sk-`, `AKIA`, `ghp_` patterns: 0 hits). No `eval`, `new Function` or `dangerouslySetInnerHTML` in `src/`.
- **Credential storage:** the management key stays in memory unless "remember password" is ticked (default off). When ticked it's persisted via Zustand `persist` → localStorage, XOR'd with a key derived from a constant salt + host + user agent and base64'd. Anyone with local or XSS access reads it trivially, as the code comments admit.
- **Plugin iframes:** no `sandbox`, `referrerPolicy="no-referrer"`, clipboard read/write allowed. `http(s):`, `data:` and `blob:` paths are passed through unchanged, so a plugin can also point the frame at an arbitrary external origin. Treat third-party plugins as having full admin access.
- **Official-plugin check:** prefix match on the full `https://github.com/router-for-me/` URL (comment notes it blocks `github.com.evil.com` look-alikes). It's a UI label, not a signature check. The backend does the actual install.
- **Transport:** nothing forces HTTPS. If you expose management remotely over plain HTTP the bearer key travels in the clear. Put it behind TLS or keep it on localhost/SSH tunnel.
- **CI:** `actions/checkout@v4`, `setup-node@v4`, `oven-sh/setup-bun@v2`, `softprops/action-gh-release@v1`, all tag-pinned, not SHA-pinned. The release job has `contents: write`. Installs use `--frozen-lockfile`, and an `overrides` pin on `form-data` shows some dependency hygiene.
- **Release integrity:** `management.html` is published without checksums or signatures, and the backend fetches/serves it as the admin UI. Compromise of the release pipeline would equal admin-session compromise.

## Maturity

- 4,441 stars, 1,336 forks, 24 open issues. Created 2025-09-06, last push 2026-10-03. Releases v1.25.1 → v1.25.3 within 2026-09-30 to 2026-10-03.
- Backend CLIProxyAPI: 54,027 stars, 8,185 forks, 663 open issues, v8.0.13 on 2026-10-03. Both are very active.
- CI runs `bun run verify` (tests + lint + build) on every PR and push to main/dev.
- Docs: concise README (EN + CN), `AGENTS.md`. No SECURITY.md.

### Validation on 2026-10-03

- `git clone --depth=1` at `ee79a79`. Downloaded the official Bun 1.3.14 linux-x64 binary from GitHub releases.
- `bun install --frozen-lockfile` was **not** run: this host's package-install gate blocks it. So the suite ran against no `node_modules`.
- `bun test` → **502 tests across 151 files: 408 pass, 94 fail.** All 60 error lines in the log are `Cannot find package` (react, axios, yaml, zustand, i18next, typescript, `@noble/hashes`), and no assertion failures appeared. So every failure is an unresolved dependency, and every test that could load passed. I did not run lint, the type-check, the build, or the UI against a live CLIProxyAPI backend.

## Comparison

| | CLI Proxy API Mgmt Center | 9Router | LiteLLM proxy UI |
|---|---|---|---|
| Role | Admin UI for one specific backend | Combined router + dashboard | Admin UI for LiteLLM gateway |
| Upstreams | Subscription CLIs via OAuth + API keys | Subscription CLIs + API keys | API keys (100+ providers) |
| Deployment | One HTML file served by backend | Node app | Part of Python proxy |
| Config editing | Visual + YAML with diff | Dashboard forms | UI + YAML/DB |
| Quota views | Per-provider subscription quotas | Basic | Spend/budgets per key/team |
| ToS exposure | High (backend pools consumer plans) | High | Low (uses paid APIs) |

See also [9router.md](9router.md).

## Self-Hosting Notes

- You get it for free with CLIProxyAPI: start the backend and open `http://<host>:<port>/management.html`. Building your own copy (`bun install --frozen-lockfile && bun run build`) only matters if you're modifying it.
- Requires backend ≥ 8.0.0. Back up `config.yaml` before a v7→v8 upgrade, because the first v8 write migrates the file.
- Keep `management.allow-remote` off unless you need it, and front it with TLS. Use a dedicated browser profile if you enable "remember password".
- Don't install third-party plugins on an instance that holds accounts you care about.
- The management key and the client `access.api-keys` are different credentials. Hand out client keys, never the management key.

## Reusable Patterns

- **Single-file admin UI** via `vite-plugin-singlefile` + hash routing + release-asset rename. Good for embedding a UI in a Go/Rust binary.
- **Response-header capability events:** the API client emits `server-version-update` / `server-plugin-support-update` from headers, and routes gate on them. This avoids a separate capability endpoint.
- **SSR-markup tests instead of a DOM harness:** `renderToStaticMarkup` + `bun:test` give fast UI regression coverage without jsdom/Playwright. It doesn't cover interactions, which the repo's AGENTS.md says outright.
- **Stale-request guards on connection switch:** a pattern worth copying for any multi-instance admin tool.

---

**Attribution:** router-for-me/Cli-Proxy-API-Management-Center, MIT
