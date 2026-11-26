# Principles of Outcome Engineering

**Source:** https://www.outcomeengineering.systems/
**Author:** Nader Dabit. The homepage has no byline; authorship is taken from its footer link to [dabit3/outcome-engineering](https://github.com/dabit3/outcome-engineering) and from that repository's commit authors.
**Date:** Undated on the page. The site's `Last-Modified` header is 2026-11-25 19:17:59 UTC. The linked repository was created 2026-11-21 and the reviewed commit was authored 2026-11-25 19:17:06 UTC.
**Reviewed:** 2026-11-26 (UTC).
**Retrieved:** 2026-11-26 UTC. Homepage HTML (8,076 bytes), SHA-256 `71939c8232600e573b25c8ed4ee4d9c72b05423ef58a2b0a04ed84f8fba39060`.
**Evidence revision:** Live site https://www.outcomeengineering.systems/ (a single page; no subpages). Linked source repository [dabit3/outcome-engineering](https://github.com/dabit3/outcome-engineering), commit [`24b9d5a371319fa4da2f9696d89a2334c3a41bb1`](https://github.com/dabit3/outcome-engineering/commit/24b9d5a371319fa4da2f9696d89a2334c3a41bb1) (README, `index.html`, and repository layout). The footer also credits “Design inspired by [paco.me](https://paco.me/).”
**Verification:** Static reading of the homepage and the linked public repository. There is no implementation, data, or experiment to reproduce.
**Topic:** A short principles essay on treating durable, self-proving outcomes as the unit of work for proactive, perpetual, self-verifying software systems.
**Rights:** No license specified on the site or repository — educational/personal use only. This review quotes short excerpts and otherwise paraphrases. Nothing is extracted into other directories.

---

## Verdict

📚 **Good reference: a clear vocabulary for a shift from tasks to durable outcomes, with no evidence and no method beyond the definitions.** Read it if you are deciding what to hand a long-running agent. The useful move is to state what should remain true, how the system will know it is true, and what the system may touch. It is a one-page manifesto, not a framework, playbook, or system.

An interactive visual guide to the eight principles is in the matching [HTML page](outcome-engineering.html).

---

## Summary

The thesis is that the unit of work should no longer be a goal or a ticket you finish once. Humans should write a statement of *what should remain true*, and a “proactive, perpetual, self-verifying” system should be responsible for that statement for as long as anyone depends on it. The site is a single page of eight italicized lead-ins, two worked contrasts, and a closing prediction that this will “redefine software engineering going into 2027.”

The first contrast is goal versus outcome: “Build this Android app” is a goal; “Build an Android version of our iOS app and keep it at parity forever” is an outcome. The second is task versus a measurable target: “Fix the bug from this support ticket” is a task; “every support ticket caused by a bug ends in a shipped fix and a reply to the customer” is “a target the system can measure itself against.” The essay says the quality of that definition sets the ceiling on what the system can deliver, and that writing it is “the important work we still do by hand.”

The remaining principles describe how people and systems should share the work. Skills, Loops, `/goal`, automations, verification, memory, context, plugins, connectors, and subagents “all matter,” but should be as invisible as compiled code: you can read them, you rarely have to manage them. Human attention is reserved for judgment calls, which the system should surface. “Done” is a state to keep true, not a finish line; the outcome is the durable asset and the code under it can be rewritten as many times as it takes. Ambition can grow because finishing and maintaining forever was the hard part and the system can now do both. Authority must be bounded in the same breath: you state what the system is allowed to touch, then leave it alone. Experimentation is cheap because a wrong guess is no longer an opportunity cost; the system can be wrong “N times on the way to being right (and in parallel).”

The close is exhortation: “fully give in to our imagination, embrace ambition, and forget that the underlying system and machinery exist.” The only evidence offered is the author’s observation that “some of the best engineers I know” already work this way.

## Key Claims

- **The unit of work should be an outcome, not a goal or task.** Supported only by the two contrasts above. The distinction is clear and usable; no cases beyond those two sentences are given.
- **A good outcome carries its own proof, and the definition is the ceiling.** This is a design rule, not a measured result. The essay does not say how to write a proof, how to resolve conflicting outcomes, or what to do when a target is gameable.
- **Machinery should be invisible, like compiled code.** A list of agent-stack nouns is named and then set aside. None of those mechanisms are defined or compared.
- **People should step in only for judgment calls, which the system should surface.** Plausible allocation of attention. No account of missed notifications, bad judgment routing, or when a human must still supervise.
- **“Done” is a state; the system stays responsible and may improve the outcome unasked; the outcome outlives the code.** This is the sharpest operational claim. It assumes a system that can watch the world, re-verify, and rewrite implementations safely. That assumption is stated, not shown.
- **Ambition can be unbound because finishing and maintaining is now tractable, but authority must be bound so a perpetual system can be left alone.** The pairing is the essay’s best piece of advice. There is no guidance on writing limits, auditing them, or revoking them.
- **Wrong guesses are cheap if the system can try N times in parallel.** Follows if experiments are isolated and reversible. The essay does not discuss cost, blast radius, or correlated failures.
- **This is becoming possible because of “proactive, perpetual, self-verifying systems,” and will redefine software engineering going into 2027.** A prediction, plus an anecdotal “best engineers I know.” No product, benchmark, or case study is cited.

## Strengths

- **Two memorable contrasts.** Goal versus outcome, and task versus a target the system can measure, are easy to reuse when writing prompts or acceptance criteria.
- **The ceiling sentence.** Treating outcome definition as the scarce human work is a cleaner split than “write better prompts” or “add more tools.”
- **Ambition and authority are paired.** A perpetual, proactive system without a stated limit is a hazard; saying both in one breath is the essay’s most practical idea.
- **Code is treated as disposable.** “The outcome is the durable asset; the code beneath it can be rewritten as many times as it takes” follows from the rest of the argument and is stated plainly.
- **Short and self-contained.** Eight principles, two examples, no tooling pitch.

## Gaps & Limitations

- **No evidence.** There are no case studies, failure stories, measurements, or links to a system that already works this way. The 2027 claim and the “best engineers I know” line are unearned.
- **Not a method.** There is no procedure for writing an outcome, choosing a proof, setting authority, or handling conflict, drift, or withdrawal of an outcome. Readers have to invent the practice.
- **Machinery is named, not examined.** “Skills, Loops, `/goal`” and the rest are left undefined. The compiled-code analogy hides the actual reliability, security, and cost problems of long-running agents.
- **Unasked improvement is underspecified.** Looking for ways to make an outcome “better” without being asked can violate the spirit of a bound authority if “better” is not itself defined and limited.
- **No license.** The site and repository specify none, so this is analysis of a public page, not a cue to copy the source.

---

**Attribution:** Nader Dabit, *Principles of Outcome Engineering*, https://www.outcomeengineering.systems/, also https://github.com/dabit3/outcome-engineering. No license specified.
