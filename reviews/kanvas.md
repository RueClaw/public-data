# Kanvas (XMihura/Kanvas)

**Repo:** https://github.com/XMihura/Kanvas
**License:** MIT (free extraction and reuse)
**Reviewed:** 2026-10-05
**Stack:** Python 3.7+ CLI (1,430 lines, zero dependencies), Obsidian Canvas (JSON) as the board, optional Obsidian watcher plugin + standalone Node watcher
**What it is:** A visual project board for mixed human/AI-agent work: an Obsidian `.canvas` file where card colors are task states and arrows are dependencies, plus a CLI that lets agents propose/start/finish tasks without being able to break the workflow rules.

---

## Verdict

✅ **Deploy candidate — the lightest workable human/agent coordination board we've seen, and it runs on tools already in the stack.** Kanvas is a convention plus a guardrail, not a platform: colors-as-states (purple proposed → red todo → orange doing → cyan review → green done, gray auto-blocked), arrows-as-dependencies, and a zero-dependency Python CLI that enforces valid transitions and dependency checks so agents never hand-edit canvas JSON. Verified locally against the sample board: `status`, `ready`, and `blocked` all compute correctly, including transitive blocking (`DL-03` correctly gray behind gray `DL-02`). Both sides contribute — humans approve and verify, agents propose and execute — which is the right power split. Caveats: maintenance looks stalled (last push 2026-03-27, 201★), the JSON canvas format means merge conflicts on heavy parallel editing, and there's no multi-board or multi-agent-locking story. But at 1,430 lines of dependency-free Python, you can own it outright.

---

## What It Is

Kanvas starts from an honest observation: agents live in CLI sandboxes, but projects still need plans, dependencies, and progress tracking that humans can see. The board is a standard Obsidian Canvas file — cards, groups, arrows, colors — living in the project repo, diffable and mergeable like any other file. The workflow:

- **Agents propose** tasks (purple). **Humans approve** them (red), draw dependency arrows, and set priorities visually.
- Agents pick ready (red, unblocked) tasks via the CLI, mark them doing (orange), then review (cyan). **Humans verify** and mark done (green).
- Tasks with unfinished dependencies are auto-gray; when a dependency goes green, blocked tasks flip back to red automatically.
- Commit code and `.canvas` together per task — git history mirrors the board state.

Three components: `RULES.md` (the workflow protocol — the actual core), `canvas-tool.py` (the CLI enforcing it: status/show/list/blocked/ready/start/finish/propose/batch/edit/add-dep/normalize), and an optional Canvas Watcher plugin that lints the board when *humans* edit it in Obsidian (catches circular deps, auto-manages blocked states). Agent-agnostic: anything that can run a shell command can use it — Claude Code, Codex, Gemini CLI, or a pasted system prompt.

## Stack

| Layer | Tech |
|-------|------|
| Board | Obsidian `.canvas` (open JSON spec) |
| CLI | Python 3.7+, zero dependencies, 1,430 lines |
| Watcher | Optional Obsidian plugin (auto-installed by `init` when `.obsidian/` exists) + standalone Node watcher |
| Agent glue | `CLAUDE.md` / `AGENTS.md` instruction files |
| VCS | Git-native; board diffs with the code |

## Key Features

### Guardrailed agent access

Agents interact only through the CLI, which enforces valid state transitions and dependency checks — an agent physically cannot mark a blocked task doing or skip the review state by editing JSON. This is the correct trust model for shared human/agent state: the tool is the policy.

### Color-state machine with automatic blocking

Six states with a defined flow (propose → approve → start → finish → verify) and automatic blocked/unblocked propagation along dependency arrows. Verified working: transitive chains block correctly, and unblocking cascades when dependencies complete.

### Git-native project memory

Board and code commit together. Any checkout shows the plan state at that moment — project archaeology for free, no database, no server, no account.

### Genuinely agent-agnostic

The whole integration surface is "run this Python command." Switch agents mid-project, run several at once, or do everything manually — the board doesn't care.

## Architecture

Deliberately none: a workflow convention (`RULES.md`), a single-file CLI implementing it, and an optional linter plugin. Setup is `python canvas-tool.py init <project>` copying four files into the target repo. The canvas file itself is the database.

## Comparison

| Aspect | Kanvas | GitHub Projects/Issues | Beads/task CLIs | Markdown TODO files |
|--------|--------|------------------------|------------------|---------------------|
| Visual board | ✅ Obsidian Canvas | ✅ web | ❌ | ❌ |
| Agent enforcement | CLI transition rules | API perms | CLI conventions | None |
| Human+agent shared | ✅ designed for it | ⚠️ perms friction | ⚠️ agent-first | ⚠️ human-first |
| Dependencies | Arrows, auto-blocking | Issue links | Explicit deps | None |
| Infra | None (a JSON file) | SaaS | None | None |
| Multi-agent locking | ❌ | ✅ | ⚠️ | ❌ |

Versus GitHub Projects: Kanvas trades collaboration features for zero infrastructure and local-first operation. Versus agent task-list tools (beads etc.): Kanvas adds the visual board humans actually review.

## Usage Notes

Clone outside your project, open the project in Obsidian once, then `python Kanvas/canvas-tool.py init <project>` — copies the CLI, instruction files, rules, and a blank board, and installs the watcher plugin. Python 3.7+, any OS. Node only needed for the standalone watcher.

---

**Attribution:** XMihura/Kanvas, MIT
