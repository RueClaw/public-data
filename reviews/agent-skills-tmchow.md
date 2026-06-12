# Agent Skills (tmchow/agent-skills)

**Repo:** https://github.com/tmchow/agent-skills
**License:** MIT, with per-skill front matter also declaring MIT or MIT-0
**Reviewed:** 2026-06-11
**Stack:** Agent Skills `SKILL.md`, Markdown READMEs/references, Python stdlib tooling, Bash asset repair, GitHub Actions checksum validation
**What it is:** A small cross-runtime skill catalog for Agent-Skills-compatible runtimes, currently shipping Camofox browser automation, Chrome DevTools AXI, Clawpatch workflow guidance, and Illo editorial illustration generation.

---

## Verdict

✅ **Deploy candidate for selected installs.** This is one of the cleaner community skill repos: four focused skills, runtime-specific install lanes, human README vs agent `SKILL.md` split, front matter with version metadata, and unusually thoughtful security/scanner guidance. Install only the skill you need. `illo` is the substantial one; the browser and Clawpatch skills are narrower operating manuals around external tools.

---

## What It Is

`tmchow/agent-skills` is a personal collection of Agent Skills distributed as top-level skill directories. The README documents installation through the generic `skills` CLI, Hermes, and OpenClaw/ClawHub rather than assuming one runtime.

The repo currently contains four skills:

- `camofox-cloaked-browser` - opt-in Camofox/Camoufox anti-detection browser automation.
- `chrome-devtools-axi` - terminal-driven Chrome DevTools AXI workflow guidance.
- `clawpatch` - operating guidance for the Clawpatch automated review/fix CLI.
- `illo` - a much larger editorial illustration skill with a Python generation engine, visual references, character packs, palettes, styles, asset checksums, and a repair script for Hermes binary-install corruption.

The best part is not just the catalog. The root `AGENTS.md` captures authoring conventions for scanner-safe community skills: keep skill bodies thin, separate README and `SKILL.md`, avoid ambient secret reads, avoid CLI secret flags, keep installed bundles small, and verify binary assets with checksums.

## Stack

| Layer | Tech |
|-------|------|
| Skill format | `SKILL.md` with YAML front matter |
| Human docs | Per-skill `README.md` plus root catalog |
| Illustration engine | Python stdlib script calling OpenRouter |
| Asset repair | Bash checksum-gated downloader |
| Asset validation | Python checksum manifest generator |
| CI | GitHub Actions workflow for `illo` asset checksum freshness |
| Distribution | `npx skills add`, Hermes install paths, OpenClaw ClawHub lanes |

## Key Features

### Cross-Runtime Skill Packaging

The repo treats runtime compatibility as a first-class concern. Each skill declares core Agent Skills fields plus additive `metadata.hermes` and `metadata.openclaw` blocks where useful. The README documents separate install lanes instead of pretending one installer works everywhere.

### Strong Skill Authoring Rules

`AGENTS.md` is a useful artifact on its own. It defines directory naming, required `name`/`description`/`version` front matter, README vs `SKILL.md` separation, progressive disclosure, and rules for CLI-wrapper skills that should point agents to live `--help` instead of stale flag catalogs.

### Scanner-Safe Credential Pattern

The `illo` skill deliberately avoids reading OpenRouter keys from ambient environment variables or command-line flags. It uses a user-run `init` command to write a config file with mode `600`, and only documents an env-to-config bridge for deliberate ephemeral workspace setup. That is the right posture for community-installed skills.

### Illo as a Substantial Creative Skill

`illo` is a full editorial illustration workflow, not just a prompt. It includes style references, composition guidance, palette logic, character packs, model routing, quality bars, a stdlib Python engine, gallery generation, and asset-integrity checks.

### Binary Asset Repair for Hermes

The repo handles a real installer edge case: some Hermes versions may corrupt binary assets during multi-file installs. `illo/assets/checksums.txt`, `.github/scripts/regen_asset_checksums.py`, and `illo/scripts/repair-hermes-assets.sh` form a checksum-gated repair path pinned to immutable raw GitHub URLs.

## Architecture

The repo structure is simple:

- every top-level skill directory contains `SKILL.md` and `README.md`;
- `references/` holds deep material loaded only when needed;
- `_assets/` holds docs-only image examples so they do not ship inside each installed skill;
- `illo/assets/` holds the small functional assets that do need to ship;
- `.github/workflows/asset-checksums.yml` keeps the functional asset manifest current.

That split is worth copying. It makes install bundles smaller while still letting the public README show rich examples.

## Validation

Local checks performed:

- Cloned the repo and fetched full history before validating checksum pins.
- Ruby/Psych front matter check passed for all 4 `SKILL.md` files: `name`, `description`, `version`, and directory-name match.
- `python3 .github/scripts/regen_asset_checksums.py --check` passed after full history fetch.
- `python3 -m py_compile .github/scripts/regen_asset_checksums.py illo/scripts/illo.py` passed.
- `bash -n illo/scripts/repair-hermes-assets.sh` passed.
- `python3 illo/scripts/illo.py doctor` ran successfully and reported expected missing local config/API key plus `assets: OK`.
- Installed `illo` skill directory is about 528 KB; docs-only `_assets` is about 12 MB and outside installed skill directories.
- Lightweight secret scan found placeholder/env-var documentation only, not committed live secrets.

The repo does not include a broad test suite for the browser/Clawpatch workflows, and most skills wrap external tools whose behavior must still be checked with live `--help` and real runtime tests.

## Comparison

| Aspect | tmchow/agent-skills | steipete/agent-scripts | tech-snacks | qship |
|--------|---------------------|------------------------|-------------|-------|
| Main focus | Installable cross-runtime skill catalog | Personal canonical agent ops repo | Claude Code plugin skill library | Ticket-to-PR automation pipeline |
| Best asset | `illo` plus scanner-safe skill rules | Shared instructions and toolbelt | Skill/reference/template packaging | Hook-gated delivery loop |
| Runtime | Agent Skills, Hermes, OpenClaw, skills CLI | Local symlinked skills/scripts | Claude Code plugin | Claude/Codex automation |
| Maturity signal | Asset CI, versioned front matter, clear READMEs | Operationally rich but personal | Useful but less testable | Strong smoke/eval scaffolding |
| Main caveat | Only 4 skills; external-tool behavior drifts | Environment-shaped | Runtime hard to verify | Broad autonomy risk |

## Self-Hosting Notes

Use `npx skills add tmchow/agent-skills --skill <name>` or the runtime-specific lane for the one skill you actually need.

Audit before installing `illo`: it is the largest and most capable skill, and it calls OpenRouter for image generation. Run `doctor`, let the user create the config file/API key, and keep generated assets out of sensitive paths.

For the browser skills, keep the trigger discipline. Camofox/Camoufox is for cloaked browser work, not ordinary browsing. Chrome DevTools AXI is for AXI/CDP workflows, not generic web search.

---

**Attribution:** tmchow/agent-skills, MIT License.
