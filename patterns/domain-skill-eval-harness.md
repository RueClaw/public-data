# Domain Skill Eval Harness

**Source:** https://github.com/AgriciDaniel/claude-ads  
**License:** MIT  
**Reviewed:** 2026-05-23  

## Pattern

Treat an agent skill as a testable domain system, not just Markdown instructions. For a large domain skill, keep the playbooks human-readable, but add a small deterministic test harness that pins routing, catalog coverage, scoring math, and security boundaries.

Claude Ads applies this to paid advertising:

- trigger phrases route to expected sub-skills
- catalog IDs must appear in their reference files, and reference rows must appear in the catalog
- weighted scoring is reimplemented in tests for deterministic edge cases
- URL validation blocks SSRF targets and credential redaction is regression-tested
- CI runs syntax checks, JSON validation, shell syntax checks, pytest, and pip-audit

## Why It Works

Large skill packs drift. A maintainer adds a new platform check but forgets the catalog, renames a route without updating trigger language, changes scoring weights without checking edge cases, or adds a browser helper that can fetch internal URLs. A lightweight pytest suite catches those failures before the skill becomes impressive documentation with unreliable behavior.

## Reusable Shape

- Main skill router
- Focused sub-skills
- Reference files with stable check IDs
- Structured fixture catalog
- Routing snapshot tests
- Bidirectional catalog/reference coverage tests
- Deterministic scoring tests
- Script boundary tests for URLs, secrets, filesystem paths, and install syntax

## Recommended Tests

1. **Routing snapshots:** For each documented command or natural-language trigger, assert the expected sub-skill or handler.
2. **Catalog/reference coverage:** Keep a structured catalog of check IDs and fail when a reference has untracked rows or the catalog points to missing checks.
3. **Scoring determinism:** Reimplement the public formula in tests and assert all-pass, all-fail, warning, NA, and mixed examples.
4. **Boundary regressions:** For helper scripts, test SSRF denial, file path validation, secret redaction, and expected failure modes.
5. **Install syntax:** Validate shell/PowerShell/JSON syntax in CI even when full host-runtime integration cannot run.

## When To Use

Use this for any agent skill that has one or more of:

- many commands or sub-skills
- domain-specific scoring or check IDs
- helper scripts that touch the network, filesystem, credentials, or browser
- published install scripts
- a README that makes quantitative claims about coverage

Small personal prompt skills do not need this. Public, reusable, domain-heavy skills do.

---

**Attribution:** AgriciDaniel/claude-ads, MIT
