# earthtojake/text-to-cad Review

**Source:** https://github.com/earthtojake/text-to-cad  
**Author:** earthtojake  
**License:** MIT  
**Reviewed:** 2026-05-20  
**Snapshot:** `0470134a44a456c1c63e582a385509cec889a30b`

## Verdict: ✅ Deploy candidate

text-to-cad is a practical bundle of agent skills for CAD, robotics, and hardware design. The name undersells it: this is not just a text prompt demo, but a reusable workflow stack for source-controlled CAD generation, STEP-first exports, geometry inspection, render review, robot description generation, and off-the-shelf part lookup.

It is a deploy candidate if the goal is to give coding agents a disciplined CAD workflow. It is still young and has some rough edges in the test/runtime layout, but the core design is unusually coherent: generated CAD artifacts are treated as derived outputs, source stays primary, validation is programmatic, and visual review is a handoff rather than the only source of truth.

## What It Is

- Installable agent skills for CAD, rendering, STEP parts, URDF, SRDF, SDF, and SendCutSend preflight.
- Python CLI helpers for STEP/STL/3MF/DXF/GLB generation and inspection.
- A CAD Explorer/render viewer for local visual review.
- Repo-level harness instructions for CAD projects edited by coding agents.
- Benchmark prompts and generated examples for mechanical parts.
- Documentation site built with Next.js.

## Repository Signals

- Stars: 3,394
- Forks: 397
- Open issues: 3
- License: MIT
- Created: 2026-04-22
- Last pushed at review time: 2026-05-21
- Python files: 97
- Markdown files: 62
- JavaScript files: 117
- TypeScript/TSX files: 20

## Stack

- Python 3.11+ skill tools.
- build123d and OpenCascade/OCP for CAD geometry.
- ezdxf, numpy, trimesh, VTK, lib3mf for export and inspection workflows.
- Next.js, React, Three.js, and Tailwind for docs/viewer surfaces.
- Git LFS for heavyweight assets and generated CAD/render artifacts.

## Strong Ideas

- **STEP-first workflow:** STEP/STP is treated as the primary artifact, with STL, 3MF, DXF, and GLB as secondary exports.
- **Source-before-output discipline:** agents are told to edit build123d/Python sources and regenerate explicit targets instead of hand-editing derived CAD files.
- **Geometry-grounded validation:** generated parts are checked through facts, planes, measurements, frame inspection, mating checks, and diffs.
- **Progressive skill references:** the CAD skill loads only the specific workflow reference needed for the current task.
- **Render as review, not truth:** visual review is integrated, but programmatic geometry checks remain the validation source of truth.
- **Reusable harness:** the repo includes AGENTS/CLAUDE harness files for CAD projects that should keep generated artifacts, LFS behavior, and regeneration rules predictable.

## Risks

- **Young project:** the repo was created less than a month before this review and is moving quickly.
- **Heavy runtime:** real CAD use pulls in large geometry dependencies such as build123d, OCP, VTK, and browser/Three.js tooling.
- **Git LFS required for full assets:** lightweight clones need LFS disabled or installed; otherwise checkout can fail on machines without `git-lfs`.
- **Some test/runtime rough edges:** most focused suites pass, but render tests fail in a fresh checkout because the expected browser asset path is missing, and two common CAD tests fail due path-root assumptions in the temporary test workspace.
- **Not engineering certification:** useful for generation and inspection loops, but does not replace mechanical engineering review, FEA, tolerancing, or manufacturing signoff.

## Verification

Commands run against a shallow clone at `0470134a44a456c1c63e582a385509cec889a30b`:

- Clone required disabling Git LFS filters locally because `git-lfs` was not installed.
- `python3 -m compileall -q skills` passed.
- SDF tests passed: 48 tests.
- URDF tests passed: 42 tests.
- SRDF tests passed: 14 tests.
- MoveIt2 server tests passed: 17 tests.
- CAD runtime dependencies installed successfully into a Python 3.12 virtualenv from `skills/cad/requirements.txt`.
- CAD focused tests passed for DXF, STEP, inspect CLI, and inspect refs: 47 tests total.
- Docs install/build passed: `npm --prefix docs ci` found 0 vulnerabilities and `npm --prefix docs run build` completed successfully.

Known verification gaps:

- `skills/cad/scripts/common/tests`: 126 tests ran; 2 assertion failures around native GLB collision error text and 1 3MF-load error from optional `trimesh` dependencies in the ad hoc environment.
- `skills/cad/scripts/render/tests`: 38 tests ran; 6 failed/error because the browser renderer expected `skills/cad/explorer/node_modules/three/build/three.module.js`, while the repo layout exposes viewer assets under the render skill path.

## Best Use

Use this when you want agents to produce inspectable mechanical CAD artifacts from prose while keeping a proper regeneration and validation trail. It is especially useful for fixtures, brackets, enclosures, robot descriptions, part lookups, and CAD project harnessing.

Do not use it as a blind manufacturing pipeline. Keep human review, explicit assumptions, and geometry validation in the loop.

## Extracted Pattern

- [agentic-cad-skill-workbench.md](../patterns/agentic-cad-skill-workbench.md) — a reusable pattern for constrained agentic CAD workflows with source-first generation, explicit targets, deterministic inspection, visual handoff, and repair loops.
