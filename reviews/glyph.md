# Glyph

*Source: https://github.com/semos-labs/glyph | License: MIT | Author: Semos Labs | Reviewed: 2026-03-23*

## Rating: 🔥🔥🔥🔥🔥

## One-liner
A React renderer for full-screen terminal UIs — Flexbox layout via Yoga, double-buffered framebuffer with character-level diffing, 20+ built-in components, proper focus management with tab scopes and modal trapping, vim-style JumpNav, Kitty/iTerm2 image protocol support, and mouse events. The TypeScript equivalent of Textual.

## What It Is

`bun create @semos-labs/glyph my-app` → React TUI app. Same component model as a web app, renders to the terminal instead of the DOM.

**The stack:**
- React 18 custom reconciler → GlyphNode tree
- Yoga flexbox for layout (same engine as React Native)
- Double-buffered framebuffer → character-level diff → stdout
- ANSI escape codes for color, styling, cursor positioning

**Version:** v0.2.10 (active, recent commits)

## Architecture

The render pipeline is textbook clean:
```
React reconciler → GlyphNode tree → Yoga layout → framebuffer rasterization → char diff → stdout
```

**Custom reconciler** (`reconciler/hostConfig.ts`): Full React 18 reconciler implementing mutation-mode lifecycle. Creates/updates/removes GlyphNodes and GlyphTextInstances. Properly implements the react-reconciler v0.31 priority methods. This is not trivial — getting a custom reconciler right is substantial work.

**Framebuffer** (`paint/framebuffer.ts`): Double-buffered. Each cell: `{ ch, fg, bg, bold, dim, italic, underline, strikethrough }`. `clear()` mutates in place, zero allocations (cells pre-allocated at construction, reset on clear, never GC'd during a frame). Only changed cells emit ANSI sequences to stdout. For busy UIs this matters — Ink does full re-renders to stdout.

**Image protocol** (`runtime/imageProtocol.ts`): Supports Kitty Graphics Protocol AND iTerm2 Inline Images. Auto-detects terminal capabilities. Handles tmux passthrough. This is rare — most TUI frameworks don't touch image rendering at all.

**Yoga layout** (`layout/yogaLayout.ts`): Full flexbox — rows, columns, wrapping, alignment, gaps, padding. No manual coordinate math. Same engine as React Native, so if you know RN layout you know Glyph layout.

## Component Library (20+)

**Layout:** `Box`, `Spacer`
**Text:** `Text` (bold, dim, italic, underline, strikethrough, color, bg, hex, RGB)
**Form controls:** `Input`, `Button`, `Checkbox`, `Radio`, `Select`
**Lists:** `List`, `Menu`, `ScrollView` (with virtualization — tested at 10k+ items)
**Overlays:** `Portal`, `FocusScope`, `Dialog`, `Toast`
**Utilities:** `Keybind`, `JumpNav`, `Progress`, `Spinner`, `Image`, `StatusBar`, `DebugOverlay`

The `JumpNav` is distinctive — displays letter hints on focusable elements (vim-style `f`/`F` navigation). `FocusScope` traps focus inside a modal. These are the details that separate "we have components" from "we have a focus system."

## Focus System

Tab navigation is automatic — Glyph tracks a focus registry, Tab/Shift-Tab cycles through focusable elements in DOM order. `FocusScope` creates an isolated focus group (modal dialogs, drawers). JumpNav overlays letter hints on all registered focusables for quick jump.

Hooks: `useFocus`, `useFocusable`, `useFocusRegistry`.

## Comparison to Ink

Ink is the incumbent React TUI framework. Glyph is explicitly better on every technical axis:

| | Glyph | Ink |
|---|---|---|
| Components | 20+ built-in | ~4 (Box, Text, Spacer, Newline) |
| Focus system | Tab + scopes + trapping + JumpNav | Basic |
| Rendering | Character-level diff | Full re-render |
| Framebuffer | Double-buffered | No |
| Images | Kitty + iTerm2 | No |
| Dialogs/Toasts | Built-in | No |
| Mouse | Yes | No |
| Virtualized lists | Yes (10k+ items) | No |
| Maintenance | Active | Slow |

Ink has mindshare and a larger ecosystem. Glyph has better engineering. For new projects: Glyph.

Note: json-render's `@json-render/ink` package uses Ink, not Glyph — if integrating json-render with a terminal renderer, Glyph would be the better rendering layer (would require a custom json-render package).

## Examples (24 total)

- `examples/dashboard` — full task manager with all components
- `examples/virtualized-list` — 10k+ item ScrollView
- `examples/jump-nav` — vim-style navigation hints
- `examples/modal-input` — dialog with focus trapping
- `examples/forms-demo` — Checkbox, Radio, Input, Select
- `examples/image` — Kitty/iTerm2 image rendering
- `examples/mouse-demo` — mouse event handling
- `examples/rich-table` — sortable, interactive table
- `examples/markdown-demo` — terminal markdown rendering (via `glyph-markdown` package)
- `examples/benchmark` — perf testing

## glyph-markdown Package

Separate `@semos-labs/glyph-markdown` package for rendering Markdown in the terminal — syntax highlighting, proper inline formatting. Not shown in examples much but present and usable.

## Semos Labs Ecosystem

The README lists two real apps built on Glyph:
- **Aion** — calendar/time management TUI (`semos-labs/aion`)
- **Epist** — Gmail client for the terminal (`semos-labs/epist`)

These are products, not demos. That's meaningful signal about production readiness.

## CLAUDE.md

Ships a `CLAUDE.md` at repo root with Bun-specific rules (use `bun` instead of `node`/`npm`/`vite`, etc.). Lightweight, project-specific, agent-ready.

## What to Take From This

**High value for agent TUIs:** glyph-cli (reviewed yesterday) uses Ink for its OpenTUI. Glyph would be a more capable rendering layer — better components, diffed rendering, mouse support, image support. If building a terminal UI for the Marcos agent or any interactive agent interface, Glyph is the right choice over Ink.

**Framebuffer pattern** (`paint/framebuffer.ts`) — the zero-allocation, in-place clear pattern is worth studying for any performance-sensitive rendering work.

**Custom reconciler** (`reconciler/`) — clean reference implementation of a React 18 custom renderer targeting a non-DOM environment. Useful if you ever need to render React to something unusual.

**Kitty image protocol** (`runtime/imageProtocol.ts`) — clean implementation of both Kitty and iTerm2 protocols with tmux passthrough. Copy this if you ever need terminal image rendering.

## License
MIT (Semos Labs, 2026)
