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
| [xurl.md](reviews/xurl.md) | [xdevplatform/xurl](https://github.com/xdevplatform/xurl) | MIT | ✅ Deploy candidate | Official curl-like CLI for the X API with OAuth2/OAuth1/app auth, multi-app token storage, shortcut commands, media upload, streaming, webhook helpers, and an agent-safe Claude skill reference |
| [open-notebook.md](reviews/open-notebook.md) | [lfnovo/open-notebook](https://github.com/lfnovo/open-notebook) | MIT | ✅ Deploy candidate | Self-hosted NotebookLM alternative with FastAPI, Next.js, SurrealDB, multi-provider AI, local model support, explicit context controls, REST API, transformations, notes, search, and podcast generation |
| [claude-bughunter.md](reviews/claude-bughunter.md) | [elementalsouls/Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter) | MIT | ⚠️ Interesting | Claude Code skill bundle for authorized bug bounty and external red-team workflows with scope gates, validation discipline, evidence hygiene, reporting templates, slash commands, and a deterministic Python CLI |
| [devils-advocate.md](reviews/devils-advocate.md) | [brandonsimpson/devils-advocate](https://github.com/brandonsimpson/devils-advocate) | MIT | ✅ Deploy candidate | Claude Code plugin for adversarial binary code/plan critique with file:line evidence, fix suggestions, context gates, standards discovery, session logs, and non-blocking commit/plan hooks |
| [comfyui-ltxvideo.md](reviews/comfyui-ltxvideo.md) | [Lightricks/ComfyUI-LTXVideo](https://github.com/Lightricks/ComfyUI-LTXVideo) | LTX-2 Community License | ⚠️ Interesting | Official ComfyUI custom-node and workflow pack for LTX-2/LTX-2.3 video generation, with IC-LoRA, HDR, lipdub, motion tracking, low-VRAM loaders, and heavyweight license/runtime caveats |
| [hermes-vault.md](reviews/hermes-vault.md) | [asimons81/hermes-vault](https://github.com/asimons81/hermes-vault) | MIT | ✅ Deploy candidate | Local-first encrypted credential broker for AI agents with policy-gated ephemeral env access, MCP tools/resources, OAuth lifecycle support, verifier plugins, and a localhost operator dashboard |
| [12-factor-agents.md](reviews/12-factor-agents.md) | [humanlayer/12-factor-agents](https://github.com/humanlayer/12-factor-agents) | Apache-2.0 code / CC BY-SA 4.0 content | 📚 Study | Production-agent principles guide: owned prompts/context, structured tool outputs, unified state, pause/resume APIs, human tool calls, explicit control flow, compact errors, and reducer-style agents |
| [vimax.md](reviews/vimax.md) | [HKUDS/ViMax](https://github.com/HKUDS/ViMax) | MIT | 📚 Study | Agentic video-generation orchestration pipeline that stages story, character, storyboard, frame, provider-backed video, and composition artifacts; useful pattern source, not deploy-ready as-is |
| [ruview.md](reviews/ruview.md) | [ruvnet/RuView](https://github.com/ruvnet/RuView) | MIT | 📚 Study | Ambitious WiFi CSI spatial-sensing platform with Rust signal crates, ESP32 firmware, dashboards, Home Assistant/Matter docs, and MCP/CLI wrappers; useful pattern source but not a turnkey safety/health deployment |
| [openhuman.md](reviews/openhuman.md) | [tinyhumansai/openhuman](https://github.com/tinyhumansai/openhuman) | GPL-3.0 | ⚠️ Interesting | Personal AI desktop harness with Rust/Tauri core, React app, local memory tree, Markdown vault, integrations, messaging channels, MCP surfaces, and significant privacy/security caveats |
| [codegraph.md](reviews/codegraph.md) | [colbymchenry/codegraph](https://github.com/colbymchenry/codegraph) | MIT | ✅ Deploy candidate | Local pre-indexed code graph and MCP server for coding agents, with SQLite/FTS5, tree-sitter extraction, broad language/framework coverage, installer targets, and strong tests |
| [cloudsail.md](reviews/cloudsail.md) | [nkzw-tech/cloudsail](https://github.com/nkzw-tech/cloudsail) | MIT | ✅ Deploy candidate | Self-hosted Cloudflare coding-agent sandboxes with Worker-owned credential injection, controlled egress, terminal/dev-server previews, git helpers, and clean alpha verification |
| [inbox-zero.md](reviews/inbox-zero.md) | [elie222/inbox-zero](https://github.com/elie222/inbox-zero) | AGPL-3.0 + commercial/enterprise restrictions | ⚠️ Interesting | Full AI email assistant with Gmail/Outlook automation, confirmed action gates, encrypted provider tokens, self-hosting docs, and dependency/license caveats |
| [tldraw.md](reviews/tldraw.md) | [tldraw/tldraw](https://github.com/tldraw/tldraw) | tldraw source-available + MIT templates | ✅ Deploy candidate | Infinite-canvas React SDK and whiteboard platform with multiplayer sync, AI starter kits, MCP app, and strong canvas-agent action patterns |
| [twenty.md](reviews/twenty.md) | [twentyhq/twenty](https://github.com/twentyhq/twenty) | AGPL-3.0 + Enterprise-marked files | ✅ Deploy candidate | Open-source CRM/product platform with self-hosted Docker/Kubernetes deployment, NestJS/React monorepo, SDK/app scaffolder, custom auth lint rules, and Claude skill direction |
| [anytype-ts.md](reviews/anytype-ts.md) | [anyproto/anytype-ts](https://github.com/anyproto/anytype-ts) | ASAL-1.0 source-available | 📚 Study | Official Anytype Electron/React desktop client for local-first encrypted object graphs, spaces, blocks, relations, sync middleware, and extension bridging |
| [bumblebee.md](reviews/bumblebee.md) | [perplexityai/bumblebee](https://github.com/perplexityai/bumblebee) | Apache-2.0 | ✅ Deploy candidate | Read-only developer endpoint scanner for exact package/tool exposure checks across lockfiles, package metadata, extensions, MCP configs, and threat-intel catalogs |
| [claude-ads.md](reviews/claude-ads.md) | [AgriciDaniel/claude-ads](https://github.com/AgriciDaniel/claude-ads) | MIT | ✅ Deploy candidate | Multi-platform paid-advertising audit skill pack with platform playbooks, helper agents, local scripts, PDF/report tooling, and a pytest eval harness |
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
| [agentmemory.md](reviews/agentmemory.md) | [rohitg00/agentmemory](https://github.com/rohitg00/agentmemory) | Apache-2.0 | ⚠️ Interesting | Persistent memory server for AI coding agents with hook capture, MCP/REST, hybrid retrieval, graph/lessons, commit provenance, privacy, audit, and retention |
| [supertonic.md](reviews/supertonic.md) | [supertone-inc/supertonic](https://github.com/supertone-inc/supertonic) | MIT code / OpenRAIL-M model | ✅ Deploy candidate | On-device multilingual TTS reference kit with ONNX Runtime examples across Python, browser/WebGPU, Node, Rust, Swift, Go, Java, C++, C#, Flutter, and iOS |
| [cloakbrowser.md](reviews/cloakbrowser.md) | [CloakHQ/CloakBrowser](https://github.com/CloakHQ/CloakBrowser) | MIT wrapper / proprietary binary | ⚠️ Interesting | Security-sensitive Playwright/Puppeteer wrapper around a patched Chromium binary, with strong wrapper tests, binary provenance docs, and anti-detection risk |
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
| [12-factor-agent-architecture.md](patterns/12-factor-agent-architecture.md) | humanlayer/12-factor-agents | Design production agents as explicit software systems with owned prompts/context/state, structured outputs, human approval tools, compact errors, and reducer-style steps |
| [agentic-video-production-pipeline.md](patterns/agentic-video-production-pipeline.md) | HKUDS/ViMax | Turn a loose creative brief into durable story, character, storyboard, frame, clip, and final-video artifacts with provider-isolated media generation |
| [wifi-csi-edge-sensing-pipeline.md](patterns/wifi-csi-edge-sensing-pipeline.md) | ruvnet/RuView | Build a local WiFi CSI sensing pipeline with calibration, quality flags, confidence scores, bounded semantic outputs, and privacy-aware home-automation integration |
| [local-personal-ai-memory-harness.md](patterns/local-personal-ai-memory-harness.md) | tinyhumansai/openhuman | Build a local desktop assistant core around inspectable memory, Markdown vault export, credential isolation, prompt-injection gates, and explicit integration trust boundaries |
| [preindexed-code-intelligence-mcp.md](patterns/preindexed-code-intelligence-mcp.md) | colbymchenry/codegraph | Keep a local code graph beside a repository and expose compact MCP tools for search, context, callers/callees, impact analysis, and index status |
| [edge-brokered-coding-sandboxes.md](patterns/edge-brokered-coding-sandboxes.md) | nkzw-tech/cloudsail | Run agents in remote coding containers while an edge control plane owns credentials, egress policy, previews, lifecycle, checkpoints, and cost limits |
| [private-email-assistant-action-gates.md](patterns/private-email-assistant-action-gates.md) | elie222/inbox-zero | Constrain private mailbox agents with untrusted-content hardening, template-only generated fields, pending confirmations, account-bound execution, encrypted secrets, and audit context |
| [local-first-encrypted-object-graph-client.md](patterns/local-first-encrypted-object-graph-client.md) | anyproto/anytype-ts | Split a local-first knowledge app into a rich Electron/React object-graph client backed by encrypted/syncing middleware and event streams |
| [read-only-endpoint-exposure-scanner.md](patterns/read-only-endpoint-exposure-scanner.md) | perplexityai/bumblebee | Read bounded local package/tool metadata, match exact exposure catalogs, and emit stable current-state records without executing packages |
| [domain-skill-eval-harness.md](patterns/domain-skill-eval-harness.md) | AgriciDaniel/claude-ads | Test large agent skills with routing snapshots, check catalog coverage, deterministic scoring, and helper-script security regressions |
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
| [hook-captured-agent-memory.md](patterns/hook-captured-agent-memory.md) | rohitg00/agentmemory | Build agent memory as a local service fed by lifecycle hooks, with privacy, progressive recall, provenance, audit, and retention |
| [on-device-onnx-tts-adapter.md](patterns/on-device-onnx-tts-adapter.md) | supertone-inc/supertonic | Wrap local ONNX TTS behind a small HTTP/OpenAI-compatible adapter so agents and apps can share one private speech runtime |
| [policy-gated-browser-automation-runtime.md](patterns/policy-gated-browser-automation-runtime.md) | CloakHQ/CloakBrowser | Put browser automation behind URL, launch-argument, network, binary-provenance, and audit policy gates |
| [agentic-html-surface-pipeline.md](patterns/agentic-html-surface-pipeline.md) | nexu-io/html-anything | Use local agent CLIs plus constrained skill templates, streaming iframe preview, and export adapters to generate finished HTML artifacts |
| [policy-gated-local-agent-credential-broker.md](patterns/policy-gated-local-agent-credential-broker.md) | asimons81/hermes-vault | Broker agent credential use through local encrypted storage, service/action policy, verification, TTL-limited env materialization, audit records, and raw-secret-safe operator surfaces |
| [evidence-bound-binary-critique-gate.md](patterns/evidence-bound-binary-critique-gate.md) | brandonsimpson/devils-advocate | Turn LLM critique into binary pass/fail criteria with context gates, file:line evidence, fix suggestions, independent review for self-critiques, and logged results |
| [scope-gated-security-skill-bundle.md](patterns/scope-gated-security-skill-bundle.md) | elementalsouls/Claude-BugHunter | Build high-risk domain skills around authorization gates, narrow routing, validation-before-action, evidence hygiene, and explicit operational stop-lines |
| [user-controlled-rag-research-workspace.md](patterns/user-controlled-rag-research-workspace.md) | lfnovo/open-notebook | Build research assistants around explicit notebooks, sources, notes, insights, context-inclusion levels, token budgets, and separate provider credentials |
| [agent-safe-social-api-cli.md](patterns/agent-safe-social-api-cli.md) | xdevplatform/xurl | Expose social APIs to agents through a local CLI with secret-free status checks, JSON shortcuts, forbidden secret flags/files, and approval gates for mutations |

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
