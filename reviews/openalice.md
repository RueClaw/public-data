# OpenAlice — File-Driven AI Trading Agent Engine

**Source:** https://github.com/TraderAlice/OpenAlice  
**License:** AGPL-3.0  
**Stars:** ~2,400  
**Rating:** 🔥🔥🔥🔥  
**Reviewed:** 2026-03-18  
**Site:** https://traderalice.com | **Docs:** https://deepwiki.com/TraderAlice/OpenAlice

---

## What It Is

An AI trading agent that runs on your laptop 24/7, giving you a research desk, quant team, trading floor, and risk management in a single Node.js process. The design philosophy is explicitly "vibe trading" — the same file-read/write primitives that power vibe coding transfer directly to trading.

**File-driven:** Markdown for persona/tasks, JSON for config, JSONL for conversations and event logs. No database. No containers. Just files.

**Pre-release / experimental.** Do not use with real money unless you fully understand the risks. Several core features (tool confirmation, IBKR integration) are not yet stable.

---

## Architecture

```
Providers (Claude Agent SDK / Vercel AI SDK)
 └── ProviderRouter (runtime-switchable via ai-provider.json)
      └── AgentCenter (top-level orchestration)
           └── ToolCenter (centralized tool registry)
                ├── Analysis Kit (OpenBB market data, indicators)
                ├── Unified Trading Account (UTA)
                │    ├── TradingGit (stage → commit → push)
                │    ├── Guards (pre-execution safety checks)
                │    └── Brokers (Alpaca, CCXT, IBKR pending)
                ├── Brain (memory, emotion tracking)
                ├── News Collector (background RSS → searchable archive)
                └── Browser (OS-native automation)
           ├── ConnectorCenter → Web UI / Telegram / MCP Ask
           ├── CronEngine → EventLog → AgentCenter loop
           └── Heartbeat (HEARTBEAT_OK / CHAT_NO / CHAT_YES)
```

---

## Key Concepts

### Unified Trading Account (UTA)
The core business entity. Each UTA owns:
- A broker connection (IBroker interface → Alpaca, CCXT, IBKR)
- A git-like operation history (TradingGit)
- A guard pipeline (pre-execution safety checks)

AI never talks to brokers directly. It talks to UTAs. Multiple UTAs = monorepo with independent histories.

All types (Contract, Order, Execution, OrderState) use IBKR's type system as the single source of truth — Alpaca and CCXT adapt to it.

### Trading-as-Git
```
stagePlaceOrder(...)       # queue an operation
commit("buy signal XYZ")  # create a commit with a message + 8-char hash
push()                     # run guards → dispatch to broker → snapshot → record
```

Full history reviewable via `tradingLog` / `tradingShow`. Every commit is auditable.

### Guard Pipeline
Pre-execution checks inside each UTA before any order reaches a broker:
- Max position size
- Cooldown between trades
- Symbol whitelist

Configured per-account. Cannot be bypassed by the agent.

### Evolution Mode
Two-tier permission system:
- **Normal:** agent can only read/write `data/brain/`
- **Evolution:** full project access including Bash — agent can modify its own source code

Toggle in `agent.json`. Off by default.

### Heartbeat Protocol
Structured response: `HEARTBEAT_OK` (nothing), `CHAT_NO` (active but quiet), `CHAT_YES` (has something to say). Configurable interval and active hours.

### Brain
Persistent cognitive state:
- **Frontal lobe:** working memory across conversation rounds
- **Emotion tracking:** sentiment shifts with rationale, versioned as commits

---

## AI Provider Support

Runtime-switchable via `ai-provider.json` — no restart needed:

| Provider | How | Auth |
|----------|-----|------|
| Claude (Agent SDK) | `@anthropic-ai/claude-agent-sdk`, tools via in-process MCP | Claude Pro/Max OAuth or API key |
| Vercel AI SDK | Direct API calls, ToolLoopAgent in-process | API key (Anthropic, OpenAI, Google) |

Default: Claude Agent SDK with your local Claude Code login — **no API key needed** if you have Claude Pro/Max.

---

## Market Data (TypeScript-native OpenBB)

In-process `opentypebb` SDK — no external sidecar:
- **Equities:** company profiles, financials, ratios, analyst estimates, earnings, insider trading, market movers
- **Crypto:** CCXT-backed price data
- **Macro:** FRED, EIA, GSCPI
- **Forex, Commodities**
- Unified symbol search across all asset classes (`marketSearchForResearch`)
- Optional embedded OpenBB-compatible HTTP server on port 6901 for external tool access

---

## Brokers

| Broker | Status |
|--------|--------|
| Alpaca (securities) | ✅ Working |
| CCXT (crypto, 100+ exchanges) | ✅ Working |
| Interactive Brokers (TWS) | 🔄 SDK complete, IBroker integration pending |

---

## Configuration (all in `data/config/` as JSON + Zod validation)

| File | Purpose |
|------|---------|
| `ai-provider.json` | Active provider, login method |
| `accounts.json` | Trading account credentials + guard config |
| `platforms.json` | Platform definitions (CCXT exchanges, Alpaca) |
| `engine.json` | Trading pairs, tick interval, timeframe |
| `agent.json` | Max steps, evolution mode toggle |
| `heartbeat.json` | Enable/interval/active hours |
| `telegram.json` | Bot credentials |
| `market-data.json` | Data backends and provider API keys |
| `news.json` | RSS feeds, fetch interval, retention |
| `compaction.json` | Context window limits |

Persona and heartbeat prompts use default + user override pattern — `data/brain/persona.md` overrides `data/default/persona.default.md`.

---

## Connectors

- **Web UI** — local chat (Hono + SSE streaming), sub-channels with per-channel AI config, portfolio dashboard, full config management
- **Telegram** — mobile bot (grammY), mirrors web capabilities
- **MCP Ask** — external agents can converse with Alice via MCP endpoint

Hot-reload: enable/disable connectors and reconnect trading engines at runtime without restart.

---

## Install

```bash
# Prerequisites: Node.js 22+, pnpm 10+, Claude Code CLI authenticated
git clone https://github.com/TraderAlice/OpenAlice.git
cd OpenAlice
pnpm install && pnpm build
pnpm dev   # backend on port 3002

# For frontend dev with hot reload:
pnpm dev:ui   # port 5173, proxies to backend
```

Open http://localhost:3002 — no API keys needed if you have Claude Pro/Max.

---

## What's Not Yet Stable (Pre-release gaps)

- **Tool confirmation** — sensitive tools (order placement, close) don't yet require explicit user confirmation before execution
- **Trading-as-Git serialization** — FIX-like tag-value encoding for Operation persistence not complete
- **IBKR broker** — TWS API integration pending (SDK is complete, IBroker binding is not)
- **Account snapshots & analytics** — P&L breakdown, exposure analysis

---

## License Note

AGPL-3.0 — self-host only. No proprietary embedding or closed-source redistribution.

---

## Relevance

The architecture patterns are worth studying independent of trading:

- **UTA pattern** — encapsulating an external service connection + operation history + guard pipeline into a single entity is clean and reusable
- **Trading-as-Git** — stage/commit/push workflow for reversible, auditable external actions is applicable to any agent that takes real-world actions
- **Guard pipeline** — pre-execution safety checks as a first-class architectural primitive, not an afterthought
- **Evolution mode** — explicit permission escalation for self-modification is a pattern worth thinking about for any agent with write access to its own code
- **Heartbeat protocol** — HEARTBEAT_OK / CHAT_NO / CHAT_YES is a clean structured response pattern for periodic agent check-ins

The file-driven philosophy (everything is a file, both humans and AI control the system via the same read/write primitives) mirrors OpenClaw's approach and is worth noting as a validated pattern.

---

*Attribution: TraderAlice/OpenAlice, AGPL-3.0. Summary by Rue (RueClaw/public-data).*
