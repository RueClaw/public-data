# Shaders (shader-effects-inc/shaders)

**Repo:** https://github.com/shader-effects-inc/shaders
**License:** MIT (free extraction and reuse; the hosted editor/presets at shaders.com are separate commercial terms)
**Reviewed:** 2026-10-05
**Stack:** TypeScript monorepo (pnpm + turbo), WebGPU/WGSL via TypeGPU, framework bindings for React/Vue/Svelte/Solid/vanilla JS generated from one core
**What it is:** 200+ WebGPU shader effects packaged as declarative components — gradients, noise, glass, metal, distortions, transitions, cursor effects — with one props API across five frameworks, plus a CLI and MCP server that connect a codebase to the shaders.com design editor.

---

## Verdict

✅ **Deploy candidate for web UI work.** The engineering is verified, not vibes: `pnpm install` + full test suite ran clean locally — **267 test files, 1,780 tests, all passing in 26s**. The architecture is the right one: a single `packages/core` engine with one folder per effect, and framework bindings *generated* from it, so React/Vue/Svelte/Solid/JS never drift. Custom effects are plain `defineShader` objects with WGSL paint functions. Caveats: the public repo is a week old (created 2026-09-29, though the platform behind it is established — "16,000+ design engineers" predates open-sourcing), the CLI/MCP/editor workflow funnels toward a shaders.com account (free tier works, Pro is the business model), and WebGPU means no Safari < 26 / older-browser fallback story beyond what you build yourself.

---

## What It Is

Shaders (from Shader Effects Inc., the shaders.com platform) packages WebGPU effects as components. `<Shader>` renders the canvas; children are layers evaluated top-to-bottom and blended on the GPU. Effects nest, blend, and mask. The same component names and props work identically in React, Vue, Svelte, Solid, and vanilla JS because the bindings are code-generated from the core engine.

The surrounding platform: a visual design editor at shaders.com (free with account) exports the exact component tree for your framework; a CLI (`npx shaders connect/install/update`) syncs designed effects into your repo as real component files with a lock file; an MCP server (`npx shaders install-mcp`) lets coding agents find, install, and edit shaders; and `llms.txt`/`llms-full.txt` carry the full component reference for agents. Pro adds 1,000+ presets, website sections, watermark-free HD rendering, and a Framer plugin.

Custom components are first-class: `defineShader({ name, props, paint: wgsl\`...\` })` with typed prop transforms, mountable via `<CustomShader>` like any built-in.

## Stack

| Layer | Tech |
|-------|------|
| Language | TypeScript, ESM, `sideEffects: false` |
| GPU | WebGPU + WGSL via TypeGPU (typed GPU resources, SSR-safe) |
| Monorepo | pnpm workspaces + turbo; `packages/{core,js,react,vue,svelte,solid,shaders,partner}` |
| Components | 199 effects in `packages/core/src/shaders/`, one folder each |
| Bindings | Generated from core — single source of truth |
| CLI/MCP | `shaders` bin: connect/install/update/install-mcp |
| Tests | 267 files, 1,780 tests — verified passing locally |
| Version | v4.0.0 (npm `shaders`) |

## Key Features

### One engine, generated bindings

Framework packages are generated from `packages/core`, so the API can never drift between React and Vue. This is the correct answer to "we support N frameworks" — most multi-framework libraries hand-maintain bindings and rot.

### Composable GPU layer tree

Effects are children of `<Shader>`, evaluated in order and blended on GPU: gradients under distortions under cursor trails, with masks. Composition is declarative — the design editor emits exactly this tree.

### Agent integration done properly

Three surfaces: MCP server (install/edit/find shaders), CLI (component files land in your repo with a lock file — diffable, reviewable, not a runtime fetch), and `llms-full.txt` with every prop, default, and range. The CLI-writes-real-files approach means agent-installed effects are just code in your repo.

### Verified test suite

1,780 tests across 267 files covering the engine, GPU layer compilation, and per-component behavior. Runs in 26 seconds. For a graphics library, that's an unusually serious correctness surface.

## Architecture

`packages/core` holds the engine: `shaderRegistry`, GPU layer compilation (TypeGPU), `customShaders`, `presetRenderer`, `performanceTracker`, and the 199 component folders. Framework packages wrap core via codegen. `packages/shaders` is the umbrella npm package (`shaders/react`, `shaders/vue`, `shaders/std`, etc. subpath exports) plus the CLI. Prop transforms (`transformColor`, `transformPosition`) normalize declarative props into GPU uniforms; the `paint` function is WGSL compiled through TypeGPU's typed resolution.

## Comparison

| Aspect | Shaders | paper-design/shaders (predecessor) | Three.js / raw WebGPU | CSS/SVG effects |
|--------|---------|------------------------------------|-----------------------|-----------------|
| Model | Component library + platform | Earlier version of same | DIY engine | No GPU |
| Frameworks | 5, generated bindings | React-only historically | Framework-agnostic | All |
| Effects | 200+ built-in + custom WGSL | ~40 | Write your own | Limited |
| Agent story | CLI + MCP + llms.txt | None | None | N/A |
| License | MIT | MIT | MIT | N/A |

This is the open-sourced evolution of the Paper design tool's shader library, now framework-general and agent-wired. Versus Three.js, the bet is that 200+ production-tuned declarative effects beat a general engine for the 95% of web shader use that is "make this section look expensive."

## Self-Hosting / Usage Notes

`npm install shaders` — the library is fully client-side and works account-free. Account features (editor projects, CLI sync, Pro presets) are additive. Build from source: `pnpm install && pnpm lib:build && pnpm test`. WebGPU baseline: Chrome/Edge 113+, Safari 26+, Firefox 141+; plan a static/CSS fallback for older browsers since there's no WebGL fallback path.

---

**Attribution:** shader-effects-inc/shaders, MIT
