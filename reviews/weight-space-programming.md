# Sparks of Weight-Space Programming: LLMs can natively read & write neural network weights

**Source:** https://rikiyat.github.io/blog/weight-space-programming/
**Authors:** Rikiya Takehi, Jayden Teoh, Alex Zhang, Omar Khattab; published on Rikiya Takehi’s website.
**Date:** 2026-11-02 (page citation metadata; no separate update date identified).
**Reviewed:** 2026-11-02 (UTC).
**Retrieved:** 2026-11-02 UTC; full HTML, 85,275 bytes, SHA-256
e28b19295586ec0c24d661057d81a7a31db9797a681ebb832383b5c1a1ed032a.

**Evidence revision:** Public experiment archive [RikiyaT/lm_understand-logs](https://github.com/RikiyaT/lm_understand-logs/tree/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f), commit
4d09ba6d6a7e891dd8063974dfe81b3d78e3494f.

**Verification:** Static review of complete article, archive documentation, selected raw evaluation JSON, final edit report/manifest, reconstruction and aggregation code, Qwen model card and cited research abstracts/framework passages. No model downloads, inference, training, source-code execution or independent experiment replication.
**Topic:** LLM-directed weight editing, neural program synthesis and mechanistic interpretability.
**Rights:** Article license not identified. Archive logs/data/networks CC BY 4.0; author scripts MIT; embedded MinAtar code GPL-3.0; third-party datasets retain their terms. Analysis only; no source code or model extraction.

---

## Verdict

⚠️ **Interesting but verify: convincing demonstrations of neural program construction and targeted repair, not a replacement for training.** Read this for the experimental design and the inspectable weight-edit artifacts. The strongest language-model result fixes pathological looping under a specified inference configuration; broad claims about adding capabilities, weight-only safety audits, avoiding forgetting and recursive self-improvement remain conjectures.

## Summary

The authors ask an unmodified frontier model, identified in their logs as OpenAI’s gpt-6-astra, to reason directly about neural weights rather than generate a conventional training loop. Their eight experiments span identifying toy networks, constructing small game policies, repairing a failed control policy, distinguishing fine-tuned language models and editing Qwen3.5-0.8B. This is a useful umbrella for several different regimes, not one uniformly zero-shot or data-free method.

The small-network demonstrations are often explicit algorithm synthesis: an editor knows the input semantics, output actions and game rules, then implements a policy in a fixed MLP. Reading examples exploit visible spatial organization or recognizable circuit statistics. Those are legitimate capabilities, but they do not establish arbitrary semantic decoding of anonymous large weight tensors.

The larger examples use an external Python harness and, when permitted, substantial behavioral feedback. Go uses batched practice games and Qwen uses generation or teacher-forced probes with activations. “No gradient descent” is accurate as the stated experimental constraint; “no learning from data” would not be. The editor updates its hypotheses and proposed weights using observations and scores.

The most consequential result is a sparse edit to two Qwen MLP output matrices. Published aggregate files agree with the headline MATH-500, GSM8K and IFEval gains. The authors also disclose two important failures: weights alone did not identify sycophancy, and analogous editing did not establish improved mathematical ability in a non-looping Gemma model. These failures materially narrow the optimistic conclusion.

## Key Claims and Evidence

All performance figures below are **author-reported**, with independent document consistency checks where specified—not independently reproduced measurements.

| Experiment | Reported result | What it establishes / does not establish |
|---|---|---|
| 1: game identification | Four custom grid-game policies correctly identified from 17,253 weights; architecture and input/action meanings supplied | Useful spatial/functional inference. Four selected policies (best of three training seeds) are not a general accuracy estimate or a comparison against simple weight statistics. |
| 2: diffusion shapes | Circle, square and triangle identified from 23,824 weights, without tools/forward passes | Output-weight geometry can reveal simple structure. Predicting outlines rather than filled shapes is an error, not proof that all possible implicit computation was absent. |
| 3: middle transformer blocks | Three training corpora correctly identified in two attempts each; copying-head locations match the reported behavioral diagnostic | Removing embeddings/readout and comparing against measured induction is a good control. Three known corpus options, repeated attempts on the same models and distributional rank clues limit generalization; not recovery of arbitrary vocabulary meaning. |
| 4: Kinetix repair | 0/256 baseline successes becomes 1,024/1,024 after changing 3.5% of weights | Strong task-specific policy repair given a scene and failed trajectory. A few added units implement reverse-then-accelerate control; no demonstrated robustness across new scenes or initial-condition families. |
| 5: MinAtar synthesis | Breakout/Seaquest/Asterix: 517.4/53.1/53.2 versus 100M-step PPO 15.8/5.6/25.8 | Impressive one-reply policy construction with source/rules supplied. Against 500M-step PPO (25.3/88.9/55.2), only Breakout clearly wins. No human-coded policy or equal-information coding-agent baseline. |
| 6: Go | Zero-feedback network wins 54.1–54.9% against small PPO; 50-pass network wins 70.0–78.5% against three tuned, same-size PPO seeds | Archive includes a stronger same-size, learning-rate-scanned baseline: do not dismiss it as only a tiny-network comparison. Zero-pass wins against that stronger baseline are only 26.3–42.6%. This is 9×9 Go versus these policies, not modern Go-engine strength. |
| 7: sycophancy | Four weights-only attempts fail; with attention-pattern probes, three trained pairs are identified | Positive result requires running the models on chosen texts. Attention correlation is not a causal localization proof or an evaluation-free safety audit. |
| 8: Qwen repair | MATH-500 7.9→48.1%; GSM8K 13.8→67.1%; IFEval 21.0→62.3% | Independently checked against unedited/p50c aggregate JSON. Cross-task benefit is real within this reported evaluation protocol, but largely consistent with restoring completion rather than acquiring new mathematics. |
| Follow-up: Gemma | MATH-500 6.8% base; 7.0/7.6/7.7/7.0% at 5/10/25/50 passes | Authors explicitly do not establish improvement. This is a useful negative result, not a universal impossibility theorem for weight editing. |

### What “50 forward passes” actually costs

A Go games pass can run up to **128 complete games**, not one neural-network evaluation. The 50-pass run used 47 games passes and three position passes (up to 256 positions each). A complete game itself requires repeated inference. Its final policy is an explicitly coded local heuristic for liberties, captures, saving groups and positional preference.

For Qwen, a pass can generate up to 512 practice solutions or teacher-force up to 1,024 texts. The archive records **158 turns, 80 Python runs, four conversations and 20.3 hours** for the 50-pass run, including a 4.7-hour service interruption. Thus a small pass count is not evidence of negligible FLOPs, latency or cost. Frontier-editor pretraining, reasoning tokens, probe generation and human prompt development also belong in a fair comparison. No end-to-end economic advantage over tuned alternatives is established here.

## Mathematical and Technical Assessment

### Sparse weights are not sparse behavior

The nominal edited region is 2 × 64 × 1,024 = **131,072 scalars**, or **0.016384%** of a rounded 0.8B denominator. The released bfloat16 edit manifest reports **130,188 actually changed bit patterns** (65,260 + 64,928); touched entries that round back to the base value are excluded. This is a precision distinction, not a material contradiction in the headline.

A direction-removal update can be written schematically as W′[:, S] = W[:, S] − αu(uᵀW[:, S]) for selected columns S and a normalized direction u. Normalization and α matter: this is an orthogonal projection only for unit u and α = 1. The archive describes different interventions at different budgets; the 10-pass global removal, 25-pass attention-head zeroing and 50-pass selected-column edit are not one monotone optimization trajectory.

For hidden activation h, changing an output matrix produces Δy = ΔW h. A few changed columns can affect every input that activates those neurons, and downstream nonlinear computation can amplify the change. Therefore “99.984% of parameters untouched” does **not** imply “99.984% of capabilities preserved,” nor does it guarantee absence of catastrophic forgetting, safety regressions or collateral changes. The excerpted benchmark suite is evidence of transfer on those tasks, not comprehensive preservation.

### Identifiability and circuit reasoning

Neural weights have symmetries: permuting hidden units with compensating adjacent weights can preserve the function while changing the raw numeric presentation. Input/output semantics, architecture, positional structure and training-distribution priors supply crucial information. The middle-block result is stronger than recognizing a paddle in first-layer weights, but remains a small closed-set classification task.

The cited [Transformer Circuits framework](https://transformer-circuits.pub/2021/framework/index.html) develops QK/OV composition and induction-head analysis. Applying known matrix-product diagnostics through an LLM is valuable automation; discovering that method in a conversation is not proof the method is new or absent from the editor’s pretraining. Intervention/ablation and predictive held-out tests would strengthen mechanistic explanations beyond plausible reasoning summaries.

### Qwen’s baseline deserves a decoding-control experiment

The [public Qwen card](https://huggingface.co/Qwen/Qwen3.5-0.8B/blob/main/README.md) independently confirms the thinking-loop warning and recommends tuning sampling and detecting/intercepting anomalous generations. At retrieval, its text-thinking recommendation uses temperature **1.0**, while the article evaluates **0.6** with top-p 0.95, top-k 20 and presence penalty 1.5. The card also contains benchmark settings using 0.6, so this is not enough to label the study’s configuration invalid.

Holding decoding fixed makes the reported weight-edit comparison meaningful. It does not establish superiority to a tuned temperature/penalty sweep, non-thinking mode, prompt adjustment, loop detection/restart, or another inference engine/version. Those are necessary practical baselines before treating sparse surgery as the cheapest fix. A causal explanation should also separate genuine repetition from merely long, unfinished answers; hitting a token limit alone is not proof of a loop.

The final editor report is unusually informative: in a paired held-out **practice** check, 576 of 579 rescues were formerly truncated outputs and aggregate accuracy on originally finished outputs was unchanged. It reports dose-response, layer-isolation and a norm-matched random control. We inspected that report, not every underlying intervention trace; these remain author-side controls, not independent confirmation.

## Strengths

- **Traceable artifacts:** experiment-to-file mapping, prompts, responses, tool records, final networks/diffs, hashes and scoring files are publicly available. Static inspection of apply_edit.py confirms base-tensor and reconstructed-tensor hash checks and exact base revisions.
- **Explicit constraints:** architectures, observations, action sampling, sticky actions, hidden opponents and tool budgets are substantially documented. Go includes three tuned same-size PPO seeds, beyond the small baselines visible in its setup summary.
- **Negative results and corrections:** weights-only sycophancy failure and Gemma failure are prominently discussed. The archive flags a stale GPQA graph value: 24.5% was an interim 149/198-question result; the final base aggregate is 22.7%.
- **Useful conceptual decomposition:** distinguish understanding weights, compiling a designed algorithm into weights, and repairing an existing network. Those can be researched separately rather than bundled into a claim of universal optimization.

## Gaps, Counterarguments and Reproducibility

1. **Selection and variance:** the archive explicitly excludes earlier prompt-version trials. Go reports one editor run per budget; Qwen uses separate runs rather than replicated budget-controlled trials. More episodes estimate each resulting policy’s performance, not the probability that a new editor attempt will succeed. Error bars across editor runs, training seeds and held-out tasks are needed.
2. **Information asymmetry:** PPO learns from reward/experience while the editor receives rich game rules, semantic channel descriptions and sometimes source code or a failure trajectory. Compare against hand-designed policies, an LLM writing ordinary code, and an LLM-plus-compiler with the same information. “Beyond humans or conventional algorithms” is not substantiated by such baselines here.
3. **Novelty is integration, not weights-as-programs:** [Tracr](https://arxiv.org/abs/2301.05062) already compiles programs into transformers, while [Fast Weight Programmers](https://arxiv.org/abs/2102.11174) address learned controllers writing fast weights. The new contribution is a general-purpose language-model editor operating on target weights through natural-language goals and tools. Those prior methods solve different problems and are not interchangeable baselines.
4. **No-gradient is narrower than no optimization:** practice-feedback-driven proposal and retention is adaptive optimization, even without backpropagation or fitting a conventional loss. This is compatible with the interesting result; it should not be sold as feedback-free training replacement.
5. **Reproduction is enabled, not turnkey or verified here:** the archive omits earlier trials, intermediate activations/draft weights, some Go per-game records and the 17GB Gemma sycophancy fine-tunes (rebuild material/hashes provided). It requires an external frontier editor and significant inference resources to repeat discovery. Applying an exact released edit is a different, easier reproducibility target.
6. **Benchmark boundaries:** repeated samples per problem are correlated and should not be treated as independent new problems. The release documents train/practice versus benchmark separation; this review did not independently audit every dataset overlap, all 1,125 claimed tool-free turns, grading output or pretraining contamination. “Tool-free” means Codex built-ins were disabled; external Python/probe tools were still available in designated experiments.
7. **Scaling and safety:** largest repaired model is 0.8B; inspected networks and diagnostics are specialized. Backdoor discovery, zero-data capability addition/unlearning, cross-architecture circuit grafting and recursive self-improvement are future proposals, not demonstrated outcomes. Sparse editing is not an automatic authorization or safety boundary.

## Practical Implications

For interpretability researchers and neural-program-synthesis practitioners, this is worth studying now. A promising workflow is **diagnose a narrow failure → propose a small weight edit → freeze and hash it → run paired held-out behavioral/regression checks**. The hash-checked diff is more actionable than the grand optimizer-replacement narrative.

Before adopting a patch: pin the base checkpoint and serving configuration, compare against decoding-only remedies and ordinary code/compilation baselines, replicate independent editor attempts, evaluate across tasks and seeds, and include safety and capability-retention regressions. Report total inference tokens/FLOPs/wall time rather than “passes” alone. Keep an exact rollback artifact. Nothing reviewed justifies unvalidated autonomous production weight edits.

## Evidence and Verification Ledger

- **Article:** complete public HTML acquired, canonical URL and four authors/publication date checked against metadata; hash above. Main text, setups, tables, limitations and embedded bibliography read.
- **Archive root/methods:** [README](https://github.com/RikiyaT/lm_understand-logs/blob/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f/README.md), [Go methods/results](https://github.com/RikiyaT/lm_understand-logs/blob/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f/exp6_go_from_scratch/README.md), [Qwen methods/results](https://github.com/RikiyaT/lm_understand-logs/blob/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f/exp8_math/README.md), and [license](https://github.com/RikiyaT/lm_understand-logs/blob/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f/LICENSE).
- **Raw scores checked:** [base](https://github.com/RikiyaT/lm_understand-logs/blob/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f/exp8_math/eval/unedited/merged.json) and [50-pass edit](https://github.com/RikiyaT/lm_understand-logs/blob/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f/exp8_math/eval/p50c/merged.json). Headline rounded values agree; no re-grading or full shard aggregation performed.
- **Edit checked:** [final answer](https://github.com/RikiyaT/lm_understand-logs/blob/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f/exp8_math/runs/p50c/final_answer.md), [manifest](https://github.com/RikiyaT/lm_understand-logs/blob/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f/exp8_math/runs/p50c/edit/manifest.json), [reconstruction code](https://github.com/RikiyaT/lm_understand-logs/blob/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f/exp8_math/code/apply_edit.py), [aggregation code](https://github.com/RikiyaT/lm_understand-logs/blob/4d09ba6d6a7e891dd8063974dfe81b3d78e3494f/exp8_math/code/merge.py), all static. Reconstruction names Qwen base revision 2fc06364715b967f1860aea9cf38778875588b17 and Gemma revision ac82b4e820549b854eebf28ce6dedaf9fdfa17b3.
- **Independent external context:** Qwen model-card loop warning and sampling recommendations checked; Tracr and Fast Weight Programmers abstracts and Transformer Circuits framework context consulted. Not a comprehensive literature review.
- **Not performed:** model execution, training, deployment, weight downloads, paid API calls, complete log audit, renderer screenshot or behavioral replication. Mathematical arithmetic and artifact markup/link checks are review checks, not experimental validation.

---

**Attribution:** Rikiya Takehi, Jayden Teoh, Alex Zhang and Omar Khattab, “Sparks of Weight-Space Programming,” 2026-11-02, https://rikiyat.github.io/blog/weight-space-programming/. Public experiment artifacts by the same authors, under the licenses noted above.
