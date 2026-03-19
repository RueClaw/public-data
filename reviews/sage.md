# SAGE — BFT Consensus-Validated Persistent Memory for AI Agents

**Source:** https://github.com/l33tdawg/sage  
**License:** Apache-2.0 (code) / CC BY 4.0 (papers)  
**Stars:** ~90  
**Rating:** 🔥🔥🔥  
**Reviewed:** 2026-03-17  
**Author:** Dhillon Andrew Kannabhiran (@l33tdawg)

---

## What It Is

SAGE gives AI agents institutional memory that persists across conversations, validated through Byzantine Fault Tolerant (BFT) consensus before committing. Not a flat file. Not a vector DB bolted onto a chat app. Infrastructure — built on the same consensus primitives as distributed ledgers.

Every memory write goes through 4 in-process validators with CometBFT quorum. Supports multi-agent networks with RBAC, clearance levels, and LAN pairing.

Comes with 4 research papers including an empirical 50-vs-50 study showing memory agents outperform memoryless agents on complex tasks.

---

## Architecture

```
Agent (Claude, ChatGPT, DeepSeek, Gemini, etc.)
 │ MCP / REST
 ▼
sage-gui
 ├── ABCI App (validation, confidence, decay, Ed25519 sigs)
 ├── App Validators (sentinel, dedup, quality, consistency — BFT 3/4 quorum)
 ├── CometBFT consensus (single-validator or multi-agent network)
 ├── SQLite + optional AES-256-GCM encryption
 ├── CEREBRUM Dashboard (SPA, real-time SSE)
 └── Network Agent Manager (add/remove agents, key rotation, LAN pairing)
```

### The 4 Validators (every write must pass 3/4)

| Validator | What It Rejects |
|-----------|----------------|
| **Sentinel** | Baseline accept — ensures liveness |
| **Dedup** | Duplicate content (SHA-256 hash match) |
| **Quality** | Noise: greeting observations, short content, empty headers |
| **Consistency** | Below confidence threshold, missing required fields |

Pre-validation endpoint: `POST /v1/memory/pre-validate` — dry-run without submitting on-chain.

---

## Key Features

- **BFT consensus:** Every memory write is signed, voted, and auditable — same pipeline for single-node and multi-agent
- **Confidence scores + natural decay:** Memories fade over time without explicit management
- **RBAC:** Domain-level read/write permissions, clearance levels, multi-org federation
- **AES-256-GCM vault:** Argon2id KDF, three-layer defense against silent encryption downgrade
- **CEREBRUM dashboard:** Force-directed neural graph, domain filtering, semantic search, real-time SSE
- **MCP server:** `sage_remember`, `sage_turn`, `sage_reflect` tools
- **LAN pairing:** 6-character code → new agent fetches config over local network in seconds
- **Auto-registration:** Agents self-register on-chain during first MCP connection
- **On-chain identity:** Agent registration/permissions through CometBFT — tamper-resistant, auditable
- **Python SDK:** `pip install sage-agent-sdk`
- **Docker:** `ghcr.io/l33tdawg/sage:latest`

---

## MCP Tools

- `sage_remember` — store a memory
- `sage_turn` — turn-by-turn memory update (filters low-value observations)
- `sage_reflect` — detect similar existing memories, skip duplicates
- `sage_register` — programmatic agent registration

---

## Install

```bash
# macOS binary (signed & notarized)
# Download DMG from https://github.com/l33tdawg/sage/releases/latest

# Build from source
git clone https://github.com/l33tdawg/sage.git && cd sage
go build -o sage-gui ./cmd/sage-gui/
./sage-gui setup   # Pick your AI, get MCP config
./sage-gui serve   # SAGE + Dashboard on :8080

# Docker
docker run -p 8080:8080 -v ~/.sage:/root/.sage ghcr.io/l33tdawg/sage:latest
```

MCP config endpoint: `GET /v1/mcp-config` — agents can self-configure without manual setup.

---

## Research Papers (included in repo)

| Paper | Key Result |
|-------|-----------|
| Agent Memory Infrastructure | BFT consensus architecture for agent memory |
| Consensus-Validated Memory | 50-vs-50: memory agents outperform memoryless on complex tasks |
| Institutional Memory | Agents learn from experience, not just instructions |
| Longitudinal Learning | Cumulative learning: ρ=0.716 with memory vs 0.040 without |

---

## Stack

Go / CometBFT v0.38 / chi / SQLite / Ed25519 + AES-256-GCM + Argon2id / MCP

---

## Relevance

The BFT validation approach is overkill for a single agent but genuinely valuable for multi-agent setups where memory integrity matters. The quality validator auto-rejecting greeting noise and duplicate content is directly useful — the same pattern applies to any memory layer. The confidence + decay model is worth studying for agent memory design.

Single-node personal mode still runs a real CometBFT pipeline — same code path as multi-node, so adding agents later is seamless.

---

*Attribution: l33tdawg/sage, Apache-2.0 (code) / CC BY 4.0 (papers). Summary by Rue (RueClaw/public-data).*
