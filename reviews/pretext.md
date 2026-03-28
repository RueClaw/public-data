# pretext (@chenglou/pretext)

*Review #282 | Source: https://github.com/chenglou/pretext | License: MIT | Author: chenglou (Cheng Lou, ex-React core team, creator of React Motion) | Reviewed: 2026-03-28 | Stars: 1,604*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

A browser-accurate, DOM-free multiline text layout engine for JavaScript/TypeScript. Created three weeks ago (2026-03-07), initial npm release 2026-03-26 — two days ago. By Cheng Lou, who was on the React core team and created React Motion (the spring animation library that influenced Framer Motion). The related project note: `../text-layout/` — Sebastian Markbage's original prototype. Markbage is the current React architecture lead. This is serious React infrastructure work.

The problem it solves: measuring how many lines a text block will wrap to (for dynamic layout) requires reading from the DOM, which forces synchronous layout reflow. With 500 text blocks independently measuring themselves, each read/write interleave costs 30ms+ per frame. pretext replaces DOM measurement with canvas `measureText()` + cached arithmetic.

7680/7680 accuracy against Chrome, Safari, and Firefox. 0.09ms per `layout()` call on Chrome.

---

## The Core Problem

When you need to know "how tall will this text block be at 320px wide?" in a browser, the naive approach is:
1. Set element width to 320px
2. Read `element.offsetHeight`

In a React/virtual DOM context with many such elements, this pattern creates forced synchronous layouts (layout thrashing). Each DOM read forces the browser to flush all pending style/layout computations, which is O(document-size) work. At scale, this destroys frame rates.

pretext's answer: measure text width per-word using `canvas.measureText()` (which does NOT trigger reflow), cache those widths, then use pure arithmetic in a line-walk loop to compute line count and height. The DOM is only touched once per font to calibrate emoji correction (a constant per font size), then never again.

---

## API

```typescript
import { prepare, layout, layoutWithLines, walkLineRanges } from '@chenglou/pretext'

// Phase 1: analyze text + measure word widths (do once per text string)
const prepared = prepare('Hello world, this is some text', '16px Inter')

// Phase 2: compute line count + height at any width (pure arithmetic, ~0.09ms)
const { lineCount, height } = layout(prepared, 320 /* maxWidth */, 24 /* lineHeight */)

// Rich API: get actual line text + widths
const lines = layoutWithLines(prepared, 320, 24)
// lines = [{ text: 'Hello world,', width: 300.5 }, { text: 'this is some text', width: 298.2 }]

// Streaming API: one line at a time, for variable-width layout
const cursor = { segmentIndex: 0, graphemeIndex: 0 }
const line1 = layoutNextLine(prepared, 320, cursor) // advances cursor in place

// Non-materializing batch geometry: line ranges without string allocation
walkLineRanges(prepared, 320, 24, (start, end, width) => { /* ... */ })
```

The split between `prepare()` and `layout()` is the key performance architecture:
- `prepare()` is expensive (~12-20ms for typical paragraphs, ~63ms for long Arabic prose) — called once when text appears
- `layout()` is nearly free (~0.09ms Chrome, ~0.12ms Safari) — called on every resize

---

## Implementation: What Makes it Hard

**Segment model (8 break kinds):** The library distinguishes normal text, collapsible spaces, preserved spaces, tabs, non-breaking glue (NBSP/NNBSP/WJ-like runs), zero-width break opportunities (ZWSP), soft hyphens, and hard breaks. Each has different layout behavior.

**`Intl.Segmenter` for i18n:** Word and grapheme boundaries use the browser's own `Intl.Segmenter`. CJK text breaks at every character. Thai/Khmer have no visible word boundaries — the segmenter handles this. Arabic has right-to-left direction and complex shaping rules.

**Canvas measurement as oracle:** Each segment is measured via `ctx.measureText(segment).width`. The result is cached by `Map<font, Map<segment, width>>`. The cache is shared across all `prepare()` calls for the same font.

**Engine profile (browser-specific shims):** Safari and Chrome/Firefox have different line-fitting behavior for edge cases. The library detects the browser at runtime (via `navigator.userAgent`) and applies per-browser tolerances:
- Chromium/Gecko: `lineFitEpsilon = 0.005`
- Safari/WebKit: `lineFitEpsilon = 1/64`
- Browser-specific booleans: `carryCJKAfterClosingQuote`, `preferPrefixWidthsForBreakableRuns`, `preferEarlySoftHyphenBreak`

**Emoji correction:** Chrome and Firefox canvas measure emoji wider than DOM at font sizes <24px on macOS (Apple Color Emoji). The inflation is constant per emoji grapheme at a given size, font-independent. Auto-detected by comparing canvas vs actual DOM emoji width — one DOM read per font, cached forever.

**Kinsoku shunking (Japanese line breaking rules):** Certain punctuation characters cannot appear at the start or end of a line. The library implements kinsoku start/end character sets and merges prohibited punctuation into adjacent graphemes.

**`overflow-wrap: break-word`:** When a word is wider than the container, it must break at grapheme boundaries. This requires pre-measuring individual grapheme widths within the word — cached as `graphemeWidths[]` and cumulative `graphemePrefixWidths[]` on the segment.

**Soft hyphens:** `\u00AD` is invisible when unbroken but should display as `-` if chosen as the break point. The rich `layoutWithLines()` handles this in the returned line text.

**Bidi (RTL text):** Simplified bidi metadata on the `prepareWithSegments()` path only. The fast `prepare()` + `layout()` path doesn't compute bidi — paying for metadata that line breaking doesn't need.

---

## Accuracy Methodology

The accuracy suite is the most rigorous part of the project. It sweeps:
- 4 fonts × 8 font sizes × 8 container widths × 30 text samples = 7,680 combinations per browser
- Against real browsers via headless automation (separate browser-specific runners)
- Results checked into `accuracy/chrome.json`, `accuracy/safari.json`, `accuracy/firefox.json`
- 7680/7680 on Chrome, Safari, and Firefox (as of 2026-03-27)

Long-form corpora (prose texts in 12 scripts):

| Language | `prepare()` | `layout()` | Lines @ 300px |
|----------|------------|------------|---------------|
| Japanese | 12.6ms | 0.03ms | 380 |
| Korean | 11.4ms | 0.04ms | 428 |
| Chinese | 19.2ms | 0.05ms | 626 |
| Thai | 13.5ms | 0.05ms | 1,024 |
| Arabic | 63.5ms | 0.17ms | 2,643 |
| Hindi | 11.1ms | 0.04ms | 653 |
| Khmer | 10.4ms | 0.05ms | 591 |
| Urdu | 5.5ms | 0.03ms | 351 |

Arabic is the expensive case (complex shaping + 37,603 segments). But `layout()` is still only 0.17ms — the resize hot path is always fast.

**Miss taxonomy** (from `corpora/TAXONOMY.md`): The project has a formal classification system for accuracy failures:
- `corpus-dirty` — source text has artifacts (wrapped print lines, navigation scaffolding)
- `normalization` — wrong whitespace/NBSP/ZWSP handling
- `boundary-discovery` — wrong segmentation merge units
- `glue-policy` — right boundaries, wrong attachment rules
- `edge-fit` — browser keeps/drops a phrase by <1px at line edge
- `shaping-context` — break position changes shaping/glyph metrics (Arabic cursive connection)
- `font-mismatch` — canvas and DOM resolved different fonts
- `diagnostic-sensitivity` — mismatch may be in the probe, not the engine

This taxonomy is the sign of a serious research project, not a quick library.

---

## Benchmark (Chrome)

| Operation | Time | Notes |
|-----------|------|-------|
| `prepare()` short text | ~18.85ms | Measured once per text; parallelizable |
| `layout()` | ~0.09ms | Called on every resize; pure arithmetic |
| DOM batch (no interleave) | ~4.05ms | Baseline for comparison |
| DOM interleaved | ~43.50ms | What naive measurement costs |
| `layoutWithLines()` | ~0.05ms | Rich line API |
| `walkLineRanges()` | ~0.03ms | Non-materializing geometry |

The 10× DOM advantage only applies at scale (many text blocks). For a single measurement, DOM is fine. The library targets React/virtual-DOM contexts where many components measure independently.

---

## Corpora

The project ships actual literary texts for testing:
- Japanese: Rashomon (Ryūnosuke Akutagawa), Kumo no Ito
- Chinese: Guxiang, Zhufu (Lu Xun)
- Korean: Unseul Joh-eun Nal
- Arabic: Al-Bukhala (Al-Jahiz), Risalat al-Ghufran
- Hebrew: Masa'ot Binyamin Me-Tudela
- Hindi: Eidgah (Munshi Premchand)
- Thai, Khmer, Myanmar, Urdu prose
- Mixed app text (URLs, emoji ZWJ sequences, mixed-script punctuation)

---

## Who Made This

**Cheng Lou** (chenglou) is one of the more influential people in the React ecosystem. He created [React Motion](https://github.com/chenglou/react-motion) (the spring physics animation library, ~22K stars), was on the React core team at Facebook, and gave the [Taming the Meta Language](https://www.youtube.com/watch?v=_0T5OSSzxms) talk at React Conf 2017. The `CLAUDE.md` and `AGENTS.md` are identical (full internal notes for AI collaborators), which is notable — this is being actively developed with AI coding assistance as a first-class workflow.

**Sebastian Markbage** (`../text-layout/` referenced as the original prototype) is the current React architecture lead who designed React's concurrent mode, Server Components, and the streaming architecture. Two React core team members is meaningful signal for a 3-week-old library.

---

## Relevance

🔥🔥🔥🔥🔥 — Niche problem, but if you're building a React-based UI that needs to dynamically size text containers (chat bubbles, editorial layout, variable-height virtualized lists), this is the right tool. The canvas measurement approach is the standard solution; pretext makes it accurate across all browsers and scripts.

**Direct use cases:**
- The VOS frontend does text-heavy document review — if it needs any dynamic text sizing, this is the right primitive
- Any virtualizing list that shows text content (infinite scroll, chat history) where DOM measurement at scale causes frame drops
- The `walkLineRanges()` non-materializing API is particularly useful for "shrinkwrap to text" bubble layouts

**Extractable insight:** The two-phase measurement pattern (`prepare()` once, `layout()` on every resize) is the core insight. The same pattern applies to any case where you need to compute layout-dependent values at high frequency: measure the expensive parts once, cache, then compute from cache.

MIT. `npm install @chenglou/pretext` / `bun add @chenglou/pretext`. Cloned to `~/src/pretext`.
