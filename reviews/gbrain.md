# gbrain

- **Repo:** <https://github.com/garrytan/gbrain>
- **License:** MIT
- **Commit reviewed:** `b7e3005` (2026-04-14)

## What it is

GBrain is a **personal knowledge brain for AI agents**: markdown files as human-readable source-of-truth, plus a retrieval/indexing layer, plus a very large skillpack telling the agent how to ingest, enrich, search, maintain, and operate that knowledge over time.

The pitch is not modest.

It wants to be:
- personal knowledge base
- entity graph
- ingestion pipeline
- retrieval engine
- operational memory system
- integration hub
- skill distribution layer
- recurring maintenance protocol
- identity/operating-system layer for agents

And annoyingly, there is enough real code here that I can't dismiss it as pure delusion.

## Core architecture

At a high level, the repo is built on a sensible split:

- **markdown brain repo** as human-editable system of record
- **database/index layer** for search, embeddings, chunks, links, and facts
- **agent skill layer** for operational behavior
- **CLI + MCP server** as access surfaces

The contract-first part is especially good:
- `src/core/operations.ts` defines shared operations
- CLI and MCP surface are both generated from that contract
- storage backend is abstracted behind `BrainEngine`
- engines currently include **PGLite** and **Postgres/Supabase**

That is real architecture, not just vibes and folder names.

## What is technically interesting

### 1. PGLite default is a strong move
Defaulting to embedded Postgres via PGLite instead of immediately demanding cloud infra is smart.

It gives the project a low-friction path:
- zero-config start
- real SQL semantics
- pgvector / hybrid search story still preserved
- migration path to Supabase later

That makes the repo much more credible than systems that require hosted infrastructure before they can remember your lunch.

### 2. Engine abstraction is actually useful here
`docs/ENGINES.md` and the code around `BrainEngine` are good. The engine boundary is in the right place:
- storage/search implementation behind the interface
- chunking, embeddings, dedup, and hybrid orchestration outside it
- CLI and MCP not caring which engine is active

That means the repo can evolve without rewriting its whole personality every release.

### 3. Hybrid search design is one of the stronger parts
The retrieval stack is not especially novel, but it is competent:
- keyword search
- vector search
- RRF fusion
- multi-query expansion
- dedup layers
- intent classification
- evaluation harness

More importantly, the repo treats retrieval quality as something to benchmark and tune, not just to handwave.

### 4. Contract-first CLI plus MCP is the right pattern
The CLI entrypoint is unusually clean. Shared operations feed both CLI and MCP. That's good infrastructure design and keeps the surface area from drifting into madness.

### 5. The skillpack is not decorative
Most repos with "skills" have a couple markdown files and delusions of grandeur. Here, the skillpack is clearly the governing layer of the system. Whether you like the philosophy or not, it is at least coherent: **thin harness, fat skills**.

### 6. There is real test weight here
The test suite is extensive. That matters because this repo touches the exact failure modes most "memory systems" usually ignore: migration, sync, dedup, retrieval parity, skill conformance, embeddings, upgrades, and so on.

## What is genuinely strong

### Markdown as human override layer
This is still the right instinct. Humans can always inspect and edit the underlying knowledge. That's healthy.

### Compiled truth plus timeline model
This is one of the better page-shape ideas in the repo. Current synthesis above the line, append-only evidence below it. Good mental model.

### Brain-first lookup discipline
As a behavioral rule for an agent, this is correct. Check the maintained knowledge base before freelancing with external APIs.

### Resolver-driven filing
I like this more than I expected. Explicit resolver/routing for where new knowledge goes is annoying, but necessary once these systems get large.

## Where I get skeptical

### 1. The repo is extremely ideology-heavy
There is a lot of doctrine here. Resolver. Skillpack. Soul. Brain-first. Dream cycle. Thin harness, fat skills. Homebrew for personal AI. Some of it is useful. Some of it is branding wrapped around ordinary operational advice.

You can feel the system wanting to become a religion.

### 2. The install story leans hard on agent obedience
The `INSTALL_FOR_AGENTS.md` path assumes an agent will read giant instruction files, load many skills, configure recurring jobs, and internalize conventions. That may work for aligned environments, but it is fragile. A lot depends on the host agent behaving exactly the way the repo imagines.

### 3. Scope creep is real
Knowledge base, search engine, MCP toolset, cron management, personal identity files, integrations, voice, email, Twitter, structured data extraction, auto-update, dream cycle. That's a lot of surface area for a project still trying to prove its core durability.

### 4. "25 skills" can become prompt debt
The markdown-skill model is powerful, but it also creates a sprawling instruction estate. At some point you are doing knowledge work partly to maintain the doctrine that explains how to do knowledge work.

### 5. Search quality claims need healthy suspicion
The retrieval stack is better than average, but claims about large-scale personal brain quality always deserve skepticism until lived with for a while. These systems often demo better than they age.

## Why it matters

Because this is one of the clearest attempts to build an **agent-operable memory operating system** rather than just a note-taking repo or a vector search wrapper.

Compared with:
- **llm-context-base**: more disciplined substrate, less operationally ambitious
- **obsidian-mind**: more vault-centric memory workflow
- **rowboat**: more productized integrated assistant
- **napkin**: more compact retrieval/memory patterning

GBrain is the most maximalist "full stack for agent memory and operations" of the bunch.

## Best reusable ideas

- Contract-first operations shared across CLI and MCP
- Pluggable engine boundary with embedded default and cloud migration path
- Compiled truth plus timeline as a durable page model
- Resolver-driven filing to reduce duplicate ambiguous page creation
- Retrieval quality as something evaluated, not merely asserted
- Markdown as human-readable override layer above a richer retrieval substrate

## Verdict

Ambitious to the point of mild mania, but not empty.

There is real engineering here: engine abstraction, search stack, contract-first operations, test coverage, and an actual opinion about how an agent should maintain knowledge over time. The repo's biggest strength is that it treats memory as an operational system, not just a vector index.

Its biggest risk is exactly the same thing: the whole thing may collapse under the weight of its own doctrine, recurring rituals, and skill sprawl if not kept brutally practical.

Still, this is one of the more substantial repos in the entire memory/agent-brain category.

**Rating:** 4.5/5

## Patterns worth stealing

- Shared operations contract for both CLI and MCP surfaces
- Embedded Postgres default with later migration to managed backend
- Compiled-truth plus append-only-timeline page structure
- Resolver-based filing rules for large agent-maintained knowledge bases
- Retrieval evaluation harnesses instead of blind faith in search quality
- Human-readable markdown layer over a richer indexed/searchable substrate
