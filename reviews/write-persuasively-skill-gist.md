# Write Persuasively Skill Gist

**Repo:** https://gist.github.com/pors/bed9bf0f47229f1d4d8bdb163a20fb0d
**License:** No explicit license detected; treat as public reading material and do not copy wholesale without permission
**Reviewed:** 2026-08-28
**Stack:** Codex Skill, Markdown, GitHub Gist
**What it is:** A two-file Codex skill for drafting, rewriting, and critiquing persuasive writing by gathering a brief, mapping the argument, pruning generated-sounding prose, and checking the final call to action.

---

## Verdict

🔧 **Harvest the workflow, do not install or redistribute as-is.** The skill is compact, practical, and better than most generic writing prompts because it forces purpose, audience, evidence, objections, channel, and voice before drafting. The blockers are licensing and provenance: the gist has no explicit license and embeds a complete Scott Adams essay, so the safe move is to summarize the pattern and rebuild it in your own words.

---

## What It Is

This public gist contains `SKILL.md` and `SOURCES.md`. The skill activates for persuasive writing tasks: emails, proposals, pitches, memos, announcements, requests, fundraising copy, marketing copy, advocacy, arguments, calls to action, and rewrites of existing persuasive text.

The core workflow is brief-first. For underspecified requests, the skill instructs the agent to ask a compact set of questions about the desired reader response, audience, support, resistance, format, tone, constraints, and deadline. If the request is already specified, the agent confirms the inferred brief and proceeds.

After that, the skill builds an argument map, drafts for momentum, prunes for clarity, removes common machine-written tells, and runs a final check. `SOURCES.md` cites Wikipedia's "Signs of AI writing" guide and two research papers on lexical/rhetorical patterns in LLM-generated prose.

## Stack

| Layer | Tech |
|-------|------|
| Skill format | Codex `SKILL.md` |
| Content | Markdown workflow and checklist |
| Supporting file | `SOURCES.md` with cited rationale |
| Runtime services | None |
| Tests | None detected |
| License | None detected |

## Key Features

### Brief-First Drafting

The skill refuses to draft from a vague prompt by default. It asks for the outcome, audience, evidence, likely objections, and channel constraints before writing. That is the strongest part of the artifact: persuasive writing usually fails because the brief is missing, not because the prose needs more polish.

### Argument Map

Before drafting, the skill asks the agent to identify the desired reader response, strongest true claim or benefit, one to three supporting facts, the likeliest objection, and a proportionate next step. That keeps persuasion tied to evidence and action instead of style alone.

### Anti-AI-Prose Cleanup

The checklist targets clusters of generated-sounding prose: formulaic contrast structures, canned openings, overused stock vocabulary, decorative headings, repeated rule-of-three rhythms, personification, hypophora, and overuse of em dashes. The framing is careful: these are signals to edit, not proof of AI authorship.

### Final Readability Gate

The final check asks whether the opening gives a reason to keep reading, the point is clear on first pass, every sentence advances the argument, claims are supported, objections are handled or intentionally omitted, the action is easy to take, and the speaker's voice still sounds identifiable.

## Architecture

This is a prompt-layer skill, not software. The logic lives in a single Markdown file with frontmatter metadata, workflow sections, bullet checklists, and embedded source text. There is no installer, package manifest, versioning scheme, automated evaluation, fixture corpus, or lint check.

That simplicity makes the skill easy to inspect and adapt. It also means output quality depends entirely on the host agent and the user's supplied brief. A production-grade writing skill would benefit from examples, before/after fixtures, evaluation criteria, and separate source references rather than embedding a whole third-party essay.

## Comparison

| Aspect | Write Persuasively Gist | Generic Writing Prompt | Tufte Claude Skill | Personal Claude Code Cheat Sheet |
|--------|--------------------------|------------------------|--------------------|----------------------------------|
| Primary use | Persuasive writing | Broad writing help | Data visualization | Agent setup documentation |
| Best idea | Brief-first persuasion workflow | Fast ad hoc drafting | Domain decision tables | Reflect live setup to user |
| Packaging | Two-file gist | Prompt only | Repo skill package | Repo skill package |
| Reuse posture | Harvest pattern only | N/A | Installable with attribution | Educational until license clarified |
| Main risk | No license; embedded third-party essay | Underbriefed output | New repo maturity | Local config leakage |

## Self-Hosting Notes

Treat this as a reference, not an install target. Before using it in a shared skill library:

- Ask the author to add an explicit license.
- Remove or replace the embedded full essay unless rights are clear.
- Rewrite the workflow in original wording.
- Add examples for emails, proposals, asks, and objections.
- Add a small evaluation set with before/after drafts and rubric checks.

---

**Attribution:** pors, GitHub Gist, no explicit license detected.
