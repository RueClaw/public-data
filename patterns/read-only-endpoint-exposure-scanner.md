# Read-Only Endpoint Exposure Scanner

**Source:** https://github.com/perplexityai/bumblebee  
**License:** Apache-2.0  
**Reviewed:** 2026-05-23  

## Pattern

For software supply-chain response, build a scanner that answers one narrow question: "Does this developer endpoint currently show on-disk metadata for a known affected package/version?"

The scanner should not execute package managers, download packages, parse source code, or claim runtime compromise. It should read bounded metadata files, normalize component identities, match against operator-supplied exact exposure catalogs, and emit structured records that a receiver can safely dedupe and promote to current state.

## Core Design

- **Read-only collection:** read lockfiles, package-manager install metadata, extension manifests, and supported tool configs.
- **No package execution:** avoid npm ls, pip show, go list, or any command that executes package code or plugin hooks.
- **Bounded profiles:** separate lightweight baseline roots, known project roots, and explicit incident-response deep roots.
- **Explicit exposure catalogs:** match exact ecosystem/name/version tuples from a trusted operator-provided catalog.
- **Structured NDJSON:** emit package, finding, diagnostic, and scan_summary records.
- **Stable record IDs:** derive IDs from canonical identity tuples so receivers can dedupe across scans.
- **Safe filesystem walking:** exclude credential directories, protected OS subtrees, build caches, editor runtime state, and oversized files.
- **Separated diagnostics:** keep warnings/errors on stderr or diagnostic records rather than mixing them with inventory records.

## Why It Works

Supply-chain incident response often has a gap between SBOM and EDR:

- SBOMs describe what shipped, not every local developer checkout, extension, MCP config, or package-manager cache.
- EDR describes runtime activity, but may not answer whether a compromised package version exists in a lockfile or installed metadata right now.

A read-only exposure scanner fills that gap. It gives responders current endpoint evidence without increasing execution risk during the investigation.

## Receiver Model

Every scan should end with a summary record. Downstream systems should promote a run to current state only when the summary says the run completed within acceptable bounds. Package and finding records should be content-addressed so repeated scans are idempotent.

Recommended record classes:

- package: normalized component inventory
- finding: exact catalog match with severity and evidence
- diagnostic: skipped files, parse errors, permission denials, size-limit skips
- scan_summary: roots, counts, duration, truncation/cancellation status

## Caveats

- Exact matches are only as good as the catalog. This pattern does not replace threat-intel curation.
- Presence is not execution. Treat findings as exposure evidence, then combine with logs, EDR, package registry data, and credential telemetry.
- Local metadata can be stale, partial, or duplicated. Confidence levels and source_type fields are useful.
- Toolchain versions matter for static binaries that use network sinks; build with a patched Go toolchain.

---

**Attribution:** perplexityai/bumblebee, Apache-2.0
