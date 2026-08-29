# agenttrail (sodiumsun/agenttrail)

**Repo:** https://github.com/sodiumsun/agenttrail  
**License:** MIT; permissive reuse with attribution  
**Reviewed:** 2026-08-29  
**Stack:** Node.js 20+, static HTML/CSS/JavaScript, Server-Sent Events, local filesystem watcher, Claude Code hooks  
**What it is:** A local dashboard for watching coding-agent work as a live repo/component map, combining a durable `PLAN.md` convention with observed file changes and optional Claude Code hook events.

---

## Verdict

✅ **Deploy candidate for local agent-work visibility.** agenttrail is small, local-first, dependency-free at runtime, and aimed at a real pain: seeing whether coding agents are making progress, drifting, or revisiting work they claimed was done. The main caveat is maturity: the repo is young, has no automated tests, and ships most behavior in one Node file plus one static HTML file.

---

## What It Is

agenttrail runs a per-repo localhost daemon, watches file changes, parses `PLAN.md`, and renders a browser board showing components, dependencies, tasks, recent edits, and active run cards. The design is intentionally closer to a live project map than an LLM tracing product: the important object is the repository and the work moving through it, not token latency or prompt telemetry.

The core convention is a Markdown plan file maintained by coding agents. Components use stable `{#id}` anchors, `files:` globs connect source paths to components, task checkboxes carry status, and `needs:`/`links:` draw dependencies. Even without a plan, the tool still provides live file activity; `init` scaffolds the convention and can add local Claude Code hooks for richer tool/todo/run cards.

It supports Claude Code most deeply through local hooks, while Codex, Cursor, or any file-editing agent can still use the plan convention and filesystem watcher path.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Dependency-free Node.js ESM CLI, Node >=20 |
| Server | Built-in `node:http`, bound to `127.0.0.1` |
| Realtime | Server-Sent Events plus small JSON polling endpoints |
| State | `PLAN.md` in repo, transient daemon state, `~/.agenttrail/*.json` board registry/cache |
| File watching | `fs.watch`, recursive where available with Linux fallback |
| Agent hooks | Claude Code `PreToolUse`, `PostToolUse`, `Stop`, `SessionStart` relay |
| Frontend | Single static `public/index.html` with SVG graph UI |
| Packaging | npm CLI package, six-file tarball including demo GIF |

## Key Features

### Plan-Backed Component Map

The `PLAN.md` parser turns owner-readable headings, stable IDs, task statuses, file ownership globs, and dependency edges into a live model. That is the strongest design choice in the repo: it keeps the map inspectable and editable instead of hiding the state in an opaque database.

### Observed vs. Declared Work

agenttrail separates what the agent says it is doing from what the filesystem shows. Components light up when their owned files change, including finished components. That catches a common agent failure mode: quietly reopening or rewriting work that the plan already marked complete.

### Claude Code Run Cards

Optional hooks relay Claude Code tool events to the local daemon. The board can show current tool, recent calls, todos, and which component a session is touching. Hook relays are fail-silent and capped with short timeouts so agent execution is not blocked by the dashboard.

### Multi-Repo Board Discovery

Each repo gets its own daemon. Boards discover neighboring ports, expose summaries, and render multiple repos as regions in one world map. `agenttrail up` can relaunch known boards, and `agenttrail autostart` writes launchd or systemd user config.

### Local-First Trust Posture

The server binds to loopback, the package has no runtime dependencies, no account, no cloud service, and no telemetry. The dashboard observes repo changes and can scaffold plan/hook files when the user consents.

## Architecture

The backend is compact: argument parsing, plan parsing, hook ingestion, filesystem watching, state persistence, HTTP routes, lifecycle helpers, and init/autostart live in `bin/agenttrail.mjs`. The frontend is a single static HTML file that renders the tree, graph, run cards, minimap, theme switching, and setup flows.

The tradeoff is obvious. The "one readable file" approach makes the system easy to audit and easy to ship through `npx`, but it also means there is no clear module boundary for tests, parser evolution, hook adapters, or server hardening. As the feature set grows, extracting the parser/model and route handlers would pay off.

Security posture is good for local-only usage: loopback bind, same-origin UI, no telemetry, no prompt-sending agent control loop, and repo-local hook settings. Risk concentrates in local authority: `/setup` can append files and install hooks, `/spawn` can launch a daemon for an arbitrary local directory supplied by the browser, and autostart writes user launch configuration. Those are acceptable local-tool powers, but they should remain loopback-only.

## Comparison

| Aspect | agenttrail | Scopey | Tracebase | Mission Control |
|--------|------------|--------|-----------|-----------------|
| Primary job | Live repo/component work map | Keep sessions on scope | Capture/search agent traces | Operate agent fleets/tasks |
| Storage | Markdown plan plus small local cache | JSON logs | Encrypted blobs + SQLite/FTS | SQLite app state |
| Control authority | Mostly observe; setup/spawn/autostart helpers | Advisory hook corrections | Read/search/export traces | Dispatch, approvals, admin panels |
| Best fit | Watching active coding sessions | Scope drift reminders | Incident/debug history | Full operator console |

agenttrail is much lighter than Tracebase or Mission Control and less corrective than Scopey. Its niche is visual, repo-grounded situational awareness while work is happening.

## Self-Hosting Notes

Run it from a repository:

```bash
npx agenttrail
```

For the full map, run:

```bash
npx agenttrail init
```

The package is suitable for local workstation use. Avoid exposing the port remotely; there is no authentication layer, and several endpoints intentionally assume trusted local access.

Validation during review:

```bash
node --check bin/agenttrail.mjs
npm pack --dry-run
```

Both passed. The repo does not include an automated test suite.

---

**Attribution:** sodiumsun/agenttrail, MIT License
