# Superpowers Review

**Repo:** https://github.com/obra/superpowers  
**License:** MIT  
**Author:** Jesse Vincent (@obra)  
**Language:** Markdown skill definitions (Claude Code / Cursor / Codex / OpenCode plugin)  
**Cloned:** ~/src/superpowers (already present)  
**Rating:** 🔥🔥🔥🔥

---

## What It Is

A **complete software development workflow plugin** for coding agents (Claude Code, Cursor, Codex, OpenCode). 14 skills that trigger automatically when the agent detects relevant context — no `/commands` needed. You get spec-before-code, TDD enforcement, subagent-driven execution, and systematic debugging as mandatory workflows, not suggestions.

Core loop: **Brainstorm → Spec → Plan → Subagent-Driven Implementation (one fresh subagent per task, two-stage review each) → Code Review → Merge/Discard**

---

## The 14 Skills

| Skill | When it fires |
|---|---|
| **brainstorming** | Before writing any code — Socratic spec refinement, hard gates before implementation |
| **using-git-worktrees** | After design approval — isolated branch + clean baseline |
| **writing-plans** | With approved design — breaks work into 2-5 min tasks with exact paths and verification |
| **subagent-driven-development** | With plan — fresh subagent per task, two-stage review (spec compliance → code quality) |
| **executing-plans** | Parallel session alternative to subagent-driven-dev |
| **dispatching-parallel-agents** | Concurrent independent subagent workflows |
| **test-driven-development** | During implementation — RED-GREEN-REFACTOR enforced, deletes code written before tests |
| **systematic-debugging** | On any bug/failure — 4-phase root cause process, no fixes without root cause |
| **verification-before-completion** | After apparent fix — ensure it's actually fixed |
| **requesting-code-review** | Between tasks — reviews against plan by severity |
| **receiving-code-review** | Responding to feedback |
| **using-git-worktrees** | Parallel development isolation |
| **finishing-a-development-branch** | When tasks complete — verify, then merge/PR/keep/discard |
| **writing-skills** | Create new skills in the framework (self-extending) |

---

## Architecture

Skills are directories under `skills/`, each with a `SKILL.md` and supporting reference files. A `session-start` hook injects the skills manifest at startup — the agent gets told which skills exist and when to use them without manual invocation.

The `hooks/` mechanism (Claude Code's SessionStart hook) is how compliance is enforced. The hook output tells the agent "here are the skills you have, here is when to use them, here are the hard gates." Without this, a model could ignore the skills; the hook makes them mandatory context at session start.

**~3000 lines of skill definitions.** The writing-skills skill (655 lines) includes its own testing methodology — skills have tests (pressure tests, academic tests) to validate the skill text itself forces compliant agent behavior.

---

## What's Actually Good

### The Subagent-Driven Development Pattern
Fresh subagent per task (not per session) + two-stage review (spec compliance first, then code quality) is the correct isolation strategy. Each implementer starts with no contamination from previous tasks. The spec review happens before quality review — you can't pass on code quality if the implementation doesn't match the spec. Clean sequencing.

The dotgraph decision trees in the skill files are effective at communicating branching logic to the model — visual DAGs are more reliably interpreted than prose conditionals.

### Systematic Debugging as Iron Law
```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```
Four phases: Root Cause Investigation → Fix Design → Implementation → Verification. The "when to use ESPECIALLY" section calls out the exact failure modes: "under time pressure", "just one quick fix seems obvious", "you've already tried multiple fixes." These are the rationalizations that lead to thrashing. Naming them explicitly in the skill is the right counter.

The `find-polluter.sh` script and condition-based-waiting patterns are included as reference artifacts alongside the skill — not just instructions, but working tools.

### The Brainstorming Hard Gates (v4.3.0)
The v4.3.0 release notes are interesting: models were skipping the design phase and jumping to implementation. Fix was adding `<HARD-GATE>` markers, a mandatory 6-item checklist, and a graphviz flow with `writing-plans` as the **only valid terminal state**. They even added an explicit anti-pattern callout: "this is too simple to need a design" is named as the exact rationalization models use to skip the process.

This is the same failure mode documented in AGENTS.md's anti-rationalization table. Good to see it addressed via structural constraint rather than just instruction.

### Self-Extending
The `writing-skills` skill teaches the agent how to write new skills in the same format, including how to write tests for skills. The framework can grow skills that meet its own standards. 655 lines — the most detailed skill in the set.

### Multi-Platform (v4.3.1)
Works on Claude Code, Cursor, Codex, OpenCode. The Windows polyglot hook fix is notable — they tracked down `bash` auto-detection mangling on Windows and fixed the hook runner to work across MSYS, WSL, and standard Git for Windows paths.

---

## What's Not Great

### No State Persistence Across Sessions
The session-start hook reinjects skills context every time, but there's no mechanism to resume a multi-session development workflow. If you start a subagent-driven development run and close the session, you're manually picking up the thread.

### Skill Tests Are Not Automated
The `test-pressure-*.md` and `test-academic.md` files in each skill directory are prompts you'd run manually to verify the skill forces correct behavior. There's no CI that runs them against a model — they're a methodology, not a test suite.

### Skills Are Compliance-Enforced, Not Verified
The system relies on the agent reading and following the skill content. There's no tool-level guardrail preventing a model from deciding to skip a step. The hard gates in brainstorming are the closest thing to enforcement, but they're still just text.

---

## Comparison to Other Dev Workflow Tools Reviewed

- **Claude Task Master (#241):** PRD → task graph → complexity scoring. More PM-oriented, less engineer-oriented. Doesn't have the TDD enforcement or systematic debugging depth.
- **spec-kit (#244):** Constitution → spec → plan chain. More governance-focused (versioned semver docs). Complementary to Superpowers, not competing.
- **claude_slash_commands (#242):** 10 slash commands by Sterling Crispin. Lighter, no enforcement mechanism. `/auditcodex` (Codex as secondary reviewer) is similar in spirit to the two-stage review here.
- **Superpowers:** Deepest engineering workflow coverage. The systematic-debugging and TDD skills are the strongest in the set.

---

## Relevance for Us

**Direct use for ODR:** The subagent-driven-development pattern is the right execution model for ODR's meta-critic feature work. Install via `/plugin install superpowers@superpowers-marketplace` in Claude Code, then use it on the meta-critic implementation tasks.

**Systematic debugging:** Worth having in every ODR coding session. The root-cause-before-fix constraint directly addresses the rationalization failures documented in AGENTS.md.

**writing-skills:** If we build custom Marcos-agent skills, the methodology here is the right way to test them — pressure tests and academic tests to verify the skill text actually forces the intended behavior.

**The brainstorming hard-gate pattern:** Relevant for any multi-step workflow where we're seeing models skip phases. The `<HARD-GATE>` + mandatory checklist + graphviz terminal state pattern is worth stealing for the Marcos agent's interaction flows.

---

## Verdict

A mature, actively maintained engineering workflow plugin. v4.3.x release notes show they're tracking and fixing real compliance failures — the brainstorming skip problem and the Windows hook problem are evidence that it's being used seriously. MIT license, cross-platform, self-extending.

The systematic-debugging and subagent-driven-development skills are the strongest pieces. Worth installing in any active Claude Code project. The skill-writing methodology is worth reading even if you never install the plugin.

---

*Source: https://github.com/obra/superpowers | License: MIT | Author: Jesse Vincent (@obra) | Reviewed: 2026-03-21*
