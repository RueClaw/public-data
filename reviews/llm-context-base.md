# llm-context-base

- **Repo:** <https://github.com/asakin/llm-context-base>
- **License:** Apache 2.0
- **Commit reviewed:** `63396c3` (2026-04-11)

## What it is

llm-context-base is an opinionated template for building a personal "LLM wiki" or personal knowledge operating system. It turns Karpathy's raw-docs plus wiki plus instruction-file pattern into a reusable repo skeleton with:

- metadata-frontmatter on every substantive file
- inbox-first capture
- a training period where the assistant adapts structure over time
- linting and freshness concepts
- multi-tool bootstrap shims (`AGENTS.md`, Claude, Cursor, Copilot, Windsurf)
- Obsidian-friendly layout

This is not a runtime product. It is a **substrate**.

And to its credit, the repo understands that distinction better than most.

## Core thesis

Keep the repo dumb. Put the intelligence outside it.

That means:
- markdown files as substrate
- AI tools as interchangeable intelligence layers
- no required app server
- no mandatory database
- no bespoke protocol dependency just to make the system usable

I like this a lot. It's a healthier design instinct than the current epidemic of "let's build an MCP server for my grocery list".

## What is genuinely good here

### 1. The substrate principle is the best thing in the repo
The explicit statement in `PHILOSOPHY.md` is the real intellectual center of the project:

- repo stays dumb
- intelligence lives outside it
- wrappers and automations are allowed, but they are separate layers

That preserves portability and keeps the base system legible.

### 2. Metadata as query surface
The metadata standard is solid and practical:
- `type`
- `summary`
- `tags`
- `status`
- `updated`
- optional `owner`, `related`, `confidence`, `failure_reason`

The key field is the `summary`. The repo understands that future retrieval quality depends less on fancy structure and more on whether each file has a sharp relevance description.

### 3. Inbox-first capture is the right default
This is a good usability move. People stall when capture requires taxonomy decisions up front. `_inbox/` with later filing is just sane.

### 4. Training period is a smart concession to reality
Most knowledge systems die because they ask the user to invent a perfect ontology on day one. This repo instead says: start loose, let the assistant observe patterns, then harden conventions later.

That's much more plausible.

### 5. Multi-tool bootstrap is handled correctly
The repo's stance is basically: yes, every tool still wants its own special little instruction file, so we ship thin shims and keep the real behavior in shared config/docs. That's the least stupid way to handle the current ecosystem mess.

## What feels weaker

### 1. README still smells templated in a few places
The top-level `[Project Name]` and "personalize during your first session" framing make it obvious that this is a skeleton. That's fine, but it slightly weakens first impression trust until the user understands the intended flow.

### 2. The training machinery risks becoming theater
The phase logic, easing curve, footers, and training logs are thoughtful, but this kind of thing can easily drift into ritualized prompt UX rather than real adaptation. Whether it works depends entirely on the assistant implementation quality.

### 3. The system still assumes a fairly disciplined user
Inbox-first reduces friction, but this is still fundamentally for someone who wants to maintain a real knowledge practice. Casual users will absolutely let it decay into half-filed markdown fog.

### 4. "No runtime" purity is mostly good, but not universally enough
For a lot of users, the substrate principle is correct. For some teams, though, a little more batteries-included automation would probably help. The repo acknowledges wrappers as valid, which softens this, but the purist stance won't fit everyone.

## Best reusable ideas

- **Substrate over app** as the base architecture for personal knowledge systems
- **Summary-first frontmatter** as retrieval infrastructure
- **Inbox with TTL** instead of requiring immediate filing decisions
- **Training-period adaptation** rather than fixed ontology upfront
- **Shared core instructions plus thin tool shims** for cross-agent portability

## Why it matters for us

This repo is directly relevant to the memory/problem-space we've been circling.

Compared to systems like obsidian-mind or rowboat:
- `obsidian-mind` is heavier and more workflow-operational
- `rowboat` is more productized and integrated
- `llm-context-base` is more minimal and principled as a portable substrate

Compared to napkin:
- napkin is more retrieval-engine shaped
- llm-context-base is more structure-and-process shaped

It is less flashy than most of the agent-memory repos we've looked at, but probably more durable.

## Verdict

Good repo. One of the more intellectually coherent takes on LLM-maintained knowledge systems because it resists the urge to turn everything into a platform. The strongest idea is not the wiki itself, it's the architectural discipline around what belongs in the repo versus in the intelligence layer above it.

A little bit of the training UX may end up ceremonial in practice, but the underlying substrate model is strong.

**Rating:** 4.5/5

## Patterns worth stealing

- Keep markdown repo as substrate, keep intelligence/tooling outside it
- Make summaries a first-class retrieval surface in frontmatter
- Use inbox-first capture with deferred filing
- Let structure emerge during a bounded training period instead of forcing ontology upfront
- Maintain one shared instruction core with thin tool-specific bootstrap files
