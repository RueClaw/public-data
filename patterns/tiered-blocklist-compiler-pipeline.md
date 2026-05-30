# Tiered Blocklist Compiler Pipeline

**Source:** luisfelipess/ad-filter-list
**Repo:** https://github.com/luisfelipess/ad-filter-list
**License:** MIT
**Extracted:** 2026-05-30

## Pattern

Build deployment-ready policy artifacts by compiling upstream feeds through a staged pipeline:

1. Fetch sources into a raw cache with fallback URLs and retry behavior.
2. Preserve a source map that records which raw file came from which URL and tier.
3. Detect source formats through pluggable readers.
4. Normalize entries through one shared validator.
5. Apply local allowlist/blocklist overrides after source parsing.
6. Track tier rank per entry so outputs can be cumulative.
7. Generate multiple output formats through pluggable writers.
8. Publish both generated artifacts and a provenance report.

This is useful beyond ad blocking. The same shape works for denylist generation, endpoint catalogs, compliance controls, threat-intel feeds, local routing policy, and any recurring job that turns public inputs into deployable text artifacts.

## Why It Works

The pipeline separates source concerns from target concerns. Readers answer "what did this upstream file mean?" Writers answer "what should this target system receive?" The merge stage owns global policy: dedupe, allowlist precedence, tier inclusion, and safety checks.

The tier model is especially useful. A source can be tagged `light`, `good`, or `aggressive`, and heavier tiers include lighter-tier entries. That lets one run generate conservative and broad policy bundles without maintaining multiple pipelines.

## Implementation Notes

- Keep local overrides outside upstream source config. Users should be able to update allow/block entries without changing source URLs.
- Emit machine-readable run reports, not just final artifacts. Include source health, rejected entries, counts, deltas, and output sizes.
- Use target-aware lossiness. In `ad-filter-list`, hosts/plain-domain outputs keep exact unique domains, while resolver formats receive subdomain-optimized lists because those systems can block whole subtrees.
- Add a regression guard before publishing generated output. A sudden large drop in count often means a failed download, bad parser detection, or upstream outage.
- Preserve stable URLs for the default tier. Non-default tiers can live under subdirectories without breaking existing consumers.

## Risks

- Feed compilers inherit upstream false positives and stale data.
- Generated artifacts can make the repository much larger than the source code.
- Source order can bias "net-new" metrics unless the compiler explicitly defines ranking behavior.
- Broad or aggressive policy tiers should be opt-in and documented as potentially disruptive.

## Attribution

Extracted from `luisfelipess/ad-filter-list`, MIT License.
