# devils-advocate (brandonsimpson/devils-advocate)

**Repo:** https://github.com/brandonsimpson/devils-advocate
**License:** MIT - permissive reuse with attribution
**Reviewed:** 2026-05-24
**Stack:** Claude Code plugin, Markdown skills, Node.js inline hooks, shell validation scripts
**What it is:** A Claude Code plugin that adds adversarial binary pass/fail critique for code and plans, with evidence requirements, context gating, standards discovery, session logs, and commit/plan-file nudges.

---

## Verdict

✅ **Deploy candidate for Claude Code users who want stricter review discipline.** This is a small prompt-only plugin, but it is unusually well specified: 20 binary code criteria, 22 binary plan criteria, mandatory file:line evidence, fix suggestions for every failure, a context-insufficient refusal path, and a self-review independence gate. The main risk is friction and false authority: it can produce useful pressure, but it is still an LLM critique workflow, not a substitute for tests, security review, or human judgment.

---

## What It Is

devils-advocate is a Claude Code plugin that turns critique into a slash-command workflow. The core command, /devils-advocate:critique, auto-detects whether it is reviewing code or a plan and applies the relevant binary criteria set. Instead of percentage scores or broad commentary, every criterion must pass or fail.

The plugin's opinion is clear: a critique without evidence is worse than no critique. Every failure must include a concrete file:line reference and a Fix: suggestion. If there is not enough context to critique, the skill is instructed to stop and emit a CONTEXT INSUFFICIENT block rather than inventing confidence.

It also includes lightweight hooks. A pre-commit hook warns when committing without a critique marker, and a post-write hook suggests critique when a plan file is written. Both are non-blocking and configurable through a project-local .devils-advocate/config.json.

## Stack

| Layer | Tech |
|-------|------|
| Plugin platform | Claude Code plugin structure |
| Skills | Markdown SKILL.md files |
| Hooks | Inline node -e commands in hooks.json |
| Validation | Bash scripts plus Node JSON/hook checks |
| State | Project-local .devils-advocate/session.md and log files |
| Marketplace | Root .claude-plugin/marketplace.json pointing at ./plugin |

## Key Features

### Binary Critique Criteria

The code critique mode defines 20 criteria across correctness, security, quality, performance, consistency, integration, and architecture. The plan critique mode defines 22 criteria across completeness, correctness, testability, security, consistency, simplicity, dependencies, resilience, integration, and architecture.

The important design choice is binary scoring. There is no "87% confident" escape hatch; every item is either satisfied or has a concrete failing reason.

### Evidence and Fix Requirements

Every failure must cite file:line evidence and include a fix suggestion. This keeps the critique from becoming a vague second opinion and makes the output actionable.

### Context Gate

The skill explicitly refuses to produce a critique if it has not read the relevant files, does not understand the task, has not explored the project structure, or has nothing concrete to critique. That is a valuable guard against false-confidence review theater.

### Independence Gate

When critiquing work produced in the same conversation, the skill instructs Claude to dispatch an independent subagent so the reviewer sees the artifact and codebase rather than the authoring chain of thought. If the agent tool is unavailable, it falls back with a self-critique warning.

### Standards Discovery

Before critique, the skill searches for CLAUDE.md, AGENTS.md, ADR files, existing helper patterns, architectural boundaries, and dominant conventions. Standards violations then cause relevant criteria to fail.

### Session Logging and Hooks

Critiques append a session entry with git SHA, timestamp, check number, and pass count, and full critique output is saved under .devils-advocate/logs/. Hooks nudge users to critique before committing or after writing plan files without blocking work.

## Architecture

The repo has a clean two-layer structure:

- The root contains the marketplace entry, README, LICENSE, banner, and top-level guidance.
- plugin/ contains the actual plugin metadata, skills, hooks, and scripts.

This avoids the circular cache problem noted in the repo docs when a marketplace and plugin share a directory. The root marketplace entry points to ./plugin, while plugin/.claude-plugin/plugin.json is the version source of truth.

The implementation is intentionally low-tech. There are no runtime dependencies beyond Claude Code and Node for hooks. Validation scripts inspect metadata, skill text, hook behavior, version sync, criteria completeness, output format, and project documentation consistency.

## Comparison

| Aspect | devils-advocate | Generic checklist prompt | Automated tests |
|--------|-----------------|--------------------------|-----------------|
| Evidence requirement | Mandatory file:line for failures | Usually optional | Concrete execution results |
| Scope | Code and plans | Varies | Code behavior |
| Independence | Has self-review subagent gate | Usually absent | Not applicable |
| Project awareness | Reads standards and patterns | Often shallow | Depends on test design |
| Failure output | Fix suggestion required | Often vague | Failing assertion/log |
| Best use | Review discipline and risk surfacing | Lightweight reminder | Behavioral verification |

The plugin is strongest as a review ritual around plans and code changes. It should complement tests and linters, not replace them.

## Self-Hosting Notes

Install through the Claude Code plugin marketplace:

```bash
/plugin marketplace add brandonsimpson/devils-advocate
/plugin install devils-advocate@devils-advocate
```

Manual installation is also simple: clone the repo and load it through Claude Code's plugin directory support. The plugin writes logs under .devils-advocate/, so projects should add that directory to .gitignore unless they intentionally want critique logs committed.

Hooks are enabled by default and can be disabled per project:

```json
{"hooks": {"pre-commit-warning": false, "plan-file-detect": false}}
```

Verification performed:

- bash plugin/scripts/check-consistency.sh: 34 passed.
- bash plugin/scripts/test-plugin.sh: 112 passed.
- JSON and shell syntax checks passed.
- Lightweight secret scan found no obvious live secrets.

---

**Attribution:** brandonsimpson/devils-advocate, MIT

