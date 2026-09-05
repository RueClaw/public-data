# Archify (tt-a1i/archify)

**Repo:** https://github.com/tt-a1i/archify  
**License:** MIT. Reusable with attribution.  
**Reviewed:** 2026-09-05  
**Stack:** Node.js ESM, JSON Schema/Ajv, standalone HTML/SVG, browser viewer runtime, GitHub Pages  
**What it is:** Archify is an agent-facing diagram-as-code Skill and renderer for architecture, workflow, sequence, data-flow, and lifecycle diagrams. Agents author strict JSON IR; Archify validates it and deterministically compiles it into interactive, self-contained HTML/SVG artifacts.

---

## Verdict

✅ **Deploy candidate for agent-generated technical diagrams.** Archify is much more than a Mermaid beautifier: it has strict schemas, deterministic render/deliver receipts, composition gates, source-evidence verification, and a serious viewer contract for exploration and export. The main caveat is operational rather than architectural: full dev dependencies currently audit with high-severity `fast-uri` advisories under Ajv, though the production install audit is clean and the package ships generated validators.

---

## What It Is

Archify turns system descriptions or repository analysis into polished interactive diagrams. It is packaged as an Agent Skill for Cursor, Claude Code, Codex CLI, OpenCode, Raven, and DeepSeek Harness, and it supports five typed diagram modes: architecture, workflow, sequence, dataflow, and lifecycle.

The important design choice is the intermediate representation. Instead of asking an agent to directly emit SVG, HTML, or Mermaid, Archify asks for a small typed JSON document. JSON Schema validation catches shape errors, renderer checks catch layout and semantic mistakes, and final delivery atomically replaces only a verified artifact.

The generated output is a portable HTML file with inline SVG and viewer controls for search, focus, route probing, upstream/downstream reach, semantic lens, presentation mode, theme/style switching, and export. Repository evidence is opt-in and revision-pinned, so ordinary diagrams remain source-free while code-backed diagrams can expose verified file links in the viewer.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Node.js >=18, ES modules |
| Schema validation | JSON Schema 2020-12, Ajv standalone generated validators |
| Rendering | Custom JavaScript renderers for HTML/SVG artifacts |
| Diagram modes | Architecture, workflow, sequence, dataflow, lifecycle |
| Viewer | Self-contained browser runtime with local state, export, search, routes, semantic views |
| Evidence | Git-backed revision/source verification for architecture diagrams |
| Distribution | Agent Skill package, ZIP, npm-style CLI, GitHub Pages docs/gallery |
| Tests | Node test runner, golden renders, schema/layout/property/security-style checks |

## Key Features

### Strict Typed IR

Each diagram type has its own schema with `additionalProperties: false`, required structural arrays, bounded enums, and shared definitions for IDs, points, legends, guided views, cards, locales, and visual presets. Unknown fields fail instead of becoming silent no-ops.

### Deterministic Delivery Receipts

The CLI separates `validate`, `render`, and `deliver`. `deliver` snapshots exact input bytes, renders from the snapshot, runs artifact checks, and only then atomically replaces the target HTML. Receipts include specification and artifact SHA-256 values, which is the right model for agent-produced documentation.

### Layout And Composition Gates

Archify checks more than schema shape. It rejects or warns on unreadable node text, route crossings, ambiguous corridors, route rhythm problems, label-route collisions, container-border runs, duplicate IDs, missing endpoints, and invalid workflow geometry. The diagnostics include stable rule codes and supported repairs.

### Truthful Interactive Viewer

The viewer exposes route probing, authored reachability, semantic lens, direct relationship exploration, guided stories, presentation mode, and export variants without letting transient viewer state contaminate the canonical SVG. That distinction matters because it keeps exploration separate from source facts.

### Revision-Pinned Source Evidence

Architecture diagrams can attach sources to components, but only when `meta.repository` names a public GitHub URL and full commit SHA and the renderer receives a matching local `--repo-root`. It verifies origin, commit availability, blob paths, and line ranges before embedding evidence metadata.

## Architecture

The project is organized as a packaged skill under `archify/`, with schemas, renderers, shared utilities, examples, docs, tests, and scripts. The CLI in `archify/bin/archify.mjs` routes commands to type-specific renderers, manages quality flags, handles evidence roots, and normalizes structured diagnostics.

The renderer stack is direct and dependency-light at runtime. Schemas are compiled ahead of time into committed standalone validator code, examples are golden-rendered, and the release package deliberately excludes dev-only metadata. The browser viewer is a large inline runtime, but it is guarded by tests around export cleanliness, localStorage failures, motion ownership, route/share-card receipts, browser evidence, and accessibility-like interaction boundaries.

Security-relevant posture is thoughtful. Output paths are guarded against symlink/hardlink/input aliasing, repository evidence is fail-closed, URL brand capture blocks reserved networks and suspicious media, optional update checks have a disable switch, and `--open` uses bounded argument-array invocation. The main audit caveat is dev dependency exposure through Ajv's `fast-uri` dependency.

## Comparison

| Aspect | Archify | Mermaid | Diagram Design |
|--------|---------|---------|----------------|
| Primary job | Validated interactive technical system maps | Lightweight text-to-diagram notation | Editorial static/HTML diagram skill |
| Source model | Typed JSON IR with strict schemas | Text DSL | Skill-authored semantic model and HTML/SVG |
| Validation | Schema, layout, artifact, evidence, delivery receipts | Parser and renderer errors | Accessibility/geometry/design checks |
| Interaction | Built-in search, routes, reach, lens, presentation, exports | Mostly static unless wrapped elsewhere | Mostly static/controlled motion |
| Best fit | Agent-generated architecture and workflow artifacts needing trust | Quick lightweight diagrams | Polished explanatory diagrams and branded visuals |

Archify is closest to a trustworthy diagram compiler for agents. Mermaid remains better for quick docs-native sketches. Diagram Design remains a better choice when editorial composition is the main goal and interactive graph exploration is secondary.

## Self-Hosting Notes

No service is required for normal use. The CLI and skill package run locally with Node, and the generated artifact is a self-contained HTML file. The README's normal path is:

```bash
npx skills add tt-a1i/archify -g
```

For local repository work, clone the repo, install dev dependencies with `npm ci` under `archify/`, then use commands such as:

```bash
node bin/archify.mjs doctor
node bin/archify.mjs guide "Show CI/CD checks, approval, deploy, and rollback"
node bin/archify.mjs validate workflow examples/agent-tool-call.workflow.json --quality showcase --json
node bin/archify.mjs deliver workflow examples/agent-tool-call.workflow.json /tmp/workflow.html --quality showcase --json
```

Local verification on 2026-09-05:

```text
npm ci
npm test
```

Result: 1001 passed, 0 failed, 31 skipped. Skips were browser or Node-version-gated checks. `npm audit --omit=dev` reported 0 vulnerabilities; full `npm audit` reported high-severity `fast-uri` advisories through dev dependency `ajv`.

---

**Attribution:** tt-a1i/archify, MIT License
