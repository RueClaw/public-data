# My Brain Is Full — Crew Review

**Repo:** https://github.com/gnekt/My-Brain-Is-Full-Crew  
**License:** MIT  
**Author:** Christian Di Maio (@gnekt) — PhD researcher  
**Language:** Markdown agent definitions (Claude Code multi-agent framework)  
**Cloned:** ~/src/My-Brain-Is-Full-Crew  
**Rating:** 🔥🔥🔥🔥

---

## What It Is

A **10-agent Claude Code multi-agent system** that manages your Obsidian vault through conversation. You talk to Claude, it routes to the right specialist agent, and your vault gets updated — no manual filing, no browsing Obsidian, no folder management.

Origin: A PhD researcher whose working memory started failing. Built what he actually needed — not a fancy note-capture tool, but a **brain dump system** for someone who is drowning.

---

## The Crew

| Agent | Role |
|---|---|
| **Architect** | Vault structure, onboarding, templates, MOCs — designs the system everyone else operates within |
| **Scribe** | Captures messy stream-of-consciousness dumps → clean structured notes |
| **Sorter** | Evening inbox triage — routes every note to its correct location |
| **Seeker** | Vault search + synthesis — answers questions with citations across notes |
| **Connector** | Knowledge graph analysis — finds hidden connections between notes you'd never spot |
| **Librarian** | Weekly maintenance — deduplication, broken link repair, vault health analytics |
| **Transcriber** | Audio/meeting recordings → structured notes with follow-up tasks |
| **Postman** | Gmail + Google Calendar bridge → deadline radar, meeting prep, calendar notes |
| **Food Coach** | Meal ideas, grocery lists, food preferences (opt-in) |
| **Wellness Guide** | Emotional support, grounding techniques (always recommends professionals, opt-in) |

---

## Architecture

```
CLAUDE.md  ← dispatcher: routing rules only, never answers directly
  ↓ delegates via Agent tool to:
agents/*.md  ← 10 specialist agents, auto-loaded by Claude Code
skills/*/   ← supporting skill files per agent
```

**CLAUDE.md is a pure dispatcher** — absolute constraint: never answer directly, always delegate to one of the 10 agents. Routing priority is strict (wellness-guide highest → librarian lowest). The key insight: routing by intent, not by explicit "/command" syntax. You just talk naturally.

**Agents communicate with each other via a shared inter-agent messaging protocol** — the Sorter leaves messages for the Architect when it finds orphaned notes; the Food Coach flags the Wellness Guide when stress-eating patterns appear; the Transcriber signals the Sorter after processing a meeting. This is a genuinely orchestrated crew, not isolated tools running in parallel.

**Language-agnostic:** Every agent description includes trigger phrases in 6+ languages (English, Italian, French, Spanish, German, Portuguese). The routing works in any of them. Agents match the user's language in responses.

**User profile:** Each agent reads `Meta/user-profile.md` before acting — provides personal context to weight results and actions. Bootstrapped during Architect onboarding.

---

## What's Actually Good

### The Dispatcher Pattern
CLAUDE.md as a pure router with no ego is correct. The "NEVER RESPOND DIRECTLY" constraint forces proper delegation. Most multi-agent setups let the coordinator answer directly when things are ambiguous — that leads to inconsistency. This one refuses.

### Wellness Guide Priority = #1 (Above Everything)
The routing rules explicitly handle implicit emotional distress signals that users will never name directly ("this sucks", "I can't take it anymore", "enough", "I'm sick of this"). The CLAUDE.md even says: *"They will vent, complain, describe pain. YOU must recognize it and delegate IMMEDIATELY."* This is unusually thoughtful for a productivity tool.

### Connector Agent
Finding non-obvious connections across vault notes — the "constellation" and "serendipity" features. This is the actual value proposition of a knowledge graph that most Obsidian users never unlock because it requires you to read all your own notes and spot the patterns. Automating this is high-value.

### Postman (Gmail + Calendar Bridge)
Turns email + calendar into vault-aware context. "Meeting prep" means your notes about the project are surfaced before you walk in. "Deadline radar" means your vault knows about your commitments, not just your notes.

### 5958 lines of agent definition
These aren't thin wrappers. Each agent has substantial system prompt with user profile integration, inter-agent messaging protocol, and language handling. The Seeker alone has detailed search strategies, citation formats, and synthesis patterns.

---

## What's Not Great

### No Automated Testing / Eval
~6K lines of agent definitions with zero tests. Multi-agent routing correctness is hard to verify without eval harness — you're trusting the agent descriptions are tight enough that Claude routes correctly every time.

### Obsidian Dependency (via Claude Code)
This is built specifically for Obsidian vaults. It assumes a specific vault structure set up by the Architect agent during onboarding. If your vault organization deviates, expect friction.

### Food Coach / Wellness Guide Scope Creep Risk
The author is transparent about these being opt-in and explicitly not medical advice. But "wellness guide" in a personal knowledge manager is a non-trivial inclusion. Worth reading DISCLAIMERS.md before sharing with anyone who might take it too seriously.

### Claude Code Required
This runs as a Claude Code multi-agent project (`.claude/agents/` directory). Not usable with plain Claude, OpenClaw, or other runtimes without adaptation. The architecture is sound and portable, but the current implementation is tightly coupled to Claude Code's agent loading mechanism.

---

## Comparison to Ori-Mnemos (reviewed #229)

Ori-Mnemos: cognitive memory with decay zones, four-signal retrieval fusion, 15 MCP tools. Designed for **agent memory** — embedding, retrieval, and compaction with mathematical rigor.

My Brain Is Full: designed for **human knowledge management** — capture, organize, search, connect, and emotional support. Uses Claude Code's native agent routing, not MCP.

They're complementary, not competing. Ori-Mnemos is the memory layer for AI agents. My Brain Is Full is the memory system for humans using Claude as a collaborator.

---

## Relevance for Us

**The dispatcher pattern is extractable.** The CLAUDE.md approach — pure router, no ego, routing by intent not command syntax — is a clean pattern for any multi-agent project. ODR's meta-critic routing could learn from this.

**The Connector agent's approach** — finding non-obvious cross-note relationships — mirrors what we want for the Marcos agent's knowledge graph. The implementation strategy (Grep + Read across vault + synthesize connections) is worth reading in full.

**The inter-agent messaging protocol** — agents leaving notes for each other in a shared inbox — is a simple but effective coordination pattern that doesn't require a complex orchestration framework. Worth adapting.

**Not useful for Vida Meat or non-technical users** — this requires Claude Code and manual vault setup. It's a developer/researcher tool.

---

## Verdict

A genuinely well-thought-out multi-agent system by someone who built it to solve their own real problem. The dispatcher architecture is clean, the routing is thorough, and the inter-agent coordination is more sophisticated than most hobby projects. The wellness-guide-first priority reveals unusual care about the human using it.

MIT license. Worth reading the agent definitions for patterns even if you never run it as-is. The Connector and Sorter agents are the most novel; the dispatcher pattern in CLAUDE.md is the most exportable.

---

*Source: https://github.com/gnekt/My-Brain-Is-Full-Crew | License: MIT | Author: Christian Di Maio (@gnekt) | Reviewed: 2026-03-21 | Note: repo went private 2026-03-22 — clone retained at ~/src/My-Brain-Is-Full-Crew*
