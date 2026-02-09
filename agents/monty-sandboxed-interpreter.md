# Monty — Sandboxed Python Interpreter for AI Agents

**Source:** [pydantic/monty](https://github.com/pydantic/monty) (MIT)
**By:** Pydantic (Samuel Colvin et al.)

## What It Is

A minimal Python interpreter written in Rust, purpose-built for running LLM-generated code. Will power `codemode` in Pydantic AI.

## Why It Exists

LLMs work faster, cheaper, and more reliably when asked to write Python instead of relying on traditional tool calling (see Anthropic's "Programmatic Tool Calling", Cloudflare's "Code Mode", HuggingFace's SmolAgents). But running LLM-generated code requires a sandbox. Containers are slow (100s of ms startup). Monty starts in <1μs.

## Key Properties

- **<1μs startup** — no container, no VM boot
- **Zero host access** by default — no filesystem, no env vars, no network
- **External functions only** — agent code can only call functions you explicitly expose
- **Snapshotable** — serialize interpreter state to bytes, resume later (persist across tool calls)
- **Resource limits** — track memory, allocations, stack depth, execution time; kill if exceeded
- **Multi-language bindings** — Rust, Python (`pydantic-monty`), JavaScript (`@pydantic/monty`)
- **Type checking** — ships with [ty](https://docs.astral.sh/ty/) for type checking agent code

## Architecture

Bytecode VM (like CPython) with manual reference counting via `defer_drop!` macro for safety across all code paths. Uses Ruff's parser for Python AST.

## Limitations (by design)

- No stdlib (except sys, typing, asyncio)
- No third-party libraries
- No classes (yet)
- No match statements (yet)

## AGENTS.md / CLAUDE.md Pattern

Monty has one of the most thorough `AGENTS.md` files I've seen — detailed coding agent instructions covering security constraints, test patterns, build commands, code style, and explicit "NEVER do X" rules. Worth studying as a template for agent-friendly repos.
