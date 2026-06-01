# Portable Agent Brain Adapters

**Source:** codejunkie99/agentic-stack  
**Repo:** https://github.com/codejunkie99/agentic-stack  
**License:** Apache-2.0  
**Reviewed:** 2026-05-31

## Pattern

Keep agent memory, skills, protocols, tools, and local telemetry in one project-local "brain" directory, then connect each coding-agent harness through a small validated adapter. The harness becomes a mount point, not the source of truth.

## Shape

```text
project/
  .agent/
    memory/
      personal/
      working/
      episodic/
      semantic/
    skills/
      _index.md
      _manifest.jsonl
      <skill>/SKILL.md
    protocols/
      permissions.md
      delegation.md
      tool_schemas/
    tools/
      recall.py
      learn.py
      data_layer_export.py
      data_flywheel_export.py

adapter manifest
  -> validated source/destination paths
  -> copy/merge/link files into harness-specific locations
  -> record ownership in install state
  -> doctor/remove/upgrade use that state later
```

## Why It Works

Agent tools change quickly. User memory, conventions, lessons, and reusable skills should not be trapped in one harness's private format. A local brain directory gives every tool the same durable context while preserving a simple escape hatch: it is just files.

The adapter layer keeps portability from turning into copy-paste drift. Each harness declares what it needs, the installer validates paths before writing, and install state records which files were created versus pre-existing.

## Implementation Notes

- Use progressive skill loading: keep a compact index and manifest in context, then load full skill bodies only when triggers match.
- Separate memory by purpose: personal preferences, live working state, raw episodic events, and accepted semantic lessons.
- Keep permissions and delegation rules as first-class files.
- Validate adapter manifests against path traversal, absolute paths, unknown keys, and unsupported actions.
- Track install ownership so uninstall can remove only files the installer created.
- Treat data exports and flywheel outputs as local artifacts unless explicitly shared.
- Use digest checks and secret scans when transferring memory bundles.
- Block adapter imports from overwriting permission policy files.

## Caveats

Portable memory can accidentally carry private data farther than intended. Make transfer scopes explicit, scan for secrets, and keep personal preferences separate from semantic lessons. Also treat bootstrap installers carefully: a digest on transferred data does not pin any remote installer code that fetches the stack itself.

## When To Use

This pattern fits teams or individuals who use multiple coding-agent tools, want durable lessons to survive tool switches, and prefer inspectable file-backed state over hosted memory by default.

It is overkill for a single narrow bot with no cross-harness use and no long-lived local memory.

---

**Attribution:** Pattern extracted from codejunkie99/agentic-stack, Apache-2.0.
