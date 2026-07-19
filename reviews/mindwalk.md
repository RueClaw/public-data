# mindwalk (cosmtrek/mindwalk)

**Repo:** https://github.com/cosmtrek/mindwalk
**License:** MIT; permissive reuse with attribution.
**Reviewed:** 2026-07-19
**Stack:** Go 1.25, React 19, Vite 7, Three.js, TypeScript, Playwright, JSON Schema
**What it is:** A local visualizer that replays Claude Code and Codex coding-agent sessions over a deterministic 3D map of the repository.

---

## Verdict

✅ **Deploy candidate for local agent-session review.** mindwalk has a strong architecture for turning opaque JSONL agent logs into trace, map, and evaluation artifacts without making viewing depend on a hosted service. It is still young, but the test posture is unusually good for a fresh visual tool: Go tests, frontend build, local Playwright e2e, JSON schemas, CI, release automation, and checksum-verified installer.

---

## What It Is

mindwalk answers a concrete agent-ops question: not just "what did the agent change?", but "where did the agent look, what did it ignore, when did it edit, and whether its footprint matched the task." It parses Claude Code and Codex session logs, builds a deterministic repository map, and plays agent activity back as file-touch states over either a radial tree or treemap terrain.

The default `mindwalk` command scans local Claude Code and Codex session directories, binds a Go server to `127.0.0.1` on a random port, and opens a React/Three.js UI. It also offers CLI exports for normalized traces, repository citymaps, and optional evaluation reports.

The optional evaluation path is the sensitive feature. Viewing stays local, but evaluation sends a derived session summary to the model behind the user's local `claude` or `codex` CLI. The code handles that boundary deliberately: evaluation starts only from explicit user action, runs with bounded concurrency, caches reports under `~/.mindwalk/reports`, and attempts to run judge subprocesses without tools, MCP servers, user settings, or session persistence.

## Stack

| Layer | Tech |
|-------|------|
| CLI/backend | Go 1.25 |
| Adapters | Claude Code JSONL, Codex JSONL |
| Map engine | Deterministic squarified treemap / tree model |
| Frontend | React 19, TypeScript, Vite 7 |
| 3D rendering | Three.js |
| Testing | Go tests, TypeScript build, Playwright e2e |
| Contracts | JSON schemas for trace, citymap, report, agent graph |
| Release | GitHub Actions, GoReleaser, checksum-verified install script |

## Key Features

### Trace / Citymap / Report Separation

The core design keeps three artifacts separate:

- **Trace:** normalized stream of file-touch events from agent logs.
- **Citymap:** deterministic repository layout independent of playback.
- **Report:** optional evidence-anchored judge findings.

That separation makes the tool easier to test and safer to extend. Adapters do not know about rendering, citymap generation does not depend on playback, and the judge reads normalized trace material rather than raw session logs.

### Local 3D Session Replay

The UI shows tree and terrain views, file touch states, a playback deck, timeline marks for compaction/subagents/user turns, inspector history, and "agent lenses" for subagent traces. The visual metaphor is polished, but the useful part is operational: it makes exploration, edit timing, churn, unvisited files, stale ghosts, and verification gaps visible quickly.

### Sealed Optional Judge

The judge path is one of the better parts of the repo. It treats the evaluated trace as untrusted input, requires explicit POST/CLI invocation, strips tool access from spawned `claude`/`codex` runs, asks only for evidence-backed findings, and computes verdicts mechanically from normalized severities. That is the right posture for model-assisted review of model activity.

### Strong Early Test Signals

Local verification passed:

```text
go test ./...                         passed
npm --prefix web ci                   passed
npm --prefix web run build            passed
npm --prefix web audit --omit=dev     0 vulnerabilities
npm --prefix web run test:e2e         15 passed
```

The CLI smoke tests also worked: `trace` parsed the bundled Claude Code fixture, and `build` produced a citymap for the repository.

## Architecture

The repository is small and well-bounded:

```text
cmd/mindwalk              CLI commands
internal/adapter          shared trace adapter primitives
internal/adapter/claudecode
internal/adapter/codex
internal/citymap          deterministic repository layout
internal/judge            sealed local CLI judge and report parsing
internal/model            trace, citymap, report, agent graph contracts
internal/server           loopback API and embedded frontend
schema                    JSON schemas
web                       React/Three.js frontend
```

The server binds explicitly to loopback:

```go
ln, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", port))
```

The citymap builder prefers `git ls-files -co --exclude-standard -z`, then falls back to a directory walk that skips common heavy directories. It records commit and dirty state, which makes exported maps more auditable.

The judge runner is the most reusable subsystem. For Codex, it uses an ephemeral, read-only, no-tool execution shape; for Claude, it disables session persistence, tools, MCP config, and settings sources. The report parser then rejects unsupported dimensions, invalid severities, and findings that do not cite real trace event IDs.

## Comparison

mindwalk sits between raw session log viewers, trace stores, and general browser/coding-agent harnesses. Its niche is visual trajectory review, not full observability or run capture.

| Aspect | mindwalk | Trace store | Raw JSONL logs |
|--------|----------|-------------|----------------|
| Primary job | Visual replay of agent attention | Persistent capture/search | Full raw record |
| Runtime | Local loopback UI | Usually service/database | None |
| Data model | Trace + citymap + optional report | Runs/events/metadata | Harness-specific |
| Best use | Reviewing how an agent moved through code | Searching and auditing many runs | Forensic source of truth |
| Main caveat | Young, format-sensitive, optional judge can upload summaries | Heavier operational footprint | Hard to read directly |

## Self-Hosting Notes

No hosted backend is needed. The normal install path downloads a release archive and verifies it against `checksums.txt`, though users should still treat `curl | sh` installers with the usual caution.

Operational notes:

- Keep the server loopback-only; do not expose it on a network without adding authentication and redaction.
- Treat session logs as sensitive. They can include task wording, file paths, commands, and fragments of private work.
- Evaluation is not local-only if the selected judge CLI uses a cloud model. The README explains this clearly, but deployments should reinforce it in policy.
- Watch adapter drift. Claude Code and Codex log formats are moving targets.
- CI currently covers Go tests and embedded frontend verification; local Playwright e2e passed, but e2e is not part of the visible CI workflow.

---

**Attribution:** cosmtrek/mindwalk, MIT.
