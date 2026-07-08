# Fable Advisor (DannyMac180/fable-advisor)

**Repo:** https://github.com/DannyMac180/fable-advisor
**License:** MIT. Safe to adapt with attribution.
**Reviewed:** 2026-07-07
**Stack:** Claude Code plugin metadata, Markdown agent definitions, Agent Skill
**What it is:** A Claude Code plugin that formalizes an "architect model delegates implementation" workflow: run the main session on the strongest model, route implementation to cheaper or different-model subagents, and reserve the strongest model for judgment.

---

## Verdict

⚠️ **Interesting orchestration doctrine, not a turnkey runtime.** The repo is small and readable, with useful agent contracts for model routing, cost discipline, and verification. Its main risk is that it assumes model names and Claude Code routing behavior that may be account- or version-dependent, and the GPT lane delegates to a CLI with broad coding authority.

---

## What It Is

Fable Advisor is a Claude Code plugin/skill package for a cost-aware multi-model coding workflow. The intended setup is a premium model in the main session acting as architect: it makes requirements, architecture, routing, and verification decisions, while cheaper or alternate implementation lanes do most of the token-heavy coding work.

The repo ships three agents and one skill. `fable-advisor` is a read-only second-opinion agent for architecture decisions and failed debugging loops. `implementer` is the default Sonnet implementation lane. `codex-implementer` is a cross-vendor lane that shells out to the OpenAI Codex CLI, then requires independent verification. The `orchestration` skill ties those lanes together with routing rules, a five-part delegation spec contract, and verification expectations.

This is best read as a workflow pattern for agent operators rather than as software infrastructure. There is no executable test suite or runtime beyond Claude Code's plugin loader and the external Codex CLI.

## Stack

| Layer | Tech |
|-------|------|
| Package format | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` |
| Agents | Markdown agent definitions with YAML frontmatter |
| Skill | Markdown `SKILL.md` |
| Runtime dependency | Claude Code plugin/subagent support |
| Optional lane | OpenAI Codex CLI |
| Tests/CI | None visible |

## Key Features

### Cost-Aware Model Routing

The strongest idea is the explicit routing table: keep the expensive session model responsible for judgment, specs, and verification, while routing routine implementation to a cheaper lane and high-risk work to stronger or cross-vendor lanes.

That is a useful antidote to "one giant model does everything" workflows. The repo states a concrete division of labor instead of vaguely saying "use subagents."

### Five-Part Delegation Contract

The `implementer` agent requires every delegated task to include objective, files, interfaces, constraints, and verification. That is the right shape for context-free subagent work because it makes missing context visible instead of letting the worker guess.

### Verification Over Trust

Both the regular implementer and Codex lane emphasize that reports are claims, not evidence. The Codex lane in particular tells the supervising agent to inspect the diff and rerun verification instead of accepting Codex's final message.

### Read-Only Advisor Boundary

The `fable-advisor` agent is explicitly advisory and read-only. That boundary is good: the highest-judgment lane is there to break bad plans, not to sprawl into implementation.

## Architecture

The repo is almost entirely instruction architecture:

```text
.claude-plugin/
  plugin.json
  marketplace.json
agents/
  fable-advisor.md
  implementer.md
  codex-implementer.md
skills/orchestration/
  SKILL.md
```

The design is intentionally thin. Claude Code provides model routing, subagent invocation, tool policy, and skill loading. The plugin contributes doctrine and contracts.

The sharpest operational choice is the Codex lane. It preflights `codex`, writes a unique temporary spec file, runs `codex exec`, and asks the supervising agent to verify the resulting diff. That is useful, but it also means the security posture depends on the host's Codex configuration, sandbox, workspace, and secret exposure.

## Comparison

| Aspect | Fable Advisor | addyosmani/agent-skills | dzhng/skills | Use Codex Skill |
|--------|---------------|-------------------------|--------------|-----------------|
| Main value | Cost-aware model routing and lane contracts | Full software lifecycle skill pack | Long-running spec/slice workflow | CLI subagent context offload |
| Runtime | Claude Code plugin + external Codex CLI | Markdown skills, commands, validation scripts | Markdown skills plus helper script | Prompt document |
| Best idea | Architect keeps judgment, workers do volume | Anti-rationalization skill anatomy | Living slice graph | Parent validates subagent output |
| Main caveat | Model/version assumptions and no tests | Large surface to reconcile | Light enforcement | Unsafe defaults |

Fable Advisor is narrower than the larger skill packs, but cleaner on the specific topic of model routing.

## Self-Hosting Notes

Installation is through Claude Code plugin marketplace commands:

```bash
claude plugin marketplace add DannyMac180/fable-advisor
claude plugin install fable-advisor
```

The optional Codex lane requires `codex` installed and authenticated. Treat it as an autonomous coding lane with real local permissions. Use it only in clean worktrees or isolated workspaces, and verify every diff before accepting it.

There is no separate service to deploy.

---

**Attribution:** DannyMac180/fable-advisor, MIT License
