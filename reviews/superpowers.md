# Superpowers (obra/superpowers)

**Repo:** https://github.com/obra/superpowers
**License:** MIT; reusable with attribution
**Reviewed:** 2026-07-11
**Stack:** Markdown Agent Skills, shell hooks, JavaScript/Node test helpers, multi-harness plugin manifests
**What it is:** A portable software-development methodology packaged as agent skills for coding assistants, covering brainstorming, planning, TDD, debugging, subagent execution, review, and branch finishing.

---

## Update Notes

Checked against the earlier 2026-03-21 review. Current release is `v6.1.1` at `d884ae0`.

Material changes:
- v6 rewrote subagent-driven development around file-backed task briefs, review packages, a progress ledger, explicit model selection, one per-task reviewer that returns both spec and quality verdicts, and a final whole-branch review.
- Codex support moved from a SessionStart hook to native skill discovery, with `hooks: {}` intentionally suppressing Codex's root hook auto-discovery fallback.
- New harness support includes Kimi Code, Pi, Antigravity, Factory Droid, GitHub Copilot CLI, and official Codex marketplace packaging; Gemini CLI support was removed after EOL.
- The project added stronger contribution gates for AI-authored PRs, including disclosure, duplicate search, core-fit checks, and session-transcript requirements for new harnesses.
- The eval/testing story is cleaner: behavior evals live in a separate `superpowers-evals` harness, while in-tree tests focus on plugin infrastructure.

---

## Verdict

✅ **Deploy candidate for agentic software-development workflows.** Superpowers is still one of the strongest public skill libraries for coding agents, and the v6 changes make it more serious: lower token cost, stricter subagent review, better file handoffs, and real multi-harness packaging. The main caveat is that it is a behavior layer, not a deterministic runtime guardrail; it improves agent discipline but does not enforce policy at the tool boundary.

---

## What It Is

Superpowers is a set of Agent Skills plus startup/bootstrap machinery that makes coding agents follow a disciplined development loop instead of jumping straight to edits. The normal path is brainstorming, design approval, implementation planning, worktree setup, subagent-driven implementation, TDD, code review, and branch finishing.

The project has grown from a Claude Code-centered plugin into a portable skill library for Claude Code, Codex, Cursor, Kimi Code, OpenCode, Pi, Antigravity, Factory Droid, and GitHub Copilot CLI. The repository ships per-harness manifests and docs rather than treating skills as plain Markdown copied by hand.

The strongest idea is still simple: skill text should be operational process, not vibes. The skills name the rationalizations agents use to skip work, force evidence before completion, require explicit verification, and give subagents small, reviewable task contracts.

## Stack

| Layer | Tech |
|-------|------|
| Skill content | Markdown `SKILL.md` files with references and prompt templates |
| Harness packaging | `.claude-plugin`, `.codex-plugin`, `.cursor-plugin`, `.kimi-plugin`, `.opencode`, `.pi`, Antigravity docs |
| Hooks/bootstrap | Shell SessionStart hooks where the harness needs them; native skills where it does not |
| Test helpers | Shell, Node test files, package archive tests, manifest tests |
| Distribution | GitHub repo, official/plugin marketplace manifests, deterministic Codex portal archive script |

## Key Features

### Subagent-Driven Development

The v6 SDD rewrite is the most important change. Instead of two reviewers per task and pasted diffs, Superpowers now writes task briefs, implementer reports, and review packages to files under `.superpowers/sdd/`. A single task reviewer returns both spec-compliance and quality verdicts, and the run finishes with a whole-branch review.

This is a practical correction to the expensive version of subagent orchestration. It keeps the isolation benefits of fresh task agents while reducing context bloat and giving the controller a progress ledger it can resume from.

### Stronger Reviewer Contract

The reviewer prompt explicitly resists controller coaching: the controller cannot tell a reviewer what to ignore, pre-rate severity, or dismiss plan-mandated defects. Reviewers are read-only, skeptical of implementer rationales, and expected to ground findings in evidence.

That matters because many coding-agent review loops fail by letting the same session that wants progress also shape the review. Superpowers is trying to keep the reviewer independent even inside a prompt-mediated workflow.

### Lower Bootstrap Cost

v6.1 trimmed the always-injected `using-superpowers` bootstrap and removed redundant per-harness tool-mapping tables. That is the right maintenance direction for skill systems: startup context should carry only behavior-shaping content that materially changes the run.

### Codex Packaging

Codex support is now marketplace-oriented and intentionally hookless. The Codex manifest uses `hooks: {}` because absent or empty-list hook fields fall back to root hook auto-discovery; the exact empty object is a sentinel meaning "no hooks." That is a useful packaging lesson for any Codex plugin.

### Contributor Hygiene for Agent PRs

The repo's `CLAUDE.md` and PR template are unusually direct about AI-authored contribution failures. They require model/harness/plugin disclosure, duplicate PR search, real problem evidence, human review of the diff, dev-branch targeting, and transcripts for new harness support. This is not just etiquette; it is a defensive boundary around a repo likely to attract low-quality agent PRs.

## Architecture

Superpowers is mostly content architecture. Each skill lives in `skills/<name>/SKILL.md`, with references or prompt templates next to it when needed. The important design choice is that the skill library is host-neutral in its core language and relies on small per-harness adapters for dispatch, hooks, packaging, and tool mapping.

The project has also separated two kinds of verification. In-tree tests validate plugin infrastructure, manifests, packaging, and hook behavior. Skill-behavior evals moved to a dedicated `superpowers-evals` repo that drives real agent sessions and judges compliance. That split is correct: shell tests can prove a package installs, but only live-agent evals can tell whether instruction text actually changes behavior.

## Comparison

| Aspect | Superpowers | addyosmani/agent-skills | dzhng/skills | shadcn/improve |
|--------|-------------|-------------------------|--------------|----------------|
| Focus | Full development methodology | Broad production-engineering skill pack | Portable software-factory skills | Read-only audit-to-plan workflow |
| Execution | Brainstorm, plan, TDD, SDD, review, finish | Lifecycle and specialist skill coverage | Living specs, implementation passes, visual review | Findings become implementation plans |
| Strength | Opinionated end-to-end workflow with strong anti-rationalization gates | Breadth and polish | Spec slicing and visual validation | Safer separation between reviewer and executor |
| Caveat | Prompt-enforced, not tool-enforced | Needs pruning before stacking with other routers | Less packaged/eval visible | Narrower scope |

## Self-Hosting Notes

This is not a server to self-host. Installation is per harness:

- Codex App/CLI: install through the official Codex plugin marketplace.
- Claude Code: install from Anthropic's official marketplace or the Superpowers marketplace.
- Cursor, Kimi, OpenCode, Pi, Antigravity, Factory Droid, and Copilot CLI each have their own install path in the README.

For contributors, target `dev`, read the PR template, and expect skill changes to require real eval evidence.

## Verification Notes

Local checks run on 2026-07-11:
- `tests/codex/test-marketplace-manifest.sh` passed.
- `tests/codex/test-package-codex-plugin.sh` mostly passed but failed one tar.gz executable-mode assertion: expected `-rwxr-xr-x`, actual `-rwx------`. This may be local archive/umask behavior, but it is still a failing check.
- `tests/shell-lint/test-lint-shell.sh` did not run because the chained command stopped at the package test failure.

---

**Attribution:** obra/superpowers, MIT
