# PentAGI — Repo Review

**Repo:** https://github.com/vxcontrol/pentagi  
**License:** MIT  
**Language:** Go (backend) + React/TypeScript (frontend)  
**Stars:** ~trendshift listed  
**Cloned:** ~/src/pentagi  
**Rating:** 🔥🔥🔥🔥

---

## What It Is

Autonomous penetration testing platform. You give it a target and a task; it plans, delegates to specialist subagents, runs tools inside Docker sandboxes, stores findings in a vector memory (pgvector), and produces a vulnerability report. Full web UI, REST + GraphQL APIs, Grafana/Langfuse observability stack.

Not a toy. This is ~200K lines of Go, serious production architecture.

---

## Architecture

### Multi-Agent Hierarchy

14 named agent types (from `MsgchainType` enum):

| Agent | Role |
|---|---|
| `primary_agent` | Orchestrator — decomposes task, delegates |
| `pentester` | Core attacker agent |
| `researcher` | OSINT, web intel |
| `coder` | Exploit/tool development |
| `installer` | Environment setup |
| `adviser` | Strategic guidance |
| `memorist` | Memory retrieval specialist |
| `searcher` | Search queries |
| `refiner` | Output refinement |
| `reflector` | Self-critique / retry |
| `enricher` | Context enrichment |
| `generator` | Content generation |
| `summarizer` | Report compression |
| `tool_call_fixer` | Repairs malformed tool calls |
| `reporter` | Final report generation |
| `assistant` | User-facing conversational interface |

Primary agent decomposes → tasks → subtasks → specialist agents execute in Docker containers with the full pentest toolkit (nmap, metasploit, sqlmap, 20+ tools).

### Memory Stack

Two-layer:
1. **pgvector** — per-flow vector store, threshold 0.2, 3-result default. Semantic search over findings.
2. **Graphiti** — Neo4j knowledge graph. Semantic relationship tracking across runs. BFS traversal for context.

### Tool Execution

All tool calls run inside Docker containers. Smart container selection — picks image based on task requirements. Terminal context maintained across tool calls (stateful sessions). Full command + output logged to PostgreSQL.

### LLM Provider Agnosticism

10+ providers: OpenAI, Anthropic, Google/Gemini, AWS Bedrock, Ollama, DeepSeek, GLM, Kimi, Qwen, custom. Plus aggregators (OpenRouter, DeepInfra). Uses vxcontrol's langchaingo fork.

**Key engineering detail:** `DetermineToolCallIDTemplate` — detects each provider's tool call ID format at runtime via sampling + AI pattern recognition, caches per provider. Handles the fact that different providers use different ID schemes for tool calls. Smart defensive engineering.

### Observability

- Langfuse: every agent turn, span, tool call traced
- Prometheus + Grafana: system metrics
- Full agent log stored in PostgreSQL (initiator + executor + task + result per entry)

---

## What's Interesting for Us

### 1. Tool Call Fixer Agent
Dedicated `tool_call_fixer` agent that repairs malformed tool calls from other agents. Instead of crashing on bad tool call format, it routes to a repair agent that fixes the JSON and retries. This is the right pattern for Ollama models that don't always produce clean tool call syntax.

### 2. Reflector + Refiner Pattern
`reflector` critiques its own output; `refiner` improves it. Two separate agents for self-improvement loop, logged separately so you can observe the quality delta. Cleaner than putting both in the primary agent loop.

### 3. Docker Sandbox Isolation
Every tool execution is fully sandboxed. The primary agent never touches the host. Clean security boundary. Reference for anything we build that runs untrusted code (Marcos's agent environment, future eval setups).

### 4. Graphiti Integration
First real production use of Graphiti I've seen in a Go codebase. Their client is at `pkg/graphiti/client.go`. Worth studying if we ever add graph memory to Marcos's agent.

### 5. Execution Monitoring Flag
Tasks have an optional `execution_monitoring` flag — when set, human stays in loop for approval before each tool execution. Clean "human in the loop" pattern we should borrow for any agentic work touching production systems.

---

## What's Not Interesting for Us

- Metasploit/nmap/sqlmap tooling — obviously not relevant
- The web UI is fine but not differentiated
- Sploitus search integration (CVE/exploit db) — pentest-specific
- Multi-user/multi-flow database model — overkill for our scale

---

## Caveats

- Requires Docker + PostgreSQL + pgvector + Neo4j to run. Heavy stack.
- No ARM64 Docker images mentioned — might need to build for Rue/opi6
- Graphiti (Neo4j) is the expensive dependency; can swap for SQLite-based graph if needed
- EULA.md exists alongside MIT LICENSE — read carefully before any commercial use (EULA may add restrictions on top of MIT)

---

## Verdict

Solid production-grade multi-agent orchestration architecture in Go. The agent type taxonomy (14 specialist types), tool call repair pattern, and two-layer memory (pgvector + knowledge graph) are worth studying directly. Not something we'd run as-is (pentest tooling isn't our domain), but the architecture patterns are extractable.

**Extract to public-data:** tool_call_fixer pattern, reflector+refiner loop, execution monitoring flag design — these are general enough to document as agent patterns.

---

*Source: https://github.com/vxcontrol/pentagi | License: MIT (+ EULA.md — check before commercial use) | Reviewed: 2026-03-21*
