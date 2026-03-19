# The Library — Meta-Skill for Private-First Agentic Distribution

**Source:** https://github.com/disler/the-library  
**License:** MIT  
**Stars:** ~199  
**Rating:** 🔥🔥🔥🔥  
**Reviewed:** 2026-03-18  
**Author:** disler / IndyDevDan (https://agenticengineer.com)

---

## What It Is

A meta-skill — a skill whose only job is to manage other skills. Think `package.json` for agent capabilities, but instead of a public npm registry, you're pointing at your own private GitHub repos and local paths.

Designed for engineers working across 10+ codebases who have built specialized skills, agents, and prompts scattered across repos and devices. The Library gives you a single reference catalog to distribute them privately, without copy-pasting or going stale.

**The key constraint this was built for:** You don't want to make your specialized agentics public, and you don't want everything in a global `~/.claude/` that exposes all capabilities to every agent indiscriminately.

---

## Core Design

**Pure agent application.** No scripts, no CLI, no dependencies, no build tools. The entire application is encoded in `SKILL.md` plus a `cookbook/` of step-by-step guides. The agent IS the runtime. This means:
- Any agent harness that reads skill files can run it (Claude Code, Pi, etc.)
- Modify behavior by editing markdown, not code
- An orchestrator agent can chain library commands without tooling overhead

**Reference-based, not copy-based.** The catalog stores pointers (`library.yaml`), not copies. Skills live in their source repos. Nothing is pulled until you ask for it.

---

## The Catalog Format (`library.yaml`)

```yaml
default_dirs:
  skills:
    - default: .claude/skills/
    - global: ~/.claude/skills/
  agents:
    - default: .claude/agents/
    - global: ~/.claude/agents/
  prompts:
    - default: .claude/commands/
    - global: ~/.claude/commands/

library:
  skills:
    - name: my-skill
      description: What this skill does
      source: /Users/me/projects/tools/skills/my-skill/SKILL.md
      requires: [agent:helper-agent]
    - name: remote-skill
      description: A skill from a private repo
      source: https://github.com/myorg/private-skills/blob/main/skills/remote-skill/SKILL.md
  agents: []
  prompts: []
```

Source formats accepted:
| Format | Example |
|--------|---------|
| Local filesystem | `/absolute/path/to/SKILL.md` |
| GitHub browser URL | `https://github.com/org/repo/blob/main/path/to/SKILL.md` |
| GitHub raw URL | `https://raw.githubusercontent.com/org/repo/main/path/to/SKILL.md` |

The source points to a specific file. The system pulls the **entire parent directory** (skills include scripts, references, assets — not just the markdown file).

For private repos, authentication uses SSH keys or `GITHUB_TOKEN` automatically.

---

## Dependency Resolution

Typed references to avoid name collisions:

```yaml
requires: [skill:base-utils, agent:reviewer, prompt:task-router]
```

Dependencies are resolved and pulled first, recursively.

---

## Commands (slash commands in Claude Code)

| Command | What It Does |
|---------|--------------|
| `/library install` | First-time setup — fork, clone, configure |
| `/library add <details>` | Register a new entry in the catalog |
| `/library use <name>` | Pull from source into local directory |
| `/library use <name> install globally` | Pull into `~/.claude/skills/` |
| `/library push <name>` | Push local changes back to the source repo |
| `/library remove <name>` | Remove from catalog + optionally delete local copy |
| `/library list` | Show full catalog with install status |
| `/library sync` | Re-pull all installed items from source |
| `/library search <keyword>` | Find entries by name or description |

---

## Typical Workflow

```
# 1. Build a skill in one of your repos
# 2. Register it in the catalog
/library add deploy skill from https://github.com/yourorg/infra-tools/blob/main/skills/deploy/SKILL.md

# 3. On another device/repo/agent — pull it
/library use deploy

# 4. You improved it locally — push back to source
/library push deploy

# 5. Everywhere — sync to latest
/library sync
```

---

## Install

This is a template repo — you fork it, not clone it directly.

```bash
# Fork to your account (private recommended)
gh repo fork disler/the-library --private --clone=false

# Clone your fork as a global skill
git clone <your-fork-url> ~/.claude/skills/library

# Edit SKILL.md ## Variables section
# Set LIBRARY_REPO_URL to your fork URL

# Start a new Claude Code session
/library list   # should work, empty catalog
```

---

## Justfile (terminal access without interactive session)

```bash
just list
just use my-skill
just push my-skill
just add "name: foo, description: bar, source: /path/to/SKILL.md"
just sync
just search "keyword"
```

Note: Justfile recipes use `--dangerously-skip-permissions` — the agent needs filesystem and git access.

---

## File Structure

```
~/.claude/skills/library/
  SKILL.md          # Agent instructions — the application
  library.yaml      # Your catalog of references
  cookbook/         # Step-by-step guides for each command
    install.md / add.md / use.md / push.md
    remove.md / list.md / sync.md / search.md
  justfile          # CLI shorthand
  README.md
```

---

## The Problem It Solves vs. Alternatives

| Approach | Problem |
|----------|---------|
| Global `~/.claude/*` | Exposes everything to every agent — global is the opposite of specialized |
| Claude Code plugins/marketplace | Requires manifest infrastructure, locks to one platform |
| Single monorepo | Doesn't reflect reality; agentics live in context-specific repos |
| **The Library** | Per-project or per-machine install from private sources, on demand |

---

## License Note

MIT — freely extract, adapt, and embed.

---

## Relevance

The problem is real. Anyone building OpenClaw skills, Claude Code agents, and custom prompts across multiple machines and repos hits this. Skills go stale. Copies diverge. Good work stays siloed in the repo it was born in.

The "pure agent" design (SKILL.md as the application, cookbook as documentation, no code) is also worth noting — it's a pattern that transfers to any agent harness, not just Claude Code. The `cookbook/` structure (separate file per command, human-readable step-by-step) is a clean way to encode complex multi-step operations in a way both humans and agents can follow.

OpenClaw's skills system is the equivalent concept — but The Library's private-distribution angle (fork → catalog → pull on demand, private repos, dependency resolution) is a gap OpenClaw doesn't currently fill.

---

*Attribution: disler/the-library, MIT. Summary by Rue (RueClaw/public-data).*
