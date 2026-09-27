# Atomic Chat (AtomicBot-ai/Atomic-Chat)

**Repo:** https://github.com/AtomicBot-ai/Atomic-Chat  
**Site:** https://atomic.chat  
**License:** Apache-2.0. Copyright is shared with Menlo Research, because this is a hard fork of Jan (janhq/jan). Reusable with attribution and a NOTICE carry-through. Bundled engines keep their own licenses (llama.cpp MIT, the MLX-VLM fork MIT, cloudflared Apache-2.0). The GitHub API reports `NOASSERTION` because the LICENSE file has a custom header.  
**Reviewed:** 2026-09-27 (commit `e417ac1`, release v2.0.44, 2026-09-21)  
**Stack:** Tauri 2 (Rust) + React/Vite/TanStack Router, TypeScript extension system, llama.cpp (upstream + TurboQuant fork), MLX-VLM PyInstaller sidecar, Apple Foundation Models sidecar (Swift), stable-diffusion.cpp for images, cloudflared  
**What it is:** A desktop and mobile local-LLM app (macOS, Windows, Linux, iOS, Android). It puts three inference backends behind one OpenAI-compatible server on `localhost:1337`, adds speculative decoding (MTP, DFlash, EAGLE-3) and TurboQuant KV-cache quantization, and ships a "Launch" page that installs and configures ~12 coding agents against the local API.

---

## Verdict

⚠️ **Interesting. It's a well-maintained Jan fork with real engine work, but the privacy marketing overstates it.** The engineering is solid. It has a disciplined ADR log (`docs/decisions/`, ~300 records), provider-gated backend flags, a signed mirror for upstream llama.cpp binaries with sha256 resolution, Host-header validation on the local API, and ~980 Rust tests plus ~430 frontend test files. What it adds over upstream Jan is concrete: TurboQuant `turbo3`/`turbo4` KV cache on all desktops, MTP/DFlash/EAGLE-3 speculative decoding wiring, the agent Launch page, a `/v1/responses` shim for Codex, and a Cloudflare quick-tunnel "remote access" mode.

The problem is the pitch. The website says "0 bytes of your data ever leaves your device", but the shipped code has **product analytics consent defaulting to on** (`productAnalytic: true`) with the first-run consent prompt disabled. Upstream Jan defaults to off and asks. It reports PostHog events and Sentry crash reports (designed as zero-PII: anonymous device ID, hardware tags) whenever the build carries those keys, which release builds are meant to. It's a toggle in settings, not a scandal, but it contradicts the headline claim. If you want a local LLM desktop app with an OpenAI-compatible server, this is a reasonable choice, especially for KV-quantized long context. Turn analytics off on first launch, and don't enable remote access without an API key.

---

## What It Is

Atomic Chat is the Jan desktop app, rebranded (with `jan*` identifiers deliberately kept for installer migrations) and pushed toward "local inference engine for agents":

- **Chat UI:** threads, projects with tree view, assistants, artifacts preview, MCP servers, image generation (sd.cpp, new in v2.0.44), and optional cloud providers (OpenAI, Anthropic, Mistral, Groq, MiniMax, Qwen, Moonshot).
- **Local API:** OpenAI-compatible `/v1` on `127.0.0.1:1337`, with a `/v1/responses` translation shim and optional API key.
- **Launch page:** one-click install and configure for Claude Code, Codex CLI, Cline, OpenCode, Droid, Goose, OpenHands, Copilot CLI, Kilo Code, Zed, Hermes Agent, and the vendor's own "Atomic Agent".
- **Remote access:** a bundled `cloudflared` quick tunnel gives the local API a temporary public `trycloudflare.com` URL.

## Stack

| Layer | Tech |
|-------|------|
| Shell | Tauri 2, Rust (`src-tauri/`: server proxy, downloads, MCP, updater, telemetry, remote access) |
| Frontend | React + Vite + TanStack Router, Tailwind, shadcn, zustand |
| Extension contracts | `core/` TS package, `extensions/*` bundled with rolldown |
| Engines | `llamacpp-upstream` (ggml-org, default), `llamacpp` (AtomicBot-ai TurboQuant fork), MLX-VLM sidecar (Apple Silicon), Apple Foundation Models (macOS/iOS), sd.cpp (images) |
| Speculation | MTP, DFlash (block diffusion drafts), EAGLE-3 (MLX, Gemma 4) |
| KV cache | TurboQuant `turbo3`/`turbo4` (llama.cpp fork), TurboQuant/uniform KV quant on MLX |
| Telemetry | PostHog (product analytics), Sentry (frontend + Rust), both gated on one consent flag |
| Release | GitHub Actions, NSIS/MSI/DMG/AppImage, App Store / Play Store |

## Key Features

### Provider-Gated Backends
The `AGENTS.md` and ADRs are strict about which llama.cpp ships where and which flags belong to which provider. Fork-only `-ctk/-ctv turbo*` cache types are guarded by provider identity rather than OS. On Linux, the fork picks CUDA 13.3 → 12.4 → ROCm → Vulkan → CPU, while upstream stays Vulkan → CPU. Upstream artifacts come through a signed mirror, with tag/asset/sha256 resolved by `scripts/resolve-upstream-backend.mjs`, and the docs forbid hardcoded download URLs. This is the kind of discipline most local-LLM wrappers don't have.

### Speculative Decoding and KV Quantization
MTP (Gemma 4, Qwen 3.5/3.6, DeepSeek V4), DFlash drafts (Qwen 3.6, Gemma 4, Kimi K2.5), and EAGLE-3 on MLX are all wired through the UI. The vendor figures are "30–70% MTP throughput, up to 3× on Gemma 4", "up to 6× DFlash", and "~4.3× smaller KV cache". The website's "8× faster, 6× less memory, zero accuracy loss" TurboQuant numbers are Google's research-paper figures on H100s, not measurements of this app on a laptop. None of these were reproduced here.

### Agent Launch Page
This page detects installed agents (resolving the login-shell PATH), installs missing ones, and writes their provider config against `localhost:1337`. The installers are the vendors' own `curl … | sh` / `irm … | iex` one-liners (Goose, Hermes Agent, Zed, poolside, Atomic Agent), run unpinned. That's convenient, but it's arbitrary remote code execution on click, trusted to each vendor's URL.

### Remote Access
`cloudflared` quick tunnel with no account, a new URL each start, and a reachability probe before the URL is shown. The code comment is explicit: "The API key is deliberately not a precondition: exposing the server without one is the user's call." So a public, unauthenticated inference endpoint is one toggle away.

### Decision Log as Agent Context
`AGENTS.md` is kept under 200 lines by rule, and every non-trivial decision becomes an ADR file indexed one line each. It's a good pattern for repos where coding agents do much of the work, which this one clearly does.

## Architecture

```
React UI ──Tauri IPC──▶ Rust core
                          ├─ server/proxy.rs  :1337 /v1 (Host allowlist, CORS, optional API key)
                          │     ├─▶ llama-server (upstream | TurboQuant fork)  per-session bearer, loopback
                          │     ├─▶ mlx-vlm sidecar                            per-session bearer, loopback
                          │     ├─▶ Foundation Models sidecar
                          │     └─▶ remote providers (passthrough with user keys)
                          ├─ remote_access/ (cloudflared quick tunnel)
                          ├─ mcp/, downloads/, updater/, telemetry/ (Sentry)
                          └─ system/commands.rs (agent Launch installers)
extensions/*  (TS drivers per backend, prebuilt into pre-install/janhq-*.tgz)
```

The proxy is a single ~5,000-line `proxy.rs`, and `system/commands.rs` is ~7,100 lines. Both files are large, but they're well tested.

## Security

- **Local API binds `127.0.0.1` by default.** Host-header validation (inherited from Jan) returns 403 for hosts outside Trusted Hosts, which blocks DNS-rebinding from browser pages. The literal `*` disables the check, and the UI suggests it for LAN users.
- **API key is optional** (Bearer or `X-Api-Key`). The comparison is a plain `==`, not constant-time. That's minor on loopback, but it matters more once remote access is on.
- **Remote access can publish the API with no key.** This is by design, and the frontend warns about it. Set a key first.
- **Backend sidecars** get a per-session bearer key and bind to loopback.
- **Telemetry defaults on.** `useProductAnalytic` initializes `productAnalytic: true`, and the first-run consent popup is turned off (`productAnalyticPrompt: false`, with a comment saying it's hidden "for now"). Upstream Jan ships the opposite defaults (`productAnalytic: false`, prompt shown), so the fork flipped both. PostHog and Sentry send `beforeSend`-filtered, zero-PII payloads (anonymous device ID, hardware/backend tags, error codes, scrubbed stderr tails) when build-time keys are present. Local dev builds without keys send nothing.
- **Agent installers** pipe remote scripts to a shell (see above).
- **CI:** only two workflows remain in the fork. Release runs with `contents: write`, and actions are pinned by tag (`actions/upload-release-asset@v1.0.1`, `dtolnay/rust-toolchain@stable`), not SHA. There's also a Cursor issue-trigger workflow. Dependabot is configured.
- No hardcoded `sk-`/`AKIA`/`ghp_`/PostHog keys found in `web-app/src`, `src-tauri/src`, `core`, or `extensions`. Keys are injected at build time.

## Maturity

- Repo created 2026-03-31. As of review: 1,637 stars, 194 forks, 59 open issues. Upstream Jan has ~44.7k stars and remains active, and this fork tracks and diverges from it.
- Releases roughly weekly (v2.0.35 → v2.0.44 in September). Most recent push 2026-09-25.
- Tests: ~981 Rust `#[test]`/`#[tokio::test]` functions, ~430 frontend `*.test.ts(x)` files, root `node:test` contract suites, plus a `make verify` gate with coverage floors.
- Docs: good internal docs (AGENTS.md, DEVELOP.md, ADR log). The README download badges still point at v2.0.0 while the site serves v2.0.44.

### Validation on 2026-09-27

- `node --test tests/*.test.mjs` (root contract suites: capability flags vs Rust, hardware profiles, registry contracts, upstream backend resolver): **30 passed, 0 failed** (Node 26.5, Linux).
- `yarn install` (Yarn 4.5.3) for the Vitest suites was killed by the host during the fetch step (resource limit). Frontend and Rust suites were **not run**. No cargo toolchain was available on the review host.
- The app wasn't built or launched, and throughput/KV-memory claims were not reproduced.
- Telemetry, API-key, remote-access, and installer findings come from reading source at `e417ac1`.

## Comparison

| Aspect | Atomic Chat | Jan (upstream) | LM Studio | Ollama |
|--------|-------------|----------------|-----------|--------|
| License | Apache-2.0 | Apache-2.0 | Proprietary | MIT |
| Engines | llama.cpp ×2, MLX-VLM, Apple FM, sd.cpp | llama.cpp (+ agent/SDK work) | llama.cpp, MLX | llama.cpp-derived |
| KV quant | TurboQuant turbo3/4, MLX KV quant | Standard | Standard | q8/q4 KV |
| Speculative | MTP, DFlash, EAGLE-3 in UI | Limited | Draft models | Limited |
| Local API | OpenAI `/v1` + Responses shim, :1337 | OpenAI `/v1`, :1337 | OpenAI + native | Ollama + OpenAI |
| Agent launcher | Yes (~12 agents) | No | Partial | `ollama launch` |
| Mobile | iOS + Android | No | No | No |
| Analytics default | On (consent prompt hidden) | Off, with first-run prompt | Proprietary | None |

## Self-Hosting Notes

- On first launch, open Settings and turn off product analytics if you want the "nothing leaves the device" behavior the site advertises.
- Set a Local API Server key before using LAN mode (`host: 0.0.0.0` plus Trusted Hosts with the **server's** address) or remote access. Prefer adding explicit hosts over `*`.
- On Linux, the AppImage defaults to upstream llama.cpp with Vulkan only. Switch to the "Atomic Llama.cpp Turboquant" provider for CUDA/ROCm and turbo KV cache.
- For Launch-page installs, consider installing agents yourself from pinned releases instead of the one-click `curl | sh`.
- Data paths are per-OS, including three legacy Windows APPDATA folders from Jan. See `DEVELOP.md` before you wipe or migrate anything.

## Reusable Patterns

- **ADR-per-decision plus a size-capped AGENTS.md.** This keeps agent context small and decision history greppable.
- **Provider-identity flag gating.** Gate engine flags on which binary you ship, not on OS or GPU.
- **Signed mirror + resolver script for third-party binaries**, with sha256 checks and a fallback to upstream.
- **Per-session bearer between proxy and loopback sidecars**, so other local processes can't talk to the engine directly.

---

**Attribution:** AtomicBot-ai/Atomic-Chat, Apache-2.0 (fork of janhq/jan, © Menlo Research)
