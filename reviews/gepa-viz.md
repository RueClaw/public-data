# gepa-viz (modaic-ai/gepa-viz)

**Repo:** https://github.com/modaic-ai/gepa-viz
**License:** MIT declared in README/package metadata; no root LICENSE file detected
**Reviewed:** 2026-05-24
**Stack:** Python 3.11+, stdlib ThreadingHTTPServer/SSE, React 19, Vite 8, TypeScript, D3 force/zoom/shape, Tailwind CSS 4
**What it is:** gepa-viz is a live visualizer for GEPA prompt-optimization runs. It streams optimizer events into a candidate-tree UI so users can inspect prompt evolution, accepted/rejected proposals, validation outcomes, minibatch feedback, prompt diffs, and Pareto-frontier behavior.

---

## Verdict

⚠️ **Interesting, and useful for GEPA-heavy workflows once the packaging edges are cleaned up.** The visualization model is the right shape: a durable `run.json` trace, an embedded local viewer, a standalone streaming server, and reusable React components. The repo is extremely young, has no real test suite, exposes an unauthenticated remote `/ingest` endpoint when bound beyond localhost, and currently breaks on Python 3.14 despite declaring `>=3.11`.

---

## What It Is

GEPA optimizes prompts by proposing, evaluating, accepting, and rejecting candidate instructions over time. gepa-viz turns that process into an inspectable graph. Accepted candidates appear as larger nodes with green/red validation-result segments, rejected candidates appear as smaller grey nodes, and edges can expose the feedback used to generate a child proposal.

The Python package provides `GepaVizCallback`, a context manager that plugs into DSPy GEPA or base `gepa.optimize`. In the default embedded mode, entering the context starts a local viewer and streams snapshots over server-sent events. In remote mode, the callback POSTs snapshots to a standalone `gepa-viz live` server. In static mode, it writes a `run.json` artifact that can be reopened later with `gepa-viz serve`.

The frontend is split into a reusable `gepa-viz` React component package and a private Vite app used as the bundled viewer. That split is good: the same graph/detail components can be embedded elsewhere without adopting the entire CLI/server wrapper.

## Stack

| Layer | Tech |
|-------|------|
| Python package | `gepa_viz`, Hatchling, hatch-vcs, uv lockfile |
| GEPA integration | Callback object that consumes GEPA/DSPy event dictionaries |
| Server | Python stdlib `ThreadingHTTPServer`, SSE `/events`, static `/run.json`, remote `/ingest` |
| Frontend library | React, TypeScript, Vite library build, Tailwind CSS |
| Visualization | D3 force simulation, D3 selection/zoom/shape, custom donut/pixel-grid views |
| Distribution | PyPI wheel intended to bundle the prebuilt SPA; npm package for React components |
| CI/release | GitHub release workflow publishes Python dists and npm package via trusted publishing |

## Key Features

### Embedded Live Viewer

The default usage is ergonomic: wrap a GEPA run in `with GepaVizCallback(...)`, and the viewer starts locally. The callback seeds the run, publishes snapshots as GEPA events arrive, dumps `run.json` on exit, and can keep the viewer alive after the optimizer finishes.

### Remote Streaming Mode

`gepa-viz live` starts a standalone server with `/events` and `/ingest`. A producer can run elsewhere and push snapshots to `<endpoint>/ingest`, while browsers subscribe over SSE. That is useful for remote training boxes or notebook/server workflows, but it should be treated as trusted-network-only because `/ingest` has no auth or schema enforcement beyond JSON parsing.

### Static Trace Artifact

The same callback can run headless and write `run.json`. This is the strongest architectural choice in the repo: the visualization is not only a live dashboard, it is a durable trace format that can be archived, shared, diffed, and reopened.

### Candidate Detail Inspection

The UI goes past a pretty graph. Candidate pages show validation-grid results, prompts, prompt diffs against the parent, minibatch attempts, score changes, and feedback. That makes the tool useful for debugging optimizer behavior instead of just watching a run animate.

### Reusable React Surface

The React package exports `Graph`, `CandidateView`, `Donut`, `ParetoGrid`, minibatch/prompt components, `RunProvider`, and schema helpers. This makes it plausible to embed GEPA visualization into other experiment dashboards.

## Architecture

The architecture is a simple trace pipeline:

1. GEPA emits optimization events.
2. `GepaVizCallback` normalizes Python/DSPy objects into JSON-safe examples, candidates, predictions, scores, minibatches, and feedback.
3. The callback publishes full snapshots to either an in-process `Hub`, a remote `/ingest` endpoint, or disk.
4. The browser chooses live/static/poll mode from `/config.json`, then reads `/events` or `/run.json`.
5. React components render a force-directed candidate tree and candidate detail pages.

The `Hub` is intentionally small: it keeps the latest snapshot and fans updates out to per-browser queues. The server resolves static assets from the bundled package, falls back to `index.html` for client-side routing, and reads static run files on demand.

The main correctness risk is that the callback depends on GEPA event ordering and event dictionary shape. The code explicitly handles one known ordering issue: `on_valset_evaluated` can arrive before `on_candidate_accepted`, so valset evaluations are parked in `_pending_valset_eval` until the candidate exists.

## Verification

Validation run against commit `1a8483da742eeff1d38d5a0017636788d93fb784`:

- `npm ci` passed.
- `npm run lint` passed.
- `npm run build` passed for both the reusable React package and bundled app.
- `npm audit --omit=dev` reported 0 vulnerabilities.
- `python3.13 -m compileall -q python/src/gepa_viz` passed.
- Synthetic fake-run generation passed under Python 3.13 with `PYTHONPATH=python/src python3.13 python/examples/fake_run.py --no-live --delay 0 --path /tmp/gepa-viz-fake-run.json`, producing 6 examples and 4 candidates.
- Python 3.14 import failed because `server.py` imports `Traversable` from `importlib.abc`; use `importlib.resources.abc.Traversable` or narrow the declared Python range.
- No obvious live secrets were found; examples include placeholder `OPENAI_API_KEY=...` references and sample run JSON.

## Comparison

| Aspect | gepa-viz | Generic experiment dashboards | Static run logs |
|--------|----------|-------------------------------|-----------------|
| GEPA semantics | First-class candidate/feedback/prompt-diff model | Usually custom work | Low |
| Live updates | SSE snapshot stream | Depends platform | No |
| Replay artifact | `run.json` | Varies | Yes, but no UI |
| Embeddability | React component package | Varies | Low |
| Maturity | Very fresh, minimal tests | Varies | Usually simple |

## Self-Hosting Notes

For local use, the default `127.0.0.1` host is the right posture. For remote use:

- Treat `gepa-viz live --host 0.0.0.0` as a trusted-network debug server.
- Do not expose `/ingest` directly to the public internet without adding auth, size limits, and basic schema validation.
- Remember that `run.json` can contain prompts, examples, model outputs, feedback, and private evaluation data.
- Add a real root `LICENSE` file if the repo is intended to be reusable under MIT.
- Fix Python 3.14 import compatibility or cap `requires-python` before broad package distribution.

---

**Attribution:** modaic-ai/gepa-viz, MIT declared in README/package metadata; no root LICENSE file detected.
