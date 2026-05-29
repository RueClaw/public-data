# Local-First Agent Trace Store

**Source:** ssreeni1/tracebase  
**Repo:** https://github.com/ssreeni1/tracebase  
**License:** MIT  
**Extracted:** 2026-05-29

## Pattern

Capture agent runs as local engineering traces instead of only chat transcripts:

```text
agent transcript / hook / wrapper / intake
  -> normalize visible events
  -> encrypt raw payload locally
  -> redact and compact searchable metadata
  -> append durable JSONL audit rows
  -> build a rebuildable SQLite/FTS index
  -> expose bounded CLI, dashboard, MCP, export, and analysis views
```

## Why It Works

Agent sessions contain sensitive data, but debugging requires fidelity. Splitting raw encrypted payloads from redacted searchable metadata lets the tool preserve forensic detail without making raw transcript contents the default read path.

The append-only log plus rebuildable index shape is also operationally useful. If the SQLite index breaks or needs schema changes, it can be rebuilt from durable local rows and encrypted blobs.

## Implementation Notes

- Bind browser surfaces to loopback by default.
- Require explicit flags for remote bind, live intake, raw blob reads, and raw exports.
- Store raw payloads in encrypted blobs with locally generated or externally supplied keys.
- Redact secrets before building searchable summaries and structured fields.
- Keep raw exports separate from normal exports, with an intentional local action gate.
- Treat MCP as a narrow read-only inspection surface unless there is a strong reason to expose writes.
- Include incident bundles that package metrics, annotations, and redacted events without raw payloads.
- Add tests for origin checks, traversal attempts, raw export gates, redaction, package contents, and install smoke.

## Where To Use It

Use this pattern for local agent observability, eval traces, debugging dashboards, support incident packets, and privacy-sensitive developer telemetry. It is especially useful when the operator needs to answer:

- What did the agent do?
- What commands failed?
- Did it run tests?
- Which files/tools mattered?
- Which repeated actions burned context?
- What can be shared safely?

## Caveats

Local encrypted storage is not a substitute for data minimization. Raw transcripts can still contain prompts, paths, outputs, credentials, and private context. Default exports should remain redacted, and raw access should stay explicit, local, and auditable.

**Attribution:** ssreeni1/tracebase, MIT.
