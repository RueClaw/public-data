# Vouch: Community Trust Management

**Source:** [mitchellh/vouch](https://github.com/mitchellh/vouch) (MIT) — by Mitchell Hashimoto
**What:** Explicit trust system for open source projects. Users must be vouched before interacting with a project. Vouch lists can form a web of trust across projects.

## Core Concept

AI tools have lowered the barrier to submit plausible-looking but low-quality contributions. Vouch moves from implicit trust (anyone can open a PR) to explicit trust (someone trusted must vouch for you first).

## Design Principles

- **Flat file format** — vouch list is a single file, parseable with POSIX tools, no external libraries
- **Web of trust** — projects can reference each other's vouch/denounce lists
- **Policy-agnostic** — what "vouched" means (and consequences) is up to each project
- **GitHub Actions integration** out of the box
- Written in **Nushell** (`.nu` scripts)

## Key Patterns

### Trust is transitive but controlled
- Only admins/collaborators with write access can vouch/denounce
- Vouched users cannot vouch others (prevents social engineering chains)
- Being vouched only grants ability to interact (open PRs, etc.) — not merge/push/release

### AGENTS.md conventions (from the repo)
- All CLI commands must have `--dry-run` (default on)
- GraphQL uses parameterized queries in dedicated `.gql` files
- Nushell module structure: exports first (alphabetical), then helpers

## Relevance
Interesting pattern for any multi-agent or community system where trust gating matters. The flat-file vouch list idea is elegant — no database, version-controlled, auditable.
