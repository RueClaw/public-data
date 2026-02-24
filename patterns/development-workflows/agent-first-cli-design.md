# Agent-First CLI Design Pattern

> Extracted from [alexknowshtml/api2cli](https://github.com/alexknowshtml/api2cli) (MIT License, Alex Hillman)
> Inspired by [Joel Hooks' agent-first CLI design](https://github.com/joelhooks/joelclaw/blob/main/.agents/skills/cli-design/SKILL.md)

## Core Idea

CLIs consumed by AI agents should return structured JSON with contextual next actions. Every response is self-contained — the agent never needs to read `--help` or guess at available commands.

## The JSON Envelope

Every response follows a consistent structure:

```json
{
  "ok": true,
  "command": "mycli list",
  "result": { "items": [...], "count": 15 },
  "next_actions": [
    { "command": "mycli show abc123", "description": "View first item details" },
    { "command": "mycli list --status=active", "description": "Filter to active items" }
  ]
}
```

Errors follow the same shape with a `fix` field:

```json
{
  "ok": false,
  "command": "mycli deploy",
  "error": { "message": "No deployment target specified", "code": "MISSING_TARGET" },
  "fix": "Run \"mycli deploy --target=staging\" or \"mycli deploy --target=production\"",
  "next_actions": [
    { "command": "mycli deploy --target=staging", "description": "Deploy to staging" },
    { "command": "mycli config show", "description": "Check current configuration" }
  ]
}
```

## Pattern 1: HATEOAS Next Actions

The most valuable pattern. Every response includes `next_actions` — contextual commands the agent can run next. These **change based on current state.**

```
# Empty list → suggest creating
next_actions: [{ command: "mycli create", description: "Create a new item" }]

# List with results → suggest viewing first item
next_actions: [{ command: "mycli show abc123", description: "View first item" }]

# Error → suggest fix
next_actions: [{ command: "mycli auth login", description: "Authenticate first" }]
```

The agent never needs to know the full command tree. Each response tells it exactly what's relevant right now.

## Pattern 2: Self-Documenting Root

Running the CLI with **no arguments** returns the full command tree as JSON. This is the agent's entry point — it discovers all capabilities in one call.

```bash
$ mycli
{
  "ok": true,
  "command": "mycli",
  "result": {
    "description": "My API CLI",
    "commands": [
      { "command": "mycli list", "description": "List all items" },
      { "command": "mycli create", "description": "Create a new item" }
    ]
  }
}
```

## Pattern 3: Error Fix Suggestions

Every error includes a `fix` field — plain language guidance on how to resolve it. The agent can follow the fix automatically or present it to the user.

## Pattern 4: Context-Protecting Truncation

Large outputs consume agent context tokens. Truncate by default, point to full data:

```json
{
  "ok": true,
  "result": {
    "items": ["...first 50..."],
    "count": 1500,
    "showing": 50,
    "truncated": true,
    "full_results": "/tmp/mycli-results-1234.json"
  }
}
```

## Pattern 5: Dual-Mode Output

Same CLI works for humans AND agents. Detect context automatically:

- **Terminal (interactive):** Human-readable tables, colors, formatting
- **Piped (non-interactive):** JSON envelope with next_actions

```typescript
const isAgent = !process.stdout.isTTY;

if (isAgent) {
  console.log(JSON.stringify({ ok: true, command, result, next_actions }));
} else {
  console.table(result.items);
}
```

**Use dual-mode when:** humans might run it directly (status checks, operational tools).
**Use pure agent-first when:** only agents call it (API wrappers, automation scripts).

## Applying to Existing CLIs

Any CLI can adopt these patterns incrementally:

1. **Start with `--json` flag** — add structured JSON output alongside human output
2. **Add `next_actions`** — contextual suggestions based on response state
3. **Add `fix` to errors** — self-healing error responses
4. **Add self-documenting root** — no-args returns command tree
5. **Auto-detect TTY** — switch between human/agent output automatically

## Why This Matters

Traditional CLIs assume a human reader. Agent-first CLIs assume a machine consumer that needs:
- **Structured data** (not formatted text to parse)
- **Workflow guidance** (what to do next, not just what happened)
- **Self-healing errors** (how to fix, not just what broke)
- **Context efficiency** (truncated results, not 10,000 lines)
