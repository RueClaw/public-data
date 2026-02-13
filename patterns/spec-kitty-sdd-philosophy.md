# Spec Kitty — Spec-Driven Development Philosophy

**Source:** https://github.com/Priivacy-ai/spec-kitty (MIT License)
**File:** `spec-driven.md`
**Attribution:** Priivacy-ai/spec-kitty, MIT License. Inspired by GitHub's Spec Kit.

## Core Philosophy: Code as Truth, Specs as Deltas

Traditional SDD treats specs as comprehensive documentation of the system. Spec Kitty inverts this:

- **Code is always the source of truth** — it represents what exists NOW
- **Specs are change requests** — they describe the DELTA between current reality and desired future
- **After merge, specs become historical** — not living documentation
- **LLMs read code for context** — no need to duplicate reality in specs

### Why This Works Better for AI Agents

> AI agents have a superpower: they can read and understand code instantly. Traditional specs tried to save humans from reading code by documenting everything. But LLMs don't need that protection.

**Traditional approach:**
```
"The system has user authentication with email/password, session management,
and password reset. It uses JWT tokens stored in httpOnly cookies..."
[500 lines documenting entire auth system]
```

**Spec Kitty approach:**
```
"Add OAuth2 social login (Google, GitHub) alongside existing email/password
authentication. Keep current JWT session management unchanged."
```

## Key Concepts

- **Intent-driven development** — natural language as lingua franca, code as last-mile
- **Discovery gates** — mandatory interview before any generation, blocks until complete
- **Workspace-per-work-package** — git worktree isolation enables true parallel AI agent work
- **Constitution framework** — enforceable project governance rules for quality gates
- **Two-branch strategy** — stable 1.x maintenance + greenfield 2.x SaaS architecture

## Competitive Positioning

Spec Kitty positions itself for 3-10 agents with hands-on control, vs:
- **Claude-Flow** — 60+ agents, enterprise orchestration
- **BMAD Method** — collaborative AI (AI assists, human leads)
- **Beads** — hash-based context graphs for long-term projects
