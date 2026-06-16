# Evidence-Backed Command Output Compaction

**Source:** [nik1t7n/context-firewall](https://github.com/nik1t7n/context-firewall)
**License:** Apache-2.0 in repository files
**Reviewed:** 2026-06-16

## Pattern

Run noisy commands through a local wrapper that stores full stdout/stderr as evidence, returns a deterministic compact summary to the agent, and includes a stable span handle for exact retrieval.

```text
command argv
  -> policy classification
  -> real command execution
  -> raw stdout/stderr artifacts
  -> deterministic reducer
  -> local ledger span
  -> compact agent-visible output + retrieval handle
```

## Why It Matters

Coding agents often need command evidence, but not all of it at once. Long test logs, search output, diffs, JSON, and browser snapshots can crowd out the code and decision context the model needs. Summarizing them with an LLM is risky because exact evidence is lost or becomes expensive to recover.

This pattern keeps the agent's context small without destroying provenance. The compact output is a view over local raw evidence, not a replacement for it.

## Implementation Notes

- Store combined raw output, split stdout, split stderr, metadata, hashes, command argv, cwd, exit code, and reducer type.
- Return a span handle in every compact response.
- Provide a retrieval command or tool that can fetch exact output or line ranges.
- Use deterministic reducers for common noisy shapes: tests, search, git diffs, logs, JSON, source outlines, and browser snapshots.
- Add a raw-output guard for secret-like content before printing exact artifacts back into the agent context.
- Keep receipt/accounting data tied to spans so "tokens saved" claims can be audited.
- Include repeat fingerprints so identical reruns can collapse to a prior span handle instead of repeating output.

## When To Use

Use this pattern anywhere an agent regularly runs terminal commands and the raw output may be useful later. It is especially good for coding agents, CI-log triage, browser automation snapshots, repo-wide search, and long-running test suites.

Avoid treating it as a sandbox. The command still runs locally with the caller's permissions; the pattern controls visibility and evidence retention, not process isolation.

## Adaptation Checklist

- Define the raw artifact retention location and retention policy.
- Decide which command classes should compact, outline, dedupe, block, or pass through.
- Make exact retrieval line-addressable.
- Keep reducers boring and testable.
- Test against real noisy corpora, not only toy strings.
- Make the default output useful enough that agents do not immediately request the full raw log.

---

**Attribution:** nik1t7n/context-firewall, Apache-2.0.
