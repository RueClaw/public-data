# Agent-Native Draw.io Diagram Pipeline

**Source:** [Agents365-ai/drawio-skill](https://github.com/Agents365-ai/drawio-skill)
**License:** MIT
**Reviewed:** 2026-06-20

## Pattern

For agent-generated diagrams, use a mature editable diagram format as the source of truth, then wrap it with deterministic generation, validation, export, and repair steps.

The pipeline:

1. Convert the user request into a logical diagram plan: diagram type, nodes, edges, grouping, layout direction, output format, and style constraints.
2. Generate uncompressed draw.io / mxGraph XML so the structure can be inspected and patched directly.
3. For larger graphs, describe the graph as JSON and let Graphviz place nodes and route edges before emitting draw.io cells.
4. Run a structural linter before visual review: duplicate IDs, dangling edge endpoints, broken parents, invalid geometry, negative positions, and overlaps.
5. Export a preview image without embedded XML for visual inspection.
6. Apply targeted XML edits for feedback rather than regenerating the whole diagram when only labels, colors, positions, sizes, or single edges change.
7. Export final PNG/SVG/PDF with embedded diagram XML so the image remains editable in draw.io.
8. Repair known exporter defects immediately after export.

## Why It Works

Diagram generation fails in boring ways: invalid IDs, guessed vendor shapes, edges through nodes, clipped labels, uneditable raster output, and renderer-specific quirks. A pipeline that treats draw.io XML as the source artifact can use normal software checks before asking a model or a human to judge aesthetics.

The pattern also avoids locking diagrams into prompt output. Users can open the final artifact in draw.io, make small manual changes, and keep the editable source embedded in the image/PDF deliverable.

## Implementation Notes

- Keep diagram source uncompressed while the agent is editing it.
- Reserve root cell IDs and validate every edge source/target before export.
- Use a real shape lookup table for vendor icons instead of guessing style strings.
- Use Graphviz for codebase, dependency, and large topology layouts.
- Separate structural lint from visual review; do not ask a vision model to find XML integrity bugs.
- For image assets that depend on a CDN, offer an embed mode for offline portability.
- Document renderer quirks as code. If a final export format has a known corruption issue, repair it in the workflow immediately after export.

## Good Fit

This pattern fits agent skills, documentation generators, architecture-review tooling, codebase visualization, AI system diagrams, cloud/network maps, and any workflow where the user needs both a polished image and an editable source file.

## Caveats

The pipeline depends on host tools. draw.io desktop CLI is required for local exports, and Graphviz is required for auto-layout. In sandboxed desktop environments, the CLI may fail for reasons unrelated to the diagram source; keep browser/editor URL fallback available.

---

**Attribution:** Agents365-ai/drawio-skill, MIT License.
