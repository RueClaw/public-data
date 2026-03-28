# council-of-high-intelligence (0xNyk/council-of-high-intelligence)

*Review #283 | Source: https://github.com/0xNyk/council-of-high-intelligence | License: CC0 (public domain) | Author: 0xNyk | Reviewed: 2026-03-28 | Stars: 29*

## Rating: 🔥🔥🔥🔥

---

## What It Is

A Claude Code skill that spawns 11 historical thinker personas as parallel subagents for structured multi-perspective deliberation. The problem it's solving: LLMs collapse toward a single perspective. Even when you ask Claude to "consider all angles," it's still one model making one coherent argument. This skill makes the disagreement structural — different agents with different epistemological commitments, running in parallel, cross-examining each other.

CC0 (public domain). Install with one script, available as `/council` immediately.

---

## The 11 Members

The roster is deliberately chosen for *polarity* — not just variety, but specific counterweights:

| Member | Domain | Model | Polarity |
|--------|--------|-------|---------|
| Aristotle | Categorization & structure | opus | Classifies everything |
| Socrates | Assumption destruction | opus | Questions everything |
| Sun Tzu | Adversarial strategy | sonnet | Reads terrain & competition |
| Ada Lovelace | Formal systems & abstraction | sonnet | What can/can't be mechanized |
| Marcus Aurelius | Resilience & moral clarity | opus | Control vs acceptance |
| Machiavelli | Power dynamics & realpolitik | sonnet | How actors actually behave |
| Lao Tzu | Non-action & emergence | opus | When less is more |
| Feynman | First-principles debugging | sonnet | Refuses unexplained complexity |
| Linus Torvalds | Pragmatic engineering | sonnet | Ship it or shut up |
| Miyamoto Musashi | Strategic timing | sonnet | The decisive strike |
| Alan Watts | Perspective & reframing | opus | Dissolves false problems |

The polarity pairs are the design insight:
- **Socrates vs Feynman**: both question, but Socrates destroys top-down; Feynman rebuilds bottom-up
- **Aristotle vs Lao Tzu**: Aristotle classifies; Lao Tzu says structure IS the problem
- **Ada vs Machiavelli**: formal purity vs messy human incentives
- **Torvalds vs Watts**: ship it vs does the problem exist
- **Torvalds vs Musashi**: ship it now vs wait for the perfect moment

Each member is assigned to a model tier (opus for deeper reasoning work, sonnet for tactical/pragmatic roles), and the `--models` flag enables routing different members to different providers to reduce model monoculture.

---

## The Deliberation Protocol (3 Rounds)

**Round 1: Blind-first parallel analysis** (400 words each)
All selected members receive only the problem statement. Run in parallel. No peer outputs visible. This prevents anchoring — the first agent's framing infecting everyone else's analysis.

**Round 2: Cross-examination** (sequential, 300 words each)
Each member receives all Round 1 outputs and must: (1) name who they most disagree with and why, (2) name who strengthened their position, (3) state whether anything changed their view, (4) restate their position. Sequential so later members can reference earlier cross-examinations.

**Round 3: Synthesis** (100 words max)
Crystallization only. Socrates gets exactly one question — not a series. Then states his position.

**Anti-recursion:** If Socrates re-asks a question already answered with evidence, coordinator invokes the "hemlock rule" — immediate 50-word position statement, no more questions.

**Anti-convergence:** Required dissent quota (at least 2 non-overlapping objections before consensus can be declared), novelty gate (Round 2 must add something not in Round 1), and a mandatory counterfactual pass if >70% agreement forms by end of Round 2: *"Assume the current consensus is wrong. What is the strongest alternative and what evidence would flip the decision?"*

**Tie-breaking:** 2/3 majority = consensus (minority report filed). No majority = present the dilemma to the user, don't force consensus. Domain expert weighting: the member whose domain most directly matches the problem gets 1.5x weight.

---

## The Output: Council Verdict

The structured deliverable:
- Consensus position (or "No consensus reached")
- Key insights by member (1-2 sentences each)
- Points of agreement
- Points of disagreement
- Minority report (dissenting positions with their strongest arguments)
- Unresolved questions
- **Epistemic Diversity Scorecard**: perspective spread (1-5), provider spread (1-5), evidence mix (% empirical / mechanistic / strategic / ethical / heuristic), convergence risk (Low/Medium/High)
- Recommended next steps

---

## Invocation Examples

```bash
/council --triad architecture Should we use a monorepo or polyrepo?
/council --full What is the right pricing strategy for our SaaS product?
/council --members socrates,feynman,ada Is our caching strategy correct?
/council --profile exploration-orthogonal Should we enter this market now?
/council --profile execution-lean --triad ship-now Should we ship this release candidate today?
```

**Pre-defined triads** (11 domain-matched combinations):
- `architecture` → Aristotle + Ada + Feynman (classify + formalize + simplicity-test)
- `strategy` → Sun Tzu + Machiavelli + Aurelius (terrain + incentives + moral grounding)
- `ethics` → Aurelius + Socrates + Lao Tzu
- `debugging` → Feynman + Socrates + Ada
- `shipping` → Torvalds + Musashi + Feynman
- `product` → Torvalds + Machiavelli + Watts
- `founder` → Musashi + Sun Tzu + Torvalds

**Two alternative profiles:**
- `exploration-orthogonal` — 8 members for maximum epistemic separation, unknown-unknown discovery
- `execution-lean` — 5 members when speed-to-decision is the priority

---

## The Agent Definitions Are the Real Work

Each of the 11 agents is a detailed `.md` file with:
- **Identity paragraph**: not just "you are Feynman" — specific epistemological stance, what they see that others miss, what they tend to miss (explicit blind spots)
- **Analytical method**: 5-step methodology with domain-specific questions
- **Deliberation grounding protocol**: anti-patterns to avoid (Socrates: depth limit, no re-asking, hemlock rule; Feynman: max 2 analogies, acknowledge limits; Torvalds: max 1 profanity-laden rant, acknowledge when it's not an engineering problem)
- **Output format (standalone)**: structured template for when invoked directly outside council

The "where I may be wrong" section in each agent is particularly well-crafted — Feynman explicitly says his bottom-up approach misses systemic patterns that only emerge at higher abstraction. Torvalds says his pragmatism dismisses genuinely important abstractions.

---

## What's Good Here

**The anti-convergence machinery** is the structural insight. The dissent quota, novelty gate, and mandatory counterfactual pass when agreement forms too early directly address the core failure mode of "brainstorm with AI" — which is that it generates consensus around whatever framing was introduced first, dressed up as multiple perspectives.

**Polarity as a design constraint** beats "diverse perspectives." Diverse perspectives can still all be basically the same epistemological type (empirical, careful, structured). Putting Lao Tzu against Aristotle, or Watts against Torvalds, forces genuine collision of incompatible worldviews, not just variation within one.

**Evidence type labeling** (`empirical`, `mechanistic`, `strategic`, `ethical`, `heuristic`) in the Epistemic Diversity Scorecard detects monocultures in reasoning type, not just in opinions.

**The blind-first Round 1** is necessary and often missed. Without it, the first agent's framing anchors everything downstream.

---

## Limitations

- 29 stars, one maintainer, three weeks old — low bus factor
- The quality of the output depends entirely on whether Claude Code's subagent tool calling actually works well for multi-agent sequential cross-examination. This is a complex orchestration pattern.
- Model costs: `--full` with opus for 5 members across 3 rounds is not cheap. The README says nothing about token cost expectations.
- The historical persona framing is evocative but also somewhat arbitrary — "Feynman" is really just "first-principles empiricist" and could have been named anything. The names add flavor but could also mislead if taken literally.
- No tests for whether the anti-convergence mechanisms actually work as described.

---

## Relevance

🔥🔥🔥🔥 — The structural approach to multi-perspective deliberation is sound. The anti-convergence machinery (dissent quota, counterfactual pass, novelty gate) directly addresses the real failure mode of AI-assisted brainstorming.

**Direct uses:**
- Hard architectural decisions for ODR or VOS (the `architecture` triad is immediately applicable)
- Marcos agent design decisions where competing values (helpfulness vs accuracy vs privacy vs autonomy) need structured arbitration — the `ethics` triad exists for this
- Strategic decisions for Bluesun (the `founder` and `strategy` triads)

**Extractable patterns without the full skill:**
1. The polarity pair design — when building any multi-agent deliberation, don't just vary expertise, vary epistemological commitment
2. Blind-first Round 1 — always run parallel agents without showing peer outputs before they produce their independent analysis
3. Anti-convergence pass — if agreement forms early, run the counterfactual
4. Evidence type labeling — categorize claim types to detect reasoning monocultures

CC0 / public domain. Install: `./install.sh`. Cloned to `~/src/council-of-high-intelligence`.
