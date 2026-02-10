# AGENTS.md: Project-Level Agent Instructions Convention

> **Source:** [workflows-acp](https://github.com/AstraBert/workflows-acp) by AstraBert
> **License:** MIT
> **Extracted:** 2026-02-10

## Pattern

Place an `AGENTS.md` file in your project root to provide any AI coding agent with project-specific instructions — coding style, best practices, architecture context, constraints. The agent reads it automatically before starting work.

## Why It Matters

Different agent frameworks have their own instruction files (`CLAUDE.md` for Claude Code, `COPILOT.md` for Copilot, `.cursorrules` for Cursor, etc.). `AGENTS.md` is an emerging **framework-agnostic** convention: a single file that any agent can read.

## How workflows-acp Uses It

From the README:

> If you wish to provide additional instructions to the agent (e.g. context on the current project, best practices, coding style rules...) you can add these instructions to an **AGENTS.md** file in the directory the agent is working in.

The agent reads `AGENTS.md` at startup and incorporates its contents into the system prompt, alongside the task from `agent_config.yaml`.

## Recommended Structure

```markdown
# AGENTS.md

## Project Overview
Brief description of what this project does.

## Tech Stack
- Language: Python 3.12
- Framework: FastAPI
- Database: PostgreSQL

## Coding Standards
- Use type hints everywhere
- Prefer composition over inheritance
- Write docstrings for public functions

## Architecture
- `src/` — main application code
- `tests/` — pytest test suite
- `docs/` — documentation

## Constraints
- Do not modify migration files directly
- Always run tests before committing
- Keep dependencies minimal
```

## Cross-Framework Compatibility

| Framework | Native File | Reads AGENTS.md? |
|-----------|------------|-------------------|
| Claude Code | `CLAUDE.md` | Not natively (but easy to add) |
| workflows-acp | `AGENTS.md` | ✅ Yes |
| Cursor | `.cursorrules` | No |
| Copilot | `.github/copilot-instructions.md` | No |

The ideal: frameworks converge on reading `AGENTS.md` as a standard, while still supporting their own native files. Until then, you can include a line in your framework-specific file: "Also read AGENTS.md for project context."

## Adoption Tip

If you already have a `CLAUDE.md` or similar, add this to it:

```markdown
## Additional Context
See AGENTS.md for framework-agnostic project instructions.
```

Then put the shared, non-framework-specific content in `AGENTS.md`.
