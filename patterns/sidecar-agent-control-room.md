# Sidecar Agent Control Room

**Source:** https://github.com/shannhk/hermes-agent-control-room
**License:** MIT
**Reviewed:** 2026-05-17

## Pattern

Create a sidecar repository or folder that governs agent operations without becoming the agent runtime itself.

The control room contains agent inventory, runtime layout, port maps, allowed and forbidden work, secret maps by reference, runbooks, backup plans, security checklists, agent registries, task/result templates, and escalation rules.

Live runtime state stays elsewhere: per-agent data directories, credentials, sessions, logs, crons, and memory.

## Why It Works

Agent teams fail when the operating model lives only in chat history or in one operator's head. A sidecar control room gives humans and orchestrators the same reference surface.

The useful boundary is:

```text
control room = docs, registry, runbooks, templates, policy
runtime      = data, credentials, logs, sessions, crons, memory
```

That separation makes it easier to publish or version the control plane without leaking secrets or committing live state.

## Growth Model

A conservative progression:

1. Document one working agent.
2. Add direct specialists only when roles are clear.
3. Add an orchestrator only when a single front door is useful.
4. Add recurring automation only after manual delegation works.

This avoids the common failure mode of starting with a fully automated multi-agent system before ownership, credentials, approvals, and recovery are understood.

## Minimal Files

A compact implementation can start with:

```text
agents/<agent-name>/
  inventory.md
  docker.md
  env-map.md
  runbook.md
  backup.md

shared/
  security.md
  commands.md
  api-keys-sop.md

registry/
  agents.yaml

task-bus/
  task-template.md
  result-template.md
```

## Task Bus Shape

Use a file-based task bus when orchestration needs to stay inspectable:

```text
tasks/<role>/
  inbox/
  working/
  outbox/
  archive/
```

Task files should include objective, context, constraints, expected output, approval gates, and artifacts. Result files should include status, work performed, findings, risks, assumptions, and recommended next action.

## Safety Rules

- Store secret names, scopes, providers, locations, and rotation dates, never raw values.
- Keep one data directory per long-running agent.
- Avoid two gateway processes sharing the same state directory.
- Bind dashboards and APIs to localhost by default.
- Require explicit approval for publishing, destructive operations, deployments, and credential rotation.
- Treat any credential pasted into chat as burned.

---

**Attribution:** Pattern summarized from shannhk/hermes-agent-control-room, MIT License.

