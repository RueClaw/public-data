# free-code — Review

**Repo:** https://github.com/paoloanzn/free-code  
**Author:** paoloanzn  
**License:** None (Anthropic source; legal gray area — see below)  
**Stars:** ~776 (created 2026-03-31, same day as the source map leak)  
**Rating:** 🔥🔥🔥🔥 (technically interesting, legally charged)  
**Cloned:** ~/src/free-code  
**Reviewed:** 2026-03-31

---

## What it is

A buildable fork of Claude Code's source, reconstructed from a source map accidentally exposed in Anthropic's npm package distribution on 2026-03-31. Three modifications on top of the raw leak:

1. **Telemetry stripped** — OpenTelemetry/gRPC, GrowthBook analytics, Sentry error reporting, session fingerprinting all removed or stubbed
2. **System prompt guardrails removed** — strips injected "cyber risk" blocks, hardcoded refusal patterns, managed-settings security overlays
3. **45+ experimental feature flags unlocked** — the Claude Code binary ships with dozens of compile-time gated features; this build enables all that bundle cleanly

---

## The source is real

The README links to the source map exposure (by Fried_rice, March 31). The codebase here is legitimate Claude Code internals — 46 tool implementations, full React/Ink terminal UI, QueryEngine, the whole stack. The `FEATURES.md` is a meticulous audit of all 88 feature flags, categorizing 54 working and 34 broken, with specific missing file paths for each broken one.

Confirmed internal structure:
- `src/tools/` — 46 tool implementations (BashTool, FileReadTool, FileEditTool, GrepTool, AgentTool, etc.)
- `src/QueryEngine.ts` — 1,295 lines, LLM query orchestration
- `src/query.ts` — 1,729 lines
- `src/services/`, `src/skills/`, `src/plugins/`, `src/voice/`, `src/bridge/` all present
- Full React/Ink terminal UI with hooks and components

---

## Feature flag highlights (working builds)

From the `build:dev:full` target (all 45+ unlocked):

| Flag | What it does |
|---|---|
| `ULTRAPLAN` | Remote multi-agent planning with Opus-class models |
| `ULTRATHINK` | Extra thinking-depth mode (type "ultrathink") |
| `VERIFICATION_AGENT` | Post-task verification agent |
| `EXTRACT_MEMORIES` | Automatic memory extraction after each query |
| `AGENT_TRIGGERS` | Local cron/trigger tools for background automation |
| `TEAMMEM` | Team-memory files and watcher hooks |
| `BASH_CLASSIFIER` | Classifier-assisted bash permission decisions |
| `COMPACTION_REMINDERS` | Smart reminders around context compaction |
| `CACHED_MICROCOMPACT` | Cached microcompact state |
| `BRIDGE_MODE` | IDE remote-control bridge (VS Code, JetBrains) |
| `VOICE_MODE` | Push-to-talk voice input (needs SoX on macOS) |
| `BUILTIN_EXPLORE_PLAN_AGENTS` | Built-in explore/plan agent presets |

Flags that bundle-compile but have runtime caveats: `VOICE_MODE` (needs claude.ai OAuth), `BRIDGE_MODE`/CCR flags (need OAuth + GrowthBook entitlements), `CHICAGO_MCP` (computer-use, needs missing `@ant/computer-use-*` packages).

Broken flags with easy reconstruction paths noted in FEATURES.md include `FORK_SUBAGENT`, `DAEMON`, `SSH_REMOTE`, `WEB_BROWSER_TOOL`, `WORKFLOW_SCRIPTS` — all have stubs and wiring in place, just missing a few core files.

---

## What's interesting architecturally

**Feature flag system** (`scripts/build.ts`) — compile-time Bun bundler defines, not runtime config. Each flag controls what gets imported/wired at build time. The build script takes `--feature=FLAG` args, meaning you can construct arbitrary feature combinations.

**Tool registration** (`src/tools.ts`) — registry of all 46 tools, feature-gated at import time. This is where you'd wire in custom tools.

**QueryEngine vs query.ts** — two-layer query system. `QueryEngine.ts` handles the LLM interaction layer; `query.ts` handles orchestration, context management, compaction triggering.

**Skills and plugins** — `src/skills/` and `src/plugins/` directories present. OpenClaw's skill system appears to be at least partially mirrored here (or was the origin).

**The `AGENT_TRIGGERS` flag** is particularly interesting — local cron/trigger tools for background automation built directly into the agent. This is what OpenClaw's heartbeat system approximates from the outside.

---

## Legal situation

No license declared. The source belongs to Anthropic and was exposed accidentally. The author explicitly acknowledges this: "The original Claude Code source is the property of Anthropic. This fork exists because the source was publicly exposed through their npm distribution."

There's an IPFS mirror (CID: `bafybeiegvef3dt24n2znnnmzcud2vxat7y7rl5ikz7y7yoglxappim54bm`) — the author expects a takedown.

**For us:** Study it, yes. Ship a product built on it, no. The telemetry stripping and guard removal are useful to understand what the binary does; the feature flag audit is a roadmap for what Anthropic is building. The source itself is valuable for understanding how Claude Code's internals actually work.

---

## Bottom line

Extraordinary artifact for a few days while it's up. The FEATURES.md alone is a research document — it tells you exactly what Anthropic has in the pipeline. The `EXTRACT_MEMORIES`, `VERIFICATION_AGENT`, `AGENT_TRIGGERS`, and `TEAMMEM` flags describe capabilities that align closely with where OpenClaw is heading independently.

The source confirms the iamfakeguru thread's behavioral observations (file read caps, tool result truncation, context compaction thresholds) — those aren't speculation, they're in the code.

**Watch:** It'll likely get DMCA'd. Mirror what you want to study.

**No public-data entry beyond this review** — the source itself isn't licensable for redistribution.

Source: No license, paoloanzn/free-code (Anthropic source leak, 2026-03-31)
