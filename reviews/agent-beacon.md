# Beacon (Asymptote-Labs/agent-beacon)

**Repo:** https://github.com/Asymptote-Labs/agent-beacon  
**License:** MIT. Free to reuse and extract with attribution. The open Threat Rules corpus (`rules/`, `spec/threat-rules`) ships in the same repo under the same license. The optional hosted pieces (Beacon Managed ingest, the Jev trace evaluator) are services, not code in this repo.  
**Reviewed:** 2026-09-27 (commit `04ac5fd`, 2026-09-27; latest release v1.3.26)  
**Stack:** Go 1.25 (CLI, hook adapter, OpenTelemetry Collector exporter), TypeScript (runtime plugins, MV3 browser extension, JS SDK), Vector for optional forwarding, launchd/systemd/MSI packaging  
**What it is:** A local endpoint agent that captures sessions from ~30 AI coding harnesses (Claude Code, Codex, Cursor, OpenCode, Cline, Hermes Agent, Copilot CLI, Pi, and more) through hooks, OTLP, plugins, and session-store polling. It normalizes them into one OpenTelemetry-shaped JSONL event log, then layers a trace browser, dashboard, threat-rule scanning, cross-harness session handoff, and a reviewed "memory" workflow on top.

---

## Verdict

⚠️ **Interesting. The capture layer is excellent; the "self-improving memory" pitch is the thinnest part.** As cross-harness agent telemetry, this is the most complete open implementation I've seen. It has per-runtime adapters with honestly documented gaps, a single normalized event schema, loopback-only collectors, redaction before write, and forwarding to a dozen SIEMs. The memory loop marketed on the README is a set of Agent Skills plus CLI commands. The scoring step calls a hosted evaluator (TypeSafe's Jev) that needs an API key, and the actual lesson is written by your agent and approved by you. That's a reasonable design, but it isn't the automatic, compounding memory the tagline implies. Two more caveats. The interactive installer preselects the hosted "Beacon Managed" forwarding (you have to opt out to Local). And the project ships very fast: three releases in two days and a 7.5 MB Go codebase after four and a half months. Deploy it if you want an audit trail of what your agents did across tools. Treat the memory features as optional extras.

---

## What It Is

Beacon sits under the harness layer. It installs hooks, OTLP settings, or managed plugins into each agent runtime it finds. It runs a local OpenTelemetry Collector with a custom `beaconjson` exporter, and it writes everything to `~/.beacon/endpoint/logs/runtime.jsonl`, rotated at 10 MiB with five archives. Consumers read that log:

- `beacon traces` is a TUI trace browser, and `beacon endpoint dashboard` is a loopback web view.
- `beacon scan` runs CEL-based Threat Rules offline over the log.
- `beacon handoff list|export|resume` moves a session from one runtime into another.
- `beacon memory ...` plus three Agent Skills (`beacon-memory-recall`, `-distill`, `-promote`) turn selected traces into approved per-project memory. That memory is exposed over MCP or Agent Skills.
- Optional forwarding goes to Splunk, Sentinel, Datadog, Elastic, S3/GCS, Falcon LogScale, or the vendor's hosted ingest.

```bash
brew tap asymptote-labs/tap && brew install beacon
beacon endpoint install      # interactive wizard; choose Local to stay offline
beacon traces
```

## Stack

| Layer | Tech |
|-------|------|
| CLI / endpoint runtime | Go (`cli/beacon`, cobra), launchd/systemd service managers, Windows MSI |
| Hook adapter | Go binary `beacon-hooks`, embedded into the CLI at build time |
| Collector | OpenTelemetry Collector distribution + custom `beaconjsonexporter` |
| Shared schema | `pkg/asymptoteobserve`: event model, harness normalization, redaction, provenance, Threat Rules engine (CEL) |
| Runtime plugins | TypeScript/Bun plugins for OpenCode, Cline, Pi-family, OpenClaw, Prime (mirrored into the CLI as embedded assets) |
| Browser capture | MV3 extension (Chromium + beta Firefox) for claude.ai / chatgpt.com streams → loopback OTLP |
| Forwarding | Vector (managed mode), SIEM content packs |
| Verification | `beacon-sandbox`: runs a real Claude Code session in a disposable sandbox and checks what was captured |

## Key Features

### Coverage Matrix That Admits Its Gaps
The README and `CLAUDE.md` document, per runtime, which signals are captured (session, prompt, tool, command, file, approval, MCP, tokens) and how: OTLP, hooks, plugin, or poll. Rules like "poll events cannot synthesize approvals" and "goose has only an adapter, don't imply it's installable" are written into the contributor guide. Kimi Code's config is appended to and verified by parse-back instead of being re-serialized, because re-serializing would drop the user's comments. This level of per-integration care is the project's strongest trait.

### One Event Schema
Everything lands as OTel GenAI-shaped events with `harness.name` and `harness.collection_method`. That means one dataset you can grep, scan, or ship, instead of 30 proprietary session formats. Token usage and runtime-reported cost are normalized into `gen_ai.usage`, and `beacon token-usage` reports on them.

### Threat Rules
There's an open rule format (`spec/threat-rules`) with CEL match conditions and conformance fixtures. It comes with 75 rules across credential access, prompt injection, context exfiltration, risky commands, approval abuse, and source control. `beacon scan` is read-only and offline. Rules live in a local store, and only an explicit `beacon rules pull <url>` touches the network.

### Session Handoff
`beacon handoff resume` reopens a session natively where the runtime supports it. Otherwise it writes a sanitized brief (0600) and starts a new session in another runtime pointed at it. It never passes approval-disabling flags, and it strips env switches like `HERMES_YOLO_MODE` and `COPILOT_ALLOW_ALL`. Quoted content is fenced with longer-than-content backtick runs, so trace content can't forge the structure of the brief.

### Policy Seam
An off-by-default hook in `pre-tool`/`permission-request` sends a JSON request to an external executable (`BEACON_POLICY_PROVIDER`) and honors allow/deny. It fails open on any error, so the open build does no enforcement itself.

### Memory Loop
`beacon memory evaluations run` scores traces with the hosted Jev evaluator. It needs `TYPESAFE_API_KEY` or `BEACON_JEV_API_KEY`, and the skill says to get consent first. Candidates are then drafted by the agent from the source trace and approved by the user. Approved items are served back through MCP or Agent Skills. Without the evaluator key, the skill tells the agent to read traces itself.

## Architecture

```
agent runtimes ──hooks──▶ beacon-hooks (no network) ─┐
               ──OTLP───▶ local Collector :4317/4318 ─┼─▶ asymptoteobserve (normalize, redact, size-limit)
               ──poll───▶ beacon endpoint <rt> sync ──┤        │
browser ext ───OTLP (127.0.0.1:4318) ────────────────┘        ▼
                                                     runtime.jsonl (+ inventory_state.jsonl)
                                                       ├─▶ traces TUI / loopback dashboard
                                                       ├─▶ scan (Threat Rules) · handoff · memory
                                                       └─▶ Vector / SIEM packs (opt-in)
```

`pkg/asymptoteobserve` is shared by the CLI, the hook adapter, and the collector exporter, so there's one normalization path. Each Go component is its own module. Plugins exist twice, as TypeScript sources and as embedded copies under `cli/beacon/internal/endpoint/hooks/assets/`, and drift between them is a maintenance risk. An inventory job runs every six hours via launchd/systemd, and there's an optional scheduled self-updater.

## Security

- **Collectors and dashboard bind to loopback.** The dashboard refuses non-loopback bind addresses and has `RequireLoopbackHost` middleware that rejects DNS-rebinding requests by Host header.
- **Hooks never touch the network.** This is stated as a hard product rule and fits the code layout (hook binary vs. separate Vector forwarder).
- **Managed forwarding is opt-out in the interactive wizard.** Beacon Managed is preselected, and confirming it starts shipping sanitized content to the vendor. A "Metadata-only" mode strips prompts, responses, tool args/results, diffs, and command output in local Vector transforms before upload. Unattended installs (system, MDM, CI, piped stdin) never enroll. The device key lives in a 0600 file outside config. `disconnect` removes local credentials but does not revoke them server-side, so revoke the device in the dashboard as well.
- **Content retention is high by default.** The log keeps prompt text, command output, raw tool inputs, and diffs, subject to secret redaction and size limits. The browser extension defaults to `full` retention of chat text. Treat `~/.beacon` as sensitive.
- **Scans:** no hardcoded `sk-`/`AKIA`/`ghp_` secrets in non-test Go/TS. The one `/bin/sh -c` is a launchd reload script with a shell-quoted path.
- **CI:** workflows default to `contents: read` (release jobs `contents: write`, npm publish uses OIDC `id-token: write`). Actions are pinned by major tag (`actions/checkout@v4`, `goreleaser-action@v6`), not SHA. The Windows sandbox workflow that runs Claude Code with `--dangerously-skip-permissions` deliberately has no `pull_request` trigger.
- Linux installer verifies `checksums.txt`, and the README says plainly that this doesn't prove provenance.

## Maturity

- Created 2026-05-12. As of review: 1,611 stars, 139 forks, 6 open issues. Releases are very frequent (v1.3.23 → v1.3.26 in ~48 h).
- 804 Go files, 377 of them tests; separate Bun/Vitest suites for plugins and extension; Playwright replay e2e for the browser extension; a real-agent sandbox for end-to-end verification (Linux only, costs money per scenario).
- Docs are extensive (`CLAUDE.md` alone is a detailed contract for every integration). The flip side is scope: 30 runtimes, 10+ destinations, a browser extension, an SDK, a rules engine, handoff, memory, and a hosted service, all from one small team.

### Validation on 2026-09-27

Go 1.25.1 on Linux x86_64. Built the embedded hooks binary first (`go build -o cli/beacon/internal/embedded/hooks.bin ./cli/beacon-hooks`), as the contributor docs require.

```text
cd pkg/asymptoteobserve && go test ./...        → 5 packages ok, 220 top-level tests passed, 0 failed
cd cli/beacon-hooks && go test ./...            → 8 packages ok, 592 top-level tests passed, 0 failed
cd cli/beacon && go test ./internal/{hermessession,managedprivacy,learning,endpoint/writer,
    endpoint/dashboard,handoff,mcpserver}/...   → 7 packages ok, 289 top-level tests passed, 0 failed
```

Without `hooks.bin`, dashboard/handoff/mcpserver fail at setup (`pattern hooks.bin: no matching files found`). That's expected and documented. I didn't run the full `cli/beacon` suite, the npm/Bun subprojects, the sandbox scenarios, or the Jev evaluator, and I didn't install the endpoint service.

## Comparison

| Aspect | Beacon | Per-harness history (built-in) | Generic OTel + LLM observability (Langfuse, Phoenix) | Agent memory layers (mem0-style) |
|--------|--------|------------------|------------------------|-----------------|
| Scope | Endpoint, ~30 coding harnesses | One tool | Apps you instrument | Apps you instrument |
| Capture method | Hooks/OTLP/plugins/poll, auto-installed | Native | SDK/OTLP | SDK |
| Storage | Local JSONL, SIEM forwarding | Tool-specific | Server DB | Vector store |
| Security use | Threat Rules, approvals, SIEM packs | None | Limited | None |
| Memory | Human-approved lessons via skills/MCP (hosted scoring optional) | Tool-specific | No | Automatic extraction |
| Best fit | Auditing and reusing agent work across tools | Single-tool users | LLM app teams | App-level personalization |

## Self-Hosting Notes

- Pick **Local** in the install wizard, or use a noninteractive install path, if nothing should leave the machine. Check `beacon endpoint status` afterwards.
- Budget disk for `~/.beacon`, and remember it holds prompts, command output, and diffs. Exclude it from sync tools and back it up like secrets.
- Hooks are written into each runtime's own config (Claude/Codex settings, `.openhands/hooks.json`, Kimi `config.toml`, and so on). Review the diff after install, and use `beacon endpoint uninstall` rather than deleting files by hand.
- The scheduled self-updater and the 6-hourly inventory job are on by default in the service installs. Disable them if your fleet manages versions another way.
- The memory scoring step needs a TypeSafe/Jev key. Everything else in the memory loop is local.

## Reusable Patterns

- **Document capture gaps per integration and forbid synthesis.** Poll paths never invent approvals or session-end events, and every event carries `collection_method`.
- **Loopback + Host-header check** for local dashboards, to defeat DNS rebinding.
- **Append-and-verify config edits.** When writing into another tool's config, append, parse the result back, compare to the intent, and only then replace the file.
- **Fail-open external policy seam** with a stable JSON contract. This keeps enforcement logic out of the open build.
- **Handoff briefs that can't forge structure.** Use fences longer than any backtick run in the quoted content, and never carry approval-bypass flags or env vars across runtimes.

---

**Attribution:** Asymptote-Labs/agent-beacon, MIT
