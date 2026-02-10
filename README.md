# public-data

Curated patterns, prompts, and architectural ideas extracted from open-source AI assistant projects.

## Structure

- `prompts/` — System prompts, prompt templates, personality definitions
- `agents/` — Agent definitions, orchestration configs, loop architectures
- `patterns/` — Architectural patterns, best practices, reusable designs
- `tools/` — Useful scripts and utilities

## Contents

### Agents

| File | Source | Description |
|------|--------|-------------|
| [autoforge-two-agent-pattern.md](agents/autoforge-two-agent-pattern.md) | leonvanzyl/autoforge | Two-agent architecture for autonomous coding (initializer + coder) |
| [shannon-ai-pentester.md](agents/shannon-ai-pentester.md) | keygraphHQ/shannon | Autonomous AI pentester with Temporal orchestration |
| [antfarm-multi-agent-workflows.md](agents/antfarm-multi-agent-workflows.md) | snarktank/antfarm | Multi-agent workflows with YAML + SQLite + cron |
| [raptor-security-research-framework.md](agents/raptor-security-research-framework.md) | gadievron/raptor | Security research framework with progressive loading |
| [claude-code-controller-orchestration.md](agents/claude-code-controller-orchestration.md) | pacholoamit/claude-code-controller | Orchestrate real Claude Code processes via REST/SDK |
| [koda-architecture.md](agents/koda-architecture.md) | koda | Subagent spawning architecture |
| [monty-sandboxed-interpreter.md](agents/monty-sandboxed-interpreter.md) | monty | Sandboxed Python interpreter pattern |

### Patterns

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

### Prompts

| File | Source | Description |
|------|--------|-------------|
| [claudio-voice-personas.md](prompts/claudio-voice-personas.md) | cleanser-labs/claudio | Voice personas for TTS assistants |
| [chatgpt-prompts-library.md](prompts/chatgpt-prompts-library.md) | pacholoamit/chatgpt-prompts | 140+ curated GPT prompts |
| [shannon-pentesting-prompts.md](prompts/shannon-pentesting-prompts.md) | keygraphHQ/shannon | Pentesting agent prompts |
| [koda-soul-personality.md](prompts/koda-soul-personality.md) | koda | AI personality definition |
| [koda-conversation-summarizer.md](prompts/koda-conversation-summarizer.md) | koda | Conversation summarization |
| [koda-subagent-prompt.md](prompts/koda-subagent-prompt.md) | koda | Subagent task prompts |

### Tools

| File | Source | Description |
|------|--------|-------------|
| [skill-audit-cli.md](tools/skill-audit-cli.md) | markpors/skill-audit | CLI for auditing AI skills |
| [security-scanner-python.md](tools/security-scanner-python.md) | gadievron/security-check-skill | Python security scanner implementation |
| [langextract-structured-extraction.md](tools/langextract-structured-extraction.md) | langextract | Structured data extraction |
| [md-browse-turndown-config.md](tools/md-browse-turndown-config.md) | md-browse | HTML to Markdown conversion |
| [witr-process-causality.md](tools/witr-process-causality.md) | witr | Process causality tracking |

## Sources

All content includes attribution to its source repo, author, and license.

**Repos mined:**
- autoforge, shannon, antfarm, raptor, claude-code-controller
- security-check-skill, skill-audit, knowledge-work-plugins
- claudio, chatgpt-prompts, explain-openclaw
- graphiti, inconvo, x-research-skill
- tinyfish-cookbook, ai-stack
- koda, md-browse, vouch, witr, coding-standards-mcp, monty, langextract

## License

Each extracted file notes its source license. Files marked "no explicit license" are for educational/non-commercial use only.
