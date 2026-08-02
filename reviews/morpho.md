# MorphoHDL (paradigms-of-intelligence/morpho)

**Repo:** https://github.com/paradigms-of-intelligence/morpho
**License:** Apache-2.0
**Reviewed:** 2026-08-02
**Stack:** Browser-native JavaScript, Canvas/WebGL, SwissGL, Python reference implementation, C/WASM layout helper, static HTML
**What it is:** Experimental hardware description language and graph rewrite system for growing logical circuit structure and physical geometry through recursive cell expansion.

---

## Verdict

📚 **Study.** MorphoHDL is a thoughtful research prototype, not a deployable EDA tool. The core idea is worth studying: recursive structural hardware descriptions with size-agnostic buses, fallback-triggered base cases, and concurrent visualization of logical graph growth and physical layout. The implementation has real compiler and oracle tests, but there is no package, CI, release, synthesis backend, or production HDL integration.

---

## What It Is

MorphoHDL explores a minimal language for describing circuits through recursive division and rewiring. A cell definition behaves like a graph rewrite rule: a node expands into subcells, buses are split or sliced dynamically, and fallback rules stop recursion when a boundary condition is hit. The result is a compact way to express size-agnostic structures like ripple adders, Brent-Kung adders, multiplexers, barrel shifters, and Wallace-style multipliers.

The project is also an interactive article and browser demo. `index.html` walks through the conceptual explanation, `demo.html` lets readers experiment with examples, `js/compiler.js` implements the browser compiler, `js/*layout*.js` renders layouts, `graphs_engine/` contains a C/WASM force-layout helper, and `tiny_morpho.py` is a self-contained Python reference implementation with simulation, compilation, optimization, and tests.

The author explicitly frames it as a conceptual sketch rather than a complete production system. That is the right framing.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Static browser app, no build step |
| Compiler | JavaScript parser/compiler using flat Struct-of-Arrays typed-array storage |
| Visualization | Canvas 2D, WebGL/SwissGL, force/hex layout engines |
| Reference implementation | Python + NumPy |
| Layout helper | C compiled to WASM with Zig |
| Data | Precomputed JSON layouts and SVG fallbacks |
| Tests | Node scripts and Python self-test |

## Key Features

### Recursive Structural HDL

The language's main abstraction is a recursive `@morpho` cell. Primitives such as `SPLIT`, `CAT`, `LSLICE`, `HSLICE`, `REPEAT`, indexing, and slicing manipulate buses without hardcoded widths. Fallbacks turn failed instantiations into base cases, either by calling another cell or returning a positional argument.

That gives small definitions surprising reach. A recursive ripple adder, Brent-Kung adder, logarithmic shifter, and Wallace multiplier can all be written as width-agnostic programs.

### Flat SoA Compiler

`js/compiler.js` stores cells, pins, and nets in typed-array Struct-of-Arrays layouts. That is unusual for a browser research demo and makes sense for interactive graph growth: lower allocation churn, better cache behavior, and cheap traversal for optimization and rendering.

The compiler includes LUT simplification, dead-code elimination, fanout handling, graph expansion, and signal arrival-time estimation.

### Interactive Article And Viewer

The repo includes an article with embedded visualizations and a separate demo explorer. Precomputed layout JSON plus SVG fallbacks make the article readable even without live computation.

### Python Reference Implementation

`tiny_morpho.py` is useful because it expresses the same concepts in compact Python. It includes the primitives, example circuits, dynamic runner, compiler, optimization, and tests in one file. For learning the model, this is probably the best starting point.

## Architecture

The repo is intentionally simple:

- `tiny_morpho.py`: reference HDL/runtime/compiler/testbed.
- `js/parser.js`: minimal parser for the Python-like Morpho syntax.
- `js/primitives.js`: primitive bus operations and LUT optimization.
- `js/compiler.js`: flat compiled graph, expansion, optimization, and timing.
- `js/viewer.js`, `js/layout_renderer.js`, `js/force_layout.js`, `js/hex_layout.js`: visualization and layout.
- `graphs_engine/src/main.c`: WASM helper for graph force layout.
- `scratch/`: tests, benchmarks, and fallback generation scripts.
- `data/`: generated layouts and static fallbacks used by the article/demo.

There is no package manager manifest, no CI workflow, and no installed CLI. Running it means serving the static files locally, or running individual Node/Python scripts.

## Comparison

| Aspect | MorphoHDL | Chisel / Amaranth / Clash | Verilog/SystemVerilog |
|--------|-----------|----------------------------|------------------------|
| Maturity | Research prototype | Real HDL ecosystems | Industry standard |
| Main idea | Recursive graph growth and geometry-aware structure | Host-language hardware generation | Explicit RTL/netlist descriptions |
| Width handling | Inferred through recursive bus operations | Parameterized types/functions | Explicit widths/params |
| Layout awareness | Central research goal, visual prototype now | Mostly external to HDL | Mostly external to HDL |
| Best use | Study and experimentation | Building real designs | Production hardware flows |

## Self-Hosting Notes

There is nothing server-like to self-host. Run a local static server from the repo root:

```bash
python3 -m http.server 8000
```

Then open `demo.html` or `index.html`. The browser app loads local JS modules and data assets.

Verification run locally:

- `node scratch/test_compiler.js` passed.
- `python3 tiny_morpho.py` passed.
- `node scratch/test_hex_layout.js` ran, but it only exercises a zeroed mock layout and should be treated as a smoke script.

---

**Attribution:** paradigms-of-intelligence/morpho, Apache-2.0
