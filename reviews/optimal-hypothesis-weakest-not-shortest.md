# The Optimal Choice of Hypothesis Is the Weakest, Not the Shortest

**Source:** https://arxiv.org/abs/2301.12987v4
**Author:** Michael Timothy Bennett
**Date:** 2023-01-30; v4 revised 2024-04-11
**Reviewed:** 2026-08-03
**Topic:** Induction, generalization, minimum description length, artificial general intelligence, enactive cognition
**License:** CC BY-NC-ND 4.0 on arXiv; summarize and cite, do not create derivative works

---

## Verdict

📚 **Good reference for questioning compression-as-intelligence, not a general replacement for MDL.** The paper gives a crisp formal counterpoint to "choose the shortest explanation": in its finite task formalism, the best hypothesis is the weakest valid one, meaning the least specific hypothesis measured by extension size. The result is worth reading, but its practical force depends on assumptions that do real work: uniform task distribution, a chosen implementable language, and toy binary-arithmetic experiments.

---

## Summary

The paper attacks a common theoretical instinct in AI: equating compression, short description length, simplicity, and generalization. It frames generalization as inferring from a known child task to an unknown parent task. The question is which valid hypothesis inferred from the child is most likely to also solve the parent.

Bennett defines "weakness" as the cardinality of a statement's extension: roughly, how many possible decisions or completions the statement allows. A weaker hypothesis asserts less and therefore contradicts fewer possible future observations. In this formalism, maximizing weakness is necessary and sufficient to maximize the probability that induction generalizes from child to parent, assuming tasks are uniformly distributed.

The paper then argues that minimum description length is neither necessary nor sufficient. It gives a counterexample where the shortest valid hypothesis is not the weakest one. The practical slogan is "explanations should be no more specific than necessary," explicitly distinguished from Ockham's Razor and from syntactic simplicity.

The empirical section compares weakness maximization against minimum description length on toy 8-bit binary addition and multiplication tasks. Weakness generalizes more often: reported generalization rates are 1.1x to 5x those of MDL, with average extent of generalization at 1.03x to 1.56x. The appendix repo includes code and result artifacts for the experiment machinery.

## Key Claims

- **Compression is not the same thing as generalization.** Strong conceptual claim. The paper shows that shorter formulas and weaker formulas can diverge, so description length is not guaranteed to pick the hypothesis most likely to generalize in the stated formalism.
- **Weakness maximization is optimal under uniform task distribution.** This is the formal core. It is persuasive inside the defined task model, but the uniform distribution assumption should not be treated as a free description of real-world tasks.
- **Weakness means extension size, not vagueness or shortness.** This is the useful vocabulary. A hypothesis can be syntactically long but weak if it rules out little; a short sentence can be overly specific.
- **DeepMind's Apperception Engine may work because it prefers weak hypotheses.** Interesting interpretation, but more explanatory than proven. The paper uses it as a lens on prior work, not as a new reproduction of that system.
- **Neural networks might benefit from optimizing weakness.** Speculative. The paper gestures at hallucination, inconsistency, and grokking, but does not provide a neural training method or benchmark evidence.

## Strengths

The distinction between simplicity and weakness is genuinely useful. "No more specific than necessary" is a better operational phrase than "shortest" for many induction and agent-design problems.

The paper is admirably direct about its formal assumptions. It repeatedly limits the proof to a mathematical formalism of enactive cognition, finite implementable languages, well-defined weakness, and uniformly distributed tasks.

The experimental section is small but not empty. It gives concrete binary arithmetic comparisons and points to a public technical-appendices repository with experiment code and results.

The counterexample against MDL is the most reusable part. Even if one rejects the broader philosophical frame, the paper still shows that description length and extension size are different optimization targets.

## Gaps & Limitations

The uniform task distribution assumption is doing heavy lifting. Real tasks are not uniformly sampled from all possible child/parent task combinations. Domain priors, data distributions, language choice, architecture, and training procedure all matter.

The experiments are toy symbolic tasks, not evidence that weakness optimization improves modern neural networks or LLM agents. The paper's neural-network discussion is a research proposal, not a demonstrated method.

Weakness depends on the chosen vocabulary or implementable language. A bad language can make the "weakest" hypothesis useless or unrepresentative; a good language encodes strong domain bias before the proxy is even applied.

The appendix/code situation is helpful but mixed for reuse. The arXiv paper is CC BY-NC-ND 4.0, the technical-appendices repo is GPL-3.0 at the root, and newer Stack Theory Suite subdirectories are Apache-2.0. Treat the paper as cite/summarize material unless reviewing specific code licenses separately.

---

**Attribution:** Michael Timothy Bennett, "The Optimal Choice of Hypothesis Is the Weakest, Not the Shortest," Proceedings of the 16th International Conference on Artificial General Intelligence, 2023; arXiv:2301.12987v4, CC BY-NC-ND 4.0.
