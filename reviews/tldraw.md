# tldraw (tldraw/tldraw)

**Repo:** https://github.com/tldraw/tldraw
**License:** Source-available tldraw license for SDK packages; production use requires a valid license key. Several starter templates and some lower-level packages are MIT.
**Reviewed:** 2026-05-23
**Stack:** TypeScript, React, Vite, Yarn 4, lazyrepo, Vitest, Playwright, Cloudflare Workers/Durable Objects/R2, WebSockets, IndexedDB, SQLite, MCP
**What it is:** tldraw is a polished infinite-canvas React SDK and whiteboard application platform, with multiplayer sync, custom shapes/tools/bindings, AI starter kits, and an MCP app that lets agents manipulate a live canvas.

---

## Verdict

✅ **Deploy candidate if the license model fits.** tldraw is one of the strongest canvas SDKs available: mature editor primitives, excellent documentation, real-time sync architecture, starter kits, and a serious test/CI surface. The caveat is licensing: the SDK is source-available rather than open source, development use is free, and production deployments require a trial, hobby, or commercial license key.

---

## What It Is

tldraw provides a feature-complete infinite canvas engine for React apps. It includes default whiteboard behavior, drawing and diagramming tools, rich text, arrows, embeds, images/videos, snapping, custom shapes, custom tools, bindings, side effects, event hooks, export, persistence, collaboration, and mobile/touch support.

The repository is broader than the npm SDK. It contains the public packages, documentation site, examples app, dotcom app/workers, analytics workers, templates, a VS Code extension, internal scripts, agent-oriented skills, and an MCP app. The docs and templates show how tldraw wants to be used as a substrate for custom products, not just embedded as a widget.

The strongest current direction is canvas plus AI. The docs describe three AI patterns: canvas as output, visual workflow graphs, and agents that read and manipulate the canvas through typed actions.

## Stack

| Layer | Tech |
|-------|------|
| SDK/UI | React 18/19, TypeScript, Vite, TipTap, Radix UI, rbush |
| State/data | tldraw state/store packages, schema migrations, validation, IndexedDB persistence |
| Realtime | @tldraw/sync, @tldraw/sync-core, WebSockets, TLSocketRoom |
| Hosted sync templates | Cloudflare Workers, Durable Objects, Durable Object SQLite, R2 asset storage |
| AI/MCP | Agent starter kit, model-provider workers, tldraw MCP app, MCP ext-apps SDK |
| Tooling | Yarn 4.12, lazyrepo, Oxlint/Oxfmt, Vitest, Playwright, API Extractor |

## Key Features

### Infinite Canvas SDK

The SDK gives developers a ready-made editor with deep customization surfaces: shapes, tools, bindings, UI components, editor APIs, external content handlers, persistence, image export, rich text, embeds, and interaction managers. The public docs are unusually complete for an SDK of this size.

### Multiplayer Sync

tldraw sync has a clear server/client model. The frontend uses a sync hook and asset store; the backend owns one room per document, synchronizes clients over WebSockets, and persists state. The recommended production path uses Cloudflare Durable Objects to guarantee a single authoritative room instance, Durable Object SQLite for room persistence, and R2 for binary assets.

The docs are honest about missing production pieces in templates: authentication, authorization, rate limiting, asset size limits, snapshots/history, and room listing/search are left to the app owner.

### AI Starter Kits

The Agent starter kit is the standout reusable pattern. It combines visual screenshots and structured shape data, then routes model output through typed action utilities that can create, update, delete, arrange, and inspect shapes. Modes define what the agent can see and do; managers decompose state for chat history, model selection, context, todos, and mode transitions.

The workflow starter kit is also interesting: custom node shapes expose ports, bindings connect nodes, and an execution engine resolves dependencies and runs the graph. That makes tldraw a credible substrate for ComfyUI-like visual workflows or domain-specific automation builders.

### MCP App

The repo includes an MCP app that exposes a tldraw canvas to compatible AI clients. Its server runs on Cloudflare Workers with a Durable Object for checkpoint storage. Its widget renders the canvas in an iframe and executes JavaScript against a focused editor proxy, translating between agent-friendly simple shapes and tldraw internal shape records.

## Architecture

The monorepo is organized around SDK packages, apps, internal tooling, and templates. Core public packages include editor, state, store, tlschema, sync, sync-core, tldraw, validate, utils, assets, mermaid, driver, and create-tldraw. Licensing varies by package: several foundational state/store/schema packages are MIT, while the main SDK/editor/sync packages use the tldraw license.

Quality gates are serious. CI checks constraints, dependency dedupe, package metadata, circular dependencies, type declarations, bundle sizes, API declarations, docs generation, lint, localization output, unit tests, package builds, and Playwright tests for examples/dotcom.

## Comparison

| Aspect | tldraw | Excalidraw | React Flow / XYFlow |
|--------|--------|------------|---------------------|
| Primary fit | Full infinite-canvas SDK and whiteboard platform | Sketchy collaborative diagram/whiteboard app and embeddable components | Node/edge workflow and graph UIs |
| Custom shapes/tools | Very strong | Moderate | Strong for graph/node UIs |
| Multiplayer | First-class sync package and Cloudflare templates | App-level collaboration model | Usually application-owned |
| AI substrate | Agent/workflow/chat starter kits plus MCP app | Can be integrated, less central | Strong for workflow UIs, less whiteboard-native |
| License | Source-available SDK; production license key required | More permissive for many uses | MIT/commercial ecosystem varies by package |

## Verification Notes

Checks performed:

- Cloned current main at commit 84056a8 from 2026-05-22.
- Inspected README, license, package manifests, docs, sync docs, AI docs, starter kits, MCP app, templates, CI workflows, and security policy.
- Installed with Yarn 4.12 through corepack/npx. Install completed with peer/build warnings under local Node v25.9.0.
- Ran Vitest CI target: 6,673 tests passed, 24 skipped, 53 todo, and 4 failed locally. The failures were in LocalIndexedDb and a SQLite migration snapshot, likely sensitive to the local Node/runtime/SQLite/fake-indexeddb environment rather than broad product breakage. The repo declares Node 20, while this local machine had Node 25.
- Ran Yarn audit: 45 moderate-or-higher advisories, including 25 high, mostly transitive build/dev/runtime dependencies such as minimatch, tar, path-to-regexp, undici, lodash, glob, and related tooling.
- Ran a targeted secret-string scan. Most hits were expected GitHub secret references or placeholder docs. One public PostHog token is committed in the analytics app source; that may be intentional for client analytics, but should be treated as a public token.

## Deployment Notes

- Production SDK use requires a license key. The docs state that license keys are validated client-side and can be public because they are domain-restricted.
- The hosted sync demo is for prototypes only: data lasts 24 hours and rooms are publicly accessible.
- Production sync needs app-owned auth, authorization, rate limits, asset limits, document history/snapshots, and room discovery.
- Commercial/hobby production licensing sends no usage data according to the docs; trial and unlicensed production modes may send license/domain information for analytics or watermark behavior.

---

**Attribution:** tldraw/tldraw, tldraw license plus MIT starter templates and selected MIT packages.
