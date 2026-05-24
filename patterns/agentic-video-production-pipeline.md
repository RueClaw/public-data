# Agentic Video Production Pipeline

**Inspired by:** HKUDS/ViMax  
**Use when:** an agent needs to turn a loose creative brief into expensive, multi-step media outputs.

## Pattern

Treat video generation as a production line, not as one prompt. Split the job into typed, inspectable stages: brief, story, script, character registry, references, scene/event graph, storyboard, camera/shot plans, candidate images, selected images, generated clips, and final composition.

Each stage writes durable artifacts before the next stage runs. That makes the pipeline resumable, auditable, and cheaper to debug.

## Implementation Notes

- Keep chat, image, video, reranker, and compositor adapters thin and separately configured.
- Cache outputs with stable filenames under a run directory.
- Make each stage idempotent where practical: if an artifact exists and validates, load it instead of regenerating.
- Use typed schemas for handoffs between agents.
- Rate-limit each external service independently.
- Retry individual provider calls, not the whole production run.
- Preserve enough context in every artifact to inspect why a later clip looks wrong.

## Safety Notes

Media agents need policy gates that ordinary coding agents may not need: likeness and consent checks, adult/violent/illegal-content boundaries, copyrighted character/style checks, provenance metadata, and human review before publishing generated video.

Without these gates, a strong media pipeline is still only a sandbox pattern.

## Minimal Shape

```text
brief
  -> story.md
  -> script.json
  -> characters.json
  -> references/
  -> storyboard.json
  -> frames/
  -> clips/
  -> final.mp4
```

The key property is that every arrow has a real file boundary. The agent can stop, resume, inspect, replace, or regenerate a stage without losing the rest of the run.

