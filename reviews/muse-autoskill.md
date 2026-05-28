# MUSE-Autoskill: Self-Evolving Agents via Skill Creation, Memory, Management, and Evaluation

**Source:** https://arxiv.org/abs/2605.27366
**Author:** Huawei Lin, Peng Li, Jie Song, Fuxin Jiang, Tieying Zhang
**Date:** 2026-05-26
**Reviewed:** 2026-05-28
**Topic:** Agent skills, self-improving agents, skill memory, evaluation

---

## Verdict

📚 **Good reference for agent skill lifecycle design, but not settled evidence.** The paper has a useful systems framing: treat skills as long-lived, testable, memory-bearing artifacts rather than one-off prompt snippets. The experiments are promising, especially the cross-agent transfer result, but the benchmark subset, single-model setup, and same-task skill distillation protocol make the headline gains too early to treat as production proof.

---

## Summary

MUSE-Autoskill argues that agent skills should be managed like durable software assets. Instead of generating a skill once and dropping it into a flat library, the framework gives skills a full lifecycle: creation, memory, management, evaluation, and refinement.

The proposed system packages each skill as a directory modeled after Anthropic Agent Skills: a `SKILL.md` interface, optional `scripts/`, `tests/`, `resources/`, and `references/`, plus a runtime catalog that exposes only skill names and descriptions until the agent chooses to load the full skill. New skills are created from inside the agent loop through a `skill_create` tool, validated through tests before registration, and revised when tests or runtime feedback fail.

The most distinctive part is skill-level memory. Each skill gets a sibling `.memory.md` file where the agent can append usage observations, failure modes, caveats, and lessons. That memory is loaded with the skill on later invocations, so experience accumulates around the capability that produced it rather than disappearing into a global chat transcript.

The evaluation uses 51 selected SkillsBench tasks, all run in Docker environments with automated verifiers. With human-authored skills, MUSE-Autoskill reaches 68.40% accuracy versus 67.28% for Codex and 61.21% for Hermes, all backed by GPT-5.5. For self-created skills, MUSE generates skills for 35 of 51 tasks; across all 51 tasks it reaches 60.35%, but on the 35 covered tasks it reports 87.94%. Transferring those generated skills into Hermes improves Hermes from 47.89% to 58.40%.

The cost story is also interesting. Skill creation costs a median 383K tokens and 164 seconds per generated skill, but generated skill usage is cheaper than human-skill usage in the reported covered-task subset. The authors claim the generated skills reduce noisy exploration by giving the agent a more concrete procedure.

## Key Claims

- **Skills work across agent runtimes.** Human skills improve all three tested agents by roughly 13-15 percentage points on the selected SkillsBench subset. This supports the broad claim that skill files are a useful abstraction, independent of this specific framework.
- **Self-created skills can outperform human skills on covered tasks.** On the 35 tasks where a successful initial trajectory exists, MUSE-generated skills reach 87.94%. This is plausible but partially circular: the skill is distilled from a successful trajectory on the same task family and then re-tested there.
- **Generated skills transfer.** Injecting MUSE-generated skills into Hermes improves Hermes by 10.51 percentage points. This is the strongest empirical point because it suggests the skill content is not purely tied to MUSE internals.
- **Per-skill memory is the right memory boundary.** The paper gives a clean design argument, but the reported experiments do not isolate how much gain comes specifically from `.memory.md` versus better skill packaging, tests, or context management.
- **Test-gated skills improve reliability.** Sensible design, but only 9% of generated skill packages include `tests/` in the reported anatomy. The lifecycle is stronger than the current empirical coverage.

## Strengths

- The lifecycle framing is practical. Creation, retrieval, use, evaluation, refinement, merging, pruning, and memory are the right nouns for a real skill system.
- The skill package schema is simple and portable: Markdown interface, optional code/tests/resources, eager catalog plus lazy full-body loading.
- The paper is unusually concrete about cost: token counts, latency, turns, generation cost, usage cost, and break-even estimates.
- The cross-agent transfer experiment is a good test of whether skills are externalized knowledge rather than hidden runtime behavior.
- The limitations section is honest about the 51-of-94 task subset, 35-of-51 generation coverage, single GPT-5.5 backbone, and same-task distillation risk.

## Gaps & Limitations

- The evaluation covers only 51 of 94 SkillsBench tasks, selected to avoid Docker failures across agents. The omitted tasks may be harder.
- Skill generation succeeds on only 68.6% of tasks. The framework is strongest after the agent has already succeeded at least once.
- Each generated skill comes from one successful trajectory. That can encode brittle source-run assumptions, and the paper reports an `hvac-control` regression where this happened.
- Cross-agent transfer is tested only from MUSE-Autoskill to Hermes. More runtimes and weaker/stronger model backbones would make the transfer claim more convincing.
- The paper does not cleanly ablate the individual contributions of per-skill memory, test gating, context compression, and procedural skill verbosity.
- The benchmark is still artificial compared with open-ended production work where task specs, file systems, credentials, safety boundaries, and user preferences drift over time.

---

**Attribution:** Huawei Lin, Peng Li, Jie Song, Fuxin Jiang, Tieying Zhang, arXiv:2605.27366, https://arxiv.org/abs/2605.27366
