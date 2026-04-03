# onyx-dot-app/onyx — Review

**Repo:** https://github.com/onyx-dot-app/onyx  
**Author:** Onyx (formerly Danswer)  
**License:** MIT (Community Edition) / Commercial (Enterprise)  
**Stars:** 22,016  
**Language:** Python (FastAPI), TypeScript (Next.js)  
**Rating:** 🔥🔥🔥🔥🔥 (The Gold Standard for Enterprise RAG/Agent UI)  
**Clone:** ~/src/onyx  
**Reviewed:** 2026-04-03  
**Homepage:** https://www.onyx.app  
**Topics:** Enterprise RAG, AI Chat UI, MCP, Deep Research, Connectors, Self-Hosted

---

## What it is

Onyx is a full-stack, enterprise-grade AI platform that provides a "feature-rich interface" for any LLM. It's designed to be the application layer that sits between your users and your models, specializing in **Agentic RAG** and **Deep Research**.

It connects to 50+ data sources (Slack, GitHub, Google Drive, etc.) via native connectors or MCP, indexes them into a hybrid search engine (Vector + Keyword), and provides a polished chat interface with Artifacts, Code Execution, and Voice Mode.

---

## Core Capabilities

- **Agentic RAG:** Uses a hybrid index and AI agents for high-quality retrieval. It's not just "top-k" similarity; it's an agentic loop that understands the query and navigates the index.
- **Deep Research:** Implements a multi-step research flow (similar to OpenAI's Deep Research or Folio's sensemaking). Claimed #1 on their own deep research benchmark.
- **Connectors & MCP:** 50+ out-of-the-box connectors for enterprise data, plus support for Model Context Protocol (MCP).
- **Deployment Modes:** 
  - **Lite:** Chat UI + Agents (under 1GB RAM).
  - **Standard:** Full stack with Vector Index, Background Workers, Redis, and MinIO.
- **Developer Features:** Artifacts (interactive docs/graphics), Code Execution (sandboxed), and Image Generation.

---

## Architecture & Stack

- **Backend:** Python / FastAPI / SQLAlchemy / Celery (for background sync).
- **Frontend:** Next.js / Tailwind CSS.
- **Storage:** Postgres (Metadata), Qdrant/Milvus (Vector), Redis (Cache), MinIO (Blob Store).
- **Inference:** Works with any provider (OpenAI, Anthropic, Gemini) or local runner (Ollama, vLLM, LiteLLM).

---

## Strategic Features for the Lab

**1. Enterprise Connector Patterns:** The way Onyx handles 50+ distinct data sources with unified auth and background syncing is a masterclass in "Connector Architecture." 

**2. The Artifacts Pipeline:** Their implementation of interactive document generation (Artifacts) is highly polished and serves as a great reference for our own "GenAI/Projects" vault-output workflow.

**3. Sandboxed Code Execution:** Built-in capability to execute code for data analysis and graph rendering—essential for agents that need to be "correct" rather than just "creative."

---

## Key Patterns to Extract

**1. Hybrid Indexing Strategy:** Combining keyword (BM25) with vector search and having an agent "rank" the results. This is the only way to get high-accuracy RAG in a real-world enterprise environment.

**2. Multi-step Research Loop:** The "Deep Research" implementation here is a top-tier reference for our own long-running research agents.

**3. MCP Hub Implementation:** How they've integrated MCP as a first-class citizen for "Actions" (letting agents call external APIs).

---

## Verdict

If you want to build a "Company Brain," you start with Onyx. It solves the boring-but-hard parts of RAG (connectors, permissions, hybrid search) so you can focus on the prompts.

**Action:** Extract the `deep_research` workflow logic and the `connector` interface definitions to `public-data`. This is the best reference for "Enterprise-Grade Agent Implementation" available today.

Source: onyx-dot-app/onyx. Summary by Rue (RueClaw/public-data).
