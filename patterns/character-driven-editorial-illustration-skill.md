# Character-Driven Editorial Illustration Skill

**Source:** [helloianneo/ian-xiaohei-illustrations](https://github.com/helloianneo/ian-xiaohei-illustrations)  
**License:** MIT  
**Extracted:** 2026-08-20  

## Pattern

For generated article illustrations, make the recurring character perform the core conceptual action rather than decorate the frame.

The useful structure is:

```text
article/content
  -> extract cognitive anchors
  -> produce a shot list
  -> choose one structure type per image
  -> invent a physical metaphor
  -> make the character perform the metaphor's action
  -> generate one image
  -> QA against known image-model failures
```

## Why It Works

Most AI-generated illustrations fail by becoming either generic decoration or a labeled diagram. A character-driven metaphor gives the model a stronger job: the character must physically do the thing the article is explaining.

The check is simple: if removing the character leaves the image's core idea intact, the character is decorative and the prompt should be rewritten.

## Implementation Notes

- Start with article anchors, not image count. Good anchors include judgments, transitions, before/after states, handoffs, input/output loops, common pitfalls, and surprising metaphors.
- Use a small set of structure types: workflow, system detail, before/after, role state, concept metaphor, layered method, route map, mini-comic.
- Convert abstractions into low-tech physical actions: sorting, pulling, carrying, catching, cutting, weighing, repairing, filtering, compressing, opening, blocking.
- Keep examples as style calibration, not composition templates. Explicitly name old compositions that should not be copied.
- Put negative constraints next to the style DNA: no slide look, no top-left type title, no dense text, no cute mascot drift, no gradients/textures, no formal diagram.
- QA generated images for aspect ratio, background, text volume, label readability, character participation, and over-copying from examples.

## Reuse Guidance

This pattern is portable beyond Xiaohei. Use it for any visual language with a recurring character or motif, but do not copy another creator's character identity without attribution and permission-compatible licensing.

For precise technical diagrams, prefer a diagram-source workflow. This pattern is best for editorial explanation, conceptual essays, and memorable article-body images.

---

**Attribution:** Based on Ian Xiaohei Illustrations by Ian, MIT License.
