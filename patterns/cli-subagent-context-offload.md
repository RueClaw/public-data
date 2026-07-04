# CLI Subagent Context Offload

**Source:** Use Codex Skill  
**URL:** https://public.my-agent-04eee268.sandbox.dev/skills/use-codex.md  
**License:** No license specified; pattern summary only  
**Reviewed:** 2026-07-03

## Pattern

Use a separate CLI agent process for noisy or context-heavy exploration, then return only its final result to the parent agent. The parent remains responsible for deciding whether to delegate, validating the result, and presenting the synthesis.

```text
parent agent
  -> writes bounded task prompt
  -> launches CLI subagent in isolated run context
  -> waits with timeout and budget
  -> reads final output
  -> validates claims against source
  -> synthesizes answer or next task
```

## When It Helps

- Large codebase reconnaissance.
- Independent second-opinion reviews.
- Comparing two implementation approaches.
- Documentation or API discovery that would flood parent context.
- Sequential specialist passes where each next task depends on the prior result.

## Guardrails

- Make each run directory and output file unique.
- Set explicit time, token, and cost budgets.
- Prefer read-only mode for review/research tasks.
- State whether the subagent may edit files, run tests, use network, or make external calls.
- Treat subagent output as untrusted until checked.
- Validate concrete claims against files, tests, logs, or primary sources before surfacing them.
- Keep the parent in charge of sequencing; do not build blind fixed loops around subagent calls.

## Prompt Shape

Good subagent prompts include:

- task context;
- numbered objectives;
- constraints and non-goals;
- allowed tools and side effects;
- expected output format;
- success and stop criteria.

## Failure Modes

- Delegation overhead exceeds the task value.
- Multiple agents edit the same files without coordination.
- Subagent output contains plausible but unverified claims.
- Shell snippets accidentally interpolate prompt content.
- Shared temp paths collide during parallel runs.
- Broad autonomy flags bypass the user's intended safety boundaries.

The pattern is useful precisely when the parent stays skeptical and operationally boring.

---

**Attribution:** Pattern summarized from the public Use Codex skill document. No license specified.
