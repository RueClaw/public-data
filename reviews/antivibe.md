# antivibe

- **Repo:** <https://github.com/mohi-devhub/antivibe>
- **License:** MIT
- **Commit reviewed:** `7faebe1` (2026-04-11)

## What it is

AntiVibe is a **Claude Code skill** aimed at fighting "vibecoding" by generating educational deep dives for AI-written code.

The intended flow is simple:
- Claude writes code
- user asks for a deep dive, or hooks trigger automatically
- the skill produces a markdown learning guide explaining what the code does, why it was written that way, related concepts, and curated resources

So this is not really a software product. It is a **prompt-and-template learning scaffold** packaged as a skill.

## The good part of the idea

The premise is good.

There really is a problem here: AI-assisted coding makes it very easy to accumulate working code without accumulating understanding. A tool that tries to convert generated code into actual learning material is pointing at a real gap.

That part is not fake.

## What is actually in the repo

The repo consists mostly of:
- `SKILL.md` with trigger phrases and workflow guidance
- `agents/explainer.md` with the explanation persona/prompt
- shell-script helpers for analysis/resource gathering/output generation
- template markdown for the final deep-dive file
- static reference docs for patterns and resource links
- optional hook config for auto-triggering

So the implementation is intentionally lightweight.

## What is technically interesting

### 1. It names the right failure mode
The strongest thing in the repo is not code, it's framing. "Learn what AI writes, not just accept it" is a real corrective to copy-paste autopilot.

### 2. Skill packaging is tidy
As a Claude Code skill, the structure is straightforward and legible:
- triggers
- workflow
- explainer persona
- output template
- optional hooks

That makes it easy to steal or adapt.

### 3. The output template is directionally correct
The template asks for:
- overview
- code walkthrough
- concepts explained
- learning resources
- related code
- next steps

That is much better than a generic "here's what this file does" summary.

### 4. The concept/resource curation files are useful starter material
The static references are generic, but sensible. They give the skill a bootstrap vocabulary for design patterns and learning links.

## Where it feels thin

### 1. Most of the repo is promptware
Let's be blunt. This is primarily:
- prompts
- template markdown
- grep-based shell helpers
- static resource lists

That is not inherently bad, but it means the repo is much less of a "framework" than the README vibe suggests.

### 2. The scripts are shallow
`scripts/analyze-code.sh` is basically extension detection plus grep. `generate-deep-dive.sh` creates a scaffold with placeholders. The heavy lifting is still expected from the model.

So if the model is weak or lazy, this does not save you.

### 3. "Curated resources" are only lightly curated
The resource file is more of a solid starter bookmark list than real context-aware curation. Useful, but not especially adaptive or deep.

### 4. Auto-trigger could be noisy in practice
The idea of generating learning artifacts automatically at `SubagentStop` or session end sounds nice, but I can easily see it producing homework nobody reads unless the trigger logic is selective.

### 5. The repo overstates generality a bit
It says multi-language/framework, which is true in the very weak sense that prompts can talk about any language. But there is not much real language-aware analysis machinery here beyond some grep heuristics and static notes.

## Why it still matters

Because the core behavioral intervention is correct.

A lot of "AI coding literacy" work does not need a giant platform. Sometimes it just needs a repeatable habit and a decent prompt structure. AntiVibe is trying to institutionalize that habit.

That has value.

## Best reusable ideas

- Treat explanation as a first-class post-generation step
- Focus on **why**, **when**, and **alternatives**, not just what the code does
- Emit durable learning artifacts in markdown instead of ephemeral chat summaries
- Use phase-based or task-based triggers to turn completed work into study material
- Include learning resources and next-step prompts so the artifact becomes a study guide, not just a summary

## Comparison notes

### Versus repo review frameworks
Repo reviews explain an external codebase.
AntiVibe explains *your freshly generated code*.
Different target, more directly educational.

### Versus llm-context-base / obsidian-mind
Those are memory substrates.
AntiVibe is a learning reflection layer that could feed into them.

### Versus a real static analysis tool
This is nowhere near that. It is an LLM teaching workflow, not a code analysis engine.

## Verdict

Good idea, thin implementation.

I would not call this a robust framework in the engineering sense. It is closer to a thoughtfully packaged Claude Code skill that encourages a healthy practice: stop, inspect, and learn from AI-generated code before it fossilizes into magic.

That makes it useful, even if the repo itself is mostly scaffolding.

**Rating:** 3.5/5

## Patterns worth stealing

- Add a deliberate "learning pass" after AI coding tasks
- Structure explanations around what, why, when, and alternatives
- Save explanations as durable markdown artifacts instead of leaving them in chat
- Attach curated resources and next-step study prompts to generated code reviews
- Use lightweight hook-based automation to encourage reflection without requiring manual discipline every time
