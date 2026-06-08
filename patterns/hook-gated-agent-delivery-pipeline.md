# Hook-Gated Agent Delivery Pipeline

**Source:** https://github.com/3awny/qship
**License:** MIT
**Extracted:** 2026-06-07

## Pattern

For long-running software-delivery agents, move completion and safety gates out of prompt prose and into filesystem artifacts plus shell hooks. The agent may propose that work is complete, but hook checks decide whether it can terminate, push, create a PR, or comment.

## Why It Matters

Agent coding workflows often fail by skipping late-stage work: E2E evidence, final test passes, review closure, or CI follow-up. Prompt instructions help, but they can be forgotten during context compaction or ignored under pressure. Hook gates make the missing artifact visible as a blocking runtime error.

## Minimal Shape

1. Define stable phase artifacts, such as progress tables, evidence files, test-pass flags, coverage JSON, and raw model logs.
2. Register pre-tool hooks for risky actions such as `git push`, `gh pr create`, or deployment commands.
3. Register stop hooks that reject termination when required progress rows remain pending.
4. Keep hook checks deterministic and local: inspect files, freshness, diff paths, and markers.
5. Put state outside the model context, under a run/ticket directory.
6. Add an outer persistence loop that re-enters the agent until a separate completion checker passes.
7. Include a watchdog for stale background workers.
8. Preserve logs so later reviewers can audit what the agent did and why.

## Design Notes

- Keep hooks narrow. They should block only the dangerous or premature transition.
- Make hook rejection text actionable so the agent can repair the missing artifact.
- Use explicit freshness windows to avoid stale state from old runs blocking new work forever.
- Prefer evidence files with structured headings over free-form completion prose.
- Treat `--dangerously-skip-permissions` style autonomy as a sandbox-only mode.
- Include a health check that verifies hooks, rendered skills, config, and companion dependencies.

## When To Use

- Ticket-to-PR pipelines.
- Long agent jobs that survive context compaction.
- Multi-agent review and bug-hunt workflows.
- CI-fix loops where "done" must mean "all gates passed."
- Any agent that can perform repository writes, pushes, PR creation, or deployment-adjacent actions.

## Caveats

- Hooks can become brittle if they parse too much prose.
- Stale state handling must be explicit.
- The agent may learn to satisfy markers without satisfying the underlying intent, so use evidence spot checks and human review.
- Full unattended execution needs a sandbox and constrained credentials.

---

**Attribution:** Inspired by 3awny/qship, MIT License.
