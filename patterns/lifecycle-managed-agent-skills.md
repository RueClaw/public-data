# Lifecycle-Managed Agent Skills

**Source:** MUSE-Autoskill: Self-Evolving Agents via Skill Creation, Memory, Management, and Evaluation
**URL:** https://arxiv.org/abs/2605.27366
**Authors:** Huawei Lin, Peng Li, Jie Song, Fuxin Jiang, Tieying Zhang
**Reviewed:** 2026-05-28

## Pattern

Treat agent skills as versionable, testable, memory-bearing software assets instead of static prompt files.

Each skill is a directory with:

- `SKILL.md` for the agent-facing interface, triggers, invariants, tools, and workflow
- optional `scripts/` for executable helpers
- optional `tests/` for validation before registration
- optional `resources/` and `references/` for supporting material
- sibling `.memory.md` for private usage notes, failure modes, caveats, and lessons learned

Expose only a compact catalog eagerly:

```yaml
- name: excel-financial-formula-modeling
  description: Fill financial Excel models with formulas while preserving workbook structure.
```

Load the full skill body only after the agent selects it. This keeps a large skill bank cheap to route over while preserving detailed procedures when needed.

## Lifecycle

1. **Create** a skill when no existing skill covers the task.
2. **Evaluate** the new skill with tests or lightweight execution checks.
3. **Register** only if validation passes.
4. **Use** the skill through the normal agent loop.
5. **Append memory** after use: input quirks, failures, gotchas, performance notes.
6. **Refine** when tests fail or runtime feedback exposes a defect.
7. **Merge or prune** overlapping, stale, or repeatedly failing skills.

## Why It Matters

This pattern gives agent systems a middle layer between opaque model weights and raw chat history. Skills become inspectable artifacts that can be reviewed, transferred, tested, and improved over time.

The strongest design move is per-skill memory. General long-term memory often becomes vague or hard to route. Skill-local memory keeps observations attached to the capability they modify, so the next invocation can inherit operational experience without polluting every unrelated task.

## Caveats

- Skill creation from one successful run can overfit to that run.
- Test coverage must be real; a lifecycle that supports tests is not the same as a bank where most skills have meaningful tests.
- Transferable skills should avoid private environment assumptions, fixed task IDs, hidden file names, and benchmark-specific constants.
- `.memory.md` should usually remain private to the agent or deployment. Transferring a skill does not necessarily mean transferring accumulated local experience.

## Good Uses

- Coding-agent project skills
- Data-processing procedures
- Document conversion and extraction workflows
- Domain-specific operational playbooks
- Repeated tool-use recipes where failure modes accumulate over time

**Attribution:** Based on MUSE-Autoskill, arXiv:2605.27366, https://arxiv.org/abs/2605.27366
