# stainful (stainlu/stainful)

**Repo:** https://github.com/stainlu/stainful
**License:** MIT; permissive for use, modification, redistribution, and generated-runtime reuse with attribution.
**Reviewed:** 2026-05-19
**Stack:** Python 3.10+, OpenAPI 3.x, Stainless-compatible YAML, ruamel.yaml, Jinja2, httpx, pydantic v2, pytest, ruff
**What it is:** stainful is an open-source, local-first Python SDK generator that consumes an OpenAPI spec plus a `stainless.yml`-style config and emits an idiomatic typed Python client.

---

## Verdict

📚 **Study, with pilot potential.** The architecture is unusually clean for a brand-new codegen project: config/OpenAPI loaders feed a language-agnostic IR, then a Python emitter renders a vendored runtime with sync/async clients, typed errors, retries, pagination, streaming, multipart uploads, and binary responses. The caution is maturity: the repo was created on 2026-05-19, has one main contributor, and still lists known parity gaps, so it should be validated against real APIs before becoming infrastructure.

---

## What It Is

stainful positions itself as an open-source Stainless alternative. Instead of using a hosted SDK generation service, teams can point it at an OpenAPI 3.x file and a Stainless-compatible `stainless.yml` and generate a Python SDK locally or in CI.

The generated SDK is meant to feel hand-written rather than mechanically generated: nested resource clients, pydantic models, typed exceptions, retry behavior, streaming helpers, auto-pagination, and sync/async surfaces are produced from the same semantic model. The repository dogfoods this through a real OneBusAway example and a CI guard that fails if regeneration changes checked-in output.

The most important design choice is the intermediate representation. The OpenAPI/config front half stays language-neutral, the IR captures semantic API shape, and the Python emitter handles Python-specific naming, typing, pagination, runtime vendoring, and package layout.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Python `argparse`, `stainful generate` |
| Config parsing | `ruamel.yaml` with source-location diagnostics |
| API spec parsing | OpenAPI 3.x YAML/JSON loader with local `$ref` and `allOf` resolver |
| Semantic model | Dataclass-based IR for resources, methods, types, security, pagination, streaming, body shapes |
| Code generation | Jinja2-style string rendering in a Python emitter |
| Generated runtime | `httpx`, `pydantic v2`, vendored sync/async client runtime |
| Quality gates | pytest fixtures, golden regeneration checks, ruff, GitHub Actions matrix for Python 3.10-3.12 |

## Key Features

### Stainless-Compatible Input

The loader accepts a Stainless-style config, models the keys the generator needs, preserves deferred keys in `.extra`, and emits warnings for genuinely unknown keys. That is the right migration posture: existing configs can load before every Stainless feature is implemented.

### Language-Agnostic IR

The IR keeps OpenAPI parsing and Python emission separate. It models required versus optional versus nullable fields, references named component models without recursively inlining everything, represents discriminated unions, and records pagination/streaming/body intent independently from the generated Python syntax.

### Hand-Written Runtime Vendored Into Output

Generated SDKs depend only on `httpx` and `pydantic`. Runtime behavior such as retries, idempotency keys, request options, streaming, pagination, and typed errors lives in audited runtime modules rather than being duplicated per endpoint.

### Conformance-Driven Testing

The OneBusAway example is both an example and a guardrail: stainful regenerates the SDK in tests and fails if checked-in output drifts. The quality harness compares public API surface against a real Stainless-generated SDK and reports recall metrics for methods, signatures, models, exports, and exceptions.

## Architecture

The core pipeline is intentionally small:

```text
stainless.yml + OpenAPI 3.x
        |
        v
config loader + OpenAPI loader/resolver
        |
        v
language-neutral IR
        |
        v
Python emitter + vendored runtime
        |
        v
typed sync/async Python SDK
```

This boundary is the strongest part of the project. The config loader does not know Python, the emitter does not parse OpenAPI, and the runtime carries behavior that should not be templated repeatedly. That keeps future targets, such as an MCP server or another language, plausible rather than just roadmap text.

The main implementation risk is that the emitter is still a large single module. For a young project that is acceptable, but as parity grows, keeping naming, type rendering, package layout, resource rendering, and runtime-copy behavior in one file will become harder to reason about.

## Comparison

| Aspect | stainful | OpenAPI Generator | Fern | Stainless |
|--------|----------|-------------------|------|-----------|
| Hosted service required | No | No | No for many workflows | Yes / service-centered |
| Stainless config compatibility | Yes, partial and growing | No | No | Native |
| Output style | Idiomatic Python SDK goal | Often mechanical | Idiomatic SDKs | Idiomatic SDKs |
| Language coverage | Python only today | Broad | Broad | Broad |
| Maturity | Very early | Mature | Mature | Mature |
| Best fit | Local Python SDK generation from existing Stainless-style configs | Broad multi-language generation | Productized SDK programs | Polished hosted SDK generation |

## Self-Hosting Notes

The local path is straightforward:

```bash
pip install stainful
stainful generate --spec openapi.yml --config stainless.yml --out ./sdk
```

From source, the project uses `uv`:

```bash
uv venv
uv pip install -e ".[dev,generated-runtime]"
uv run pytest -q
uv run ruff check src tests
```

Local verification on 2026-05-19 passed with:

- `56 passed, 5 skipped in 5.10s`
- `ruff check src tests`: all checks passed

The skipped tests are expected oracle-dependent tests rather than broad collection failure. A first verification attempt without explicit generated-runtime/dev dependencies failed during collection; rerunning with `httpx`, `pydantic`, `pytest`, `ruamel.yaml`, and `jinja2` available passed.

---

**Attribution:** stainlu/stainful, MIT License
