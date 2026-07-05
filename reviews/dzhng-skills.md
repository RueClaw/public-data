# Skills (dzhng/skills)

**Repo:** https://github.com/dzhng/skills
**License:** MIT. The skill text and bundled helper script can be reused with attribution.
**Reviewed:** 2026-07-05
**Stack:** Markdown Agent Skills, Claude plugin manifest, Node.js helper script for visual diffing
**What it is:** A compact, opinionated catalog of agent skills for turning large software work into mapped unknowns, independently verifiable specs, iterative implementation passes, review loops, and visual gates.

---

## Verdict

✅ **Deploy candidate for agent-workflow teams.** This is not a product runtime; it is a portable instruction library. The best parts are the strict spec lifecycle, recursive reslicing, visual verification discipline, and explicit skill-authoring/eval guidance. It is strongest when installed as a workflow layer for coding agents, not treated as generic documentation.

---

## What It Is

`dzhng/skills` is a personal skill catalog for software-factory style agent work. It ships 16 skills across engineering, visual review, authoring, and graphics. The repository is small, readable, and intentionally harness-agnostic: the README names Claude Code, Codex, opencode, Cursor, duet, and the wider Vercel Labs skills ecosystem as targets.

The core thesis is that autonomous software work should be sliced into independently verifiable pieces. The `write-spec` skill turns a broad goal into a `specs/<feature>/` folder with a living README, slice files, review surfaces, assets, and handoff prompts. The `implement-spec` skill then treats each pass as a committed checkpoint while continuing until the whole spec is done.

The repo is useful because it encodes operational judgment rather than long-form philosophy. Most files are direct procedures: when to inspect, when to spawn fresh drafts, when to reslice, when to run visual critique, when to delete temporary scaffolding, and how to keep handoffs current.

## Stack

| Layer | Tech |
|-------|------|
| Skill format | Markdown `SKILL.md` files with YAML frontmatter |
| Distribution | `npx skills add dzhng/skills`, plus `.claude-plugin/plugin.json` |
| Runtime dependencies | None for most skills |
| Helper tooling | Node.js ESM screenshot diff script using `pngjs` and `pixelmatch` from the host repo |
| Assets | README images only |
| Tests/CI | No visible automated test suite in this repo |

## Key Features

### Spec-Driven Software Factory Loop

The strongest engineering pattern is the pair of `write-spec` and `implement-spec`. `write-spec` insists on mapping unknowns, slicing at API boundaries, building visible checkpoints, and materializing the plan as a reviewable folder. `implement-spec` then keeps the agent moving through passes, commits, cleanup, verification, and handoff updates.

The useful detail is that reslicing is treated as normal work. If implementation reveals that a slice is too broad, the agent updates the spec first instead of stretching the patch until it becomes unreviewable.

### Recursive Unknown Mapping

`explore-unknowns` uses a quadrant walk: known knowns, known unknowns, unknown knowns, unknown unknowns, then a final handoff map. The structure is stronger than a generic "ask clarifying questions" instruction because it requires the agent to hand the user a concrete map before implementation starts.

### Visual Review Discipline

The visual skills reject vague screenshot approval. `compare-screenshots` frames pixel metrics as diagnostic telemetry, not as acceptance. It requires a target from first principles, comparability checks, side-by-side artifacts, crops, heatmaps, edge maps, and a final "less wrong" verdict. The bundled `visual-parity-diff.mjs` script is the only real code in the repo and provides a reusable local comparison harness.

### Skill Authoring and Eval

`write-skills` is one of the most reusable files. It treats skills as compressed operational memory rather than docs, emphasizes trigger descriptions, progressive disclosure, checkable completion criteria, and no-op pruning. `eval-skills` adds blind runs, separate judging, pass-rate thinking, and failure diagnosis against skill defects.

## Architecture

The repo is intentionally flat and transparent:

- `skills/engineering/` holds planning, implementation, refactoring, docs, tests, and second-agent workflow skills.
- `skills/visual/` holds screenshot critique, comparison, and preview skills.
- `skills/authoring/` holds skill creation and eval practices.
- `skills/graphics/renderer/` provides a focused WebGPU/three.js renderer workflow.
- `.claude-plugin/plugin.json` lists the skill directories for Claude-style plugin installation.

The main architectural choice is to keep almost everything in Markdown procedures, with long variants pushed to `references/` and fragile operations pushed to `scripts/`. That matches the repository's purpose: portable agent behavior, not a coupled library.

## Comparison

Compared with broader agent-skill collections, this repo is narrower but sharper. It is less of a catalog and more of an operating style for large software changes.

| Aspect | dzhng/skills | qship | ponytail | shadcn/improve |
|--------|--------------|-------|----------|----------------|
| Primary shape | Portable skill library | Ticket-to-PR delivery pipeline | Behavior layer across harnesses | Read-only audit-to-plan skill |
| Runtime | Mostly Markdown | Hooks, rendered skills, state files | Adapters, hooks, generated skills | Markdown skill |
| Best use | Planning, slicing, verification discipline | Enforced long-running implementation | Coding-agent defaults and restraint | Senior review plans |
| Main caveat | No tests/CI for the skill catalog itself | Higher automation blast radius | Larger adapter surface | Does not execute fixes |

## Self-Hosting Notes

There is no service to self-host. Install with:

```bash
npx skills add dzhng/skills
```

or copy specific `skills/<category>/<name>/` folders into a compatible harness. Because the repo is MIT-licensed, teams can fork and adapt the skills. The main adoption work is policy, not deployment: decide which skills should be always available, which should be user-invoked, and which behaviors conflict with local review or commit rules.

---

**Attribution:** dzhng/skills, MIT License, https://github.com/dzhng/skills
