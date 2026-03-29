# Paperclip (paperclipai/paperclip)

*Review #289 | Source: https://github.com/paperclipai/paperclip | License: MIT | Author: Paperclip AI | Reviewed: 2026-03-29 | Stars: 38,470*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

"If OpenClaw is an employee, Paperclip is the company."

An open-source, self-hosted Node.js + React orchestration platform for running teams of AI agents as if they were a business. Bring your own agents (OpenClaw, Claude Code, Codex, Cursor, Gemini, OpenCode), assign them roles in an org chart, set budgets, define goals, and manage from a dashboard (including mobile). 38,470 stars, created 2026-03-02 — less than a month old. TypeScript monorepo. MIT.

The positioning is sharp: not a chatbot, not an agent framework, not a workflow builder. An organizational layer *above* agents — org charts, budgets, governance, goal alignment, ticketing. You run a company, not a pile of scripts.

---

## The Problem It Solves

The README is honest about the target user: someone with 20 Claude Code sessions open who has lost track of what each one is doing, who manually re-explains context after every reboot, who has had runaway agent loops burn through API budgets, and who has recurring work they're manually kicking off.

Paperclip's specific answers:
- **Task context persists across sessions** — agents resume rather than restart
- **Goal ancestry flows down** — every task knows why it exists, not just what to do
- **Budget enforcement is atomic** — checkout + budget check are a single transaction, preventing double-work and runaway spend
- **Heartbeat scheduling** — recurring work happens automatically; management supervises
- **Immutable audit log** — every conversation traced, every tool call recorded

---

## Architecture

TypeScript + pnpm monorepo. Packages:

```
packages/
├── adapters/              — one adapter per supported agent runtime
│   ├── openclaw-gateway/  — OpenClaw via gateway API
│   ├── claude-local/      — Claude Code
│   ├── codex-local/       — Codex CLI
│   ├── cursor-local/      — Cursor
│   ├── gemini-local/      — Gemini
│   ├── opencode-local/    — OpenCode
│   └── pi-local/          — Pi (OpenClaw agent name)
├── db/                    — embedded Postgres (no setup needed), Drizzle ORM
│   └── schema/            — ~50 tables
├── plugins/               — plugin SDK + examples
├── shared/
└── adapter-utils/
server/src/
├── services/              — 64 service modules
├── routes/                — REST API
└── ...
ui/                        — React dashboard
```

**Embedded Postgres**: `npx paperclipai onboard --yes` creates the database automatically. No external dependencies.

**The data model** (schema tables): companies, agents, agent_task_sessions, agent_runtime_state, agent_wakeup_requests, issues, issue_comments, issue_work_products, goals, project_goals, projects, budgets, budget_policies, budget_incidents, cost_events, approvals, approval_comments, routines, heartbeat_runs, heartbeat_run_events, activity_log, company_secrets, company_skills, execution_workspaces, workspace_operations, plugins, plugin_state, plugin_jobs, org-chart (inferred from routes), and more.

The schema reveals the depth of thinking: `agent_config_revisions` (governance + rollback), `workspace_runtime_services` (execution isolation), `issue_inbox_archives` (threaded conversations), `finance_events` (cost tracking), `agent_api_keys` / `board_api_keys` (authentication).

---

## Key Technical Properties

**Atomic task checkout.** An agent claiming a task and having its budget checked are a single atomic operation. This prevents two agents from picking up the same work and prevents overspend races.

**Persistent agent state.** `agent_runtime_state` and `agent_task_sessions` tables mean agents resume where they left off across heartbeat cycles, not from scratch.

**Goal-aware execution.** Every issue/task carries its full goal ancestry (project → goal → company mission). Agents receive context about *why*, not just *what*.

**Governance + rollback.** Config changes are stored in `agent_config_revisions`. Bad changes can be rolled back. Approval gates are enforced before sensitive operations.

**Heartbeat-driven scheduling.** Custom cron parser (5-field standard cron expressions) drives recurring tasks. Heartbeat runs are logged (`heartbeat_runs`, `heartbeat_run_events`). Management-level agents supervise subordinate agents' work.

**Multi-company isolation.** Every entity is company-scoped. One Paperclip deployment can run many companies with complete data isolation.

**Runtime skill injection.** Agents can receive Paperclip context and workflows at runtime without model retraining.

**Plugin system.** Plugin SDK in `packages/plugins/`. Plugin state, jobs, logs, webhooks, and company-scoped settings are all tracked. The `plugin_entities` table allows plugins to introduce new first-class objects.

---

## Agent Integration

Paperclip talks to agents via adapters. The adapter contract: agents expose a heartbeat endpoint (or equivalent). If it can receive a heartbeat, it's hired.

Current adapters:
- **openclaw-gateway**: communicates with OpenClaw gateway API
- **claude-local**: Claude Code
- **codex-local**: Codex CLI
- **cursor-local**: Cursor
- **gemini-local**: Gemini
- **opencode-local**: OpenCode
- **pi-local**: Pi (OpenClaw variant)

From the AGENTS.md/`.agents` directory: the repo ships with skill configurations for OpenClaw agents — AGENTS.md-compatible configs, goal injection patterns.

---

## Clipmart (Coming Soon)

"Download and run entire companies with one click." Pre-built company templates — org structures, agent configs, and skills — importable in seconds. Companion to `companies.sh` (already shipped: import/export entire org structures with secret scrubbing and collision handling). This is the distribution mechanism: not individual agents but entire configured organizations.

---

## Installation

```bash
# One command
npx paperclipai onboard --yes

# Or manual
git clone https://github.com/paperclipai/paperclip.git
cd paperclip && pnpm install && pnpm dev
# API at http://localhost:3100
```

Requirements: Node 20+, pnpm 9.15+. Embedded Postgres created automatically.

Docker: `docker-compose.yml` (full stack) and `docker-compose.quickstart.yml` (quick start). `Dockerfile.onboard-smoke` for smoke testing.

---

## Roadmap

Already shipped: plugin system, OpenClaw adapters, company import/export, AGENTS.md configs, Skills Manager, Scheduled Routines, budgeting.

Upcoming: Artifacts & Deployments, CEO Chat, MAXIMIZER MODE (??), Multiple Human Users, Cloud/Sandbox agents (Cursor/e2b), Cloud deployments, Desktop App.

`awesome-paperclip` community repo exists for plugins and extensions.

---

## Comparison to Alternatives

- **Task runners (cron, Make)**: No agent awareness, no goal context, no cost tracking
- **Trello/Asana + OpenClaw**: No atomic checkout, no budget enforcement, no agent-native persistence
- **LangGraph/CrewAI**: Agent framework, not organizational layer. Doesn't orchestrate heterogeneous agents (OpenClaw + Codex + Cursor simultaneously)
- **Sweep/Devin**: Single-agent code review, not multi-company multi-role orchestration

The closest prior art is enterprise workflow orchestration (Temporal, Prefect) crossed with GitHub Issues, but built specifically for AI agents as workers.

---

## Caveats

- 38K stars in 27 days is extremely viral. Production maturity unclear.
- Embedded Postgres is convenient but creates upgrade friction at scale; the Docker compose files suggest they anticipate external Postgres.
- The "zero-human company" framing is provocative marketing. Real value is probably in reducing human coordination overhead, not replacing humans.
- MAXIMIZER MODE in the roadmap is unexplained and slightly alarming.
- No agent weights or model hosting — Paperclip is purely orchestration; all inference costs fall on the underlying agent providers.

---

## Verdict

🔥🔥🔥🔥🔥 — The most complete multi-agent orchestration layer available. The atomic task checkout, goal ancestry propagation, governance/rollback, multi-company isolation, and heterogeneous agent support (OpenClaw + Claude Code + Codex + Cursor simultaneously) are all things that need to exist and currently require hand-rolling. The OpenClaw adapter is first-class. 38K stars in 27 days is extreme signal. MIT. Cloned to `~/src/paperclip`.
