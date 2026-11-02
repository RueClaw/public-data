# FigCraft (storytold/figcraft)

**Repo:** https://github.com/storytold/figcraft
**License:** MIT OR Apache-2.0 code; separate font/dependency licenses and restricted ArtCraft branding.
**Reviewed:** 2026-11-02 (UTC)
**Revision:** bd920fc7dec63ee8d433884a175f2f581cc9eb87 — whole repository, sampled implementation across desktop, engine, formats, plugins, automation and collaboration.
**Verification:** Static source review only. No build, source execution, application tests, installation, model download, provider call or live design conversion was performed.
**Stack:** Rust 2024 (minimum Rust 1.95), egui/eframe, tiny-skia, imbl, serde, wasmi, WebAssembly, WebSockets.
**What it is:** A native interface-design and prototyping editor with a shared command engine for people, scripts and MCP agents—not a Figma API wrapper or an AI image generator.

---

## Verdict

⚠️ **Interesting — pilot on disposable designs, not yet a production Figma replacement.** The implementation is substantial: editable scene graphs, components, layout, prototypes, a CPU renderer, native archives, import/export and a genuinely shared automation surface. The strongest ideas are command-level reuse, explicit conversion warnings and bounded plugin execution. Experimental interoperability, fast-moving alpha behavior and materially stale headline documentation make representative round-trip testing and independent backups mandatory.

## What It Is

ArtCraft's FigCraft targets interface designers, design-system authors and developers who want local files and a scriptable editor. A normal workflow is to create frames, use auto layout and components, bind variables and modes, wire prototype interactions, inspect developer-facing code and export assets. Boards add whiteboard-style objects. Native, headless and browser entry points share the engine rather than implementing separate editors. [E1–E3]

The repository calls itself a clean-room reimplementation of collaborative design workflows. That is an author provenance claim, not something this review independently certifies. Its README labels the project alpha and estimates roughly 49% readiness for replacing proprietary tools. That percentage and menu-coverage counts are project estimates, not measured compatibility or usability scores. Conversely, its architecture document still says there is no .fig reader, while the actual source contains both import and experimental export. Read the code and dated compatibility notes, not just the overview. [E1, E2, E4]

## Stack

| Layer | Technology / responsibility |
|---|---|
| Document | Persistent imbl node maps, stable IDs, serde data, structural sharing and snapshots |
| Engine | JSON command registry, layout/component synchronization, gestures, undo, prototype runtime and code generation |
| Rendering | tiny-skia CPU rendering; kurbo/linesweeper geometry; HarfRust/skrifa text; raster fallback for effects in vector exports |
| UI | egui/eframe desktop; WASM browser build; GPU-backed window presentation is distinct from CPU document rendering |
| Interchange | ZIP/JSON native archives; kiwi/deflate/zstd .fig parsing; REST JSON, Penpot and Sketch adapters; SVG/PDF/image outputs |
| Automation | CLI, newline-JSON loopback control and stdio MCP, headless or attached |
| Extensions / sharing | Metered wasmi plugins; separate collaboration core, WebSocket transport and persistent server |

The manifest pins craft-libs, egui and winit forks to revisions and includes Cargo.lock. This improves reproducibility but makes the maintenance surface larger than stock crates.io dependencies. No dependency vulnerability audit or recursive dependency-source audit was performed. [E3]

## Key Features

### One command engine, several clients

Session execution is the common path for UI, CLI and MCP operations. The headless MCP backend owns a real engine Session, polls/synchronizes live collaboration and discards UI-dialog requests; it is not screenshot-only automation. Pointer/text actions and structured edits support agent construction of editable documents. An agent can inspect and render its changes before export, but the model client still needs its own permission policy and verification loop. No model or provider credential is required by the editor's basic design workflow; an external MCP client determines whether design content is sent to a model provider. [E2, E5]

### Layout, components and handoff rather than just drawing

The source splits auto layout, reusable components and variables, vector geometry, text shaping, prototype execution and developer code generation into dedicated modules. These are meaningful implementation surfaces, not just menu labels. Generated React/CSS or mobile UI snippets are handoff material, not independently validated production applications. Font availability and renderer differences remain part of visual fidelity. [E2, E3]

### Real interoperability, explicitly lossy

| Format / workflow | What is implemented | What not to assume |
|---|---|---|
| Native .figcraft | ZIP with document JSON, images, versions, branches and library data | Not a guarantee of byte-preserving storage for unknown/damaged future fields |
| Figma .fig | Generic kiwi schema/chunk reader mapped through REST import; experimental schema/message writer | Not a lossless Figma round trip or full feature parity |
| FigJam .jam | Same container reader, board file kind, approximate ordinary layers | Imported stickies/connectors are not necessarily equivalent native board objects; no .jam writer |
| Figma REST JSON | Local import of design structure, variables and supplied images | Not live authenticated Figma workspace synchronization |
| Penpot 2.x | Offline ZIP/JSON import/export into editable nodes, with source metadata/fingerprints | Not Penpot 1.x binary support or verified live-server compatibility |
| Sketch | Best-effort modern .sketch import | No Sketch writer; older binary-plist/SQLite versions unsupported |
| SVG/PDF/raster | Asset export; selected effects become rasters | Exported pixels do not preserve the full editable design model |

The .fig writer genuinely exists and serializes nodes, components, styles and variables; the format notes report some external-application import checks, including an image-hash and component-property correction. Those are upstream reports, not tests reproduced here. The same notes enumerate dropped or approximated information: comments, Dev Mode data, version history/branches, various text details, slot content and some prototype actions. Internal exporter→importer agreement cannot prove another product reads the result correctly. [E4]

Penpot support is particularly thoughtful: unchanged supported source properties can be reused by fingerprint rather than regenerated, unsupported layout can retain saved positions and bounded metadata, and warnings describe conversion loss. But embedded font binaries are not retained, regenerated text is laid out again, some interactions/layout are unsupported, and token edits may fall back to preserved source tokens with a warning. This is a promising migration adapter, not a lossless interchange contract. [E6]

## Architecture

The workspace separates geometry/color, document data, layout/text/collaboration/plugin primitives, rendering/formats, the engine and UI/transports. The layer-check task is intended to prevent lower-level crates from acquiring UI dependencies. Persistent document snapshots make undo cheaper than full deep copying; actual rendering and large-file performance were not benchmarked here. Command guards convert native unwinding panics into errors, with rollback responsibilities in callers. [E2, E3, E7]

The README's “Never crashes” is too strong. The guard explicitly documents that WASM panics stop the page; allocation exhaustion, dependencies and graphics/platform failures are not eliminated by banning unwrap/expect/panic macros. Similarly, “pure Rust” does not remove OS/window-system or GPU-driver dependencies. [E1, E7]

## Security, Privacy and Execution Boundaries

- **Offline editing is plausible; the absolute network claim is stale.** The README says no server is contacted until sharing/joining. Desktop main explicitly enables startup update checking, and the update UI calls craft-update's check-at-start path. Optional font downloads also exist. This establishes additional network-capable paths, not telemetry or document exfiltration; exact updater request contents were not audited in its external dependency. [E1, E8]
- **Sharing changes the trust model.** Online sharing sends the document to a server (a public default is documented). TLS protects transport, not end-to-end confidentiality; operators can read stored designs. Stopping sharing revokes access but is not the same as deleting the stored document. The public service has retention rules and no backup/uptime guarantee. LAN sessions are documented as unencrypted. [E1, E9]
- **Bearer links are credentials.** There are no user accounts in the documented model. View/edit/comment access, server keys and owner tokens carry authority. Owner tokens are kept in local preferences, not an OS-secret-store boundary; reading that file can enable management of published files. Some library links carry tokens with the document. Do not send archives, preferences or invitation URLs to unintended readers. The optional team list intentionally exposes shared files to everyone who can reach that server. [E9]
- **Control/MCP is powerful, not automatically sandboxed.** The opt-in control socket binds loopback and uses bounded raw JSON rather than HTTP, reducing browser-request confusion; the inspected listener/protocol has no token authentication. Other local programs able to connect can exercise its control authority. Read/write-root flags provide explicit canonicalized path confinement and disable relevant engine network operations; they are opt-in, have documented app-owned/startup-file exceptions, and are not a whole-process OS sandbox. [E5, E10]
- **Plugins have a meaningfully narrower boundary.** wasmi has no WASI, fuel and memory/message/log caps; engine policy blocks file, collaboration and other high-authority command families. A permissioned save-file API hands bytes and a sanitized suggested name to a host dialog rather than exposing a filesystem path. Plugin authorship is not cryptographically verified simply because a directory displays a name. This is FigCraft's own plugin API, not automatic compatibility with the Figma plugin ecosystem. [E11]
- **Untrusted designs still need resource isolation.** Readers enforce member, value, image, layer and recursion budgets. Native format totals can still allow gigabytes of decompression; those caps do not bound all decoded-pixel or process memory. Read bounded parser code as defense in depth, not proof of denial-of-service immunity. [E4, E6, E12]

## Data Preservation

Native archives are the authoritative editable output. The save implementation uses atomic staging/rename support and ordinary Save checks for external changes unless explicitly overridden. The change detector uses size/modification time; explicit-path saves and Save As have different overwrite semantics, and same-size changes within a coarse timestamp tick can escape detection. Atomic replacement is not a backup or multi-writer transaction. [E12, E13]

Import warnings and missing-image placeholders are valuable, but lenient repair or skipped damaged versions/libraries can change the document. A successful open is not proof that everything survived. Keep the original untouched, save a native copy, inspect warnings, reopen it, compare visual exports and verify component/variable/prototype behavior in the destination application. Preserve independent offline copies before collaborating; recovery copies and server snapshots are useful but were not failure-tested here. [E4, E9, E12]

## Maturity, Tests and Platform Constraints

Public metadata retrieved 2026-11-02: repository created 2026-10-09, last push 2026-11-01, 4,053 stars, 1,589 forks and 263 open issues/PRs combined. Popularity is not validation. Latest observed release is v0.14.0, published 2026-11-01 with 31 assets; GitHub marks it non-prerelease while the README still explicitly describes alpha readiness. The reviewed commit is dated 2026-11-01. [E14]

There is substantial regression infrastructure: parser budgets, synthetic import/export fixtures, plugin permissions, disk-change preservation, server hardening and UI/engine tests. xtask ci chains formatting, clippy, workspace tests/doctests, translation reporting, layers, asset attribution, docs and WASM checks. The CI workflow delegates to craft-common-actions at mutable main, while its font input is pinned. At the inspected SHA the API reported CI success, SonarCloud failure and FreeBSD in progress. The cause of the scan failure was not investigated; do not equate one green gate with all-platform certification. [E15]

Desktop packaging targets macOS, Windows, Linux and FreeBSD, with a browser build. Releases/documentation are evidence of intended coverage, not proof this revision works on every target. Linux needs native window/font dependencies; Wayland hidden-window automation has documented limitations. Optional craft-fonts affects reproducible text. No GUI, fonts, accessibility, installer signatures, browser persistence, simultaneous editing, performance or external-product corpus was validated during this review.

## Comparison

| Alternative | Prefer it when | FigCraft's tradeoff |
|---|---|---|
| [Penpot](https://github.com/penpot/penpot) | You want a browser-first open-source design/collaboration platform | FigCraft emphasizes a native local-file editor and shared headless engine; its Penpot bridge remains conversion, not shared live storage |
| [Figma](https://www.figma.com/) | Existing teams require native Figma files, ecosystem and established collaborative workflows | FigCraft offers local ownership and permissive code, but cannot promise feature-equivalent .fig round trips |
| [Inkscape](https://inkscape.org/) | Your main need is mature SVG/vector authoring | FigCraft's component/layout/prototype model fits interface design more directly, with much younger implementation |

These are workflow comparisons, not fresh comparative benchmarks or license audits of the alternatives. The related [PhotoCraft review](photocraft.md) covers another ArtCraft editor, not evidence that FigCraft inherits its format fidelity.

## Self-Hosting Notes

A local editor needs no collaboration server or model service. For a deliberate multiplayer trial, the separate server defaults to loopback and closed publishing; expose it only behind an authenticated/trusted network arrangement and TLS reverse proxy, with quotas, backups and restore tests. Do not casually enable open publishing or the team directory for confidential work. Keep server keys and owner tokens separate from review artifacts and logs. No deployment was performed. [E9]

**Practical acceptance gate:** use synthetic, disposable examples first; then authorized copies of representative design files. Compare fonts, images, masks/effects, auto layout, nested component overrides, variable modes and prototype actions before and after native save/reopen and destination reimport. Test crash recovery, conflicting saves, collaborator revocation and disconnected edits. Promote only the workflows that pass; retain the originals regardless.

## Evidence and Verification Limits

All source links below are pinned to the reviewed revision. Documentation claims, upstream CI results and this static inspection are distinct evidence classes. No clean-room legal audit, external dependency audit, dynamic security test or real-design interoperability certification is implied.

- **E1:** [README.md](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/README.md)
- **E2:** [docs/architecture.md](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/docs/architecture.md); [crates/engine/src/lib.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/engine/src/lib.rs)
- **E3:** [Cargo.toml](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/Cargo.toml); [Cargo.lock](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/Cargo.lock)
- **E4:** [crates/format/src/fig.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/format/src/fig.rs); [crates/format/src/fig/export.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/format/src/fig/export.rs); [docs/file-format-parity.md](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/docs/file-format-parity.md)
- **E5:** [crates/mcp/src/headless.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/mcp/src/headless.rs); [docs/mcp.md](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/docs/mcp.md)
- **E6:** [docs/penpot.md](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/docs/penpot.md); [crates/format/src/penpot.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/format/src/penpot.rs); [crates/format/src/penpot/export.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/format/src/penpot/export.rs)
- **E7:** [crates/engine/src/guard.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/engine/src/guard.rs)
- **E8:** [apps/figcraft/src/main.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/apps/figcraft/src/main.rs); [crates/ui-egui/src/dialogs/updates_ui.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/ui-egui/src/dialogs/updates_ui.rs)
- **E9:** [docs/server.md](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/docs/server.md); [apps/figcraft-server/src/config.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/apps/figcraft-server/src/config.rs); [apps/figcraft-server/src/codes.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/apps/figcraft-server/src/codes.rs)
- **E10:** [docs/control-protocol.md](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/docs/control-protocol.md); [apps/figcraft/src/control_server.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/apps/figcraft/src/control_server.rs); [crates/engine/src/automation/file_access.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/engine/src/automation/file_access.rs)
- **E11:** [crates/plugin/src/sandbox.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/plugin/src/sandbox.rs); [crates/plugin/src/manifest.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/plugin/src/manifest.rs); [crates/engine/src/extensions/plugins.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/engine/src/extensions/plugins.rs)
- **E12:** [crates/format/src/lib.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/format/src/lib.rs)
- **E13:** [crates/engine/src/cmd/file/save.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/crates/engine/src/cmd/file/save.rs)
- **E14:** [Public metadata](https://api.github.com/repos/storytold/figcraft); [v0.14.0](https://github.com/storytold/figcraft/releases/tag/v0.14.0).
- **E15:** [.github/workflows/ci.yml](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/.github/workflows/ci.yml); [xtask/src/main.rs](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/xtask/src/main.rs); [CI](https://github.com/storytold/figcraft/actions/runs/41340566220); [SonarCloud](https://github.com/storytold/figcraft/actions/runs/41340566210); [FreeBSD](https://github.com/storytold/figcraft/actions/runs/41377503322).
- **E16:** [LICENSE-MIT](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/LICENSE-MIT); [LICENSE-APACHE](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/LICENSE-APACHE); [NOTICE](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/NOTICE); [ATTRIBUTION.md](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/ATTRIBUTION.md); [docs/brand/LICENSE-brand.txt](https://github.com/storytold/figcraft/blob/bd920fc7dec63ee8d433884a175f2f581cc9eb87/docs/brand/LICENSE-brand.txt)

---

**Attribution:** ArtCraft Team and FigCraft contributors, [storytold/figcraft](https://github.com/storytold/figcraft). Code is MIT OR Apache-2.0; preserve applicable licenses and NOTICE on reuse. Fonts/dependencies retain their own terms. ArtCraft brand assets are expressly non-open-source and must be removed from distributed modified forks except the stated contribution exception. This review copies no artwork, fonts or project code. [E16]
