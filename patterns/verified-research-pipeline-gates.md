# Verified Research Pipeline Gates

**Source:** https://github.com/aiming-lab/AutoResearchClaw
**Author:** Aiming Lab
**License:** MIT
**Extracted:** 2026-05-23
**Type:** Architecture pattern

## Pattern

Structure an autonomous research workflow as a staged pipeline where every high-risk transition has an explicit artifact, gate, or verifier. The goal is not just to produce a paper-shaped output, but to preserve evidence about how the output was produced and block common failure modes before publication.

## Core Shape

1. **Stage the work.** Break the research flow into named phases such as topic scoping, literature discovery, hypothesis generation, experiment design, execution, analysis, paper writing, peer review, export, and citation verification.
2. **Persist stage artifacts.** Each stage writes structured outputs that downstream stages consume and reviewers can inspect.
3. **Checkpoint execution.** Store the last completed stage, run id, timestamps, and human-in-the-loop session state so long workflows can resume safely.
4. **Gate risky transitions.** Require approval at stages where bad choices compound: literature screening, experiment design, final quality/export.
5. **Execute experiments in a bounded environment.** Run generated code in local or containerized sandboxes with entry-point validation, timeouts, network policy, and a stable harness.
6. **Build a verified value registry.** Collect numeric outputs from experiment artifacts and register rounded/percentage variants with provenance.
7. **Verify paper claims.** Check generated paper numbers against the registry and reject strict-section violations.
8. **Verify citations separately.** Validate bibliography entries through external identifiers, DOI lookup, and title search instead of trusting generated references.
9. **Archive decisions and lessons.** Store outcomes, warnings, failures, and lessons so later runs can reuse operational knowledge.

## Why It Works

Research automation fails when text generation is treated as the primary product. This pattern treats text as one artifact among many. The actual system of record is the pipeline trace: design files, experiment code, execution logs, metrics, verification reports, review comments, and final exports.

That makes it possible to answer:

- Where did this number come from?
- Which experiment generated it?
- Which citations were real?
- Which stage approved the design?
- What failed and how was it repaired?
- Can the run resume from a checkpoint?

## Useful Design Details

- Use a typed stage enum rather than free-form workflow names.
- Separate required gates from noncritical stages.
- Treat citation verification and numeric verification as different checks.
- Let generated code run only after path and entry-point validation.
- Put human guidance in stage-local artifacts instead of mutating hidden prompt state.
- Use a final summary file with stage counts, status, generated timestamp, and content metrics.
- Make failed experiments produce repair prompts instead of silently fabricating success.

## When To Use

Use this pattern for:

- autonomous research assistants,
- paper-generation systems,
- experiment orchestration agents,
- benchmark-running agents,
- scientific workflow copilots,
- any AI system that transforms generated code and literature search into claims.

## Cautions

- A verifier can reduce hallucination, but it cannot prove scientific novelty or usefulness.
- Generated experiments still need resource controls and expert review.
- Citation lookup can fail because of API availability, metadata drift, or title mismatch.
- Human approval gates should be meaningful, not rubber stamps.
- Do not let a successful pipeline run imply publication readiness.

## Attribution

This pattern is derived from the public AutoResearchClaw repository by Aiming Lab, especially its staged pipeline, human-in-the-loop gates, sandboxed execution, verified numeric registry, and citation verification design.
