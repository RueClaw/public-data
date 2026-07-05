# Anti-Convergence Deliberation Protocol

**Source:** [0xNyk/council-of-high-intelligence](https://github.com/0xNyk/council-of-high-intelligence)
**License:** MIT
**Extracted:** 2026-07-05

## Problem

Asking one model to "consider multiple perspectives" often produces one fluent frame with cosmetic variation. Even multi-agent debate can collapse into groupthink when agents see an early answer, defer to identity labels, update because consensus is forming, or let a coordinator infer a verdict from prose.

## Pattern

Run deliberation as a bounded protocol that makes disagreement structural and measurable:

1. **Select diverse methods, not just personas.** Each seat should have a distinct reasoning method and domain. Avoid panels where every member is a careful analytical generalist with different labels.
2. **Restate before analyzing.** Require each seat to restate the problem and provide an alternate framing. Divergent restatements reveal that the question itself may be unstable.
3. **Analyze blind-first.** Round 1 happens independently, without peer outputs, so the first answer cannot anchor everyone else.
4. **Anonymize cross-examination.** Present peer outputs as stable anonymous labels (`Member A`, `Member B`) during critique rounds to reduce identity and self-bias.
5. **Require named updates.** A seat may update its position only if it can name the specific flaw in its earlier reasoning. Repetition or emerging consensus is not enough.
6. **Force dissent checks.** If agreement forms too early, run a counterfactual pass: assume the consensus is wrong and steelman the strongest alternative.
7. **Parse final stances.** Every final answer ends with a machine-readable line:

   ```text
   STANCE: <option> | CONFIDENCE: high|med|low | DEALBREAKER: yes|no
   ```

8. **Tally, do not intuit.** Compute confidence-weighted votes and report no-consensus when no option clears the threshold. Include dealbreaker dissent as a minority report.
9. **Separate synthesis.** Have a non-deliberating chairman/synthesizer produce the final verdict from the transcript instead of letting one panel member dominate the close.

## Why It Works

The protocol attacks the main convergence paths directly:

- blind-first work limits anchoring
- anonymization reduces status/name effects
- method diversity reduces "same model, same frame" repetition
- named-update rules block social-pressure updates
- structured stance lines prevent the coordinator from inventing consensus from prose
- no-consensus output preserves real uncertainty

## Minimal Version

For small decisions, use three seats:

```text
Round 0: each seat restates the problem and alternate framing
Round 1: blind independent analysis, 200 words max
Round 2: anonymized critique of the other two outputs, 150 words max
Round 3: final stance line + 75-word rationale
Synthesis: tally votes, list unresolved questions, give next step or no-consensus
```

## Implementation Notes

- Keep round budgets tight. Long debate invites style drift and cost blowup.
- Select the domain-weight seat before analysis begins, not after seeing positions.
- Do not infer missing stance lines; re-prompt or mark the seat degraded.
- Track provider/model diversity separately from persona diversity.
- Treat personas as mnemonic lenses, not claims of faithful historical simulation.
- Record fallbacks and degraded seats in the final metadata.

## Good Fits

- architecture tradeoffs
- launch/no-launch decisions
- product strategy
- policy or ethics questions
- high-uncertainty technical bets
- postmortem alternatives and counterfactuals

## Poor Fits

- factual lookup
- simple implementation tasks
- decisions with one hard external constraint
- situations where all needed evidence is unavailable

---

**Attribution:** 0xNyk/council-of-high-intelligence, MIT License.
