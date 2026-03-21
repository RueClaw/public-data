# Claude Task Master (Taskmaster) — Repo Review

**Repo:** https://github.com/eyaltoledano/claude-task-master  
**License:** MIT + Commons Clause (source-available — see below)  
**Language:** TypeScript / Node.js  
**Stars:** Trendshift listed, npm: `task-master-ai`  
**Version:** 0.43.0  
**Cloned:** ~/src/claude-task-master  
**Rating:** 🔥🔥🔥

---

## What It Is

AI-driven task management system for software development, exposed as an MCP server. You give it a PRD (Product Requirements Document) and it:

1. Parses the PRD → generates a structured task list with dependencies
2. Analyzes task complexity (1–10 score, AI-powered)
3. Expands complex tasks into subtasks with customized prompts
4. Tracks status (pending/in-progress/done/deferred)
5. Feeds "next task" to your coding agent via MCP

Designed for Cursor/Windsurf/Claude Code/VS Code. You work with an AI coder, and Taskmaster is the PM layer that tells the agent what to work on next and tracks progress.

---

## Architecture

### MCP Server
30+ MCP tools covering the full task lifecycle:

| Tool Category | Tools |
|---|---|
| Init | `initialize-project`, `parse-prd` |
| Task CRUD | `add-task`, `remove-task`, `move-task`, `add-subtask`, `remove-subtask` |
| Dependencies | `add-dependency`, `remove-dependency`, `fix-dependencies` |
| Analysis | `analyze` (complexity), `complexity-report`, `expand-task`, `expand-all` |
| Workflow | `next-task`, `get-operation-status` |
| Tagging | `add-tag`, `delete-tag`, `copy-tag`, `rename-tag`, `list-tags` |
| Research | `research` (via Perplexity/web) |
| Scoping | `scope-up`, `scope-down` |

### AI Provider Stack
Uses Vercel AI SDK (`ai` package) with providers for: Anthropic, OpenAI, Google Gemini, Mistral, Groq, xAI, OpenRouter, Ollama, AWS Bedrock, Azure. Three model slots: main, research (optional Perplexity), fallback.

Also supports **Claude Code CLI** and **Codex CLI** as providers (no API key needed if you have the CLI). That's an unusual and clever move — use your existing Claude/ChatGPT subscription.

### Task File Format
Tasks live in `.taskmaster/tasks/tasks.json` with fields:
- `id`, `title`, `description`, `status`, `priority`
- `dependencies` (with ✅/⏱️ status indicators)
- `details` — full implementation instructions
- `testStrategy` — verification approach
- `subtasks` — nested task breakdown

Individual task files exported as markdown for agent consumption.

### Tag System
Tasks can be multi-tagged — essentially separate workspaces/branches within the same project. `scope-up`/`scope-down` for context management. Interesting for managing multiple features in parallel.

### Complexity Analysis
`analyze-complexity` scores each task 1–10 and generates tailored expansion prompts per task. `expand-task` then uses those custom prompts + the recommended subtask count. Smart: the expansion prompt is task-specific, not generic.

---

## License — IMPORTANT

**MIT + Commons Clause.** The Commons Clause means:

> You cannot sell software/services whose value derives substantially from Taskmaster's functionality.

So you can:
- Use it to manage your own projects ✅
- Modify it ✅
- Deploy it internally ✅

You cannot:
- Build a competing product/SaaS on top of it ❌
- Charge for consulting/hosting that substantially relies on it ❌

**For our use:** Personal/homelab project management → fine. Selling a product built on Taskmaster → not allowed.

---

## What's Interesting for Us

### 1. PRD → Task Graph Pattern
The `parse-prd` → task dependency graph → `next-task` workflow is the right skeleton for any project that needs structured AI-driven execution. Worth borrowing for anything with a planning phase.

### 2. Three-Model Slot Design
Main (capable, expensive) + research (web-connected) + fallback (cheap). Clean tiering pattern. We have a similar setup with ollama fallbacks — same principle.

### 3. Complexity Scoring Before Expansion
Score tasks before breaking them down. Only expand high-complexity tasks. Avoids over-decomposing simple tasks. Obvious in hindsight, rarely implemented.

### 4. Claude Code / Codex CLI as AI Providers
The `ai-sdk-provider-claude-code` and `ai-sdk-provider-codex-cli` packages let you use the CLI tools as API backends. No extra API keys. Worth checking if we can wire our Claude Code CLI similarly.

### 5. Context Manager
`mcp-server/src/core/context-manager.js` — manages per-project context fed to the AI. Worth reading for how they structure task context for LLM consumption.

---

## What's Not Interesting

- The CLI UX (boxen, chalk, figlet, gradient-string) — heavy cosmetics, not the point
- Sentry error tracking baked in (`@sentry/node` dep) — telemetry, watch for this
- Supabase dep (`@supabase/supabase-js`) — unclear what it's used for, possibly cloud sync
- Cursor-specific integrations — not relevant

---

## Verdict

Solid "AI project manager" pattern. The PRD→task graph→next-task pipeline, three-tier model slots, and complexity-gated expansion are all patterns worth extracting. The Commons Clause means we can use it but not productize it. Useful to have on hand for any structured multi-task coding projects.

Not 🔥🔥🔥🔥🔥 because it's a well-executed version of a fairly conventional idea (AI task management), and the Commons Clause limits how we'd ever build on it.

---

*Source: https://github.com/eyaltoledano/claude-task-master | License: MIT + Commons Clause (no selling derivatives) | Reviewed: 2026-03-21*
