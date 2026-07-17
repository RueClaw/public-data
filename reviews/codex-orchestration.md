# Codex Orchestration (Cjbuilds/Codex-Orchestration)

**Repo:** https://github.com/Cjbuilds/Codex-Orchestration
**License:** MIT. Safe to adapt with attribution.
**Reviewed:** 2026-07-17
**Stack:** Codex plugin, Agent Skill, Python 3.11 configurators, local MCP bridge, GitHub Actions
**What it is:** A Codex plugin that installs a persistent Planner/Advisor/Executor routing policy so Codex can use compatible models, including Claude Fable 5 through Claude Code, while keeping the selected Codex task model as root.

---

## Verdict

✅ **Deploy candidate for Codex users who want safer multi-model routing.** This is much more than a prompt pack: it ships a real plugin manifest, bounded skill instructions, config-safe Python setup/status/disable tools, an opt-in no-tools Fable bridge, and a serious regression suite. The main caveat is honest but important: current Codex routing is policy-guided rather than a separate engine-level scheduler, so users still need to understand the root/child boundary.

---

## What It Is

Codex Orchestration adds three role seats to Codex work: an optional Planner, optional Advisor, and required Executor. The task's selected Codex model remains the root orchestrator. It decides whether delegation is useful, mediates the Planner/Advisor loop, verifies child output, and delivers the final answer.

The repo's most useful design choice is that it treats model routing as a bounded policy, not magic. Same-provider models are routed through Codex's native multi-agent controls. Claude Fable 5 is a bundled exception: it is exposed as Planner or Advisor through a disabled-by-default local MCP bridge that calls the authenticated Claude Code CLI with no tools and no session persistence.

This is aimed at advanced Codex users who want to use different models for planning, critique, and implementation without hand-editing config or pretending that child agents can safely self-coordinate.

## Stack

| Layer | Tech |
|-------|------|
| Package | Codex plugin manifest under `plugins/codex-orchestration/.codex-plugin/plugin.json` |
| Skill | `plugins/codex-orchestration/skills/codex-orchestration/SKILL.md` |
| Setup/status/disable | Python 3.11 scripts using Codex App Server config APIs |
| Cross-provider exception | Local MCP server invoking Claude Code CLI for Claude Fable 5 |
| Config/state | Codex user config plus `.codex-orchestration-routing.json` restore state |
| Tests | Python `unittest`, lifecycle smoke tests, packaging/contract tests |
| CI | GitHub Actions for lint, tests, lifecycle, legacy-client guard, CodeQL, portability |

## Key Features

### Root-Mediated Planner/Advisor/Executor Roles

The role model is intentionally conservative. Planner drafts and revises plans; Advisor reviews and either approves or asks for revision; Executors receive bounded implementation packets. Planner and Advisor do not talk to each other directly, and children are told not to spawn descendants.

That keeps Codex's normal authority model intact: the root still owns intent, decomposition, integration, permissions, verification, and the final answer.

### Config-Safe Native Routing

The native configurator does not rewrite TOML by hand. It uses Codex App Server `config/read` and `config/batchWrite`, preserves unrelated settings and comments, checks shared-client compatibility, records restore state, and refuses to overwrite user-authored routing hints without explicit replacement.

The status path also has an automation mode, `--require-effective`, that fails when policy is installed but ineffective, overridden, incomplete, incompatible, or backed by unavailable routes. That is the right shape for a feature that changes local agent routing.

### Claude Fable 5 Bridge

The Fable bridge is narrow and fail-closed. It strips provider override environment variables, checks for first-party Claude Code login, pins `claude-fable-5`, disables tools and session persistence, bounds input size, and validates runtime model metadata against a small allowlist.

The repo is also careful not to overclaim: MCP requests do not currently carry caller identity, so the "root only" caller boundary is instruction-enforced, while no-tools execution and model/effort pinning are mechanically enforced by the bridge.

### Strong Test Posture

The test suite is unusually broad for a small plugin. Local verification ran 189 tests successfully across routing state validation, native config behavior, Fable bridge boundaries, packaging, release metadata, skill contracts, and custom-agent lifecycle safety.

CI adds pinned GitHub Actions, CodeQL, Dependabot, Python 3.11/3.13 tests, plugin lifecycle smoke tests against Codex CLI, a legacy-client compatibility guard, and macOS/Windows portability checks.

## Architecture

The repository is compact:

```text
plugins/codex-orchestration/
  .codex-plugin/plugin.json
  .mcp.json
  skills/codex-orchestration/
    SKILL.md
    agents/openai.yaml
    references/providers-and-models.md
    scripts/configure_native_routing.py
    scripts/configure_orchestration.py
    scripts/fable_advisor_mcp.py
    scripts/routing_state.py
    scripts/inspect_models.py
tests/
scripts/release_check.py
docs/production-readiness-audit.md
```

The key split is between policy and execution. `SKILL.md` describes the user-facing contract and agent behavior. `configure_native_routing.py` manages Codex's native multi-agent policy fields. `configure_orchestration.py` manages provider-pinned custom-agent files for durable cross-provider roles. `fable_advisor_mcp.py` exposes bounded planning/review operations for Claude Fable 5.

The production-readiness audit is worth reading because it documents known boundaries instead of burying them: direct routing is not an engine-level `executor_model`; cross-provider setup spans two storage transactions; Windows custom-agent mutation fails closed; setup-time config parsing is not live route proof.

## Comparison

| Aspect | Codex Orchestration | Fable Advisor | Open Multi-Agent | Use Codex Skill |
|--------|---------------------|---------------|------------------|-----------------|
| Primary value | Persistent Codex routing policy with setup/status/disable | Claude Code lane doctrine | TypeScript runtime DAG orchestration | Prompt pattern for CLI delegation |
| Runtime | Codex plugin plus Python configurators | Claude Code plugin and optional Codex CLI | Node/TypeScript library | Host agent plus shell-spawned Codex |
| Best idea | Root-mediated role seats with reversible config | Architect keeps judgment, workers do volume | Plan preview/replay and scheduler | Parent validates subagent claims |
| Main caveat | Policy-guided routing is not a separate scheduler | Light runtime enforcement | Dynamic DAG needs gates | Unsafe defaults in examples |

Codex Orchestration is closest in spirit to Fable Advisor, but it is substantially more engineered: reversible config writes, status checks, compatibility probes, bundled bridge constraints, and tests turn the doctrine into an installable Codex workflow.

## Self-Hosting Notes

Install is through the Codex plugin marketplace:

```bash
codex plugin marketplace add Cjbuilds/Codex-Orchestration
codex plugin add codex-orchestration@codex-orchestration
```

Setup requires Python 3.11 or newer. Fable usage additionally requires the official Claude Code CLI and a compatible first-party Claude login. Users with multiple Codex clients sharing one config should pay attention to the compatibility checks; an older CLI may reject newer multi-agent policy fields.

For production-like use, start with `status --require-effective`, keep Planner and Advisor distinct, avoid treating child reports as evidence, and verify diffs/tests in the root session.

## Verification

Reviewed commit `df1e3da61fcca1b6134fdc1ac1a1f3100d403757` from 2026-07-14. GitHub metadata at review time: 362 stars, 27 forks, 1 open issue, MIT license, created 2026-07-10, last pushed 2026-07-14.

Local verification:

```bash
python3 -m unittest discover -s tests -v
```

Result: 189 tests passed.

---

**Attribution:** Cjbuilds/Codex-Orchestration, MIT License
