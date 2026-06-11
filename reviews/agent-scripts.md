# Agent Scripts (steipete/agent-scripts)

**Repo:** https://github.com/steipete/agent-scripts
**License:** MIT, permissive reuse with attribution
**Reviewed:** 2026-06-11
**Stack:** Markdown Agent Skills, shared AGENTS.MD rules, Bash, TypeScript, Python helper scripts, GitHub Actions
**What it is:** A canonical shared toolkit for coding-agent workspaces: reusable skills, global agent instructions, slash-command docs, and small portable scripts that can be symlinked into Codex, Claude Code, and downstream repositories.

---

## Verdict

📚 **Study and selectively harvest, not a drop-in product.** This is a strong example of treating agent operations as a versioned codebase: skills are routable units, shared rules are kept canonical, and validation scripts catch broken skill metadata. It is personal and environment-shaped, so the value is in the repo pattern and selected procedures rather than installing it wholesale.

---

## What It Is

`agent-scripts` is an operations repo for AI coding agents. It centralizes shared instructions in `AGENTS.MD`, reusable workflows in `skills/`, small helper CLIs in `scripts/`, and docs for slash commands, subagents, releases, macOS app release work, and concurrency guidance.

The README explicitly positions it as the canonical source for shared agent rules and portable helpers. Downstream projects are expected to point to the canonical `AGENTS.MD` instead of copying the whole instruction block, while global skill directories can symlink to `skills/`.

The repo is not a service, framework, or packaged CLI. It is closer to a maintained operator runbook plus toolbelt for people who use coding agents heavily across many repositories.

## Stack

| Layer | Tech |
|-------|------|
| Agent instructions | `AGENTS.MD`, Markdown docs |
| Skills | `skills/<name>/SKILL.md` with YAML front matter |
| Validation | Ruby `scripts/validate-skills`, TypeScript `scripts/docs-list.ts` |
| Helper scripts | Bash, TypeScript, Python `uv` scripts |
| Browser automation helper | TypeScript + Puppeteer/CDP helper |
| CI | GitHub Actions smoke workflow |
| Distribution model | Git repo plus symlinks into agent tool directories |

## Key Features

### Canonical Shared Agent Instructions

The repo keeps shared hard rules in one `AGENTS.MD` and recommends pointer-style downstream files. That avoids drift across many workspaces while still leaving room for repo-local rules below the pointer.

### Routeable Skill Catalog

The `skills/` directory contains 49 skill files at review time, covering areas such as maintainer orchestration, GitHub review, browser automation, release work, Obsidian, 1Password, image generation, and platform-specific development. Each skill has front matter with `name` and `description`, making the directory usable by agents that perform skill discovery.

### Validation Over Convention

`scripts/validate-skills` parses every `skills/*/SKILL.md` front matter block, requires non-empty `name` and `description`, and catches duplicate skill names. `scripts/docs-list.ts` walks docs, extracts front matter summaries and `read_when` hints, and prints a compact onboarding index.

### Small Portable Utilities

The helper scripts are deliberately light: a selective commit wrapper, a trash helper, a browser DevTools CLI, image/audio helpers, and release support scripts. The best ones are narrow, dependency-light, and built around agent failure modes such as accidental broad staging or stale docs discovery.

## Architecture

The main design pattern is a canonical agent-ops repo:

- one source of truth for shared agent behavior;
- skill files as reusable, routeable workflow modules;
- docs with metadata so agents know when to read them;
- validation scripts to keep the routeable metadata healthy;
- downstream repos that point to the canonical source instead of copying it.

That is the interesting architecture. The individual scripts vary in polish and portability, but the repository boundary is clean: instructions, skills, docs, and helpers live together because they change together.

## Comparison

| Aspect | Agent Scripts | qship | tech-snacks | agentic-stack |
|--------|---------------|-------|-------------|---------------|
| Main focus | Shared operator rules, skills, and helpers | Ticket-to-PR delivery pipeline | Claude Code skill/workflow library | Portable `.agent` brain across tools |
| Enforcement | Metadata validation and repo convention | Hook gates and pipeline state | Workflow scripts and templates | Manifest/adapters/data layer |
| Best use | Study and harvest patterns | Sandboxed delivery automation | Borrow focused skill procedures | Study portability layer |
| Main caveat | Personal/local assumptions | Broad unattended autonomy | Variable template quality | Adapter complexity |

## Self-Hosting Notes

Do not install this wholesale unless your environment matches the author's assumptions. A safer adoption path is:

1. Create your own canonical `agent-ops` repo.
2. Keep shared agent rules in one file and use pointer-style downstream instructions.
3. Store reusable skills under `skills/<name>/SKILL.md`.
4. Add a validator for skill front matter and duplicate names.
5. Keep scripts small, inspectable, and tied to real agent failure modes.

---

**Attribution:** steipete/agent-scripts, MIT License.
