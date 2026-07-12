# Ponytail (DietrichGebert/ponytail)

**Repo:** https://github.com/DietrichGebert/ponytail  
**License:** MIT. Reusable with attribution.  
**Reviewed:** 2026-07-11  
**Stack:** JavaScript/Node lifecycle hooks, Agent Skills, MCP, npm package, Claude/Codex/OpenCode/Gemini/Copilot/Pi/Hermes/Qoder/Devin/OpenClaw adapters  
**What it is:** Ponytail is a portable "lazy senior developer" instruction pack for coding agents. It pushes agents to understand the task, reuse what already exists, prefer standard/native features, and only write custom code when the simpler rungs fail.

---

## Update Notes

**Checked:** 2026-07-11  
**Prior reviewed ref:** `6da37bf`  
**Current ref:** `14a0d79`  
**Latest release:** `v4.8.4` (2026-06-29); `main` has additional fixes after that tag.  

Material changes since the prior review:

- Ponytail is now published as the scoped npm package `@dietrichgebert/ponytail`, with OpenCode/Pi packaging and npm trusted-publishing workflow.
- Added or expanded Qoder, Devin, Hermes, Pi, Copilot, Codex, OpenCode, Antigravity/Gemini, and static AGENTS/rules support.
- Fixed Codex hook output schemas, including top-level `additionalContext` for Codex CLI SessionStart.
- Added subagent ruleset injection via lifecycle hooks, with later scoping so SubagentStart injection can be limited by agent type.
- Added default-mode persistence (`/ponytail default <mode>`), quiet Pi startup options, status indicator controls, and safer uninstall behavior that preserves combined statuslines.
- Hardened cross-platform behavior: PowerShell-compatible hook commands, no bash-only `exec`, Windows stdin EOF freeze fix, CRLF handling, malformed config handling, and Qwen/OpenCode system-entry compatibility.
- Improved adapter/test coverage: Pi extension tests, MCP tests under root test intent, Qoder tests, copied-rule invariants, OpenClaw generated-skill parity, and more manifest/version drift checks.

---

## Verdict

✅ **Deploy candidate for agent-instruction stacks.** Ponytail remains a strong small behavior layer, and the update makes it more deployable: npm packaging, broader host support, better Codex/OpenCode/Pi/Qoder compatibility, and more cross-platform hook hardening. It is still a behavior modifier rather than a correctness/security tool, so pair it with tests and review gates.

---

## What It Is

Ponytail packages a coding-agent style guide as reusable agent infrastructure. The core rule is a ladder: ask whether the task should exist, reuse existing code, use the standard library, use native platform features, use already-installed dependencies, then write the smallest custom implementation that preserves validation, security, accessibility, and explicit user requirements.

The repo is no longer just a multi-host prompt pack. It is an installable npm package, an MCP server, a Pi extension, OpenCode plugin, Claude/Codex plugin set, Qoder/Devin/Hermes/Gemini/Copilot adapter collection, generated OpenClaw skill source, and static rules bundle for hosts that read `AGENTS.md` or rule files.

The benchmark story remains a useful corrective: the project documents how earlier single-shot numbers overstated the effect, then moved to real agentic runs against a FastAPI/React repo with diff-based scoring and adversarial safety checks.

## Stack

| Layer | Tech |
|-------|------|
| Core rules | Markdown Agent Skills and `AGENTS.md` |
| Runtime hooks | Node.js CommonJS lifecycle scripts |
| Package | npm package `@dietrichgebert/ponytail` |
| MCP | `@modelcontextprotocol/sdk`, Zod, stdio server |
| Host adapters | Claude, Codex, OpenCode, Gemini/Antigravity, Copilot CLI, Pi, Hermes, Qoder, Devin, Cursor, Windsurf, Cline, Kiro, OpenClaw |
| Tests | Node test runner, adapter smoke tests, Windows hook checks, generated-skill drift tests, MCP/Pi subproject tests |
| Benchmarks | Promptfoo configs, Python agentic harness, Claude Code JSON telemetry |

## Key Features

### Canonical Rule Source With Adapter Fan-Out

The strongest engineering pattern is still the same: Ponytail keeps the rules canonical and makes adapters consume or generate from that source. `hooks/ponytail-instructions.js` reads the canonical skill, filters mode-specific sections, and feeds lifecycle hooks and MCP. Tests keep generated OpenClaw skills and copied rule files aligned.

### Installable Package and Broader Adapter Support

Since the prior review, Ponytail became an npm package and added more first-class adapter surfaces. OpenCode and Pi can consume it through package-style installs; Qoder has rules plus hook config; Hermes has a plugin manifest and runtime tests; Devin has plugin metadata; Codex hook schemas were corrected; and static `AGENTS.md`/rules files cover hosts that do not need active hooks.

### Persistent, Mode-Aware Hooks

The hooks persist active mode and inject the right ruleset on session start or prompt submission. Newer changes improve default-mode persistence and status indicators while reducing accidental state damage during uninstall or malformed config handling.

### Cross-Platform Hook Hardening

The recent commit history is mostly boring in the best way: PowerShell compatibility, bash-only `exec` removal, Windows stdin freeze protection, UTF-8 BOM handling, CRLF benchmark parsing, and safer filesystem writes. That is exactly the maintenance work portable agent plugins need.

### Defensive Minimalism, Not Code Golf

The skill still blocks the bad version of "write less." It tells the agent not to simplify away trust-boundary validation, data-loss error handling, security, accessibility, hardware calibration, or explicit user requirements. It also expects a tiny runnable check for non-trivial logic.

## Architecture

Ponytail is a portability layer around one rule corpus:

- `skills/` holds canonical skills and commands.
- `AGENTS.md` and host rule files make instruction-only adapters work.
- `hooks/` implements mode tracking, activation, instruction assembly, subagent injection, and statusline support.
- `.codex-plugin/`, `.claude-plugin/`, `.opencode/`, `.qoder-plugin/`, `.devin-plugin/`, `.github/plugin/`, `gemini-extension.json`, `plugin.yaml`, and `pi-extension/` expose host-specific install surfaces.
- `ponytail-mcp/` serves the ruleset through MCP.
- `tests/` checks adapter wiring, copied-rule drift, generated OpenClaw skills, Windows hook syntax, package scripts, uninstall behavior, and benchmark correctness helpers.

The clean pattern is "source instruction once, generate or verify every downstream host copy." That is still worth copying.

## Comparison

| Aspect | Ponytail | Superpowers | agent-skills | dzhng/skills |
|--------|----------|-------------|--------------|--------------|
| Primary value | Minimal-code behavior layer | Full coding workflow methodology | Broad production skill catalog | Portable software-factory skills |
| Scope | One behavior, many adapters | End-to-end dev lifecycle | Many skills and personas | Spec/implementation/review loops |
| Runtime weight | Small Node hooks or static rules | Skill/plugin bootstrap | Skill/command pack | Skill pack |
| Best pattern | Canonical rule source with drift tests | File-backed SDD/review | Anti-rationalization breadth | Living slice graph |
| Caveat | Behavior modifier only | Heavier workflow | Needs pruning | Less packaged than Ponytail |

## Self-Hosting Notes

For most users, install through the target host's plugin/package mechanism. The npm package path is now the cleanest route for OpenCode/Pi-style use. Node must be available for lifecycle hooks in active-hook hosts; if it is missing, the static skills/rules still work where the host loads them.

For local verification, upstream expects Python with pandas for one CSV benchmark correctness test. Without pandas, the root test suite fails that one fixture while the adapter/hook/package tests around it still pass.

## Verification Notes

Local checks on 2026-07-11:

- Cloned current `main` at `14a0d79548d4de8fc2de95c1b94bb0de63a739d3`.
- GitHub metadata: 80,849 stars, 4,364 forks, 24 open issues, latest release `v4.8.4`.
- `npm install` at root reported 0 vulnerabilities.
- `npm test` at root ran 82 tests: 81 passed, 1 failed because this machine lacks pandas for the CSV benchmark correctness fixture.
- `npm test --prefix pi-extension` passed 23 tests.
- `npm test --prefix ponytail-mcp` passed 3 tests and reported 0 vulnerabilities after install.

---

**Attribution:** DietrichGebert/ponytail, MIT License
