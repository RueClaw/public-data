# Graph-Backed Context Bundle Selection

**Source:** https://github.com/stevesolun/ctx
**License:** MIT
**Reviewed:** 2026-05-17

## Pattern

Use a knowledge graph to select a small, task-specific bundle of agent helpers instead of loading every available skill, agent, MCP server, or harness.

The system has four parts:

1. Entity catalog: skills, agents, MCP servers, harnesses, and metadata.
2. Evidence scanner: detects the current repository stack and task signals.
3. Graph/ranking layer: scores entities by tags, slug tokens, semantic similarity, quality, usage, source overlap, and graph structure.
4. Approval surface: recommends load/install/update/unload actions without mutating live context until the user or policy approves.

## Why It Works

Large helper catalogs create a context-budget problem. More available skills do not help if the model sees the wrong ones or too many at once.

Graph-backed selection lets the system answer what stack this repo uses, which helpers are directly relevant, which adjacent helpers are useful through graph relationships, which helpers are low quality or stale, and what should stay out of context.

## Ranking Signals

| Signal | Purpose |
|--------|---------|
| Stack evidence | Match the actual repo, not vague user intent |
| Task/query tokens | Match the current request |
| Semantic similarity | Catch related concepts that tags miss |
| Graph neighbors | Include supporting helpers |
| Usage history | Prefer helpers that worked before |
| Quality score | Demote broken or stale helpers |
| Conflict rules | Avoid loading mutually incompatible helpers |
| Token budget | Cap the final bundle |

## Safety Rules

- Recommend first, mutate only through explicit commands or approved policy.
- Explain why each helper is included.
- Keep install/update/uninstall dry-runs available.
- Treat remote harnesses and MCP servers as higher-risk than local docs-only skills.
- Log accepted and rejected recommendations to improve future ranking.
- Keep a hard cap on loaded helpers.

## Good Fit

This pattern is useful for AI coding assistants with many optional skills, MCP-heavy workbenches, multi-agent systems with specialist libraries, local knowledge bases with many reusable workflows, and context-window constrained tools.

## Cautions

Graph-backed recommendation systems can become heavy. Keep the runtime path fast, cache graph indexes, and make artifact validation part of release. If the graph cannot load, the system should degrade to file/tag matching rather than fail closed for ordinary work.

---

**Attribution:** Pattern summarized from stevesolun/ctx, MIT License.

