# Ian Xiaohei Illustrations (helloianneo/ian-xiaohei-illustrations)

**Repo:** https://github.com/helloianneo/ian-xiaohei-illustrations  
**License:** MIT. Reusable with attribution; bundled example images and the recurring Xiaohei visual language should retain Ian attribution per `NOTICE.md`.  
**Reviewed:** 2026-08-20  
**Stack:** Codex Skill, Markdown reference files, YAML agent metadata, generated PNG examples  
**What it is:** A Codex Skill for turning Chinese long-form writing into 16:9 white-background hand-drawn article illustrations using Ian's Xiaohei visual language.

---

## Verdict

✅ **Deploy candidate for Chinese editorial illustration workflows.** This is a tight, opinionated visual-production skill: it does not try to be a generic diagrammer or slide generator, and that restraint makes it useful. The strongest parts are the shot-list-first workflow, explicit anti-replication rules, compact prompt template, and QA checklist for catching the usual image-model failures.

---

## What It Is

Ian Xiaohei Illustrations packages a specific illustration grammar for AI agents. The target output is a set of 16:9 article-body illustrations for Chinese essays, blogs, Notion pages, methods posts, and workflow explanations. Each image should explain one cognitive anchor from the article: a judgment, transition, flow, state, structure, or metaphor.

The repo's recurring visual character is Xiaohei: a small solid-black, white-eyed, deadpan worker who must perform the core conceptual action in the image. That rule matters. It prevents the common "mascot standing beside a diagram" failure and pushes the model toward a physical metaphor where the character is part of the explanation.

This is not a code-heavy repo. The value is in the skill's visual taxonomy and workflow constraints: read the article, identify 4-8 illustration-worthy anchors, choose one structure type per image, invent a fresh low-tech metaphor, generate each image separately, then check for white background, sparse text, Xiaohei participation, and non-PPT composition.

## Stack

| Layer | Tech |
|-------|------|
| Agent interface | Codex Skill `SKILL.md` |
| Packaging | Skill directory plus `agents/openai.yaml` metadata |
| References | Markdown style DNA, character/IP guide, composition patterns, prompt template, QA checklist |
| Output | 16:9 PNG illustrations saved under workspace assets |
| Examples | Generated PNG style-calibration images |
| Runtime services | Whatever image-generation model the host agent uses |

## Key Features

### Shot List Before Image Generation

The skill separates "where should this article have images?" from "generate this image." That is the right workflow for editorial content. It tells the agent to choose cognitive anchors instead of distributing illustrations evenly through the article.

### Xiaohei As Action, Not Decoration

The character guide is unusually specific: Xiaohei has a limited visual form, tone, behavior set, and failure modes. The key rule is testable: if removing Xiaohei leaves the metaphor intact, the image is wrong. That single check does more work than a page of aesthetic adjectives.

### Composition Pattern Library

The reference set gives eight useful structure types: workflow, system detail, before/after, role state, concept metaphor, layered method, map route, and mini-comic panel. The skill then forces a fresh low-tech metaphor instead of reusing prior examples.

### Prompt Template With Negative Constraints

The template carries the actual production spec: pure white background, black hand-drawn line art, sparse red/orange/blue handwritten Chinese labels, plenty of empty space, no top-left title, no formal diagram, no PPT look, no cute mascot poster, and no copied example composition.

### QA Checklist

The QA file names the practical failure cases: wrong aspect ratio, too much text, title hallucination, PPT-style layout, cute-cartoon drift, textured backgrounds, bad Chinese labels, and example-copying. That makes post-generation review concrete instead of taste-only.

## Architecture

The package is a small, progressive-disclosure skill:

```text
SKILL.md
  -> style-dna.md
  -> xiaohei-ip.md
  -> composition-patterns.md
  -> prompt-template.md
  -> qa-checklist.md
  -> examples only for low-frequency calibration
```

The important design choice is that the examples are explicitly demoted. They are calibration assets, not templates. The skill tells the agent not to open or copy them by default and lists specific old compositions to avoid reusing.

The repo has no application runtime, tests, CI, or deterministic verifier. For a content skill, that is acceptable, but the next level would be a small validator that checks generated image dimensions, dominant background brightness, and OCR text density before handing work back to the user.

## Comparison

| Aspect | Ian Xiaohei Illustrations | Diagram Design | drawio-skill | Tufte Chart Skill |
|--------|---------------------------|----------------|--------------|-------------------|
| Primary job | Chinese editorial raster illustrations | Editorial technical diagrams | Editable draw.io diagrams | Quantitative charts |
| Output | PNG images | HTML/SVG/PNG | `.drawio` plus exports | HTML/SVG/React chart patterns |
| Best pattern | Character-driven metaphor with QA checklist | Semantic pattern before visual type | Editable source plus deterministic validation | Data-story choice plus kill list |
| Main caveat | Image-model output remains probabilistic | Less editable in mainstream tools | Desktop CLI dependency | Narrow chart scope |

This is closest to a visual-language skill, not a diagramming system. Use Diagram Design or drawio-skill when the output must be a precise architecture diagram. Use Ian Xiaohei Illustrations when the job is an article illustration that should feel memorable, sparse, and hand-drawn.

## Self-Hosting Notes

Installation is just copying `ian-xiaohei-illustrations/` into the Codex skills directory:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R ./ian-xiaohei-illustrations "${CODEX_HOME:-$HOME/.codex}/skills/"
```

There are no package dependencies. Actual generation depends on the host agent having an image-generation tool, and the final assets need human or vision-model review because Chinese labels and title hallucinations are known failure points.

---

**Attribution:** helloianneo/ian-xiaohei-illustrations, MIT License
