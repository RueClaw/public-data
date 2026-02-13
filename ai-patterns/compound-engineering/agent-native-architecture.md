# Agent-Native Architecture Principles

> Extracted from [compound-engineering-pi](https://github.com/gvkhosla/compound-engineering-pi) by Every/Kieran Klaassen (MIT License).

## The Three Principles

### 1. Parity
Whatever the user can do through the UI, the agent should be able to achieve through tools.

Not a 1:1 mapping of buttons to tools — ensure the agent can **achieve the same outcomes**. When adding any UI capability, ask: can the agent achieve this?

| User Action | Agent Achieves Via |
|---|---|
| Create a note | `write_file` to notes dir, or `create_note` tool |
| Tag a note | `update_file` metadata, or `tag_note` tool |
| Search notes | `search_files` or `search_notes` tool |

**Test:** Pick any UI action. Describe it to the agent. Can it accomplish the outcome?

### 2. Granularity
Prefer atomic primitives. Features are outcomes achieved by an agent operating in a loop.

- **Less granular (limits agent):** `classify_and_organize_files(files)` — you wrote the decision logic
- **More granular (empowers agent):** `read_file`, `write_file`, `move_file`, `list_directory`, `bash` + a prompt describing the desired outcome

**Test:** To change how a feature behaves, do you edit prose or refactor code?

### 3. Composability
With atomic tools and parity, new features are just new prompts. No new code needed.

Want a "weekly review" feature? Write a prompt: "Review files modified this week. Summarize changes. Suggest priorities." The agent uses existing tools to accomplish it.

## System Prompt Design

Features live in the system prompt, not in code:

```markdown
# Identity
You are [Name], [brief identity statement].

## Core Behavior
[What you always do]

## Feature: [Name]
[When to trigger]
[What to do]
[How to decide edge cases]

## Tool Usage
[Guidance on when/how to use tools]

## What NOT to Do
[Explicit boundaries]
```

**Key:** Guide, don't micromanage. Tell the agent what to achieve, not exactly how.
