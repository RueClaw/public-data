# ECC Patterns — Everything Claude Code

**Source:** https://github.com/affaan-m/everything-claude-code
**License:** MIT
**Author:** Affaan Mustafa
**Extracted:** 2026-03-16

Patterns and scripts from Everything Claude Code (ECC), an Anthropic hackathon winner.
50K+ stars. 10+ months of daily production use.

## What's here

| File | What it is |
|------|-----------|
| `ecc-curated-instincts.yaml` | Curated instincts for ECC repo itself — format reference |
| `continuous-learning-v2.md` | Full SKILL.md for the instinct-based learning system |
| `observe.sh` | Hook script that captures every tool call (PreToolUse/PostToolUse) |
| `instinct-cli.py` | CLI to manage instincts — status, export, import, promote |
| `evaluate-session.js` | Stop-hook session evaluator (v1 pattern, fires at session end) |
| `hooks-rules.md` | Rules doc: hook types, best practices, TodoWrite guidance |
| `architect.md` | Architect agent definition |
| `planner.md` | Planner agent definition |
| `chief-of-staff.md` | Chief of staff meta-agent |
| `harness-optimizer.md` | Harness optimizer agent |
| `loop-operator.md` | Loop operator agent (autonomous loop mgmt) |

## Key Patterns

### Instinct model (continuous-learning-v2)
Atomic learned behaviors: `trigger` + `action` + `confidence` (0.3-0.9) + `evidence`.
Project-scoped by default (git remote URL hash), promote to global when seen in 2+ projects.
Hooks fire 100% of the time — v1 skills fire 50-80%. Hook-based observation is more reliable.

### Hook reliability
- `PreToolUse` / `PostToolUse` hooks: deterministic, 100% capture
- `Stop` hook: session end summary
- `ECC_HOOK_PROFILE=minimal|standard|strict` for load control
- Script-based hooks (`run-with-flags.js`) for complex conditional logic

### The instinct lifecycle
```
Session → observe.sh captures every tool call → observations.jsonl
→ background observer (Haiku) detects patterns → instinct .yaml files
→ /evolve clusters instincts → skills/commands/agents
→ /promote elevates project instincts to global
```
