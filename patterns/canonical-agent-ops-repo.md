# Canonical Agent Ops Repo

**Source:** [steipete/agent-scripts](https://github.com/steipete/agent-scripts)
**License:** MIT
**Reviewed:** 2026-06-11

## Pattern

Keep shared coding-agent operations in a dedicated versioned repository instead of scattering instructions, skills, prompts, and helper scripts across every project.

The repo should contain:

- one canonical shared instruction file;
- pointer-style downstream instruction files in project repos;
- routeable skills under `skills/<name>/SKILL.md`;
- lightweight helper scripts for repeatable agent workflows;
- docs with metadata that tells agents when to read them;
- validators for skill front matter, duplicate names, and documentation metadata.

## Why It Works

Agent instructions drift quickly when copied between repositories. A canonical operations repo turns that drift into normal source control: reviewable diffs, history, validation, and explicit downstream sync.

It also separates reusable operating procedure from project-specific policy. Shared skills can evolve once, while downstream repos keep local rules short and focused.

## Implementation Notes

- Use pointer-style downstream files instead of copying the full instruction body.
- Keep skill descriptions short and optimized for routing.
- Validate every skill has parseable YAML front matter with non-empty `name` and `description`.
- Prefer helper scripts when a workflow has repeatable shell steps.
- Keep environment-specific assumptions in local notes, not public shared skills.
- Treat the repo as operational infrastructure: validate changes in CI and avoid broad, unreviewed rewrites.

## Good Fit

This pattern is useful for teams or solo maintainers who use AI agents across many repositories and want consistent behavior, reusable workflows, and fewer stale instruction copies.

## Caveats

A canonical agent-ops repo can become too personal or too large. Keep public/shared parts generic, keep private environment notes elsewhere, and periodically prune skills that no longer earn their prompt-budget cost.

---

**Attribution:** steipete/agent-scripts, MIT License.
