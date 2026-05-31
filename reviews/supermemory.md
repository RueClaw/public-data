# supermemory (supermemoryai/supermemory)

**Repo:** https://github.com/supermemoryai/supermemory  
**License:** MIT, with hosted service and enterprise self-hosting packaging separate from the open repository  
**Reviewed:** 2026-05-30  
**Stack:** TypeScript, Bun, Turbo, Next.js, OpenNext Cloudflare, Hono, Cloudflare Workers/Durable Objects, Better Auth, Drizzle, Postgres/pgvector, React, Python SDK packages  
**What it is:** A memory and context platform for AI agents, with a hosted app/API, MCP server, framework SDKs, browser and Raycast extensions, memory graph visualization, docs, and agent-client integrations.

---

## Verdict

✅ **Deploy candidate, with sensitive-infrastructure caveats.** `supermemory` is highly relevant, active, MIT-licensed, and unusually broad in integration coverage: MCP, SDK wrappers, agent plugins, browser/Raycast surfaces, memory graph UI, and hosted API workflows all point at the same memory layer. It is not a casual drop-in self-hosted backend, though. Treat it as privacy-sensitive infrastructure and review prompt-injection, extension-token, CI-agent, telemetry, and retention boundaries before storing sensitive memories.

---

## What It Is

`supermemory` positions itself as a "memory and context engine" for AI systems. The core product stores user and project memories, extracts profiles, searches context, and exposes that context back to agents through APIs, MCP tools, SDK integrations, and client apps.

The public monorepo includes the web app, MCP Worker, docs, browser extension, Raycast extension, memory graph package, multiple JavaScript and Python integration packages, and agent-client skill/plugin references. The main backend service is consumed as an API, and the self-hosting documentation indicates that full self-hosted deployment is currently packaged for enterprise customers rather than as a simple open clone-and-run path.

## Maturity

At review time, the repository had about 23k GitHub stars and 2k forks, was pushed on 2026-05-31 UTC, and had an MIT license in the root. The latest observed commit was `4eb8399` from 2026-05-30, "Enhance README with additional context on usage." There was no GitHub release attached through the API, so the active branch is the best current reference.

## Stack

| Layer | Tech |
|-------|------|
| Monorepo | Bun 1.3.x, Turbo, TypeScript |
| Web app | Next.js, OpenNext Cloudflare, React, Better Auth |
| MCP service | Hono, Cloudflare Workers, Durable Objects, `agents/mcp` |
| Data/API clients | Supermemory SDK, Drizzle, Postgres/pgvector-oriented backend surfaces |
| Agent integrations | MCP, AI SDK, OpenAI tool wrappers, Mastra, Voltagent, and agent-client plugin references |
| Client apps | Browser extension, Raycast extension, docs site, memory graph playground |
| Python integrations | OpenAI SDK helpers, Pipecat, Cartesia, Microsoft Agent Framework package |
| Observability | PostHog, Sentry, workflow logs |

## Key Features

### Memory, Recall, and Context

The clearest product primitive is a three-part memory surface:

1. `memory` saves or forgets facts.
2. `recall` searches prior memories and profile context.
3. `context` injects profile-style context into a model conversation.

The MCP server exposes those as tools, resources, and prompts. It also supports project/container scoping through tags, which is the right shape for separating memories by app, tenant, workspace, or task domain.

### Agent Integration Surface

The repo is valuable as an integration map. It provides packages and references for AI SDK, OpenAI-style function calling, Mastra, Voltagent, MCP clients, Claude Code-style agents, browser workflows, and Raycast. Even if someone does not adopt the hosted service, the repo is a useful survey of how durable memory gets packaged for modern agent runtimes.

### Memory Graph

The `@supermemory/memory-graph` package gives a visual graph surface for memories and relationships. That matters because memory systems need audit and inspection affordances. A raw vector search API is rarely enough once users need to understand why an agent remembers something.

### Connectors and Imports

The product documentation describes connectors for Google Drive, Gmail, Notion, OneDrive, GitHub, web crawling, and browser import flows. Those are powerful, but they also make the security model much more important because imported memories can contain private, stale, poisoned, or instruction-like content.

## Architecture Notes

The repository is a Bun/Turbo monorepo with apps and packages split cleanly:

- `apps/web` for the Cloudflare-deployed web app.
- `apps/mcp` for the MCP server and Durable Object agent.
- `apps/browser-extension` and `apps/raycast-extension` for client capture/import surfaces.
- `packages/tools` for memory tools and middleware.
- `packages/ai-sdk`, `packages/openai-sdk-python`, and other SDK packages for framework-specific integrations.
- `packages/memory-graph` for the React graph visualization package.
- `skills/supermemory` for agent-client instructions and references.

The MCP service is the most reusable architectural reference. It validates bearer tokens or OAuth sessions, derives an API key, passes scoped props into a Durable Object-backed MCP agent, and registers tools/resources/prompts around memory and profile operations.

The strongest pattern is the "memory gateway": durable memory is not just a database, but a tool surface with auth, schemas, project tags, profile composition, search, graph inspection, and SDK-specific adapters.

## Security and Privacy Notes

The security posture has good pieces, but it deserves a careful deployment review because memory is sensitive by definition.

Positive signals:

- MCP access is authenticated and validates API-key or OAuth-derived sessions before serving tools.
- Tool inputs use Zod schemas and practical size caps.
- Project/container tags provide a workable scoping boundary.
- Python Agent Framework utilities wrap memories as read-only data and explicitly warn the model not to follow instructions inside retrieved memories.
- Publishing workflows for packages use OIDC/trusted publishing patterns.

Caveats:

- The MCP app uses broad CORS (`*`) while relying on bearer auth. That is workable for MCP/client compatibility, but increases the importance of token handling and client isolation.
- The browser extension captures Twitter/X authorization, cookie, and CSRF headers from web requests to support imports. That is a high-trust feature and should require clear user consent, careful storage, and tight review before production use.
- The TypeScript tool prompt builder injects memory text without the same untrusted-memory delimiter seen in the Python Agent Framework helper. Retrieved memory should be treated as data, not instructions, in every SDK path.
- The web app config ignores TypeScript build errors. That may be practical for a fast-moving app, but it weakens CI confidence.
- Sentry replay and PostHog are used in a memory product. Those tools can be safe, but only with strict masking and retention discipline.
- Claude automation workflows have broad write-capable agent permissions in some paths. This is an interesting dogfooding pattern, but it raises the blast radius of compromised prompts, same-repo PRs, or overly broad tool use.

## Verification

Local checks performed on the reviewed checkout:

- `bun install --frozen-lockfile` passed.
- Scoped Turbo type checks for `@supermemory/ai-sdk` and `@supermemory/memory-graph` passed.
- `packages/memory-graph` test suite passed: 154 tests.
- Python package sources compiled successfully with `python3 -m compileall`.
- Python OpenAI SDK tests failed collection because the tests import stale package names.
- Python Agent Framework tests failed collection because `agent_framework` no longer exports the expected `BaseContextProvider` symbol.
- Pipecat Python package had no tests to run.
- Bun security audit could not be completed because Bun did not have a configured scanner for `bun pm scan`, and `bun pm audit` was not available in the installed Bun command set.

## Self-Hosting Notes

The repo is open and MIT-licensed, but the main product deployment is not presented as a simple community self-host path. The self-hosting docs describe an enterprise deployment package requiring Cloudflare Workers, Postgres with pgvector, LLM API keys, Resend, and optional connector configuration.

That makes the best adoption path:

1. Use the hosted API/app for evaluation with non-sensitive test data.
2. Review deletion/export/retention, connector, telemetry, and data-processing policies.
3. Use separate project/container tags for unrelated domains.
4. Add an untrusted-memory wrapper around retrieved context in any custom agent integration.
5. Treat full self-hosting as a commercial/enterprise conversation, not as a weekend Docker deployment.

## Comparison

Compared with simpler coding-agent memory projects, `supermemory` is broader and more productized: it covers app UI, hosted API, MCP, SDKs, connectors, and graph visualization. Compared with a generic RAG stack, it focuses on user/profile memory and fact evolution rather than only chunk retrieval. Compared with an enterprise knowledge base, it is more agent-native but also more exposed to prompt-injection, connector, and privacy risks.

## Best Extracted Pattern

The reusable pattern is an **agent memory gateway**:

- Durable memory store behind a dedicated API.
- Tool-level primitives for save, forget, recall, profile, and context injection.
- Project/container tags for scoped memory.
- MCP tools/resources/prompts plus SDK wrappers for multiple frameworks.
- Graph inspection for memory auditability.
- Explicit treatment of retrieved memories as untrusted data.

That pattern is worth copying even when the backing store, hosted service, or SDK choices differ.

---

**Attribution:** supermemoryai/supermemory, MIT License
