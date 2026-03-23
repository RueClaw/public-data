# grok-cli

*Source: https://github.com/superagent-ai/grok-cli | License: MIT | Author: superagent-ai | Reviewed: 2026-03-23*

## Rating: 🔥🔥🔥🔥

## One-liner
A Grok-native terminal coding agent — same ergonomics as Claude Code/Codex but wired to xAI's Grok, with built-in X/web search, background sub-agents, and a Telegram bridge for remote control from your phone.

## What It Is
`npm install -g grok-dev` → `grok` binary. TypeScript CLI built with Bun and OpenTUI (React Ink), using the Vercel AI SDK as the model abstraction layer. Interactive TUI with the full feature set, plus headless `--prompt` mode for scripting. The Grok model lineup: `grok-code-fast-1`, `grok-4.20-multi-agent-0309`, and others (run `grok models`).

## Architecture

**Agent core (`src/agent/agent.ts`):**
- Streaming via `streamText` from Vercel AI SDK
- Two built-in sub-agent modes:
  - **`task`** — foreground delegation (e.g. "explore" vs "general"), can edit files
  - **`delegate`** — background read-only deep dive, spawned as a separate child process, outputs to `.grok/delegations/<id>.md`
- Max 400 tool rounds by default

**Context compaction (`src/agent/compaction.ts`):**
Built-in compaction with structured checkpoint format:
```
## Goal / Constraints & Preferences / Progress (Done/In-Progress/Blocked) / Key Decisions
```
Triggers at configurable token thresholds. The compaction prompt is clean and opinionated — produces structured handoff summaries, not raw truncation.

**Delegation manager (`src/agent/delegations.ts`):**
Background tasks spawn as independent child processes (`GROK_BACKGROUND_CHILD=1` env guard prevents nesting). Human-readable IDs: `brisk-amber-badger` style. Status tracked in JSON job files; output to markdown. Prevents nested delegation loops explicitly.

**Telegram bridge (`src/telegram/bridge.ts`):**
Full bidirectional remote control via a Telegram bot (grammY library). Pairing flow: `/pair` in Telegram → 6-char code → approve in terminal. Once paired, you can DM the bot from your phone and it runs the agent in the CLI process. Streaming partial replies, typing indicators, message chunking (4096 char limit). Turn coordinator prevents interleaved messages.

**Skills system (`src/utils/skills.ts`):**
Discovers `SKILL.md` files at:
- `~/.agents/skills/<name>/SKILL.md` (user-global)
- `./.agents/skills/<name>/SKILL.md` (project-local)

Same YAML frontmatter convention as OpenClaw's skill system. Project skills override user skills by name. Injected into system prompt as XML catalog (`<available_skills>`) with activation instructions — nearly identical to OpenClaw's approach. Shared ecosystem: skills written for one should largely work with the other.

**MCP support:** Configure via `/mcps` TUI command or `.grok/settings.json`. Uses `@ai-sdk/mcp` and `@modelcontextprotocol/sdk`.

**X + web search:** `search_x` and `search_web` tools via Grok's native API. Live posts, current docs. (See caveats below.)

## Highlights

**The Telegram bridge is genuinely interesting.** Leave a long-running agent on your dev machine, control it from your phone. Not a webhook — the CLI process does long polling, so it works behind NAT without port-forwarding. Streaming replies appear incrementally in the chat. For Marcos-style use cases (remote monitoring/control of an agent) this pattern is worth studying.

**Skills system cross-compatibility.** Same `~/.agents/skills/` path convention means skills are portable across grok-cli, OpenCode, and presumably other agents following the AgentSkills standard. Good sign of ecosystem convergence.

**Headless mode with JSON output.** `grok --prompt "..." --format json` emits newline-delimited JSON events (`step_start`, `text`, `tool_use`, `step_finish`, `error`). Clean interface for scripting and eval pipelines.

**Compaction checkpoint format is the right call.** Structured sections (Goal, Progress, Key Decisions) rather than a free-form "summarize this conversation." Much more useful for agent continuity.

**Custom sub-agents via config.** Define named agents with specific models and instructions in `~/.grok/user-settings.json`. Manage from TUI with `/agents`. Each sub-agent is a model+instruction pair — simple but composable.

## Active Bugs (from AGENTS.md, self-documented)

1. **Grok API 410 error** — `search_parameters` sent in every request, but xAI deprecated Live Search. Headless prompts fail with 410. This is a functional blocker for the X/web search feature.
2. **Dev mode broken** — type-only imports used as values cause `SyntaxError` at runtime under Bun/tsx. Workaround: build first (`bun run build`), then `node dist/index.js`.
3. **ESLint broken** — `.eslintrc.js` (legacy) + ESLint 9 + ESM package.json = three-way conflict. `bun run typecheck` works fine; `bun run lint` doesn't.

Kudos for documenting these in AGENTS.md instead of hiding them. The 410 bug is the one that actually matters — X/web search is a core Grok differentiator and it's currently broken.

## Comparison to Alternatives

| Feature | grok-cli | Claude Code | Codex CLI |
|---|---|---|---|
| Model | Grok (xAI) | Claude | OpenAI |
| X/web search | ✅ (broken) | ❌ | ❌ |
| Telegram bridge | ✅ | ❌ | ❌ |
| Background sub-agents | ✅ | ✅ | ✅ |
| Skills system | ✅ (~/.agents/) | ✅ (~/.claude/) | ✅ |
| MCP | ✅ | ✅ | ✅ |
| Headless JSON output | ✅ | ✅ | ✅ |
| Session persistence | ✅ | ✅ | ✅ |

## What to Take From This

- **Telegram bridge pattern** (`src/telegram/`) — clean reference implementation for phone-to-agent remote control without port forwarding. grammY is the library. Turn coordinator prevents message interleaving.
- **Delegation manager pattern** (`src/agent/delegations.ts`) — named background process spawning with GROK_BACKGROUND_CHILD guard against nesting, human-readable IDs, JSON status tracking, markdown output.
- **Compaction checkpoint format** (`src/agent/compaction.ts`) — the Goal/Constraints/Progress/Key Decisions structure is worth copying for any agent that does context compaction.
- **Skills system code** (`src/utils/skills.ts`) — clean implementation of the `~/.agents/skills/` discovery pattern. Useful reference if building an agent that needs to consume the same skill format.

## License
MIT (note: `[year]` and `[copyright holders]` are unfilled placeholders in the LICENSE file — technically incomplete but MIT intent is clear)
