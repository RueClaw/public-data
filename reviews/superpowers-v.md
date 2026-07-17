# Superpowers V (procoders/superpowers-v)

**Repo:** https://github.com/procoders/superpowers-v  
**License:** MIT. Safe to adapt with attribution.  
**Reviewed:** 2026-07-17  
**Stack:** Claude Code plugin, Agent Skills, Python 3.9+ helper scripts, Bash adapters, JSON schemas, GitHub Actions  
**What it is:** A Claude Code plugin that layers a deterministic multi-model coding orchestration workflow on top of Superpowers: pre-flight research, manifest-based task partitioning, multi-backend worker dispatch, git-derived scope gates, crash resume, local memory, and epic/marathon modes.

---

## Verdict

✅ **Deploy candidate for advanced Claude Code users who already want disciplined agent orchestration.** This is an ambitious plugin, but it is unusually explicit about authority boundaries: manifests are validated, worker scope is checked from git rather than self-report, lower-trust external CLIs are labeled as lower-trust, and the repo ships a large selftest surface. The main caveat is complexity: it is not a lightweight skill pack, and it is still primarily a Claude Code workflow despite Codex/Gemini shim docs.

---

## What It Is

Superpowers V, branded as Compound V, is a sidekick to the Superpowers coding-agent methodology. Instead of replacing the upstream brainstorming/planning workflow, it intercepts several phase transitions and adds structure around them:

- optional pre-brainstorm recon
- three parallel pre-flights: code archaeology, domain expert, and library/documentation validation
- disjoint file partitioning
- a machine-readable `manifest.yaml`
- multi-backend worker dispatch
- git-derived write-scope enforcement
- result collection and review gates
- local outcome/prose memory
- resumable epic and marathon modes

The design goal is to let a strong orchestrator split a feature into non-overlapping implementation jobs, route each job to a suitable backend, and prevent worker drift from silently merging. It supports Claude subagents, headless Codex, Antigravity, Cursor, Devin, and opencode adapters, but treats Codex as the preferred external worker for untrusted or high-stakes work because Codex has a workspace sandbox. Antigravity, Cursor, Devin, and opencode are explicitly labeled lower-trust because the worktree plus git gate detects scope violations after the fact but does not provide the same preventive boundary.

## Stack

| Layer | Tech |
|-------|------|
| Plugin package | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` |
| Skills | `skills/compound-v`, `skills/backend-launcher`, `skills/pr-review` |
| Commands | `/v:init`, `/v:epic`, `/v:dispatch`, `/v:resume`, `/v:dashboard`, `/v:preferences`, `/v:pr-review`, and related wrappers |
| Agents | Code archaeology, domain expert, doc validator, partition reviewer, dispatcher, spec reviewer |
| Deterministic gates | Python scripts for manifest validation, scope checking, model resolution, pre-eval, fast-path, epic state, arbiter, dashboard, memory |
| Worker adapters | Bash wrappers for Codex, Antigravity, Cursor, Devin, opencode plus Claude subagent contract docs |
| State | `docs/superpowers/**` run records, memory, archaeology, expert, library-audit, specs, plans |
| CI | GitHub Actions validating manifests, frontmatter, schemas, hooks, shell scripts, cross-links, and selftests |

There is no normal Python package manifest. The repo is a plugin plus a collection of pure-Python and shell utilities.

## Key Features

### Manifest-Driven Worker Dispatch

The central contract is a manifest that describes jobs, dependencies, allowed write globs, read intent, backend, tier, effort, isolation, and acceptance criteria. `scripts/compound-v-validate-manifest.py` rejects overlapping write scopes, path-traversal ids, missing model/tier intent, invalid effort values, parallel direct jobs, Codex jobs without worktrees, non-deep reviewers, lower-trust backends used as reviewers, and malformed fast-path bindings.

That moves a lot of agent orchestration out of prose and into a deterministic artifact.

### Git-Derived Scope Gate

The strongest reusable idea is the scope gate. `scripts/compound-v-scope-check.py` computes changed files from git, including tracked diffs, untracked files, ignored files, committed-in-worktree changes, rename sources, unusual filenames, and escaping symlinks. Anything outside `write_allowed` blocks the job. The worker's summary is never trusted as the source of truth.

This is the right shape for multi-agent coding. Prompt instructions say "do not write outside scope"; the gate decides whether the worker actually did.

### Honest Backend Trust Model

The repo is candid about backend differences. Codex runs in a worktree with `--sandbox workspace-write`. Antigravity and Cursor need stronger permission flags for headless writes and lack the same kernel-level confinement. Devin has a research-preview sandbox but is still treated as lower-trust until verified. opencode is marked lower-trust and worker-only because it is provider-agnostic and has a permissive default posture.

That honesty is important. The plugin does not pretend that all "worker CLIs" are equivalent.

### Epic, Marathon, and Recovery State

Compound V can chain multiple feature builds through an epic state machine. Default epic mode checkpoints after each feature. Marathon mode is opt-in and adds global breakers, blocker ledgers, arbiter panels, durable audit obligations, and resume/watch mechanics. The docs are careful about boundaries: scheduler-based resurrection is bounded catch-up, not an always-on service, and machine-off execution is out of scope.

### Local Memory and Preference Recall

V-memory indexes `docs/superpowers/**` with an always-on SQLite FTS5 lane and optional dense embeddings. It is evidence for planning/review, not a routing input. Decision preference memory stores raw personal decision logs outside the repo, distills scrubbed summaries into repo docs, and pairs recall with a challenge rather than using past behavior as an autopilot default.

## Architecture

The repo is organized as a plugin runtime written mostly in Markdown contracts plus Python enforcement scripts:

```text
.claude-plugin/          plugin and marketplace manifests
agents/                  first-class agent definitions
commands/                /v:* command wrappers
skills/compound-v/       orchestration phases, routing, memory, epic mode
skills/backend-launcher/ backend adapter contracts
scripts/                 deterministic validators, gates, workers, state tools
schemas/                 JSON schemas for job results and review artifacts
docs/superpowers/        dogfooded run records, architecture notes, memory
tests/                   shell and Python acceptance tests
```

The split between prose contracts and deterministic scripts is the main architectural pattern. Markdown explains the workflow and worker contracts; Python scripts enforce the parts that should not depend on model obedience.

## Comparison

| Aspect | Superpowers V | Superpowers | compound-engineering-plugin | Codex Orchestration |
|--------|---------------|-------------|-----------------------------|---------------------|
| Primary value | Claude Code orchestration layer with multi-backend workers and deterministic gates | Methodology and skill workflow for disciplined coding agents | Cross-harness engineering workflow plugin | Codex-specific Planner/Advisor/Executor routing policy |
| Execution model | Manifest → dispatcher → backend workers → git scope gate | Mostly skill/procedure driven | Workflow skills and adapters | Root-mediated model seats |
| Strongest idea | Git-derived scope enforcement plus manifest invariants | File-backed planning/review loop | Stable plan IDs and workflow contracts | Truthful model-routing boundaries |
| Main caveat | Complex, Claude Code-first, many optional backends | Less of a runtime | Workflow overlap if installed wholesale | Narrower routing focus |

Superpowers V is closest to a local "agent squad" runtime for Claude Code. It is much heavier than a normal skill pack, but it also has much stronger deterministic machinery.

## Self-Hosting Notes

Install from Claude Code:

```text
/plugin marketplace add https://github.com/procoders/superpowers-v
/plugin install superpowers-v@procoders
```

Then run `/v:init` in a project. It detects Codex, Context7, Antigravity, Cursor, Devin, opencode, and other capabilities, then writes project-local config.

For cautious use:

- Start Claude-only or Claude + Codex before enabling lower-trust backends.
- Keep marathon and auto-resurrection modes off until the normal checkpoint loop is understood.
- Treat `docs/superpowers/**` as durable run state and review evidence, not scratch.
- Review generated config and capabilities before letting the plugin route external workers.

## Verification

Reviewed commit `478aeef686e5a46e2aeb13519a0335e92c23c5a4` from 2026-07-17. GitHub metadata at review time: 19 stars, 1 fork, 0 open issues, MIT license, latest release `v2.16.0`, created 2026-05-18, last pushed 2026-07-17.

Local verification:

```bash
python3 -m compileall -q scripts tests
python3 -m venv .venv
.venv/bin/python -m pip install pyyaml pytest
.venv/bin/python scripts/lint-frontmatter.py .
.venv/bin/python scripts/compound-v-validate-manifest.py examples/manifest.example.yaml
.venv/bin/python scripts/compound-v-validate-manifest.py --selftest
.venv/bin/python scripts/compound-v-scope-check.py --selftest
LANG=C .venv/bin/python tests/v2.9-e2e/test_fastpath_and_escalation.py
bash tests/test-codex-review-schema-default.sh
bash tests/test-session-banner-staleness.sh
for f in scripts/*.py; do
  if grep -q -- '--selftest' "$f"; then .venv/bin/python "$f" --selftest; fi
done
```

Results: compile passed; frontmatter clean; manifest example valid; manifest and scope selftests passed; v2.9 e2e ran 12 tests successfully; shell smoke tests passed; all discovered Python script `--selftest` commands exited cleanly.

`shellcheck hooks/*.sh scripts/*.sh tests/*.sh` found two warnings in `tests/test-session-banner-staleness.sh` (`cd` without `|| exit`, and `A && B || C` style). Runtime hooks/scripts were otherwise clean in that sweep.

## Caveats

The repo is young and low-star despite being active. That is not a blocker, but it argues for piloting on non-critical repositories first.

The workflow surface is large. Users need to understand what is deterministic, what is description-driven, and what still depends on the parent agent invoking the right skill at the right phase.

Some compatibility surfaces are explicitly experimental. `AGENTS.md` and `GEMINI.md` document Codex/Gemini shims, but the repo says those have not been tested on real installs.

Lower-trust worker backends should be opt-in. The repo's own docs say the worktree plus git gate detects in-worktree violations but cannot prevent all out-of-worktree side effects for those CLIs.

## Extracted Pattern

Extracted to `public-data/patterns/git-derived-agent-worker-scope-gate.md`.

The reusable pattern is to combine manifest-declared `write_allowed` scopes with a post-worker git authority that detects tracked, untracked, ignored, committed, renamed, and symlink-escape changes before any worker output is merged.

---

**Attribution:** procoders/superpowers-v, MIT License
