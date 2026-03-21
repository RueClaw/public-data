# GitHub Spec Kit — Repo Review

**Repo:** https://github.com/github/spec-kit  
**License:** MIT  
**Author:** GitHub, Inc.  
**Language:** Python (CLI), Markdown (templates/commands)  
**Cloned:** ~/src/spec-kit  
**Rating:** 🔥🔥🔥🔥

---

## What It Is

A toolkit for **Spec-Driven Development (SDD)** — a methodology where specifications are the primary artifact and code is their generated output. You write a spec, the spec generates an implementation plan, the plan generates code. The spec remains the source of truth; code is downstream.

Practically: a Python CLI (`specify`) that bootstraps projects with a `.specify/` directory structure, templates, and agent command files (slash commands, workflows) for 23+ supported coding agents.

---

## The SDD Philosophy

The core idea is a **power inversion**: specs used to serve code (written, then discarded). SDD makes code serve specs. When requirements change, you update the spec, not the code directly — then regenerate.

The workflow:
1. **`/speckit.constitution`** — establish project principles and development guidelines
2. **`/speckit.specify`** — describe what to build (what/why, not how)
3. **`/speckit.clarify`** — AI asks clarifying questions, fills gaps, defines acceptance criteria
4. **`/speckit.plan`** — generates a technical implementation plan from the spec
5. **`/speckit.tasks`** — breaks plan into discrete tasks
6. **`/speckit.implement`** — implements from the plan
7. **`/speckit.checklist`** — verification against spec requirements
8. **`/speckit.analyze`** — analysis and gap detection

The spec lives at `.specify/memory/`. Constitution, PRD, plan, and tasks are all versioned markdown files. Code is the last step.

---

## What Gets Generated

`specify init <PROJECT>` bootstraps:
- `.specify/` — memory (constitution.md, spec.md, plan.md, tasks.md), templates, extensions config
- Agent command files for whichever agents you specify (`--ai claude`, `--ai codex`, etc.)

The CLI writes the appropriate slash command files to each agent's directory. For Claude Code: `.claude/commands/speckit.*.md`. For Codex: `.agents/skills/speckit-*.md`. For Gemini: `.gemini/commands/*.toml`. And so on.

---

## Supported Agents (23+)

Probably the most complete agent compatibility matrix I've seen in a single tool:

Claude Code, Gemini CLI, Copilot, Cursor, Qwen Code, opencode, Codex CLI, Windsurf, Junie, Kilo Code, Auggie, Roo Code, CodeBuddy, Qoder, Kiro, Amp, SHAI, Tabnine, Kimi Code, **Pi (OpenClaw)**, iFlow, IBM Bob, Trae, plus generic via `--ai-commands-dir`.

Pi is explicitly in the agent registry at `.pi/prompts/`. For Pi, command files are markdown prompts in that directory.

---

## Extension System

`.specify/extensions.yml` defines hooks that run before/after each command. Before-specify hooks can be mandatory (auto-execute) or optional (prompt user). Hooks chain into each other — a research hook before specification is a documented use case.

There's an extension catalog (`extensions/catalog.json`) and community catalog (`extensions/catalog.community.json`) with publishable extensions. The extension API is documented in `EXTENSION-API-REFERENCE.md`.

---

## What's Worth Stealing

### The Constitution Pattern
A "project constitution" as the foundational document — principles, guidelines, development standards — that all subsequent specs reference. Versioned (semver), with ratification date and amendment history. This is the right way to give an agent persistent project context that doesn't drift.

Not just "here's a CLAUDE.md" — a formal governance document with principles that specs must comply with. The constitution is input to every subsequent command.

### Evidence vs Assumption in Spec Format
The spec template separates "known constraints" from "assumptions to validate." Same discipline as the sterling slash commands' evidence table, but at the spec level.

### The Handoff Chain
Each command's YAML frontmatter includes `handoffs` — suggested next steps with pre-populated prompts. After `/speckit.specify`, the suggested handoffs are `speckit.plan` and `speckit.clarify`. The agent UI can render these as buttons. Clean composition.

### Pre/Post Hook Architecture
The extension hook system is straightforward YAML — enabled/disabled, optional/mandatory, condition expressions (deferred to a HookExecutor). Easy to model for our own skill system.

### Agent-Agnostic Command Templates
One source template (`templates/commands/specify.md`) gets rendered into agent-specific formats by the CLI. The template uses `$ARGUMENTS` as a universal placeholder; the CLI translates to each agent's convention. Clean separation between template logic and agent-specific syntax.

---

## What's Not Interesting

- The Python CLI itself is thin scaffolding — the templates are the real content
- The spec-driven philosophy is well-articulated but not new (it's basically "design before you code" with LLM wrapping)
- The extension marketplace is early/thin
- Heavy Cursor/VS Code orientation in the docs

---

## License

MIT, GitHub Inc. — fully extractable, reusable, attributable.

---

## Verdict

Strong methodology, well-executed scaffolding, excellent agent coverage. The constitution pattern (versioned project principles as a governance doc) and the handoff chain in command frontmatter are worth borrowing directly. The pre/post hook YAML is clean and modelable for our skill system.

The SDD workflow (constitution → spec → plan → tasks → implement → verify) is essentially what ralphinit/ralphonce does at the project level, with better formalization. The two complement each other.

**Worth adapting:** the constitution template for long-running projects (ODR, Parkinson's agent), and the handoff chain pattern for our OpenClaw skills.

---

*Source: https://github.com/github/spec-kit | License: MIT | Author: GitHub, Inc. | Reviewed: 2026-03-21*
