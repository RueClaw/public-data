# Claude Code Controller Orchestration

> **Source:** [pacholoamit/claude-code-controller](https://github.com/pacholoamit/claude-code-controller)
> **License:** MIT
> **Description:** Spawn, orchestrate, and control real Claude Code agents programmatically via REST API, TypeScript SDK, or Web Dashboard.

## Overview

Claude Code Controller runs **real Claude Code processes** — not API wrappers. The same Claude Code you use in your terminal, controllable from code or a dashboard.

## Why Real Processes Matter

- **Uses your Claude Code subscription** — No separate API key, no usage-based billing
- **Day 0 features** — When Anthropic ships new features, you get them immediately
- **Full tool access** — Bash, Read, Write, Edit, Glob, Grep, WebSearch, Task sub-agents
- **Real terminal environment** — Agents run in a PTY with your actual project directory
- **Battle-tested agent loop** — Claude Code's production-hardened agent loop

## API Architecture

### REST API

```typescript
// Create a new agent
POST /api/agents
{
  "workingDir": "/path/to/project",
  "model": "claude-sonnet-4-20250514"
}

// Send a message
POST /api/agents/:id/messages
{
  "content": "Implement user authentication"
}

// Stream responses
GET /api/agents/:id/stream

// Approve/reject tool use
POST /api/agents/:id/approve
POST /api/agents/:id/reject
```

### TypeScript SDK

```typescript
import { ClaudeCodeController } from 'claude-code-controller';

const controller = new ClaudeCodeController();

// Spawn an agent
const agent = await controller.spawn({
  workingDir: '/path/to/project',
  model: 'claude-sonnet-4-20250514',
});

// Send a message and stream response
const stream = agent.sendMessage('Add OAuth login to the app');

for await (const event of stream) {
  if (event.type === 'tool_use') {
    // Approve or reject tool use
    await agent.approve(event.id);
  }
  if (event.type === 'text') {
    console.log(event.content);
  }
}

// Clean up
await agent.stop();
```

### Web Dashboard

Visual interface for:
- Spawning agents
- Sending messages
- Approving tool use
- Monitoring multiple agents

## Agent Lifecycle

```
spawn → running → [pause/resume] → stop
```

Each agent:
- Runs in its own PTY
- Has isolated context
- Can be paused/resumed
- Supports streaming output

## Multi-Agent Orchestration

Run multiple agents concurrently:

```typescript
// Spawn agents for different tasks
const agents = await Promise.all([
  controller.spawn({ workingDir: '/project/frontend' }),
  controller.spawn({ workingDir: '/project/backend' }),
  controller.spawn({ workingDir: '/project/tests' }),
]);

// Coordinate their work
await agents[0].sendMessage('Build the login form');
await agents[1].sendMessage('Add the auth API endpoints');
await agents[2].sendMessage('Write integration tests for auth');
```

## Tool Approval Flow

When agents need to use tools:

1. Agent requests tool use (e.g., file write, bash command)
2. Controller emits `tool_use` event
3. Your code approves or rejects
4. Agent proceeds or handles rejection

```typescript
stream.on('tool_use', async (event) => {
  if (event.tool === 'write' && event.path.includes('config')) {
    // Auto-approve config file writes
    await agent.approve(event.id);
  } else {
    // Manual review for other writes
    const approved = await promptUser(event);
    if (approved) {
      await agent.approve(event.id);
    } else {
      await agent.reject(event.id, 'User declined');
    }
  }
});
```

## Key Design Principles

- **Real processes, not wrappers** — Full Claude Code capabilities
- **Subscription-based** — Uses your Max plan, no extra billing
- **REST + SDK + UI** — Multiple integration options
- **Stream everything** — Real-time output and events
- **Approval gates** — Control when tools can execute
