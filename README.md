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

| File | Source | License | Rating | Description |
|------|--------|---------|--------|-------------|
| [gait.md](reviews/gait.md) | Clyra-AI/gait | Apache-2.0 | 🔥🔥🔥 | Policy-as-code enforcement at the AI agent tool boundary |
| [sage.md](reviews/sage.md) | l33tdawg/sage | Apache-2.0 | 🔥🔥🔥 | BFT consensus-validated persistent memory for AI agents |
| [crucix.md](reviews/crucix.md) | calesthio/Crucix | AGPL-3.0 | 🔥🔥🔥🔥 | Self-hosted OSINT intelligence terminal, 27 sources |
| [flash-moe.md](reviews/flash-moe.md) | danveloper/flash-moe | **no license** | 🔥🔥🔥🔥🔥 | Pure C/Metal inference for 397B MoE on a 48GB MacBook |
| [claude-chromium-native-messaging.md](reviews/claude-chromium-native-messaging.md) | stolot0mt0m/claude-chromium-native-messaging | MIT | 🔥🔥 | Claude extension for non-Chrome Chromium browsers |

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

## Prompts

| File | Source | Description |
|------|--------|-------------|
| [claudio-voice-personas.md](prompts/claudio-voice-personas.md) | cleanser-labs/claudio | Voice personas for TTS assistants |
| [chatgpt-prompts-library.md](prompts/chatgpt-prompts-library.md) | pacholoamit/chatgpt-prompts | 140+ curated GPT prompts |
| [shannon-pentesting-prompts.md](prompts/shannon-pentesting-prompts.md) | keygraphHQ/shannon | Pentesting agent prompts |
| [koda-soul-personality.md](prompts/koda-soul-personality.md) | koda | AI personality definition |
| [koda-conversation-summarizer.md](prompts/koda-conversation-summarizer.md) | koda | Conversation summarization |
| [koda-subagent-prompt.md](prompts/koda-subagent-prompt.md) | koda | Subagent task prompts |

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
