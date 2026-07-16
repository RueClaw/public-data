# Bolt Slides (stackblitz/bolt-slides)

**Repo:** https://github.com/stackblitz/bolt-slides  
**License:** MIT; permissive reuse with attribution  
**Reviewed:** 2026-07-16  
**Stack:** TypeScript, React 18, Vite 5, Framer Motion, Canvas2D  
**What it is:** A React/Vite presentation-deck starter where each slide is a responsive web component instead of a fixed slide canvas. It pairs a polished deck engine with an agent-facing Bolt skill for generating bespoke interactive decks.

---

## Verdict

✅ **Deploy candidate for agent-authored interactive decks.** The core idea is strong: treat a presentation as a real web app, keep the deck chrome stable, and let agents compose topic-specific slides from responsive React components. It is young and template-shaped rather than a mature publishing product, but the engine, component library, authoring guide, CI, and MIT license make it immediately useful for forks and experiments.

---

## What It Is

Bolt Slides is a starter app for making presented slide decks that can contain normal web UI: live data views, charts, 3D/canvas scenes, code windows, browser mockups, annotations, presenter notes, and click-build reveals. The README frames it as an answer to generic AI slide output: agents should not just fill bullet templates, they should author a responsive web presentation.

The repository has two main parts. `src/deck/` is the reusable deck engine: keyboard navigation, hash deep links, thumbnail rail, grid overview, click-build state, annotations, fullscreen, and synced presenter mode. `src/components/` is the visual slide kit: cover, split layouts, bento grids, charts, timeline, comparison, pricing, team, globe, code windows, browser frames, and other common presentation blocks.

The unusual part is `.bolt/skills/slides/SKILL.md`, a long agent-facing authoring guide. It tells an agent to leave the engine alone, delete the demo content, theme the deck through CSS tokens, write original slides from the user's real input, and verify responsive behavior. That makes the repo less like a component library and more like a packaged design workflow for coding agents.

## Stack

| Layer | Tech |
|-------|------|
| App shell | Vite, React 18, TypeScript |
| Motion | Framer Motion |
| Presentation engine | Custom React state, keyboard handlers, URL hash sync |
| Presenter sync | Browser `BroadcastChannel` |
| Persistence | `localStorage` for editable presenter notes |
| Visuals | CSS tokens, Canvas2D globe and annotation layer |
| CI | GitHub Actions: `npm ci`, `npx tsc --noEmit`, `npm run build` |

## Key Features

### Web-Native Slide Engine

Slides are top-level React children inside `<Deck>`, not a fixed 16:9 canvas. The engine supports keyboard navigation, click-builds, grid view, thumbnail sidebar, fullscreen, hash links, and a presenter window. That is a pragmatic middle ground: the presenter experience still feels like slideware, but each slide can be real responsive UI.

### Content-Anchored Annotations

The annotation layer is better than a simple absolute canvas overlay. Strokes are stored as data and anchored to the block element under their center using a child-index path from the slide stage. When the same slide reflows on another viewport, the annotation resolves against the corresponding element instead of just scaling against the screen.

### Agent-Facing Authoring Skill

The bundled Bolt skill is the most valuable artifact in the repo. It gives agents concrete design rules: do not regenerate the engine, author from the user's real input, center text-only slides, theme only through tokens, set title/favicon, choose layouts by story need, and test narrow viewports. That turns subjective "make a nice deck" work into a reusable operating procedure.

### Useful Component Kit

The component library covers enough common pitch/report/storytelling patterns to keep agents from reinventing every slide. The better pieces are the structural components (`Cover`, `Slide`, `Split`, `Bento`, `StatGrid`), story components (`Comparison`, `Timeline`, `Steps`, `Quote`), product components (`CodeWindow`, `BrowserFrame`), and interactive visual components (`Globe`, charts, annotations).

## Architecture

The architecture is intentionally small:

- `src/deck/Deck.tsx` owns navigation state, build state, overlays, presenter mode, hash sync, and cross-tab sync.
- `src/deck/Slide.tsx`, `Build.tsx`, and `Reveal.tsx` provide the core slide authoring primitives.
- `src/deck/Annotator.tsx` is a self-contained canvas annotation system.
- `src/components/` is a flat set of presentation components using shared CSS tokens.
- `src/styles/tokens.css` is the primary theme surface.
- `src/App.tsx` is explicitly disposable demo content.

The main design decision is the "locked engine, disposable content" split. That is the right boundary for agent-generated decks: agents can safely work in `App.tsx` and tokens while leaving navigation, annotations, and presenter behavior intact.

Security-wise, the app is mostly client-side and low-risk. There are no hardcoded secrets or server-side auth surfaces. Presenter notes persist to localStorage, which is appropriate for a local/published deck but worth remembering if decks contain sensitive speaker notes. `BroadcastChannel('deck-sync')` is same-origin scoped, so it is not a cross-site channel, but multiple decks on the same origin could collide unless the channel name is made deck-specific.

The main dependency caveat is dev-only: `npm audit` reports Vite/esbuild development-server advisories, while `npm audit --omit=dev` is clean. Published static decks are much less exposed than a shared dev server, but maintainers should still bump Vite when convenient.

## Comparison

| Aspect | Bolt Slides | Slidev | Reveal.js |
|--------|-------------|--------|-----------|
| Authoring model | React components plus agent skill | Markdown/MDX-centered slide authoring | HTML/Markdown slide authoring |
| Layout behavior | Responsive web layouts | More slide-canvas oriented | Usually fixed/presentation oriented |
| Agent fit | Strong: explicit authoring rules and component kit | Good, but agents must learn more conventions | Generic, less opinionated |
| Presenter chrome | Built-in sidebar, grid, annotations, presenter notes | Mature presenter workflow | Mature presentation controls |
| Maturity | Very new template | Established ecosystem | Established ecosystem |

## Self-Hosting Notes

This is a static Vite app. For local authoring:

```bash
npm install
npm run dev
```

For validation:

```bash
npx tsc --noEmit
npm run build
```

The reviewed checkout passed typecheck and production build on 2026-07-16. Production deployment should be straightforward to any static host. Do not expose the Vite dev server to untrusted networks without upgrading the dev toolchain and reviewing Vite server settings.

---

**Attribution:** stackblitz/bolt-slides, MIT
