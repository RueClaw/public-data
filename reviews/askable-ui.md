# askable-ui (askable-ui/askable)

*Review #291 | Source: https://github.com/askable-ui/askable | License: MIT (stated in README; no LICENSE file yet) | Author: askable-ui | Reviewed: 2026-03-30 | Stars: 2*

## Rating: 🔥🔥🔥🔥

---

## What It Is

A micro-library (~1kb gzipped) that gives LLMs awareness of what the user is currently looking at in a UI. One HTML attribute (`data-askable`), one observer call, one method to inject context into any LLM call. Framework adapters for React, Vue, Svelte. Python packages for Django and Streamlit.

2 stars, 2 days old. But the idea is sharp and the implementation is clean.

---

## The Problem

When a user clicks a revenue chart and asks "why is this dropping?", the LLM has no idea what chart they're talking about. It gives a generic answer about possible causes of revenue decline. The fix is obvious but tedious: serialize UI state, route it into the system prompt, maintain that plumbing across every component that might be relevant.

Askable makes that trivial.

---

## How It Works

**Three-step pattern:**

```
1. ANNOTATE   →  data-askable='{"chart":"revenue","delta":"-12%"}' on any element
2. OBSERVE    →  askable.observe(document) — one call, covers everything
3. INJECT     →  askable.toPromptContext() — drops a string into any LLM call
```

**Core implementation** (the actual code, not a description):

The `Observer` class uses:
- `querySelectorAll('[data-askable]')` to find all annotated elements on init
- A `MutationObserver` watching for dynamically added/removed nodes (covers React re-renders, virtual lists, etc.)
- Event listeners on each element for `click`, `mouseenter`, `focus` (configurable)
- When triggered: parses `data-askable` attribute (JSON or plain string), extracts `textContent`, emits a `focus` event with `{ meta, text, element, timestamp }`

`toPromptContext()` serializes the current focus to:
```
User is focused on: chart: revenue, delta: -12%, period: Q3 — value "Q3 Revenue: $2.3M"
```

That's the entire core: ~150 lines, zero dependencies.

---

## Architecture

```
packages/
├── core/          — zero-dep observer + context (~150 lines)
│   ├── observer.ts     — MutationObserver + event delegation
│   ├── context.ts      — AskableContext, toPromptContext()
│   ├── emitter.ts      — tiny EventEmitter
│   └── types.ts
├── react/         — <Askable> component + useAskable() hook
├── vue/           — <Askable> component + useAskable() composable
├── svelte/        — <Askable> + createAskableStore()
└── python/
    ├── django/    — {% askable %} template tags + auto-inject middleware
    └── streamlit/ — returns focus as Python dict
```

Bundle sizes: core ~1kb gz, each framework adapter ~0.5kb gz.

---

## Usage Patterns

**Basic annotation — works with any framework:**
```html
<div data-askable='{"metric":"revenue","delta":"-12%","period":"Q3"}'>
  <RevenueChart />
</div>
```

**React with the `<Askable>` wrapper:**
```tsx
// The same data prop renders the chart AND feeds the AI — no duplication
<Askable meta={data.revenue}>
  <RevenueChart data={data.revenue} />
</Askable>

// Pull context anywhere
function AIInput() {
  const { promptContext } = useAskable({ events: ['click'] });
  return <input onKeyDown={e => sendToLLM(promptContext, e.target.value)} />;
}
```

**"Ask AI" button pattern:**
```tsx
function RevenueCard({ data }) {
  const { askable } = useAskable();
  const ref = useRef<HTMLDivElement>(null);
  return (
    <Askable meta={data} ref={ref}>
      <RevenueChart data={data} />
      <button onClick={() => { askable.select(ref.current!); openChat(); }}>
        ✦ Ask AI
      </button>
    </Askable>
  );
}
```

**Works with any LLM SDK:**
```ts
// Anthropic
{ system: `UI context:\n${askable.toPromptContext()}` }

// OpenAI / Vercel AI SDK
{ role: 'system', content: `UI context:\n${askable.toPromptContext()}` }
```

---

## What Makes This Worth Noting

**The key insight:** The data that renders a component and the data an AI needs to answer questions about that component are usually identical. Askable makes you write it once. The `<Askable meta={data}>` pattern directly exploits this — same prop to both.

**MutationObserver coverage:** Handles dynamic UIs (React re-renders, infinite scroll, portals) without any extra wiring. Attach once to `document` and forget.

**Framework-agnostic core:** The `data-askable` attribute approach means it works with server-rendered HTML, web components, or any JS framework. The core has zero dependencies and no knowledge of React/Vue/etc.

**The "Ask AI" button UX pattern:** `askable.select(ref.current)` allows programmatic focus — so clicking "Ask AI" beside a specific chart tells the LLM what that chart contains, not what the user last clicked on.

---

## Relevance

**For VOS:** Directly applicable. VOS has multiple document sections, persona feedback panels, and review areas. When a user clicks a section and asks a follow-up question, the LLM could know exactly which paragraph/section/persona comment they're looking at. Three lines to wire up: annotate sections with `data-askable`, observe on mount, inject `toPromptContext()` into the chat system prompt.

**For any AI-first web app:** This solves a universal problem. Any app with both a UI and an AI chat/assistant interface benefits from this pattern.

---

## Caveats

- 2 days old, 2 stars. No battle-testing yet.
- No LICENSE file in repo (README says MIT — it's stated but not a formal file yet).
- `toPromptContext()` currently only formats one focused element. No built-in support for serializing multiple visible elements simultaneously — though you could call `getFocus()` and build a richer context manually.
- The Python packages exist but are thin wrappers. Streamlit/Django use cases are narrower than the JS ecosystem.
- No sanitization of `data-askable` values against prompt injection — worth noting if user-controlled data ends up in those attributes. The README doesn't address this.

---

## Verdict

🔥🔥🔥🔥 — Extremely tight abstraction over a real problem. The MutationObserver-backed observer means it actually works in modern reactive UIs, not just static pages. Zero-dep ~1kb core is the right architecture for something that belongs in every AI-enabled web app. The "same data renders and informs the AI" pattern is genuinely elegant. Brand new with no production track record, but worth keeping an eye on and worth lifting the pattern even if you don't take the dependency. MIT. Cloned to `~/src/askable`.
