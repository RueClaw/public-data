# Myrlin Workbook — CLAUDE.md Sandboxing Pattern

**Source:** https://github.com/therealarthur/myrlin-workbook (AGPL-3.0)
**File:** `CLAUDE.md`
**Attribution:** therealarthur/myrlin-workbook, AGPL-3.0 License

## Pattern: Strict Scope Constraint for AI Agents

```markdown
## CRITICAL SCOPE CONSTRAINT
**You MUST only create, edit, and modify files within this project directory.**

**NEVER modify files outside this folder.** This includes:
- Do NOT edit `~/.claude/settings.json` or any global config
- Do NOT edit files in other projects
- Do NOT modify system files
- All scripts, configs, tests, and output MUST stay within this folder

If you need to READ files outside this folder (e.g., to understand Claude session data),
that's fine. But all WRITES stay here.
```

## Pattern: Agent Team Coordination

```markdown
## Agent Teams
This project has agent teams enabled. Use teammates for:
- One teammate for core state management logic
- One teammate for terminal UI/display
- One teammate for testing and screenshots
- Coordinate via the lead agent
```

## Why These Patterns Matter

1. **Read-only external access** — allows the agent to understand context (reading session data) without risk of modifying global state
2. **Explicit deny list** — naming specific files NOT to touch is more effective than vague "be careful" instructions
3. **Team decomposition** — splitting responsibilities across agent teammates mirrors how human teams work
