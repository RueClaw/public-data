# WikiSkill: Compiling Agent Experience into Persistent Knowledge for Skill Evolution

**Source:** https://arxiv.org/abs/2608.27454
**Author:** Liyan Tang, Cyrus Rashtchian, Chun-Sung Ferng, Andrew Tomkins, Da-Cheng Juan, Tu Vu
**Date:** 2026-08-27
**Reviewed:** 2026-08-28
**Topic:** Agent skills, persistent knowledge, skill evolution, agent memory

---

## Verdict

📚 **Good reference for skill-evolution architecture.** WikiSkill is one of the cleaner recent arguments for separating raw traces, durable knowledge, and executable skills instead of treating skill updates as the only persistent artifact. The empirical case is useful because the paper ablates the wiki layer directly, but the work is still a research framework: it directly injects skills into the agent prompt, uses small validation splits, and does not yet solve skill retrieval, long-horizon online adaptation, or wiki pruning.

---

## Summary

WikiSkill proposes a three-layer workspace for agents that learn reusable skills from experience. The Raw Layer stores immutable execution traces, the Wiki Layer compiles those traces into persistent pattern pages and evolution logs, and the Skill Layer stores executable `SKILL.md` procedures plus `PURPOSE.md` provenance tying each skill back to the wiki patterns that motivated it.

The key design move is that skills can be rolled back when validation performance drops, but the wiki persists. This lets later skill proposals learn from rejected diffs, recurring errors, and successful strategies without making every lesson immediately executable. That is a better separation of concerns than treating optimization history, memory, and active procedures as one object.

The evolution loop has four parts: an inference agent runs training tasks using the active skills, a wiki maintainer consolidates sampled traces into pattern pages and logs, a skill proposer reads the wiki and selected traces to propose one atomic skill change, and a validation gate accepts or rejects the skill update. The inference agent is intentionally blocked from reading the wiki during training rollouts; the authors report that letting it read the wiki makes trajectories less useful for skill development.

The experiments cover five benchmarks: LiveMathematicianBench, SealQA, SpreadsheetBench, OfficeQA, and ALFWorld. Across Qwen, Gemma, and Gemini models, WikiSkill beats Trace2Skill, EvoSkill, SkillOpt, and no-skill baselines on average. The reported gains are largest for stronger Qwen models: +12.3, +17.5, and +23.9 average points for Qwen-3.5-4B, Qwen-3.5-9B, and Qwen-3.6-27B respectively.

The transfer results are especially interesting. Skills evolved by one model often help another model, and sometimes transferred skills beat self-evolved skills. That supports the idea that skill discovery and skill execution are separate capabilities, and that agent skill libraries should be treated as shared knowledge assets rather than per-model caches.

## Key Claims

- **A persistent wiki improves skill evolution** — With Gemini-3.5-Flash, giving the skill proposer wiki access while keeping the inference agent away from the wiki improves average performance from 48.7% to 63.7% in the ablation.
- **Skill evolution complements model scaling** — WikiSkill gains increase across Qwen model scale, and Qwen-3.5-9B with WikiSkill outperforms Qwen-3.6-27B without skills on average.
- **Skills transfer across models** — Cross-model transfer often improves no-skill baselines, and Qwen-3.6-27B-evolved ALFWorld skills lift Qwen-3.5-9B to 70.2% versus 63.4% with its own skill.
- **Not all skills transfer cleanly** — Spreadsheet skills from Qwen-3.5-4B hurt Gemini-3.5-Flash, suggesting that low-level model-specific workarounds can constrain stronger models.
- **Direct wiki access during rollouts can degrade skill quality** — The paper argues that if the inference agent solves tasks from the wiki rather than the active skills, later traces become less diagnostic for improving skills.

## Strengths

- The raw/wiki/skill split is concrete and easy to map onto real agent workspaces.
- The paper ablates persistent knowledge accumulation rather than only asserting that memory should help.
- Validation rollback applies to skills but not to the wiki, which preserves rejected attempts and failure evidence without shipping bad procedures.
- The `PURPOSE.md` link between each skill and its motivating wiki patterns is a strong provenance pattern.
- Cross-model transfer is a useful test of whether the learned skill is general procedural knowledge or just a source-model workaround.
- The limitations section names real deployment issues: skill retrieval, strict validation gates, wiki pruning, and missing very long-horizon tasks.

## Gaps & Limitations

- Skills are injected directly into the inference agent prompt. The paper intentionally avoids testing skill retrieval and triggering, which are unavoidable once a skill library grows.
- Validation sets are small, and strict accept-only-if-better gating can reject neutral infrastructure changes that enable later gains.
- The wiki accumulates indefinitely. There is no automated pruning, merging, contradiction handling, or staleness policy.
- Benchmarks are still short compared with multi-hour operational tasks where tools, credentials, user intent, and environment state drift.
- WikiSkill studies skill quality while holding the broader agent harness fixed. That is good experimentally, but production agents also need memory security, permissioning, retrieval, observability, and rollback of bad knowledge.
- The framework records raw traces containing reasoning/tool outputs; real deployments would need privacy, retention, and redaction rules.

---

**Attribution:** Liyan Tang, Cyrus Rashtchian, Chun-Sung Ferng, Andrew Tomkins, Da-Cheng Juan, Tu Vu, arXiv:2608.27454, https://arxiv.org/abs/2608.27454, CC BY 4.0
