# openagents — Review

**Repo:** https://github.com/openagents-org/openagents  
**Author:** openagents-org  
**License:** Apache-2.0  
**Stars:** ~2,079  
**Rating:** 🔥🔥🔥🔥  
**Cloned:** ~/src/openagents  
**Reviewed:** 2026-03-31

---

## What it is

OpenAgents is a multi-layer platform for running and coordinating AI coding agents across machines. It's grown from a Python SDK for agent networking into three distinct products:

1. **Workspace** — browser-based collaboration hub: shared threads, files, browser, @mentions between agents
2. **Launcher (`agn`)** — TUI/CLI daemon manager: install agent runtimes, configure credentials, connect to workspaces, keep agents alive as background processes
3. **Network SDK** — Python library for building event-driven multi-agent systems

The tagline: "One workspace where all your AI agents collaborate." The concrete problem it solves: you have agents running on different machines, in different terminals, and no unified view of what they're doing or way to make them coordinate.

---

## The three layers

### Launcher

The `agn` CLI is the most immediately useful piece. It's an interactive terminal dashboard (Textual TUI) that manages agent runtimes as a local daemon:

```bash
agn install openclaw          # install a runtime
agn create my-agent --type openclaw
agn env openclaw --set LLM_API_KEY=sk-...
agn up                        # start the daemon
```

Supported agents: **OpenClaw ✅, Claude Code ✅, Codex CLI ✅, Cursor ✅, OpenCode ✅**. Aider, Goose, Gemini CLI, Copilot, Amp all listed as "coming soon." Desktop app available for macOS/Windows/Linux as well.

The launcher handles: runtime installation, credential management, connecting agents to network workspaces, keeping them alive as persistent background processes, and exposing local dev servers as public tunnel URLs.

### Workspace

`workspace.openagents.org` — a persistent URL per workspace. Agents connect to it, humans can monitor and interact from any browser or phone. Shared context: same threads, same file store, same live browser that all agents (and humans) can operate.

The @mention model lets you pull specific agents into conversations. Agents can handoff work to each other through the shared thread context rather than via copy-pasting or SSH hops.

Self-hostable. The `deploy/` and `docker-compose.yml` suggest a reasonably self-contained deployment story.

### Network SDK (Python)

The SDK is the original core — event-driven networking for building custom multi-agent systems. Architecture:

- **`AgentNetwork`** — the central coordination hub. Takes a `NetworkConfig`, manages agent registrations, event routing, topology
- **Transport layer** — pluggable backends: HTTP, WebSocket, gRPC, MCP, A2A. Found in `src/openagents/sdk/transports/`
- **Topology abstraction** — network modes (star, mesh, etc.) abstracted via `create_topology()`
- **Mod system** — capability modules for communication, coordination, file sharing, browser control, games, workspaces. `src/openagents/mods/` with subdirs for each domain
- **A2A support** — Agent-to-Agent protocol (Google's standard) via `a2a_registry.py` and `a2a_task_store.py`
- **MCP server** — `mcp_server.py` exposes the network as an MCP tool server

Events are the primitive. Every agent interaction is an `Event` with `EventVisibility` — who can see it within the workspace. System events for register/unregister/poll. The `EventGateway` handles routing.

```python
from openagents.sdk.network import AgentNetwork
from openagents.models.network_config import NetworkConfig

network = AgentNetwork(config=NetworkConfig(...), workspace_path="./workspace")
```

---

## What's notable

**OpenClaw is a first-class citizen.** Not a secondary integration — it's listed first in the supported agents table. The launcher installs and manages OpenClaw the same way it manages Claude Code or Codex. The `agent-connector` package handles the bridge.

**A2A + MCP both supported.** The SDK implements both Google's A2A protocol and Model Context Protocol server mode. That's the right move for interoperability — covers both the Google/enterprise ecosystem and the Anthropic/tool-use ecosystem.

**Mods architecture.** The capability system (`mods/`) is genuinely well-structured: `communication/`, `coordination/`, `work/`, `workspace/`, `games/`, `integrations/`, `discovery/`. This is the hook for extending what agents can do together beyond basic messaging.

**Self-host story exists.** `docker-compose.yml` + `Dockerfile` + `deploy/` directory. The workspace isn't cloud-only.

**Tunnel built in.** `tunnel.py` — expose local dev servers as public URLs from inside the launcher. Useful for agent-built previews.

---

## Caveats

**2,079 stars but launched recently** (March 2025). The "Launch Week" announcement in the README and the partner logos suggest this is at the marketing push stage. The SDK core is more mature than the workspace product.

**Python SDK + TypeScript launcher** — the `packages/` directory has `agent-connector` (TypeScript) and `launcher` (TypeScript) alongside the Python SDK. The tech stack is split, which has integration surface implications.

**Workspace SaaS dependency** — while it's open source and self-hostable, the default flow uses `workspace.openagents.org`. Unknown what data transits through there.

**No auth model described** in the README. "No account required" is stated, but it's unclear what prevents anyone from joining a workspace URL they've discovered.

---

## Relevance to us

The Launcher is the most immediately interesting piece. If we want to run OpenClaw alongside Claude Code on different machines and have them coordinate through a shared workspace — this is built exactly for that. The `agn` daemon model matches what we've been building toward with OpenClaw heartbeats + watcher agents, but as an explicit multi-agent coordination layer.

The Network SDK's event architecture is worth studying as a reference pattern for any custom agent orchestration we build. The Mod system in particular — the idea of capability modules that agents opt into — maps cleanly onto OpenClaw's skill system.

The A2A + MCP dual-protocol support is the right call for interoperability. If we ever build agents that need to interact with non-OpenClaw systems, this is the integration layer.

Worth watching. The workspace product is new but the SDK core is real.

Source: Apache-2.0, openagents-org/openagents
