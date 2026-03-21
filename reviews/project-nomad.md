# Project N.O.M.A.D. — Repo Review

**Repo:** https://github.com/Crosstalk-Solutions/project-nomad  
**License:** Apache 2.0  
**Language:** TypeScript (AdonisJS v6 backend + Inertia.js frontend)  
**Rating:** 🔥🔥🔥

---

## What It Is

**Node for Offline Media, Archives, and Data** — a Docker-orchestrated self-hosted knowledge hub designed for offline-first / grid-down scenarios. One install script, everything containerized, accessible via browser with no desktop environment required.

Target use cases: disaster preparedness, field deployments, school labs with no internet, homesteads, grid-down contingency. Not an AI product — more of a "survival server" concept.

---

## What It Bundles

| Service | Purpose |
|---|---|
| Ollama | Local LLM inference |
| Qdrant | Vector DB for RAG over documents |
| Kiwix | Offline Wikipedia, medical refs, survival guides (ZIM format) |
| Kolibri | Khan Academy offline — courses, multi-user, progress tracking |
| ProtoMaps | Downloadable offline maps with search |
| CyberChef | Data encryption/encoding/analysis |
| FlatNotes | Local markdown note-taking |
| Built-in benchmark | Hardware scoring + community leaderboard |

The "Command Center" is a web UI (AdonisJS + Inertia.js + Tailwind) that manages all of these via Docker. One wizard for first-time setup.

---

## Architecture

- **Backend:** AdonisJS v6 (Node.js framework), TypeScript
- **Frontend:** Inertia.js (server-driven SPA, no separate API), Tailwind CSS
- **Containerization:** Docker Compose orchestration, everything in containers
- **RAG pipeline:** Ollama + Qdrant, document upload → semantic search → chat
- **No auth by default** — designed to be network-isolated; auth is a future consideration

Key services: `docker_service.ts`, `ollama_service.ts`, `rag_service.ts`, `zim_service.ts`, `download_service.ts`. Clean separation. Each external tool gets its own service class.

The ZIM handling (Kiwix format) has its own extraction service — somewhat interesting if you ever need to work with offline Wikipedia programmatically.

---

## What's Interesting for Us

Honestly, not much architecturally. The interesting thing is **the concept**:

- Offline-first, self-hosted, everything-in-Docker
- RAG over arbitrary documents works entirely on-device
- Zero telemetry by design
- Runs on modest hardware (4GB RAM minimum, 32GB+ optimal for LLMs)

The ZIM/Kiwix integration is the most niche interesting piece — offline Wikipedia with ~80GB+ of content available as downloadable packs. If we ever wanted offline reference capability for Marcos's agent (e.g., medical references that work without internet), that's the path.

**Community benchmark leaderboard** is a cute touch — submits hardware scores, gives your device a "Builder Tag". Helps users know what to expect on their hardware.

---

## What's Not Interesting

- AdonisJS is fine but not what we use (we're Next.js/FastAPI)
- The Docker orchestration is basic — just Compose files, no novel patterns
- No agent orchestration, no multi-agent, no memory beyond RAG
- Inertia.js is an unusual choice (server-rendered SPA) that would be confusing to port patterns from

---

## Verdict

Solid project for its niche — offline survival knowledge server. Concept > implementation for us. The value is understanding what "offline-first AI" means at the homelab level, and noting that Kiwix/ZIM is a real path to offline reference content (medical, encyclopedic) if we ever need that for Marcos.

Nothing here to extract to public-data; it's more of a "know this exists" entry.

---

*Source: https://github.com/Crosstalk-Solutions/project-nomad | License: Apache 2.0 | Reviewed: 2026-03-21*
