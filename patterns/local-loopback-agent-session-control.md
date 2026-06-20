# Local Loopback Agent Session Control

**Source:** [modem-dev/hunk](https://github.com/modem-dev/hunk)  
**License:** MIT  
**Reviewed:** 2026-06-20  
**Pattern type:** Agent/tool UI control plane

## Pattern

Give a human-facing local application a small loopback-only control plane so agents can inspect and steer the live UI through structured commands.

The core split is:

- the human uses the normal interactive UI
- the app registers live session state with a local broker
- agents call compact commands such as `list`, `review`, `navigate`, `reload`, and `comment`
- the app validates those commands against the original session bounds before mutating state or reading files

This avoids two bad extremes: agents scraping terminal pixels, and agents taking over the entire UI process. The agent gets a narrow API shaped around review tasks; the human keeps the actual review surface.

## Why It Works

The useful move is making "where the user is looking" and "what the agent can annotate" first-class state. In Hunk, a live diff session can expose selected file/hunk context, accept navigation commands, and apply inline comments beside code. That turns review into shared state rather than a hidden transcript.

The pattern is strongest when the command API returns compact structural summaries by default and only exposes raw patches or large payloads on explicit request. That keeps agent context small and makes accidental data dumping less likely.

## Guardrails

A local control plane should treat same-machine access as powerful and keep the default boundary tight:

- bind to loopback by default
- require an explicit unsafe opt-in for non-loopback hosts
- validate Host and Origin headers to reduce DNS-rebinding risk
- enforce request-body limits
- keep reloads inside the original repository or session root
- resolve symlinks and existing ancestors before allowing file reads
- avoid shell execution when launching pagers, editors, or helper tools
- make mutating commands explicit and auditable

## Where To Use It

This is a good fit for terminal or desktop developer tools where an AI assistant should guide the human through state that already exists locally: code review, test failure triage, trace inspection, log review, debugger navigation, and document review.

It is a poor fit for remotely exposed services unless the broker grows real authentication, authorization, identity, and audit controls. Loopback-only is a feature, not an implementation detail.

## Source Pointers

- `src/session-broker/brokerConfig.ts` — loopback default and unsafe remote opt-in
- `src/session-broker/brokerServer.ts` — Host/Origin validation and session API dispatch
- `src/hunk-session/sessionFileBounds.ts` — symlink-aware reload bounds
- `src/hunk-session/cli.ts` — agent-facing session commands
- `docs/agent-workflows.md` — user-facing workflow model

---

**Attribution:** modem-dev/hunk, MIT License
