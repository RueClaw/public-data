# GL4SS / The Looking Glass (elder-plinius/GL4SS)

**Repo:** https://github.com/elder-plinius/GL4SS  
**License:** AGPL-3.0-or-later  
**Reviewed:** 2026-08-01  
**Commit:** `ab4984597ecf3afbd8ea66309be5ed68ce429146`  
**Stack:** React 19, TypeScript, Vite 7, Leaflet, Three.js, raw WebGL, IndexedDB, localStorage, OpenRouter, Cloudflare static assets  
**What it is:** A browser-only "spatiotemporal image + video engine" that lets a user choose a place, year, and time of day, then generates a scene plan, still image, and optional video through OpenRouter.

---

## Verdict

⚠️ **Interesting, especially as a browser-only BYOK media-generation pattern.** GL4SS is more careful than the average AI-media demo: it has no backend, keeps the OpenRouter key in the browser, sets a restrictive CSP, avoids attaching authorization headers to arbitrary returned media URLs, separates demand generation from prefetching, and stores generated frames locally in IndexedDB. I would treat the generated history/future imagery as speculative concept art, not research evidence, and I would not copy code into proprietary work without thinking through the AGPL. But as a static, bring-your-own-key AI experience, it is worth studying.

---

## What It Is

GL4SS is a one-page static web app for generating "views" of Earth locations across deep time, recorded history, present day, and imagined futures. The user can:

1. pick a location through search, map, globe, or direct coordinates;
2. choose a year from the Great Dying era through 3050 AD;
3. set hour, phase, style, aspect ratio, and weather;
4. generate a still image;
5. optionally generate video and sound;
6. compare, pin, revisit, and locally cache frames.

The repo is client-only. There is no server-side secret custody, account layer, database service, or telemetry backend in the application code. The deployed Cloudflare configuration serves static assets with SPA fallback.

## Architecture

| Layer | Notes |
|-------|-------|
| Frontend | React/Vite TypeScript single-page app |
| Map/search | Leaflet, Esri World Imagery tiles, Nominatim search |
| Globe | Lazy-loaded Three.js globe view |
| Visual effects | Raw WebGL wormhole canvas plus CSS UI |
| Generation | OpenRouter chat/completions calls for planning, images, and video |
| Persistence | IndexedDB frame store plus localStorage settings/key wrapper |
| Deployment | Cloudflare Pages/Workers static assets via `wrangler.jsonc` and `public/_headers` |

## Strong Parts

### Browser-Only Key Boundary

The app makes a deliberate product choice: bring your own OpenRouter key and keep it client-side. That is not risk-free, but the surrounding implementation is unusually explicit:

- `public/_headers` restricts `connect-src` to the app itself, OpenRouter, and Nominatim;
- `Permissions-Policy` disables geolocation, camera, microphone, and payment;
- key verification hits OpenRouter's key endpoint rather than a project backend;
- storage access is wrapped so private mode or blocked localStorage does not crash the app;
- generated video URLs are fetched with authorization only when the URL origin is OpenRouter.

That last point matters. Some providers return signed or CDN-hosted media URLs. GL4SS avoids the easy mistake of blindly attaching the user's OpenRouter bearer token to every returned URL.

### Paid Generation Is Gated

The UI and engine distinguish deliberate "generate" actions from browsing and prefetch behavior. The frame engine tracks demand and prefetch queues separately, keeps concurrency low, and avoids re-billing already stored frames during hydration. This is a good shape for any browser app that can spend user credits.

### Local Archive Design

`frameStore.ts` uses IndexedDB to split frame metadata from image bytes, tracks local cache size, handles storage failures, and evicts unviewed prefetched frames before user-requested frames. The cache budget is still approximate, but the direction is right: generated artifacts are treated as durable user value, not throwaway UI state.

### Prompt Hygiene

The scene-planning path treats user and geocoder location text as data. The prompt template quotes location values with `JSON.stringify`, validates returned JSON, and has fallback paths when moderation or model output fails. That will not make generated history factual, but it reduces ordinary prompt-injection and malformed-output failure modes.

### UX Density

The app is built as the experience, not a landing page. It has a map, globe, temporal stations, curated journeys, a sundial/hour control, style/model controls, compare/pin flows, and a WebGL "warp" transition. The README's count of 284 temporal stations and 55 journeys matches the ambition of an exploratory tool rather than a thin API wrapper.

## Caveats

- **Generated history is not evidence.** The app can be evocative, but it does not cite historical, paleoclimate, archaeological, or urban-planning sources for individual frames. Treat outputs as speculative visualization.
- **AGPL changes reuse posture.** The repo is AGPL-3.0-or-later. Summarize patterns freely with attribution, but do not lift implementation into proprietary/networked software without satisfying source obligations.
- **Very young project.** The repo was created 2026-07-31, has no release, no obvious CI, and no automated tests beyond build/lint validation.
- **OpenRouter model names drift.** The README describes the default video model as `bytedance/seedance-2.0`, while the code defaults to `x-ai/grok-imagine-video`. That kind of mismatch is common in fast-moving media APIs and needs routine upkeep.
- **Paid media can get expensive.** Still and video generation are user-keyed and may be slow or costly. The app's gates help, but operators still need to understand OpenRouter pricing and provider availability.
- **CSP is bounded but not absolute.** `img-src` and `media-src` allow `https:` broadly so provider-hosted assets can render. The origin check protects the bearer token path, but supply-chain and hosted-asset risk still exist.
- **LocalStorage key storage is a tradeoff.** It is convenient and browser-only, but any script that runs on the app origin could read it. The no-backend architecture and CSP reduce the attack surface; dependency hygiene still matters.

## Verification

Local checks performed on 2026-08-01:

- `npm install` completed, but modified `package-lock.json` in the temp clone and reported 10 full dev-tree advisories: 1 low, 1 moderate, 8 high.
- `npm run build` passed with Vite's large-chunk warning for the main bundle/Three chunk.
- `npm run lint` passed.
- `npm audit --omit=dev` passed with 0 production vulnerabilities.

I did not run live image or video generation because that requires an OpenRouter key and could spend user credits.

## Reuse Notes

The reusable idea is not "AI time machine" so much as a static BYOK media app with:

- a visible paid-generation lever;
- provider-key custody in the user's browser;
- CSP-bounded network access;
- no accidental bearer-token forwarding to returned media URLs;
- local IndexedDB artifact storage;
- separate demand/prefetch queues;
- graceful degradation when storage, moderation, model output, or provider jobs fail.

Good fit:

- personal static AI tools where users bring their own provider key;
- exploratory media interfaces with local archives;
- examples of key-exfiltration-aware client code;
- speculative art/history/future visualization demos.

Poor fit:

- factual research visualization without citations;
- proprietary codebases that cannot accept AGPL obligations;
- shared deployments where an operator wants to custody one central API key;
- apps that need deterministic, test-covered generation workflows.

---

**Attribution:** elder-plinius/GL4SS, AGPL-3.0-or-later.
