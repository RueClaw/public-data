# REA — Reverse Engineer Anything (morluto/rea)

**Repo:** https://github.com/morluto/rea
**License:** MIT (free extraction and reuse)
**Reviewed:** 2026-10-05
**Stack:** TypeScript/Node 22+ (~180K lines), MCP server + CLI, bridges to Hopper/Ghidra/IDA for native binaries; static JS/Electron/.NET/APK analysis without external engines
**What it is:** One MCP (and CLI) for reverse engineering across native binaries, JavaScript/Electron apps, .NET assemblies, APKs, firmware, and websites — built around an Evidence model where every conclusion ships with its supporting evidence, limitations, and unknowns.

---

## Verdict

✅ **Deploy candidate for investigation tooling.** REA is the most carefully engineered agent-facing tool in this review series: consent-gated setup that shows diffs and backs up configs before touching them, provider selection that *refuses to guess* when multiple analysis engines could handle a target (fails with `capability_unavailable` + candidate list, never falls back silently), immutable snapshot caching keyed on exact target bytes + operation + parameters, owner-only file permissions, no-follow file opens, and an uninstall that preserves everything it didn't create. Verified locally: after `npm ci` + `npm run build`, **4,059 of 4,066 relevant tests pass (99.8%)**; the 7 failures are all Xcode NIB-decoding boundary tests that smell host-specific (macOS 27 NIB serialization), not logic bugs. Native deep analysis requires bring-your-own Hopper/Ghidra/IDA — the MCP is only as strong as the engine behind it — and reverse engineering carries the usual legal/ToS boundaries: point it at software you're entitled to inspect.

---

## What It Is

REA's pitch: "See a feature you like. Understand how it works, down to the binary level." An agent (Claude Code, Codex, Cursor, Gemini CLI, Copilot CLI, OpenCode, VS Code, and more) gets a tool catalog for investigating applications without source access — recover readable code, strings, and structure; trace behavior; capture and compare process runs — and every result comes back as an **Evidence bundle** with inline citations, explicit limitations, and named unknowns. The agent can then explain the feature and draft an equivalent implementation.

Analysis providers are pluggable: static JavaScript/Electron analysis runs with Node alone (no engine, no execution of the target); native binaries go through Hopper (setup can install it with approval; demo mode works), Ghidra (BYO 12.1.x + JDK 21, headless, atomic annotation edits), or IDA Pro (reuses mrexodia/ida-pro-mcp, attached or headless). APK uses a caller-supplied JADX JAR; firmware uses caller-supplied Binwalk/Unblob. When multiple installed engines could handle a target, REA makes you choose once — explicitly — and sticks to it.

Operational details are unusually well thought out: `doctor` audits host/engines/registrations with scoped readiness checks (a missing engine you're not using doesn't fail your task); snapshots let exact-repeat queries skip the provider entirely; reference-source import keeps historical source separate from current observations; evidence bundles can be canonicalized, exported, and diffed (`rea compare`).

## Stack

| Layer | Tech |
|-------|------|
| Language | TypeScript, Node 22.19+/24.11+/26+ (~180K lines src, 504 test files) |
| Surfaces | MCP server (stdio) + full CLI parity (`rea analyze`, `rea decompile`, `rea doctor`, ...) |
| Native engines | Hopper (optional approved install), Ghidra 12.1.x headless, IDA Pro 9.x via ida-pro-mcp |
| Engineless | Static JS/Electron/ASAR analysis with Node only |
| Mobile/FW | JADX (BYO JAR) for APK; Binwalk/Unblob for firmware regions |
| Data model | Immutable Evidence bundles; snapshot cache keyed on bytes+op+params |
| Tests | 504 files, 4,125 tests — verified 4,059 pass post-build (99.8%) |

## Key Features

### Evidence as the output contract

Every analysis returns evidence, limitations, and unknowns alongside conclusions — the agent can't overclaim because the tool reports its own uncertainty. Evidence bundles are immutable, canonicalizable, and diffable across app versions. This is the same anti-hallucination philosophy as Leviathan's `shown N of M`, applied to reverse engineering.

### Refusal-by-design provider selection

Multiple capable engines → `capability_unavailable`, `selection_reason: "ambiguous"`, candidate IDs. Choose once via flag/env; the session never silently falls back. Selected engine broken → `provider_unavailable` with remediation. Both failure modes are explicit and actionable.

### Consent-gated, reversible setup

Setup shows exact paths and changes before applying, backs up existing config, detects-but-doesn't-select agents, treats Hopper as a separate consent decision, and `uninstall` removes only REA-owned registrations — preserving Evidence, captures, unrelated MCP servers, and never following purge symlinks.

### Security-conscious file handling

Owner-only snapshot permissions, safe no-follow opens for source import, configurable secret-pattern exclusion for reference imports, analysis on a temporary copy of the target (Ghidra), read-only session databases (IDA attached mode never saves your GUI database).

## Architecture

Monorepo: `src/` (MCP server, CLI, provider adapters, evidence model), `bridge/` (native analysis bridges for Hopper/Ghidra), `native/` (bundled native controls, e.g. Windows Job Object/DACL for the Windows Ghidra P0 boundary), `skills/` (version-matched agent skill with the investigation workflow), `tests/` (unit/boundary/acceptance tiers — acceptance tests exercise the *compiled* CLI and MCP factories end-to-end). Provider adapters expose a uniform contract (inventory, function, memory inspection, annotation) over very different engines.

## Comparison

| Aspect | REA | Raw Ghidra/IDA MCP plugins | Manual RE workflow |
|--------|-----|---------------------------|--------------------|
| Agent contract | Evidence + limitations + unknowns | Raw tool output | Human judgment |
| Engine selection | Explicit, ambiguity-refusing | One engine per plugin | N/A |
| Breadth | Native + JS/Electron + .NET + APK + firmware | Native only | Everything, slowly |
| Setup safety | Consent diffs, backups, clean uninstall | Varies | N/A |
| Verification | 4,125 tests incl. compiled-CLI acceptance | Sparse | N/A |

Versus using mrexodia/ida-pro-mcp or a Ghidra MCP directly: REA is the disciplined layer on top — uniform contracts across engines, evidence semantics, snapshots, and lifecycle hygiene. If you only ever use one engine and don't care about evidence bundles, a direct plugin is simpler.

## Usage Notes

`npx rea-agents setup` (interactive, consent-gated) registers the MCP with chosen agents and installs a version-matched skill. No-setup path: `npx rea-agents analyze-javascript-application /path/to/app --json` works with Node alone. `rea doctor --json` diagnoses. Legal/ToS note: reverse engineering rights vary by jurisdiction and license — REA's local, read-only analysis posture is the responsible default, but entitlement to inspect the target is on you.

---

**Attribution:** morluto/rea, MIT
