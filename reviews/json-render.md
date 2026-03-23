# json-render

*Source: https://github.com/vercel-labs/json-render | License: Apache-2.0 | Author: Vercel Labs | Reviewed: 2026-03-23*

## Rating: 🔥🔥🔥🔥🔥

## One-liner
A generative UI framework from Vercel Labs — AI outputs constrained JSON specs, you render them across any target (React, Vue, Svelte, Solid, React Native, Remotion video, React PDF, HTML email, Ink terminal, Three.js 3D, OG images) with full streaming, state management, MCP Apps integration, and a 36-component shadcn catalog.

## What It Is

The core insight: instead of letting AI generate arbitrary UI code (unpredictable, unauditable), constrain AI output to a catalog you define. AI generates JSON specs; you render them with your components. The framework supplies the schema system, prompt generator, streaming parser, state management, and renderers.

**The pitch:**
- **Guardrailed** — AI can only use components you register in your catalog
- **Predictable** — JSON output always matches your schema
- **Streaming** — JSONL SpecStream format for progressive rendering
- **Cross-platform** — same catalog concept across 13+ render targets

## Packages (21 total)

| Package | What |
|---|---|
| `@json-render/core` | Schema, catalog, AI prompt gen, SpecStream, state-store interface |
| `@json-render/react` | React renderer + contexts + hooks |
| `@json-render/vue` | Vue 3 renderer |
| `@json-render/svelte` | Svelte 5 renderer (runes-based) |
| `@json-render/solid` | SolidJS renderer |
| `@json-render/shadcn` | 36 pre-built shadcn/ui components (Radix + Tailwind) |
| `@json-render/react-three-fiber` | 3D scene renderer (19 built-in Three.js components) |
| `@json-render/react-native` | Mobile renderer (25+ standard components) |
| `@json-render/remotion` | Video timeline renderer |
| `@json-render/react-pdf` | PDF document renderer |
| `@json-render/react-email` | HTML email renderer |
| `@json-render/ink` | Terminal UI renderer (Ink-based) |
| `@json-render/image` | SVG/PNG output via Satori (OG images, social cards) |
| `@json-render/mcp` | MCP Apps server — renders UIs inline in Claude/ChatGPT/Cursor/VS Code |
| `@json-render/codegen` | Generate code from UI trees |
| `@json-render/yaml` | YAML wire format with streaming parser |
| `@json-render/redux/zustand/jotai/xstate` | State store adapters |

## Core Architecture

**Spec format** — flat element map with a root key:
```json
{
  "root": "card-1",
  "elements": {
    "card-1": { "type": "Card", "props": { "title": "Hello" }, "children": ["btn-1"] },
    "btn-1": { "type": "Button", "props": { "label": "Click" }, "children": [] }
  }
}
```

**Catalog → prompt → spec → render loop:**
1. Define catalog (component name → Zod props schema + description)
2. Call `catalog.prompt()` to get a typed system prompt for the AI
3. AI generates a JSON spec constrained to catalog components
4. Stream spec chunks through `createSpecStreamCompiler`
5. Render with `<Renderer spec={spec} registry={registry} />`

**Dynamic props** — any prop value can be an expression:
```json
{ "color": { "$cond": { "$state": "/activeTab", "eq": "home" }, "$then": "#007AFF", "$else": "#8E8E93" } }
```
Expression types: `$state` (read from state model), `$cond`/`$then`/`$else` (conditional), `$template` (string interpolation with state), `$computed` (registered function call), `$bindState` (two-way binding).

**Visibility** — conditional show/hide:
```json
{ "visible": [{ "$state": "/form/hasError" }, { "$state": "/form/errorDismissed", "not": true }] }
```

**State watchers** — react to state changes, trigger actions:
```json
{ "watch": { "/form/country": { "action": "loadCities", "params": { "country": { "$state": "/form/country" } } } } }
```

**SpecStream** — JSONL patches for progressive streaming. `createSpecStreamCompiler` processes chunks incrementally, returning `{ result, newPatches }` per chunk. Renderers can display partial UI as streaming proceeds.

## MCP Apps Integration

The `@json-render/mcp` package creates an MCP server that serves a json-render UI as an interactive iframe embedded in Claude/ChatGPT/Cursor/VS Code conversations. Architecture:

1. Define your catalog and components
2. Bundle your React app (with `vite-plugin-singlefile`) into a single HTML string
3. `createMcpApp({ name, version, catalog, html })` creates the MCP server
4. Client receives both the tool result (JSON spec) and the iframe UI

The iframe side uses `useJsonRenderApp()` hook which connects to the MCP host, receives spec updates, and re-renders. This is MCP Apps — an extension to MCP that returns interactive HTML instead of text. Supported by Claude, ChatGPT, VS Code Copilot, Cursor, Goose.

## Skills Directory

The repo ships `skills/` at the repo root — per-renderer SKILL.md files covering the API for each package. These work directly in Claude Code or any skill-aware coding agent. Essentially, they've packaged their own documentation as agent-consumable skills. Smart.

## Examples (13 working demos)

- `examples/chat` — AI chat with tool-driven UI generation
- `examples/dashboard` — finance dashboard with Drizzle DB, sortable widgets, full REST API
- `examples/game-engine` — Three.js game with AI-controlled characters, TTS dialogue
- `examples/image` — OG image generation
- `examples/ink-chat` — terminal chat with Ink renderer
- `examples/mcp` — MCP Apps example (Vite + single-file bundle)
- `examples/no-ai` — static spec rendering without AI
- `examples/react-email` — email generation with send
- `examples/react-native` — Expo mobile app
- `examples/react-pdf` — PDF generation
- `examples/remotion` — AI-generated video
- `examples/stripe-app` — Stripe drawer/fullpage app extensions
- `examples/svelte-chat` — Svelte version of the chat example

## Honest Assessment

**What's genuinely impressive:**
- The renderer abstraction is solid — catalog + spec + renderer is the right separation. AI stays in its lane (JSON), rendering stays in yours.
- Breadth of render targets is remarkable: web, mobile, video, PDF, email, terminal, 3D, OG images, MCP Apps — all from the same catalog concept.
- The MCP Apps integration is forward-looking. Inline interactive UIs in Claude conversations is the direction things are going.
- Excellent test coverage across packages.
- The skills directory is clever self-documentation.
- `$bindState`, `$cond`, `$computed` expressions give specs real dynamism without arbitrary code execution.

**Concerns:**
- Apache-2.0 is clean, but Vercel Labs provenance means this could pivot to enterprise licensing if it takes off (see: next.js trajectory).
- The framework requires significant boilerplate — defining catalog, registry, and renderer per component. Worth it at scale; probably overkill for simple use cases.
- Relies on AI reliably honoring the catalog constraint. In practice, models occasionally hallucinate component names or invalid props — the spec validator (`packages/core/src/spec-validator.ts`) catches this, but the UX on fallback is up to you.
- The game-engine example with AI character dialogue is impressive but illustrates scope creep — this is now a game engine?

## Relevance

**High.** This is directly relevant to:
- **VOS (OpinionatedDocReviewer)** — the meta-critic rendering problem (show AI feedback in structured UI components) is exactly what json-render solves. Could replace the current TanStack Table + custom rendering with a proper catalog-driven approach.
- **Marcos (Parkinson's agent)** — generating dynamic, personalized UI for a non-technical user from AI output without risking arbitrary code execution.
- **Any agent that needs to produce UI** — the MCP Apps integration means you can drop this into any Claude tool and get rich interactive output instead of text.

## License
Apache-2.0 (Vercel Inc., 2025) — permissive, use freely.
