# Claudeception

- **Repo:** <https://github.com/blader/Claudeception>
- **License:** MIT
- **Commit reviewed:** `62dbb91` (2026-02-20)

## What it is

Claudeception is a meta-skill for Claude Code that turns session discoveries into new reusable skills. The core idea is simple and good: treat debugging wins, weird workarounds, and project-specific lessons as durable artifacts instead of ephemeral chat residue.

## What it actually ships

- A top-level `SKILL.md` that defines extraction criteria, update-vs-create rules, versioning guidance, and a structured extraction workflow
- A prompt-injection hook (`scripts/claudeception-activator.sh`) that nudges the agent to ask, on each prompt, whether the current work produced extractable knowledge
- A markdown skill template plus research notes and examples

This is not a memory system in the broad sense. It is a **skill distillation loop**. Narrower than a vault, but cleaner.

## Why it matters

The useful pattern here is not "agents can write files", we already know that. The useful pattern is the **quality gate** on what deserves promotion into a reusable tool:

- must be reusable
- must be non-trivial
- must be specific
- must be verified

That keeps the skill library from turning into a landfill of vaguely phrased "best practices" sludge.

The update/create decision table is also solid. Same trigger and same fix means update. Same trigger but different root cause means create a sibling skill and cross-link it. That is the right mental model for long-lived operational knowledge.

## Best ideas worth stealing

### 1. Skills as writeable retrieval substrate
Claude Code's skill system is usually treated as static prompt engineering. Claudeception treats it as a writable index. That is the real move.

### 2. Trigger-condition-first descriptions
The repo is explicit that descriptions should be optimized for future retrieval, not for human prose elegance. "Fix for PrismaClientKnownRequestError in serverless" beats "database troubleshooting notes". Correct.

### 3. Retrospective extraction after discovery
The repo doesn't try to pre-author all useful skills. It waits until the agent actually learns something. That makes the resulting artifacts grounded in real pain.

### 4. Hook-assisted activation
Relying purely on semantic matching means the extraction skill may never fire at the right moment. The reminder hook is a blunt instrument, but a practical one.

## Limitations

- **Claude-centric**. The repo mentions Codex paths in `SKILL.md`, but the shipped mechanism is clearly designed around Claude Code conventions and hooks.
- **No broader memory graph**. It creates skills, not linked notes, not long-term relational memory, not cross-session summaries.
- **Quality still depends on model taste**. The rubric is good, but garbage extraction is still possible if the agent gets overeager.
- **Potential skill sprawl** if used without curation. It has rules, but not an explicit consolidation or pruning loop.

## Where it fits

Claudeception is best understood as a **skill refinery**, not a full memory architecture.

- If you want durable project memory, use a vault or structured notes system.
- If you want reusable operational playbooks to self-accumulate, this is more targeted and arguably better.

It pairs naturally with systems like napkin, obsidian-mind, or Rowboat:
- those preserve context
- this one promotes repeatable solutions into runnable guidance

## Verdict

Good idea, tightly scoped, and more rigorous than most "self-improving agent" repos. It avoids grandiose claims and mostly sticks to one believable loop: **discover something useful, verify it, package it for retrieval next time**.

That is modest, but actually useful.

**Rating:** 4/5

## Patterns worth stealing

- Writeable skill library as an adaptive memory layer
- Update-vs-create decision table for operational knowledge
- Trigger-condition-first skill descriptions for retrieval quality
- Hook-based retrospective prompts to increase extraction rate
- Verified-only promotion gate for learned tactics
