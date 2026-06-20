# SkillSpector (NVIDIA/SkillSpector)

**Repo:** https://github.com/NVIDIA/SkillSpector
**License:** Apache-2.0, permissive reuse with attribution
**Reviewed:** 2026-06-20
**Stack:** Python 3.12-3.14, LangGraph, Typer, Rich, Pydantic, YARA, OSV.dev, OpenAI/Anthropic/NVIDIA-compatible LLM providers, Docker
**What it is:** A security scanner for AI agent skills that checks skill bundles before installation, combining static rules, AST/taint checks, YARA signatures, MCP-specific checks, live OSV dependency lookups, and optional LLM review.

---

## Update Notes

Checked against `a5092dd` on 2026-06-20. Since the 2026-05-31 review, SkillSpector has moved to version `2.2.3`, added a Docker path, constrained Python support to `<3.15`, expanded provider abstraction, fixed real-scan MCP tool-poisoning reachability, added invalid skill path rejection, and grew the default test run to 621 passing tests.

---

## Verdict

✅ **Deploy candidate for pre-install skill screening.** SkillSpector still hits a real and under-served gap: agent skills are executable trust packages, and most agent runtimes still treat them as plain documentation. The repo is young, but the current snapshot is stronger than the May review: Docker packaging, Python-version guardrails, reachable MCP checks, live dependency intelligence, and a larger passing test suite make it usable as a practical intake gate.

---

## What It Is

SkillSpector scans a local directory, single `SKILL.md`, zip, raw URL, or Git repository and emits terminal, JSON, Markdown, or SARIF reports. Its threat model is specific to AI-agent skills: prompt injection in metadata, data exfiltration, privilege escalation, supply chain issues, excessive agency, memory poisoning, tool misuse, rogue-agent behavior, MCP least privilege, MCP tool poisoning, and dependency CVEs.

The architecture is a LangGraph workflow: input resolution, context building, parallel analyzers, optional LLM filtering/enrichment, then report generation. That is a good fit for a scanner because deterministic passes can run quickly while semantic passes remain optional and provider-selectable.

The project remains alpha-classified, and there are still explicit TODOs around analyzer discovery and service mode. But it is no longer just a paper-shaped demo. It has a real CLI, Dockerfile, SARIF output, provider registries, OSV fallback behavior, malicious/clean fixtures, and a broad test suite.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Typer, Rich |
| Workflow | LangGraph |
| Models | Pydantic, dataclasses |
| Static scanning | Regex analyzers, AST analyzer, taint-tracking stub, YARA rules |
| Dependency intelligence | OSV.dev via `httpx`, static fallback lists |
| Semantic analysis | OpenAI, Anthropic, NVIDIA build endpoint, OpenAI-compatible local endpoints |
| Packaging | Python package, uv/pip install, Dockerfile on Python 3.12 slim |
| Outputs | Terminal, JSON, Markdown, SARIF |
| Tests | Pytest, pytest-asyncio |

## Key Features

### Agent-Skill Threat Taxonomy

The strongest part is the domain-specific taxonomy. SkillSpector does not just scan Python for dangerous calls; it models prompt injection, memory poisoning, output handling, rogue agent persistence, MCP tool metadata poisoning, and least-privilege mismatches. That makes it a better fit for agent package review than a generic SAST-only tool.

### Two-Stage Analysis

The scanner runs deterministic analyzers first, then optionally uses an LLM meta-analyzer to filter and enrich findings. This is the right shape for a noisy security domain: fast high-recall rules produce candidates, while semantic review can reduce false positives when credentials and model access are available.

### Live Dependency Lookup

The supply-chain analyzer now uses OSV.dev for live vulnerability checks, with a static fallback when the API is unavailable. That is a meaningful improvement over hand-curated vulnerable-package lists because new Python and npm advisories do not require a scanner release before they can be detected.

### CI-Friendly Outputs

SARIF support matters. A scanner like this is most useful when it can become a required check before skills are installed, published, or promoted. JSON and Markdown outputs make it usable in local review and documentation pipelines.

### Docker Path

The repo now includes Docker support and a smoke-test script. The Dockerfile installs `git`, which matters because scanning repository URLs from inside the container would otherwise fail.

### Real Test Surface

Verification on 2026-06-20 with Python 3.12 passed:

```text
621 passed, 12 skipped, 26 deselected, 1 warning
```

That is unusually solid for a fresh agent-security repo. The tests cover input resolution, CLI behavior, SARIF, static patterns, semantic analyzer plumbing, MCP checks, provider routing, graph integration, and report generation.

## Architecture

The main workflow is compact:

```text
resolve_input -> build_context -> parallel analyzers -> meta_analyzer -> report
```

`resolve_input` normalizes Git URLs, file URLs, zips, single files, and directories into a local directory. `build_context` walks files, builds a file cache, parses `SKILL.md` frontmatter, records executable-file metadata, and now preserves parameter definitions so MCP tool-poisoning checks can run on real scans.

Analyzer nodes append normalized findings through the LangGraph state reducer. `meta_analyzer` optionally calls an LLM per file or chunk. `report` computes a score, risk band, recommendation, and selected output format.

The biggest design win is keeping analyzers as independent graph nodes. Adding a detector is mostly a registration problem: implement a node that returns findings, add it to `ANALYZER_NODE_IDS`, and the graph fans it out automatically.

## Comparison

| Aspect | SkillSpector | Generic SAST | Dependency scanner |
|--------|--------------|--------------|--------------------|
| Agent metadata attacks | First-class | Usually absent | Absent |
| Executable script risk | Yes | Yes | No |
| MCP metadata/tool poisoning | Yes | No | No |
| CVE lookup | OSV.dev | Sometimes | Primary focus |
| CI output | SARIF/JSON/Markdown | Often | Often |
| Maturity | Alpha but tested | Varies | Often mature |

SkillSpector should complement, not replace, broader scanners. It catches agent-skill failure modes that Bandit, Semgrep, npm audit, or pip-audit are not designed to see.

## Self-Hosting Notes

Use Python 3.12 or 3.13 for local development today. The project now declares `>=3.12,<3.15`, but the current dependency path still fails to build on Python 3.14 in this environment through `jsonschema-rs`/PyO3 from `langgraph-cli[inmem]`. Running the test suite with Python 3.12 works cleanly.

Docker is now the least fussy path for no-Python local scans:

```bash
make docker-build
docker run --rm -v "$PWD:/scan" skillspector scan ./my-skill/ --no-llm
```

For privacy-sensitive scans, run `--no-llm` or point the OpenAI-compatible provider at a local endpoint. The static checks and OSV lookup remain useful without sending skill content to a hosted model. If using live OSV lookup, allow outbound HTTPS to `api.osv.dev`.

Treat Git URL and remote zip scanning as networked input handling. For automated pipelines, prefer scanning already-fetched artifacts from a controlled checkout rather than letting the scanner fetch arbitrary URLs directly.

---

**Attribution:** NVIDIA/SkillSpector, Apache-2.0
