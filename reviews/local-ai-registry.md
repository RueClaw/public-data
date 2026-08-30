# Local AI Registry (0xSero/local-ai-registry)

**Repo:** https://github.com/0xSero/local-ai-registry  
**License:** MIT; safe to fork, adapt, and extract with attribution.  
**Reviewed:** 2026-08-30  
**Stack:** Next.js 16, React 19, TypeScript, static JSON, Python ETL/validation scripts, Bash CLI  
**What it is:** A hardware-aware registry for local AI model artifacts, launch recipes, measured speed sweeps, public benchmark rows, and regional hardware prices. It treats the JSON tree as the source of truth and layers a read-only web UI, API, and CLI over the same data.

---

## Verdict

✅ **Deploy candidate for local model selection and registry design.** The useful part is not the UI polish; it is the data contract: model, artifact, hardware, recipe, evidence, benchmark, and price records are separated cleanly, validated, and exposed through progressive disclosure. It is fresh and still has build-scale caveats, but the validation posture is much better than most local-inference catalogs.

---

## What It Is

Local AI Registry answers a practical question: "Given this machine, which local model artifacts can I run, with what runtime, trust level, and evidence?" It stores canonical models, downloadable model instances, hardware profiles, artifact-by-hardware recipes, measured speed sweeps, scraped public benchmark rows, and regional price observations as normalized JSON records.

The project deliberately avoids making every observed command a runnable recipe. `validated` recipes require pinned artifacts, pinned runtime contracts, tokenized launch arguments, compatible hardware, completion proof, speed evidence, and no eager-mode/CUDA-graph-disabling workaround. Imported LocalMaxxing, local.ai Postgres, and mlx.fast observations stay as `candidate` or `reference` evidence unless separately curated.

The Next.js app reads the registry tree directly at runtime, exposes a read-only `/api/v1` surface, and provides a search/filter browser. The Bash CLI reads the same tree, detects Apple Silicon/NVIDIA/AMD/Intel hardware, lists compatible recipes, and resolves selected records without needing the web app.

## Stack

| Layer | Tech |
|-------|------|
| Web app | Next.js 16 App Router, React 19 |
| API | Next.js route handlers, read-only JSON responses |
| Data store | Static JSON under `registry/` |
| Schema | JSON Schema plus generated/parallel TypeScript interfaces |
| ETL/validation | Python scripts for imports, curation, market snapshots, benchmarks, validation |
| CLI | Bash + `jq`, optional `rg`, `gum`, `nvidia-smi`, `system_profiler`, `lspci`, `rocminfo` |
| Deployment | Vercel-compatible Next app; registry can also be served as static JSON |

## Key Features

### Progressive Registry Contract

`registry/index.json` is the discovery document. Clients read compact recipe rows first, then fetch exact model-instance, model, hardware, recipe, price, benchmark, or speed-sweep records only when needed. That keeps large registry data usable by static hosts, APIs, CLIs, and agents without recursively embedding the whole graph.

### Trust-State Separation

The project draws a hard line between observed evidence and runnable contracts. Candidate/reference rows can remain searchable and inspectable, but they are not launchable. This is the right default for local AI recipes, where copied shell snippets, mutable containers, approximate hardware labels, and partial benchmark reports are common sources of false confidence.

### Read-Only API

The `/api/v1` API exposes discovery, facets, models, model instances, hardware, prices, recipes/compatibility, speed sweeps, and benchmarks. List routes support bounded pagination and filters for model/hardware text, validation status, launchability, engine, precision, hardware vendor/backend, memory, capabilities, evidence, and price dimensions.

### Hardware-Aware CLI

`bin/local-ai` can detect local hardware on macOS and common Linux GPU setups, list exact or capacity-compatible recipes, and resolve a recipe with its immediate model, model-instance, hardware, and speed-sweep references. It is small, readable, and useful even without running the web UI.

### Provenance and Validation

The Python validator checks ID/file consistency, schema versions, references, timestamp shape, Hugging Face identity semantics, tokenized launch fields, container provenance, promotion boundaries, and missing launch assets for validated Docker recipes. In local review, `python3 scripts/validate_registry.py` passed with:

```text
registry valid: hardware=100 model=283 model-instance=1148 recipe=2250 speed-sweeps=2789 benchmarks=97 price=130
```

## Architecture

The project has a good data-first architecture:

- `registry/` is the normalized source of truth.
- `registry/schema/` describes the public contract.
- `lib/registry.ts` loads records, resolves relationships, applies filters, and builds API/detail results.
- `app/` renders the browser and read-only API over that same library.
- `bin/local-ai` gives a filesystem-native path for terminal users.
- `scripts/` handles imports, enrichment, curation, price snapshots, and validation.

The strongest design choice is treating runtime launchability as a derived trust property, not as a synonym for "there is a command somewhere." `isLaunchable()` requires `status === "validated"` and excludes `reference` launches, while the validator enforces that observed commands stay in metadata rather than promoted into the launch contract.

The main caveat is build-scale ergonomics. `npm run build` passes, but Turbopack warns that the dynamic `readFileSync(path.join(process.cwd(), "registry", ...parts))` pattern can match 13,630 files and may cause build performance or over-bundling issues as the registry grows. That is not a correctness bug today, but it is the next scaling seam to address.

## Comparison

| Aspect | Local AI Registry | Runtime Server Catalogs | Static Leaderboards |
|--------|-------------------|-------------------------|---------------------|
| Main job | Match model artifacts, hardware, runtime recipes, speed evidence, benchmarks, and prices | Serve or manage models on a host | Rank model quality/performance |
| Data model | Normalized static JSON graph | Usually app/database-specific | Usually flat tables |
| Trust boundary | Explicit candidate/reference/validated split | Often implicit or runtime-specific | Usually evidence-only |
| Launch posture | Validated rows only should become Run actions | Runtime-dependent | Not launch-oriented |
| Best use | Model/hardware planning and registry substrate | Running models | Comparing reported scores |

Compared with a one-off README table, this is much more agent- and tool-friendly. Compared with a full local AI appliance, it is deliberately narrower: it catalogs and validates evidence, but does not yet manage downloads, containers, endpoints, or running services end to end.

## Self-Hosting Notes

The app can run locally with:

```bash
npm install
npm run dev
```

For production checks:

```bash
npm test
npm run typecheck
npm run build
python3 scripts/validate_registry.py
```

In review, the TypeScript tests, typecheck, production build, and Python registry validator all passed after installing dependencies. The build emitted one Turbopack warning about broad dynamic filesystem reads over the registry tree.

The API is read-only and sets permissive CORS. That is fine for public static data, but downstream deployments should keep mutation/import workflows out of the web runtime.

---

**Attribution:** 0xSero/local-ai-registry, MIT
