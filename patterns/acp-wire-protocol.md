# ACP (Agent Communication Protocol) Wire Pattern

> **Source:** [workflows-acp](https://github.com/AstraBert/workflows-acp) by AstraBert
> **License:** MIT
> **Extracted:** 2026-02-10

## Pattern

Expose any LlamaIndex Workflow as a network-accessible agent using the Agent Communication Protocol (ACP). The agent handles session management, streaming events, tool permissions, and model selection over a standardized wire format.

## Architecture

```
  Client (IDE, CLI, other agent)
        │
        │  ACP Protocol (JSON over HTTP/WebSocket)
        │
  ┌─────▼──────────────────┐
  │  AcpAgentWorkflow      │
  │  ├─ Session management │
  │  ├─ Permission handling│
  │  ├─ Event streaming    │
  │  └─ Tool orchestration │
  └─────┬──────────────────┘
        │
  ┌─────▼──────────────────┐
  │  LlamaIndex Workflow   │
  │  (your actual logic)   │
  └────────────────────────┘
```

## Key Concepts

### Session Lifecycle
1. **`initialize`** — negotiate capabilities and protocol version
2. **`new_session`** — create a session with cwd and MCP servers
3. **`prompt`** — send content blocks, receive streaming events
4. **`fork_session`** / **`resume_session`** — branch or continue
5. **`cancel`** — abort a running prompt

### Event Streaming
During `prompt`, the agent streams typed events back to the client:

| Event | Purpose |
|-------|---------|
| `ThinkingEvent` | Internal reasoning (shown as thought bubbles) |
| `PromptEvent` | Agent's text output |
| `ToolCallEvent` | Starting a tool call (shows pending status) |
| `ToolResultEvent` | Tool call completed |
| `ToolPermissionEvent` | Asks client for permission before executing |

### Permission Modes
Two modes for tool execution:
- **`ask`** — pause and request client permission before each tool call
- **`bypass`** — execute tools without asking

### MCP Integration
The agent can consume MCP (Model Context Protocol) servers, combining their tools with built-in ones. MCP servers are configured via `.mcp.json` or passed at session creation.

## Minimal Implementation

To expose your own workflow over ACP:

1. **Subclass `Agent`** and implement the protocol methods (`initialize`, `new_session`, `prompt`, etc.)
2. **In `prompt`**, run your workflow and stream events via `self._conn.session_update()`
3. **Call `run_agent(agent)`** to start the ACP server

```python
from acp import Agent, run_agent

class MyAgent(Agent):
    async def prompt(self, prompt, session_id, **kwargs):
        # Run your workflow
        # Stream events via self._conn.session_update()
        # Return PromptResponse(stop_reason="end_turn")
        ...

await run_agent(agent=MyAgent())
```

## Why This Matters

- **Interoperability** — any ACP-compatible client can talk to any ACP agent
- **Streaming** — real-time visibility into agent thinking and tool use
- **Permission model** — humans stay in the loop for sensitive operations
- **Session state** — agents maintain conversation context across prompts
- **Composability** — agents can be clients of other agents
