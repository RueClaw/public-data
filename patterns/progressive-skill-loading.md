# Pattern: Progressive Skill Loading

> **Source:** [ImTheMars/koda](https://github.com/ImTheMars/koda) (MIT License)

## Problem

An AI assistant with many skills needs them available but can't fit all skill documentation into every system prompt.

## Solution

Three-tier loading:

1. **Always-on skills** — full SKILL.md content injected every turn (marked `always: true` in YAML frontmatter)
2. **Skill summary** — names + one-line descriptions in an XML block, always present
3. **On-demand loading** — agent reads full SKILL.md via filesystem tool when it decides a skill is relevant

## Skill Format

```markdown
---
name: web-research
description: Multi-step web research with source synthesis
always: false
---

# Web Research

## When to Use
- User asks a complex factual question
...

## Procedure
1. Break down the query into 2-3 specific search queries
...
```

## Summary Format (in system prompt)

```xml
<skills>
  <skill>
    <name>web-research</name>
    <description>Multi-step web research with source synthesis</description>
    <location>/path/to/skills/web-research/SKILL.md</location>
  </skill>
</skills>
```

## Discovery Priority

Workspace skills (`{workspace}/skills/`) override builtin skills (`{project}/skills/`) by name. This lets users customize or replace default skills without modifying the source.

## Why This Works

- Base prompt stays small regardless of skill count
- Agent can self-select relevant skills based on the summary
- Skills are just markdown files — easy to create, edit, version
- The `always: true` flag handles skills that should always be available (like the skill-creator meta-skill)
- User-created skills automatically appear in the summary
