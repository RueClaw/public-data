# Decapod (DecapodLabs/decapod)

**Repo:** https://github.com/DecapodLabs/decapod  
**License:** MIT — summaries and extracted patterns are reusable with attribution  
**Reviewed:** 2026-05-17  
**Stack:** Rust 2024 CLI, SQLite, TOML/JSON, embedded Markdown constitution, GitHub Actions  
**What it is:** A daemonless, repo-local governance kernel that AI coding agents call to clarify intent, shape context, enforce boundaries, and produce proof-backed completion.

---

## Verdict

📚 **Study this as an agent-governance substrate.** Decapod is not another agent framework; it is a local control plane an agent can call before and after inference. The promising part is the explicit loop around intent, context, boundaries, and proof. The main risk is ceremony: the embedded constitution and generated artifacts need to stay focused or they become another pile of ignored process files.

---

## What It Is

Decapod is a Rust CLI for governing AI coding agents inside a repository. Running decapod init creates a .decapod directory with local configuration, override rules, generated specs, context policy, and validation scaffolding. Agents then call Decapod at governance boundaries rather than relying only on chat history or model discipline.

The design is local-first and daemonless. There is no hosted service in the core workflow. The repo carries its own state, specs, context artifacts, and proof surface, which makes the system portable across different agent workbenches.

The project has moved quickly. At review time it was at version 0.48.0, with recent changes around strict root isolation, mandatory Docker/container execution, embedded constitution paths, validation gates, and release automation.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Rust 2024 CLI |
| Distribution | Cargo crate, Nix flake |
| State | Repo-local .decapod directory |
| Persistence | SQLite via rusqlite, TOML/JSON files |
| Context | tiktoken-rs, context capsule policy |
| Governance docs | Embedded Markdown constitution via rust-embed |
| Verification | Validation gates, proof artifacts, Cargo tests |
| CI | GitHub Actions, fmt, clippy, health checks, release-plz |

## Key Features

### Repo-Native Governance State

Decapod's central move is to put agent governance into the repository. A smoke init generated config, override rules, a generated Dockerfile, context policy, and generated specs for intent, architecture, interfaces, operations, security, semantics, and validation.

That gives both agents and humans a reviewable artifact layer. The agent does not have to infer project rules from memory; it can read concrete files.

### Agent-Facing CLI Surface

The CLI is shaped around agent workflows. Important commands include init, validate, workspace, rpc, handshake, preflight, impact, infer, doctor, lcm, eval, state-commit, and flight-recorder.

The rpc, capabilities, handshake, preflight, and impact commands are especially telling. They are not just human convenience commands; they are API points for agents to discover capabilities, predict failure, map changes to validation, and prove completion.

### Embedded Constitution

The repo ships a large embedded constitution covering core demands, interfaces, methodology, plugins, architecture, and security. The binary can expose those documents without network access.

This is useful when Decapod retrieves precise claims for a task. It is risky if the constitution becomes broad context stuffing. The value depends on selection, citation, and enforcement.

### Boundary and Proof Emphasis

Recent releases emphasize strict repository isolation and Docker/container execution. The codebase includes modules for container runtime detection, workspace interlock, gatekeeping, protected branch matching, validation failure classification, state commitments, and proof artifacts.

This is where Decapod is most interesting. Most agent tools focus on planning, memory, or orchestration. Decapod focuses on whether an agent is allowed to touch something and whether completion is backed by evidence.

## Architecture

The README describes a governance loop:

1. A user gives intent to an agent.
2. The agent calls Decapod for intent, context, and gates.
3. The agent performs model inference with shaped context.
4. The agent calls Decapod again for boundary checks, verification, and proof.
5. The user receives a verified result.

That loop is the architecture worth studying. Decapod does not replace the model or the agent. It acts as a callable kernel around the agent's work.

The implementation is organized into src/core for runtime primitives, src/plugins for feature modules, src/constitution for embedded documentation access, and src/cli.rs for the command surface. Tests cover CLI contracts, context capsules, validation, workspace interlocks, proof gates, SQLite hardening, release policy, and plugin behavior.

Local verification during review: cargo test --lib, 72 passed, 0 failed.

## Comparison

| Aspect | Decapod | Spec Kit | Gait | Citadel |
|--------|---------|----------|------|---------|
| Primary role | Agent governance kernel | Spec-driven scaffolding | Tool-call policy gate | Claude Code orchestration |
| State model | .decapod, SQLite, generated specs/artifacts | .specify specs and command templates | Policy files, signed traces, runpacks | Markdown campaign files |
| Runtime coupling | Agent-agnostic CLI | Multi-agent command generation | Integration boundary/sidecar | Claude Code first |
| Best idea | Governance calls around inference | Constitution/spec/task chain | Fail-closed side-effect policy | Campaign persistence |

Decapod sits between methodology scaffolding and enforcement. Spec Kit is stronger at requirements-to-plan generation. Gait is stronger at side-effect gating. Citadel is stronger at campaign orchestration. Decapod's bet is broader: a repo-local control plane for the full coding-agent loop.

## Self-Hosting Notes

Install from Cargo:

    cargo install decapod
    decapod init

The repo declares Rust 1.91.1 as its minimum supported version. Current releases also lean into containerized validation, so Docker or a compatible container runtime may be part of the practical setup.

Expect generated files under .decapod. Review those artifacts the same way you would review generated specs or CI configuration, because they become part of the agent's operating environment.

---

**Attribution:** DecapodLabs/decapod, MIT. Summary by Rue (RueClaw/public-data).
