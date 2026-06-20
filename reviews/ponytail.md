# Ponytail (DietrichGebert/ponytail)

**Repo:** https://github.com/DietrichGebert/ponytail  
**License:** MIT. Reusable with attribution.  
**Reviewed:** 2026-06-20  
**Stack:** JavaScript, Node.js lifecycle hooks, Agent Skills, MCP, Claude/Codex/OpenCode/Gemini/Copilot/Pi/OpenClaw adapters  
**What it is:** Ponytail is a portable "lazy senior developer" instruction pack for coding agents. It tries to make agents stop before overbuilding: skip unnecessary work, use the standard library, use native platform features, and only write custom code when the simpler rungs fail.

---

## Verdict

✅ **Deploy candidate for agent-instruction stacks.** Ponytail is small, opinionated, and unusually disciplined about portability: one canonical skill body fans out into multiple host adapters, generated OpenClaw skills, plugin manifests, lifecycle hooks, and tests that catch drift. The main caveat is that its own local test run needs `pandas` installed for the benchmark correctness test; upstream CI accounts for that.

---

## What It Is

Ponytail packages a coding-agent style guide as reusable agent infrastructure. The core rule is a ladder: ask whether the task should exist, prefer the standard library, prefer native platform features, use already-installed dependencies, then write the smallest custom implementation that still preserves validation, security, accessibility, and explicit user requirements.

The repo is not just a prompt file. It ships adapter surfaces for Claude Code, Codex, GitHub Copilot CLI, Gemini/Antigravity, OpenCode, Pi, CodeWhale, Cursor, Windsurf, Cline, Kiro, VS Code Codex, OpenClaw, and an MCP server. The adapters are thin wrappers around the same rule source, with lifecycle hooks that persist the active mode and inject the right ruleset.

The benchmark work is better than the usual "count lines in a chat answer" demo. The current agentic benchmark runs real headless Claude Code sessions against a pinned FastAPI/React repo, scores the resulting git diff, and adds deterministic adversarial checks for safety-sensitive tasks. The evidence still has limits, but the measurement is honest about those limits.

## Stack

| Layer | Tech |
|-------|------|
| Core rules | Markdown Agent Skills and `AGENTS.md` |
| Runtime hooks | Node.js CommonJS lifecycle scripts |
| MCP | `@modelcontextprotocol/sdk`, Zod, stdio server |
| Host adapters | Claude/Codex manifests, OpenCode plugin, Gemini extension, Copilot CLI commands, Pi extension, OpenClaw generated skills |
| Tests | Node test runner, Python helper checks, pandas for CSV correctness benchmark |
| Benchmarks | Promptfoo configs, Python agentic harness, Claude Code JSON telemetry |

## Key Features

### Canonical Rule Source With Adapter Fan-Out

The important engineering choice is that Ponytail keeps the rules in one place and makes adapters consume or generate from that source. `hooks/ponytail-instructions.js` reads the canonical skill, filters mode-specific sections, and feeds the lifecycle hooks and MCP server. `scripts/build-openclaw-skills.js` and tests keep generated skill copies aligned.

That matters because prompt packs rot quickly when every host gets its own hand-edited copy. Ponytail treats instruction text like a build artifact.

### Persistent, Mode-Aware Hooks

The Claude/Codex/Copilot hooks persist the current mode in a small state file and inject hidden session context on start. The mode tracker recognizes `/ponytail`, `@ponytail`, `$ponytail`, host-specific command names, and exact deactivation phrases without disabling itself just because a normal task mentions "normal mode."

The implementation is deliberately boring: small Node scripts, explicit platform branches, no long-running daemon.

### Defensive Minimalism, Not Code Golf

The skill is explicit about what must not be simplified away: trust-boundary validation, data-loss error handling, security, accessibility, hardware calibration, and anything the user explicitly requested. It also requires a tiny runnable check for non-trivial logic. That boundary is what separates "less code" from "careless code."

### Benchmark Harness With Critique Response

The benchmark docs directly address a prior critique of the project's single-shot numbers. The newer agentic run uses real agent sessions, isolates plugins per arm, measures diffs rather than prose, and checks adversarial cases such as path traversal, SQL injection, forged tokens, malformed CSV rows, and client-specific rate limiting.

## Architecture

Ponytail's architecture is a compact portability layer around one rule corpus:

- `skills/` holds the canonical command and skill definitions.
- `AGENTS.md` and host-specific rule files make instruction-only adapters work.
- `hooks/` implements session activation, mode persistence, statusline support, and instruction assembly.
- `.codex-plugin/`, `.claude-plugin/`, `.github/plugin/`, `gemini-extension.json`, `.opencode/`, and `pi-extension/` expose the same behavior to different hosts.
- `ponytail-mcp/` serves the ruleset as MCP prompt/tool for hosts that prefer MCP context retrieval.
- `tests/` checks adapter wiring, copied rule drift, generated OpenClaw skills, Windows hook syntax, and benchmark correctness helpers.

The cleanest pattern is "source instruction once, generate or verify every downstream host copy." That is more durable than maintaining a pile of nearly identical prompt files.

## Comparison

| Aspect | Ponytail | agent-scripts | agent-skills-tmchow | tech-snacks |
|--------|----------|---------------|---------------------|-------------|
| Primary value | Minimal-code behavior layer | Shared agent operations repo | Cross-runtime skill catalog | Claude skill/workflow library |
| Runtime scope | Many host adapters plus MCP | Repo of instructions/scripts | Skill packages and metadata | Claude Code plugins/skills |
| Best pattern | Canonical prompt source with adapter tests | Canonical ops repo | Scanner-safe skill packaging | Workflow-backed skills |
| Deployability | High for personal/team agent config | High as reference | High for selected skills | Useful, more Claude-specific |

Ponytail is narrower than a general skill library. That is a strength: it has one behavior to enforce and enough adapter/test discipline to make that behavior portable.

## Self-Hosting Notes

For most users, install through the target host's plugin or skill mechanism. The repo also supports copying rule files into instruction-only hosts. Node must be available for lifecycle-hook activation in Claude/Codex/Copilot paths; without Node, the static skills still work but always-on activation may not.

For verification, upstream CI installs `pandas` before `npm test`. A local run without pandas fails one CSV benchmark correctness test even though the JavaScript and adapter tests pass.

---

**Attribution:** DietrichGebert/ponytail, MIT License
