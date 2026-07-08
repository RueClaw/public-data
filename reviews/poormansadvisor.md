# poormansadvisor (leighstillard/poormansadvisor)

**Repo:** https://github.com/leighstillard/poormansadvisor
**License:** README says MIT, but there is no LICENSE file and GitHub does not detect a license; treat as educational/personal-use unless clarified.
**Reviewed:** 2026-07-07
**Stack:** Claude Code Skill Markdown, subagent routing prompt, optional Codex advisor lane
**What it is:** A single-file Claude Code skill that tries to approximate Anthropic's advisor strategy by routing hard decisions to a stronger or different advisor model without moving the whole session to that model.

---

## Verdict

⚠️ **Interesting advisor-consult pattern, but under-packaged and too trusting as written.** The core idea is sound: when the executor is stuck or making a high-blast-radius decision, ask a stronger or independent model for advice before continuing. The implementation is only a `SKILL.md`, though, and several claims depend on host behavior that is not enforced by the repo: slash-command invocation, automatic trigger discipline, current-model detection, and a nonstandard Codex subagent target.

---

## What It Is

`poormansadvisor` is a small Claude Code skill inspired by Anthropic's advisor strategy. Instead of using the API-only advisor tool, it instructs the current coding agent to gather a minimal context brief and spawn an advisor subagent. Sonnet or Haiku sessions route to Fable; Opus or Fable sessions route to Codex.

The skill is explicitly advisory. It tells the advisor not to implement changes, only to return analysis, recommendations, risks, and next steps. It is designed to auto-trigger when the agent is stuck, looping, facing architectural uncertainty, touching multiple subsystems, or noticing uncertainty in its own reasoning.

As a repository, this is closer to a prompt pattern than an installable plugin. It has no plugin manifest, no command file, no tests, and no license text file. The README describes `/poormansadvisor` usage, but the repo does not include a slash-command artifact that would make that invocation portable across Claude Code setups.

## Stack

| Layer | Tech |
|-------|------|
| Skill | Single `SKILL.md` with YAML frontmatter |
| Distribution | Manual copy or symlink into `~/.claude/skills/poormansadvisor` |
| Advisor backend | Host `Agent` tool with `model: fable` |
| Cross-vendor backend | Host `Agent` tool with `subagent_type: codex:codex-rescue` |
| Context gathering | `git diff --stat`, `git log --oneline -5`, `pwd` |
| Tests/CI | None visible |

## Key Features

### Advisor Trigger Heuristics

The best part is the trigger list. It names situations where a cheap executor should stop pushing forward alone: repeated failed attempts, architectural uncertainty, debugging spirals, broad changes, and visible uncertainty. That is a useful behavioral pattern even if the exact model names change.

### Minimal Context Brief

Before dispatching, the skill asks the executor to collect a small context bundle: working directory, recent diff stat, recent commits, active work, files in play, failed attempts, and the question. That is the right shape for an advisor call because it keeps the expensive model from spending its first pass orienting itself.

### Model Routing Rule

The simple routing table is easy to understand:

| Executor | Advisor |
|----------|---------|
| Sonnet / Haiku | Fable |
| Opus / Fable | Codex |

The rule is less about those exact names than about consulting "up" or consulting a different model family when the executor may share blind spots with its usual lane.

### Advisory-Only Boundary

The skill says the advisor should not implement. That boundary is good. It keeps the consultation framed as decision support instead of another partially supervised coding worker.

## Architecture

The repo has only two tracked files:

```text
README.md
SKILL.md
```

The skill's architecture is procedural:

1. Parse optional `--fable` or `--codex` flags.
2. Detect the current model from the system prompt or model metadata.
3. Gather a context bundle using basic git commands.
4. Spawn a Fable or Codex advisor subagent.
5. Return the advisor response verbatim.

The weak point is enforcement. There is no wrapper, command implementation, validator, or runtime adapter. Everything depends on the host agent interpreting and obeying the instructions.

The "return guidance verbatim" rule is also questionable. It preserves the advisor's exact output, but it prevents the executor from doing the most important parent-agent job: reconciling advice with local evidence, spotting impossible instructions, and summarizing what will actually happen next.

## Comparison

| Aspect | poormansadvisor | Fable Advisor | Use Codex Skill | dzhng/skills |
|--------|-----------------|---------------|-----------------|--------------|
| Main value | Advisor consultation trigger and prompt | Broader model-lane orchestration | CLI subagent context offload | Durable software-workflow skills |
| Repo shape | One `SKILL.md` | Plugin metadata, agents, skill | Public skill document | Multi-skill catalog |
| Best idea | Consult when stuck or making structural decisions | Separate judgment and implementation lanes | Parent/subagent delegation | Living spec/slice graph |
| Main caveat | Not enough packaging or validation | Model/account assumptions | Unsafe execution hygiene | Light enforcement |

This is narrower and less complete than Fable Advisor, but the trigger list is a clean standalone pattern.

## Self-Hosting Notes

Installation is manual:

```bash
ln -s /path/to/poormansadvisor ~/.claude/skills/poormansadvisor
```

or copy `SKILL.md` into a skill folder. Before relying on it:

- Add a real LICENSE file if redistribution or adaptation matters.
- Verify whether your Claude Code setup actually supports the `/poormansadvisor` slash-command form.
- Replace `codex:codex-rescue` with a subagent type that exists in your environment.
- Treat auto-triggering as instruction-following, not a hard runtime guarantee.
- Do not relay advisor output blindly when it contradicts source evidence.

---

**Attribution:** leighstillard/poormansadvisor, README-stated MIT; no license file detected
