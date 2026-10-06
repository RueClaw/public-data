# PhotoCraft (storytold/photocraft)

**Repo:** https://github.com/storytold/photocraft
**License:** MIT OR Apache-2.0 (free extraction and reuse)
**Reviewed:** 2026-10-05
**Stack:** Pure Rust (23 crates, ~235K lines), egui/eframe UI on wgpu, WebAssembly build, CLI + JSON control channel + MCP server
**What it is:** An open-source, clean-room reimplementation of Adobe Photoshop in pure Rust — layers, masks, adjustment layers, type, vectors, brushes, and real PSD read/write — with every action exposed as a command drivable from the UI, CLI, or an agent over MCP.

---

## Verdict

⚠️ **Interesting — the agent-facing image engine is the story, not the Photoshop clone.** The codebase is real and verified: two crates built and tested clean on the first try (psd: 119/119, compose: 122/122), 2,675 `#[test]` functions, corpus tests against psd-tools/ag-psd/PngSuite fixtures with sha256 pins, and an honest alpha disclaimer ("not yet a Photoshop replacement for daily professional work"). The caveats are equally real: the repo is six days old (created 2026-09-30), ~235K lines landed in 270 commits — unmistakably AI-velocity development (lead author "echelon", 189 commits) — so internal consistency and long-term maintenance are unproven, and every feature claim beyond the two crates tested here is self-reported. For agent-driven image manipulation (batch edits, PSD automation, thumbnail/asset pipelines) the CLI + MCP + 500-command registry is immediately the most interesting surface; the desktop app is a wait-and-see.

---

## What It Is

PhotoCraft aims at 1:1 Photoshop parity — same menus, shortcuts, behavior, and file fidelity — as a native Rust app with no Electron/Tauri/webview anywhere (egui on wgpu; the same Rust compiles to WASM for the web build). It's one of seven "Crafting Apps" from the ArtCraft/storytold team, all pure-Rust clean-room creative tools.

The architecture is engine-first: a pure-data document model, a command engine with a single registry of 500+ commands, and a thin UI on top. Layering across 23 crates is enforced at build time (L0 foundation: geometry, ICC color, raster/COW tiles → L1 document model → L2 brush/type/vector engines → L3 dual compositors → L4 format IO → UI). A CPU compositor serves as the correctness oracle for the wgpu GPU compositor; they're tested against each other.

Because every menu item and tool runs through the command registry, the UI, `photocraft-cli`, a JSON control channel, and an MCP server all drive the same engine. The CLI does headless open/edit/save and folder batching with recorded action lists; the desktop app exposes an authenticated loopback-only control channel for UI-state inspection, synthetic pointer events, and offscreen screenshots.

## Stack

| Layer | Tech |
|-------|------|
| Language | Rust only — no JS/TS, no webview (hard rule in AGENTS.md) |
| UI | egui/eframe on wgpu (Metal/Vulkan/DX12/WebGPU); WASM web build |
| Engine | Pure-data doc model, COW 256² sparse tiles, dual CPU/GPU compositors |
| Color | ICC color management in pure Rust, 8/16/32-bit, RGB/CMYK/Lab/Grayscale |
| Formats | PSD/PSB (standalone crate from Adobe's public spec) + PNG/JPEG/TIFF/WebP/GIF/EXR/AVIF/etc., native `.pcraft` |
| Agent surface | 500+ command registry, CLI, JSON control channel, MCP server |
| Tests | 2,675 test fns; corpora: psd-tools, ag-psd, PngSuite + own Photoshop-authored oracle PSDs, sha256-pinned |

## Key Features

### Agent-ready by construction

Every action is a command in one registry; UI, CLI, control channel, and MCP are peers. Headless batch: `photocraft-cli batch --actions grade.json --in ./raw --out ./graded`. This is the right pattern for any desktop app that wants agent automation — no separate API to drift out of sync with the UI.

### PSD support measured against oracles

Claims are specific and falsifiable: re-saving renders the same for 307/309 psd-tools test files and 169/170 in a mixed corpus; the standalone `photocraft-psd` crate round-trips every parseable corpus file byte-for-byte; a composite oracle compares renders against Photoshop's own merged image; unmodeled blocks are carried through rather than dropped. Corpora are fetched via xtask and sha256-verified.

### Engineering discipline unusual for its age

Build-time-enforced crate layering; `unsafe` isolated to a single tablet-input crate; hostile-input fuzz tests in the format crates (`hostile_input_errors_without_panicking`); a generated parity doc and scorecard that explicitly list what doesn't work, including "settings that do nothing"; README screenshots rendered offscreen through its own control channel.

### Full editing surface (self-reported)

34 tools, a real brush engine (dynamics, scattering, pen pressure/tilt), 16 adjustment layers, layer styles, smart objects with smart filters, type with canvas editing, vector shapes with boolean ops, 27 blend modes, ICC soft proofing on GPU. Six days in, treat depth claims as directional — the project's own parity doc says wiring ≠ behavior.

## Architecture

`geom cms color raster / psd codecs tablet` (L0) → `doc` (L1 pure-data model) → `ops paint algo text vector` (L2) → `compose gpu format` (L3) → `io plugins` (L4, plus sandboxed WASM plugins) → `automation ui-egui` (L5). The automation crate owns headless mode, the MCP server, the control-channel bridge, budgets, and workspace security — agent access is a first-class layer with its own security module, not an afterthought.

## Comparison

| Aspect | PhotoCraft | GIMP | Krita | ImageMagick |
|--------|-----------|------|-------|-------------|
| Model | Rust, engine-first, command registry | C/GTK, plugin scripts | C++/Qt | C CLI |
| PSD fidelity | 307/309 corpus render-parity (claimed) | Partial, lossy on modern features | Good import, weaker round-trip | Flatten-oriented |
| Agent driving | CLI + MCP + control channel, same registry as UI | Script-Fu/Python-Fu | Python scripting | Native CLI |
| Maturity | 6 days, early alpha | 30 years | 20 years | 35 years |

Versus Graphite (the other Rust Photoshop-ish project): PhotoCraft is a pixel-editor with PSD round-tripping and far more conventional surface; Graphite is a node-based procedural editor. Different bets.

## Self-Hosting / Build Notes

`cargo run --release -p photocraft -- image.psd` for the app; `cargo test --workspace` for the suite. Installers per release for macOS (signed/notarized), Windows, Linux (AppImage/deb/rpm/Flatpak), FreeBSD, and web. Corpus tests need `cargo xtask corpus --all` first. Optional `craft-fonts` checkout for Japanese UI/type fonts.

---

**Attribution:** storytold/photocraft, MIT OR Apache-2.0
