# pretext

- **Repo:** <https://github.com/chenglou/pretext>
- **License:** MIT
- **Commit reviewed:** `7aacd78` (2026-04-15)

## What it is

Pretext is a **pure JS/TS multiline text measurement and layout library** that tries to answer a deceptively annoying question:

> how tall will this paragraph be, or how will it wrap, without touching the DOM?

Its core move is to split the problem into two phases:
- `prepare()` does the expensive one-time text analysis and canvas measurement work
- `layout()` does the hot-path reflow math with no DOM reads and no new text measurement

That alone is useful. What makes the repo interesting is that it is not just a canvas-measurement toy. It is a **browser-oracle-driven, multilingual text layout engine** with a lot of empirical validation behind it.

## Core architecture

### 1. Two-phase pipeline
This is the heart of the project.

- `prepare(text, font, options)`
  - normalize whitespace
  - segment text
  - merge or glue specific punctuation/script patterns
  - measure segments via canvas
  - build cached segment data
- `layout(prepared, maxWidth, lineHeight)`
  - pure arithmetic over cached widths
  - no DOM reads
  - no canvas calls
  - designed for resize hot paths

That separation is clean and absolutely the right design center for the problem.

### 2. Text analysis as a first-class subsystem
A lot of libraries hand-wave this part. Pretext does not.

`src/analysis.ts` is full of explicit modeling for:
- whitespace modes (`normal`, `pre-wrap`)
- `word-break: normal` and `keep-all`
- break kinds like text, space, preserved-space, tab, glue, zero-width-break, soft-hyphen, hard-break
- CJK detection and kinsoku-style punctuation rules
- Arabic-script handling
- script- and punctuation-specific glue policies

That is where much of the real value lives.

### 3. Measurement engine with browser-profile shims
`src/measurement.ts` keeps cached segment metrics and just enough engine profiling to be practical:
- browser-specific line-fit epsilon
- Safari vs Chromium handling differences
- emoji correction when canvas and DOM disagree
- fallback modes for breakable-run fit calculations

That is pragmatic engineering, not purity theater.

### 4. Rich manual layout escape hatch
The core API is paragraph-oriented, but the repo also exposes richer layout primitives:
- `prepareWithSegments`
- `layoutWithLines`
- `walkLineRanges`
- `layoutNextLineRange`
- `materializeLineRange`
- rich inline helper at `@chenglou/pretext/rich-inline`

That makes it more than just “height prediction.” It becomes a userland layout substrate for custom rendering paths.

## What is technically interesting

### 1. It treats browsers as the oracle, not as the enemy
This is the repo’s best quality.

A lot of text-layout projects drift into fantasy-land where they quietly become their own rendering model. Pretext stays grounded in browser behavior and keeps asking:
- what do Chrome, Safari, and Firefox actually do?
- where does canvas match DOM?
- where does it drift?
- which mismatches are source-text issues vs engine issues vs extractor issues?

That discipline shows up everywhere.

### 2. The repo has real multilingual ambition
Not “supports Unicode” as a checkbox, but actual work around:
- CJK and kinsoku-like behavior
- Thai
- Khmer
- Myanmar
- Arabic
- Urdu
- mixed app text with URLs, emoji, quotes, query strings, soft hyphens

The corpora and research notes are doing real labor here.

### 3. The research log is unusually valuable
`RESEARCH.md` is not fluff. It documents:
- what was tried
- what failed
- what was kept
- which classes of mismatch are real
- which fixes were rejected

That matters a lot. You can see the repo resisting bad abstractions instead of accumulating them.

### 4. The taxonomy work is smart
`corpora/TAXONOMY.md` gives names to mismatch classes like:
- `corpus-dirty`
- `normalization`
- `boundary-discovery`
- `glue-policy`
- `edge-fit`
- `shaping-context`
- `font-mismatch`
- `diagnostic-sensitivity`

That is the sort of meta-tooling that keeps a gnarly research codebase from dissolving into vibes.

### 5. The narrowness of the public API is disciplined
This repo could easily have overexposed internals. Instead, it keeps the main handle opaque and treats richer structures as explicit escape hatches.

That is good restraint.

## What is strong

### The design target is clear
Fast resize-path layout without DOM reflow. No confusion there.

### The validation culture is excellent
Browser sweeps, corpora, benchmarks, snapshots, status dashboards, focused checkers. This repo keeps receipts.

### It understands that preprocessing beats runtime cleverness
One repeated lesson in the research notes is that semantic preprocessing and narrow glue rules beat fancy runtime correction models. That feels hard-won and probably correct.

### Rich inline helper is a nice productization move
The separate `rich-inline` helper is a good example of not bloating the core API while still serving a very real UI need.

### The permanent unit suite stays intentionally small
That is smart. The repo uses browser-oracle tooling for the hairy stuff and keeps the durable test suite focused on stable invariants.

## Where I get skeptical

### 1. This is still fundamentally browser-shadowing
Even done well, this is a hard problem because browser text engines are not simple and not static. The repo knows this, but the maintenance cost is real.

### 2. “Pure JS/TS” still depends on browser font behavior as truth
That is not a contradiction, just a practical limitation. The model is browser-grounded rather than independently authoritative.

### 3. Some unresolved classes look like they want a richer shaping model
The repo is careful not to prematurely overbuild there, which I respect. But Arabic/Urdu/Myanmar-style edge cases are a reminder that segment-sum layout has limits.

### 4. The project’s honesty about `system-ui` is good, but also a warning
If your app depends on slippery real-world font stacks, this library is only as good as the font assumptions you keep honest.

## Why it matters

Because this is one of the more credible attempts I’ve seen to create a **userland text layout engine for web apps that is fast, practical, and empirically grounded**.

The immediate use cases are obvious:
- virtualization without DOM measurement loops
- custom layout systems
- canvas/SVG/WebGL text rendering helpers
- browser-free UI verification for label overflow
- tighter control over paragraph wrapping behavior in complex UIs

But the deeper value is methodological. The repo shows how to build this kind of engine without just hallucinating typography rules.

## Verdict

Excellent nerd work.

Pretext is the rare text-layout project that feels both ambitious and disciplined. The central two-phase architecture is sound, the multilingual handling is serious, and the browser-oracle validation culture gives the claims real weight. The repo does not pretend the problem is solved in the abstract; it keeps a running account of where the model holds, where it drifts, and which fixes were not worth keeping.

That honesty makes it much more convincing.

If you need exact browser-independent typography truth, this is not magic. But if you want a fast, pragmatic, browser-grounded layout engine for real UI work, this is very compelling.

**Rating:** 5/5

## Patterns worth stealing

- Split expensive text analysis from hot-path layout arithmetic
- Keep the main prepared handle opaque
- Use browsers as an empirical oracle, not just as a rendering target
- Build a mismatch taxonomy so debugging does not collapse into folklore
- Prefer narrow semantic preprocessing over increasingly clever runtime correction
- Maintain separate compact status docs and long-form research logs
- Use corpora and product-shaped canaries, not only synthetic test strings
- Keep public API narrow while offering explicit rich-layout escape hatches
