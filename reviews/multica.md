# multica

- **Repo:** <https://github.com/multica-ai/multica>
- **License:** Source-available, Apache-2.0-derived with commercial restrictions (not standard Apache 2.0)
- **Commit reviewed:** `287a9eb` (2026-04-15)

## What it is

Multica is an **AI-native task management platform** where coding agents are treated as first-class teammates. The pitch is basically:

- assign work to agents like humans
- let them execute through local or cloud runtimes
- track progress on a board
- accumulate reusable skills
- support mixed human + agent teams

Stack-wise it is a real application, not a landing page in a trenchcoat:
- Next.js frontend
- Go backend
- PostgreSQL with pgvector
- local daemon for agent execution
- support for Claude Code, Codex, OpenClaw, OpenCode, Hermes, and Gemini in code paths

## First impression

This is one of the more serious repos in this space.

Not because the idea is novel, but because the team has clearly thought through the ugly operational middle: runtime registration, daemon behavior, task claiming, auth, self-hosting, workspace isolation, package boundaries, and cross-platform UI reuse.

That already puts it ahead of half the "agent platform" field, which is usually just optimism wearing Tailwind.

## What is technically interesting

### 1. The daemon-runtime model is the real center of gravity
The important piece is not the board UI. It's the local daemon.

`server/internal/daemon/daemon.go` shows the actual product shape:
- resolve auth from CLI config
- register runtimes per workspace
- detect installed agent CLIs and versions
- poll for tasks
- execute them in isolated workspaces
- heartbeat and usage reporting
- repo cache management
- runtime deregistration on shutdown

This is the part that makes "agents as teammates" operational instead of theatrical.

### 2. Unified backend interface for multiple coding agents
`server/pkg/agent/agent.go` defines a unified backend abstraction for:
- Claude
- Codex
- OpenCode
- OpenClaw
- Hermes
- Gemini

That is a good pattern. The repo is not hardwiring itself to one vendor. It is treating agent CLIs as swappable execution backends behind a common execution/session interface.

### 3. OpenClaw integration is handled like a real adapter
The OpenClaw backend is not superficial. `server/pkg/agent/openclaw.go`:
- spawns the CLI with structured flags
- consumes NDJSON event streams
- maps tool/text/lifecycle events into internal message types
- accumulates token usage and session identity
- handles timeouts and cancellation

That adapter work is the boring, necessary glue most "multi-agent platform" projects handwave. Multica actually does it.

### 4. Architecture discipline is unusually explicit
The root `CLAUDE.md` is opinionated in a useful way:
- React Query owns server state
- Zustand owns client state
- shared packages have hard boundaries
- no `next/*` imports in shared views
- platform-specific code constrained to app/platform layers

This is not glamorous, but it is exactly the kind of discipline that keeps a cross-platform app from turning into soup.

### 5. Self-hosting story exists and is coherent
The self-host docs are clear enough that this appears genuinely deployable, not merely "open source" in the ceremonial sense.

The split is sensible:
- server stack via Docker Compose
- daemon on each teammate's local machine
- CLI handles auth + pairing + startup

That matches the problem shape.

## Strong design patterns

### Agents as runtimes, not just names in a dropdown
The daemon registers runtimes with version and provider information. That is much better than pretending "agent = model".

### Query cache vs local state split
Their React Query and Zustand separation is one of the clearest examples we've seen in these repos. Good rule set, good guardrails.

### Monorepo package boundary enforcement
`core`, `ui`, and `views` each have explicit responsibilities. This is the kind of thing people always claim and rarely maintain. Here it appears to be taken seriously.

### Workspace-aware operations
A lot of the backend and daemon design is explicitly workspace-scoped. Good. Multi-tenant agent systems get weird fast if that is fuzzy.

## Caveats

### 1. License is not really open source in the clean sense
This matters. The repo says "open source" but the license adds commercial restrictions around hosted/embedded use. So this is source-available with limits, not plain Apache freedom.

Not evil, just worth stating plainly.

### 2. Cloud-first posture makes it less personally interesting than local-first systems
Compared with something like Paperclip or some of the personal-agent orchestration repos, Multica is more team-product shaped. That is a strength commercially, but it also means more coordination, more auth, more moving parts.

### 3. Operational complexity is real
Go backend, Next.js app, Electron app, local daemon, multiple agent CLIs, PostgreSQL, WebSockets, self-hosting paths. This is not a lightweight system.

### 4. "Skills compound over time" still needs scrutiny
The repo clearly believes in reusable skills as a core value prop. That can be real, but this category often overclaims on transferability. I'd want to inspect the actual skill packaging and retrieval paths more deeply before buying the full story.

## Why it matters

Multica is one of the stronger examples of the shift from:
- "let me run an agent"

into:
- "let me manage a team where some coworkers are agents"

That is a more serious product surface. It requires identity, runtime management, task lifecycle, collaboration primitives, and a stable operational loop. This repo appears to understand that.

## Comparison notes

### Versus Paperclip
The README's comparison is directionally fair.
- Multica is more team-collaboration/product platform
- Paperclip is more governance-heavy local operator framework

### Versus OpenClaw itself
OpenClaw is a runtime/agent platform.
Multica is trying to be the management layer *above* runtimes.
That distinction makes sense.

### Versus rowboat / obsidian-mind / llm-context-base
Those are memory or personal-knowledge oriented.
Multica is execution-and-coordination oriented.
Very different layer.

## Verdict

This is a real product repo with real architecture, not just a deck pretending to be code. The daemon/runtime model and multi-agent backend abstraction are the strongest parts. The repo understands that the hard part is not generating text, it's operating agents reliably inside a team workflow.

The biggest footnote is the license, which is more restrictive than the README's "open-source managed agents platform" vibe initially suggests.

Still, on substance, this is one of the more credible agent-management systems we've reviewed.

**Rating:** 4.5/5

## Patterns worth stealing

- Treat agent CLIs as pluggable execution backends behind one session interface
- Use a local daemon as the operational bridge between board software and agent runtimes
- Separate server state and client state ruthlessly (React Query vs Zustand)
- Enforce package boundaries hard in shared cross-platform monorepos
- Register runtimes with provider/version/workspace context instead of modeling agents as static abstract entities
