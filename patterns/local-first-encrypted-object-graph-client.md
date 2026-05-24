# Local-First Encrypted Object Graph Client

**Source:** https://github.com/anyproto/anytype-ts  
**License:** Any Source Available License 1.0  
**Reviewed:** 2026-05-23  

## Pattern

Build a rich knowledge app as a local-first object graph client backed by a separate encrypted/syncing middleware process.

The client owns interaction, rendering, local UI state, windows, tabs, graph visualization, imports, and extension surfaces. The middleware owns the hard substrate: identity, account/session state, object storage, sync, encryption, object commands, and event streaming.

## Core Shape

- **Object model:** pages, tasks, files, spaces, relations, collections, dataviews, and custom types are all objects or object-associated details.
- **Block editor:** documents are composed from typed blocks, with command wrappers for structural changes.
- **Reactive client state:** MobX stores cache auth, records, details, blocks, UI state, membership, progress, menus, and popups.
- **Command boundary:** frontend commands are thin wrappers around middleware RPCs.
- **Event stream:** middleware sends object/detail/block/session events, and the client applies them inside batched state updates.
- **Local-first shell:** Electron provides filesystem, keychain, safe storage, native menus, updates, tabs, child windows, downloads, and extension integration.
- **Heavy visualizations off-thread:** graph rendering can move to an OffscreenCanvas/Web Worker with PixiJS/D3 to keep React responsive.

## Why It Works

A local-first knowledge app needs strong UX and strong data guarantees. Keeping the UI in TypeScript/React allows fast product iteration, while a separate middleware can focus on encrypted storage, sync, identity, protocol stability, and cross-client consistency.

The event-stream boundary is the key. The UI can optimistically render and react to local state, but all authoritative changes arrive through a single protocol path. That gives the app a coherent state model despite having tabs, windows, extension surfaces, and multiple object views.

## Tradeoffs

- The client is not standalone. Builds and typechecks depend on generated protocol artifacts and a compatible middleware version.
- The command/event boundary can become a large dispatcher unless event routing is split into smaller domains.
- License and network constraints matter if the codebase is source-available rather than open source.
- Dependency hygiene is harder in rich Electron apps with editor, graph, PDF, extension, analytics, and packaging dependencies.

## Use When

Use this pattern for tools that need:

- offline-first knowledge or workspace data
- encrypted local storage plus optional sync
- user-defined object/relation models
- desktop-native integration
- multiple client surfaces over one local data substrate
- graph or block-editor UI on top of structured data

Do not use it for a simple note app, a server-first SaaS dashboard, or a tool whose data model is just files and folders.

---

**Attribution:** anyproto/anytype-ts, Any Source Available License 1.0
