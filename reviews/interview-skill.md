# interview-skill (olelehmann100kMRR/interview-skill)

*Review #280 | Source: https://github.com/olelehmann100kMRR/interview-skill | License: none stated | Author: olelehmann100kMRR | Reviewed: 2026-03-27 | Stars: 26*

## Rating: 🔥🔥🔥🔥

---

## What It Is

A single OpenClaw/Claude Code skill (`SKILL.md`) that acts as a universal pre-flight planning agent for any creative or content creation task. 26 stars, created yesterday (2026-03-27), no license.

The premise: every "create X" request hides dozens of unconstrained decisions. Without an interview, those decisions get filled with safe, generic defaults. The result is technically correct but mediocre. This skill intercepts before building starts.

---

## What It Does (4 Steps)

**Step 1: Classify the asset.** Figure out what's being built. If ambiguous, ask. This takes two seconds but shapes everything: what context matters, what questions to ask, what specialized skill (if any) handles actual creation.

**Step 2: Silent spec expansion.** Read all available workspace context (voice docs, audience profiles, style guides, past examples, brand docs). Then expand the one-sentence request into the fullest possible spec and show it to the user before asking anything.

The explicit reference is Anthropic's internal planner agent — described as taking "create a 2D retro game maker" into a 16-feature spec across 10 build phases. The instruction: "Be ambitious about scope. Don't under-spec." For a landing page, that means every section with its strategic purpose, emotional beat, objection handled, proof used, and transition.

Key constraint on the spec: **substance, not implementation.** Define what the asset needs to deliver (this section must overcome the main objection), not how to execute it (font, word count, color). Over-specifying implementation details creates error propagation — one wrong constraint cascades. Defining deliverables leaves execution room.

**Step 3: Targeted interview.** Take the unresolved gaps from the silent expansion and turn them into questions. Rules:

- **Gating test before presenting any question:** "Does this extract something I literally cannot build a good version without?" If no, cut it. Logistics are never the answer (format, URLs, dates, file types — figure those out yourself).
- **Propose a recommended answer for each question.** Don't ask blank questions. The user reacts to something concrete. Faster, better results.
- **Calibrate depth to complexity:** 2-3 questions for simple assets, 3-5 for medium, 5-8 for complex. But even 2-3 questions should be the hardest, most specific ones.
- **Mix multiple choice and open-ended.** Multiple choice for predictable answer spaces. Open-ended for questions where the real answer lives in the user's head and can't be reduced to 4 options: the core insight, the specific story, the objection they're most worried about.

Examples of bad vs. good questions:
```
Bad:  "What's the angle?" (too abstract, forces the user to do your job)
Bad:  "How formal should this be?" (read the style guide)
Bad:  "Who's the audience?" (read the audience profile)

Good: "What's the one thing you want someone to remember after reading this?"
Good: "Is there a specific example, stat, or story you want to anchor this around?"
Good: "What's the main objection someone would have, and how do you want to handle it?"
Good: "What makes this different from what everyone else is saying about this topic?"
```

The test: if you removed the question and the output would be noticeably worse, keep it. If roughly the same, cut it.

**Step 4: Brief, approve, then build.** Synthesize context + answers into a structured brief covering: what, who, core idea, angle/hook, structure, proof, CTA, tone, constraints. Present it. User approves or adjusts. Then either hand off to a specialized skill or build directly.

---

## What's Actually Good Here

**The silent expansion before interviewing** is the structural insight. Most "ask before building" patterns go straight to questions. This one first shows the user what a fully expanded version of their request looks like — which often surfaces misalignments they couldn't have articulated without seeing the expanded scope. The interview then fills the remaining gaps.

**The question quality filter** is the operational core. The default mode for AI systems is to ask clarifying questions that feel thorough but extract no substance — logistics, preferences, format choices. This skill's rule (cut anything that doesn't extract something you can't build without) is a direct counter to that pattern.

**Proposing answers vs. asking blank questions** is well-established UX for AI interviews but explicitly stated here. The user reacts to something concrete, which is dramatically faster than generating from scratch.

**The depth calibration is honest.** Most skills claim to be comprehensive. This one explicitly says a simple post needs 2-3 questions, and they should be the hardest ones — not a full 8-question interview to prove thoroughness.

---

## Limitations

- No license. "No explicit license" means all-rights-reserved by default. The content is clearly intended to be used (it's an OpenClaw skill published publicly), but there's no formal permission to redistribute or modify.
- Narrow scope: it's a planning skill, not a building skill. You still need other skills (or raw capability) for the actual creation.
- The reference to Anthropic's internal planner agent ("in one case, a 16-feature spec across 10 build phases") is probably marketing copy or secondhand description — not a documented Anthropic methodology.

---

## Relevance

🔥🔥🔥🔥 — The skill itself is immediately usable in any OpenClaw/Claude Code context that does content or creative work. The patterns are worth extracting into your own prompt engineering even without the skill framework.

**The extractable patterns:**
1. Silent expansion (show the expanded spec) before asking questions
2. Question quality gate: "Does this extract something I cannot build without?"
3. Propose an answer with every question
4. Substance questions > logistics questions
5. Brief-approve-build sequence instead of diving directly into creation

No license — use for personal/educational purposes. Note "no explicit license" in any attribution.
