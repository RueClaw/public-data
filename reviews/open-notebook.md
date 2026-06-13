# Open Notebook (lfnovo/open-notebook)

**Repo:** https://github.com/lfnovo/open-notebook
**License:** MIT
**Reviewed:** 2026-06-07
**Checked:** 2026-06-13
**Stack:** Python 3.11/3.12, FastAPI, LangChain/LangGraph, SurrealDB, Next.js, React 19, TypeScript, Tailwind, Docker
**What it is:** Open Notebook is a self-hosted, privacy-focused NotebookLM alternative with multi-provider AI support, document/source ingestion, full-text and vector search, contextual chat, transformations, notes, API access, and multi-speaker podcast generation.

---

## Update Notes

Checked on 2026-06-13 against current HEAD `d39af076605171bc5ef51441e20e2842af6618e4` / version 1.9.0. Prior review/check-in was 2026-06-07 against `327d766e2ad2c86afe39eca5473b1441c6b2d749`.

Material changes since the prior check-in:

- Security/dependency patching continued: Starlette/FastAPI were bumped for CVE-2026-48710, and `aiohttp` and `tornado` were bumped.
- Podcast generation got a real `Notebook.get_context()` path that fetches full source text and note content instead of handing podcast workflows a thin notebook object.
- PUT handlers for speaker and episode profiles now use `model_dump(exclude_unset=True)`, reducing accidental overwrite behavior on partial profile updates.
- Turkish UI localization was added, along with a Contributor Covenant code of conduct and issue-first contribution guidance.
- `scripts/export_docs.py` now generates a table of contents in consolidated doc exports.
- Validation refreshed on current HEAD: backend `uv run pytest -q` passed 163 tests; frontend `npm test` passed 33 tests; `npm run lint` has 0 errors / 12 warnings; `npm audit --omit=dev` reports 2 moderate advisories; full `npm audit` reports 9 advisories, including 3 high-severity dev-toolchain advisories.

Checked on 2026-06-07 against current HEAD `327d766e2ad2c86afe39eca5473b1441c6b2d749` / version 1.9.0. Prior review was 2026-05-24 against `24892ac`.

Material changes:

- 1.9.0 added or surfaced more audio/provider capabilities through Esperanto 2.21-2.22: Mistral Voxtral STT/TTS, Deepgram TTS, xAI TTS, Google STT/TTS, Vertex TTS, ElevenLabs STT, and OpenRouter embeddings.
- Ollama credentials now support a per-credential `num_ctx` override, while the default Ollama context window dropped to 8192 to avoid consumer-GPU OOMs.
- Embedding robustness improved with `OPEN_NOTEBOOK_EMBEDDING_BATCH_SIZE` and `OPEN_NOTEBOOK_MIN_CHUNK_SIZE`, plus fixes for degenerate tiny chunks and null embeddings from stricter/local providers.
- Docs grew materially: Windows native installation, external Ollama setup, provider matrix refresh, and new Polish/Catalan UI locales.
- Validation on current HEAD passed: backend `uv run pytest -q` 158 passed; frontend `npm test` 32 passed; `npm run lint` 0 errors / 12 warnings; `npm ci` still reports 6 advisories, 1 low and 5 moderate.

## Verdict

✅ **Deploy candidate for local or hardened self-hosted research workflows.** Open Notebook is active, well-documented, MIT-licensed, and substantially more complete than most NotebookLM-style clones. The June 13 changes improve security posture and fix a real podcast-context gap without changing the core adoption call. The main caution is still deployment and dependency hygiene: authentication is disabled unless OPEN_NOTEBOOK_PASSWORD is set, the API defaults CORS to wildcard for backward compatibility, Docker examples expose SurrealDB and the API locally, and the frontend dependency tree still reports audit advisories.

---

## What It Is

Open Notebook is a research workspace for collecting sources, organizing notebooks, asking questions over selected context, extracting insights, writing notes, and generating audio/podcast outputs. It targets users who want the NotebookLM workflow without being locked to Google-hosted data or Google-only models.

The project supports a broad provider matrix through the Esperanto library, including OpenAI, Anthropic, Google, Vertex AI, Groq, Ollama, LM Studio/OpenAI-compatible endpoints, Mistral, DeepSeek, Voyage, ElevenLabs, Azure OpenAI, xAI, OpenRouter, DashScope, MiniMax, and Deepgram for supported audio paths. It also supports fully local setups through Docker Compose examples with Ollama and related services.

The strongest product idea is context control. Open Notebook distinguishes notebooks, sources, notes, transformations, chat, and ask/RAG flows so users can decide which source material is sent to a model, which stays out of context, and which is represented through summaries or retrieved chunks.

## Stack

| Layer | Tech |
|-------|------|
| API | FastAPI, Pydantic, Uvicorn |
| AI orchestration | LangChain, LangGraph, Esperanto, ai-prompter |
| Data store | SurrealDB plus SQLite LangGraph checkpoints |
| Frontend | Next.js, React 19, TypeScript, Tailwind, Radix UI |
| Search/RAG | Full-text and vector search over ingested sources |
| Content ingestion | content-core for URLs, documents, audio/video, and extracted text |
| Deployment | Docker Compose, single-container image, source install |
| Tests | Pytest, Vitest, ESLint |

## Key Features

### Multi-Provider AI Without Hard Lock-In

Open Notebook separates model/provider credentials from notebook content and lets users register models after connection testing. That supports private/local models for sensitive work and paid cloud providers when quality or modality support matters. In 1.9.0, this matrix expanded most visibly around audio and OpenRouter embeddings.

### Explicit Research Object Model

The domain model separates notebooks, sources, notes, insights, transformations, models, credentials, and podcast profiles. This gives the product cleaner boundaries than a single "upload files and chat" interface.

### User-Controlled Context

The docs describe different context modes: chat can include selected full content, while ask/RAG retrieves relevant chunks. The context builder supports source and note inclusion levels, token limits, deduplication, and prioritization. This is a useful privacy and cost-control pattern.

### Credential Storage With Field-Level Encryption

Provider API keys are stored as encrypted credential records using Fernet-derived symmetric encryption. The encryption key is required for credential storage and can be supplied through environment variables or Docker secrets.

### Podcast and Audio Workflows

The app goes beyond text Q&A by generating multi-speaker podcast episodes from research material. That makes it useful for turning dense research into reviewable audio, especially when paired with local or low-cost speech models. The 1.9.0 release improves the audio provider surface and makes STT connection tests use a real bundled speech clip instead of silence.

## Architecture

Open Notebook is split into a Python backend, a Next.js frontend, and a SurrealDB database:

- api/ contains FastAPI routers and service layers.
- open_notebook/domain/ contains persistent domain objects.
- open_notebook/graphs/ contains LangGraph workflows for source processing, transformations, chat, and ask flows.
- open_notebook/ai/ handles model discovery, provisioning, credentials, and connection testing.
- frontend/src contains the dashboard UI, settings, notebooks, source management, notes, chat, and tests.
- prompts/ keeps Jinja templates for ask, chat, podcast, and source-chat flows.
- docker-compose.yml starts SurrealDB plus the Open Notebook image.

Security-sensitive design choices are visible in the codebase: API keys are encrypted at rest, link-local metadata URLs are blocked in provider URL validation, Docker secrets are supported, and the changelog documents recent fixes for template injection, path traversal, local file inclusion, and SurrealDB injection.

The deployment defaults need care. Authentication is optional and disabled when OPEN_NOTEBOOK_PASSWORD is absent. CORS defaults to wildcard unless CORS_ORIGINS is set. The quick-start Docker Compose uses placeholder encryption and database credentials that must be changed before any non-local deployment.

## Verification

Validation run against current HEAD `d39af07`:

- Python backend tests: 163 passed, 8 warnings.
- Frontend tests: 33 passed.
- ESLint: 0 errors, 12 warnings.
- npm audit, production only: 2 moderate advisories via Next/PostCSS.
- npm audit, full tree: 9 advisories, 1 low, 5 moderate, 3 high. High advisories are in the dev-toolchain path through esbuild/Vite/@vitejs/plugin-react.
- Secret scan found documented placeholders and example credentials only, not obvious live secrets.

## Comparison

| Aspect | Open Notebook | Google NotebookLM | Local NotebookLM-style scripts |
|--------|---------------|-------------------|--------------------------------|
| Hosting | Self-hosted/local/cloud | Google-hosted | Usually local |
| Model choice | Broad multi-provider + local options | Google models | Varies, often narrow |
| API access | Full REST API | Limited/no public equivalent | Usually minimal |
| Context control | Explicit source/note/context controls | Product-managed | Often ad hoc |
| Audio generation | Multi-speaker podcast profiles | Fixed product workflow | Usually absent |
| Ops burden | User manages database, keys, auth, updates | Hosted | Low to medium |

## Self-Hosting Notes

Use Docker Compose for the fastest path, but change the quick-start defaults before exposing it beyond localhost:

- Set OPEN_NOTEBOOK_ENCRYPTION_KEY to a strong secret and back it up securely.
- Set OPEN_NOTEBOOK_PASSWORD for any shared, LAN, or public deployment.
- Set CORS_ORIGINS to the actual frontend origin in production.
- Change default SurrealDB credentials if the database port is exposed or reused.
- Prefer reverse proxy TLS and avoid publishing SurrealDB directly.
- Run npm audit and dependency updates as part of routine maintenance.

---

**Attribution:** lfnovo/open-notebook, MIT License.
