# claude-usage

- **Repo:** <https://github.com/phuryn/claude-usage>
- **License:** MIT
- **Commit reviewed:** `af507cd` (2026-04-09)

## What it is

A local dashboard that scans Claude Code transcript logs and turns them into:

- usage totals by model
- cost estimates using Anthropic API pricing
- session/project visibility
- a lightweight web dashboard served from Python stdlib only

No framework circus, no SaaS middleman, no telemetry stunt. Just parse local JSONL, store it in SQLite, render useful charts.

## Why it stands out

The repo is aggressively boring in a good way.

- `scanner.py` ingests transcripts incrementally
- `dashboard.py` serves the UI
- `cli.py` exposes `scan`, `today`, `stats`, and `dashboard`
- SQLite is the storage layer
- stdlib-only Python keeps install friction near zero

That's the whole trick.

## Best part

### Local logs are the real API
Claude Code already emits the data. This repo simply notices. That's the right instinct.

A lot of tooling tries to create observability by inserting itself into the workflow. This one extracts observability from artifacts already being produced.

## Practical strengths

### 1. Tiny operational footprint
No `pip install`, no web framework, no bundler. That matters.

### 2. Incremental scan design
Tracking file path + mtime is enough to make rescans fast without overengineering the ingestion layer.

### 3. Useful distinction between subscription reality and API pricing
The README is clear that costs are estimates based on API rates, not literal Max/Pro billing. Good.

### 4. Works across multiple Claude surfaces that still write local logs
CLI, VS Code extension, dispatched sessions. That makes it more than a toy.

## Limitations

- It only sees what writes local transcripts, so cowork sessions are invisible.
- Cost estimates are model-name heuristic based, not billing-authoritative.
- This is analytics, not control. It tells you what happened, not how to optimize automatically.
- Claude-specific. The pattern generalizes, but the repo itself is narrow.

## Why it matters for us

This is a very reusable pattern for agent tooling generally:

- treat session artifacts as the source of truth
- parse them into a local DB
- provide both terminal summaries and a dead-simple dashboard

The repo is a nice reminder that you can get a lot of value from **artifact mining** before building any protocol integration.

## Verdict

Small, focused, and actually useful. No magical claims, just solid local introspection over existing logs.

I trust repos like this more than bigger ones because they know exactly what problem they're solving.

**Rating:** 4/5

## Patterns worth stealing

- Use local transcript artifacts as an analytics substrate
- Incremental JSONL ingestion into SQLite
- Standard-library-only local dashboarding for low-friction ops tools
- Separate observed metrics from inferred pricing/cost semantics
