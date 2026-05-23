# Tufte Chart Skill Framework

**Source:** https://github.com/aref-vc/tufte-claude-skill  
**Author:** aref-vc  
**License:** MIT  
**Reviewed:** 2026-05-23

## Pattern

Turn a subjective design style into a small, loadable agent workbench: trigger contract, principles, decision table, kill list, implementation presets, visual examples, and a final checklist.

For chart generation, this is stronger than a single system prompt because it separates judgment into reusable files:

- principles.md defines the design philosophy.
- chart-selection.md maps data shape and reader goal to chart type.
- kill-list.md removes misleading or decorative defaults.
- presets/ gives stack-specific implementation snippets.
- checklist.md forces a final honesty and readability pass.

## Why It Works

Most AI-generated charts fail before rendering: they choose the wrong chart, overuse color, copy library defaults, add detached legends, or optimize for decoration instead of comparison. A skill workbench can intervene before code generation by making the agent classify the data and communication goal first.

The useful structure is not Tufte-specific. Any opinionated design or engineering domain can use the same shape: compact doctrine, a decision table, a negative rule set, concrete presets, and an acceptance checklist.

## Core Components

- **Activation contract:** precise trigger terms and output targets in SKILL.md.
- **Principles:** short rules that explain why the style exists.
- **Decision table:** converts input type and user goal into the right artifact.
- **Kill list:** names anti-patterns explicitly so the model has less room to imitate bad defaults.
- **Presets:** executable or near-executable snippets for supported stacks.
- **Examples:** before/after cases that calibrate visual judgment.
- **Checklist:** final pass covering correctness, honesty, and polish.

## Implementation Notes

- Keep the main skill file short enough to load quickly.
- Put expensive context in progressive reference files.
- Prefer decision tables over prose when the agent must choose between artifact types.
- Include negative rules; models often need explicit permission to remove familiar defaults.
- Provide stack-specific snippets so the agent does not have to translate pure design language into code from scratch.
- Use examples to calibrate taste, but keep the checklist as the acceptance gate.

## Good Fit

- Data visualization skills.
- UI design-system skills.
- CAD, diagramming, document formatting, security review, or compliance workflows.
- Any agent task where the hard part is choosing constraints before generating output.

## Watch Outs

- A skill like this can overfit one aesthetic. Make override rules explicit.
- Source quotations and book-derived summaries need careful attribution.
- Without sample prompt/output tests, regressions will be qualitative and harder to catch.

## Minimal Checklist

1. Define when the skill activates.
2. Load the smallest principle file that frames the work.
3. Choose the artifact with a decision table.
4. Apply a kill list before implementation.
5. Render using a stack-specific preset.
6. Run a final checklist before declaring done.

---

**Attribution:** aref-vc/tufte-claude-skill, MIT
