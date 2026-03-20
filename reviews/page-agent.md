# page-agent (alibaba/page-agent)

**Rating:** 🔥🔥🔥🔥  
**License:** MIT  
**Version:** 1.6.0  
**Source:** https://github.com/alibaba/page-agent  
**Reviewed:** 2026-03-20

## What It Is

A GUI agent that lives *inside* your webpage. Natural language → browser actions, purely client-side — no Python, no headless browser, no extension required for basic use. Just a JS bundle dropped into a page, or `npm install page-agent`.

## Architecture (monorepo)

| Package | Role |
|---------|------|
| `@page-agent/core` | `PageAgentCore` — headless, no UI |
| `page-agent` | Core + floating Panel UI |
| `@page-agent/page-controller` | DOM extraction + SimulatorMask visual overlay |
| `@page-agent/llms` | OpenAI-compatible client, reflection-before-action |
| `@page-agent/mcp` | MCP bridge → Chrome extension → live tab |

## Agent Loop

ReAct pattern. Each step structured as:
```json
{
  "evaluation_previous_goal": "...",
  "memory": "...",
  "next_goal": "...",
  "action": { "tool_name": { ...params } }
}
```
History carried forward as structured event stream. `done` is the only valid termination tool.

## DOM Approach — Text-Only, No Screenshots

- Live DOM → `FlatDomTree` → simplified text `[index]<type>text</type>`
- `*[index]` marks elements new since last step
- Element ops by index (not XPath/CSS) — deterministic, LLM-safe
- Scrollable elements tagged with scroll distance in all directions
- No multimodal LLM needed

## Key Design Decisions

- **Two task modes** — step-by-step vs. open-ended, explicitly distinguished in system prompt
- **Explicit failure policy** — "Trying too hard can be harmful." Agent is instructed to fail gracefully rather than thrash. `success: false` is a first-class outcome.
- **CAPTCHA policy** — tell user, stop. Do not attempt.
- **`onAskUser` callback** — human-in-the-loop interrupt hook
- **SimulatorMask** — visual overlay blocks user interaction during execution (good UX signal)

## MCP Bridge

```
Claude Desktop → @page-agent/mcp (stdio) → WebSocket → Chrome extension (hub tab) → live page
```
Three MCP tools: `execute_task`, `get_status`, `stop_task`. Requires Page Agent Chrome extension for the relay.

## What's Novel

In-page vs. server-side is the differentiator. The agent runs *inside the browser tab's JS context*, not a separate process. Can interact with SPA state and React component internals that Playwright/Puppeteer sometimes can't reach cleanly. Works with any OpenAI-compatible endpoint including local Ollama.

## Limitations

- Single-page only without extension (no cross-tab nav)
- No `<a target="_blank">` link following
- MCP use requires Chrome extension (hub tab must be open)

## Relevance

- VOS: embed as AI copilot — "fill in this form based on the document" flows without server-side browser control
- Claude Code via MCP: drive any open webpage from coding sessions
- Pattern reference: clean ReAct loop impl, DOM text serialization, explicit failure handling

## System Prompt Excerpt (key patterns)

```
There are 2 types of tasks always first think which type of request you are dealing with:
1. Very specific step by step instructions: Follow them precisely.
2. Open ended tasks: Plan yourself, be creative.

Trying too hard can be harmful. Repeating some action back and forth or pushing for 
a complex procedure with little knowledge can cause unwanted results. User would rather 
you complete the task with a fail.
```
