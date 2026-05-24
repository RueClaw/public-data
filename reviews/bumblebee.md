# Bumblebee (perplexityai/bumblebee)

**Repo:** https://github.com/perplexityai/bumblebee  
**License:** Apache-2.0; permissive reuse with patent grant and attribution.  
**Reviewed:** 2026-05-23  
**Stack:** Go 1.25+, static CLI, NDJSON output, stdlib-only runtime, GitHub Actions, GoReleaser  
**What it is:** A read-only developer endpoint scanner for package, extension, MCP, and developer-tool metadata. It answers one incident-response question: when a known compromised package or version is named, which developer machines currently show matching on-disk evidence?

---

## Verdict

✅ **Deploy candidate for targeted supply-chain exposure response.** Bumblebee has a narrow, useful scope and unusually clean operational posture: static Go binary, zero third-party runtime dependencies, no package execution, bounded profiles, structured NDJSON, stable record IDs, and bundled threat-intel catalogs. The main caveat is toolchain hygiene: local govulncheck found vulnerabilities in Go 1.26.2's standard library affecting HTTP output paths, fixed in Go 1.26.3, so release builds should use a patched Go toolchain.

---

## What It Is

Bumblebee inventories local developer-machine metadata without executing package managers or reading source code. It scans lockfiles, installed package metadata, editor/browser extension manifests, and supported MCP host configs, then emits normalized component records.

Its exposure mode takes a JSON catalog of exact ecosystem/name/version entries and emits finding records when local metadata matches. That makes it a fit for supply-chain compromise campaigns where responders already know the affected packages, such as compromised npm, RubyGems, Composer, or MCP-related artifacts.

This is not an EDR, malware scanner, SBOM generator, or vulnerability database. That boundary is a strength: it avoids claiming runtime truth and instead provides fast current-state evidence from messy developer endpoints.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Go 1.25+, single static binary |
| Dependencies | Standard library only |
| Output | NDJSON to stdout, file, or HTTPS sink |
| Inventory sources | npm, pnpm, Yarn, Bun, PyPI, Go modules, RubyGems, Composer, MCP configs, editor extensions, browser extensions |
| Exposure catalogs | JSON files/directories with exact ecosystem/name/version matches |
| CI | gofmt, go vet, race tests on Linux/macOS, build, selftest, govulncheck |
| Release | GoReleaser for darwin/linux amd64/arm64 tarballs |

## Key Features

### Read-Only Developer Inventory

The scanner explicitly avoids package-manager execution: no npm ls, pip show, go list, or similar commands. It reads known metadata files only, applies max file-size limits, and excludes high-risk or high-cost directories such as credential stores, caches, protected macOS Library subtrees, cloud config directories, and editor runtime state.

### Profiles For Different Cadences

Bumblebee has three scan profiles:

- baseline: common global/user package roots, toolchains, extensions, and MCP configs
- project: configured development roots such as code/src/work directories
- deep: explicit incident-response roots, including broad home-directory scans

Baseline and project profiles refuse bare-home roots; deep mode is the explicit escape hatch.

### Stable NDJSON State Model

Every package, finding, diagnostic, and summary is a structured record. Package/finding IDs are content-addressed over canonical identity tuples, which gives downstream systems stable dedupe across repeated scans. Each run ends with a scan_summary record so receivers can decide whether to promote that run to current state.

### Exposure Catalogs

The repo ships threat-intel catalogs for campaigns including Mini/Shai-Hulud, AntV Mini Shai-Hulud, GemStuffer, node-ipc credential stealer, nx-console VS Code compromise, shopsprint decimal typosquat, and Laravel Lang compromise. Catalogs are exact match inputs, not a live threat feed.

### HTTPS Sink With Secret Hygiene

Output can stream to stdout, file, or HTTPS. HTTP output supports bearer or HMAC auth via environment variables, gzip, batching, timeout controls, and a testing-only insecure HTTP override. MCP parsing also avoids emitting env values and strips sensitive URL parts from remote MCP server records.

## Architecture

Bumblebee is organized as small packages:

- cmd/bumblebee: CLI commands, roots, selftest, version stamping
- internal/ecosystem/*: ecosystem-specific scanners
- internal/scanner: orchestration, profile/run behavior, exposure matching
- internal/walk: bounded filesystem walker and exclusion logic
- internal/model: shared record schema and stable identity
- internal/output: stdout/file/HTTPS sinks
- internal/exposure: catalog loading and matching
- internal/normalize: ecosystem-specific name normalization

The filesystem walker surfaces entries while scanners decide what to open. That split keeps traversal policy, exclusion logic, file-size limits, and parsing responsibilities reasonably separated.

## Comparison

| Aspect | Bumblebee | SBOM Tool | EDR |
|--------|-----------|-----------|-----|
| Primary question | Which endpoints show this known bad package/version right now? | What shipped in this build/artifact? | What ran, executed, or touched network? |
| Data source | Local metadata files and manifests | Build/package artifacts | Runtime telemetry |
| Runtime risk | Low: read-only, no package execution | Varies | Agent-level endpoint access |
| Best use | Incident-response sweeps across developer machines | Release compliance and provenance | Runtime detection/response |
| Weak spot | Exact-match catalogs only; no exploit/runtime evidence | Often misses local dev state | Can miss lockfile-only/local metadata context |

## Self-Hosting Notes

Local verification:

- gofmt produced no changes
- go vet ./... passed
- go test ./... passed across all packages
- go test -race ./... passed
- go build -buildvcs=false ./cmd/bumblebee passed
- bumblebee selftest passed with 3 findings
- govulncheck against local Go 1.26.2 reported two reachable standard-library vulnerabilities in net/net/http, both fixed in Go 1.26.3

Deploy as a scheduled one-shot binary from cron, systemd, launchd, MDM, or an endpoint-management system. Use LaunchAgent by default on macOS for per-user state; use LaunchDaemon plus --all-users only when root-owned whole-machine scans are intentional.

For HTTPS output, prefer HMAC or bearer tokens passed through environment variables and keep output TLS-only except for local testing.

---

**Attribution:** perplexityai/bumblebee, Apache-2.0
