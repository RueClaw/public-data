# Learn Quiz Skill Gist

**Source:** https://gist.github.com/ThariqS/1389dcdff9eba4789887a2211370f06b
**Author:** ThariqS
**Date:** 2026-06-01; latest observed update 2026-06-06
**Reviewed:** 2026-06-06
**Topic:** AI tutoring skill, session comprehension checks, Socratic code review support

---

## Verdict

📚 **Good small reference for teach-back driven tutoring, not a complete skill.** The gist captures a useful operating mode for an assistant that should teach throughout a session instead of dumping an explanation at the end. It is too short, unlicensed, and tool-specific to install directly, but the teaching loop is worth adapting.

---

## Summary

This gist is a single Markdown file named `SKILL.MD` under the description "Learn Quiz." It defines an assistant posture for helping a human understand a coding or debugging session deeply: explain incrementally, track what the learner should understand, ask them to restate their understanding, fill gaps, and quiz before moving on.

The strongest idea is the teach-back loop. Instead of assuming understanding because an explanation was delivered, the assistant has the learner reconstruct the problem, solution, design tradeoffs, edge cases, and impact. That is a better fit for real technical learning than a final recap after the work is already over.

The gist also pushes for maintaining a running Markdown checklist of learning objectives. That gives the session a durable artifact and avoids losing track of concepts across a long debugging or implementation flow.

The weak parts are mainly operational. The prompt references a specific question tool and a `/goal` command without defining how those work in other runtimes. It also uses absolute mastery gates that could block normal task completion if applied to every session.

## Key Claims

- **Teaching should happen incrementally, not only at the end.** Strong. It matches how people build mental models during complex code work.
- **The learner should restate their understanding before the assistant fills gaps.** Strong. This is a practical way to reveal false confidence and missing causal links.
- **A running checklist should track problem, solution, decisions, edge cases, and impact.** Useful, especially for long sessions or onboarding.
- **The session should not end until understanding is verified.** Too absolute. Good for explicit tutoring mode, bad as a default for ordinary engineering tasks.

## Strengths

- Compact and easy to adapt.
- Focuses on causal understanding: why the problem existed, why the solution works, and what the change affects.
- Encourages varied assessment through open-ended questions, multiple-choice questions, code inspection, and debugger use.
- Treats the learner as active, not as a passive recipient of explanations.

## Gaps & Limitations

- No explicit license. Treat it as public reading material; do not reuse the text wholesale.
- It is a prompt fragment, not a full skill package with metadata, examples, tool fallbacks, or runtime compatibility notes.
- The referenced tool names and `/goal` command are runtime-specific.
- It does not distinguish between tutoring sessions and normal task-execution sessions, where repeated quizzes would be intrusive.
- It assumes a single learner profile and should be generalized before reuse.

---

**Attribution:** ThariqS, GitHub Gist, no explicit license found.
