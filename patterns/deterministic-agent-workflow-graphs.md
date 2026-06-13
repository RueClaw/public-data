# Deterministic Agent Workflow Graphs

Source: https://github.com/fabro-sh/fabro  
License: MIT  
Extracted from review: [fabro.md](../reviews/fabro.md)  
Date: 2026-06-13

## Pattern

Represent long-running agent work as a version-controlled workflow graph instead of a prompt loop.

The core move is to make the process visible and executable: agents, shell commands, prompts, human approvals, waits, conditionals, parallel branches, merges, and exits become typed graph nodes. The runtime walks the graph, records durable events and outputs, and can pause, retry, resume, or checkpoint specific stages.

## Why It Works

Prompt prose is weak at process control. It can ask an agent to plan, test, review, ask for help, and continue, but the real state lives in the chat transcript and is hard to audit or replay.

A graph gives the process an inspectable shape:

- Branches and loops are explicit.
- Human approval is a paused runtime state, not a social convention.
- Parallel work has real fan-out and merge points.
- Stage outputs are addressable artifacts.
- Retry and timeout policy can be attached to nodes.
- The workflow can be code-reviewed like the rest of the repo.

## Design Moves

- Store workflow topology in a committed graph file.
- Use node types or visual shapes for agent, command, prompt, human, wait, conditional, parallel, merge, start, and exit.
- Keep model routing separate from workflow topology so the same process can run against different model/provider policies.
- Treat run configuration as a separate manifest that binds graph, goal, environment, sandbox provider, inputs, artifacts, notifications, hooks, and integrations.
- Make sandbox choice explicit: local for trusted convenience, container/cloud isolation for untrusted work.
- Emit an event stream plus durable stage outputs so a failed run can be inspected without reconstructing it from chat.
- Create git checkpoints or run branches when the workflow mutates a repository.

## When To Use It

Use this when agent work is:

- Longer than one interaction.
- Expensive enough that retries need structure.
- Risky enough to require human approval or verification gates.
- Repeated often enough that the process should improve over time.
- Shared across a team or fleet of agents.

## Failure Modes

- The graph can become its own programming language if the authoring model is too clever.
- Debugging needs first-class tooling; a graph without event traces is just prettier configuration.
- Local execution is not a sandbox. The runtime must be blunt about that.
- Human gates can become rubber stamps unless the gate includes evidence and clear choices.
- Model-routing policy can hide important behavior if it is too detached from the workflow being reviewed.

## Minimal Implementation Sketch

1. Define a small set of node kinds.
2. Parse a graph format into a typed workflow model.
3. Execute one stage at a time, appending events after every state transition.
4. Persist stage inputs, outputs, conclusions, and errors.
5. Require command and agent nodes to run through a sandbox interface.
6. Pause at human nodes and resume from an explicit decision.
7. Add git checkpoints around repository mutations.

The important constraint is that the runtime owns state. The agent can reason inside a node, but it should not be the only keeper of process state.
