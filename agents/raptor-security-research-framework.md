# RAPTOR Security Research Framework

> **Source:** [gadievron/raptor](https://github.com/gadievron/raptor)
> **License:** MIT
> **Description:** Autonomous offensive/defensive security research framework based on Claude Code. Progressive loading, binary analysis, and exploit development workflows.

## Overview

RAPTOR is a security research framework that orchestrates vulnerability analysis with progressive context loading, multi-agent crash analysis, and exploitability validation.

## Core Commands

```
/scan /fuzz /web /agentic /codeql /analyze  - Security testing
/exploit /patch                              - Generate PoCs and fixes
/validate                                    - Exploitability validation pipeline
/crash-analysis                              - Autonomous crash root-cause analysis
/oss-forensics                               - GitHub forensic investigation
/create-skill                                - Save approaches
```

## Progressive Loading Architecture

Load context only when needed:

```
When scan completes:        Load tiers/analysis-guidance.md
When validating:            Load exploitability-validation/SKILL.md
When validation errors:     Load tiers/validation-recovery.md
When developing exploits:   Load tiers/exploit-guidance.md
When errors occur:          Load tiers/recovery.md
When requested:             Load tiers/personas/[name].md
```

## Exploitability Validation Pipeline

Six-stage validation process:

```
Stage 0 (Inventory) → A (One-Shot) → B (Process) → C (Sanity) → D (Ruling) → E (Feasibility)
```

Each stage has gates that must pass before proceeding.

## Crash Analysis System

Multi-agent crash root-cause analysis for C/C++ crashes:

### Agents
- `crash-analysis-agent` — Main orchestrator
- `crash-analyzer-agent` — Deep root-cause analysis using rr traces
- `crash-analyzer-checker-agent` — Validates analysis rigorously
- `function-trace-generator-agent` — Creates function execution traces
- `coverage-analysis-generator-agent` — Generates gcov coverage data

### Skills
- `rr-debugger` — Deterministic record-replay debugging
- `function-tracing` — Function instrumentation
- `gcov-coverage` — Code coverage collection
- `line-execution-checker` — Fast line execution queries

## OSS Forensics Investigation

Evidence-backed forensic investigation for public GitHub repositories:

### Agents
- `oss-forensics-agent` — Main orchestrator
- `oss-investigator-gh-archive-agent` — Queries GH Archive via BigQuery
- `oss-investigator-gh-api-agent` — Queries live GitHub API
- `oss-investigator-gh-recovery-agent` — Recovers deleted content
- `oss-investigator-local-git-agent` — Analyzes cloned repos
- `oss-investigator-ioc-extractor-agent` — Extracts IOCs from vendor reports
- `oss-hypothesis-former-agent` — Forms evidence-backed hypotheses
- `oss-evidence-verifier-agent` — Verifies evidence
- `oss-hypothesis-checker-agent` — Validates claims
- `oss-report-generator-agent` — Produces final report

## Binary Analysis Flow

**Principle: Find vulnerabilities FIRST, then check exploitability.**

1. **Analyze the binary** — Find vulnerabilities (buffer overflows, format strings, etc.)
2. **If vulnerabilities found** — Run exploit feasibility analysis (MANDATORY)

```python
from packages.exploit_feasibility.api import analyze_binary, format_analysis_summary

# MANDATORY: Run this after finding vulnerabilities
result = analyze_binary('/path/to/binary')
print(format_analysis_summary(result, verbose=True))
```

### Why Use Exploit Feasibility Analysis

Catches critical constraints that checksec/readelf miss:
- Empirical %n verification (glibc may block it)
- Null byte constraints from strcpy
- ROP gadget quality
- Input handler bad bytes
- Full RELRO blocking .fini_array

## Output Style Rules

**Human-readable status values:**
- `Exploitable` not `EXPLOITABLE`
- `Confirmed` not `CONFIRMED`
- `Ruled Out` not `RULED_OUT`

**No red/green status indicators:**
- Don't use 🔴/🟢 — perspective-dependent
- Other emojis are fine (⚠️, ✓, etc.)

## Safety Boundaries

```
Safe operations (install, scan, read, generate): DO IT.
Dangerous operations (apply patches, delete, git push): ASK FIRST.
```

## Key Design Principles

- **Python orchestrates everything** — Claude shows results concisely
- **Progressive loading** — Load context only when needed
- **Multi-agent verification** — Separate agents for analysis and checking
- **Evidence-backed conclusions** — All claims require verification
- **Constraint-aware exploitation** — Always verify feasibility before attempting
