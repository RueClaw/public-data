# Stateless-Baseline Gain Evaluation

**Source:** pgasawa/continual-learning-bench  
**Repo:** https://github.com/pgasawa/continual-learning-bench  
**License:** Apache-2.0  
**Reviewed:** 2026-06-10

## Pattern

When evaluating a stateful agent, run the same benchmark instances twice:

1. **Stateful rollout:** the agent keeps its allowed memory, context, files, retrieved facts, or learned policy across ordered instances.
2. **Reset baseline:** the same agent is reset between canonical instances, so each instance is solved independently.

Then compute per-instance gain:

```text
gain[i] = stateful_reward[i] - reset_baseline_reward[i]
```

Track the same comparison for cost and latency when available:

```text
cost_increase[i] = stateful_cost[i] - reset_baseline_cost[i]
```

Aggregate by index and cumulatively:

- baseline reward by index
- mean stateful reward by index
- mean gain by index
- cumulative mean gain by index
- mean cost, cost increase, and latency by index

## Why It Works

Raw reward conflates two things:

- the base model or toolchain is good at the task
- the system actually used prior experience to improve

The reset baseline separates those effects. A strong stateless system can score well but show little gain. A weaker system with good memory may start lower but show positive gain as repeated structure becomes useful.

## Implementation Notes

- Give every benchmark instance a stable `instance_id` and `instance_index`.
- Ensure the reset baseline and stateful rollout play the same canonical instance set.
- Make reset semantics explicit: context, retrieved memory, file state, provider sessions, and tool workspaces may each need separate handling.
- Store per-instance outcomes, not only run-level averages.
- Treat cost and latency deltas as first-class metrics; a memory system that improves reward by spending far more may not be a real win.
- Allow partial baseline coverage only when refusals or blocked instances are explicitly represented in the aggregate.

## Good Fit

- Longitudinal agent memory
- Coding agents working through related issues in one repository
- Retrieval systems that should accumulate domain knowledge
- Skill/playbook systems that claim to improve after feedback
- Human-in-the-loop agent workflows where procedures should get cheaper over time

## Caveats

The reset baseline must be fair. If the reset system loses information that would normally be in the task prompt or environment, the gain will be inflated. If the stateful system is allowed to see hidden feedback or test answers, the gain is contaminated.

For long-context systems, decide whether provider-side conversation state counts as memory. The important thing is not the label; it is that reset and stateful modes are documented and comparable.

---

**Attribution:** Derived from the benchmark aggregation and reset-baseline design in pgasawa/continual-learning-bench, Apache-2.0.
