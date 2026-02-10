# OpenClaw Architecture Guide

> **Source:** [djmango/explain-openclaw](https://github.com/djmango/explain-openclaw)
> **License:** No explicit license (educational use only)
> **Description:** Comprehensive beginner + technical guide to the OpenClaw agent framework. Covers architecture, deployment, security, and optimization.

## What is OpenClaw?

OpenClaw is a framework for running a **personal AI assistant** on hardware you control.

### The One-Sentence Mental Model

> **OpenClaw is a self-hosted Gateway that connects chat apps to an agent that can reason and (optionally) act.**

## Architecture Components

### 1. Gateway — "Your assistant's home base"

Long-running process that:
- Receives inbound messages from chat platforms (channels)
- Decides what should happen (routing + policy)
- Runs the agent turn (calls your model provider)
- Sends responses back to the same chat platform
- Stores local state (config, credentials, session logs)

### 2. Channels — "Phone lines" into the assistant

Normalize messaging platforms into common events:
- WhatsApp (via WhatsApp Web / Baileys)
- Telegram (Bot API)
- Discord
- iMessage (macOS integration)
- Plus plugins for many more

### 3. Sessions — "Conversation memory"

A session is a conversation thread with state:
- Chat history (transcripts)
- Metadata (who/where it came from)
- Optional memory indexes

Sessions live on disk under `~/.openclaw/`.

### 4. Agent — "The brain"

Where your AI model is actually called. OpenClaw supplies:
- System prompt templates
- History/context
- Safety wrappers
- Tool availability rules

### 5. Tools — "Hands" (powerful; risky)

Let the model do more than output text:
- Web fetch/search
- Browser automation
- Cron/automation
- Exec or node/device invocations

**Tools are where most real-world risk comes from.**

### 6. Nodes/Devices — "Peripherals"

Devices that connect to Gateway for local capabilities:
- Camera
- Audio input
- Canvas/webviews
- (on macOS) Remote execution with approvals

## Deployment Options

### Standalone Mac Mini

Full local control. Best for:
- Maximum privacy
- Device-local tools (camera, audio)
- Personal assistant

### Isolated VPS

Always-on with minimal risk. Best for:
- 24/7 availability
- Text-only channels
- Reduced attack surface

### Cloudflare Moltworker

Serverless at the edge. Best for:
- Scale
- Low latency globally
- Minimal infrastructure

### Docker Model Runner

Local model inference. Best for:
- Complete privacy
- No external API calls
- Development/testing

## Security Posture

### Beginner-Safe Starting Posture

1. Keep Gateway **loopback-only** (localhost)
2. Use **pairing** and/or **allowlists** (only you can trigger it)
3. Avoid enabling powerful tools until comfortable
4. Run `openclaw security audit --deep` and fix findings

### Threat Model Categories

- **Channel security** — Who can message your agent?
- **Tool security** — What can your agent do?
- **Data security** — What can your agent access?
- **Model security** — What does the model provider see?

## Cost & Token Optimization

### Model Recommendations by Function

| Function | Recommended Model |
|----------|-------------------|
| Simple routing | Haiku |
| Complex reasoning | Sonnet |
| Critical decisions | Opus |
| Tool use | Sonnet or better |

### Token Optimization

- Trim history aggressively
- Summarize long conversations
- Use context caching where available
- Batch similar requests

## What OpenClaw is Great For

### Personal/Small-Team Assistant in Chat

- "Summarize the last 200 messages in this group"
- "Draft a reply in my tone"
- "Keep track of ongoing tasks"

### Private Assistant with Your Own Policies

Because you control the Gateway:
- Who can talk to it
- What it can do
- Where it can reach

### Always-On Agent Host

VPS or home server keeps Gateway running even if your laptop sleeps.

## What OpenClaw is NOT

### Not Automatically Safe for Public Bots

If you open inbound DMs/groups to the public AND enable tools, you've built a remote-controlled automation engine.

### Not "Privacy Magic"

OpenClaw keeps state locally, but your model provider still receives prompts for inference (unless you run a local model).

## Key Design Principles

- **Self-hosted by default** — You control the infrastructure
- **Channel-agnostic** — Same agent, multiple platforms
- **Session-based memory** — Persistent conversation state
- **Tool-gated capabilities** — Explicit control over what agent can do
- **Security by configuration** — Safe defaults, explicit opt-in for power
