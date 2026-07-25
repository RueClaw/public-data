# Repo-Owned Agent Workflow Contract

**Source:** [openai/symphony](https://github.com/openai/symphony)
**License:** Apache-2.0
**Extracted:** 2026-07-25

## Problem

Background coding agents need project-specific policy: which tracker states are active, how workspaces are created, which commands are allowed, what handoff means, which tests are mandatory, and how the agent should update the issue. If that policy lives only in a daemon config or operator memory, it drifts away from the codebase it governs.

## Pattern

Put the agent workflow contract in the target repository as a single versioned file:

```markdown
---
tracker:
  kind: linear
  active_states: [Todo, In Progress, Rework]
  terminal_states: [Done, Closed]
workspace:
  root: ~/code/workspaces
hooks:
  after_create: |
    git clone git@github.com:example/app.git .
agent:
  max_concurrent_agents: 5
  max_turns: 20
codex:
  command: codex app-server
  thread_sandbox: workspace-write
---

You are working on {{ issue.identifier }}.

Title: {{ issue.title }}
Description: {{ issue.description }}

Follow this repository's implementation, validation, handoff, and review rules...
```

The file has two halves:

1. **Machine config** in YAML front matter.
2. **Agent policy** in Markdown prompt text.

The orchestrator loads this file before dispatch, validates the config, renders the prompt with issue context, and runs the agent under the configured workspace, sandbox, and tracker policy.

## Why It Works

The repository becomes the source of truth for its own automation. Changes to test requirements, branch policy, tracker states, sandbox posture, or handoff rules can be reviewed like code. Agents get instructions that travel with the project, and the orchestrator stays generic.

This also makes rollout safer. A team can start with conservative settings, collect evidence, then evolve the workflow contract through normal code review instead of editing a long-running service by hand.

## Minimal Version

```text
WORKFLOW.md
  YAML:
    tracker kind and active/terminal states
    workspace root
    lifecycle hooks
    agent concurrency and max turns
    model/runtime/sandbox policy

  Markdown:
    issue context template
    implementation rules
    validation requirements
    handoff criteria
    blocked-state behavior
```

## Implementation Notes

- Keep literal secrets out of the workflow file. Use `$VAR` references or host-side secret resolution.
- Treat lifecycle hooks as deployment scripts. Review them carefully and keep them short.
- On startup, fail fast when the workflow file is missing or invalid.
- On reload, keep the last known good workflow if the new one fails validation.
- Make active and terminal states explicit; do not infer them from vague tracker labels.
- Keep handoff distinct from done. A good default is "agent opens PR and moves work to human review."
- Include sandbox and approval policy in the contract so autonomy is visible during code review.
- Render tracker issue text as task context, not as privileged runtime authority.

## Good Fits

- autonomous coding-agent daemons
- issue-tracker-driven implementation queues
- team-specific validation and handoff policy
- repo-by-repo agent rollout
- environments where workflow changes should go through code review

## Poor Fits

- ad hoc one-off agent runs
- centralized platforms where repo maintainers cannot edit automation policy
- public issue trackers without prompt-injection and token boundaries
- deployments that need hard policy enforcement but only encode rules in prompt text

---

**Attribution:** openai/symphony, Apache-2.0 License.
