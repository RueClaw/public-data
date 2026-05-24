# Anytype TS (anyproto/anytype-ts)

**Repo:** https://github.com/anyproto/anytype-ts  
**License:** Any Source Available License 1.0; non-commercial use and commercial use only on allowed Any networks. Not an open-source/permissive fork target.  
**Reviewed:** 2026-05-23  
**Stack:** Electron, React 18, TypeScript, MobX, Vite, Bun, gRPC-Web, anytype-heart middleware, Lexical, PixiJS/D3, Storybook, browser extension, Go native messaging host  
**What it is:** The official desktop client for Anytype: a local-first, encrypted, peer-to-peer personal knowledge base and object graph for macOS, Windows, and Linux.

---

## Verdict

📚 **Study, do not casually fork.** Anytype TS is a mature, ambitious local-first knowledge client with valuable patterns around object-based data, encrypted local-first UX, Electron tab/window management, web-clipper bridging, and middleware-backed gRPC state updates. The codebase is large, source-available rather than permissively open source, depends on generated anytype-heart artifacts, and currently has rough verification signals in a fresh checkout: tests fail, typecheck needs generated middleware files, and dependency audit reports 31 moderate/high advisories.

---

## What It Is

Anytype is a personal knowledge base built around objects, spaces, relations, blocks, graph views, and user-defined data models. The desktop client is an Electron/React application that talks to the Go-based anytype-heart middleware through gRPC-Web. Data is designed to be local-first and encrypted, with optional peer-to-peer sync.

The repo also includes web mode, a browser/web-clipper extension, native messaging host support, Storybook stories, localization tooling, and packaging flows for macOS, Windows, and Linux. It is the official production client rather than a small reference app.

The most interesting technical idea is the product architecture: a rich local object graph UI backed by a separate encrypted/syncing middleware process. That keeps UI iteration in TypeScript while pushing storage, identity, sync, and protocol concerns into anytype-heart.

## Stack

| Layer | Tech |
|-------|------|
| Desktop shell | Electron 41, electron-builder |
| Frontend | React 18, TypeScript, MobX, SCSS |
| Build | Bun, Vite, ts-proto, Storybook |
| Middleware transport | gRPC-Web to anytype-heart, generated protobuf bindings |
| Editor/UI | Lexical, block components, dataviews, graph views |
| Graph rendering | PixiJS worker + D3 force simulation |
| Extension | Browser extension surfaces plus Go native messaging host |
| Secrets/system integration | keytar, Electron safe storage, OS-specific packaging/signing |

## Key Features

### Local-First Object Graph

The application is structured around objects, details, relations, blocks, widgets, spaces, and graph views. MobX stores hold reactive client state while the middleware streams object/detail/block events through a central dispatcher.

### Middleware Boundary

anytype-ts is primarily the client surface. Account creation, wallet/session flows, object commands, imports, membership, files, and sync-aware updates are routed through generated gRPC command wrappers and dispatcher responses from anytype-heart.

### Rich Electron Client

The Electron layer handles tab/window state, child windows, PIN locking, native menus, updates, keytar-backed secrets, safe local storage, downloads, file/path opening, tray/menu behavior, and cross-platform packaging.

### Web Clipper / Native Messaging

The repo includes a browser extension and Go native messaging host, giving the desktop app a bridge for clipping or sending browser context into Anytype.

### Graph Visualization

The graph view uses an off-main-thread PixiJS/D3 worker architecture for large interactive graphs. That is a strong pattern for knowledge tools that need dense graph visualization without blocking the React UI thread.

## Architecture

The rough shape:

- electron/ts: main-process application lifecycle, IPC, windows, updates, storage, keytar, server management
- src/ts/lib/api: generated-command wrappers, dispatcher, response mapping, protobuf transport integration
- src/ts/store: MobX stores for auth, blocks, details, records, menus, popups, membership, notifications, progress
- src/ts/component: block editor, pages, menus, popups, widgets, graph views, settings, onboarding
- extension: browser extension UI/auth/iframe/popup surfaces
- go: native messaging host
- dist and middleware artifacts: runtime assets and generated protocol/runtime files expected during build

This is a client for a larger system, not a standalone note-taking engine. Any serious evaluation needs anytype-heart and the generated middleware artifacts.

## Comparison

| Aspect | Anytype TS | Local NotebookLM | html-anything | Obsidian-like Local Apps |
|--------|------------|------------------|---------------|--------------------------|
| Core model | Encrypted object graph and spaces | PDF/audio workflows | Agent-generated HTML surfaces | File/vault notes and plugins |
| Runtime | Electron client + Go middleware | FastAPI/Gradio/CLI | Local web app + agent CLIs | Desktop app/plugin runtime |
| License | Source-available ASAL | Apache-2.0 | Apache-2.0 | Varies |
| Best pattern | Local-first encrypted object graph UI | staged media pipeline | streaming preview/export | plugin/vault ecosystem |
| Main caveat | Hard to fork/deploy independently | narrower product | security-sensitive shell boundary | less structured object model |

## Self-Hosting Notes

Fresh-checkout verification:

- bun install --frozen-lockfile succeeded
- bun run lint passed with two warnings
- bun run typecheck failed because generated middleware/protobuf files were absent in the checkout
- bun run test failed: 369 passed, 101 failed, mostly missing globals such as U/Relation in Vitest setup plus one icon component ReferenceError
- bun audit --audit-level moderate reported 31 vulnerabilities: 11 high, 20 moderate

Builds require fetching anytype-heart middleware via update.sh or update-ci.sh, generating protobuf bindings, and using platform-specific signing/notarization inputs for release packaging. Treat this as an official-client codebase to study or contribute to, not a quick self-hostable fork.

---

**Attribution:** anyproto/anytype-ts, Any Source Available License 1.0
