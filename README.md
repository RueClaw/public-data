# public-data

Curated patterns, prompts, architectural ideas, and repo reviews extracted from publicly available AI projects.

## Publishing Policy

**What we share:**
- Summaries and useful parts of any publicly available code repository
- Full write-ups in `reviews/` for every repo reviewed
- Extracted patterns, prompts, and tools in their respective directories

**Attribution:**
- Every file includes source repo, author, and license
- Files with no license are marked clearly: "no license specified — educational/personal use only"
- We respect that authors chose to share publicly. We honor that by sharing our analysis publicly too, with attribution.

**License handling:**
- Apache-2.0, MIT, BSD, CC-BY → extract freely, include attribution
- AGPL/GPL → summarize and document patterns; do not embed in proprietary code
- No license → note explicitly; treat as educational/personal use only; do not redistribute code itself
- Always attribute: source repo, author, and license in each file

---

## Structure

- `reviews/` — Full write-ups of every repo reviewed (published with attribution)
- `prompts/` — System prompts, prompt templates, personality definitions
- `agents/` — Agent definitions, orchestration configs, loop architectures
- `patterns/` — Architectural patterns, best practices, reusable designs
- `tools/` — Useful scripts and utilities
- `notes/` — Research notes and analysis

---

## Reviews

Full write-ups of repos reviewed, with architecture summaries, key patterns, code examples, and relevance notes.

Repository tracking:
- [research-channel-repositories.md](reviews/research-channel-repositories.md) — GitHub repositories shared in the #research Discord channel, with review status and last review date.

| File | Source | License | Rating | Description |
|------|--------|---------|--------|-------------|
| [multica.md](reviews/multica.md) | [multica-ai/multica](https://github.com/multica-ai/multica) | source-available Apache-2.0-derived | ✅ Deploy candidate | Managed coding-agent workspace with web, desktop, mobile, daemon, cloud/local runtimes, squads, autopilots, and task lifecycle control |
| [activegraph.md](reviews/activegraph.md) | [yoheinakajima/activegraph](https://github.com/yoheinakajima/activegraph) | Apache-2.0 | ⚠️ Interesting | Event-sourced reactive graph runtime for auditable, replayable, forkable agent systems |
| [text-to-cad.md](reviews/text-to-cad.md) | [earthtojake/text-to-cad](https://github.com/earthtojake/text-to-cad) | MIT | ✅ Deploy candidate | Agent skill bundle for source-first CAD, robotics descriptions, geometry inspection, render review, and CAD project harnessing |
| [cal-diy.md](reviews/cal-diy.md) | [calcom/cal.diy](https://github.com/calcom/cal.diy) | MIT | ⚠️ Interesting | MIT-only self-hosted Cal.com fork for personal/non-production scheduling infrastructure |
| [noah-zender-ideas.md](reviews/noah-zender-ideas.md) | [Noah Zender Ideas](https://www.noahzender.com/ideas) | N/A | 📚 Good reference | Large index of short mental-model notes for product, AI, writing, markets, psychology, and leadership |
| [agent-governance-toolkit.md](reviews/agent-governance-toolkit.md) | [microsoft/agent-governance-toolkit](https://github.com/microsoft/agent-governance-toolkit) | MIT | 📚 Study | Microsoft public-preview runtime governance stack for AI agents: policy, identity, MCP security, audit, SRE, and compliance |
| [freellmapi.md](reviews/freellmapi.md) | [tashfeenahmed/freellmapi](https://github.com/tashfeenahmed/freellmapi) | MIT | ⚠️ Interesting | Local OpenAI-compatible proxy that aggregates free-tier LLM providers with key-aware fallback routing |
| [gait.md](reviews/gait.md) | Clyra-AI/gait | Apache-2.0 | 🔥🔥🔥 | Policy-as-code enforcement at the AI agent tool boundary |
| [sage.md](reviews/sage.md) | l33tdawg/sage | Apache-2.0 | 🔥🔥🔥 | BFT consensus-validated persistent memory for AI agents |
| [crucix.md](reviews/crucix.md) | calesthio/Crucix | AGPL-3.0 | 🔥🔥🔥🔥 | Self-hosted OSINT intelligence terminal, 27 sources |
| [flash-moe.md](reviews/flash-moe.md) | danveloper/flash-moe | **no license** | 🔥🔥🔥🔥🔥 | Pure C/Metal inference for 397B MoE on a 48GB MacBook |
| [claude-chromium-native-messaging.md](reviews/claude-chromium-native-messaging.md) | stolot0mt0m/claude-chromium-native-messaging | MIT | 🔥🔥 | Claude extension for non-Chrome Chromium browsers |
| [openalice.md](reviews/openalice.md) | TraderAlice/OpenAlice | AGPL-3.0 | 🔥🔥🔥🔥 | File-driven AI trading agent engine — UTA pattern, Trading-as-Git, guard pipeline, evolution mode |
| [the-library.md](reviews/the-library.md) | disler/the-library | MIT | 🔥🔥🔥🔥 | Meta-skill for private-first distribution of skills/agents/prompts across devices and teams |
| [supabase.md](reviews/supabase.md) | supabase/supabase | Apache-2.0 | ⭐⭐⭐⭐⭐ | Open-source Firebase alternative — Postgres, auth, realtime, edge functions, self-hostable |
| [citadel.md](reviews/citadel.md) | SethGammon/Citadel | MIT | 📚 Study | Agent orchestration OS for Claude Code — proportional routing, campaign persistence, fleet coordination |
| [ctx.md](reviews/ctx.md) | stevesolun/ctx | MIT | 📚 Study | Graph-backed recommendations for capped skill, agent, MCP, and harness context bundles |
| [decapod.md](reviews/decapod.md) | DecapodLabs/decapod | MIT | 📚 Study | Repo-local governance kernel for AI coding agents — intent, context, boundaries, proof |
| [nobulex.md](reviews/nobulex.md) | arian-gogani/nobulex | MIT | 📚 Study | Proof-of-behavior protocol for earned agent autonomy and Trust Capital |
| [photogimp.md](reviews/photogimp.md) | Diolinux/PhotoGIMP | GPL-3.0 | ✅ Deploy candidate | GIMP 3.0 profile patch that gives Photoshop users familiar shortcuts, layout, icons, and splash assets |
| [hermes-agent-control-room.md](reviews/hermes-agent-control-room.md) | shannhk/hermes-agent-control-room | MIT | 🔧 Harvest | Sidecar control room for VPS-hosted agent teams, runbooks, secret maps, task bus, and SOP skills |
| [ruflo.md](reviews/ruflo.md) | ruvnet/ruflo | MIT | 📚 Study | Claude Code orchestration platform with plugins, swarms, memory, federation, and signed verification witnesses |
| [vibe-coding.md](reviews/vibe-coding.md) | wanderloots-tutorials/vibe-coding | **no license** | 📚 Study | Tutorial notes with an agent-buildable Raw/Wiki/Schema knowledge workflow |
| [motus.md](reviews/motus.md) | lithos-ai/motus | Apache-2.0 | ⚠️ Interesting | Python agent serving/runtime framework with session APIs, task graph workflows, MCP/tools, and cloud deploy |
| [local-notebooklm.md](reviews/local-notebooklm.md) | Goekdeniz-Guelmez/Local-NotebookLM | Apache-2.0 | ⚠️ Interesting | Local NotebookLM-style PDF-to-audio app with CLI, FastAPI, Gradio, and Docker surfaces |
| [insforge.md](reviews/insforge.md) | [InsForge/InsForge](https://github.com/InsForge/InsForge) | Apache-2.0 | ⚠️ Interesting | Agent-native backend platform with Postgres, auth, storage, functions, MCP/CLI surfaces, and typed control-plane APIs |
| [audiblez.md](reviews/audiblez.md) | [santinic/audiblez](https://github.com/santinic/audiblez) | MIT | ⚠️ Interesting | Local EPUB-to-M4B audiobook generator using Kokoro TTS, chapter WAV intermediates, and ffmpeg packaging |
| [stainful.md](reviews/stainful.md) | [stainlu/stainful](https://github.com/stainlu/stainful) | MIT | 📚 Study | Local Stainless-compatible Python SDK generator with an IR-first pipeline and conformance-gated output |
| [deepsec.md](reviews/deepsec.md) | [vercel-labs/deepsec](https://github.com/vercel-labs/deepsec) | Apache-2.0 | ✅ Deploy candidate | Agent-powered vulnerability scanner with resumable per-file records, PR mode, revalidation, plugins, and sandbox workers |
| [codebase-reasoning-topology-gist.md](reviews/codebase-reasoning-topology-gist.md) | [acidgreenservers gist](https://gist.github.com/acidgreenservers/001185d63e5cd65f9fbe6f7a1c70a200) | **no license** | 📚 Good reference | Coding-agent prompt bundle for topology-first codebase reasoning and read-only reconnaissance |
| [9router.md](reviews/9router.md) | [decolua/9router](https://github.com/decolua/9router) | MIT | ⚠️ Interesting | Local AI router/dashboard for coding tools with provider fallback, quota tracking, translation, MITM/tunnel helpers, and RTK token compression |
| [agentmemory.md](reviews/agentmemory.md) | [rohitg00/agentmemory](https://github.com/rohitg00/agentmemory) | Apache-2.0 | ⚠️ Interesting | Persistent memory server for AI coding agents with hook capture, MCP/REST, hybrid retrieval, graph/lessons, privacy, audit, and retention |
| [html-anything.md](reviews/html-anything.md) | [nexu-io/html-anything](https://github.com/nexu-io/html-anything) | Apache-2.0 | ⚠️ Interesting | Local-first agentic HTML editor that drives coding-agent CLIs through skill templates, streaming preview, and platform-specific exports |

---

## Agents

| File | Source | Description |
|------|--------|-------------|
| [autoforge-two-agent-pattern.md](agents/autoforge-two-agent-pattern.md) | leonvanzyl/autoforge | Two-agent architecture for autonomous coding (initializer + coder) |
| [shannon-ai-pentester.md](agents/shannon-ai-pentester.md) | keygraphHQ/shannon | Autonomous AI pentester with Temporal orchestration |
| [antfarm-multi-agent-workflows.md](agents/antfarm-multi-agent-workflows.md) | snarktank/antfarm | Multi-agent workflows with YAML + SQLite + cron |
| [raptor-security-research-framework.md](agents/raptor-security-research-framework.md) | gadievron/raptor | Security research framework with progressive loading |
| [claude-code-controller-orchestration.md](agents/claude-code-controller-orchestration.md) | pacholoamit/claude-code-controller | Orchestrate real Claude Code processes via REST/SDK |
| [koda-architecture.md](agents/koda-architecture.md) | koda | Subagent spawning architecture |
| [monty-sandboxed-interpreter.md](agents/monty-sandboxed-interpreter.md) | monty | Sandboxed Python interpreter pattern |
| [ecc-patterns/](agents/ecc-patterns/) | affaan-m/everything-claude-code (MIT) | ECC instincts, hooks, orchestration patterns |

## Patterns

| File | Source | Description |
|------|--------|-------------|
| [managed-agent-runtime-control-plane.md](patterns/managed-agent-runtime-control-plane.md) | multica-ai/multica | Separate agent work management from local/cloud runtime execution with capability reporting, task claiming, provider adapters, and realtime progress |
| [forkable-event-sourced-agent-runs.md](patterns/forkable-event-sourced-agent-runs.md) | yoheinakajima/activegraph | Persist agent work as an event-sourced graph so runs can be audited, replayed, forked, and structurally diffed |
| [agentic-cad-skill-workbench.md](patterns/agentic-cad-skill-workbench.md) | earthtojake/text-to-cad | Constrain agentic CAD with source-first generation, explicit targets, deterministic inspection, render handoff, and repair loops |
| [pre-execution-agent-policy-gate.md](patterns/pre-execution-agent-policy-gate.md) | microsoft/agent-governance-toolkit | Deterministic allow/deny/audit policy checks before agent tool calls, resource access, messages, or workflow steps execute |
| [skill-security-audit.md](patterns/skill-security-audit.md) | gadievron/security-check-skill | Security auditing pattern for AI skills |
| [knowledge-work-plugins.md](patterns/knowledge-work-plugins.md) | anthropics/knowledge-work-plugins | Role-specific plugin architecture |
| [graphiti-knowledge-graph.md](patterns/graphiti-knowledge-graph.md) | getzep/graphiti | Real-time knowledge graphs for agents |
| [x-research-skill.md](patterns/x-research-skill.md) | xBenJamminx/x-research-skill | X/Twitter research skill pattern |
| [explain-openclaw-architecture.md](patterns/explain-openclaw-architecture.md) | djmango/explain-openclaw | OpenClaw architecture guide |
| [tinyfish-web-agents.md](patterns/tinyfish-web-agents.md) | tinyfish-ai/tinyfish-cookbook | Web agents for browser automation |
| [inconvo-data-agents.md](patterns/inconvo-data-agents.md) | inconvoai/inconvo | Chat-with-data agents for databases |
| [focus-mode-with-urgency-detection.md](patterns/focus-mode-with-urgency-detection.md) | koda | Focus mode with urgency detection |
| [progressive-skill-loading.md](patterns/progressive-skill-loading.md) | koda | Load skills progressively |
| [resilience-utilities.md](patterns/resilience-utilities.md) | koda | Error handling patterns |
| [smart-history-trimming.md](patterns/smart-history-trimming.md) | koda | Context window management |
| [subconscious-innovation-loop.md](patterns/subconscious-innovation-loop.md) | koda | Background innovation pattern |
| [vouch-web-of-trust.md](patterns/vouch-web-of-trust.md) | vouch | Web of trust verification |
| [mcp-template-server/](patterns/mcp-template-server/) | coding-standards-mcp | MCP server template |
| [citadel-campaign-persistence.md](patterns/citadel-campaign-persistence.md) | SethGammon/Citadel | Multi-session state persistence via structured campaign markdown files |
| [graph-backed-context-bundle-selection.md](patterns/graph-backed-context-bundle-selection.md) | stevesolun/ctx | Select capped helper bundles from large skill/agent/MCP catalogs using graph-ranked evidence |
| [agent-governance-kernel.md](patterns/agent-governance-kernel.md) | DecapodLabs/decapod | Callable governance loop around AI agent inference |
| [earned-autonomy-gates.md](patterns/earned-autonomy-gates.md) | arian-gogani/nobulex | Graduated agent permissions based on verifiable compliant behavior history |
| [profile-overlay-distribution.md](patterns/profile-overlay-distribution.md) | Diolinux/PhotoGIMP | Ship curated app defaults as inspectable profile files instead of forking the host app |
| [sidecar-agent-control-room.md](patterns/sidecar-agent-control-room.md) | shannhk/hermes-agent-control-room | Sidecar operations control plane for multi-agent teams |
| [signed-regression-witnesses.md](patterns/signed-regression-witnesses.md) | ruvnet/ruflo | Signed marker manifests for keeping past bug fixes auditable across refactors |
| [source-to-compiled-wiki-gates.md](patterns/source-to-compiled-wiki-gates.md) | wanderloots-tutorials/vibe-coding | Raw source layer, compiled wiki notes, JSONL catalog, source coverage, and lint gates |
| [agent-operated-backend-control-plane.md](patterns/agent-operated-backend-control-plane.md) | InsForge/InsForge | Typed backend control plane for AI coding agents |
| [local-tts-audiobook-pipeline.md](patterns/local-tts-audiobook-pipeline.md) | santinic/audiblez | Resumable local TTS audiobook pipeline with chapter-level intermediates |
| [conformance-gated-sdk-codegen.md](patterns/conformance-gated-sdk-codegen.md) | stainlu/stainful | Test generated SDKs with committed output, regeneration stability, and oracle public-surface comparison |
| [sandbox-credential-brokering.md](patterns/sandbox-credential-brokering.md) | vercel-labs/deepsec | Keep real provider tokens on the orchestrator while sandboxed agent workers use egress-layer credential injection |
| [topology-first-codebase-reasoning.md](patterns/topology-first-codebase-reasoning.md) | acidgreenservers gist | Map state, feedback, blast radius, timing, and trust boundaries before non-trivial code changes |
| [rtk-tool-result-compression.md](patterns/rtk-tool-result-compression.md) | decolua/9router | Compress noisy coding-tool outputs before LLM routing while preserving errors and fallback safety |
| [hook-captured-agent-memory.md](patterns/hook-captured-agent-memory.md) | rohitg00/agentmemory | Build agent memory as a local service fed by lifecycle hooks, with privacy, progressive recall, audit, and retention |
| [agentic-html-surface-pipeline.md](patterns/agentic-html-surface-pipeline.md) | nexu-io/html-anything | Use local agent CLIs plus constrained skill templates, streaming iframe preview, and export adapters to generate finished HTML artifacts |

## Prompts

| File | Source | Description |
|------|--------|-------------|
| [claudio-voice-personas.md](prompts/claudio-voice-personas.md) | cleanser-labs/claudio | Voice personas for TTS assistants |
| [chatgpt-prompts-library.md](prompts/chatgpt-prompts-library.md) | pacholoamit/chatgpt-prompts | 140+ curated GPT prompts |
| [shannon-pentesting-prompts.md](prompts/shannon-pentesting-prompts.md) | keygraphHQ/shannon | Pentesting agent prompts |
| [koda-soul-personality.md](prompts/koda-soul-personality.md) | koda | AI personality definition |
| [koda-conversation-summarizer.md](prompts/koda-conversation-summarizer.md) | koda | Conversation summarization |
| [koda-subagent-prompt.md](prompts/koda-subagent-prompt.md) | koda | Subagent task prompts |
| [supabase-coding-rules/](prompts/supabase-coding-rules/) | supabase/supabase (Apache-2.0) | 8 production coding rules — RLS, edge functions, auth, migrations, realtime |

## Tools

| File | Source | Description |
|------|--------|-------------|
| [skill-audit-cli.md](tools/skill-audit-cli.md) | markpors/skill-audit | CLI for auditing AI skills |
| [security-scanner-python.md](tools/security-scanner-python.md) | gadievron/security-check-skill | Python security scanner implementation |
| [langextract-structured-extraction.md](tools/langextract-structured-extraction.md) | langextract | Structured data extraction |
| [md-browse-turndown-config.md](tools/md-browse-turndown-config.md) | md-browse | HTML to Markdown conversion |
| [witr-process-causality.md](tools/witr-process-causality.md) | witr | Process causality tracking |

---

## Sources

All content includes attribution to its source repo, author, and license.

**Policy:** public repos → review published; license noted (including "none"); code only extracted under permissive licenses; AGPL/GPL summaries only; unlicensed → educational use only.
