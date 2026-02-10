# Antfarm Multi-Agent Workflows

> **Source:** [snarktank/antfarm](https://github.com/snarktank/antfarm)
> **License:** MIT
> **Description:** Team of specialized AI agents working in deterministic workflows. YAML + SQLite + cron architecture with zero external dependencies.

## Overview

Antfarm provides pre-built agent teams for common development workflows. Each workflow defines roles (lead, developer, verifier, reviewer) with strict handoff protocols.

## Bundled Workflows

### feature-dev (7 agents)

```
plan → setup → implement → verify → test → PR → review
```

Drop in a feature request. Get back a tested PR. The planner decomposes tasks into stories. Each story gets implemented, verified, and tested in isolation. Failures retry automatically.

### security-audit (7 agents)

```
scan → prioritize → setup → fix → verify → test → PR
```

Point at a repo. Get back a security fix PR with regression tests. Scans for vulnerabilities, ranks by severity, patches each one, re-audits after all fixes.

### bug-fix (6 agents)

```
triage → investigate → setup → fix → verify → PR
```

Paste a bug report. Get back a fix with a regression test. Triager reproduces it, investigator finds root cause, fixer patches, verifier confirms.

## Why It Works

- **Deterministic workflows** — Same workflow, same steps, same order
- **Agents verify each other** — The developer doesn't mark their own homework
- **Fresh context, every step** — Each agent gets a clean session. No context window bloat
- **Retry and escalate** — Failed steps retry automatically. Exhausted retries escalate

## Custom Workflow Definition

```yaml
id: my-workflow
name: My Custom Workflow
agents:
  - id: researcher
    name: Researcher
    workspace:
      files:
        AGENTS.md: agents/researcher/AGENTS.md

steps:
  - id: research
    agent: researcher
    input: |
      Research {{task}} and report findings.
      Reply with STATUS: done and FINDINGS: ...
    expects: "STATUS: done"
```

## Architecture

### Minimal by Design

YAML + SQLite + cron. No Redis, no Kafka, no container orchestrator.

### Based on the Ralph Loop

Each agent runs in a fresh session with clean context. Memory persists through git history and progress files — the autonomous loop pattern from Ralph, scaled to multi-agent workflows.

### What Antfarm Changes in OpenClaw

- Adds workflow agents to `openclaw.json`
- Creates workflow workspaces under `~/.openclaw/workspaces/workflows`
- Stores workflow definitions and run state under `~/.openclaw/antfarm`
- Inserts guidance blocks into the main agent's `AGENTS.md` and `TOOLS.md`

## Key Design Principles

- **Define, Install, Run** — YAML agents and steps, one-command provisioning
- **Agents poll for work independently** — Claim a step, do the work, pass context
- **SQLite tracks state** — Cron keeps it moving
- **No Docker, no queues, no external services**
