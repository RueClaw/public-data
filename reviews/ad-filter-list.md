# ad-filter-list (luisfelipess/ad-filter-list)

**Repo:** https://github.com/luisfelipess/ad-filter-list
**License:** MIT, permissive reuse with attribution
**Reviewed:** 2026-05-30
**Stack:** Python 3.8+ standard library, GitHub Actions, hosts/adblock/RPZ/dnsmasq/Unbound output formats
**What it is:** A small automated blocklist compiler that fetches upstream DNS and ad-block lists, normalizes and deduplicates domains, and republishes tiered outputs in resolver-friendly formats.

---

## Verdict

⚠️ **Interesting, especially as a self-hosted DNS-list pipeline pattern.** The repo is usable for personal DNS filtering and has a surprisingly disciplined pipeline for a small project: pluggable readers/writers, source health reporting, tiered outputs, fallback downloads, IANA TLD validation, and daily publishing. It is still a tiny personal repo with 2 stars, committed generated artifacts, false-positive risk from aggressive lists, and a stale compatibility shim/test mismatch, so treat it as a pattern source or cautious personal deployment rather than a mature shared service.

---

## What It Is

`ad-filter-list` builds one combined blocklist from multiple upstream sources. It downloads hosts, domain-only, wildcard-domain, and adblock-style sources, strips invalid entries, applies allowlist/blocklist overrides, deduplicates exact domains, optionally removes redundant subdomains for DNS formats, and writes six output formats.

The project publishes three tiers: `light`, `good` as the default root output, and `aggressive`. The current run reports 31 sources, 951,966 default unique domains for hosts/plain-domain outputs, 719,328 DNS-optimized domains, and 1,438,346 aggressive-tier domains.

The repo is also intended to be cloned and customized locally. `sources.conf`, `allowlist.txt`, `blocklist.txt`, `writers.conf`, and `tiers.conf` are plain text control surfaces, and the runtime has no package dependencies beyond Python.

## Stack

| Layer | Tech |
|-------|------|
| Pipeline | Python 3.8+ standard library |
| Source fetch | `urllib.request`, `ThreadPoolExecutor`, gzip/zip handling, retry/fallback URLs |
| Parsing | Pluggable readers for hosts, domain-only/wildcard, and adblock syntax |
| Output | Pluggable writers for hosts, plain domains, adblock, BIND9 RPZ, dnsmasq, Unbound |
| Automation | GitHub Actions daily schedule and manual trigger |
| Reports | JSON source/run report plus rejected-entry log |
| Tests | `unittest` coverage for readers, merge logic, tiering, writers, and source health |

## Key Features

### Tiered Outputs

Sources can be tagged by tier in `sources.conf`, with cumulative inclusion from lighter to heavier tiers. The default `good` tier writes to `processed/` for backwards-compatible links, while non-default tiers write under `processed/<tier>/`.

### Format-Aware Deduplication

Hosts and plain-domain files keep exact unique domains, while DNS resolver formats receive a subdomain-optimized list because RPZ, dnsmasq, Unbound, and adblock rules can cover subdomains more compactly. That split avoids throwing away useful host-file entries while still shrinking resolver configs.

### Source Quality Reporting

Every run writes `reports/blocklist-report.json` with per-source scanned, accepted, rejected, net-new, tier-exclusive, health, and output-size data. The repo also commits `reports/rejected-entries.txt`, making parser failures and invalid TLD rejections inspectable.

### Simple Customization

The user-facing controls are text files: choose sources, set fallback URLs, enable writers, adjust tiers, force block entries, and allowlist domains. For a DNS-list compiler, that is the right level of complexity.

## Architecture

The core architecture is a three-stage pipeline:

1. `fetch.py` downloads source files into `raw/` and writes `raw/sources.map`.
2. `merge.py` detects formats, normalizes domains, applies allowlist/blocklist rules, computes tiers, and writes outputs/reports.
3. `post_run.py` rebuilds the README stats block from the JSON report.

The cleanest design choice is the reader/writer split. Readers own source syntax detection and extraction. Writers own output syntax and decide whether they need the exact-deduped or DNS-optimized list through a `BaseWriter.optimize_subdomains` flag. That keeps format-specific behavior out of the main merge loop.

The weakest design choice is keeping large generated blocklists in the same Git repository as the source code. It makes raw Git clones heavy for a small Python project, although it does make GitHub raw URLs easy to consume.

## Comparison

Compared with using a single upstream list such as StevenBlack, OISD, or HaGeZi directly, this project is more configurable and multi-format, but it inherits the operational burden of source selection and false-positive management. Compared with full DNS-filtering stacks such as Pi-hole or AdGuard Home, it is not a resolver or UI; it is a list compiler that can feed those systems.

| Aspect | This Tool | Single Upstream List | Pi-hole / AdGuard Home |
|--------|-----------|----------------------|-------------------------|
| Purpose | Compile and publish merged lists | Provide one curated list | Run DNS filtering service |
| Deployment | GitHub raw files or local Python run | Subscribe to URL | Service/container/appliance |
| Customization | Sources, tiers, writers, allow/block overrides | Usually limited | UI and resolver-level controls |
| Risk | Source-combination false positives | Curator-specific false positives | Operational service exposure |

## Self-Hosting Notes

The default hosted output can be consumed directly via GitHub raw URLs. For local customization, clone the repo, edit `sources.conf`, `allowlist.txt`, `blocklist.txt`, `writers.conf`, or `tiers.conf`, then run:

```bash
python3 run.py
```

For faster local tuning after an initial download:

```bash
python3 run.py --skip-download
```

Use the aggressive tier carefully. It includes policy-style sources such as DoH/VPN/proxy bypass lists and broader telemetry/threat feeds, which can break legitimate traffic depending on the network.

---

**Attribution:** luisfelipess/ad-filter-list, MIT License
