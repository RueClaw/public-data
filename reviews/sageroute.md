# SageRoute (codejunkie99/sageroute)

**Repo:** https://github.com/codejunkie99/sageroute
**License:** MIT, permissive reuse with attribution
**Reviewed:** 2026-07-30
**Stack:** TypeScript, Bun, HTTP proxy, OpenAI Responses API, OpenAI Chat Completions, Anthropic Messages API, OAuth credential handling
**What it is:** A trajectory-aware model router that exposes an OpenAI/Anthropic-compatible proxy, starts each agent session on a cheap model, and escalates to stronger models only when tool-call evidence shows the agent is stuck.

---

## Verdict

⚠️ **Interesting, with a strong pattern worth harvesting before deployment.** SageRoute has a crisp architecture and a well-tested core: it recovers execution evidence from agent request bodies, derives deterministic stuck signals, asks Levanto Sage at checkpoints, and applies a guarded cheap-to-strong ladder. It is still early operationally: no tags/releases, no committed lockfile, red upstream CI on the reviewed commit, and a hard dependency on an external decision API for live routing.

---

## What It Is

SageRoute is an HTTP model proxy for coding agents. Instead of choosing a model before a task starts, the proxy watches the execution history already present in each agent request: tool calls, tool outputs, failed commands, repeated errors, verification attempts, costs, and session identity. Based on that trajectory, it keeps the session on the cheap tier, switches to a stronger tier, restarts with trimmed context, or returns a human-escalation notice.

The main integration path is the OpenAI Responses API at `/v1/responses`, which is the native routed path because it carries tool-call history. The proxy also serves Anthropic Messages at `/v1/messages` and translates that wire into the same internal Responses-shaped evidence model, then translates responses back for clients such as Claude Code. Chat Completions is supported for passthrough and upstream adapters, but the router alias rejects Chat Completions because that wire does not preserve enough execution trajectory.

The live decision dependency is Levanto Sage. SageRoute reduces the run to compact evidence and asks a two-stage protocol: first a binary "intervene?" gate, then a four-way action choice only when the gate fires. If Sage is unavailable, policy fails open and continues rather than taking the agent down.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Bun 1.1+, TypeScript strict |
| Proxy | Native `Request`/`Response`, JSON and SSE handling |
| Inbound APIs | OpenAI Responses, Anthropic Messages, Chat Completions passthrough |
| Upstream adapters | `openai-responses`, `openai-chat`, `anthropic-messages` |
| Decision engine | Deterministic trajectory signals plus Levanto Sage `/decide` |
| Auth | API-key secret indirection, optional proxy bearer token, OpenAI/Anthropic OAuth store |
| Persistence | In-memory session state; OAuth credentials in `~/.sageroute/auth.json` |
| Deployment | Bun CLI, Dockerfile, shell daemon wrapper, macOS LaunchAgent script |
| Tests | Bun test suite, 180 local tests passing |

## Key Features

### Evidence-Based Routing

The best idea is the boundary: SageRoute treats the agent request body as a trajectory log. It pairs `function_call` and `function_call_output` items by `call_id`, hashes tool arguments and outputs, classifies failure text into coarse error classes, counts pending calls, and extracts a bounded task goal.

That is a better signal than asking the model whether it is struggling. A passing test, repeated `AssertionError`, or write/test/write/test cycle is concrete evidence; assistant narration is not.

### Deterministic Stuck Signals

Before Sage is consulted, the router computes transparent signals:

- repeated identical action plus identical observation
- repeated error class
- ping-pong between two actions
- recent error rate
- failed verification streak
- rewrite/retest cycles
- steps since successful execution
- budget burn

This keeps the external judge grounded in a compact factual summary instead of a raw transcript.

### Guarded Model Ladder

The ladder is one-way: cheap to strong, then clean restart or human escalation. It avoids demotion, applies budget hard stops locally, uses asymmetric hysteresis so the first cheap-to-strong switch can happen quickly, and fails open on Sage outages.

The "capability before retry" rule is particularly good: if a clean restart is proposed while still on the cheap model, the policy upgrades capability first rather than giving the same weak model a fresh chance at the same hard problem.

### Cross-Wire Translation

The Anthropic Messages route lifts `tool_use` and `tool_result` blocks into the same internal Responses-shaped action sequence. On the way back, it restores Anthropic's event protocol and `stop_reason` semantics so the client continues to execute tools. This is practical interoperability work, not just a base URL swap.

### Credential Handling

Provider config supports `${VAR}`, `$VAR`, and `env:VAR` secret indirection. Config validation rejects missing selected API keys, OAuth/key ambiguity, private-network upstream URLs unless explicitly allowed, unknown adapters, and invalid ladder settings.

OAuth storage is local and permissioned: `~/.sageroute` is created as `0700`, `auth.json` as `0600`, corrupt stores are backed up, and credential import from Codex/Claude Code is read-only.

## Architecture

The repo is small and well separated:

- `src/core/evidence.ts` recovers trajectory steps from request input.
- `src/core/signals.ts` derives loop, failure, progress, and budget signals.
- `src/core/policy.ts` turns Sage verdicts into guarded ladder actions.
- `src/core/router.ts` owns per-turn session routing and request-body rewrites.
- `src/proxy/server.ts` owns HTTP routes, auth, model passthrough, and decision headers.
- `src/proxy/upstream.ts` owns provider dispatch, SSE translation, and usage metering.
- `src/proxy/config.ts` owns config validation and secret resolution.
- `src/oauth/*` owns browser/login/import/store flows.
- `src/registry.ts` owns provider presets for subscription and API-key modes.

The cleanest reusable pattern is the split between pure routing core and proxy shell. The core has no HTTP imports; the proxy layer owns transport, adapters, credentials, config files, and upstream calls. That makes the hard part testable without live providers.

## Comparison

| Aspect | SageRoute | Codex-Orchestration | OpenScience | 9router |
|--------|-----------|---------------------|-------------|---------|
| Main goal | Runtime cheap-to-strong routing from trajectory evidence | Persistent planner/advisor/executor route policy | Scientific agent workbench | Local LLM routing gateway |
| Routing signal | Tool-call history, errors, loops, verification, budget | User/workflow role and policy | Provider/session configuration | Provider availability, fallback, compression |
| Integration point | OpenAI/Anthropic-compatible HTTP proxy | Codex plugin/config | Local app/server | Gateway/dashboard |
| Strongest pattern | Evidence-derived escalation ladder | Root-mediated routing policy | Local workbench plus scientific tools | Endpoint fallback/compression |
| Main caveat | Early ops posture and external Sage dependency | Harness-specific assumptions | Unsandboxed agent plus dependency cleanup | Security-sensitive gateway surface |

## Self-Hosting Notes

Basic local setup:

```bash
git clone https://github.com/codejunkie99/sageroute
cd sageroute
bun install
echo "SAGE_API_KEY=lv_..." > .env
bun run serve
```

Point a Responses-compatible client at:

```bash
export OPENAI_BASE_URL=http://127.0.0.1:8787/v1
export OPENAI_MODEL=sageroute
```

Local verification on 2026-07-30:

- `bun install --frozen-lockfile` passed, but no lockfile is committed, so the frozen install has no locked graph to enforce.
- `bun run typecheck` passed.
- `bun test tests/` passed: 180 pass / 0 fail.
- `bun run src/cli.ts check --config sageroute.config.example.json` passed when dummy CI-style env vars were provided.
- `bun audit --omit dev` could not run because no lockfile exists.
- GitHub Actions showed latest `CI` runs failing on the reviewed commit, but the failed job log was unavailable through `gh run view`.

Do not expose this proxy broadly without an `authToken`, network controls, and careful upstream config. It sits in front of paid model providers and can forward credentials; the private-network upstream guard is good, but the proxy host remains part of the trusted boundary.

---

**Attribution:** codejunkie99/sageroute, MIT License
