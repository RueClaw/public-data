# Open Intelligent UI (CopilotKit/OpenIntelligentUI)

**Repo:** https://github.com/CopilotKit/OpenIntelligentUI
**License:** MIT (free extraction and reuse)
**Reviewed:** 2026-10-09
**Stack:** Next.js + CopilotKit/AG-UI frontend, Python Deep Agent (FastAPI), optional standalone MCP server, pnpm/turbo monorepo
**What it is:** An open-source generative-UI chat framework: the agent answers with text, a native component, or a custom interactive UI (3D explainer, comparison chart, calculator, map) streamed into a sandboxed iframe — with the renderer chosen per-turn by the Jev decision model.

---

## Verdict

⚠️ **Interesting — the cleanest reference implementation of agent-generated interactive UI, but it's a template, not a product.** The architecture is the valuable part: a visualization router (Jev, requiring a TypeSafe API key) picks per-turn between plain text, A2UI native components, and `generateSandboxedUi` — streamed custom HTML/CSS/JS in an isolated iframe (`sandbox="allow-scripts"`, no `allow-same-origin`) with a validated host bridge for follow-ups, ordered tool parameters, and no cross-call patch API so each artifact stays immutable. BYOK hygiene is unusually careful: keys live in browser memory only (never storage, never chat state/checkpoints), LangSmith tracing is disabled for BYOK requests, and provider failures are surfaced rather than silently rerouted. Verified locally: **159/159 workspace tests pass** (app 140, design-system 15, MCP 4). Limitations: it's a demo-grade starter — sample data, two required provider keys (OpenAI + TypeSafe Jev), thin test coverage relative to surface, and the standalone MCP server is a separate, narrower path than the web app's streaming integration. Use it as the pattern source for building generative UI into your own app, not as an app.

---

## What It Is

Open Intelligent UI is CopilotKit's flagship generative-UI example grown into a small framework: a chat interface where answers can be interactive. Ask about airplanes, get a rotatable 3D model with labeled pitch/roll/yaw controls; compare plans, get a table that becomes a chart on follow-up; split a bill, get a working calculator; plan a trip, get a live USGS-tiled map with pins. Launch scenes are honestly labeled as rendered demos, and sample numbers as illustrations.

The pipeline: a Python "Deep Agent" (task-first system prompt + focused skills) streams through CopilotKit/AG-UI to the Next.js app. **Jev** (`jev-latest`, the TypeSafe decision model) selects the presentation per user turn: text, A2UI native components for basic tables, or Open Generative UI for charts/diagrams/calculators/maps. Custom UI is generated as HTML/CSS/JS with a strict parameter order (`initialHeight → placeholderMessages → css → html → jsFunctions → jsExpressions`) and streamed into a sandboxed iframe. Local controls run inside the sandbox; a user-initiated follow-up passes selected values through a validated host bridge into a new agent turn. Prior outputs remain separate immutable artifacts.

An optional standalone MCP server exposes skill resources, prompt templates, and `assemble_document` (returns an HTML document as text for a compatible host to render) — explicitly distinct from the web app's streaming path.

## Stack

| Layer | Tech |
|-------|------|
| Frontend | Next.js, CopilotKit, AG-UI, `packages/design-system` |
| Agent | Python 3.12+ Deep Agent, FastAPI (port 8123) |
| Routing | Jev (`jev-latest` via TypeSafe key) → text / A2UI / Open Generative UI |
| Model | `chat-latest` (OpenAI) default; BYOK via chat header |
| Sandbox | Isolated iframe, `sandbox="allow-scripts"`, validated host bridge |
| MCP | Optional standalone server (HTTP/stdio/Docker) |
| Tests | 24 files, 159 tests — verified passing |

## Key Features

### Jev-routed presentation

The renderer decision is made per-turn by a small decision model rather than prompt conventions — text vs. native component vs. generated UI. Failures surface instead of silently substituting another router. This is the second substantial Jev consumer we've reviewed (after OpenHuman's tool routing), and the use is well-scoped: presentation selection is exactly a fixed-option-set decision.

### Sandboxed generative UI with real boundaries

Generated code runs in an isolated iframe without same-origin access; host communication crosses a validated bridge and only on user action; tool parameters arrive in a fixed order; there's deliberately no patch API, so conversation artifacts are immutable. The right shape for agent-generated UI.

### BYOK done carefully

Keys in browser memory only (cleared on refresh, never in storage), kept out of chat state and checkpoints, hosted LangSmith tracing disabled for BYOK requests, connection test before save, and a new chat on key change. Plus the honest caveat: "only use this on a deployment whose operator you trust."

### Launch honesty

Demo scenes labeled as rendered; sample data labeled illustrative; map connections labeled "not verified driving directions"; tests alone don't verify model access, and the docs say so.

## Architecture

`apps/app` (Next.js + CopilotKit frontend) ↔ `apps/agent` (Python Deep Agent + FastAPI) with `apps/mcp` (optional standalone MCP) and `packages/design-system` (shared theme/SVG/form styles). The agent stream carries typed UI intents; native components handle structured tasks while `generateSandboxedUi` streams custom documents into the iframe. Single-user demo posture; Render deployment config included.

## Comparison

| Aspect | Open Intelligent UI | Vercel AI SDK generative UI | openmuse (same org, reviewed) |
|--------|---------------------|------------------------------|-------------------------------|
| Generated UI | Sandboxed iframe, streamed HTML/CSS/JS | RSC/component tool calls | AG-UI server template |
| Renderer routing | Jev decision model | LLM tool choice | — |
| BYOK hygiene | Memory-only keys, no tracing | App-dependent | Hosted key required |
| Purpose | Reference framework | SDK | Personal-agent template |
| Maturity | Demo-grade, MIT, 2.3K★ | Production SDK | 13-day alpha at review |

## Usage Notes

`make setup && make dev` (Node 22+, pnpm 9+, Python 3.12+, uv). Needs `OPENAI_API_KEY` + `TYPESAFE_API_KEY` (server env or per-visitor via chat header). Agent health at `:8123/health`. `docs/bring-to-your-app.md` is the extraction path — the repo expects to be mined, not deployed as-is.

---

**Attribution:** CopilotKit/OpenIntelligentUI, MIT
