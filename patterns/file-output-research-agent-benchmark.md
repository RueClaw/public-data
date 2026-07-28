# File-Output Research Agent Benchmark

**Source:** perplexityai/wandr  
**License:** Apache-2.0  
**Extracted:** 2026-07-28

## Pattern

For research-agent benchmarks, make the task output contract a filesystem artifact contract, not a chat transcript convention.

Each task declares the exact files a solver must create. The runner reads that declaration, includes it in the prompt, collects files through the provider-specific delivery mechanism, validates paths and non-empty required files, and only then starts the verifier.

## Why It Works

Research tasks often fail quietly: an agent may write a nice final answer while omitting rows, duplicating entities, citing unfetchable URLs, or leaving work inside an inaccessible sandbox. A file contract turns completion into something the harness can inspect before scoring.

The verifier can then own truth: parse submitted JSONL, fetch cited pages, reject unsafe URLs, triage source quality, normalize entities, deduplicate rows, and judge evidence support.

## Implementation Shape

1. Put required output paths in task metadata.
2. Normalize every submitted path relative to the workspace root.
3. Reject absolute paths outside the workspace, empty paths, duplicate paths, symlink targets, missing files, and empty required files.
4. Keep provider delivery modes explicit: sandbox files, shared files, stdout, or final-output fences.
5. Materialize files before running the verifier.
6. Record provider-neutral events, trajectories, usage, costs, and produced-file metadata.
7. Treat endpoint final text as observability, not as a substitute for required files.

## Use When

- comparing deep research agents;
- evaluating agents that must produce structured evidence files;
- benchmarking across providers with incompatible artifact delivery APIs;
- requiring verifier-owned scoring instead of self-reported success;
- publishing task packages that should run independently of the benchmark source repo.

## Caveats

This pattern does not make the task environment safe by itself. Public-network benchmarks still need provider budgets, credential scoping, workspace isolation, and clear data-handling rules.

It also adds delivery friction for providers without durable file APIs. That friction is worth paying for evaluation tasks where row fidelity and evidence completeness matter more than conversational polish.

---

**Attribution:** Derived from `perplexityai/wandr`, Apache-2.0.
