# Walkthrough (austeane/walkthrough)

**Repo:** https://github.com/austeane/walkthrough  
**License:** no license specified — educational/personal use only; do not redistribute code or reuse implementation directly without permission  
**Reviewed:** 2026-06-06  
**Stack:** Python 3.11+, Jinja2, Pygments, optional Pillow, optional Playwright, uv, pytest  
**What it is:** Walkthrough converts AI coding-agent session histories into evidence-backed, self-contained HTML walkthroughs for developers reviewing what an agent built.

---

## Verdict

📚 **Study this as a strong pattern source, not a drop-in dependency yet.** The architecture is unusually clear for a small young repo: provider-specific normalizers converge into one event model, noisy transcript data is projected down before summarization, and the final artifact emphasizes verifiable claims over transcript replay. The missing license, minimal README, no visible CI, and very young project status keep it out of deploy-candidate territory.

---

## What It Is

Walkthrough is a pipeline for turning Codex CLI, Claude Code, and OpenCode session histories into a developer-facing narrative. Its premise is good: agent work is rarely useful as a raw log, but a compressed walkthrough with claims, decisions, files, commands, screenshots, and source references can help a developer review or re-learn the code.

The output target is a single offline HTML document with reading and presentation modes. The docs push a specific editorial stance: the walkthrough should explain what changed and why, group many low-level agent actions into a smaller number of meaningful steps, and expose proof only when the reader wants to drill down.

The repo is more of a skill/pipeline kit than a hosted application. It ships Python scripts, a Jinja2 HTML template, provider format references, an agent skill file, and a pytest suite.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python 3.11+ |
| Packaging | uv, pyproject, Hatchling |
| Session ingestion | Codex CLI JSONL, Claude Code JSONL, OpenCode export JSONL |
| Rendering | Jinja2 template, embedded JSON data, Pygments diff highlighting |
| Optional media | Pillow for image handling, Playwright for capture workflows |
| Validation | Deterministic pipeline checks, editorial quality checks, pytest |
| Distribution | Codex/Claude skill symlink workflow |

## Key Features

### Provider-Normalized Event Model

The strongest design choice is the shared event schema. Instead of making downstream steps understand every source transcript format, Walkthrough normalizes Codex, Claude Code, and OpenCode into common event kinds such as messages, tool uses, tool results, file changes, commands, reasoning, screenshots, and metadata.

That gives the rest of the pipeline a stable contract. Chunking, validation, summarization, rendering, and quality checks can operate on one shape even when the original agents record sessions differently.

### Noise-Reduced Projection Before Summarization

The pipeline explicitly projects normalized events before chunking. It drops or compresses transcript material that is expensive but low-signal, while keeping errors, messages, commands, file changes, reasoning, and other review-relevant events. This is the right instinct for long agent sessions: preserve provenance, but do not make the summarizer pay for every raw context dump.

### Evidence-First HTML Artifact

The renderer is designed around offline review. It emits a self-contained HTML page, uses local system fonts, embeds the data, highlights diffs, links file references, and separates reading/deck modes plus end-state/journey views. The product docs are blunt about the goal: this should be a reading instrument, not a dashboard.

### Deterministic Gates

The repo includes both structural validation and editorial quality validation. The pipeline validator checks things like required fields, provider values, turn indexing, session contiguity, tool pairing, projected-event constraints, and chunk integrity. The walkthrough quality gate checks that final walkthroughs do not still look like raw chunk metadata and that steps contain grounded claims with source references.

## Architecture

The architecture is a staged local pipeline:

1. Discover candidate session files.
2. Strip binary content, optionally preserving screenshots.
3. Normalize source-specific transcripts into the shared JSONL event model.
4. Project events to remove noisy data before LLM summarization.
5. Extract compact deterministic session cards.
6. Chunk projected events.
7. Summarize chunks with an LLM outside this repo's deterministic code.
8. Merge summaries into a walkthrough JSON artifact.
9. Render self-contained HTML.
10. Validate both pipeline contracts and narrative quality.

That separation is the main lesson. The deterministic stages own parsing, contraction, provenance, and rendering. The LLM stage owns editorial compression. That makes the system easier to test and easier to debug than a single prompt that tries to read a transcript and output final documentation in one step.

## Comparison

| Aspect | Walkthrough | Trace Capture Tools | Browser Task Harnesses |
|--------|-------------|---------------------|------------------------|
| Primary goal | Explain completed agent work as a narrative | Store/search agent traces | Produce/replay browser automation work |
| Artifact | Offline HTML walkthrough plus JSON | Trace database, search UI, logs | Scripts, screenshots, reports |
| Strongest pattern | Provider-normalized events with evidence refs | Durable local trace storage | Rerunnable task evidence |
| Weakness | Young, no license, sparse README | Often less editorial | Focused on browser actions, not full coding sessions |

Walkthrough is closest in spirit to trace tooling, but it sits higher in the stack. It is not mainly about retention or observability; it is about turning retained traces into reviewable developer explanations.

## Self-Hosting Notes

This is a local tool rather than a service. Installation is `uv sync` plus symlinking the repo as a skill into compatible agent environments. The project exposes console scripts for each pipeline stage through `pyproject.toml`.

Operational caveats:

- No declared license means treat it as read-only study material unless permission is granted.
- The README is too thin for users who do not already understand agent session formats.
- No CI config was visible in the reviewed tree.
- The local test suite passed: `142 passed in 0.83s` on Python 3.11 via `uv run pytest -q`.
- Optional screenshot/capture paths depend on Pillow or Playwright and deserve separate validation in real projects.

---

**Attribution:** austeane/walkthrough, no license specified
