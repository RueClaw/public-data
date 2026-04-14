# rowboat

- **Repo:** <https://github.com/rowboatlabs/rowboat>
- **License:** Apache 2.0
- **Commit reviewed:** `2133d72` (2026-04-13)

## What it is

Rowboat is a local-first AI coworker that builds a long-lived knowledge graph from email, calendar, meeting notes, voice memos, and external tools, then uses that context to help produce briefs, drafts, decks, and follow-ups.

At the product level, it's "personal chief of staff with memory". At the storage level, it's an Obsidian-compatible markdown vault with backlinks.

## Why it is interesting

This repo is attacking the same broad problem as several others we've reviewed, but from a cleaner product angle:

- memory is durable and inspectable
- data lives locally as markdown
- models are swappable
- integrations feed the graph instead of trapping context in opaque app state

That combination is strong.

## What stands out

### 1. Local markdown as the memory substrate
This is still the right answer. Human-editable artifacts beat hidden vector soup.

### 2. Real-world ingestion targets
Gmail, Calendar, Fireflies, voice notes, Composio tools, MCP, Exa, ElevenLabs. This is aimed at actual knowledge work instead of benchmark theater.

### 3. Artifact-oriented outputs
Meeting briefs, email drafts, PDF decks, running notes. It is trying to produce useful work products, not just chat.

### 4. Bring-your-own-model posture
That matters. The memory substrate and workflow should outlive any one model provider.

## Architecture signals

The top-level README undersells the real size of the codebase. The root is more of a product shell over a larger monorepo with:

- Electron desktop app under `apps/x`
- multiple frontends and SDK surfaces
- a real `CLAUDE.md` with nested workspace architecture
- model/provider configuration under local config files

So this is not a toy markdown app. It is a substantial product stack wrapped around a local-memory thesis.

## Concerns

### 1. Scope breadth
This is trying to be memory system, assistant, note app bridge, meeting tool, voice memo processor, and tool execution layer. That's a lot of failure modes.

### 2. Trust boundary complexity
Anything that pulls from email, calendar, meeting notes, and external tools needs very good permission and review UX. The README says the right words, but that is always where systems like this live or die.

### 3. Product polish vs inspectability tension
The more assistant-like the system becomes, the easier it is to hide too much logic behind "helpful" behavior. The markdown substrate helps counterbalance that, but only if the implementation stays faithful.

## Why it matters for us

Rowboat is one of the better examples of a **local-first executive-memory product**.

Compared to obsidian-mind:
- obsidian-mind is more operator-manual and agent-workflow heavy
- Rowboat is more productized and end-user facing

Compared to napkin:
- napkin is more retrieval-compact
- Rowboat is more action-and-relationship oriented

## Verdict

Promising and conceptually aligned with where a lot of agent tooling should go: durable local memory, inspectable artifacts, swappable models, work-product generation.

The repo's main risk is simple, ugly, ancient scope creep. But the underlying thesis is strong.

**Rating:** 4.5/5

## Patterns worth stealing

- Obsidian-compatible markdown vault as primary memory substrate
- Product outputs grounded in durable context graph
- BYO-model architecture over stable local data ownership
- Integrations that feed memory rather than replace it
- Local-first coworker framing instead of stateless chat assistant framing
