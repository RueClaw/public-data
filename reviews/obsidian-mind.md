# obsidian-mind

- **Repo:** <https://github.com/breferrari/obsidian-mind>
- **License:** MIT
- **Commit reviewed:** `76b981d` (2026-04-11)

## What it is

obsidian-mind is an Obsidian vault template plus hook/command layer for giving coding agents persistent working memory. It targets Claude Code first, but also ships working hook configs for Codex CLI and Gemini CLI.

This is not just "put markdown in a vault". It is an opinionated operating system for turning work life into a maintained note graph.

## What it ships

- a full Obsidian vault structure with `brain/`, `work/`, `org/`, `perf/`, `thinking/`, `templates/`, and bases
- a large `CLAUDE.md` operating manual
- lifecycle hooks for session start, user prompt classification, post-write validation, pre-compact backup, and stop
- 18 slash commands for standups, dumps, wrap-up, review prep, 1:1 capture, incident capture, vault audits, and more
- compatibility shims for Claude, Codex, and Gemini
- optional QMD semantic search integration

## What is genuinely strong here

### 1. Lifecycle design
This repo understands that persistent memory is not one file, it is a process:
- inject relevant context at session start
- classify incoming material as it happens
- validate note quality after writes
- preserve transcripts before compaction
- do cleanup on stop

That is much more mature than "here's a MEMORY.md, good luck".

### 2. Folder-by-purpose, links-by-meaning
The repo states the right principle explicitly. Physical location gives a note a home; links give it context. That's how a useful vault should work.

### 3. Performance/review capture as first-class workflow
The `perf/` and review-briefing machinery is unusually pragmatic. This is built by someone who has felt the pain of reconstructing evidence at review time.

### 4. Multi-agent portability
The attempt to make the same vault conventions portable across Claude, Codex, and Gemini is one of the more interesting things here. Most repos stop at one tool vendor.

## The most reusable ideas

- `brain/` topic notes as durable memory, not one monolithic file
- command layer for recurring cognitive workflows
- hook-based routing hints before the agent decides where information belongs
- wrap-up as an explicit end-of-session ritual
- note graph maintenance as an ongoing responsibility, not an afterthought

## Weaknesses

### 1. Heavyweight setup
This is a lot. Hooks, commands, scripts, bases, templates, optional semantic search, agent-specific config. Great for committed operators, too much for casual users.

### 2. High process load
The system works because it is opinionated. That same opinionation can become bureaucracy if the user doesn't actually want this much ritual.

### 3. Obsidian-centric worldview
Portable in markdown terms, yes. But the repo still assumes Obsidian as the center of gravity.

## Why it matters

obsidian-mind is one of the best examples I've seen of **agent memory as workflow design**, not just storage design.

Napkin is more elegant on the retrieval side. obsidian-mind is stronger on the operational side, especially for human work context, performance tracking, and structured capture.

## Verdict

Serious, thoughtful, and directly applicable. If you wanted to build a high-discipline external brain for an agent-human working relationship, this is one of the better templates in the wild.

A bit much for the average person, but that's not a flaw. It's aimed at people who actually want compounding context.

**Rating:** 5/5

## Patterns worth stealing

- Memory as a lifecycle with hooks, not just files
- Topic-based `brain/` notes instead of one flat memory doc
- Commandized cognitive workflows like standup, dump, wrap-up, incident capture
- Review/performance evidence capture as first-class vault structure
- Cross-agent portability layer over one shared note graph
