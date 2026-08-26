# Public Subset Boundary Audit

**Source:** MengTo/threeui
**License:** MIT
**Extracted:** 2026-08-26
**Pattern Type:** Public/private release hygiene

## Pattern

When an open-source package is generated from a larger private or paid source tree, treat the public boundary as a build artifact that must be tested, not as a maintainer promise.

ThreeUI's Community repo shows this pattern well:

- sync from a private main source snapshot;
- filter paid/private catalog entries before publishing;
- rewrite media and source paths into public-safe forms;
- remove restricted assets;
- generate a public source registry and package entry points;
- write a machine-readable sync report;
- test the public tree against that report;
- audit the build output for private paths, auth runtime, commerce runtime, and private-host links.

## Why It Matters

Private-to-public publishing fails in boring ways: one auth component stays imported, one paid asset leaks, one absolute local path lands in a generated registry, one docs link points to a private host, or one public package export exposes a component the catalog hides.

Those are not philosophical problems. They are regression-test problems.

## Borrowable Checks

- Assert that excluded product tiers do not appear in route/catalog/component registries.
- Assert that public variants and controls match a generated sync report.
- Hash public source entries and verify the hashes in tests.
- Search source and build output for private absolute paths.
- Search for auth, checkout, payment, and private-host strings.
- Reject environment files, symlinks, private keys, and sensitive-looking assignments in the public tree.
- Generate package exports from the public catalog rather than hand-maintaining them.
- Run an anonymous install smoke test against the packed package.

## Caveats

String checks are useful but incomplete. They should encode known project-specific leak classes, then run alongside normal typecheck/build/tests and human review. For higher-risk releases, add allowlisted asset manifests and license checks for every copied binary.

---

**Attribution:** Based on MengTo/threeui, MIT License.
