# Static-First Semantic Diagram Skill

**Source:** [cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design)  
**License:** MIT  
**Extracted:** 2026-08-14  

## Pattern

For agent-generated diagrams, separate what the diagram means from how it is laid out, render a complete static frame by default, and make every optional dynamic behavior pass through a narrow reviewed controller.

The useful workflow:

```text
request or source diagram
  -> select semantic pattern when behavior/risk/state matters
  -> select nearest visual type for layout
  -> set size, detail, audience, and output format
  -> build a small semantic model
  -> render self-contained HTML/SVG
  -> run deterministic checks
```

## Why It Works

Most agent diagrams fail before rendering. The model picks a familiar visual form, copies source layout, overuses accent colors, and depends on animation or explanation text to repair the result. This pattern forces the agent to decide what must be understood first.

Static output stays the primary artifact. Motion can reveal order, but the still frame must remain complete. That makes diagrams usable in documentation, screenshots, slide exports, PDFs, and reduced-motion environments.

## Key Moves

- Route behavior-heavy requests through semantic patterns such as queues, policy traces, trust boundaries, governance catalogs, or compensating security layers.
- Let the visual type own layout grammar, spacing, and connector rules.
- Use source diagrams as semantic input, not as layout authority. Coordinates, colors, Mermaid renderer styles, and draw.io shape choices are hints at most.
- Treat imported diagram labels, URLs, click targets, and metadata as untrusted content.
- Ship a local self-check script with the skill so generated artifacts can be validated after installation.
- Permit motion only through a reviewed controller, with reduced-motion and static fallback behavior.

## Applicability

Use this for artifact-generation skills that produce diagrams, charts, canvases, generated docs, explainer pages, or any visual output where the model can confuse style with meaning.

It is especially useful when:

- the user asks for architecture, process, policy, risk, or control diagrams;
- the input is a Mermaid or draw.io file that should be improved rather than faithfully rendered;
- the output may be published as static documentation;
- accessibility, artifact safety, or offline portability matters.

## Caveats

This pattern does not replace taste review. It gives the agent a better operating frame and makes mistakes easier to catch. For workflows where manual editing in a mainstream diagram tool is required, an editable source format such as draw.io may still be a better primary artifact.

---

**Attribution:** cathrynlavery/diagram-design, MIT License.
