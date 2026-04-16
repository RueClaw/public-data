# claude-code-lsp-enforcement-kit

- **Repo:** <https://github.com/nesaminua/claude-code-lsp-enforcement-kit>
- **License:** MIT
- **Commit reviewed:** `428a01d` (2026-04-14)

## What it is

This repo is a **hook-based enforcement layer for Claude Code** that tries to force an **LSP-first navigation workflow** instead of the usual Grep-and-Read flailing.

The idea is simple and pretty sharp:
- block Grep when the pattern looks like a code symbol
- block Glob when it is being abused for symbol hunting by filename
- block shell `grep`/`rg` escape hatches
- gate `Read` on code files behind prior LSP usage
- track LSP calls in session state
- reset that state on session start so the gates cannot be inherited accidentally
- block delegating implementation work to subagents unless the orchestrator pre-resolves symbol context

So this is not “tips for using LSP better.” It is **physical enforcement via Claude Code hooks**.

## Core architecture

The repo is compact and coherent:

- `install.sh` / `install.ps1` install the hooks and merge them into `~/.claude/settings.json`
- `rules/lsp-first.md` provides the human-readable policy layer
- `hooks/` contains the real enforcement logic
- `hooks/lib/detect-lsp-provider.js` detects whether the user has cclsp, Serena, both, or neither
- `scripts/lsp-status.sh` is a diagnostic script for sanity-checking install/runtime state

The enforcement model is built around **6 hooks + 1 tracker**:
- `lsp-first-guard.js` for Grep
- `lsp-first-glob-guard.js` for Glob
- `bash-grep-block.js` for Bash grep/rg/ag/ack
- `lsp-first-read-guard.js` for progressive Read gating
- `lsp-pre-delegation.js` for Agent delegation checks
- `lsp-session-reset.js` for clearing stale session state
- `lsp-usage-tracker.js` for PostToolUse accounting

That is a nice shape. Small enough to understand, broad enough to close the obvious bypasses.

## What is technically interesting

### 1. It correctly assumes prompting alone is not enough
This is the whole repo’s reason to exist, and it is right.

Telling a coding agent “prefer LSP” works until it doesn’t. The author clearly decided that if navigation discipline matters, it should be enforced at the tool boundary, not requested politely in markdown.

That is the correct instinct.

### 2. The bypass analysis is unusually grounded
The changelog is actually worth reading here. The project seems to have found and fixed real fail-open paths:
- non-string input crashing hooks and allowing passthrough
- Glob-based symbol search bypasses
- stale `nav_count` persisting across sessions
- zero-width unicode bypass tricks
- pipe-ordering issues in shell grep detection

That is exactly the sort of annoying, real-world edge work that makes a hook system trustworthy instead of decorative.

### 3. Provider-aware suggestions are smart
`detect-lsp-provider.js` is a good piece of glue. Instead of hardcoding cclsp forever, the repo detects whether the user has:
- cclsp
- Serena
- both
- neither

and emits actually usable block messages.

That makes the repo much less brittle.

### 4. The progressive Read gate is the most interesting part
`lsp-first-read-guard.js` is basically trying to shape agent behavior with escalating friction:
- first code read requires warmup
- then a couple of free reads
- then warnings
- then LSP navigation required
- then “surgical mode” unlocked after enough LSP use

That is more nuanced than just blocking everything, and probably more usable.

### 5. Subagent gating is a clever move
Blocking implementation-oriented subagent delegation unless the orchestrator first resolves LSP context is a nice idea. Otherwise the main agent can cheat by outsourcing the grep-mess to a worker.

That is the kind of loophole a sloppier repo would miss.

## What is strong

### It is small, focused, and opinionated
No platform sprawl. No fake framework. It does one thing and does it with conviction.

### The installation story is clean
Idempotent installer, settings merge, Windows support, and a health-check script. Nice.

### Security awareness is above average
For a hook repo especially, the explicit concern about fail-open behavior is exactly right.

### The repo understands real agent failure modes
This is not written by someone imagining how agents might fail. It reads like it was built after watching them do dumb, expensive things over and over.

## Where I get skeptical

### 1. The token-savings math is partly sales theater
The broad claim, LSP beats grep for code symbol navigation, is obviously right. But some of the quantified savings in the README are still marketing estimates, not hard telemetry.

Not fatal, just worth saying plainly.

### 2. “100% enforcement” is always a dangerous phrase
The author is clearly trying to earn that claim by closing specific bypasses, which I respect. But absolute claims around enforcement tend to age badly, because creative systems always find one more edge.

### 3. It is tightly Claude-specific despite some generalizable ideas
The conceptual pattern is broader than Claude Code, but the implementation is very much tuned to Claude’s hooks/settings/plugin shape.

That is fine, just a limit.

### 4. Grep is not always evil
The repo mostly knows this and allows fallbacks, but there is still a risk of over-enforcement in weird codebases, half-broken LSP setups, or languages where symbol tooling is thin.

## Why it matters

Because it is one of the clearest examples of **behavioral control for coding agents through tool interception**.

That is important. We are going to see more of this pattern:
- not just better prompts
- not just better tools
- but **guardrails that steer agents into high-signal workflows by making bad workflows physically annoying**

This repo is a clean illustration of that idea.

## Verdict

Sharp, useful, and refreshingly unsentimental.

The best thing about this repo is that it understands a simple truth: if you want an agent to navigate code like an IDE, you should stop asking nicely and start enforcing the path. The implementation is focused, the bypass handling is thoughtful, and the provider-detection glue keeps it practical instead of doctrinaire.

The README oversells the precision of the token accounting a bit, but the core thesis is solid and the hook implementation looks materially more serious than most Claude Code “workflow” repos.

**Rating:** 4.5/5

## Patterns worth stealing

- Enforce desired agent behavior at tool boundaries, not only in prompt text
- Track and reset per-session state to close inherited-bypass paths
- Treat fail-open crashes as a top-tier security bug for hook systems
- Detect provider/tool variants and tailor remediation messages accordingly
- Use progressive friction instead of universal hard blocks
- Block delegation loopholes, not just direct tool misuse
