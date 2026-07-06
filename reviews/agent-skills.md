# Agent Skills (addyosmani/agent-skills)

**Repo:** https://github.com/addyosmani/agent-skills
**License:** MIT
**Reviewed:** 2026-07-05
**Commit:** `8c6530305396f341b5da7201cf1f7e390fdb863f`
**Release checked:** `0.6.3`
**Stack:** Markdown Agent Skills, Claude Code plugin metadata, Antigravity/Gemini/Cursor/OpenCode/Copilot setup docs, Node.js validators, Bash hooks
**What it is:** A large lifecycle-oriented engineering skill pack for AI coding agents, with 24 process skills, 8 slash commands, specialist review personas, reference checklists, and validation scripts.

---

## Verdict

✅ **Deploy candidate as a workflow layer for coding agents.** This is one of the stronger public skill packs because it treats skills as repeatable engineering processes, not just advice. The best parts are the lifecycle routing, anti-rationalization sections, verification gates, command parity checks, and specialist review personas.

The caveat is that this is still prompt/process infrastructure. It improves agent behavior when the host agent actually follows the procedures, but it is not a runtime sandbox, test harness, or empirical guarantee of better code.

---

## What It Is

`agent-skills` packages senior-engineering workflows as agent-readable skills. The core sequence is Define → Plan → Build → Verify → Review → Ship, exposed through slash commands such as `/spec`, `/plan`, `/build`, `/test`, `/review`, `/code-simplify`, `/webperf`, and `/ship`.

The repo includes 24 skills: 23 lifecycle skills plus a `using-agent-skills` meta-skill that maps incoming work to the right process. The skills cover requirement interviews, idea refinement, spec-driven development, planning, incremental implementation, TDD, source-driven development, context engineering, doubt-driven development, UI engineering, API design, browser testing, debugging, review, simplification, security, performance, git workflow, CI/CD, migrations, docs/ADRs, observability, and launch.

It is designed for multiple agent hosts: Claude Code plugin install, Cursor rules, Antigravity plugin metadata, Gemini CLI skills, Windsurf rules, OpenCode skill-tool routing, GitHub Copilot personas, and generic Markdown import.

## Stack

| Layer | Tech |
|-------|------|
| Skill format | Markdown `SKILL.md` files with YAML frontmatter |
| Commands | Claude Markdown commands, Gemini TOML commands, Antigravity TOML commands |
| Personas | Markdown subagent/persona prompts |
| Plugin metadata | Claude Code marketplace/plugin JSON, Antigravity `plugin.json` |
| Validation | Node.js scripts for skill schema and command parity |
| Hooks | Bash session-start hook, optional WebFetch cache and simplify-ignore hooks |
| Docs | Tool-specific setup guides and skill anatomy docs |

## Key Features

### Process-First Skill Anatomy

Most skills follow a recognizable shape:

- frontmatter with `name` and trigger-rich `description`;
- overview;
- when-to-use and when-not-to-use guidance;
- step-by-step workflow;
- common rationalizations;
- red flags;
- verification checklist.

That structure is useful because agents often fail by rationalizing skipped work. This repo makes the failure modes explicit inside each skill instead of assuming the agent will remember general engineering discipline.

### Lifecycle Commands

The eight slash commands map to common engineering phases:

- `/spec`
- `/plan`
- `/build`
- `/test`
- `/review`
- `/webperf`
- `/code-simplify`
- `/ship`

The commands are not just aliases. For example, `/build auto` requires a real spec, checks for unrelated local changes, asks for one approval, then executes task-by-task with tests, builds, and per-task commits. `/ship` fans out to specialist review personas, then merges the reports into a go/no-go decision and rollback plan.

### Specialist Personas

The repo ships four personas:

- `code-reviewer`
- `security-auditor`
- `test-engineer`
- `web-performance-auditor`

The important design choice is composition discipline: personas do not call other personas. Slash commands or the user orchestrate. `/ship` is the canonical parallel fan-out pattern, with independent review/security/test reports merged by the main agent.

### Validator-Owned Conformance

The repo includes validators for:

- skill frontmatter;
- skill naming;
- description trigger language;
- required sections;
- dead cross-skill references;
- command parity across Claude, Gemini, and Antigravity command directories;
- description sync across command variants.

This is stronger than most skill libraries. It means the catalog has a maintained shape instead of slowly drifting into a pile of Markdown.

### Useful Hooks

The session-start hook injects the meta-skill at the beginning of Claude Code sessions. Optional hooks add:

- `sdd-cache`: a WebFetch cache that revalidates with `ETag` / `Last-Modified` before serving cached content;
- `simplify-ignore`: block-level placeholders for code that should not be simplified.

The cache hook has a good freshness model. The simplify-ignore hook is clever but more dangerous because it mutates files in-place during a session and relies on stop/crash recovery.

## Architecture

The repo is deliberately small: 95 tracked non-git files, about 1.1 MB, mostly Markdown. The architecture is content plus conformance:

```text
skills/                 workflow skills
agents/                 review/test/security/performance personas
commands/               Antigravity command variants
.claude/commands/        Claude command variants
.gemini/commands/        Gemini command variants
references/             reusable checklists
hooks/                  optional Bash hooks
scripts/                validation scripts
docs/                   setup, comparison, and anatomy docs
```

The best part is that the docs define the skill format and the scripts enforce enough of it to matter. The validator keeps exemptions in code rather than allowing skills to self-declare exemption from checks, which avoids a common governance hole.

## Comparison

Compared with other public skill packs:

| Aspect | agent-skills | dzhng/skills | codebase-to-course |
|--------|--------------|--------------|--------------------|
| Primary focus | Full software lifecycle discipline | Software-factory workflows and visual/review loops | One specialized codebase course generator |
| Format | 24 process skills, commands, personas, hooks | Claude plugin skills and helper scripts | One Claude Code skill with static assets |
| Validation | Skill and command parity validators, plugin install CI | Less visible repo-level validation | No visible tests/CI |
| Best use | Installed workflow layer | Selective workflow/pattern harvesting | Study/use for course generation only |

The repo's own comparison docs are also unusually fair: they position this pack against Superpowers and Matt Pocock's skills without pretending there is one universal winner.

## Self-Hosting / Installation Notes

Best install path depends on host:

- Claude Code: marketplace/plugin install.
- Cursor/Windsurf/Copilot: copy or reference skills/personas into the host's rules/instructions system.
- Gemini CLI: install the `skills/` directory.
- Antigravity: use the included plugin manifest.
- Generic agents: import the Markdown skills directly.

Do not install multiple broad skill routers at the same time without pruning. Stacked meta-skills and overlapping command names can fight each other.

## Caveats

- This is processware. It relies on the host agent following instructions.
- The repo validates structure and installability, not whether the skills improve outcomes across a benchmark suite.
- The package/release metadata is a little uneven: the Git tag/release is `0.6.3`, while the minimal root `plugin.json` says `1.0.0`.
- The optional simplify-ignore hook mutates files in-place and needs careful `.gitignore` plus crash recovery awareness.
- Some guidance is intentionally opinionated and may be too ceremony-heavy for tiny fixes.
- The repository is very popular, which means rapid PR churn and duplicate skill proposals are likely; the contribution docs already acknowledge this.

## Verification Performed

Local checks passed:

- `node scripts/validate-skills.js`
- `node scripts/validate-commands.js`
- `bash hooks/session-start-test.sh`
- `bash hooks/simplify-ignore-test.sh`

Observed results:

- 24 skills checked, 0 errors, 0 warnings.
- 8 commands checked, 0 errors.
- Hook tests passed, including 21 simplify-ignore assertions.

## Extracted Pattern

- [Anti-Rationalization Skill Anatomy](../patterns/anti-rationalization-skill-anatomy.md)

This captures the repo's strongest reusable design move: skills should include not only steps, but also the specific excuses agents use to skip those steps, the red flags that indicate drift, and evidence-based verification requirements.

---

**Attribution:** addyosmani/agent-skills, MIT
