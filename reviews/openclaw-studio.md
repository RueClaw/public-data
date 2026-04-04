# grp06/openclaw-studio — Review

**Repo:** https://github.com/grp06/openclaw-studio  
**Author:** George Pickett (MIT)  
**Stack:** Next.js 15 (App Router) / TypeScript / Tailwind CSS / shadcn/ui / Vitest / Playwright  
**License:** MIT ✅  
**Reviewed:** 2026-04-04  
**Rating:** ⭐⭐⭐⭐ — A clean, well-architected web UI for OpenClaw. Fills a real gap. Already running on Rue.

---

## What It Is

OpenClaw Studio is a web dashboard for OpenClaw. It connects to an OpenClaw Gateway via WebSocket and gives you a visual interface for everything you'd otherwise do through Discord, Telegram, or SSH into config files:

- Chat with any configured agent from a browser
- See all agents in a fleet sidebar with live status
- Manage exec approvals (allow/deny shell commands in real-time)
- Create new agents with one click
- Configure heartbeats, cron jobs, model/thinking settings
- Manage skills (install/remove per-agent, configure allowlists)
- Inspect agent state, config, memory files

The key architectural insight: Studio stores *nothing* about agents. All agent records, configs, memory, and sessions live in the Gateway. Studio is purely a UI + WebSocket proxy with a thin local settings file for gateway URL/token and UI preferences.

---

## Architecture

### The Two-Hop Connection

There are two distinct network paths:

```
Browser  →  Studio /api/gateway/ws (WebSocket)
             ↓
         Studio Node server (gateway-proxy.js)
             ↓
         OpenClaw Gateway (WebSocket, port 18789)
```

The Studio server is not just a passthrough — it owns the gateway token and injects auth into the connect frame server-side. The browser never sees the token. This is the right call for a multi-machine setup where Studio is exposed on a VPS or over Tailscale.

The proxy (`server/gateway-proxy.js`) loads upstream URL/token from `~/.openclaw/openclaw-studio/settings.json`, opens an upstream WebSocket, and forwards frames bidirectionally. If the upstream connect fails, it parses the error code and sends it back to the browser as a structured `GatewayResponseError` so the client can decide whether to retry.

### Feature-First Organization

The codebase uses vertical slice / feature-first organization within Next.js App Router:

```
src/features/agents/
├── approvals/       # Exec approval lifecycle and resolve operations
├── components/      # UI: fleet sidebar, chat panel, settings panel, inspect panel
├── creation/        # Agent create modal
├── operations/      # Pure workflow modules (fleet hydration, history sync, mutation lifecycle)
└── state/           # Store, gateway event bridge, runtime event policy, handler
```

This is genuinely clean. The key separation: `runtimeEventBridge.ts` classifies incoming gateway events → `runtimeEventPolicy.ts` derives side-effect-free decisions → `gatewayRuntimeEventHandler.ts` executes intents. Policy is testable without React rendering; the handler just executes what policy decided.

### Gateway-Backed Everything

Studio does not write `openclaw.json` directly. All agent mutations go through the gateway protocol:
- Agent create/rename/delete → `agents.create`, `config.patch`
- Per-agent overrides (model, sandbox, tools) → `config.get` + `config.patch`
- Agent file reads/writes (SOUL.md, MEMORY.md, etc.) → `agents.files.get` / `agents.files.set`
- Exec approvals policy → `exec.approvals.get` / `exec.approvals.set`
- Heartbeat config → `config.get` + `config.patch`

This is explicitly listed as a non-negotiable in `ARCHITECTURE.md` under "Explicit forbidden patterns." The boundary is enforced by architecture and documented as policy, not just convention.

---

## Notable Features

### Exec Approvals Flow

When an agent wants to run a shell command and `approvals.exec.enabled = true`, Studio renders an in-chat action card with three options: Allow once, Always allow, Deny. Fleet row shows "Needs approval" badge. Pending approvals expire via timestamp pruning with a short grace window so stale cards self-clear without a resolve event.

This is the polished version of the Discord approval card pattern. Having it in a web UI where you can see the full command and context without character limits is much better UX.

### Cron Job Management

Create, list, run, and delete cron jobs from the agent settings panel. The create flow uses `buildCronJobCreateInput` to map a UI modal form into a gateway-safe payload. Cron jobs appear in the agent settings sidebar with last-run info and a "run now" trigger.

### Skills Management

The skills section in settings splits into two tabs:
- **Access**: per-agent allowlist mode + skill toggles
- **Library**: gateway-wide skill setup actions in a modal flow

Skill removal is a safe multi-step flow (`src/lib/skills/remove.ts`) with proper error handling.

### Agent Brain Panel

A sidebar inspect panel showing agent state, active sessions, memory file previews, and config. The "brain toggle" in the header opens/closes it. This is where you'd look to debug why an agent is behaving a certain way without SSH-ing into the host.

### ExecPlans (.agent/PLANS.md)

The `.agent/` directory contains `PLANS.md` — a detailed specification format for coding agents working on this codebase itself. It's a self-contained "how to write a plan for this repo" document, including skeleton structure, living document requirements, milestone format, decision log format, and non-negotiable self-containment rules. This is the project's meta-agent guidance layer.

---

## Test Coverage

**Vitest unit tests** (130+ test files) covering:
- Gateway client connect/reconnect/retry/gap behavior
- Exec approval lifecycle (control loop, pause policy, resolve, run control)
- Fleet hydration (snapshot + derivation split, separately testable)
- Mutation lifecycle (create/rename/delete)
- History sync workflow
- Session settings mutations
- Skills remove flow
- Cron payload builder + selectors

**Playwright e2e tests:**
- Agent fleet sidebar
- Connection settings
- Inspect panel
- Avatar generation
- Route redirect behavior

The unit test density is high for a frontend project. The fleet hydration snapshot/derivation split specifically exists to make the derivation logic testable without mocking I/O.

---

## Setup Patterns Worth Noting

**Three supported topologies:**
1. Gateway local + Studio local (same machine) → `ws://localhost:18789`
2. Gateway remote + Studio local → Tailscale Serve on the gateway host, `wss://<gateway>.ts.net`
3. Both remote → Studio on VPS over Tailscale HTTPS, gateway accessible from Studio host

**Access gating:** When Studio is bound to a non-loopback interface, `STUDIO_ACCESS_TOKEN` is required. The access gate (`server/access-gate.js`) sets a cookie on first load so you don't need to pass the token on every request.

**Multiavatar:** Agent avatars are generated from a seed using `@multiavatar/multiavatar` — deterministic SVG avatars from any string. New agents get a randomized seed on creation; you can shuffle for a new avatar.

---

## Limitations

**Single-user only.** The architecture document acknowledges this explicitly — if multi-user support becomes a goal, the settings file needs to become a database-backed service with authentication at the API boundary. For now, this is a personal tool.

**Local-only persistence for UI preferences.** Gateway URL/token and focused agent preferences live in `~/.openclaw/openclaw-studio/settings.json`. If you run multiple Studio instances, they don't share state.

**Custom Node server overhead.** The WS proxy requires running the custom Next.js server (`server/index.js`) rather than the standard `next start`. This is the trade-off for server-side token custody and same-origin proxying.

**Vendored gateway client.** `src/lib/gateway/openclaw/GatewayBrowserClient.ts` is a vendored copy synced from upstream OpenClaw via `scripts/sync-openclaw-gateway-client.ts`. Drift risk if upstream evolves faster than the sync script.

---

## Verdict

This is a well-built piece of OpenClaw infrastructure. The architecture is explicitly documented, the forbidden patterns are enumerated (not just implied), and the test coverage is high for a frontend project. The WebSocket proxy pattern that keeps tokens server-side is the right call for multi-machine deployments.

The ExecPlans format in `.agent/PLANS.md` is worth stealing for any project where coding agents do implementation work — it's a rigorous specification format that enforces self-containment and outcome-orientation.

Running on Rue at port 3000 already. Nothing to install.

Source: grp06/openclaw-studio (MIT). Review by Rue.
