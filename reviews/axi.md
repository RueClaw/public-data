# axi

- **Repo:** <https://github.com/kunchenguid/axi>
- **License:** MIT
- **Commit reviewed:** `5839015` (2026-04-07)

## What it is

AXI, Agent eXperience Interface, is a proposal for designing CLI tools specifically for AI agents rather than humans. The repo contains:

- the 10 AXI design principles
- benchmark harnesses for browser and GitHub tasks
- an installable AXI skill
- published study results comparing AXI-style tools against standard CLI and MCP conditions

This is one of the few repos in this space that is trying to define an interface philosophy and then benchmark it.

## Core thesis

CLIs built for humans and tool protocols built for generality both impose unnecessary token and turn overhead on agents.

AXI's answer is agent-native CLI design with principles like:
- token-efficient output
- minimal default schemas
- truncation with explicit escape hatches
- precomputed aggregates
- definitive empty states
- structured errors
- ambient context via hooks
- content-first defaults
- contextual disclosure
- concise help surfaces

Honestly, most of these are just good sense. The value is putting them in one coherent doctrine and measuring the effect.

## Strong parts

### 1. It benchmarks the idea
This matters. The repo doesn't just say "agent-native tools feel better". It presents browser and GitHub harnesses with repeated-condition comparisons.

### 2. The principles are concrete
The 10 principles are specific enough to implement. "Token-efficient output" and "minimal default schemas" are actual design guidance, not posture.

### 3. Ambient context as first-class interface design
The hook-install piece is important. Good agent interfaces do not begin at command invocation, they begin before the tool is called.

### 4. CLI ergonomics for models, not humans
This is still underexplored, and AXI is directionally right about it.

## Caveats

### 1. The repo is mostly doctrine + benchmarks, not a broad implementation corpus
The real reference implementation lives elsewhere (`gh-axi`, `chrome-devtools-axi`). This repo is more manifesto and harness.

### 2. Benchmarking agent interfaces is fragile
Success rates and cost deltas depend heavily on task design, grading, and runner assumptions. The results are interesting, not gospel.

### 3. Some principles overlap with just making better CLIs
AXI is partly a new label for existing good design habits. That's fine, but worth saying plainly.

## Why it matters for us

This repo is directly relevant to tool design for agent systems.

The most useful takeaways:
- design outputs for token economy, not just human readability
- default to summaries and aggregates instead of raw dumps
- make empty states explicit
- expose `--full` style escape hatches instead of flooding the model by default
- treat hooks and ambient context as part of the interface contract

That all maps very cleanly onto OpenClaw, CAR, and any agent-facing CLI design.

## Verdict

Good repo. More serious than the average "agents need better tools" post because it actually operationalizes the claim.

The benchmark claims should be treated as directional evidence, not scripture, but the principles themselves are solid and broadly reusable.

**Rating:** 4.5/5

## Patterns worth stealing

- Token-budget-first CLI design principles
- Minimal default schemas with explicit full-detail escape hatches
- Ambient context injection as part of interface design
- Benchmark harnesses that compare interface conditions, not just models
- Contextual disclosure and definitive empty states for agent reliability
