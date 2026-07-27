# Foundry (simoncorry/foundry)

**Repo:** https://github.com/simoncorry/foundry
**License:** MIT; reusable with attribution
**Reviewed:** 2026-07-26
**Stack:** Markdown command files, Node.js scripts, Codex/Claude Code/Cursor command packaging
**What it is:** A plain-file agent workflow that brings a designer-style process to coding agents: plan, frame, critique, build, test, critique again, wrap up, hand off.

---

## Verdict

✅ **Deploy candidate for durable agent-assisted software work.** Foundry is not a runtime or orchestration server; it is a disciplined command pack and project skeleton. That narrowness is a strength: the repo is easy to inspect, MIT licensed, dependency-free, and backed by checks that keep the generated Claude/Codex/Cursor shapes synchronized.

---

## What It Is

Foundry packages a software-building process as markdown commands for agent coding tools. The chain is deliberately named and staged: start up, construct the plan, frame it, five plan-challenge rounds, build, test, optional security scan, five implementation-challenge rounds, wrap up, hand off, and quiz.

The core bet is that work meant to last needs artifacts outside chat scrollback. Plans live in `docs/plans/`, session notes in `docs/sessions/`, durable project knowledge in `docs/wiki/`, and generated command surfaces are checked from one source of truth. This makes the process portable across tools instead of binding it to one agent harness.

It is opinionated and token-heavy. The README is honest about that cost and documents a light path that keeps the same shape with fewer challenge rounds.

## Stack

| Layer | Tech |
|-------|------|
| Workflow surface | Markdown slash-command files |
| Supported harnesses | Cursor, Claude Code, Codex skills |
| Scripts | Node.js ESM, zero package dependencies |
| State/artifacts | Repo-local plans, sessions log, wiki |
| CI | GitHub Actions running `npm run check` |
| Tests | Node built-in test runner |

## Key Features

### File-backed agent process

Foundry makes the plan and memory concrete files rather than relying on a long chat transcript. `construct-the-plan` writes a proposed plan file, challenge rounds edit that file when they demote assumptions, `wrap-up` records session knowledge, and `handoff` leaves the next-session bridge.

### Structured critique rounds

The challenge rounds require distinct review angles and structured count lines. This is the strongest part of the repo: it turns "review it again" into a protocol that tries to prevent repeated shallow passes.

### Multi-harness command generation

`.cursor/commands/` is the source of truth. `scripts/generate-command-shapes.js` emits byte-identical Claude command copies and frontmattered Codex skills with manual-only invocation policy. `npm run check` fails on drift or orphan generated files.

### Local quality gates

The repo ships no external dependencies. Its checks cover tests, generated-shape sync, dead markdown/backtick/prose references, wiki index completeness, and a voice/jargon gate. Local verification passed `npm run check` with 79 tests.

## Architecture

Foundry is intentionally small:

- `AGENTS.md` defines the standing working agreement.
- `.cursor/commands/` holds the editable command source.
- `.claude/commands/` and `.agents/skills/` are generated surfaces.
- `docs/wiki/` carries reference knowledge that the process tells agents when to load.
- `scripts/` enforces shape sync, link health, voice rules, session rotation, and wiki pointers.

The most reusable design decision is treating process prompts as source files with generated adapters, then verifying those adapters in CI. That is cleaner than hand-maintaining near-identical command packs for each tool.

## Comparison

| Aspect | Foundry | Superpowers | Compound Engineering Plugin |
|--------|---------|-------------|-----------------------------|
| Primary unit | Sequential process commands | Skill methodology and task discipline | Cross-harness workflow plugin |
| Runtime dependency | None beyond an agent and Node for checks | Agent skill support | Bun/TypeScript tooling |
| State model | Repo-local plans, logs, wiki | File-backed development artifacts | Workflow artifacts and converter outputs |
| Best fit | Long-lived product work needing human checkpoints | General coding-agent discipline | Broader engineering workflow automation |

Foundry is less ambitious than full orchestration systems, but more legible. It is closest to a design-process scaffold for agents, not a platform.

## Self-Hosting Notes

There is nothing to host. Use it by cloning the repo for a new project, copying the documented command/rules/scripts set into an existing project, or running:

```bash
node scripts/install.js <target-project> [--wiki] [--dry-run]
```

The installer intentionally overwrites prior Foundry copies on rerun, so treat installed command files as consumed artifacts unless you plan to manage local divergence.

---

**Attribution:** simoncorry/foundry, MIT
