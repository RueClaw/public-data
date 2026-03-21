# claude_slash_commands — Repo Review

**Repo:** https://github.com/sterlingcrispin/claude_slash_commands  
**License:** None specified (no LICENSE file — conservative/educational use only)  
**Language:** Markdown (pure prompt files)  
**Author:** Sterling Crispin  
**Cloned:** ~/src/claude_slash_commands  
**Rating:** 🔥🔥🔥🔥

---

## What It Is

A collection of 10 Claude Code slash commands (markdown files dropped in `.claude/commands/`) that extend a coding agent's workflow with structured patterns. Each command is a markdown prompt that Claude Code loads and executes when invoked via `/commandname`.

No code. No dependencies. No install. Just markdown files in the right place.

---

## The Commands

### Workflow/Process Commands

**`/checkpoint`** — Concise structured checkpoint:
> Hypothesis tested → exact change made → before/after metrics → what improved → what didn't → current blocker → next priority action

**`/sanitycheck`** — Plain-language gut-check with 10 questions:
> What are we building? Why? What's the telos? How far are we? Do we know when we're done? Assessment? Keep/change?

**`/selfaudit`** — First-principles audit of recent work:
> What's true (evidence) → what's assumption → what could be wrong → highest-risk bug → next priority + why → then either patch or explain why not

### Documentation Commands

**`/audithandoffdoc`** — Generates `AUDIT_HANDOFF.md` — a structured handoff document for another agent:
> Executive summary → product vision + telos → implementation approach → progress → success metrics → hypotheses → evidence vs assumptions table → risk register → most recent experiment → next hypothesis → open questions

Excellent structure. The "evidence vs assumptions" table with confidence levels and the telos framing are the standout pieces.

**`/ralphinit`** — Bootstraps a project from a `current_SYSTEM-PLAN.md`:
> Generates `current_PRD.md` (40-100 testable requirements in JSON with pass/fail tracking) + `current_PROGRESS.md` (session log + stage checklist). Creates the scaffolding for a continuous agent development loop.

**`/ralphonce`** — One-feature development cycle:
> Read `current_*` docs → pick highest-priority feature → implement → test → update PRD → append to progress log → commit. ONE FEATURE ONLY. Atomic.

### Multi-Agent Commands

**`/auditcodex`** — Cross-agent code review:
> Runs `codex exec` (OpenAI Codex CLI) as a separate read-only reviewer on the current diff. Critically: Claude then **validates each Codex finding** against source + project docs before presenting it. The validation step is the key insight — cross-agent audits produce hallucinations, so the primary agent acts as filter.

**`/pair`** — Pair programming protocol:
> Review partner's work → verify correctness → make edits → complete next task → append message to file → commit.

**`/push`** — Smart commit + push:
> Review all changes → update `agents.md` and `README.md` if appropriate → stage → commit with good message → push. The "update docs first" step is the useful addition over a raw git commit.

**`/researchquestions`** — Structured research prompt generator:
> Produces a `docs/research_prompts/<topic>.md` — questions only, no answers. Hierarchical format (topic areas → sub-questions → follow-up angles). Rules: scale questions, build-vs-borrow questions, "how do others do it" comparatives. No emojis, no fluff.

---

## What's Interesting

### The Telos Framing
Multiple commands ask "what is the telos of this?" — the ultimate purpose or end-state if the project fully succeeds. It's a good forcing function. Most agents (and humans) confuse the current task with the destination. Naming the telos separately keeps strategic clarity.

### Evidence vs Assumptions Table (audithandoffdoc)
```
Claim | Type (Evidence/Assumption) | Source | Confidence (Low/Med/High) | Notes
```
This is the right way to structure uncertainty. Surfacing what you *think* you know vs what you've *verified* is the core epistemic discipline for long-running agent sessions.

### Cross-Agent Audit with Validation Filter (auditcodex)
Spawns Codex as a separate reviewer, then explicitly tells Claude to validate each finding before presenting it. The key insight: cross-agent audits are useful for catching blind spots, but the secondary agent lacks project context and will hallucinate critical issues. The primary agent is the filter. Clean pattern.

### The `current_*` Document System (ralphinit + ralphonce)
Three files: SYSTEM-PLAN + PRD (JSON with pass/fail flags) + PROGRESS (session log). Agent picks up where it left off by reading `current_*`. Atomic feature commits. This is a clean continuous development loop design — essentially the same pattern as what we've built in HEARTBEAT.md + AGENTS.md, but formalized into a project-specific scaffold.

### Research Prompt as Discipline (researchquestions)
"Write questions, not answers. Do not research the topic yourself." — Producing a structured question document before doing research is genuinely underused. Forces you to define the exploration space before diving in.

---

## License Situation

No LICENSE file. Sterling Crispin's GitHub profile suggests these are shared as a community contribution (it's just 10 markdown files), but technically no explicit license means conservative use. The content is patterns and prompts, not code — conceptually borrowable, but can't extract verbatim to public-data without a license.

**These are worth adapting into our own slash commands / skill format.** The patterns are the value, not the specific wording.

---

## Verdict

Excellent prompt engineering, zero fluff. The telos framing, evidence-vs-assumptions table, atomic feature cycle, and cross-agent audit with validation filter are all worth internalizing. The `researchquestions` command matches almost exactly how this channel is supposed to work. The `ralphinit`/`ralphonce` duo is a clean continuous-development-loop design.

No license, so can't copy verbatim — but these are patterns, not code. Adapt them into our own workflow.

**Recommendation:** Pull the best patterns into our Claude Code skill set and OpenClaw skills. The `audithandoffdoc` structure should inform how we do session handoffs. The `current_*` system is worth piloting on the next ODR feature cycle.

---

*Source: https://github.com/sterlingcrispin/claude_slash_commands | License: None specified | Reviewed: 2026-03-21*
