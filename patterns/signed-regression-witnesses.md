# Signed Regression Witnesses

**Source:** https://github.com/ruvnet/ruflo
**License:** MIT
**Reviewed:** 2026-05-17

## Pattern

Ruflo's verification/ directory documents a regression-protection pattern that complements ordinary tests:

1. Write normal behavioral smoke tests for user-visible behavior.
2. Record a machine-readable witness manifest for previously fixed bugs.
3. For each fix, store a file path, SHA-256, and a distinctive load-bearing marker substring.
4. Sign the manifest with Ed25519.
5. Keep per-platform history in append-only JSONL.
6. Run CI checks that fail when a marker disappears or the signed manifest no longer validates.

This catches a class of regressions that normal tests can miss: a fix may remain semantically important even after the file changes and the exact hash drifts. Ruflo handles that by distinguishing exact PASS from marker-based PASS_DRIFT.

## Why It Matters

Agentic and plugin-heavy systems accumulate many small bug fixes around CLI parsing, hook behavior, generated files, and install-time edge cases. Those fixes often live in code paths that are hard to cover exhaustively. A witness manifest makes the existence of each load-bearing fix explicit and auditable.

## When To Use

Use this pattern when:

- regressions are repeatedly reintroduced after refactors;
- fixes are tied to specific command-line flags, generated file content, or integration glue;
- a project ships across operating systems;
- there is a public need to prove that a release still contains specific remediations.

Avoid using marker witnesses as a replacement for tests. They prove that important code is still present, not that the whole behavior still works.

## Minimal Shape

Example witness input:

    {
      "fixes": [
        {
          "id": "CLI-001",
          "desc": "Subcommand flag parser preserves scoped aliases",
          "file": "dist/cli.js",
          "marker": "registerLazyCommandName"
        }
      ]
    }

Good markers are unique to the fix and unlikely to appear by accident. Bad markers are generic words such as function, TODO, or fix.

---

**Attribution:** ruvnet/ruflo, MIT License.
