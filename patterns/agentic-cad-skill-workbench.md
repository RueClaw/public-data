# Agentic CAD Skill Workbench

**Source:** https://github.com/earthtojake/text-to-cad  
**Author:** earthtojake  
**License:** MIT  
**Reviewed:** 2026-05-20

## Pattern

Give coding agents a constrained CAD workbench instead of asking a general model to emit final geometry directly. The workbench has a skill contract, source-first modeling rules, explicit generation targets, deterministic inspection commands, visual review handoff, and a repair loop.

The important move is separating four things that often get blurred together:

- The user's natural-language design intent.
- The source model that owns the geometry.
- The generated exchange artifacts.
- The validation and review surfaces.

## Why It Works

CAD artifacts are brittle when agents treat generated files as editable text. A source-first workflow keeps intent in code or structured source files, then regenerates STEP/STP, STL, DXF, 3MF, GLB, URDF, SRDF, or SDF outputs explicitly. The agent can then inspect geometry facts and measurements instead of relying on visual guesses.

## Core Components

- **Skill contract:** a short task classifier, defaults, non-negotiables, and progressive references.
- **Natural-language brief:** dimensions, coordinate system, assumptions, output paths, and validation targets extracted from prose.
- **Source model:** build123d/Python or equivalent parametric source remains the editable truth.
- **Generated targets:** exchange files are regenerated from source and treated as derived artifacts.
- **Inspection CLI:** checks facts, planes, measurements, frames, diffs, and mating relationships.
- **Render handoff:** viewer links or snapshots support human/visual review after deterministic checks.
- **Repair loop:** classify the failing generation/export/inspection/render issue, make the smallest source fix, regenerate, and rerun the failed checks.
- **Harness rules:** repo-level instructions keep generated artifacts, LFS behavior, and project layout predictable without duplicating every skill detail.

## Implementation Notes

- Treat STEP/STP as the primary CAD exchange artifact; branch STL, 3MF, DXF, and GLB from that process.
- Keep source files and generated artifacts discoverable together, but never hand-edit generated CAD outputs by default.
- Use named parameters and stable labels/selectors so follow-up edits can target geometry precisely.
- Require explicit generation targets rather than directory-wide regeneration.
- Validate dimensions and mating with CLI checks before relying on render screenshots.
- Use visual review for semantic and human-facing checks, then convert visual concerns back into geometry checks where possible.
- Put large binary CAD/render assets under Git LFS and keep markdown/spec files in normal Git for diffs.

## Good Fit

- Mechanical brackets, enclosures, fixtures, simple mechanisms, and assemblies.
- Agent-generated CAD where repeatability matters.
- Robotics description files such as URDF, SRDF, and SDF.
- Design workflows that need both human review and source-controlled regeneration.

## Watch Outs

- This pattern does not replace engineering signoff, tolerancing, FEA, DFM, or safety review.
- Heavy geometry/runtime dependencies need explicit setup and version control.
- Viewer/render failures should not be allowed to masquerade as geometry validation failures.
- LFS-heavy assets can break lightweight clones if the environment lacks Git LFS or the repo is not configured to skip smudge.

## Minimal Checklist

1. Convert prose into a compact CAD brief.
2. Edit parametric source, not generated artifacts.
3. Generate explicit target files.
4. Inspect facts, planes, dimensions, and placements.
5. Render or snapshot for visual review.
6. Repair source and rerun failed checks.
7. Commit source plus generated outputs only after validation.
